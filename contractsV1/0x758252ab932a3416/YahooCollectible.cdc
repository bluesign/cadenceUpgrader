import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract YahooCollectible: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// totalSupply
	// The total number of YahooCollectible that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// metadata for each item
	// 
	access(contract)
	var itemMetadata:{ UInt64: Metadata}
	
	// Type Definitions
	// 
	access(all)
	struct Metadata{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		// mediaType: MIME type of the media
		// - image/png
		// - image/jpeg
		// - video/mp4
		// - audio/mpeg
		access(all)
		let mediaType: String
		
		// mediaHash: IPFS storage hash
		access(all)
		let mediaHash: String
		
		// additional metadata
		access(self)
		let additional:{ String: String}
		
		// number of items
		access(all)
		var itemCount: UInt64
		
		init(name: String, description: String, mediaType: String, mediaHash: String, additional:{ String: String}){ 
			self.name = name
			self.description = description
			self.mediaType = mediaType
			self.mediaHash = mediaHash
			self.additional = additional
			self.itemCount = 0
		}
		
		access(all)
		fun getAdditional():{ String: String}{ 
			return self.additional
		}
	}
	
	// NFT
	// A Yahoo Collectible NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// The token's type
		access(all)
		let itemID: UInt64
		
		// The token's edition number
		access(all)
		let editionNumber: UInt64
		
		// initializer
		//
		init(initID: UInt64, itemID: UInt64){ 
			self.id = initID
			self.itemID = itemID
			let metadata = YahooCollectible.itemMetadata[itemID] ?? panic("itemID not valid")
			self.editionNumber = metadata.itemCount + 1 as UInt64
			
			// Increment the edition count by 1
			metadata.itemCount = self.editionNumber
			YahooCollectible.itemMetadata[itemID] = metadata
		}
		
		// Expose metadata
		access(all)
		fun getMetadata(): Metadata?{ 
			return YahooCollectible.itemMetadata[self.itemID]
		}
		
		access(all)
		fun getRoyalties(): MetadataViews.Royalties{ 
			var royalties: [MetadataViews.Royalty] = []
			let receiver = getAccount(0xfcf3a236f4cd7dbc).capabilities.get<&{FungibleToken.Vault}>(/public/flowTokenReceiver)
			royalties.append(MetadataViews.Royalty(receiver: receiver, cut: 0.1, description: "Royalty receiver for Yahoo"))
			return MetadataViews.Royalties(royalties)
		}
		
		access(all)
		fun getEditions(): MetadataViews.Editions{ 
			let metadata = self.getMetadata() ?? panic("missing metadata")
			let editionInfo = MetadataViews.Edition(name: metadata.name, number: self.editionNumber, max: metadata.itemCount)
			let editionList: [MetadataViews.Edition] = [editionInfo]
			return MetadataViews.Editions(editionList)
		}
		
		access(all)
		fun getExternalURL(): MetadataViews.ExternalURL{ 
			return MetadataViews.ExternalURL("https://bay.blocto.app/flow/yahoo/".concat(self.id.toString()))
		}
		
		access(all)
		fun getCollectionData(): MetadataViews.NFTCollectionData{ 
			return MetadataViews.NFTCollectionData(storagePath: YahooCollectible.CollectionStoragePath, publicPath: YahooCollectible.CollectionPublicPath, publicCollection: Type<&YahooCollectible.Collection>(), publicLinkedType: Type<&YahooCollectible.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
					return <-YahooCollectible.createEmptyCollection(nftType: Type<@YahooCollectible.Collection>())
				})
		}
		
		access(all)
		fun getCollectionDisplay(): MetadataViews.NFTCollectionDisplay{ 
			let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://raw.githubusercontent.com/portto/assets/main/nft/flow/yahoo/logo.png"), mediaType: "image/png")
			let bannerImager = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://raw.githubusercontent.com/portto/assets/main/nft/flow/yahoo/banner.png"), mediaType: "image/png")
			return MetadataViews.NFTCollectionDisplay(name: "Yahoo", description: "NFT collection of Yahoo Taiwan", externalURL: MetadataViews.ExternalURL("https://bay.blocto.app/market?collections=yahoo"), squareImage: squareImage, bannerImage: bannerImager, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/Yahoo")})
		}
		
		access(all)
		fun getTraits(): MetadataViews.Traits{ 
			let metadata = self.getMetadata() ?? panic("missing metadata")
			return MetadataViews.dictToTraits(dict: metadata.getAdditional(), excludedNames: [])
		}
		
		access(all)
		fun getMedias(): MetadataViews.Medias{ 
			let metadata = self.getMetadata() ?? panic("missing metadata")
			let file = MetadataViews.IPFSFile(cid: metadata.mediaHash, path: nil)
			let mediaInfo = MetadataViews.Media(file: file, mediaType: metadata.mediaType)
			let mediaList: [MetadataViews.Media] = [mediaInfo]
			return MetadataViews.Medias(mediaList)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.IPFSFile>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Medias>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					let metadata = self.getMetadata() ?? panic("missing metadata")
					return MetadataViews.Display(name: metadata.name, description: metadata.description, thumbnail: MetadataViews.IPFSFile(cid: metadata.mediaHash, path: nil))
				case Type<MetadataViews.Royalties>():
					return self.getRoyalties()
				case Type<MetadataViews.Editions>():
					return self.getEditions()
				case Type<MetadataViews.ExternalURL>():
					return self.getExternalURL()
				case Type<MetadataViews.NFTCollectionData>():
					return self.getCollectionData()
				case Type<MetadataViews.NFTCollectionDisplay>():
					return self.getCollectionDisplay()
				case Type<MetadataViews.IPFSFile>():
					return MetadataViews.IPFSFile(cid: (self.getMetadata()!).mediaHash, path: nil)
				case Type<MetadataViews.Traits>():
					return self.getTraits()
				case Type<MetadataViews.Medias>():
					return self.getMedias()
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowYahooCollectible(id: UInt64): &YahooCollectible.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow YahooCollectible reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of YahooCollectible NFTs owned by an account
	//
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @YahooCollectible.NFT
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
		
		// borrowYahooCollectible
		// Gets a reference to an NFT in the collection as a YahooCollectible,
		// exposing all of its fields.
		// This is safe as there are no functions that can be called on the YahooCollectible.
		//
		access(all)
		fun borrowYahooCollectible(id: UInt64): &YahooCollectible.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &YahooCollectible.NFT
			} else{ 
				return nil
			}
		}
		
		// borrowViewResolver
		// Gets a reference to an MetadataView.Resolver in the collection as a YahooCollectible.
		// This is safe as there are no functions that can be called on the YahooCollectible.
		//
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let exampleNFT = nft as! &YahooCollectible.NFT
			return exampleNFT as &{ViewResolver.Resolver}
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
	
	// Admin
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource Admin{ 
		
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, itemID: UInt64, codeHash: String?){ 
			pre{ 
				codeHash == nil || !YahooCollectible.checkCodeHashUsed(codeHash: codeHash!):
					"duplicated codeHash"
			}
			emit Minted(id: YahooCollectible.totalSupply)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create YahooCollectible.NFT(initID: YahooCollectible.totalSupply, itemID: itemID))
			YahooCollectible.totalSupply = YahooCollectible.totalSupply + 1 as UInt64
			
			// if minter passed in codeHash, register it to dictionary
			if let checkedCodeHash = codeHash{ 
				let redeemedCodes = YahooCollectible.account.storage.load<{String: Bool}>(from: /storage/redeemedCodes)!
				redeemedCodes[checkedCodeHash] = true
				YahooCollectible.account.storage.save<{String: Bool}>(redeemedCodes, to: /storage/redeemedCodes)
			}
		}
		
		// batchMintNFT
		// Mints a batch of new NFTs
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun batchMintNFT(recipient: &{NonFungibleToken.CollectionPublic}, itemID: UInt64, count: Int){ 
			var index = 0
			while index < count{ 
				self.mintNFT(recipient: recipient, itemID: itemID, codeHash: nil)
				index = index + 1
			}
		}
		
		// registerMetadata
		// Registers metadata for a itemID
		//
		access(all)
		fun registerMetadata(itemID: UInt64, metadata: Metadata){ 
			pre{ 
				YahooCollectible.itemMetadata[itemID] == nil:
					"duplicated itemID"
			}
			YahooCollectible.itemMetadata[itemID] = metadata
		}
		
		// updateMetadata
		// Registers metadata for a itemID
		//
		access(all)
		fun updateMetadata(itemID: UInt64, metadata: Metadata){ 
			pre{ 
				YahooCollectible.itemMetadata[itemID] != nil:
					"itemID does not exist"
			}
			metadata.itemCount = (YahooCollectible.itemMetadata[itemID]!).itemCount
			
			// update metadata
			YahooCollectible.itemMetadata[itemID] = metadata
		}
	}
	
	// fetch
	// Get a reference to a YahooCollectible from an account's Collection, if available.
	// If an account does not have a YahooCollectible.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &YahooCollectible.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&YahooCollectible.Collection>(YahooCollectible.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust YahooCollectible.Collection.borowYahooCollectible to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowYahooCollectible(id: itemID)
	}
	
	// getMetadata
	// Get the metadata for a specific type of YahooCollectible
	//
	access(all)
	fun getMetadata(itemID: UInt64): Metadata?{ 
		return YahooCollectible.itemMetadata[itemID]
	}
	
	// checkCodeHashUsed
	// Check if a codeHash has been registered
	//
	access(all)
	view fun checkCodeHashUsed(codeHash: String): Bool{ 
		var redeemedCodes = YahooCollectible.account.storage.copy<{String: Bool}>(from: /storage/redeemedCodes)!
		return redeemedCodes[codeHash] ?? false
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/yahooCollectibleCollection
		self.CollectionPublicPath = /public/yahooCollectibleCollection
		self.AdminStoragePath = /storage/yahooCollectibleAdmin
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Initialize predefined metadata
		self.itemMetadata ={} 
		
		// Create a Admin resource and save it to storage
		let minter <- create Admin()
		self.account.storage.save(<-minter, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
