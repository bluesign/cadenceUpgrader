import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract FEHVAsset: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(contract)
	let minted:{ String: Bool}
	
	access(contract)
	let registry:{ String: AnyStruct}
	
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
	let AdminStoragePath: StoragePath
	
	// The ExtraData view provides extra metadata 
	// such as json data and metadata id.
	//
	access(all)
	struct ExtraData{ 
		access(all)
		let metadataId: String
		
		access(all)
		let free: Bool
		
		access(all)
		let jsonData: String
		
		init(metadataId: String, free: Bool, jsonData: String){ 
			self.metadataId = metadataId
			self.free = free
			self.jsonData = jsonData
		}
	}
	
	// Helper to get an ExtraData view in a typesafe way
	//
	access(all)
	fun getExtraData(_ viewResolver: &{ViewResolver.Resolver}): ExtraData?{ 
		if let view = viewResolver.resolveView(Type<ExtraData>()){ 
			if let v = view as? ExtraData{ 
				return v
			}
		}
		return nil
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let metadataId: String
		
		access(all)
		let free: Bool
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let externalUrl: String
		
		access(all)
		let video: String
		
		access(all)
		let jsonData: String
		
		access(self)
		let traits: [MetadataViews.Trait]
		
		init(id: UInt64, metadataId: String, free: Bool, name: String, description: String, thumbnail: String, externalUrl: String, video: String, jsonData: String, traits: [MetadataViews.Trait]){ 
			self.id = id
			self.metadataId = metadataId
			self.free = free
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.externalUrl = externalUrl
			self.video = video
			self.jsonData = jsonData
			self.traits = traits
			FEHVAsset.minted[metadataId] = true
			FEHVAsset.totalSupply = FEHVAsset.totalSupply + 1
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Medias>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>(), Type<FEHVAsset.ExtraData>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					let royalty = MetadataViews.Royalty(receiver: FEHVAsset.registry["royalty-capability"]! as! Capability<&{FungibleToken.Receiver}>, cut: FEHVAsset.registry["royalty-cut"]! as! UFix64, description: "Creator Royalty")
					return MetadataViews.Royalties([royalty])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(self.externalUrl.concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: FEHVAsset.CollectionStoragePath, publicPath: FEHVAsset.CollectionPublicPath, publicCollection: Type<&FEHVAsset.Collection>(), publicLinkedType: Type<&FEHVAsset.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-FEHVAsset.createEmptyCollection(nftType: Type<@FEHVAsset.Collection>())
						})
				case Type<MetadataViews.Medias>():
					let imageFile = MetadataViews.HTTPFile(url: self.thumbnail)
					let videoFile = MetadataViews.HTTPFile(url: self.video)
					let imageMedia = MetadataViews.Media(file: imageFile, mediaType: "image/png")
					let videoMedia = MetadataViews.Media(file: videoFile, mediaType: "video/mp4")
					return MetadataViews.Medias([imageMedia, videoMedia])
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: FEHVAsset.registry["square-image-url"]! as! String), mediaType: "image/png")
					let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: FEHVAsset.registry["banner-image-url"]! as! String), mediaType: "image/png")
					let externalUrl = FEHVAsset.registry["collection-external-url"]! as! String
					return MetadataViews.NFTCollectionDisplay(name: FEHVAsset.registry["collection-name"]! as! String, description: FEHVAsset.registry["collection-description"]! as! String, externalURL: MetadataViews.ExternalURL(externalUrl), squareImage: squareMedia, bannerImage: bannerMedia, socials: FEHVAsset.registry["social-links"]! as!{ String: MetadataViews.ExternalURL})
				case Type<MetadataViews.Traits>():
					return MetadataViews.Traits(self.traits)
				case Type<FEHVAsset.ExtraData>():
					return FEHVAsset.ExtraData(metadataId: self.metadataId, free: self.free, jsonData: self.jsonData)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface AssetCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowAsset(id: UInt64): &FEHVAsset.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Asset reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: AssetCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @FEHVAsset.NFT
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
		fun borrowAsset(id: UInt64): &FEHVAsset.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &FEHVAsset.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let asset = nft as! &FEHVAsset.NFT
			return asset
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
	
	// isMinted returns true if an NFT with that metadata ID was minted
	access(all)
	fun isMinted(metadataId: String): Bool{ 
		return self.minted[metadataId] == true
	}
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadataId: String, free: Bool, name: String, description: String, thumbnail: String, externalUrl: String, video: String, jsonData: String, traits: [MetadataViews.Trait]){ 
			pre{ 
				FEHVAsset.minted[metadataId] != true:
					"Already minted"
			}
			
			// create a new NFT
			var newNFT <- create NFT(id: FEHVAsset.totalSupply, metadataId: metadataId, free: free, name: name, description: description, thumbnail: thumbnail, externalUrl: externalUrl, video: video, jsonData: jsonData, traits: traits)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
		}
	}
	
	// A token resource that allows its holder to change the registry data.
	//
	access(all)
	resource Admin{ 
		access(all)
		fun setRegistry(key: String, value: AnyStruct){ 
			FEHVAsset.registry[key] = value
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Initialize the minted metadata IDs
		self.minted ={} 
		
		// Initialize the data registry
		self.registry ={} 
		
		// Set the named paths
		self.CollectionStoragePath = /storage/FEHVAssetCollection
		self.CollectionPublicPath = /public/FEHVAssetCollection
		self.MinterStoragePath = /storage/FEHVAssetMinter
		self.AdminStoragePath = /storage/FEHVAssetAdmin
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		
		// Create an Admin resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
