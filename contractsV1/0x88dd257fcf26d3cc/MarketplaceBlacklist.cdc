access(all)
contract MarketplaceBlacklist{ 
	
	// listingId : nftId
	access(all)
	let blacklist:{ UInt64: UInt64}
	
	access(all)
	event MarketplaceBlacklistAdd(listingId: UInt64, nftId: UInt64)
	
	access(all)
	event MarketplaceBlacklistRemove(listingId: UInt64, nftId: UInt64)
	
	init(){ 
		self.blacklist ={} 
	}
	
	access(all)
	fun exist(listingId: UInt64): Bool{ 
		return self.blacklist.containsKey(listingId)
	}
	
	access(all)
	fun add(listingId: UInt64, nftId: UInt64){ 
		self.blacklist[listingId] = nftId
		emit MarketplaceBlacklistAdd(listingId: listingId, nftId: nftId)
	}
	
	access(all)
	fun remove(listingId: UInt64){ 
		pre{ 
			self.blacklist[listingId] != nil:
				"listingId not exist"
		}
		let nftId = self.blacklist.remove(key: listingId)
		if let unwrappedNftId = nftId{ 
			emit MarketplaceBlacklistRemove(listingId: listingId, nftId: unwrappedNftId)
		}
		assert(nftId != nil, message: "Not been removed successfully!")
	}
}
