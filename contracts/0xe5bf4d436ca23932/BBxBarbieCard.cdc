/*
*
*   An NFT contract for redeeming/minting unlimited tokens
*
*
*/

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract BBxBarbieCard: NonFungibleToken {

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
    *   Card State Variables
    */
    access(account) var name: String
    access(account) var currentCardEditionIdByPackSeriesId: {UInt64: UInt64}

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64 // aka cardEditionID

        pub let packSeriesID: UInt64
        pub let cardEditionID: UInt64
        pub let packHash: String 
        pub let redeemable: String
        pub let metadata: {String: String}

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Traits>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Medias>(),
                Type<MetadataViews.Rarity>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    var ipfsImage = MetadataViews.IPFSFile(
                        cid: self.metadata["thumbnailCID"] ?? "ThumnailCID not set"
                        , path: self.metadata["thumbnailPath"] ?? "ThumbnailPath not set"
                        )
                    return MetadataViews.Display(
                        name: self.metadata["name"]?.concat(" Card #")?.concat(self.cardEditionID.toString()) ?? "Boss Beauties x Barbie Card",
                        description: self.metadata["description"] ?? "Digital Card Collectable from the Boss Beauties x Barbie collaboration" ,
                        thumbnail: ipfsImage
                    )

                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL(
                    url: self.metadata["url"] ?? ""
                    )

                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: BBxBarbieCard.CollectionStoragePath,
                        publicPath: BBxBarbieCard.CollectionPublicPath,
                        providedPath: /private/BBxBarbieCardCollection,
                        publicCollection: Type<&BBxBarbieCard.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, BBxBarbieCard.CardCollectionPublic, MetadataViews.ResolverCollection}>(),
                        publicLinkedType: Type<&BBxBarbieCard.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, BBxBarbieCard.CardCollectionPublic, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&BBxBarbieCard.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, BBxBarbieCard.CardCollectionPublic, MetadataViews.ResolverCollection}>(),
                        createEmptyCollection: fun(): @NonFungibleToken.Collection {return <- BBxBarbieCard.createEmptyCollection()}
                    )

                case Type<MetadataViews.NFTCollectionDisplay>():
                    let externalURL = MetadataViews.ExternalURL(
                        url: "https://mattel.com/"
                        )
                    let squareImage = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://www.mattel.com/"
                            ),
                        mediaType: "image/png")
                    let bannerImage = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://www.mattel.com/"
                            ),
                        mediaType: "image/png")
                    let socialMap: {String: MetadataViews.ExternalURL} = {
                        "facebook": MetadataViews.ExternalURL(
                            url: "https://www.facebook.com/mattel"
                            ),
                        "instagram": MetadataViews.ExternalURL(
                            url: "https://www.instagram.com/mattel"
                            ),
                        "twitter": MetadataViews.ExternalURL(
                            url: "https://www.twitter.com/mattel"
                            )
                    }
                    return MetadataViews.NFTCollectionDisplay(
                        name: self.metadata["career"] ?? self.metadata["miniCollection"] ?? "BBxBarbie",
                        description: self.metadata["careerDescription"] ?? "Digital Collectable from the Boss Beauties x Barbie collaboration",
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
                case Type<MetadataViews.Traits>(): 
                    let excludedTraits = [
                                "thumbnailPath"
                                , "thumbnailCID"
                                , "career"
                                , "careerDescription"
                                , "description"
                                , "url"
                            ]
                    let traitsView = MetadataViews.dictToTraits(
                        dict: self.metadata
                        , excludedNames: excludedTraits
                        )

                    return traitsView
                case Type<MetadataViews.Editions>():
                    return MetadataViews.Edition(
                        name: nil
                        , number: self.id
                        , max: nil
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial( 
                        number: self.uuid
                        )
                case Type<MetadataViews.Medias>():
                    return [
                        // MetadataViews.Media(
                        //     file: MetadataViews.IPFSFile(
                        //         cid: self.metadata["thumbnailCid"] ?? ""
                        //         , path: self.metadata["thumbnailPath"] ?? ""
                        //         )
                        //     , mediaType: "image/png"
                        //     ),
                        // MetadataViews.Media(
                        //     file: MetadataViews.IPFSFile(
                        //         cid: self.metadata["mp4Cid"] ?? ""
                        //         , path: self.metadata["mp4Path"] ?? ""
                        //         )
                        //     , mediaType: "video/mp4"
                        //     )
                    ]
                case Type<MetadataViews.Rarity>():
                    return MetadataViews.Rarity(
                        score: nil
                        , max: nil
                        , description: self.metadata["rarity"]
                    )


            }
            return nil
        }

        init(
            id: UInt64
            , packSeriesID: UInt64
            , cardEditionID: UInt64
            , packHash: String
            , redeemable: String
            , metadata: {String: String}
            ) {
            self.id = id
            self.packSeriesID = packSeriesID
            self.cardEditionID = cardEditionID
            self.packHash = packHash
            self.redeemable = redeemable
            self.metadata = metadata
            emit Mint(id: self.id)
        }

        destroy() {
            emit Burn(id: self.id)
        }
    }

    pub resource interface CardCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowCard(id: UInt64): &BBxBarbieCard.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow BBxBarbieCardPack reference: The ID of the returned reference is incorrect"
            }
        }
    }


    pub resource Collection: CardCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
            let BBxBarbieCard <- token as! @BBxBarbieCard.NFT
            let BBxBarbieCardUUID: UInt64 = BBxBarbieCard.uuid
            let BBxBarbieCardSeriesId: UInt64 = BBxBarbieCard.packSeriesID
            let BBxBarbieCardID: UInt64 = BBxBarbieCard.id
            let BBxBarbieCardEditionID: UInt64 = BBxBarbieCard.cardEditionID

            self.ownedNFTs[BBxBarbieCardID] <-! BBxBarbieCard

            emit Deposit(
                id: BBxBarbieCardID
                , to: self.owner?.address
            )
            emit DepositEvent(
                uuid:BBxBarbieCardUUID
                , id: BBxBarbieCardID
                , seriesId: BBxBarbieCardSeriesId
                , editionId: BBxBarbieCardEditionID
                , to: self.owner?.address
            )
        }


        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }


        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }


        pub fun borrowCard(id: UInt64): &BBxBarbieCard.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &BBxBarbieCard.NFT
            } else {
                return nil
            }
        }


        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let token = nft as! &BBxBarbieCard.NFT
            return token as &AnyResource{MetadataViews.Resolver}
        }


        destroy () {
            destroy self.ownedNFTs
        }
    }


    /* 
    *   Admin Functions
    */
    access(account) fun addNewSeries(newCardSeriesID: UInt64){
        self.currentCardEditionIdByPackSeriesId.insert(key: newCardSeriesID, 0)
    }


    access(account) fun updateCurrentEditionIdByPackSeriesId(packSeriesID: UInt64, cardSeriesEdition: UInt64){
        self.currentCardEditionIdByPackSeriesId[packSeriesID] = cardSeriesEdition
    }


    access(account) fun mint(
        nftID: UInt64
        , packSeriesID: UInt64
        , cardEditionID: UInt64
        , packHash: String
        , metadata: {String: String}
        ): @NonFungibleToken.NFT {

        self.totalSupply = self.getTotalSupply() + 1

        self.currentCardEditionIdByPackSeriesId[packSeriesID] = self.currentCardEditionIdByPackSeriesId[packSeriesID]! + 1

        return <- create NFT(
            id: nftID
            , packSeriesID: packSeriesID
            , cardEditionID: self.currentCardEditionIdByPackSeriesId[packSeriesID]!
            , packHash: packHash
            , redeemable: metadata["redeemable"]!
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

    pub fun transfer(uuid: UInt64, id: UInt64, packSeriesId: UInt64, cardEditionId: UInt64, toAddress: Address){

        let BBxBarbieCardV2UUID: UInt64 = uuid
        let BBxBarbieCardV2SeriesId: UInt64 = packSeriesId
        let BBxBarbieCardV2ID: UInt64 = id
        let BBxBarbieCardV2cardEditionID: UInt64 = cardEditionId

        emit TransferEvent(
            uuid: BBxBarbieCardV2UUID
            , id: BBxBarbieCardV2ID
            , seriesId: BBxBarbieCardV2SeriesId
            , editionId: BBxBarbieCardV2cardEditionID
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
        self.name = "Boss Beauties x Barbie Card"
        self.totalSupply = 0
        self.currentCardEditionIdByPackSeriesId = {1 : 0}

        // set the named paths
        self.CollectionStoragePath = /storage/BBxBarbieCardCollection
        self.CollectionPublicPath = /public/BBxBarbieCardCollection

        emit ContractInitialized()   
    }

}
 