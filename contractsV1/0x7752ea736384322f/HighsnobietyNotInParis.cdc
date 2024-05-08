import TheFabricantMetadataViewsV2 from "./TheFabricantMetadataViewsV2.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import TheFabricantNFTStandardV2 from "./TheFabricantNFTStandardV2.cdc"

import RevealableV2 from "./RevealableV2.cdc"

import CoCreatableV2 from "./CoCreatableV2.cdc"

import TheFabricantAccessList from "./TheFabricantAccessList.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract HighsnobietyNotInParis: NonFungibleToken, TheFabricantNFTStandardV2, RevealableV2{ 
	
	// -----------------------------------------------------------------------
	// Paths
	// -----------------------------------------------------------------------
	access(all)
	let HighsnobietyNotInParisCollectionStoragePath: StoragePath
	
	access(all)
	let HighsnobietyNotInParisCollectionPublicPath: PublicPath
	
	access(all)
	let HighsnobietyNotInParisProviderStoragePath: PrivatePath
	
	access(all)
	let HighsnobietyNotInParisPublicMinterStoragePath: StoragePath
	
	access(all)
	let HighsnobietyNotInParisAdminStoragePath: StoragePath
	
	access(all)
	let HighsnobietyNotInParisPublicMinterPublicPath: PublicPath
	
	// -----------------------------------------------------------------------
	// Contract Events
	// -----------------------------------------------------------------------
	// Event that emitted when the NFT contract is initialized
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event ItemMintedAndTransferred(uuid: UInt64, id: UInt64, name: String, description: String, collection: String, editionNumber: UInt64, originalRecipient: Address, license: MetadataViews.License?, nftMetadataId: UInt64)
	
	access(all)
	event ItemRevealed(uuid: UInt64, id: UInt64, name: String, description: String, collection: String, editionNumber: UInt64, originalRecipient: Address, license: MetadataViews.License?, nftMetadataId: UInt64, externalURL: MetadataViews.ExternalURL, coCreatable: Bool, coCreator: Address)
	
	access(all)
	event TraitRevealed(nftUuid: UInt64, id: UInt64, trait: String)
	
	access(all)
	event IsTraitRevealableV2Updated(nftUuid: UInt64, id: UInt64, trait: String, isRevealableV2: Bool)
	
	access(all)
	event MintPaymentSplitDeposited(address: Address, price: UFix64, amount: UFix64, nftUuid: UInt64)
	
	access(all)
	event ItemDestroyed(uuid: UInt64, id: UInt64, name: String, description: String, collection: String)
	
	access(all)
	event PublicMinterCreated(uuid: UInt64, name: String, description: String, collection: String, path: String)
	
	access(all)
	event PublicMinterIsOpenAccessChanged(uuid: UInt64, name: String, description: String, collection: String, path: String, isOpenAccess: Bool, isAccessListOnly: Bool, isOpen: Bool)
	
	access(all)
	event PublicMinterIsAccessListOnly(uuid: UInt64, name: String, description: String, collection: String, path: String, isOpenAccess: Bool, isAccessListOnly: Bool, isOpen: Bool)
	
	access(all)
	event PublicMinterMintingIsOpen(uuid: UInt64, name: String, description: String, collection: String, path: String, isOpenAccess: Bool, isAccessListOnly: Bool, isOpen: Bool)
	
	access(all)
	event PublicMinterSetAccessListId(uuid: UInt64, name: String, description: String, collection: String, path: String, isOpenAccess: Bool, isAccessListOnly: Bool, isOpen: Bool, accessListId: UInt64)
	
	access(all)
	event PublicMinterSetPaymentAmount(uuid: UInt64, name: String, description: String, collection: String, path: String, isOpenAccess: Bool, isAccessListOnly: Bool, isOpen: Bool, paymentAmount: UFix64)
	
	access(all)
	event PublicMinterSetMinterMintLimit(uuid: UInt64, name: String, description: String, collection: String, path: String, isOpenAccess: Bool, isAccessListOnly: Bool, isOpen: Bool, minterMintLimit: UInt64?)
	
	access(all)
	event AdminResourceCreated(uuid: UInt64, adminAddress: Address)
	
	access(all)
	event AdminPaymentReceiverCapabilityChanged(address: Address, paymentType: Type)
	
	access(all)
	event AdminSetMaxSupply(maxSupply: UInt64)
	
	access(all)
	event AdminSetAddressMintLimit(addressMintLimit: UInt64)
	
	access(all)
	event AdminSetCollectionId(collectionId: String)
	
	access(all)
	event AdminSetBaseURI(baseURI: String)
	
	// Event that is emitted when a token is withdrawn,
	// indicating the owner of the collection that it was withdrawn from.
	//
	// If the collection is not in an account's storage, `from` will be `nil`.
	//
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Event that emitted when a token is deposited to a collection.
	//
	// It indicates the owner of the collection that it was deposited to.
	//
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// -----------------------------------------------------------------------
	// Contract State
	// -----------------------------------------------------------------------
	// NOTE: This is updated anywhere ownership of the nft is changed - on minting and therefore on deposit
	access(contract)
	var nftIdsToOwner:{ UInt64: Address}
	
	access(contract)
	var publicMinterPaths:{ UInt64: String}
	
	// NOTE: this is contract-level so all minters can access it.
	// Keeps track of the number of times an address has minted
	access(contract)
	var addressMintCount:{ Address: UInt64}
	
	// Receives payment for minting
	access(contract)
	var paymentReceiverCap: Capability<&{FungibleToken.Receiver}>?
	
	access(contract)
	var nftMetadata:{ UInt64:{ RevealableV2.RevealableMetadata}}
	
	// The total number of tokens of this type in existence
	// NOTE: All public minters use totalSupply to assign the next
	// id and edition number. Each public minter has a minterMintLimit property
	// that defines the max no. of mints a pM can do. 
	access(all)
	var totalSupply: UInt64
	
	// NOTE: The max number of NFTs in this collection that will ever be minted
	// Init as nil if there is no max. 
	access(all)
	var maxSupply: UInt64?
	
	// NOTE: Max mints per address
	access(all)
	var addressMintLimit: UInt64?
	
	//NOTE: uuid of collection added to NFT and used by BE
	access(all)
	var collectionId: String?
	
	access(contract)
	var baseTokenURI: String?
	
	// -----------------------------------------------------------------------
	// RevealableV2 Metadata Struct
	// -----------------------------------------------------------------------
	access(all)
	struct RevealableMetadata: RevealableV2.RevealableMetadata{ 
		
		//NOTE: totalSupply value of attached NFT, therefore edition number. 
		access(all)
		let id: UInt64
		
		// NOTE: !IMPORTANT! nftUuid is the uuid of the associated nft.
		// This RevealableMetadata struct should be stored in the nftMetadata dict under this
		// value. This is because the uuid is used across contracts for identification purposes
		access(all)
		let nftUuid: UInt64 // uuid of NFT
		
		
		// NOTE: Name of NFT. 
		// Will be combined with the edition number on the application
		// Doesn't include the edition number.
		access(all)
		var name: String
		
		access(all)
		var description: String //Display
		
		
		// NOTE: Thumbnail, which is needed for the Display view, should be set using one of the
		// media properties
		//pub let thumbnail: String //Display
		access(all)
		let collection: String // Name of collection eg The Fabricant > Season 3 > Wholeland > XXories Originals
		
		
		// Stores the metadata that describes this particular creation,
		// but is not part of a characteristic eg mainImage, video etc
		access(all)
		var metadata:{ String: AnyStruct}
		
		// This is where the user-chosed characteristics live. This represents
		// the data that in older contracts, would've been separate NFTs.		
		access(all)
		var characteristics:{ String:{ CoCreatableV2.Characteristic}}
		
		access(all)
		var rarity: UFix64?
		
		access(all)
		var rarityDescription: String?
		
		// NOTE: Media is not implemented in the struct because MetadataViews.Medias
		// is not mutable, so can't be updated. In addition, each 
		// NFT collection might have a different number of image/video properties.
		// Instead, the NFT should implement a function that rolls up the props
		// into a MetadataViews.Medias struct
		//pub let media: MetadataViews.Medias //Media
		access(all)
		let license: MetadataViews.License? //License
		
		
		access(all)
		let externalURL: MetadataViews.ExternalURL //ExternalURL
		
		
		access(all)
		let coCreatable: Bool
		
		access(all)
		let coCreator: Address
		
		access(all)
		var isRevealed: Bool?
		
		// id and editionNumber might not be the same in the nft...
		access(all)
		let editionNumber: UInt64 //Edition
		
		
		access(all)
		let maxEditionNumber: UInt64?
		
		access(all)
		let royalties: MetadataViews.Royalties //Royalty
		
		
		access(all)
		let royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties
		
		access(contract)
		var revealableTraits:{ String: Bool}
		
		access(all)
		fun getRevealableTraits():{ String: Bool}{ 
			return self.revealableTraits
		}
		
		//NOTE: Customise
		//NOTE: This should be updated for each campaign contract!
		// Called by the Admin to reveal the traits for this NFT.
		// Should contain a switch function that knows how to modify
		// the properties of this struct. Should check that the trait
		// being revealed is allowed to be modified.
		access(contract)
		fun revealTraits(traits: [{RevealableV2.RevealableTrait}]){ 
			var i = 0
			while i < traits.length{ 
				let RevealableTrait = traits[i]
				let traitName = RevealableTrait.name
				let traitValue = RevealableTrait.value
				switch traitName{ 
					case "mainImage":
						assert(self.checkRevealableTrait(traitName: traitName)!, message: "UnRevealableV2 trait passed in - please ensure trait can be revealed: ".concat(traitName))
						self.updateMetadata(key: traitName, value: traitValue)
					case "video":
						assert(self.checkRevealableTrait(traitName: traitName)!, message: "UnRevealableV2 trait passed in - please ensure trait can be revealed: ".concat(traitName))
						self.updateMetadata(key: traitName, value: traitValue)
					default:
						panic("UnRevealableV2 trait passed in - please ensure trait can be revealed: ".concat(traitName))
				}
				i = i + 1
			}
			self.isRevealed = true
		}
		
		access(contract)
		fun updateMetadata(key: String, value: AnyStruct){ 
			self.metadata[key] = value
		}
		
		// Called by the nft owner to modify if a trait can be 
		// revealed or not - used to revoke admin access
		access(all)
		fun updateIsTraitRevealable(key: String, value: Bool){ 
			self.revealableTraits[key] = value
		}
		
		access(all)
		fun checkRevealableTrait(traitName: String): Bool?{ 
			if let RevealableV2 = self.revealableTraits[traitName]{ 
				return RevealableV2
			}
			return nil
		}
		
		init(id: UInt64, nftUuid: UInt64, name: String, description: String, collection: String, metadata:{ String: AnyStruct}, characteristics:{ String:{ CoCreatableV2.Characteristic}}, license: MetadataViews.License?, externalURL: MetadataViews.ExternalURL, coCreatable: Bool, coCreator: Address, editionNumber: UInt64, maxEditionNumber: UInt64?, revealableTraits:{ String: Bool}, royalties: MetadataViews.Royalties, royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties){ 
			self.id = id
			self.nftUuid = nftUuid
			self.name = name
			self.description = description
			self.collection = collection
			self.metadata = metadata
			self.characteristics = characteristics
			self.rarity = nil
			self.rarityDescription = nil
			self.license = license
			self.externalURL = externalURL
			self.coCreatable = coCreatable
			self.coCreator = coCreator
			//NOTE: Customise
			// This should be nil if the nft can't be revealed!
			self.isRevealed = true
			self.editionNumber = editionNumber
			self.maxEditionNumber = maxEditionNumber
			self.revealableTraits = revealableTraits
			self.royalties = royalties
			self.royaltiesTFMarketplace = royaltiesTFMarketplace
		}
	}
	
	// -----------------------------------------------------------------------
	// Trait Struct
	// -----------------------------------------------------------------------
	// Used by txs to target traits/characteristics to be revealed
	access(all)
	struct Trait: RevealableV2.RevealableTrait{ 
		access(all)
		let name: String
		
		access(all)
		let value: AnyStruct
		
		init(name: String, value: AnyStruct){ 
			self.name = name
			self.value = value
		}
	}
	
	// -----------------------------------------------------------------------
	// NFT Resource
	// -----------------------------------------------------------------------
	// Restricted scope for borrowHighsnobietyNotInParis() in Collection.
	// Ensures that the returned NFT ref is read only.
	access(all)
	resource interface PublicNFT{ 
		access(all)
		fun getFullName(): String
		
		access(all)
		fun getEditions(): MetadataViews.Editions
		
		access(all)
		fun getMedias(): MetadataViews.Medias
		
		access(all)
		fun getTraits(): MetadataViews.Traits?
		
		access(all)
		view fun getRarity(): MetadataViews.Rarity?
		
		access(all)
		fun getExternalRoyalties(): MetadataViews.Royalties
		
		access(all)
		fun getTFRoyalties(): TheFabricantMetadataViewsV2.Royalties
		
		access(all)
		fun getMetadata():{ String: AnyStruct}
		
		access(all)
		fun getCharacteristics():{ String:{ CoCreatableV2.Characteristic}}?
		
		access(all)
		fun getDisplay(): MetadataViews.Display
		
		access(all)
		fun getCollectionData(): MetadataViews.NFTCollectionData
		
		access(all)
		fun getCollectionDisplay(): MetadataViews.NFTCollectionDisplay
		
		access(all)
		fun getNFTView(): MetadataViews.NFTView
		
		access(all)
		fun getViews(): [Type]
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?
	}
	
	access(all)
	resource NFT: TheFabricantNFTStandardV2.TFNFT, NonFungibleToken.NFT, ViewResolver.Resolver, PublicNFT{ 
		access(all)
		let id: UInt64
		
		// NOTE: Ensure that the name for the nft is correct. This 
		// will be shown to users. It should not include the edition number.
		access(contract)
		let collectionId: String
		
		access(contract)
		let editionNumber: UInt64 //Edition
		
		
		access(contract)
		let maxEditionNumber: UInt64?
		
		access(contract)
		let originalRecipient: Address
		
		access(contract)
		let license: MetadataViews.License?
		
		access(contract)
		let nftMetadataId: UInt64
		
		access(all)
		fun getFullName(): String{ 
			return ((HighsnobietyNotInParis.nftMetadata[self.nftMetadataId]!).name!).concat(" #".concat(self.editionNumber.toString()))
		}
		
		// NOTE: This is important for Edition view
		access(all)
		fun getEditionName(): String{ 
			return (HighsnobietyNotInParis.nftMetadata[self.nftMetadataId]!).collection
		}
		
		access(all)
		fun getEditions(): MetadataViews.Editions{ 
			// NOTE: In this case, id == edition number
			let edition = MetadataViews.Edition(name: (HighsnobietyNotInParis.nftMetadata[self.nftMetadataId]!).collection, number: self.editionNumber, max: HighsnobietyNotInParis.maxSupply)
			return MetadataViews.Editions([edition])
		}
		
		//NOTE: Customise
		//NOTE: This will be different for each campaign, determined by how
		// many media files there are and their keys in metadata! Pay attention
		// to where the media files are stored and therefore accessed
		access(all)
		fun getMedias(): MetadataViews.Medias{ 
			let nftMetadata = HighsnobietyNotInParis.nftMetadata[self.id]!
			let mainImage = nftMetadata.metadata["mainImage"]! as! String
			// NOTE: This assumes that when the shoeShape characteristic is created
			// in the update_shoe_shapes_char tx, the value property is created as a dictionary
			let video = nftMetadata.metadata["video"]! as! String
			let mainImageMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: mainImage), mediaType: "image/png")
			let videoMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: video), mediaType: "video/mp4")
			return MetadataViews.Medias([mainImageMedia, videoMedia])
		}
		
		// NOTE: Customise
		access(all)
		fun getImages():{ String: String}{ 
			let nftMetadata = HighsnobietyNotInParis.nftMetadata[self.id]!
			let mainImage = nftMetadata.metadata["mainImage"]! as! String
			return{ "mainImage": mainImage}
		}
		
		// NOTE: Customise
		access(all)
		fun getVideos():{ String: String}{ 
			let nftMetadata = HighsnobietyNotInParis.nftMetadata[self.id]!
			let mainVideo = nftMetadata.metadata["video"]! as! String
			return{ "mainVideo": mainVideo}
		}
		
		// NOTE: Customise
		// What are the traits that you want external marketplaces
		// to display?
		access(all)
		fun getTraits(): MetadataViews.Traits?{ 
			return nil
		}
		
		access(all)
		view fun getRarity(): MetadataViews.Rarity?{ 
			return nil
		}
		
		access(all)
		fun getExternalRoyalties(): MetadataViews.Royalties{ 
			let nftMetadata = HighsnobietyNotInParis.nftMetadata[self.id]!
			return nftMetadata.royalties
		}
		
		access(all)
		fun getTFRoyalties(): TheFabricantMetadataViewsV2.Royalties{ 
			let nftMetadata = HighsnobietyNotInParis.nftMetadata[self.id]!
			return nftMetadata.royaltiesTFMarketplace
		}
		
		access(all)
		fun getMetadata():{ String: AnyStruct}{ 
			return (HighsnobietyNotInParis.nftMetadata[self.id]!).metadata
		}
		
		//NOTE: This is not a CoCreatableV2 NFT, so no characteristics are present
		access(all)
		fun getCharacteristics():{ String:{ CoCreatableV2.Characteristic}}?{ 
			return nil
		}
		
		access(all)
		fun getRevealableTraits():{ String: Bool}?{ 
			return (HighsnobietyNotInParis.nftMetadata[self.id]!).getRevealableTraits()
		}
		
		//NOTE: The first file in medias will be the thumbnail.
		// Maybe put a file type check in here to ensure it is 
		// an image?
		access(all)
		fun getDisplay(): MetadataViews.Display{ 
			return MetadataViews.Display(name: self.getFullName(), description: (HighsnobietyNotInParis.nftMetadata[self.nftMetadataId]!).description, thumbnail: self.getMedias().items[0].file)
		}
		
		access(all)
		fun getCollectionData(): MetadataViews.NFTCollectionData{ 
			return MetadataViews.NFTCollectionData(storagePath: HighsnobietyNotInParis.HighsnobietyNotInParisCollectionStoragePath, publicPath: HighsnobietyNotInParis.HighsnobietyNotInParisCollectionPublicPath, publicCollection: Type<&HighsnobietyNotInParis.Collection>(), publicLinkedType: Type<&HighsnobietyNotInParis.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
					return <-HighsnobietyNotInParis.createEmptyCollection(nftType: Type<@HighsnobietyNotInParis.Collection>())
				})
		}
		
		//NOTE: Customise
		// NOTE: Update this function with the collection display image
		// and TF socials
		access(all)
		fun getCollectionDisplay(): MetadataViews.NFTCollectionDisplay{ 
			let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://highsnobiety-collection-display.s3.eu-central-1.amazonaws.com/images/HS_squareImage.png"), mediaType: "image/png")
			let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://highsnobiety-collection-display.s3.eu-central-1.amazonaws.com/images/HS_bannerImage.png"), mediaType: "image/png")
			return MetadataViews.NFTCollectionDisplay(name: self.getEditionName(), description: "Not in Paris is the most extensive and impactful flagship event in Highsnobiety\u{2019}s calendar and is a celebration of all things fashion, culture and tech. For the Not in Paris 2023 edition, The Fabricant has created a series of digital fashion collectibles in collaboration with Highsnobiety.", externalURL: (HighsnobietyNotInParis.nftMetadata[self.id]!).externalURL, squareImage: squareImage, bannerImage: bannerImage, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/thefabricant"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/the_fab_ric_ant/"), "facebook": MetadataViews.ExternalURL("https://www.facebook.com/thefabricantdesign/"), "artstation": MetadataViews.ExternalURL("https://www.artstation.com/thefabricant"), "behance": MetadataViews.ExternalURL("https://www.behance.net/thefabricant"), "linkedin": MetadataViews.ExternalURL("https://www.linkedin.com/company/the-fabricant"), "sketchfab": MetadataViews.ExternalURL("https://sketchfab.com/thefabricant"), "clolab": MetadataViews.ExternalURL("https://www.clo3d.com/en/clollab/thefabricant"), "tiktok": MetadataViews.ExternalURL("@digital_fashion"), "discord": MetadataViews.ExternalURL("https://discord.com/channels/692039738751713280/778601303013195836")})
		}
		
		access(all)
		fun getNFTView(): MetadataViews.NFTView{ 
			return MetadataViews.NFTView(id: self.id, uuid: self.uuid, display: self.getDisplay(), externalURL: (HighsnobietyNotInParis.nftMetadata[self.id]!).externalURL, collectionData: self.getCollectionData(), collectionDisplay: self.getCollectionDisplay(), royalties: (HighsnobietyNotInParis.nftMetadata[self.id]!).royalties, traits: self.getTraits())
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			let viewArray: [Type] = [Type<TheFabricantMetadataViewsV2.TFNFTIdentifierV1>(), Type<TheFabricantMetadataViewsV2.TFNFTSimpleView>(), Type<MetadataViews.NFTView>(), Type<MetadataViews.Display>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Medias>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Traits>()]
			if self.license != nil{ 
				viewArray.append(Type<MetadataViews.License>())
			}
			if self.getRarity() != nil{ 
				viewArray.append(Type<MetadataViews.Rarity>())
			}
			return viewArray
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<TheFabricantMetadataViewsV2.TFNFTIdentifierV1>():
					return TheFabricantMetadataViewsV2.TFNFTIdentifierV1(uuid: self.uuid, id: self.id, name: self.getFullName(), collection: (HighsnobietyNotInParis.nftMetadata[self.nftMetadataId]!).collection, editions: self.getEditions(), address: (self.owner!).address, originalRecipient: self.originalRecipient)
				case Type<TheFabricantMetadataViewsV2.TFNFTSimpleView>():
					return TheFabricantMetadataViewsV2.TFNFTSimpleView(uuid: self.uuid, id: self.id, name: self.getFullName(), description: (HighsnobietyNotInParis.nftMetadata[self.nftMetadataId]!).description, collection: (HighsnobietyNotInParis.nftMetadata[self.nftMetadataId]!).collection, collectionId: HighsnobietyNotInParis.collectionId!, metadata: self.getMetadata(), media: self.getMedias(), images: self.getImages(), videos: self.getVideos(), externalURL: (HighsnobietyNotInParis.nftMetadata[self.id]!).externalURL, rarity: self.getRarity(), traits: self.getTraits(), characteristics: self.getCharacteristics(), coCreatable: (HighsnobietyNotInParis.nftMetadata[self.id]!).coCreatable, coCreator: (HighsnobietyNotInParis.nftMetadata[self.id]!).coCreator, isRevealed: (HighsnobietyNotInParis.nftMetadata[self.id]!).isRevealed, editions: self.getEditions(), originalRecipient: self.originalRecipient, royalties: (HighsnobietyNotInParis.nftMetadata[self.id]!).royalties, royaltiesTFMarketplace: (HighsnobietyNotInParis.nftMetadata[self.id]!).royaltiesTFMarketplace, revealableTraits: self.getRevealableTraits(), address: (self.owner!).address)
				case Type<MetadataViews.NFTView>():
					return self.getNFTView()
				case Type<MetadataViews.Display>():
					return self.getDisplay()
				case Type<MetadataViews.Editions>():
					return self.getEditions()
				case Type<MetadataViews.Serial>():
					return self.id
				case Type<MetadataViews.Royalties>():
					return HighsnobietyNotInParis.nftMetadata[self.id]?.royalties
				case Type<MetadataViews.Medias>():
					return self.getMedias()
				case Type<MetadataViews.License>():
					return self.license
				case Type<MetadataViews.ExternalURL>():
					return HighsnobietyNotInParis.nftMetadata[self.id]?.externalURL
				case Type<MetadataViews.NFTCollectionData>():
					return self.getCollectionData()
				case Type<MetadataViews.NFTCollectionDisplay>():
					return self.getCollectionDisplay()
				case Type<MetadataViews.Rarity>():
					return self.getRarity()
				case Type<MetadataViews.Traits>():
					return self.getTraits()
			}
			return nil
		}
		
		access(all)
		fun updateIsTraitRevealable(key: String, value: Bool){ 
			let nftMetadata = HighsnobietyNotInParis.nftMetadata[self.id]!
			nftMetadata.updateIsTraitRevealable(key: key, value: value)
			HighsnobietyNotInParis.nftMetadata[self.id] = nftMetadata
			emit IsTraitRevealableV2Updated(nftUuid: nftMetadata.nftUuid, id: nftMetadata.id, trait: key, isRevealableV2: value)
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(originalRecipient: Address, license: MetadataViews.License?){ 
			assert(HighsnobietyNotInParis.collectionId != nil, message: "Ensure that Admin has set collectionId in the contract")
			HighsnobietyNotInParis.totalSupply = HighsnobietyNotInParis.totalSupply + 1
			self.id = HighsnobietyNotInParis.totalSupply
			self.collectionId = HighsnobietyNotInParis.collectionId!
			
			// NOTE: Customise
			// The edition number may need to be different to id
			// for some campaigns
			self.editionNumber = self.id
			self.maxEditionNumber = HighsnobietyNotInParis.maxSupply
			self.originalRecipient = originalRecipient
			self.license = license
			self.nftMetadataId = self.id
		}
	}
	
	// -----------------------------------------------------------------------
	// Collection Resource
	// -----------------------------------------------------------------------
	access(all)
	resource interface HighsnobietyNotInParisCollectionPublic{ 
		access(all)
		fun borrowHighsnobietyNotInParis(id: UInt64): &HighsnobietyNotInParis.NFT?
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, HighsnobietyNotInParisCollectionPublic, ViewResolver.ResolverCollection{ 
		
		// Dictionary to hold the NFTs in the Collection
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let HighsnobietyNotInParis = nft as! &HighsnobietyNotInParis.NFT
			return HighsnobietyNotInParis as &{ViewResolver.Resolver}
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: NFT does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			
			// Return the withdrawn token
			return <-token
		}
		
		// deposit takes an NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			// By ensuring self.owner.address is not nil we keep the nftIdsToOwner dict 
			// up to date.
			pre{ 
				self.owner?.address != nil:
					"The Collection resource must be stored in a users account"
			}
			
			// Cast the deposited token as  NFT to make sure
			// it is the correct type
			let token <- token as! @NFT
			
			// Get the token's ID
			let id = token.id
			
			// Add the new token to the dictionary
			let oldToken <- self.ownedNFTs[id] <- token
			HighsnobietyNotInParis.nftIdsToOwner[id] = (self.owner!).address
			emit Deposit(id: id, to: self.owner?.address)
			
			// Destroy the empty old token that was "removed"
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// Returns a borrowed reference to an NFT in the collection
		// so that the caller can read data and call methods from it
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowHighsnobietyNotInParis(id: UInt64): &HighsnobietyNotInParis.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &HighsnobietyNotInParis.NFT
			}
			return nil
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
		
		// If a transaction destroys the Collection object,
		// All the NFTs contained within are also destroyed!
		//
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// -----------------------------------------------------------------------
	// Admin Resource
	// -----------------------------------------------------------------------
	access(all)
	resource Admin{ 
		access(all)
		fun setPublicReceiverCap(paymentReceiverCap: Capability<&{FungibleToken.Receiver}>){ 
			HighsnobietyNotInParis.paymentReceiverCap = paymentReceiverCap
			emit AdminPaymentReceiverCapabilityChanged(address: paymentReceiverCap.address, paymentType: paymentReceiverCap.getType())
		}
		
		access(all)
		fun setBaseURI(baseURI: String){ 
			HighsnobietyNotInParis.baseTokenURI = baseURI
			emit AdminSetBaseURI(baseURI: baseURI)
		}
		
		// The max supply determines the maximum number of NFTs that can be minted from this contract
		access(all)
		fun setMaxSupply(maxSupply: UInt64){ 
			HighsnobietyNotInParis.maxSupply = maxSupply
			emit AdminSetMaxSupply(maxSupply: maxSupply)
		}
		
		access(all)
		fun setAddressMintLimit(addressMintLimit: UInt64){ 
			HighsnobietyNotInParis.addressMintLimit = addressMintLimit
			emit AdminSetAddressMintLimit(addressMintLimit: addressMintLimit)
		}
		
		access(all)
		fun setCollectionId(collectionId: String){ 
			HighsnobietyNotInParis.collectionId = collectionId
			emit AdminSetCollectionId(collectionId: collectionId)
		}
		
		//NOTE: Customise
		// mint not:
		// maxSupply has been hit √
		// minting isn't open (!isOpen) √
		// mint if:
		// openAccess √
		// OR address on access list √
		// Output:
		// NFT √
		// nftMetadata √
		// update mints per address √
		//NOTE: !Used for CC payments via MoonPay!
		access(all)
		fun distributeDirectlyViaAccessList(receiver: &{NonFungibleToken.CollectionPublic}, publicMinterPathString: String, variantId: UInt64){ 
			
			// Ensure that the maximum supply of nfts for this contract has not been hit
			if HighsnobietyNotInParis.maxSupply != nil{ 
				assert(HighsnobietyNotInParis.totalSupply + 1 <= HighsnobietyNotInParis.maxSupply!, message: "Max supply for NFTs has been hit")
			}
			
			// Get the publicMinter details so we can apply all the correct props to the NFT
			//NOTE: Therefore relies on a pM having been created
			let publicPath = PublicPath(identifier: publicMinterPathString) ?? panic("Failed to construct public path from path string: ".concat(publicMinterPathString))
			let publicMinterCap = getAccount((self.owner!).address).capabilities.get<&HighsnobietyNotInParis.PublicMinter>(publicPath).borrow<&HighsnobietyNotInParis.PublicMinter>() ?? panic("Couldn't get publicMinter ref or pathString is wrong: ".concat(publicMinterPathString))
			let publicMinterDetails = publicMinterCap.getPublicMinterDetails()
			
			//Confirm that minting is open on the publicMinter
			let isOpen = publicMinterDetails["isOpen"] as! Bool?
			assert(isOpen!, message: "Minting is not open!")
			
			//Check that the address has access via the access list. If isOpenAccess, then anyone can mint.
			let isOpenAccess = publicMinterDetails["isOpenAccess"] as! Bool?
			let accessListId = publicMinterDetails["accessListId"] as! UInt64?
			if !isOpenAccess!{ 
				assert(TheFabricantAccessList.checkAccessForAddress(accessListDetailsId: accessListId!, address: (receiver.owner!).address), message: "User address is not on the access list and so cannot mint.")
			}
			
			// Create the NFT
			let license = publicMinterDetails["license"] as! MetadataViews.License?
			let nft <- create NFT(originalRecipient: (receiver.owner!).address, license: license)
			let name = publicMinterDetails["name"] as! String?
			let description = publicMinterDetails["description"] as! String?
			let collection = publicMinterDetails["collection"] as! String?
			let externalURL = publicMinterDetails["externalURL"] as! MetadataViews.ExternalURL?
			let coCreatable = publicMinterDetails["coCreatable"] as! Bool?
			let revealableTraits = publicMinterDetails["revealableTraits"] as!{ String: Bool}?
			let royalties = publicMinterDetails["royalties"] as! MetadataViews.Royalties?
			let royaltiesTFMarketplace = publicMinterDetails["royaltiesTFMarketplace"] as! TheFabricantMetadataViewsV2.Royalties?
			
			//Create the nftMetadata
			HighsnobietyNotInParis.createNftMetadata(id: nft.id, nftUuid: nft.uuid, variantId: variantId, name: name!, description: description!, collection: collection!, characteristics:{} , license: nft.license, externalURL: externalURL!, coCreatable: coCreatable!, coCreator: (receiver.owner!).address, editionNumber: nft.editionNumber, maxEditionNumber: nft.maxEditionNumber, revealableTraits: revealableTraits!, royalties: royalties!, royaltiesTFMarketplace: royaltiesTFMarketplace!)
			
			//NOTE: Event is emitted here and not in nft init because
			// data is split between RevealableMetadata and nft,
			// so not all event data is accessible during nft init
			emit ItemMintedAndTransferred(uuid: nft.uuid, id: nft.id, name: (HighsnobietyNotInParis.nftMetadata[nft.nftMetadataId]!).name, description: (HighsnobietyNotInParis.nftMetadata[nft.nftMetadataId]!).description, collection: (HighsnobietyNotInParis.nftMetadata[nft.nftMetadataId]!).collection, editionNumber: nft.editionNumber, originalRecipient: nft.originalRecipient, license: nft.license, nftMetadataId: nft.nftMetadataId)
			receiver.deposit(token: <-nft)
			
			// Increment the number of mints that an address has
			if HighsnobietyNotInParis.addressMintCount[(receiver.owner!).address] != nil{ 
				HighsnobietyNotInParis.addressMintCount[(receiver.owner!).address] = HighsnobietyNotInParis.addressMintCount[(receiver.owner!).address]! + 1
			} else{ 
				HighsnobietyNotInParis.addressMintCount[(receiver.owner!).address] = 1
			}
		}
		
		// NOTE: It is in the public minter that you would create the restrictions
		// for minting. 
		access(all)
		fun createPublicMinter(name: String, description: String, collection: String, license: MetadataViews.License?, externalURL: MetadataViews.ExternalURL, coCreatable: Bool, revealableTraits:{ String: Bool}, minterMintLimit: UInt64?, royalties: MetadataViews.Royalties, royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties, paymentAmount: UFix64, paymentType: Type, paymentSplit: MetadataViews.Royalties?, typeRestrictions: [Type], accessListId: UInt64){ 
			pre{ 
				HighsnobietyNotInParis.paymentReceiverCap != nil:
					"Please set the paymentReceiverCap before creating a minter"
			}
			let publicMinter: @HighsnobietyNotInParis.PublicMinter <- create PublicMinter(name: name, description: description, collection: collection, license: license, externalURL: externalURL, coCreatable: coCreatable, revealableTraits: revealableTraits, minterMintLimit: minterMintLimit, royalties: royalties, royaltiesTFMarketplace: royaltiesTFMarketplace, paymentAmount: paymentAmount, paymentType: paymentType, paymentSplit: paymentSplit, typeRestrictions: typeRestrictions, accessListId: accessListId)
			
			// Save path: name_collection_uuid
			// Link the Public Minter to a Public Path of the admin account
			let publicMinterStoragePath = StoragePath(identifier: publicMinter.path)
			let publicMinterPublicPath = PublicPath(identifier: publicMinter.path)
			HighsnobietyNotInParis.account.storage.save(<-publicMinter, to: publicMinterStoragePath!)
			HighsnobietyNotInParis.account.link<&PublicMinter>(publicMinterPublicPath!, target: publicMinterStoragePath!)
		}
		
		access(all)
		fun revealTraits(nftMetadataId: UInt64, traits: [{RevealableV2.RevealableTrait}]){ 
			let nftMetadata = HighsnobietyNotInParis.nftMetadata[nftMetadataId]! as! HighsnobietyNotInParis.RevealableMetadata
			nftMetadata.revealTraits(traits: traits)
			HighsnobietyNotInParis.nftMetadata[nftMetadataId] = nftMetadata
			
			// Event should be emitted in resource, not struct
			var i = 1
			while i < traits.length{ 
				let traitName = traits[i].name
				let traitValue = traits[i].value
				emit TraitRevealed(nftUuid: nftMetadata.nftUuid, id: nftMetadata.id, trait: traitName)
				i = i + 1
			}
			emit ItemRevealed(uuid: nftMetadata.nftUuid, id: nftMetadata.id, name: nftMetadata.name, description: nftMetadata.description, collection: nftMetadata.collection, editionNumber: nftMetadata.editionNumber, originalRecipient: nftMetadata.coCreator, license: nftMetadata.license, nftMetadataId: nftMetadata.id, externalURL: nftMetadata.externalURL, coCreatable: nftMetadata.coCreatable, coCreator: nftMetadata.coCreator)
		}
		
		init(adminAddress: Address){ 
			emit AdminResourceCreated(uuid: self.uuid, adminAddress: adminAddress)
		}
	}
	
	// -----------------------------------------------------------------------
	// PublicMinter Resource
	// -----------------------------------------------------------------------
	// NOTE: The public minter is exposed via a capability to allow the public
	// to mint the NFT so long as they meet the criteria.
	// It is in the public minter that the various mint functions would be exposed
	// such as paid mint etc.
	// Every contract has to manage its own minting via the PublicMinter.
	//NOTE: Customise
	// Update the mint functions
	access(all)
	resource interface Minter{ 
		access(all)
		fun mintUsingAccessList(receiver: &{NonFungibleToken.CollectionPublic}, payment: @{FungibleToken.Vault}, variantId: UInt64)
		
		access(all)
		fun getPublicMinterDetails():{ String: AnyStruct}
	}
	
	access(all)
	resource PublicMinter: TheFabricantNFTStandardV2.TFNFTPublicMinter, Minter{ 
		access(all)
		var path: String
		
		access(all)
		var isOpen: Bool
		
		access(all)
		var isAccessListOnly: Bool
		
		access(all)
		var isOpenAccess: Bool
		
		// NOTE: Remove these as required and update the NFT props and 
		// resolveView to reflect this, so that views that this nft
		// does not display are not provided
		// Name of nft, not campaign. This will be combined with the edition number
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let collection: String
		
		access(all)
		let license: MetadataViews.License?
		
		access(all)
		let externalURL: MetadataViews.ExternalURL
		
		access(all)
		let coCreatable: Bool
		
		access(all)
		let revealableTraits:{ String: Bool}
		
		// NOTE: The max number of mints this pM can do (eg multiple NFTs, a different minter for each one. Each NFT has a max number of mints allowed).
		access(all)
		var minterMintLimit: UInt64?
		
		access(all)
		var numberOfMints: UInt64
		
		access(all)
		let royalties: MetadataViews.Royalties
		
		access(all)
		let royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties
		
		access(all)
		var paymentAmount: UFix64
		
		access(all)
		let paymentType: Type
		
		// paymentSplit: How much each address gets paid on minting of NFT
		access(all)
		let paymentSplit: MetadataViews.Royalties?
		
		access(all)
		var typeRestrictions: [Type]?
		
		access(all)
		var accessListId: UInt64
		
		access(all)
		fun changeIsOpenAccess(isOpenAccess: Bool){ 
			self.isOpenAccess = isOpenAccess
			emit PublicMinterIsOpenAccessChanged(uuid: self.uuid, name: self.name, description: self.description, collection: self.collection, path: self.path, isOpenAccess: self.isOpenAccess, isAccessListOnly: self.isAccessListOnly, isOpen: self.isOpen)
		}
		
		access(all)
		fun changeIsAccessListOnly(isAccessListOnly: Bool){ 
			self.isAccessListOnly = isAccessListOnly
			emit PublicMinterIsAccessListOnly(uuid: self.uuid, name: self.name, description: self.description, collection: self.collection, path: self.path, isOpenAccess: self.isOpenAccess, isAccessListOnly: self.isAccessListOnly, isOpen: self.isOpen)
		}
		
		access(all)
		fun changeMintingIsOpen(isOpen: Bool){ 
			self.isOpen = isOpen
			emit PublicMinterMintingIsOpen(uuid: self.uuid, name: self.name, description: self.description, collection: self.collection, path: self.path, isOpenAccess: self.isOpenAccess, isAccessListOnly: self.isAccessListOnly, isOpen: self.isOpen)
		}
		
		access(all)
		fun setAccessListId(accessListId: UInt64){ 
			self.accessListId = accessListId
			emit PublicMinterSetAccessListId(uuid: self.uuid, name: self.name, description: self.description, collection: self.collection, path: self.path, isOpenAccess: self.isOpenAccess, isAccessListOnly: self.isAccessListOnly, isOpen: self.isOpen, accessListId: self.accessListId)
		}
		
		access(all)
		fun setPaymentAmount(amount: UFix64){ 
			self.paymentAmount = amount
			emit PublicMinterSetPaymentAmount(uuid: self.uuid, name: self.name, description: self.description, collection: self.collection, path: self.path, isOpenAccess: self.isOpenAccess, isAccessListOnly: self.isAccessListOnly, isOpen: self.isOpen, paymentAmount: self.paymentAmount)
		}
		
		access(all)
		fun setMinterMintLimit(minterMintLimit: UInt64){ 
			self.minterMintLimit = minterMintLimit
			emit PublicMinterSetMinterMintLimit(uuid: self.uuid, name: self.name, description: self.description, collection: self.collection, path: self.path, isOpenAccess: self.isOpenAccess, isAccessListOnly: self.isAccessListOnly, isOpen: self.isOpen, minterMintLimit: self.minterMintLimit)
		}
		
		// The owner of the pM can access this via borrow in tx.
		access(all)
		fun updateTypeRestrictions(types: [Type]){ 
			self.typeRestrictions = types
		}
		
		//NOTE: Customise
		// mint not:
		// maxMint for this address has been hit
		// maxSupply has been hit √
		// minting isn't open (!isOpen) √
		// payment is insufficient √
		// minterMintLimit is hit √
		// mint if:
		// openAccess √
		// OR address on access list √
		// Output:
		// NFT √
		// nftMetadata √
		// update mints per address √
		access(all)
		fun mintUsingAccessList(receiver: &{NonFungibleToken.CollectionPublic}, payment: @{FungibleToken.Vault}, variantId: UInt64){ 
			pre{ 
				self.isOpen:
					"Minting is not currently open!"
				payment.isInstance(self.paymentType):
					"payment vault is not requested fungible token"
				payment.balance == self.paymentAmount:
					"Incorrect payment amount provided for minting"
				HighsnobietyNotInParis.paymentReceiverCap != nil:
					"Payment Receiver Cap must be set for minting!"
			}
			post{ 
				receiver.getIDs().length == before(receiver.getIDs().length) + 1:
					"Minted NFT must be deposited into Collection"
			}
			
			// Total number of mints by this pM
			self.numberOfMints = self.numberOfMints + 1
			
			// Ensure that minterMintLimit for this pM has not been hit
			if self.minterMintLimit != nil{ 
				assert(self.numberOfMints <= self.minterMintLimit!, message: "Maximum number of mints for this public minter has been hit")
			}
			
			// Ensure that the maximum supply of nfts for this contract has not been hit
			if HighsnobietyNotInParis.maxSupply != nil{ 
				assert(HighsnobietyNotInParis.totalSupply + 1 <= HighsnobietyNotInParis.maxSupply!, message: "Max supply for NFTs has been hit")
			}
			
			// Ensure user hasn't minted more NFTs from this contract than allowed
			if HighsnobietyNotInParis.addressMintLimit != nil{ 
				if HighsnobietyNotInParis.addressMintCount[(receiver.owner!).address] != nil{ 
					assert(HighsnobietyNotInParis.addressMintCount[(receiver.owner!).address]! < HighsnobietyNotInParis.addressMintLimit!, message: "User has already minted the maximum allowance per address!")
				}
			}
			
			// Check that the address has access via the access list. If isOpenAccess, then anyone can mint.
			if !self.isOpenAccess{ 
				assert(TheFabricantAccessList.checkAccessForAddress(accessListDetailsId: self.accessListId, address: (receiver.owner!).address), message: "User address is not on the access list and so cannot mint.")
			}
			
			// Settle Payment
			if let _paymentSplit = self.paymentSplit{ 
				var i = 0
				let splits = _paymentSplit.getRoyalties()
				while i < splits.length{ 
					let split = splits[i]
					let receiver = split.receiver
					let cut = split.cut
					let paymentAmount = self.paymentAmount * cut
					if let wallet = receiver.borrow(){ 
						let pay <- payment.withdraw(amount: paymentAmount)
						emit MintPaymentSplitDeposited(address: (wallet.owner!).address, price: self.paymentAmount, amount: pay.balance, nftUuid: self.uuid)
						wallet.deposit(from: <-pay)
					}
					i = i + 1
				}
			}
			if payment.balance != 0.0 || payment.balance == 0.0{ 
				// pay rest to TF
				emit MintPaymentSplitDeposited(address: (HighsnobietyNotInParis.paymentReceiverCap!).address, price: self.paymentAmount, amount: payment.balance, nftUuid: self.uuid)
			}
			((			  // Deposit has to occur outside of above if statement as resource must be moved or destroyed
			  HighsnobietyNotInParis.paymentReceiverCap!).borrow()!).deposit(from: <-payment)
			let nft <- create NFT(originalRecipient: (receiver.owner!).address, license: self.license)
			HighsnobietyNotInParis.createNftMetadata(id: nft.id, nftUuid: nft.uuid, variantId: variantId, name: self.name, description: self.description, collection: self.collection, characteristics:{} , license: nft.license, externalURL: self.externalURL, coCreatable: self.coCreatable, coCreator: (receiver.owner!).address, editionNumber: nft.editionNumber, maxEditionNumber: nft.maxEditionNumber, revealableTraits: self.revealableTraits, royalties: self.royalties, royaltiesTFMarketplace: self.royaltiesTFMarketplace)
			
			//NOTE: Event is emitted here and not in nft init because
			// data is split between RevealableMetadata and nft,
			// so not all event data is accessible during nft init
			emit ItemMintedAndTransferred(uuid: nft.uuid, id: nft.id, name: (HighsnobietyNotInParis.nftMetadata[nft.nftMetadataId]!).name, description: (HighsnobietyNotInParis.nftMetadata[nft.nftMetadataId]!).description, collection: (HighsnobietyNotInParis.nftMetadata[nft.nftMetadataId]!).collection, editionNumber: nft.editionNumber, originalRecipient: nft.originalRecipient, license: self.license, nftMetadataId: nft.nftMetadataId)
			receiver.deposit(token: <-nft)
			
			// Increment the number of mints that an address has
			if HighsnobietyNotInParis.addressMintCount[(receiver.owner!).address] != nil{ 
				HighsnobietyNotInParis.addressMintCount[(receiver.owner!).address] = HighsnobietyNotInParis.addressMintCount[(receiver.owner!).address]! + 1
			} else{ 
				HighsnobietyNotInParis.addressMintCount[(receiver.owner!).address] = 1
			}
		}
		
		access(all)
		fun getPublicMinterDetails():{ String: AnyStruct}{ 
			let ret:{ String: AnyStruct} ={} 
			ret["name"] = self.name
			ret["uuid"] = self.uuid
			ret["path"] = self.path
			ret["isOpen"] = self.isOpen
			ret["isAccessListOnly"] = self.isAccessListOnly
			ret["isOpenAccess"] = self.isOpenAccess
			ret["description"] = self.description
			ret["collection"] = self.collection
			ret["collectionId"] = HighsnobietyNotInParis.collectionId
			ret["license"] = self.license
			ret["externalURL"] = self.externalURL
			ret["coCreatable"] = self.coCreatable
			ret["revealableTraits"] = self.revealableTraits
			ret["minterMintLimit"] = self.minterMintLimit
			ret["numberOfMints"] = self.numberOfMints
			ret["royalties"] = self.royalties
			ret["royaltiesTFMarketplace"] = self.royaltiesTFMarketplace
			ret["paymentAmount"] = self.paymentAmount
			ret["paymentType"] = self.paymentType
			ret["paymentSplit"] = self.paymentSplit
			ret["typeRestrictions"] = self.typeRestrictions
			ret["accessListId"] = self.accessListId
			return ret
		}
		
		init(name: String, description: String, collection: String, license: MetadataViews.License?, externalURL: MetadataViews.ExternalURL, coCreatable: Bool, revealableTraits:{ String: Bool}, minterMintLimit: UInt64?, royalties: MetadataViews.Royalties, royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties, paymentAmount: UFix64, paymentType: Type, paymentSplit: MetadataViews.Royalties?, typeRestrictions: [Type], accessListId: UInt64){ 
			
			// Create and save path: name_collection_uuid
			let pathString = "TheFabricantNFTPublicMinter_HighsnobietyNotInParis_".concat(self.uuid.toString())
			HighsnobietyNotInParis.publicMinterPaths[self.uuid] = pathString
			self.path = pathString
			self.isOpen = false
			self.isAccessListOnly = true
			self.isOpenAccess = false
			self.name = name
			self.description = description
			self.collection = collection
			self.license = license
			self.externalURL = externalURL
			self.coCreatable = coCreatable
			self.revealableTraits = revealableTraits
			self.minterMintLimit = minterMintLimit
			self.numberOfMints = 0
			self.royalties = royalties
			self.royaltiesTFMarketplace = royaltiesTFMarketplace
			self.paymentAmount = paymentAmount
			self.paymentType = paymentType
			self.paymentSplit = paymentSplit
			self.typeRestrictions = typeRestrictions
			self.accessListId = accessListId
			emit PublicMinterCreated(uuid: self.uuid, name: name, description: description, collection: collection, path: self.path)
		}
	}
	
	// -----------------------------------------------------------------------
	// Private Utility Functions
	// -----------------------------------------------------------------------
	//NOTE: Customise
	// This function generates the metadata for the minted nft.
	access(contract)
	fun createNftMetadata(id: UInt64, nftUuid: UInt64, variantId: UInt64, name: String, description: String, collection: String, characteristics:{ String:{ CoCreatableV2.Characteristic}}, license: MetadataViews.License?, externalURL: MetadataViews.ExternalURL, coCreatable: Bool, coCreator: Address, editionNumber: UInt64, maxEditionNumber: UInt64?, revealableTraits:{ String: Bool}, royalties: MetadataViews.Royalties, royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties){ 
		pre{ 
			HighsnobietyNotInParis.baseTokenURI != nil:
				"Base URI must be set to mint an NFT!"
			variantId == 1 || variantId == 2 || variantId == 3:
				"Variant ID must be either 1, 2 or 3"
		}
		var nftName: String = ""
		var nftDescription: String = ""
		var metadata:{ String: String} ={} 
		switch variantId{ 
			case 1:
				nftName = "Eiffel Tower Pursuit"
				nftDescription = "Introducing the Eiffel Tower Pursuit Varsity Jacket, a digital twin of the classic Varsity Jacket. Mini Eiffel Towers follow you as you wander the city, paying homage to the iconic landmark."
				metadata ={ "mainImage": (HighsnobietyNotInParis.baseTokenURI!).concat("/EiffelTowerPursuit.png"), "video": (HighsnobietyNotInParis.baseTokenURI!).concat("/EiffelTowerPursuit.mp4")}
			case 2:
				nftName = "Parisian Mirage"
				nftDescription = "Step into a world of illusions with the Parisian Mirage Varsity Jacket. This jacket creates a mesmerizing effect that seamlessly transforms from a realistic surface to a mirage-like reflection of the surrounding environment."
				metadata ={ "mainImage": (HighsnobietyNotInParis.baseTokenURI!).concat("/ParisianMirage.png"), "video": (HighsnobietyNotInParis.baseTokenURI!).concat("/ParisianMirage.mp4")}
			case 3:
				nftName = "Echoes of Paris"
				nftDescription = "Get ready to trip out with the Echoes of Paris Varsity Jacket. This jacket features patches with a slow-mo effect that creates an entrancing visual display as you move."
				metadata ={ "mainImage": (HighsnobietyNotInParis.baseTokenURI!).concat("/EchoesOfParis.png"), "video": (HighsnobietyNotInParis.baseTokenURI!).concat("/EchoesOfParis.mp4")}
		}
		let mD = RevealableMetadata(id: id, nftUuid: nftUuid, name: nftName, description: nftDescription, collection: collection, metadata: metadata, characteristics: characteristics, license: license, externalURL: externalURL, coCreatable: coCreatable, coCreator: coCreator, editionNumber: editionNumber, maxEditionNumber: maxEditionNumber, revealableTraits: revealableTraits, royalties: royalties, royaltiesTFMarketplace: royaltiesTFMarketplace)
		HighsnobietyNotInParis.nftMetadata[id] = mD
	}
	
	access(self)
	fun nftsCanBeUsedForMint(receiver: &{NonFungibleToken.CollectionPublic}, refs: [&{NonFungibleToken.INFT}], typeRestrictions: [Type]): Bool{ 
		assert(typeRestrictions.length != 0, message: "There are no type restrictions for this promotion")
		var i = 0
		while i < refs.length{ 
			if typeRestrictions.contains(refs[i].getType()) && (receiver.owner!).address == (refs[i].owner!).address{ 
				return true
			}
			i = i + 1
		}
		return false
	}
	
	// -----------------------------------------------------------------------
	// Public Utility Functions
	// -----------------------------------------------------------------------
	// createEmptyCollection creates an empty Collection
	// and returns it to the caller so that they can own NFTs
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	fun getPublicMinterPaths():{ UInt64: String}{ 
		return HighsnobietyNotInParis.publicMinterPaths
	}
	
	access(all)
	fun getNftIdsToOwner():{ UInt64: Address}{ 
		return HighsnobietyNotInParis.nftIdsToOwner
	}
	
	access(all)
	fun getMaxSupply(): UInt64?{ 
		return HighsnobietyNotInParis.maxSupply
	}
	
	access(all)
	fun getTotalSupply(): UInt64{ 
		return HighsnobietyNotInParis.totalSupply
	}
	
	access(all)
	fun getCollectionId(): String?{ 
		return HighsnobietyNotInParis.collectionId
	}
	
	access(all)
	fun getNftMetadatas():{ UInt64:{ RevealableV2.RevealableMetadata}}{ 
		return self.nftMetadata
	}
	
	access(all)
	fun getPaymentCap(): Address?{ 
		return HighsnobietyNotInParis.paymentReceiverCap?.address
	}
	
	access(all)
	fun getBaseUri(): String?{ 
		return HighsnobietyNotInParis.baseTokenURI
	}
	
	// -----------------------------------------------------------------------
	// Contract Init
	// -----------------------------------------------------------------------
	init(){ 
		self.totalSupply = 0
		self.maxSupply = nil
		self.publicMinterPaths ={} 
		self.collectionId = nil
		self.nftIdsToOwner ={} 
		self.addressMintCount ={} 
		self.paymentReceiverCap = nil
		self.nftMetadata ={} 
		self.addressMintLimit = nil
		self.baseTokenURI = nil
		self.HighsnobietyNotInParisCollectionStoragePath = /storage/HighsnobietyNotInParisCollectionStoragePath
		self.HighsnobietyNotInParisCollectionPublicPath = /public/HighsnobietyNotInParisCollectionPublicPath
		self.HighsnobietyNotInParisProviderStoragePath = /private/HighsnobietyNotInParisProviderStoragePath
		self.HighsnobietyNotInParisAdminStoragePath = /storage/HighsnobietyNotInParisAdminStoragePath
		self.HighsnobietyNotInParisPublicMinterStoragePath = /storage/HighsnobietyNotInParisPublicMinterStoragePath
		self.HighsnobietyNotInParisPublicMinterPublicPath = /public/HighsnobietyNotInParisPublicMinterPublicPath
		self.account.storage.save(<-create Admin(adminAddress: self.account.address), to: self.HighsnobietyNotInParisAdminStoragePath)
		emit ContractInitialized()
	}
}
