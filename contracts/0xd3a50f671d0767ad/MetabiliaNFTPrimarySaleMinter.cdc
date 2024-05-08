import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import GaiaPrimarySale from "../0x01ddf82c652e36ef/GaiaPrimarySale.cdc"
import MetabiliaNFT from "../0x28766db62a58d796/MetabiliaNFT.cdc"

pub contract MetabiliaNFTPrimarySaleMinter {
    pub resource Minter: GaiaPrimarySale.IMinter {
        access(self) let setMinter: @MetabiliaNFT.SetMinter

        pub fun mint(assetID: UInt64, creator: Address): @NonFungibleToken.NFT {
            return <- self.setMinter.mint(templateID: assetID, creator: creator)
        }

        init(setMinter: @MetabiliaNFT.SetMinter) {
            self.setMinter <- setMinter
        }

        destroy() {
            destroy self.setMinter
        }
    }

    pub fun createMinter(setMinter: @MetabiliaNFT.SetMinter): @Minter {
        return <- create Minter(setMinter: <- setMinter)
    }
}
