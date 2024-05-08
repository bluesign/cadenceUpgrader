// CREATED BY: Emerald City DAO
// REASON: For the sake of love
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Geeft: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	// Paths
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	// Standard Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Geeft Events
	access(all)
	event GeeftCreated(id: UInt64, message: String?, createdBy: Address?, to: Address)
	
	access(all)
	event GeeftOpened(id: UInt64, by: Address)
	
	access(all)
	struct GeeftInfo{ 
		access(all)
		let id: UInt64
		
		access(all)
		let createdBy: Address?
		
		access(all)
		let message: String?
		
		access(all)
		let collections:{ String: [MetadataViews.Display?]}
		
		access(all)
		let vaults:{ String: UFix64?}
		
		access(all)
		let extra:{ String: AnyStruct}
		
		init(id: UInt64, createdBy: Address?, message: String?, collections:{ String: [MetadataViews.Display?]}, vaults:{ String: UFix64?}, extra:{ String: AnyStruct}){ 
			self.id = id
			self.createdBy = createdBy
			self.message = message
			self.collections = collections
			self.vaults = vaults
			self.extra = extra
		}
	}
	
	access(all)
	resource CollectionContainer{ 
		access(all)
		let publicPath: PublicPath
		
		access(all)
		let storagePath: StoragePath
		
		access(all)
		let assets: @[{ViewResolver.Resolver}]
		
		access(all)
		let originalReceiverCap: Capability<&{NonFungibleToken.Receiver}>
		
		init(publicPath: PublicPath, storagePath: StoragePath, assets: @[{ViewResolver.Resolver}], to: Address){ 
			self.publicPath = publicPath
			self.storagePath = storagePath
			self.assets <- assets
			self.originalReceiverCap = getAccount(to).capabilities.get<&{NonFungibleToken.Receiver}>(publicPath)!
		}
		
		access(all)
		fun send(to: Address): Bool{ 
			if let collection = self.getCap(to: to).borrow(){ 
				while self.assets.length > 0{ 
					collection.deposit(token: <-(self.assets.removeFirst() as! @{NonFungibleToken.NFT}))
				}
				return true
			}
			return false
		}
		
		access(self)
		fun getCap(to: Address): Capability<&{NonFungibleToken.Receiver}>{ 
			if to == self.originalReceiverCap.address{ 
				return self.originalReceiverCap
			} else{ 
				return getAccount(to).capabilities.get<&{NonFungibleToken.Receiver}>(self.publicPath)!
			}
		}
		
		access(all)
		fun getDisplays(): [MetadataViews.Display?]{ 
			var i = 0
			let answer: [MetadataViews.Display?] = []
			while i < self.assets.length{ 
				let viewResolver = &self.assets[i] as &{ViewResolver.Resolver}
				answer.append(MetadataViews.getDisplay(viewResolver))
				i = i + 1
			}
			return answer
		}
	}
	
	access(all)
	resource VaultContainer{ 
		access(all)
		let receiverPath: PublicPath
		
		access(all)
		let storagePath: StoragePath
		
		access(all)
		var assets: @{FungibleToken.Vault}?
		
		access(all)
		let originalReceiverCap: Capability<&{FungibleToken.Receiver}>
		
		init(receiverPath: PublicPath, storagePath: StoragePath, assets: @{FungibleToken.Vault}, to: Address){ 
			self.receiverPath = receiverPath
			self.storagePath = storagePath
			self.assets <- assets
			self.originalReceiverCap = getAccount(to).capabilities.get<&{FungibleToken.Receiver}>(receiverPath)!
		}
		
		access(all)
		fun send(to: Address): Bool{ 
			if let vault = self.getCap(to: to).borrow(){ 
				var assets: @{FungibleToken.Vault}? <- nil
				self.assets <-> assets
				vault.deposit(from: <-assets!)
				return true
			}
			return false
		}
		
		access(self)
		fun getCap(to: Address): Capability<&{FungibleToken.Receiver}>{ 
			if to == self.originalReceiverCap.address{ 
				return self.originalReceiverCap
			} else{ 
				return getAccount(to).capabilities.get<&{FungibleToken.Receiver}>(self.receiverPath)!
			}
		}
		
		access(all)
		fun getBalance(): UFix64?{ 
			return self.assets?.balance
		}
	}
	
	// This represents a Geeft
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let createdBy: Address?
		
		access(all)
		let message: String?
		
		// ex. "FLOAT" -> A bunch of FLOATs and associated information
		access(all)
		var storedCollections: @{String: CollectionContainer}
		
		// ex. "FlowToken" -> Stored $FLOW and associated information
		access(all)
		var storedVaults: @{String: VaultContainer}
		
		access(all)
		let extra:{ String: AnyStruct}
		
		access(all)
		fun getGeeftInfo(): GeeftInfo{ 
			let collections:{ String: [MetadataViews.Display?]} ={} 
			for collectionName in self.storedCollections.keys{ 
				collections[collectionName] = self.storedCollections[collectionName]?.getDisplays()
			}
			let vaults:{ String: UFix64?} ={} 
			for vaultName in self.storedVaults.keys{ 
				vaults[vaultName] = self.storedVaults[vaultName]?.getBalance()
			}
			return GeeftInfo(id: self.id, createdBy: self.createdBy, message: self.message, collections: collections, vaults: vaults, extra: self.extra)
		}
		
		access(all)
		fun open(opener: Address): Bool{ 
			var completed: Bool = true
			for collectionName in self.storedCollections.keys{ 
				let succeeded = self.storedCollections[collectionName]?.send(to: opener)!
				if succeeded{ 
					destroy self.storedCollections.remove(key: collectionName)
				} else if completed{ 
					completed = false
				}
			}
			for vaultName in self.storedVaults.keys{ 
				let succeeded = self.storedVaults[vaultName]?.send(to: opener)!
				if succeeded{ 
					destroy self.storedVaults.remove(key: vaultName)
				} else if completed{ 
					completed = false
				}
			}
			return completed
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "Geeft #".concat(self.id.toString()), description: self.message ?? (self.createdBy == nil ? "This is a Geeft." : "This is a Geeft created by ".concat((self.createdBy!).toString()).concat(".")), thumbnail: MetadataViews.HTTPFile(url: "https://i.imgur.com/dZxbOEa.png"))
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(createdBy: Address?, message: String?, collections: @{String: CollectionContainer}, vaults: @{String: VaultContainer}, extra:{ String: AnyStruct}){ 
			self.id = self.uuid
			self.createdBy = createdBy
			self.message = message
			self.storedCollections <- collections
			self.storedVaults <- vaults
			self.extra = extra
			Geeft.totalSupply = Geeft.totalSupply + 1
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun getGeeftInfo(geeftId: UInt64): GeeftInfo
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let geeft <- token as! @NFT
			emit Deposit(id: geeft.id, to: self.owner?.address)
			self.ownedNFTs[geeft.id] <-! geeft
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let geeft <- self.ownedNFTs.remove(key: withdrawID) ?? panic("This Geeft does not exist in this collection.")
			emit Withdraw(id: geeft.id, from: self.owner?.address)
			return <-geeft
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun openGeeft(id: UInt64){ 
			let token <- self.ownedNFTs.remove(key: id) ?? panic("This Geeft does not exist.")
			let geeft <- token as! @NFT
			let completed = geeft.open(opener: (self.owner!).address)
			emit GeeftOpened(id: geeft.id, by: (self.owner!).address)
			if completed{ 
				destroy geeft
			} else{ 
				self.deposit(token: <-geeft)
			}
		}
		
		access(all)
		fun getGeeftInfo(geeftId: UInt64): GeeftInfo{ 
			let ref = (&self.ownedNFTs[geeftId] as &{NonFungibleToken.NFT}?)!
			let geeft = ref as! &NFT
			return geeft.getGeeftInfo()
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let geeft = nft as! &NFT
			return geeft as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	access(all)
	fun sendGeeft(createdBy: Address?, message: String?, collections: @{String: CollectionContainer}, vaults: @{String: VaultContainer}, extra:{ String: AnyStruct}, recipient: Address){ 
		let geeft <- create NFT(createdBy: createdBy, message: message, collections: <-collections, vaults: <-vaults, extra: extra)
		let collection = getAccount(recipient).capabilities.get<&Collection>(Geeft.CollectionPublicPath).borrow<&Collection>() ?? panic("The recipient does not have a Geeft Collection")
		emit GeeftCreated(id: geeft.id, message: message, createdBy: createdBy, to: recipient)
		collection.deposit(token: <-geeft)
	}
	
	access(all)
	fun createCollectionContainer(publicPath: PublicPath, storagePath: StoragePath, assets: @[{ViewResolver.Resolver}], to: Address): @CollectionContainer{ 
		return <-create CollectionContainer(publicPath: publicPath, storagePath: storagePath, assets: <-assets, to: to)
	}
	
	access(all)
	fun createVaultContainer(receiverPath: PublicPath, storagePath: StoragePath, assets: @{FungibleToken.Vault}, to: Address): @VaultContainer{ 
		return <-create VaultContainer(receiverPath: receiverPath, storagePath: storagePath, assets: <-assets, to: to)
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/GeeftCollection
		self.CollectionPublicPath = /public/GeeftCollection
		self.totalSupply = 0
		emit ContractInitialized()
	}
}
