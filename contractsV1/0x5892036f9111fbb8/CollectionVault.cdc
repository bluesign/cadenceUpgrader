import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract CollectionVault{ 
	access(all)
	event VaultAccessed(key: String)
	
	access(all)
	let DefaultStoragePath: StoragePath
	
	access(all)
	let DefaultPublicPath: PublicPath
	
	access(all)
	let DefaultPrivatePath: PrivatePath
	
	access(all)
	resource interface VaultPublic{ 
		access(all)
		fun storeVaultPublic(
			capability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
		)
	}
	
	access(all)
	resource Vault: VaultPublic{ 
		access(contract)
		var storedCapabilities:{ String: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>}
		
		access(contract)
		var allowedPublic: [String]?
		
		access(contract)
		var enabled: Bool
		
		access(all)
		fun getKeys(): [String]{ 
			return self.storedCapabilities.keys
		}
		
		access(all)
		fun hasKey(_ key: String): Bool{ 
			let capability = self.storedCapabilities[key]
			if capability == nil{ 
				return false
			}
			return (capability!).check()
		}
		
		access(all)
		fun getVault(_ key: String): &{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}?{ 
			let capability = self.storedCapabilities[key]
			if capability == nil{ 
				return nil
			}
			emit VaultAccessed(key: key)
			return (capability!).borrow()
		}
		
		access(all)
		fun storeVault(_ key: String, capability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>){ 
			self.storedCapabilities.insert(key: key, capability)
		}
		
		access(all)
		fun storeVaultPublic(capability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>){ 
			let collection = capability.borrow() ?? panic("Could not borrow capability")
			let type = collection.getType().identifier
			if self.allowedPublic != nil && !(self.allowedPublic!).contains(type){ 
				panic("Type ".concat(type).concat(" is not allowed for storeVaultPublic"))
			}
			let owner = collection.owner ?? panic("Collection must be owned in order to use storeVaultPublic")
			let key = type.concat("@").concat(owner.address.toString())
			self.storedCapabilities.insert(key: key, capability)
		}
		
		access(all)
		fun removeVault(_ key: String){ 
			self.storedCapabilities.remove(key: key)
		}
		
		access(all)
		fun setAllowedPublic(_ allowedPublic: [String]?){ 
			self.allowedPublic = allowedPublic
		}
		
		init(_ allowedPublic: [String]?){ 
			self.storedCapabilities ={} 
			self.allowedPublic = allowedPublic
			self.enabled = true
		}
	}
	
	access(all)
	fun createEmptyVault(_ allowedPublic: [String]?): @Vault{ 
		return <-create Vault(allowedPublic)
	}
	
	access(all)
	fun getAddress(): Address{ 
		return self.account.address
	}
	
	init(_ allowedPublic: [String]?){ 
		self.DefaultStoragePath = /storage/nftRealityCollectionVault
		self.DefaultPublicPath = /public/nftRealityCollectionVault
		self.DefaultPrivatePath = /private/nftRealityCollectionVault
		let vault <- create Vault(allowedPublic)
		self.account.storage.save(<-vault, to: self.DefaultStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&{VaultPublic}>(self.DefaultStoragePath)
		self.account.capabilities.publish(capability_1, at: self.DefaultPublicPath)
	}
}
