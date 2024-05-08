import AFLNFT from "./AFLNFT.cdc"
import AFLPack from "./AFLPack.cdc"
import AFLBurnExchange from "./AFLBurnExchange.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import PackRestrictions from "./PackRestrictions.cdc"

pub contract AFLAdmin {

    // Admin
    // the admin resource is defined so that only the admin account
    // can have this resource. It possesses the ability to open packs
    // given a user's Pack Collection and Card Collection reference.
    // It can also create a new pack type and mint Packs.
    //
    pub resource Admin {

        pub fun createTemplate(maxSupply:UInt64, immutableData:{String: AnyStruct}): UInt64 {
            return AFLNFT.createTemplate(maxSupply:maxSupply, immutableData:immutableData)
        }

        pub fun updateImmutableData(templateID:UInt64, immutableData:{String: AnyStruct}){
            let templateRef = &AFLNFT.allTemplates[templateID] as &AFLNFT.Template?
            templateRef?.updateImmutableData(immutableData) ?? panic("Template does not exist")
        }

        pub fun addRestrictedPack(id: UInt64) {
            PackRestrictions.addPackId(id: id)
        }

        pub fun removeRestrictedPack(id: UInt64) {
            PackRestrictions.removePackId(id: id)
        }

        pub fun openPack(templateInfo: {String: UInt64}, account: Address){
            AFLNFT.mintNFT(templateInfo:templateInfo, account:account)
        }

        pub fun mintNFT(templateInfo: {String: UInt64}): @NonFungibleToken.NFT {
            return <- AFLNFT.mintAndReturnNFT(templateInfo:templateInfo)
        }

        pub fun addTokenForExchange(nftId: UInt64, token: @NonFungibleToken.NFT) {
            AFLBurnExchange.addTokenForExchange(nftId: nftId, token: <- token)
        }

        pub fun withdrawTokenFromBurnExchange(nftId: UInt64): @NonFungibleToken.NFT {
            return <- AFLBurnExchange.withdrawToken(nftId: nftId)
        }

        // createAdmin
        // only an admin can ever create
        // a new Admin resource
        //
        pub fun createAdmin(): @Admin {
            return <- create Admin()
        }

        init() {
            
        }
    }

    init() {
        self.account.save(<- create Admin(), to: /storage/AFLAdmin)
    }
}