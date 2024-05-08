/*
	Description: Central Smart Contract for Leofy

	This smart contract contains the core functionality for 
	Leofy, created by LEOFY DIGITAL S.L.

	The contract manages the data associated with all the items
	that are used as templates for the NFTs

	Then an Admin can create new Items. Items consist of a public struct that 
	contains public information about a item, and a private resource used
	to mint new NFT's linked to the Item.

	The admin resource has the power to do all of the important actions
	in the smart contract. When admins want to call functions in a Item,
	they call their borrowItem function to get a reference 
	to a item in the contract. Then, they can call functions on the item using that reference.
	
	When NFTs are minted, they are initialized with a ItemID and
	are returned by the minter.

	The contract also defines a Collection resource. This is an object that 
	every Leofy NFT owner will store in their account
	to manage their NFT collection.

	The main Leofy account will also have its own NFT's collections
	it can use to hold its own NFT's that have not yet been sent to a user.

	Note: All state changing functions will panic if an invalid argument is
	provided or one of its pre-conditions or post conditions aren't met.
	Functions that don't modify state will simply return 0 or nil 
	and those cases need to be handled by the caller.

*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import LeofyCoin from "./LeofyCoin.cdc"

access(all)
contract LeofyNFT: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// Leofy contract Events
	// -----------------------------------------------------------------------
	
	// Emitted when the LeofyNFT contract is created
	access(all)
	event ContractInitialized()
	
	// Emitted when a new Item struct is created
	access(all)
	event ItemCreated(id: UInt64, metadata:{ String: String})
	
	access(all)
	event SetCreated(id: UInt64, name: String)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, itemID: UInt64, serialNumber: UInt32)
	
	// Named Paths
	//
	access(all)
	let ItemStoragePath: StoragePath
	
	access(all)
	let ItemPublicPath: PublicPath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// -----------------------------------------------------------------------
	// TopShot contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// Variable size dictionary of Item structs
	//access(self) var items: @{UInt64: Item}
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var totalItemSupply: UInt64
	
	// -----------------------------------------------------------------------
	// LeofyNFT contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// -----------------------------------------------------------------------
	// Item is a Resource that holds metadata associated 
	// with a specific Artist Item, like the picture from Artist John Doe
	//
	// Leofy NFTs will all reference a single item as the owner of
	// its metadata. 
	//
	access(all)
	resource interface ItemCollectionPublic{ 
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		fun getItemsLength(): Int
		
		access(all)
		fun getItemMetaDataByField(itemID: UInt64, field: String): String?
		
		access(all)
		fun borrowItem(itemID: UInt64): &Item?
	}
	
	access(all)
	resource ItemCollection: ItemCollectionPublic{ 
		access(all)
		var items: @{UInt64: LeofyNFT.Item}
		
		init(){ 
			self.items <-{} 
		}
		
		access(all)
		fun createItem(metadata:{ String: String}, price: UFix64): UInt64{ 
			
			// Create the new Item
			var newItem <- create Item(metadata: metadata, price: price)
			let newID = newItem.itemID
			
			// Store it in the contract storage
			self.items[newID] <-! newItem
			emit ItemCreated(id: LeofyNFT.totalItemSupply, metadata: metadata)
			
			// Increment the ID so that it isn't used again
			LeofyNFT.totalItemSupply = LeofyNFT.totalItemSupply + 1
			return newID
		}
		
		access(all)
		fun borrowItem(itemID: UInt64): &Item?{ 
			pre{ 
				self.items[itemID] != nil:
					"Cannot borrow Item: The Item doesn't exist"
			}
			return &self.items[itemID] as &Item?
		}
		
		// getIDs returns an array of the IDs that are in the Item Collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.items.keys
		}
		
		// getItemsLength 
		// Returns: Int length of items created
		access(all)
		fun getItemsLength(): Int{ 
			return self.items.length
		}
		
		// getItemMetaDataByField returns the metadata associated with a 
		//						specific field of the metadata
		//						Ex: field: "Artist" will return something
		//						like "John Doe"
		// 
		// Parameters: itemID: The id of the Item that is being searched
		//			 field: The field to search for
		//
		// Returns: The metadata field as a String Optional
		access(all)
		fun getItemMetaDataByField(itemID: UInt64, field: String): String?{ 
			// Don't force a revert if the itemID or field is invalid
			let item = (&self.items[itemID] as &Item?)!
			return item.metadata[field]
		}
	}
	
	access(all)
	resource interface ItemPublic{ 
		access(all)
		let itemID: UInt64
		
		access(all)
		var numberMinted: UInt32
		
		access(all)
		var price: UFix64
		
		access(all)
		fun getMetadata():{ String: String}
		
		access(all)
		fun borrowCollection(): &LeofyNFT.Collection
		
		access(all)
		fun purchase(payment: @{FungibleToken.Vault}): @{NonFungibleToken.NFT}
	}
	
	access(all)
	resource Item: ItemPublic{ 
		
		// The unique ID for the Item
		access(all)
		let itemID: UInt64
		
		// Stores all the metadata about the item as a string mapping
		// This is not the long term way NFT metadata will be stored. It's a temporary
		// construct while we figure out a better way to do metadata.
		//
		access(contract)
		let metadata:{ String: String}
		
		access(all)
		var numberMinted: UInt32
		
		access(all)
		var NFTsCollection: @LeofyNFT.Collection
		
		access(all)
		var price: UFix64
		
		init(metadata:{ String: String}, price: UFix64){ 
			pre{ 
				metadata.length != 0:
					"New Item metadata cannot be empty"
			}
			self.itemID = LeofyNFT.totalItemSupply
			self.metadata = metadata
			self.price = price
			self.numberMinted = 0
			self.NFTsCollection <- create Collection()
		}
		
		access(all)
		fun mintNFT(){ 
			// create a new NFT
			var newNFT <- create NFT(id: LeofyNFT.totalSupply, itemID: self.itemID, serialNumber: self.numberMinted + 1)
			
			// deposit it in the recipient's account using their reference
			self.NFTsCollection.deposit(token: <-newNFT)
			emit Minted(id: LeofyNFT.totalSupply, itemID: self.itemID, serialNumber: self.numberMinted + 1)
			self.numberMinted = self.numberMinted + 1
			LeofyNFT.totalSupply = LeofyNFT.totalSupply + 1
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun batchMintNFT(quantity: UInt64){ 
			var i: UInt64 = 0
			while i < quantity{ 
				self.mintNFT()
				i = i + 1
			}
		}
		
		access(all)
		fun setPrice(price: UFix64){ 
			self.price = price
		}
		
		access(all)
		fun borrowCollection(): &LeofyNFT.Collection{ 
			return &self.NFTsCollection as &Collection
		}
		
		access(all)
		fun purchase(payment: @{FungibleToken.Vault}): @{NonFungibleToken.NFT}{ 
			pre{ 
				self.NFTsCollection.getIDs().length > 0:
					"listing has already been purchased"
				payment.isInstance(Type<@LeofyCoin.Vault>()):
					"payment vault is not requested fungible token"
				payment.balance == self.price:
					"payment vault does not contain requested price"
			}
			let nft <- self.NFTsCollection.withdraw(withdrawID: self.NFTsCollection.getIDs()[0])
			let vault = LeofyNFT.getLeofyCoinVault()
			vault.deposit(from: <-payment)
			return <-nft
		}
	}
	
	// This is an implementation of a custom metadata view for Leofy.
	// This view contains the Item metadata.
	//
	access(all)
	struct LeofyNFTMetadataView{ 
		access(all)
		let author: String
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let itemID: UInt64
		
		access(all)
		let serialNumber: UInt32
		
		init(author: String, name: String, description: String, thumbnail:{ MetadataViews.File}, itemID: UInt64, serialNumber: UInt32){ 
			self.author = author
			self.name = name
			self.description = description
			self.thumbnail = thumbnail.uri()
			self.itemID = itemID
			self.serialNumber = serialNumber
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let itemID: UInt64
		
		access(all)
		let serialNumber: UInt32
		
		init(id: UInt64, itemID: UInt64, serialNumber: UInt32){ 
			self.id = id
			self.itemID = itemID
			self.serialNumber = serialNumber
		}
		
		access(all)
		fun description(): String{ 
			let itemCollection = LeofyNFT.getItemCollectionPublic()
			return "NFT: '".concat(itemCollection.getItemMetaDataByField(itemID: self.itemID, field: "name") ?? "''").concat("' from Author: '").concat(itemCollection.getItemMetaDataByField(itemID: self.itemID, field: "author") ?? "''").concat("' with serial number ").concat(self.serialNumber.toString())
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<LeofyNFTMetadataView>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let itemCollection = LeofyNFT.getItemCollectionPublic()
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: itemCollection.getItemMetaDataByField(itemID: self.itemID, field: "name") ?? "", description: self.description(), thumbnail: MetadataViews.HTTPFile(url: itemCollection.getItemMetaDataByField(itemID: self.itemID, field: "thumbnail") ?? ""))
				case Type<LeofyNFTMetadataView>():
					return LeofyNFTMetadataView(author: itemCollection.getItemMetaDataByField(itemID: self.itemID, field: "author") ?? "", name: itemCollection.getItemMetaDataByField(itemID: self.itemID, field: "name") ?? "", description: self.description(), thumbnail: MetadataViews.HTTPFile(url: itemCollection.getItemMetaDataByField(itemID: self.itemID, field: "thumbnail") ?? ""), itemID: self.itemID, serialNumber: self.serialNumber)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface LeofyCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowLeofyNFT(id: UInt64): &LeofyNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow LeofyNFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: LeofyCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT: ".concat(withdrawID.toString()))
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @LeofyNFT.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowLeofyNFT(id: UInt64): &LeofyNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &LeofyNFT.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return nft as! &LeofyNFT.NFT
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
	// LeofyNFT contract-level function definitions
	// -----------------------------------------------------------------------
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	fun getItemCollectionPublic(): &{LeofyNFT.ItemCollectionPublic}{ 
		return self.account.capabilities.get<&{LeofyNFT.ItemCollectionPublic}>(LeofyNFT.ItemPublicPath).borrow<&{LeofyNFT.ItemCollectionPublic}>() ?? panic("Could not borrow capability from public Item Collection")
	}
	
	access(all)
	fun getLeofyCoinVault(): &{FungibleToken.Receiver}{ 
		return (self.account.capabilities.get<&{FungibleToken.Receiver}>(LeofyCoin.ReceiverPublicPath)!).borrow() ?? panic("Could not borrow receiver reference to the recipient's Vault")
	}
	
	// -----------------------------------------------------------------------
	// LeofyNFT initialization function
	// -----------------------------------------------------------------------
	init(){ 
		self.ItemStoragePath = /storage/LeofyItemCollection
		self.ItemPublicPath = /public/LeofyItemCollection
		self.CollectionStoragePath = /storage/LeofyNFTCollection
		self.CollectionPublicPath = /public/LeofyNFTCollection
		self.AdminStoragePath = /storage/LeofyNFTMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		self.totalItemSupply = 0
		destroy self.account.storage.load<@ItemCollection>(from: self.ItemStoragePath)
		// create a public capability for the Item collection
		self.account.storage.save(<-create ItemCollection(), to: self.ItemStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&LeofyNFT.ItemCollection>(self.ItemStoragePath)
		self.account.capabilities.publish(capability_1, at: self.ItemPublicPath)
		
		// Create a Collection resource and save it to storage
		destroy self.account.storage.load<@Collection>(from: self.CollectionStoragePath)
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_2 = self.account.capabilities.storage.issue<&LeofyNFT.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
