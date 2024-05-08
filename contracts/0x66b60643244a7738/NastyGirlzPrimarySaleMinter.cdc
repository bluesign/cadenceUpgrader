// Mainnet
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import NGPrimarySale from "./NGPrimarySale.cdc"
import NastyGirlz from "./NastyGirlz.cdc"

pub contract NastyGirlzPrimarySaleMinter {
    pub resource Minter: NGPrimarySale.IMinter {
        access(self) let setMinter: @NastyGirlz.SetMinter

        pub fun mint(assetID: UInt64, creator: Address): @NonFungibleToken.NFT {
            return <- self.setMinter.mint(templateID: assetID, creator: creator)
        }

        init(setMinter: @NastyGirlz.SetMinter) {
            self.setMinter <- setMinter
        }

        destroy() {
            destroy self.setMinter
        }
    }

    pub fun createMinter(setMinter: @NastyGirlz.SetMinter): @Minter {
        return <- create Minter(setMinter: <- setMinter)
    }
}