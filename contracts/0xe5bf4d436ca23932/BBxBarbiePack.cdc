/*
*
*   This is an implemetation of a Flow Non-Fungible Token
*   It is not a part of the official standard but it is assumed to be
*   similar to how NFTs would implement the core functionality
*
*
*/

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract BBxBarbiePack: NonFungibleToken {

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
    *   Pack State Variables
    */
    access(account) var name: String
    access(account) var currentPackEditionIdByPackSeriesId: {UInt64: UInt64}


    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let packSeriesID: UInt64
        pub let packEditionID: UInt64
        pub let packHash: String
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
                        cid: self.metadata["thumbnailCID"] ?? "No ThumnailCID set"
                        , path: self.metadata["thumbnailPath"] ?? "No ThumbnailPath set"
                        )
                    return MetadataViews.Display(
                        name: self.metadata["packName"]?.concat(" #")?.concat(self.packEditionID.toString()) ?? "Boss Beauties x Barbie Pack",
                        description: self.metadata["description"] ?? "Digital Pack Collectable from the Boss Beauties x Barbie collaboration" ,
                        thumbnail: ipfsImage
                    )

                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL(
                        url: self.metadata["url"] ?? ""
                        )

                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: BBxBarbiePack.CollectionStoragePath,
                        publicPath: BBxBarbiePack.CollectionPublicPath,
                        providedPath: /private/BBxBarbiePackCollection,
                        publicCollection: Type<&BBxBarbiePack.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, BBxBarbiePack.PackCollectionPublic, MetadataViews.ResolverCollection}>(),
                        publicLinkedType: Type<&BBxBarbiePack.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, BBxBarbiePack.PackCollectionPublic, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&BBxBarbiePack.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, BBxBarbiePack.PackCollectionPublic, MetadataViews.ResolverCollection}>(),
                        createEmptyCollection: fun(): @NonFungibleToken.Collection {return <- BBxBarbiePack.createEmptyCollection()}
                    )
                
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let externalURL = MetadataViews.ExternalURL(
                        url: "https://www.mattel.com/"
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
                        name: self.metadata["drop"] ?? "Boss Beauties x Barbie Pack",
                        description: self.metadata["collectionDescription"] ?? "Digital Collectable from the Boss Beauties x Barbie collaboration",
                        externalURL: externalURL,
                        squareImage: squareImage,
                        bannerImage: bannerImage,
                        socials: socialMap
                        )
                case Type<MetadataViews.Traits>(): 
                    let excludedTraits = [
                                "thumbnailPath"
                                , "thumbnailCID"
                                , "collectionName"
                                , "collectionDescription"
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
            , packEditionID: UInt64
            , packHash: String
            , metadata: {String: String}
            ) {
            self.id = id
            self.packSeriesID = packSeriesID
            self.packEditionID = packEditionID
            self.packHash = packHash
            self.metadata = metadata
            emit Mint(id: self.packEditionID)
        }


        destroy() {
            emit Burn(id: self.id)
        }
    }


    pub resource interface PackCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowPack(id: UInt64): &BBxBarbiePack.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow BBxBarbiePack reference: The ID of the returned reference is incorrect"
            }
        }
    }


    pub resource Collection: PackCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init() {
            self.ownedNFTs <- {}
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let BBxBarbiePack <- self.ownedNFTs.remove(
                key: withdrawID
                ) ?? panic("missing NFT")
            emit Withdraw(
                id: BBxBarbiePack.id,
                from: self.owner?.address
                )
            return <-BBxBarbiePack
        }

        pub fun deposit(
            token: @NonFungibleToken.NFT
            ) {
            let BBxBarbiePack <- token as! @BBxBarbiePack.NFT
            let BBxBarbiePackUUID: UInt64 = BBxBarbiePack.uuid
            let BBxBarbiePackSeriesId: UInt64 = BBxBarbiePack.packSeriesID
            let BBxBarbiePackID: UInt64 = BBxBarbiePack.id
            let BBxBarbiePackEditionID: UInt64 = BBxBarbiePack.packEditionID
            self.ownedNFTs[BBxBarbiePackID] <-! BBxBarbiePack
            emit Deposit(
                id: BBxBarbiePackID,
                to: self.owner?.address
            )
            emit DepositEvent(
                uuid:BBxBarbiePackUUID
                , id: BBxBarbiePackID
                , seriesId: BBxBarbiePackSeriesId
                , editionId: BBxBarbiePackEditionID
                , to: self.owner?.address
            )
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(
            id: UInt64
            ): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowPack(
            id: UInt64
            ): &BBxBarbiePack.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &BBxBarbiePack.NFT
            } else {
                return nil
            }
        }
    
        pub fun borrowViewResolver(
            id: UInt64
            ): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let nftPack = nft as! &BBxBarbiePack.NFT
            return nftPack
        }

        destroy () {
            destroy self.ownedNFTs
        }
    }


    /* 
    *   Admin Functions
    */
    access(account) fun addNewSeries(newPackSeriesID: UInt64){
        self.currentPackEditionIdByPackSeriesId.insert(key: newPackSeriesID, 0)
    }


    access(account) fun updateCurrentEditionIdByPackSeriesId(packSeriesID: UInt64, packSeriesEdition: UInt64){
        self.currentPackEditionIdByPackSeriesId[packSeriesID] = packSeriesEdition
    }
    

    access(account) fun mint(
        nftID: UInt64
        , packEditionID: UInt64
        , packSeriesID: UInt64
        , packHash: String
        , metadata: {String: String}
        ): @NonFungibleToken.NFT {
        self.totalSupply = self.totalSupply + 1
        self.currentPackEditionIdByPackSeriesId[packSeriesID] = self.currentPackEditionIdByPackSeriesId[packSeriesID]! + 1
        return <- create NFT(
            id: nftID
            , packSeriesID: packSeriesID
            , packEditionID: self.currentPackEditionIdByPackSeriesId[packSeriesID]!
            , packHash: packHash
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


    /* 
    *   NonFungibleToken Standard Functions
    */
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }


    pub fun transfer(uuid: UInt64, id: UInt64, packSeriesId: UInt64, packEditionId: UInt64, toAddress: Address){

        let BBxBarbiePackV2UUID: UInt64 = uuid
        let BBxBarbiePackV2SeriesId: UInt64 = packSeriesId
        let BBxBarbiePackV2ID: UInt64 = id
        let BBxBarbiePackV2packEditionID: UInt64 = packEditionId

        emit TransferEvent(
            uuid: BBxBarbiePackV2UUID
            , id: BBxBarbiePackV2ID
            , seriesId: BBxBarbiePackV2SeriesId
            , editionId: BBxBarbiePackV2packEditionID
            , to: toAddress)
    }


    // initialize contract state variables
    init(){
        self.name = "Boss Beauties x Barbie Pack"
        self.totalSupply = 0
        self.currentPackEditionIdByPackSeriesId = {1 : 0}

        // set the named paths
        self.CollectionStoragePath = /storage/BBxBarbiePackCollection
        self.CollectionPublicPath = /public/BBxBarbiePackCollection

        emit ContractInitialized()   
    }

}
 