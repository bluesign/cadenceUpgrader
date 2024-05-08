import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract AACurrencyManager{ 
	access(self)
	var acceptCurrencies: [Type]
	
	access(self)
	let paths:{ String: CurPath}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	struct CurPath{ 
		access(all)
		let publicPath: PublicPath
		
		access(all)
		let storagePath: StoragePath
		
		init(publicPath: PublicPath, storagePath: StoragePath){ 
			self.publicPath = publicPath
			self.storagePath = storagePath
		}
	}
	
	access(all)
	resource Administrator{ 
		access(all)
		fun setAcceptCurrencies(types: [Type]){ 
			for type in types{ 
				assert(type.isSubtype(of: Type<@{FungibleToken.Vault}>()), message: "Should be a sub type of FungibleToken.Vault")
			}
			AACurrencyManager.acceptCurrencies = types
		}
		
		access(all)
		fun setPath(type: Type, path: CurPath){ 
			AACurrencyManager.paths[type.identifier] = path
		}
	}
	
	access(all)
	fun getAcceptCurrentcies(): [Type]{ 
		return self.acceptCurrencies
	}
	
	access(all)
	fun isCurrencyAccepted(type: Type): Bool{ 
		return self.acceptCurrencies.contains(type)
	}
	
	access(all)
	fun getPath(type: Type): CurPath?{ 
		return self.paths[type.identifier]
	}
	
	init(){ 
		self.acceptCurrencies = []
		self.paths ={} 
		self.AdminStoragePath = /storage/AACurrencyManagerAdmin
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
}
