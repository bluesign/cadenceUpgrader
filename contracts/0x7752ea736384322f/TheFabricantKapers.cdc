import TheFabricantMetadataViewsV2 from "./TheFabricantMetadataViewsV2.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import TheFabricantNFTStandardV2 from "./TheFabricantNFTStandardV2.cdc"
import RevealableV2 from "./RevealableV2.cdc"
import CoCreatableV2 from "./CoCreatableV2.cdc"
import TheFabricantAccessList from "./TheFabricantAccessList.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"

// Kapers
// 3 garments
// 10 materials
// 10 primary colors
// 10 secondary colors

pub contract TheFabricantKapers: NonFungibleToken, TheFabricantNFTStandardV2, RevealableV2 {

    // -----------------------------------------------------------------------
    // Paths
    // -----------------------------------------------------------------------

    pub let TheFabricantKapersCollectionStoragePath: StoragePath
    pub let TheFabricantKapersCollectionPublicPath: PublicPath
    pub let TheFabricantKapersProviderPath: PrivatePath
    pub let TheFabricantKapersPublicMinterStoragePath: StoragePath 
    pub let TheFabricantKapersAdminStoragePath: StoragePath
    pub let TheFabricantKapersPublicMinterPublicPath: PublicPath

    // -----------------------------------------------------------------------
    // Contract Events
    // -----------------------------------------------------------------------

    // Event that emitted when the NFT contract is initialized
    //
    pub event ContractInitialized()

    pub event ItemMintedAndTransferred(
        uuid: UInt64,
        id: UInt64,
        name: String,
        description: String,
        collection: String,
        editionNumber: UInt64,
        originalRecipient: Address,
        license: MetadataViews.License?,
        nftMetadataId: UInt64
    )

    pub event DataAllocationCreated(
        uuid: UInt64,
        id: UInt64,
        editionNumber: UInt64,
        originalRecipient: Address,
        nftMetadataId: UInt64,
        dataAllocationString: String
    )

    pub event ItemRevealed(
        uuid: UInt64,
        id: UInt64,
        name: String,
        description: String,
        collection: String,
        editionNumber: UInt64,
        originalRecipient: Address,
        license: MetadataViews.License?,
        nftMetadataId: UInt64,
        externalURL: MetadataViews.ExternalURL,
        coCreatable: Bool,
        coCreator: Address,
    )

    pub event TraitRevealed(
        nftUuid: UInt64, 
        id: UInt64,
        trait: String,
    )

    pub event IsTraitRevealableUpdated(
        nftUuid: UInt64, 
        id: UInt64,
        trait: String,
        isRevealable: Bool
    )

    pub event ItemDestroyed(
        uuid: UInt64,
        id: UInt64,
        name: String,
        description: String,
        collection: String,
    )

    pub event MintPaymentSplitDeposited(
        address: Address,
        price: UFix64,
        amount: UFix64,
        nftUuid: UInt64
    )

    pub event PublicMinterCreated(
        uuid: UInt64,
        name: String,
        description: String,
        collection: String,
        path: String,
    )

    pub event PublicMinterIsOpenAccessChanged(
        uuid: UInt64,
        name: String,
        description: String,
        collection: String,
        path: String,
        isOpenAccess: Bool,
        isAccessListOnly: Bool,
        isOpen: Bool
    )

    pub event PublicMinterIsAccessListOnly(
        uuid: UInt64,
        name: String,
        description: String,
        collection: String,
        path: String,
        isOpenAccess: Bool,
        isAccessListOnly: Bool,
        isOpen: Bool
    )

    pub event PublicMinterMintingIsOpen(
        uuid: UInt64,
        name: String,
        description: String,
        collection: String,
        path: String,
        isOpenAccess: Bool,
        isAccessListOnly: Bool,
        isOpen: Bool
    )

    pub event PublicMinterSetAccessListId(
        uuid: UInt64,
        name: String,
        description: String,
        collection: String,
        path: String,
        isOpenAccess: Bool,
        isAccessListOnly: Bool,
        isOpen: Bool,
        accessListId: UInt64
    )

    pub event PublicMinterSetPaymentAmount(
        uuid: UInt64,
        name: String,
        description: String,
        collection: String,
        path: String,
        isOpenAccess: Bool,
        isAccessListOnly: Bool,
        isOpen: Bool,
        paymentAmount: UFix64
    )
    

    pub event PublicMinterSetMinterMintLimit(
        uuid: UInt64,
        name: String,
        description: String,
        collection: String,
        path: String,
        isOpenAccess: Bool,
        isAccessListOnly: Bool,
        isOpen: Bool,
        minterMintLimit: UInt64?
    )

    pub event AdminResourceCreated(
        uuid:UInt64,
        adminAddress: Address
    )

    pub event AdminPaymentReceiverCapabilityChanged(
        address: Address,
        paymentType: Type
    )

    pub event AdminSetMaxSupply(
        maxSupply: UInt64 
    )

    pub event AdminSetAddressMintLimit(
        addressMintLimit: UInt64 
    )

    pub event AdminSetCollectionId(
        collectionId: String 
    )

    pub event AdminSetBaseURI(baseURI: String)

    pub event AdminSetIsFreeMintActive(isActive: Bool)

    // Event that is emitted when a token is withdrawn,
    // indicating the owner of the collection that it was withdrawn from.
    //
    // If the collection is not in an account's storage, `from` will be `nil`.
    //
    pub event Withdraw(id: UInt64, from: Address?)

    // Event that emitted when a token is deposited to a collection.
    //
    // It indicates the owner of the collection that it was deposited to.
    //
    pub event Deposit(id: UInt64, to: Address?)

    // -----------------------------------------------------------------------
    // Contract State
    // -----------------------------------------------------------------------

    // NOTE: This is updated anywhere ownership of the nft is changed - on minting and therefore on deposit
    access(contract) var nftIdsToOwner: {UInt64: Address}
    access(contract) var publicMinterPaths: {UInt64: String}

    // NOTE: this is contract-level so all minters can access it.
    // Keeps track of the number of times an address has minted
    access(contract) var addressMintCount: {Address: UInt64}

    // Receives payment for minting
    access(contract) var paymentReceiverCap: Capability<&{FungibleToken.Receiver}>?

    access(contract) var nftMetadata: {UInt64: AnyStruct{RevealableV2.RevealableMetadata}}

    // Keeps track of characteristic combinations, ensuring unique combos
    access(contract) var dataAllocations: {String: UInt64}
    access(contract) var idsToDataAllocations: {UInt64: String}

    // The total number of tokens of this type in existence
    // NOTE: All public minters use totalSupply to assign the next
    // id and edition number. Each public minter has a minterMintLimit property
    // that defines the max no. of mints a pM can do. 
    pub var totalSupply: UInt64
    // NOTE: The max number of NFTs in this collection that will ever be minted
    // Init as nil if there is no max. 
    pub var maxSupply: UInt64?
    
    // NOTE: Max mints per address
    pub var addressMintLimit: UInt64?

    //NOTE: uuid of collection added to NFT and used by BE
    pub var collectionId: String?

    // Change these dictionaries to represent the characteristics
    // of the nft that the user can choose from
    access(contract) var garments: {UInt64: {CoCreatableV2.Characteristic}}
    access(contract) var materials: {UInt64: {CoCreatableV2.Characteristic}}
    access(contract) var primaryColors: {UInt64: {CoCreatableV2.Characteristic}}
    access(contract) var secondaryColors: {UInt64: {CoCreatableV2.Characteristic}}

    access(contract) var baseTokenURI: String?

    access(contract) var isFreeMintActive: Bool
    // {mintAddress: nftId}
    access(contract) var claimedFreeMints: {Address: UInt64}

    // -----------------------------------------------------------------------
    // RevealableV2 Metadata Struct
    // -----------------------------------------------------------------------

    pub struct RevealableMetadata: RevealableV2.RevealableMetadata {

        //NOTE: totalSupply value of attached NFT, therefore edition number. 
        pub let id: UInt64 

        // NOTE: !IMPORTANT! nftUuid is the uuid of the associated nft.
        // This RevealableMetadata struct should be stored in the nftMetadata dict under this
        // value. This is because the uuid is used across contracts for identification purposes
        pub let nftUuid: UInt64 // uuid of NFT
        
        // NOTE: Name of NFT. Will most likely be the last node in the collection value.
        // eg XXories Original.
        // Will be combined with the edition number on the application
        // Doesn't include the edition number.
        pub var name: String

        pub var description: String //Display
        // NOTE: Thumbnail, which is needed for the Display view, should be set using one of the
        // media properties
        //pub let thumbnail: String //Display

        pub let collection: String // Name of collection eg The Fabricant > Season 3 > Wholeland > XXories Originals

        // Stores the metadata that describes this particular creation,
        // but is not part of a characteristic eg mainImage, video etc
        pub var metadata: {String: AnyStruct}

        // This is where the user-chosen characteristics live. This represents
        // the data that in older contracts, would've been separate NFTs.        
        pub var characteristics: {String: {CoCreatableV2.Characteristic}}

        pub var rarity: UFix64?
        pub var rarityDescription: String?

        // NOTE: Media is not implemented in the struct because MetadataViews.Medias
        // is not mutable, so can't be updated. In addition, each 
        // NFT collection might have a different number of image/video properties.
        // Instead, the NFT should implement a function that rolls up the props
        // into a MetadataViews.Medias struct
        //pub let media: MetadataViews.Medias //Media

        pub let license: MetadataViews.License? //License

        pub let externalURL: MetadataViews.ExternalURL //ExternalURL
        
        pub let coCreatable: Bool
        pub let coCreator: Address

        pub var isRevealed: Bool?

        // id and editionNumber might not be the same in the nft...
        pub let editionNumber: UInt64 //Edition
        pub let maxEditionNumber: UInt64?

        pub let royalties: MetadataViews.Royalties //Royalty
        pub let royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties
        
        access(contract) var revealableTraits: {String: Bool}

        pub fun getRevealableTraits(): {String: Bool} {
            return self.revealableTraits
        }

        //NOTE: Customise
        //NOTE: This should be updated for each campaign contract!
        // Called by the Admin to reveal the traits for this NFT.
        // Should contain a switch function that knows how to modify
        // the properties of this struct. Should check that the trait
        // being revealed is allowed to be modified.
        access(contract) fun revealTraits(traits: [{RevealableV2.RevealableTrait}]) {
            assert(TheFabricantKapers.baseTokenURI != nil, message: "The base URI must be set before reveal can take place")
            var i = 0
            while i < traits.length {
                let revealableTrait = traits[i]
                let traitName = revealableTrait.name
                let traitValue = revealableTrait.value

                switch(traitName) {
                    case "mainImage":
                        assert(self.checkRevealableTrait(traitName: traitName)!, message: "Unrevealable trait passed in - please ensure trait can be revealed: ".concat(traitName))
                        self.updateMetadata(key: traitName, value: traitValue)
                    case "video":
                        assert(self.checkRevealableTrait(traitName: traitName)!, message: "Unrevealable trait passed in - please ensure trait can be revealed: ".concat(traitName))
                        self.updateMetadata(key: traitName, value: traitValue)
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

        access(self) fun constructAssetPath(): String {
            
            // Get CharcteristicIds
            let garmentId = (self.characteristics["garment"] as {CoCreatableV2.Characteristic}?)!.id
            let materialId = (self.characteristics["material"] as {CoCreatableV2.Characteristic}?)!.id
            let primaryColorId = (self.characteristics["primaryColor"] as! {CoCreatableV2.Characteristic}?)!.id
            let secondaryColorId = (self.characteristics["secondaryColor"] as! {CoCreatableV2.Characteristic}?)!.id
            return "/"
                .concat(garmentId.toString())
                .concat("_").concat(materialId.toString())
                .concat("_").concat(primaryColorId.toString())
                .concat("_").concat(secondaryColorId.toString())
        }

        access(contract) fun updateMetadata(key: String, value: AnyStruct) {
            self.metadata[key] = value
        }

        // Called by the nft owner to modify if a trait can be 
        // revealed or not - used to revoke admin access
        pub fun updateIsTraitRevealable(key: String, value: Bool) {
            self.revealableTraits[key] = value
        }

        pub fun checkRevealableTrait(traitName: String): Bool? {
            if let revealable = self.revealableTraits[traitName] {
                return revealable
            }
            return nil
        }

        init(
            id: UInt64,
            nftUuid: UInt64,    
            name: String,
            description: String,
            collection: String,
            metadata: {String: AnyStruct},
            characteristics: {String: {CoCreatableV2.Characteristic}},
            license: MetadataViews.License?,
            externalURL: MetadataViews.ExternalURL,
            coCreatable: Bool,
            coCreator: Address,
            editionNumber: UInt64,
            maxEditionNumber: UInt64?,
            revealableTraits: {String: Bool},
            royalties: MetadataViews.Royalties,
            royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties

        ) {

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
    
    pub struct Trait: RevealableV2.RevealableTrait {
        pub let name: String
        pub let value: AnyStruct

        init(
            name: String, 
            value: AnyStruct
            ) {
            self.name = name
            self.value = value
        }
    }

    // -----------------------------------------------------------------------
    // Characteristic Struct
    // -----------------------------------------------------------------------

    pub struct Characteristic: CoCreatableV2.Characteristic {
        pub var id: UInt64

        pub var version: UFix64
        // This is the name that will be used for the trait, so 
        // will be displayed on external MPs etc. Should be capitalised
        // and spaced eg "Garment Name"
        pub var traitName: String
        // eg characteristicType = garmentData
        pub var characteristicType: String
        pub var characteristicDescription: String
        pub var designerName: String?
        pub var designerDescription: String?
        pub var designerAddress: Address?
        // Value is the name of the selected characteristic
        // For example, for a garment, this might be "Adventurer Top"
        pub var value: AnyStruct
        pub var rarity: MetadataViews.Rarity?

        pub var media: MetadataViews.Medias?

        init(
            id: UInt64,
            traitName: String,
            characteristicType: String,
            characteristicDescription: String,
            designerName: String?,
            designerDescription: String?,
            designerAddress: Address?,
            value: AnyStruct,
            rarity: MetadataViews.Rarity?,
            media: MetadataViews.Medias?
        ) {
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
        pub fun convertToTraits(): [MetadataViews.Trait] {
            let traits: [MetadataViews.Trait] = []
            let idTrait =  MetadataViews.Trait(
                name: self.traitName.concat(" ID"),
                value: self.id,
                displayType: "Number",
                rarity: nil
            )
            traits.append(idTrait)

            if self.designerName != nil {
                let designerNameTrait =  MetadataViews.Trait(
                    name: self.traitName.concat(" Designer"),
                    value: self.designerName,
                    displayType: "String",
                    rarity: nil
                )
                traits.append(designerNameTrait)
            }

            if self.designerDescription != nil {
                let designerDescriptionTrait =  MetadataViews.Trait(
                    name: self.traitName.concat(" Designer Description"),
                    value: self.designerDescription,
                    displayType: "String",
                    rarity: nil
                )
                traits.append(designerDescriptionTrait)
            }

            let valueRarity = self.rarity != nil ? self.rarity : nil
            // If the designer name is nil, then the trait wasn't designed and it must be a color.
            // Therefore we give it a name of "XYZ Value"
            let valueTrait =  MetadataViews.Trait(
                name: self.designerName != nil ? self.traitName.concat(" Name"): self.traitName.concat(" Value"),
                value: self.value,
                displayType: "String",
                rarity: valueRarity
            )
            traits.append(valueTrait)
            return traits
        }

        //NOTE: Customise
        access(contract) fun updateCharacteristic(key: String, value: AnyStruct) {
            // Can be implemented if needed.
            // Should be a switch statement like revealTrait() in Metadata struct
        }

        
    }

    // -----------------------------------------------------------------------
    // NFT Resource
    // -----------------------------------------------------------------------

    // Restricted scope for borrowTheFabricantKapers() in Collection.
    // Ensures that the returned NFT ref is read only.
    pub resource interface PublicNFT {
        pub fun getFullName(): String
        pub fun getEditions(): MetadataViews.Editions
        pub fun getMedias(): MetadataViews.Medias
        pub fun getTraits(): MetadataViews.Traits?
        pub fun getRarity(): MetadataViews.Rarity?
        pub fun getExternalRoyalties(): MetadataViews.Royalties 
        pub fun getTFRoyalties(): TheFabricantMetadataViewsV2.Royalties 
        pub fun getMetadata(): {String: AnyStruct} 
        pub fun getCharacteristics(): {String: {CoCreatableV2.Characteristic}}? 
        pub fun getDisplay(): MetadataViews.Display 
        pub fun getCollectionData(): MetadataViews.NFTCollectionData 
        pub fun getCollectionDisplay(): MetadataViews.NFTCollectionDisplay
        pub fun getNFTView(): MetadataViews.NFTView
        pub fun getViews(): [Type]
        pub fun resolveView(_ view: Type): AnyStruct?
    }

    pub resource NFT: TheFabricantNFTStandardV2.TFNFT, NonFungibleToken.INFT, MetadataViews.Resolver, PublicNFT {
        pub let id: UInt64 
        //pub let uuid: UInt64 //Display, Serial, <- uuid is set automatically so no need to add
        
        // NOTE: Ensure that the name for the nft is correct. This 
        // will be shown to users. It should not include the edition number.

        access(contract) let collectionId: String

        access(contract) let editionNumber: UInt64 //Edition
        access(contract) let maxEditionNumber: UInt64?

        access(contract) let originalRecipient: Address

        access(contract) let license: MetadataViews.License?

        access(contract) let nftMetadataId: UInt64

        pub fun getFullName(): String {
            return TheFabricantKapers.nftMetadata[self.nftMetadataId]!.name!.concat(" #".concat(self.editionNumber.toString()))
        }

        // NOTE: This is important for Edition view
        pub fun getEditionName(): String {
            return TheFabricantKapers.nftMetadata[self.nftMetadataId]!.collection
        }

        pub fun getEditions(): MetadataViews.Editions {
            // NOTE: In this case, id == edition number
            let edition = MetadataViews.Edition(
                name: TheFabricantKapers.nftMetadata[self.nftMetadataId]!.collection,
                number: self.editionNumber,
                max: TheFabricantKapers.maxSupply
            )

            return MetadataViews.Editions(
                infoList: [edition]
            )
        }

        //NOTE: Customise
        //NOTE: This will be different for each campaign, determined by how
        // many media files there are and their keys in metadata! Pay attention
        // to where the media files are stored and therefore accessed
        // NOTE: DOUBLE CHECK THE fileType IS CORRECT!!!
        pub fun getMedias(): MetadataViews.Medias {
            let nftMetadata = TheFabricantKapers.nftMetadata[self.id]!
            let mainImage = nftMetadata.metadata["mainImage"]! as! String
            // NOTE: This assumes that when the garment characteristic is created
            // in the update_garment_char tx, the value property is created as a dictionary
            let video = nftMetadata.metadata["video"]! as! String

            let mainImageMedia = MetadataViews.Media(
                file: MetadataViews.HTTPFile(url: mainImage), 
                fileType: "image/png"
            )
            let videoMedia = MetadataViews.Media(
                file: MetadataViews.HTTPFile(url: video), 
                fileType: "video/mp4"
            )
            return MetadataViews.Medias(items: [
                mainImageMedia,
                videoMedia
            ])
        }

        // NOTE: Customise
        pub fun getImages(): {String: String} {
            let nftMetadata = TheFabricantKapers.nftMetadata[self.id]!
            let mainImage = nftMetadata.metadata["mainImage"]! as! String
            return {
                "mainImage": mainImage
            }
        }

        // NOTE: Customise
        pub fun getVideos(): {String: String} {
            let nftMetadata = TheFabricantKapers.nftMetadata[self.id]!
            let mainVideo = nftMetadata.metadata["video"]! as! String
            return {
                "mainVideo": mainVideo
            }
        }

        // NOTE: Customise
        // What are the traits that you want external marketplaces
        // to display?
        pub fun getTraits(): MetadataViews.Traits? {
            let characteristics = TheFabricantKapers.nftMetadata[self.id]!.characteristics
            let garmentCharacteristic = characteristics["garment"]!
            let garmentTraits = garmentCharacteristic.convertToTraits()
            let materialCharacteristic = characteristics["material"]!
            let materialTraits = materialCharacteristic.convertToTraits()
            let primaryColorCharacteristic = characteristics["primaryColor"]!
            let primaryColorTraits = primaryColorCharacteristic.convertToTraits()
            let secondaryColorsCharacteristic = characteristics["secondaryColor"]!
            let secondaryColorTraits = secondaryColorsCharacteristic.convertToTraits()
            let concatenatedArrays = garmentTraits.concat(materialTraits).concat(primaryColorTraits).concat(secondaryColorTraits)
            return MetadataViews.Traits(concatenatedArrays)
        }

        pub fun getRarity(): MetadataViews.Rarity? {
            return nil
        }

        pub fun getExternalRoyalties(): MetadataViews.Royalties {
            let nftMetadata = TheFabricantKapers.nftMetadata[self.id]!
            return nftMetadata.royalties
        }

        pub fun getTFRoyalties(): TheFabricantMetadataViewsV2.Royalties {
            let nftMetadata = TheFabricantKapers.nftMetadata[self.id]!
            return nftMetadata.royaltiesTFMarketplace
        }

        pub fun getMetadata(): {String: AnyStruct} {
            return TheFabricantKapers.nftMetadata[self.id]!.metadata
        }

        //NOTE: This is not a CoCreatableV2 NFT, so no characteristics are present
        pub fun getCharacteristics(): {String: {CoCreatableV2.Characteristic}}? {
            return TheFabricantKapers.nftMetadata[self.id]!.characteristics
        }

        pub fun getRevealableTraits(): {String: Bool}? {
            return TheFabricantKapers.nftMetadata[self.id]!.getRevealableTraits()
        }


        //NOTE: The first file in medias will be the thumbnail.
        // Maybe put a file type check in here to ensure it is 
        // an image?
        pub fun getDisplay(): MetadataViews.Display {
            return MetadataViews.Display(
                name: self.getFullName(),
                description: TheFabricantKapers.nftMetadata[self.nftMetadataId]!.description,
                thumbnail: self.getMedias().items[0].file
            )
        }

        pub fun getCollectionData(): MetadataViews.NFTCollectionData {
            return MetadataViews.NFTCollectionData(
                storagePath: TheFabricantKapers.TheFabricantKapersCollectionStoragePath,
                publicPath: TheFabricantKapers.TheFabricantKapersCollectionPublicPath,
                providerPath: TheFabricantKapers.TheFabricantKapersProviderPath,
                publicCollection: Type<&TheFabricantKapers.Collection{TheFabricantKapers.TheFabricantKapersCollectionPublic, MetadataViews.ResolverCollection}>(),
                publicLinkedType: Type<&TheFabricantKapers.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, TheFabricantKapers.TheFabricantKapersCollectionPublic, MetadataViews.ResolverCollection}>(),
                providerLinkedType: Type<&TheFabricantKapers.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, TheFabricantKapersCollectionPublic}>(),
                createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-TheFabricantKapers.createEmptyCollection()
                })
            )
        }

        //NOTE: Customise
        // NOTE: Update this function with the collection display image
        // and TF socials
        pub fun getCollectionDisplay(): MetadataViews.NFTCollectionDisplay {
            let squareImage = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://leela.mypinata.cloud/ipfs/QmVPbbS7zVEyBGARHSVX8KcYBZ7bqV48koT2ibBFbL4iYy/BULLISH_KAPER_01.png"
                        ),
                        mediaType: "image/png"
                    )
            let bannerImage = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://leela.mypinata.cloud/ipfs/QmVPbbS7zVEyBGARHSVX8KcYBZ7bqV48koT2ibBFbL4iYy/VENICE_SCENE1_SHOT3_2K0530-studio.png"
                        ),
                        mediaType: "image/png"
                    )
            return MetadataViews.NFTCollectionDisplay(
                        name: self.getEditionName(),
                        description: "Inspired by club culture in the 90s and 2000s, the Kapers are headgear to get you moving up to speed. Next to the XXories, they form a part of the overall look of the collection and we want you to co-create them with us.",
                        externalURL: TheFabricantKapers.nftMetadata[self.id]!.externalURL,
                        squareImage: squareImage,
                        bannerImage: bannerImage,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/thefabricant"),
                            "instagram":MetadataViews.ExternalURL( "https://www.instagram.com/the_fab_ric_ant/"),
                            "facebook": MetadataViews.ExternalURL("https://www.facebook.com/thefabricantdesign/"),
                            "artstation": MetadataViews.ExternalURL("https://www.artstation.com/thefabricant"),
                            "behance": MetadataViews.ExternalURL("https://www.behance.net/thefabricant"),
                            "linkedin": MetadataViews.ExternalURL("https://www.linkedin.com/company/the-fabricant"),
                            "sketchfab": MetadataViews.ExternalURL("https://sketchfab.com/thefabricant"),
                            "clolab": MetadataViews.ExternalURL("https://www.clo3d.com/en/clollab/thefabricant"),
                            "tiktok": MetadataViews.ExternalURL("@digital_fashion"),
                            "discord": MetadataViews.ExternalURL("https://discord.com/channels/692039738751713280/778601303013195836")
                        }
                    )
        }

        pub fun getNFTView(): MetadataViews.NFTView {
            return MetadataViews.NFTView(
                id: self.id,
                uuid : self.uuid,
                display : self.getDisplay(),
                externalURL : TheFabricantKapers.nftMetadata[self.id]!.externalURL,
                collectionData : self.getCollectionData(),
                collectionDisplay : self.getCollectionDisplay(),
                royalties : TheFabricantKapers.nftMetadata[self.id]!.royalties,
                traits: self.getTraits()
            )
        }

        pub fun getViews(): [Type] {
            let viewArray: [Type] = [
                Type<TheFabricantMetadataViewsV2.TFNFTIdentifierV1>(),
                Type<TheFabricantMetadataViewsV2.TFNFTSimpleView>(),
                Type<MetadataViews.NFTView>(),
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Medias>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Traits>()
            ]

            if self.license != nil {
                viewArray.append(Type<MetadataViews.License>())
            }
            if self.getRarity() != nil {
                viewArray.append(Type<MetadataViews.Rarity>())
            }

            return viewArray
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<TheFabricantMetadataViewsV2.TFNFTIdentifierV1>():
                    return TheFabricantMetadataViewsV2.TFNFTIdentifierV1(
                        uuid: self.uuid,
                        id: self.id,
                        name: self.getFullName(),
                        collection: TheFabricantKapers.nftMetadata[self.nftMetadataId]!.collection,
                        editions: self.getEditions(),
                        address: self.owner!.address,
                        originalRecipient: self.originalRecipient,
                    )
                case Type<TheFabricantMetadataViewsV2.TFNFTSimpleView>():
                    return TheFabricantMetadataViewsV2.TFNFTSimpleView(
                        uuid: self.uuid,
                        id: self.id,
                        name: self.getFullName(),
                        description: TheFabricantKapers.nftMetadata[self.nftMetadataId]!.description,
                        collection: TheFabricantKapers.nftMetadata[self.nftMetadataId]!.collection,
                        collectionId: TheFabricantKapers.collectionId!,
                        metadata: self.getMetadata(),
                        media: self.getMedias(),
                        images: self.getImages(),
                        videos: self.getVideos(),
                        externalURL: TheFabricantKapers.nftMetadata[self.id]!.externalURL,
                        rarity: self.getRarity(),
                        traits: self.getTraits(),
                        characteristics: self.getCharacteristics(),
                        coCreatable: TheFabricantKapers.nftMetadata[self.id]!.coCreatable,
                        coCreators: TheFabricantKapers.nftMetadata[self.id]!.coCreator,
                        isRevealed: TheFabricantKapers.nftMetadata[self.id]!.isRevealed,
                        editions: self.getEditions(),
                        originalRecipient: self.originalRecipient,
                        royalties: TheFabricantKapers.nftMetadata[self.id]!.royalties,
                        royaltiesTFMarketplace: TheFabricantKapers.nftMetadata[self.id]!.royaltiesTFMarketplace,
                        revealableTraits: self.getRevealableTraits(),
                        address: self.owner!.address
                    )
                case Type<MetadataViews.NFTView>():
                    return self.getNFTView()
                case Type<MetadataViews.Display>():
                    return self.getDisplay()
                case Type<MetadataViews.Editions>():
                    return self.getEditions()
                case Type<MetadataViews.Serial>():
                    return self.id
                case Type<MetadataViews.Royalties>():
                    return TheFabricantKapers.nftMetadata[self.id]?.royalties
                case Type<MetadataViews.Medias>():
                    return self.getMedias()
                case Type<MetadataViews.License>():
                    return self.license
                case Type<MetadataViews.ExternalURL>():
                    return TheFabricantKapers.nftMetadata[self.id]?.externalURL
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

        pub fun updateIsTraitRevealable(key: String, value: Bool) {
            let nftMetadata = TheFabricantKapers.nftMetadata[self.id]!
            nftMetadata.updateIsTraitRevealable(key: key, value: value)
            TheFabricantKapers.nftMetadata[self.id] = nftMetadata
            emit IsTraitRevealableUpdated(
                nftUuid: nftMetadata.nftUuid, 
                id: nftMetadata.id,
                trait: key,
                isRevealable: value
            )
        }

        init(
            originalRecipient: Address,
            license: MetadataViews.License?
        ) {
            assert(
                TheFabricantKapers.collectionId != nil, 
                message: "Ensure that Admin has set collectionId in the contract"
            )
            
            TheFabricantKapers.totalSupply = TheFabricantKapers.totalSupply + 1
            self.id = TheFabricantKapers.totalSupply
            self.collectionId = TheFabricantKapers.collectionId!

            // NOTE: Customise
            // The edition number may need to be different to id
            // for some campaigns
            self.editionNumber = self.id
            self.maxEditionNumber = TheFabricantKapers.maxSupply

            self.originalRecipient = originalRecipient

            self.license = license

            self.nftMetadataId = self.id

        }
        destroy() {
            emit ItemDestroyed(
                uuid: self.uuid,
                id: self.id,
                name: TheFabricantKapers.nftMetadata[self.nftMetadataId]!.name,
                description: TheFabricantKapers.nftMetadata[self.nftMetadataId]!.description,
                collection: TheFabricantKapers.nftMetadata[self.nftMetadataId]!.collection
            )
        }
    }

    // -----------------------------------------------------------------------
    // Collection Resource
    // -----------------------------------------------------------------------

    pub resource interface TheFabricantKapersCollectionPublic {
        pub fun borrowTheFabricantKapers(id: UInt64): &TheFabricantKapers.NFT{TheFabricantKapers.PublicNFT}?
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT        
    }

    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, TheFabricantKapersCollectionPublic, MetadataViews.ResolverCollection {

        // Dictionary to hold the NFTs in the Collection
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let TheFabricantKapers = nft as! &TheFabricantKapers.NFT
            return TheFabricantKapers as &AnyResource{MetadataViews.Resolver}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            // Remove the nft from the Collection
            let token <- self.ownedNFTs.remove(key: withdrawID) 
                ?? panic("Cannot withdraw: NFT does not exist in the collection")

            emit Withdraw(id: token.id, from: self.owner?.address)
            
            // Return the withdrawn token
            return <-token
        }

        // deposit takes an NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            // By ensuring self.owner.address is not nil we keep the nftIdsToOwner dict 
            // up to date.
            pre {
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
            
            TheFabricantKapers.nftIdsToOwner[id] = self.owner!.address
            emit Deposit(id: id, to: self.owner?.address)

            // Destroy the empty old token that was "removed"
            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // Returns a borrowed reference to an NFT in the collection
        // so that the caller can read data and call methods from it
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowTheFabricantKapers(id: UInt64): &TheFabricantKapers.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &TheFabricantKapers.NFT
            }

            return nil
        }

        // If a transaction destroys the Collection object,
        // All the NFTs contained within are also destroyed!
        //
        destroy() {
            destroy self.ownedNFTs
        }

        init(
        ) {
            self.ownedNFTs <- {}
        }
    }

    // -----------------------------------------------------------------------
    // Admin Resource
    // -----------------------------------------------------------------------

    pub resource Admin {

        pub fun setPublicReceiverCap(paymentReceiverCap: Capability<&{FungibleToken.Receiver}>) {
            TheFabricantKapers.paymentReceiverCap = paymentReceiverCap

            emit AdminPaymentReceiverCapabilityChanged(
                address: paymentReceiverCap.address, 
                paymentType: paymentReceiverCap.getType()
            )
        }

        pub fun setBaseURI(baseURI: String) {
            TheFabricantKapers.baseTokenURI = baseURI

            emit AdminSetBaseURI (
                baseURI: baseURI
            )
        }

        // The max supply determines the maximum number of NFTs that can be minted from this contract
        pub fun setMaxSupply(maxSupply: UInt64) {
            TheFabricantKapers.maxSupply = maxSupply

            emit AdminSetMaxSupply(
                maxSupply: maxSupply 
            )
        }

        pub fun setAddressMintLimit(addressMintLimit: UInt64) {
            TheFabricantKapers.addressMintLimit = addressMintLimit

            emit AdminSetAddressMintLimit(
                addressMintLimit: addressMintLimit 
            )
        }

        pub fun setCollectionId(collectionId: String) {
            TheFabricantKapers.collectionId = collectionId

            emit AdminSetCollectionId(
                collectionId: collectionId 
            )
        }

        pub fun setIsFreeMintActive(isActive: Bool) {
            TheFabricantKapers.isFreeMintActive = isActive

            emit AdminSetIsFreeMintActive(
                isActive: isActive
            )
        }

        //NOTE: Customise
         // mint not:
            // maxSupply has been hit √
            // minting isn't open (!isOpen) √
            // combo has been minted √
        // mint if:
            // openAccess √
            // OR address on access list √
        // Output:
            // NFT √
            // nftMetadata √
            // update mints per address √
        //NOTE: !Used for CC payments via MoonPay!
        pub fun distributeDirectlyViaAccessList(
            receiver: &{NonFungibleToken.CollectionPublic},
            publicMinterPathString: String,
            garmentId: UInt64, 
            materialId: UInt64, 
            primaryColorId: UInt64, 
            secondaryColorId: UInt64
            ) {
                pre {
                    TheFabricantKapers.paymentReceiverCap != nil: "Payment Receiver Cap must be set for minting!"
                    TheFabricantKapers.isFreeMintActive != true: "Cannot mint via CC if free mint is active, please use mintUsingAccessList"
                    !TheFabricantKapers.dataAllocations.containsKey(TheFabricantKapers.constructDataAllocationString(
                    garmentId: garmentId, 
                    materialId: materialId, 
                    primaryColorId: primaryColorId, 
                    secondaryColorId: secondaryColorId
                )): "Combination of characteristics already exists, please choose again" 
                }

            // Ensure that the maximum supply of nfts for this contract has not been hit
            if TheFabricantKapers.maxSupply != nil {
                assert((TheFabricantKapers.totalSupply + 1) <= TheFabricantKapers.maxSupply!, message: "Max supply for NFTs has been hit")
            }

            // Get the publicMinter details so we can apply all the correct props to the NFT
            //NOTE: Therefore relies on a pM having been created
            let publicPath = PublicPath(identifier: publicMinterPathString) ?? panic("Failed to construct public path from path string: ".concat(publicMinterPathString))
            let publicMinterCap = getAccount(self.owner!.address)
            .getCapability(publicPath).borrow<&TheFabricantKapers.PublicMinter{TheFabricantKapers.Minter}>() 
            ?? panic("Couldn't get publicMinter ref or pathString is wrong: ".concat(publicMinterPathString))
            
            let publicMinterDetails = publicMinterCap.getPublicMinterDetails()

            //Confirm that minting is open on the publicMinter
            let isOpen = publicMinterDetails["isOpen"] as! Bool? 
            assert(isOpen!, message: "Minting is not open!")

            let isOpenAccess = publicMinterDetails["isOpenAccess"] as! Bool?
            let accessListId = publicMinterDetails["accessListId"] as! UInt64?

            // Check that it is NOT openAccess and free mint simultaneously
            if isOpenAccess! && TheFabricantKapers.isFreeMintActive {
                panic("There is no public free mint for this collection, free mint is for presale")
            }

            //Check that the address has access via the access list. If isOpenAccess, then anyone can mint.
            if !isOpenAccess! {
                assert(TheFabricantAccessList.checkAccessForAddress(accessListDetailsId: accessListId!, address: receiver.owner!.address), message: "User address is not on the access list and so cannot mint.")
            }
            
            // Create the NFT
            let license = publicMinterDetails["license"] as! MetadataViews.License?
            let nft <- create NFT(
                originalRecipient: receiver.owner!.address,
                license: license
            )

            let name = publicMinterDetails["name"] as! String?
            let collection = publicMinterDetails["collection"] as! String?
            let externalURL = publicMinterDetails["externalURL"] as! MetadataViews.ExternalURL?
            let coCreatable = publicMinterDetails["coCreatable"] as! Bool?
            let revealableTraits = publicMinterDetails["revealableTraits"] as! {String: Bool}?

            //garment.desc is to be used for the NFT desc
            let garment = TheFabricantKapers.garments[garmentId]
            let garmentValue = garment!.value as! {String: String}
            let garmentDescription = garment!.characteristicDescription

            // -- External Royalties

            let externalPublicMinterRoyalties = publicMinterDetails["royalties"] as! MetadataViews.Royalties?

            let externalRoyaltiesArray = externalPublicMinterRoyalties!.getRoyalties()
            let externalRoyalties = MetadataViews.Royalties(cutInfos: externalRoyaltiesArray)

            //-- TF MP Royalties 
            // NOTE: Internal royalties are not added to as there is no CoCreator royalty for this collection
            let internalPublicMinterRoyalties = publicMinterDetails["royaltiesTFMarketplace"] as! TheFabricantMetadataViewsV2.Royalties?
            let internalPublicMinterRoyaltiesArray = internalPublicMinterRoyalties!.getRoyalties()

            let internalRoyalties = TheFabricantMetadataViewsV2.Royalties(cutInfos: internalPublicMinterRoyaltiesArray)
            
            // -- Characteristics

            // Create Characteristics struct
            let characteristics = TheFabricantKapers.createCharacteristics(garmentId: garmentId, materialId: materialId, primaryColorId: primaryColorId, secondaryColorId: secondaryColorId)

            //Update data allocation. This prevents people from minting the same combination
            TheFabricantKapers.updateDataAllocations(
                nftId: nft.id,
                garmentId: garmentId, 
                materialId: materialId, 
                primaryColorId: primaryColorId, 
                secondaryColorId: secondaryColorId
            )

            //Create the nftMetadata
            TheFabricantKapers.createNftMetadata(
                id: nft.id, 
                nftUuid: nft.uuid, 
                name: name!, 
                description: garmentDescription, 
                collection: collection!, 
                characteristics: characteristics, 
                license: nft.license, 
                externalURL: externalURL!, 
                coCreatable: coCreatable!, 
                coCreator: receiver.owner!.address, 
                editionNumber: nft.editionNumber, 
                maxEditionNumber: nft.maxEditionNumber, 
                revealableTraits: revealableTraits!, 
                royalties: externalRoyalties, 
                royaltiesTFMarketplace: internalRoyalties
            ) 

            //NOTE: Event is emitted here and not in nft init because
            // data is split between RevealableMetadata and nft,
            // so not all event data is accessible during nft init
            emit ItemMintedAndTransferred(
                uuid: nft.uuid,
                id: nft.id,
                name: TheFabricantKapers.nftMetadata[nft.nftMetadataId]!.name,
                description: TheFabricantKapers.nftMetadata[nft.nftMetadataId]!.description,
                collection: TheFabricantKapers.nftMetadata[nft.nftMetadataId]!.collection,
                editionNumber: nft.editionNumber,
                originalRecipient: nft.originalRecipient,   
                license: nft.license,
                nftMetadataId: nft.nftMetadataId,
            )

            emit DataAllocationCreated(
                uuid: nft.uuid,
                id: nft.id,
                editionNumber: nft.editionNumber,
                originalRecipient: nft.originalRecipient,
                nftMetadataId: nft.nftMetadataId,
                dataAllocationString: TheFabricantKapers.idsToDataAllocations[nft.nftMetadataId]!
            )

            receiver.deposit(token: <- nft)

            // Increment the number of mints that an address has
            if TheFabricantKapers.addressMintCount[receiver.owner!.address] != nil {
                TheFabricantKapers.addressMintCount[receiver.owner!.address] = TheFabricantKapers.addressMintCount[receiver.owner!.address]! + 1
            } else {
                TheFabricantKapers.addressMintCount[receiver.owner!.address] = 1
            }
        }

        // NOTE: It is in the public minter that you would create the restrictions
        // for minting. 
        pub fun createPublicMinter(
            name: String,
            description: String,
            collection: String,
            license: MetadataViews.License?,
            externalURL: MetadataViews.ExternalURL,
            coCreatable: Bool,
            revealableTraits: {String: Bool},
            minterMintLimit: UInt64?,
            royalties: MetadataViews.Royalties,
            royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties,
            paymentAmount: UFix64,
            paymentType: Type,
            paymentSplit: MetadataViews.Royalties?,
            typeRestrictions: [Type],
            accessListId: UInt64,
        ) {

            pre {
                TheFabricantKapers.baseTokenURI != nil: "Please set a baseURI before creating a minter"
                TheFabricantKapers.materials.length != 0: "Please add materials to the contract"
                TheFabricantKapers.garments.length != 0: "Please add garments to the contract"
                TheFabricantKapers.secondaryColors.length != 0: "Please add secondaryColors to the contract"
                TheFabricantKapers.primaryColors.length != 0: "Please add primaryColors to the contract"
            }

            let publicMinter: @TheFabricantKapers.PublicMinter <- create PublicMinter(
                name: name,
                description: description,
                collection: collection,
                license: license,
                externalURL: externalURL,
                coCreatable: coCreatable,
                revealableTraits: revealableTraits,
                minterMintLimit: minterMintLimit,
                royalties: royalties,
                royaltiesTFMarketplace: royaltiesTFMarketplace,
                paymentAmount: paymentAmount,
                paymentType: paymentType,
                paymentSplit: paymentSplit,
                typeRestrictions: typeRestrictions,
                accessListId: accessListId,
            )

            // Save path: name_collection_uuid
            // Link the Public Minter to a Public Path of the admin account
            let publicMinterStoragePath = StoragePath(identifier: publicMinter.path)
            let publicMinterPublicPath = PublicPath(identifier: publicMinter.path)
            TheFabricantKapers.account.save(<- publicMinter, to: publicMinterStoragePath!)
            TheFabricantKapers.account.link<&PublicMinter{Minter}>(publicMinterPublicPath!, target: publicMinterStoragePath!)
        }

        pub fun revealTraits(nftMetadataId: UInt64, traits: [{RevealableV2.RevealableTrait}]) {
            let nftMetadata = TheFabricantKapers.nftMetadata[nftMetadataId]! as!  TheFabricantKapers.RevealableMetadata
            
            nftMetadata.revealTraits(traits: traits)
            TheFabricantKapers.nftMetadata[nftMetadataId] = nftMetadata

            // Event should be emitted in resource, not struct
            var i = 1
            while i < traits.length {
                let traitName = traits[i].name
                let traitValue = traits[i].value
                emit TraitRevealed(
                    nftUuid: nftMetadata.nftUuid, 
                    id: nftMetadata.id,
                    trait: traitName,
                )
                i = i + 1
            }
            emit ItemRevealed(
                uuid: nftMetadata.nftUuid,
                id: nftMetadata.id,
                name: nftMetadata.name,
                description: nftMetadata.description,
                collection: nftMetadata.collection,
                editionNumber: nftMetadata.editionNumber,
                originalRecipient: nftMetadata.coCreator,   
                license: nftMetadata.license,
                nftMetadataId: nftMetadata.id,
                externalURL: nftMetadata.externalURL,
                coCreatable: nftMetadata.coCreatable,
                coCreator: nftMetadata.coCreator,                 
            )
        }

        // NOTE: Customise
        pub fun updateGarments(shapes: {UInt64: {CoCreatableV2.Characteristic}}) {
            var i: UInt64 = 0
            let keys = shapes.keys
            let values = shapes.values
            while i < UInt64(shapes.length) {
                TheFabricantKapers.garments[keys[i]] = values[i]
                i = i + 1
            }
        }

        // NOTE: Customise
        pub fun emptyGarments() {
            TheFabricantKapers.garments = {}
        }

        // NOTE: Customise
        pub fun updateMaterials(materials: {UInt64: {CoCreatableV2.Characteristic}}) {
            var i: UInt64 = 0
            let keys = materials.keys
            let values = materials.values
            while i < UInt64(materials.length) {
                TheFabricantKapers.materials[keys[i]] = values[i]
                i = i + 1
            }
        }

        // NOTE: Customise
        pub fun emptyMaterials() {
            TheFabricantKapers.materials = {}
        }

        // NOTE: Customise
        pub fun updatePrimaryColors(primaryColors: {UInt64: {CoCreatableV2.Characteristic}}) {
            var i: UInt64 = 0
            let keys = primaryColors.keys
            let values = primaryColors.values
            while i < UInt64(primaryColors.length) {
                TheFabricantKapers.primaryColors[keys[i]] = values[i]
                i = i + 1
            }
        }

        // NOTE: Customise
        pub fun emptyPrimaryColors() {
            TheFabricantKapers.primaryColors = {}
        }

        // NOTE: Customise
        pub fun updateSecondaryColors(secondaryColors: {UInt64: {CoCreatableV2.Characteristic}}) {
            var i: UInt64 = 0
            let keys = secondaryColors.keys
            let values = secondaryColors.values
            while i < UInt64(secondaryColors.length) {
                TheFabricantKapers.secondaryColors[keys[i]] = values[i]
                i = i + 1
            }
        }

        // NOTE: Customise
        pub fun emptySecondaryColors() {
            TheFabricantKapers.secondaryColors = {}
        }

        init(adminAddress: Address) {

            emit AdminResourceCreated(
                uuid: self.uuid,
                adminAddress: adminAddress
            )
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
    pub resource interface Minter {
        pub fun mintUsingAccessList(
            receiver: &{NonFungibleToken.CollectionPublic},
            payment: @FungibleToken.Vault,
            garmentId: UInt64, 
            materialId: UInt64, 
            primaryColorId: UInt64, 
            secondaryColorId: UInt64
        )
        pub fun getPublicMinterDetails(): {String: AnyStruct}
    }

    pub resource PublicMinter: TheFabricantNFTStandardV2.TFNFTPublicMinter, Minter {

        pub var path: String

        pub var isOpen: Bool
        pub var isAccessListOnly: Bool
        pub var isOpenAccess: Bool

        // NOTE: Remove these as required and update the NFT props and 
        // resolveView to reflect this, so that views that this nft
        // does not display are not provided

        // Name of nft, not campaign. This will be combined with the edition number
        pub let name: String
        pub let description: String
        pub let collection: String
        pub let license: MetadataViews.License?
        pub let externalURL: MetadataViews.ExternalURL
        pub let coCreatable: Bool
        pub let revealableTraits: {String: Bool}
        // NOTE: The max number of mints this pM can do (eg multiple NFTs, a different minter for each one. Each NFT has a max number of mints allowed).
        pub var minterMintLimit: UInt64?
        pub var numberOfMints: UInt64
        pub let royalties: MetadataViews.Royalties
        pub let royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties
        pub var paymentAmount: UFix64
        pub let paymentType: Type
        // paymentSplit: How much each address gets paid on minting of NFT
        pub let paymentSplit: MetadataViews.Royalties?
        pub var typeRestrictions: [Type]?   
        pub var accessListId: UInt64     

        pub fun changeIsOpenAccess(isOpenAccess: Bool) {
            self.isOpenAccess = isOpenAccess

            emit PublicMinterIsOpenAccessChanged(
                uuid: self.uuid,
                name: self.name,
                description: self.description,
                collection: self.collection,
                path: self.path,
                isOpenAccess: self.isOpenAccess,
                isAccessListOnly: self.isAccessListOnly,
                isOpen: self.isOpen
            )
        }

        pub fun changeIsAccessListOnly(isAccessListOnly: Bool) {
            self.isAccessListOnly = isAccessListOnly

            emit PublicMinterIsAccessListOnly (
                uuid: self.uuid,
                name: self.name,
                description: self.description,
                collection: self.collection,
                path: self.path,
                isOpenAccess: self.isOpenAccess,
                isAccessListOnly: self.isAccessListOnly,
                isOpen: self.isOpen
             )
        }

        pub fun changeMintingIsOpen(isOpen: Bool) {
            self.isOpen = isOpen

            emit PublicMinterMintingIsOpen(
                uuid: self.uuid,
                name: self.name,
                description: self.description,
                collection: self.collection,
                path: self.path,
                isOpenAccess: self.isOpenAccess,
                isAccessListOnly: self.isAccessListOnly,
                isOpen: self.isOpen
            )
        }

        pub fun setAccessListId(accessListId: UInt64) {
            self.accessListId = accessListId

            emit PublicMinterSetAccessListId(
                uuid: self.uuid,
                name: self.name,
                description: self.description,
                collection: self.collection,
                path: self.path,
                isOpenAccess: self.isOpenAccess,
                isAccessListOnly: self.isAccessListOnly,
                isOpen: self.isOpen,
                accessListId: self.accessListId
            )
        }

        pub fun setPaymentAmount(amount: UFix64) {
            self.paymentAmount = amount

            emit PublicMinterSetPaymentAmount(
                uuid: self.uuid,
                name: self.name,
                description: self.description,
                collection: self.collection,
                path: self.path,
                isOpenAccess: self.isOpenAccess,
                isAccessListOnly: self.isAccessListOnly,
                isOpen: self.isOpen,
                paymentAmount: self.paymentAmount
            )
        }

        pub fun setMinterMintLimit(minterMintLimit: UInt64) {
            self.minterMintLimit = minterMintLimit

            emit PublicMinterSetMinterMintLimit(
                uuid: self.uuid,
                name: self.name,
                description: self.description,
                collection: self.collection,
                path: self.path,
                isOpenAccess: self.isOpenAccess,
                isAccessListOnly: self.isAccessListOnly,
                isOpen: self.isOpen,
                minterMintLimit: self.minterMintLimit
            )
        }

        // The owner of the pM can access this via borrow in tx.
        pub fun updateTypeRestrictions(types: [Type]) {
            self.typeRestrictions = types
        }

        //NOTE: Customise
        // mint not:
            // maxMint for this address has been hit √
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
        pub fun mintUsingAccessList(
            receiver: &{NonFungibleToken.CollectionPublic},
            payment: @FungibleToken.Vault,
            garmentId: UInt64, 
            materialId: UInt64, 
            primaryColorId: UInt64, 
            secondaryColorId: UInt64
        ) {
            pre {
                self.isOpen : "Minting is not currently open!"
                !TheFabricantKapers.dataAllocations.containsKey(TheFabricantKapers.constructDataAllocationString(
                    garmentId: garmentId, 
                    materialId: materialId, 
                    primaryColorId: primaryColorId, 
                    secondaryColorId: secondaryColorId
                )): "Combination of characteristics already exists, please choose again" 
                payment.isInstance(self.paymentType): 
                "payment vault is not requested fungible token"
                payment.balance == (TheFabricantKapers.isFreeMintActive ? 0.0 : self.paymentAmount):
                    "Incorrect payment amount provided for minting"
                TheFabricantKapers.paymentReceiverCap != nil: "Payment Receiver Cap must be set for minting!"
            }
            post {
                receiver.getIDs().length == before(receiver.getIDs().length) + 1
                    : "Minted NFT must be deposited into Collection"
            }
            // Total number of mints by this pM
            self.numberOfMints = self.numberOfMints + 1

            // Free mint checks
            if TheFabricantKapers.isFreeMintActive {
                assert(payment.balance == 0.0, message: "Payment amount must be 0.0 for free mint")
                assert(!TheFabricantKapers.claimedFreeMints.containsKey(receiver.owner!.address), message: "Only one free mint per address is allowed")
                TheFabricantKapers.claimedFreeMints[receiver.owner!.address] = TheFabricantKapers.totalSupply + 1
            }

            // Ensure that minterMintLimit for this pM has not been hit
            if self.minterMintLimit != nil {
                assert(self.numberOfMints <= self.minterMintLimit!, message: "Maximum number of mints for this public minter has been hit")
            }

            // Ensure that the maximum supply of nfts for this contract has not been hit
            if TheFabricantKapers.maxSupply != nil {
                assert((TheFabricantKapers.totalSupply + 1) <= TheFabricantKapers.maxSupply!, message: "Max supply for NFTs has been hit")
            }

            // Ensure user hasn't minted more NFTs from this contract than allowed
            if TheFabricantKapers.addressMintLimit != nil {
                if TheFabricantKapers.addressMintCount[receiver.owner!.address] != nil {
                    assert(TheFabricantKapers.addressMintCount[receiver.owner!.address]! < TheFabricantKapers.addressMintLimit!,
                        message: "User has already minted the maximum allowance per address!")
                }
            }

            // Check that it is NOT openAccess and free mint simultaneously
            if self.isOpenAccess && TheFabricantKapers.isFreeMintActive {
                panic("There is no public free mint for this collection, free mint is for presale")
            }
            
            // Check that the address has access via the access list. If isOpenAccess, then anyone can mint.
           if !self.isOpenAccess {
                assert(TheFabricantAccessList.checkAccessForAddress(accessListDetailsId: self.accessListId, address: receiver.owner!.address), message: "User address is not on the access list and so cannot mint.")
            }

            // Settle Payment
            if let _paymentSplit = self.paymentSplit {
                var i = 0
                let splits = _paymentSplit.getRoyalties()
                while i < splits.length {
                    // If it is a free mint, skip allocating payment splits
                    if (payment.balance == 0.0 && TheFabricantKapers.isFreeMintActive) {
                        i = i + 1
                        break
                    }
                    let split = splits[i]
                    let receiver = split.receiver
                    let cut = split.cut
                    let paymentAmount = self.paymentAmount * cut
                    if let wallet = receiver.borrow() {
                        let pay <- payment.withdraw(amount: paymentAmount)
                        emit MintPaymentSplitDeposited(
                            address: wallet.owner!.address, 
                            price: self.paymentAmount,
                            amount: pay.balance,
                            nftUuid: self.uuid
                        )
                        wallet.deposit(from: <- pay)
                    }
                    i = i + 1
                }
            }
            if payment.balance != 0.0 || payment.balance == 0.0 {
                // pay rest to TF
                emit MintPaymentSplitDeposited(
                            address: TheFabricantKapers.paymentReceiverCap!.address,
                            price: self.paymentAmount,
                            amount: payment.balance,
                            nftUuid: self.uuid
                        )
            }
            // Deposit has to occur outside of above if statement as resource must be moved or destroyed
            TheFabricantKapers.paymentReceiverCap!.borrow()!.deposit(from: <- payment)

            let nft <- create NFT(
                originalRecipient: receiver.owner!.address,
                license: self.license,
            )

            //garment.desc is to be used for the NFT desc
            let garment = TheFabricantKapers.garments[garmentId]
            let garmentValue = garment!.value as! {String: String}
            let garmentDescription = garment!.characteristicDescription

            // - External Royalties

            let externalPublicMinterRoyalties = self.royalties.getRoyalties()

            let externalRoyalties = MetadataViews.Royalties(cutInfos: externalPublicMinterRoyalties)

            // -- TF Internal Royalties
            // NOTE: Internal royalties are not added to as there is no CoCreator royalty for this collection
            let internalPublicMinterRoyalties = self.royaltiesTFMarketplace.getRoyalties()

            let internalRoyalties = TheFabricantMetadataViewsV2.Royalties(cutInfos: internalPublicMinterRoyalties)

            //-- Characteristics

            // Create Characteristics struct
            let characteristics = TheFabricantKapers.createCharacteristics(garmentId: garmentId, materialId: materialId, primaryColorId: primaryColorId, secondaryColorId: secondaryColorId)

            //Update data allocation. This prevents people from minting the same combination
            TheFabricantKapers.updateDataAllocations(
                nftId: nft.id,
                garmentId: garmentId, 
                materialId: materialId, 
                primaryColorId: primaryColorId, 
                secondaryColorId: secondaryColorId
            )

            TheFabricantKapers.createNftMetadata(
                id: nft.id, 
                nftUuid: nft.uuid, 
                name: self.name, 
                description: garmentDescription, 
                collection: self.collection, 
                characteristics: characteristics, 
                license: nft.license, 
                externalURL: self.externalURL, 
                coCreatable: self.coCreatable, 
                coCreator: receiver.owner!.address, 
                editionNumber: nft.editionNumber, 
                maxEditionNumber: nft.maxEditionNumber, 
                revealableTraits: self.revealableTraits, 
                royalties: externalRoyalties, 
                royaltiesTFMarketplace: internalRoyalties
            )

            //NOTE: Event is emitted here and not in nft init because
            // data is split between RevealableMetadata and nft,
            // so not all event data is accessible during nft init
            emit ItemMintedAndTransferred(
                uuid: nft.uuid,
                id: nft.id,
                name: TheFabricantKapers.nftMetadata[nft.nftMetadataId]!.name,
                description: TheFabricantKapers.nftMetadata[nft.nftMetadataId]!.description,
                collection: TheFabricantKapers.nftMetadata[nft.nftMetadataId]!.collection,
                editionNumber: nft.editionNumber,
                originalRecipient: nft.originalRecipient,   
                license: self.license,
                nftMetadataId: nft.nftMetadataId,
            )

            emit DataAllocationCreated(
                uuid: nft.uuid,
                id: nft.id,
                editionNumber: nft.editionNumber,
                originalRecipient: nft.originalRecipient,
                nftMetadataId: nft.nftMetadataId,
                dataAllocationString: TheFabricantKapers.idsToDataAllocations[nft.nftMetadataId]!
            )

            receiver.deposit(token: <- nft)

            // Increment the number of mints that an address has
            if TheFabricantKapers.addressMintCount[receiver.owner!.address] != nil {
                TheFabricantKapers.addressMintCount[receiver.owner!.address] = TheFabricantKapers.addressMintCount[receiver.owner!.address]! + 1
            } else {
                TheFabricantKapers.addressMintCount[receiver.owner!.address] = 1
            }
        }

        pub fun getPublicMinterDetails(): {String: AnyStruct} {
            let ret: {String: AnyStruct} = {}

            ret["name"] = self.name
            ret["uuid"] = self.uuid
            ret["path"] = self.path
            ret["isOpen"] = self.isOpen
            ret["isAccessListOnly"] = self.isAccessListOnly
            ret["isOpenAccess"] = self.isOpenAccess
            ret["description"] = self.description
            ret["collection"] = self.collection
            ret["collectionId"] = TheFabricantKapers.collectionId
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

        init(
            name: String,
            description: String,
            collection: String,
            license: MetadataViews.License?,
            externalURL: MetadataViews.ExternalURL,
            coCreatable: Bool,
            revealableTraits: {String: Bool},
            minterMintLimit: UInt64?,
            royalties: MetadataViews.Royalties,
            royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties,
            paymentAmount: UFix64,
            paymentType: Type,
            paymentSplit: MetadataViews.Royalties?,
            typeRestrictions: [Type],
            accessListId: UInt64,

        ) {

            // Create and save path: name_collection_uuid
            let pathString = "TheFabricantNFTPublicMinter_TheFabricantKapers_".concat(self.uuid.toString())
            TheFabricantKapers.publicMinterPaths[self.uuid] = pathString

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

            emit PublicMinterCreated(
                uuid: self.uuid,
                name: name,
                description: description,
                collection: collection,
                path: self.path
            )
        }
}

    // -----------------------------------------------------------------------
    // Private Utility Functions
    // -----------------------------------------------------------------------

    //NOTE: Customise
    // This function generates the metadata for the minted nft.
    access(contract) fun createNftMetadata(
        id: UInt64,
        nftUuid: UInt64,    
        name: String,
        description: String,
        collection: String,
        characteristics: {String: {CoCreatableV2.Characteristic}},
        license: MetadataViews.License?,
        externalURL: MetadataViews.ExternalURL,
        coCreatable: Bool,
        coCreator: Address,
        editionNumber: UInt64,
        maxEditionNumber: UInt64?,
        revealableTraits: {String: Bool},
        royalties: MetadataViews.Royalties,
        royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties
    ) {
        pre {
            TheFabricantKapers.baseTokenURI != nil: "Ensure baseUri is set before minting!"
        }

        //Instant reveal
        let dataAllocation = TheFabricantKapers.idsToDataAllocations[id]!
        let metadata = {
            "mainImage": TheFabricantKapers.baseTokenURI!
                            .concat("/")
                            .concat(dataAllocation)
                            .concat(".png"),
            "video": TheFabricantKapers.baseTokenURI!
                            .concat("/")
                            .concat(dataAllocation)
                            .concat(".mp4")
        }

        let mD = RevealableMetadata(
            id: id,
            nftUuid: nftUuid,
            name: name,
            description: description,
            collection: collection,
            metadata: metadata,
            characteristics: characteristics,
            license: license,
            externalURL: externalURL,
            coCreatable: coCreatable,
            coCreator: coCreator,
            editionNumber: editionNumber,
            maxEditionNumber: maxEditionNumber,
            revealableTraits: revealableTraits,
            royalties: royalties,
            royaltiesTFMarketplace: royaltiesTFMarketplace,
        )
        TheFabricantKapers.nftMetadata[id] = mD
    }

    //NOTE: Customise
        // This function generates the characteristics data for the minted nft.
        access(contract) fun createCharacteristics(
            garmentId: UInt64, 
            materialId: UInt64, 
            primaryColorId: UInt64, 
            secondaryColorId: UInt64
            ) : {String: {CoCreatableV2.Characteristic}} {
            let dict: {String: {CoCreatableV2.Characteristic}} = {}

            let garment = TheFabricantKapers.garments[garmentId] ?? panic("A garment with this id does not exist")
            dict["garment"] = garment

            let material = TheFabricantKapers.materials[materialId] ?? panic("A material with this id does not exist")
            dict["material"] = material

            let primaryColor = TheFabricantKapers.primaryColors[primaryColorId]?? panic("A primary color with this id does not exist")
            dict["primaryColor"] = primaryColor

            let secondaryColor = TheFabricantKapers.secondaryColors[secondaryColorId]?? panic("A secondary color with this id does not exist")
            dict["secondaryColor"] = secondaryColor
            return dict
        }

    access(self) fun nftsCanBeUsedForMint(
        receiver: &{NonFungibleToken.CollectionPublic},
        refs: [&AnyResource{NonFungibleToken.INFT}],
        typeRestrictions: [Type]
        ): Bool {
        assert(typeRestrictions.length != 0, message: "There are no typerestrictions for this promotion")
        var i = 0 
        while i < refs.length {
            if typeRestrictions.contains(refs[i].getType()) 
                && receiver.owner!.address == refs[i].owner!.address
                {
                return true
            }
            i = i + 1
        }
        return false
    }

    // Used to create the string Ids for checking if combo is taken
    // garment_material_primaryColor_secondaryColor
    access(contract) fun constructDataAllocationString(
        garmentId: UInt64, 
        materialId: UInt64, 
        primaryColorId: UInt64,
        secondaryColorId: UInt64
        ): String {
        return "gar".concat(garmentId.toString())
            .concat("_mat")
            .concat(materialId.toString())
            .concat("_primary")
            .concat(primaryColorId.toString())
            .concat("_secondary")
            .concat(secondaryColorId.toString())
            
    }

    access(contract) fun updateDataAllocations(
        nftId: UInt64, 
        garmentId: UInt64, 
        materialId: UInt64, 
        primaryColorId: UInt64,
        secondaryColorId: UInt64
        ) {
        let allocationString = self.constructDataAllocationString(
            garmentId: garmentId,
            materialId: materialId,
            primaryColorId: primaryColorId,
            secondaryColorId: secondaryColorId,
        )
        self.dataAllocations[allocationString] = nftId
        self.idsToDataAllocations[nftId] = allocationString
    }

    // -----------------------------------------------------------------------
    // Public Utility Functions
    // -----------------------------------------------------------------------

    // createEmptyCollection creates an empty Collection
    // and returns it to the caller so that they can own NFTs
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <-create Collection()
    }

    pub fun getPublicMinterPaths(): {UInt64: String} {
        return TheFabricantKapers.publicMinterPaths
    }

    pub fun getNftIdsToOwner(): {UInt64: Address} {
        return TheFabricantKapers.nftIdsToOwner
    }

    pub fun getMaxSupply(): UInt64? {
        return TheFabricantKapers.maxSupply
    }

    pub fun getTotalSupply(): UInt64 {
        return TheFabricantKapers.totalSupply
    }

    pub fun getCollectionId(): String? {
        return TheFabricantKapers.collectionId
    }

    pub fun getNftMetadatas(): {UInt64: AnyStruct{RevealableV2.RevealableMetadata}} {
        return self.nftMetadata
    }

    pub fun getDataAllocations(): {String: UInt64} {
        return self.dataAllocations
    }

    pub fun getAllIdsToDataAllocations(): {UInt64: String} {
        return self.idsToDataAllocations
    }
    pub fun getIdToDataAllocation(id: UInt64): String? {
        return self.idsToDataAllocations[id]
    }

    pub fun getAllCharacteristics(): AnyStruct {
        let res = {
            "garments": TheFabricantKapers.garments,
            "materials": TheFabricantKapers.materials,
            "primaryColors": TheFabricantKapers.primaryColors,
            "secondaryColors": TheFabricantKapers.secondaryColors    
        }
        return res
    }

    pub fun getBaseUri(): String? {
        return TheFabricantKapers.baseTokenURI
    }

    pub fun getIsFreeMintActive(): Bool {
        return TheFabricantKapers.isFreeMintActive
    }

    pub fun getPaymentCap(): Address? {
        return TheFabricantKapers.paymentReceiverCap?.address
    }

    pub fun getClaimedFreeMints(): {Address: UInt64} {
        return TheFabricantKapers.claimedFreeMints
    }

    // -----------------------------------------------------------------------
    // Contract Init
    // -----------------------------------------------------------------------
    
    init() {
        self.totalSupply = 0
        self.maxSupply = nil
        self.publicMinterPaths = {}
        self.collectionId = nil

        self.nftIdsToOwner = {}
        self.addressMintCount = {}

        self.paymentReceiverCap = nil

        self.nftMetadata = {}

        self.dataAllocations = {}
        self.idsToDataAllocations = {}

        self.addressMintLimit = nil

        self.garments = {}
        self.materials = {}
        self.primaryColors = {}
        self.secondaryColors = {}

        self.baseTokenURI = nil

        self.isFreeMintActive = false
        self.claimedFreeMints = {}

        self.TheFabricantKapersCollectionStoragePath = /storage/TheFabricantKapersCollectionStoragePath
        self.TheFabricantKapersCollectionPublicPath = /public/TheFabricantKapersCollectionPublicPath
        self.TheFabricantKapersProviderPath = /private/TheFabricantKapersProviderPath
        self.TheFabricantKapersAdminStoragePath = /storage/TheFabricantKapersAdminStoragePath
        self.TheFabricantKapersPublicMinterStoragePath = /storage/TheFabricantKapersPublicMinterStoragePath
        self.TheFabricantKapersPublicMinterPublicPath = /public/TheFabricantKapersPublicMinterPublicPath

        self.account.save(<- create Admin(adminAddress: self.account.address), to: self.TheFabricantKapersAdminStoragePath)

        emit ContractInitialized()
    }
}
 