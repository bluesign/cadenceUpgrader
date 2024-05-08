import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract FEHVNexus: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(contract)
	let minted:{ String: Bool}
	
	access(contract)
	let registry:{ String: AnyStruct}
	
	access(contract)
	let metadata:{ Int: Category}
	
	access(contract)
	let burned:{ Address:{ Int: UInt64}}
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Burn(id: UInt64, category: Int, print: UInt64, from: Address)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// The ExtraView view provides extra metadata.
	//
	access(all)
	struct ExtraView{ 
		access(all)
		let externalUuid: String
		
		access(all)
		let print: UInt64
		
		init(externalUuid: String, print: UInt64){ 
			self.externalUuid = externalUuid
			self.print = print
		}
	}
	
	// Helper to get an ExtraView view in a typesafe way
	//
	access(all)
	fun getExtraView(_ viewResolver: &{ViewResolver.Resolver}): ExtraView?{ 
		if let view = viewResolver.resolveView(Type<ExtraView>()){ 
			if let v = view as? ExtraView{ 
				return v
			}
		}
		return nil
	}
	
	// The Category structure stores token metadata.
	//
	access(all)
	struct Category{ 
		access(all)
		var supply: UInt64
		
		access(all)
		var name: String
		
		access(all)
		var description: String
		
		access(all)
		var thumbnail: String
		
		access(all)
		var externalUrl: String
		
		access(all)
		var video: String
		
		access(contract)
		var traits: [MetadataViews.Trait]
		
		init(){ 
			self.supply = 0
			self.name = ""
			self.description = ""
			self.thumbnail = ""
			self.externalUrl = ""
			self.video = ""
			self.traits = []
		}
		
		access(contract)
		fun setData(name: String, description: String, thumbnail: String, externalUrl: String, video: String, traits: [MetadataViews.Trait]){ 
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.externalUrl = externalUrl
			self.video = video
			self.traits = traits
		}
		
		access(contract)
		fun getSupplyAndInc(): UInt64{ 
			let value = self.supply
			self.supply = self.supply + 1
			return value
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let externalUuid: String
		
		access(all)
		let category: Int
		
		access(all)
		let print: UInt64
		
		init(id: UInt64, externalUuid: String, category: Int, print: UInt64){ 
			self.id = id
			self.externalUuid = externalUuid
			self.category = category
			self.print = print
			FEHVNexus.minted[externalUuid] = true
			FEHVNexus.totalSupply = FEHVNexus.totalSupply + 1
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Medias>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>(), Type<FEHVNexus.ExtraView>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: (FEHVNexus.metadata[self.category]!).name.concat(" #").concat(self.print.toString()), description: (FEHVNexus.metadata[self.category]!).description, thumbnail: MetadataViews.HTTPFile(url: (FEHVNexus.metadata[self.category]!).thumbnail))
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					let royalty = MetadataViews.Royalty(receiver: FEHVNexus.registry["royalty-capability"]! as! Capability<&{FungibleToken.Receiver}>, cut: FEHVNexus.registry["royalty-cut"]! as! UFix64, description: "Creator Royalty")
					return MetadataViews.Royalties([royalty])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL((FEHVNexus.metadata[self.category]!).externalUrl.concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: FEHVNexus.CollectionStoragePath, publicPath: FEHVNexus.CollectionPublicPath, publicCollection: Type<&FEHVNexus.Collection>(), publicLinkedType: Type<&FEHVNexus.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-FEHVNexus.createEmptyCollection(nftType: Type<@FEHVNexus.Collection>())
						})
				case Type<MetadataViews.Medias>():
					let imageFile = MetadataViews.HTTPFile(url: (FEHVNexus.metadata[self.category]!).thumbnail)
					let videoFile = MetadataViews.HTTPFile(url: (FEHVNexus.metadata[self.category]!).video)
					let imageMedia = MetadataViews.Media(file: imageFile, mediaType: "image/png")
					let videoMedia = MetadataViews.Media(file: videoFile, mediaType: "video/mp4")
					return MetadataViews.Medias([imageMedia, videoMedia])
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: FEHVNexus.registry["square-image-url"]! as! String), mediaType: "image/png")
					let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: FEHVNexus.registry["banner-image-url"]! as! String), mediaType: "image/png")
					let externalUrl = FEHVNexus.registry["collection-external-url"]! as! String
					return MetadataViews.NFTCollectionDisplay(name: FEHVNexus.registry["collection-name"]! as! String, description: FEHVNexus.registry["collection-description"]! as! String, externalURL: MetadataViews.ExternalURL(externalUrl), squareImage: squareMedia, bannerImage: bannerMedia, socials: FEHVNexus.registry["social-links"]! as!{ String: MetadataViews.ExternalURL})
				case Type<MetadataViews.Traits>():
					return MetadataViews.Traits((FEHVNexus.metadata[self.category]!).traits)
				case Type<FEHVNexus.ExtraView>():
					return FEHVNexus.ExtraView(externalUuid: self.externalUuid, print: self.print)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface NexusCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowNexus(id: UInt64): &FEHVNexus.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Nexus reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: NexusCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @FEHVNexus.NFT
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
		fun borrowNexus(id: UInt64): &FEHVNexus.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &FEHVNexus.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nexus = nft as! &FEHVNexus.NFT
			return nexus
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
	
	// isMinted returns true if a Nexus with that external UUID was minted
	access(all)
	fun isMinted(externalUuid: String): Bool{ 
		return self.minted[externalUuid] == true
	}
	
	// viewCategory returns the category metadata
	access(all)
	fun viewCategory(category: Int): Category?{ 
		return self.metadata[category]
	}
	
	// Increments the burnt registry for that address and token category
	access(all)
	fun registerBurn(token: @FEHVNexus.NFT, from: Address){ 
		// Burn token
		let category = token.category
		emit Burn(id: token.id, category: category, print: token.print, from: from)
		destroy token
		
		// Register burn
		if !self.burned.containsKey(from){ 
			self.burned.insert(key: from,{} )
		}
		if !(self.burned[from]!).containsKey(category){ 
			(self.burned[from]!).insert(key: category, 0)
		}
		let balance = (self.burned[from]!)[category]!
		(self.burned[from]!).insert(key: category, balance + 1)
	}
	
	// Returns the burnt balance of a category for a user
	access(all)
	fun getBurntBalance(from: Address, category: Int): UInt64{ 
		if !self.burned.containsKey(from){ 
			return 0
		}
		if !(self.burned[from]!).containsKey(category){ 
			return 0
		}
		return (self.burned[from]!)[category]!
	}
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs and set metadata
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, externalUuid: String, category: Int){ 
			pre{ 
				!FEHVNexus.minted.containsKey(externalUuid):
					"Already minted"
				FEHVNexus.metadata.containsKey(category):
					"Metadata not set"
				(FEHVNexus.metadata[category]!).supply < 10000:
					"Max supply is reached"
			}
			
			// create a new NFT
			var newNFT <- create NFT(id: FEHVNexus.totalSupply, externalUuid: externalUuid, category: category, print: (FEHVNexus.metadata[category]!).getSupplyAndInc())
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
		}
	}
	
	// A token resource that allows its holder to change data.
	//
	access(all)
	resource Admin{ 
		access(all)
		fun setRegistry(key: String, value: AnyStruct){ 
			FEHVNexus.registry[key] = value
		}
		
		access(all)
		fun setMetadata(category: Int, name: String, description: String, thumbnail: String, externalUrl: String, video: String, traits: [MetadataViews.Trait]){ 
			if !FEHVNexus.metadata.containsKey(category){ 
				FEHVNexus.metadata.insert(key: category, Category())
			}
			(FEHVNexus.metadata[category]!).setData(name: name, description: description, thumbnail: thumbnail, externalUrl: externalUrl, video: video, traits: traits)
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Initialize the minted external UUIDs
		self.minted ={} 
		
		// Initialize the data registry
		self.registry ={} 
		
		// Initialize the metadata
		self.metadata ={} 
		
		// Initialize the burned
		self.burned ={} 
		
		// Set the named paths
		self.CollectionStoragePath = /storage/FEHVNexusCollection
		self.CollectionPublicPath = /public/FEHVNexusCollection
		self.MinterStoragePath = /storage/FEHVNexusMinter
		self.AdminStoragePath = /storage/FEHVNexusAdmin
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		
		// Create an Admin resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
