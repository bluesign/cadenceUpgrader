import TheFabricantMetadataViewsV2 from "./TheFabricantMetadataViewsV2.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import TheFabricantNFTStandardV2 from "./TheFabricantNFTStandardV2.cdc"
import RevealableV2 from "./RevealableV2.cdc"
import CoCreatableV2 from "./CoCreatableV2.cdc"
import TheFabricantAccessList from "./TheFabricantAccessList.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

pub contract Weekday: NonFungibleToken, TheFabricantNFTStandardV2, RevealableV2 {

    // -----------------------------------------------------------------------
    // Paths
    // -----------------------------------------------------------------------

    pub let WeekdayCollectionStoragePath: StoragePath
    pub let WeekdayCollectionPublicPath: PublicPath
    pub let WeekdayProviderStoragePath: PrivatePath
    pub let WeekdayPublicMinterStoragePath: StoragePath 
    pub let WeekdayAdminStoragePath: StoragePath
    pub let WeekdayPublicMinterPublicPath: PublicPath

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

    pub event IsTraitRevealableV2Updated(
        nftUuid: UInt64, 
        id: UInt64,
        trait: String,
        isRevealableV2: Bool
    )

    pub event MintPaymentSplitDeposited(
        address: Address,
        price: UFix64,
        amount: UFix64,
        nftUuid: UInt64
    )

    pub event ItemDestroyed(
        uuid: UInt64,
        id: UInt64,
        name: String,
        description: String,
        collection: String,
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

    access(contract) var baseTokenURI: String?

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
        
        // NOTE: Name of NFT. 
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

        // This is where the user-chosed characteristics live. This represents
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
            //TODO: This is dependent upon what will be saved in this specific campaign
            // nft.
            var i = 0
            while i < traits.length {
                let RevealableTrait = traits[i]
                let traitName = RevealableTrait.name
                let traitValue = RevealableTrait.value

                switch(traitName) {
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

        access(contract) fun updateMetadata(key: String, value: AnyStruct) {
            self.metadata[key] = value
        }

        // Called by the nft owner to modify if a trait can be 
        // revealed or not - used to revoke admin access
        pub fun updateIsTraitRevealable(key: String, value: Bool) {
            self.revealableTraits[key] = value
        }

        pub fun checkRevealableTrait(traitName: String): Bool? {
            if let RevealableV2 = self.revealableTraits[traitName] {
                return RevealableV2
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
    // NFT Resource
    // -----------------------------------------------------------------------

    // Restricted scope for borrowWeekday() in Collection.
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
        
        // NOTE: Ensure that the name for the nft is correct. This 
        // will be shown to users. It should not include the edition number.

        access(contract) let collectionId: String

        access(contract) let editionNumber: UInt64 //Edition
        access(contract) let maxEditionNumber: UInt64?

        access(contract) let originalRecipient: Address

        access(contract) let license: MetadataViews.License?

        access(contract) let nftMetadataId: UInt64

        pub fun getFullName(): String {
            return Weekday.nftMetadata[self.nftMetadataId]!.name!.concat(" #".concat(self.editionNumber.toString()))
        }

        // NOTE: This is important for Edition view
        pub fun getEditionName(): String {
            return Weekday.nftMetadata[self.nftMetadataId]!.collection
        }

        pub fun getEditions(): MetadataViews.Editions {
            // NOTE: In this case, id == edition number
            let edition = MetadataViews.Edition(
                name: Weekday.nftMetadata[self.nftMetadataId]!.collection,
                number: self.editionNumber,
                max: Weekday.maxSupply
            )

            return MetadataViews.Editions(
                infoList: [edition]
            )
        }

        //NOTE: Customise
        //NOTE: This will be different for each campaign, determined by how
        // many media files there are and their keys in metadata! Pay attention
        // to where the media files are stored and therefore accessed
        pub fun getMedias(): MetadataViews.Medias {
            let nftMetadata = Weekday.nftMetadata[self.id]!
            let mainImage = nftMetadata.metadata["mainImage"]! as! String
            // NOTE: This assumes that when the shoeShape characteristic is created
            // in the update_shoe_shapes_char tx, the value property is created as a dictionary
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
            let nftMetadata = Weekday.nftMetadata[self.id]!
            let mainImage = nftMetadata.metadata["mainImage"]! as! String
            return {
                "mainImage": mainImage
            }
        }

        // NOTE: Customise
        pub fun getVideos(): {String: String} {
            let nftMetadata = Weekday.nftMetadata[self.id]!
            let mainVideo = nftMetadata.metadata["video"]! as! String
            return {
                "mainVideo": mainVideo
            }
        }

        // NOTE: Customise
        // What are the traits that you want external marketplaces
        // to display?
        pub fun getTraits(): MetadataViews.Traits? {
            return nil
        }

        pub fun getRarity(): MetadataViews.Rarity? {
            return nil
        }

        pub fun getExternalRoyalties(): MetadataViews.Royalties {
            let nftMetadata = Weekday.nftMetadata[self.id]!
            return nftMetadata.royalties
        }

        pub fun getTFRoyalties(): TheFabricantMetadataViewsV2.Royalties {
            let nftMetadata = Weekday.nftMetadata[self.id]!
            return nftMetadata.royaltiesTFMarketplace
        }

        pub fun getMetadata(): {String: AnyStruct} {
            return Weekday.nftMetadata[self.id]!.metadata
        }

        //NOTE: This is not a CoCreatableV2 NFT, so no characteristics are present
        pub fun getCharacteristics(): {String: {CoCreatableV2.Characteristic}}? {
            return nil
        }

        pub fun getRevealableTraits(): {String: Bool}? {
            return Weekday.nftMetadata[self.id]!.getRevealableTraits()
        }


        //NOTE: The first file in medias will be the thumbnail.
        // Maybe put a file type check in here to ensure it is 
        // an image?
        pub fun getDisplay(): MetadataViews.Display {
            return MetadataViews.Display(
                name: self.getFullName(),
                description: Weekday.nftMetadata[self.nftMetadataId]!.description,
                thumbnail: self.getMedias().items[0].file
            )
        }

        pub fun getCollectionData(): MetadataViews.NFTCollectionData {
            return MetadataViews.NFTCollectionData(
                storagePath: Weekday.WeekdayCollectionStoragePath,
                publicPath: Weekday.WeekdayCollectionPublicPath,
                providerPath: Weekday.WeekdayProviderStoragePath,
                publicCollection: Type<&Weekday.Collection{Weekday.WeekdayCollectionPublic, MetadataViews.ResolverCollection}>(),
                publicLinkedType: Type<&Weekday.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, Weekday.WeekdayCollectionPublic, MetadataViews.ResolverCollection}>(),
                providerLinkedType: Type<&Weekday.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, WeekdayCollectionPublic}>(),
                createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-Weekday.createEmptyCollection()
                })
            )
        }

        //NOTE: Customise
        // NOTE: Update this function with the collection display image
        // and TF socials
        pub fun getCollectionDisplay(): MetadataViews.NFTCollectionDisplay {
            let squareImage = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://weekday-collection-display.s3.eu-central-1.amazonaws.com/images/WD_squareImage.png"
                        ),
                        mediaType: "image/png"
                    )
            let bannerImage = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://weekday-collection-display.s3.eu-central-1.amazonaws.com/images/WD_bannerImage.jpeg"
                        ),
                        mediaType: "image/png"
                    )
            return MetadataViews.NFTCollectionDisplay(
                        name: self.getEditionName(),
                        description: "Enter Artifact 001, a limited-edition collection of digital collectibles complete with AR filters, and physical accessories for the citizens of tomorrow. The items, inspired by mineral formations, are part of a collab between Weekday and digital fashion house The Fabricant. Consider them locked in time, always remaining as they find their way to new owners. Make your move now, history doesn’t wait.",
                        externalURL: Weekday.nftMetadata[self.id]!.externalURL,
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
                externalURL : Weekday.nftMetadata[self.id]!.externalURL,
                collectionData : self.getCollectionData(),
                collectionDisplay : self.getCollectionDisplay(),
                royalties : Weekday.nftMetadata[self.id]!.royalties,
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
                        collection: Weekday.nftMetadata[self.nftMetadataId]!.collection,
                        editions: self.getEditions(),
                        address: self.owner!.address,
                        originalRecipient: self.originalRecipient,
                    )
                case Type<TheFabricantMetadataViewsV2.TFNFTSimpleView>():
                    return TheFabricantMetadataViewsV2.TFNFTSimpleView(
                        uuid: self.uuid,
                        id: self.id,
                        name: self.getFullName(),
                        description: Weekday.nftMetadata[self.nftMetadataId]!.description,
                        collection: Weekday.nftMetadata[self.nftMetadataId]!.collection,
                        collectionId: Weekday.collectionId!,
                        metadata: self.getMetadata(),
                        media: self.getMedias(),
                        images: self.getImages(),
                        videos: self.getVideos(),
                        externalURL: Weekday.nftMetadata[self.id]!.externalURL,
                        rarity: self.getRarity(),
                        traits: self.getTraits(),
                        characteristics: self.getCharacteristics(),
                        coCreatable: Weekday.nftMetadata[self.id]!.coCreatable,
                        coCreators: Weekday.nftMetadata[self.id]!.coCreator,
                        isRevealed: Weekday.nftMetadata[self.id]!.isRevealed,
                        editions: self.getEditions(),
                        originalRecipient: self.originalRecipient,
                        royalties: Weekday.nftMetadata[self.id]!.royalties,
                        royaltiesTFMarketplace: Weekday.nftMetadata[self.id]!.royaltiesTFMarketplace,
                        RevealableTraits: self.getRevealableTraits(),
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
                    return Weekday.nftMetadata[self.id]?.royalties
                case Type<MetadataViews.Medias>():
                    return self.getMedias()
                case Type<MetadataViews.License>():
                    return self.license
                case Type<MetadataViews.ExternalURL>():
                    return Weekday.nftMetadata[self.id]?.externalURL
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
            let nftMetadata = Weekday.nftMetadata[self.id]!
            nftMetadata.updateIsTraitRevealable(key: key, value: value)
            Weekday.nftMetadata[self.id] = nftMetadata
            emit IsTraitRevealableV2Updated(
                nftUuid: nftMetadata.nftUuid, 
                id: nftMetadata.id,
                trait: key,
                isRevealableV2: value
            )
        }

        init(
            originalRecipient: Address,
            license: MetadataViews.License?
        ) {
            assert(
                Weekday.collectionId != nil, 
                message: "Ensure that Admin has set collectionId in the contract"
            )
            
            Weekday.totalSupply = Weekday.totalSupply + 1
            self.id = Weekday.totalSupply
            self.collectionId = Weekday.collectionId!

            // NOTE: Customise
            // The edition number may need to be different to id
            // for some campaigns
            self.editionNumber = self.id
            self.maxEditionNumber = Weekday.maxSupply

            self.originalRecipient = originalRecipient

            self.license = license

            self.nftMetadataId = self.id

        }
        destroy() {
            emit ItemDestroyed(
                uuid: self.uuid,
                id: self.id,
                name: Weekday.nftMetadata[self.nftMetadataId]!.name,
                description: Weekday.nftMetadata[self.nftMetadataId]!.description,
                collection: Weekday.nftMetadata[self.nftMetadataId]!.collection
            )
        }
    }

    // -----------------------------------------------------------------------
    // Collection Resource
    // -----------------------------------------------------------------------

    pub resource interface WeekdayCollectionPublic {
        pub fun borrowWeekday(id: UInt64): &Weekday.NFT{Weekday.PublicNFT}?
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT        
    }

    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, WeekdayCollectionPublic, MetadataViews.ResolverCollection {

        // Dictionary to hold the NFTs in the Collection
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let Weekday = nft as! &Weekday.NFT
            return Weekday as &AnyResource{MetadataViews.Resolver}
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
            
            Weekday.nftIdsToOwner[id] = self.owner!.address
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

        pub fun borrowWeekday(id: UInt64): &Weekday.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Weekday.NFT
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
            Weekday.paymentReceiverCap = paymentReceiverCap

            emit AdminPaymentReceiverCapabilityChanged(
                address: paymentReceiverCap.address, 
                paymentType: paymentReceiverCap.getType()
            )
        }

        pub fun setBaseURI(baseURI: String) {
            Weekday.baseTokenURI = baseURI

            emit AdminSetBaseURI (
                baseURI: baseURI
            )
        }

        // The max supply determines the maximum number of NFTs that can be minted from this contract
        pub fun setMaxSupply(maxSupply: UInt64) {
            Weekday.maxSupply = maxSupply

            emit AdminSetMaxSupply(
                maxSupply: maxSupply 
            )
        }

        pub fun setAddressMintLimit(addressMintLimit: UInt64) {
            Weekday.addressMintLimit = addressMintLimit

            emit AdminSetAddressMintLimit(
                addressMintLimit: addressMintLimit 
            )
        }

        pub fun setCollectionId(collectionId: String) {
            Weekday.collectionId = collectionId

            emit AdminSetCollectionId(
                collectionId: collectionId 
            )
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
        pub fun distributeDirectlyViaAccessList(
            receiver: &{NonFungibleToken.CollectionPublic},
            publicMinterPathString: String,
            variantId: UInt64
            ) {

            // Ensure that the maximum supply of nfts for this contract has not been hit
            if Weekday.maxSupply != nil {
                assert((Weekday.totalSupply + 1) <= Weekday.maxSupply!, message: "Max supply for NFTs has been hit")
            }

            // Get the publicMinter details so we can apply all the correct props to the NFT
            //NOTE: Therefore relies on a pM having been created
            let publicPath = PublicPath(identifier: publicMinterPathString) ?? panic("Failed to construct public path from path string: ".concat(publicMinterPathString))
            let publicMinterCap = getAccount(self.owner!.address)
            .getCapability(publicPath).borrow<&Weekday.PublicMinter{Weekday.Minter}>() 
            ?? panic("Couldn't get publicMinter ref or pathString is wrong: ".concat(publicMinterPathString))
            
            let publicMinterDetails = publicMinterCap.getPublicMinterDetails()

            //Confirm that minting is open on the publicMinter
            let isOpen = publicMinterDetails["isOpen"] as! Bool? 
            assert(isOpen!, message: "Minting is not open!")

            //Check that the address has access via the access list. If isOpenAccess, then anyone can mint.
            let isOpenAccess = publicMinterDetails["isOpenAccess"] as! Bool?
            let accessListId = publicMinterDetails["accessListId"] as! UInt64?
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
            let description = publicMinterDetails["description"] as! String?
            let collection = publicMinterDetails["collection"] as! String?
            let externalURL = publicMinterDetails["externalURL"] as! MetadataViews.ExternalURL?
            let coCreatable = publicMinterDetails["coCreatable"] as! Bool?
            let revealableTraits = publicMinterDetails["revealableTraits"] as! {String: Bool}?
            let royalties = publicMinterDetails["royalties"] as! MetadataViews.Royalties?
            let royaltiesTFMarketplace = publicMinterDetails["royaltiesTFMarketplace"] as! TheFabricantMetadataViewsV2.Royalties?

            //Create the nftMetadata
            Weekday.createNftMetadata(
                id: nft.id, 
                nftUuid: nft.uuid, 
                variantId: variantId,
                name: name!, 
                description: description!, 
                collection: collection!, 
                characteristics: {}, 
                license: nft.license, 
                externalURL: externalURL!, 
                coCreatable: coCreatable!, 
                coCreator: receiver.owner!.address, 
                editionNumber: nft.editionNumber, 
                maxEditionNumber: nft.maxEditionNumber, 
                revealableTraits: revealableTraits!, 
                royalties: royalties!, 
                royaltiesTFMarketplace: royaltiesTFMarketplace!
            ) 

            //NOTE: Event is emitted here and not in nft init because
            // data is split between RevealableMetadata and nft,
            // so not all event data is accessible during nft init
            emit ItemMintedAndTransferred(
                uuid: nft.uuid,
                id: nft.id,
                name: Weekday.nftMetadata[nft.nftMetadataId]!.name,
                description: Weekday.nftMetadata[nft.nftMetadataId]!.description,
                collection: Weekday.nftMetadata[nft.nftMetadataId]!.collection,
                editionNumber: nft.editionNumber,
                originalRecipient: nft.originalRecipient,   
                license: nft.license,
                nftMetadataId: nft.nftMetadataId,
            )
            receiver.deposit(token: <- nft)

            // Increment the number of mints that an address has
            if Weekday.addressMintCount[receiver.owner!.address] != nil {
                Weekday.addressMintCount[receiver.owner!.address] = Weekday.addressMintCount[receiver.owner!.address]! + 1
            } else {
                Weekday.addressMintCount[receiver.owner!.address] = 1
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
                Weekday.paymentReceiverCap != nil: 
                    "Please set the paymentReceiverCap before creating a minter"
            }

            let publicMinter: @Weekday.PublicMinter <- create PublicMinter(
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
            Weekday.account.save(<- publicMinter, to: publicMinterStoragePath!)
            Weekday.account.link<&PublicMinter{Minter}>(publicMinterPublicPath!, target: publicMinterStoragePath!)
        }

        pub fun revealTraits(nftMetadataId: UInt64, traits: [{RevealableV2.RevealableTrait}]) {
            let nftMetadata = Weekday.nftMetadata[nftMetadataId]! as!  Weekday.RevealableMetadata
            
            nftMetadata.revealTraits(traits: traits)
            Weekday.nftMetadata[nftMetadataId] = nftMetadata

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
            variantId: UInt64
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
            // minterMintLimit is hit √
        // mint if:
            // openAccess √
            // OR address on access list √
        // Output:
            // NFT √
            // nftMetadata √
            // update mints per address √
        pub fun mintUsingAccessList(
            receiver: &{NonFungibleToken.CollectionPublic},
            payment: @FungibleToken.Vault,
            variantId: UInt64
        ) {
            pre {
                self.isOpen : "Minting is not currently open!"
                payment.isInstance(self.paymentType): 
                "payment vault is not requested fungible token"
                payment.balance == self.paymentAmount:
                    "Incorrect payment amount provided for minting"
                Weekday.paymentReceiverCap != nil: "Payment Receiver Cap must be set for minting!"
            }
            post {
                receiver.getIDs().length == before(receiver.getIDs().length) + 1
                    : "Minted NFT must be deposited into Collection"
            }
            
            // Total number of mints by this pM
            self.numberOfMints = self.numberOfMints + 1

            // Ensure that minterMintLimit for this pM has not been hit
            if self.minterMintLimit != nil {
                assert(self.numberOfMints <= self.minterMintLimit!, message: "Maximum number of mints for this public minter has been hit")
            }

            // Ensure that the maximum supply of nfts for this contract has not been hit
            if Weekday.maxSupply != nil {
                assert((Weekday.totalSupply + 1) <= Weekday.maxSupply!, message: "Max supply for NFTs has been hit")
            }

            // Ensure user hasn't minted more NFTs from this contract than allowed
            if Weekday.addressMintLimit != nil {
                if Weekday.addressMintCount[receiver.owner!.address] != nil {
                    assert(Weekday.addressMintCount[receiver.owner!.address]! < Weekday.addressMintLimit!,
                        message: "User has already minted the maximum allowance per address!")
                }
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
                            address: Weekday.paymentReceiverCap!.address,
                            price: self.paymentAmount,
                            amount: payment.balance,
                            nftUuid: self.uuid
                        )
            }
            // Deposit has to occur outside of above if statement as resource must be moved or destroyed
            Weekday.paymentReceiverCap!.borrow()!.deposit(from: <- payment)

            let nft <- create NFT(
                originalRecipient: receiver.owner!.address,
                license: self.license,
            )

            Weekday.createNftMetadata(
                id: nft.id, 
                nftUuid: nft.uuid, 
                variantId: variantId,
                name: self.name, 
                description: self.description, 
                collection: self.collection, 
                characteristics: {}, 
                license: nft.license, 
                externalURL: self.externalURL, 
                coCreatable: self.coCreatable, 
                coCreator: receiver.owner!.address, 
                editionNumber: nft.editionNumber, 
                maxEditionNumber: nft.maxEditionNumber, 
                revealableTraits: self.revealableTraits, 
                royalties: self.royalties, 
                royaltiesTFMarketplace: self.royaltiesTFMarketplace
            )

            //NOTE: Event is emitted here and not in nft init because
            // data is split between RevealableMetadata and nft,
            // so not all event data is accessible during nft init
            emit ItemMintedAndTransferred(
                uuid: nft.uuid,
                id: nft.id,
                name: Weekday.nftMetadata[nft.nftMetadataId]!.name,
                description: Weekday.nftMetadata[nft.nftMetadataId]!.description,
                collection: Weekday.nftMetadata[nft.nftMetadataId]!.collection,
                editionNumber: nft.editionNumber,
                originalRecipient: nft.originalRecipient,   
                license: self.license,
                nftMetadataId: nft.nftMetadataId,
            )

            receiver.deposit(token: <- nft)

            // Increment the number of mints that an address has
            if Weekday.addressMintCount[receiver.owner!.address] != nil {
                Weekday.addressMintCount[receiver.owner!.address] = Weekday.addressMintCount[receiver.owner!.address]! + 1
            } else {
                Weekday.addressMintCount[receiver.owner!.address] = 1
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
            ret["collectionId"] = Weekday.collectionId
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
            let pathString = "TheFabricantNFTPublicMinter_Weekday_".concat(self.uuid.toString())
            Weekday.publicMinterPaths[self.uuid] = pathString

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
            variantId: UInt64,
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
                Weekday.baseTokenURI != nil: "Base URI must be set to mint an NFT!"
                variantId == 1 || variantId == 2: "Variant ID must be either 1 or 2"
            }
            var nftName: String = ""
            var nftDescription: String = ""
            var metadata: {String: String} = {}
            switch variantId {
                case 1:
                    nftName = "Dark Stalactite"
                    nftDescription = "Molded in the shade, headed into the unknown. Dark stalactite is a powerful collectible eager to unfold its full AR-potential when the owner decides to. Respond to it."
                    metadata = {
                        "mainImage": Weekday.baseTokenURI!.concat("/DarkStalactite.png"),
                        "video": Weekday.baseTokenURI!.concat("/DarkStalactite.mp4")
                    }
                case 2: 
                    nftName = "Light Stalactite"
                    nftDescription = "Born to deflect harmful rays and betraying looks. Light stalactite will enhance the everyday life of its owner with just the right amount of AR-magic."
                    metadata = {
                        "mainImage": Weekday.baseTokenURI!.concat("/LightStalactite.png"),
                        "video": Weekday.baseTokenURI!.concat("/LightStalactite.mp4")
                    }
            }

            let mD = RevealableMetadata(
                id: id,
                nftUuid: nftUuid,
                name: nftName,
                description: nftDescription,
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
            Weekday.nftMetadata[id] = mD
        }

        access(self) fun nftsCanBeUsedForMint(
            receiver: &{NonFungibleToken.CollectionPublic},
            refs: [&AnyResource{NonFungibleToken.INFT}],
            typeRestrictions: [Type]
            ): Bool {

            assert(typeRestrictions.length != 0, message: "There are no type restrictions for this promotion")
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

    // -----------------------------------------------------------------------
    // Public Utility Functions
    // -----------------------------------------------------------------------

    // createEmptyCollection creates an empty Collection
    // and returns it to the caller so that they can own NFTs
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <-create Collection()
    }

    pub fun getPublicMinterPaths(): {UInt64: String} {
        return Weekday.publicMinterPaths
    }

    pub fun getNftIdsToOwner(): {UInt64: Address} {
        return Weekday.nftIdsToOwner
    }

    pub fun getMaxSupply(): UInt64? {
        return Weekday.maxSupply
    }

     pub fun getTotalSupply(): UInt64 {
        return Weekday.totalSupply
    }

    pub fun getCollectionId(): String? {
        return Weekday.collectionId
    }

    pub fun getNftMetadatas(): {UInt64: AnyStruct{RevealableV2.RevealableMetadata}} {
        return self.nftMetadata
    }

    pub fun getPaymentCap(): Address? {
        return Weekday.paymentReceiverCap?.address
    }

    pub fun getBaseUri(): String? {
        return Weekday.baseTokenURI
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

        self.addressMintLimit = nil

        self.baseTokenURI = nil

        self.WeekdayCollectionStoragePath = /storage/WeekdayCollectionStoragePath
        self.WeekdayCollectionPublicPath = /public/WeekdayCollectionPublicPath
        self.WeekdayProviderStoragePath = /private/WeekdayProviderStoragePath
        self.WeekdayAdminStoragePath = /storage/WeekdayAdminStoragePath
        self.WeekdayPublicMinterStoragePath = /storage/WeekdayPublicMinterStoragePath
        self.WeekdayPublicMinterPublicPath = /public/WeekdayPublicMinterPublicPath

        self.account.save(<- create Admin(adminAddress: self.account.address), to: self.WeekdayAdminStoragePath)

        emit ContractInitialized()
    }
}
 