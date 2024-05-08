import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FlowverseTreasures from "./FlowverseTreasures.cdc"
import FlowversePrimarySale from "./FlowversePrimarySale.cdc"

pub contract FlowverseTreasuresPrimarySaleMinter {
    pub resource Minter: FlowversePrimarySale.IMinter {
        access(self) let setMinter: @FlowverseTreasures.SetMinter

        pub fun mint(entityID: UInt64, minterAddress: Address): @NonFungibleToken.NFT {
            return <- self.setMinter.mint(entityID: entityID, minterAddress: minterAddress)
        }

        init(setMinter: @FlowverseTreasures.SetMinter) {
            self.setMinter <- setMinter
        }

        destroy() {
            destroy self.setMinter
        }
    }

    pub fun createMinter(setMinter: @FlowverseTreasures.SetMinter): @Minter {
        return <- create Minter(setMinter: <- setMinter)
    }

    pub fun getPrivatePath(setID: UInt64): PrivatePath {
        let pathIdentifier = "FlowverseTreasuresPrimarySaleMinter"
        return PrivatePath(identifier: pathIdentifier.concat(setID.toString()))!
    }

    pub fun getStoragePath(setID: UInt64): StoragePath {
        let pathIdentifier = "FlowverseTreasuresPrimarySaleMinter"
        return StoragePath(identifier: pathIdentifier.concat(setID.toString()))!
    }
}