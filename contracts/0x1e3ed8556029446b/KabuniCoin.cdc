pub contract KabuniCoin {

    pub var totalSupply: UFix64
    pub var name: String
    pub var symbol: String
    pub var decimals: UInt8

    pub resource interface Provider {
        pub fun withdraw(amount: UFix64): @KabuniCoin.Vault
    }

    pub resource interface Receiver {
        pub fun deposit(from: @KabuniCoin.Vault)
    }

    pub resource Vault: Provider, Receiver {
        pub var balance: UFix64

        init(balance: UFix64) {
            self.balance = balance
        }

        pub fun withdraw(amount: UFix64): @KabuniCoin.Vault {
            pre {
                self.balance >= amount: "Insufficient balance"
            }
            self.balance = self.balance - amount
            return <-create Vault(balance: amount)
        }

        pub fun deposit(from: @KabuniCoin.Vault) {
            self.balance = self.balance + from.balance
            destroy from
        }
    }

    init() {
        self.totalSupply = 1000000000.0
        self.name = "Kabuni Coin"
        self.symbol = "KBC"
        self.decimals = 18

        let vault <- create Vault(balance: self.totalSupply)
        self.account.save(<-vault, to: /storage/mainVault)
        self.account.link<&AnyResource{KabuniCoin.Provider}>(/public/provider, target: /storage/mainVault)
    }

    pub fun createEmptyVault(): @KabuniCoin.Vault {
        return <-create Vault(balance: 0.0)
    }

    pub fun mintTokens(to: Address, amount: UFix64) {
        pre {
            amount > 0.0: "Invalid amount"
        }

        let mainVaultRef = self.account.borrow<&KabuniCoin.Vault>(from: /storage/mainVault)
            ?? panic("Could not borrow main vault reference")

        let receiverRef = getAccount(to).getCapability<&AnyResource{KabuniCoin.Receiver}>(/public/receiver)!.borrow()
            ?? panic("Could not borrow receiver reference")

        let tokens <- mainVaultRef.withdraw(amount: amount)
        receiverRef.deposit(from: <-tokens)

        self.totalSupply = self.totalSupply + amount
    }
}
