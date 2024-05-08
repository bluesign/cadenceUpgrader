import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract FEHVAsset: NonFungibleToken {

    pub var totalSupply: UInt64
    access(contract) let minted: {String: Bool}
    access(contract) let registry: {String: AnyStruct}

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath
    pub let AdminStoragePath: StoragePath

    // The ExtraData view provides extra metadata 
    // such as json data and metadata id.
    //
    pub struct ExtraData {
        pub let metadataId: String
        pub let free: Bool
        pub let jsonData: String

        init(metadataId: String, free: Bool, jsonData: String) {
            self.metadataId = metadataId
            self.free = free
            self.jsonData = jsonData
        }
    }

    // Helper to get an ExtraData view in a typesafe way
    //
    pub fun getExtraData(_ viewResolver: &{MetadataViews.Resolver}) : ExtraData? {
        if let view = viewResolver.resolveView(Type<ExtraData>()) {
            if let v = view as? ExtraData {
                return v
            }
        }
        return nil
    }

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let metadataId: String
        pub let free: Bool
        pub let name: String
        pub let description: String
        pub let thumbnail: String
        pub let externalUrl: String
        pub let video: String
        pub let jsonData: String
        access(self) let traits: [MetadataViews.Trait]
     
        init(
            id: UInt64,
            metadataId: String,
            free: Bool,
            name: String,
            description: String,
            thumbnail: String,
            externalUrl: String,
            video: String,
            jsonData: String,
            traits: [MetadataViews.Trait]
        ) {
            self.id = id
            self.metadataId = metadataId
            self.free = free
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.externalUrl = externalUrl
            self.video = video
            self.jsonData = jsonData
            self.traits = traits
            FEHVAsset.minted[metadataId] = true
            FEHVAsset.totalSupply = FEHVAsset.totalSupply + 1
        }
    
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.Medias>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>(),
                Type<FEHVAsset.ExtraData>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(url: self.thumbnail)
                    )

                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(self.id)

                case Type<MetadataViews.Royalties>():
                    let royalty = MetadataViews.Royalty(
                        receiver: FEHVAsset.registry["royalty-capability"]! as! Capability<&{FungibleToken.Receiver}>,
                        cut: FEHVAsset.registry["royalty-cut"]! as! UFix64,
                        description: "Creator Royalty"
                    )
                    return MetadataViews.Royalties([royalty])

                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL(self.externalUrl.concat(self.id.toString()))

                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: FEHVAsset.CollectionStoragePath,
                        publicPath: FEHVAsset.CollectionPublicPath,
                        providerPath: /private/FEHVAssetCollection,
                        publicCollection: Type<&FEHVAsset.Collection{FEHVAsset.AssetCollectionPublic}>(),
                        publicLinkedType: Type<&FEHVAsset.Collection{FEHVAsset.AssetCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&FEHVAsset.Collection{FEHVAsset.AssetCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-FEHVAsset.createEmptyCollection()
                        })
                    )

                case Type<MetadataViews.Medias>():
                    let imageFile = MetadataViews.HTTPFile(url: self.thumbnail)
                    let videoFile = MetadataViews.HTTPFile(url: self.video)
                    let imageMedia = MetadataViews.Media(file: imageFile, mediaType: "image/png")
                    let videoMedia = MetadataViews.Media(file: videoFile, mediaType: "video/mp4")
                    return MetadataViews.Medias([imageMedia, videoMedia])

                case Type<MetadataViews.NFTCollectionDisplay>():
                    let squareMedia = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(url: FEHVAsset.registry["square-image-url"]! as! String),
                        mediaType: "image/png"
                    )
                    let bannerMedia = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(url: FEHVAsset.registry["banner-image-url"]! as! String),
                        mediaType: "image/png"
                    )
                    let externalUrl = FEHVAsset.registry["collection-external-url"]! as! String
                    return MetadataViews.NFTCollectionDisplay(
                        name: FEHVAsset.registry["collection-name"]! as! String,
                        description: FEHVAsset.registry["collection-description"]! as! String,
                        externalURL: MetadataViews.ExternalURL(externalUrl),
                        squareImage: squareMedia,
                        bannerImage: bannerMedia,
                        socials: FEHVAsset.registry["social-links"]! as! {String: MetadataViews.ExternalURL}
                    )

                case Type<MetadataViews.Traits>():
                    return MetadataViews.Traits(self.traits)

                case Type<FEHVAsset.ExtraData>():
                    return FEHVAsset.ExtraData(
                        metadataId: self.metadataId,
                        free: self.free,
                        jsonData: self.jsonData
                    )
            }
            return nil
        }
    }

    pub resource interface AssetCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowAsset(id: UInt64): &FEHVAsset.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Asset reference: the ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: AssetCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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

            return <-token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @FEHVAsset.NFT

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
 
        pub fun borrowAsset(id: UInt64): &FEHVAsset.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &FEHVAsset.NFT
            }

            return nil
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let asset = nft as! &FEHVAsset.NFT
            return asset
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // isMinted returns true if an NFT with that metadata ID was minted
    pub fun isMinted(metadataId: String): Bool {
        return self.minted[metadataId] == true
    }

    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
    pub resource NFTMinter {

        // mintNFT mints a new NFT with a new ID
        // and deposit it in the recipients collection using their collection reference
        pub fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            metadataId: String,
            free: Bool,
            name: String,
            description: String,
            thumbnail: String,
            externalUrl: String,
            video: String,
            jsonData: String,
            traits: [MetadataViews.Trait]
        ) {
            pre {
                FEHVAsset.minted[metadataId] != true : "Already minted"
            }

            // create a new NFT
            var newNFT <- create NFT(
                id: FEHVAsset.totalSupply,
                metadataId: metadataId,
                free: free,
                name: name,
                description: description,
                thumbnail: thumbnail,
                externalUrl: externalUrl,
                video: video,
                jsonData: jsonData,
                traits: traits
            )

            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newNFT)
        }
    }

    // A token resource that allows its holder to change the registry data.
    //
    pub resource Admin {
        pub fun setRegistry(key: String, value: AnyStruct) {
            FEHVAsset.registry[key] = value
        }
    }

    init() {
        // Initialize the total supply
        self.totalSupply = 0

        // Initialize the minted metadata IDs
        self.minted = {}

        // Initialize the data registry
        self.registry = {}

        // Set the named paths
        self.CollectionStoragePath = /storage/FEHVAssetCollection
        self.CollectionPublicPath = /public/FEHVAssetCollection
        self.MinterStoragePath = /storage/FEHVAssetMinter
        self.AdminStoragePath = /storage/FEHVAssetAdmin

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        // Create an Admin resource and save it to storage
        let admin <- create Admin()
        self.account.save(<-admin, to: self.AdminStoragePath)

        emit ContractInitialized()
    }
}
