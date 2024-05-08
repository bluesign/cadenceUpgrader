access(all)
contract DapperWalletCollections{ 
	access(all)
	let StoragePath: StoragePath
	
	access(all)
	event TypeChanged(identifier: String, added: Bool)
	
	access(self)
	let types:{ Type: Bool}
	
	access(all)
	resource Admin{ 
		access(all)
		fun addType(_ t: Type){ 
			DapperWalletCollections.types.insert(key: t, true)
			emit TypeChanged(identifier: t.identifier, added: true)
		}
		
		access(all)
		fun removeType(_ t: Type){ 
			DapperWalletCollections.types.remove(key: t)
			emit TypeChanged(identifier: t.identifier, added: false)
		}
	}
	
	init(){ 
		self.types ={} 
		self.StoragePath = /storage/dapperWalletCollections
	}
}
