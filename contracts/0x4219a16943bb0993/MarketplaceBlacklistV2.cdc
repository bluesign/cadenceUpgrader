pub contract MarketplaceBlacklistV2 {

    pub let AdminStoragePath: StoragePath

    // listingId : nftId
    priv let blacklist: {UInt64: UInt64}

    pub event MarketplaceBlacklistAdd(listingId: UInt64, nftId: UInt64)

    pub event MarketplaceBlacklistRemove(listingId: UInt64, nftId: UInt64)

    pub resource Administrator {
        
        pub fun add(listingId: UInt64, nftId: UInt64) {
            MarketplaceBlacklistV2.blacklist[listingId] = nftId
            emit MarketplaceBlacklistAdd(listingId: listingId, nftId: nftId)
        }

        pub fun remove(listingId: UInt64) {
            pre {
                MarketplaceBlacklistV2.blacklist[listingId] != nil: "listingId not exist"
            }
            let nftId = MarketplaceBlacklistV2.blacklist.remove(key: listingId)
            if let unwrappedNftId = nftId {
                emit MarketplaceBlacklistRemove(listingId: listingId, nftId: unwrappedNftId)
            }
            assert(nftId != nil, message: "Not been removed successfully!")
        }
        
    }

    init () {
        self.blacklist = {}
        self.AdminStoragePath = /storage/marketplaceBlacklistV2

        let admin <- create Administrator()
        self.account.save(<-admin, to: self.AdminStoragePath)
    }

    pub fun exist(listingId: UInt64): Bool {
        return self.blacklist.containsKey(listingId)
    }

    pub fun getAmount(): Int {
        return self.blacklist.length
    }

}
