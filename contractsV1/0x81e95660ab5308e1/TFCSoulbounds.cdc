access(all)
contract TFCSoulbounds{ 
	
	// Events
	access(all)
	event AddedItemToSoulbounds(itemName: String)
	
	access(all)
	event RemovedItemFromSoulbounds(itemName: String)
	
	access(all)
	event ContractInitialized()
	
	// Named Paths
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	access(contract)
	var soulboundItems:{ String: Bool}
	
	access(all)
	resource Administrator{ 
		access(all)
		fun addNewItemToSoulboundList(itemName: String){ 
			TFCSoulbounds.soulboundItems.insert(key: itemName, true)
			emit AddedItemToSoulbounds(itemName: itemName)
		}
		
		access(all)
		fun removeItemFromSoulboundList(itemName: String){ 
			TFCSoulbounds.soulboundItems.remove(key: itemName)
			emit RemovedItemFromSoulbounds(itemName: itemName)
		}
	}
	
	access(all)
	fun getSoulboundItemsList(): [String]{ 
		return self.soulboundItems.keys
	}
	
	access(all)
	fun isItemSoulbound(itemName: String): Bool{ 
		return self.soulboundItems.containsKey(itemName)
	}
	
	init(){ 
		// Set our named paths
		self.AdminStoragePath = /storage/TFCSoulboundsAdmin
		self.AdminPrivatePath = /private/TFCSoulboundsAdminPrivate
		
		// Initialize Vars
		self.soulboundItems ={} 
		
		// Create a Admin resource and save it to storage
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&Administrator>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath)
		emit ContractInitialized()
	}
}
