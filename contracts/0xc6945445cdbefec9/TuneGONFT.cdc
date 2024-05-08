import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

// Contract
//
pub contract TuneGONFT: NonFungibleToken {

    // Events
    //
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(
        id: UInt64,
        itemId: String,
        edition: UInt64,
        royalties: [RoyaltyData],
        additionalInfo: {String: String}
    )
    pub event Destroyed(id: UInt64)
    pub event Burned(id: UInt64)
    pub event Claimed(id: UInt64, type: String, recipient: Address, tag: String?)
    pub event ClaimedReward(id: String, recipient: Address)

    // Named Paths
    //
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPrivatePath: PrivatePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    // totalSupply
    // The total number of TuneGONFT that have been minted
    //
    pub var totalSupply: UInt64

    // itemEditions
    //
    access(contract) var itemEditions: {String: UInt64}

    // Default Collection Metadata
    pub struct CollectionMetadata {
        pub let collectionName: String
        pub let collectionDescription: String
        pub let collectionURL: String
        pub let collectionMedia: String
        pub let collectionMediaMimeType: String
        pub let collectionMediaBanner: String?
        pub let collectionMediaBannerMimeType: String?
        pub let collectionSocials: {String:String}

        init(
            collectionName: String,
            collectionDescription: String,
            collectionURL: String,
            collectionMedia: String,
            collectionMediaMimeType: String,
            collectionMediaBanner: String?,
            collectionMediaBannerMimeType: String?,
            collectionSocials: {String:String},
        ) {
            self.collectionName = collectionName
            self.collectionDescription = collectionDescription
            self.collectionURL = collectionURL
            self.collectionMedia = collectionMedia
            self.collectionMediaMimeType = collectionMediaMimeType
            self.collectionMediaBanner = collectionMediaBanner
            self.collectionMediaBannerMimeType = collectionMediaBannerMimeType
            self.collectionSocials = collectionSocials
        }

    }

    pub fun getDefaultCollectionMetadata(): CollectionMetadata {
        let media = "https://www.tunegonft.com/assets/images/tunego-beta-logo.png"
        return TuneGONFT.CollectionMetadata(
            collectionName: "TuneGO NFT",
            collectionDescription: "Unique music collectibles from the TuneGO Community",
            collectionURL: "https://www.tunegonft.com/",
            collectionMedia: media,
            collectionMediaMimeType: "image/png",
            collectionMediaBanner: media,
            collectionMediaBannerMimeType: "image/png",
            collectionSocials: {
                "discord": "https://discord.gg/nsGnsRbMke",
                "facebook": "https://www.facebook.com/tunego",
                "instagram": "https://www.instagram.com/tunego",
                "twitter": "https://twitter.com/TuneGONFT",
                "tiktok": "https://www.tiktok.com/@tunegoadmin?lang=en"
            },
        )
    }

    // Metadata
    //
    pub struct Metadata {
        pub let title: String
        pub let description: String
        pub let creator: String
        pub let asset: String
        pub let assetMimeType: String
        pub let assetHash: String
        pub let artwork: String
        pub let artworkMimeType: String
        pub let artworkHash: String
        pub let artworkAlternate: String?
        pub let artworkAlternateMimeType: String?
        pub let artworkAlternateHash: String?
        pub let thumbnail: String
        pub let thumbnailMimeType: String
        pub let termsUrl: String
        pub let rarity: String?
        pub let credits: String?

        // Collection information
        pub let collectionName: String?
        pub let collectionDescription: String?
        pub let collectionURL: String?
        pub let collectionMedia: String?
        pub let collectionMediaMimeType: String?
        pub let collectionMediaBanner: String?
        pub let collectionMediaBannerMimeType: String?
        pub let collectionSocials: {String:String}?

        // Miscellaneous
        pub let mintedBlock: UInt64
        pub let mintedTime: UFix64

        init(
            title: String,
            description: String,
            creator: String,
            asset: String,
            assetMimeType: String,
            assetHash: String,
            artwork: String,
            artworkMimeType: String,
            artworkHash: String,
            artworkAlternate: String?,
            artworkAlternateMimeType: String?,
            artworkAlternateHash: String?,
            thumbnail: String,
            thumbnailMimeType: String,
            termsUrl: String,
            rarity: String?,
            credits: String?,
            collectionName: String?,
            collectionDescription: String?,
            collectionURL: String?,
            collectionMedia: String?,
            collectionMediaMimeType: String?,
            collectionMediaBanner: String?,
            collectionMediaBannerMimeType: String?,
            collectionSocials: {String:String}?,
            mintedBlock: UInt64,
            mintedTime: UFix64
        ) {

            if collectionName != nil {
                assert(collectionDescription != nil, message: "Missing collectionDescription")
                assert(collectionURL != nil, message: "Missing collectionURL")
                assert(collectionMedia != nil, message: "Missing collectionMedia")
                assert(collectionMediaMimeType != nil, message: "Missing collectionMediaMimeType")
                assert(collectionSocials != nil, message: "Missing collectionSocials")
            }

            self.title = title
            self.description = description
            self.creator = creator
            self.asset = asset
            self.assetMimeType = assetMimeType
            self.assetHash = assetHash
            self.artwork = artwork
            self.artworkMimeType = artworkMimeType
            self.artworkHash = artworkHash
            self.artworkAlternate = artworkAlternate
            self.artworkAlternateMimeType = artworkAlternateMimeType
            self.artworkAlternateHash = artworkAlternateHash
            self.thumbnail = thumbnail
            self.thumbnailMimeType = thumbnailMimeType
            self.termsUrl = termsUrl
            self.credits = credits
            self.rarity = rarity
            self.collectionName = collectionName
            self.collectionDescription = collectionDescription
            self.collectionURL = collectionURL
            self.collectionMedia = collectionMedia
            self.collectionMediaMimeType = collectionMediaMimeType
            self.collectionMediaBanner = collectionMediaBanner
            self.collectionMediaBannerMimeType = collectionMediaBannerMimeType
            self.collectionSocials = collectionSocials
            self.mintedBlock = mintedBlock
            self.mintedTime = mintedTime
        }

        pub fun getCollectionMetadata(): CollectionMetadata {
            if self.collectionName != nil {
                return TuneGONFT.CollectionMetadata(
                    collectionName: self.collectionName!,
                    collectionDescription: self.collectionDescription!,
                    collectionURL: self.collectionURL!,
                    collectionMedia: self.collectionMedia!,
                    collectionMediaMimeType: self.collectionMediaMimeType!,
                    collectionMediaBanner: self.collectionMediaBanner,
                    collectionMediaBannerMimeType: self.collectionMediaBannerMimeType,
                    collectionSocials: self.collectionSocials!,
                )
            }
            return TuneGONFT.getDefaultCollectionMetadata()
        }

        pub fun toDict(): {String: AnyStruct?} {
            let rawMetadata: {String: AnyStruct?} = {}
            rawMetadata.insert(key: "title", self.title)
            rawMetadata.insert(key: "description", self.description)
            rawMetadata.insert(key: "creator", self.creator)
            if(self.asset.length == 0){
                rawMetadata.insert(key: "asset", nil)
                rawMetadata.insert(key: "assetMimeType", nil)
                rawMetadata.insert(key: "assetHash", nil)
            }else{
                rawMetadata.insert(key: "asset", self.asset)
                rawMetadata.insert(key: "assetMimeType", self.assetMimeType)
                rawMetadata.insert(key: "assetHash", self.assetHash)
            }
            rawMetadata.insert(key: "artwork", self.artwork)
            rawMetadata.insert(key: "artworkMimeType", self.artworkMimeType)
            rawMetadata.insert(key: "artworkHash", self.artworkHash)
            rawMetadata.insert(key: "artworkAlternate", self.artworkAlternate)
            rawMetadata.insert(key: "artworkAlternateMimeType", self.artworkAlternateMimeType)
            rawMetadata.insert(key: "artworkAlternateHash", self.artworkAlternateHash)
            rawMetadata.insert(key: "thumbnail", self.thumbnail)
            rawMetadata.insert(key: "thumbnailMimeType", self.thumbnailMimeType)
            rawMetadata.insert(key: "termsUrl", self.termsUrl)
            rawMetadata.insert(key: "rarity", self.rarity)
            rawMetadata.insert(key: "credits", self.credits)

            let collectionSource = self.getCollectionMetadata()
            rawMetadata.insert(key: "collectionName", collectionSource.collectionName)
            rawMetadata.insert(key: "collectionDescription", collectionSource.collectionDescription)
            rawMetadata.insert(key: "collectionURL", collectionSource.collectionURL)
            rawMetadata.insert(key: "collectionMedia", collectionSource.collectionMedia)
            rawMetadata.insert(key: "collectionMediaMimeType", collectionSource.collectionMediaMimeType)
            rawMetadata.insert(key: "collectionMediaBanner", collectionSource.collectionMediaBanner ?? collectionSource.collectionMedia)
            rawMetadata.insert(key: "collectionMediaBannerMimeType", collectionSource.collectionMediaBannerMimeType ?? collectionSource.collectionMediaBannerMimeType)
            rawMetadata.insert(key: "collectionSocials", collectionSource.collectionSocials)

            rawMetadata.insert(key: "mintedBlock", self.mintedBlock)
            rawMetadata.insert(key: "mintedTime", self.mintedTime)
            return rawMetadata
        }

        pub fun toStringDict(): {String: String?} {
            let rawMetadata: {String: String?} = {}
            rawMetadata.insert(key: "title", self.title)
            rawMetadata.insert(key: "description", self.description)
            rawMetadata.insert(key: "creator", self.creator)
            if(self.asset.length == 0){
                rawMetadata.insert(key: "asset", nil)
                rawMetadata.insert(key: "assetMimeType", nil)
                rawMetadata.insert(key: "assetHash", nil)
            }else{
                rawMetadata.insert(key: "asset", self.asset)
                rawMetadata.insert(key: "assetMimeType", self.assetMimeType)
                rawMetadata.insert(key: "assetHash", self.assetHash)
            }
            rawMetadata.insert(key: "artwork", self.artwork)
            rawMetadata.insert(key: "artworkMimeType", self.artworkMimeType)
            rawMetadata.insert(key: "artworkHash", self.artworkHash)
            rawMetadata.insert(key: "artworkAlternate", self.artworkAlternate)
            rawMetadata.insert(key: "artworkAlternateMimeType", self.artworkAlternateMimeType)
            rawMetadata.insert(key: "artworkAlternateHash", self.artworkAlternateHash)
            rawMetadata.insert(key: "thumbnail", self.thumbnail)
            rawMetadata.insert(key: "thumbnailMimeType", self.thumbnailMimeType)
            rawMetadata.insert(key: "termsUrl", self.termsUrl)
            rawMetadata.insert(key: "rarity", self.rarity)
            rawMetadata.insert(key: "credits", self.credits)

            let collectionSource = self.getCollectionMetadata()
            rawMetadata.insert(key: "collectionName", collectionSource.collectionName)
            rawMetadata.insert(key: "collectionDescription", collectionSource.collectionDescription)
            rawMetadata.insert(key: "collectionURL", collectionSource.collectionURL)
            rawMetadata.insert(key: "collectionMedia", collectionSource.collectionMedia)
            rawMetadata.insert(key: "collectionMediaMimeType", collectionSource.collectionMediaMimeType)
            rawMetadata.insert(key: "collectionMediaBanner", collectionSource.collectionMediaBanner ?? collectionSource.collectionMedia)
            rawMetadata.insert(key: "collectionMediaBannerMimeType", collectionSource.collectionMediaBannerMimeType ?? collectionSource.collectionMediaBannerMimeType)

            rawMetadata.insert(key: "mintedBlock", self.mintedBlock.toString())
            rawMetadata.insert(key: "mintedTime", self.mintedTime.toString())

            // Socials
            for key in collectionSource.collectionSocials!.keys {
                rawMetadata.insert(key: "collectionSocials_".concat(key), collectionSource.collectionSocials![key])
            }

            return rawMetadata
        }
    }

    // Edition
    //
    pub struct Edition {
        pub let edition: UInt64
        pub let totalEditions: UInt64

        init(edition: UInt64, totalEditions: UInt64) {
            self.edition = edition
            self.totalEditions = totalEditions
        }
    }

    pub fun editionCirculatingKey(itemId: String): String {
        return "circulating:".concat(itemId)
    }

    // RoyaltyData
    //
    pub struct RoyaltyData {
        pub let receiver: Address
        pub let percentage: UFix64

        init(receiver: Address, percentage: UFix64) {
            self.receiver = receiver
            self.percentage = percentage
        }
    }

    // NFT
    //
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let itemId: String
        pub let edition: UInt64
        access(self) let metadata: Metadata
        access(self) let royalties: [MetadataViews.Royalty]
        access(self) let additionalInfo: {String: String}

        init(
            id: UInt64,
            itemId: String,
            edition: UInt64,
            metadata: Metadata,
            royalties: [MetadataViews.Royalty],
            additionalInfo: {String: String}
        ) {
            self.id = id
            self.itemId = itemId
            self.edition = edition
            self.metadata = metadata
            self.royalties = royalties
            self.additionalInfo = additionalInfo
        }

        pub fun getAdditionalInfo(): {String: String} {
            return self.additionalInfo
        }

        pub fun totalEditions(): UInt64 {
            return TuneGONFT.itemEditions[self.itemId] ?? UInt64(0)
        }

        pub fun circulatingEditions(): UInt64 {
            return TuneGONFT.itemEditions[TuneGONFT.editionCirculatingKey(itemId: self.itemId)] ?? self.totalEditions()
        }

        pub fun getViews(): [Type] {
            return [
                Type<Metadata>(),
                Type<Edition>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<Metadata>():
                    return self.metadata
                case Type<Edition>():
                    return Edition(
                        edition: self.edition,
                        totalEditions: self.totalEditions()
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        self.royalties
                    )
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.metadata.title,
                        description: self.metadata.description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.metadata.thumbnail
                        )
                    )
                case Type<MetadataViews.Editions>():
                    let editionInfo = MetadataViews.Edition(name: "TuneGO NFT", number: self.edition, max: nil)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(
                        editionList
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.edition
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://www.tunegonft.com/view-collectible/".concat(self.uuid.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: TuneGONFT.CollectionStoragePath,
                        publicPath: TuneGONFT.CollectionPublicPath,
                        providerPath: TuneGONFT.CollectionPrivatePath,
                        publicCollection: Type<&TuneGONFT.Collection{TuneGONFT.TuneGONFTCollectionPublic}>(),
                        publicLinkedType: Type<&TuneGONFT.Collection{TuneGONFT.TuneGONFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&TuneGONFT.Collection{TuneGONFT.TuneGONFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-TuneGONFT.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let collectionMetadata = self.metadata.getCollectionMetadata()
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: collectionMetadata.collectionMedia
                        ),
                        mediaType: collectionMetadata.collectionMediaMimeType
                    )
                    let mediaBanner = collectionMetadata.collectionMediaBanner != nil ?
                        MetadataViews.Media(
                            file: MetadataViews.HTTPFile(
                                url: collectionMetadata.collectionMediaBanner!
                            ),
                            mediaType: collectionMetadata.collectionMediaBannerMimeType!
                        )
                        : media
                    let socials: {String:MetadataViews.ExternalURL} = {}
                    for key in collectionMetadata.collectionSocials.keys {
                        socials.insert(key: key,MetadataViews.ExternalURL(collectionMetadata.collectionSocials![key]!))
                    }
                    return MetadataViews.NFTCollectionDisplay(
                        name: collectionMetadata.collectionName,
                        description: collectionMetadata.collectionDescription,
                        externalURL: MetadataViews.ExternalURL(collectionMetadata.collectionURL),
                        squareImage: media,
                        bannerImage: mediaBanner,
                        socials: socials
                    )
                case Type<MetadataViews.Traits>():
                    let excludedTraits = ["mintedTime"]
                    let dict = self.metadata.toDict()
                    dict.forEachKey(fun (key: String): Bool {
                        if (dict[key] == nil) {
                            dict.remove(key: key)
                        }
                        return false
                    })
                    let traitsView = MetadataViews.dictToTraits(dict: self.metadata.toDict(), excludedNames: excludedTraits)

                    // mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
                    let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata.mintedTime!, displayType: "Date", rarity: nil)
                    traitsView.addTrait(mintedTimeTrait)

                    return traitsView
            }

            return nil
        }

        // If the Collectible is destroyed, emit an event
        destroy() {
            emit Destroyed(id: self.id)
        }
    }

    // TuneGONFTCollectionPublic
    //
    pub resource interface TuneGONFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowTuneGONFT(id: UInt64): &TuneGONFT.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow TuneGONFT reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection
    //
    pub resource Collection: TuneGONFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {

        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @TuneGONFT.NFT
            let id: UInt64 = token.id
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowTuneGONFT(id: UInt64): &TuneGONFT.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &TuneGONFT.NFT
            } else {
                return nil
            }
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let tunegoNFT = nft as! &TuneGONFT.NFT
            return tunegoNFT as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }

        init () {
            self.ownedNFTs <- {}
        }
    }

    // createEmptyCollection
    //
    pub fun createEmptyCollection(): @TuneGONFT.Collection {
        return <- create Collection()
    }

    // burnNFTs
    //
    pub fun burnNFTs(nfts: @{UInt64: TuneGONFT.NFT}) {
        let toBurn: Int = nfts.keys.length
        var nftItemID: String? = nil

        for nftID in nfts.keys {
            let nft <- nfts.remove(key: nftID)!
            assert(nft.id == nftID, message: "Invalid nftID")

            nftItemID = nftItemID ?? nft.itemId
            assert(nftItemID == nft.itemId, message: "All burned NFTs must have the same itemID")
            assert(Int64(nft.edition) > Int64(nft.circulatingEditions()) - Int64(toBurn), message: "Invalid NFT edition to burn")

            TuneGONFT.itemEditions[TuneGONFT.editionCirculatingKey(itemId: nftItemID!)] = nft.circulatingEditions() - UInt64(1)

            destroy nft
            emit Burned(id: nftID)
        }

        destroy nfts
    }

    // Claiming
    pub fun claimNFT(nft: @NonFungibleToken.NFT, receiver: &{NonFungibleToken.Receiver}, tag: String?) {
        let id = nft.id
        let type = nft.getType().identifier
        let recipient = receiver.owner?.address ?? panic("Receiver must be owned")

        receiver.deposit(token:<- nft)

        emit Claimed(id: id, type: type, recipient: recipient, tag: tag)
    }

    // NFTMinter
    //
    pub resource NFTMinter {

        access(all) fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            itemId: String,
            metadata: Metadata,
            royalties: [MetadataViews.Royalty],
            additionalInfo: {String: String}
        ) {
            assert(TuneGONFT.itemEditions[TuneGONFT.editionCirculatingKey(itemId: itemId)] == nil, message: "New NFTs cannot be minted")

            var totalRoyaltiesPercentage: UFix64 = 0.0
            let royaltiesData: [RoyaltyData] = []

            for royalty in royalties {
                assert(royalty.receiver.borrow() != nil, message: "Missing royalty receiver")
                let receiverAccount = getAccount(royalty.receiver.address)
                let receiverDUCVaultCapability = receiverAccount.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
                assert(receiverDUCVaultCapability.borrow() != nil, message: "Missing royalty receiver DapperUtilityCoin vault")

                let royaltyPercentage = royalty.cut * 100.0
                royaltiesData.append(RoyaltyData(
                    receiver: receiverAccount.address,
                    percentage: royaltyPercentage
                ))
                totalRoyaltiesPercentage = totalRoyaltiesPercentage + royaltyPercentage;
            }
            assert(totalRoyaltiesPercentage <= 95.0, message: "Total royalties percentage is too high")

            let totalEditions = TuneGONFT.itemEditions[itemId] != nil ? TuneGONFT.itemEditions[itemId] : UInt64(0)
            let edition = totalEditions! + UInt64(1)

            emit Minted(
                id: TuneGONFT.totalSupply,
                itemId: itemId,
                edition: edition,
                royalties: royaltiesData,
                additionalInfo: additionalInfo
            )

            recipient.deposit(token: <-create TuneGONFT.NFT(
                id: TuneGONFT.totalSupply,
                itemId: itemId,
                edition: edition,
                metadata: metadata,
                royalties: royalties,
                additionalInfo: additionalInfo
            ))

            TuneGONFT.itemEditions[itemId] = totalEditions! + UInt64(1)
            TuneGONFT.totalSupply = TuneGONFT.totalSupply + UInt64(1)
        }

        access(all) fun batchMintNFTOld(
            recipient: &{NonFungibleToken.CollectionPublic},
            itemId: String,
            metadata: Metadata,
            royalties: [MetadataViews.Royalty],
            additionalInfo: {String: String},
            quantity: UInt64
        ) {
            var i: UInt64 = 0
            while i < quantity {
                i = i + UInt64(1)
                self.mintNFT(
                    recipient: recipient,
                    itemId: itemId,
                    metadata: metadata,
                    royalties: royalties,
                    additionalInfo: additionalInfo
                )
            }
        }

        access(all) fun batchMintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            itemId: String,
            metadata: Metadata,
            royalties: [MetadataViews.Royalty],
            additionalInfo: {String: String},
            quantity: UInt64
        ) {

            assert(TuneGONFT.itemEditions[TuneGONFT.editionCirculatingKey(itemId: itemId)] == nil, message: "New NFTs cannot be minted")

            var totalRoyaltiesPercentage: UFix64 = 0.0
            let royaltiesData: [RoyaltyData] = []

            for royalty in royalties {
                assert(royalty.receiver.borrow() != nil, message: "Missing royalty receiver")
                let receiverAccount = getAccount(royalty.receiver.address)
                let receiverDUCVaultCapability = receiverAccount.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
                assert(receiverDUCVaultCapability.borrow() != nil, message: "Missing royalty receiver DapperUtilityCoin vault")

                let royaltyPercentage = royalty.cut * 100.0
                royaltiesData.append(RoyaltyData(
                    receiver: receiverAccount.address,
                    percentage: royaltyPercentage
                ))
                totalRoyaltiesPercentage = totalRoyaltiesPercentage + royaltyPercentage;
            }
            assert(totalRoyaltiesPercentage <= 95.0, message: "Total royalties percentage is too high")

            let totalEditions = TuneGONFT.itemEditions[itemId] != nil ? TuneGONFT.itemEditions[itemId]! : UInt64(0)
            var i: UInt64 = 0
            while i < quantity {
                let id = TuneGONFT.totalSupply + i
                i = i + UInt64(1)
                let edition = totalEditions + i

                emit Minted(
                    id: id,
                    itemId: itemId,
                    edition: edition,
                    royalties: royaltiesData,
                    additionalInfo: additionalInfo
                )

                recipient.deposit(token: <-create TuneGONFT.NFT(
                    id: id,
                    itemId: itemId,
                    edition: edition,
                    metadata: metadata,
                    royalties: royalties,
                    additionalInfo: additionalInfo
                ))

            }
            TuneGONFT.itemEditions[itemId] = totalEditions + quantity
            TuneGONFT.totalSupply = TuneGONFT.totalSupply + quantity
        }

        access(all) fun checkIncClaim(id: String, address: Address, max: UInt16): Bool {
            return TuneGONFT.loadMetadataStorage().checkIncClaim(id: id, address: address, max: max)
        }

        access(all) fun readClaims(id: String, addresses: [Address]): {Address: UInt16} {
            let storage = TuneGONFT.loadMetadataStorage()
            let res: {Address: UInt16} = {}
            for address in addresses {
                let claims: {String:UInt16} = storage.claims[address] ?? {}
                res[address] = claims[id] ?? UInt16(0)
            }
            return res
        }

        access(all) fun emitClaimedReward(id: String, address: Address) {
            emit ClaimedReward(id: id, recipient: address)
        }

        pub fun createNFTMinter(): @NFTMinter {
            return <- create NFTMinter()
        }
    }

    pub resource MetadataStorage {
        access(account) let metadatas: {String: Metadata }
        access(account) let royalties: {String: {Address:UFix64} }
        access(account) let claims: {Address: {String:UInt16} }
        access(account) fun setMetadata(id: String, edition: UInt64?, data: Metadata) {
            let fullId = edition == nil ? id : id.concat(edition!.toString())
            if(self.metadatas[fullId] != nil){ return }
            self.metadatas[fullId] = data
        }
        pub fun getMetadata(id: String, edition: UInt64?): Metadata? {
            if edition != nil {
                let perItem = self.metadatas[id.concat(edition!.toString())]
                if perItem != nil { return perItem }
            }
            return self.metadatas[id]
        }
        access(account) fun setRoyalties(id: String, edition: UInt64?, royalties: {Address:UFix64}) {
            let fullId = edition == nil ? id : id.concat(edition!.toString())
            if(self.royalties[fullId] != nil){ return }
            self.royalties[fullId] = royalties
        }
        pub fun getRoyalties(id: String, edition: UInt64?): {Address:UFix64}? {
            if edition != nil {
                let perItem = self.royalties[id.concat(edition!.toString())]
                if perItem != nil { return perItem }
            }
            return self.royalties[id]
        }
        access(account) fun checkIncClaim(id: String, address: Address, max: UInt16): Bool {
             if(self.claims[address] == nil) {
                 self.claims[address] = {}
             }
             let claims = self.claims[address]!
             let prev: UInt16 = claims[id] ?? 0
             if(prev >= max){ return false }
             claims[id] = prev + UInt16(1)
             self.claims[address] = claims
             return true
         }
        init() {
           self.metadatas = {}
           self.royalties = {}
           self.claims = {}
        }
    }

    access(contract) fun loadMetadataStorage(): &MetadataStorage {
        if let existing = self.account.borrow<&MetadataStorage>(from: /storage/metadataStorage) {
            return existing
        }
        let res <- create MetadataStorage()
        let ref = &res as &MetadataStorage
        self.account.save(<-res, to: /storage/metadataStorage)
        return ref
    }

    access(all) fun getMetadata(id: String, edition: UInt64?): Metadata? {
        return TuneGONFT.loadMetadataStorage().getMetadata(id: id, edition: edition)
    }

    init () {
        self.CollectionStoragePath = /storage/tunegoNFTCollection
        self.CollectionPrivatePath = /private/tunegoNFTCollection
        self.CollectionPublicPath = /public/tunegoNFTCollection
        self.MinterStoragePath = /storage/tunegoNFTMinter

        self.totalSupply = 0
        self.itemEditions = {}

        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}
