
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import LCubeExtension from "./LCubeExtension.cdc"

//Wow! You are viewing LimitlessCube NFT token contract.

pub contract LCubeNFT: NonFungibleToken {

  pub var totalSupply: UInt64

  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath
  pub let MinterStoragePath: StoragePath
  pub let MinterPublicPath: PublicPath

  pub event ContractInitialized()
  pub event Withdraw(id: UInt64, from: Address?)
  pub event Deposit(id: UInt64, to: Address?)
  pub event Mint(id: UInt64, setID: UInt64, creator: Address, metadata: {String:String})
  pub event Destroy(id: UInt64)

  pub event SetCreated(setID: UInt64, creator: Address, metadata: {String:String})
  pub event NFTAddedToSet(setID: UInt64, nftID: UInt64)
  pub event NFTRetiredFromSet(setID: UInt64, nftID: UInt64)
  pub event SetLocked(setID: UInt64)

   pub fun createMinter(creator: Address, metadata: {String:String}): @NFTMinter {
    assert(metadata.containsKey("setName"), message: "setName property is required for LCubeNFTSet!")
    assert(metadata.containsKey("thumbnail"), message: "thumbnail property is required for LCubeNFTSet!")

    var setName = LCubeExtension.clearSpaceLetter(text: metadata["setName"]!)

    assert(setName.length>2, message: "setName property is not empty or minimum 3 characters!")

    let storagePath= "LCubeNFTSet_".concat(setName)

    let candidate <- self.account.load<@LCubeNFTSet>(from: StoragePath(identifier: storagePath)!)

    if candidate!=nil {
        panic(setName.concat(" LCubeNFTSet already created before!"))
    }
    
    destroy candidate

    var newSet <- create LCubeNFTSet(creatorAddress: creator, metadata: metadata)
    var setID: UInt64 = newSet.uuid
    emit SetCreated(setID: setID, creator: creator, metadata: metadata)    
    
    self.account.save(<-newSet, to: StoragePath(identifier: storagePath)!)

    return <- create NFTMinter(setID: setID)
  }

    pub fun borrowSet(storagePath: StoragePath): &LCubeNFTSet {
        return self.account.borrow<&LCubeNFTSet>(from: storagePath)!
    }

  pub resource LCubeNFTSet {
    pub let creatorAddress: Address
    pub let metadata: {String:String}

    init(creatorAddress: Address, metadata: {String:String}) {
         self.creatorAddress = creatorAddress
         self.metadata = metadata
        }
  }  


  pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
    
    pub let id: UInt64
    pub let setID: UInt64

    pub let creator: Address
    access(self) let metadata: {String:String}
    access(self) let royalties: [MetadataViews.Royalty]

       init(id: UInt64, setID:UInt64, creator: Address, metadata: {String:String}, royalties: [MetadataViews.Royalty]) {
            self.id = id
            self.setID = setID
            self.creator = creator
            self.royalties = royalties
            self.metadata = metadata
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
                    let editionInfo = MetadataViews.Edition(name: "LCube NFT Edition", number: self.id, max: nil)
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
                    return MetadataViews.ExternalURL("https://limitlesscube.com/".concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: LCubeNFT.CollectionStoragePath,
                        publicPath: LCubeNFT.CollectionPublicPath,
                        providerPath: /private/LCubeNFTCollection,
                        publicCollection: Type<&LCubeNFT.Collection{LCubeNFTCollectionPublic}>(),
                        publicLinkedType: Type<&LCubeNFT.Collection{LCubeNFT.LCubeNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&LCubeNFT.Collection{LCubeNFT.LCubeNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-LCubeNFT.createEmptyCollection()
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
                        name: "The LCube Collection",
                        description: "This collection is used as an limitlesscube to help you develop your next Flow NFT.",
                        externalURL: MetadataViews.ExternalURL("https://limitlesscube.com"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/limitlesscube")
                        }
                    )
                case Type<MetadataViews.Traits>():
                    let excludedTraits = ["name", "description","thumbnail","uri"]
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

        destroy() {
            emit Destroy(id: self.id)
        }
  }

    pub resource interface LCubeNFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowLCubeNFT(id: UInt64): &LCubeNFT.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow LCube reference: The ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: LCubeNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @LCubeNFT.NFT

            let id: UInt64 = token.id
            let oldToken <- self.ownedNFTs[id] <- token
            destroy oldToken
            emit Deposit(id: id, to: self.owner?.address)
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowLCubeNFT(id: UInt64): &LCubeNFT.NFT? {
          if self.ownedNFTs[id] != nil {
             let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
             return ref as! &LCubeNFT.NFT
          } else {
               return nil
           }
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refItem = nft as! &LCubeNFT.NFT
            return refItem;
        }

        pub fun borrow(id: UInt64): &NFT? {
            let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT?
            return ref as! &LCubeNFT.NFT
        }

        pub fun getMetadata(id: UInt64): {String:String} {
            let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT?
            return (ref as! &LCubeNFT.NFT).getMetadata()
        }

        pub fun getRoyalties(id: UInt64): [MetadataViews.Royalty] {
            let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT?
            return (ref as! &LCubeNFT.NFT).getRoyalties()
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub resource NFTMinter {

    access(self) let setID: UInt64
    init(setID: UInt64){
        self.setID=setID
    }

    pub fun mintNFT(creator: Capability<&{NonFungibleToken.Receiver}>, metadata: {String:String}, royalties: [MetadataViews.Royalty]): &NonFungibleToken.NFT {
    
         assert(metadata.containsKey("nftType"), message: "nftType property is required for LCubeNFT!")
         assert(metadata.containsKey("name"), message: "name property is required for LCubeNFT!")
         assert(metadata.containsKey("description"), message: "description property is required for LCubeNFT!")
         assert(metadata.containsKey("thumbnail"), message: "thumbnail property is required for LCubeNFT!")

            let token <- create NFT(
                id: LCubeNFT.totalSupply,
                setID: self.setID,
                creator: creator.address,
                metadata: metadata,
                royalties: royalties
            )
            LCubeNFT.totalSupply = LCubeNFT.totalSupply + 1
            let tokenRef = &token as &NonFungibleToken.NFT

            emit Mint(id: token.id,setID:self.setID, creator: creator.address, metadata: metadata)
            creator.borrow()!.deposit(token: <- token)
            return tokenRef
    }
  }

    init() {

        self.totalSupply = 0
        self.CollectionStoragePath = /storage/LCubeNFTCollection
        self.CollectionPublicPath = /public/LCubeNFTCollection
        self.MinterPublicPath = /public/LCubeNFTMinter
        self.MinterStoragePath = /storage/LCubeNFTMinter

        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        self.account.link<&LCubeNFT.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, LCubeNFT.LCubeNFTCollectionPublic, MetadataViews.ResolverCollection}>(LCubeNFT.CollectionPublicPath, target: LCubeNFT.CollectionStoragePath)

        emit ContractInitialized()
    }
}
 