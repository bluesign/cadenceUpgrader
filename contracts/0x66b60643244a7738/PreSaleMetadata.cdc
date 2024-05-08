pub contract PreSaleMetadata {
    // Event definitions
    pub event MetadataAdded(id: UInt64, userAddress: Address, amount: UFix64, timeStamp: String, txID: String)
    pub event MetadataRemoved(id: UInt64)

    // Definition of Metadata
    pub struct Metadata {
        pub let id: UInt64
        pub let userAddress: Address
        pub let amount: UFix64
        pub let timeStamp: String
        pub let txID: String

        init(id: UInt64, userAddress: Address, amount: UFix64, timeStamp: String, txID: String) {
            self.id = id
            self.userAddress = userAddress
            self.amount = amount
            self.timeStamp = timeStamp
            self.txID = txID
        }
    }

    // Store for the metadata
    pub var metadataRecords: {UInt64: Metadata}

    // Global ID counter for unique metadata records
    pub var nextId: UInt64

    // Function to add pre-sale metadata
    pub fun addMetadata(userAddress: Address, amount: UFix64, timeStamp: String, txID: String) {
        let newMetadata = Metadata(id: self.nextId, userAddress: userAddress, amount: amount, timeStamp: timeStamp, txID: txID)
        self.metadataRecords[self.nextId] = newMetadata

        // Emit an event when metadata is added
        emit MetadataAdded(id: self.nextId, userAddress: userAddress, amount: amount, timeStamp: timeStamp, txID: txID)

        self.nextId = self.nextId + 1
    }

    // Function to remove pre-sale metadata by transaction ID
    pub fun removeMetadataByTxID(txIDToRemove: String) {
        var keyToRemove: UInt64? = nil
        for key in self.metadataRecords.keys {
            if self.metadataRecords[key]!.txID == txIDToRemove {
                keyToRemove = key
                break // Stop at the first match found
            }
        }
        
        if let key = keyToRemove {
            self.metadataRecords.remove(key: key)
            emit MetadataRemoved(id: key)
        }
    }

    init() {
        self.metadataRecords = {}
        self.nextId = 0
    }
}
