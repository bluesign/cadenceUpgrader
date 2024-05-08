 

pub contract MoxyData {
    
    pub struct DictionaryMapped {
        pub var dictionary: {UFix64:AnyStruct}
        pub var arrayMap: [UFix64]

        pub fun setValue(_ value: AnyStruct) {
            let timestamp = getCurrentBlock().timestamp
            self.dictionary[timestamp] = value
            self.arrayMap.append(timestamp)
        }

        pub fun valueNow():AnyStruct {
            return self.valueFor(timestamp: getCurrentBlock().timestamp)

        }
        
        pub fun valueFor(timestamp: UFix64):AnyStruct {
            if (self.arrayMap.length == 0 || timestamp < self.arrayMap[0]) {
                // No values for that timestamp
                return nil
            }

            if (timestamp >= self.arrayMap[self.arrayMap.length-1]) {
                return self.dictionary[self.arrayMap[self.arrayMap.length-1]]!
            }

            //search
            var i = 0
            while (self.arrayMap.length < i && self.arrayMap[i] < timestamp) {
                i = i + 1
            }

            if (i > self.arrayMap.length-1) {
                i = self.arrayMap.length-1
            }

            return self.dictionary[self.arrayMap[i]]
        }

        init() {
            self.dictionary = {}
            self.arrayMap = []
        }
    }

    /** Resource to store key: Timestamp, value: amount
     *  The amounts in dictionary accumulates from last amounts added
     *  so the changes must to be calculated.
     */

    pub resource OrderedDictionary {
        pub var dictionary: {UFix64:UFix64}
        pub var arrayMap: [UFix64]
        pub var ages: {UFix64:UFix64}
        pub var agesMap: [UFix64]

        pub fun getDictionary(): {UFix64: UFix64} {
            return self.dictionary
        }

        /**
            Returns the value for the given timestamp. If the timestamp
            is not found, it returns the most recent timestamp that is
            less than the parameter received.
         */
        pub fun getValueOrMostRecentFor(timestamp: UFix64): UFix64 {
            let time0000 = MoxyData.getTimestampTo0000(timestamp: timestamp)
            if (self.dictionary[time0000] != nil) {
                return self.dictionary[time0000]!
            }

            // For this day there are no registered balances, look for the
            // last recorded balance or zero if there are no previous records
            // per requested day
            var index = -1
            var hasActivity = false
            for time in self.arrayMap {
                if (time >= time0000  ) {
                    hasActivity = true
                    break
                }
                index = index + 1
            }
            if (index < 0) {
                // No previous activity
                return 0.0
            }
            return self.dictionary[self.arrayMap[index]]!
        }

        pub fun getValueFor(timestamp: UFix64): UFix64 {
            let time0000 = MoxyData.getTimestampTo0000(timestamp: timestamp)
            if (self.dictionary[time0000] == nil) {
                return 0.0
            }
            return self.dictionary[time0000]!
        }

        pub fun getValueForToday(): UFix64 {
            let balance = self.getValueOrMostRecentFor(timestamp: getCurrentBlock().timestamp)
            if (balance == nil) {
                return 0.0
            }
            return balance
        }

        pub fun getValueChangeForToday(): Fix64 {
            return self.getValueChange(timestamp: getCurrentBlock().timestamp)
        }

        // Get the difference between the day (represented by timestamp) with the
        // previous date (previous date could be several days ago, depending on activity)
        pub fun getValueChange(timestamp: UFix64): Fix64 {
            let time0000 = MoxyData.getTimestampTo0000(timestamp: timestamp)

            if (self.dictionary.length < 1) {
                // No records > no change
                return 0.0
            }
            if (self.arrayMap[0] > time0000 ) {
                // Date is previous to the first registered
                return 0.0
            }
            var lastTimestamp = self.getLastKeyAdded()
            if (time0000 > lastTimestamp!) {
                // Date is over last timestamp
                return 0.0
            }

            // Balance en la fecha consultada
            var timestamp = self.dictionary[time0000]
            
            if (timestamp == nil) {
                // No records > no changes
                return 0.0
            }

            // Look for last balance
            if (self.arrayMap[0] == time0000 ) {
                // No previous > change is balance total
                return Fix64(timestamp!)
            }

            // There is a balance, we have to look for the previous balance to see
            // what was the change
            // search
            var index = 0
            for time in self.arrayMap {
                if (time == time0000) {
                    break
                }
                index = index + 1
            }
            let indexBefore = index - 1
            var timestampBefore = self.dictionary[self.arrayMap[indexBefore]]

            return Fix64(timestamp!) - Fix64(timestampBefore!)
        }

        pub fun getValueChanges(): {UFix64:UFix64} {
            return self.getValueChangesUpTo(timestamp: getCurrentBlock().timestamp)
        }

        pub fun getValueChangesUpTo(timestamp: UFix64): {UFix64:UFix64} {
            let resu: {UFix64:UFix64} = {}
            var amountBefore = 0.0
            var timeBefore = 0.0
            var remaining = 0.0

            for time in self.arrayMap {
                if (time > timestamp) {
                    // If timestamp
                    continue
                }
                if (self.dictionary[time]! > amountBefore ) {
                    let amount = self.dictionary[time]! - amountBefore

                    // Add to dictionary
                    resu[time] = amount
                } else {
                    // Changes are negative
                    remaining = remaining + amountBefore - self.dictionary[time]!
                }
                if (remaining > 0.0 && resu[timeBefore] != nil) {
                    if (resu[timeBefore]! > remaining) {
                        resu[timeBefore] = resu[timeBefore]! - remaining
                        remaining = 0.0
                    } else {
                        let amnt = resu[timeBefore]!
                        resu.remove(key: timeBefore) ?? nil
                        remaining = remaining - amnt
                    }
                }
                amountBefore = self.dictionary[time]!
                timeBefore = time
            }
            for time in resu.keys {
                if (remaining == 0.0) {
                    break
                }
                if (resu[time]! > remaining) {
                    resu[time] = resu[time]! - remaining
                    remaining = 0.0
                } else {
                    let amnt = resu[time]!
                    resu.remove(key: time) ?? nil
                    remaining = remaining - amnt
                }
            }

            return resu
        }

        pub fun getLastKeyAdded(): UFix64? {
            let pos = self.dictionary.length - 1
            if (pos < 0) {
                return nil
            }
            return self.arrayMap[pos]
        }

        pub fun getFirstKeyAdded(): UFix64? {
            if (self.arrayMap.length == 0) {
                return nil
            }
            return self.arrayMap[0]
        }

        pub fun getLastValue(): UFix64 {
            let pos = self.dictionary.length - 1
            if (pos < 0) {
                return 0.0
            }
            return self.dictionary[self.arrayMap[pos]!]!
        }

        pub fun setAmountFor(timestamp: UFix64, amount: UFix64) {
            let time0000 = MoxyData.getTimestampTo0000(timestamp: timestamp)
            let lastTimestamp = self.getLastKeyAdded()

            // Check if timestamp to add exists and that is greater than
            // the last timestamp added, to keep order on arrayMap
            if (lastTimestamp == nil || time0000 > lastTimestamp! || self.dictionary[time0000] == nil) {
                // Assign last value as initial amount for required timestamp
                self.dictionary[time0000] = self.getLastValue()
                self.arrayMap.append(time0000)
            }
            self.addAge(timestamp: time0000, amount: amount)
            self.dictionary[time0000] = self.dictionary[time0000]! + amount
        }
        
        pub fun addAge(timestamp: UFix64, amount: UFix64) {
            if (self.ages[timestamp] == nil) {
                self.ages[timestamp] = 0.0
                self.agesMap.append(timestamp)
            }
            self.ages[timestamp] = self.ages[timestamp]! + amount
        }

        pub fun subtractOldestAge(amount: UFix64): {UFix64: UFix64} {
            var amountRemaining = amount
            let dict: {UFix64:UFix64} = {}

            while(amountRemaining > 0.0 && self.agesMap.length > 0) {
                // Always ask for index zero as is the oldest deposit
                let timestamp = self.agesMap[0]
                let balance = self.ages[timestamp]!
                if (amountRemaining > balance ) {
                    //balance of the day is not enough for total withdraw
                    amountRemaining = amountRemaining - balance
                    //remove daily balance
                    self.ages.remove(key: timestamp)
                    self.agesMap.remove(at: 0)
                    dict[timestamp] = balance
                } else {
                    //balance is enough to complete total withdraw
                    self.ages[timestamp] = self.ages[timestamp]! - amountRemaining
                    dict[timestamp] = amountRemaining
                    amountRemaining = 0.0
                }
            }
            if (amountRemaining > 0.0) {
                panic("Not enough amount to withdraw from dictionary.")
            }
            return dict
        }


        pub fun canUpdateTo(timestamp: UFix64): Bool {

            let time0000 = MoxyData.getTimestampTo0000(timestamp: timestamp)
            let lastTimestamp = self.getLastKeyAdded()

            // Returns true if there are no registered timestamp yet or
            // if the time to add is equal or greater than the las timestamp added.
            return lastTimestamp == nil || time0000 >= lastTimestamp!
        }

        pub fun withdrawValueFromOldest(amount: UFix64): {UFix64: UFix64} {
            let time0000 = MoxyData.getTimestampTo0000(timestamp: getCurrentBlock().timestamp)
            let lastTimestamp = self.getLastKeyAdded()
            let value = self.getLastValue()

            if (value < amount) {
                panic("Not enough amount to withdraw from dictionary.")
            }

            let dict = self.subtractOldestAge(amount: amount)
            for time in dict.keys {
                self.dictionary[time] = self.dictionary[time]! - dict[time]!
            }

            return dict
        }

        pub fun destroyWith(orderedDictionary: @OrderedDictionary) {
            let dict = orderedDictionary.getDictionary()
            for timestamp in dict.keys {
                if (self.dictionary[timestamp] != nil) {
                    self.dictionary[timestamp] = self.dictionary[timestamp]! - dict[timestamp]!
                }
            }

            destroy orderedDictionary
        }


        init() {
            self.dictionary = {}
            self.arrayMap = []
            self.ages = {}
            self.agesMap = []
        }

    }

    pub resource interface OrderedDictionaryInfo {
        pub fun getDictionary(): {UFix64: UFix64}
    }

    pub fun getTimestampTo0000(timestamp: UFix64): UFix64 {
        let dayInSec = 86400.0
        let days = timestamp / dayInSec
        return UFix64(UInt64(days)) * dayInSec
    }

    pub fun createNewOrderedDictionary(): @OrderedDictionary {
        return <-create OrderedDictionary()
    }

    
    init() {
    }
}
 
