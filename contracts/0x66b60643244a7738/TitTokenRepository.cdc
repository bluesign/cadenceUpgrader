// Testnet
// import FungibleToken from "../0x9a0766d93b6608b7/FungibleToken.cdc"
// import TitToken from "../0x6e9ac121d7106a09/TitToken.cdc"


// Mainnet
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import TitToken from 0x66b60643244a7738 // Replace with actual address

pub contract TitTokenRepository {

    pub event TresorCreated(tresorId: UInt64, seller: Address, price: UFix64, amount: UFix64)
    pub event TokensPurchased(tresorId: UInt64, buyer: Address, price: UFix64, amount: UFix64)
    pub event TresorRemoved(tresorId: UInt64, seller: Address)

    pub let RepositoryStoragePath: StoragePath
    pub let RepositoryPublicPath: PublicPath

    pub var nextTresorId: UInt64

    pub struct TresorDetails {
        pub let tresorId: UInt64
        pub let seller: Address
        pub let price: UFix64
        pub let amount: UFix64

        init (tresorId: UInt64, seller: Address, price: UFix64, amount: UFix64) {
            self.tresorId = tresorId
            self.seller = seller
            self.price = price
            self.amount = amount
        }
    }

    pub resource interface TresorPublic {

        pub fun transferAndRemoveTresor(buyerVaultRef: &{FungibleToken.Receiver}, repositoryRef: &TitTokenRepository.Repository{TitTokenRepository.RepositoryPublic})

//        pub fun purchaseTokens(tresorId: UInt64, buyer: AuthAccount, paymentVault: @FungibleToken.Vault)

        pub fun transferTokens(buyerVaultRef: &{FungibleToken.Receiver}) 

        pub fun getDetails(): TresorDetails
    }

    pub resource Tresor: TresorPublic {
        pub let details: TresorDetails
        pub let seller: Address
        pub let price: UFix64
        pub let amount: UFix64
        pub var tokenVault: @FungibleToken.Vault




        pub fun getDetails(): TresorDetails {
            return self.details
        }

        // This method allows the transfer of tokens to a buyer's vault
        pub fun transferTokens(buyerVaultRef: &{FungibleToken.Receiver}) {
            let amount = self.amount
            let tokens <- self.tokenVault.withdraw(amount: amount)
            buyerVaultRef.deposit(from: <- tokens)
        }

            // New function to handle the transfer and removal
        pub fun transferAndRemoveTresor(buyerVaultRef: &{FungibleToken.Receiver}, repositoryRef: &TitTokenRepository.Repository{TitTokenRepository.RepositoryPublic}) {
            // Transfer tokens
            let amount = self.amount
            let tokens <- self.tokenVault.withdraw(amount: amount)
            buyerVaultRef.deposit(from: <- tokens)

            // Remove the Tresor from the repository, triggering destruction
            repositoryRef.removeTresor(signer: self.getDetails().seller, tresorId: self.getDetails().tresorId)
        //    emit TokensPurchased(tresorId: self.getDetails().tresorId, buyer: buyer.address, price: tresor.price, amount: tresor.amount)
        
        }


        init(_seller: Address, _price: UFix64, _amount: UFix64, _vault: @FungibleToken.Vault, _tresorId: UInt64) {
            self.seller = _seller
            self.price = _price
            self.amount = _amount
            self.tokenVault <- _vault

            self.details = TresorDetails(
                tresorId: _tresorId,
                seller: _seller,
                price: _price,
                amount: _amount
            )
        }



        destroy() {
            destroy self.tokenVault
        }
    }

    pub resource interface RepositoryManager {
        pub fun purchaseTokens(tresorId: UInt64, buyer: AuthAccount, paymentVault: @FungibleToken.Vault)

        pub fun createTresor(signer: AuthAccount, price: UFix64, amount: UFix64): UInt64

        pub fun removeTresor(signer: Address, tresorId: UInt64) 
    }

    pub resource interface RepositoryPublic {
        pub fun removeTresor(signer: Address, tresorId: UInt64) 
        pub fun getTresorIDs(): [UInt64]
//        pub fun getTresorDetails(tresorId: UInt64): TresorDetails
        pub fun borrowTresor(tresorResourceID: UInt64): &Tresor{TresorPublic}?
    }

    pub resource Repository: RepositoryManager, RepositoryPublic {

        pub var tresors: @{UInt64: Tresor}

        //A resource with the form of Tresor is created in the createTResor function
        // and moved to the tresors dictionary with the current index
        // When the purchase tokens function is called the resource is moved from that index
        // and the tokens are deposited into the buyers TitTokenStorage

                // Function to purchase TitTokens

        pub fun purchaseTokens(tresorId: UInt64, buyer: AuthAccount, paymentVault: @FungibleToken.Vault) {
            let tresor <- self.tresors.remove(key: tresorId)
                ?? panic("Tresor does not exist.")

            let seller = getAccount(tresor.seller)

            // Ensure the paymentVault is a Flow token vault and deposit Flow tokens into the seller's vault
            let receiver = seller.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
                .borrow() ?? panic("Could not borrow receiver reference to the seller's Flow token vault")
            receiver.deposit(from: <- paymentVault)

            // Ensure the buyer has a TitToken receiver and transfer TitTokens from the tresor to the buyer
            let buyerReceiver = buyer.getCapability<&{FungibleToken.Receiver}>(TitToken.VaultReceiverPath)
                .borrow() ?? panic("Could not borrow receiver reference to the buyer's TitToken vault")
            tresor.transferTokens(buyerVaultRef: buyerReceiver)


            emit TokensPurchased(tresorId: tresorId, buyer: buyer.address, price: tresor.price, amount: tresor.amount)
            destroy tresor
        }

        // Function to list TitTokens for sale
        pub fun createTresor(signer: AuthAccount, price: UFix64, amount: UFix64): UInt64 {
            let vaultRef = signer.borrow<&TitToken.Vault{FungibleToken.Provider, FungibleToken.Balance}>(from: TitToken.VaultStoragePath)
                ?? panic("Could not borrow reference to the TitToken vault")

            let tokens <- vaultRef.withdraw(amount: amount)

            // Use the contract-level nextTresorId for uniqueness
            let tresorId = TitTokenRepository.nextTresorId
            TitTokenRepository.nextTresorId = TitTokenRepository.nextTresorId + 1

            let tresor <- create Tresor(_seller: signer.address, _price: price, _amount: amount, _vault: <- tokens, _tresorId: tresorId)
            self.tresors[tresorId] <-! tresor
            emit TresorCreated(tresorId: tresorId, seller: signer.address, price: price, amount: amount)

            return tresorId
        }



        // Function to remove a tresor
        pub fun removeTresor(signer: Address, tresorId: UInt64) {
            let tresor <- self.tresors.remove(key: tresorId)
                ?? panic("Tresor does not exist.")

            // assert(tresor.seller == signer.address, message: "Only the seller can remove the tresor")

            emit TresorRemoved(tresorId: tresorId, seller: signer)
            destroy tresor
        }

        // This function works for this contract, the problem with this contract
        // is that we can't use the purchase function, because even though the 
        // IDs exist, the Tresor resource for some reason can't find them???
        pub fun getTresorIDs(): [UInt64] {
            return self.tresors.keys
        }

        pub fun borrowTresor(tresorResourceID: UInt64): &Tresor{TresorPublic}? {

            if self.tresors[tresorResourceID] != nil {
                return(&self.tresors[tresorResourceID] as &Tresor{TresorPublic}?)
            } else {
                return nil
            }

        }


        // Destructor to clean up the tresors dictionary
        destroy() {
            destroy self.tresors
        }

        init() {
            self.tresors <- {}
        }

    }




//        // Function to get details of all tresors
//    pub fun getAllTresorDetails(): [TresorDetails] {
//        let detailsArray: [TresorDetails] = []
//        for tresor in self.tresors.values {
//            detailsArray.append(tresor.getDetails())
//        }
//        return detailsArray
//    }


    pub fun createRepository(): @Repository {
        return <- create Repository()
    }


    init() {
        self.RepositoryStoragePath = /storage/TitTokenRepository
        self.RepositoryPublicPath = /public/TitTokenRepository

        self.nextTresorId = 1
    }
}
