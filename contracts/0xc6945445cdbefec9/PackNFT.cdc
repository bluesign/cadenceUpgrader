import Crypto
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract PackNFT: NonFungibleToken {

    pub var totalSupply: UInt64
    pub let itemEditions: {UInt64: UInt32}
    pub var version: String
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let CollectionPrivatePath: PrivatePath
    pub var CollectionPublicType: Type
    pub var CollectionPrivateType: Type
    pub let OperatorStoragePath: StoragePath
    pub let OperatorPrivPath: PrivatePath

    pub var defaultCollectionMetadata: CollectionMetadata?
    access(contract) let itemMetadata: {String: Metadata}
    access(contract) let itemCollectionMetadata: {String: CollectionMetadata}

    pub var metadataOpenedWarning: String

    // representation of the NFT in this contract to keep track of states
    access(contract) let packs: @{UInt64: Pack}

    pub event RevealRequest(id: UInt64, openRequest: Bool)
    pub event OpenRequest(id: UInt64)
    pub event Revealed(id: UInt64, salt: String, nfts: String)
    pub event Opened(id: UInt64)
    pub event MetadataUpdated(distId: UInt64, edition: UInt32?, metadata: Metadata)
    pub event CollectionMetadataUpdated(distId: UInt64, edition: UInt32?, metadata: CollectionMetadata)
    pub event Mint(id: UInt64, edition: UInt32, commitHash: String, distId: UInt64, nftCount: UInt16?, lockTime: UFix64?, additionalInfo: {String: String}?)
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub enum Status: UInt8 {
        pub case Sealed
        pub case Revealed
        pub case Opened
    }

    pub resource interface IOperator {
        pub fun setMetadata(
            distId: UInt64,
            edition: UInt32?,
            metadata: Metadata,
            overwrite: Bool
         )
         pub fun setCollectionMetadata(
             distId: UInt64,
             edition: UInt32?,
             metadata: CollectionMetadata,
             overwrite: Bool
          )
         pub fun mint(
            distId: UInt64,
            additionalInfo: {String: String}?,
            commitHash: String,
            issuer: Address,
            nftCount: UInt16?,
            lockTime: UFix64?
         ): @NFT
        pub fun reveal(id: UInt64, nfts: [&NonFungibleToken.NFT], salt: String)
        pub fun open(id: UInt64, nfts: [&NonFungibleToken.NFT])
    }

    pub resource PackNFTOperator: IOperator {

         pub fun setMetadata(
            distId: UInt64,
            edition: UInt32?,
            metadata: Metadata,
            overwrite: Bool
         ) {
            let fullId = edition != nil ? distId.toString().concat(":").concat(edition!.toString()) : distId.toString()
            if !overwrite && PackNFT.itemMetadata[fullId] != nil {
                return
            }
            PackNFT.itemMetadata[fullId] = metadata
            emit MetadataUpdated(distId: distId, edition: edition, metadata: metadata)

         }

         pub fun setCollectionMetadata(
            distId: UInt64,
            edition: UInt32?,
            metadata: CollectionMetadata,
            overwrite: Bool
         ) {
            let fullId = edition != nil ? distId.toString().concat(":").concat(edition!.toString()) : distId.toString()
            if !overwrite && PackNFT.itemCollectionMetadata[fullId] != nil {
                return
            }
            PackNFT.itemCollectionMetadata[fullId] = metadata
            emit CollectionMetadataUpdated(distId: distId, edition: edition, metadata: metadata)

         }

         pub fun mint(
            distId: UInt64,
            additionalInfo: {String: String}?,
            commitHash: String,
            issuer: Address,
            nftCount: UInt16?,
            lockTime: UFix64?
         ): @NFT{
            assert(PackNFT.defaultCollectionMetadata != nil, message: "Please set the default collection metadata before minting")

            let totalEditions = PackNFT.itemEditions[distId] ?? UInt32(0)
            let edition = totalEditions + UInt32(1)
            let id = PackNFT.totalSupply + 1
            let nft <- create NFT(id: id, distId: distId, edition: edition, additionalInfo: additionalInfo, commitHash: commitHash, issuer: issuer, nftCount: nftCount, lockTime: lockTime)
            PackNFT.itemEditions[distId] = edition
            PackNFT.totalSupply = PackNFT.totalSupply + 1
            let p  <-create Pack(commitHash: commitHash, issuer: issuer, nftCount: nftCount, lockTime: lockTime)
            PackNFT.packs[id] <-! p
            emit Mint(id: id, edition: edition, commitHash: commitHash, distId: distId, nftCount: nftCount, lockTime: lockTime, additionalInfo: additionalInfo)
            return <- nft
         }

        pub fun reveal(id: UInt64, nfts: [&NonFungibleToken.NFT], salt: String) {
            let p <- PackNFT.packs.remove(key: id) ?? panic("no such pack")
            p.reveal(id: id, nfts: nfts, salt: salt)
            PackNFT.packs[id] <-! p
        }

        pub fun open(id: UInt64, nfts: [&NonFungibleToken.NFT]) {
            let p <- PackNFT.packs.remove(key: id) ?? panic("no such pack")
            p.open(id: id, nfts: nfts)
            PackNFT.packs[id] <-! p
        }

        pub fun createOperator(): @PackNFTOperator {
            return <- create PackNFTOperator()
        }

        pub fun setDefaultCollectionMetadata(defaultCollectionMetadata: CollectionMetadata) {
            PackNFT.defaultCollectionMetadata = defaultCollectionMetadata
        }

        pub fun setVersion(version: String) {
            PackNFT.version = version
        }

        init(){}
    }

    pub resource Pack {
        pub let commitHash: String
        pub let issuer: Address
        pub let nftCount: UInt16?
        pub let lockTime: UFix64?
        pub var status: Status
        pub var salt: String?

        pub fun verify(nftString: String): Bool {
            assert(self.status as! PackNFT.Status != PackNFT.Status.Sealed, message: "Pack not revealed yet")
            var hashString = self.salt!
            hashString = hashString.concat(",").concat(nftString)
            let hash = HashAlgorithm.SHA2_256.hash(hashString.utf8)
            assert(self.commitHash == String.encodeHex(hash), message: "CommitHash was not verified")
            return true
        }

        access(self) fun _hashNft(nft: &NonFungibleToken.NFT): String {
            return nft.getType().identifier.concat(".").concat(nft.id.toString())
        }

        access(self) fun _verify(nfts: [&NonFungibleToken.NFT], salt: String, commitHash: String): String {
            assert(self.nftCount == nil || self.nftCount! == (UInt16(nfts.length)), message: "nftCount doesn't match nfts length")
            var hashString = salt.concat(",").concat(nfts.length.toString())
            var nftString = nfts.length > 0 ? self._hashNft(nft: nfts[0]) : ""
            var i = 1
            while i < nfts.length {
                let s = self._hashNft(nft: nfts[i])
                nftString = nftString.concat(",").concat(s)
                i = i + 1
            }
            hashString = hashString.concat(",").concat(nftString)
            let hash = HashAlgorithm.SHA2_256.hash(hashString.utf8)
            assert(self.commitHash == String.encodeHex(hash), message: "CommitHash was not verified")
            return nftString
        }

        access(contract) fun reveal(id: UInt64, nfts: [&NonFungibleToken.NFT], salt: String) {
            assert(self.status as! PackNFT.Status == PackNFT.Status.Sealed, message: "Pack status is not Sealed")
            let v = self._verify(nfts: nfts, salt: salt, commitHash: self.commitHash)
            self.salt = salt
            self.status = PackNFT.Status.Revealed
            emit Revealed(id: id, salt: salt, nfts: v)
        }

        access(contract) fun open(id: UInt64, nfts: [&NonFungibleToken.NFT]) {
            pre {
                (self.lockTime == nil) || (getCurrentBlock().timestamp > self.lockTime!): "Pack is locked until ".concat(self.lockTime!.toString())
            }
            assert(self.status as! PackNFT.Status == PackNFT.Status.Revealed, message: "Pack status is not Revealed")
            self._verify(nfts: nfts, salt: self.salt!, commitHash: self.commitHash)
            self.status = PackNFT.Status.Opened
            emit Opened(id: id)
        }

        init(commitHash: String, issuer: Address, nftCount: UInt16?, lockTime: UFix64?) {
            self.commitHash = commitHash
            self.issuer = issuer
            self.status = PackNFT.Status.Sealed
            self.salt = nil
            self.nftCount = nftCount
            self.lockTime = lockTime
        }
    }

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
        pub let artworkOpened: String?
        pub let artworkOpenedMimeType: String?
        pub let artworkOpenedHash: String?
        pub let thumbnail: String
        pub let thumbnailMimeType: String
        pub let thumbnailOpened: String?
        pub let thumbnailOpenedMimeType: String?
        pub let termsUrl: String
        pub let externalUrl: String?
        pub let rarity: String?
        pub let credits: String?

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
            rawMetadata.insert(key: "artworkOpened", self.artworkOpened)
            rawMetadata.insert(key: "artworkOpenedMimeType", self.artworkOpenedMimeType)
            rawMetadata.insert(key: "artworkOpenedHash", self.artworkOpenedHash)
            rawMetadata.insert(key: "thumbnail", self.thumbnail)
            rawMetadata.insert(key: "thumbnailMimeType", self.thumbnailMimeType)
            rawMetadata.insert(key: "thumbnailOpened", self.thumbnailOpened)
            rawMetadata.insert(key: "thumbnailOpenedMimeType", self.thumbnailOpenedMimeType)
            rawMetadata.insert(key: "termsUrl", self.termsUrl)
            rawMetadata.insert(key: "externalUrl", self.externalUrl)
            rawMetadata.insert(key: "rarity", self.rarity)
            rawMetadata.insert(key: "credits", self.credits)

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
            rawMetadata.insert(key: "artworkOpened", self.artworkOpened)
            rawMetadata.insert(key: "artworkOpenedMimeType", self.artworkOpenedMimeType)
            rawMetadata.insert(key: "artworkOpenedHash", self.artworkOpenedHash)
            rawMetadata.insert(key: "thumbnail", self.thumbnail)
            rawMetadata.insert(key: "thumbnailMimeType", self.thumbnailMimeType)
            rawMetadata.insert(key: "thumbnailOpened", self.thumbnailOpened)
            rawMetadata.insert(key: "thumbnailOpenedMimeType", self.thumbnailOpenedMimeType)
            rawMetadata.insert(key: "termsUrl", self.termsUrl)
            rawMetadata.insert(key: "externalUrl", self.externalUrl)
            rawMetadata.insert(key: "rarity", self.rarity)
            rawMetadata.insert(key: "credits", self.credits)

            return rawMetadata
        }

        pub fun patchedForOpened(): Metadata {
            return Metadata(
                title: PackNFT.metadataOpenedWarning.concat(self.title),
                description: PackNFT.metadataOpenedWarning.concat(self.description),
                creator: self.creator,
                asset: self.asset,
                assetMimeType: self.assetMimeType,
                assetHash: self.assetHash,
                artwork: self.artworkOpened ?? self.artwork,
                artworkMimeType: self.artworkOpenedMimeType ?? self.artworkMimeType,
                artworkHash: self.artworkOpenedHash ?? self.artworkHash,
                artworkAlternate: self.artworkAlternate,
                artworkAlternateMimeType: self.artworkAlternateMimeType,
                artworkAlternateHash: self.artworkAlternateHash,
                artworkOpened: self.artworkOpened,
                artworkOpenedMimeType: self.artworkOpenedMimeType,
                artworkOpenedHash: self.artworkOpenedHash,
                thumbnail: self.thumbnailOpened ?? self.thumbnail,
                thumbnailMimeType: self.thumbnailOpenedMimeType ?? self.thumbnailMimeType,
                thumbnailOpened: self.thumbnailOpened,
                thumbnailOpenedMimeType: self.thumbnailOpenedMimeType,
                termsUrl: self.termsUrl,
                externalUrl: self.externalUrl,
                rarity: self.rarity,
                credits: self.credits
            )
        }


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
            artworkOpened: String?,
            artworkOpenedMimeType: String?,
            artworkOpenedHash: String?,
            thumbnail: String,
            thumbnailMimeType: String,
            thumbnailOpened: String?,
            thumbnailOpenedMimeType: String?,
            termsUrl: String,
            externalUrl: String?,
            rarity: String?,
            credits: String?
        ) {

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
            self.artworkOpened = artworkOpened
            self.artworkOpenedMimeType = artworkOpenedMimeType
            self.artworkOpenedHash = artworkOpenedHash
            self.thumbnail = thumbnail
            self.thumbnailMimeType = thumbnailMimeType
            self.thumbnailOpened = thumbnailOpened
            self.thumbnailOpenedMimeType = thumbnailOpenedMimeType
            self.termsUrl = termsUrl
            self.externalUrl = externalUrl
            self.credits = credits
            self.rarity = rarity
        }
    }


    pub struct CollectionMetadata {
        pub let name: String
        pub let description: String
        pub let URL: String
        pub let media: String
        pub let mediaMimeType: String
        pub let mediaBanner: String?
        pub let mediaBannerMimeType: String?
        pub let socials: {String:String}


        pub fun toDict(): {String: AnyStruct?} {
            let rawMetadata: {String: AnyStruct?} = {}

            rawMetadata.insert(key: "name", self.name)
            rawMetadata.insert(key: "description", self.description)
            rawMetadata.insert(key: "URL", self.URL)
            rawMetadata.insert(key: "media", self.media)
            rawMetadata.insert(key: "mediaMimeType", self.mediaMimeType)
            rawMetadata.insert(key: "mediaBanner", self.mediaBanner)
            rawMetadata.insert(key: "mediaBannerMimeType", self.mediaBanner)
            rawMetadata.insert(key: "socials", self.socials)

            return rawMetadata
        }

        init(
            name: String,
            description: String,
            URL: String,
            media: String,
            mediaMimeType: String,
            mediaBanner: String?,
            mediaBannerMimeType: String?,
            socials: {String:String}?,
        ) {
            self.name = name
            self.description = description
            self.URL = URL
            self.media = media
            self.mediaMimeType = mediaMimeType
            self.mediaBanner = mediaBanner
            self.mediaBannerMimeType = mediaBannerMimeType
            self.socials = socials ?? {}
        }
    }

    pub resource interface IPackNFTToken {
        pub let id: UInt64
        pub let edition: UInt32
        pub let commitHash: String
        pub let issuer: Address
        pub let nftCount: UInt16?
        pub let lockTime: UFix64?
    }

    pub resource interface IPackNFTOwnerOperator {
        pub fun reveal(openRequest: Bool)
        pub fun open()
    }

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver, IPackNFTToken, IPackNFTOwnerOperator {
        pub let id: UInt64
        pub let distId: UInt64
        pub let edition: UInt32
        pub let commitHash: String
        pub let issuer: Address
        pub let nftCount: UInt16?
        pub let lockTime: UFix64?

        access(self) let additionalInfo: {String: String}
        pub let mintedBlock: UInt64
        pub let mintedTime: UFix64

        pub fun reveal(openRequest: Bool){
            PackNFT.revealRequest(id: self.id, openRequest: openRequest)
        }

        pub fun open(){
            pre {
                (self.lockTime == nil) || (getCurrentBlock().timestamp > self.lockTime!): "Pack is locked until ".concat(self.lockTime!.toString())
            }
            PackNFT.openRequest(id: self.id)
        }

        pub fun getAdditionalInfo(): {String: String} {
            return self.additionalInfo
        }

        pub fun totalEditions(): UInt32 {
            return PackNFT.itemEditions[self.distId] ?? UInt32(0)
        }

        pub fun getViews(): [Type] {
            return [
                Type<Metadata>(),
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
                    return self.metadata()
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.metadata().title,
                        description: self.metadata().description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.metadata().thumbnail
                        )
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        UInt64(self.edition)
                    )
                case Type<MetadataViews.Editions>():
                    let name = self.collectionMetadata()?.name ?? PackNFT.defaultCollectionMetadata!.name
                    let editionInfo = MetadataViews.Edition(name: name, number: UInt64(self.edition), max: nil)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(
                        editionList
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL(
                        self.metadata().externalUrl ?? "https://www.tunegonft.com/view-pack-collectible/".concat(self.uuid.toString())
                    )
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: PackNFT.CollectionStoragePath,
                        publicPath: PackNFT.CollectionPublicPath,
                        providerPath: PackNFT.CollectionPrivatePath,
                        publicCollection: PackNFT.CollectionPublicType,
                        publicLinkedType: PackNFT.CollectionPublicType,
                        providerLinkedType: PackNFT.CollectionPrivateType,
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-PackNFT.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let collectionMetadata = self.collectionMetadata() ?? PackNFT.defaultCollectionMetadata!
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: collectionMetadata.media
                        ),
                        mediaType: collectionMetadata.mediaMimeType
                    )
                    let mediaBanner = collectionMetadata.mediaBanner != nil ?
                        MetadataViews.Media(
                            file: MetadataViews.HTTPFile(
                                url: collectionMetadata.mediaBanner!
                            ),
                            mediaType: collectionMetadata.mediaBannerMimeType!
                        )
                        : media
                    let socials: {String:MetadataViews.ExternalURL} = {}
                    collectionMetadata.socials.forEachKey(fun (key: String): Bool {
                        socials.insert(key: key,MetadataViews.ExternalURL(collectionMetadata.socials[key]!))
                        return false
                    })
                    return MetadataViews.NFTCollectionDisplay(
                        name: collectionMetadata.name,
                        description: collectionMetadata.description,
                        externalURL: MetadataViews.ExternalURL(collectionMetadata.URL),
                        squareImage: media,
                        bannerImage: mediaBanner,
                        socials: socials
                    )
                case Type<MetadataViews.Traits>():
                    let excludedTraits = ["mintedTime"]
                    let dict = self.metadataDict()
                    dict.forEachKey(fun (key: String): Bool {
                        if (dict[key] == nil) {
                            dict.remove(key: key)
                        }
                        return false
                    })
                    let traitsView = MetadataViews.dictToTraits(dict: dict, excludedNames: excludedTraits)

                    // mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
                    let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.mintedTime!, displayType: "Date", rarity: nil)
                    traitsView.addTrait(mintedTimeTrait)

                    return traitsView
            }

            return nil
        }

        pub fun _metadata(): Metadata  {
            let fullId = self.distId.toString().concat(":").concat(self.edition.toString())
            let editionMetadata = PackNFT.itemMetadata[fullId]
            if editionMetadata != nil {
                return editionMetadata!
            }
            let distMetadata = PackNFT.itemMetadata[self.distId.toString()]
            if distMetadata != nil {
                return distMetadata!
            }
            panic("Metadata not found for collectible ".concat(fullId))
        }

        pub fun metadata(): Metadata {
            let metadata = self._metadata()
            let p = PackNFT.borrowPackRepresentation(id: self.id) ?? panic ("Pack representation not found")
            if p.status as! PackNFT.Status == PackNFT.Status.Opened {
                return metadata.patchedForOpened()
            }
            return metadata
        }

        pub fun collectionMetadata(): CollectionMetadata?  {
            let fullId = self.distId.toString().concat(":").concat(self.edition.toString())
            let editionMetadata = PackNFT.itemCollectionMetadata[fullId]
            if editionMetadata != nil {
                return editionMetadata!
            }
            let distMetadata = PackNFT.itemCollectionMetadata[self.distId.toString()]
            return distMetadata
        }

        pub fun metadataDict(): {String: AnyStruct?} {
            let dict = self.metadata().toDict()
            let collectionDict = self.collectionMetadata()?.toDict()
            if (collectionDict != nil) {
                collectionDict!.forEachKey(fun (key: String): Bool {
                    dict.insert(key: "collection_".concat(key), collectionDict![key])
                    return false
                })
            }

            dict.insert(key: "mintedBlock", self.mintedBlock)
            dict.insert(key: "mintedTime", self.mintedTime)

            return dict
        }

        init(
            id: UInt64,
            distId: UInt64,
            edition: UInt32,
            additionalInfo: {String: String}?,
            commitHash: String,
            issuer: Address,
            nftCount: UInt16?,
            lockTime: UFix64?
        ) {
            self.id = id
            self.distId = distId
            self.edition = edition
            self.additionalInfo = additionalInfo ?? {}
            self.commitHash = commitHash
            self.issuer = issuer
            self.nftCount = nftCount
            self.lockTime = lockTime
            let currentBlock = getCurrentBlock()
            self.mintedBlock = currentBlock.height
            self.mintedTime = currentBlock.timestamp

            // asserts metadata exists for distribution / edition
            self._metadata()
        }

        destroy(){
            let p = PackNFT.borrowPackRepresentation(id: self.id) ?? panic ("No such pack")
            assert(p.status as! PackNFT.Status == PackNFT.Status.Opened, message: "Pack status must be Opened in order to destroy the PackNFT")
        }

    }


    pub resource interface IPackNFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowPackNFT(id: UInt64): &NFT{IPackNFTToken, NonFungibleToken.INFT, MetadataViews.Resolver}? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result!.id == id):
                    "Cannot borrow PackNFT reference: The ID of the returned reference is incorrect"
            }
        }
    }
    pub resource interface IPackNFTCollectionPrivate {
        pub fun borrowPackNFT(id: UInt64): &NFT{IPackNFTToken, NonFungibleToken.INFT, MetadataViews.Resolver, IPackNFTOwnerOperator}? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result!.id == id):
                    "Cannot borrow PackNFT reference: The ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection:
        NonFungibleToken.Provider,
        NonFungibleToken.Receiver,
        NonFungibleToken.CollectionPublic,
        MetadataViews.ResolverCollection,
        IPackNFTCollectionPublic,
        IPackNFTCollectionPrivate
    {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <- token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @PackNFT.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowPackNFT(id: UInt64): &NFT? {
            let nft<- self.ownedNFTs.remove(key: id)
            if(nft == nil){
                destroy nft
                return nil
            }
            let token <- nft! as! @PackNFT.NFT
            let ref = &token as &NFT
            self.ownedNFTs[id] <-! token as! @PackNFT.NFT
            return ref
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let ref = nft as! &PackNFT.NFT
            return ref as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    access(contract) fun revealRequest(id: UInt64, openRequest: Bool ) {
        let p = PackNFT.borrowPackRepresentation(id: id) ?? panic ("No such pack")
        assert(p.status == PackNFT.Status.Sealed, message: "Pack status must be Sealed for reveal request")
        emit RevealRequest(id: id, openRequest: openRequest)
    }

    access(contract) fun openRequest(id: UInt64) {
        let p = PackNFT.borrowPackRepresentation(id: id) ?? panic ("No such pack")
        assert(p.status == PackNFT.Status.Revealed, message: "Pack status must be Revealed for open request")
        emit OpenRequest(id: id)
    }

    pub fun publicReveal(id: UInt64, nfts: [&NonFungibleToken.NFT], salt: String) {
        let p = PackNFT.borrowPackRepresentation(id: id) ?? panic ("No such pack")
        p.reveal(id: id, nfts: nfts, salt: salt)
    }

    pub fun borrowPackRepresentation(id: UInt64):  &Pack? {
        return &self.packs[id] as &Pack?
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    init() {
        self.totalSupply = 0
        self.itemEditions = {}
        self.packs <- {}
        self.CollectionStoragePath = /storage/tunegoPack
        self.CollectionPublicPath = /public/tunegoPack
        self.CollectionPrivatePath = /private/tunegoPackPriv
        self.OperatorStoragePath = /storage/tunegoPackOperator
        self.OperatorPrivPath = /private/tunegoPackOperator
        self.defaultCollectionMetadata = nil
        self.version = "1.0"

        self.itemMetadata = {}
        self.itemCollectionMetadata = {}
        self.metadataOpenedWarning = "WARNING this pack has already been opened! \n"

        self.CollectionPublicType = Type<&Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, IPackNFTCollectionPublic}>()
        self.CollectionPrivateType = Type<&Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, IPackNFTCollectionPrivate}>()

        // Create a collection to receive Pack NFTs
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)
        self.account.link<&Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, IPackNFTCollectionPublic}>(self.CollectionPublicPath, target: self.CollectionStoragePath)
        self.account.link<&Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, IPackNFTCollectionPrivate}>(self.CollectionPrivatePath, target: self.CollectionStoragePath)

        // Create a operator to share mint capability with proxy
        let operator <- create PackNFTOperator()
        self.account.save(<-operator, to: self.OperatorStoragePath)
        self.account.link<&PackNFTOperator{IOperator}>(self.OperatorPrivPath, target: self.OperatorStoragePath)
    }

}

