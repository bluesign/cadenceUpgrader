access(all)
contract MarketplaceBlacklistV2{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	// listingId : nftId
	access(self)
	let blacklist:{ UInt64: UInt64}
	
	access(all)
	event MarketplaceBlacklistAdd(listingId: UInt64, nftId: UInt64)
	
	access(all)
	event MarketplaceBlacklistRemove(listingId: UInt64, nftId: UInt64)
	
	access(all)
	resource Administrator{ 
		access(all)
		fun add(listingId: UInt64, nftId: UInt64){ 
			MarketplaceBlacklistV2.blacklist[listingId] = nftId
			emit MarketplaceBlacklistAdd(listingId: listingId, nftId: nftId)
		}
		
		access(all)
		fun remove(listingId: UInt64){ 
			pre{ 
				MarketplaceBlacklistV2.blacklist[listingId] != nil:
					"listingId not exist"
			}
			let nftId = MarketplaceBlacklistV2.blacklist.remove(key: listingId)
			if let unwrappedNftId = nftId{ 
				emit MarketplaceBlacklistRemove(listingId: listingId, nftId: unwrappedNftId)
			}
			assert(nftId != nil, message: "Not been removed successfully!")
		}
	}
	
	init(){ 
		self.blacklist ={} 
		self.AdminStoragePath = /storage/marketplaceBlacklistV2
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
	}
	
	access(all)
	fun exist(listingId: UInt64): Bool{ 
		return self.blacklist.containsKey(listingId)
	}
	
	access(all)
	fun getKeysAmount(): Int{ 
		return self.blacklist.keys.length
	}
}
