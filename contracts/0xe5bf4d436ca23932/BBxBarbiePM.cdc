/* 
*   A contract that manages the creation and sale of packs and tokens
*
*   A manager resource exists allow modifying the parameters of the public
*   sale and have the capability to mint editions themselves
*/

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
import BBxBarbieToken from "./BBxBarbieToken.cdc"
import BBxBarbieCard from "./BBxBarbieCard.cdc"
import BBxBarbiePack from "./BBxBarbiePack.cdc"

pub contract BBxBarbiePM {
    /* 
    *   Events
    *
    *   emitted when the contract is deployed
    */
    pub event ContractInitialized()

    /* 
    *   BBxBarbieToken
    *
    *   emmited when an admin airdrops a redeemable card to an address
    */
    pub event AirdropRedeemable(
        WalletAddress: Address
        , TokenID:UInt64
        , TokenMintID: String
        , OriginalCardSerial: String
        , TokenSerial: String
        , SeriesName: String
        , Name: String
        , TokenImageHash: String
        , TokenReleaseDate: String
        , TokenExpireDate: String
        , CardID: String
        , TemplateID: String
    )
    
    // emitted when a new token series is added
    pub event AdminAddNewTokenSeries(
        tokenSeriesID: UInt64
        )

    pub event AdminMintToken(
        uuid: UInt64
        , id: UInt64
        , metadata: {String: String}
        )

    pub event AirdropBurn(
        WalletAddress: Address
        , TokenSerial: String
        , AirdropEditionId: UInt64
    )
    /* 
    *   BBxBarbieCard
    *
    *   emmited when an admin has initiated a mint of a BBxBarbieCard
    */

    // emitted when a new pack series is added
    pub event AdminAddNewCardSeries(
        cardSeriesID: UInt64
        )


    pub event AdminMintCard(
        uuid: UInt64
        , id: UInt64
        , metadata: {String: String}
        , packHash: String
        , address: Address
    )


    // emmited when the metadata for an BBxBarbieCard collection is updated
    pub event UpdateCardCollectionMetadata()


    /* 
    *   BBxBarbiePack
    *
    */

    // emitted when a new pack series is added
    pub event AdminAddNewPackSeries(
        packSeriesID: UInt64
        )


    // emitted when an admin has initiated a mint of a BBxBarbieCard
    pub event AdminMintPack(
        uuid: UInt64
        , packHash: String
        , packSeriesID: UInt64
        , packID: UInt64 // aka packEditionID
        , metadata: {String: String}
        )


    // emitted when someone redeems a BBxBarbieCard for Tokens
    pub event RedeemPack(
        id: UInt64
        , packID: UInt64 // aka packEditionID
        , packSeriesID: UInt64
        , address: Address
        , packHash: String
        )


    // emitted when a user submits a packHash to claim a pack
    pub event PackClaimBegin(
        address: Address
        , packHash: String
        )


    // emitted when a user succesfully claims a pack

    pub event PackClaimSuccess(
        address: Address
        , packHash: String
        , packID: UInt64 // aka packEditionID
        )


    /* 
    *   Named Paths
    */
    pub let ManagerStoragePath: StoragePath


    /* 
    *   BBxBarbiePM fields
    */
    access(self) var BBxBarbieSeriesIdIsLive: {UInt64: Bool}


    /* 
    *   BBxBarbieCard
    */
    access(self) var BBxBarbieTokenSeriesIdIsLive: {UInt64: Bool}


    /* 
    *   BBxBarbieCard
    */
    access(self) var BBxBarbieCardSeriesIdIsLive: {UInt64: Bool}


    /* 
    *   BBxBarbiePack
    */
    // We need a way to track if a series is live
    // This dictionary will be updated before each drop to insert the series that is to be released
    // For example, the contract launches with an empty dictionary of {}
    // In order to prepare for a drop we need to have an admin execute admin_add_packSeries.cdc
    // This transaction takes a UInt64 as a parameter
    // NOTE: Once a series is added, it is live and a valid pack hash will mint that a pack to a user wallet
    access(self) var BBxBarbiePackSeriesIdIsLive: {UInt64: Bool}


    // Do we want to update when the pack Redeeming begins? because we can
    pub var packRedeemStartTime: UFix64
    // should we have a state variable to start/stop packClaim
    // should we have a state variable to start/stop packRedeem


    /* 
    *   Manager resource for all NFTs
    */
    pub resource Manager {
        /*
         *  BBxBarbiePM
         */

         // One call to add a new seriesID for Packs and Card
         pub fun addNewSeriesID(seriesID: UInt64){
            BBxBarbiePM.addSeriesID(seriesID: seriesID)
            self.addPackSeriesID(packSeriesID: seriesID)
            self.addCardSeriesID(packSeriesID: seriesID)
            self.addTokenSeriesID(packSeriesId: seriesID)
         }

        /* 
        *   BBxBarbieToken
        */
        pub fun addTokenSeriesID(packSeriesId: UInt64) {
            pre {
                packSeriesId >= 1: "Requested series does not exists in this scope."
            }

            BBxBarbiePM.addTokenSeriesID(tokenSeriesID: packSeriesId)
            
            emit AdminAddNewTokenSeries(tokenSeriesID: packSeriesId)
            
        }

        pub fun mintSequentialBBxBarbieToken(
            address: Address
            , packSeriesID: UInt64
            , metadata: {String: String}
            ): @NonFungibleToken.NFT {
            
            pre {
                packSeriesID >= 1: "Requested series does not exist in this scope."
            }

            let BBxBarbieToken <- BBxBarbiePM.mintSequentialToken(
                packSeriesID: packSeriesID
                , metadata: metadata
                )

            emit AdminMintToken(
                uuid: BBxBarbieToken.uuid
                , id: BBxBarbieToken.id
                , metadata: metadata
                )
            
            emit AirdropRedeemable(
                WalletAddress: address
                , TokenID:BBxBarbieToken.id // aka tokenEditionID
                , TokenMintID: metadata["mint"] ?? "N/A"
                , OriginalCardSerial: metadata["originalCardSerialNumber"] ?? "N/A"
                , TokenSerial: metadata["serialNumber"] ?? "N/A"
                , SeriesName: metadata["seriesName"] ?? "N/A"
                , Name: metadata["name"] ?? "N/A"
                , TokenImageHash: metadata["imageCID"] ?? "N/A"
                , TokenReleaseDate: metadata["releaseDate"] ?? "N/A"
                , TokenExpireDate: metadata["expirationDate"] ?? "N/A"
                , CardID: metadata["cardId"] ?? "N/A"
                , TemplateID: metadata["templateId"] ?? "N/A"
            )
            return <- BBxBarbieToken
        }        

        /* 
        *   BBxBarbieCard
        */

        // Add a packSeries to the dictionary to support a new drop
        pub fun addCardSeriesID(packSeriesID: UInt64) {
            pre {
                packSeriesID >= 1: "Requested series does not exist in this scope."
            }

            BBxBarbiePM.addCardSeriesID(cardSeriesID: packSeriesID)
            
            emit AdminAddNewCardSeries(cardSeriesID: packSeriesID)
        }


        pub fun mintSequentialBBxBarbieCard(
            address: Address
            , packHash: String
            , packSeriesID: UInt64
            , packEditionID: UInt64
            , redeemable: String
            , metadata: {String: String}
            ): @NonFungibleToken.NFT {

            let BBxBarbieCard <- BBxBarbiePM.mintSequentialCard(
                packHash: packHash
                , packSeriesID: packSeriesID
                , packEditionID: packEditionID
                , metadata: metadata
                )

            emit AdminMintCard(
                uuid: BBxBarbieCard.uuid
                , id: BBxBarbieCard.id
                , metadata: metadata
                , packHash: packHash
                , address: address
                
            )

            return <- BBxBarbieCard
        }


        /* 
        *   BBxBarbiePack
        */

        // Add a packSeries to the dictionary to support a new drop
        pub fun addPackSeriesID(packSeriesID: UInt64) {
            pre {
                packSeriesID >= 1: "PM - Requested series does not exist in this scope."
                BBxBarbiePM.BBxBarbiePackSeriesIdIsLive.containsKey(packSeriesID) == false: "PM - Requested pack series already exists."
            }

            BBxBarbiePM.addPackSeriesID(packSeriesID: packSeriesID)
            
            emit AdminAddNewPackSeries(packSeriesID: packSeriesID)
        }


        pub fun mintSequentialBBxBarbiePack(
            address: Address
            , packHash: String
            , packSeriesID: UInt64
            , metadata: {String: String}
            ): @NonFungibleToken.NFT {
            
            pre {
                packSeriesID >= 1: "PM - Requested series does not exist in this scope."
                BBxBarbiePM.BBxBarbiePackSeriesIdIsLive.containsKey(packSeriesID) == true: "PM - Requested pack series is not ready."
            }

            let BBxBarbiePack <- BBxBarbiePM.mintSequentialPack(
                packHash: packHash
                , packSeriesID: packSeriesID
                , metadata: metadata
                )

            emit AdminMintPack(
                uuid: BBxBarbiePack.uuid
                , packHash: packHash
                , packSeriesID: packSeriesID
                , packID: BBxBarbiePack.id // aka packEditionID
                , metadata: metadata
                )

            emit PackClaimSuccess(
                address: address
                , packHash: packHash
                , packID: BBxBarbiePack.id // aka packEditionID
                )

            return <-BBxBarbiePack
        }


    } /// end admin block

    access(contract) fun addSeriesID(seriesID: UInt64) {
        pre {
            seriesID >= 1: "Requested series does not exist in this scope."
        }

        self.BBxBarbieSeriesIdIsLive.insert(key: seriesID, true)
    }


    /* 
    *   BBxBarbieToken
    *
    *   Mint a BBxBarbieToken
    */

    // Add a packSeries to the dictionary to support a new drop
    access(contract) fun addTokenSeriesID(tokenSeriesID: UInt64) {
        pre {
            tokenSeriesID >= 1: "Requested series does not exist in this scope."
            BBxBarbiePM.BBxBarbieTokenSeriesIdIsLive.containsKey(tokenSeriesID) == false: "Requested token series already exists."
        }

        self.BBxBarbieTokenSeriesIdIsLive.insert(key: tokenSeriesID, true)
        
        BBxBarbieToken.addNewSeries(newTokenSeriesID: tokenSeriesID)
    }


    // look for the next Card in the sequence, and mint there
    access(self) fun mintSequentialToken(
        packSeriesID: UInt64
        , metadata: {String: String}
        ): @NonFungibleToken.NFT {
        pre {
            packSeriesID >= 1: "PM - Requested series does not exist in this scope."
            self.BBxBarbieTokenSeriesIdIsLive.containsKey(packSeriesID) == true: "PM - Requested token series is not ready at this time."
        }

        var currentEditionNumber = BBxBarbieToken.getTotalSupply() + 1
        
        let newToken <- BBxBarbieToken.mint(

            nftID:currentEditionNumber
            , packSeriesID: packSeriesID
            , tokenEditionID: currentEditionNumber
            , metadata: metadata
            )

        return <- newToken
    }    

    /* 
    *   BBxBarbieCard
    *
    *   Mint a BBxBarbieCard
    */

    // Add a packSeries to the dictionary to support a new drop
    access(contract) fun addCardSeriesID(cardSeriesID: UInt64) {
        pre {
            cardSeriesID >= 1: "Requested series does not exist in this scope."
            BBxBarbiePM.BBxBarbieCardSeriesIdIsLive.containsKey(cardSeriesID) == false: "Requested card series already exists."
        }

        self.BBxBarbieCardSeriesIdIsLive.insert(key: cardSeriesID, true)
        
        BBxBarbieCard.addNewSeries(newCardSeriesID: cardSeriesID)
    }


    // look for the next Card in the sequence, and mint there
    access(self) fun mintSequentialCard(
        packHash: String
        , packSeriesID: UInt64
        , packEditionID: UInt64
        , metadata: {String: String}    
        ): @NonFungibleToken.NFT {
        pre {
            packSeriesID >= 1: "PM - Requested series does not exist in this scope."
            self.BBxBarbieCardSeriesIdIsLive.containsKey(packSeriesID) == true: "PM - Requested card series is not ready at this time."
        }

        var currentEditionNumber = BBxBarbieCard.getTotalSupply() + 1
        
        let newCard <- BBxBarbieCard.mint(
            nftID:currentEditionNumber
            , packSeriesID: packSeriesID
            , cardEditionID: currentEditionNumber
            , packHash: packHash
            , metadata: metadata
            )

        return <- newCard
    }

    /* 
    *   BBxBarbiePack
    *
    *   Mint a BBxBarbiePack
    */
    // Add a packSeries to the dictionary to support a new drop
    access(contract) fun addPackSeriesID(packSeriesID: UInt64) {
        pre {
            packSeriesID >= 1: "PM - Requested series does not exist in this scope."
            self.BBxBarbiePackSeriesIdIsLive.containsKey(packSeriesID) == false: "PM - Requested pack series already exists."
        }

        self.BBxBarbiePackSeriesIdIsLive.insert(key: packSeriesID, true)

        BBxBarbiePack.addNewSeries(newPackSeriesID: packSeriesID)
    }


    // Look for the next available pack, and mint there
    access(self) fun mintSequentialPack(
        packHash: String
        , packSeriesID: UInt64
        , metadata: {String: String}
    ): @NonFungibleToken.NFT {
        pre {
            packSeriesID >= 1: "Requested series does not exist in this scope."
            // add a check to verify if the right series has been passed in
            // i.e.: series 2 packs cannot be minted if series 2 is NOT active
            // self.BBxBarbieSeriesIdIsLive.containsKey(packSeriesID) == true: "Requested pack series is not ready at this time."
            self.BBxBarbiePackSeriesIdIsLive.containsKey(packSeriesID) == true: "PM - Requested pack series is not ready at this time."
        }

        // Grab the packEditionID to mint 
        var currentPackEditionNumber = BBxBarbiePack.getTotalSupply() + 1

        let newPack <- BBxBarbiePack.mint(
            nftID: currentPackEditionNumber // pack X of Y
            , packEditionID: currentPackEditionNumber // pack X of Y
            , packSeriesID: packSeriesID  // aka series
            , packHash: packHash
            , metadata: metadata
            )

        return <-newPack
    }


    /* 
    *   Public Functions
    *
    *   BBxBarbiePM
    */

    pub fun getEnabledSeries(): {UInt64: Bool}{
        return BBxBarbiePM.BBxBarbieSeriesIdIsLive
    }

    pub fun getEnabledTokenSeries(): {UInt64: Bool}{
        return BBxBarbiePM.BBxBarbieTokenSeriesIdIsLive
    }

    pub fun getEnabledCardSeries(): {UInt64: Bool}{
        return BBxBarbiePM.BBxBarbieCardSeriesIdIsLive
    }


    pub fun getEnabledPackSeries(): {UInt64: Bool}{
        return BBxBarbiePM.BBxBarbiePackSeriesIdIsLive
    }


    /*
     *  Public Pack Functions
     */

    pub fun claimPack(address: Address, packHash: String) {
        // this event is picked up by a web hook to verify packHash
        // if packHash is valid, the backend will mint the pack and
        // deposit to the recipient address
        emit PackClaimBegin(address: address, packHash: packHash)
    }


    pub fun publicRedeemPack(
        address: Address,
        pack: @NonFungibleToken.NFT,
        packHash: String
        ) {
        pre {
            getCurrentBlock().timestamp >= self.packRedeemStartTime: "PM - Redemption has not yet started"
            pack.isInstance(Type<@BBxBarbiePack.NFT>())
        }

        let packInstance <- pack as! @BBxBarbiePack.NFT

        // emit event that our backend will read and mint pack contents to the associated address
        emit RedeemPack(
            id: packInstance.id,
            packID: packInstance.packEditionID,
            packSeriesID: packInstance.packSeriesID,
            address: address,
            packHash: packHash
            )
        // burn pack since it was redeemed for BBxBarbieCard(s)
        destroy packInstance
    }


    pub fun getPackEditionIdByPackSeriesId(): {UInt64: UInt64}{
        return BBxBarbiePack.currentPackEditionIdByPackSeriesId
    }


    pub fun getCardEditionIdByPackSeriesId(): {UInt64: UInt64}{
        return BBxBarbieCard.currentCardEditionIdByPackSeriesId
    }


    pub fun getTokenEditionIdByPackSeriesId(): {UInt64: UInt64}{
        return BBxBarbieToken.currentTokenEditionIdByPackSeriesId
    }

    /*
     *  Public Airdrop Functions
    */
    
    pub fun burnAirdrop(
        walletAddress: Address
        , tokenSerial: String
        , airdropToken: @NonFungibleToken.NFT
    ) {
        pre{
            // check airdropEdition is the right Type
            airdropToken.isInstance(Type<@BBxBarbieToken.NFT>())
        }
        let airdropInstance <- airdropToken as! @BBxBarbieToken.NFT
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
        *   State variables
        *   BBxBarbiePM
        */
        // start with no existing series enabled
        // {1: true, 2: true} when series 1 and 2 are live
        self.BBxBarbieSeriesIdIsLive = {}


        /*
        *   BBxBarbieToken
        */
        self.BBxBarbieTokenSeriesIdIsLive = {}

        /*
        *   BBxBarbieCard
        */
        self.BBxBarbieCardSeriesIdIsLive = {}


        /* 
        *   BBxBarbiePack
        */
        self.packRedeemStartTime = 1658361290.0
        self.BBxBarbiePackSeriesIdIsLive = {}


        // manager resource is only saved to the deploying account's storage
        self.ManagerStoragePath = /storage/BBxBarbiePM
        self.account.save(<- create Manager(), to: self.ManagerStoragePath)

        emit ContractInitialized()
    }
}
 