import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract CollectionVault {
    pub event VaultAccessed(key: String)

    pub let DefaultStoragePath: StoragePath
    pub let DefaultPublicPath: PublicPath
    pub let DefaultPrivatePath: PrivatePath

    pub resource interface VaultPublic {
        pub fun storeVaultPublic(capability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>)
    }

    pub resource Vault: VaultPublic {
        access(contract) var storedCapabilities: {String: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>}
        access(contract) var allowedPublic: [String]?
        access(contract) var enabled: Bool

        pub fun getKeys(): [String] {
            return self.storedCapabilities.keys
        }

        pub fun hasKey(_ key: String): Bool {
            let capability = self.storedCapabilities[key]
            if capability == nil { return false }
            return capability!.check()
        }

        pub fun getVault(_ key: String): &{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}? {
            let capability = self.storedCapabilities[key]
            if capability == nil { return nil }
            emit VaultAccessed(key: key)
            return capability!.borrow()
        }

        pub fun storeVault(_ key: String, capability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>) {
            self.storedCapabilities.insert(key: key, capability)
        }

        pub fun storeVaultPublic(capability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>) {
            let collection = capability.borrow() ?? panic("Could not borrow capability")
            let type = collection.getType().identifier
            if self.allowedPublic != nil && !self.allowedPublic!.contains(type) {
                panic("Type ".concat(type).concat(" is not allowed for storeVaultPublic"))
            }
            let owner = collection.owner ?? panic("Collection must be owned in order to use storeVaultPublic")

            let key = type.concat("@").concat(owner.address.toString())

            self.storedCapabilities.insert(key: key, capability)
        }

        pub fun removeVault(_ key: String) {
            self.storedCapabilities.remove(key: key)
        }

        pub fun setAllowedPublic(_ allowedPublic: [String]?) {
            self.allowedPublic = allowedPublic
        }

        init(_ allowedPublic: [String]?) {
            self.storedCapabilities = {}
            self.allowedPublic = allowedPublic
            self.enabled = true
        }
    }

    pub fun createEmptyVault(_ allowedPublic: [String]?): @Vault {
        return <- create Vault(allowedPublic)
    }

    pub fun getAddress(): Address {
        return self.account.address
    }

    init (_ allowedPublic: [String]?) {
        self.DefaultStoragePath = /storage/nftRealityCollectionVault
        self.DefaultPublicPath = /public/nftRealityCollectionVault
        self.DefaultPrivatePath = /private/nftRealityCollectionVault

        let vault <- create Vault(allowedPublic)
        self.account.save(<-vault, to: self.DefaultStoragePath)

        self.account.link<&{VaultPublic}>(self.DefaultPublicPath, target: self.DefaultStoragePath)
    }
}
