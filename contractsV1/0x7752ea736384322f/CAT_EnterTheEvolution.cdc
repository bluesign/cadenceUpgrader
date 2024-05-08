import TheFabricantMetadataViewsV2 from "./TheFabricantMetadataViewsV2.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import TheFabricantNFTStandardV2 from "./TheFabricantNFTStandardV2.cdc"

import RevealableV2 from "./RevealableV2.cdc"

import CoCreatableV2 from "./CoCreatableV2.cdc"

import TheFabricantAccessList from "./TheFabricantAccessList.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

// CAT
// 4 shapes
// 10 materials
// 16 solid colors
// 10 texture sets
access(all)
contract CAT_EnterTheEvolution: NonFungibleToken, TheFabricantNFTStandardV2, RevealableV2{ 
	
	// -----------------------------------------------------------------------
	// Paths
	// -----------------------------------------------------------------------
	access(all)
	let CAT_EnterTheEvolutionCollectionStoragePath: StoragePath
	
	access(all)
	let CAT_EnterTheEvolutionCollectionPublicPath: PublicPath
	
	access(all)
	let CAT_EnterTheEvolutionProviderPath: PrivatePath
	
	access(all)
	let CAT_EnterTheEvolutionPublicMinterStoragePath: StoragePath
	
	access(all)
	let CAT_EnterTheEvolutionAdminStoragePath: StoragePath
	
	access(all)
	let CAT_EnterTheEvolutionPublicMinterPublicPath: PublicPath
	
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
	event DataAllocationCreated(uuid: UInt64, id: UInt64, editionNumber: UInt64, originalRecipient: Address, nftMetadataId: UInt64, dataAllocationString: String)
	
	access(all)
	event ItemRevealed(uuid: UInt64, id: UInt64, name: String, description: String, collection: String, editionNumber: UInt64, originalRecipient: Address, license: MetadataViews.License?, nftMetadataId: UInt64, externalURL: MetadataViews.ExternalURL, coCreatable: Bool, coCreator: Address)
	
	access(all)
	event TraitRevealed(nftUuid: UInt64, id: UInt64, trait: String)
	
	access(all)
	event IsTraitRevealableUpdated(nftUuid: UInt64, id: UInt64, trait: String, isRevealable: Bool)
	
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
	
	access(contract)
	var nftMetadata:{ UInt64:{ RevealableV2.RevealableMetadata}}
	
	// Keeps track of characteristic combinations, ensuring unique combos
	access(contract)
	var dataAllocations:{ String: UInt64}
	
	access(contract)
	var idsToDataAllocations:{ UInt64: String}
	
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
	
	// Change these dictionaries to represent the characteristics
	// of the nft that the user can choose from
	access(contract)
	var shoeShapes:{ UInt64:{ CoCreatableV2.Characteristic}}
	
	access(contract)
	var materials:{ UInt64:{ CoCreatableV2.Characteristic}}
	
	access(contract)
	var solidColors:{ UInt64:{ CoCreatableV2.Characteristic}}
	
	access(contract)
	var textureSets:{ UInt64:{ CoCreatableV2.Characteristic}}
	
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
		
		
		// NOTE: Name of NFT. Will most likely be the last node in the collection value.
		// eg XXories Original.
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
		
		// This is where the user-chosen characteristics live. This represents
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
			assert(CAT_EnterTheEvolution.baseTokenURI != nil, message: "The base URI must be set before reveal can take place")
			var i = 0
			while i < traits.length{ 
				let revealableTrait = traits[i]
				let traitName = revealableTrait.name
				let traitValue = revealableTrait.value
				switch traitName{ 
					case "mainImage":
						assert(self.checkRevealableTrait(traitName: traitName)!, message: "Unrevealable trait passed in - please ensure trait can be revealed: ".concat(traitName))
						self.updateMetadata(key: traitName, value: traitValue)
						log("Revealing mainImage")
					case "video":
						assert(self.checkRevealableTrait(traitName: traitName)!, message: "Unrevealable trait passed in - please ensure trait can be revealed: ".concat(traitName))
						self.updateMetadata(key: traitName, value: traitValue)
						log("Revealing video")
					default:
						panic("Unrevealable trait passed in - please ensure trait can be revealed: ".concat(traitName))
				}
				i = i + 1
			}
			//NOTE: Customise
			// Some collections may allow users to partially reveal their items. In this case, 
			// it may not be appropriate to set isRevealed to true yet.
			self.isRevealed = true
		}
		
		access(self)
		fun constructAssetPath(): String{ 
			
			// Get CharcteristicIds
			let shoeShapeId = ((self.characteristics["shoeShape"] as{ CoCreatableV2.Characteristic}?)!).id
			let materialId = ((self.characteristics["material"] as{ CoCreatableV2.Characteristic}?)!).id
			let solidColorId = ((self.characteristics["solidColor"] as!{ CoCreatableV2.Characteristic}?)!).id
			let textureSetId = ((self.characteristics["textureSet"] as!{ CoCreatableV2.Characteristic}?)!).id
			return "/".concat(shoeShapeId.toString()).concat("_").concat(materialId.toString()).concat("_").concat(solidColorId.toString()).concat("_").concat(textureSetId.toString())
		}
		
		access(contract)
		fun updateMetadata(key: String, value: AnyStruct){ 
			log("revealing key and value:")
			log(key)
			log(value)
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
			if let revealable = self.revealableTraits[traitName]{ 
				return revealable
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
	// Characteristic Struct
	// -----------------------------------------------------------------------
	access(all)
	struct Characteristic: CoCreatableV2.Characteristic{ 
		access(all)
		var id: UInt64
		
		access(all)
		var version: UFix64
		
		// This is the name that will be used for the trait, so 
		// will be displayed on external MPs etc. Should be capitalised
		// and spaced eg "Shoe Shape Name"
		access(all)
		var traitName: String
		
		// eg characteristicType = garmentData
		access(all)
		var characteristicType: String
		
		access(all)
		var characteristicDescription: String
		
		access(all)
		var designerName: String?
		
		access(all)
		var designerDescription: String?
		
		access(all)
		var designerAddress: Address?
		
		// Value is the name of the selected characteristic
		// For example, for a garment, this might be "Adventurer Top"
		access(all)
		var value: AnyStruct
		
		access(all)
		var rarity: MetadataViews.Rarity?
		
		access(all)
		var media: MetadataViews.Medias?
		
		init(id: UInt64, traitName: String, characteristicType: String, characteristicDescription: String, designerName: String?, designerDescription: String?, designerAddress: Address?, value: AnyStruct, rarity: MetadataViews.Rarity?, media: MetadataViews.Medias?){ 
			self.id = id
			//NOTE: Customise according to the 
			// CoCreatableV2 contract version
			self.version = 2.0
			self.traitName = traitName
			self.characteristicType = characteristicType
			self.characteristicDescription = characteristicDescription
			self.designerName = designerName
			self.designerDescription = designerDescription
			self.designerAddress = designerAddress
			self.value = value
			self.rarity = rarity
			self.media = media
		}
		
		// NOTE: Customise
		//Helper function that converts to traits for MetadataViews 
		access(all)
		fun convertToTraits(): [MetadataViews.Trait]{ 
			let traits: [MetadataViews.Trait] = []
			let idTrait = MetadataViews.Trait(name: self.traitName.concat(" ID"), value: self.id, displayType: "Number", rarity: nil)
			traits.append(idTrait)
			if self.designerName != nil{ 
				let designerNameTrait = MetadataViews.Trait(name: self.traitName.concat(" Designer"), value: self.designerName, displayType: "String", rarity: nil)
				traits.append(designerNameTrait)
			}
			if self.designerDescription != nil{ 
				let designerDescriptionTrait = MetadataViews.Trait(name: self.traitName.concat(" Designer Description"), value: self.designerDescription, displayType: "String", rarity: nil)
				traits.append(designerDescriptionTrait)
			}
			let valueRarity = self.rarity != nil ? self.rarity : nil
			// If the designer name is nil, then the trait wasn't designed and it must be a color.
			// Therefore we give it a name of "XYZ Value"
			let valueTrait = MetadataViews.Trait(name: self.designerName != nil ? self.traitName.concat(" Name") : self.traitName.concat(" Value"), value: self.value, displayType: "String", rarity: valueRarity)
			traits.append(valueTrait)
			return traits
		}
		
		//NOTE: Customise
		access(contract)
		fun updateCharacteristic(key: String, value: AnyStruct){} 
	// Can be implemented if needed.
	// Should be a switch statement like revealTrait() in Metadata struct
	}
	
	// -----------------------------------------------------------------------
	// NFT Resource
	// -----------------------------------------------------------------------
	// Restricted scope for borrowCAT_EnterTheEvolution() in Collection.
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
		
		//pub let uuid: UInt64 //Display, Serial, <- uuid is set automatically so no need to add
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
			return ((CAT_EnterTheEvolution.nftMetadata[self.nftMetadataId]!).name!).concat(" #".concat(self.editionNumber.toString()))
		}
		
		// NOTE: This is important for Edition view
		access(all)
		fun getEditionName(): String{ 
			return (CAT_EnterTheEvolution.nftMetadata[self.nftMetadataId]!).collection
		}
		
		access(all)
		fun getEditions(): MetadataViews.Editions{ 
			// NOTE: In this case, id == edition number
			let edition = MetadataViews.Edition(name: (CAT_EnterTheEvolution.nftMetadata[self.nftMetadataId]!).collection, number: self.editionNumber, max: CAT_EnterTheEvolution.maxSupply)
			return MetadataViews.Editions([edition])
		}
		
		//NOTE: Customise
		//NOTE: This will be different for each campaign, determined by how
		// many media files there are and their keys in metadata! Pay attention
		// to where the media files are stored and therefore accessed
		// NOTE: DOUBLE CHECK THE fileType IS CORRECT!!!
		access(all)
		fun getMedias(): MetadataViews.Medias{ 
			let nftMetadata = CAT_EnterTheEvolution.nftMetadata[self.id]!
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
			let nftMetadata = CAT_EnterTheEvolution.nftMetadata[self.id]!
			let mainImage = nftMetadata.metadata["mainImage"]! as! String
			return{ "mainImage": mainImage}
		}
		
		// NOTE: Customise
		access(all)
		fun getVideos():{ String: String}{ 
			let nftMetadata = CAT_EnterTheEvolution.nftMetadata[self.id]!
			let mainVideo = nftMetadata.metadata["video"]! as! String
			return{ "mainVideo": mainVideo}
		}
		
		// NOTE: Customise
		// What are the traits that you want external marketplaces
		// to display?
		access(all)
		fun getTraits(): MetadataViews.Traits?{ 
			let characteristics = (CAT_EnterTheEvolution.nftMetadata[self.id]!).characteristics
			log(characteristics)
			let shoeShapeCharacteristic = characteristics["shoeShape"]!
			let shoeTraits = shoeShapeCharacteristic.convertToTraits()
			let materialCharacteristic = characteristics["material"]!
			let materialTraits = materialCharacteristic.convertToTraits()
			let solidColorCharacteristic = characteristics["solidColor"]!
			let solidColorTraits = solidColorCharacteristic.convertToTraits()
			let textureSetsCharacteristic = characteristics["textureSet"]!
			let textureSetTraits = textureSetsCharacteristic.convertToTraits()
			let concatenatedArrays = shoeTraits.concat(materialTraits).concat(solidColorTraits).concat(textureSetTraits)
			return MetadataViews.Traits(concatenatedArrays)
		}
		
		access(all)
		view fun getRarity(): MetadataViews.Rarity?{ 
			return nil
		}
		
		access(all)
		fun getExternalRoyalties(): MetadataViews.Royalties{ 
			let nftMetadata = CAT_EnterTheEvolution.nftMetadata[self.id]!
			return nftMetadata.royalties
		}
		
		access(all)
		fun getTFRoyalties(): TheFabricantMetadataViewsV2.Royalties{ 
			let nftMetadata = CAT_EnterTheEvolution.nftMetadata[self.id]!
			return nftMetadata.royaltiesTFMarketplace
		}
		
		access(all)
		fun getMetadata():{ String: AnyStruct}{ 
			return (CAT_EnterTheEvolution.nftMetadata[self.id]!).metadata
		}
		
		//NOTE: This is not a CoCreatableV2 NFT, so no characteristics are present
		access(all)
		fun getCharacteristics():{ String:{ CoCreatableV2.Characteristic}}?{ 
			return (CAT_EnterTheEvolution.nftMetadata[self.id]!).characteristics
		}
		
		access(all)
		fun getRevealableTraits():{ String: Bool}?{ 
			return (CAT_EnterTheEvolution.nftMetadata[self.id]!).getRevealableTraits()
		}
		
		//NOTE: The first file in medias will be the thumbnail.
		// Maybe put a file type check in here to ensure it is 
		// an image?
		access(all)
		fun getDisplay(): MetadataViews.Display{ 
			return MetadataViews.Display(name: self.getFullName(), description: (CAT_EnterTheEvolution.nftMetadata[self.nftMetadataId]!).description, thumbnail: self.getMedias().items[0].file)
		}
		
		access(all)
		fun getCollectionData(): MetadataViews.NFTCollectionData{ 
			return MetadataViews.NFTCollectionData(storagePath: CAT_EnterTheEvolution.CAT_EnterTheEvolutionCollectionStoragePath, publicPath: CAT_EnterTheEvolution.CAT_EnterTheEvolutionCollectionPublicPath, publicCollection: Type<&CAT_EnterTheEvolution.Collection>(), publicLinkedType: Type<&CAT_EnterTheEvolution.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
					return <-CAT_EnterTheEvolution.createEmptyCollection(nftType: Type<@CAT_EnterTheEvolution.Collection>())
				})
		}
		
		//NOTE: Customise
		// NOTE: Update this function with the collection display image
		// and TF socials
		access(all)
		fun getCollectionDisplay(): MetadataViews.NFTCollectionDisplay{ 
			let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://www.dropbox.com/s/8jgcbkus6rg4v6c/CAT-logo-768x461.png?dl=0"), mediaType: "image/svg+xml")
			let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://www.dropbox.com/s/do50ksxr5vpdvsh/Stage02_CloseStill4k_169-US.png?dl=0"), mediaType: "image/svg+xml")
			return MetadataViews.NFTCollectionDisplay(name: self.getEditionName(), description: "Example Simple TFNFT", externalURL: (CAT_EnterTheEvolution.nftMetadata[self.id]!).externalURL, squareImage: squareImage, bannerImage: bannerImage, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/thefabricant"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/the_fab_ric_ant/"), "facebook": MetadataViews.ExternalURL("https://www.facebook.com/thefabricantdesign/"), "artstation": MetadataViews.ExternalURL("https://www.artstation.com/thefabricant"), "behance": MetadataViews.ExternalURL("https://www.behance.net/thefabricant"), "linkedin": MetadataViews.ExternalURL("https://www.linkedin.com/company/the-fabricant"), "sketchfab": MetadataViews.ExternalURL("https://sketchfab.com/thefabricant"), "clolab": MetadataViews.ExternalURL("https://www.clo3d.com/en/clollab/thefabricant"), "tiktok": MetadataViews.ExternalURL("@digital_fashion"), "discord": MetadataViews.ExternalURL("https://discord.com/channels/692039738751713280/778601303013195836")})
		}
		
		access(all)
		fun getNFTView(): MetadataViews.NFTView{ 
			return MetadataViews.NFTView(id: self.id, uuid: self.uuid, display: self.getDisplay(), externalURL: (CAT_EnterTheEvolution.nftMetadata[self.id]!).externalURL, collectionData: self.getCollectionData(), collectionDisplay: self.getCollectionDisplay(), royalties: (CAT_EnterTheEvolution.nftMetadata[self.id]!).royalties, traits: self.getTraits())
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
					return TheFabricantMetadataViewsV2.TFNFTIdentifierV1(uuid: self.uuid, id: self.id, name: self.getFullName(), collection: (CAT_EnterTheEvolution.nftMetadata[self.nftMetadataId]!).collection, editions: self.getEditions(), address: (self.owner!).address, originalRecipient: self.originalRecipient)
				case Type<TheFabricantMetadataViewsV2.TFNFTSimpleView>():
					return TheFabricantMetadataViewsV2.TFNFTSimpleView(uuid: self.uuid, id: self.id, name: self.getFullName(), description: (CAT_EnterTheEvolution.nftMetadata[self.nftMetadataId]!).description, collection: (CAT_EnterTheEvolution.nftMetadata[self.nftMetadataId]!).collection, collectionId: CAT_EnterTheEvolution.collectionId!, metadata: self.getMetadata(), media: self.getMedias(), images: self.getImages(), videos: self.getVideos(), externalURL: (CAT_EnterTheEvolution.nftMetadata[self.id]!).externalURL, rarity: self.getRarity(), traits: self.getTraits(), characteristics: self.getCharacteristics(), coCreatable: (CAT_EnterTheEvolution.nftMetadata[self.id]!).coCreatable, coCreator: (CAT_EnterTheEvolution.nftMetadata[self.id]!).coCreator, isRevealed: (CAT_EnterTheEvolution.nftMetadata[self.id]!).isRevealed, editions: self.getEditions(), originalRecipient: self.originalRecipient, royalties: (CAT_EnterTheEvolution.nftMetadata[self.id]!).royalties, royaltiesTFMarketplace: (CAT_EnterTheEvolution.nftMetadata[self.id]!).royaltiesTFMarketplace, revealableTraits: self.getRevealableTraits(), address: (self.owner!).address)
				case Type<MetadataViews.NFTView>():
					return self.getNFTView()
				case Type<MetadataViews.Display>():
					return self.getDisplay()
				case Type<MetadataViews.Editions>():
					return self.getEditions()
				case Type<MetadataViews.Serial>():
					return self.id
				case Type<MetadataViews.Royalties>():
					return CAT_EnterTheEvolution.nftMetadata[self.id]?.royalties
				case Type<MetadataViews.Medias>():
					return self.getMedias()
				case Type<MetadataViews.License>():
					return self.license
				case Type<MetadataViews.ExternalURL>():
					return CAT_EnterTheEvolution.nftMetadata[self.id]?.externalURL
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
			let nftMetadata = CAT_EnterTheEvolution.nftMetadata[self.id]!
			nftMetadata.updateIsTraitRevealable(key: key, value: value)
			CAT_EnterTheEvolution.nftMetadata[self.id] = nftMetadata
			emit IsTraitRevealableUpdated(nftUuid: nftMetadata.nftUuid, id: nftMetadata.id, trait: key, isRevealable: value)
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(originalRecipient: Address, license: MetadataViews.License?){ 
			assert(CAT_EnterTheEvolution.collectionId != nil, message: "Ensure that Admin has set collectionId in the contract")
			CAT_EnterTheEvolution.totalSupply = CAT_EnterTheEvolution.totalSupply + 1
			self.id = CAT_EnterTheEvolution.totalSupply
			self.collectionId = CAT_EnterTheEvolution.collectionId!
			
			// NOTE: Customise
			// The edition number may need to be different to id
			// for some campaigns
			self.editionNumber = self.id
			self.maxEditionNumber = CAT_EnterTheEvolution.maxSupply
			self.originalRecipient = originalRecipient
			self.license = license
			self.nftMetadataId = self.id
		}
	}
	
	// -----------------------------------------------------------------------
	// Collection Resource
	// -----------------------------------------------------------------------
	access(all)
	resource interface CAT_EnterTheEvolutionCollectionPublic{ 
		access(all)
		fun borrowCAT_EnterTheEvolution(id: UInt64): &CAT_EnterTheEvolution.NFT?
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CAT_EnterTheEvolutionCollectionPublic, ViewResolver.ResolverCollection{ 
		
		// Dictionary to hold the NFTs in the Collection
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let CAT_EnterTheEvolution = nft as! &CAT_EnterTheEvolution.NFT
			return CAT_EnterTheEvolution as &{ViewResolver.Resolver}
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
			CAT_EnterTheEvolution.nftIdsToOwner[id] = (self.owner!).address
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
		fun borrowCAT_EnterTheEvolution(id: UInt64): &CAT_EnterTheEvolution.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &CAT_EnterTheEvolution.NFT
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
		fun setBaseURI(baseURI: String){ 
			CAT_EnterTheEvolution.baseTokenURI = baseURI
			emit AdminSetBaseURI(baseURI: baseURI)
		}
		
		// The max supply determines the maximum number of NFTs that can be minted from this contract
		access(all)
		fun setMaxSupply(maxSupply: UInt64){ 
			CAT_EnterTheEvolution.maxSupply = maxSupply
			emit AdminSetMaxSupply(maxSupply: maxSupply)
		}
		
		access(all)
		fun setAddressMintLimit(addressMintLimit: UInt64){ 
			CAT_EnterTheEvolution.addressMintLimit = addressMintLimit
			emit AdminSetAddressMintLimit(addressMintLimit: addressMintLimit)
		}
		
		access(all)
		fun setCollectionId(collectionId: String){ 
			CAT_EnterTheEvolution.collectionId = collectionId
			emit AdminSetCollectionId(collectionId: collectionId)
		}
		
		// NOTE: It is in the public minter that you would create the restrictions
		// for minting. 
		access(all)
		fun createPublicMinter(name: String, description: String, collection: String, license: MetadataViews.License?, externalURL: MetadataViews.ExternalURL, coCreatable: Bool, revealableTraits:{ String: Bool}, minterMintLimit: UInt64?, royalties: MetadataViews.Royalties, royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties, paymentAmount: UFix64, paymentType: Type, paymentSplit: MetadataViews.Royalties?, typeRestrictions: [Type], accessListId: UInt64){ 
			pre{ 
				CAT_EnterTheEvolution.baseTokenURI != nil:
					"Please set a baseURI before creating a minter"
				CAT_EnterTheEvolution.materials.length != 0:
					"Please add materials to the contract"
				CAT_EnterTheEvolution.shoeShapes.length != 0:
					"Please add shoeShapes to the contract"
				CAT_EnterTheEvolution.textureSets.length != 0:
					"Please add textureSets to the contract"
				CAT_EnterTheEvolution.solidColors.length != 0:
					"Please add solidColors to the contract"
			}
			let publicMinter: @CAT_EnterTheEvolution.PublicMinter <- create PublicMinter(name: name, description: description, collection: collection, license: license, externalURL: externalURL, coCreatable: coCreatable, revealableTraits: revealableTraits, minterMintLimit: minterMintLimit, royalties: royalties, royaltiesTFMarketplace: royaltiesTFMarketplace, paymentAmount: paymentAmount, paymentType: paymentType, paymentSplit: paymentSplit, typeRestrictions: typeRestrictions, accessListId: accessListId)
			
			// Save path: name_collection_uuid
			// Link the Public Minter to a Public Path of the admin account
			let publicMinterStoragePath = StoragePath(identifier: publicMinter.path)
			let publicMinterPublicPath = PublicPath(identifier: publicMinter.path)
			CAT_EnterTheEvolution.account.storage.save(<-publicMinter, to: publicMinterStoragePath!)
			CAT_EnterTheEvolution.account.link<&PublicMinter>(publicMinterPublicPath!, target: publicMinterStoragePath!)
		}
		
		access(all)
		fun revealTraits(nftMetadataId: UInt64, traits: [{RevealableV2.RevealableTrait}]){ 
			let nftMetadata = CAT_EnterTheEvolution.nftMetadata[nftMetadataId]! as! CAT_EnterTheEvolution.RevealableMetadata
			nftMetadata.revealTraits(traits: traits)
			CAT_EnterTheEvolution.nftMetadata[nftMetadataId] = nftMetadata
			
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
		
		// NOTE: Customise
		access(all)
		fun updateShoeShapes(shapes:{ UInt64:{ CoCreatableV2.Characteristic}}){ 
			var i: UInt64 = 0
			let keys = shapes.keys
			let values = shapes.values
			while i < UInt64(shapes.length){ 
				CAT_EnterTheEvolution.shoeShapes[keys[i]] = values[i]
				i = i + 1
			}
		}
		
		// NOTE: Customise
		access(all)
		fun emptyShoeShapes(){ 
			CAT_EnterTheEvolution.shoeShapes ={} 
		}
		
		// NOTE: Customise
		access(all)
		fun updateMaterials(materials:{ UInt64:{ CoCreatableV2.Characteristic}}){ 
			var i: UInt64 = 0
			let keys = materials.keys
			let values = materials.values
			while i < UInt64(materials.length){ 
				CAT_EnterTheEvolution.materials[keys[i]] = values[i]
				i = i + 1
			}
		}
		
		// NOTE: Customise
		access(all)
		fun emptyMaterials(){ 
			CAT_EnterTheEvolution.materials ={} 
		}
		
		// NOTE: Customise
		access(all)
		fun updateSolidColors(solidColors:{ UInt64:{ CoCreatableV2.Characteristic}}){ 
			var i: UInt64 = 0
			let keys = solidColors.keys
			let values = solidColors.values
			while i < UInt64(solidColors.length){ 
				CAT_EnterTheEvolution.solidColors[keys[i]] = values[i]
				i = i + 1
			}
		}
		
		// NOTE: Customise
		access(all)
		fun emptySolidColors(){ 
			CAT_EnterTheEvolution.solidColors ={} 
		}
		
		// NOTE: Customise
		access(all)
		fun updateTextureSets(textureSets:{ UInt64:{ CoCreatableV2.Characteristic}}){ 
			var i: UInt64 = 0
			let keys = textureSets.keys
			let values = textureSets.values
			while i < UInt64(textureSets.length){ 
				CAT_EnterTheEvolution.textureSets[keys[i]] = values[i]
				i = i + 1
			}
		}
		
		// NOTE: Customise
		access(all)
		fun emptyTextureSets(){ 
			CAT_EnterTheEvolution.textureSets ={} 
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
		fun mintUsingAccessList(receiver: &{NonFungibleToken.CollectionPublic}, shoeShapeId: UInt64, materialId: UInt64, solidColorId: UInt64, textureSetId: UInt64)
		
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
		// maxSupply is hit √
		// minterMintLimit is hit √
		// mint if:
		// openAccess √
		// OR address on access list √
		// Output:
		// NFT √
		// nftMetadata √
		// Characteristics √
		// adds to dataAllocations dicts √
		// update mints per address √
		access(all)
		fun mintUsingAccessList(receiver: &{NonFungibleToken.CollectionPublic}, shoeShapeId: UInt64, materialId: UInt64, solidColorId: UInt64, textureSetId: UInt64){ 
			pre{ 
				self.isOpen:
					"Minting is not currently open!"
				!CAT_EnterTheEvolution.dataAllocations.containsKey(CAT_EnterTheEvolution.constructDataAllocationString(shoeShapeId: shoeShapeId, materialId: materialId, solidColorId: solidColorId, textureSetId: textureSetId)):
					"Combination of characteristics already exists, please choose again"
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
			if CAT_EnterTheEvolution.maxSupply != nil{ 
				assert(CAT_EnterTheEvolution.totalSupply + 1 <= CAT_EnterTheEvolution.maxSupply!, message: "Max supply for NFTs has been hit")
			}
			
			// Ensure user hasn't minted more NFTs from this contract than allowed
			if CAT_EnterTheEvolution.addressMintLimit != nil{ 
				if CAT_EnterTheEvolution.addressMintCount[(receiver.owner!).address] != nil{ 
					assert(CAT_EnterTheEvolution.addressMintCount[(receiver.owner!).address]! < CAT_EnterTheEvolution.addressMintLimit!, message: "User has already minted the maximum allowance per address!")
				}
			}
			
			// Ensure maxSupply hasn't been hit
			if CAT_EnterTheEvolution.maxSupply != nil{ 
				assert(CAT_EnterTheEvolution.totalSupply <= CAT_EnterTheEvolution.maxSupply!, message: "Cannot mint any more NFTs, max supply has been reached!")
			}
			if !self.isOpenAccess{ 
				assert(TheFabricantAccessList.checkAccessForAddress(accessListDetailsId: self.accessListId, address: (receiver.owner!).address), message: "User address is not on the access list and so cannot mint.")
			}
			let nft <- create NFT(originalRecipient: (receiver.owner!).address, license: self.license)
			
			//shoeShape.name is to be used for the NFT name
			let shoeShape = CAT_EnterTheEvolution.shoeShapes[shoeShapeId]
			let shoeShapeValue = (shoeShape!).value as!{ String: String}
			let shoeShapeName = (shoeShapeValue["name"] as String?)!
			let shoeShapeDescription = (shoeShape!).characteristicDescription
			
			// Add CoCreator to external royalties
			let coCreatorReceiver = getAccount((receiver.owner!).address).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
			let coCreatorExternalRoyalty = MetadataViews.Royalty(receiver: coCreatorReceiver, cut: 0.01, description: "CoCreator Royalty")
			let externalPublicMinterRoyalties = self.royalties.getRoyalties()
			externalPublicMinterRoyalties.append(coCreatorExternalRoyalty)
			let externalRoyalties = MetadataViews.Royalties(externalPublicMinterRoyalties)
			
			// Add CoCreator to internal royalties
			// Initial cut for CoCreator is 90%. They should also be the seller in the primary sale, unless they transferred the NFT.
			let coCreatorInternalRoyalty = TheFabricantMetadataViewsV2.Royalty(receiver: coCreatorReceiver, initialCut: 0.9, cut: 0.03, description: "CoCreator Royalty")
			let internalPublicMinterRoyalties = self.royaltiesTFMarketplace.getRoyalties()
			internalPublicMinterRoyalties.append(coCreatorInternalRoyalty)
			let internalRoyalties = TheFabricantMetadataViewsV2.Royalties(internalPublicMinterRoyalties)
			
			// Create Characteristics struct
			let characteristics = CAT_EnterTheEvolution.createCharacteristics(shoeShapeId: shoeShapeId, materialId: materialId, solidColorId: solidColorId, textureSetId: textureSetId)
			
			//Update data allocation. This prevents people from minting the same combination
			CAT_EnterTheEvolution.updateDataAllocations(nftId: nft.id, shoeShapeId: shoeShapeId, materialId: materialId, solidColorId: solidColorId, textureSetId: textureSetId)
			CAT_EnterTheEvolution.createNftMetadata(id: nft.id, nftUuid: nft.uuid, name: shoeShapeName, description: shoeShapeDescription, collection: self.collection, characteristics: characteristics, license: nft.license, externalURL: self.externalURL, coCreatable: self.coCreatable, coCreator: (receiver.owner!).address, editionNumber: nft.editionNumber, maxEditionNumber: nft.maxEditionNumber, revealableTraits: self.revealableTraits, royalties: externalRoyalties, royaltiesTFMarketplace: internalRoyalties)
			
			//NOTE: Event is emitted here and not in nft init because
			// data is split between RevealableMetadata and nft,
			// so not all event data is accessible during nft init
			emit ItemMintedAndTransferred(uuid: nft.uuid, id: nft.id, name: (CAT_EnterTheEvolution.nftMetadata[nft.nftMetadataId]!).name, description: (CAT_EnterTheEvolution.nftMetadata[nft.nftMetadataId]!).description, collection: (CAT_EnterTheEvolution.nftMetadata[nft.nftMetadataId]!).collection, editionNumber: nft.editionNumber, originalRecipient: nft.originalRecipient, license: self.license, nftMetadataId: nft.nftMetadataId)
			emit DataAllocationCreated(uuid: nft.uuid, id: nft.id, editionNumber: nft.editionNumber, originalRecipient: nft.originalRecipient, nftMetadataId: nft.nftMetadataId, dataAllocationString: CAT_EnterTheEvolution.idsToDataAllocations[nft.nftMetadataId]!)
			receiver.deposit(token: <-nft)
			
			// Increment the number of mints that an address has
			if CAT_EnterTheEvolution.addressMintCount[(receiver.owner!).address] != nil{ 
				CAT_EnterTheEvolution.addressMintCount[(receiver.owner!).address] = CAT_EnterTheEvolution.addressMintCount[(receiver.owner!).address]! + 1
			} else{ 
				CAT_EnterTheEvolution.addressMintCount[(receiver.owner!).address] = 1
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
			ret["collectionId"] = CAT_EnterTheEvolution.collectionId
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
			let pathString = "TheFabricantNFTPublicMinter_CAT_EnterTheEvolution_".concat(self.uuid.toString())
			CAT_EnterTheEvolution.publicMinterPaths[self.uuid] = pathString
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
	fun createNftMetadata(id: UInt64, nftUuid: UInt64, name: String, description: String, collection: String, characteristics:{ String:{ CoCreatableV2.Characteristic}}, license: MetadataViews.License?, externalURL: MetadataViews.ExternalURL, coCreatable: Bool, coCreator: Address, editionNumber: UInt64, maxEditionNumber: UInt64?, revealableTraits:{ String: Bool}, royalties: MetadataViews.Royalties, royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties){ 
		pre{ 
			CAT_EnterTheEvolution.baseTokenURI != nil:
				"Ensure baseUri is set before minting!"
		}
		
		//Instant reveal
		let dataAllocation = CAT_EnterTheEvolution.idsToDataAllocations[id]!
		let metadata ={ "mainImage": (CAT_EnterTheEvolution.baseTokenURI!).concat("/").concat(dataAllocation).concat(".png"), "video": (CAT_EnterTheEvolution.baseTokenURI!).concat("/").concat(dataAllocation).concat(".mp4")}
		let mD = RevealableMetadata(id: id, nftUuid: nftUuid, name: name, description: description, collection: collection, metadata: metadata, characteristics: characteristics, license: license, externalURL: externalURL, coCreatable: coCreatable, coCreator: coCreator, editionNumber: editionNumber, maxEditionNumber: maxEditionNumber, revealableTraits: revealableTraits, royalties: royalties, royaltiesTFMarketplace: royaltiesTFMarketplace)
		CAT_EnterTheEvolution.nftMetadata[id] = mD
	}
	
	//NOTE: Customise
	// This function generates the characteristics data for the minted nft.
	access(contract)
	fun createCharacteristics(shoeShapeId: UInt64, materialId: UInt64, solidColorId: UInt64, textureSetId: UInt64):{ String:{ CoCreatableV2.Characteristic}}{ 
		let dict:{ String:{ CoCreatableV2.Characteristic}} ={} 
		let shoeShape = CAT_EnterTheEvolution.shoeShapes[shoeShapeId] ?? panic("A shoe shape with this id does not exist")
		dict["shoeShape"] = shoeShape
		let material = CAT_EnterTheEvolution.materials[materialId] ?? panic("A material with this id does not exist")
		dict["material"] = material
		let solidColor = CAT_EnterTheEvolution.solidColors[solidColorId] ?? panic("A solid color with this id does not exist")
		dict["solidColor"] = solidColor
		let textureSet = CAT_EnterTheEvolution.textureSets[textureSetId] ?? panic("A texture set with this id does not exist")
		dict["textureSet"] = textureSet
		return dict
	}
	
	access(self)
	fun nftsCanBeUsedForMint(receiver: &{NonFungibleToken.CollectionPublic}, refs: [&{NonFungibleToken.INFT}], typeRestrictions: [Type]): Bool{ 
		assert(typeRestrictions.length != 0, message: "There are no typerestrictions for this promotion")
		var i = 0
		while i < refs.length{ 
			if typeRestrictions.contains(refs[i].getType()) && (receiver.owner!).address == (refs[i].owner!).address{ 
				return true
			}
			i = i + 1
		}
		return false
	}
	
	// Used to create the string Ids for checking if combo is taken
	// shoeShape_material_solidColor_textureSet
	access(contract)
	view fun constructDataAllocationString(shoeShapeId: UInt64, materialId: UInt64, solidColorId: UInt64, textureSetId: UInt64): String{ 
		return "shoe".concat(shoeShapeId.toString()).concat("_mat").concat(materialId.toString()).concat("_tex").concat(textureSetId.toString()).concat("_col").concat(solidColorId.toString())
	}
	
	access(contract)
	fun updateDataAllocations(nftId: UInt64, shoeShapeId: UInt64, materialId: UInt64, solidColorId: UInt64, textureSetId: UInt64){ 
		let allocationString = self.constructDataAllocationString(shoeShapeId: shoeShapeId, materialId: materialId, solidColorId: solidColorId, textureSetId: textureSetId)
		self.dataAllocations[allocationString] = nftId
		self.idsToDataAllocations[nftId] = allocationString
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
		return CAT_EnterTheEvolution.publicMinterPaths
	}
	
	access(all)
	fun getNftIdsToOwner():{ UInt64: Address}{ 
		return CAT_EnterTheEvolution.nftIdsToOwner
	}
	
	access(all)
	fun getMaxSupply(): UInt64?{ 
		return CAT_EnterTheEvolution.maxSupply
	}
	
	access(all)
	fun getTotalSupply(): UInt64{ 
		return CAT_EnterTheEvolution.totalSupply
	}
	
	access(all)
	fun getCollectionId(): String?{ 
		return CAT_EnterTheEvolution.collectionId
	}
	
	access(all)
	fun getNftMetadatas():{ UInt64:{ RevealableV2.RevealableMetadata}}{ 
		return self.nftMetadata
	}
	
	access(all)
	fun getDataAllocations():{ String: UInt64}{ 
		return self.dataAllocations
	}
	
	access(all)
	fun getAllIdsToDataAllocations():{ UInt64: String}{ 
		return self.idsToDataAllocations
	}
	
	access(all)
	fun getIdToDataAllocation(id: UInt64): String?{ 
		return self.idsToDataAllocations[id]
	}
	
	access(all)
	fun getAllCharacteristics(): AnyStruct{ 
		let res ={ "shoeShapes": CAT_EnterTheEvolution.shoeShapes, "materials": CAT_EnterTheEvolution.materials, "solidColors": CAT_EnterTheEvolution.solidColors, "textureSets": CAT_EnterTheEvolution.textureSets}
		return res
	}
	
	access(all)
	fun getBaseUri(): String?{ 
		return CAT_EnterTheEvolution.baseTokenURI
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
		self.nftMetadata ={} 
		self.dataAllocations ={} 
		self.idsToDataAllocations ={} 
		self.addressMintLimit = nil
		self.shoeShapes ={} 
		self.materials ={} 
		self.solidColors ={} 
		self.textureSets ={} 
		self.baseTokenURI = nil
		self.CAT_EnterTheEvolutionCollectionStoragePath = /storage/CAT_EnterTheEvolutionCollectionStoragePath
		self.CAT_EnterTheEvolutionCollectionPublicPath = /public/CAT_EnterTheEvolutionCollectionPublicPath
		self.CAT_EnterTheEvolutionProviderPath = /private/CAT_EnterTheEvolutionProviderPath
		self.CAT_EnterTheEvolutionAdminStoragePath = /storage/CAT_EnterTheEvolutionAdminStoragePath
		self.CAT_EnterTheEvolutionPublicMinterStoragePath = /storage/CAT_EnterTheEvolutionPublicMinterStoragePath
		self.CAT_EnterTheEvolutionPublicMinterPublicPath = /public/CAT_EnterTheEvolutionPublicMinterPublicPath
		self.account.storage.save(<-create Admin(adminAddress: self.account.address), to: self.CAT_EnterTheEvolutionAdminStoragePath)
		emit ContractInitialized()
	}
}
