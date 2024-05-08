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

pub contract HWGaragePackV2: NonFungibleToken {

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
                        , path: self.metadata["thumbnailPath"] ?? ""
                        )
                    return MetadataViews.Display(
                        name: self.metadata["packName"]!.concat(" Series ").concat(self.packSeriesID.toString()).concat(" #").concat(self.packEditionID.toString()),
                        description: self.metadata["packDescription"] ?? "Digital Pack Collectable from Hot Wheels Garage" ,
                        thumbnail: ipfsImage
                    )

                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL(
                        url: self.metadata["url"] ?? ""
                        )

                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: HWGaragePackV2.CollectionStoragePath,
                        publicPath: HWGaragePackV2.CollectionPublicPath,
                        providedPath: /private/HWGaragePackV2Collection,
                        publicCollection: Type<&HWGaragePackV2.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, HWGaragePackV2.PackCollectionPublic, MetadataViews.ResolverCollection}>(),
                        publicLinkedType: Type<&HWGaragePackV2.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, HWGaragePackV2.PackCollectionPublic, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&HWGaragePackV2.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, HWGaragePackV2.PackCollectionPublic, MetadataViews.ResolverCollection}>(),
                        createEmptyCollection: fun(): @NonFungibleToken.Collection {return <- HWGaragePackV2.createEmptyCollection()}
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
                        name: self.metadata["collectionName"] ?? "Hot Wheels Garage Pack",
                        description: self.metadata["collectionDescription"] ?? "Digital Collectable from Hot Wheels Garage",
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
                                , "packDescription"
                                , "url"
                            ]
                    let traitsView = MetadataViews.dictToTraits(
                        dict: self.metadata,
                        excludedNames:excludedTraits
                    )
                    let packHashTrait = MetadataViews.Trait(
                        name: "packHash",
                        value: self.packHash,
                        displayType: "String",
                        rarity: nil
                    )
                    traitsView.addTrait(packHashTrait)
                    
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
        pub fun borrowPack(id: UInt64): &HWGaragePackV2.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow HWGaragePackV2 reference: The ID of the returned reference is incorrect"
            }
        }
    }


    pub resource Collection: PackCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init() {
            self.ownedNFTs <- {}
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let HWGaragePackV2 <- self.ownedNFTs.remove(
                key: withdrawID
                ) ?? panic("missing NFT")
            emit Withdraw(
                id: HWGaragePackV2.id,
                from: self.owner?.address
                )
            return <-HWGaragePackV2
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let HWGaragePackV2 <- token as! @HWGaragePackV2.NFT
            let HWGaragePackV2UUID: UInt64 = HWGaragePackV2.uuid
            let HWGaragePackV2SeriesID: UInt64 = HWGaragePackV2.packSeriesID
            let HWGaragePackV2ID: UInt64 = HWGaragePackV2.id
            let HWGaragePackV2packEditionID: UInt64 = HWGaragePackV2.packEditionID
            
            self.ownedNFTs[HWGaragePackV2ID] <-! HWGaragePackV2
            
            emit Deposit(
                id: HWGaragePackV2ID,
                to: self.owner?.address
                )
            emit DepositEvent(
                uuid: HWGaragePackV2UUID,
                id: HWGaragePackV2ID,
                seriesId: HWGaragePackV2SeriesID,
                editionId: HWGaragePackV2packEditionID,
                to: self.owner?.address
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
            ): &HWGaragePackV2.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &HWGaragePackV2.NFT
            } else {
                return nil
            }
        }
    
        pub fun borrowViewResolver(
            id: UInt64
            ): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let nftPack = nft as! &HWGaragePackV2.NFT
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
        if (newPackSeriesID == 4){
            panic("series 4 cannot live here")
        } else {
            self.currentPackEditionIdByPackSeriesId.insert(key: newPackSeriesID, 0)
        }
        
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


    pub fun transfer(uuid: UInt64, id: UInt64, packSeriesId: UInt64, packEditionId: UInt64, toAddress: Address){

        let HWGaragePackV2UUID: UInt64 = uuid
        let HWGaragePackV2SeriesId: UInt64 = packSeriesId
        let HWGaragePackV2ID: UInt64 = id
        let HWGaragePackV2packEditionID: UInt64 = packEditionId

        emit TransferEvent(
            uuid: HWGaragePackV2UUID
            , id: HWGaragePackV2ID
            , seriesId: HWGaragePackV2SeriesId
            , editionId: HWGaragePackV2packEditionID
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
        self.name = "Hot Wheels Garage Pack v2"
        self.totalSupply = 0
        self.currentPackEditionIdByPackSeriesId = {1 : 0}

        // set the named paths
        self.CollectionStoragePath = /storage/HWGaragePackV2Collection
        self.CollectionPublicPath = /public/HWGaragePackV2Collection

        emit ContractInitialized()   
    }

}
 