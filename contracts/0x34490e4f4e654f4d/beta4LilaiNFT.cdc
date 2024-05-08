import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import ViewResolver from "../0x1d7e57aa55817448/ViewResolver.cdc"

pub contract beta4LilaiNFT: NonFungibleToken, ViewResolver {

    /// Total supply of beta4LilaiNFTs in existence
    pub var totalSupply: UInt64

    /// The event that is emitted when the contract is created
    pub event ContractInitialized()

    /// The event that is emitted when an NFT is withdrawn from a Collection
    pub event Withdraw(id: UInt64, from: Address?)

    /// The event that is emitted when an NFT is deposited to a Collection
    pub event Deposit(id: UInt64, to: Address?)

    /// The event that is emitted when the Lilaiputia field of an NFT is updated
    pub event LilaiputiaUpdated(id: UInt64, updater: Address?, newLilaiputiaData: String)

    // Event when an nft is minted
    pub event NFTMinted(id: UInt64)

    /// Storage and Public Paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    /// The core resource that represents a Non Fungible Token.
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        /// The unique ID that each NFT has
        pub let id: UInt64

        /// Metadata fields
        pub let name: String
        pub let description: String
        pub let thumbnail: String
        access(self) let royalties: [MetadataViews.Royalty]
        access(self) let metadata: {String: AnyStruct}
        access(self) var lilaiputia: String // Mutable field for Lilaiputia data

        init(
            id: UInt64,
            name: String,
            description: String,
            thumbnail: String,
            royalties: [MetadataViews.Royalty],
            metadata: {String: AnyStruct},
            lilaiputia: String
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.royalties = royalties
            self.metadata = metadata
            self.lilaiputia = lilaiputia
        }

        /// Function to update the Lilaiputia field
        pub fun updateLilaiputia(newLilaiputiaData: String) {
            self.lilaiputia = newLilaiputiaData
            emit LilaiputiaUpdated(id: self.id, updater: self.owner?.address, newLilaiputiaData: newLilaiputiaData)
        }

        /// Function that returns all the Metadata Views implemented by a Non Fungible Token
        ///
        /// @return An array of Types defining the implemented views. This value will be used by
        ///         developers to know which parameter to pass to the resolveView() method.
        ///
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>()
            ]
        }

                /// Function that resolves a metadata view for this token.
        ///
        /// @param view: The Type of the desired view.
        /// @return A structure representing the requested view.
        ///
        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.thumbnail
                        )
                    )
                case Type<MetadataViews.Editions>():
                    let editionInfo = MetadataViews.Edition(name: "Lilaiputian NFTs", number: self.id, max: nil)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(
                        editionList
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        self.royalties
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("http://www.lilaiputia.com/".concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: beta4LilaiNFT.CollectionStoragePath,
                        publicPath: beta4LilaiNFT.CollectionPublicPath,
                        providerPath: /private/beta4LilaiNFTCollection,
                        publicCollection: Type<&beta4LilaiNFT.Collection{beta4LilaiNFT.beta4LilaiNFTCollectionPublic}>(),
                        publicLinkedType: Type<&beta4LilaiNFT.Collection{beta4LilaiNFT.beta4LilaiNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&beta4LilaiNFT.Collection{beta4LilaiNFT.beta4LilaiNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-beta4LilaiNFT.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "lilaiputia.mypinata.cloud"
                        ),
                        mediaType: "image/svg+xml"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "The Lilai Collection",
                        description: "A collection of unique NFTs for the Lilai universe.",
                        externalURL: MetadataViews.ExternalURL("lilaiputia.mypinata.cloud"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/lilaipuita")
                        }
                    )
                case Type<MetadataViews.Traits>():
                    let excludedTraits = ["mintedTime", "foo"]
                    let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)

                    let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
                    traitsView.addTrait(mintedTimeTrait)

                    let fooTraitRarity = MetadataViews.Rarity(score: 10.0, max: 100.0, description: "Common")
                    let fooTrait = MetadataViews.Trait(name: "foo", value: self.metadata["foo"], displayType: nil, rarity: fooTraitRarity)
                    traitsView.addTrait(fooTrait)

                    return traitsView

            }
            return nil
        }
    }

    /// Defines the methods that are particular to this NFT contract collection
    ///
    pub resource interface beta4LilaiNFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowbeta4LilaiNFT(id: UInt64): &beta4LilaiNFT.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow beta4LilaiNFT reference: the ID of the returned reference is incorrect"
            }
        }
    }

    /// The resource that will be holding the NFTs inside any account.
    /// In order to be able to manage NFTs any account will need to create
    /// an empty collection first
    ///
    pub resource Collection: beta4LilaiNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
            let token <- token as! @beta4LilaiNFT.NFT
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

        pub fun borrowbeta4LilaiNFT(id: UInt64): &beta4LilaiNFT.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &beta4LilaiNFT.NFT
            }
            return nil
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let beta4LilaiNFT = nft as! &beta4LilaiNFT.NFT
            return beta4LilaiNFT as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // Public function to mint a new NFT
    pub fun mintNFT(
        recipientAddress: Address,
        name: String,
        description: String,
        thumbnail: String,
        royalties: [MetadataViews.Royalty],
        lilaiputiaData: String
    ) {
        let recipientAccount = getAccount(recipientAddress)
        let recipientCollection = recipientAccount.getCapability(self.CollectionPublicPath)
            .borrow<&Collection{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not borrow a reference to the recipient's collection")

        let metadata: {String: AnyStruct} = {
            "name": name,
            "description": description,
            "thumbnail": thumbnail,
            "ipfsLink": thumbnail, // Include IPFS link
            "mintedBlock": getCurrentBlock().height,
            "mintedTime": getCurrentBlock().timestamp,
            "minter": recipientAddress
            // Add other fields as needed
        }

        var newNFT <- create NFT(
            id: beta4LilaiNFT.totalSupply,
            name: name,
            description: description,
            thumbnail: thumbnail,
            royalties: royalties,
            metadata: metadata,
            lilaiputia: lilaiputiaData
        )
        recipientCollection.deposit(token: <-newNFT)

        beta4LilaiNFT.totalSupply = beta4LilaiNFT.totalSupply + UInt64(1)
        emit beta4LilaiNFT.NFTMinted(id: beta4LilaiNFT.totalSupply)
    }

    pub fun resolveView(_ view: Type): AnyStruct? {
        switch view {
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                    storagePath: beta4LilaiNFT.CollectionStoragePath,
                    publicPath: beta4LilaiNFT.CollectionPublicPath,
                    providerPath: /private/beta4LilaiNFTCollection,
                    publicCollection: Type<&beta4LilaiNFT.Collection{beta4LilaiNFT.beta4LilaiNFTCollectionPublic}>(),
                    publicLinkedType: Type<&beta4LilaiNFT.Collection{beta4LilaiNFT.beta4LilaiNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                    providerLinkedType: Type<&beta4LilaiNFT.Collection{beta4LilaiNFT.beta4LilaiNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                    createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                        return <-beta4LilaiNFT.createEmptyCollection()
                    })
                )
            case Type<MetadataViews.NFTCollectionDisplay>():
                let media = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "lilaiputia.mypinata.cloud"
                    ),
                    mediaType: "image/svg+xml"
                )
                return MetadataViews.NFTCollectionDisplay(
                    name: "The Lilai Collection",
                    description: "A diverse collection of NFTs within the Lilai universe.",
                    externalURL: MetadataViews.ExternalURL("lilaiputia.mypinata.cloud"),
                    squareImage: media,
                    bannerImage: media,
                    socials: {
                        "twitter": MetadataViews.ExternalURL("hhttps://twitter.com/lilaiputia")
                    }
                )
        }
        return nil
    }
    
    pub fun getViews(): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>()
        ]
    }

    init() {
        self.totalSupply = 0

        // Set the paths
        self.CollectionStoragePath = /storage/beta4LilaiNFTCollection
        self.CollectionPublicPath = /public/beta4LilaiNFTCollection

        // Create and store the collection
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // Link the collection to the public path
        self.account.link<&beta4LilaiNFT.Collection{NonFungibleToken.CollectionPublic, beta4LilaiNFT.beta4LilaiNFTCollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        emit ContractInitialized()
    }
}