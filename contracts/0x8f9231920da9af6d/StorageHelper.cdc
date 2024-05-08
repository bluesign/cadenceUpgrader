import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"

pub contract StorageHelper {

    pub var topUpAmount: UFix64
    pub var topUpThreshold: UInt64

    pub event AccountToppedUp(address: Address, amount: UFix64)

    pub fun availableAccountStorage(address: Address): UInt64 {
        return getAccount(address).storageCapacity - getAccount(address).storageUsed
    }

    access(account) fun topUpAccount(address: Address) {
        let topUpAmount = self.getTopUpAmount()
        let topUpThreshold = self.getTopUpThreshold()
        
        if (StorageHelper.availableAccountStorage(address: address) > topUpThreshold) {
            return
        }

        let vaultRef = self.account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Could not borrow reference to the owner's Vault!")
        let topUpFunds <- vaultRef.withdraw(amount: topUpAmount)
        let receiverRef = getAccount(address)
            .getCapability(/public/flowTokenReceiver)
            .borrow<&{FungibleToken.Receiver}>()
			?? panic("Could not borrow receiver reference to the recipient's Vault")
        receiverRef.deposit(from: <-topUpFunds)

        emit AccountToppedUp(address: address, amount: topUpAmount)
    }

    access(account) fun updateTopUpAmount(amount: UFix64) {
        self.topUpAmount = amount
    }

    access(account) fun updateTopUpThreshold(threshold: UInt64) {
        self.topUpThreshold = threshold
    }

    access(account) fun getTopUpAmount(): UFix64 {
        return 0.000012 // self.topUpAmount //
    }

    access(account) fun getTopUpThreshold(): UInt64 {
        return 1200 // self.topUpThreshold
    }

    init() {
        self.topUpAmount = 0.000012
        self.topUpThreshold = 1200
    }
 }