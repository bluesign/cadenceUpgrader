import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import AthleteStudioMintCache from "./AthleteStudioMintCache.cdc"

access(all)
contract AthleteStudio: NonFungibleToken{ 
	access(all)
	let version: String
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, editionID: UInt64, serialNumber: UInt64)
	
	access(all)
	event Burned(id: UInt64)
	
	access(all)
	event EditionCreated(edition: Edition)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	/// The total number of Athlete Studio NFTs that have been minted.
	///
	access(all)
	var totalSupply: UInt64
	
	/// The total number of Athlete Studio NFT editions that have been created.
	///
	access(all)
	var totalEditions: UInt64
	
	/// The royalty information for all Athlete Studio NFTs.
	///
	access(all)
	var royalty: MetadataViews.Royalty?
	
	access(all)
	struct Metadata{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let asset: String
		
		access(all)
		let assetType: String
		
		access(all)
		let athleteID: Int
		
		access(all)
		let athleteName: String
		
		access(all)
		let athleteURL: String
		
		access(all)
		let itemType: String
		
		access(all)
		let itemCategory: String
		
		access(all)
		let series: String
		
		access(all)
		let eventName: String
		
		access(all)
		let eventDate: String
		
		access(all)
		let eventType: String
		
		access(all)
		let signed: Bool
		
		init(name: String, description: String, thumbnail: String, asset: String, assetType: String, athleteID: Int, athleteName: String, athleteURL: String, itemType: String, itemCategory: String, series: String, eventName: String, eventDate: String, eventType: String, signed: Bool){ 
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.asset = asset
			self.assetType = assetType
			self.athleteID = athleteID
			self.athleteName = athleteName
			self.athleteURL = athleteURL
			self.itemType = itemType
			self.itemCategory = itemCategory
			self.series = series
			self.eventName = eventName
			self.eventDate = eventDate
			self.eventType = eventType
			self.signed = signed
		}
	}
	
	access(all)
	struct Edition{ 
		access(all)
		let id: UInt64
		
		/// The maximum size of this edition.
		///
		access(all)
		let size: UInt64
		
		/// The number of NFTs minted in this edition.
		///
		/// The count cannot exceed the edition size.
		///
		access(all)
		var count: UInt64
		
		/// The metadata for this edition.
		///
		access(all)
		let metadata: Metadata
		
		init(id: UInt64, size: UInt64, metadata: Metadata){ 
			self.id = id
			self.size = size
			self.metadata = metadata
			
			// An edition starts with a count of zero
			self.count = 0
		}
		
		/// Increment the NFT count of this edition.
		///
		/// The count cannot exceed the edition size.
		///
		access(contract)
		fun incrementCount(){ 
			post{ 
				self.count <= self.size:
					"edition has already reached its maximum size"
			}
			self.count = self.count + 1 as UInt64
		}
	}
	
	access(self)
	let editions:{ UInt64: Edition}
	
	access(all)
	fun getEdition(id: UInt64): Edition?{ 
		return AthleteStudio.editions[id]
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let editionID: UInt64
		
		access(all)
		let serialNumber: UInt64
		
		init(editionID: UInt64, serialNumber: UInt64){ 
			self.id = self.uuid
			self.editionID = editionID
			self.serialNumber = serialNumber
		}
		
		/// Return the edition that this NFT belongs to.
		///
		access(all)
		fun getEdition(): Edition{ 
			return AthleteStudio.getEdition(id: self.editionID)!
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.NFTView>(), Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Edition>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Media>(), Type<MetadataViews.Medias>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let edition = self.getEdition()
			switch view{ 
				case Type<MetadataViews.NFTView>():
					return self.resolveNFTView(edition.metadata)
				case Type<MetadataViews.Display>():
					return self.resolveDisplay(edition.metadata)
				case Type<MetadataViews.ExternalURL>():
					return self.resolveExternalURL(edition.metadata)
				case Type<MetadataViews.NFTCollectionDisplay>():
					return self.resolveNFTCollectionDisplay()
				case Type<MetadataViews.NFTCollectionData>():
					return self.resolveNFTCollectionData()
				case Type<MetadataViews.Royalties>():
					return self.resolveRoyalties()
				case Type<MetadataViews.Edition>():
					return self.resolveEditionView(edition)
				case Type<MetadataViews.Serial>():
					return self.resolveSerialView(self.serialNumber)
				case Type<MetadataViews.Media>():
					return self.resolveMedia(edition.metadata)
				case Type<MetadataViews.Medias>():
					return self.resolveMedias(edition.metadata)
			}
			return nil
		}
		
		access(all)
		fun resolveNFTView(_ metadata: Metadata): MetadataViews.NFTView{ 
			return MetadataViews.NFTView(id: self.id, uuid: self.uuid, display: self.resolveDisplay(metadata), externalURL: self.resolveExternalURL(metadata), collectionData: self.resolveNFTCollectionData(), collectionDisplay: self.resolveNFTCollectionDisplay(), royalties: self.resolveRoyalties(), traits: nil)
		}
		
		access(all)
		fun resolveDisplay(_ metadata: Metadata): MetadataViews.Display{ 
			return MetadataViews.Display(name: metadata.name, description: metadata.description, thumbnail: MetadataViews.IPFSFile(cid: metadata.thumbnail, path: nil))
		}
		
		access(all)
		fun resolveExternalURL(_ metadata: Metadata): MetadataViews.ExternalURL{ 
			return MetadataViews.ExternalURL(metadata.athleteURL)
		}
		
		access(all)
		fun resolveNFTCollectionDisplay(): MetadataViews.NFTCollectionDisplay{ 
			let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://d3w5a827wx4ops.cloudfront.net/athlete-studio-logo-light.png"), mediaType: "image/png")
			return MetadataViews.NFTCollectionDisplay(name: "Athlete Studio NFTs", description: "Officially licensed NFTs from Pro Athletes.", externalURL: MetadataViews.ExternalURL("https://athlete.studio"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://athlete.studio/twitter"), "instagram": MetadataViews.ExternalURL("https://athlete.studio/instagram")})
		}
		
		access(all)
		fun resolveNFTCollectionData(): MetadataViews.NFTCollectionData{ 
			return MetadataViews.NFTCollectionData(storagePath: AthleteStudio.CollectionStoragePath, publicPath: AthleteStudio.CollectionPublicPath, publicCollection: Type<&AthleteStudio.Collection>(), publicLinkedType: Type<&AthleteStudio.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
					return <-AthleteStudio.createEmptyCollection(nftType: Type<@AthleteStudio.Collection>())
				})
		}
		
		access(all)
		fun resolveRoyalties(): MetadataViews.Royalties{ 
			// Return the Athlete Studio royalty if one is set
			if let royalty = AthleteStudio.royalty{ 
				return MetadataViews.Royalties([royalty])
			}
			return MetadataViews.Royalties([])
		}
		
		access(all)
		fun resolveEditionView(_ edition: Edition): MetadataViews.Edition{ 
			return MetadataViews.Edition(name: "Edition", number: self.serialNumber, max: edition.size)
		}
		
		access(all)
		fun resolveSerialView(_ serialNumber: UInt64): MetadataViews.Serial{ 
			return MetadataViews.Serial(serialNumber)
		}
		
		access(all)
		fun resolveMedia(_ metadata: Metadata): MetadataViews.Media{ 
			return MetadataViews.Media(file: MetadataViews.IPFSFile(cid: metadata.asset, path: nil), mediaType: metadata.assetType)
		}
		
		access(all)
		fun resolveMedias(_ metadata: Metadata): MetadataViews.Medias{ 
			return MetadataViews.Medias([MetadataViews.Media(file: MetadataViews.IPFSFile(cid: metadata.asset, path: nil), mediaType: metadata.assetType), MetadataViews.Media(file: MetadataViews.IPFSFile(cid: metadata.thumbnail, path: nil), mediaType: "image/png")])
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface AthleteStudioCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowAthleteStudio(id: UInt64): &AthleteStudio.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow AthleteStudio reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: AthleteStudioCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		
		/// A dictionary of all NFTs in this collection indexed by ID.
		///
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		/// Remove an NFT from the collection and move it to the caller.
		///
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Requested NFT to withdraw does not exist in this collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		/// Deposit an NFT into this collection.
		///
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @AthleteStudio.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		/// Return an array of the NFT IDs in this collection.
		///
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		/// Return a reference to an NFT in this collection.
		///
		/// This function panics if the NFT does not exist in this collection.
		///
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		/// Return a reference to an NFT in this collection
		/// typed as AthleteStudio.NFT.
		///
		/// This function returns nil if the NFT does not exist in this collection.
		///
		access(all)
		fun borrowAthleteStudio(id: UInt64): &AthleteStudio.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &AthleteStudio.NFT
			}
			return nil
		}
		
		/// Return a reference to an NFT in this collection
		/// typed as MetadataViews.Resolver.
		///
		/// This function panics if the NFT does not exist in this collection.
		///
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nftRef = nft as! &AthleteStudio.NFT
			return nftRef as &{ViewResolver.Resolver}
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
	
	/// Return a new empty collection.
	///
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	/// The administrator resource used to mint and reveal NFTs.
	///
	access(all)
	resource Admin{ 
		
		/// Create a new NFT edition.
		///
		/// This function does not mint any NFTs. It only creates the
		/// edition data that will later be associated with minted NFTs.
		///
		access(all)
		fun createEdition(mintID: String, size: UInt64, name: String, description: String, thumbnail: String, asset: String, assetType: String, athleteID: Int, athleteName: String, athleteURL: String, itemType: String, itemCategory: String, series: String, eventName: String, eventDate: String, eventType: String, signed: Bool): UInt64{ 
			// Prevent multiple editions from being minted with the same mint ID
			assert(AthleteStudioMintCache.getEditionByMintID(mintID: mintID) == nil, message: "an edition has already been created with mintID=".concat(mintID))
			let metadata = Metadata(name: name, description: description, thumbnail: thumbnail, asset: asset, assetType: assetType, athleteID: athleteID, athleteName: athleteName, athleteURL: athleteURL, itemType: itemType, itemCategory: itemCategory, series: series, eventName: eventName, eventDate: eventDate, eventType: eventType, signed: signed)
			let edition = Edition(id: AthleteStudio.totalEditions, size: size, metadata: metadata)
			AthleteStudio.editions[edition.id] = edition
			emit EditionCreated(edition: edition)
			
			// Update the mint ID index
			AthleteStudioMintCache.insertEditionMintID(mintID: mintID, editionID: edition.id)
			AthleteStudio.totalEditions = AthleteStudio.totalEditions + 1 as UInt64
			return edition.id
		}
		
		/// Mint a new NFT.
		///
		/// This function will mint the next NFT in this edition
		/// and automatically assign the serial number.
		///
		/// This function will panic if the edition has already
		/// reached its maximum size.
		///
		access(all)
		fun mintNFT(editionID: UInt64): @AthleteStudio.NFT{ 
			let edition = AthleteStudio.editions[editionID] ?? panic("edition does not exist")
			
			// Increase the edition count by one
			edition.incrementCount()
			
			// The NFT serial number is the new edition count
			let serialNumber = edition.count
			let nft <- create AthleteStudio.NFT(editionID: editionID, serialNumber: serialNumber)
			
			// Save the updated edition
			AthleteStudio.editions[editionID] = edition
			emit Minted(id: nft.id, editionID: editionID, serialNumber: serialNumber)
			AthleteStudio.totalSupply = AthleteStudio.totalSupply + 1 as UInt64
			return <-nft
		}
		
		/// Set the royalty percentage and receiver for all Athlete Studio NFTs.
		///
		access(all)
		fun setRoyalty(royalty: MetadataViews.Royalty){ 
			AthleteStudio.royalty = royalty
		}
	}
	
	/// Return a public path that is scoped to this contract.
	///
	access(all)
	fun getPublicPath(suffix: String): PublicPath{ 
		return PublicPath(identifier: "AthleteStudio_".concat(suffix))!
	}
	
	/// Return a private path that is scoped to this contract.
	///
	access(all)
	fun getPrivatePath(suffix: String): PrivatePath{ 
		return PrivatePath(identifier: "AthleteStudio_".concat(suffix))!
	}
	
	/// Return a storage path that is scoped to this contract.
	///
	access(all)
	fun getStoragePath(suffix: String): StoragePath{ 
		return StoragePath(identifier: "AthleteStudio_".concat(suffix))!
	}
	
	access(self)
	fun initAdmin(admin: AuthAccount){ 
		// Create an empty collection and save it to storage
		let collection <- AthleteStudio.createEmptyCollection(nftType: Type<@AthleteStudio.Collection>())
		admin.save(<-collection, to: AthleteStudio.CollectionStoragePath)
		admin.link<&AthleteStudio.Collection>(AthleteStudio.CollectionPrivatePath, target: AthleteStudio.CollectionStoragePath)
		admin.link<&AthleteStudio.Collection>(AthleteStudio.CollectionPublicPath, target: AthleteStudio.CollectionStoragePath)
		
		// Create an admin resource and save it to storage
		let adminResource <- create Admin()
		admin.save(<-adminResource, to: self.AdminStoragePath)
	}
	
	init(){ 
		self.version = "0.0.24"
		self.CollectionPublicPath = AthleteStudio.getPublicPath(suffix: "Collection")
		self.CollectionStoragePath = AthleteStudio.getStoragePath(suffix: "Collection")
		self.CollectionPrivatePath = AthleteStudio.getPrivatePath(suffix: "Collection")
		self.AdminStoragePath = AthleteStudio.getStoragePath(suffix: "Admin")
		self.totalSupply = 0
		self.totalEditions = 0
		self.editions ={} 
		self.royalty = nil
		self.initAdmin(admin: self.account)
		emit ContractInitialized()
	}
}
