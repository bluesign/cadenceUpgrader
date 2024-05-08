import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowversePrimarySaleV2 from "./FlowversePrimarySaleV2.cdc"

import FindViews from "../0x097bafa4e0b48eef/FindViews.cdc"

access(all)
contract FlowverseShirt: NonFungibleToken{ 
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event EntityCreated(id: UInt64, metadata:{ String: String})
	
	access(all)
	event EntityUpdated(id: UInt64, metadata:{ String: String})
	
	access(all)
	event NFTMinted(nftID: UInt64, nftUUID: UInt64, entityID: UInt64, minterAddress: Address)
	
	access(all)
	event NFTDestroyed(nftID: UInt64)
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(self)
	var entityDatas:{ UInt64: Entity}
	
	access(self)
	var numMintedPerEntity:{ UInt64: UInt64}
	
	// Total number of FlowverseShirt NFTs that have been minted
	// Incremented ID used to create nfts
	access(all)
	var totalSupply: UInt64
	
	// Incremented ID used to create entities
	access(all)
	var nextEntityID: UInt64
	
	// Entity is a blueprint that holds metadata associated with an NFT
	access(all)
	struct Entity{ 
		// Unique ID for the entity
		access(all)
		let entityID: UInt64
		
		// Stores all the metadata about the entity as a string mapping
		access(all)
		var metadata:{ String: String}
		
		init(metadata:{ String: String}){ 
			pre{ 
				metadata.length != 0:
					"New Entity metadata cannot be empty"
			}
			self.entityID = FlowverseShirt.nextEntityID
			self.metadata = metadata
		}
		
		access(contract)
		fun removeMetadata(key: String){ 
			self.metadata.remove(key: key)
		}
		
		access(contract)
		fun setMetadata(key: String, value: String){ 
			self.metadata[key] = value
		}
	}
	
	// NFT Resource that represents the Entity instances
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// Global unique NFT ID
		access(all)
		let id: UInt64
		
		// The ID of the Entity that the NFT references
		access(all)
		let entityID: UInt64
		
		// The minterAddress of the NFT
		access(all)
		let minterAddress: Address
		
		init(entityID: UInt64, minterAddress: Address){ 
			self.id = FlowverseShirt.totalSupply
			self.entityID = entityID
			self.minterAddress = minterAddress
			emit NFTMinted(nftID: self.id, nftUUID: self.uuid, entityID: entityID, minterAddress: self.minterAddress)
		}
		
		// If the NFT is destroyed, emit an event to indicate 
		// to outside observers that it has been destroyed
		access(all)
		view fun checkSoulbound(): Bool{ 
			return FlowverseShirt.getEntityMetaDataByField(entityID: self.entityID, field: "soulbound") == "true"
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			let supportedViews = [Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Edition>(), Type<MetadataViews.Traits>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Rarity>()]
			if self.checkSoulbound() == true{ 
				supportedViews.append(Type<FindViews.SoulBound>())
			}
			return supportedViews
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: FlowverseShirt.CollectionStoragePath, publicPath: FlowverseShirt.CollectionPublicPath, publicCollection: Type<&FlowverseShirt.Collection>(), publicLinkedType: Type<&FlowverseShirt.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-FlowverseShirt.createEmptyCollection(nftType: Type<@FlowverseShirt.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					return MetadataViews.NFTCollectionDisplay(name: "Flowverse Shirt", description: "The Flowverse Shirt is the official shirt collection for the Flowverse community. Join a group of die-hard Flow enthusiasts and rep the Flowverse Shirt on the Flow Blockchain", externalURL: MetadataViews.ExternalURL("https://twitter.com/flowverse_"), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://flowverse.myfilebase.com/ipfs/QmeFH4AXFLkCzKJ64nRmtRyqxXsVH8N98QDZcUNwJphXBz"), mediaType: "image/png"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://flowverse.myfilebase.com/ipfs/QmSevyXCcgmHse2TTc6mtK2sdAGDSWncERUXrFYP2hxMgu"), mediaType: "image/png"), socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/flowverse_")})
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: (FlowverseShirt.getEntityMetaDataByField(entityID: self.entityID, field: "name") ?? "").concat(" #").concat(self.id.toString()), description: FlowverseShirt.getEntityMetaDataByField(entityID: self.entityID, field: "description") ?? "", thumbnail: MetadataViews.HTTPFile(url: FlowverseShirt.getEntityMetaDataByField(entityID: self.entityID, field: "thumbnailURL") ?? ""))
				case Type<MetadataViews.Medias>():
					let mediaURL = FlowverseShirt.getEntityMetaDataByField(entityID: self.entityID, field: "mediaURL")
					let mediaType = FlowverseShirt.getEntityMetaDataByField(entityID: self.entityID, field: "mediaType")
					if mediaURL != nil && mediaType != nil{ 
						let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: mediaURL!), mediaType: mediaType!)
						return MetadataViews.Medias([media])
					}
					return MetadataViews.Medias([])
				case Type<MetadataViews.Royalties>():
					let royalties: [MetadataViews.Royalty] = [MetadataViews.Royalty(receiver: getAccount(0x604b63bcbef5974f).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, cut: 0.05, description: "Creator Royalty Fee")]
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.Traits>():
					let traits: [MetadataViews.Trait] = []
					return MetadataViews.Traits(traits)
				case Type<MetadataViews.ExternalURL>():
					let baseURL = "https://nft.flowverse.co/collections/FlowverseShirts/"
					return MetadataViews.ExternalURL(baseURL.concat((self.owner!).address.toString()).concat("/".concat(self.id.toString())))
				case Type<FindViews.SoulBound>():
					if self.checkSoulbound() == true{ 
						return FindViews.SoulBound("This NFT cannot be transferred.")
					}
					return nil
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(self)
	fun mint(entityID: UInt64, minterAddress: Address): @NFT{ 
		pre{ 
			FlowverseShirt.entityDatas[entityID] != nil:
				"Cannot mint: the entity doesn't exist."
		}
		
		// Gets the number of NFTs that have been minted for this Entity
		let entityMintNumber = FlowverseShirt.numMintedPerEntity[entityID]!
		
		// Increment the global NFT ID
		FlowverseShirt.totalSupply = FlowverseShirt.totalSupply + UInt64(1)
		
		// Mint the new NFT
		let newNFT: @NFT <- create NFT(entityID: entityID, minterAddress: minterAddress)
		
		// Increment the number of copies minted for this NFT
		FlowverseShirt.numMintedPerEntity[entityID] = entityMintNumber + UInt64(1)
		return <-newNFT
	}
	
	access(all)
	resource NFTMinter: FlowversePrimarySaleV2.IMinter{ 
		init(){} 
		
		access(all)
		fun mint(entityID: UInt64, minterAddress: Address): @NFT{ 
			return <-FlowverseShirt.mint(entityID: entityID, minterAddress: minterAddress)
		}
	}
	
	// Admin is a special authorization resource that 
	// allows the owner to perform important functions to modify the 
	// various aspects of the Entities, Sets, and NFTs
	//
	access(all)
	resource Admin{ 
		
		// createEntity creates a new Entity struct 
		// and stores it in the Entities dictionary in the FlowverseShirt smart contract
		access(all)
		fun createEntity(metadata:{ String: String}): UInt64{ 
			// Create the new Entity
			var newEntity = Entity(metadata: metadata)
			let newID = newEntity.entityID
			
			// Increment the ID so that it isn't used again
			FlowverseShirt.nextEntityID = FlowverseShirt.nextEntityID + UInt64(1)
			
			// Store it in the contract storage
			FlowverseShirt.entityDatas[newID] = newEntity
			
			// Initialise numMintedPerEntity
			FlowverseShirt.numMintedPerEntity[newID] = UInt64(0)
			emit EntityCreated(id: newID, metadata: metadata)
			return newID
		}
		
		// updateEntity updates an existing Entity 
		access(all)
		fun updateEntity(entityID: UInt64, metadata:{ String: String}){ 
			let updatedEntity = FlowverseShirt.entityDatas[entityID]!
			updatedEntity.metadata = metadata
			FlowverseShirt.entityDatas[entityID] = updatedEntity
			emit EntityUpdated(id: entityID, metadata: metadata)
		}
		
		access(all)
		fun setEntitySoulbound(entityID: UInt64, soulbound: Bool){ 
			assert(FlowverseShirt.entityDatas[entityID] != nil, message: "Cannot set soulbound: the entity doesn't exist.")
			if soulbound{ 
				(FlowverseShirt.entityDatas[entityID]!).setMetadata(key: "soulbound", value: "true")
			} else{ 
				(FlowverseShirt.entityDatas[entityID]!).removeMetadata(key: "soulbound")
			}
		}
		
		access(all)
		fun mint(entityID: UInt64, minterAddress: Address): @NFT{ 
			return <-FlowverseShirt.mint(entityID: entityID, minterAddress: minterAddress)
		}
		
		// createNFTMinter creates a new NFTMinter resource
		access(all)
		fun createNFTMinter(): @NFTMinter{ 
			return <-create NFTMinter()
		}
		
		// createNewAdmin creates a new Admin resource
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	// Public interface for the FlowverseShirt Collection that allows users access to certain functionalities
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowFlowverseShirtNFT(id: UInt64): &FlowverseShirt.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow FlowverseShirt reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
	}
	
	// Collection of FlowverseShirt NFTs owned by an account
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// Dictionary of entity instances conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			let nft <- token as! @NFT
			
			// Check if the NFT is soulbound. Secondary marketplaces will use the
			// withdraw function, so if the NFT is soulbound, it will not be transferrable,
			// and hence cannot be sold.
			if nft.checkSoulbound() == true{ 
				panic("This NFT is not transferrable.")
			}
			emit Withdraw(id: withdrawID, from: self.owner?.address)
			return <-nft
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @FlowverseShirt.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			let keys = tokens.getIDs()
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			destroy tokens
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
		fun borrowFlowverseShirtNFT(id: UInt64): &FlowverseShirt.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &FlowverseShirt.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nftRef = nft as! &FlowverseShirt.NFT
			return nftRef as &{ViewResolver.Resolver}
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// -----------------------------------------------------------------------
	// FlowverseShirt contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create FlowverseShirt.Collection()
	}
	
	// getAllEntities returns all the entities available
	access(all)
	fun getAllEntities(): [FlowverseShirt.Entity]{ 
		return FlowverseShirt.entityDatas.values
	}
	
	// getEntity returns an entity by ID
	access(all)
	fun getEntity(entityID: UInt64): FlowverseShirt.Entity?{ 
		return self.entityDatas[entityID]
	}
	
	// getEntityMetaData returns all the metadata associated with a specific Entity
	access(all)
	fun getEntityMetaData(entityID: UInt64):{ String: String}?{ 
		return self.entityDatas[entityID]?.metadata
	}
	
	access(all)
	view fun getEntityMetaDataByField(entityID: UInt64, field: String): String?{ 
		if let entity = FlowverseShirt.entityDatas[entityID]{ 
			return entity.metadata[field]
		} else{ 
			return nil
		}
	}
	
	access(all)
	fun getNumMintedPerEntity():{ UInt64: UInt64}{ 
		return self.numMintedPerEntity
	}
	
	// -----------------------------------------------------------------------
	// FlowverseShirt initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		self.CollectionStoragePath = /storage/FlowverseShirtCollection
		self.CollectionPublicPath = /public/FlowverseShirtCollection
		self.AdminStoragePath = /storage/FlowverseShirtAdmin
		
		// Initialize contract fields
		self.entityDatas ={} 
		self.numMintedPerEntity ={} 
		self.nextEntityID = 1
		self.totalSupply = 0
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: self.CollectionStoragePath)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Put the Admin resource in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
