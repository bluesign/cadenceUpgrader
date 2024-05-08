import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract TopTCollection2: NonFungibleToken{ 
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event WithdrawBadge(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event DepositBadge(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, name: String, to: Address)
	
	access(all)
	event MintedBadge(id: UInt64, name: String)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	var totalSupplyBadges: UInt64
	
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
		let metadata: TopTCollection2.Metadata
		
		access(all)
		let id: UInt64
		
		init(metadata: TopTCollection2.Metadata, id: UInt64){ 
			self.metadata = metadata
			self.id = id
		}
	}
	
	access(all)
	enum Kind: UInt8{ 
		access(all)
		case Cooking
		
		access(all)
		case Dancing
		
		access(all)
		case Singing
	}
	
	access(all)
	fun kindToStoragePath(_ kind: Kind): String{ 
		switch kind{ 
			case Kind.Cooking:
				return "Cooking"
			case Kind.Dancing:
				return "Dancing"
			case Kind.Singing:
				return "Singing"
		}
		return ""
	}
	
	access(all)
	fun kindToString(_ kind: Kind): String{ 
		switch kind{ 
			case Kind.Cooking:
				return "Cooking"
			case Kind.Dancing:
				return "Dancing"
			case Kind.Singing:
				return "Singing"
		}
		return ""
	}
	
	// pub struct BadgeData {
	//	 pub let id: UInt64
	// 	pub let kind: Kind
	//	 pub let storagePath:String
	//	 pub let royalty: MetadataViews.Royalty
	// 	init(
	//	 id: UInt64,
	//	 kind: Kind,
	//	 storagePath:String,
	//	 royalty: MetadataViews.Royalty
	//	 ) {
	// 		self.id=id
	//		 self.kind = kind
	//		 self.storagePath = storagePath
	//		 self.royalty = royalty
	// 	}
	// }
	access(all)
	resource BADGE: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let kind: Kind
		
		access(all)
		let marketRoyalty: MetadataViews.Royalty
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, kind: Kind, marketRoyalty: MetadataViews.Royalty){ 
			self.id = initID
			self.kind = kind
			self.marketRoyalty = marketRoyalty
		}
	// pub fun getBadgeData(): {
	//		 return TopTCollection.BadgeData(id: self.id,kind:self.kind,storagePath:self.storagePath,royalty:self.royalty)
	// }
	}
	
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
		fun getArtData(): TopTCollection2.ArtData{ 
			return TopTCollection2.ArtData(metadata: self.metadata, id: self.id)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.metadata.storageRef))
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(self.metadata.storageRef)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: TopTCollection2.CollectionStoragePath, publicPath: TopTCollection2.CollectionPublicPath, publicCollection: Type<&TopTCollection2.Collection>(), publicLinkedType: Type<&TopTCollection2.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-TopTCollection2.createEmptyCollection(nftType: Type<@TopTCollection2.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.metadata.storageRef), mediaType: "mp4")
					return MetadataViews.NFTCollectionDisplay(name: "The TopT Collection", description: self.description, externalURL: MetadataViews.ExternalURL(self.metadata.storageRef), squareImage: media, bannerImage: media, socials:{} )
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
		fun depositBadge(token: @TopTCollection2.BADGE)
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		view fun borrowBADGE(): &BADGE?
		
		access(all)
		fun borrowToptItem(id: UInt64): &TopTCollection2.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow TopTItem reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource interface BadgeReceiver{ 
		// deposit takes an NFT as an argument and adds it to the Collection
		//
		access(all)
		fun depositBadge(token: @BADGE)
		
		access(all)
		fun isExists(): Bool
	}
	
	access(all)
	resource interface BadgeProvider{ 
		// withdraw removes an NFT from the collection and moves it to the caller
		access(all)
		fun withdrawBadge(): @BADGE
	}
	
	// Collection
	// A collection of KittyItem NFTs owned by an account
	//
	access(all)
	resource Collection: TopTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, BadgeProvider, BadgeReceiver{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		//
		access(all)
		var badge: @BADGE?
		
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
		
		access(all)
		fun withdrawBadge(): @BADGE{ 
			pre{ 
				self.badge != nil:
					"There's no badge"
			}
			let id = (self.borrowBADGE()!).id
			let token <- self.badge <- nil
			// let id = token.id
			emit WithdrawBadge(id: id, from: self.owner?.address)
			return <-token!
		// post{
		//	 self.badge == nil ?? panic()
		// }
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @TopTCollection2.NFT
			let id: UInt64 = token.id
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun depositBadge(token: @BADGE){ 
			pre{ 
				self.badge == nil:
					"Can only have one badge at a time!!!"
			}
			let token <- token as! @TopTCollection2.BADGE
			let id: UInt64 = token.id
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.badge <- token
			emit DepositBadge(id: id, to: self.owner?.address)
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
		
		access(all)
		fun isExists(): Bool{ 
			return self.badge != nil
		}
		
		// borrowKittyItem
		// Gets a reference to an NFT in the collection as a KittyItem,
		// exposing all of its fields (including the typeID & rarityID).
		// This is safe as there are no functions that can be called on the KittyItem.
		//
		access(all)
		fun borrowToptItem(id: UInt64): &TopTCollection2.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &TopTCollection2.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowBADGE(): &TopTCollection2.BADGE?{ 
			if self.badge != nil{ 
				let ref = (&self.badge as &TopTCollection2.BADGE?)!
				return ref as! &TopTCollection2.BADGE
			} else{ 
				return nil
			}
		}
		
		// destructor
		// initializer
		//
		init(){ 
			self.badge <- nil
			self.ownedNFTs <-{} 
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let topTNFT = nft as! &TopTCollection2.NFT
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
	
	// NFTMinter
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun mintBADGE(recipient: &{TopTCollection2.TopTCollectionPublic}, kind: Kind, marketRoyalty: MetadataViews.Royalty){ 
			pre{ 
				recipient.borrowBADGE() == nil:
					"Can only have one badge at a time!!!"
			}
			let marketWalletCap = getAccount(0xf8d6e0586b0a20c7).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
			// deposit it in the recipient's account using their reference
			recipient.depositBadge(token: <-create TopTCollection2.BADGE(initID: TopTCollection2.totalSupplyBadges, kind: kind, marketRoyalty: MetadataViews.Royalty(receiver: marketWalletCap!, cut: 0.1, description: "Market")))
			emit MintedBadge(id: TopTCollection2.totalSupplyBadges, name: TopTCollection2.kindToString(kind))
			TopTCollection2.totalSupplyBadges = TopTCollection2.totalSupplyBadges + 1 as UInt64
		}
	}
	
	// fetch
	// Get a reference to a KittyItem from an account's Collection, if available.
	// If an account does not have a KittyItems.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &TopTCollection2.NFT?{ 
		let collection = getAccount(from).capabilities.get<&TopTCollection2.Collection>(TopTCollection2.CollectionPublicPath).borrow<&TopTCollection2.Collection>() ?? panic("Couldn't get collection")
		// We trust KittyItems.Collection.borowKittyItem to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowToptItem(id: itemID)
	}
	
	access(all)
	fun mintNFT(name: String, description: String, caption: String, storagePath: String, artistAddress: Address, royalties: [MetadataViews.Royalty], thumbnail: String): @TopTCollection2.NFT{ 
		let marketWalletCap = getAccount(0xf8d6e0586b0a20c7).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
		var newNFT <- create NFT(initID: TopTCollection2.totalSupply, metadata: Metadata(artistAddress: artistAddress, storagePath: storagePath, caption: caption), name: name, description: description, thumbnail: thumbnail, royalties: royalties.concat([MetadataViews.Royalty(receiver: marketWalletCap!, cut: 0.1, description: "Market")]))
		emit Minted(id: TopTCollection2.totalSupply, name: name, to: artistAddress)
		TopTCollection2.totalSupply = TopTCollection2.totalSupply + UInt64(1)
		return <-newNFT
	}
	
	access(all)
	fun getBadge(address: Address): &TopTCollection2.BADGE?{ 
		if let artCollection = getAccount(address).capabilities.get<&{TopTCollection2.TopTCollectionPublic}>(self.CollectionPublicPath).borrow<&{TopTCollection2.TopTCollectionPublic}>(){ 
			return artCollection.borrowBADGE()
		}
		return nil
	}
	
	access(all)
	fun getArt(address: Address): [ArtData]{ 
		var artData: [ArtData] = []
		if let artCollection = getAccount(address).capabilities.get<&{TopTCollection2.TopTCollectionPublic}>(self.CollectionPublicPath).borrow<&{TopTCollection2.TopTCollectionPublic}>(){ 
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
		self.totalSupplyBadges = 0
		self.CollectionPublicPath = /public/TopTArtCollection
		self.CollectionStoragePath = /storage/TopTArtCollection
		self.MinterStoragePath = /storage/TopTBadgesMinterV1
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		// Create a Minter resource and save it to storage
		emit ContractInitialized()
	}
}
