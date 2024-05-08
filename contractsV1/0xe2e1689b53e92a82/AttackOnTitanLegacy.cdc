//  SPDX-License-Identifier: UNLICENSED
//
//  Description: Attack On Titan Legacy
//  This is NonFungibleToken and Anique NFT.
//
//  authors: Atsushi Otani atsushi.ootani@anique.jp
//
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import Anique from "./Anique.cdc"

access(all)
contract AttackOnTitanLegacy: NonFungibleToken, Anique{ 
	// -----------------------------------------------------------------------
	// AttackOnTitanLegacy contract Events
	// -----------------------------------------------------------------------
	
	// Events for Contract-Related actions
	//
	// Emitted when the AttackOnTitanLegacy contract is created
	access(all)
	event ContractInitialized()
	
	// Events for Set-Related actions
	//
	// emitted when a new Set is created
	access(all)
	event SetCreated(setID: UInt32, name: String)
	
	// emitted when a new play is added to a set
	access(all)
	event ItemAddedToSet(setID: UInt32, itemID: UInt32)
	
	// Events for Item-Related actions
	//
	// Emitted when a new Item struct is created
	access(all)
	event ItemCreated(id: UInt32, metadata:{ String: String})
	
	// Events for Collectible-Related actions
	//
	// Emitted when an CollectibleData NFT is minted
	access(all)
	event CollectibleMinted(collectibleID: UInt64, itemID: UInt32, setID: UInt32, serialNumber: UInt32)
	
	// Emitted when an CollectibleData NFT is destroyed
	access(all)
	event CollectibleDestroyed(collectibleID: UInt64)
	
	// events for Collection-related actions
	//
	// Emitted when an CollectibleData is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when an CollectibleData is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// paths
	access(all)
	let collectionStoragePath: StoragePath
	
	access(all)
	let collectionPublicPath: PublicPath
	
	access(all)
	let collectionPrivatePath: PrivatePath
	
	access(all)
	let adminStoragePath: StoragePath
	
	access(all)
	let saleCollectionStoragePath: StoragePath
	
	access(all)
	let saleCollectionPublicPath: PublicPath
	
	// -----------------------------------------------------------------------
	// AttackOnTitanLegacy contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// fields for Set-related
	//
	// variable size dictionary of Set resources
	access(self)
	var sets: @{UInt32: Set}
	
	// the ID that is used to create Sets. Every time a Set is created
	// setID is assigned to the new set's ID and then is incremented by 1.
	access(all)
	var nextSetID: UInt32
	
	// fields for Item-related
	//
	// Variable size dictionary of Item structs
	access(self)
	var itemDatas:{ UInt32: Item}
	
	// The ID that is used to create Items.
	access(all)
	var nextItemID: UInt32
	
	// fields for Collectible-related
	//
	// Total number of CollectibleData NFTs that have been minted ever.
	access(all)
	var totalSupply: UInt64
	
	// -----------------------------------------------------------------------
	// AttackOnTitanLegacy contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// The structure that represents Item
	// each digital content which AttackOnTitanLegacy deal with on Flow
	//
	access(all)
	struct Item{ 
		
		// The unique ID for the Item
		access(all)
		let itemID: UInt32
		
		// Stores all the metadata about the item as a string mapping
		// This is not the long term way NFT metadata will be stored. It's a temporary
		// construct while we figure out a better way to do metadata.
		//
		access(all)
		let metadata:{ String: String}
		
		init(metadata:{ String: String}){ 
			pre{ 
				metadata.length != 0:
					"New Item metadata cannot be empty"
			}
			self.itemID = AttackOnTitanLegacy.nextItemID
			self.metadata = metadata
		}
	}
	
	// SetData is a struct that is stored in a public field of the contract.
	// This is to allow anyone to be able to query the constant information
	// about a set but not have the ability to modify any data in the
	// private set resource
	//
	access(all)
	struct SetData{ 
		// unique ID for the set
		access(all)
		let setID: UInt32
		
		// Name of the Set
		access(all)
		let name: String
		
		// Array of Items that are a part of this Set
		// When an Item is added to the Set, its ID gets appended here
		access(all)
		var items: [UInt32]
		
		// Indicates the number of Collectibles
		// that have been minted per Item in this Set
		// When a Collectible is minted, this value is stored in the Collectible to
		// show where in the Item Set it is so far. ex. 13 of 60
		access(all)
		var numberMintedPerItem:{ UInt32: UInt32}
		
		init(setID: UInt32){ 
			pre{ 
				AttackOnTitanLegacy.sets[setID] != nil:
					"Set doesn't exist"
			}
			
			// remove the Set from the dictionary to get its field
			if let setToRead <- AttackOnTitanLegacy.sets.remove(key: setID){ 
				self.setID = setID
				self.name = setToRead.name
				self.items = setToRead.getItems()
				self.numberMintedPerItem = setToRead.getNumberMintedPerItem()
				
				// put the set back
				AttackOnTitanLegacy.sets[setID] <-! setToRead
			} else{ 
				self.setID = 0
				self.name = ""
				self.items = []
				self.numberMintedPerItem ={} 
			}
		}
	}
	
	// Set is a resource type that contains the functions to add and remove
	// Items from a Set and mint Collectibles.
	//
	// It is stored in a private field in the contract so that
	// the admin resource can call its methods and that there can be
	// public getters for some of its fields
	//
	// The admin can add Items to a Set so that the Set can mint Collectibles
	// that reference that Item.
	// The Collectibles that are minted by a Set will be listed as belonging to
	// the Set that minted it, as well as the Item it references
	//
	access(all)
	resource Set{ 
		
		// unique ID for the set
		access(all)
		let setID: UInt32
		
		// Name of the Set
		access(all)
		let name: String
		
		// Array of Items that are a part of this Set
		// When an Item is added to the Set, its ID gets appended here
		access(self)
		var items: [UInt32]
		
		// Indicates the number of Collectibles
		// that have been minted per Item in this Set
		// When a Collectible is minted, this value is stored in the Collectible to
		// show where in the Item Set it is so far. ex. 13 of 60
		access(self)
		var numberMintedPerItem:{ UInt32: UInt32}
		
		init(name: String){ 
			pre{ 
				name.length > 0:
					"New Set name cannot be empty"
			}
			self.setID = AttackOnTitanLegacy.nextSetID
			self.name = name
			self.items = []
			self.numberMintedPerItem ={} 
			
			// increment the setID so that it isn't used again
			AttackOnTitanLegacy.nextSetID = AttackOnTitanLegacy.nextSetID + 1 as UInt32
			emit SetCreated(setID: self.setID, name: self.name)
		}
		
		// addItem adds an Item to the Set
		//
		// Parameters: itemID: The ID of the Item that is being added
		//
		// Pre-Conditions:
		// The Item needs to be an existing Item
		// The Item can't have already been added to the Set
		//
		access(all)
		fun addItem(itemID: UInt32){ 
			pre{ 
				AttackOnTitanLegacy.itemDatas[itemID] != nil:
					"Cannot add the Item to Set: Item doesn't exist"
				self.numberMintedPerItem[itemID] == nil:
					"The Item has already been added to the Set"
			}
			
			// Add the Item to the array of Items
			self.items.append(itemID)
			
			// Initialize the Collectible count to zero
			self.numberMintedPerItem[itemID] = 0
			emit ItemAddedToSet(setID: self.setID, itemID: itemID)
		}
		
		// addItems adds multiple Items to the Set
		//
		// Parameters: itemIDs: The IDs of the Items that are being added
		//					  as an array
		//
		access(all)
		fun addItems(itemIDs: [UInt32]){ 
			for itemID in itemIDs{ 
				self.addItem(itemID: itemID)
			}
		}
		
		// mintCollectible mints a new Collectible and returns the newly minted Collectible
		//
		// Parameters: itemID: The ID of the Item that the Collectible references
		//
		// Pre-Conditions:
		// The Item must exist in the Set and be allowed to mint new Collectibles
		//
		// Returns: The NFT that was minted
		//
		access(all)
		fun mintCollectible(itemID: UInt32): @NFT{ 
			// get the number of Collectibles that have been minted for this Item
			// to use as this Collectible's serial number
			let numInItem = self.numberMintedPerItem[itemID]!
			
			// mint the new Collectible
			let newCollectible: @NFT <- create NFT(serialNumber: numInItem + 1 as UInt32, itemID: itemID, setID: self.setID)
			
			// Increment the count of Collectibles minted for this Item
			self.numberMintedPerItem[itemID] = numInItem + 1 as UInt32
			return <-newCollectible
		}
		
		// batchMintCollectible mints an arbitrary quantity of Collectibles
		// and returns them as a Collection
		//
		// Parameters: itemID: the ID of the Item that the Collectibles are minted for
		//			 quantity: The quantity of Collectibles to be minted
		//
		// Returns: Collection object that contains all the Collectibles that were minted
		//
		access(all)
		fun batchMintCollectible(itemID: UInt32, quantity: UInt64): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintCollectible(itemID: itemID))
				i = i + 1 as UInt64
			}
			return <-newCollection
		}
		
		// Returns: Array of Items that are a part of this Set
		access(all)
		fun getItems(): [UInt32]{ 
			return self.items
		}
		
		// Returns: the number of Collectibles
		// that have been minted per Item in this Set
		access(all)
		fun getNumberMintedPerItem():{ UInt32: UInt32}{ 
			return self.numberMintedPerItem
		}
	}
	
	// The structure holds metadata of an Collectible
	access(all)
	struct CollectibleData{ 
		
		// the ID of the Set that the Collectible comes from
		access(all)
		let setID: UInt32
		
		// The ID of the Item that the Collectible references
		access(all)
		let itemID: UInt32
		
		// The place in the Item that this Collectible was minted
		access(all)
		let serialNumber: UInt32
		
		init(setID: UInt32, itemID: UInt32, serialNumber: UInt32){ 
			self.setID = setID
			self.itemID = itemID
			self.serialNumber = serialNumber
		}
	}
	
	// The resource that represents the CollectibleData NFTs
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, Anique.INFT{ 
		
		// Global unique collectibleData ID
		access(all)
		let id: UInt64
		
		// Struct of Collectible metadata
		access(all)
		let data: CollectibleData
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(serialNumber: UInt32, itemID: UInt32, setID: UInt32){ 
			// Increment the global Collectible IDs
			AttackOnTitanLegacy.totalSupply = AttackOnTitanLegacy.totalSupply + 1 as UInt64
			
			// set id
			self.id = AttackOnTitanLegacy.totalSupply
			
			// Set the metadata struct
			self.data = CollectibleData(setID: setID, itemID: itemID, serialNumber: serialNumber)
			emit CollectibleMinted(collectibleID: self.id, itemID: itemID, setID: setID, serialNumber: self.data.serialNumber)
		}
	}
	
	// interface that represents AttackOnTitanLegacy collections to public
	// extends of NonFungibleToken.CollectionPublic
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		// deposit multi tokens
		access(all)
		fun batchDeposit(tokens: @{Anique.Collection})
		
		// contains NFT
		access(all)
		fun contains(id: UInt64): Bool
		
		// borrow NFT as AttackOnTitanLegacy token
		access(all)
		fun borrowAttackOnTitanLegacyCollectible(id: UInt64): &NFT
	}
	
	// Collection is a resource that every user who owns NFTs
	// will store in their account to manage their NFTs
	//
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Receiver, NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// Dictionary of CollectibleData conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes a Collectible from the Collection and moves it to the caller
		//
		// Parameters: withdrawID: The ID of the NFT
		// that is to be removed from the Collection
		//
		// returns: @NonFungibleToken.NFT the token that was withdrawn
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Collectible does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			
			// Return the withdrawn token
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: collectibleIds: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: A collection that contains
		//										the withdrawn collectibles
		//
		access(all)
		fun batchWithdraw(collectibleIds: [UInt64]): @{Anique.Collection}{ 
			// Create a new empty Collection
			var batchCollection <- create Collection()
			
			// Iterate through the collectibleIds and withdraw them from the Collection
			for collectibleID in collectibleIds{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: collectibleID))
			}
			
			// Return the withdrawn tokens
			return <-batchCollection
		}
		
		// deposit takes a Collectible and adds it to the Collections dictionary
		//
		// Parameters: token: the NFT to be deposited in the collection
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			
			// Cast the deposited token as an AttackOnTitanLegacy NFT to make sure
			// it is the correct type
			let token <- token as! @AttackOnTitanLegacy.NFT
			
			// Get the token's ID
			let id = token.id
			
			// Add the new token to the dictionary
			let oldToken <- self.ownedNFTs[id] <- token
			
			// Only emit a deposit event if the Collection
			// is in an account's storage
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			
			// Destroy the empty old token that was "removed"
			destroy oldToken
		}
		
		// batchDeposit takes a Collection object as an argument
		// and deposits each contained NFT into this Collection
		access(all)
		fun batchDeposit(tokens: @{Anique.Collection}){ 
			
			// Get an array of the IDs to be deposited
			let keys = tokens.getIDs()
			
			// Iterate through the keys in the collection and deposit each one
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			
			// Destroy the empty Collection
			destroy tokens
		}
		
		// getIDs returns an array of the IDs that are in the Collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// contains returns whether ID is in the Collection
		access(all)
		fun contains(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		// borrowNFT Returns a borrowed reference to a Collectible in the Collection
		// so that the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		//
		// Note: This only allows the caller to read the ID of the NFT,
		// not any AttackOnTitanLegacy specific data. Please use borrowCollectible to
		// read Collectible data.
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowAniqueNFT(id: UInt64): &{Anique.NFT}{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return nft as! &{Anique.NFT}
		}
		
		// borrowAttackOnTitanLegacyCollectible returns a borrowed reference
		// to an AttackOnTitanLegacy Collectible
		access(all)
		fun borrowAttackOnTitanLegacyCollectible(id: UInt64): &NFT{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT does not exist in the collection!"
			}
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return nft as! &NFT
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
	//
	}
	
	// Admin is a special authorization resource that
	// allows the owner to perform important functions to modify the
	// various aspects of the Items, CollectibleDatas, etc.
	//
	access(all)
	resource Admin{ 
		
		// createItem creates a new Item struct
		// and stores it in the Items dictionary field in the AttackOnTitanLegacy smart contract
		//
		// Parameters: metadata: A dictionary mapping metadata titles to their data
		//					   example: {"Title": "Excellent Anime", "Author": "John Smith"}
		//
		// Returns: the ID of the new Item object
		//
		access(all)
		fun createItem(metadata:{ String: String}): UInt32{ 
			// Create the new Item
			var newItem = Item(metadata: metadata)
			
			// Increment the ID so that it isn't used again
			AttackOnTitanLegacy.nextItemID = AttackOnTitanLegacy.nextItemID + 1 as UInt32
			let newID = newItem.itemID
			
			// Store it in the contract storage
			AttackOnTitanLegacy.itemDatas[newID] = newItem
			emit ItemCreated(id: newItem.itemID, metadata: metadata)
			return newID
		}
		
		// createSet creates a new Set resource and returns it
		// so that the caller can store it in their account
		//
		// Parameters: name: The name of the set
		//
		access(all)
		fun createSet(name: String): UInt32{ 
			// Create the new Set
			var newSet <- create Set(name: name)
			let setId = newSet.setID
			AttackOnTitanLegacy.sets[newSet.setID] <-! newSet
			return setId
		}
		
		// borrowSet returns a reference to a set in the AttackOnTitanLegacy
		// contract so that the admin can call methods on it
		//
		// Parameters: setID: The ID of the Set that you want to
		// get a reference to
		//
		// Returns: A reference to the Set with all of the fields
		// and methods exposed
		//
		access(all)
		fun borrowSet(setID: UInt32): &Set{ 
			pre{ 
				AttackOnTitanLegacy.sets[setID] != nil:
					"Cannot borrow Set: The Set doesn't exist"
			}
			return (&AttackOnTitanLegacy.sets[setID] as &Set?)!
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	// -----------------------------------------------------------------------
	// AttackOnTitanLegacy contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection creates a new, empty Collection object so that
	// a user can store it in their account storage.
	// Once they have a Collection in their storage, they are able to receive
	// Collectibles in transactions.
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create AttackOnTitanLegacy.Collection()
	}
	
	// getAllItems returns all the Items in AttackOnTitanLegacy
	//
	// Returns: An array of all the Items that have been created
	access(all)
	fun getAllItems(): [AttackOnTitanLegacy.Item]{ 
		return AttackOnTitanLegacy.itemDatas.values
	}
	
	// getItemMetaData returns all the metadata associated with a specific Item
	//
	// Parameters: itemID: The id of the Item that is being searched
	//
	// Returns: The metadata as a String to String mapping optional
	access(all)
	fun getItemMetaData(itemID: UInt32):{ String: String}?{ 
		return self.itemDatas[itemID]?.metadata
	}
	
	// getSetIDsByName returns the IDs that the specified set name
	//				 is associated with.
	//
	// Parameters: setName: The name of the set that is being searched
	//
	// Returns: An array of the IDs of the set if it exists, or nil if doesn't
	access(all)
	fun getSetIDsByName(setName: String): [UInt32]?{ 
		var setIDs: [UInt32] = []
		
		// iterate through all the sets and search for the name
		for setID in AttackOnTitanLegacy.sets.keys{ 
			let setData = AttackOnTitanLegacy.SetData(setID: setID)
			if setName == setData.name{ 
				// if the name is found, return the ID
				setIDs.append(setData.setID)
			}
		}
		
		// If the name isn't found, return nil
		// Don't force a revert if the setName is invalid
		if setIDs.length == 0{ 
			return nil
		} else{ 
			return setIDs
		}
	}
	
	// getNumCollectiblesInSetItem return the number of Collectibles that have been
	//						minted from a certain Set/Item.
	//
	// Parameters: setID: The id of the Set that is being searched
	//			 itemID: The id of the Item that is being searched
	//
	// Returns: The total number of Collectibles
	//		  that have been minted from a Set/Item
	access(all)
	fun getNumCollectiblesInSetItem(setID: UInt32, itemID: UInt32): UInt32?{ 
		// Don't force a revert if the set or item ID is invalid
		// remove the Set from the dictionary to get its field
		if let setToRead <- AttackOnTitanLegacy.sets.remove(key: setID){ 
			let numberMintedPerItem = setToRead.getNumberMintedPerItem()
			
			// read the numMintedPerItem
			let amount = numberMintedPerItem[itemID]
			
			// put the set back
			AttackOnTitanLegacy.sets[setID] <-! setToRead
			return amount
		} else{ 
			return nil
		}
	}
	
	// -----------------------------------------------------------------------
	// AttackOnTitanLegacy initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		// Initialize contract fields
		self.sets <-{} 
		self.nextSetID = 1
		self.itemDatas ={} 
		self.nextItemID = 1
		self.totalSupply = 0
		self.collectionStoragePath = /storage/AttackOnTitanLegacyCollection
		self.collectionPublicPath = /public/AttackOnTitanLegacyCollection
		self.collectionPrivatePath = /private/AttackOnTitanLegacyCollection
		self.adminStoragePath = /storage/AttackOnTitanLegacyAdmin
		self.saleCollectionStoragePath = /storage/AttackOnTitanLegacySaleCollection
		self.saleCollectionPublicPath = /public/AttackOnTitanLegacySaleCollection
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: self.collectionStoragePath)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{CollectionPublic}>(self.collectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.collectionPublicPath)
		
		// Put the Admin in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: self.adminStoragePath)
		emit ContractInitialized()
	}
}
