import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FungibleTokenMetadataViews from "./FungibleTokenMetadataViews.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import ViewResolver from "./ViewResolver.cdc"
import FlowToken from 0x1654653399040a61 

pub contract Lama: ViewResolver {
    pub let LamaStoragePath: StoragePath
    pub let LamaPrivatePath: PrivatePath

    pub event Allowed(path: PrivatePath, limit: UFix64)
    pub event Collected(path: PrivatePath, limit: UFix64, receiver: Address)

    // private functions only accessed by Account Parent
    pub resource interface ParentAccess {
        pub fun collect(path: PrivatePath, receiverPath: PublicPath, receiver: Address)
    }
    
    // private functions only accessed by Account Child
    pub resource interface ChildAccess {
        pub fun setAllowance(path: PrivatePath, allowance: UFix64, provider: Capability<&AnyResource{FungibleToken.Provider, FungibleToken.Balance}>)
    }

    pub resource Allowance: ParentAccess, ChildAccess {
        access(self) var allowances: {PrivatePath: UFix64} 
        access(self) var collected: {PrivatePath: UFix64}
        access(self) var capabilities: {PrivatePath : Capability<&AnyResource{FungibleToken.Provider, FungibleToken.Balance}>}
 
        init () {
            self.allowances = {}
            self.collected = {}
            self.capabilities = {}
        }

        pub fun getAllowance(path: PrivatePath): UFix64 {
            return self.allowances[path] ?? 0.0
        }

        pub fun getCollected(path: PrivatePath): UFix64 {
            return self.collected[path] ?? 0.0
        }

        pub fun collect(path: PrivatePath, receiverPath: PublicPath, receiver: Address) {
            let childProvider: Capability<&AnyResource{FungibleToken.Provider, FungibleToken.Balance}> = self.capabilities[path]
                ?? panic("FungibleToken.Provider capability not found for provider path")

            let childVault: &AnyResource{FungibleToken.Provider, FungibleToken.Balance} = childProvider.borrow()
                ?? panic("Could not borrow FungibleToken.Provider")

            let parentVault: &AnyResource{FungibleToken.Receiver} = getAccount(receiver).getCapability<&AnyResource{FungibleToken.Receiver}>(receiverPath).borrow()
                ?? panic("Problem getting parent receiver for this public path")                        

            var collectable: UFix64 = self.getAllowance(path: path) 

            if (collectable == 0.0 || childVault.balance == 0.0) {
                panic("No more tokens to be collected")
            }

            if (collectable >= childVault.balance) {
                collectable = childVault.balance
                // leave 0.001 for account storage in case of flow token
                let isTokenFlow: Bool = path == /private/flowTokenVault 
                let storageAmount: UFix64 = 0.001 // TDB by user

                if isTokenFlow && childVault.balance >= storageAmount {
                    collectable = childVault.balance - storageAmount
                }
            }

            parentVault.deposit(from: <-childVault.withdraw(amount: collectable))

            self._setAllowance(
                path: path, 
                allowance: self.getAllowance(path: path) - collectable
            )

            self.collected.insert(
                key: path, collectable + self.getCollected(path: path)
            )            
            
            emit Lama.Collected(path: path, amount: collectable, receiver: receiver)
        }

        pub fun setAllowance(path: PrivatePath, allowance: UFix64, provider: Capability<&AnyResource{FungibleToken.Provider, FungibleToken.Balance}>) {
            self.capabilities.insert(key: path, provider)
            self._setAllowance(path: path, allowance: allowance)            
        }

        access(self) fun _setAllowance(path: PrivatePath, allowance: UFix64) {
            self.allowances.insert(key: path, allowance)
            emit Lama.Allowed(path: path, allowance: allowance)
        }
    }

    pub fun createAllowance(): @Lama.Allowance {
        return <- create Allowance()
    }

    init() {
        self.LamaStoragePath = /storage/lama
        self.LamaPrivatePath = /private/lama
    }
}