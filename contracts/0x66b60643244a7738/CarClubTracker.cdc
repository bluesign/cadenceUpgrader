pub contract CarClubTracker {

    pub struct PurchaseRecord {
        pub let id: UInt64
        pub let userAddress: Address
        pub let itemType: String // "Single" or "Pack"
        pub let rollout: String

        init(_ id: UInt64, userAddress: Address, itemType: String, rollout: String) {
            self.id = id
            self.userAddress = userAddress
            self.itemType = itemType
            self.rollout = rollout
        }
    }

    // Store for the purchase records
    pub var purchaseRecords: {UInt64: PurchaseRecord}

    // Global ID counter for purchase records
    pub var nextId: UInt64

    // Function to add a new purchase record
    pub fun addPurchase(userAddress: Address, itemType: String, rollout: String) {
        let newPurchase = PurchaseRecord(self.nextId, userAddress: userAddress, itemType: itemType, rollout: rollout)
        self.purchaseRecords[self.nextId] = newPurchase
        self.nextId = self.nextId + 1
    }

    init() {
        self.purchaseRecords = {}
        self.nextId = 0
    }
}