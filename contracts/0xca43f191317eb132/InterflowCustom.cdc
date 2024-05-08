import NonFungibleToken from 0x1d7e57aa55817448 
import MetadataViews from 0x1d7e57aa55817448 
 
pub contract InterflowCustom: NonFungibleToken {

    /// Total supply of InterflowCustoms in existence
    pub var totalSupply: UInt64

    /// The event that is emitted when the contract is created
    pub event ContractInitialized()

    pub event NftRevealed(id: UInt64)

    /// The event that is emitted when an NFT is withdrawn from a Collection
    pub event Withdraw(id: UInt64, from: Address?)

    /// The event that is emitted when an NFT is deposited to a Collection
    pub event Deposit(id: UInt64, to: Address?)

    /// Storage and Public Paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    /// The core resource that represents a Non Fungible Token. 
    /// New instances will be created using the NFTMinter resource
    /// and stored in the Collection resource
    ///
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        
        /// The unique ID that each NFT has
        pub let id: UInt64

        /// Metadata fields
        pub let name: String
        pub let description: String
        pub var thumbnail: String
        pub let originalNftUuid: UInt64
        pub let originalNftImageLink: String
        pub let originalNftCollectionName: String
        pub let originalNftType: Type?
        pub let originalNftContractAddress: Address?
        access(self) let royalties: [MetadataViews.Royalty]
    
        init(
            id: UInt64,
            name: String,
            description: String,
            thumbnail: String,
            originalNftUuid: UInt64,
            originalNftImageLink: String,
            originalNftCollectionName: String,
            originalNftType: Type?,
            originalNftContractAddress: Address?,
            royalties: [MetadataViews.Royalty],
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.originalNftUuid = originalNftUuid
            self.originalNftImageLink = originalNftImageLink
            self.originalNftCollectionName = originalNftCollectionName
            self.originalNftType = originalNftType
            self.originalNftContractAddress = originalNftContractAddress
            self.royalties = royalties
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
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Traits>()
            ]
        }

        access(contract) fun revealThumbnail() {
            self.thumbnail = "https://interflow-app.s3.amazonaws.com/".concat(self.id.toString()).concat(".png")
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
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        self.royalties
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://interflow.../".concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: InterflowCustom.CollectionStoragePath,
                        publicPath: InterflowCustom.CollectionPublicPath,
                        providerPath: /private/interflowCustomCollection,
                        publicCollection: Type<&InterflowCustom.Collection{InterflowCustom.InterflowCustomCollectionPublic}>(),
                        publicLinkedType: Type<&InterflowCustom.Collection{InterflowCustom.InterflowCustomCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&InterflowCustom.Collection{InterflowCustom.InterflowCustomCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-InterflowCustom.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://interflow-app.s3.amazonaws.com/bgImage.png"
                        ),
                        mediaType: "image/png"
                    )
                    let squareImg = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://interflow-app.s3.amazonaws.com/logo.png"
                        ),
                        mediaType: "image/png"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "Interflow Custom",
                        description: "First AI generated NFT Collection based in original NFTs images.",
                        externalURL: MetadataViews.ExternalURL("https://interflow.../"),
                        squareImage: squareImg,
                        bannerImage: media,
                        socials: {
                            "discord": MetadataViews.ExternalURL("https://discord.gg/QzBqwSSc")
                        }
                    )
                case Type<MetadataViews.Traits>():
                    let traits: [MetadataViews.Trait] = []
                    return MetadataViews.Traits(traits)
            }
            return nil
        }
    }

    /// Defines the methods that are particular to this NFT contract collection
    ///
    pub resource interface InterflowCustomCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowInterflowCustom(id: UInt64): &InterflowCustom.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow InterflowCustom reference: the ID of the returned reference is incorrect"
            }
        }
    }

    /// The resource that will be holding the NFTs inside any account.
    /// In order to be able to manage NFTs any account will need to create
    /// an empty collection first
    ///
    pub resource Collection: InterflowCustomCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        /// Removes an NFT from the collection and moves it to the caller
        ///
        /// @param withdrawID: The ID of the NFT that wants to be withdrawn
        /// @return The NFT resource that has been taken out of the collection
        ///
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        /// Adds an NFT to the collections dictionary and adds the ID to the id array
        ///
        /// @param token: The NFT resource to be included in the collection
        /// 
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @InterflowCustom.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        /// Helper method for getting the collection IDs
        ///
        /// @return An array containing the IDs of the NFTs in the collection
        ///
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        /// Gets a reference to an NFT in the collection so that 
        /// the caller can read its metadata and call its methods
        ///
        /// @param id: The ID of the wanted NFT
        /// @return A reference to the wanted NFT resource
        ///
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }
 
        /// Gets a reference to an NFT in the collection so that 
        /// the caller can read its metadata and call its methods
        ///
        /// @param id: The ID of the wanted NFT
        /// @return A reference to the wanted NFT resource
        ///        
        pub fun borrowInterflowCustom(id: UInt64): &InterflowCustom.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &InterflowCustom.NFT
            }

            return nil
        }

        /// Gets a reference to the NFT only conforming to the `{MetadataViews.Resolver}`
        /// interface so that the caller can retrieve the views that the NFT
        /// is implementing and resolve them
        ///
        /// @param id: The ID of the wanted NFT
        /// @return The resource reference conforming to the Resolver interface
        /// 
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let InterflowCustom = nft as! &InterflowCustom.NFT
            return InterflowCustom as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    /// Allows anyone to create a new empty collection
    ///
    /// @return The new Collection resource
    ///
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    /// Resource that an admin or something similar would own to be
    /// able to mint new NFTs
    ///
    pub resource NFTMinter {


        pub fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            id: UInt64,
            name: String,
            description: String,
            originalNftUuid: UInt64,
            originalNftImageLink: String,
            originalNftCollectionName: String,
            originalNftType: Type?,
            originalNftContractAddress: Address?,
            royalties: [MetadataViews.Royalty]
        ) {

            let placeholderImage = "https://interflow-app.s3.amazonaws.com/placeholder.png"
            // create a new NFT
            var newNFT <- create NFT(
                id: id,
                name: name,
                description: description,
                thumbnail: placeholderImage,
                originalNftUuid: originalNftUuid,
                originalNftImageLink: originalNftImageLink,
                originalNftCollectionName: originalNftCollectionName,
                originalNftType: originalNftType,
                originalNftContractAddress: originalNftContractAddress,
                royalties: royalties,
            )

            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newNFT)

            InterflowCustom.totalSupply = InterflowCustom.totalSupply + UInt64(1)
        }

        pub fun revealNft(nft: &NFT) {
            nft.revealThumbnail()
            emit NftRevealed(id: nft.id)
        }
    }

    init() {
        // Initialize the total supply
        self.totalSupply = 0

        // Set the named paths
        self.CollectionStoragePath = /storage/interflowCustomCollection
        self.CollectionPublicPath = /public/interflowCustomCollection
        self.MinterStoragePath = /storage/interflowCustomMinter

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // create a public capability for the collection
        self.account.link<&InterflowCustom.Collection{NonFungibleToken.CollectionPublic, InterflowCustom.InterflowCustomCollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}