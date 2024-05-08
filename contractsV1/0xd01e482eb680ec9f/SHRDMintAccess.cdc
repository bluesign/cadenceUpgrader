import SHRD from "./SHRD.cdc"

access(all)
contract SHRDMintAccess{ 
	access(all)
	fun getVersion(): String{ 
		return "1.0.0"
	}
	
	// Interface to allow the MintGuard owner to enable minting on another account's MintProxy
	//
	access(all)
	resource interface MintProxyPublic{ 
		access(all)
		fun setCapability(mintCapability: Capability<&MintGuard>)
		
		access(all)
		fun getMax(): UFix64
		
		access(all)
		fun getTotal(): UFix64
	}
	
	// Interface to allow a contract to mint SHRD by holding a capability, while keeping the link private to not expose the minting function publicly
	//
	access(all)
	resource interface MintProxyPrivate{ 
		access(all)
		fun mint(amount: UFix64): @SHRD.Vault
	}
	
	access(all)
	resource MintProxy: MintProxyPublic, MintProxyPrivate{ 
		access(all)
		var mintCapability: Capability<&MintGuard>?
		
		access(all)
		fun getMax(): UFix64{ 
			return ((self.mintCapability!).borrow()!).max
		}
		
		access(all)
		fun getTotal(): UFix64{ 
			return ((self.mintCapability!).borrow()!).total
		}
		
		// Can be called successfully only by a MintGuard owner, since the Capability type is based on a private link
		access(all)
		fun setCapability(mintCapability: Capability<&MintGuard>){ 
			pre{ 
				mintCapability.check() == true:
					"mintCapability.check() is false"
			}
			self.mintCapability = mintCapability
		}
		
		access(all)
		fun mint(amount: UFix64): @SHRD.Vault{ 
			return <-((self.mintCapability!).borrow()!).mint(amount: amount)
		}
		
		init(){ 
			self.mintCapability = nil
		}
	}
	
	// MintGuardPrivate
	// Use as interface for a link
	//
	access(all)
	resource interface MintGuardPrivate{ 
		access(all)
		fun mint(amount: UFix64): @SHRD.Vault
		
		access(all)
		var total: UFix64
		
		access(all)
		var max: UFix64
	}
	
	access(all)
	resource interface MintGuardPublic{ 
		access(all)
		fun getTotal(): UFix64
		
		access(all)
		fun getMax(): UFix64
	}
	
	// MintGuard
	//
	// The MintGuard's role is to be the source of a revokable link to the account's SHRD contract' mint function.
	//
	access(all)
	resource MintGuard: MintGuardPrivate, MintGuardPublic{ 
		
		// max is the largest total amount that can be withdrawn using the VaultGuard
		//
		access(all)
		var max: UFix64
		
		// total keeps track of how much has been withdrawn via the VaultGuard
		//
		access(all)
		var total: UFix64
		
		access(self)
		let mintCapability: Capability<&SHRD.SHRDMinter>
		
		access(all)
		fun getTotal(): UFix64{ 
			return self.total
		}
		
		access(all)
		fun getMax(): UFix64{ 
			return self.max
		}
		
		// mint - part of private interface. Should never be exposed publicly
		//
		access(all)
		fun mint(amount: UFix64): @SHRD.Vault{ 
			// check authoried amount
			pre{ 
				amount + self.total <= self.max:
					"Total of amount + previously withdrawn exceeds max (".concat(self.max.toString()).concat(") withdrawal.")
			}
			self.total = self.total + amount
			return <-(self.mintCapability.borrow()!).mint(amount: amount)
		}
		
		// Setter using a SHRDMintAccess.Admin lock to set the max for a mint guard
		//
		access(all)
		fun setMax(adminRef: &Admin, max: UFix64){ 
			self.max = max
		}
		
		// constructor - takes a SHRDMinter vault reference, and a max mint amount
		//
		init(privateMintCapability: Capability<&SHRD.SHRDMinter>, max: UFix64){ 
			pre{ 
				privateMintCapability != nil:
					"privateMintCapability is nil in SHRDMintAccess.MintGuard init"
			}
			self.mintCapability = privateMintCapability
			self.max = max
			self.total = UFix64(0.0)
		}
	}
	
	// Admin resource
	//
	access(all)
	resource Admin{} 
	
	access(all)
	enum MintObjectType: UInt8{ 
		access(all)
		case MintGuard
		
		access(all)
		case MintProxy
	}
	
	access(all)
	enum PathType: UInt8{ 
		access(all)
		case StorageType
		
		access(all)
		case PrivateType
		
		access(all)
		case PublicType
	}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var pathIndex: UInt64
	
	access(all)
	let pathIndexToAddressMap:{ UInt64: Address}
	
	access(all)
	let addressToPathIndexMap:{ Address: UInt64}
	
	access(all)
	let whitelisted:{ Address: Bool}
	
	access(all)
	let mintGuardPathPrefix: String
	
	access(all)
	let mintProxyPathPrefix: String
	
	access(all)
	fun createMintGuard(
		adminRef: &Admin,
		privateMintCapability: Capability<&SHRD.SHRDMinter>,
		targetAddress: Address,
		max: UFix64
	){ 
		pre{ 
			adminRef != nil:
				"adminRef ref is nil"
			self.addressToPathIndexMap[targetAddress] == nil:
				"A mint guard has already been created for that target address"
		}
		self.pathIndex = self.pathIndex + 1
		self.pathIndexToAddressMap[self.pathIndex] = targetAddress
		self.addressToPathIndexMap[targetAddress] = self.pathIndex
		let mintGuard <- create MintGuard(privateMintCapability: privateMintCapability, max: max)
		let storagePath =
			self.getStoragePath(address: targetAddress, objectType: MintObjectType.MintGuard)!
		let privatePath =
			self.getPrivatePath(address: targetAddress, objectType: MintObjectType.MintGuard)!
		let publicPath =
			self.getPublicPath(address: targetAddress, objectType: MintObjectType.MintGuard)!
		self.account.storage.save(<-mintGuard, to: storagePath)
		var capability_1 = self.account.capabilities.storage.issue<&MintGuard>(storagePath)
		self.account.capabilities.publish(capability_1, at: privatePath)
		var capability_2 = self.account.capabilities.storage.issue<&MintGuard>(storagePath)
		self.account.capabilities.publish(capability_2, at: publicPath)
		self.whitelisted[targetAddress] = true
	}
	
	access(all)
	fun createMintProxy(authAccount: AuthAccount){ 
		pre{ 
			self.whitelisted[authAccount.address] == true:
				"authAccount.address is not whitelisted"
		}
		let mintProxy <- create MintProxy()
		let address = authAccount.address!
		let storagePath =
			self.getStoragePath(address: address, objectType: MintObjectType.MintProxy)
		let privatePath =
			self.getPrivatePath(address: address, objectType: MintObjectType.MintProxy)
		let publicPath = self.getPublicProxyPath(address: address)
		authAccount.save(<-mintProxy, to: storagePath)
		authAccount.link<&MintProxy>(privatePath, target: storagePath)
		authAccount.link<&MintProxy>(publicPath, target: storagePath)
	}
	
	// Getter function to get storage MintGuard or MintProxy path for address
	//
	access(all)
	fun getStoragePath(address: Address, objectType: MintObjectType): StoragePath{ 
		let index = self.addressToPathIndexMap[address]!
		let identifier =
			objectType == MintObjectType.MintGuard
				? self.mintGuardPathPrefix
				: self.mintProxyPathPrefix
		return StoragePath(identifier: identifier.concat(index.toString()))!
	}
	
	// Getter function to get private MintGuard or MintProxy path for address
	//
	access(all)
	fun getPrivatePath(address: Address, objectType: MintObjectType): PrivatePath{ 
		let index = self.addressToPathIndexMap[address]!
		let identifier =
			objectType == MintObjectType.MintGuard
				? self.mintGuardPathPrefix
				: self.mintProxyPathPrefix
		return PrivatePath(identifier: identifier.concat(index.toString()))!
	}
	
	// Getter function to get public MintProxy path for address (mapped to index)
	// Always returns the Proxy path, since VaultGuards don't have a public path
	//
	access(all)
	fun getPublicProxyPath(address: Address): PublicPath{ 
		let index = self.addressToPathIndexMap[address]!
		return PublicPath(identifier: self.mintProxyPathPrefix.concat(index.toString()))!
	}
	
	access(all)
	fun getPublicPath(address: Address, objectType: MintObjectType): PublicPath{ 
		let index = self.addressToPathIndexMap[address]!
		let identifier =
			objectType == MintObjectType.MintGuard
				? self.mintGuardPathPrefix
				: self.mintProxyPathPrefix
		return PublicPath(identifier: identifier.concat(index.toString()))!
	}
	
	init(){ 
		self.mintGuardPathPrefix = "shrdMintGuard"
		self.mintProxyPathPrefix = "shrdMintProxy"
		self.pathIndex = 0
		self.pathIndexToAddressMap ={} 
		self.addressToPathIndexMap ={} 
		self.whitelisted ={} 
		self.AdminStoragePath = /storage/shrdMinterAccessAdmin
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
