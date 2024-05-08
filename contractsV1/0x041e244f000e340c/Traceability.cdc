access(all)
contract Traceability{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event ProductCodeCreate(code: String)
	
	access(all)
	event ProductCodeRemove(code: String)
	
	access(all)
	resource interface ProductCodePublic{ 
		access(all)
		fun ProductCodeExist(code: String): Bool
		
		access(all)
		fun GetAllProductCodes(): [String]
		
		access(all)
		fun ProductCodesLength(): Integer
	}
	
	access(all)
	resource ProductCodeList: ProductCodePublic{ 
		access(all)
		var CodeMap:{ String: Bool}
		
		init(){ 
			self.CodeMap ={} 
		}
		
		// public interface contains function that everyone can call
		access(all)
		fun ProductCodesLength(): Integer{ 
			return self.CodeMap.length
		}
		
		access(all)
		fun ProductCodeExist(code: String): Bool{ 
			return self.CodeMap.containsKey(code)
		}
		
		access(all)
		fun GetAllProductCodes(): [String]{ 
			return self.CodeMap.keys
		}
		
		// only account owner can call the rest of functions
		access(all)
		fun AddProductCode(code: String){ 
			self.CodeMap[code] = true
			emit ProductCodeCreate(code: code)
		}
		
		access(all)
		fun RemoveProductCode(code: String){ 
			if self.CodeMap.containsKey(code){ 
				self.CodeMap.remove(key: code)
				emit ProductCodeRemove(code: code)
			}
		}
	}
	
	access(all)
	fun createCodeList(): @ProductCodeList{ 
		return <-create ProductCodeList()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/CodeCollection
		self.CollectionPublicPath = /public/CodeCollection
		
		// store an empty ProductCode Collection in account storage
		self.account.storage.save(<-self.createCodeList(), to: self.CollectionStoragePath)
		
		// publish a reference to the Collection in storage
		// create a public capability for the collection
		var capability_1 =
			self.account.capabilities.storage.issue<&Traceability.ProductCodeList>(
				self.CollectionStoragePath
			)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
