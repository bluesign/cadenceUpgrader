import KeeprNFTStorefront from "./KeeprNFTStorefront.cdc"

access(all)
contract KeeprAdmin{ 
	access(all)
	let KeeprAdminStoragePath: StoragePath
	
	access(all)
	let KeeprAdminPublicPath: PublicPath
	
	access(all)
	event InitAdmin()
	
	access(all)
	event AddedCapability(owner: Address)
	
	access(all)
	resource interface AdminStorefrontManagerPublic{ 
		access(all)
		fun addCapability(_ cap: Capability<&KeeprNFTStorefront.Storefront>, owner: Address)
	}
	
	access(all)
	resource AdminStorefront{ 
		access(all)
		let account: Address
		
		access(all)
		let storefrontCapability: Capability<&KeeprNFTStorefront.Storefront>
		
		init(account: Address, storefrontCapability: Capability<&KeeprNFTStorefront.Storefront>){ 
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
		fun addCapability(_ cap: Capability<&KeeprNFTStorefront.Storefront>, owner: Address){ 
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
		self.KeeprAdminStoragePath = /storage/keepradmin002
		self.KeeprAdminPublicPath = /public/keepradmin002
	}
}
