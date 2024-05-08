import MoxyData from "./MoxyData.cdc"
 

pub contract MoxyProcessQueue {
    pub event MoxyQueueSelected(queueNumber: Int)
    pub event RunCompleted(processed: Int)

    pub resource Run {
        pub var runId: Int
        pub var indexStart: Int
        pub var indexEnd: Int
        pub var index: Int
        pub var currentAddresses: [Address]
        pub var isFinished: Bool

        pub fun isAtBeginning(): Bool {
            return self.index == self.indexStart
        }

        pub fun getCurrentAddresses(): [Address] {
            return self.currentAddresses
        }

        pub fun getBounds(): [Int] {
            return [self.index, self.indexEnd]
        }

        pub fun setCurrentAddresses(addresses: [Address]) {
            self.currentAddresses = addresses
        }

        pub fun setIndex(index: Int) {
            self.index = index
        }

        pub fun complete(): Int {
            let processed = self.currentAddresses.length
            emit RunCompleted(processed: processed)
            self.index = self.index + processed
            if (self.index > self.indexEnd) {
                self.isFinished = true
            }
            self.currentAddresses = []
            return processed
        }

        pub fun getRemainings(): Int {
            return self.indexEnd - self.index + 1
        }

        init(runId: Int, indexStart: Int, indexEnd: Int) {
            self.runId = runId
            self.indexStart = indexStart
            self.indexEnd = indexEnd
            self.index = indexStart
            self.currentAddresses = []
            self.isFinished = false
        }

    }

    pub struct CurrentRunStatus {
        pub var totalAccounts: Int
        pub var startTime: UFix64
        pub var lastUpdated: UFix64
        pub var accountsProcessed: Int
        pub var accountsRemaining: Int
        pub var hasFinished: Bool

        init(totalAccounts: Int, startTime: UFix64, lastUpdated: UFix64, accountsProcessed: Int, accountsRemaining: Int, hasFinished: Bool) {
            self.totalAccounts = totalAccounts
            self.startTime = startTime
            self.lastUpdated = lastUpdated
            self.accountsProcessed = accountsProcessed
            self.accountsRemaining = accountsRemaining
            self.hasFinished = hasFinished
        }
    }

    pub resource QueueBatch {
        access(contract) var currentRuns: @[Run?]
        pub var startTime: UFix64
        pub var startTime0000: UFix64
        pub var lastUpdateTime: UFix64
        pub var endTime: UFix64
        pub var executions: Int
        pub var runSize: Int
        pub var accountsToProcess: Int
        pub var accountsProcessed: Int
        pub var isStarted: Bool

        access(contract) fun start(accounts: Int) {
            pre {
                !self.isStarted : "Queues is already started."
            }

            if (accounts == 0) {
                self.startTime  = 0.0
                self.startTime0000 = 0.0
                self.accountsToProcess = 0
                self.accountsProcessed = 0
                return 
            }

            self.accountsToProcess = accounts

            var i = 0
            var incrFl = UFix64(accounts) / UFix64(self.currentRuns.length)
            if (incrFl - UFix64(Int(incrFl)) > 0.0) {
                incrFl = incrFl + 1.0
            }
            var incr = Int(incrFl)
            if (incr < 1) {
                incr = 1
            }
            var indexStart = 0
            var indexEnd = 0

            while (i < self.currentRuns.length && indexStart < accounts) {
                indexEnd = indexStart + incr
                let rem = accounts - indexEnd
                if (rem < incr) {
                    indexEnd = accounts - 1
                }
                let run <- self.currentRuns[i] <- create Run(runId: i, indexStart: indexStart, indexEnd: indexEnd)
                destroy run
                i = i + 1
                indexStart = indexEnd + 1
            }
            self.isStarted = true
        }

        pub fun setRunSize(quantity: Int) {
            pre {
                quantity > 0 : "Run size must be greater than 0"
                quantity < 2 : "Run size must be lower than 2"
            }
            var i = 0
            var temp: @[Run?] <- []
            while ( i < quantity) {
                temp.append(nil)
                i = i + 1
            }
            self.currentRuns <-> temp

            // Elements on temp will be nil as the queue is not running
            destroy temp
        }

        pub fun isAtBeginning(): Bool {
            var isBeginning = true
            var i = 0
            while (i < self.currentRuns.length && self.currentRuns[i] != nil && self.currentRuns[i]?.isAtBeginning()!) {
                i = i + 1
            }
            return i > self.currentRuns.length
        }

        pub fun hasFinished(): Bool {
            return self.accountsToProcess > 0 && self.accountsProcessed == self.accountsToProcess
        }

        pub fun getFreeRun(): @Run? {
            var tries = 0
            var i = 0
            var run: @Run? <- nil

            while (i < self.currentRuns.length && run == nil) {
                if (self.currentRuns[i] != nil && !self.currentRuns[i]?.isFinished!) {
                    run <-! create Run(runId: i, indexStart: self.currentRuns[i]?.indexStart!, indexEnd: self.currentRuns[i]?.indexEnd!)
                    run?.setIndex(index: self.currentRuns[i]?.index!)
                } else {
                    i = i + 1
                }
            }
            if (run != nil) {
                emit MoxyQueueSelected(queueNumber: i)
            }
            return <- run
        }

        pub fun completeNextAddresses(run: @Run) {
            self.currentRuns[run.runId]?.setCurrentAddresses(addresses: run.getCurrentAddresses())
            self.accountsProcessed = self.accountsProcessed + self.currentRuns[run.runId]?.complete()!
            self.lastUpdateTime = getCurrentBlock().timestamp
            destroy run
        }

        pub fun getRemainings(): Int {
            var total = 0
            var i = 0
            while ( i < self.currentRuns.length) {
                if (self.currentRuns[i] != nil) {
                    total = total + self.currentRuns[i]?.getRemainings()!
                }
                i = i + 1
            }
            return total
        }

        pub fun getRunBounds(): [[Int]] {
            var bounds: [[Int]] = []
            var i = 0
            while ( i < self.currentRuns.length) {
                if (self.currentRuns[i] != nil) {
                    bounds.append(self.currentRuns[i]?.getBounds()!)
                }
                i = i + 1
            }
            return bounds
        }

        pub fun getCurrentRunStatus(): CurrentRunStatus {
            return CurrentRunStatus(totalAccounts: self.accountsToProcess, startTime: self.startTime, 
                        lastUpdated: self.lastUpdateTime, accountsProcessed: self.accountsProcessed, 
                        accountsRemaining: self.getRemainings(), hasFinished: self.hasFinished())
        }

        init(runSize: Int, accounts: Int) {
            self.startTime = getCurrentBlock().timestamp
            self.startTime0000 = MoxyData.getTimestampTo0000(timestamp: getCurrentBlock().timestamp)
            self.lastUpdateTime = getCurrentBlock().timestamp
            self.endTime = 0.0
            self.executions = 0
            self.currentRuns <- [ nil ]
            self.runSize = 1
            self.isStarted = false
            self.accountsToProcess = 0
            self.accountsProcessed = 0
            self.setRunSize(quantity: runSize)
            self.start(accounts: accounts)
        }

        destroy() {
            destroy self.currentRuns
        }

    }

    pub resource Queue: QueueInfo {
        access(contract) var accounts: [Address]
        access(contract) var accountsDict: {Address:Int}
        pub var accountsQuantity: Int
        access(contract) var batchs: @[QueueBatch]
        access(contract) var currentBatch: @QueueBatch
        pub var runSize: Int
        pub var isStarted: Bool

        pub fun addAccount(address: Address) {
            if (self.accountsDict[address] != nil) {
                log("Account already added to queue")
                return
            }
            self.accounts.append(address)
            self.accountsDict[address] = self.accounts.length - 1
            self.accountsQuantity = self.accountsQuantity + 1
        }

        pub fun removeAccount(address: Address) {
            self.accounts[self.accountsDict[address]!] = 0x0
            self.accountsQuantity = self.accountsQuantity - 1
        }
        
        access(contract) fun createNewBatch() {
            if (self.accounts.length < 1) {
                log("No accoutns to process.")
                return
            } 
            let b <- self.currentBatch <- create QueueBatch(runSize: self.runSize, accounts: self.accounts.length)
            self.batchs.append(<-b)

            // Keep only the last 30 runs
            if (self.batchs.length > 30) {
                let r <- self.batchs.removeFirst()
                destroy r
            }
        }


        pub fun getRunSize() :Int {
            return self.runSize
        }

        pub fun setRunSize(quantity: Int) {
            pre {
                quantity > 0 : "Run size must be greater than 0"
                quantity < 2 : "Run size must be lower than 2"
            }
            self.runSize = quantity
        }

         /* Returns true if the current batch is at the beginning */
        pub fun isAtBeginning(): Bool {
            return self.currentBatch.isAtBeginning()
        }

        /* Returns true if the current batch has finished */
        pub fun hasFinished(): Bool {
            return self.currentBatch.hasFinished()
        }

        pub fun isEmptyQueue(): Bool {
            return self.accountsQuantity < 1
        }

        pub fun getAccountsQuantity(): Int {
            return self.accountsQuantity
        }

        pub fun getRemainingAddresses(): [Address] {
            var addrs: [Address] = []
            var bounds = self.currentBatch.getRunBounds()
            var i = 0
            while ( i < bounds.length) {
                let fr = bounds[i][0]
                var to = bounds[i][1] + 1
                addrs = addrs.concat(self.accounts.slice(from: fr, upTo: to) )
                i = i + 1
            }
            return addrs
        }

        pub fun lockRunWith(quantity: Int): @Run? {
            let time0000 = MoxyData.getTimestampTo0000(timestamp: getCurrentBlock().timestamp)
            if ((self.currentBatch.hasFinished() && self.currentBatch.startTime0000 < time0000) || self.currentBatch.accountsToProcess == 0 ) {
                self.createNewBatch()
            }

            let run <- self.currentBatch.getFreeRun()

            if (run != nil) {
                let fr = run?.index!
                var to = fr + quantity
                if (to > run?.indexEnd!) {
                    to = run?.indexEnd! + 1
                }
                let addrs = self.accounts.slice(from: fr, upTo: to)
                run?.setCurrentAddresses(addresses: addrs)
                return <- run
            }
            destroy run
            return nil
        }

        pub fun completeNextAddresses(run: @Run) {
            self.currentBatch.completeNextAddresses(run: <- run)
        }

        pub fun getRemainings(): Int {
            if (self.currentBatch.hasFinished() || self.currentBatch.accountsToProcess < 1) {
                if (self.currentBatch.startTime0000 < (MoxyData.getTimestampTo0000(timestamp: getCurrentBlock().timestamp))) {
                    return self.accounts.length
                }
                return 0
            }
            return self.currentBatch.getRemainings()
        }

        pub fun getCurrentRunStatus(): CurrentRunStatus {
            return self.currentBatch.getCurrentRunStatus()
        }

        init() {
            self.accounts = []
            self.accountsDict = {}
            self.accountsQuantity = 0
            self.batchs <- []
            self.runSize = 1
            self.currentBatch <- create QueueBatch(runSize: 1, accounts: 0)
            self.isStarted = false
        }

        destroy() {
            destroy self.batchs
            destroy self.currentBatch
        }
    }

    pub fun createNewQueue(): @Queue {
        return <- create Queue()
    }

    pub resource interface QueueInfo {
        pub fun getCurrentRunStatus(): CurrentRunStatus
    }
}
 
