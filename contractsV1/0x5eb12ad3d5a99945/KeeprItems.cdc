import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract KeeprItems: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, name: String, imageUrl: String, thumbnailUrl: String, imageCid: String, thumbCid: String, docId: String)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of KeeprItems that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// A Keepr Item as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let cid: String
		
		access(all)
		let path: String
		
		access(all)
		let thumbCid: String
		
		access(all)
		let thumbPath: String
		
		access(all)
		let cardBackCid: String?
		
		access(all)
		let cardBackPath: String?
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		init(id: UInt64, cid: String, path: String, thumbCid: String, thumbPath: String, name: String, description: String, cardBackCid: String, cardBackPath: String){ 
			self.id = id
			self.cid = cid
			self.path = path
			self.thumbCid = thumbCid
			self.thumbPath = thumbPath
			self.name = name
			self.description = description
			self.cardBackCid = cardBackCid
			self.cardBackPath = cardBackPath
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.IPFSFile(cid: self.thumbCid, path: self.thumbPath))
				case Type<MetadataViews.IPFSFile>():
					return MetadataViews.IPFSFile(cid: self.cid, path: self.path)
				case Type<MetadataViews.Editions>():
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					let editionInfo = MetadataViews.Edition(name: "KittyItems NFT Edition", number: self.id, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://keepr.gg/nftdirect/".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: KeeprItems.CollectionStoragePath, publicPath: KeeprItems.CollectionPublicPath, publicCollection: Type<&KeeprItems.Collection>(), publicLinkedType: Type<&KeeprItems.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-KeeprItems.createEmptyCollection(nftType: Type<@KeeprItems.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://firebasestorage.googleapis.com/v0/b/keepr-86355.appspot.com/o/static%2Flogo-dark.svg?alt=media&token=9d66d7ea-9b3e-4fe0-8604-04df064af359"), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "The Keepr Collection", description: "This collection is used as an example to help you develop your next Flow NFT.", externalURL: MetadataViews.ExternalURL("https://keepr.gg/"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/keeprGG")})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// This is the interface that users can cast their KeeprItems Collection as
	// to allow others to deposit KeeprItems into their Collection. It also allows for reading
	// the details of KeeprItems in the Collection.
	access(all)
	resource interface KeeprItemsCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowKeeprItem(id: UInt64): &KeeprItems.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow KeeprItem reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of KeeprItem NFTs owned by an account
	//
	access(all)
	resource Collection: KeeprItemsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @KeeprItems.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs
		// Returns an array of the IDs that are in the collection
		//
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowKeeprItem
		// Gets a reference to an NFT in the collection as a KeeprItem,
		// exposing all of its fields (including the typeID & rarityID).
		// This is safe as there are no functions that can be called on the KeeprItem.
		//
		access(all)
		fun borrowKeeprItem(id: UInt64): &KeeprItems.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &KeeprItems.NFT
			} else{ 
				return nil
			}
		}
		
		// destructor
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let item = nft as! &KeeprItems.NFT
			return item as &{ViewResolver.Resolver}
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
		
		// initializer
		//
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// NFTMinter
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		access(all)
		fun dwebURL(_ cid: String, _ path: String): String{ 
			var url = "https://".concat(cid).concat(".ipfs.dweb.link/")
			return url.concat(path)
		}
		
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection}, cid: String, path: String, thumbCid: String, thumbPath: String, name: String, description: String, docId: String, cardBackCid: String, cardBackPath: String){ 
			// deposit it in the recipient's account using their reference
			let item <- create KeeprItems.NFT(id: KeeprItems.totalSupply, cid: cid, path: path, thumbCid: thumbCid, thumbPath: thumbPath, name: name, description: description, cardBackCid: cardBackCid, cardBackPath: cardBackPath)
			emit Minted(id: KeeprItems.totalSupply, name: name, imageUrl: self.dwebURL(item.cid, item.path), thumbnailUrl: self.dwebURL(item.thumbCid, item.thumbPath), imageCid: cid, thumbCid: thumbCid, docId: docId)
			recipient.deposit(token: <-item)
			KeeprItems.totalSupply = KeeprItems.totalSupply + 1 as UInt64
		}
	}
	
	// fetch
	// Get a reference to a KeeprItem from an account's Collection, if available.
	// If an account does not have a KeeprItems.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &KeeprItems.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&KeeprItems.Collection>(KeeprItems.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust KeeprItems.Collection.borowKeeprItem to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowKeeprItem(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/KeeprItemsCollectionV10
		self.CollectionPublicPath = /public/KeeprItemsCollectionV10
		self.MinterStoragePath = /storage/KeeprItemsMinterV10
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
