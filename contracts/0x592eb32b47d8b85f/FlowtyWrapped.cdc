import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import ViewResolver from "../0x1d7e57aa55817448/ViewResolver.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

import FlowtyRaffles from "../0x2fb4614ede95ab2b/FlowtyRaffles.cdc"
import FlowtyRaffleSource from "../0x2fb4614ede95ab2b/FlowtyRaffleSource.cdc"

pub contract FlowtyWrapped: NonFungibleToken, ViewResolver {
    // Total supply of FlowtyWrapped NFTs
    pub var totalSupply: UInt64
    pub var collectionExternalUrl: String
    pub var nftExternalBaseUrl: String
    access(account) let editions: {String: {WrappedEdition}}

    /// The event that is emitted when the contract is created
    pub event ContractInitialized()

    pub event CollectionCreated(uuid: UInt64)

    /// The event that is emitted when an NFT is withdrawn from a Collection
    pub event Withdraw(id: UInt64, from: Address?)

    /// The event that is emitted when an NFT is deposited to a Collection
    pub event Deposit(id: UInt64, to: Address?)

    /// Storage and Public Paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let CollectionProviderPath: PrivatePath
    pub let AdminStoragePath: StoragePath
    pub let AdminPublicPath: PublicPath

    pub struct interface WrappedEdition {
        pub fun getName(): String
        pub fun resolveView(_ t: Type, _ nft: &NFT): AnyStruct?
        pub fun getEditionSupply(): UInt64

        access(account) fun setStatus(_ s: String)
        access(account) fun mint(address: Address, data: {String: AnyStruct}): @NFT
    }

    /// The core resource that represents a Non Fungible Token. 
    /// New instances will be created using the NFTMinter resource
    /// and stored in the Collection resource
    ///
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        /// The unique ID that each NFT has
        pub let id: UInt64
        pub let serial: UInt64
        pub let editionName: String
        pub let address: Address
        pub let data: {String: AnyStruct}

        init(
            id: UInt64,
            serial: UInt64,
            editionName: String,
            address: Address,
            data: {String: AnyStruct}
        ) {
            self.id = id
            self.serial = serial
            self.editionName = editionName
            self.address = address
            self.data = data
        }

        /// Function that returns all the Metadata Views implemented by a Non Fungible Token
        ///
        /// @return An array of Types defining the implemented views. This value will be used by
        ///         developers to know which parameter to pass to the resolveView() method.
        ///
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Medias>(),
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
                    let edition = FlowtyWrapped.getEditionRef(self.editionName)
                    return edition.resolveView(view, &self as &NFT)
                case Type<MetadataViews.Medias>():
                    let edition = FlowtyWrapped.getEditionRef(self.editionName)
                    return edition.resolveView(view, &self as &NFT)
                case Type<MetadataViews.Editions>():
                    let edition = FlowtyWrapped.getEditionRef(self.editionName)
                    return edition.resolveView(view, &self as &NFT)
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.serial
                    )
                case Type<MetadataViews.Royalties>():
                    return nil
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL(FlowtyWrapped.nftExternalBaseUrl.concat("/").concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return FlowtyWrapped.resolveView(view)
                case Type<MetadataViews.NFTCollectionDisplay>():
                    return FlowtyWrapped.resolveView(view)
                case Type<MetadataViews.Traits>():
                    let edition = FlowtyWrapped.getEditionRef(self.editionName)
                    return edition.resolveView(view, &self as &NFT)
            }
            return nil
        }
    }

    /// Defines the methods that are particular to this NFT contract collection
    ///
    pub resource interface FlowtyWrappedCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowFlowtyWrapped(id: UInt64): &FlowtyWrapped.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow FlowtyWrapped reference: the ID of the returned reference is incorrect"
            }
        }
    }

    /// The resource that will be holding the NFTs inside any account.
    /// In order to be able to manage NFTs any account will need to create
    /// an empty collection first
    ///
    pub resource Collection: FlowtyWrappedCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
            assert(false, message: "Flowty Wrapped is not transferrable.")

            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        /// Adds an NFT to the collections dictionary and adds the ID to the id array
        ///
        /// @param token: The NFT resource to be included in the collection
        /// 
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @FlowtyWrapped.NFT
            let nftOwnerAddress = token.address

            assert(nftOwnerAddress == self.owner?.address, message: "The NFT must be owned by the collection owner")

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
        pub fun borrowFlowtyWrapped(id: UInt64): &FlowtyWrapped.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &FlowtyWrapped.NFT
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
            return nft as! &FlowtyWrapped.NFT
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
        let c <- create Collection()
        emit CollectionCreated(uuid: c.uuid)
        return <- c
    }

    pub resource interface AdminPublic {}

    /// Resource that an admin or something similar would own to be
    /// able to mint new NFTs
    ///
    pub resource Admin: AdminPublic {
        /// Mints a new NFT with a new ID and deposit it in the
        /// recipients collection using their collection reference
        ///
        /// @param recipient: A capability to the collection where the new NFT will be deposited
        ///
        pub fun mintNFT(editionName: String, address: Address, data: {String: AnyStruct}): @FlowtyWrapped.NFT {
            // we want IDs to start at 1, so we'll increment first
            FlowtyWrapped.totalSupply = FlowtyWrapped.totalSupply + 1

            let edition = FlowtyWrapped.getEditionRef(editionName)
            let nft <- edition.mint(address: address, data: data)

            return <- nft
        }

        pub fun getEdition(editionName: String): AnyStruct{
            let edition = FlowtyWrapped.getEditionRef(editionName)
            return edition
        }

        pub fun registerEdition(_ edition: {WrappedEdition}) {
            pre {
                FlowtyWrapped.editions[edition.getName()] == nil: "edition name already exists"
            }

            FlowtyWrapped.editions[edition.getName()] = edition
        }

        pub fun setCollectionExternalUrl(_ s: String) {
            FlowtyWrapped.collectionExternalUrl = s
        }

        pub fun createAdmin(): @Admin {
            return <- create Admin()
        }
    }

    /// Function that resolves a metadata view for this contract.
    ///
    /// @param view: The Type of the desired view.
    /// @return A structure representing the requested view.
    ///
    pub fun resolveView(_ view: Type): AnyStruct? {
        switch view {
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                    storagePath: FlowtyWrapped.CollectionStoragePath,
                    publicPath: FlowtyWrapped.CollectionPublicPath,
                    providerPath: FlowtyWrapped.CollectionProviderPath,
                    publicCollection: Type<&FlowtyWrapped.Collection{FlowtyWrapped.FlowtyWrappedCollectionPublic}>(),
                    publicLinkedType: Type<&FlowtyWrapped.Collection{FlowtyWrapped.FlowtyWrappedCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                    providerLinkedType: Type<&FlowtyWrapped.Collection{FlowtyWrapped.FlowtyWrappedCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                    createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                        return <-FlowtyWrapped.createEmptyCollection()
                    })
                )
            case Type<MetadataViews.NFTCollectionDisplay>():
                return MetadataViews.NFTCollectionDisplay(
                        name: "Flowty Wrapped",
                        description: "A celebration and statistical review of an exciting year on Flowty and across the Flow blockchain ecosystem.",
                        externalURL: MetadataViews.ExternalURL(FlowtyWrapped.collectionExternalUrl),
                        squareImage: MetadataViews.Media(
                            file: MetadataViews.IPFSFile(
                                url: "QmdCiwwJ7z2gQecDr6hn4pJj91miWYnFC178o9p6JKftmi",
                                nil
                            ),
                            mediaType: "image/jpg"
                        ),
                        bannerImage: MetadataViews.Media(
                            file: MetadataViews.IPFSFile(
                                url: "QmcLJhJh6yuLAoH6wWKMDS2zUv6myduXQc83zD5xv2V8tA",
                                nil
                            ),
                            mediaType: "image/jpg"
                        ),
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/flowty_io")
                        }
                    )
        }
        return nil
    }

    /// Function that returns all the Metadata Views implemented by a Non Fungible Token
    ///
    /// @return An array of Types defining the implemented views. This value will be used by
    ///         developers to know which parameter to pass to the resolveView() method.
    ///
    pub fun getViews(): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>()
        ]
    }

    access(account) fun getRaffleManager(): &FlowtyRaffles.Manager {
        return self.account.borrow<&FlowtyRaffles.Manager>(from: FlowtyRaffles.ManagerStoragePath)!
    }

    access(contract) fun borrowAdmin(): &Admin {
        return self.account.borrow<&Admin>(from: self.AdminStoragePath)!
    }

    access(account) fun mint(
        id: UInt64,
        serial: UInt64,
        editionName: String,
        address: Address,
        data: {String: AnyStruct}): @NFT {
            return <- create NFT(id: id, serial: serial, editionName: editionName, address: address, data: data)
    }

    access(contract) fun getEditionRef(_ name: String): &{WrappedEdition} {
        pre {
            self.editions[name] != nil: "no edition found with given name"
        }
        return (&self.editions[name] as &{WrappedEdition}?)!
    }

    pub fun getEdition(_ name: String): {WrappedEdition} {
        return self.editions[name] ?? panic("no edition found with given name")
    }

    pub fun getAccountAddress(): Address {
        return self.account.address
    }

    init() {
        // Initialize the total supply
        self.totalSupply = 0

        let identifier = "FlowtyWrapped_".concat(self.account.address.toString())

        // Set the named paths
        self.CollectionStoragePath = StoragePath(identifier: identifier)!
        self.CollectionPublicPath = PublicPath(identifier: identifier)!
        self.CollectionProviderPath = PrivatePath(identifier: identifier)!
        self.AdminStoragePath = StoragePath(identifier: identifier.concat("_Minter"))!
        self.AdminPublicPath = PublicPath(identifier: identifier.concat("_Minter"))!

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // create a public capability for the collection
        self.account.link<&FlowtyWrapped.Collection{NonFungibleToken.CollectionPublic, FlowtyWrapped.FlowtyWrappedCollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath 
        )

        // Create a Minter resource and save it to storage
        let minter <- create Admin()
        self.account.save(<-minter, to: self.AdminStoragePath)
        self.account.link<&Admin{AdminPublic}>(self.AdminPublicPath, target: self.AdminStoragePath)

        emit ContractInitialized()

        let manager <- FlowtyRaffles.createManager()
        self.account.save(<-manager, to: FlowtyRaffles.ManagerStoragePath)
        self.account.link<&FlowtyRaffles.Manager{FlowtyRaffles.ManagerPublic}>(FlowtyRaffles.ManagerPublicPath, target: FlowtyRaffles.ManagerStoragePath)

        self.collectionExternalUrl = "https://flowty.io/collection/".concat(self.account.address.toString()).concat("/FlowtyWrapped")
        self.nftExternalBaseUrl = "https://flowty.io/asset/".concat(self.account.address.toString()).concat("/FlowtyWrapped")
        self.editions = {}
    }
}