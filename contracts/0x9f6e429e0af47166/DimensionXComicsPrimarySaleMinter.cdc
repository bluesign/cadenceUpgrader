import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import GaiaPrimarySale from "../0x01ddf82c652e36ef/GaiaPrimarySale.cdc"
import DimensionXComics from "../0xe3ad6030cbaff1c2/DimensionXComics.cdc"

pub contract DimensionXComicsPrimarySaleMinter {

    pub event ContractInitialized()
    pub event MinterCreated(maxMints: Int)

    pub let MinterStoragePath: StoragePath
    pub let MinterPrivatePath: PrivatePath
    pub let MinterPublicPath: PublicPath

    pub resource interface MinterCapSetter {
        pub fun setMinterCap(minterCap: Capability<&DimensionXComics.NFTMinter>)
    }

    pub resource Minter: GaiaPrimarySale.IMinter, MinterCapSetter {
        access(contract) var dmxComicsMinterCap: Capability<&DimensionXComics.NFTMinter>?
        access(contract) let escrowCollection: @DimensionXComics.Collection

        pub let maxMints: Int
        pub var currentMints: Int

        pub fun mint(assetID: UInt64, creator: Address): @NonFungibleToken.NFT {
            pre {
                self.currentMints < self.maxMints: "mints exhausted: ".concat(self.currentMints.toString()).concat("/").concat(self.maxMints.toString())
            }

            let minter = self.dmxComicsMinterCap!.borrow() ?? panic("Unable to borrow minter")

            minter.mintNFT(recipient: &self.escrowCollection as &DimensionXComics.Collection)

            let ids = self.escrowCollection.getIDs()

            assert(ids.length == 1, message: "Escrow collection count invalid")

            let nft <- self.escrowCollection.withdraw(withdrawID: ids[0])

            self.currentMints = self.currentMints + 1
            return <- nft
        }

        pub fun setMinterCap(minterCap: Capability<&DimensionXComics.NFTMinter>) {
            self.dmxComicsMinterCap = minterCap
        }

        pub fun hasValidMinterCap(): Bool {
            return self.dmxComicsMinterCap != nil && self.dmxComicsMinterCap!.check()
        }

        init(
            maxMints: Int,
        ) {
            self.maxMints = maxMints
            self.currentMints = 0
            self.escrowCollection <- DimensionXComics.createEmptyCollection() as! @DimensionXComics.Collection
            self.dmxComicsMinterCap = nil

            emit MinterCreated(maxMints: self.maxMints)
        }

        destroy() {
            destroy self.escrowCollection
        }
    }

    pub fun createMinter(
        maxMints: Int,
    ): @Minter {
        return <- create Minter(
            maxMints: maxMints
        )
    }

    init() {
        self.MinterPrivatePath = /private/DimensionXComicsPrimarySaleMinterPrivatePath001
        self.MinterStoragePath = /storage/DimensionXComicsPrimarySaleMinterStoragePath001
        self.MinterPublicPath = /public/DimensionXComicsPrimarySaleMinterPublicPath001

        emit ContractInitialized()
    }
}
