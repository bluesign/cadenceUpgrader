import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract Provineer: NonFungibleToken {

    pub var totalSupply: UInt64

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let ProvineerAdminStoragePath: StoragePath
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event ProvineerCreated(id: UInt64, fileName: String, fileVersion: String, description: String, signature: String)

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let fileName: String
        pub let thumbnail: String
        pub let fileVersion: String
        pub let category: String
        pub let description: String
        pub let proof1: String
        pub let proof2: String
        pub let proof3: String
        pub let signature: String

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.Traits>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.fileName,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.thumbnail
                        )
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://www.provineer.com/")
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let mediaSquare = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://global-uploads.webflow.com/60f008ba9757da0940af288e/62e77af588325131a9aa8e61_4BFJowii_400x400.jpeg"
                        ),
                        mediaType: "image/svg+xml"
                    )
                    let mediaBanner = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://www.provineer.com/static/logo-full-dark@2x-0e8797bb751b2fcb15c6c1227ca7b3b6.png"
                        ),
                        mediaType: "image/svg+xml"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "Provineer",
                        description: "Authenticate anything, anytime, anywhere.",
                        externalURL: MetadataViews.ExternalURL("https://www.provineer.com/"),
                        squareImage: mediaSquare,
                        bannerImage: mediaBanner,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/provineer")
                        }
                    )
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: Provineer.CollectionStoragePath,
                        publicPath: Provineer.CollectionPublicPath,
                        providerPath: /private/ProvineerCollection,
                        publicCollection: Type<&Provineer.Collection{Provineer.ProvineerCollectionPublic}>(),
                        publicLinkedType: Type<&Provineer.Collection{Provineer.ProvineerCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&Provineer.Collection{Provineer.ProvineerCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection { return <-Provineer.createEmptyCollection() })
                    )
                    case Type<MetadataViews.Traits>():
                    let traits: [MetadataViews.Trait] = []
                        traits.append(MetadataViews.Trait(
                            trait: "File Version",
                            value: self.fileVersion,
                            displayType: nil,
                            rarity: nil
                        ))
                    return MetadataViews.Traits(traits: traits)
            }

            return nil
        }

        init(
            fileName: String,
            thumbnail: String,
            fileVersion: String,
            category: String,
            description: String,
            proof1: String,
            proof2: String,
            proof3: String,
            signature: String,
            
        ) { 
            self.id = self.uuid
            self.fileName = fileName
            self.thumbnail = thumbnail
            self.fileVersion = fileVersion
            self.category = category
            self.description = description
            self.proof1 = proof1
            self.proof2 = proof2 
            self.proof3 = proof3
            self.signature = signature
        }
    }

    pub resource interface ProvineerCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowProvineer(id: UInt64): &Provineer.NFT? { 
            post {
                (result == nil) || (result?.id == id): 
                    "Cannot borrow Provineer reference: The ID of the returned reference is incorrect"
            }
        }      
    }

    pub resource Collection: ProvineerCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Provineer.NFT

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

        pub fun borrowProvineer(id: UInt64): &Provineer.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Provineer.NFT
            }

            return nil
        }
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let provineer = nft as! &Provineer.NFT
            return provineer as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub resource ProvineerAdmin {

        pub fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            fileName: String,
            thumbnail: String,
            fileVersion: String,
            category: String,
            description: String,
            proof1: String,
            proof2: String,
            proof3: String,
            signature: String,
        ) 
        {  

            recipient.deposit(token: <-create Provineer.NFT(
                                                fileName: fileName,
                                                thumbnail: thumbnail,
                                                fileVersion:fileVersion,
                                                category: category,
                                                description:description,
                                                proof1: proof1,
                                                proof2: proof2,
                                                proof3: proof3,
                                                signature:signature))


            emit ProvineerCreated(
                id: self.uuid,
                fileName: fileName,
                fileVersion: fileVersion,
                description: description,
                signature: signature,
            )

            Provineer.totalSupply = Provineer.totalSupply + (1 as UInt64)
        }
    }

    init() {
        self.totalSupply = 0

        self.CollectionStoragePath = /storage/provineerCollection
        self.CollectionPublicPath = /public/provineerCollection
        self.ProvineerAdminStoragePath = /storage/provineerAdmin

        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        self.account.link<&Provineer.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>
        ( self.CollectionPublicPath, target: self.CollectionStoragePath )

        let minter <- create ProvineerAdmin()
        self.account.save(<-minter, to: self.ProvineerAdminStoragePath)

        emit ContractInitialized()
    }
}