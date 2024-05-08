access(all)
contract MarketplaceCleaner{ 
	access(all)
	event MarketplaceCleanerCleaned(storefrontResourceID: UInt64, nftId: UInt64)
	
	init(){} 
	
	access(all)
	fun clean(storefrontResourceID: UInt64, nftId: UInt64){ 
		emit MarketplaceCleanerCleaned(storefrontResourceID: storefrontResourceID, nftId: nftId)
	}
}
