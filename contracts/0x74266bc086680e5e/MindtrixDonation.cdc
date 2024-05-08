import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import MindtrixViews from "./MindtrixViews.cdc"
import Mindtrix from "./Mindtrix.cdc"
import MindtrixEssence from "./MindtrixEssence.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"

pub contract MindtrixDonation {

    // ========================================================
    //                          EVENT
    // ========================================================

    pub event Donate(nftId: UInt64, price: UFix64, creatorId: String, showGuid: String, episodeGuid: String, donorAddress: Address, nftName: String)
    pub event UpdateDonationRoyalties(showGuid: String, creatorAddress: Address, primaryCut: UFix64, secondaryCut: UFix64)

    // ========================================================
    //                       MUTABLE STATE
    // ========================================================

    // Store who donate which episode and the NFT uuid they owned.
    // eg: {"cl9ecksoc014i01v969ovftzy": { 0x739dbfea743996c3: [{uuid: 34, serial: 000011111, holder: 0x12345677, createdTime: 1667349560}]}}
    access(self) var episodeGuidToDonations: {String: {Address: [MindtrixViews.NFTIdentifier]}}

    // Store the royalties of each show.
    // eg: {"cl9ecksoc014i01v969ovftzy": {
    //   "primary": [
    //      {receiver: Capability<>, cut: 0.8, description: "creator's primary royalty"},
    //      {receiver: Capability<>, cut: 0.2, description: "Mindtrix's primary royalty"}
    //    ],
    //   "secondary": [
    //      {receiver: Capability<>, cut: 0.1, description: "creator's secondary royalty"},
    //      {receiver: Capability<>, cut: 0.05, description: "Mindtrix's secondary royalty"}
    //    ]
    //  }
    //}
    access(self) var showGuidToRoyalties: {String: {String: [MetadataViews.Royalty]}};

    access(self) var metadata: {String: AnyStruct}

    // ========================================================
    //                         FUNCTION
    // ========================================================

    access(account) fun updateDonorDic(donorAddress: Address, episodeGuid: String, nftIdentifier: MindtrixViews.NFTIdentifier) {

        if self.episodeGuidToDonations[episodeGuid] == nil {
            var newDonationDic: {Address: [MindtrixViews.NFTIdentifier]} =  {}
            newDonationDic.insert(key: donorAddress, [nftIdentifier])
            self.episodeGuidToDonations.insert(key: episodeGuid, newDonationDic)
        } else {
            let oldEpisodeGuidDic: {Address: [MindtrixViews.NFTIdentifier]} = self.episodeGuidToDonations[episodeGuid]!
            if self.episodeGuidToDonations[episodeGuid]![donorAddress] == nil {
                self.episodeGuidToDonations[episodeGuid]!.insert(key: donorAddress, [nftIdentifier])
            } else {
                self.episodeGuidToDonations[episodeGuid]![donorAddress]!.append(nftIdentifier)
            }
        }
    }

    access(account) fun getNFTEditionFromDonationDicByEpisodeGuid(episodeGuid: String): UInt64{
        if self.episodeGuidToDonations[episodeGuid] == nil {
            return 0
        } else {
            return UInt64(self.episodeGuidToDonations[episodeGuid]?.keys?.length ?? 0)
        }
    }

    access(account) fun replaceShowGuidToRoyalties(showGuid: String, creatorAddress: Address, primaryRoyalties: [MetadataViews.Royalty], secondaryRoyalties: [MetadataViews.Royalty]){

        var showGuidToRoyaltiesTmp: {String: {String: [MetadataViews.Royalty]}}  = {}
        var primaryRoyaltiesTmp: {String: [MetadataViews.Royalty]} = {}
        var secondaryRoyaltiesTmp: {String: [MetadataViews.Royalty]} = {}

        primaryRoyaltiesTmp.insert(key: "primary", primaryRoyalties)
        secondaryRoyaltiesTmp.insert(key: "secondary", secondaryRoyalties)
        showGuidToRoyaltiesTmp.insert(key: showGuid, primaryRoyaltiesTmp)
        showGuidToRoyaltiesTmp[showGuid]!.insert(key: "secondary", secondaryRoyalties)

        if self.showGuidToRoyalties[showGuid] == nil {
            self.showGuidToRoyalties.insert(key: showGuid, primaryRoyaltiesTmp)
            self.showGuidToRoyalties[showGuid]!.insert(key: "secondary", secondaryRoyalties)
        } else {
            self.showGuidToRoyalties[showGuid] = primaryRoyaltiesTmp
            self.showGuidToRoyalties[showGuid]!.insert(key: "secondary", secondaryRoyalties)
        }

        var i = 0
        var primaryCut = 0.0
        var secondaryCut = 0.0

        for primaryRoyalty in primaryRoyalties {
            let address = primaryRoyalty!.receiver!.address
            if address == creatorAddress {
                primaryCut = primaryRoyalty.cut
                secondaryCut = secondaryRoyalties[i].cut
            }
            i = i + 1
        }
        log("self.showGuidToRoyalties[showGuid]")
        log(self.showGuidToRoyalties[showGuid])
        emit UpdateDonationRoyalties(showGuid: showGuid, creatorAddress: creatorAddress, primaryCut: primaryCut, secondaryCut: secondaryCut)

    }

    pub fun getIsShowGuidExistInRoyalties(showGuid: String): Bool {
        return self.showGuidToRoyalties[showGuid] != nil
    }

    pub fun getShowGuidRoyalties(showGuid: String): {String: [MetadataViews.Royalty]}? {
        return self.showGuidToRoyalties[showGuid]
    }

    // the frontend will directly pass the essenceStruct without generating an Essence on-chain.
    pub fun mintNFTFromDonation(
        creatorAddress: Address,
        creatorId: String,
        donorNFTCollection: &{NonFungibleToken.CollectionPublic},
        payment: @FungibleToken.Vault,
        essenceId: UInt64,
        claimCodeSig: String, 
        claimCodeRandomstamp: UInt64
        ) {
        // Type<@FlowToken.Vault>().identifier => A.7e60df042a9c0868.FlowToken.Vault (testnet)
        let flowTokenVaultIdentifier = Type<@FlowToken.Vault>().identifier
        let essenceStruct = MindtrixEssence.getOneEssenceStruct(essenceId: essenceId)!
        let mintPrices = essenceStruct.getMintPrice()
        let claimable = essenceStruct.getEssenceClaimable()
        let minterAddress = donorNFTCollection.owner!.address
        let donatePrice = payment.balance
        assert(claimable == true, message: "Cannot donate to an unclaimable episode.")
        assert(mintPrices != nil, message: "The donation price should not be nil.")
        assert(mintPrices!.containsKey(flowTokenVaultIdentifier), message: "The the token address from the price is incorrect.")
        assert(mintPrices![flowTokenVaultIdentifier]!.price > UFix64(0), message: "The donation price should not be free.")

        // Verify minting conditions and abort if an error occurs.
        essenceStruct.verifyMintingConditions(minterAddress: minterAddress, claimCodeSig: claimCodeSig, claimCodeRandomstamp: claimCodeRandomstamp, isAssert: true)

        let mindtrixTreasuryAddress: Address = MindtrixDonation.account.address
        let essenceMetadata = essenceStruct.getMetadata()
        let showGuid = essenceMetadata["showGuid"] ?? ""

        let royaltiesFromShowGuid = MindtrixDonation.showGuidToRoyalties[showGuid] !as {String: [MetadataViews.Royalty]}
        log("showGuid:")
        log(showGuid)
        
        log("mintNFTFromDonation royaltiesFromShowGuid:")
        log(royaltiesFromShowGuid)

        var mindtrixPrimaryCut = 0.2
        var MindtrixVault: &AnyResource{FungibleToken.Receiver}? = nil
        var CreatorVault: &AnyResource{FungibleToken.Receiver}? = nil

        for primaryRoyalty in royaltiesFromShowGuid["primary"]! {
            let address = primaryRoyalty!.receiver!.address
            if address == mindtrixTreasuryAddress {
                mindtrixPrimaryCut = primaryRoyalty!.cut
                MindtrixVault = primaryRoyalty.receiver.borrow()
                    ?? panic("Could not borrow the &{FungibleToken.Receiver} from Mindtrix's Vault.");
            } else if address == creatorAddress {
                // CreatorVault = primaryRoyalty.receiver.borrow()
                //    ?? panic("Could not borrow the &{FungibleToken.Receiver} from the creator.");
            }
        }

        CreatorVault = getAccount(0xf8d6e0586b0a20c7).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow()!
    
        let mindtrixFlow <- payment.withdraw(amount: payment.balance * mindtrixPrimaryCut)

        MindtrixVault!.deposit(from: <- mindtrixFlow)
        CreatorVault!.deposit(from: <- payment)

        let episodeGuid = essenceMetadata["episodeGuid"] ?? ""

        let nftName = essenceMetadata["nftName"] ?? ""

        let donorAddress = donorNFTCollection.owner!.address
        let mintedEdition = self.getNFTEditionFromDonationDicByEpisodeGuid(episodeGuid: episodeGuid) + 1
        let nftMetadata: {String: String} = {
            "nftName": nftName,
            // donor fields-start
            "donorName": essenceMetadata["donorName"] ?? "",
            "donorMessage": essenceMetadata["donorMessage"] ?? "",
            // donor fields-end
            "nftDescription": essenceMetadata["essenceDescription"] ?? "",
            "essenceId": essenceId.toString(),
            "showGuid": showGuid,
            "collectionName": essenceMetadata["collectionName"] ?? "",
            "collectionDescription": essenceMetadata["collectionDescription"] ?? "",
            // collectionExternalURL is the Podcast link from the hosting platform.
            "collectionExternalURL": essenceMetadata["collectionExternalURL"] ?? "",
            "collectionSquareImageUrl": essenceMetadata["collectionSquareImageUrl"] ?? "",
            "collectionSquareImageType": essenceMetadata["collectionSquareImageType"] ?? "",
            "collectionBannerImageUrl": essenceMetadata["collectionBannerImageUrl"] ?? "",
            "collectionBannerImageType": essenceMetadata["collectionBannerImageType"] ?? "",
            // essenceExternalURL is the Donation page from Mindtrix Marketplace
            "essenceExternalURL": essenceMetadata["essenceExternalURL"] ?? "",
            "episodeGuid": episodeGuid,
            "nftExternalURL": essenceMetadata["nftExternalURL"] ?? "",
            "nftFileIPFSCid": essenceMetadata["essenceFileIPFSCid"] ?? "",
            "nftFileIPFSDirectory": essenceMetadata["essenceFileIPFSDirectory"] ?? "",
            "nftFilePreviewUrl": essenceMetadata["essenceFilePreviewUrl"] ?? "",
            "nftImagePreviewUrl": essenceMetadata["essenceImagePreviewUrl"] ?? "",
            "nftVideoPreviewUrl": essenceMetadata["essenceVideoPreviewUrl"] ?? "",
            "essenceRealmSerial": essenceMetadata["essenceRealmSerial"] ?? "",
            "essenceTypeSerial": essenceMetadata["essenceTypeSerial"] ?? "",
            "showSerial": essenceMetadata["showSerial"] ?? "",
            "episodeSerial": essenceMetadata["episodeSerial"] ?? "",
            "audioEssenceSerial": "0",
            "nftEditionSerial": mintedEdition.toString(),
            "licenseIdentifier": essenceMetadata["licenseIdentifier"] ?? "",
            "audioStartTime": essenceMetadata["audioStartTime"] ?? "",
            "audioEndTime": essenceMetadata["audioEndTime"] ?? "",
            "fullEpisodeDuration": essenceMetadata["fullEpisodeDuration"] ?? ""
        }

        var orgRoyalties = essenceStruct.getRoyalties() as! [MetadataViews.Royalty]
        var royaltiesMap: {Address: MetadataViews.Royalty} = {}
        // the royalties address should not be duplicated
        for royalty in orgRoyalties {
            let receipientAddress = royalty.receiver.address
            if !royaltiesMap.containsKey(receipientAddress) {
                royaltiesMap.insert(key: receipientAddress, royalty)
            }
        }
        let newRoyalties = royaltiesMap.values

        let data = Mindtrix.NFTStruct(
            nftId: nil,
            essenceId: essenceId,
            nftEdition: mintedEdition,
            currentHolder: donorAddress,
            createdTime: getCurrentBlock().timestamp,
            royalties: newRoyalties,
            metadata: nftMetadata,
            socials: essenceStruct.socials,
            components: essenceStruct.components
        )

        log("donation mint data:")
        log(data)

        let nft <- Mindtrix.mintNFT(data: data)
        let nftId = nft.id
        log("nftId:".concat(nftId.toString()))

        let nftIdentifier = MindtrixViews.NFTIdentifier(
            uuid: nftId,
            serial: mintedEdition,
            holder: donorAddress
        )

        self.updateDonorDic(donorAddress: donorAddress, episodeGuid: episodeGuid, nftIdentifier: nftIdentifier)
        donorNFTCollection.deposit(token: <- nft )
        emit Donate(
            nftId: nftId,
            price: donatePrice,
            creatorId: creatorId,
            showGuid: showGuid,
            episodeGuid: episodeGuid,
            donorAddress: donorAddress,
            nftName: nftName
        )

    }

    init() {
        self.episodeGuidToDonations = {}
        self.showGuidToRoyalties = {}
        self.metadata = {}
    }
}
 