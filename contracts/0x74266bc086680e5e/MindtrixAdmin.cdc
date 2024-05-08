import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import MindtrixViews from "./MindtrixViews.cdc"
import Mindtrix from "./Mindtrix.cdc"
import MindtrixEssence from "./MindtrixEssence.cdc"
import MindtrixDonation from "./MindtrixDonation.cdc"

pub contract MindtrixAdmin {

    // ========================================================
    //                          PATH
    // ========================================================

    pub let MindtrixAdminStoragePath: StoragePath
    pub let MindtrixAdminPrivatePath: PrivatePath

    // ========================================================
    //               COMPOSITE TYPES: RESOURCE
    // ========================================================

    // TODO: should separate the Admin roles, such as RootAdmin, PackAdmin, DonationAdmin, etc. Like an IAM system.
    pub resource Admin {

        pub fun freeMintNFTFromEssence(recipient: &{NonFungibleToken.CollectionPublic}, essenceId: UInt64, strMetadata: {String: String}, claimCodeSig: String, claimCodeRandomstamp: UInt64) {
            pre {
                    (MindtrixEssence.getOneEssenceStruct(essenceId: essenceId)?.getMintPrice() ?? nil) == nil: "You have to purchase this essence."
                    (MindtrixEssence.getOneEssenceStruct(essenceId: essenceId)?.getEssenceClaimable() ?? false) == true : "This Essence is not claimable, and thus not currently active."
                }
            // early return if essenceStruct is nil        
            let essenceStruct = MindtrixEssence.getOneEssenceStruct(essenceId: essenceId)!
            let claimable = essenceStruct.getEssenceClaimable()
            let minterAddress = recipient.owner!.address
            assert(claimable == true, message: "This essence is unclaimable.")
            // verify minting conditions
            essenceStruct.verifyMintingConditions(minterAddress: minterAddress, claimCodeSig: claimCodeSig, claimCodeRandomstamp: claimCodeRandomstamp, isAssert: true)
              
            let essenceMetadata = essenceStruct.getMetadata()
            let mintedEdition = essenceStruct.currentEdition + 1
            let nftMetadata: {String: String} = {
                "nftName": essenceMetadata["essenceName"] ?? "",
                "nftDescription": essenceMetadata["essenceDescription"] ?? "",
                "essenceId": essenceId.toString(),
                "showGuid": essenceMetadata["showGuid"] ?? "",
                "collectionName": essenceMetadata["collectionName"] ?? "",
                "collectionDescription": essenceMetadata["collectionDescription"] ?? "",
                // collectionExternalURL is the Podcast link from the hosting platform.
                "collectionExternalURL": essenceMetadata["collectionExternalURL"] ?? "",
                "collectionSquareImageUrl": essenceMetadata["collectionSquareImageUrl"] ?? "",
                "collectionSquareImageType": essenceMetadata["collectionSquareImageType"] ?? "",
                "collectionBannerImageUrl": essenceMetadata["collectionBannerImageUrl"] ?? "",
                "collectionBannerImageType": essenceMetadata["collectionBannerImageType"] ?? "",
                // essenceExternalURL is the Essence page from Mindtrix Marketplace.
                "essenceExternalURL": essenceMetadata["essenceExternalURL"] ?? "",
                "episodeGuid": essenceMetadata["episodeGuid"] ?? "",
                "nftExternalURL": essenceMetadata["nftExternalURL"] ?? "",
                "nftFileIPFSCid": essenceMetadata["essenceFileIPFSCid"] ?? "",
                "nftFileIPFSDirectory": essenceMetadata["essenceFileIPFSDirectory"] ?? "",
                "nftFilePreviewUrl": strMetadata["nftFilePreviewUrl"] != nil ? strMetadata["nftFilePreviewUrl"]! : essenceMetadata["essenceFilePreviewUrl"] ?? "",
                "nftAudioPreviewUrl": strMetadata["nftAudioPreviewUrl"] ?? "",
                "nftImagePreviewUrl": strMetadata["nftImagePreviewUrl"] != nil ? strMetadata["nftImagePreviewUrl"]! : essenceMetadata["essenceImagePreviewUrl"] ?? "",
                "nftVideoPreviewUrl": essenceMetadata["essenceVideoPreviewUrl"] ?? "",
                "nftTtcTier": strMetadata["nftTtcTier"] ?? "",
                "essenceRealmSerial": essenceMetadata["essenceRealmSerial"] ?? "",
                "essenceTypeSerial": essenceMetadata["essenceTypeSerial"] ?? "",
                "essenceEpisodeImgLink": essenceMetadata["essenceEpisodeImgLink"] ?? "",
                "showSerial": essenceMetadata["showSerial"] ?? "",
                "episodeSerial": essenceMetadata["episodeSerial"] ?? "",
                "audioEssenceSerial": essenceMetadata["audioEssenceSerial"] ?? "",
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
                essenceId: essenceStruct.essenceId,
                nftEdition: mintedEdition,
                currentHolder: recipient.owner!.address,
                createdTime: getCurrentBlock().timestamp,
                royalties: newRoyalties,
                metadata: nftMetadata,
                socials: essenceStruct.socials,
                components: essenceStruct.components
            )
            recipient.deposit(token: <-  Mindtrix.mintNFT(data: data))
        }

        /// Essence Utilities
        pub fun updateEssenceMetadata(essenceId: UInt64, newMetadata: {String: String}){
            let essence = MindtrixEssence.getOneEssenceStruct(essenceId: essenceId)!
            essence.updateMetadata(newMetadata: newMetadata)
        }

        // Update essence preview URL
        pub fun updatePreviewURL(essenceId: UInt64, essenceVideoPreviewUrl: String?, essenceImagePreviewUrl: String?){
            let essence = MindtrixEssence.getOneEssenceStruct(essenceId: essenceId)!
            essence.updatePreviewURL(essenceVideoPreviewUrl: essenceVideoPreviewUrl ?? "", essenceImagePreviewUrl: essenceImagePreviewUrl ?? "")
        }

        pub fun replaceShowGuidToRoyalties(showGuid: String, creatorAddress: Address, primaryRoyalties: [MetadataViews.Royalty], secondaryRoyalties: [MetadataViews.Royalty]){
            MindtrixDonation.replaceShowGuidToRoyalties(showGuid: showGuid, creatorAddress: creatorAddress, primaryRoyalties: primaryRoyalties, secondaryRoyalties: secondaryRoyalties)
        }

    }

    init() {

        self.MindtrixAdminStoragePath = /storage/MindtrixAdmin
        self.MindtrixAdminPrivatePath = /private/MindtrixAdmin


        if self.account.borrow<&MindtrixAdmin.Admin>(from: MindtrixAdmin.MindtrixAdminStoragePath) == nil {
            self.account.save<@MindtrixAdmin.Admin>(<- create MindtrixAdmin.Admin(), to: MindtrixAdmin.MindtrixAdminStoragePath)
        }

        self.account.link<&MindtrixAdmin.Admin>(MindtrixAdmin.MindtrixAdminPrivatePath, target: MindtrixAdmin.MindtrixAdminStoragePath)!
    }

}
 