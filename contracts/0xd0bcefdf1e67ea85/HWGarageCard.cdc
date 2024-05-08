/*
*
*   An NFT contract demo for redeeming/minting unlimited tokens
*
*
*/

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract HWGarageCard: NonFungibleToken {

    /* 
    *   NonFungibleToken Standard Events
    */

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    /* 
    *   Project Events
    */

    pub event Mint(id: UInt64)
    pub event Burn(id: UInt64)
    pub event DepositEvent(
        uuid: UInt64
        , id: UInt64
        , seriesId: UInt64
        , editionId: UInt64
        , to: Address?
        )
    pub event TransferEvent(
        uuid: UInt64
        , id: UInt64
        , seriesId: UInt64
        , editionId: UInt64
        , to: Address?
        )

    /* 
    *   Named Paths
    */

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    /* 
    *   NonFungibleToken Standard Fields
    */

    pub var totalSupply: UInt64

    /*
    *   Token State Variables
    */

    pub var name: String

    access(self) var collectionMetadata: { String: String }
    access(self) let idToTokenMetadata: { UInt64: TokenMetadata }

    pub struct TokenMetadata {
        pub let metadata: { String: String }

        init(metadata: { String: String }) {
            self.metadata = metadata
        }
    }

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let packID: UInt64

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Royalties>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    var ipfsImage = MetadataViews.IPFSFile(cid: "No thumbnail cid set", path: "No thumbnail path set")
                    if (self.getMetadata().containsKey("thumbnailCID")){
                        ipfsImage = MetadataViews.IPFSFile(cid: self.getMetadata()["thumbnailCID"]!, path: self.getMetadata()["thumbnailPath"])
                    }
                    return MetadataViews.Display(
                        name: self.getMetadata()["name"] ?? "Hot Wheels Garage Card Series 4 #".concat(self.id.toString()),
                        description: self.getMetadata()["description"] ?? "Digital Card Collectable from Hot Wheels Garage",
                        thumbnail: ipfsImage
                    )

                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL(
                    url: ""
                    )

                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: HWGarageCard.CollectionStoragePath,
                        publicPath: HWGarageCard.CollectionPublicPath,
                        providedPath: /private/HWGarageCardCollection,
                        publicCollection: Type<&HWGarageCard.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, HWGarageCard.HWGarageCardCollectionPublic, MetadataViews.ResolverCollection}>(),
                        publicLinkedType: Type<&HWGarageCard.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, HWGarageCard.HWGarageCardCollectionPublic, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&HWGarageCard.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, HWGarageCard.HWGarageCardCollectionPublic, MetadataViews.ResolverCollection}>(),
                        createEmptyCollection: fun(): @NonFungibleToken.Collection {return <- HWGarageCard.createEmptyCollection()}
                    )
                
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let externalURL = MetadataViews.ExternalURL("")
                    let squareImage = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(url: ""),
                        mediaType: "image/png")
                    let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: ""), mediaType: "image/png")
                    let socialMap: {String: MetadataViews.ExternalURL} = {
                        "facebook": MetadataViews.ExternalURL(
                            url: "https://www.facebook.com/hotwheels"
                            ),
                        "instagram": MetadataViews.ExternalURL(
                            url: "https://www.instagram.com/hotwheelsofficial/"
                            ),
                        "twitter": MetadataViews.ExternalURL(
                            url: "https://twitter.com/Hot_Wheels"
                            ),
                        "discord": MetadataViews.ExternalURL(
                            url: "https://discord.gg/mattel"
                            )
                    }
                    return MetadataViews.NFTCollectionDisplay(
                        name: "Hot Wheels Garage Card",
                        description: "Digital Collectable from Hot Wheels Garage",
                        externalURL: externalURL,
                        squareImage: squareImage,
                        bannerImage: bannerImage,
                        socials: socialMap
                        )
                case Type<MetadataViews.Royalties>(): 
                    let flowReciever = getAccount(0xf86e2f015cd692be).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
                    return MetadataViews.Royalties([
                    MetadataViews.Royalty(
                        recipient:flowReciever
                        , cut: 0.05
                        , description: "Mattel 5% Royalty")
                    ]
                )
            }

            return nil
        }

        pub fun getMetadata(): {String: String} {
            if (HWGarageCard.idToTokenMetadata[self.id] != nil){
                return HWGarageCard.idToTokenMetadata[self.id]!.metadata
            } else {
                return {}
            }
        }

        init(id: UInt64, packID: UInt64) {
            self.id = id
            self.packID = packID
            emit Mint(id: self.id)
        }

        destroy() {
            emit Burn(id: self.id)
        }
    }

    pub resource interface HWGarageCardCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowHWGarageCard(id: UInt64): &HWGarageCard.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow HWGarageCardPack reference: The ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: HWGarageCardCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init() {
            self.ownedNFTs <- {}
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            // let token <- token as! @HWGarageCard.NFT
            // let id: UInt64 = token.id
            let HWGarageCard <- token as! @HWGarageCard.NFT
            let HWGarageCardUUID: UInt64 = HWGarageCard.uuid
            let HWGarageCardSeriesId: UInt64 = 4
            let HWGarageCardID: UInt64 = HWGarageCard.id
            let HWGarageCardcardEditionID: UInt64 = HWGarageCard.id
            self.ownedNFTs[HWGarageCardID] <-! HWGarageCard
            emit Deposit(id: HWGarageCardID, to: self.owner?.address)
            emit DepositEvent(
                uuid: HWGarageCardUUID,
                id: HWGarageCardID,
                seriesId: HWGarageCardSeriesId,
                editionId: HWGarageCardcardEditionID,
                to: self.owner?.address
                )
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowHWGarageCard(id: UInt64): &HWGarageCard.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &HWGarageCard.NFT
            } else {
                return nil
            }
        }
    
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let token = nft as! &HWGarageCard.NFT
            return token as &AnyResource{MetadataViews.Resolver}
        }

        destroy () {
            destroy self.ownedNFTs
        }
    }

    /* 
    *   Admin Functions
    */
    access(account) fun setEditionMetadata(editionNumber: UInt64, metadata: {String: String}) {
        self.idToTokenMetadata[editionNumber] = TokenMetadata(metadata: metadata)
    }

    access(account) fun setCollectionMetadata(metadata: {String: String}) {
        self.collectionMetadata = metadata
    }

    access(account) fun mint(nftID: UInt64, packID: UInt64): @NonFungibleToken.NFT {
        self.totalSupply = self.totalSupply + 1
        return <- create NFT(id: nftID, packID: packID)
    }

    /* 
    *   Public Functions
    */
    pub fun getTotalSupply(): UInt64 {
        return self.totalSupply
    }

    pub fun getName(): String {
        return self.name
    }

    pub fun transfer(uuid: UInt64, id: UInt64, packSeriesId: UInt64, cardEditionId: UInt64, toAddress: Address){

        let HWGarageCardV2UUID: UInt64 = uuid
        let HWGarageCardV2SeriesId: UInt64 = packSeriesId
        let HWGarageCardV2ID: UInt64 = id
        let HWGarageCardV2cardEditionID: UInt64 = cardEditionId

        emit TransferEvent(
            uuid: HWGarageCardV2UUID
            , id: HWGarageCardV2ID
            , seriesId: HWGarageCardV2SeriesId
            , editionId: HWGarageCardV2cardEditionID
            , to: toAddress)
    }

    pub fun getCollectionMetadata(): {String: String} {
        return self.collectionMetadata
    }

    pub fun getEditionMetadata(_ edition: UInt64): {String: String} {
        if ( self.idToTokenMetadata[edition] != nil) {
            return self.idToTokenMetadata[edition]!.metadata
        } else {
            return {}
        }
    }

    pub fun getMetadataLength(): Int {
        return self.idToTokenMetadata.length
    }

    /* 
    *   NonFungibleToken Standard Functions
    */
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // initialize contract state variables
    init(){
        self.name = "HWGarageCard"
        self.totalSupply = 0

        self.collectionMetadata = {}
        self.idToTokenMetadata = {}

        // set the named paths
        self.CollectionStoragePath = /storage/HWGarageCardCollection
        self.CollectionPublicPath = /public/HWGarageCardCollection

        emit ContractInitialized()   
    }

}
 