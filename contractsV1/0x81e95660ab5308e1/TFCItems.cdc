import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import TFCSoulbounds from "./TFCSoulbounds.cdc"

// TFCItems
// NFT items for TheFootballClub!
access(all)
contract TFCItems: NonFungibleToken{ 
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event DepositAdmin(id: UInt64, to: Address?, indexer: UInt64)
	
	access(all)
	event DepositMinted(id: UInt64, to: Address?, indexer: String)
	
	access(all)
	event Minted(id: UInt64, metadata:{ String: String}, downcastID: UInt64, indexer: UInt64, to: Address?)
	
	access(all)
	event Burned(id: UInt64, from: Address?)
	
	access(all)
	event BurnedAdmin(id: UInt64, indexer: UInt64)
	
	access(all)
	event BatchBurned(requestID: String, itemIDs: [UInt64], from: Address?)
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	// totalSupply
	// The total number of TFCItems that have been minted
	access(all)
	var totalSupply: UInt64
	
	// NFT
	// A TFC Item as an NFT
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// The items's type, e.g. 1 == Hat, 2 == Shirt, etc.
		access(all)
		let typeID: UInt64
		
		// String mapping to hold metadata
		access(self)
		let metadata:{ String: String}
		
		// initializer
		init(initID: UInt64, initTypeID: UInt64, initMetadata:{ String: String}){ 
			self.id = initID
			self.typeID = initTypeID
			self.metadata = initMetadata
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(contract)
		fun setImageURL(url: String){ 
			self.metadata["URL"] = url
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.metadata["Title"]!, description: "TFCItem #".concat(self.id.toString()).concat(", Type ID: ").concat(self.metadata["Type"]!).concat(", Created By: ").concat(self.metadata["Creator"]!), thumbnail: MetadataViews.IPFSFile(cid: self.metadata["URL"]!, path: nil))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://thefootballclub.com/")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: TFCItems.CollectionStoragePath, publicPath: TFCItems.CollectionPublicPath, publicCollection: Type<&TFCItems.Collection>(), publicLinkedType: Type<&TFCItems.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-TFCItems.createEmptyCollection(nftType: Type<@TFCItems.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let mediaSquare = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://thefootballclub.com/public/images/logo.png"), mediaType: "image/png")
					let mediaBanner = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://thefootballclub.com/public/images/banner.png"), mediaType: "image/png")
					let socials ={ "twitter": MetadataViews.ExternalURL("https://twitter.com/play_tfc"), "instagram": MetadataViews.ExternalURL("https://instagram.com/playtfc"), "discord": MetadataViews.ExternalURL("https://discord.gg/playtfc")}
					return MetadataViews.NFTCollectionDisplay(name: "TFC", description: "Welcome to the Metaverse of Football Fandom. The new home of football to play and connect with fans worldwide.", externalURL: MetadataViews.ExternalURL("https://thefootballclub.com/"), squareImage: mediaSquare, bannerImage: mediaBanner, socials: socials)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
				case Type<MetadataViews.Traits>():
					let serialNumberTrait = MetadataViews.Trait(name: "Serial Number", value: self.metadata["Serial Number"] ?? "Missing Serial Number Data", displayType: nil, rarity: nil)
					let editionsTrait = MetadataViews.Trait(name: "Editions", value: self.metadata["Editions"] ?? "Missing Edition Data", displayType: nil, rarity: nil)
					let dateCreatedTrait = MetadataViews.Trait(name: "Date Created", value: self.metadata["Date Created"] ?? "Missing Date Created", displayType: nil, rarity: nil)
					let itemNameTrait = MetadataViews.Trait(name: "Item Name", value: self.metadata["Title"] ?? "Missing Title", displayType: nil, rarity: nil)
					return MetadataViews.Traits([serialNumberTrait, editionsTrait, dateCreatedTrait, itemNameTrait])
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// This is the interface that users can cast their TFCItems Collection as
	// to allow others to deposit TFCItems into their Collection. It also allows for reading
	// the details of TFCItems in the Collection.
	access(all)
	resource interface TFCItemsCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowTFCItem(id: UInt64): &TFCItems.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow TFCItem reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(contract)
		fun depositAdmin(token: @{NonFungibleToken.NFT}, indexer: UInt64)
		
		access(contract)
		fun burnAdmin(burnIDs: [UInt64], indexer: UInt64)
	}
	
	// Collection
	// A collection of TFCItem NFTs owned by an account
	access(all)
	resource Collection: TFCItemsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// burn
		// burns an NFT from your collection, emits Burned event
		access(all)
		fun burn(burnID: UInt64){ 
			let token <- self.ownedNFTs.remove(key: burnID) ?? panic("missing NFT")
			destroy token
			emit Burned(id: burnID, from: self.owner?.address)
		}
		
		// batchBurn
		// burns a batch of NFTs, used internally to interact with the TFC app
		access(all)
		fun batchBurn(burnIDs: [UInt64], requestID: String){ 
			for burnID in burnIDs{ 
				let token <- self.ownedNFTs.remove(key: burnID) ?? panic("missing NFT")
				destroy token
			}
			emit BatchBurned(requestID: requestID, itemIDs: burnIDs, from: self.owner?.address)
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @TFCItems.NFT
			if TFCSoulbounds.isItemSoulbound(itemName: token.getMetadata()["Title"]!){ 
				panic("This item is not tradable")
			}
			let id: UInt64 = token.id
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// depositAdmin
		// allows the admin to deposit soulbound items to users
		access(account)
		fun depositAdmin(token: @{NonFungibleToken.NFT}, indexer: UInt64){ 
			let token <- token as! @TFCItems.NFT
			let id: UInt64 = token.id
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit DepositAdmin(id: id, to: self.owner?.address, indexer: indexer)
			destroy oldToken
		}
		
		// burnAdmin
		// used by the admin's burn function, emits a special BurnedAdmin event
		access(account)
		fun burnAdmin(burnIDs: [UInt64], indexer: UInt64){ 
			for burnID in burnIDs{ 
				let token <- self.ownedNFTs.remove(key: burnID) ?? panic("missing NFT")
				destroy token
				emit BurnedAdmin(id: burnID, indexer: indexer)
			}
		}
		
		// getIDs
		// Returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowTFCItem
		// Gets a reference to an NFT in the collection as a TFCItem,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the TFCItem.
		access(all)
		fun borrowTFCItem(id: UInt64): &TFCItems.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &TFCItems.NFT
			} else{ 
				return nil
			}
		}
		
		// borrowViewResolver
		// Returns a reference to the view resolver of the specified item
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let TFCItem = nft as! &TFCItems.NFT
			return TFCItem
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
		
		// destructor
		// initializer
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Administrator
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	access(all)
	resource Administrator{ 
		
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{TFCItems.TFCItemsCollectionPublic}, typeID: UInt64, metadata:{ String: String}, indexer: UInt64){ 
			let token <- create TFCItems.NFT(initID: TFCItems.totalSupply, initTypeID: typeID, initMetadata: metadata)
			let downcastID: UInt64 = (&token as &{NonFungibleToken.NFT}).id
			// deposit it in the recipient's account using their reference
			recipient.depositAdmin(token: <-token, indexer: indexer)
			emit Minted(id: TFCItems.totalSupply, metadata: metadata, downcastID: downcastID, indexer: indexer, to: recipient.owner?.address)
			TFCItems.totalSupply = TFCItems.totalSupply + 1
		}
		
		// setImageURL
		// Sets an NFT's URL metadata field
		access(all)
		fun setImageURL(itemRef: &TFCItems.NFT, url: String){ 
			itemRef.setImageURL(url: url)
		}
		
		access(all)
		fun depositAdmin(recipient: &{TFCItems.TFCItemsCollectionPublic}, item: @TFCItems.NFT, indexer: UInt64){ 
			recipient.depositAdmin(token: <-item, indexer: indexer)
		}
		
		access(all)
		fun burnAdmin(collection: &{TFCItems.TFCItemsCollectionPublic}, burnIDs: [UInt64], indexer: UInt64){ 
			collection.burnAdmin(burnIDs: burnIDs, indexer: indexer)
		}
	}
	
	// fetch
	// Get a reference to a TFCItem from an account's Collection, if available.
	// If an account does not have a TFCItems.Collection, panic.
	// If it has a collection but does not contain the itemId, return nil.
	// If it has a collection and that collection contains the itemId, return a reference to that.
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &TFCItems.NFT?{ 
		let capability = getAccount(from).capabilities.get<&TFCItems.Collection>(TFCItems.CollectionPublicPath)
		if capability.check(){ 
			let collection = capability.borrow()
			return (collection!).borrowTFCItem(id: itemID)
		} else{ 
			return nil
		}
	}
	
	// fetchIsSoulbound
	// Get's a reference to a TFCItem and checks if it's a soulbound item.
	access(all)
	fun fetchIsSoulbound(owner: Address, itemID: UInt64): Bool{ 
		let item = self.fetch(owner, itemID: itemID)
		if item != nil && TFCSoulbounds.isItemSoulbound(itemName: (item!).getMetadata()["Title"]!){ 
			return true
		} else{ 
			return false
		}
	}
	
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/TFCItemsCollection
		self.CollectionPublicPath = /public/TFCItemsCollection
		self.AdminStoragePath = /storage/TFCItemsMinter
		self.AdminPrivatePath = /private/TFCItemsAdminPrivate
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Admin resource and save it to storage
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Administrator>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath)
		emit ContractInitialized()
	}
}
