access(all)
contract StorefrontService{ 
	
	// basic data about the storefront
	access(all)
	let version: UInt32
	
	access(all)
	let name: String
	
	access(all)
	let description: String
	
	access(all)
	var closed: Bool
	
	// paths
	access(all)
	let ADMIN_OBJECT_PATH: StoragePath
	
	// storefront events
	access(all)
	event StorefrontClosed()
	
	access(all)
	event ContractInitialized()
	
	init(){ 
		self.version = 1
		self.name = "Example Storefront"
		self.description = "An example storefront"
		self.closed = false
		self.ADMIN_OBJECT_PATH = /storage/StorefrontAdmin
		
		// put the admin in storage
		self.account.storage.save<@StorefrontAdmin>(
			<-create StorefrontAdmin(),
			to: StorefrontService.ADMIN_OBJECT_PATH
		)
		emit ContractInitialized()
	}
	
	// Returns the version of this contract
	//
	access(all)
	fun getVersion(): UInt32{ 
		return self.version
	}
	
	// StorefrontAdmin is used for administering the Storefront
	//
	access(all)
	resource StorefrontAdmin{ 
		
		// Closes the Storefront, rendering any write access impossible
		//
		access(all)
		fun close(){ 
			if !StorefrontService.closed{ 
				StorefrontService.closed = true
				emit StorefrontClosed()
			}
		}
		
		// Creates a new StorefrontAdmin that allows for another account
		// to administer the Storefront
		//
		access(all)
		fun createNewStorefrontAdmin(): @StorefrontAdmin{ 
			return <-create StorefrontAdmin()
		}
	}
}
