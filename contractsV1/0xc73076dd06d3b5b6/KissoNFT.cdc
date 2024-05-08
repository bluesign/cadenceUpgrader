import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import Clock from "./Clock.cdc"

import AdminToken from "./AdminToken.cdc"

access(all)
contract KissoNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(contract)
	let seriesTotalSupply:{ UInt64: UInt64}
	
	// represents line items, key of hash to line item record
	access(contract)
	let lineItemRecords:{ String: LineItemRecord}
	
	access(account)
	let artLibrary:{ UInt64: Variants}
	
	access(all)
	struct Variants{ 
		access(all)
		let variants:{ UInt64: Variant}
		
		access(all)
		fun addUpdateVariant(variantID: UInt64, variant: Variant){ 
			self.variants.insert(key: variantID, variant)
		}
		
		access(all)
		fun removeVariant(variantID: UInt64){ 
			self.variants.remove(key: variantID)
		}
		
		init(){ 
			self.variants ={} 
		}
	}
	
	access(all)
	struct Variant{ 
		access(all)
		let thumbnailImg: String
		
		access(all)
		let thumbnailImgMimetype: String
		
		access(all)
		let ipfsCID: String // this is the IPFS CID
		
		
		access(all)
		let ipfsPath: String? // directory for IPFS 
		
		
		init(thumbnailImg: String, thumbnailImgMimetype: String, ipfsCID: String, ipfsPath: String?){ 
			self.thumbnailImg = thumbnailImg
			self.thumbnailImgMimetype = thumbnailImgMimetype
			self.ipfsCID = ipfsCID
			self.ipfsPath = ipfsPath
		}
	}
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	struct OrderInfo{ 
		access(all)
		let id: UInt64
		
		access(all)
		let created_at: UFix64
		
		access(all)
		let order_number: UInt64
		
		init(id: UInt64, created_at: UFix64, order_number: UInt64){ 
			self.id = id
			self.created_at = created_at
			self.order_number = order_number
		}
	}
	
	access(all)
	struct LineItemRecord{ 
		access(all)
		let timestamp: UFix64
		
		access(all)
		let nftID: UInt64
		
		access(all)
		let seriesID: UInt64
		
		access(all)
		let productID: UInt64
		
		access(all)
		let variantID: UInt64
		
		access(all)
		let name: String
		
		init(nftID: UInt64, seriesID: UInt64, productID: UInt64, variantID: UInt64, name: String){ 
			self.timestamp = Clock.getTime()
			self.nftID = nftID
			self.seriesID = seriesID
			self.productID = productID
			self.variantID = variantID
			self.name = name
		}
	}
	
	access(all)
	struct LineItemInfo{ 
		access(all)
		let id: UInt64
		
		access(all)
		let product_id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let title: String
		
		access(all)
		let variant_id: UInt64
		
		access(all)
		let variant_title: String
		
		access(all)
		let price: UInt64
		
		access(all)
		let currency: String
		
		access(all)
		let item_hash: String
		
		init(id: UInt64, product_id: UInt64, name: String, title: String, variant_id: UInt64, variant_title: String, price: UInt64, currency: String, item_hash: String){ 
			self.id = id
			self.product_id = product_id
			self.name = name
			self.title = title
			self.variant_id = variant_id
			self.variant_title = variant_title
			self.price = price
			self.currency = currency
			self.item_hash = item_hash
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let seriesID: UInt64
		
		access(all)
		let weight: UInt64
		
		access(all)
		let miniThumbnail: String // a base64 encoded string
		
		
		access(all)
		let miniThumbnailMimetype: String // mimetype of the b64 encoded string
		
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String // this is the IPFS CID for the main image
		
		
		access(all)
		let path: String? // path for the IPFS directory
		
		
		access(all)
		let orderInfo: OrderInfo
		
		access(all)
		let lineItemInfo: LineItemInfo
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		init(id: UInt64, seriesID: UInt64, miniThumbnail: String, miniThumbnailMimetype: String, name: String, description: String, thumbnail: String, path: String?, orderInfo: OrderInfo, lineItemInfo: LineItemInfo, lineItemVotingWeight: UInt64, royalties: [MetadataViews.Royalty]){ 
			self.id = id
			self.seriesID = seriesID
			self.weight = lineItemVotingWeight
			self.miniThumbnail = miniThumbnail
			self.miniThumbnailMimetype = miniThumbnailMimetype
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.path = path
			self.orderInfo = orderInfo
			self.lineItemInfo = lineItemInfo
			self.royalties = royalties
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.IPFSFile(cid: self.thumbnail, path: self.path))
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.seriesID)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://kissodao.com/")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: KissoNFT.CollectionStoragePath, publicPath: KissoNFT.CollectionPublicPath, publicCollection: Type<&KissoNFT.Collection>(), publicLinkedType: Type<&KissoNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-KissoNFT.createEmptyCollection(nftType: Type<@KissoNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://www.kissodao.com/_next/image?url=%2F_next%2Fstatic%2Fmedia%2Fkisso.ca9af3bf.png&w=256&q=100"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "The Kisso DAO Collection", description: "This is the official collection of Kisso DAO.", externalURL: MetadataViews.ExternalURL("https://kissodao.com"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/kissodao")})
				case Type<MetadataViews.Traits>():
					let metadata:{ String: AnyStruct} ={} 
					let traitsView = MetadataViews.dictToTraits(dict: metadata, excludedNames: nil)
					let supplyIDTrait = MetadataViews.Trait(name: "supplyID", value: self.id, displayType: "Number", rarity: nil)
					traitsView.addTrait(supplyIDTrait)
					let seriesIDTrait = MetadataViews.Trait(name: "seriesID", value: self.seriesID, displayType: "Number", rarity: nil)
					traitsView.addTrait(seriesIDTrait)
					let votingWeightTrait = MetadataViews.Trait(name: "votingWeight", value: self.weight, displayType: "Number", rarity: nil)
					traitsView.addTrait(votingWeightTrait)
					return traitsView
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface KissoNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowKissoNFT(id: UInt64): &KissoNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow KissoNFT reference: the ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		fun getVotingWeights():{ UInt64: UInt64}
	}
	
	// TODO: this is redundant with the same method on the public interface
	access(all)
	resource interface KissoNFTCollectionPrivate{ 
		access(all)
		fun getVotingWeights():{ UInt64: UInt64}
	}
	
	access(all)
	resource Collection: KissoNFTCollectionPublic, KissoNFTCollectionPrivate, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// maps uuid to token voting weight for this collection
		access(all)
		var votingWeights:{ UInt64: UInt64}
		
		init(){ 
			self.ownedNFTs <-{} 
			self.votingWeights ={} 
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			let uuid: UInt64 = token.uuid
			emit Withdraw(id: token.id, from: self.owner?.address)
			self.votingWeights.remove(key: uuid)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @KissoNFT.NFT
			let id: UInt64 = token.id
			let uuid: UInt64 = token.uuid
			self.votingWeights.insert(key: uuid, token.weight)
			
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
		
		access(all)
		fun getVotingWeightsUUIDs(): [UInt64]{ 
			return self.votingWeights.keys
		}
		
		access(all)
		fun getVotingWeight(uuid: UInt64): UInt64?{ 
			return self.votingWeights[uuid]
		}
		
		// gets a collection's voting weights dict
		access(all)
		fun getVotingWeights():{ UInt64: UInt64}{ 
			return self.votingWeights
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowKissoNFT(id: UInt64): &KissoNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &KissoNFT.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let kissoNFT = nft as! &KissoNFT.NFT
			return kissoNFT as &{ViewResolver.Resolver}
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
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	fun getTotalSupply(): UInt64{ 
		return KissoNFT.totalSupply
	}
	
	access(all)
	fun getLineItemRecord(hash: String): KissoNFT.LineItemRecord?{ 
		return KissoNFT.lineItemRecords[hash]
	}
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		// is a passive minter, only minting if the item hasn't been used for minting yet
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, lineItemHash: String, orderInfo: OrderInfo, lineItemInfo: LineItemInfo, lineItemVotingWeight: UInt64, royalties: [MetadataViews.Royalty]){ 
			pre{ 
				KissoNFT.artLibrary[lineItemInfo.product_id] != nil:
					"the product doesn't exist in the art library"
				(KissoNFT.artLibrary[lineItemInfo.product_id]!).variants[lineItemInfo.variant_id] != nil:
					"the variant doesn't exist in for the product in the art library"
			}
			if KissoNFT.lineItemRecords[lineItemHash] == nil{ 
				let productID = lineItemInfo.product_id
				let variantID = lineItemInfo.variant_id
				if KissoNFT.seriesTotalSupply[productID] == nil{ 
					KissoNFT.seriesTotalSupply.insert(key: productID, UInt64(0))
				}
				
				// create a new NFT
				var newNFT <- create NFT(id: KissoNFT.totalSupply, seriesID: KissoNFT.seriesTotalSupply[productID]!, miniThumbnail: ((KissoNFT.artLibrary[productID]!).variants[variantID]!).thumbnailImg, miniThumbnailMimetype: ((KissoNFT.artLibrary[productID]!).variants[variantID]!).thumbnailImgMimetype, name: name, description: description, thumbnail: ((KissoNFT.artLibrary[productID]!).variants[variantID]!).ipfsCID, path: ((KissoNFT.artLibrary[productID]!).variants[variantID]!).ipfsPath, orderInfo: orderInfo, lineItemInfo: lineItemInfo, lineItemVotingWeight: lineItemVotingWeight, royalties: royalties)
				
				// deposit it in the recipient's account using their reference
				recipient.deposit(token: <-newNFT)
				
				// make a record of the mint for this hash
				KissoNFT.lineItemRecords.insert(key: lineItemHash, KissoNFT.LineItemRecord(nftID: KissoNFT.totalSupply, seriesID: KissoNFT.seriesTotalSupply[productID]!, productID: productID, variantID: variantID, name: name))
				
				// increment the series id supply
				KissoNFT.seriesTotalSupply[productID] = KissoNFT.seriesTotalSupply[productID]! + UInt64(1)
				
				// increment the total supply
				KissoNFT.totalSupply = KissoNFT.totalSupply + UInt64(1)
			}
		}
	}
	
	access(all)
	fun addUpdateArtLibraryVariant(productID: UInt64, variantID: UInt64, thumbnailImg: String, thumbnailImgMimetype: String, ipfsCID: String, ipfsPath: String?, ref: &AdminToken.Token?){ 
		AdminToken.checkAuthorizedAdmin(ref) // check for authorized admin
		
		if KissoNFT.artLibrary[productID] == nil{ 
			KissoNFT.artLibrary.insert(key: productID, KissoNFT.Variants())
		}
		(KissoNFT.artLibrary[productID]!).addUpdateVariant(variantID: variantID, variant: KissoNFT.Variant(thumbnailImg: thumbnailImg, thumbnailImgMimetype: thumbnailImgMimetype, ipfsCID: ipfsCID, ipfsPath: ipfsPath))
	}
	
	access(all)
	fun removeArtLibraryVariant(productID: UInt64, variantID: UInt64, ref: &AdminToken.Token?){ 
		pre{ 
			KissoNFT.artLibrary[productID] != nil:
				"product does not exist"
			(KissoNFT.artLibrary[productID]!).variants[variantID] != nil:
				"variant does not exist"
		}
		AdminToken.checkAuthorizedAdmin(ref)
		( // check for authorized admin		 
		 KissoNFT.artLibrary[productID]!).removeVariant(variantID: variantID)
	}
	
	access(all)
	fun removeArtLibraryProduct(productID: UInt64, ref: &AdminToken.Token?){ 
		pre{ 
			KissoNFT.artLibrary[productID] != nil:
				"product does not exist"
		}
		AdminToken.checkAuthorizedAdmin(ref) // check for authorized admin
		
		KissoNFT.artLibrary.remove(key: productID)
	}
	
	access(all)
	fun artLibraryItemExists(productID: UInt64, variantID: UInt64): Bool{ 
		if KissoNFT.artLibrary[productID] == nil{ 
			return false
		}
		if (KissoNFT.artLibrary[productID]!).variants[variantID] == nil{ 
			return false
		} else{ 
			return true
		}
	}
	
	access(all)
	fun getArtLibraryItem(productID: UInt64, variantID: UInt64): KissoNFT.Variant?{ 
		if KissoNFT.artLibrary[productID] == nil{ 
			return nil
		}
		if (KissoNFT.artLibrary[productID]!).variants[variantID] == nil{ 
			return nil
		}
		return (KissoNFT.artLibrary[productID]!).variants[variantID]
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.seriesTotalSupply ={} 
		self.lineItemRecords ={} 
		self.artLibrary ={} 
		
		// Set the named paths
		self.CollectionStoragePath = /storage/kissoNFTCollection
		self.CollectionPublicPath = /public/kissoNFTCollection
		self.MinterStoragePath = /storage/kissoNFTMinter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&KissoNFT.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
