/**
> Author: FIXeS World <https://fixes.world/>

# Black Hole is the utility contract for burning fungible tokens on the Flow blockchain.

## Features:

- You can register a BlackHole Resource from the BlackHole contract.
- Users can burn fungible tokens by sending them to the random BlackHole Resource.
- Users can get the balance of vanished fungible tokens by the type of the Fungible Token in the BlackHole Resource.

*/
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import StringUtils from "../0xa340dc0a4ec828ab/StringUtils.cdc"

/// BlackHole contract
///
access(all) contract BlackHole {
    /* --- Events --- */

    /// Event emitted when a new BlackHole Resource is registered
    access(all) event NewBlackHoleRegistered(
        blackHoleAddr: Address,
        blackHoleId: UInt64,
    )

    /// Event emitted when a new Fungible Token is registered
    access(all) event FungibleTokenVanished(
        blackHoleAddr: Address,
        blackHoleId: UInt64,
        vaultIdentifier: Type,
        amount: UFix64,
    )

    /* --- Variable, Enums and Structs --- */

    /// BlackHole Resource
    access(all) let storagePath: StoragePath
    /// BlackHoles Registry
    access(contract) let blackHoles: {Address: Bool}

    /* --- Interfaces & Resources --- */

    /// The public interface for the BlackHole Resource
    ///
    access(all) resource interface BlackHolePublic {
        /// Check if the BlackHole Resource is valid
        access(all) view
        fun isValid(): Bool
        /// Get the balance by the type of the Fungible Token
        access(all) view
        fun getVanishedBalanced(_ type: Type): UFix64
    }

    /// The resource of BlackHole Fungible Token Receiver
    ///
    access(all) resource Receiver: FungibleToken.Receiver, BlackHolePublic {
        /// The dictionary of Fungible Token Pools
        access(self) let pools: @{Type: FungibleToken.Vault}

        init() {
            self.pools <- {}
        }

        /// @deprecated in Cadence 1.0
        destroy() {
            destroy self.pools
        }

        /** ---- FungibleToken Receiver Interface ---- */

        /// Takes a Vault and deposits it into the implementing resource type
        ///
        /// @param from: The Vault resource containing the funds that will be deposited
        ///
        access(all)
        fun deposit(from: @FungibleToken.Vault) {
            pre {
                self.isValid(): "The BlackHole Resource should be valid"
                from.balance > UFix64(0): "The balance should be greater than zero"
            }
            let fromType = from.getType()
            let receiverRef = self._borrowOrCreateBlackHoleVault(fromType)
            let vanishedAmount = from.balance
            receiverRef.deposit(from: <- from)

            emit BlackHole.FungibleTokenVanished(
                blackHoleAddr: self.owner?.address ?? panic("Invalid BlackHole Address"),
                blackHoleId: self.uuid,
                vaultIdentifier: fromType,
                amount: vanishedAmount
            )
        }

        /** ---- BlackHolePublic Interface ---- */

        /// Check if the BlackHole Resource is valid
        /// Valid means that the owner's account should have all keys revoked
        ///
        access(all) view
        fun isValid(): Bool {
            /// The Keys in the owner's account should be all revoked
            if let ownerAddr = self.owner?.address {
                let ownerAcct = getAccount(ownerAddr)
                // Check if all keys are revoked
                var isAllKeyRevoked = true
                ownerAcct.keys.forEach(fun (key: AccountKey): Bool {
                    isAllKeyRevoked = isAllKeyRevoked && key.isRevoked
                    return isAllKeyRevoked
                })
                return isAllKeyRevoked
            }
            return false
        }

        /// Get the balance by the type of the Fungible Token
        ///
        access(all) view
        fun getVanishedBalanced(_ type: Type): UFix64 {
            return self.pools[type]?.balance ?? 0.0
        }

        /** ---- Internal Methods ---- */

        /// Borrow the FungibleToken Vault
        ///
        access(self)
        fun _borrowOrCreateBlackHoleVault(_ type: Type): &FungibleToken.Vault {
            pre {
                type.isSubtype(of: Type<@FungibleToken.Vault>()): "The type should be a subtype of FungibleToken.Vault"
            }
            if let ref = &self.pools[type] as &FungibleToken.Vault? {
                return ref
            } else {
                let ftArr = StringUtils.split(type.identifier, ".")
                let ftAddress = Address.fromString("0x".concat(ftArr[1])) ?? panic("Invalid Fungible Token Address")
                let ftContractName = ftArr[2]
                let ftContract = getAccount(ftAddress)
                    .contracts.borrow<&FungibleToken>(name: ftContractName)
                    ?? panic("Could not borrow the FungibleToken contract reference")
                // @deprecated in Cadence 1.0
                self.pools[type] <-! ftContract.createEmptyVault()
                return &self.pools[type] as &FungibleToken.Vault? ?? panic("Invalid Fungible Token Vault")
            }
        }
    }

    /** --- Methods --- */

    /// Get the receiver path for the BlackHole Resource
    ///
    /// @return The PublicPath for the generic BlackHole receiver
    ///
    access(all) view
    fun getBlackHoleReceiverPublicPath(): PublicPath {
        return /public/BlackHoleFTReceiver
    }

    /// Get the storage path for the BlackHole Resource
    ///
    /// @return The StoragePath for the generic BlackHole receiver
    ///
    access(all) view
    fun getBlackHoleReceiverStoragePath(): StoragePath {
        return self.storagePath
    }

    /// Create a new BlackHole Resource
    ///
    access(all)
    fun createNewBlackHole(): @Receiver {
        return <- create Receiver()
    }

    /// Register an address as a new BlackHole
    ///
    access(all)
    fun registerAsBlackHole(_ addr: Address) {
        if self.blackHoles[addr] == nil {
            let ref = self.borrowBlackHoleReceiver(addr)
                ?? panic("Could not borrow the BlackHole Resource")
            assert(
                ref.isValid(),
                message: "The BlackHole Resource should be valid"
            )
            self.blackHoles[addr] = true

            // emit the event
            emit NewBlackHoleRegistered(
                blackHoleAddr: addr,
                blackHoleId: ref.uuid
            )
        }
    }

    /// Borrow a BlackHole Resource by the address
    ///
    access(all)
    fun borrowBlackHoleReceiver(_ addr: Address): &Receiver{FungibleToken.Receiver, BlackHolePublic}? {
        return getAccount(addr)
            .getCapability<&Receiver{FungibleToken.Receiver, BlackHolePublic}>(self.getBlackHoleReceiverPublicPath())
            .borrow()
    }

    /// Check if is the address a valid BlackHole address
    ///
    access(all) view
    fun isValidBlackHole(_ addr: Address): Bool {
        return self.borrowBlackHoleReceiver(addr)?.isValid() == true
    }

    /// Register a BlackHole Resource
    ///
    access(all)
    fun borrowRandomBlackHoleReceiver(): &Receiver{FungibleToken.Receiver} {
        let max = self.blackHoles.keys.length
        assert(max > 0, message: "There is no BlackHole Resource")
        let rand = revertibleRandom()
        let blackHoleAddr = self.blackHoles.keys[Int(rand) % max]
        return self.borrowBlackHoleReceiver(blackHoleAddr) ?? panic("Could not borrow the BlackHole Resource")
    }

    /// Get the registered BlackHoles addresses
    ///
    access(all) view
    fun getRegisteredBlackHoles(): [Address] {
        return self.blackHoles.keys
    }

    /// Burn the Fungible Token by sending it to the BlackHole Resource
    ///
    access(all)
    fun vanish(_ vault: @FungibleToken.Vault) {
        let blackHole = self.borrowRandomBlackHoleReceiver()
        blackHole.deposit(from: <- vault)
    }

    init() {
        let identifier = "BlackHole_".concat(self.account.address.toString()).concat("_receiver")
        self.storagePath = StoragePath(identifier: identifier)!

        self.blackHoles = {}
    }
}
