access(all)
contract MarketplaceCleaner{ 
	access(all)
	var removed:{ UInt64: UInt64}
	
	access(all)
	event MarketplaceCleanerCleaned(storefrontResourceID: UInt64, nftId: UInt64)
	
	init(){ 
		self.removed ={} 
	}
	
	access(all)
	fun clean(storefrontResourceID: UInt64, nftId: UInt64){ 
		self.removed[nftId] = storefrontResourceID
		emit MarketplaceCleanerCleaned(storefrontResourceID: storefrontResourceID, nftId: nftId)
	}
}
