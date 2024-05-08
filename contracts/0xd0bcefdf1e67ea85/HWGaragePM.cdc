/* 
*   A contract that manages the creation and sale of packs and tokens
*
*   A manager resource exists allow modifying the parameters of the public
*   sale and have the capability to mint editions themselves
*/

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
import HWGarageCard from "./HWGarageCard.cdc"
import HWGaragePack from "./HWGaragePack.cdc"

pub contract HWGaragePM {
    /* 
    *   Events
    *
    *   emitted when the contract is deployed
    */
    pub event ContractInitialized()

    /* 
    *   HWGarageCard
    *
    *   emmited when an admin has initiated a mint of a HWGarageCard
    */
    pub event AdminMintHWGarageCard(id: UInt64)
    // emmited when the metadata for an HWGarageCard collection is updated
    pub event UpdateHWGarageCardCollectionMetadata()
    // emmited when an edition within HWGarageCard has had it's metdata updated
    pub event UpdateTokenEditionMetadata(id: UInt64, metadata: {String: String}, packHash: String, address: Address)

    /* 
    *   HWGaragePack
    *
    *   emitted when an admin has initiated a mint of a HWGarageCard
    */
    pub event AdminMintPack(id: UInt64, packHash: String)
    // emitted when someone redeems a HWGaragePack for Cards
    pub event RedeemPack(id: UInt64, packID: UInt64, packEditionID: UInt64, address: Address, packHash: String)
    // emitted when Pack has metadata updated
    pub event UpdatePackCollectionMetadata()
    // emitted when PackEdition updates metadata
    pub event UpdatePackEditionMetadata(id: UInt64, metadata: {String: String})
    // emitted when any information about redemption has been modified
    pub event UpdateHWGaragePackRedeemInfo(redeemStartTime: UFix64)
    // emitted when a user submits a packHash to claim a pack
    pub event PackClaimBegin(address: Address, packHash: String)
    // emitted when a user succesfully claims a pack
    pub event PackClaimSuccess(address: Address, packHash: String, packID: UInt64)
    
    /*
    *   HWGarageAirdrop
    *
    *   emitted when an admin has initiates an airdrop to a wallet
     */
    // V2 is depracated
    pub event AirdropRedeemableV2(id:UInt64, address: Address)
    
    pub event AirdropRedeemable(
        WalletAddress: Address
        , TokenID:UInt64
        , TokenMintID: UInt64
        , OriginalCardSerial: String
        , TokenSerial: String
        , SeriesName: String
        , Name: String
        , TokenImageHash: String
        , TokenReleaseDate: String
        , TokenExpireDate: String
        , CardID: UInt64
        , TemplateID: String
        )

    //  emitted when a user initiates a burn on redeemable airdrop
    pub event AirdropBurn(
        WalletAddress: Address
        , TokenSerial: String
        , AirdropEditionId: UInt64
        )


    /* 
    *   Named Paths
    */
    pub let ManagerStoragePath: StoragePath

    /* 
    *   HWGaragePM fields
    */
    /* 
    *   HWGarageCard
    */
    access(self) let HWGarageCardsMintedEditions: { UInt64: Bool}
    access(self) var HWGarageCardsSequentialMintMin: UInt64
    pub var HWGarageCardsTotalSupply: UInt64
    /* 
    *   HWGaragePack
    */
    access(self) let packsMintedEditions: {UInt64: Bool}
    access(self) let packsByPackIdMintedEditions: {UInt64: {UInt64:Bool}}
    access(self) var packsSequentialMintMin: UInt64
    access(self) var packsByPackIdSequentialMintMin: {UInt64: UInt64}
    pub var packTotalSupply: UInt64
    pub var packRedeemStartTime: UFix64


    /* 
    *   Manager resource for all NFTs
    */
    pub resource Manager {
        /* 
        *   HWGarageCard
        */
        pub fun updateHWGarageCardEditionMetadata(editionNumber: UInt64, metadata: {String: String}, packHash: String, address: Address) {
            HWGarageCard.setEditionMetadata(editionNumber: editionNumber, metadata: metadata)
            emit UpdateTokenEditionMetadata(id: editionNumber, metadata: metadata, packHash: packHash, address: address)
        }

        pub fun updateHWGarageCardCollectionMetadata(metadata: {String: String}) {
            HWGarageCard.setCollectionMetadata(metadata: metadata)
            emit UpdateHWGarageCardCollectionMetadata()
        }

        pub fun mintHWGarageCardAtEdition(edition: UInt64, packID: UInt64): @NonFungibleToken.NFT {
            emit AdminMintHWGarageCard(id: edition)
            return <-HWGaragePM.mintHWGarageCard(edition: edition, packID: packID)
        }

        pub fun mintSequentialHWGarageCard(packID: UInt64): @NonFungibleToken.NFT {
            let HWGarageCard <- HWGaragePM.mintSequentialHWGarageCard(packID: packID)
            emit AdminMintHWGarageCard(id: HWGarageCard.id)
            return <- HWGarageCard
        }

        /* 
        *   HWGaragePack
        */
        pub fun updatePackEditionMetadata(editionNumber: UInt64, metadata: {String: String}) {
            HWGaragePack.setEditionMetadata(editionNumber: editionNumber, metadata: metadata)
            emit UpdatePackEditionMetadata(id: editionNumber, metadata: metadata)
        }

        pub fun updatePackCollectionMetadata(metadata: {String: String}) {
            HWGaragePack.setCollectionMetadata(metadata: metadata)
            emit UpdatePackCollectionMetadata()
        }

        pub fun mintPackAtEdition(edition: UInt64, packID: UInt64, packEditionID: UInt64, address: Address, packHash: String): @NonFungibleToken.NFT {
            emit AdminMintHWGarageCard(id: edition)
            emit PackClaimSuccess(address: address, packHash: packHash, packID: packID)
            return <-HWGaragePM.mintPackAtEdition(edition: edition, packID: packID, packEditionID: packEditionID, packHash: packHash)
        }

        pub fun mintSequentialHWGaragePack(packID: UInt64, address: Address, packHash: String): @NonFungibleToken.NFT {
            let HWGarageCard <- HWGaragePM.mintSequentialPack(packID: packID, packHash: packHash)
            emit AdminMintPack(id: HWGarageCard.id, packHash: packHash)
            emit PackClaimSuccess(address: address, packHash: packHash, packID: HWGarageCard.id)
            return <-HWGarageCard
        }

        pub fun updateHWGaragePackRedeemStartTime(_ redeemStartTime: UFix64) {
            HWGaragePM.packRedeemStartTime = redeemStartTime
            emit UpdateHWGaragePackRedeemInfo(redeemStartTime: HWGaragePM.packRedeemStartTime)
        }

        /*
        *   HWGarageAirdrop
        */
        pub fun airdropRedeemable(
            airdropSeriesID: UInt64
            , address: Address
            , tokenMintID: UInt64
            , originalCardSerial: String
            , tokenSerial: String
            , seriesName: String
            , carName: String
            , tokenImageHash: String
            , tokenReleaseDate: String
            , tokenExpireDate: String
            , cardID: UInt64
            , templateID: String
            ): @NonFungibleToken.NFT {
            let HWGarageAirdrop <- HWGaragePM.mintSequentialAirdrop(
                airdropID: airdropSeriesID
                )
            emit AirdropRedeemable(
                WalletAddress: address
                , TokenID:HWGarageAirdrop.id // tokenEditionID 
                , TokenMintID: tokenMintID
                , OriginalCardSerial: originalCardSerial
                , TokenSerial: tokenSerial
                , SeriesName: seriesName
                , Name: carName
                , TokenImageHash: tokenImageHash
                , TokenReleaseDate: tokenReleaseDate
                , TokenExpireDate: tokenExpireDate
                , CardID: cardID
                , TemplateID: templateID
                )
            return <-HWGarageAirdrop
        }
    }

    /* 
    *   HWGarageCard
    *
    *   Mint a HWGarageCard
    */
    access(contract) fun mintHWGarageCard(edition: UInt64, packID: UInt64): @NonFungibleToken.NFT {
        pre {
            edition >= 1: "Requested edition is outisde the realm of space and time, you just lost the game."
            self.HWGarageCardsMintedEditions[edition] == nil : "Requested edition has already been minted"
        }
        self.HWGarageCardsMintedEditions[edition] = true

        let hwGarageCard <- HWGarageCard.mint(nftID: edition, packID: packID)
        return <-hwGarageCard
    }

    // look for the next Card in the sequence, and mint there
    access(self) fun mintSequentialHWGarageCard(packID: UInt64): @NonFungibleToken.NFT {
        var currentEditionNumber = HWGarageCard.getTotalSupply()
        currentEditionNumber = currentEditionNumber + 1

        self.HWGarageCardsSequentialMintMin = currentEditionNumber
        let hwGarageCard <- self.mintHWGarageCard(edition: currentEditionNumber, packID: packID)
        return <- hwGarageCard
    }

    /* 
    *   HWGaragePack
    *
    *   Mint a HWGaragePack
    */
    access(contract) fun mintPackAtEdition(edition: UInt64, packID: UInt64, packEditionID: UInt64, packHash: String): @NonFungibleToken.NFT {
        pre {
            edition >= 1: "Requested edition is outside the realm of space and time, you just lost the game."
       }

        let pack <- HWGaragePack.mint(nftID: edition, packID: packID, packEditionID: packEditionID)
        return <-pack
    }

    // Look for the next available pack, and mint there
    access(self) fun mintSequentialPack(packID: UInt64, packHash: String): @NonFungibleToken.NFT {

        var currentPackEditionNumber = HWGaragePack.getTotalSupply() + 1
        let newToken <- self.mintPackAtEdition(edition: UInt64(currentPackEditionNumber), packID: packID, packEditionID: UInt64(currentPackEditionNumber), packHash: packHash)
        return <-newToken
    }

    /* 
    *   HWGarageAirdrop
    *
    *   Mint a redeemable HWGarageAirdrop token
    */
    access(contract) fun mintSequentialAirdrop(airdropID: UInt64): @NonFungibleToken.NFT {
        var currentAirdrop = HWGaragePack.getTotalSupply() + 1
        let newAirdropToken <- HWGaragePack.mint(
            nftID: currentAirdrop
            , packID: airdropID
            , packEditionID: currentAirdrop
            )
        return <- newAirdropToken
    }


    /* 
    *   Public Functions
    *
    *   HWGaragePack
    */
    pub fun claimPack(address: Address, packHash: String) {
        // this event is picked up by a web hook to verify packHash
        // if packHash is valid, the backend will mint the pack and
        // deposit to the recipient address
        emit PackClaimBegin(address: address, packHash: packHash)
    }

    pub fun publicRedeemPack(pack: @NonFungibleToken.NFT, address: Address, packHash: String) {
        pre {
            getCurrentBlock().timestamp >= self.packRedeemStartTime: "Redemption has not yet started"
            pack.isInstance(Type<@HWGaragePack.NFT>())
        }
        let packInstance <- pack as! @HWGaragePack.NFT

        // emit event that our backend will read and mint pack contents to the associated address
        emit RedeemPack(id: packInstance.id, packID: packInstance.packID, packEditionID: packInstance.packEditionID, address: address, packHash: packHash)
        // burn pack since it was redeemed for HWGarageCard(s)
        destroy packInstance
    }


    // 
    pub fun burnAirdrop(
        walletAddress: Address
        , tokenSerial: String
        , airdropToken: @NonFungibleToken.NFT
        
    ) {
        pre{
            // check airdropIdEdition is the Type
            airdropToken.isInstance(Type<@HWGaragePack.NFT>())
        }
        let airdropInstance <- airdropToken as! @HWGaragePack.NFT
        // emit event signaling Airdrop is burned
        emit AirdropBurn(
            WalletAddress: walletAddress
            , TokenSerial: tokenSerial
            , AirdropEditionId: airdropInstance.id
            )
        destroy airdropInstance
    }

    init(){
        /*
        *   Non-human modifiable state variables
        *
        *   HWGarageCard
        */
        self.HWGarageCardsTotalSupply = 0
        self.HWGarageCardsSequentialMintMin = 1
        // Start with no existing editions minted
        self.HWGarageCardsMintedEditions = {}

        /* 
        *   HWGaragePack
        */
        self.packTotalSupply = 0
        self.packRedeemStartTime = 1658361290.0
        self.packsSequentialMintMin = 1
        // start with no existing editions minted
        self.packsMintedEditions = {}
        // setup with initial PackID
        self.packsByPackIdMintedEditions = { 1: {}}
        self.packsByPackIdSequentialMintMin = {1 : 1}


        // manager resource is only saved to the deploying account's storage
        self.ManagerStoragePath = /storage/HWGaragePM
        self.account.save(<- create Manager(), to: self.ManagerStoragePath)

        emit ContractInitialized()
    }
}
 