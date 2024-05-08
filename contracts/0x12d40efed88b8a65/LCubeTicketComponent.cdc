import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"


//Wow! You are viewing LimitlessCube TicketComponent contract.

pub contract LCubeTicketComponent: NonFungibleToken {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath
    pub let MinterPublicPath: PublicPath

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Created(id: UInt64, metadata:{String:String})
    pub event Destroy(id: UInt64)

 pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {

    pub let id: UInt64

    pub let eventID: UInt64
    access(self) let metadata: {String:String}
    access(self) let seedBlock: UInt64
    access(self) let royalties: [MetadataViews.Royalty]

       init(id: UInt64, eventID: UInt64, metadata: {String:String}, royalties: [MetadataViews.Royalty]) {
            self.id = id
            self.eventID = eventID
            self.metadata = metadata
            self.royalties = royalties

            self.seedBlock = getCurrentBlock().height + 1
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                         name: self.metadata["name"] ?? "",
                        description: self.metadata["description"] ?? "",
                        thumbnail: MetadataViews.HTTPFile(url: self.metadata["thumbnail"] ?? ""),
                    )
                case Type<MetadataViews.Editions>():
                    let editionInfo = MetadataViews.Edition(name: "LimitlessCube Ticket Edition", number: self.id, max: nil)
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
                    return MetadataViews.ExternalURL("https://limitlesscube.io/flow/".concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: LCubeTicketComponent.CollectionStoragePath,
                        publicPath: LCubeTicketComponent.CollectionPublicPath,
                        providerPath: /private/LCubeNFTCollection,
                        publicCollection: Type<&LCubeTicketComponent.Collection{LCubeTicketComponentCollectionPublic}>(),
                        publicLinkedType: Type<&LCubeTicketComponent.Collection{LCubeTicketComponent.LCubeTicketComponentCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&LCubeTicketComponent.Collection{LCubeTicketComponent.LCubeTicketComponentCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-LCubeTicketComponent.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://limitlesscube.io/images/logo.svg"
                        ),
                        mediaType: "image/svg+xml"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "The LimitlessCube Collection",
                        description: "This collection is used as an LimitlessCube to help you develop your next Flow NFT.",
                        externalURL: MetadataViews.ExternalURL("https://limitlesscube.io/flow/MetadataViews"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "x": MetadataViews.ExternalURL("https://x.com/limitlesscube")
                        }
                    )
                case Type<MetadataViews.Traits>():
                    let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: ["name", "description","image","thumbnail","nftType","eventName"])

                    return traitsView
            }
            return nil
        }

        pub fun getMetadata(): {String:String} {
            return self.metadata
        }

        pub fun getRoyalties(): [MetadataViews.Royalty] {
            return self.royalties
        }

        destroy() {
            emit Destroy(id: self.id)
        }
  }

    pub resource interface LCubeTicketComponentCollectionPublic {

        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowComponent(id: UInt64): &LCubeTicketComponent.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Component reference: The ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: LCubeTicketComponentCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <- token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @LCubeTicketComponent.NFT

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

        pub fun borrowComponent(id: UInt64): &LCubeTicketComponent.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &LCubeTicketComponent.NFT
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            pre {
                self.ownedNFTs[id] != nil : "NFT does not exist"
            }
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let componentNFT = nft as! &LCubeTicketComponent.NFT
            return componentNFT
        }
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }


    pub resource ComponentMinter {

     priv fun createComponent(eventID: UInt64, metadata: {String:String},royalties: [MetadataViews.Royalty]) : @LCubeTicketComponent.NFT {

        var component <- create NFT(
                id: LCubeTicketComponent.totalSupply,
                eventID: eventID,
                metadata: metadata,
                royalties: royalties
                )

        LCubeTicketComponent.totalSupply = LCubeTicketComponent.totalSupply + 1
        emit Created(id: component.id, metadata: metadata)

        return <- component
    }

     pub fun batchCreateComponents(eventID: UInt64, metadata: {String:String}, royalties: [MetadataViews.Royalty], quantity: UInt8): @Collection {
        let newCollection <- create Collection()

        var i: UInt8 = 0
        while i < quantity {
            newCollection.deposit(token: <-self.createComponent(eventID: eventID, metadata: metadata, royalties: royalties))
            i = i + 1
        }

       return <-newCollection
        }
    }

  // pub fun minter(minterAccount:AuthAccount): Capability<&ComponentMinter> {
  //      return self.account.getCapability<&ComponentMinter>(self.MinterPublicPath)      
  //  }

	init() {
        self.CollectionPublicPath = /public/LCubeTicketComponentCollection
        self.CollectionStoragePath = /storage/LCubeTicketComponentCollection
        self.MinterPublicPath = /public/LCubeTicketComponentMinter
        self.MinterStoragePath = /storage/LCubeTicketComponentMinter

        self.totalSupply = 0

        self.account.save<@NonFungibleToken.Collection>(<- LCubeTicketComponent.createEmptyCollection(), to: LCubeTicketComponent.CollectionStoragePath)
        self.account.link<&{LCubeTicketComponent.LCubeTicketComponentCollectionPublic}>(LCubeTicketComponent.CollectionPublicPath, target: LCubeTicketComponent.CollectionStoragePath)

        let minter <- create ComponentMinter()
        self.account.save(<- minter, to: self.MinterStoragePath)
        self.account.link<&ComponentMinter>(self.MinterPublicPath, target: self.MinterStoragePath)

        emit ContractInitialized()
	}
}