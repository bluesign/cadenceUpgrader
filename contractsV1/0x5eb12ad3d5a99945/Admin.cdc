import NFTStorefront from "./../../standardsV1/NFTStorefront.cdc"

access(all)
contract Admin{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPublicPath: PublicPath
	
	access(all)
	event InitAdmin()
	
	access(all)
	event AddedCapability(owner: Address)
	
	access(all)
	resource interface AdminStorefrontManagerPublic{ 
		access(all)
		fun addCapability(_ cap: Capability<&NFTStorefront.Storefront>, owner: Address)
	}
	
	access(all)
	resource AdminStorefront{ 
		access(all)
		let account: Address
		
		access(all)
		let storefrontCapability: Capability<&NFTStorefront.Storefront>
		
		init(account: Address, storefrontCapability: Capability<&NFTStorefront.Storefront>){ 
			self.account = account
			self.storefrontCapability = storefrontCapability
		}
	}
	
	access(all)
	resource AdminStorefrontManager: AdminStorefrontManagerPublic{ 
		access(self)
		var storefronts: @{Address: AdminStorefront}
		
		init(){ 
			self.storefronts <-{} 
			emit InitAdmin()
		}
		
		access(all)
		fun addCapability(_ cap: Capability<&NFTStorefront.Storefront>, owner: Address){ 
			let storefront <- create AdminStorefront(account: owner, storefrontCapability: cap)
			let oldStorefront <- self.storefronts[owner] <- storefront
			destroy oldStorefront
		}
		
		access(all)
		fun getCapability(owner: Address): &AdminStorefront?{ 
			return &self.storefronts[owner] as &AdminStorefront?
		}
	}
	
	access(all)
	fun createStorefrontManager(): @AdminStorefrontManager{ 
		return <-create AdminStorefrontManager()
	}
	
	init(){ 
		self.AdminStoragePath = /storage/keepradmin
		self.AdminPublicPath = /public/keepradmin
	}
}
