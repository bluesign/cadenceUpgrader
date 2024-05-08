import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import LCubeComponent from "./LCubeComponent.cdc"
import LCubeExtension from "./LCubeExtension.cdc"

//Wow! You are viewing LimitlessCube Pack contract.

pub contract LCubePack: NonFungibleToken {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath
    pub let MinterPublicPath: PublicPath

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event GameCreated(gameID: UInt64, creator: Address, metadata: {String:String})
    pub event PackCreated(creatorAddress: Address, gameID:UInt64, id: UInt64,  metadata: {String:String})
    pub event PackOpened(id: UInt64, accountAddress: Address?, items: [UInt64])
    pub event Destroy(id: UInt64)

pub fun createGameMinter(creator: Address, metadata: {String:String}): @PackMinter {
    assert(metadata.containsKey("gameName"), message: "gameName property is required for LCubePack!")
    assert(metadata.containsKey("thumbnail"), message: "thumbnail property is required for LCubePack!")

    var gameName = LCubeExtension.clearSpaceLetter(text: metadata["gameName"]!)

    assert(gameName.length>2, message: "gameName property is not empty or minimum 3 characters!")

    let storagePath= "Game_".concat(gameName)

    let candidate <- self.account.load<@Game>(from: StoragePath(identifier: storagePath)!)

    if candidate!=nil {
        panic(gameName.concat(" Game already created before!"))
    }
    
    destroy candidate

    var newGame <- create Game(creatorAddress: creator, metadata: metadata)
    var gameID: UInt64 = newGame.uuid
    emit GameCreated(gameID: gameID, creator: creator, metadata: metadata)    
    
    self.account.save(<-newGame, to: StoragePath(identifier: storagePath)!)

    return <- create PackMinter(gameID: gameID)
  }

  pub resource Game {
    pub let creatorAddress: Address
    pub let metadata: {String:String}

    init(creatorAddress: Address, metadata: {String:String}) {
         self.creatorAddress = creatorAddress
         self.metadata = metadata
        }
  }  

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let creatorAddress: Address
        pub let gameID: UInt64        
        pub let startOfUse: UFix64
        pub let itemCount: UInt8
        pub let metadata: {String:String}
        access(self) let royalties: [MetadataViews.Royalty]
        init(
            creatorAddress: Address,
            gameID:UInt64,           
            startOfUse: UFix64,
            metadata: {String:String},
            royalties: [MetadataViews.Royalty],
            itemCount: UInt8
        ) {
            LCubePack.totalSupply = LCubePack.totalSupply + 1

            self.id = LCubePack.totalSupply 
            self.creatorAddress = creatorAddress
            self.gameID = gameID         
            self.startOfUse = startOfUse
            self.metadata = metadata
            self.royalties = royalties
            self.itemCount = itemCount
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
                    // There is no max number of NFTs that can be minted from this contract
                    // so the max edition field value is set to nil
                    let editionInfo = MetadataViews.Edition(name: "LimitlessCube Pack Edition", number: self.id, max: nil)
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
                    return MetadataViews.ExternalURL("https://limitlesscube.com/flow/pack/".concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: LCubePack.CollectionStoragePath,
                        publicPath: LCubePack.CollectionPublicPath,
                        providerPath: /private/LCubeNFTCollection,
                        publicCollection: Type<&LCubePack.Collection{LCubePackCollectionPublic}>(),
                        publicLinkedType: Type<&LCubePack.Collection{LCubePack.LCubePackCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&LCubePack.Collection{LCubePack.LCubePackCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-LCubePack.createEmptyCollection()
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
                        name: "The LimitlessCube Pack Collection",
                        description: "This collection is used as an LimitlessCube to help you develop your next Flow NFT.",
                        externalURL: MetadataViews.ExternalURL("https://limitlesscube.com/flow/MetadataViews"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/limitlesscube")
                        }
                    )
                case Type<MetadataViews.Traits>():
                    // exclude mintedTime and foo to show other uses of Traits
                    let excludedTraits = ["name", "description","thumbnail","image","nftType"]
                    let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)

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
    }

    pub resource interface LCubePackCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowLCubePack(id: UInt64): &LCubePack.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow LimitlessCube reference: The ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: LCubePackCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
         pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {

            let nft = (&self.ownedNFTs[withdrawID] as auth &NonFungibleToken.NFT?)!
            let packNFT = nft as! &LCubePack.NFT

            if (packNFT.startOfUse > getCurrentBlock().timestamp) {
                panic("Cannot withdraw: Pack is locked")
            }

            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing Pack")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @LCubePack.NFT
            let id: UInt64 = token.id
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)
            destroy oldToken
        }


         pub fun openPack(id: UInt64, receiverAccount: AuthAccount) {

            let recipient = getAccount(receiverAccount.address)

            let recipientCap = recipient.getCapability<&{LCubeComponent.LCubeComponentCollectionPublic}>(LCubeComponent.CollectionPublicPath)
            let auth = recipientCap.borrow()!      

            let pack <- self.withdraw(withdrawID: id) as! @LCubePack.NFT

            let minter = LCubePack.getComponentMinter().borrow() ?? panic("Could not borrow receiver capability (maybe receiver not configured?)")

            let collectionRef = receiverAccount.borrow<&LCubeComponent.Collection>(from: LCubeComponent.CollectionStoragePath)
            ?? panic("Could not borrow a reference to the owner's collection")

            let depositRef = recipient.getCapability(LCubeComponent.CollectionPublicPath).borrow<&{NonFungibleToken.CollectionPublic}>()!
    
            let beneficiaryCapability = recipient.getCapability<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())
          
            if !beneficiaryCapability.check() { panic("Beneficiary capability is not valid!") }  

            var royalties: [MetadataViews.Royalty] = [MetadataViews.Royalty(
                  receiver: beneficiaryCapability,
                  cut: 0.05,
                  description: "LimitlessCubePack Royalty"
              )]

            let componentMetadata = pack.getMetadata()

            componentMetadata.insert(key: "gameID", pack.gameID.toString())
            componentMetadata.insert(key: "creatorAddress", receiverAccount.address.toString())

            let components <- minter.batchCreateComponents(
                 gameID: pack.gameID,
                 metadata: pack.getMetadata(),
                 royalties:royalties,
                 quantity: pack.itemCount
            )

            let keys = components.getIDs()
            for key in keys {
                depositRef.deposit(token: <-components.withdraw(withdrawID: key))
            }   

            destroy components

            emit PackOpened(id: pack.id,accountAddress: receiverAccount.address, items: keys)
            destroy pack
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT{
            let ref = (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
            return ref
        }
        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver}{
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let packNFT = nft as! &LCubePack.NFT
            return packNFT
        }

        pub fun getMetadata(id: UInt64): {String:String} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let packNFT = nft as! &LCubePack.NFT
            return packNFT.getMetadata()
        }

        pub fun borrowLCubePack(id: UInt64): &LCubePack.NFT? {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let packNFT = nft as! &LCubePack.NFT
            return packNFT
        }

        pub fun getRoyalties(id: UInt64): [MetadataViews.Royalty] {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let packNFT = nft as! &LCubePack.NFT
            return packNFT.getRoyalties()
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub fun createEmptyCollection(): @LCubePack.Collection {
        return <- create Collection()
    }

    pub fun getPacks(address: Address) : [UInt64]? {
        let account = getAccount(address)
        if let packCollection = account.getCapability(self.CollectionPublicPath).borrow<&{LCubePack.LCubePackCollectionPublic}>()  {
            return packCollection.getIDs();
        }
        return nil
    }

    pub fun minter(): Capability<&PackMinter> {
        return self.account.getCapability<&PackMinter>(self.MinterPublicPath)
    }

    priv fun getComponentMinter(): Capability<&LCubeComponent.ComponentMinter> {
        return self.account.getCapability<&LCubeComponent.ComponentMinter>(/public/LCubeComponentMinter)
    }

   pub resource PackMinter {
    
    access(self) let gameID: UInt64
    init(gameID: UInt64){
        self.gameID=gameID
    }

    priv fun createPack(
            creatorAddress: Address,
            startOfUse: UFix64,
            metadata: {String:String},
            royalties: [MetadataViews.Royalty],
            itemCount: UInt8
        ) : @LCubePack.NFT {

        var newPack <- create NFT( 
            creatorAddress: creatorAddress,
            gameID: self.gameID,          
            startOfUse: startOfUse,
            metadata:metadata,
            royalties: royalties,
            itemCount : itemCount
        )

        emit PackCreated(creatorAddress: creatorAddress, gameID:self.gameID, id: newPack.id, metadata: metadata)
        return <- newPack
    }

    pub fun batchCreatePacks(creator: Capability<&{NonFungibleToken.Receiver}>, startOfUse: UFix64, metadata: {String:String}, royalties: [MetadataViews.Royalty], itemCount: UInt8, quantity: UInt8): @Collection {
         
         assert(metadata.containsKey("name"), message: "name property is required for LCubePack!")
         assert(metadata.containsKey("description"), message: "description property is required for LCubePack!")     
         assert(metadata.containsKey("image"), message: "image property is required for LCubePack!")

        let packCollection <- create Collection()

        var i: UInt8 = 0
        while i < quantity {
            packCollection.deposit(token: <-self.createPack(creatorAddress: creator.address, startOfUse: startOfUse, metadata: metadata,royalties: royalties, itemCount: itemCount))
            i = i + 1
        }

       return <-packCollection
        }
   }


	init() {

        self.CollectionPublicPath=/public/LCubePackCollection
        self.CollectionStoragePath=/storage/LCubePackCollection

        self.MinterPublicPath = /public/LCubePackMinter
        self.MinterStoragePath = /storage/LCubePackMinter

        self.totalSupply = 0

        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        self.account.link<&LCubePack.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, LCubePack.LCubePackCollectionPublic, MetadataViews.ResolverCollection}>(LCubePack.CollectionPublicPath, target: LCubePack.CollectionStoragePath)


        emit ContractInitialized()
	}
}