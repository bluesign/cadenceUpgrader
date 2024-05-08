pub contract MarketplaceCleaner {

    pub var removed: {UInt64: UInt64}

    pub event MarketplaceCleanerCleaned(storefrontResourceID: UInt64, nftId: UInt64)

    init () {
        self.removed = {}
    }

    pub fun clean(storefrontResourceID: UInt64, nftId: UInt64) {
        self.removed[nftId] = storefrontResourceID
        emit MarketplaceCleanerCleaned(storefrontResourceID: storefrontResourceID, nftId: nftId)
    }
}
