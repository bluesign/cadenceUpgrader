import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import LilaiQuest from "./LilaiQuest.cdc"
import LilaiMarket from "./LilaiMarket.cdc"

pub contract LilaiBounty {

    pub var questFulfillments: {UInt64: Fulfillment}

    pub struct Fulfillment {
        pub let questId: UInt64
        pub let fulfiller: Address
        pub var submissionMetadata: {String: String}
        pub(set) var status: String
        pub let bounty: UFix64

        init(questId: UInt64, fulfiller: Address, submissionMetadata: {String: String}, bounty: UFix64) {
            self.questId = questId
            self.fulfiller = fulfiller
            self.submissionMetadata = submissionMetadata
            self.status = "Pending"
            self.bounty = bounty
        }
    }

    // Function to submit fulfillment details
    pub fun submitFulfillment(questId: UInt64, fulfiller: Address, submissionMetadata: {String: String}, bounty: UFix64) {
        let newFulfillment = Fulfillment(questId: questId, fulfiller: fulfiller, submissionMetadata: submissionMetadata, bounty: bounty)
        self.questFulfillments[questId] = newFulfillment
    }

    // Function for the requester to approve fulfillment and release bounty
    pub fun approveFulfillment(questId: UInt64, buyer: Address, buyerVaultRef: &FungibleToken.Vault) {
        let fulfillment = self.questFulfillments[questId]!
        assert(fulfillment.status == "Pending", message: "Fulfillment already processed")

        // Withdraw the bounty amount from the buyer's vault
        let bountyVault <- buyerVaultRef.withdraw(amount: fulfillment.bounty)

        // Get the fulfiller's public Vault capability
        let fulfillerVaultCap = getAccount(fulfillment.fulfiller)
                                .getCapability<&FungibleToken.Vault{FungibleToken.Receiver}>(/public/FungibleTokenReceiver)
        
        // Deposit the bounty into the fulfiller's vault
        let fulfillerVaultRef = fulfillerVaultCap.borrow()
                           ?? panic("Could not borrow a reference to the fulfiller's vault")
        fulfillerVaultRef.deposit(from: <-bountyVault)

        fulfillment.status = "Approved"
        emit FulfillmentApproved(questId: questId, fulfiller: fulfillment.fulfiller)
    }

    // Function for the requester to reject fulfillment
    pub fun rejectFulfillment(questId: UInt64, buyer: Address) {
        let fulfillment = self.questFulfillments[questId]!
        assert(fulfillment.status == "Pending", message: "Fulfillment already processed")

        fulfillment.status = "Rejected"
        emit FulfillmentRejected(questId: questId, fulfiller: fulfillment.fulfiller)
    }

    // Events
    pub event FulfillmentApproved(questId: UInt64, fulfiller: Address)
    pub event FulfillmentRejected(questId: UInt64, fulfiller: Address)

    init() {
        self.questFulfillments = {}
    }
}
