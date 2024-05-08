pub contract MarketplaceCleaner {

    pub event MarketplaceCleanerCleaned(storefrontResourceID: UInt64, nftId: UInt64)

    init () {}

    pub fun clean(storefrontResourceID: UInt64, nftId: UInt64) {
        emit MarketplaceCleanerCleaned(storefrontResourceID: storefrontResourceID, nftId: nftId)
    }
}
