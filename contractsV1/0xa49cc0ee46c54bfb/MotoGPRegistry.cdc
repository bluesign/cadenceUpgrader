import ContractVersion from 0xa49cc0ee46c54bfb

access(all)
contract MotoGPRegistry: ContractVersion{ 
	access(all)
	fun getVersion(): String{ 
		return "1.0.0"
	}
	
	access(all)
	resource Admin{} 
	
	access(contract)
	let map:{ String: AnyStruct}
	
	access(all)
	fun set(adminRef: &Admin, key: String, value: AnyStruct){ 
		self.map[key] = value
	}
	
	access(all)
	fun get(key: String): AnyStruct?{ 
		return self.map[key] ?? nil
	}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	init(){ 
		self.map ={} 
		self.AdminStoragePath = /storage/registryAdmin
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
