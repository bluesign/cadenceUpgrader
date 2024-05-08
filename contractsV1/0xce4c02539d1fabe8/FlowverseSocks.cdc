import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract FlowverseSocks: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var nextID: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	//pub var CollectionPrivatePath: PrivatePath
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64, creator: Address, metadata:{ String: String})
	
	access(all)
	event Destroy(id: UInt64)
	
	access(all)
	var baseURI: String
	
	access(all)
	fun getTokenURI(id: UInt64): String{ 
		return self.baseURI.concat("/").concat(id.toString())
	}
	
	// We use dict to store raw metadata
	access(all)
	resource interface RawMetadata{ 
		access(all)
		fun getRawMetadata():{ String: String}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver, RawMetadata{ 
		access(all)
		let id: UInt64
		
		access(all)
		let creator: Address
		
		access(self)
		let metadata:{ String: String}
		
		init(id: UInt64, creator: Address, metadata:{ String: String}){ 
			self.id = id
			self.creator = creator
			self.metadata = metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Medias>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "Socks by Flowverse #".concat(self.id.toString()), description: "Socks by Flowverse are versatile NFTs that enable you to claim 1 limited edition pair of physical Flowverse Socks, shipped globally. Instructions on how to redeem will be published on the Flowverse website early 2022 and will involve a shipping + raw material cost. Each NFT can only be redeemed once for a physical pair of socks. Make sure to check if this specific pair has already been redeemed prior to purchase by checking the Flowverse website here: https://flowverse.co/socks . These NFTs are created by Designer and 3D motion artist Jenny Jiang. There are 111 total Socks by Flowverse. ", thumbnail: MetadataViews.HTTPFile(url: "https://chainbase.media.nft.matrixlabs.org/FlowverseSocks/default.gif"))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://www.socknft.com/")
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: getAccount(0x604b63bcbef5974f).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, cut: 0.05, description: "Flowverse artist royalty")])
				case Type<MetadataViews.Medias>():
					return MetadataViews.Medias([MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://chainbase.media.nft.matrixlabs.org/FlowverseSocks/default_vedio.mp4"), mediaType: "video/mp4")])
				case Type<MetadataViews.NFTCollectionDisplay>():
					let externalURL = MetadataViews.ExternalURL("https://www.socknft.com/")
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://media.nft.matrixmarket.xyz/media/dbbrUIkarYLXKKjiY5AYk_IMAGE.png"), mediaType: "image")
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://media.nft.matrixmarket.xyz/media/cvR_VOmK5g6oGMhXRj1pR_IMAGE.png"), mediaType: "image")
					return MetadataViews.NFTCollectionDisplay(name: "Flowverse Socks", description: "Socks by Flowverse are versatile NFTs that enable you to claim 1 limited edition pair of physical Flowverse Socks, shipped globally. The total number of Socks by Flowverse is 111.", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials:{ "discord": MetadataViews.ExternalURL("https://discord.com/invite/flowverse"), "twitter": MetadataViews.ExternalURL("https://twitter.com/flowverse_")})
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: FlowverseSocks.CollectionStoragePath, publicPath: FlowverseSocks.CollectionPublicPath, publicCollection: Type<&Collection>(), publicLinkedType: Type<&Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-FlowverseSocks.createEmptyCollection(nftType: Type<@FlowverseSocks.Collection>())
						})
				case Type<MetadataViews.Traits>():
					let traits: [MetadataViews.Trait] = []
					return MetadataViews.Traits(traits)
			}
			return nil
		}
		
		access(all)
		fun getRawMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface FlowverseSocksCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrow_NFT_NAME_(id: UInt64): &FlowverseSocks.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow NFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: FlowverseSocksCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @FlowverseSocks.NFT
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
		fun borrow_NFT_NAME_(id: UInt64): &FlowverseSocks.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &FlowverseSocks.NFT?
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let mlNFT = nft as! &FlowverseSocks.NFT
			return mlNFT
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
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFTWithID mints a new NFT with id
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFTWithID(id: UInt64, recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}): &{NonFungibleToken.NFT}{ 
			if FlowverseSocks.nextID <= id{ 
				FlowverseSocks.nextID = id + 1
			}
			let creator = (self.owner!).address
			// create a new NFT
			var newNFT <- create NFT(id: id, creator: creator, metadata: metadata)
			let tokenRef = &newNFT as &{NonFungibleToken.NFT}
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			FlowverseSocks.totalSupply = FlowverseSocks.totalSupply + 1
			emit Mint(id: tokenRef.id, creator: creator, metadata: metadata)
			return tokenRef
		}
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}): &{NonFungibleToken.NFT}{ 
			let creator = (self.owner!).address
			// create a new NFT
			var newNFT <- create NFT(id: FlowverseSocks.nextID, creator: creator, metadata: metadata)
			FlowverseSocks.nextID = FlowverseSocks.nextID + 1
			let tokenRef = &newNFT as &{NonFungibleToken.NFT}
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			FlowverseSocks.totalSupply = FlowverseSocks.totalSupply + 1
			emit Mint(id: tokenRef.id, creator: creator, metadata: metadata)
			return tokenRef
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun setBaseURI(baseURI: String){ 
			FlowverseSocks.baseURI = baseURI
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.nextID = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/MatrixMarketFlowverseSocksCollection
		self.CollectionPublicPath = /public/MatrixMarketFlowverseSocksCollection
		self.MinterStoragePath = /storage/MatrixMarketFlowverseSocksMinter
		self.AdminStoragePath = /storage/MatrixMarketFlowverseSocksAdmin
		self.baseURI = ""
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&FlowverseSocks.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
