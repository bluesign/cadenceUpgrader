/// Testnet
/// import FungibleToken from "../0x9a0766d93b6608b7/FungibleToken.cdc"

/// Mainnet
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"


pub contract TitToken: FungibleToken {

    pub var totalSupply: UFix64

    pub let VaultReceiverPath: PublicPath
    pub let VaultBalancePath: PublicPath
    pub let VaultStoragePath: StoragePath
    pub let AdminStoragePath: StoragePath

    pub event TokensInitialized(initialSupply: UFix64)
    pub event TokensWithdrawn(amount: UFix64, from: Address?)
    pub event TokensDeposited(amount: UFix64, to: Address?)
    pub event TokensMinted(amount: UFix64)
    pub event TokensBurned(amount: UFix64)
    pub event MinterCreated(allowedAmount: UFix64)
    pub event BurnerCreated()

    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {

        pub var balance: UFix64

        init(balance: UFix64) {
            self.balance = balance
        }

        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <- create Vault(balance: amount)
        }

        pub fun deposit(from: @FungibleToken.Vault) {
            let vault <- from as! @TitToken.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }

        destroy() {
            if(self.balance >= 0.0){
                emit TokensBurned(amount: self.balance)
            }
            TitToken.totalSupply = TitToken.totalSupply - self.balance
        }

    }

    pub fun createEmptyVault(): @Vault {
        return <- create Vault(balance: 0.0)
    }

    pub resource Minter {

        pub var allowedAmount: UFix64

        pub fun mintTokens(amount: UFix64): @TitToken.Vault {
            pre {
                amount > 0.0: "Amount minted must be greater than zero"
                amount <= self.allowedAmount: "Amount minted must be less than the allowed amount"
            }
            TitToken.totalSupply = TitToken.totalSupply + amount
            self.allowedAmount = self.allowedAmount - amount
            emit TokensMinted(amount: amount)
            return <- create Vault(balance: amount)
        }

        init(allowedAmount: UFix64) {
            self.allowedAmount = allowedAmount
        }

    }

    pub resource Burner {
        pub fun burnTokens(from: @FungibleToken.Vault) {
            let vault <- from as! @TitToken.Vault
            let amount = vault.balance
            destroy vault
            emit TokensBurned(amount: amount)
        }
    }

    pub resource Administrator {

        pub fun createNewMinter(allowedAmount: UFix64): @Minter {
            emit MinterCreated(allowedAmount: allowedAmount)
            return <- create Minter(allowedAmount: allowedAmount)
        }

        pub fun createNewBurner(): @Burner {
            emit BurnerCreated()
            return <- create Burner()
        }
    }

    init() {
        self.totalSupply = 444444444.0

        self.VaultReceiverPath = /public/TitTokenReceiver
        self.VaultBalancePath = /public/TitTokenBalance
        self.VaultStoragePath = /storage/TitTokenVault
        self.AdminStoragePath = /storage/TitTokenAdmin

        let vault <- create Vault(balance: self.totalSupply)
        self.account.save(<-vault, to: self.VaultStoragePath)
        self.account.link<&{FungibleToken.Receiver, FungibleToken.Balance}>(
            self.VaultReceiverPath,
            target: self.VaultStoragePath
        )

        self.account.link<&{FungibleToken.Balance}>(
            self.VaultBalancePath,
            target: self.VaultStoragePath
        )

        let admin <- create Administrator()
        self.account.save(<-admin, to: self.AdminStoragePath)

        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}

