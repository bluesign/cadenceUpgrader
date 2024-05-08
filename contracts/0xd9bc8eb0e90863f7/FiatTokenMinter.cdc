import Minter from "./Minter.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FiatToken from "../0xb19436aae4d94622/FiatToken.cdc"

pub contract FiatTokenMinter {
    pub resource FungibleTokenMinter: Minter.FungibleTokenMinter {
        pub let type: Type
        pub let addr: Address

        pub fun mintTokens(acct: AuthAccount, amount: UFix64): @FungibleToken.Vault {
            let minter <-  FiatToken.createNewMinter()
            let controller <- FiatToken.createNewMinterController(publicKeys: [], pubKeyAttrs: [])

            let executor = acct.borrow<&FiatToken.MasterMinterExecutor>(from: FiatToken.MasterMinterExecutorStoragePath)
                ?? panic("executor not found")
            executor.configureMinterController(minter: minter.uuid, minterController: controller.uuid)
            controller.increaseMinterAllowance(increment: amount)

            let tokens <- minter.mint(amount: amount)

            destroy minter
            destroy controller

            return <- tokens
        }

        init(_ t: Type, _ a: Address) {
            self.type = t
            self.addr = a
        }
    }

    pub fun createMinter(_ t: Type, _ a: Address): @FungibleTokenMinter {
        return <- create FungibleTokenMinter(t, a)
    }
}