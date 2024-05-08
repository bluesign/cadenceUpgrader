// BasicToken.cdc
//
// The BasicToken contract is a sample implementation of a fungible token on Flow.
//
// Fungible tokens behave like everyday currencies -- they can be minted, transferred or
// traded for digital goods.
//
// Follow the fungible tokens tutorial to learn more: https://developers.flow.com/cadence/tutorial/06-fungible-tokens
//
// This is a basic implementation of a Fungible Token and is NOT meant to be used in production
// See the Flow Fungible Token standard for real examples: https://github.com/onflow/flow-ft

pub contract BasicToken {

    // Vault
    //
    // Each user stores an instance of only the Vault in their storage
    // The functions in the Vault and governed by the pre and post conditions
    // in the interfaces when they are called.
    // The checks happen at runtime whenever a function is called.
    //
    // Resources can only be created in the context of the contract that they
    // are defined in, so there is no way for a malicious user to create Vaults
    // out of thin air. A special Minter resource or constructor function needs to be defined to mint
    // new tokens.
    //
    pub resource Vault {

		// keeps track of the total balance of the account's tokens
        pub var balance: UFix64

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
        }

        // withdraw
        //
        // Function that takes an integer amount as an argument
        // and withdraws that amount from the Vault.
        //
        // It creates a new temporary Vault that is used to hold
        // the money that is being transferred. It returns the newly
        // created Vault to the context that called so it can be deposited
        // elsewhere.
        //
        pub fun withdraw(amount: UFix64): @Vault {
            self.balance = self.balance - amount
            return <-create Vault(balance: amount)
        }

        // deposit
        //
        // Function that takes a Vault object as an argument and adds
        // its balance to the balance of the owners Vault.
        //
        // It is allowed to destroy the sent Vault because the Vault
        // was a temporary holder of the tokens. The Vault's balance has
        // been consumed and therefore can be destroyed.
        pub fun deposit(from: @Vault) {
            self.balance = self.balance + from.balance
            destroy from
        }
    }

    // createVault
    //
    // Function that creates a new Vault with an initial balance
    // and returns it to the calling context. A user must call this function
    // and store the returned Vault in their storage in order to allow their
    // account to be able to receive deposits of this token type.
    //
    pub fun createVault(): @Vault {
        return <-create Vault(balance: 30.0)
    }

    // The init function for the contract. All fields in the contract must
    // be initialized at deployment. This is just an example of what
    // an implementation could do in the init function. The numbers are arbitrary.
    init() {
        // create the Vault with the initial balance and put it in storage
        // account.save saves an object to the specified `to` path
        // The path is a literal path that consists of a domain and identifier
        // The domain must be `storage`, `private`, or `public`
        // the identifier can be any name
        let vault <- self.createVault()
        self.account.save(<-vault, to: /storage/CadenceFungibleTokenTutorialVault)
    }
}

