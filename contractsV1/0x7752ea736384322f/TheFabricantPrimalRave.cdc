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

import PrimalRaveVariantMintLimits from "./PrimalRaveVariantMintLimits.cdc"

access(all)
contract TheFabricantPrimalRave: NonFungibleToken, TheFabricantNFTStandardV2, RevealableV2{ 
	
	// -----------------------------------------------------------------------
	// Paths
	// -----------------------------------------------------------------------
	access(all)
	let TheFabricantPrimalRaveCollectionStoragePath: StoragePath
	
	access(all)
	let TheFabricantPrimalRaveCollectionPublicPath: PublicPath
	
	access(all)
	let TheFabricantPrimalRaveProviderStoragePath: PrivatePath
	
	access(all)
	let TheFabricantPrimalRavePublicMinterStoragePath: StoragePath
	
	access(all)
	let TheFabricantPrimalRaveAdminStoragePath: StoragePath
	
	access(all)
	let TheFabricantPrimalRavePublicMinterPublicPath: PublicPath
	
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
	event AdminSetVariantSupply(variantId: UInt64, name: String, supply: UInt64)
	
	access(all)
	event AdminSetVariantPaymentAmount(variantId: UInt64, name: String, paymentAmount: UFix64)
	
	access(all)
	event AdminSetMintableVariants(mintableVariants: [UInt64])
	
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
	
	// The variant info for each variant
	access(contract)
	var variants:{ UInt64: VariantInfo}
	
	// The variants that this contract is able to mint
	access(contract)
	var mintableVariants: [UInt64]
	
	// -----------------------------------------------------------------------
	// VariantInfo Struct
	// -----------------------------------------------------------------------
	// Contains the information about a variant that is used in minting and on FE/BE etc.
	// The info contained in this struct is used to populate the NFT metadata
	access(all)
	struct VariantInfo{ 
		// id of the variant that is used in minting and on FE/BE etc
		access(all)
		let id: UInt64
		
		// name of the variant
		access(all)
		var name: String
		
		// variant description
		access(all)
		var description: String
		
		// price of the variant
		access(all)
		var paymentAmount: UFix64
		
		// max number of mints for this variant
		access(all)
		var supply: UInt64
		
		// total number of mints for this variant (ie current number of mints)
		access(all)
		var totalSupply: UInt64
		
		init(id: UInt64, name: String, description: String, paymentAmount: UFix64, supply: UInt64){ 
			self.id = id
			self.name = name
			self.description = description
			self.paymentAmount = paymentAmount
			self.supply = supply
			self.totalSupply = 0
		}
		
		access(all)
		fun incrementTotalSupply(){ 
			self.totalSupply = self.totalSupply + 1
		}
		
		access(all)
		fun canMintSupply(): Bool{ 
			return self.totalSupply <= self.supply
		}
		
		access(all)
		fun setPaymentAmount(paymentAmount: UFix64){ 
			self.paymentAmount = paymentAmount
		}
		
		access(all)
		fun setSupply(supply: UInt64){ 
			self.supply = supply
		}
	}
	
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
	// Restricted scope for borrowTheFabricantPrimalRave() in Collection.
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
			return ((TheFabricantPrimalRave.nftMetadata[self.nftMetadataId]!).name!).concat(" #".concat(self.editionNumber.toString()))
		}
		
		// NOTE: This is important for Edition view
		access(all)
		fun getEditionName(): String{ 
			return (TheFabricantPrimalRave.nftMetadata[self.nftMetadataId]!).collection
		}
		
		access(all)
		fun getEditions(): MetadataViews.Editions{ 
			// NOTE: In this case, id != edition number
			let edition = MetadataViews.Edition(name: (TheFabricantPrimalRave.nftMetadata[self.nftMetadataId]!).collection, number: self.editionNumber, max: self.maxEditionNumber)
			return MetadataViews.Editions([edition])
		}
		
		//NOTE: Customise
		//NOTE: This will be different for each campaign, determined by how
		// many media files there are and their keys in metadata! Pay attention
		// to where the media files are stored and therefore accessed
		access(all)
		fun getMedias(): MetadataViews.Medias{ 
			let nftMetadata = TheFabricantPrimalRave.nftMetadata[self.id]!
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
			let nftMetadata = TheFabricantPrimalRave.nftMetadata[self.id]!
			let mainImage = nftMetadata.metadata["mainImage"]! as! String
			return{ "mainImage": mainImage}
		}
		
		// NOTE: Customise
		access(all)
		fun getVideos():{ String: String}{ 
			let nftMetadata = TheFabricantPrimalRave.nftMetadata[self.id]!
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
			let nftMetadata = TheFabricantPrimalRave.nftMetadata[self.id]!
			return nftMetadata.royalties
		}
		
		access(all)
		fun getTFRoyalties(): TheFabricantMetadataViewsV2.Royalties{ 
			let nftMetadata = TheFabricantPrimalRave.nftMetadata[self.id]!
			return nftMetadata.royaltiesTFMarketplace
		}
		
		access(all)
		fun getMetadata():{ String: AnyStruct}{ 
			return (TheFabricantPrimalRave.nftMetadata[self.id]!).metadata
		}
		
		//NOTE: This is not a CoCreatableV2 NFT, so no characteristics are present
		access(all)
		fun getCharacteristics():{ String:{ CoCreatableV2.Characteristic}}?{ 
			return nil
		}
		
		access(all)
		fun getRevealableTraits():{ String: Bool}?{ 
			return (TheFabricantPrimalRave.nftMetadata[self.id]!).getRevealableTraits()
		}
		
		//NOTE: The first file in medias will be the thumbnail.
		// Maybe put a file type check in here to ensure it is 
		// an image?
		access(all)
		fun getDisplay(): MetadataViews.Display{ 
			return MetadataViews.Display(name: self.getFullName(), description: (TheFabricantPrimalRave.nftMetadata[self.nftMetadataId]!).description, thumbnail: self.getMedias().items[0].file)
		}
		
		access(all)
		fun getCollectionData(): MetadataViews.NFTCollectionData{ 
			return MetadataViews.NFTCollectionData(storagePath: TheFabricantPrimalRave.TheFabricantPrimalRaveCollectionStoragePath, publicPath: TheFabricantPrimalRave.TheFabricantPrimalRaveCollectionPublicPath, publicCollection: Type<&TheFabricantPrimalRave.Collection>(), publicLinkedType: Type<&TheFabricantPrimalRave.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
					return <-TheFabricantPrimalRave.createEmptyCollection(nftType: Type<@TheFabricantPrimalRave.Collection>())
				})
		}
		
		//NOTE: Customise
		// NOTE: Update this function with the collection display image
		// and TF socials
		access(all)
		fun getCollectionDisplay(): MetadataViews.NFTCollectionDisplay{ 
			let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://primalrave-collection-display.s3.eu-central-1.amazonaws.com/images/primalrave_square.png"), mediaType: "image/png")
			let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://primalrave-collection-display.s3.eu-central-1.amazonaws.com/images/primalrave_banner.png"), mediaType: "image/png")
			return MetadataViews.NFTCollectionDisplay(name: self.getEditionName(), description: "An exploration of the self through a club night, this collection takes inspiration from a secret rave in the forest. Elements of Dutch traditional dress in combination with 90s gabber aesthetic create a fresh narrative on what it means to explore your identity in a club night. ", externalURL: (TheFabricantPrimalRave.nftMetadata[self.id]!).externalURL, squareImage: squareImage, bannerImage: bannerImage, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/thefabricant"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/the_fab_ric_ant/"), "facebook": MetadataViews.ExternalURL("https://www.facebook.com/thefabricantdesign/"), "artstation": MetadataViews.ExternalURL("https://www.artstation.com/thefabricant"), "behance": MetadataViews.ExternalURL("https://www.behance.net/thefabricant"), "linkedin": MetadataViews.ExternalURL("https://www.linkedin.com/company/the-fabricant"), "sketchfab": MetadataViews.ExternalURL("https://sketchfab.com/thefabricant"), "clolab": MetadataViews.ExternalURL("https://www.clo3d.com/en/clollab/thefabricant"), "tiktok": MetadataViews.ExternalURL("@digital_fashion"), "discord": MetadataViews.ExternalURL("https://discord.com/channels/692039738751713280/778601303013195836")})
		}
		
		access(all)
		fun getNFTView(): MetadataViews.NFTView{ 
			return MetadataViews.NFTView(id: self.id, uuid: self.uuid, display: self.getDisplay(), externalURL: (TheFabricantPrimalRave.nftMetadata[self.id]!).externalURL, collectionData: self.getCollectionData(), collectionDisplay: self.getCollectionDisplay(), royalties: (TheFabricantPrimalRave.nftMetadata[self.id]!).royalties, traits: self.getTraits())
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
					return TheFabricantMetadataViewsV2.TFNFTIdentifierV1(uuid: self.uuid, id: self.id, name: self.getFullName(), collection: (TheFabricantPrimalRave.nftMetadata[self.nftMetadataId]!).collection, editions: self.getEditions(), address: (self.owner!).address, originalRecipient: self.originalRecipient)
				case Type<TheFabricantMetadataViewsV2.TFNFTSimpleView>():
					return TheFabricantMetadataViewsV2.TFNFTSimpleView(uuid: self.uuid, id: self.id, name: self.getFullName(), description: (TheFabricantPrimalRave.nftMetadata[self.nftMetadataId]!).description, collection: (TheFabricantPrimalRave.nftMetadata[self.nftMetadataId]!).collection, collectionId: TheFabricantPrimalRave.collectionId!, metadata: self.getMetadata(), media: self.getMedias(), images: self.getImages(), videos: self.getVideos(), externalURL: (TheFabricantPrimalRave.nftMetadata[self.id]!).externalURL, rarity: self.getRarity(), traits: self.getTraits(), characteristics: self.getCharacteristics(), coCreatable: (TheFabricantPrimalRave.nftMetadata[self.id]!).coCreatable, coCreator: (TheFabricantPrimalRave.nftMetadata[self.id]!).coCreator, isRevealed: (TheFabricantPrimalRave.nftMetadata[self.id]!).isRevealed, editions: self.getEditions(), originalRecipient: self.originalRecipient, royalties: (TheFabricantPrimalRave.nftMetadata[self.id]!).royalties, royaltiesTFMarketplace: (TheFabricantPrimalRave.nftMetadata[self.id]!).royaltiesTFMarketplace, revealableTraits: self.getRevealableTraits(), address: (self.owner!).address)
				case Type<MetadataViews.NFTView>():
					return self.getNFTView()
				case Type<MetadataViews.Display>():
					return self.getDisplay()
				case Type<MetadataViews.Editions>():
					return self.getEditions()
				case Type<MetadataViews.Serial>():
					return self.id
				case Type<MetadataViews.Royalties>():
					return TheFabricantPrimalRave.nftMetadata[self.id]?.royalties
				case Type<MetadataViews.Medias>():
					return self.getMedias()
				case Type<MetadataViews.License>():
					return self.license
				case Type<MetadataViews.ExternalURL>():
					return TheFabricantPrimalRave.nftMetadata[self.id]?.externalURL
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
			let nftMetadata = TheFabricantPrimalRave.nftMetadata[self.id]!
			nftMetadata.updateIsTraitRevealable(key: key, value: value)
			TheFabricantPrimalRave.nftMetadata[self.id] = nftMetadata
			emit IsTraitRevealableV2Updated(nftUuid: nftMetadata.nftUuid, id: nftMetadata.id, trait: key, isRevealableV2: value)
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(variantId: UInt64, originalRecipient: Address, license: MetadataViews.License?){ 
			assert(TheFabricantPrimalRave.collectionId != nil, message: "Ensure that Admin has set collectionId in the contract")
			
			// Increment the total number of NFTs minted in the contract
			TheFabricantPrimalRave.totalSupply = TheFabricantPrimalRave.totalSupply + 1
			self.id = TheFabricantPrimalRave.totalSupply
			self.collectionId = TheFabricantPrimalRave.collectionId!
			(			 
			 // Increment the number minted for this variant
			 TheFabricantPrimalRave.variants[variantId]!).incrementTotalSupply()
			
			// Set nft edition number
			self.editionNumber = (TheFabricantPrimalRave.variants[variantId]!).totalSupply
			// max edition number is specific to the variant
			self.maxEditionNumber = (TheFabricantPrimalRave.variants[variantId]!).supply
			self.originalRecipient = originalRecipient
			self.license = license
			self.nftMetadataId = self.id
		}
	}
	
	// -----------------------------------------------------------------------
	// Collection Resource
	// -----------------------------------------------------------------------
	access(all)
	resource interface TheFabricantPrimalRaveCollectionPublic{ 
		access(all)
		fun borrowTheFabricantPrimalRave(id: UInt64): &TheFabricantPrimalRave.NFT?
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, TheFabricantPrimalRaveCollectionPublic, ViewResolver.ResolverCollection{ 
		
		// Dictionary to hold the NFTs in the Collection
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let TheFabricantPrimalRave = nft as! &TheFabricantPrimalRave.NFT
			return TheFabricantPrimalRave as &{ViewResolver.Resolver}
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
			TheFabricantPrimalRave.nftIdsToOwner[id] = (self.owner!).address
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
		fun borrowTheFabricantPrimalRave(id: UInt64): &TheFabricantPrimalRave.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &TheFabricantPrimalRave.NFT
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
			TheFabricantPrimalRave.paymentReceiverCap = paymentReceiverCap
			emit AdminPaymentReceiverCapabilityChanged(address: paymentReceiverCap.address, paymentType: paymentReceiverCap.getType())
		}
		
		access(all)
		fun setBaseURI(baseURI: String){ 
			TheFabricantPrimalRave.baseTokenURI = baseURI
			emit AdminSetBaseURI(baseURI: baseURI)
		}
		
		// The max supply determines the maximum number of NFTs that can be minted from this contract
		access(all)
		fun setMaxSupply(maxSupply: UInt64){ 
			TheFabricantPrimalRave.maxSupply = maxSupply
			emit AdminSetMaxSupply(maxSupply: maxSupply)
		}
		
		access(all)
		fun setAddressMintLimit(addressMintLimit: UInt64){ 
			TheFabricantPrimalRave.addressMintLimit = addressMintLimit
			emit AdminSetAddressMintLimit(addressMintLimit: addressMintLimit)
		}
		
		access(all)
		fun setCollectionId(collectionId: String){ 
			TheFabricantPrimalRave.collectionId = collectionId
			emit AdminSetCollectionId(collectionId: collectionId)
		}
		
		// Sets the supply for each variant.
		access(all)
		fun setVariantSupply(supplyDict:{ UInt64: UInt64}){ 
			let keys = supplyDict.keys
			let values = supplyDict.values
			let variantKeys = TheFabricantPrimalRave.variants.keys
			while keys.length > 0{ 
				let key = keys.removeFirst()
				let value = values.removeFirst()
				assert(variantKeys.contains(key), message: "Variant does not exist")
				(TheFabricantPrimalRave.variants[key]!).setSupply(supply: value)
				emit AdminSetVariantSupply(variantId: key, name: (TheFabricantPrimalRave.variants[key]!).name, supply: value)
			}
			// Update maxSupply
			let variants = TheFabricantPrimalRave.variants.values
			var i = 0
			var sum: UInt64 = 0
			while i < variants.length{ 
				sum = sum + variants[i].supply
				i = i + 1
			}
			TheFabricantPrimalRave.maxSupply = sum
			emit AdminSetMaxSupply(maxSupply: sum)
		}
		
		access(all)
		fun setVariantPaymentAmount(priceDict:{ UInt64: UFix64}){ 
			let keys = priceDict.keys
			let values = priceDict.values
			let variantKeys = TheFabricantPrimalRave.variants.keys
			while keys.length > 0{ 
				let key = keys.removeFirst()
				let value = values.removeFirst()
				assert(variantKeys.contains(key), message: "Variant does not exist")
				(TheFabricantPrimalRave.variants[key]!).setPaymentAmount(paymentAmount: value)
				emit AdminSetVariantPaymentAmount(variantId: key, name: (TheFabricantPrimalRave.variants[key]!).name, paymentAmount: value)
			}
		}
		
		access(all)
		fun setMintableVariants(mintableVariants: [UInt64]){ 
			TheFabricantPrimalRave.mintableVariants = mintableVariants
			emit AdminSetMintableVariants(mintableVariants: mintableVariants)
		}
		
		//NOTE: Customise
		// mint not:
		// address mint limit for variant has been hit √
		// total maxSupply has been hit √
		// maxSupply for variant has been hit √
		// minting isn't open (!isOpen) √
		// variant is not mintable √
		// baseURI is not set √
		// mint if:
		// openAccess √
		// OR address on access list √
		// Output:
		// NFT √
		// nftMetadata √
		// update mints per address √
		// update total supply for variant √
		//NOTE: !Used for CC payments via MoonPay!
		access(all)
		fun distributeDirectlyViaAccessList(receiver: &{NonFungibleToken.CollectionPublic}, publicMinterPathString: String, variantId: UInt64){ 
			
			// Ensure that the maximum supply of nfts for this contract has not been hit
			if TheFabricantPrimalRave.maxSupply != nil{ 
				assert(TheFabricantPrimalRave.totalSupply + 1 <= TheFabricantPrimalRave.maxSupply!, message: "Max supply for NFTs has been hit")
			}
			
			// Check that address has not minted the maximum number of NFTs for this variant
			assert(PrimalRaveVariantMintLimits.checkAddressCanMintVariant(address: (receiver.owner!).address, variantId: variantId), message: "Address has already minted the maximum for this variant")
			
			// Get the publicMinter details so we can apply all the correct props to the NFT
			//NOTE: Therefore relies on a pM having been created
			let publicPath = PublicPath(identifier: publicMinterPathString) ?? panic("Failed to construct public path from path string: ".concat(publicMinterPathString))
			let publicMinterCap = getAccount((self.owner!).address).capabilities.get<&TheFabricantPrimalRave.PublicMinter>(publicPath).borrow<&TheFabricantPrimalRave.PublicMinter>() ?? panic("Couldn't get publicMinter ref or pathString is wrong: ".concat(publicMinterPathString))
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
			let nft <- create NFT(variantId: variantId, originalRecipient: (receiver.owner!).address, license: license)
			let name = publicMinterDetails["name"] as! String?
			let description = publicMinterDetails["description"] as! String?
			let collection = publicMinterDetails["collection"] as! String?
			let externalURL = publicMinterDetails["externalURL"] as! MetadataViews.ExternalURL?
			let coCreatable = publicMinterDetails["coCreatable"] as! Bool?
			let revealableTraits = publicMinterDetails["revealableTraits"] as!{ String: Bool}?
			let royalties = publicMinterDetails["royalties"] as! MetadataViews.Royalties?
			let royaltiesTFMarketplace = publicMinterDetails["royaltiesTFMarketplace"] as! TheFabricantMetadataViewsV2.Royalties?
			
			//Create the nftMetadata
			TheFabricantPrimalRave.createNftMetadata(id: nft.id, nftUuid: nft.uuid, variantId: variantId, collection: collection!, characteristics:{} , license: nft.license, externalURL: externalURL!, coCreatable: coCreatable!, coCreator: (receiver.owner!).address, editionNumber: nft.editionNumber, maxEditionNumber: nft.maxEditionNumber, revealableTraits: revealableTraits!, royalties: royalties!, royaltiesTFMarketplace: royaltiesTFMarketplace!)
			
			//NOTE: Event is emitted here and not in nft init because
			// data is split between RevealableMetadata and nft,
			// so not all event data is accessible during nft init
			emit ItemMintedAndTransferred(uuid: nft.uuid, id: nft.id, name: (TheFabricantPrimalRave.nftMetadata[nft.nftMetadataId]!).name, description: (TheFabricantPrimalRave.nftMetadata[nft.nftMetadataId]!).description, collection: (TheFabricantPrimalRave.nftMetadata[nft.nftMetadataId]!).collection, editionNumber: nft.editionNumber, originalRecipient: nft.originalRecipient, license: nft.license, nftMetadataId: nft.nftMetadataId)
			receiver.deposit(token: <-nft)
			
			// Increment the number of mints that an address has
			if TheFabricantPrimalRave.addressMintCount[(receiver.owner!).address] != nil{ 
				TheFabricantPrimalRave.addressMintCount[(receiver.owner!).address] = TheFabricantPrimalRave.addressMintCount[(receiver.owner!).address]! + 1
			} else{ 
				TheFabricantPrimalRave.addressMintCount[(receiver.owner!).address] = 1
			}
			
			// Increment the number of mints for this variant
			PrimalRaveVariantMintLimits.incrementVariantMintsForAddress(address: (receiver.owner!).address, variantId: variantId)
		}
		
		// NOTE: It is in the public minter that you would create the restrictions
		// for minting. 
		access(all)
		fun createPublicMinter(name: String, description: String, collection: String, license: MetadataViews.License?, externalURL: MetadataViews.ExternalURL, coCreatable: Bool, revealableTraits:{ String: Bool}, minterMintLimit: UInt64?, royalties: MetadataViews.Royalties, royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties, paymentAmount: UFix64, paymentType: Type, paymentSplit: MetadataViews.Royalties?, typeRestrictions: [Type], accessListId: UInt64){ 
			pre{ 
				TheFabricantPrimalRave.paymentReceiverCap != nil:
					"Please set the paymentReceiverCap before creating a minter"
			}
			let publicMinter: @TheFabricantPrimalRave.PublicMinter <- create PublicMinter(name: name, description: description, collection: collection, license: license, externalURL: externalURL, coCreatable: coCreatable, revealableTraits: revealableTraits, minterMintLimit: minterMintLimit, royalties: royalties, royaltiesTFMarketplace: royaltiesTFMarketplace, paymentAmount: paymentAmount, paymentType: paymentType, paymentSplit: paymentSplit, typeRestrictions: typeRestrictions, accessListId: accessListId)
			
			// Save path: name_collection_uuid
			// Link the Public Minter to a Public Path of the admin account
			let publicMinterStoragePath = StoragePath(identifier: publicMinter.path)
			let publicMinterPublicPath = PublicPath(identifier: publicMinter.path)
			TheFabricantPrimalRave.account.storage.save(<-publicMinter, to: publicMinterStoragePath!)
			TheFabricantPrimalRave.account.link<&PublicMinter>(publicMinterPublicPath!, target: publicMinterStoragePath!)
		}
		
		access(all)
		fun revealTraits(nftMetadataId: UInt64, traits: [{RevealableV2.RevealableTrait}]){ 
			let nftMetadata = TheFabricantPrimalRave.nftMetadata[nftMetadataId]! as! TheFabricantPrimalRave.RevealableMetadata
			nftMetadata.revealTraits(traits: traits)
			TheFabricantPrimalRave.nftMetadata[nftMetadataId] = nftMetadata
			
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
		// address mint limit for variant has been hit √
		// maxMint for this address has been hit √
		// total maxSupply has been hit √
		// maxSupply for variant has been hit √
		// minting isn't open (!isOpen) √
		// payment is insufficient √
		// minterMintLimit is hit √
		// variant is not mintable √
		// baseURI is not set √
		// mint if:
		// openAccess √
		// OR address on access list √
		// Output:
		// NFT √
		// nftMetadata √
		// update mints per address √
		// update total supply for variant √
		access(all)
		fun mintUsingAccessList(receiver: &{NonFungibleToken.CollectionPublic}, payment: @{FungibleToken.Vault}, variantId: UInt64){ 
			pre{ 
				self.isOpen:
					"Minting is not currently open!"
				payment.isInstance(self.paymentType):
					"payment vault is not requested fungible token"
				TheFabricantPrimalRave.paymentReceiverCap != nil:
					"Payment Receiver Cap must be set for minting!"
			}
			post{ 
				receiver.getIDs().length == before(receiver.getIDs().length) + 1:
					"Minted NFT must be deposited into Collection"
			}
			assert(payment.balance == (TheFabricantPrimalRave.variants[variantId]!).paymentAmount, message: "Payment amount is incorrect")
			
			// Check that address has not minted the maximum number of NFTs for this variant
			assert(PrimalRaveVariantMintLimits.checkAddressCanMintVariant(address: (receiver.owner!).address, variantId: variantId), message: "Address has already minted the maximum for this variant")
			
			// Total number of mints by this pM
			self.numberOfMints = self.numberOfMints + 1
			
			// Ensure that minterMintLimit for this pM has not been hit
			if self.minterMintLimit != nil{ 
				assert(self.numberOfMints <= self.minterMintLimit!, message: "Maximum number of mints for this public minter has been hit")
			}
			
			// Ensure that the maximum supply of nfts for this contract has not been hit
			if TheFabricantPrimalRave.maxSupply != nil{ 
				assert(TheFabricantPrimalRave.totalSupply + 1 <= TheFabricantPrimalRave.maxSupply!, message: "Max supply for NFTs has been hit")
			}
			
			// Ensure user hasn't minted more NFTs from this contract than allowed
			if TheFabricantPrimalRave.addressMintLimit != nil{ 
				if TheFabricantPrimalRave.addressMintCount[(receiver.owner!).address] != nil{ 
					assert(TheFabricantPrimalRave.addressMintCount[(receiver.owner!).address]! < TheFabricantPrimalRave.addressMintLimit!, message: "User has already minted the maximum allowance per address!")
				}
			}
			
			// Check that the address has access via the access list. If isOpenAccess, then anyone can mint.
			if !self.isOpenAccess{ 
				assert(TheFabricantAccessList.checkAccessForAddress(accessListDetailsId: self.accessListId, address: (receiver.owner!).address), message: "User address is not on the access list and so cannot mint.")
			}
			
			// Settle Payment ONLY if variant is not free
			if (TheFabricantPrimalRave.variants[variantId]!).paymentAmount != 0.0{ 
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
			}
			if payment.balance != 0.0 || payment.balance == 0.0{ 
				// pay rest to TF
				emit MintPaymentSplitDeposited(address: (TheFabricantPrimalRave.paymentReceiverCap!).address, price: self.paymentAmount, amount: payment.balance, nftUuid: self.uuid)
			}
			((			  // Deposit has to occur outside of above if statement as resource must be moved or destroyed
			  TheFabricantPrimalRave.paymentReceiverCap!).borrow()!).deposit(from: <-payment)
			let nft <- create NFT(variantId: variantId, originalRecipient: (receiver.owner!).address, license: self.license)
			TheFabricantPrimalRave.createNftMetadata(id: nft.id, nftUuid: nft.uuid, variantId: variantId, collection: self.collection, characteristics:{} , license: nft.license, externalURL: self.externalURL, coCreatable: self.coCreatable, coCreator: (receiver.owner!).address, editionNumber: nft.editionNumber, maxEditionNumber: nft.maxEditionNumber, revealableTraits: self.revealableTraits, royalties: self.royalties, royaltiesTFMarketplace: self.royaltiesTFMarketplace)
			
			//NOTE: Event is emitted here and not in nft init because
			// data is split between RevealableMetadata and nft,
			// so not all event data is accessible during nft init
			emit ItemMintedAndTransferred(uuid: nft.uuid, id: nft.id, name: (TheFabricantPrimalRave.nftMetadata[nft.nftMetadataId]!).name, description: (TheFabricantPrimalRave.nftMetadata[nft.nftMetadataId]!).description, collection: (TheFabricantPrimalRave.nftMetadata[nft.nftMetadataId]!).collection, editionNumber: nft.editionNumber, originalRecipient: nft.originalRecipient, license: self.license, nftMetadataId: nft.nftMetadataId)
			receiver.deposit(token: <-nft)
			
			// Increment the number of mints that an address has
			if TheFabricantPrimalRave.addressMintCount[(receiver.owner!).address] != nil{ 
				TheFabricantPrimalRave.addressMintCount[(receiver.owner!).address] = TheFabricantPrimalRave.addressMintCount[(receiver.owner!).address]! + 1
			} else{ 
				TheFabricantPrimalRave.addressMintCount[(receiver.owner!).address] = 1
			}
			
			// Increment the number of mints for this variant
			PrimalRaveVariantMintLimits.incrementVariantMintsForAddress(address: (receiver.owner!).address, variantId: variantId)
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
			ret["collectionId"] = TheFabricantPrimalRave.collectionId
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
			let pathString = "TheFabricantNFTPublicMinter_TheFabricantPrimalRave_".concat(self.uuid.toString())
			TheFabricantPrimalRave.publicMinterPaths[self.uuid] = pathString
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
	fun createNftMetadata(id: UInt64, nftUuid: UInt64, variantId: UInt64, collection: String, characteristics:{ String:{ CoCreatableV2.Characteristic}}, license: MetadataViews.License?, externalURL: MetadataViews.ExternalURL, coCreatable: Bool, coCreator: Address, editionNumber: UInt64, maxEditionNumber: UInt64?, revealableTraits:{ String: Bool}, royalties: MetadataViews.Royalties, royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties){ 
		pre{ 
			TheFabricantPrimalRave.baseTokenURI != nil:
				"Base URI must be set to mint an NFT!"
		}
		assert(TheFabricantPrimalRave.mintableVariants.contains(variantId), message: "Variant is not mintable")
		assert((TheFabricantPrimalRave.variants[variantId]!).canMintSupply(), message: "Variant has hit max supply for variant")
		
		// Get variant specific metadata
		let name: String = (TheFabricantPrimalRave.variants[variantId]!).name
		let description: String = (TheFabricantPrimalRave.variants[variantId]!).description
		var metadata:{ String: String} ={ "mainImage": (TheFabricantPrimalRave.baseTokenURI!).concat("/").concat(variantId.toString()).concat(".png"), "video": (TheFabricantPrimalRave.baseTokenURI!).concat("/").concat(variantId.toString()).concat(".mp4")}
		let mD = RevealableMetadata(id: id, nftUuid: nftUuid, name: name, description: description, collection: collection, metadata: metadata, characteristics: characteristics, license: license, externalURL: externalURL, coCreatable: coCreatable, coCreator: coCreator, editionNumber: editionNumber, maxEditionNumber: maxEditionNumber, revealableTraits: revealableTraits, royalties: royalties, royaltiesTFMarketplace: royaltiesTFMarketplace)
		TheFabricantPrimalRave.nftMetadata[id] = mD
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
		return TheFabricantPrimalRave.publicMinterPaths
	}
	
	access(all)
	fun getNftIdsToOwner():{ UInt64: Address}{ 
		return TheFabricantPrimalRave.nftIdsToOwner
	}
	
	access(all)
	fun getMaxSupply(): UInt64?{ 
		return TheFabricantPrimalRave.maxSupply
	}
	
	access(all)
	fun getTotalSupply(): UInt64{ 
		return TheFabricantPrimalRave.totalSupply
	}
	
	access(all)
	fun getCollectionId(): String?{ 
		return TheFabricantPrimalRave.collectionId
	}
	
	access(all)
	fun getNftMetadatas():{ UInt64:{ RevealableV2.RevealableMetadata}}{ 
		return self.nftMetadata
	}
	
	access(all)
	fun getVariantInfo(variantId: UInt64): VariantInfo?{ 
		return TheFabricantPrimalRave.variants[variantId]
	}
	
	access(all)
	fun getVariants():{ UInt64: VariantInfo}{ 
		return TheFabricantPrimalRave.variants
	}
	
	access(all)
	fun getVariantSupplies():{ UInt64:{ String: UInt64}}{ 
		var ret:{ UInt64:{ String: UInt64}} ={} 
		var i: UInt64 = 1
		while i <= UInt64(TheFabricantPrimalRave.variants.length){ 
			ret[i] ={ "maxSupply": (TheFabricantPrimalRave.variants[i]!).supply, "totalSupply": (TheFabricantPrimalRave.variants[i]!).totalSupply}
			i = i + 1
		}
		return ret
	}
	
	access(all)
	fun getMintableVariants(): [UInt64]{ 
		return TheFabricantPrimalRave.mintableVariants
	}
	
	access(all)
	fun getPaymentCap(): Address?{ 
		return TheFabricantPrimalRave.paymentReceiverCap?.address
	}
	
	access(all)
	fun getBaseUri(): String?{ 
		return TheFabricantPrimalRave.baseTokenURI
	}
	
	// -----------------------------------------------------------------------
	// Contract Init
	// -----------------------------------------------------------------------
	init(){ 
		self.totalSupply = 0
		self.publicMinterPaths ={} 
		self.collectionId = nil
		self.nftIdsToOwner ={} 
		self.addressMintCount ={} 
		self.paymentReceiverCap = nil
		self.nftMetadata ={} 
		self.addressMintLimit = nil
		self.baseTokenURI = nil
		
		// Used to calculate maxSupply
		let v1Supply: UInt64 = 475
		let v2Supply: UInt64 = 275
		let v3Supply: UInt64 = 350
		let v4Supply: UInt64 = 5025
		let v5Supply: UInt64 = 375
		let v6Supply: UInt64 = 275
		let v7Supply: UInt64 = 275
		let v8Supply: UInt64 = 5025
		self.maxSupply = v1Supply + v2Supply + v3Supply + v4Supply + v5Supply + v6Supply + v7Supply + v8Supply
		self.variants ={ 1: VariantInfo(id: 1, name: "Hardcore Happiness", description: "Where are we headed, can you feel the excitement in the air? The journey is about to begin. Right before you go to the party, the excitement can even make you a little nauseous. Eating the forbidden fruit is also known as breaking free of conventions. Can you shift your paradigm? Are you open to rediscover new parts of yourself you forgot existed, yet were here all along?", paymentAmount: 70.0, supply: v1Supply), 2: VariantInfo(id: 2, name: "Door Bitch", description: "We all judge, all the time. It is our mechanism. Discrimination is the ability to distinguish things. We need it, yet it has gotten such a heavy load in our culture. Can we see beyond the boundaries, beyond the binaries, and discover the true nature is all made of the same anyway? Our souls are all the same and we have all lived multiple lives. Will you get into the club in this lifetime or the next?", paymentAmount: 50.0, supply: v2Supply), 3: VariantInfo(id: 3, name: "Skullfck", description: "Take a good look at yourself in the mirror. Are you accepting all of you? Or does your darkness catch you off guard? Does it scare you, or can you fully accept it? We all have parts of ourselves we hide, but to embrace them is key to becoming whole.", paymentAmount: 30.0, supply: v3Supply), 4: VariantInfo(id: 4, name: "Pump Boots", description: "Dance from dusk till dawn in these platform pumps, emblazoned with the iconic acid house smiley and sad face. Featuring neon detailing across the vamp and heel, lighting the way on even the darkest dance floors.", paymentAmount: 0.0, supply: v4Supply), 5: VariantInfo(id: 5, name: "Curtain Calling", description: "Enter a world of desire, longing and infatuation. Intoxicate yourself with the beauty of these pleasures, but only to widen your perspective. Are you able to admire the beauty without losing yourself in it? Only then you are worthy of entering xthis holy space.. Shaking the bum and hips was used in ancient temples to awaken the pelvic floor and get the energy moving in your body.", paymentAmount: 30.0, supply: v5Supply), 6: VariantInfo(id: 6, name: "Forbidden Fruit", description: "Your core is shaking. Foundations are melting. When you accept your whole self, the ground will melt away under your feet first. If you let yourself melt, accept it fully, only then can you rise from the dark waters.", paymentAmount: 50.0, supply: v6Supply), 7: VariantInfo(id: 7, name: "Ecstasy", description: "If, and only if we can accept ourselves fully, we realize that we are all the parts we played in the game. We shine bright like never before, embracing ourselves in all our fullness. We realize we are everything already anyway, and nothing at the same time. These are just layers of identity, which is not our true self. We cut away anything that is not true and shine our colors in that. We don\u{2019}t need to eat anything to become something, because we are the fruit ourselves.", paymentAmount: 70.0, supply: v7Supply), 8: VariantInfo(id: 8, name: "Lace Boots", description: "Extended version of the pumps boots reaching knee high with fitted fluorescent backs and open front laced up. Neon detailing across the vamp and heel, lighting the way on the darkest dance floors.", paymentAmount: 0.0, supply: v8Supply)}
		self.mintableVariants = [1, 2, 3, 4]
		self.TheFabricantPrimalRaveCollectionStoragePath = /storage/TheFabricantPrimalRaveCollectionStoragePath
		self.TheFabricantPrimalRaveCollectionPublicPath = /public/TheFabricantPrimalRaveCollectionPublicPath
		self.TheFabricantPrimalRaveProviderStoragePath = /private/TheFabricantPrimalRaveProviderStoragePath
		self.TheFabricantPrimalRaveAdminStoragePath = /storage/TheFabricantPrimalRaveAdminStoragePath
		self.TheFabricantPrimalRavePublicMinterStoragePath = /storage/TheFabricantPrimalRavePublicMinterStoragePath
		self.TheFabricantPrimalRavePublicMinterPublicPath = /public/TheFabricantPrimalRavePublicMinterPublicPath
		self.account.storage.save(<-create Admin(adminAddress: self.account.address), to: self.TheFabricantPrimalRaveAdminStoragePath)
		emit ContractInitialized()
	}
}
