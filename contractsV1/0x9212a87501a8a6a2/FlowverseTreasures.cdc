// MAINNET
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

// Flowverse Treasures is an NFT contract for artist collaboration collections
access(all)
contract FlowverseTreasures: NonFungibleToken{ 
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
	event SetCreated(setID: UInt64, name: String, description: String, externalURL: String, isPrivate: Bool, thumbnailURL: String, bannerURL: String, royaltyReceiverAddress: Address)
	
	access(all)
	event SetUpdated(setID: UInt64, description: String?, externalURL: String?, thumbnailURL: String?, bannerURL: String?, royaltyReceiverAddress: Address?)
	
	access(all)
	event EntityAddedToSet(setID: UInt64, entityID: UInt64)
	
	access(all)
	event EntityRetiredFromSet(setID: UInt64, entityID: UInt64, numNFTs: UInt64)
	
	access(all)
	event SetLocked(setID: UInt64)
	
	access(all)
	event NFTMinted(nftID: UInt64, nftUUID: UInt64, entityID: UInt64, setID: UInt64, mintNumber: UInt64, minterAddress: Address)
	
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
	var setDatas:{ UInt64: SetData}
	
	access(self)
	var sets: @{UInt64: Set}
	
	// Total number of FlowverseTreasures NFTs that have been minted
	access(all)
	var totalSupply: UInt64
	
	// Incremented ID used to create entities
	access(all)
	var nextEntityID: UInt64
	
	// Incremented ID used to create sets
	access(all)
	var nextSetID: UInt64
	
	// Entity is a Struct that holds metadata associated with an NFT
	// NFTs reference a single entity. The entities are publicly accessible, so anyone can
	// read the metadata associated with a specific entity ID.
	// An entity metadata is immutable
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
			self.entityID = FlowverseTreasures.nextEntityID
			self.metadata = metadata
		}
	}
	
	// A Set is a group of Entities.
	// An Entity can exist in multiple different sets. 
	// SetData is a struct that contains information about the set.
	access(all)
	struct SetData{ 
		// Unique ID for the Set
		access(all)
		let setID: UInt64
		
		// Name of the Set
		access(all)
		let name: String
		
		// Description of the Set
		access(all)
		let description: String
		
		// External URL (website) of the Set
		access(all)
		let externalURL: String
		
		// Thumbnail image URL of the Set
		access(all)
		let thumbnailURL: String
		
		// Banner image URL of the Set
		access(all)
		let bannerURL: String
		
		// Address of the royalty receiver
		access(all)
		let royaltyReceiverAddress: Address
		
		// Indicates if the Set is listed as a Drop
		// e.g. admin may create a private collection for air dropping nfts
		access(all)
		var isPrivate: Bool
		
		init(setID: UInt64, name: String, description: String, externalURL: String, thumbnailURL: String, bannerURL: String, royaltyReceiverAddress: Address, isPrivate: Bool){ 
			pre{ 
				name.length > 0:
					"Set name cannot be empty"
				description.length > 0:
					"Set description cannot be empty"
				thumbnailURL.length > 0:
					"Set thumbnailURL cannot be empty"
				bannerURL.length > 0:
					"Set bannerURL cannot be empty"
			}
			self.setID = setID
			self.name = name
			self.description = description
			self.externalURL = externalURL
			self.thumbnailURL = thumbnailURL
			self.bannerURL = bannerURL
			self.royaltyReceiverAddress = royaltyReceiverAddress
			self.isPrivate = isPrivate
		}
	}
	
	// Set is a resource type that contains the functions to add and remove
	// entities from a set and mint NFTs.
	//
	// It is stored in a private field in the contract so that
	// only the admin resource can call its methods.
	//
	// The admin can add entities to a Set so that the set can mint NFTs
	// that reference that entity data.
	// The NFTs that are minted by a Set will be listed as belonging to
	// the Set that minted it, as well as the Entity it references.
	// 
	// Admin can also lock entities from the Set, meaning that the locked
	// Entity can no longer have NFTs minted from it.
	//
	// If the admin locks the Set, no more entities can be added to it, but 
	// NFTs can still be minted from the set.
	access(all)
	resource Set{ 
		// Unique ID for the set
		access(all)
		let setID: UInt64
		
		// Array of entities that are a part of this set.
		// When an entity is added to the set, its ID gets appended here.
		access(self)
		var entities: [UInt64]
		
		// Map of entity IDs that indicates whether an entity in this Set can be minted.
		// When an entity is added to a Set, it is mapped to false.
		// When an entity is retired, the mapping is updated to true and cannot be changed.
		access(self)
		var retired:{ UInt64: Bool}
		
		// Indicates whether the Set is currently locked.
		// When a Set is created, it is unlocked 
		// and entities can be added to it.
		// When a set is locked, entities cannot be added.
		// A Set can never be changed from locked to unlocked.
		// The decision to lock a Set it is final and irreversible.
		// If a Set is locked, entities cannot be added, but
		// NFTs can still be minted from entities that exist in the Set.
		access(all)
		var locked: Bool
		
		// Mapping of Entity IDs that indicates the number of NFTs 
		// that have been minted for specific entities in this Set.
		// When an NFT is minted, this value is stored in the NFT to
		// show its position / mint number (serial number) 
		// in the Set, eg. 13 of 60.
		access(self)
		var numMintedPerEntity:{ UInt64: UInt64}
		
		access(all)
		var totalMinted: UInt64
		
		init(){ 
			self.setID = FlowverseTreasures.nextSetID
			self.entities = []
			self.retired ={} 
			self.locked = false
			self.numMintedPerEntity ={} 
			self.totalMinted = 0
		}
		
		// addEntity adds an entity to the set
		//
		// Parameters: entityID: The ID of the entity that is being added
		//
		// Pre-Conditions:
		// The entity needs to be an existing entity
		// The Set must not be locked
		// The entity cannot already exist in the Set
		//
		access(all)
		fun addEntity(entityID: UInt64){ 
			pre{ 
				FlowverseTreasures.entityDatas[entityID] != nil:
					"Cannot add the Entity to Set: Entity doesn't exist."
				!self.locked:
					"Cannot add the entity to the Set after the set has been locked."
				self.numMintedPerEntity[entityID] == nil:
					"The entity has already been added to the set."
			}
			
			// Add the entity to the array of entities
			self.entities.append(entityID)
			
			// Allow the entity to be minted
			self.retired[entityID] = false
			
			// Initialize the entity minted count to zero
			self.numMintedPerEntity[entityID] = 0
			emit EntityAddedToSet(setID: self.setID, entityID: entityID)
		}
		
		// addEntities adds multiple entities to the Set
		//
		// Parameters: entityIDs: The entity IDs that are being added
		//
		access(all)
		fun addEntities(entityIDs: [UInt64]){ 
			for entity in entityIDs{ 
				self.addEntity(entityID: entity)
			}
		}
		
		// retireEntity retires an entity from the Set so that it cannot mint new NFTs
		//
		// Parameters: entityID: The ID of the entity that is being retired
		//
		// Pre-Conditions:
		// The entity exists in the Set and is not already retired
		// 
		access(all)
		fun retireEntity(entityID: UInt64){ 
			pre{ 
				self.retired[entityID] == false:
					"Cannot retire the entity: Entity must exist in the Set and not be retired."
			}
			self.retired[entityID] = true
			emit EntityRetiredFromSet(setID: self.setID, entityID: entityID, numNFTs: self.numMintedPerEntity[entityID]!)
		}
		
		// retireAll retires all the entities in the Set
		//
		access(all)
		fun retireAll(){ 
			for entity in self.entities{ 
				self.retireEntity(entityID: entity)
			}
		}
		
		// lock() locks the Set so that no more entities can be added to it
		//
		// Pre-Conditions:
		// The Set should not already be locked
		access(all)
		fun lock(){ 
			pre{ 
				self.locked == false:
					"Cannot lock the set: Set is already locked."
			}
			self.locked = true
			emit SetLocked(setID: self.setID)
		}
		
		// mint mints a new entity instance and returns the newly minted instance of an entity
		// 
		// Parameters: 
		// entityID: The ID of the entity that the NFT references
		// minterAddress: The address of the minter
		//
		// Pre-Conditions:
		// The entity must exist in the Set and be allowed to mint new NFTs
		//
		// Returns: The NFT that was minted
		// 
		access(all)
		fun mint(entityID: UInt64, minterAddress: Address): @NFT{ 
			pre{ 
				self.retired[entityID] == false:
					"Cannot mint: the entity doesn't exist or has been retired."
			}
			
			// Gets the number of NFTs that have been minted for this Entity
			// to use as this NFT's serial number
			let mintNumber = self.numMintedPerEntity[entityID]!
			
			// Mint the new NFT
			let nft: @NFT <- create NFT(mintNumber: mintNumber + UInt64(1), entityID: entityID, setID: self.setID, minterAddress: minterAddress)
			
			// Increment the number of copies minted for this NFT
			self.numMintedPerEntity[entityID] = mintNumber + UInt64(1)
			
			// Increment the total number of NFTs minted for this Set
			self.totalMinted = self.totalMinted + UInt64(1)
			return <-nft
		}
		
		// batchMint mints an arbitrary quantity of NFTs 
		// and returns them as a Collection
		//
		// Parameters: entityID: the ID of the entity that the NFTs are minted for
		//			 quantity: The quantity of NFTs to be minted
		//
		// Returns: Collection object that contains all the NFTs that were minted
		//
		access(all)
		fun batchMint(entityID: UInt64, quantity: UInt64, minterAddress: Address): @Collection{ 
			let collection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				collection.deposit(token: <-self.mint(entityID: entityID, minterAddress: minterAddress))
				i = i + UInt64(1)
			}
			return <-collection
		}
		
		access(all)
		fun getEntities(): [UInt64]{ 
			return self.entities
		}
		
		access(all)
		fun getRetired():{ UInt64: Bool}{ 
			return self.retired
		}
		
		access(all)
		fun getNumMintedPerEntity():{ UInt64: UInt64}{ 
			return self.numMintedPerEntity
		}
		
		access(all)
		fun getTotalMinted(): UInt64{ 
			return self.totalMinted
		}
	}
	
	// Struct that contains all of the important data about a set
	// Can be easily queried by instantiating the `QuerySetData` object
	// with the desired set ID
	// let setData = FlowverseTreasures.QuerySetData(setID: 12)
	//
	access(all)
	struct QuerySetData{ 
		access(all)
		let setID: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let externalURL: String
		
		access(all)
		let thumbnailURL: String
		
		access(all)
		let bannerURL: String
		
		access(all)
		let royaltyReceiverAddress: Address
		
		access(all)
		let isPrivate: Bool
		
		access(all)
		var locked: Bool
		
		access(all)
		var totalMinted: UInt64
		
		access(self)
		var entities: [UInt64]
		
		access(self)
		var retired:{ UInt64: Bool}
		
		access(self)
		var numMintedPerEntity:{ UInt64: UInt64}
		
		init(setID: UInt64){ 
			pre{ 
				FlowverseTreasures.sets[setID] != nil:
					"The set with the given ID does not exist"
			}
			let set = (&FlowverseTreasures.sets[setID] as &Set?)!
			let setData = FlowverseTreasures.setDatas[setID]!
			self.setID = setID
			self.name = setData.name
			self.description = setData.description
			self.externalURL = setData.externalURL
			self.thumbnailURL = setData.thumbnailURL
			self.bannerURL = setData.bannerURL
			self.royaltyReceiverAddress = setData.royaltyReceiverAddress
			self.locked = set.locked
			self.isPrivate = setData.isPrivate
			self.totalMinted = set.getTotalMinted()
			self.entities = set.getEntities()
			self.retired = set.getRetired()
			self.numMintedPerEntity = set.getNumMintedPerEntity()
		}
		
		// getEntities returns the IDs of all the entities in the Set
		access(all)
		fun getEntities(): [UInt64]{ 
			return self.entities
		}
		
		// getRetired returns a mapping of entity IDs to retired state
		access(all)
		fun getRetired():{ UInt64: Bool}{ 
			return self.retired
		}
		
		// getNumMintedPerEntity returns a mapping of entity IDs to the number of NFTs minted for that entity
		access(all)
		fun getNumMintedPerEntity():{ UInt64: UInt64}{ 
			return self.numMintedPerEntity
		}
	}
	
	// NFT Resource that represents an instance of an entity in a set
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// Global unique NFT ID
		access(all)
		let id: UInt64
		
		// The ID of the Set that the NFT comes from
		access(all)
		let setID: UInt64
		
		// The ID of the Entity that the NFT references
		access(all)
		let entityID: UInt64
		
		// The minterAddress of the NFT
		access(all)
		let minterAddress: Address
		
		// The serial number of the NFT, number minted for this entity in the set
		access(all)
		let mintNumber: UInt64
		
		init(mintNumber: UInt64, entityID: UInt64, setID: UInt64, minterAddress: Address){ 
			FlowverseTreasures.totalSupply = FlowverseTreasures.totalSupply + UInt64(1)
			self.id = FlowverseTreasures.totalSupply
			self.mintNumber = mintNumber
			self.entityID = entityID
			self.setID = setID
			self.minterAddress = minterAddress
			emit NFTMinted(nftID: self.id, nftUUID: self.uuid, entityID: entityID, setID: self.setID, mintNumber: self.mintNumber, minterAddress: self.minterAddress)
		}
		
		access(all)
		fun name(): String{ 
			let name: String = FlowverseTreasures.getEntityMetaDataByField(entityID: self.entityID, field: "name") ?? ""
			return name.concat(" #").concat(self.mintNumber.toString())
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Edition>(), Type<MetadataViews.Traits>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Medias>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let querySetData = FlowverseTreasures.getSetData(setID: self.setID)!
			switch view{ 
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: FlowverseTreasures.CollectionStoragePath, publicPath: FlowverseTreasures.CollectionPublicPath, publicCollection: Type<&FlowverseTreasures.Collection>(), publicLinkedType: Type<&FlowverseTreasures.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-FlowverseTreasures.createEmptyCollection(nftType: Type<@FlowverseTreasures.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: querySetData.thumbnailURL), mediaType: "image")
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: querySetData.bannerURL), mediaType: "image")
					return MetadataViews.NFTCollectionDisplay(name: querySetData.name, description: querySetData.description, externalURL: MetadataViews.ExternalURL(querySetData.externalURL), squareImage: squareImage, bannerImage: bannerImage, socials:{ "discord": MetadataViews.ExternalURL("https://discord.gg/flowverse"), "twitter": MetadataViews.ExternalURL("https://twitter.com/flowverse_"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/flowverseofficial")})
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name(), description: FlowverseTreasures.getEntityMetaDataByField(entityID: self.entityID, field: "description") ?? "", thumbnail: MetadataViews.HTTPFile(url: FlowverseTreasures.getEntityMetaDataByField(entityID: self.entityID, field: "thumbnailURL") ?? ""))
				case Type<MetadataViews.Royalties>():
					let feeCut: UFix64 = 0.05
					let royalties: [MetadataViews.Royalty] = [MetadataViews.Royalty(receiver: getAccount(querySetData.royaltyReceiverAddress).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, cut: feeCut, description: "Creator Royalty Fee")]
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.mintNumber)
				case Type<MetadataViews.Edition>():
					return MetadataViews.Edition(name: FlowverseTreasures.getEntityMetaDataByField(entityID: self.entityID, field: "name") ?? "", number: self.mintNumber, max: nil)
				case Type<MetadataViews.Traits>():
					let traits: [MetadataViews.Trait] = []
					if let artist = FlowverseTreasures.getEntityMetaDataByField(entityID: self.entityID, field: "artist"){ 
						traits.append(MetadataViews.Trait(name: "Artist", value: artist, displayType: nil, rarity: nil))
					}
					if let edition = FlowverseTreasures.getEntityMetaDataByField(entityID: self.entityID, field: "edition"){ 
						traits.append(MetadataViews.Trait(name: "Edition", value: edition, displayType: nil, rarity: nil))
					}
					if let color = FlowverseTreasures.getEntityMetaDataByField(entityID: self.entityID, field: "color"){ 
						traits.append(MetadataViews.Trait(name: "Color", value: color, displayType: nil, rarity: nil))
					}
					return MetadataViews.Traits(traits)
				case Type<MetadataViews.ExternalURL>():
					let baseURL = "https://nft.flowverse.co/collections/FlowverseTreasures/"
					return MetadataViews.ExternalURL(baseURL.concat((self.owner!).address.toString()).concat("/".concat(self.id.toString())))
				case Type<MetadataViews.Medias>():
					let mediaURL = FlowverseTreasures.getEntityMetaDataByField(entityID: self.entityID, field: "mediaURL")
					let mediaType = FlowverseTreasures.getEntityMetaDataByField(entityID: self.entityID, field: "mediaType")
					if mediaURL != nil && mediaType != nil{ 
						let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: mediaURL!), mediaType: mediaType!)
						return MetadataViews.Medias([media])
					}
					return MetadataViews.Medias([])
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// SetMinter is a special authorization resource that
	// allows the owner to mint new NFTs
	access(all)
	resource SetMinter{ 
		access(all)
		let setID: UInt64
		
		init(setID: UInt64){ 
			self.setID = setID
		}
		
		access(all)
		fun mint(entityID: UInt64, minterAddress: Address): @NFT{ 
			let setRef = (&FlowverseTreasures.sets[self.setID] as &Set?)!
			return <-setRef.mint(entityID: entityID, minterAddress: minterAddress)
		}
	}
	
	// Admin is a special authorization resource that 
	// allows the owner to perform important functions to modify the 
	// various aspects of the entities and sets
	//
	access(all)
	resource Admin{ 
		
		// createEntity creates a new Entity struct 
		// and stores it in the Entities dictionary in the FlowverseTreasures smart contract
		access(all)
		fun createEntity(metadata:{ String: String}): UInt64{ 
			// Create the new Entity
			var entity = Entity(metadata: metadata)
			let entityID = entity.entityID
			emit EntityCreated(id: entityID, metadata: metadata)
			
			// Increment the ID so that it isn't used again
			FlowverseTreasures.nextEntityID = FlowverseTreasures.nextEntityID + UInt64(1)
			
			// Store it in the contract
			FlowverseTreasures.entityDatas[entityID] = entity
			return entityID
		}
		
		// updateEntity updates an existing Entity 
		access(all)
		fun updateEntity(entityID: UInt64, metadata:{ String: String}){ 
			let updatedEntity = FlowverseTreasures.entityDatas[entityID]!
			updatedEntity.metadata = metadata
			FlowverseTreasures.entityDatas[entityID] = updatedEntity
			emit EntityUpdated(id: entityID, metadata: metadata)
		}
		
		// createSet creates a new Set resource and stores it
		// in the sets mapping in the contract
		access(all)
		fun createSet(name: String, description: String, externalURL: String, thumbnailURL: String, bannerURL: String, royaltyReceiverAddress: Address, isPrivate: Bool): UInt64{ 
			// Create a new SetData for this Set
			let setData = SetData(setID: FlowverseTreasures.nextSetID, name: name, description: description, externalURL: externalURL, thumbnailURL: thumbnailURL, bannerURL: bannerURL, royaltyReceiverAddress: royaltyReceiverAddress, isPrivate: isPrivate)
			
			// Create the new Set
			var set <- create Set()
			
			// Increment the setID so that it isn't used again
			FlowverseTreasures.nextSetID = FlowverseTreasures.nextSetID + UInt64(1)
			let setID = set.setID
			emit SetCreated(setID: setID, name: name, description: description, externalURL: externalURL, isPrivate: isPrivate, thumbnailURL: thumbnailURL, bannerURL: bannerURL, royaltyReceiverAddress: royaltyReceiverAddress)
			
			// Store it in the contract
			FlowverseTreasures.setDatas[setID] = setData
			FlowverseTreasures.sets[setID] <-! set
			return setID
		}
		
		// updateSetData updates set info including: description, externalURL, thumbnailURL, bannerURL
		access(all)
		fun updateSetData(setID: UInt64, description: String?, externalURL: String?, thumbnailURL: String?, bannerURL: String?, royaltyReceiverAddress: Address?){ 
			pre{ 
				FlowverseTreasures.setDatas.containsKey(setID):
					"Set data does not exist"
				FlowverseTreasures.sets.containsKey(setID):
					"Set data does not exist"
				FlowverseTreasures.sets[setID]?.locked == false:
					"Locked set data cannot be updated"
			}
			var setData = FlowverseTreasures.setDatas[setID]!
			let updatedSetData = SetData(setID: setID, name: setData.name, description: description ?? setData.description, externalURL: externalURL ?? setData.externalURL, thumbnailURL: thumbnailURL ?? setData.thumbnailURL, bannerURL: bannerURL ?? setData.bannerURL, royaltyReceiverAddress: royaltyReceiverAddress ?? setData.royaltyReceiverAddress, isPrivate: setData.isPrivate)
			FlowverseTreasures.setDatas[setID] = updatedSetData
			emit SetUpdated(setID: setID, description: description, externalURL: externalURL, thumbnailURL: thumbnailURL, bannerURL: bannerURL, royaltyReceiverAddress: royaltyReceiverAddress)
		}
		
		// borrowSet returns a reference to a set in the contract
		// so that the admin can call methods on it
		access(all)
		fun borrowSet(setID: UInt64): &Set{ 
			pre{ 
				FlowverseTreasures.sets[setID] != nil:
					"Cannot borrow Set: The Set doesn't exist"
			}
			
			// Get a reference to the Set and return it
			// use `&` to indicate the reference to the object and type
			return (&FlowverseTreasures.sets[setID] as &Set?)!
		}
		
		access(all)
		fun createSetMinter(setID: UInt64): @SetMinter{ 
			return <-create SetMinter(setID: setID)
		}
		
		// createNewAdmin creates a new Admin resource
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	// Public interface for the FlowverseTreasures Collection that allows users access to certain functionalities
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
		fun borrowFlowverseTreasuresNFT(id: UInt64): &FlowverseTreasures.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow FlowverseTreasures reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
	}
	
	// Collection
	// A collection of FlowverseTreasures NFTs owned by an account
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
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <- create Collection()
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @FlowverseTreasures.NFT
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
		fun borrowFlowverseTreasuresNFT(id: UInt64): &FlowverseTreasures.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &FlowverseTreasures.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let flowverseNFT = nft as! &FlowverseTreasures.NFT
			return flowverseNFT as &{ViewResolver.Resolver}
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
	// FlowverseTreasures contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create FlowverseTreasures.Collection()
	}
	
	// getAllEntities returns all the entities available
	access(all)
	fun getAllEntities(): [FlowverseTreasures.Entity]{ 
		return FlowverseTreasures.entityDatas.values
	}
	
	// getEntity returns an entity by ID
	access(all)
	fun getEntity(entityID: UInt64): FlowverseTreasures.Entity?{ 
		return self.entityDatas[entityID]
	}
	
	// getEntityMetaData returns all the metadata associated with a specific entity
	access(all)
	fun getEntityMetaData(entityID: UInt64):{ String: String}?{ 
		return self.entityDatas[entityID]?.metadata
	}
	
	access(all)
	fun getEntityMetaDataByField(entityID: UInt64, field: String): String?{ 
		if let entity = FlowverseTreasures.entityDatas[entityID]{ 
			return entity.metadata[field]
		} else{ 
			return nil
		}
	}
	
	// getSetData returns the data that the specified Set
	//			is associated with.
	// 
	// Parameters: setID: The id of the Set that is being searched
	//
	// Returns: The QuerySetData struct that has all the important information about the set
	access(all)
	fun getSetData(setID: UInt64): QuerySetData?{ 
		if FlowverseTreasures.sets[setID] == nil{ 
			return nil
		} else{ 
			return QuerySetData(setID: setID)
		}
	}
	
	// getSetName returns the name that the specified Set
	//			is associated with.
	// 
	// Parameters: setID: The id of the Set that is being searched
	//
	// Returns: The name of the Set
	access(all)
	fun getSetName(setID: UInt64): String?{ 
		// Don't force a revert if the setID is invalid
		return FlowverseTreasures.setDatas[setID]?.name
	}
	
	// getSetIDsByName returns the IDs that the specified Set name
	//				 is associated with.
	access(all)
	fun getSetIDsByName(setName: String): [UInt64]?{ 
		var setIDs: [UInt64] = []
		for setData in FlowverseTreasures.setDatas.values{ 
			if setName == setData.name{ 
				setIDs.append(setData.setID)
			}
		}
		if setIDs.length == 0{ 
			return nil
		} else{ 
			return setIDs
		}
	}
	
	// getAllSetDatas returns all the set datas available
	access(all)
	fun getAllSetDatas(): [SetData]{ 
		return FlowverseTreasures.setDatas.values
	}
	
	// getEntitiesInSet returns the list of Entity IDs that are in the Set
	access(all)
	fun getEntitiesInSet(setID: UInt64): [UInt64]?{ 
		return FlowverseTreasures.sets[setID]?.getEntities()
	}
	
	// isSetEntityRetired returns a boolean that indicates if a Set/Entity combination
	//				  is retired.
	//				  If an entity is retired, it still remains in the Set,
	//				  but NFTs can no longer be minted from it.
	access(all)
	fun isSetEntityRetired(setID: UInt64, entityID: UInt64): Bool?{ 
		if let setdata = self.getSetData(setID: setID){ 
			// See if the Entity is retired from this Set
			let retired = setdata.getRetired()[entityID]
			
			// Return the retired status
			return retired
		} else{ 
			// If the Set wasn't found, return nil
			return nil
		}
	}
	
	access(all)
	fun isSetLocked(setID: UInt64): Bool?{ 
		return FlowverseTreasures.sets[setID]?.locked
	}
	
	// getNumInstancesOfEntity return the number of entity instances that have been 
	//						minted in a set.
	//
	// Parameters: setID: The id of the Set that is being searched
	//			 entityID: The id of the Entity that is being searched
	//
	// Returns: The total number of entity instances (NFTs) 
	//		  that have been minted in a set
	access(all)
	fun getNumInstancesOfEntity(setID: UInt64, entityID: UInt64): UInt64?{ 
		if let setdata = self.getSetData(setID: setID){ 
			return setdata.getNumMintedPerEntity()[entityID]
		} else{ 
			// If the set wasn't found return nil
			return nil
		}
	}
	
	// -----------------------------------------------------------------------
	// FlowverseTreasures initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		self.CollectionStoragePath = /storage/FlowverseTreasuresCollection
		self.CollectionPublicPath = /public/FlowverseTreasuresCollection
		self.AdminStoragePath = /storage/FlowverseTreasuresAdmin
		
		// Initialize contract fields
		self.entityDatas ={} 
		self.setDatas ={} 
		self.sets <-{} 
		self.nextEntityID = 1
		self.nextSetID = 1
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
