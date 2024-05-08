import Minter from "./Minter.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"

pub contract FlowTokenMinter {
    pub resource FungibleTokenMinter: Minter.FungibleTokenMinter {
        pub let type: Type
        pub let addr: Address

        pub fun mintTokens(acct: AuthAccount, amount: UFix64): @FungibleToken.Vault {
            let admin = acct.borrow<&FlowToken.Administrator>(from: /storage/flowTokenAdmin)
                ?? panic("admin not found")
            let minter <- admin.createNewMinter(allowedAmount: amount)
            let tokens <- minter.mintTokens(amount: amount)

            destroy minter
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