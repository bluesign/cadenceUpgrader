import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FlowversePrimarySaleV2 from "./FlowversePrimarySaleV2.cdc"
import FindViews from "../0x097bafa4e0b48eef/FindViews.cdc"

pub contract FlowverseShirt: NonFungibleToken {

    // Events
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event EntityCreated(id: UInt64, metadata: {String:String})
    pub event EntityUpdated(id: UInt64, metadata: {String:String})
    pub event NFTMinted(nftID: UInt64, nftUUID: UInt64, entityID: UInt64, minterAddress: Address)
    pub event NFTDestroyed(nftID: UInt64)

    // Named Paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let AdminStoragePath: StoragePath

    access(self) var entityDatas: {UInt64: Entity}
    access(self) var numMintedPerEntity: {UInt64: UInt64}

    // Total number of FlowverseShirt NFTs that have been minted
    // Incremented ID used to create nfts
    pub var totalSupply: UInt64

    // Incremented ID used to create entities
    pub var nextEntityID: UInt64

    // Entity is a blueprint that holds metadata associated with an NFT
    pub struct Entity {
        // Unique ID for the entity
        pub let entityID: UInt64

        // Stores all the metadata about the entity as a string mapping
        pub(set) var metadata: {String: String}

        init(metadata: {String: String}) {
            pre {
                metadata.length != 0: "New Entity metadata cannot be empty"
            }
            self.entityID = FlowverseShirt.nextEntityID
            self.metadata = metadata
        }

        access(contract) fun removeMetadata(key: String) {
            self.metadata.remove(key: key)
        }

        access(contract) fun setMetadata(key: String, value: String) {
            self.metadata[key] = value
        }
    }

    // NFT Resource that represents the Entity instances
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        // Global unique NFT ID
        pub let id: UInt64

        // The ID of the Entity that the NFT references
        pub let entityID: UInt64

        // The minterAddress of the NFT
        pub let minterAddress: Address

        init(entityID: UInt64, minterAddress: Address) {
            self.id = FlowverseShirt.totalSupply
            self.entityID = entityID
            self.minterAddress = minterAddress

            emit NFTMinted(nftID: self.id, nftUUID: self.uuid, entityID: entityID, minterAddress: self.minterAddress)
        }

        // If the NFT is destroyed, emit an event to indicate 
        // to outside observers that it has been destroyed
        destroy() {
            emit NFTDestroyed(nftID: self.id)
        }

        pub fun checkSoulbound(): Bool {
            return FlowverseShirt.getEntityMetaDataByField(entityID: self.entityID, field: "soulbound") == "true"
        }

        pub fun getViews(): [Type] {
            let supportedViews = [
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Edition>(),
                Type<MetadataViews.Traits>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.Rarity>()
            ]
            if self.checkSoulbound() == true {
                supportedViews.append(Type<FindViews.SoulBound>())
            }
            return supportedViews
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: FlowverseShirt.CollectionStoragePath,
                        publicPath: FlowverseShirt.CollectionPublicPath,
                        providerPath: /private/FlowverseShirtCollection,
                        publicCollection: Type<&FlowverseShirt.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, FlowverseShirt.CollectionPublic, MetadataViews.ResolverCollection}>(),
                        publicLinkedType: Type<&FlowverseShirt.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, FlowverseShirt.CollectionPublic, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&FlowverseShirt.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, FlowverseShirt.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                        createEmptyCollection: (fun(): @NonFungibleToken.Collection {return <- FlowverseShirt.createEmptyCollection()})
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    return MetadataViews.NFTCollectionDisplay(
                        name: "Flowverse Shirt",
                        description: "The Flowverse Shirt is the official shirt collection for the Flowverse community. Join a group of die-hard Flow enthusiasts and rep the Flowverse Shirt on the Flow Blockchain",
                        externalURL: MetadataViews.ExternalURL("https://twitter.com/flowverse_"),
                        squareImage: MetadataViews.Media(
                            file: MetadataViews.HTTPFile(
                                url: "https://flowverse.myfilebase.com/ipfs/QmeFH4AXFLkCzKJ64nRmtRyqxXsVH8N98QDZcUNwJphXBz"
                            ),
                            mediaType: "image/png"
                        ),
                        bannerImage: MetadataViews.Media(
                            file: MetadataViews.HTTPFile(
                                url: "https://flowverse.myfilebase.com/ipfs/QmSevyXCcgmHse2TTc6mtK2sdAGDSWncERUXrFYP2hxMgu"
                            ),
                            mediaType: "image/png"
                        ),
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/flowverse_")
                        }
                    )
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: (FlowverseShirt.getEntityMetaDataByField(entityID: self.entityID, field: "name") ?? "").concat(" #").concat(self.id.toString()),
                        description: FlowverseShirt.getEntityMetaDataByField(entityID: self.entityID, field: "description") ?? "",
                        thumbnail: MetadataViews.HTTPFile(
                          url: FlowverseShirt.getEntityMetaDataByField(entityID: self.entityID, field: "thumbnailURL") ?? ""
                        )
                    )
                case Type<MetadataViews.Medias>():
                    let mediaURL = FlowverseShirt.getEntityMetaDataByField(entityID: self.entityID, field: "mediaURL")
                    let mediaType = FlowverseShirt.getEntityMetaDataByField(entityID: self.entityID, field: "mediaType")
                    if mediaURL != nil && mediaType != nil {
                        let media = MetadataViews.Media(
                            file: MetadataViews.HTTPFile(
                                url: mediaURL!
                            ),
                            mediaType: mediaType!
                        )
                        return MetadataViews.Medias([media])
                    }
                    return MetadataViews.Medias([])
                case Type<MetadataViews.Royalties>():
                    let royalties : [MetadataViews.Royalty] = [
                        MetadataViews.Royalty(
                            receiver: getAccount(0x604b63bcbef5974f).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!,
                            cut: 0.05,
                            description: "Creator Royalty Fee")
                    ]
                    return MetadataViews.Royalties(cutInfos: royalties)
                case Type<MetadataViews.Traits>():
                    let traits: [MetadataViews.Trait] = []
                    return MetadataViews.Traits(traits)
                case Type<MetadataViews.ExternalURL>():
                    let baseURL = "https://nft.flowverse.co/collections/FlowverseShirts/"
                    return MetadataViews.ExternalURL(baseURL.concat(self.owner!.address.toString()).concat("/".concat(self.id.toString())))
                case Type<FindViews.SoulBound>():
                    if self.checkSoulbound() == true {
                        return FindViews.SoulBound(
                            "This NFT cannot be transferred."
                        )
                    }
                    return nil
            }
            return nil
        }   
    }

    access(self) fun mint(entityID: UInt64, minterAddress: Address): @NFT {
        pre {
            FlowverseShirt.entityDatas[entityID] != nil: "Cannot mint: the entity doesn't exist."
        }

        // Gets the number of NFTs that have been minted for this Entity
        let entityMintNumber = FlowverseShirt.numMintedPerEntity[entityID]!

        // Increment the global NFT ID
        FlowverseShirt.totalSupply = FlowverseShirt.totalSupply + UInt64(1)

        // Mint the new NFT
        let newNFT: @NFT <- create NFT(entityID: entityID, minterAddress: minterAddress)

        // Increment the number of copies minted for this NFT
        FlowverseShirt.numMintedPerEntity[entityID] = entityMintNumber + UInt64(1)
        return <-newNFT
    }

    pub resource NFTMinter: FlowversePrimarySaleV2.IMinter {
        init() {}
        pub fun mint(entityID: UInt64, minterAddress: Address): @NFT {
            return <-FlowverseShirt.mint(entityID: entityID, minterAddress: minterAddress)
        }
    }

    // Admin is a special authorization resource that 
    // allows the owner to perform important functions to modify the 
    // various aspects of the Entities, Sets, and NFTs
    //
    pub resource Admin {

        // createEntity creates a new Entity struct 
        // and stores it in the Entities dictionary in the FlowverseShirt smart contract
        pub fun createEntity(metadata: {String: String}): UInt64 {
            // Create the new Entity
            var newEntity = Entity(metadata: metadata)
            let newID = newEntity.entityID

            // Increment the ID so that it isn't used again
            FlowverseShirt.nextEntityID = FlowverseShirt.nextEntityID + UInt64(1)

            // Store it in the contract storage
            FlowverseShirt.entityDatas[newID] = newEntity

            // Initialise numMintedPerEntity
            FlowverseShirt.numMintedPerEntity[newID] = UInt64(0)
            
            emit EntityCreated(id: newID, metadata: metadata)

            return newID
        }
        
        // updateEntity updates an existing Entity 
        pub fun updateEntity(entityID: UInt64, metadata: {String: String}) {
            let updatedEntity = FlowverseShirt.entityDatas[entityID]!
            updatedEntity.metadata = metadata
            FlowverseShirt.entityDatas[entityID] = updatedEntity
            
            emit EntityUpdated(id: entityID, metadata: metadata)
        }

        pub fun setEntitySoulbound(entityID: UInt64, soulbound: Bool) {
            assert(FlowverseShirt.entityDatas[entityID] != nil, message: "Cannot set soulbound: the entity doesn't exist.")
            if soulbound {
                FlowverseShirt.entityDatas[entityID]!.setMetadata(key: "soulbound", value: "true")
            } else {
                FlowverseShirt.entityDatas[entityID]!.removeMetadata(key: "soulbound")
            }
        }

        pub fun mint(entityID: UInt64, minterAddress: Address): @NFT {
            return <-FlowverseShirt.mint(entityID: entityID, minterAddress: minterAddress)
        }

        // createNFTMinter creates a new NFTMinter resource
        pub fun createNFTMinter(): @NFTMinter {
            return <-create NFTMinter()
        }

        // createNewAdmin creates a new Admin resource
        pub fun createNewAdmin(): @Admin {
            return <-create Admin()
        }
    }

    // Public interface for the FlowverseShirt Collection that allows users access to certain functionalities
    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowFlowverseShirtNFT(id: UInt64): &FlowverseShirt.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow FlowverseShirt reference: The ID of the returned reference is incorrect"
            }
        }
        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver}
    }

    // Collection of FlowverseShirt NFTs owned by an account
    pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // Dictionary of entity instances conforming tokens
        // NFT is a resource type with a UInt64 ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            let nft <- token as! @NFT

            // Check if the NFT is soulbound. Secondary marketplaces will use the
            // withdraw function, so if the NFT is soulbound, it will not be transferrable,
            // and hence cannot be sold.
            if nft.checkSoulbound() == true {
                panic("This NFT is not transferrable.")
            }

            emit Withdraw(id: withdrawID, from: self.owner?.address)
            return <- nft
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @FlowverseShirt.NFT
            let id: UInt64 = token.id
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)
            destroy oldToken
        }

        pub fun batchDeposit(tokens: @NonFungibleToken.Collection) {
            let keys = tokens.getIDs()
            for key in keys {
                self.deposit(token: <-tokens.withdraw(withdrawID: key))
            }
            destroy tokens
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowFlowverseShirtNFT(id: UInt64): &FlowverseShirt.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &FlowverseShirt.NFT
            } else {
                return nil
            }
        }
        
        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)! 
            let nftRef = nft as! &FlowverseShirt.NFT
            return nftRef as &{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // -----------------------------------------------------------------------
    // FlowverseShirt contract-level function definitions
    // -----------------------------------------------------------------------

    // createEmptyCollection
    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create FlowverseShirt.Collection()
    }

    // getAllEntities returns all the entities available
    pub fun getAllEntities(): [FlowverseShirt.Entity] {
        return FlowverseShirt.entityDatas.values
    }

    // getEntity returns an entity by ID
    pub fun getEntity(entityID: UInt64): FlowverseShirt.Entity? {
        return self.entityDatas[entityID]
    }

    // getEntityMetaData returns all the metadata associated with a specific Entity
    pub fun getEntityMetaData(entityID: UInt64): {String: String}? {
        return self.entityDatas[entityID]?.metadata
    }
    
    pub fun getEntityMetaDataByField(entityID: UInt64, field: String): String? {
        if let entity = FlowverseShirt.entityDatas[entityID] {
            return entity.metadata[field]
        } else {
            return nil
        }
    }

    pub fun getNumMintedPerEntity(): {UInt64: UInt64} {
        return self.numMintedPerEntity
    }

    // -----------------------------------------------------------------------
    // FlowverseShirt initialization function
    // -----------------------------------------------------------------------
    //
    init() {
        self.CollectionStoragePath = /storage/FlowverseShirtCollection
        self.CollectionPublicPath = /public/FlowverseShirtCollection
        self.AdminStoragePath = /storage/FlowverseShirtAdmin

        // Initialize contract fields
        self.entityDatas = {}
        self.numMintedPerEntity = {}
        self.nextEntityID = 1
        self.totalSupply = 0

        // Put a new Collection in storage
        self.account.save<@Collection>(<- create Collection(), to: self.CollectionStoragePath)

        // Create a public capability for the Collection
        self.account.link<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, CollectionPublic, MetadataViews.ResolverCollection}>(self.CollectionPublicPath, target: self.CollectionStoragePath)

        // Put the Admin resource in storage
        self.account.save<@Admin>(<- create Admin(), to: self.AdminStoragePath)

        emit ContractInitialized()
    }
}
 