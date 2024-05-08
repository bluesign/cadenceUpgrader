import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MoxyToken from "./MoxyToken.cdc"
 

pub contract PlayAndEarn {
    pub event PlayAndEarnEventCreated(eventCode: String, feeCost: UFix64)
    pub event PlayAndEarnEventParticipantAdded(eventCode: String, addressAdded: Address, feePaid: UFix64)
    pub event PlayAndEarnEventPaymentToAddress(eventCode: String, receiver: Address, amount: UFix64)
    pub event PlayAndEarnEventTokensDeposited(eventCode: String, amount: UFix64)
    
    pub resource PlayAndEarnEcosystem: PlayAndEarnEcosystemInfoInterface {
        access(contract) var events: @{String:PlayAndEarnEvent}

        pub fun getMOXYBalanceFor(eventCode: String): UFix64 {
            return self.events[eventCode]?.getMOXYBalance()!
        }

        pub fun getFeeAmountFor(eventCode: String): UFix64 {
            return self.events[eventCode]?.getFeeAmount()!
        }

        pub fun getParticipantsFor(eventCode: String): [Address] {
            return self.events[eventCode]?.getParticipants()!
        }

        pub fun getPaymentsFor(eventCode: String): {Address: UFix64} {
            return self.events[eventCode]?.getPayments()!
        }

        pub fun getCreatedAt(eventCode: String): UFix64 {
            return self.events[eventCode]?.getCreatedAt()!
        }

        pub fun getAllEvents(): [String] {
            return self.events.keys
        }

        pub fun addParticipantTo(eventCode: String, address: Address, feeVault: @FungibleToken.Vault ) {
            self.events[eventCode]?.addParticipant(address: address, feeVault: <-feeVault.withdraw(amount: feeVault.balance))
            destroy feeVault
        }

        pub fun depositTo(eventCode: String, vault: @FungibleToken.Vault ) {
            self.events[eventCode]?.deposit(vault: <- vault.withdraw(amount: vault.balance))
            destroy vault
        }

        pub fun payToAddressFor(eventCode: String, address: Address, amount: UFix64) {
            self.events[eventCode]?.payToAddress(address: address, amount: amount)
        }

        pub fun addEvent(code: String, feeAmount: UFix64) {
            if (self.events[code] != nil) {
                panic("Event already exists")
            }
            
            self.events[code] <-! create PlayAndEarnEvent(code: code, fee: feeAmount)
            emit PlayAndEarnEventCreated(eventCode: code, feeCost: feeAmount)
        }

        init() {
            self.events <- {}
        }

        destroy() {
            destroy self.events
        }
    }

    pub resource PlayAndEarnEvent {
        pub var code: String
        pub var fee: UFix64
        pub var vault: @FungibleToken.Vault 
        access(contract) var participants: {Address:UFix64}
        access(contract) var payments: {Address:UFix64}
        pub var createdAt: UFix64

        pub fun getFeeAmount(): UFix64 {
            return self.fee
        }

        pub fun getMOXYBalance(): UFix64 {
            return self.vault.balance
        }

        pub fun getParticipants(): [Address] {
            return self.participants.keys
        }

        pub fun getPayments(): {Address: UFix64} {
            return self.payments
        }

        pub fun getCreatedAt(): UFix64 {
            return self.createdAt
        }

        pub fun hasParticipant(address: Address): Bool {
            return self.participants[address] != nil
        }

        pub fun addParticipant(address: Address, feeVault: @FungibleToken.Vault ) {
            let feePaid = feeVault.balance
            self.participants[address] = feePaid
            self.vault.deposit(from: <-feeVault)
            emit PlayAndEarnEventParticipantAdded(eventCode: self.code, addressAdded: address, feePaid: feePaid)
        }

        pub fun deposit(vault: @FungibleToken.Vault) {
            let amount = vault.balance
            self.vault.deposit(from: <-vault)
            emit PlayAndEarnEventTokensDeposited(eventCode: self.code, amount: amount)
        }

        pub fun payToAddress(address: Address, amount: UFix64) {
            // Get the amount from the event vault
            let vault <- self.vault.withdraw(amount: amount)
            
            // Get the recipient's public account object
            let recipient = getAccount(address)

            // Get a reference to the recipient's Receiver
            let receiverRef = recipient.getCapability(MoxyToken.moxyTokenReceiverPath)
                .borrow<&{FungibleToken.Receiver}>()
                ?? panic("Could not borrow receiver reference to the recipient's Vault")

            // Deposit the withdrawn tokens in the recipient's receiver
            receiverRef.deposit(from: <- vault)

            // Register address as payment recipient
            if (self.payments[address] == nil) {
                self.payments[address] = amount
            } else {
                self.payments[address] = self.payments[address]! + amount
            }
            emit PlayAndEarnEventPaymentToAddress(eventCode: self.code, receiver: address, amount: amount)
        }


        init(code:String, fee: UFix64){
            self.code = code
            self.fee = fee
            self.vault <- MoxyToken.createEmptyVault()
            self.participants = {}
            self.payments = {}
            self.createdAt = getCurrentBlock().timestamp
        }

        destroy() {
            destroy self.vault
        }
    }

    pub fun getPlayAndEarnEcosystemPublicCapability(): &PlayAndEarnEcosystem{PlayAndEarnEcosystemInfoInterface} {
        return self.account
                .getCapability(PlayAndEarn.playAndEarnEcosystemPublic)
                .borrow<&PlayAndEarn.PlayAndEarnEcosystem{PlayAndEarnEcosystemInfoInterface}>()!
    }

    pub resource interface PlayAndEarnEcosystemInfoInterface {
        pub fun getMOXYBalanceFor(eventCode: String): UFix64
        pub fun getFeeAmountFor(eventCode: String): UFix64
        pub fun getParticipantsFor(eventCode: String): [Address]
        pub fun getPaymentsFor(eventCode: String): {Address: UFix64}
        pub fun getCreatedAt(eventCode: String): UFix64
        pub fun getAllEvents(): [String]
        pub fun depositTo(eventCode: String, vault: @FungibleToken.Vault )
    }


    pub let playAndEarnEcosystemStorage: StoragePath
    pub let playAndEarnEcosystemPrivate: PrivatePath
    pub let playAndEarnEcosystemPublic: PublicPath

    init(){
        self.playAndEarnEcosystemStorage = /storage/playAndEarnEcosystem
        self.playAndEarnEcosystemPrivate = /private/playAndEarnEcosystem
        self.playAndEarnEcosystemPublic = /public/playAndEarnEcosystem

        let playAndEarnEcosystem <- create PlayAndEarnEcosystem()
        self.account.save(<-playAndEarnEcosystem, to: self.playAndEarnEcosystemStorage)
        self.account.link<&PlayAndEarnEcosystem>(self.playAndEarnEcosystemPrivate, target: self.playAndEarnEcosystemStorage)
        self.account.link<&PlayAndEarnEcosystem{PlayAndEarnEcosystemInfoInterface}>(
            self.playAndEarnEcosystemPublic,
            target: self.playAndEarnEcosystemStorage
        )
    }
}
 
