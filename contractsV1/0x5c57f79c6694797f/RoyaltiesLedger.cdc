import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract RoyaltiesLedger{ 
	access(all)
	let StoragePath: StoragePath
	
	access(all)
	resource Ledger{ 
		access(account)
		let royalties:{ UInt64: MetadataViews.Royalties}
		
		access(contract)
		fun set(_ id: UInt64, _ r: MetadataViews.Royalties?){ 
			if r == nil{ 
				return
			}
			self.royalties[id] = r
		}
		
		access(contract)
		fun get(_ id: UInt64): MetadataViews.Royalties?{ 
			return self.royalties[id]
		}
		
		access(all)
		fun remove(_ id: UInt64){ 
			self.royalties.remove(key: id)
		}
		
		init(){ 
			self.royalties ={} 
		}
	}
	
	access(account)
	fun set(_ id: UInt64, _ r: MetadataViews.Royalties){ 
		(self.account.storage.borrow<&Ledger>(from: RoyaltiesLedger.StoragePath)!).set(id, r)
	}
	
	access(account)
	fun remove(_ id: UInt64){ 
		(self.account.storage.borrow<&Ledger>(from: RoyaltiesLedger.StoragePath)!).remove(id)
	}
	
	access(all)
	fun get(_ id: UInt64): MetadataViews.Royalties?{ 
		return (self.account.storage.borrow<&Ledger>(from: RoyaltiesLedger.StoragePath)!).get(id)
	}
	
	init(){ 
		self.StoragePath = /storage/RoyaltiesLedger
		self.account.storage.save(<-create Ledger(), to: self.StoragePath)
	}
}
