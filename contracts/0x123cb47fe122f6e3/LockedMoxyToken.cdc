import MoxyToken from "./MoxyToken.cdc"
import LinearRelease from "./LinearRelease.cdc"
import MoxyData from "./MoxyData.cdc"
 

pub contract LockedMoxyToken {

    pub var totalSupply: UFix64

    /// LockedTokensWithdrawn
    ///
    /// The event that is emitted when locked tokens are withdrawn from a Vault
    /// due to an MV to MOX convert request
    pub event LockedTokensWithdrawn(amount: UFix64, from: Address?)

    pub struct FixedBalance {
        // This is the schedule of how the tokens will be unlock
        pub var schedule: LinearRelease.LinearSchedule

        // This is the amount that is remaining to unlock
        pub var remaining: UFix64

        pub fun getBalanceRemaining(): UFix64 {
            return self.remaining
        }

        pub fun unlockAmounts(): UFix64 {
            if (self.remaining == 0.0) {
                return 0.0
            }
            
            var amount = self.schedule.getDailyAmountToPay()

            // Check for remainings
            if (amount > self.remaining) {
                log("Negative amount: ".concat(amount.toString()).concat(" self.remaining ").concat(self.remaining.toString()))
                amount = self.remaining
            }
            if ((self.remaining - amount) < 0.001) {
                // Set the residual
                amount = self.remaining
            }

            self.remaining = self.remaining - amount
            self.schedule.updateLastReleaseDate()

            return amount
        }

        pub fun splitWith(amount: UFix64): LinearRelease.LinearSchedule {
            pre {
                amount < self.remaining : "Not enough amount to split"
            }

            let schedule = self.schedule.splitWith(amount: amount)
            
            self.remaining = self.remaining - amount

            return schedule
            
        }

        init(schedule: LinearRelease.LinearSchedule, remaining: UFix64) {
            self.schedule = schedule
            self.remaining = remaining
        }
    }

    pub resource ConversionRequest {
        access(contract) var vault: @MoxyToken.Vault
        access(contract) var fixedAmount: UFix64
        access(contract) var schedule: {UFix64:UFix64}
        access(contract) var fixedSchedules: [FixedBalance]
        pub var address: Address

        access(account) fun withdraw(): @MoxyToken.Vault {
            let vault <- self.vault.withdraw(amount: self.vault.balance) as! @MoxyToken.Vault
            LockedMoxyToken.totalSupply = LockedMoxyToken.totalSupply - vault.balance
            return <- vault
        }

        pub fun getSchedule(): {UFix64: UFix64} {
            return self.schedule
        }

        pub  fun getFixedSchedules(): [FixedBalance] {
            return self.fixedSchedules
        }

        pub  fun getFixedAmount(): UFix64 {
            return self.fixedAmount
        }

        pub  fun getBalance(): UFix64 {
            return self.vault.balance
        }

        init(vault: @MoxyToken.Vault, fixedAmount: UFix64, schedule: {UFix64:UFix64}, fixedSchedules: [FixedBalance], address: Address) {
            self.vault <- vault
            self.fixedAmount = fixedAmount
            self.schedule = schedule
            self.fixedSchedules = fixedSchedules
            self.address = address
        }

        destroy() {
            destroy self.vault
        }

    }


    pub resource LockedVault: Receiver, Balance {
        access(contract) var lockedBalances: {UFix64:UFix64}
        access(contract) var lockedFixedBalances: [FixedBalance]
        access(contract) var vault: @MoxyToken.Vault

        pub fun getBalance():UFix64 {
            return self.vault.balance
        }

        pub fun isValutBalanceOk(): Bool {
            var locked = 0.0
            var lockedFixed = 0.0

            locked = self.sumLockedBalances()
            lockedFixed = self.sumLockedFixedBalances()

            let total = locked + lockedFixed

            let diff: Fix64 = Fix64(self.vault.balance) - Fix64(total)
            
            return self.vault.balance == total
        }

        pub fun deposit(from: @MoxyToken.Vault) {
            self.depositFor(from: <-from, time: getCurrentBlock().timestamp)
        }

        pub fun depositFor(from: @MoxyToken.Vault, time: UFix64) {
            post {
                self.isValutBalanceOk() : "Vault balance does not fit with locked and locked fixed balances"
            }

            let amount = from.balance
            self.vault.deposit(from: <-from) 

            if (self.lockedBalances[time] == nil) {
                self.lockedBalances[time] = 0.0
            } 
            self.lockedBalances[time] = self.lockedBalances[time]! + amount
            LockedMoxyToken.totalSupply = LockedMoxyToken.totalSupply + amount
        }

        pub fun depositFromFixedSchedule(from: @MoxyToken.Vault, schedule: LinearRelease.LinearSchedule) {
            post {
                self.isValutBalanceOk() : "Vault balance does not fit with locked and locked fixed balances"
            }
            
            let total = from.balance

            self.vault.deposit(from: <-from)

            let time = getCurrentBlock().timestamp

            let fixedBalance = FixedBalance(schedule: schedule, remaining: total)
            self.lockedFixedBalances.append(fixedBalance)

            LockedMoxyToken.totalSupply = LockedMoxyToken.totalSupply + total
        }

        pub fun depositFromSchedule(from: @MoxyToken.Vault, schedule: {UFix64:UFix64}) {
            post {
                self.isValutBalanceOk() : "Vault balance does not fit with locked and locked fixed balances"
            }

            let total = from.balance
            self.vault.deposit(from: <-from)

            let ti = getCurrentBlock().timestamp

            // Merge schedules with existing lockedBalances
            for time in schedule.keys {
                if (self.lockedBalances[time] == nil) {
                    self.lockedBalances[time] = 0.0
                }
                self.lockedBalances[time] = self.lockedBalances[time]! + schedule[time]!
            }

            LockedMoxyToken.totalSupply = LockedMoxyToken.totalSupply + total
        }

        pub fun sumLockedBalances(): UFix64 {
            var total = 0.0
            for value in self.lockedBalances.values {
                total = total + value
            }
            return total
        }

        pub fun sumLockedFixedBalances(): UFix64 {
            var total = 0.0
            for fixed in self.lockedFixedBalances {
                total = total + fixed.getBalanceRemaining()
            }
            return total
        }

        pub fun createConversionRequest(amount: UFix64): @ConversionRequest {
            pre {
                amount <= self.vault.balance : "Not enough balance to convert."
            }
            post {
                self.isValutBalanceOk() : "Vault balance does not fit with locked and locked fixed balances"
            }

            let keys = self.lockedBalances.keys
            var i = 0
            var lbTotal = 0.0
            var remaining = amount - lbTotal
            var schedule: {UFix64:UFix64} = {}

            // Take the part from lockedBalances
            while (i < keys.length && remaining > 0.0) {
                let key = keys[i]
                let value = self.lockedBalances[key]!
                var amnt = 0.0
                if (value > remaining) {
                    // Cover all with this balance
                    amnt = remaining
                    self.lockedBalances[key] = value - amnt
                } else {
                    amnt = value
                    self.lockedBalances.remove(key: key)
                }
                schedule[key] = amnt
                lbTotal = lbTotal + amnt
                remaining = amount - lbTotal
                i = i + 1
            }

            // If remaining amounts, then use the fixedBalances 
            var fxTotal = 0.0
            let fixedSchedules: [FixedBalance] = []
            if (remaining > 0.0) {
                // Sacar amount y ajustar fixedBalances
                i = 0
                while (i < self.lockedFixedBalances.length && remaining > 0.0) {
                    var sche: LinearRelease.LinearSchedule? = nil
                    var amnt = 0.0
                    if (self.lockedFixedBalances[i].remaining > remaining) {
                        amnt = remaining
                        sche = self.lockedFixedBalances[i].splitWith(amount: amnt)
                        i = i + 1
                        fxTotal = fxTotal + amnt
                        remaining = 0.0
                    } else {
                        sche = self.lockedFixedBalances[i].schedule
                        amnt = self.lockedFixedBalances[i].remaining
                        fxTotal = fxTotal + amnt
                        remaining = remaining - amnt
                        self.lockedFixedBalances.remove(at: i)
                    }

                    fixedSchedules.append(FixedBalance(schedule: sche!, remaining: amnt))
                }
            }
            let total = lbTotal + fxTotal
            if (remaining > 0.0 || amount != total) {
                panic("Error can't convert, get remainings or totals mismatch")
            }

            emit LockedTokensWithdrawn(amount: amount, from: self.owner?.address)
            
            let vault <- self.vault.withdraw(amount: amount) as! @MoxyToken.Vault

            return <-create ConversionRequest(vault: <- vault, fixedAmount: fxTotal, 
                                schedule: schedule, fixedSchedules: fixedSchedules, address: self.owner!.address)
        }

        // Withdraws the tokens that are available to unlock
        pub fun withdrawUnlocked(): @MoxyToken.Vault {
            post {
                self.isValutBalanceOk() : "Vault balance does not fit with locked and locked fixed balances"
            }

            let temp = self.lockedBalances
            var total = 0.0
            var totalLocked = 0.0
            let dict = self.getUnlockBalancesFor(days: 0.0)

            for key in dict.keys {
                let value = dict[key]!
                let amount = self.lockedBalances[key]!
                self.lockedBalances.remove(key: key)
                totalLocked = totalLocked + amount
            }

            // Unlock fixed amounts
            var totalFixed = 0.0
            var i = 0
            while (i < self.lockedFixedBalances.length) {
                let amount = self.lockedFixedBalances[i].unlockAmounts()
                totalFixed = totalFixed + amount
                i = i + 1
            }

            total = totalLocked + totalFixed
            
            LockedMoxyToken.totalSupply = LockedMoxyToken.totalSupply - total

             if (self.vault.balance < total) {
                let diff = total - self.vault.balance
                if (diff > 1.0) {
                    panic("Error vault does not have enough balance")
                }
                total = self.vault.balance
            }

            if (self.vault.balance > total) {
                let diff = self.vault.balance - total
                if (diff < 0.001) {
                    // Set the residual on vault
                    total = self.vault.balance
                }
            }

            let vault <- self.vault.withdraw(amount: total) as! @MoxyToken.Vault
            return <- vault
        }

        pub fun getTotalLockedBalance(): UFix64 {
            return self.vault.balance
        }

        pub fun getTotalToUnlockBalanceFor(days: UFix64): UFix64 {
            // Returns the amount that will be unlocked in the next few days
            var total = 0.0
            var timestamp = getCurrentBlock().timestamp + (days * 86400.0)
            for key in self.lockedBalances.keys {
                if (key < timestamp) {
                    let value = self.lockedBalances[key]!
                    total = total + value
                }
            }
            return total
        }

        pub fun getUnlockBalancesFor(days: UFix64): {UFix64:UFix64} {
            // Returns a dictionary with the amounts that will be unlocked in the next few days
            var dict: {UFix64:UFix64} = {} 
            var timestamp = getCurrentBlock().timestamp + (days * 86400.0)
            for key in self.lockedBalances.keys {
                if (key < timestamp) {
                    dict[key] = self.lockedBalances[key]! 
                }
            }
            return dict
        }

        init(vault: @MoxyToken.Vault) {
            self.lockedBalances = {}
            self.lockedFixedBalances = []
            self.vault <- vault
        }

        destroy() {
            destroy self.vault
        }
    }

    pub resource interface Receiver {
        /// deposit takes a Vault and deposits it into the implementing resource type
        ///
        pub fun deposit(from: @MoxyToken.Vault)
        pub fun depositFor(from: @MoxyToken.Vault, time: UFix64)
        pub fun depositFromSchedule(from: @MoxyToken.Vault, schedule: {UFix64:UFix64})
        pub fun depositFromFixedSchedule(from: @MoxyToken.Vault, schedule: LinearRelease.LinearSchedule)
    }

    pub resource interface Balance {

        /// The total balance of a vault
        ///
        pub fun getBalance():UFix64
        pub fun getTotalToUnlockBalanceFor(days: UFix64): UFix64 
        pub fun getTotalLockedBalance(): UFix64 
    }

    pub fun createLockedVault(vault: @MoxyToken.Vault): @LockedVault {
        return <-create LockedVault(vault: <-vault)
    }

    init() {
        self.totalSupply = 0.0
    }

}
 
