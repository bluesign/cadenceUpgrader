import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

pub contract FlowLottery {
    pub var totalLotteries: UInt64
    access(self) let pot: @FlowToken.Vault
    // general purpose variables for potentially
    // adding new features & improvements
    // by storing things here.
    access(self) let extra: {String: AnyStruct}
    access(self) let additions: @{String: AnyResource}

    pub let AdminStoragePath: StoragePath

    pub event LotteryWinner(winner: Address, amount: UFix64, winningNumber: UInt64)
    pub event TicketsBought(address: Address, amount: UInt64)
    pub event LotteryReset(newLotteryId: UInt64)
    pub event Donation(amount: UFix64)

    // donate without participating
    pub fun donate(payment: @FlowToken.Vault) {
        pre {
            payment.balance == UFix64(UInt64(payment.balance)): "You must pass in a full number of Flow Tokens."
        }
        emit Donation(amount: payment.balance)
        self.pot.deposit(from: <- payment)
    }

    // buy tickets
    pub fun buyTickets(address: Address, payment: @FlowToken.Vault) {
        pre {
            payment.balance == UFix64(UInt64(payment.balance)): "You must pass in a full number of Flow Tokens."
        }
        let numTickets: UInt64 = UInt64(payment.balance)
        self.pot.deposit(from: <- payment)

        let currentLottery: &LotteryDetails = self.borrowCurrentLotteryDetails() ?? panic("There is no lottery happening right now.")
        currentLottery.addTickets(address: address, numTickets: numTickets)
        emit TicketsBought(address: address, amount: numTickets)
    }

    pub struct Winner {
        pub let address: Address
        pub let flowAmount: UFix64
        pub let timestamp: UFix64
        pub let winningNumber: UInt64

        init(address: Address, flowAmount: UFix64, timestamp: UFix64, winningNumber: UInt64) {
            self.address = address
            self.flowAmount = flowAmount
            self.timestamp = timestamp
            self.winningNumber = winningNumber
        }
    }

    pub resource LotteryDetails {
        pub let id: UInt64
        pub let entries: [Address]
        pub let tickets: {Address: UInt64}
        pub let winners: [Winner]

        access(contract) fun addTickets(address: Address, numTickets: UInt64) {
            self.tickets[address] = (self.tickets[address] ?? 0) + numTickets
            var i: UInt64 = 0
            while i < numTickets {
                self.entries.append(address)
                i = i + 1
            }
        }

        access(contract) fun addWinner(address: Address, amount: UFix64, removeAtIndex: UInt64) {
            self.winners.append(Winner(address: address, flowAmount: amount, timestamp: getCurrentBlock().timestamp, winningNumber: removeAtIndex))
            self.entries.remove(at: removeAtIndex)
            self.tickets[address] = self.tickets[address]! - 1
        }

        init() {
            self.entries = []
            self.tickets = {}
            self.winners = []
            self.id = FlowLottery.totalLotteries
            FlowLottery.totalLotteries = FlowLottery.totalLotteries + 1
        }
    }

    pub resource Admin {
        pub let lotteryHistory: @{UInt64: LotteryDetails}

        // christmas special
        pub fun resolveWinner(): Winner {
            let currentLotteryDetails: &LotteryDetails = self.borrowCurrentLotteryDetails()!
            assert(currentLotteryDetails.entries.length > 0, message: "No one has entered the lottery yet!")
            let numDone: Int = currentLotteryDetails.winners.length
            let percentAmounts: {Int: UFix64} = {
                0: 0.01,
                1: 0.02,
                2: 0.07,
                3: 0.20,
                4: 1.00
            }

            // get amount
            let amount: UFix64 = FlowLottery.pot.balance * percentAmounts[numDone]!
            let hitJackpot: Bool = numDone == 4

            // get the winner
            let randomWinnerIndex: UInt64 = FlowLottery.getRandom(min: 0, max: UInt64(currentLotteryDetails.entries.length) - 1)
            let winner: Address = currentLotteryDetails.entries[randomWinnerIndex]

            // remove rake
            // 2.5% total:
                // 0.5% is for the platform (development + marketing)
                // 2% rollover gets immediately deposited back into the pot for future drawings
            let winnings: @FungibleToken.Vault <- FlowLottery.pot.withdraw(amount: amount)
            let rollover: @FungibleToken.Vault <- winnings.withdraw(amount: amount * 0.02)
            let platformTax: @FungibleToken.Vault <- winnings.withdraw(amount: amount * 0.005)
            let platformVault: &FlowToken.Vault{FungibleToken.Receiver} = FlowLottery.account.getCapability(/public/flowTokenReceiver).borrow<&FlowToken.Vault{FungibleToken.Receiver}>()!
            platformVault.deposit(from: <- platformTax)

            // deposit winnings
            let winnerFlowVault: &FlowToken.Vault{FungibleToken.Receiver} = getAccount(winner).getCapability(/public/flowTokenReceiver)
                                .borrow<&FlowToken.Vault{FungibleToken.Receiver}>()
                                ?? panic("User does not have a Flow Token vault set up.")
            winnerFlowVault.deposit(from: <- winnings)

            // remove winner's ticket and add them as a winner
            currentLotteryDetails.addWinner(address: winner, amount: amount, removeAtIndex: randomWinnerIndex)

            // reset & automatically start a new lottery
            if hitJackpot {
                self.reset()
            }

            // deposit rollover
            FlowLottery.pot.deposit(from: <- rollover)

            emit LotteryWinner(winner: winner, amount: amount, winningNumber: randomWinnerIndex)
            return Winner(address: winner, flowAmount: amount, timestamp: getCurrentBlock().timestamp, winningNumber: randomWinnerIndex)
        }

        access(contract) fun reset() {
            pre {
                FlowLottery.pot.balance == 0.0: "A Jackpot was not hit!"
            }
            let newLotteryDetails: @LotteryDetails <- create LotteryDetails()
            emit LotteryReset(newLotteryId: newLotteryDetails.id)
            self.lotteryHistory[newLotteryDetails.id] <-! newLotteryDetails
        }

        pub fun borrowLotteryDetails(id: UInt64): &LotteryDetails? {
            return &self.lotteryHistory[id] as &LotteryDetails?
        }

        pub fun borrowCurrentLotteryDetails(): &LotteryDetails? {
            return &self.lotteryHistory[FlowLottery.totalLotteries - 1] as &LotteryDetails?
        }

        init() {
            self.lotteryHistory <- {}
        }

        destroy() {
            destroy self.lotteryHistory
        }
    }

    // gets a number between min & max, included
    pub fun getRandom(min: UInt64, max: UInt64): UInt64 {
        let randomNumber: UInt64 = revertibleRandom()
        return (randomNumber % (max + 1 - min)) + min
    }

    pub fun getPotTotal(): UFix64 {
        return self.pot.balance
    }

    pub fun borrowCurrentLotteryDetails(): &LotteryDetails? {
        return self.borrowAdmin().borrowCurrentLotteryDetails()
    }

    access(contract) fun borrowAdmin(): &Admin {
        return self.account.borrow<&FlowLottery.Admin>(from: self.AdminStoragePath)!
    }

    init() {
        self.pot <- FlowToken.createEmptyVault() as! @FlowToken.Vault
        self.totalLotteries = 0
        self.extra = {}
        self.additions <- {}
        self.AdminStoragePath = /storage/FlowLotteryAdmin

        let admin: @Admin <- create Admin()
        admin.reset() // start the first lottery
        self.account.save(<- admin, to: self.AdminStoragePath)
    }
}