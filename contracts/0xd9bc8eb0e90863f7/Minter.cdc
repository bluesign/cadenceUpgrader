import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

pub contract Minter {
    pub let StoragePath: StoragePath

    pub event MinterAdded(_ t: Type)

    pub resource interface FungibleTokenMinter {
        pub let type: Type
        pub let addr: Address

        pub fun mintTokens(acct: AuthAccount, amount: UFix64): @FungibleToken.Vault
    }

    pub resource interface AdminPublic {
        pub fun borrowMinter(_ t: Type): &{FungibleTokenMinter}?
        pub fun getTypes(): [Type]
    }

    pub resource Admin: AdminPublic {
        pub let minters: @{Type: {FungibleTokenMinter}} // type to a minter interface

        pub fun registerMinter(_ m: @{FungibleTokenMinter}) {
            emit MinterAdded(m.getType())
            destroy <- self.minters.insert(key: m.type, <- m)
        }

        pub fun borrowMinter(_ t: Type): &{FungibleTokenMinter} {
            return (&self.minters[t] as &{FungibleTokenMinter}?)!
        }

        pub fun getTypes(): [Type] {
            return self.minters.keys
        }

        init() {
            self.minters <- {}
        }

        destroy () {
            destroy self.minters
        }
    }

    pub fun borrowAdminPublic(): &Admin{AdminPublic}? {
        return self.account.borrow<&Admin{AdminPublic}>(from: self.StoragePath)
    }

    pub fun createAdmin(): @Admin {
        return <- create Admin()
    }

    init() {
        self.StoragePath = /storage/MinterAdmin

        let a <- create Admin()
        self.account.save(<- a, to: self.StoragePath)
    }
}
 