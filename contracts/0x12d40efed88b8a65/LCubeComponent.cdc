import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import RandomGenerator from "./RandomGenerator.cdc"

//Wow! You are viewing LimitlessCube Component contract.

pub contract LCubeComponent: NonFungibleToken {

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

    pub let gameID: UInt64
    access(self) let metadata: {String:String}
    access(self) let seedBlock: UInt64
    access(self) let royalties: [MetadataViews.Royalty]

       init(id: UInt64, gameID: UInt64, metadata: {String:String}, royalties: [MetadataViews.Royalty]) {
            self.id = id
            self.gameID = gameID
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
                    let editionInfo = MetadataViews.Edition(name: "LimitlessCube NFT Edition", number: self.id, max: nil)
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
                    return MetadataViews.ExternalURL("https://limitlesscube.com/flow/".concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: LCubeComponent.CollectionStoragePath,
                        publicPath: LCubeComponent.CollectionPublicPath,
                        providerPath: /private/LCubeNFTCollection,
                        publicCollection: Type<&LCubeComponent.Collection{LCubeComponentCollectionPublic}>(),
                        publicLinkedType: Type<&LCubeComponent.Collection{LCubeComponent.LCubeComponentCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&LCubeComponent.Collection{LCubeComponent.LCubeComponentCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-LCubeComponent.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://limitlesscube.com/images/logo.svg"
                        ),
                        mediaType: "image/svg+xml"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "The LimitlessCube Collection",
                        description: "This collection is used as an LimitlessCube to help you develop your next Flow NFT.",
                        externalURL: MetadataViews.ExternalURL("https://limitlesscube.com/flow/MetadataViews"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/limitlesscube")
                        }
                    )
                case Type<MetadataViews.Traits>():
                    let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: ["name", "description","image","thumbnail","nftType","gameName"])

                  if getCurrentBlock().height >= self.seedBlock {

                        let randomizer <- RandomGenerator.createFrom(blockHeight: self.seedBlock, uuid: self.uuid)

                        let randomTrait = (randomizer.pickWeighted(["legendary", "rare", "common"],[5,10,85]) as! String)

                        traitsView.addTrait(
                            MetadataViews.Trait(
                                name: "rarity",
                                value: randomTrait,
                                displayType: "String",
                                rarity: nil
                            )
                        )

                        destroy randomizer
                    }
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

    pub resource interface LCubeComponentCollectionPublic {

        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowComponent(id: UInt64): &LCubeComponent.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Component reference: The ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: LCubeComponentCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
            let token <- token as! @LCubeComponent.NFT

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

        pub fun borrowComponent(id: UInt64): &LCubeComponent.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &LCubeComponent.NFT
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
            let componentNFT = nft as! &LCubeComponent.NFT
            return componentNFT as &AnyResource{MetadataViews.Resolver}
        }
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }


    pub resource ComponentMinter {

     priv fun createComponent(gameID: UInt64, metadata: {String:String},royalties: [MetadataViews.Royalty]) : @LCubeComponent.NFT {

        var packComponent <- create NFT(
                id: LCubeComponent.totalSupply,
                gameID: gameID,
                metadata: metadata,
                royalties: royalties
                )

        LCubeComponent.totalSupply = LCubeComponent.totalSupply + 1
        emit Created(id: packComponent.id, metadata: metadata)

        return <- packComponent
    }

     pub fun batchCreateComponents(gameID: UInt64, metadata: {String:String}, royalties: [MetadataViews.Royalty], quantity: UInt8): @Collection {
        let newCollection <- create Collection()

        var i: UInt8 = 0
        while i < quantity {
            newCollection.deposit(token: <-self.createComponent(gameID: gameID, metadata: metadata, royalties: royalties))
            i = i + 1
        }

       return <-newCollection
        }
    }

  // pub fun minter(minterAccount:AuthAccount): Capability<&ComponentMinter> {
  //      return self.account.getCapability<&ComponentMinter>(self.MinterPublicPath)      
  //  }

	init() {
        self.CollectionPublicPath = /public/LCubeComponentCollection
        self.CollectionStoragePath = /storage/LCubeComponentCollection
        self.MinterPublicPath = /public/LCubeComponentMinter
        self.MinterStoragePath = /storage/LCubeComponentMinter

        self.totalSupply = 0

        self.account.save<@NonFungibleToken.Collection>(<- LCubeComponent.createEmptyCollection(), to: LCubeComponent.CollectionStoragePath)
        self.account.link<&{LCubeComponent.LCubeComponentCollectionPublic}>(LCubeComponent.CollectionPublicPath, target: LCubeComponent.CollectionStoragePath)

        let minter <- create ComponentMinter()
        self.account.save(<- minter, to: self.MinterStoragePath)
        self.account.link<&ComponentMinter>(self.MinterPublicPath, target: self.MinterStoragePath)

        emit ContractInitialized()
	}
}