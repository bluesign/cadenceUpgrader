/*
*
*   An NFT contract for redeeming/minting unlimited tokens
*
*
*/

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract BBxBarbieToken: NonFungibleToken {

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

        pub let packSeriesID: UInt64
        pub let tokenEditionID: UInt64
        pub let redeemable: String
        pub let metadata: {String: String}

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Traits>()
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
                        name: self.metadata["name"]?.concat(" Token #")?.concat(self.tokenEditionID.toString()) ?? "Boss Beauties x Barbie Redeemable Token",
                        description: self.metadata["description"] ?? "Digital Redeemable Token Collectable from the Boss Beauties x Barbie collaboration" ,
                        thumbnail: ipfsImage
                    )

                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL(
                    url: self.metadata["url"] ?? ""
                    )

                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: BBxBarbieToken.CollectionStoragePath,
                        publicPath: BBxBarbieToken.CollectionPublicPath,
                        providedPath: /private/BBxBarbieTokenCollection,
                        publicCollection: Type<&BBxBarbieToken.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, BBxBarbieToken.TokenCollectionPublic, MetadataViews.ResolverCollection}>(),
                        publicLinkedType: Type<&BBxBarbieToken.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, BBxBarbieToken.TokenCollectionPublic, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&BBxBarbieToken.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, BBxBarbieToken.TokenCollectionPublic, MetadataViews.ResolverCollection}>(),
                        createEmptyCollection: fun(): @NonFungibleToken.Collection {return <- BBxBarbieToken.createEmptyCollection()}
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
                        name: self.metadata["name"] ?? "Boss Beauties x Barbie Token",
                        description: self.metadata["dropDescription"] ?? "Digital Collectable from the Boss Beauties x Barbie collaboration",
                        externalURL: externalURL,
                        squareImage: squareImage,
                        bannerImage: bannerImage,
                        socials: socialMap
                        )
                case Type<MetadataViews.Traits>(): 
                    let excludedTraits = [
                                "thumbnailPath"
                                , "thumbnailCID"
                                , "drop"
                                , "dropDescription"
                                , "description"
                                , "url"
                            ]
                    let traitsView = MetadataViews.dictToTraits(
                        dict: self.metadata
                        , excludedNames: excludedTraits
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
            }
            return nil
        }

        init(
            id: UInt64
            , packSeriesID: UInt64
            , tokenEditionID: UInt64
            , redeemable: String
            , metadata: {String: String}
            ) {
            self.id = id
            self.packSeriesID = packSeriesID
            self.tokenEditionID = tokenEditionID
            self.redeemable = redeemable
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
        pub fun borrowToken(id: UInt64): &BBxBarbieToken.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow BBxBarbieToken reference: The ID of the returned reference is incorrect"
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

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }


        pub fun deposit(token: @NonFungibleToken.NFT) {
            let BBxBarbieToken <- token as! @BBxBarbieToken.NFT
            let BBxBarbieTokenUUID: UInt64 = BBxBarbieToken.uuid
            let BBxBarbieTokenSeriesId: UInt64 = BBxBarbieToken.packSeriesID
            let BBxBarbieTokenID: UInt64 = BBxBarbieToken.id
            let BBxBarbieTokenEditionID: UInt64 = BBxBarbieToken.tokenEditionID
            self.ownedNFTs[BBxBarbieTokenID] <-! BBxBarbieToken

            emit Deposit(
                id: BBxBarbieTokenID
                , to: self.owner?.address
            )
            emit DepositEvent(
                uuid:BBxBarbieTokenUUID
                , id: BBxBarbieTokenID
                , seriesId: BBxBarbieTokenSeriesId
                , editionId: BBxBarbieTokenEditionID
                , to: self.owner?.address
            )

        }


        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }


        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }


        pub fun borrowToken(id: UInt64): &BBxBarbieToken.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &BBxBarbieToken.NFT
            } else {
                return nil
            }
        }


        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let token = nft as! &BBxBarbieToken.NFT
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
        , tokenEditionID: UInt64
        , metadata: {String: String}
        ): @NonFungibleToken.NFT {

        self.totalSupply = self.getTotalSupply() + 1

        self.currentTokenEditionIdByPackSeriesId[packSeriesID] = self.currentTokenEditionIdByPackSeriesId[packSeriesID]! + 1

        return <- create NFT(
            id: nftID
            , packSeriesID: packSeriesID
            , tokenEditionID: self.currentTokenEditionIdByPackSeriesId[packSeriesID]!
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

    pub fun transfer(uuid: UInt64, id: UInt64, packSeriesId: UInt64, tokenEditionId: UInt64, toAddress: Address){

        let BBxBarbieTokenV2UUID: UInt64 = uuid
        let BBxBarbieTokenV2SeriesId: UInt64 = packSeriesId
        let BBxBarbieTokenV2ID: UInt64 = id
        let BBxBarbieTokenV2tokenEditionID: UInt64 = tokenEditionId

        emit TransferEvent(
            uuid: BBxBarbieTokenV2UUID
            , id: BBxBarbieTokenV2ID
            , seriesId: BBxBarbieTokenV2SeriesId
            , editionId: BBxBarbieTokenV2tokenEditionID
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
        self.name = "Boss Beauties x Barbie Token"
        self.totalSupply = 0
        self.currentTokenEditionIdByPackSeriesId = {1 : 0}

        // set the named paths
        self.CollectionStoragePath = /storage/BBxBarbieTokenCollection
        self.CollectionPublicPath = /public/BBxBarbieTokenCollection

        emit ContractInitialized()   
    }

}
 