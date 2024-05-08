pub contract BidMetadata {
    // Event definitions
    pub event MetadataAdded(id: UInt64, userAddress: Address, auctionType: String, currentBid: UFix64, timeStamp: String, txID: String)
    pub event MetadataRemoved(id: UInt64)

    pub struct Metadata {
        pub let id: UInt64
        pub let userAddress: Address
        pub let auctionType: String
        pub let currentBid: UFix64
        pub let timeStamp: String
        pub let txID: String

        init(id: UInt64, userAddress: Address, auctionType: String, currentBid: UFix64, timeStamp: String, txID: String) {
            self.id = id
            self.userAddress = userAddress
            self.auctionType = auctionType
            self.currentBid = currentBid
            self.timeStamp = timeStamp
            self.txID = txID
        }
    }

    // Store for the metadata
    pub var metadataRecords: {UInt64: Metadata}

    // Global ID counter
    pub var nextId: UInt64

    pub fun addMetadata(userAddress: Address, auctionType: String, currentBid: UFix64, timeStamp: String, txID: String) {
        let newMetadata = Metadata(id: self.nextId, userAddress: userAddress, auctionType: auctionType, currentBid: currentBid, timeStamp: timeStamp, txID: txID)
        self.metadataRecords[self.nextId] = newMetadata

        // Emitting an event for adding metadata
        emit MetadataAdded(id: self.nextId, userAddress: userAddress, auctionType: auctionType, currentBid: currentBid, timeStamp: timeStamp, txID: txID)

        self.nextId = self.nextId + 1
    }

    pub fun removeMetadataByTxID(txIDToRemove: String) {
        var keyToRemove: UInt64? = nil
        for key in self.metadataRecords.keys {
            if self.metadataRecords[key]!.txID == txIDToRemove {
                keyToRemove = key
                break // Assuming you want to remove the first match
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
