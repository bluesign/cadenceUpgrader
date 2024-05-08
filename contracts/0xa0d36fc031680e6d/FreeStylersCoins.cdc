pub contract FreeStylersCoins {
    priv var totalSupply: UFix64
    pub var name: String
    pub var symbol: String

    pub resource Token {
        pub let value: UFix64

        init(value: UFix64) {
            self.value = value
        }
    }

    pub fun createInitialTokens(amount: UFix64): @Token {
        let newToken <- create Token(value: amount)
        self.totalSupply = self.totalSupply + amount
        return <- newToken
    }

    init() {
        self.totalSupply = 0.0
        self.name = "FreeStylers Coin"
        self.symbol = "FSC"

        // Creating initial tokens
        self.totalSupply = 50000000.0
        // Consider decimal places for the token if necessary
    }
}