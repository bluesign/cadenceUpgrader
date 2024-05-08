import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Evolution: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// Evolution contract Events
	// -----------------------------------------------------------------------
	
	// Emitted when the Evolution contract is created
	access(all)
	event ContractInitialized()
	
	// Emitted when a new Item struct is created
	access(all)
	event ItemCreated(id: UInt32, metadata:{ String: String})
	
	// Emitted when a new series has been started
	access(all)
	event NewSeriesStarted(newCurrentSeries: UInt32)
	
	// Events for Set-Related actions
	//
	// Emitted when a new Set is created
	access(all)
	event SetCreated(setId: UInt32, series: UInt32)
	
	// Emitted when a new Item is added to a Set
	access(all)
	event ItemAddedToSet(setId: UInt32, itemId: UInt32)
	
	// Emitted when an Item is retired from a Set and cannot be used to mint
	access(all)
	event ItemRetiredFromSet(setId: UInt32, itemId: UInt32, minted: UInt32)
	
	// Emitted when a Set is locked, meaning collectibles cannot be added
	access(all)
	event SetLocked(setId: UInt32)
	
	// Emitted when a collectible is minted from a Set
	access(all)
	event CollectibleMinted(id: UInt64, itemId: UInt32, setId: UInt32, serialNumber: UInt32)
	
	// Emitted when a collectible is destroyed
	access(all)
	event CollectibleDestroyed(id: UInt64)
	
	// Events for Collection-related actions
	//
	// Emitted when a collectible is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when a collectible is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// -----------------------------------------------------------------------
	// Evolution contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// Series that this Set belongs to.
	// Many Sets can exist at a time, but only one series.
	access(all)
	var currentSeries: UInt32
	
	// Variable size dictionary of Item structs
	access(self)
	var itemDatas:{ UInt32: Item}
	
	// Variable size dictionary of SetData structs
	access(self)
	var setDatas:{ UInt32: SetData}
	
	// Variable size dictionary of Set resources
	access(self)
	var sets: @{UInt32: Set}
	
	// The Id that is used to create Items.
	// Every time an Item is created, nextItemId is assigned
	// to the new Item's Id and then is incremented by one.
	access(all)
	var nextItemId: UInt32
	
	// The Id that is used to create Sets.
	// Every time a Set is created, nextSetId is assigned
	// to the new Set's Id and then is incremented by one.
	access(all)
	var nextSetId: UInt32
	
	// The total number of Collectible NFTs that have been created
	// Because NFTs can be destroyed, it doesn't necessarily mean that this
	// reflects the total number of NFTs in existence, just the number that
	// have been minted to date.
	access(all)
	var totalSupply: UInt64
	
	// -----------------------------------------------------------------------
	// Evolution contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// -----------------------------------------------------------------------
	// Item is a Struct that holds metadata associated with a specific collectible item.
	access(all)
	struct Item{ 
		
		// The unique Id for the Item
		access(all)
		let itemId: UInt32
		
		// Stores all the metadata about the item as a string mapping.
		access(all)
		let metadata:{ String: String}
		
		init(metadata:{ String: String}){ 
			pre{ 
				metadata.length != 0:
					"New Item metadata cannot be empty"
			}
			self.itemId = Evolution.nextItemId
			self.metadata = metadata
			
			// Increment the Id so that it isn't used again
			Evolution.nextItemId = Evolution.nextItemId + UInt32(1)
			emit ItemCreated(id: self.itemId, metadata: metadata)
		}
	}
	
	// A Set is a grouping of Items that make up a related group of collectibles,
	// like sets of baseball cards.
	// An Item can exist in multiple different sets.
	//
	// SetData is a struct that is stored in a field of the contract.
	// Anyone can query the constant information
	// about a set by calling various getters located
	// at the end of the contract. Only the admin has the ability
	// to modify any data in the private Set resource.
	access(all)
	struct SetData{ 
		
		// Unique Id for the Set
		access(all)
		let setId: UInt32
		
		// Name of the Set
		access(all)
		let name: String
		
		// Description of the Set
		access(all)
		let description: String?
		
		// Series that this Set belongs to
		access(all)
		let series: UInt32
		
		init(name: String, description: String?){ 
			pre{ 
				name.length > 0:
					"New Set name cannot be empty"
			}
			self.setId = Evolution.nextSetId
			self.name = name
			self.description = description
			self.series = Evolution.currentSeries
			
			// Increment the setId so that it isn't used again
			Evolution.nextSetId = Evolution.nextSetId + UInt32(1)
			emit SetCreated(setId: self.setId, series: self.series)
		}
	}
	
	// Set is a resource type that contains the functions to add and remove
	// Items from a set and mint Collectibles.
	//
	// It is stored in a private field in the contract so that
	// the admin resource can call its methods.
	//
	// The admin can add Items to a Set so that the set can mint Collectibles.
	// The Collectible that is minted by a Set will be listed as belonging to
	// the Set that minted it, as well as the Item it reference.
	//
	// Admin can also retire Items from the Set, meaning that the retired
	// Item can no longer have Collectibles minted from it.
	//
	// If the admin locks the Set, no more Items can be added to it, but
	// Collectibles can still be minted.
	//
	// If retireAll() and lock() are called back-to-back,
	// the Set is closed off forever and nothing more can be done with it.
	access(all)
	resource Set{ 
		
		// Unique Id for the set
		access(all)
		let setId: UInt32
		
		// Array of items that are a part of this set.
		// When an item is added to the set, its Id gets appended here.
		// The Id does not get removed from this array when an Item is retired.
		access(all)
		var items: [UInt32]
		
		// Map of Item Ids that indicates if an Item in this Set can be minted.
		// When an Item is added to a Set, it is mapped to false (not retired).
		// When an Item is retired, this is set to true and cannot be changed.
		access(all)
		var retired:{ UInt32: Bool}
		
		// Indicates if the Set is currently locked.
		// When a Set is created, it is unlocked and Items are allowed to be added to it.
		// When a set is locked, Items cannot be added to it.
		// A Set can't transition from locked to unlocked. Locking is final.
		// If a Set is locked, Items cannot be added, but Collectibles can still be minted
		// from Items that exist in the Set.
		access(all)
		var locked: Bool
		
		// Mapping of Item Ids that indicates the number of Collectibles
		// that have been minted for specific Items in this Set.
		// When a Collectible is minted, this value is stored in the Collectible to
		// show its place in the Set, eg. 42 of 100.
		access(all)
		var numberMintedPerItem:{ UInt32: UInt32}
		
		init(name: String, description: String?){ 
			self.setId = Evolution.nextSetId
			self.items = []
			self.retired ={} 
			self.locked = false
			self.numberMintedPerItem ={} 
			
			// Create a new SetData for this Set and store it in contract storage
			Evolution.setDatas[self.setId] = SetData(name: name, description: description)
		}
		
		// Add an Item to the Set
		//
		// Pre-Conditions:
		// The Item exists.
		// The Set is unlocked.
		// The Item is not present in the Set.
		access(all)
		fun addItem(itemId: UInt32){ 
			pre{ 
				Evolution.itemDatas[itemId] != nil:
					"Cannot add the Item to Set: Item doesn't exist."
				!self.locked:
					"Cannot add the Item to the Set after the set has been locked."
				self.numberMintedPerItem[itemId] == nil:
					"The Item has already beed added to the set."
			}
			
			// Add the Item to the array of Items
			self.items.append(itemId)
			
			// Allow minting for Item
			self.retired[itemId] = false
			
			// Initialize the Collectible count to zero
			self.numberMintedPerItem[itemId] = 0
			emit ItemAddedToSet(setId: self.setId, itemId: itemId)
		}
		
		// Adds multiple Items to the Set
		access(all)
		fun addItems(itemIds: [UInt32]){ 
			for id in itemIds{ 
				self.addItem(itemId: id)
			}
		}
		
		// Retire an Item from the Set. The Set can't mint new Collectibles for the Item.
		// Pre-Conditions:
		// The Item is part of the Set and not retired.
		access(all)
		fun retireItem(itemId: UInt32){ 
			pre{ 
				self.retired[itemId] != nil:
					"Cannot retire the Item: Item doesn't exist in this set!"
			}
			if !self.retired[itemId]!{ 
				self.retired[itemId] = true
				emit ItemRetiredFromSet(setId: self.setId, itemId: itemId, minted: self.numberMintedPerItem[itemId]!)
			}
		}
		
		// Retire all the Items in the Set
		access(all)
		fun retireAll(){ 
			for id in self.items{ 
				self.retireItem(itemId: id)
			}
		}
		
		// Lock the Set so that no more Items can be added to it.
		//
		// Pre-Conditions:
		// The Set is unlocked
		access(all)
		fun lock(){ 
			if !self.locked{ 
				self.locked = true
				emit SetLocked(setId: self.setId)
			}
		}
		
		// Mint a new Collectible and returns the newly minted Collectible.
		// Pre-Conditions:
		// The Item must exist in the Set and be allowed to mint new Collectibles
		access(all)
		fun mintCollectible(itemId: UInt32): @NFT{ 
			pre{ 
				self.retired[itemId] != nil:
					"Cannot mint the collectible: This item doesn't exist."
				!self.retired[itemId]!:
					"Cannot mint the collectible from this item: This item has been retired."
			}
			
			// Gets the number of Collectibles that have been minted for this Item
			// to use as this Collectibles's serial number
			let minted = self.numberMintedPerItem[itemId]!
			
			// Mint the new collectible
			let newCollectible: @NFT <- create NFT(serialNumber: minted + UInt32(1), itemId: itemId, setId: self.setId)
			
			// Increment the count of Collectibles minted for this Item
			self.numberMintedPerItem[itemId] = minted + UInt32(1)
			return <-newCollectible
		}
		
		// Mint an arbitrary quantity of Collectibles and return them as a Collection
		access(all)
		fun batchMintCollectible(itemId: UInt32, quantity: UInt64): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintCollectible(itemId: itemId))
				i = i + UInt64(1)
			}
			return <-newCollection
		}
	}
	
	// Struct of Collectible metadata
	access(all)
	struct CollectibleData{ 
		
		// The Id of the Set that the Collectible comes from
		access(all)
		let setId: UInt32
		
		// The Id of the Item that the Collectible references
		access(all)
		let itemId: UInt32
		
		// The place in the edition that this Collectible was minted
		access(all)
		let serialNumber: UInt32
		
		init(setId: UInt32, itemId: UInt32, serialNumber: UInt32){ 
			self.setId = setId
			self.itemId = itemId
			self.serialNumber = serialNumber
		}
	}
	
	// The resource that represents the Collectible NFT
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		
		// Global unique Collectible Id
		access(all)
		let id: UInt64
		
		// Struct of Collectible metadata
		access(all)
		let data: CollectibleData
		
		init(serialNumber: UInt32, itemId: UInt32, setId: UInt32){ 
			
			// Increment the global Collectible Id
			Evolution.totalSupply = Evolution.totalSupply + UInt64(1)
			self.id = Evolution.totalSupply
			self.data = CollectibleData(setId: setId, itemId: itemId, serialNumber: serialNumber)
			emit CollectibleMinted(id: self.id, itemId: itemId, setId: setId, serialNumber: self.data.serialNumber)
		}
		
		// If the Collectible is destroyed, emit an event
		// Metdata Views
		access(all)
		fun name(): String{ 
			if let field = Evolution.getItemMetadataByField(itemId: self.data.itemId, field: "Title"){ 
				return field
			}
			return ""
		}
		
		access(all)
		fun description(): String{ 
			if let field = Evolution.getItemMetadataByField(itemId: self.data.itemId, field: "Description"){ 
				return field
			}
			return ""
		}
		
		access(all)
		fun contentID(): String{ 
			return "bafybeiefzzhayvk6qeb7l2avjfwwdlgzzxqpj2qh4u33szbjqzlqg6vmfa"
		}
		
		access(all)
		fun thumbnail(): MetadataViews.IPFSFile{ 
			return MetadataViews.IPFSFile(cid: self.contentID(), path: "thumbs/".concat(self.data.itemId.toString()).concat(".png"))
		}
		
		access(all)
		fun originalMedia(): MetadataViews.Media{ 
			var mediaType = "video/mp4"
			var extension = ".mp4"
			return MetadataViews.Media(file: MetadataViews.IPFSFile(cid: self.contentID(), path: self.data.itemId.toString().concat(extension)), mediaType: mediaType)
		}
		
		access(all)
		fun serialNumber(): UInt64{ 
			return UInt64(self.data.serialNumber)
		}
		
		access(all)
		fun creatorAddress(): Address{ 
			return 0x77b78d7d3f0d1787
		}
		
		access(all)
		fun editionName(): String{ 
			return self.name()
		}
		
		access(all)
		fun editionNumber(): UInt64{ 
			return UInt64(self.data.serialNumber)
		}
		
		access(all)
		fun maxEditions(): UInt64{ 
			if let editions = Evolution.getNumberCollectiblesInEdition(setId: self.data.setId, itemId: self.data.itemId){ 
				return UInt64(editions)
			}
			return UInt64(0)
		}
		
		access(all)
		fun collectionName(): String{ 
			return "Evolution"
		}
		
		access(all)
		fun collectionDescription(): String{ 
			return ""
		}
		
		access(all)
		fun collectionURL(): MetadataViews.ExternalURL{ 
			return MetadataViews.ExternalURL("https://www.evolution-collect.com")
		}
		
		access(all)
		fun squareImage(): MetadataViews.Media{ 
			return MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://nftstorage.link/ipfs/bafkreiddhegxjpqm4wz3ib6wb4wceploarw5otnvox43hqnfb6ou2376im"), mediaType: "image/png")
		}
		
		access(all)
		fun bannerImage(): MetadataViews.Media{ 
			return MetadataViews.Media(file: MetadataViews.HTTPFile(url: ""), mediaType: "image/png")
		}
		
		access(all)
		fun tier(): String{ 
			if let editions = Evolution.getNumberCollectiblesInEdition(setId: self.data.setId, itemId: self.data.itemId){ 
				switch editions{ 
					case 50:
						return "Legendary"
					case 100:
						return "Rare"
					case 888:
						return "Common"
					case 277:
						return "Reward"
					case 37:
						return "Reward"
					case 29:
						return "Reward"
					case 10:
						return "Reward"
					case 9:
						return "Reward"
					default:
						return "Other"
				}
			}
			return ""
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Medias>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name(), description: self.description(), thumbnail: self.thumbnail())
				case Type<MetadataViews.Editions>():
					let editions: [MetadataViews.Edition] = [MetadataViews.Edition(name: self.editionName(), number: self.editionNumber(), max: self.maxEditions())]
					return MetadataViews.Editions(editions)
				case Type<MetadataViews.Royalties>():
					let creator = getAccount(self.creatorAddress())
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: creator.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, cut: 0.10, description: "Creator earnings")])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://shadow.is/A.f4264ac8f3256818.Evolution/".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: /storage/f4264ac8f3256818_Evolution_Collection, publicPath: /public/f4264ac8f3256818_Evolution_Collection, publicCollection: Type<&Evolution.Collection>(), publicLinkedType: Type<&Evolution.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Evolution.createEmptyCollection(nftType: Type<@Evolution.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					return MetadataViews.NFTCollectionDisplay(name: self.collectionName(), description: self.collectionDescription(), externalURL: self.collectionURL(), squareImage: self.squareImage(), bannerImage: self.bannerImage(), socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/BenMauroArt")})
				case Type<MetadataViews.Traits>():
					let traits:{ String: AnyStruct} ={ "Tier": self.tier()}
					return MetadataViews.dictToTraits(dict: traits, excludedNames: nil)
				case Type<MetadataViews.Medias>():
					return MetadataViews.Medias([self.originalMedia()])
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.serialNumber())
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Admin is an authorization resource that allows the owner to modify
	// various aspects of the Items, Sets, and Collectibles
	access(all)
	resource Admin{ 
		// Create a new Item struct and store it in the Items dictionary in the contract
		access(all)
		fun createItem(metadata:{ String: String}): UInt32{ 
			var newItem = Item(metadata: metadata)
			let newId = newItem.itemId
			Evolution.itemDatas[newId] = newItem
			return newId
		}
		
		// Create a new Set resource and store it in the sets mapping in the contract
		access(all)
		fun createSet(name: String, description: String?){ 
			var newSet <- create Set(name: name, description: description)
			Evolution.sets[newSet.setId] <-! newSet
		}
		
		// Return a reference to a set in the contract
		access(all)
		fun borrowSet(setId: UInt32): &Set{ 
			pre{ 
				Evolution.sets[setId] != nil:
					"Cannot borrow set: The set doesn't exist."
			}
			return (&Evolution.sets[setId] as &Set?)!
		}
		
		// End the current series and start a new one
		access(all)
		fun startNewSeries(): UInt32{ 
			Evolution.currentSeries = Evolution.currentSeries + UInt32(1)
			emit NewSeriesStarted(newCurrentSeries: Evolution.currentSeries)
			return Evolution.currentSeries
		}
		
		// Create a new Admin resource
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	// Interface that users can cast their Evolution Collection as
	// to allow others to deposit Evolution Collectibles into their Collection.
	access(all)
	resource interface EvolutionCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowCollectible(id: UInt64): &Evolution.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow collectible reference: The id of the returned reference is incorrect."
			}
		}
	}
	
	// Collection is a resource that every user who owns NFTs
	// will store in their account to manage their NFTS
	access(all)
	resource Collection: EvolutionCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// Dictionary of Collectible conforming tokens
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// Remove a Collectible from the Collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Collectible does not exist in the collection.")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// Withdraw multiple tokens and returns them as a Collection
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <- create Collection()
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		// Add a Collectible to the Collections dictionary
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			
			// Cast the deposited token as a Collectible NFT to make sure
			// it is the correct type
			let token <- token as! @Evolution.NFT
			let id = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			
			// Emit a deposit event if the Collection is in an account's storage
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			
			// Destroy the empty removed token
			destroy oldToken
		}
		
		// Deposit multiple NFTs into this Collection
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			let keys = tokens.getIDs()
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			
			// Destroy the empty Collection
			destroy tokens
		}
		
		// Get the Ids that are in the Collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// Return a borrowed reference to a Collectible in the Collection
		// This only allows the caller to read the ID of the NFT,
		// not any Collectible specific data.
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// Return a borrowed reference to a Collectible
		// This  allows the caller to read the setId, itemId, serialNumber,
		// and use them to read the setData or Item data from the contract
		access(all)
		fun borrowCollectible(id: UInt64): &Evolution.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Evolution.NFT
			} else{ 
				return nil
			}
		}
		
		// Metadata Views
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let collectible = nft as! &NFT
			return collectible
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
	
	// If a transaction destroys the Collection object,
	// All the NFTs contained within are also destroyed!
	}
	
	// -----------------------------------------------------------------------
	// Evolution contract-level function definitions
	// -----------------------------------------------------------------------
	// Create a new, empty Collection object so that a user can store it in their account storage
	// and be able to receive Collectibles
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Evolution.Collection()
	}
	
	// Return all the Collectible Items
	access(all)
	fun getAllItems(): [Evolution.Item]{ 
		return Evolution.itemDatas.values
	}
	
	// Get all metadata of an Item
	access(all)
	fun getItemMetadata(itemId: UInt32):{ String: String}?{ 
		return self.itemDatas[itemId]?.metadata
	}
	
	// Get a metadata field of an Item
	access(all)
	fun getItemMetadataByField(itemId: UInt32, field: String): String?{ 
		if let item = Evolution.itemDatas[itemId]{ 
			return item.metadata[field]
		} else{ 
			return nil
		}
	}
	
	// Get the name of the Set
	access(all)
	fun getSetName(setId: UInt32): String?{ 
		return Evolution.setDatas[setId]?.name
	}
	
	// Get the description of the Set
	access(all)
	fun getSetDescription(setId: UInt32): String?{ 
		return Evolution.setDatas[setId]?.description
	}
	
	// Get the series that the specified Set is associated with
	access(all)
	fun getSetSeries(setId: UInt32): UInt32?{ 
		return Evolution.setDatas[setId]?.series
	}
	
	// Get the Ids that the specified Set name is associated with
	access(all)
	fun getSetIdsByName(setName: String): [UInt32]?{ 
		var setIds: [UInt32] = []
		for setData in Evolution.setDatas.values{ 
			if setName == setData.name{ 
				setIds.append(setData.setId)
			}
		}
		if setIds.length == 0{ 
			return nil
		} else{ 
			return setIds
		}
	}
	
	// Get the list of Item Ids that are in the Set
	access(all)
	fun getItemsInSet(setId: UInt32): [UInt32]?{ 
		return Evolution.sets[setId]?.items
	}
	
	// Indicates if a Set/Item combo (otherwise known as an edition) is retired
	access(all)
	fun isEditionRetired(setId: UInt32, itemId: UInt32): Bool?{ 
		if let setToRead <- Evolution.sets.remove(key: setId){ 
			let retired = setToRead.retired[itemId]
			Evolution.sets[setId] <-! setToRead
			return retired
		} else{ 
			return nil
		}
	}
	
	// Indicates if the Set is locked or not
	access(all)
	fun isSetLocked(setId: UInt32): Bool?{ 
		return Evolution.sets[setId]?.locked
	}
	
	// Total number of Collectibles that have been minted from an edition
	access(all)
	fun getNumberCollectiblesInEdition(setId: UInt32, itemId: UInt32): UInt32?{ 
		if let setToRead <- Evolution.sets.remove(key: setId){ 
			let amount = setToRead.numberMintedPerItem[itemId]
			
			// Put the Set back into the Sets dictionary
			Evolution.sets[setId] <-! setToRead
			return amount
		} else{ 
			return nil
		}
	}
	
	// -----------------------------------------------------------------------
	// Evolution initialization function
	// -----------------------------------------------------------------------
	init(){ 
		self.currentSeries = 0
		self.itemDatas ={} 
		self.setDatas ={} 
		self.sets <-{} 
		self.nextItemId = 1
		self.nextSetId = 1
		self.totalSupply = 0
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: /storage/EvolutionCollection)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{EvolutionCollectionPublic}>(/storage/EvolutionCollection)
		self.account.capabilities.publish(capability_1, at: /public/EvolutionCollection)
		
		// Put the Admin in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: /storage/EvolutionAdmin)
		emit ContractInitialized()
	}
}
