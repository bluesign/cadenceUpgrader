/*
*
*   An NFT contract for redeeming/minting tokens by series
*
*
*/

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract HWGarageTokenV2: NonFungibleToken {

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
    access(account) var name: String
    access(account) var currentTokenEditionIdByPackSeriesId: {UInt64: UInt64}

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        // the pack series this Token came from
        pub let packSeriesID: UInt64
        pub let tokenEditionID: UInt64
        pub let metadata: {String: String}

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Traits>(),
                Type<MetadataViews.Rarity>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    var ipfsImage = MetadataViews.IPFSFile(
                        cid: self.metadata["thumbnailCID"] ?? "ThumbnailCID not set"
                        , path: self.metadata["thumbnailPath"] ?? ""
                        )
                    return MetadataViews.Display(
                        name: self.metadata["tokenName"] ?? "Hot Wheels Garage Token Series ".concat(self.packSeriesID.toString()).concat(" #").concat(self.tokenEditionID.toString()),
                        description: self.metadata["tokenDescription"] ?? "Digital Redeemable Token Collectable from Hot Wheels Garage" ,
                        thumbnail: ipfsImage
                    )

                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL(
                    url: self.metadata["url"] ?? ""
                    )

                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: HWGarageTokenV2.CollectionStoragePath,
                        publicPath: HWGarageTokenV2.CollectionPublicPath,
                        providedPath: /private/HWGarageTokenV2Collection,
                        publicCollection: Type<&HWGarageTokenV2.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, HWGarageTokenV2.TokenCollectionPublic, MetadataViews.ResolverCollection}>(),
                        publicLinkedType: Type<&HWGarageTokenV2.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, HWGarageTokenV2.TokenCollectionPublic, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&HWGarageTokenV2.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, HWGarageTokenV2.TokenCollectionPublic, MetadataViews.ResolverCollection}>(),
                        createEmptyCollection: fun(): @NonFungibleToken.Collection {return <- HWGarageTokenV2.createEmptyCollection()}
                    )

                case Type<MetadataViews.NFTCollectionDisplay>():
                    let externalURL = MetadataViews.ExternalURL(
                        url: ""
                        )

                    let squareImage = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: ""
                            ),
                        mediaType: "image/png")

                    let bannerImage = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: ""
                            ),
                        mediaType: "image/png")

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
                        name: self.metadata["collectionName"] ?? "Hot Wheels Garage Redeemable Token",
                        description: self.metadata["collectionDescription"] ?? "Digital Collectable from Hot Wheels Garage",
                        externalURL: externalURL,
                        squareImage: squareImage,
                        bannerImage: bannerImage,
                        socials: socialMap
                        )
                case Type<MetadataViews.Traits>(): 
                    let exludedTraits = [
                                "thumbnailPath"
                                , "thumbnailCID"
                                , "collectionName"
                                , "collectionDescription"
                                , "tokenDescription"
                                , "url"
                            ]
                    let traitsView = MetadataViews.dictToTraits(
                        dict: self.metadata,
                        excludedNames: exludedTraits
                    )
                    return traitsView
                case Type<MetadataViews.Royalties>(): 
                    let flowReciever = getAccount(0xf86e2f015cd692be).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
                return MetadataViews.Royalties([
                    MetadataViews.Royalty(
                        recipient:flowReciever
                        , cut: 0.05
                        , description: "Mattel 5% Royalty")
                    ]
                )
                case Type<MetadataViews.Rarity>(): 
                    let rarityDescription = self.metadata["rarity"]
                    return MetadataViews.Rarity(
                    score: nil
                    , max: nil
                    ,description: rarityDescription
                )
            }
            return nil
        }

        init(
            id: UInt64
            , packSeriesID: UInt64
            , tokenEditionID: UInt64
            , metadata: {String: String}
            ) {
            self.id = id
            self.packSeriesID = packSeriesID
            self.tokenEditionID = tokenEditionID
            self.metadata = metadata
            emit Mint(id: self.id)
        }

        destroy() {
            emit Burn(id: self.id)
        }
    }

    pub resource interface TokenCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowToken(id: UInt64): &HWGarageTokenV2.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow HWGarageTokenV2Pack reference: The ID of the returned reference is incorrect"
            }
        }
    }


    pub resource Collection: TokenCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init() {
            self.ownedNFTs <- {}
        }


        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(
                id: token.id,
                from: self.owner?.address
                )

            return <-token
        }


        pub fun deposit(token: @NonFungibleToken.NFT) {
            let HWGarageTokenV2 <- token as! @HWGarageTokenV2.NFT
            let HWGarageTokenV2UUID = HWGarageTokenV2.uuid
            let HWGarageTokenV2SeriesID: UInt64 = HWGarageTokenV2.packSeriesID
            let HWGarageTokenV2ID: UInt64 = HWGarageTokenV2.id
            let HWGarageTokenV2tokenEditionID: UInt64 = HWGarageTokenV2.tokenEditionID

            self.ownedNFTs[HWGarageTokenV2ID] <-! HWGarageTokenV2

            emit Deposit(
                id: HWGarageTokenV2ID,
                to: self.owner?.address
                )
            emit DepositEvent(
                uuid: HWGarageTokenV2UUID,
                id: HWGarageTokenV2ID,
                seriesId: HWGarageTokenV2SeriesID,
                editionId: HWGarageTokenV2tokenEditionID,
                to: self.owner?.address
                )
        }


        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }


        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }


        pub fun borrowToken(id: UInt64): &HWGarageTokenV2.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &HWGarageTokenV2.NFT
            } else {
                return nil
            }
        }


        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let token = nft as! &HWGarageTokenV2.NFT
            return token as &AnyResource{MetadataViews.Resolver}
        }


        destroy () {
            destroy self.ownedNFTs
        }
    }


    /* 
    *   Admin Functions
    */
    access(account) fun addNewSeries(newTokenSeriesID: UInt64){
        self.currentTokenEditionIdByPackSeriesId.insert(key: newTokenSeriesID, 0)
    }


    access(account) fun updateCurrentEditionIdByPackSeriesId(packSeriesID: UInt64, tokenSeriesEdition: UInt64){
        self.currentTokenEditionIdByPackSeriesId[packSeriesID] = tokenSeriesEdition
    }


    access(account) fun mint(
        nftID: UInt64
        , packSeriesID: UInt64
        , metadata: {String: String}
        ): @NonFungibleToken.NFT {

        self.totalSupply = self.getTotalSupply() + 1

        self.currentTokenEditionIdByPackSeriesId[packSeriesID] = self.currentTokenEditionIdByPackSeriesId[packSeriesID]! + 1

        return <- create NFT(
            id: nftID
            , packSeriesID: packSeriesID
            , tokenEditionID: self.currentTokenEditionIdByPackSeriesId[packSeriesID]!
            , metadata: metadata
            )
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


    pub fun transfer(uuid: UInt64, id: UInt64, packSeriesId: UInt64, tokenEditionId: UInt64, toAddress: Address){

        let HWGarageTokenV2UUID: UInt64 = uuid
        let HWGarageTokenV2SeriesId: UInt64 = packSeriesId
        let HWGarageTokenV2ID: UInt64 = id
        let HWGarageTokenV2tokenEditionID: UInt64 = tokenEditionId

        emit TransferEvent(
            uuid: HWGarageTokenV2UUID
            , id: HWGarageTokenV2ID
            , seriesId: HWGarageTokenV2SeriesId
            , editionId: HWGarageTokenV2tokenEditionID
            , to: toAddress)
    }


    /* 
    *   NonFungibleToken Standard Functions
    */
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }


    // initialize contract state variables
    init(){
        self.name = "Hot Wheels Garage Token v2"
        self.totalSupply = 0
        self.currentTokenEditionIdByPackSeriesId = {1 : 0}

        // set the named paths
        self.CollectionStoragePath = /storage/HWGarageTokenV2Collection
        self.CollectionPublicPath = /public/HWGarageTokenV2Collection

        emit ContractInitialized()   
    }

}
 