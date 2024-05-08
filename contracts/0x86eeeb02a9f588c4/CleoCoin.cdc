/*  
    CLΣΘ CΘΙΝ 6/9/2023
*/

import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

access(all) contract CleoCoin: FungibleToken {

    access(all) event TokensInitialized(initialSupply: UFix64)
    access(all) event TokensWithdrawn(amount: UFix64, from: Address?)
    access(all) event TokensDeposited(amount: UFix64, to: Address?)
    access(all) event TokensBurned(amount: UFix64)
    access(all) event TokensMinted(amount: UFix64)
    access(all) event MinterCreated(allowedAmount: UFix64)

    pub let VaultStoragePath: StoragePath
    pub let VaultReceiverPath: PublicPath
    pub let VaultBalancePath: PublicPath

    access(all) let MAX_SUPPLY: UFix64
    access(all) let ALLOWED_AMOUNT_PER_MINTER: UFix64
    access(all) let MAX_MINTERS: UInt32

    access(all) var totalSupply: UFix64
    access(all) var totalMinters: UInt32

    access(all) resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {
        access(all) var balance: UFix64

        init(balance: UFix64) {
            self.balance = balance
        }

        access(all) fun withdraw(amount: UFix64): @FungibleToken.Vault {
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        access(all) fun deposit(from: @FungibleToken.Vault) {
            let vault <- from as! @CleoCoin.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }

        destroy() {
            CleoCoin.totalSupply = CleoCoin.totalSupply - self.balance
            emit TokensBurned(amount: self.balance)
        }

    }

    access(all) fun createEmptyVault(): @CleoCoin.Vault {
        return <-create Vault(balance: 0.0)
    }

    access(all) resource Minter {
        access(all) var allowedAmount: UFix64

        access(all) fun mintTokens(amount: UFix64): @CleoCoin.Vault {
            pre {
                amount > 0.0: "Amount minted must be greater than zero"
                amount <= self.allowedAmount: "Amount minted must be less than or equal to the allowed amount"
            }
            post {
                CleoCoin.totalSupply <= CleoCoin.MAX_SUPPLY: "Total supply must be less than or equal to the max supply"
            }
            self.allowedAmount = self.allowedAmount - amount
            CleoCoin.totalSupply = CleoCoin.totalSupply + amount
            emit TokensMinted(amount: amount)
            return <-create Vault(balance: amount)
        }

        init() {
            pre {
                CleoCoin.totalMinters <= CleoCoin.MAX_MINTERS: "Total minters must be less than or equal to the max minters"
            }
            self.allowedAmount = CleoCoin.ALLOWED_AMOUNT_PER_MINTER
            CleoCoin.totalMinters = CleoCoin.totalMinters + 1
            emit MinterCreated(allowedAmount: self.allowedAmount)
        }
    }

    access(account) fun createMinter(): @Minter {
        return <-create Minter()
    }

    init() {
        self.VaultStoragePath = /storage/CleoCoinVault
        self.VaultReceiverPath = /public/CleoCoinVaultReceiver
        self.VaultBalancePath = /public/CleoCoinVaultBalance

        self.MAX_SUPPLY = 69_000_000_000.0
        self.ALLOWED_AMOUNT_PER_MINTER = 690_000_000.0
        self.MAX_MINTERS = 100

        self.totalSupply = 0.0
        self.totalMinters = 0

        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}