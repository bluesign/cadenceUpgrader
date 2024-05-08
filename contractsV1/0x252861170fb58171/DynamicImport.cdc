access(all)
contract DynamicImport{ 
	access(all)
	resource interface ImportInterface{ 
		access(all)
		fun dynamicImport(name: String): &AnyStruct?
	}
	
	access(all)
	fun dynamicImport(address: Address, contractName: String): &AnyStruct?{ 
		if let borrowed =
			self.account.storage.borrow<&{ImportInterface}>(
				from: StoragePath(identifier: "A".concat(address.toString()))!
			){ 
			return borrowed.dynamicImport(name: contractName)
		}
		return nil
	}
}
