import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract MoxyNFT: NonFungibleToken {

    pub var totalSupply: UInt64

    access(contract) var editions: {UInt64: Edition}
    access(contract) var editionIndex: UInt64

    access(contract) var catalogList: {UInt64:Catalog}
    access(contract) var catalogListIndex: UInt64

    access(contract) var mintRequest: MintRequest?


    pub var catalogsTotalSupply: {UInt64:UInt64}
    pub var editionsTotalSupply: {UInt64:UInt64}

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event NFTMinted(catalogId: UInt64, editionId: UInt64, tokensMinted: UInt64)
    pub event CatalogAdded(collectionId: UInt64, name: String)
    pub event NFTMintRequestStored(catalogId: UInt64, editionId: UInt64, tokensToMint: UInt64)
    pub event NFTMintRequestFinished(catalogId: UInt64, editionId: UInt64, tokensMinted: UInt64)
    pub event ProcessMintRequestStarted(catalogId: UInt64, editionId: UInt64)
    pub event ProcessMintRequestFinished(catalogId: UInt64, editionId: UInt64, nftMinted: UInt64, remaining: UInt64 )

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath


    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64

        pub let catalogId: UInt64
        pub let editionId: UInt64
        access(self) let royalties: [MetadataViews.Royalty]
        access(self) let metadata: {String: AnyStruct}
        pub let edition: UInt64

        init(
            id: UInt64,
            catalogId: UInt64,
            editionId: UInt64,
            royalties: [MetadataViews.Royalty],
            metadata: {String: AnyStruct},
            edition: UInt64,
        ) {
            pre {
                MoxyNFT.editions[editionId] != nil : "The edition does not exists"
                MoxyNFT.catalogList[catalogId] != nil : "Catalog/Collection does not exists"
            }
            self.id = id
            self.catalogId = catalogId
            self.editionId = editionId
            self.royalties = royalties
            self.metadata = metadata
            self.edition = edition
        }

        pub fun getEdition(): Edition {
            return MoxyNFT.editions[self.editionId]!
        }

        pub fun getCid(): String {
            return self.getEdition().cid
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>(),
                Type<MetadataViews.IPFSFile>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            let edition = self.getEdition()
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: edition.name,
                        description: edition.description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: edition.thumbnail
                        )
                    )
                case Type<MetadataViews.Editions>():
                    let editionInfo = MetadataViews.Edition(name: self.getEdition().name, number: self.edition, max: edition.maxEdition)
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
                    return MetadataViews.ExternalURL("https://moxy.io/nft".concat(self.id.toString()))
                
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: MoxyNFT.CollectionStoragePath,
                        publicPath: MoxyNFT.CollectionPublicPath,
                        providerPath: /private/moxyNFTCollection,
                        publicCollection: Type<&MoxyNFT.Collection{MoxyNFT.MoxyNFTCollectionPublic}>(),
                        publicLinkedType: Type<&MoxyNFT.Collection{MoxyNFT.MoxyNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&MoxyNFT.Collection{MoxyNFT.MoxyNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-MoxyNFT.createEmptyCollection()
                        })
                    )
                
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let catalog = MoxyNFT.getCatalog(id: self.catalogId)!
                    
                    return MetadataViews.NFTCollectionDisplay(
                        name: catalog.name,
                        description: catalog.description,
                        externalURL: MetadataViews.ExternalURL(catalog.externalURL),
                        squareImage: catalog.squareImage,
                        bannerImage: catalog.bannerImage,
                        socials: catalog.socials
                    )
                
                case Type<MetadataViews.Traits>():
                    let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: [])

                    // mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
                    let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
                    traitsView.addTrait(mintedTimeTrait)

                    let rarityTag = MetadataViews.Rarity(score: nil, max: nil, description: edition.rarityDescription)
                    let rarityTrait = MetadataViews.Trait(name: "rarityTag", value: rarityTag, displayType: nil, rarity: rarityTag)
                    traitsView.addTrait(rarityTrait)
                    
                    return traitsView
                case Type<MetadataViews.IPFSFile>():
                    return MetadataViews.IPFSFile(cid: edition.cid, path: "path/algo")
            }
            return nil
        }
        
        
    }

    pub resource interface MoxyNFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun getCatalogsInfo(): {UInt64: UInt64}
        pub fun getEditionsInfo(): {UInt64: UInt64}
        pub fun getCatalogTotal(catalogId: UInt64): UInt64
        pub fun getEditionTotal(editionId: UInt64): UInt64
        pub fun hasCatalog(catalogId: UInt64): Bool 
        pub fun hasEdition(editionId: UInt64): Bool 
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowMoxyNFT(id: UInt64): &MoxyNFT.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow MoxyNFT reference: the ID of the returned reference is incorrect"
            }
        }
    }

    // Struct to return info from a Catalog to be used on Views
    pub struct CatalogInfo {
        pub var id: UInt64
        pub var name: String
        pub var description: String
        pub var externalURL: String
        pub var squareImage: MetadataViews.Media
        pub var bannerImage: MetadataViews.Media
        pub var socials: {String:MetadataViews.ExternalURL}

        init(id: UInt64, name: String, description: String, externalURL: String, squareImage: String, bannerImage: String, socials: {String:MetadataViews.ExternalURL}) {
            self.id = id
            self.name = name
            self.description = description
            self.externalURL = externalURL
            self.squareImage = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: squareImage
                        ),
                        mediaType: "image/jpeg"
                    )
            self.bannerImage = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: bannerImage
                        ),
                        mediaType: "image/jpeg"
                    )
            self.socials = socials
        }
    }

    pub struct Catalog {
        pub var id: UInt64
        pub var name: String
        pub var description: String
        pub var externalURL: String
        pub var squareImage: String
        pub var bannerImage: String
        pub var socials: {String:MetadataViews.ExternalURL}
        
        pub fun getInfo(): CatalogInfo {
            return CatalogInfo(id: self.id, name: self.name, description: self.description, externalURL: self.externalURL, 
                                    squareImage: self.squareImage, bannerImage: self.bannerImage, socials: self.socials)

        }

        init(id: UInt64, name: String, description: String, externalURL: String, squareImage: String, bannerImage: String, socials: {String:MetadataViews.ExternalURL}) {
            self.id = id
            self.name = name
            self.description = description
            self.externalURL = externalURL
            self.squareImage = squareImage
            self.bannerImage = bannerImage
            self.socials = socials
        }

    }


    pub struct Edition {
        pub let id: UInt64
        pub let name: String
        pub let description: String
        pub let thumbnail: String
        pub let cid: String
        pub let rarityDescription: String
        pub let maxEdition: UInt64

        init(
            name: String,
            description: String,
            thumbnail: String,
            cid: String,
            rarityDescription: String,
            maxEdition: UInt64,
        ) {
            MoxyNFT.editionIndex = MoxyNFT.editionIndex + 1
            self.id = MoxyNFT.editionIndex
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.cid = cid
            self.rarityDescription = rarityDescription
            self.maxEdition = maxEdition
        }

    }


    pub resource Collection: MoxyNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        pub var catalogs: {UInt64:UInt64} 
        pub var editions: {UInt64:UInt64} 

        init () {
            self.ownedNFTs <- {}
            self.catalogs = {}
            self.editions = {}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            let to <- token as! @MoxyNFT.NFT

            self.unregisterToken(catalogId: to.catalogId, editionId: to.editionId)

            let tok <- to as @NonFungibleToken.NFT
            
            emit Withdraw(id: tok.id, from: self.owner?.address)

            return <-tok
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @MoxyNFT.NFT

            let id: UInt64 = token.id

            self.registerToken(catalogId: token.catalogId, editionId: token.editionId)

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        pub fun registerToken(catalogId: UInt64, editionId: UInt64) {
            if (self.catalogs[catalogId] == nil) {
                self.catalogs[catalogId] = 0
            }
            if (self.editions[editionId] == nil) {
                self.editions[editionId] = 0
            }
            self.catalogs[catalogId] = self.catalogs[catalogId]! + 1
            self.editions[editionId] = self.editions[editionId]! + 1
        }

        pub fun unregisterToken(catalogId: UInt64, editionId: UInt64) {
            self.catalogs[catalogId] = self.catalogs[catalogId]! - 1
            self.editions[editionId] = self.editions[editionId]! - 1

            if (self.catalogs[catalogId] == 0) {
                self.catalogs.remove(key: catalogId)
            }
            if (self.editions[editionId] == 0) {
                self.editions.remove(key: editionId)
            }
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun getCatalogsInfo(): {UInt64: UInt64} {
            return self.catalogs
        }

        pub fun getEditionsInfo(): {UInt64: UInt64} {
            return self.editions
        }

        pub fun getCatalogTotal(catalogId: UInt64): UInt64 {
            if (self.catalogs[catalogId] == nil) {
                return 0
            }
            return self.catalogs[catalogId]!
        }

        pub fun getEditionTotal(editionId: UInt64): UInt64 {
            if (self.editions[editionId] == nil) {
                return 0
            }
            return self.editions[editionId]!
        }

        pub fun hasCatalog(catalogId: UInt64): Bool {
            return self.catalogs[catalogId] != nil
        }

        pub fun hasEdition(editionId: UInt64): Bool {
            return self.editions[editionId] != nil
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }
 
        pub fun borrowMoxyNFT(id: UInt64): &MoxyNFT.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &MoxyNFT.NFT
            }

            return nil
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let MoxyNFT = nft as! &MoxyNFT.NFT
            return MoxyNFT as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub struct MintRequest {
        pub var recipient: Address
        pub var catalogId: UInt64
        pub var editionId: UInt64
        pub var royalties: [MetadataViews.Royalty]
        pub var currentEdition: UInt64

        pub fun editionMinted() {
            self.currentEdition = self.currentEdition + 1
        }

        pub fun hasFinished(): Bool {
            return self.currentEdition > MoxyNFT.editions[self.editionId]!.maxEdition
        }

        pub fun hasPendings(): Bool {
            return !self.hasFinished()
        }

        pub fun getRemainings(): UInt64 {
            return MoxyNFT.editions[self.editionId]!.maxEdition - (self.currentEdition - 1)
        }
        
        init(recipient: Address, catalogId: UInt64, editionId: UInt64, royalties: [MetadataViews.Royalty]) {
            self.recipient = recipient
            self.catalogId = catalogId
            self.editionId = editionId
            self.royalties = royalties
            self.currentEdition = 1
        }
    }

    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
    pub resource NFTMinter {

        // mintNFT mints a new NFT with a new ID
        // and deposit it in the recipients collection using their collection reference
        access(contract) fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            catalogId: UInt64,
            editionId: UInt64,
            royalties: [MetadataViews.Royalty],
            edition: UInt64,
        ) {
            pre {
                MoxyNFT.editions[editionId] != nil : "The edition does not exists."
            }

            let metadata: {String: AnyStruct} = {}
            let currentBlock = getCurrentBlock()
            metadata["mintedBlock"] = currentBlock.height
            metadata["mintedTime"] = currentBlock.timestamp
            metadata["minter"] = recipient.owner!.address

            // create a new NFT
            var newNFT <- create NFT(
                id: MoxyNFT.totalSupply,
                catalogId: catalogId,
                editionId: editionId,
                royalties: royalties,
                metadata: metadata,
                edition: edition,
            )

            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newNFT)

            MoxyNFT.totalSupply = MoxyNFT.totalSupply + 1

            // Increment total supply by catalog id and edition id
            if (MoxyNFT.catalogsTotalSupply[catalogId] == nil) {
                MoxyNFT.catalogsTotalSupply[catalogId] = 0
            }
            if (MoxyNFT.editionsTotalSupply[editionId] == nil) {
                MoxyNFT.editionsTotalSupply[editionId] = 0
            }
            MoxyNFT.catalogsTotalSupply[catalogId] = MoxyNFT.catalogsTotalSupply[catalogId]! + 1 
            MoxyNFT.editionsTotalSupply[editionId] = MoxyNFT.editionsTotalSupply[editionId]! + 1 
        }

        pub fun batchMintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            catalogId: UInt64,
            name: String,
            description: String,
            thumbnail: String,
            cid: String,
            rarityDescription: String,
            royalties: [MetadataViews.Royalty],
            maxEdition: UInt64
        ) {
            pre {
                MoxyNFT.mintRequest == nil : "Can't mint, there is a mint request in course."
            }

            let edition = Edition(
                name: name,
                description: description,
                thumbnail: thumbnail,
                cid: cid,
                rarityDescription: rarityDescription,
                maxEdition: maxEdition
            )

            MoxyNFT.editions[edition.id] = edition

            MoxyNFT.mintRequest = MintRequest(recipient: recipient.owner!.address, catalogId: catalogId, editionId: edition.id, royalties: royalties)
            emit NFTMintRequestStored(catalogId: catalogId, editionId: edition.id, tokensToMint: maxEdition)

            self.processMintRequest(quantity: 100)
        }

        pub fun processMintRequest(quantity: UInt64) {
            pre {
                MoxyNFT.mintRequest != nil : "Can't process mint request, there is not a mint request in course."
            }

            var counter: UInt64 = 1
            emit ProcessMintRequestStarted(catalogId: MoxyNFT.mintRequest!.catalogId, editionId: MoxyNFT.mintRequest!.editionId)

            let recipientRef = getAccount(MoxyNFT.mintRequest!.recipient)
                                    .getCapability(MoxyNFT.CollectionPublicPath)
                                    .borrow<&{NonFungibleToken.CollectionPublic}>()
                                    ?? panic("Could not get receiver reference to the NFT Collection")

            while (MoxyNFT.mintRequest!.hasPendings() && counter <= quantity) {
                // create a new NFT

                self.mintNFT(
                    recipient: recipientRef,
                    catalogId: MoxyNFT.mintRequest!.catalogId,
                    editionId: MoxyNFT.mintRequest!.editionId,
                    royalties: MoxyNFT.mintRequest!.royalties,
                    edition: MoxyNFT.mintRequest!.currentEdition,
                )
                counter = counter + 1
                MoxyNFT.mintRequest!.editionMinted()
            }

            emit ProcessMintRequestFinished(catalogId: MoxyNFT.mintRequest!.catalogId, editionId: MoxyNFT.mintRequest!.editionId, nftMinted: counter - 1, remaining: MoxyNFT.mintRequest!.getRemainings() )

            if (MoxyNFT.mintRequest!.hasFinished()) {
                emit NFTMinted(catalogId: MoxyNFT.mintRequest!.catalogId, editionId: MoxyNFT.mintRequest!.editionId, tokensMinted: MoxyNFT.editions[MoxyNFT.mintRequest!.editionId]!.maxEdition)
                emit NFTMintRequestFinished(catalogId: MoxyNFT.mintRequest!.catalogId, editionId: MoxyNFT.mintRequest!.editionId, tokensMinted: MoxyNFT.editions[MoxyNFT.mintRequest!.editionId]!.maxEdition)
                MoxyNFT.mintRequest = nil
            }

        }

        pub fun addCatalog(name: String, description: String, externalURL: String, squareImage: String, 
                            bannerImage: String, socials: {String:MetadataViews.ExternalURL}) {
            MoxyNFT.catalogListIndex = MoxyNFT.catalogListIndex + 1
            let col = Catalog(id: MoxyNFT.catalogListIndex, name: name, 
                                            description: description, 
                                            externalURL: externalURL, 
                                            squareImage: squareImage, 
                                            bannerImage: bannerImage, 
                                            socials: socials)
            MoxyNFT.catalogList[col.id] = col
            emit CatalogAdded(collectionId: col.id, name: col.name)
        }

    }

    pub fun getCatalog(id: UInt64): CatalogInfo? {
        if (MoxyNFT.catalogList[id] == nil) {
            return nil
        }

        return MoxyNFT.catalogList[id]!.getInfo()
    }

    pub fun getCatalogTotalSupply(catalogId: UInt64): UInt64 {
        if (MoxyNFT.catalogsTotalSupply[catalogId] == nil) {
            return 0
        }
        return  MoxyNFT.catalogsTotalSupply[catalogId]!
    }

    pub fun getEditionTotalSupply(editionId: UInt64): UInt64 {
        if (MoxyNFT.editionsTotalSupply[editionId] == nil) {
            return 0
        }
        return  MoxyNFT.editionsTotalSupply[editionId]!
    }

    pub fun isNFTMiningInProgress(): Bool {
        return MoxyNFT.mintRequest != nil
    }


    init() {
        // Initialize the total supply
        self.totalSupply = 0

        self.editions = {}
        self.editionIndex = 0

        self.catalogList = {}
        self.catalogListIndex = 0

        self.catalogsTotalSupply = {}
        self.editionsTotalSupply = {}

        self.mintRequest = nil

        // Set the named paths
        self.CollectionStoragePath = /storage/moxyNFTCollection
        self.CollectionPublicPath = /public/moxyNFTCollection
        self.MinterStoragePath = /storage/moxyNFTMinter

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // create a public capability for the collection
        self.account.link<&MoxyNFT.Collection{NonFungibleToken.CollectionPublic, MoxyNFT.MoxyNFTCollectionPublic}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}
 
