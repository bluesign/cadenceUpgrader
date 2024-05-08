import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract RoyaltiesOverride{ 
	access(all)
	let StoragePath: StoragePath
	
	access(all)
	resource Ledger{ 
		access(account)
		let overrides:{ Type: Bool}
		
		access(all)
		fun set(_ type: Type, _ b: Bool){ 
			self.overrides[type] = b
		}
		
		access(all)
		fun get(_ type: Type): Bool{ 
			return self.overrides[type] ?? false
		}
		
		access(all)
		fun remove(_ type: Type){ 
			self.overrides.remove(key: type)
		}
		
		init(){ 
			self.overrides ={} 
		}
	}
	
	access(all)
	fun get(_ type: Type): Bool{ 
		return (self.account.storage.borrow<&Ledger>(from: RoyaltiesOverride.StoragePath)!).get(
			type
		)
	}
	
	init(){ 
		self.StoragePath = /storage/RoyaltiesOverride
		self.account.storage.save(<-create Ledger(), to: self.StoragePath)
	}
}
