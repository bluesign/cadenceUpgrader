import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

pub contract YerchNFT: NonFungibleToken {

    pub var totalSupply: UInt64
    
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Bought(id: UInt64, to: Address?)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let AdminStoragePath: StoragePath

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let edition: UInt64

        pub let name: String
        pub let description: String
        pub let thumbnailCID: String
        pub let gameAssetID: String
        pub let type: String
        pub var season: String
        pub var rarity: String

        init(edition: UInt64, name: String, description: String, thumbnailCID: String, gameAssetID: String, type: String, season: String, rarity: String) {
            YerchNFT.totalSupply = YerchNFT.totalSupply + 1
            self.id = YerchNFT.totalSupply

            self.edition = edition
            self.name = name
            self.description = description
            self.thumbnailCID = thumbnailCID
            self.gameAssetID = gameAssetID
            self.type = type
            self.season = season
            self.rarity = rarity
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.Royalties>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.IPFSFile(
                            cid: self.thumbnailCID,
                            path: ""
                        )
                    )
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: YerchNFT.CollectionStoragePath,
                        publicPath: YerchNFT.CollectionPublicPath,
                        providerPath: /private/YerchNFTCollection,
                        publicCollection: Type<&YerchNFT.Collection{YerchNFT.YerchNFTCollectionPublic}>(),
                        publicLinkedType: Type<&YerchNFT.Collection{YerchNFT.YerchNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&YerchNFT.Collection{YerchNFT.YerchNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-YerchNFT.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: ""
                        ),
                        mediaType: "image/svg+xml"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "Yerch NFT",
                        description: "Collection of YDY Yerch NFTs.",
                        externalURL: MetadataViews.ExternalURL("https://www.ydylife.com/"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/ydylife")
                        }
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL(
                        "https://www.ydylife.com/"
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        [MetadataViews.Royalty(recepient: getAccount(YerchNFT.account.address).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver), cut: 0.075, description: "This is the royalty receiver for YDY Yerch NFTs")]
                    )  
            }
            return nil
        }
    }

        pub resource interface YerchNFTCollectionPublic {
            pub fun deposit(token: @NonFungibleToken.NFT)
            pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT
            pub fun getIDs(): [UInt64]
            pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
            pub fun borrowYerchNFT(id: UInt64): &YerchNFT.NFT
            pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver}
        }

        pub resource Collection: NonFungibleToken.Receiver, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, YerchNFTCollectionPublic {
            pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

            pub fun deposit(token: @NonFungibleToken.NFT) {
                let myToken <- token as! @YerchNFT.NFT
                emit Deposit(id: myToken.id, to: self.owner?.address)
                self.ownedNFTs[myToken.id] <-! myToken
            }

            pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
                let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("This NFT does not exist")
                emit Withdraw(id: token.id, from: self.owner?.address)
                return <- token
            }

            pub fun getIDs(): [UInt64] {
                return self.ownedNFTs.keys
            }

            pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
                return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
            }

            pub fun borrowYerchNFT(id: UInt64): &YerchNFT.NFT {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &YerchNFT.NFT
            }

            pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                let nft = ref as! &YerchNFT.NFT
                return nft as &AnyResource{MetadataViews.Resolver}
            }

            init() {
                self.ownedNFTs <- {}
            }

            destroy() {
                destroy self.ownedNFTs
            }
        }

        pub fun createEmptyCollection(): @Collection {
            return <- create Collection()
        }

        pub resource Admin {

            pub fun mintNFT(metadata: {String: String}, edition: UInt64, recipient: Capability<&Collection{YerchNFT.YerchNFTCollectionPublic}>) {
               pre {
                    metadata["name"] != nil: "Name is required"
                    metadata["description"] != nil: "Description is required"
                    metadata["thumbnailCID"] != nil: "Thumbnail CID is required"
                    metadata["gameAssetID"] != nil: "Game Asset ID is required"
                    metadata["type"] != nil: "Type is required"
                    metadata["season"] != nil: "Season is required"
                    metadata["rarity"] != nil: "Rarity is required"
               }
               let nft <- create NFT(edition: edition, name: metadata["name"]!, description: metadata["description"]!, thumbnailCID: metadata["thumbnailCID"]!, gameAssetID: metadata["gameAssetID"]!, type: metadata["type"]!, season: metadata["season"]!, rarity: metadata["rarity"]!)
               let recipientCollection = recipient.borrow() ?? panic("Could not borrow recipient's collection")
               recipientCollection.deposit(token: <-nft)
            }
        }

    init() {
        self.totalSupply = 0
        self.CollectionStoragePath = /storage/YerchNFTCollection
        self.CollectionPublicPath = /public/YerchNFTCollection
        self.AdminStoragePath = /storage/YerchNFTAdmin

        let admin <- create Admin()
        self.account.save(<-admin, to: self.AdminStoragePath)

        emit ContractInitialized()
    }
}