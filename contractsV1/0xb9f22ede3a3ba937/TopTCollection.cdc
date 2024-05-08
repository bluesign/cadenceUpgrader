import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract TopTCollection: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, name: String, to: Address)
	
	access(all)
	event ImagesAddedForNewKind(kind: UInt8)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// totalSupply
	// The total number of KittyItems that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	access(all)
	struct Metadata{ 
		access(all)
		let artistAddress: Address
		
		access(all)
		let storageRef: String
		
		access(all)
		let caption: String
		
		init(artistAddress: Address, storagePath: String, caption: String){ 
			self.artistAddress = artistAddress
			self.storageRef = storagePath
			self.caption = caption
		}
	}
	
	access(all)
	struct ArtData{ 
		access(all)
		let metadata: TopTCollection.Metadata
		
		access(all)
		let id: UInt64
		
		init(metadata: TopTCollection.Metadata, id: UInt64){ 
			self.metadata = metadata
			self.id = id
		}
	}
	
	// A Kitty Item as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let metadata: Metadata
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let royalties: [MetadataViews.Royalty]
		
		// Initialize both fields in the init function
		init(initID: UInt64, metadata: Metadata, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty]){ 
			self.id = initID
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.royalties = royalties
			self.metadata = metadata
		}
		
		access(all)
		fun getArtData(): TopTCollection.ArtData{ 
			return TopTCollection.ArtData(metadata: self.metadata, id: self.id)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://TopT-nft.onflow.org/".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: TopTCollection.CollectionStoragePath, publicPath: TopTCollection.CollectionPublicPath, publicCollection: Type<&TopTCollection.Collection>(), publicLinkedType: Type<&TopTCollection.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-TopTCollection.createEmptyCollection(nftType: Type<@TopTCollection.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "The TopT Collection", description: "This collection is used as an example to help you develop your next Flow NFT.", externalURL: MetadataViews.ExternalURL("https://example-nft.onflow.org"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/flow_blockchain")})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// This is the interface that users can cast their KittyItems Collection as
	// to allow others to deposit KittyItems into their Collection. It also allows for reading
	// the details of KittyItems in the Collection.
	access(all)
	resource interface TopTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowToptItem(id: UInt64): &TopTCollection.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow KittyItem reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of KittyItem NFTs owned by an account
	//
	access(all)
	resource Collection: TopTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @TopTCollection.NFT
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
		
		// borrowKittyItem
		// Gets a reference to an NFT in the collection as a KittyItem,
		// exposing all of its fields (including the typeID & rarityID).
		// This is safe as there are no functions that can be called on the KittyItem.
		//
		access(all)
		fun borrowToptItem(id: UInt64): &TopTCollection.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &TopTCollection.NFT
			} else{ 
				return nil
			}
		}
		
		// destructor
		// initializer
		//
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let topTNFT = nft as! &TopTCollection.NFT
			return topTNFT as &{ViewResolver.Resolver}
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
	
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// fetch
	// Get a reference to a KittyItem from an account's Collection, if available.
	// If an account does not have a KittyItems.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &TopTCollection.NFT?{ 
		let collection = getAccount(from).capabilities.get<&TopTCollection.Collection>(TopTCollection.CollectionPublicPath).borrow<&TopTCollection.Collection>() ?? panic("Couldn't get collection")
		// We trust KittyItems.Collection.borowKittyItem to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowToptItem(id: itemID)
	}
	
	access(all)
	fun mintNFT(name: String, description: String, caption: String, storagePath: String, artistAddress: Address, royalties: [MetadataViews.Royalty], thumbnail: String): @TopTCollection.NFT{ 
		var newNFT <- create NFT(initID: TopTCollection.totalSupply, metadata: Metadata(artistAddress: artistAddress, storagePath: storagePath, caption: caption), name: name, description: description, thumbnail: thumbnail, royalties: royalties)
		emit Minted(id: TopTCollection.totalSupply, name: name, to: artistAddress)
		TopTCollection.totalSupply = TopTCollection.totalSupply + UInt64(1)
		return <-newNFT
	}
	
	access(all)
	fun getArt(address: Address): [ArtData]{ 
		var artData: [ArtData] = []
		if let artCollection = getAccount(address).capabilities.get<&{TopTCollection.TopTCollectionPublic}>(self.CollectionPublicPath).borrow<&{TopTCollection.TopTCollectionPublic}>(){ 
			for id in artCollection.getIDs(){ 
				var art = artCollection.borrowToptItem(id: id) ?? panic("ddd")
				artData.append(ArtData(metadata: art.metadata, id: id))
			}
		}
		return artData
	}
	
	// initializer
	//
	init(){ 
		self.totalSupply = 0
		self.CollectionPublicPath = /public/TopTArtCollection
		self.CollectionStoragePath = /storage/TopTArtCollection
		
		// Create a Minter resource and save it to storage
		emit ContractInitialized()
	}
}
