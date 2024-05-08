import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MoxyData from "./MoxyData.cdc"
 

pub contract MoxyVaultToken: FungibleToken {

    /// Total supply of MoxyVaultTokens in existence
    pub var totalSupply: UFix64
    access(contract) var totalSupplies: @MoxyData.OrderedDictionary
    pub var numberOfHolders: UInt

    /// TokensInitialized
    ///
    /// The event that is emitted when the contract is created
    pub event TokensInitialized(initialSupply: UFix64)

    /// TokensWithdrawn
    ///
    /// The event that is emitted when tokens are withdrawn from a Vault
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    /// TokensDeposited
    ///
    /// The event that is emitted when tokens are deposited to a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)

    /// TokensMinted
    ///
    /// The event that is emitted when new tokens are minted
    pub event TokensMinted(amount: UFix64)

    /// TokensBurned
    ///
    /// The event that is emitted when tokens are destroyed
    pub event TokensBurned(amount: UFix64)

    /// MinterCreated
    ///
    /// The event that is emitted when a new minter resource is created
    pub event MinterCreated(allowedAmount: UFix64)

    /// BurnerCreated
    ///
    /// The event that is emitted when a new burner resource is created
    pub event BurnerCreated()

    pub event MVToMOXYConverterCreated(conversionAmount: UFix64, timestamp: UFix64)

    /// Vault
    ///
    /// Each user stores an instance of only the Vault in their storage
    /// The functions in the Vault and governed by the pre and post conditions
    /// in FungibleToken when they are called.
    /// The checks happen at runtime whenever a function is called.
    ///
    /// Resources can only be created in the context of the contract that they
    /// are defined in, so there is no way for a malicious user to create Vaults
    /// out of thin air. A special Minter resource needs to be defined to mint
    /// new tokens.
    ///
    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, DailyBalancesInterface, ReceiverInterface {

        /// The total balance of this vault
        pub var balance: UFix64
        access(contract) var dailyBalances: @MoxyData.OrderedDictionary
        
        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
            self.dailyBalances <- MoxyData.createNewOrderedDictionary()
            if (balance > 0.0) {
                self.dailyBalances.setAmountFor(timestamp: getCurrentBlock().timestamp, amount: balance)
            }
        }

        pub fun getDailyBalanceFor(timestamp: UFix64): UFix64? {
            return self.dailyBalances.getValueOrMostRecentFor(timestamp: timestamp)
        }

        pub fun getDailyBalancesChangesUpTo(timestamp: UFix64): {UFix64:UFix64} {
            return self.dailyBalances.getValueChangesUpTo(timestamp: timestamp)
        }

        pub fun getDailyBalanceChange(timestamp: UFix64): Fix64 {
            return self.dailyBalances.getValueChange(timestamp: timestamp)
        }

        pub fun getLastTimestampAdded(): UFix64? {
            return self.dailyBalances.getLastKeyAdded()
        }

        pub fun getFirstTimestampAdded(): UFix64? {
            return self.dailyBalances.getFirstKeyAdded()
        }

        /// withdraw
        ///
        /// Function that takes an amount as an argument
        /// and withdraws that amount from the Vault.
        ///
        /// It creates a new temporary Vault that is used to hold
        /// the money that is being transferred. It returns the newly
        /// created Vault to the context that called so it can be deposited
        /// elsewhere.
        ///
        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            panic("MV token can't be withdrawn")
        }

        access(account) fun withdrawAmount(amount: UFix64): @FungibleToken.Vault {
            let vault <- self.vaultToConvert(amount: amount) 
            return <- vault
        }

        /// deposit
        ///
        /// Function that takes a Vault object as an argument and adds
        /// its balance to the balance of the owners Vault.
        ///
        /// It is allowed to destroy the sent Vault because the Vault
        /// was a temporary holder of the tokens. The Vault's balance has
        /// been consumed and therefore can be destroyed.
        ///

        pub fun deposit(from: @FungibleToken.Vault) {
            panic("MV tokens can't be directly deposited.")
        }

        // Deposit keeping original daily balances that cames from the vault
        access(account) fun depositAmount(from: @FungibleToken.Vault) {
            let vault <- from as! @MoxyVaultToken.Vault

            if (self.owner != nil && self.balance == 0.0 && vault.balance > 0.0) {
                MoxyVaultToken.numberOfHolders = MoxyVaultToken.numberOfHolders + 1
            }

            let dailyBalances = vault.dailyBalances.getDictionary()

            for time in dailyBalances.keys {
                self.dailyBalances.setAmountFor(timestamp: time, amount: dailyBalances[time]!)
            }

            self.balance = self.balance + vault.balance

            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            
            vault.dailyBalances.withdrawValueFromOldest(amount: vault.balance)
            vault.balance = 0.0

            destroy vault
        }


        access(account) fun depositDueConversion(from: @FungibleToken.Vault) {
            let timestamp = getCurrentBlock().timestamp
            return self.depositFor(from: <-from, timestamp: timestamp)
        }

        access(contract) fun depositFor(from: @FungibleToken.Vault, timestamp: UFix64) {
            let vault <- from as! @MoxyVaultToken.Vault

            if (self.owner != nil && self.balance == 0.0 && vault.balance > 0.0) {
                MoxyVaultToken.numberOfHolders = MoxyVaultToken.numberOfHolders + 1
            }

            self.dailyBalances.setAmountFor(timestamp: timestamp, amount: vault.balance)

            self.balance = self.balance + vault.balance

            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            
            vault.dailyBalances.withdrawValueFromOldest(amount: vault.balance)
            vault.balance = 0.0

            destroy vault
        }

        access(contract) fun depositWithAges(balance: UFix64, ages: {UFix64:UFix64}) {
            post {
                total == balance : "Cannot assigning ages, please check amounts."
            }

            if (self.owner != nil && self.balance == 0.0 && balance > 0.0) {
                MoxyVaultToken.numberOfHolders = MoxyVaultToken.numberOfHolders + 1
            }

            var total = 0.0
            for time in ages.keys {
                self.dailyBalances.setAmountFor(timestamp: time, amount: ages[time]!)
                total = total + ages[time]!
            }

            self.balance = self.balance + balance
        }

        pub fun createNewMVConverter(privateVaultRef: Capability<&MoxyVaultToken.Vault>, allowedAmount: UFix64): @MVConverter {
            return <- create MVConverter(privateVaultRef: privateVaultRef, allowedAmount: allowedAmount, address: self.owner!.address)
        }

        access(contract) fun vaultToConvert(amount: UFix64): @FungibleToken.Vault {
            // Withdraw can only be done when a conversion MV to MOX is requested
            // withdraw are done from oldest deposits to newer deposits
            let balanceBefore = self.balance

            let dict = self.dailyBalances.withdrawValueFromOldest(amount: amount)
            self.balance = self.balance - amount
            
            if (self.balance == 0.0 && balanceBefore > 0.0 && self.owner != nil) {
                MoxyVaultToken.numberOfHolders = MoxyVaultToken.numberOfHolders - 1
            }
            
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            let vault <- MoxyVaultToken.createEmptyVault()
            
            vault.depositWithAges(balance: amount, ages: dict)
        
            return <- vault
        }

        
        destroy() {
            destroy self.dailyBalances
            MoxyVaultToken.totalSupply = MoxyVaultToken.totalSupply - self.balance
        }
    }

    /// createEmptyVault
    ///
    /// Function that creates a new Vault with a balance of zero
    /// and returns it to the calling context. A user must call this function
    /// and store the returned Vault in their storage in order to allow their
    /// account to be able to receive deposits of this token type.
    ///
    pub fun createEmptyVault(): @Vault {
        return <-create Vault(balance: 0.0)
    }

    pub resource Administrator {

        /// createNewMinter
        ///
        /// Function that creates and returns a new minter resource
        ///
        access(account) fun createNewMinter(allowedAmount: UFix64): @Minter {
            emit MinterCreated(allowedAmount: allowedAmount)
            return <-create Minter(allowedAmount: allowedAmount)
        }

        /// createNewBurner
        ///
        /// Function that creates and returns a new burner resource
        ///
        access(account) fun createNewBurner(): @Burner {
            emit BurnerCreated()
            return <-create Burner()
        }
    }

    /// Minter
    ///
    /// Resource object that token admin accounts can hold to mint new tokens.
    ///
    pub resource Minter {

        /// The amount of tokens that the minter is allowed to mint
        pub var allowedAmount: UFix64

        /// mintTokens
        ///
        /// Function that mints new tokens, adds them to the total supply,
        /// and returns them to the calling context.
        ///
        pub fun mintTokens(amount: UFix64): @MoxyVaultToken.Vault {
            let timestamp = getCurrentBlock().timestamp
            return <-self.mintTokensFor(amount: amount, timestamp: timestamp)
        }

        pub fun mintTokensFor(amount: UFix64, timestamp: UFix64): @MoxyVaultToken.Vault {
            pre {
                amount > 0.0: "Amount minted must be greater than zero"
                amount <= self.allowedAmount: "Amount minted must be less than the allowed amount"
            }

            if (!MoxyVaultToken.totalSupplies.canUpdateTo(timestamp: timestamp)) {
                panic("Cannot mint MV token for events before the last registerd")
            } 

            MoxyVaultToken.totalSupplies.setAmountFor(timestamp: timestamp, amount: amount)

            MoxyVaultToken.totalSupply = MoxyVaultToken.totalSupply + amount

            self.allowedAmount = self.allowedAmount - amount

            emit TokensMinted(amount: amount)
            let vault <-create Vault(balance: amount)
            
            return <- vault
        }

        init(allowedAmount: UFix64) {
            self.allowedAmount = allowedAmount
        }
    }

    /// Burner
    ///
    /// Resource object that token admin accounts can hold to burn tokens.
    ///
    pub resource Burner {

        /// burnTokens
        ///
        /// Function that destroys a Vault instance, effectively burning the tokens.
        ///
        /// Note: the burned tokens are automatically subtracted from the
        /// total supply in the Vault destructor.
        ///
        pub fun burnTokens(from: @FungibleToken.Vault) {
            let vault <- from as! @MoxyVaultToken.Vault
            let amount = vault.balance
            destroy vault
            emit TokensBurned(amount: amount)
        }
    }

    pub resource MVConverter: Converter {
        pub var privateVaultRef: Capability<&MoxyVaultToken.Vault>
        pub var allowedAmount: UFix64
        pub var address: Address

        pub fun getDailyVault(amount: UFix64): @FungibleToken.Vault {
            pre {
                amount > 0.0: "Amount to burn must be greater than zero"
                amount <= self.allowedAmount: "Amount to burn must be equal or less than the allowed amount. Allowed amount: ".concat(self.allowedAmount.toString()).concat(" amount: ").concat(amount.toString())
            }
            self.allowedAmount = self.allowedAmount - amount
            let vault <- self.privateVaultRef.borrow()!.vaultToConvert(amount: amount) as! @MoxyVaultToken.Vault
            
            return <-vault
        }

        init(privateVaultRef: Capability<&MoxyVaultToken.Vault>, allowedAmount: UFix64, address: Address ) {
            self.privateVaultRef = privateVaultRef
            self.allowedAmount = allowedAmount
            self.address = address
        }
    }

    pub resource interface DailyBalancesInterface {
        pub fun getDailyBalanceFor(timestamp: UFix64): UFix64? 
        pub fun getDailyBalanceChange(timestamp: UFix64): Fix64
        pub fun getLastTimestampAdded(): UFix64?
        pub fun getFirstTimestampAdded(): UFix64?
        pub fun getDailyBalancesChangesUpTo(timestamp: UFix64): {UFix64:UFix64} 
    }

    pub resource interface ReceiverInterface {
        access(account) fun depositDueConversion(from: @FungibleToken.Vault)
        access(account) fun depositAmount(from: @FungibleToken.Vault)
    }

    pub resource interface Converter {
        pub fun getDailyVault(amount: UFix64): @FungibleToken.Vault
    }

    pub fun getLastTotalSupplyTimestampAdded(): UFix64? {
        return self.totalSupplies.getLastKeyAdded()
    }

    pub fun getTotalSupplyFor(timestamp: UFix64): UFix64 {
        return self.totalSupplies.getValueOrMostRecentFor(timestamp: timestamp)
    }

    pub fun getDailyChangeTo(timestamp: UFix64): Fix64 {
        return self.totalSupplies.getValueChange(timestamp: timestamp)
    }

    access(contract) fun destroyTotalSupply(orderedDictionary: @MoxyData.OrderedDictionary) {
        self.totalSupplies.destroyWith(orderedDictionary: <-orderedDictionary)
    }

    pub let moxyVaultTokenVaultStorage: StoragePath
    pub let moxyVaultTokenVaultPrivate: PrivatePath
    pub let moxyVaultTokenAdminStorage: StoragePath
    pub let moxyVaultTokenReceiverPath: PublicPath
    pub let moxyVaultTokenBalancePath: PublicPath
    pub let moxyVaultTokenDailyBalancePath: PublicPath
    pub let moxyVaultTokenReceiverTimestampPath: PublicPath
    // Paths for Locked tonkens 
    pub let moxyVaultTokenLockedVaultStorage: StoragePath
    pub let moxyVaultTokenLockedVaultPrivate: PrivatePath
    pub let moxyVaultTokenLockedBalancePath: PublicPath
    pub let moxyVaultTokenLockedReceiverPath: PublicPath

    init() {
        self.totalSupply = 0.0
        self.totalSupplies <- MoxyData.createNewOrderedDictionary()
        self.numberOfHolders = 0

        self.moxyVaultTokenVaultStorage = /storage/moxyVaultTokenVault
        self.moxyVaultTokenVaultPrivate = /private/moxyVaultTokenVault
        self.moxyVaultTokenAdminStorage = /storage/moxyVaultTokenAdmin
        self.moxyVaultTokenReceiverPath = /public/moxyVaultTokenReceiver
        self.moxyVaultTokenBalancePath = /public/moxyVaultTokenBalance
        self.moxyVaultTokenDailyBalancePath = /public/moxyVaultTokenDailyBalance
        self.moxyVaultTokenReceiverTimestampPath = /public/moxyVaultTokenReceiverTimestamp
        // Locked vaults
        self.moxyVaultTokenLockedVaultStorage = /storage/moxyVaultTokenLockedVault
        self.moxyVaultTokenLockedVaultPrivate = /private/moxyVaultTokenLockedVault
        self.moxyVaultTokenLockedBalancePath = /public/moxyVaultTokenLockedBalance
        self.moxyVaultTokenLockedReceiverPath = /public/moxyVaultTokenLockedReceiver

        // Create the Vault with the total supply of tokens and save it in storage
        //
        let vault <- create Vault(balance: self.totalSupply)
        self.account.save(<-vault, to: self.moxyVaultTokenVaultStorage)

        // Private access to MoxyVault token Vault
        self.account.link<&MoxyVaultToken.Vault>(
            self.moxyVaultTokenVaultPrivate,
            target: self.moxyVaultTokenVaultStorage
        )

        // Create a public capability to the stored Vault that only exposes
        // the `deposit` method through the `Receiver` interface
        //
        self.account.link<&{FungibleToken.Receiver}>(
            self.moxyVaultTokenReceiverPath,
            target: self.moxyVaultTokenVaultStorage
        )
        // Link to receive tokens in a specific timestamp
        self.account.link<&{MoxyVaultToken.ReceiverInterface}>(
            self.moxyVaultTokenReceiverTimestampPath,
            target: self.moxyVaultTokenVaultStorage
        )

        // Create a public capability to the stored Vault that only exposes
        // the `balance` field through the `Balance` interface
        //
        self.account.link<&MoxyVaultToken.Vault{FungibleToken.Balance}>(
            self.moxyVaultTokenBalancePath,
            target: self.moxyVaultTokenVaultStorage
        )
        self.account.link<&MoxyVaultToken.Vault{DailyBalancesInterface}>(
            self.moxyVaultTokenDailyBalancePath,
            target: self.moxyVaultTokenVaultStorage
        )

        let admin <- create Administrator()
        self.account.save(<-admin, to: self.moxyVaultTokenAdminStorage)

        // Emit an event that shows that the contract was initialized
        //
        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}
 
