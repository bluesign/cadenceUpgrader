import NonFungibleToken from 0x1d7e57aa55817448 //Mainnet address: 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448 //Mainnet address: 0x1d7e57aa55817448

pub contract ChainIDEShieldNFT: NonFungibleToken {

    /// Total supply of ChainIDEShieldNFT in existence
    pub var totalSupply: UInt64

    /// Max supply of ChainIDEShieldNFT in existence
    pub var maxSupply: UInt64

    /// The event that is emitted when the contract is created
    pub event ContractInitialized()

    /// The event that is emitted when an NFT is withdrawn from a Collection
    pub event Withdraw(id: UInt64, from: Address?)

    /// The event that is emitted when an NFT is deposited to a Collection
    pub event Deposit(id: UInt64, to: Address?)

    // Collection name
    pub let CollectionName: String
    // Collection description
    pub let CollectionDesc: String

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
        pub let type: String



        /// Metadata fields
        access(self) let metadata: {String: AnyStruct}

        init(
            id: UInt64,
            type: String,
            metadata: {String: AnyStruct},
        ) {
            self.id = id
            self.type = type
            self.metadata = metadata
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
                        name: "ChainIDE shield NFT #".concat(self.id.toString()),
                        description: "ChainIDE is a cloud-based IDE for creating decentralized applications.",
                        thumbnail: MetadataViews.IPFSFile(
                            cid: "bafybeify7ul3fvtewfk6rkxqje4ofwm7enekgiy7hc5qpjcrqcj653tg54",
                            path: self.type.concat(".jpg")
                        )
                    )
                case Type<MetadataViews.Editions>():
                    let editionInfo = MetadataViews.Edition(name: "ChainIDE Shield NFT Edition", number: self.id, max: ChainIDEShieldNFT.maxSupply)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(
                        editionList
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties([])
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://chainide.com/")
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: ChainIDEShieldNFT.CollectionStoragePath,
                        publicPath: ChainIDEShieldNFT.CollectionPublicPath,
                        providerPath: /private/ChainIDEShieldNFTCollection,
                        publicCollection: Type<&ChainIDEShieldNFT.Collection{ChainIDEShieldNFT.ChainIDEShieldNFTCollectionPublic}>(),
                        publicLinkedType: Type<&ChainIDEShieldNFT.Collection{ChainIDEShieldNFT.ChainIDEShieldNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&ChainIDEShieldNFT.Collection{ChainIDEShieldNFT.ChainIDEShieldNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-ChainIDEShieldNFT.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://ipfs.io/ipfs/bafkreietoyammygl7liiqboujde5fle4tz4ts6fhwljdnwnaj36bv4kly4"
                        ),
                        mediaType: "image/jpg"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: ChainIDEShieldNFT.CollectionName,
                        description: ChainIDEShieldNFT.CollectionDesc,
                        externalURL: MetadataViews.ExternalURL("https://chainide.com"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/ChainIDE")
                        }
                    )
                case Type<MetadataViews.Traits>():
                    // exclude mintedTime and type to show other uses of Traits
                    let excludedTraits = ["mintedTime"]
                    let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)

                    // mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
                    let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
                    traitsView.addTrait(mintedTimeTrait)

                    return traitsView

            }
            return nil
        }
    }

    /// Defines the methods that are particular to this NFT contract collection
    ///
    pub resource interface ChainIDEShieldNFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowChainIDEShieldNFT(id: UInt64): &ChainIDEShieldNFT.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow ChainIDEShieldNFT reference: the ID of the returned reference is incorrect"
            }
        }
    }

    /// The resource that will be holding the NFTs inside any account.
    /// In order to be able to manage NFTs any account will need to create
    /// an empty collection first
    ///
    pub resource Collection: ChainIDEShieldNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
            let token <- token as! @ChainIDEShieldNFT.NFT

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
        pub fun borrowChainIDEShieldNFT(id: UInt64): &ChainIDEShieldNFT.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &ChainIDEShieldNFT.NFT
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
            let ChainIDEShieldNFT = nft as! &ChainIDEShieldNFT.NFT
            return ChainIDEShieldNFT as &AnyResource{MetadataViews.Resolver}
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

        /// Mints a new NFT with a new ID and deposit it in the
        /// recipients collection using their collection reference
        ///
        /// @param recipient: A capability to the collection where the new NFT will be deposited
        /// @param type: The type for the NFT metadata
        /// @param royalties: An array of Royalty structs, see MetadataViews docs
        ///
        pub fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            type: String,
        ) {

            pre {
                ChainIDEShieldNFT.totalSupply < ChainIDEShieldNFT.maxSupply : "ChainIDEShieldNFT: soldout."
            }
            let metadata: {String: AnyStruct} = {}
            let currentBlock = getCurrentBlock()
            metadata["mintedBlock"] = currentBlock.height
            metadata["mintedTime"] = currentBlock.timestamp
            metadata["minter"] = recipient.owner!.address
            metadata["type"] = type

            // create a new NFT
            var newNFT <- create NFT(
                id: ChainIDEShieldNFT.totalSupply,
                type: type,
                metadata: metadata,
            )

            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newNFT)

            ChainIDEShieldNFT.totalSupply = ChainIDEShieldNFT.totalSupply + UInt64(1)

        }
    }

    init(_maxSupply: UInt64) {
        // Initialize the total supply
        self.totalSupply = 0

        self.maxSupply = _maxSupply

        // Set collection name and description
        self.CollectionName = "ChainIDE Shield NFT"
        self.CollectionDesc = "ChainIDE is a cloud-based IDE for creating decentralized applications to deploy on blockchains."

        // Set the named paths
        self.CollectionStoragePath = /storage/ChainIDEShieldNFTCollection
        self.CollectionPublicPath = /public/ChainIDEShieldNFTCollection
        self.MinterStoragePath = /storage/ChainIDEShieldNFTMinter

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // create a public capability for the collection
        self.account.link<&ChainIDEShieldNFT.Collection{NonFungibleToken.CollectionPublic, ChainIDEShieldNFT.ChainIDEShieldNFTCollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}
