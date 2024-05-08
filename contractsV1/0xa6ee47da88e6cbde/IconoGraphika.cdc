import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract IconoGraphika: NonFungibleToken{ 
	access(all)
	struct IconoGraphikaDisplay{ 
		access(all)
		let itemId: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let collectionName: String
		
		access(all)
		let collectionDescription: String
		
		access(all)
		let shortDescription: String
		
		access(all)
		let fullDescription: String
		
		access(all)
		let creatorName: String
		
		access(all)
		let mintDateTime: UInt64
		
		access(all)
		let mintLocation: String
		
		access(all)
		let copyrightHolder: String
		
		access(all)
		let minterName: String
		
		access(all)
		let fileFormat: String
		
		access(all)
		let propertyObjectType: String
		
		access(all)
		let propertyColour: String
		
		access(all)
		let rightsAndObligationsSummary: String
		
		access(all)
		let rightsAndObligationsFullText: String
		
		access(all)
		let editionSize: UInt64
		
		access(all)
		let editionNumber: UInt64
		
		access(all)
		let fileSizeMb: UFix64
		
		access(all)
		let imageCID:{ MetadataViews.File}
		
		init(itemId: UInt64, name: String, collectionName: String, collectionDescription: String, shortDescription: String, fullDescription: String, creatorName: String, mintDateTime: UInt64, mintLocation: String, copyrightHolder: String, minterName: String, fileFormat: String, propertyObjectType: String, propertyColour: String, rightsAndObligationsSummary: String, rightsAndObligationsFullText: String, editionSize: UInt64, editionNumber: UInt64, fileSizeMb: UFix64, imageCID:{ MetadataViews.File}){ 
			self.itemId = itemId
			
			// String
			self.name = name
			self.collectionName = collectionName
			self.collectionDescription = collectionDescription
			self.shortDescription = shortDescription
			self.fullDescription = fullDescription
			self.creatorName = creatorName
			self.mintLocation = mintLocation
			self.copyrightHolder = copyrightHolder
			self.minterName = minterName
			self.fileFormat = fileFormat
			self.propertyObjectType = propertyObjectType
			self.propertyColour = propertyColour
			self.rightsAndObligationsSummary = rightsAndObligationsSummary
			self.rightsAndObligationsFullText = rightsAndObligationsFullText
			
			// UInt64
			self.mintDateTime = mintDateTime
			self.editionSize = editionSize
			self.editionNumber = editionNumber
			
			// UFix64
			self.fileSizeMb = fileSizeMb
			
			// IPFS
			self.imageCID = imageCID
		}
	}
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, name: String)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let collectionName: String
		
		access(all)
		let collectionDescription: String
		
		access(all)
		let collectionSquareImageCID: String
		
		access(all)
		let collectionBannerImageCID: String
		
		access(all)
		let shortDescription: String
		
		access(all)
		let fullDescription: String
		
		access(all)
		let creatorName: String
		
		// Save date as unix epoch timestamp
		access(all)
		let mintDateTime: UInt64
		
		access(all)
		let mintLocation: String
		
		access(all)
		let copyrightHolder: String
		
		access(all)
		let minterName: String
		
		access(all)
		let fileFormat: String
		
		access(all)
		let propertyObjectType: String
		
		access(all)
		let propertyColour: String
		
		access(all)
		let rightsAndObligationsSummary: String
		
		access(all)
		let rightsAndObligationsFullText: String
		
		access(all)
		let editionSize: UInt64
		
		access(all)
		let editionNumber: UInt64
		
		access(all)
		let fileSizeMb: UFix64
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		access(all)
		let imageCID: String
		
		init(id: UInt64, name: String, collectionName: String, collectionDescription: String, collectionSquareImageCID: String, collectionBannerImageCID: String, shortDescription: String, fullDescription: String, creatorName: String, mintDateTime: UInt64, mintLocation: String, copyrightHolder: String, minterName: String, fileFormat: String, propertyObjectType: String, propertyColour: String, rightsAndObligationsSummary: String, rightsAndObligationsFullText: String, editionSize: UInt64, editionNumber: UInt64, fileSizeMb: UFix64, royalties: [MetadataViews.Royalty], imageCID: String){ 
			self.id = id
			
			// String
			self.name = name
			self.collectionName = collectionName
			self.collectionDescription = collectionDescription
			self.collectionSquareImageCID = collectionSquareImageCID
			self.collectionBannerImageCID = collectionBannerImageCID
			self.shortDescription = shortDescription
			self.fullDescription = fullDescription
			self.creatorName = creatorName
			self.mintDateTime = mintDateTime
			self.mintLocation = mintLocation
			self.copyrightHolder = copyrightHolder
			self.minterName = minterName
			self.fileFormat = fileFormat
			self.propertyObjectType = propertyObjectType
			self.propertyColour = propertyColour
			self.rightsAndObligationsSummary = rightsAndObligationsSummary
			self.rightsAndObligationsFullText = rightsAndObligationsFullText
			
			// UInt64
			self.editionSize = editionSize
			self.editionNumber = editionNumber
			
			// UFix64
			self.fileSizeMb = fileSizeMb
			
			// Royalties
			self.royalties = royalties
			
			// IPFS
			self.imageCID = imageCID
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<IconoGraphikaDisplay>(), Type<MetadataViews.IPFSFile>(), Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Medias>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<IconoGraphikaDisplay>():
					return IconoGraphikaDisplay(itemId: self.id, name: self.name, collectionName: self.collectionName, collectionDescription: self.collectionDescription, shortDescription: self.shortDescription, fullDescription: self.fullDescription, creatorName: self.creatorName, mintDateTime: self.mintDateTime, mintLocation: self.mintLocation, copyrightHolder: self.copyrightHolder, minterName: self.minterName, fileFormat: self.fileFormat, propertyObjectType: self.propertyObjectType, propertyColour: self.propertyColour, rightsAndObligationsSummary: self.rightsAndObligationsSummary, rightsAndObligationsFullText: self.rightsAndObligationsFullText, editionSize: self.editionSize, editionNumber: self.editionNumber, fileSizeMb: self.fileSizeMb, imageCID: MetadataViews.IPFSFile(cid: self.imageCID, path: nil))
				case Type<MetadataViews.IPFSFile>():
					return MetadataViews.IPFSFile(cid: self.imageCID, path: nil)
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.shortDescription, thumbnail: MetadataViews.IPFSFile(cid: self.imageCID, path: nil))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://iconographika.com/")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: IconoGraphika.CollectionStoragePath, publicPath: IconoGraphika.CollectionPublicPath, publicCollection: Type<&IconoGraphika.Collection>(), publicLinkedType: Type<&IconoGraphika.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-IconoGraphika.createEmptyCollection(nftType: Type<@IconoGraphika.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					return MetadataViews.NFTCollectionDisplay(name: self.collectionName, description: self.collectionDescription, externalURL: MetadataViews.ExternalURL("https://iconographika.com/"), squareImage: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: self.collectionSquareImageCID, path: nil), mediaType: "image/png"), bannerImage: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: self.collectionBannerImageCID, path: nil), mediaType: "image/png"), socials:{} )
				case Type<MetadataViews.Medias>():
					return MetadataViews.Medias([MetadataViews.Media(file: MetadataViews.IPFSFile(cid: self.imageCID, path: nil), mediaType: "image/".concat(self.fileFormat))])
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.Traits>():
					return MetadataViews.Traits([MetadataViews.Trait(name: "NFT Creator", value: self.creatorName, displayType: nil, rarity: nil), MetadataViews.Trait(name: "NFT Copyright Holder", value: self.copyrightHolder, displayType: nil, rarity: nil), MetadataViews.Trait(name: "Minter Name", value: self.minterName, displayType: nil, rarity: nil), MetadataViews.Trait(name: "NFT Mint Date", value: self.mintDateTime, displayType: "Date", rarity: nil), MetadataViews.Trait(name: "NFT Mint Location", value: self.mintLocation, displayType: nil, rarity: nil), MetadataViews.Trait(name: "NFT Rights and Obligations Summary", value: self.rightsAndObligationsSummary, displayType: nil, rarity: nil), MetadataViews.Trait(name: "NFT Rights and Obligations Full", value: self.rightsAndObligationsFullText, displayType: nil, rarity: nil), MetadataViews.Trait(name: "NFT Object Type", value: self.propertyObjectType, displayType: nil, rarity: nil), MetadataViews.Trait(name: "NFT Color", value: self.propertyColour, displayType: nil, rarity: nil)])
				case Type<MetadataViews.Editions>():
					return MetadataViews.Editions([MetadataViews.Edition(name: nil, number: self.editionNumber, max: self.editionSize)])
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface IconoGraphikaCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowIconoGraphika(id: UInt64): &IconoGraphika.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow IconoGraphika reference: the ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
	}
	
	access(all)
	resource Collection: IconoGraphikaCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @IconoGraphika.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
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
		fun borrowIconoGraphika(id: UInt64): &IconoGraphika.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &IconoGraphika.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let IconoGraphika = nft as! &IconoGraphika.NFT
			return IconoGraphika as &{ViewResolver.Resolver}
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
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	fun createMinter(): @NFTMinter{ 
		return <-create NFTMinter()
	}
	
	access(all)
	resource NFTMinter{ 
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, collectionName: String, collectionDescription: String, collectionSquareImageCID: String, collectionBannerImageCID: String, shortDescription: String, fullDescription: String, creatorName: String, mintDateTime: UInt64, mintLocation: String, copyrightHolder: String, minterName: String, fileFormat: String, propertyObjectType: String, propertyColour: String, rightsAndObligationsSummary: String, rightsAndObligationsFullText: String, editionSize: UInt64, editionNumber: UInt64, fileSizeMb: UFix64, royalties: [MetadataViews.Royalty], imageCID: String){ 
			var newNFT <- create NFT(id: IconoGraphika.totalSupply, name: name, collectionName: collectionName, collectionDescription: collectionDescription, collectionSquareImageCID: collectionSquareImageCID, collectionBannerImageCID: collectionBannerImageCID, shortDescription: shortDescription, fullDescription: fullDescription, creatorName: creatorName, mintDateTime: mintDateTime, mintLocation: mintLocation, copyrightHolder: copyrightHolder, minterName: minterName, fileFormat: fileFormat, propertyObjectType: propertyObjectType, propertyColour: propertyColour, rightsAndObligationsSummary: rightsAndObligationsSummary, rightsAndObligationsFullText: rightsAndObligationsFullText, editionSize: editionSize, editionNumber: editionNumber, fileSizeMb: fileSizeMb, royalties: royalties, imageCID: imageCID)
			
			// deposit newNFT in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			IconoGraphika.totalSupply = IconoGraphika.totalSupply + 1
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/IconoGraphikaNFT
		self.CollectionPublicPath = /public/IconoGraphikaNFT
		self.MinterStoragePath = /storage/IconoGraphikaNFTMinter
		self.account.storage.save(<-self.createEmptyCollection(nftType: Type<@Collection>()), to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&IconoGraphika.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		self.account.storage.save(<-self.createMinter(), to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
