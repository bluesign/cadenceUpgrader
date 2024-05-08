import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MoxyData from "./MoxyData.cdc"

access(all)
contract ScoreToken: FungibleToken{ 
	
	/// Total supply of ScoreTokens in existence
	access(all)
	var totalSupply: UFix64
	
	access(contract)
	var totalSupplies: @MoxyData.OrderedDictionary
	
	/// TokensInitialized
	///
	/// The event that is emitted when the contract is created
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	/// TokensWithdrawn
	///
	/// The event that is emitted when tokens are withdrawn from a Vault
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	/// TokensDeposited
	///
	/// The event that is emitted when tokens are deposited to a Vault
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	/// TokensMinted
	///
	/// The event that is emitted when new tokens are minted
	access(all)
	event TokensMinted(amount: UFix64)
	
	/// TokensBurned
	///
	/// The event that is emitted when tokens are destroyed
	access(all)
	event TokensBurned(amount: UFix64)
	
	/// MinterCreated
	///
	/// The event that is emitted when a new minter resource is created
	access(all)
	event MinterCreated(allowedAmount: UFix64)
	
	/// BurnerCreated
	///
	/// The event that is emitted when a new burner resource is created
	access(all)
	event BurnerCreated()
	
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
	access(all)
	resource Vault: FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, DailyBalancesInterface, ReceiverInterface{ 
		
		/// The total balance of this vault
		access(all)
		var balance: UFix64
		
		access(contract)
		var dailyBalances: @MoxyData.OrderedDictionary
		
		// initialize the balance at resource creation time
		init(balance: UFix64){ 
			self.balance = balance
			self.dailyBalances <- MoxyData.createNewOrderedDictionary()
		}
		
		access(all)
		fun getDailyBalanceFor(timestamp: UFix64): UFix64?{ 
			return self.dailyBalances.getValueOrMostRecentFor(timestamp: timestamp)
		}
		
		access(all)
		fun getBalanceFor(timestamp: UFix64): UFix64?{ 
			return self.dailyBalances.getValueFor(timestamp: timestamp)
		}
		
		access(all)
		fun getDailyBalanceChangeForToday(): Fix64{ 
			return self.dailyBalances.getValueChangeForToday()
		}
		
		access(all)
		fun getDailyBalanceChange(timestamp: UFix64): Fix64{ 
			return self.dailyBalances.getValueChange(timestamp: timestamp)
		}
		
		access(all)
		fun getLastTimestampAdded(): UFix64?{ 
			return self.dailyBalances.getLastKeyAdded()
		}
		
		access(all)
		fun getFirstTimestampAdded(): UFix64?{ 
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
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			// Withdraw not allowed for SCORE token
			panic("SCORE can't be withdrawn")
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
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			panic("SCORE can't be deposited")
		}
		
		access(contract)
		fun earnScore(from: @{FungibleToken.Vault}){ 
			let timestamp = getCurrentBlock().timestamp
			return self.depositFor(from: <-from, timestamp: timestamp)
		}
		
		access(contract)
		fun depositFor(from: @{FungibleToken.Vault}, timestamp: UFix64){ 
			let vault <- from as! @ScoreToken.Vault
			self.dailyBalances.setAmountFor(timestamp: timestamp, amount: vault.balance)
			self.balance = self.balance + vault.balance
			emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
			vault.balance = 0.0
			destroy vault
		}
		
		access(all)
		fun createEmptyVault(): @{FungibleToken.Vault}{ 
			return <-create Vault(balance: 0.0)
		}
		
		access(all)
		view fun isAvailableToWithdraw(amount: UFix64): Bool{ 
			return self.balance >= amount
		}
	}
	
	/// createEmptyVault
	///
	/// Function that creates a new Vault with a balance of zero
	/// and returns it to the calling context. A user must call this function
	/// and store the returned Vault in their storage in order to allow their
	/// account to be able to receive deposits of this token type.
	///
	access(all)
	fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault}{ 
		return <-create Vault(balance: 0.0)
	}
	
	access(all)
	resource Administrator{ 
		
		/// createNewMinter
		///
		/// Function that creates and returns a new minter resource
		///
		access(all)
		fun createNewMinter(allowedAmount: UFix64): @Minter{ 
			emit MinterCreated(allowedAmount: allowedAmount)
			return <-create Minter(allowedAmount: allowedAmount)
		}
		
		/// createNewBurner
		///
		/// Function that creates and returns a new burner resource
		///
		access(all)
		fun createNewBurner(): @Burner{ 
			emit BurnerCreated()
			return <-create Burner()
		}
	}
	
	/// Minter
	///
	/// Resource object that token admin accounts can hold to mint new tokens.
	///
	access(all)
	resource Minter{ 
		
		/// The amount of tokens that the minter is allowed to mint
		access(all)
		var allowedAmount: UFix64
		
		/// mintTokens
		///
		/// Function that mints new tokens, adds them to the total supply,
		/// and returns them to the calling context.
		///
		access(all)
		fun mintTokensTo(amount: UFix64, address: Address){ 
			let tokenReceiver = getAccount(address).capabilities.get<&{ScoreToken.ReceiverInterface}>(ScoreToken.scoreTokenReceiverTimestampPath).borrow<&{ScoreToken.ReceiverInterface}>() ?? panic("Unable to borrow receiver reference")
			let mintedVault <- self.mintTokensFor(amount: amount, timestamp: getCurrentBlock().timestamp)
			tokenReceiver.earnScore(from: <-mintedVault)
		}
		
		access(account)
		fun mintTokensFor(amount: UFix64, timestamp: UFix64): @ScoreToken.Vault{ 
			pre{ 
				amount > 0.0:
					"Amount minted must be greater than zero"
				amount <= self.allowedAmount:
					"Amount minted must be less than the allowed amount"
			}
			if !ScoreToken.totalSupplies.canUpdateTo(timestamp: timestamp){ 
				panic("Cannot mint SCORE token for events before the last registerd")
			}
			ScoreToken.totalSupplies.setAmountFor(timestamp: timestamp, amount: amount)
			ScoreToken.totalSupply = ScoreToken.totalSupply + amount
			self.allowedAmount = self.allowedAmount - amount
			emit TokensMinted(amount: amount)
			return <-create Vault(balance: amount)
		}
		
		init(allowedAmount: UFix64){ 
			self.allowedAmount = allowedAmount
		}
	}
	
	/// Burner
	///
	/// Resource object that token admin accounts can hold to burn tokens.
	///
	access(all)
	resource Burner{ 
		
		/// burnTokens
		///
		/// Function that destroys a Vault instance, effectively burning the tokens.
		///
		/// Note: the burned tokens are automatically subtracted from the
		/// total supply in the Vault destructor.
		///
		access(all)
		fun burnTokens(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @ScoreToken.Vault
			let amount = vault.balance
			destroy vault
			emit TokensBurned(amount: amount)
		}
	}
	
	access(all)
	fun getLastTotalSupplyTimestampAdded(): UFix64?{ 
		return self.totalSupplies.getLastKeyAdded()
	}
	
	access(all)
	fun getTotalSupplyFor(timestamp: UFix64): UFix64{ 
		return self.totalSupplies.getValueOrMostRecentFor(timestamp: timestamp)
	}
	
	access(all)
	fun getDailyChangeTo(timestamp: UFix64): Fix64{ 
		return self.totalSupplies.getValueChange(timestamp: timestamp)
	}
	
	access(contract)
	fun destroyTotalSupply(orderedDictionary: @MoxyData.OrderedDictionary){ 
		self.totalSupplies.destroyWith(orderedDictionary: <-orderedDictionary)
	}
	
	access(all)
	resource interface DailyBalancesInterface{ 
		access(all)
		fun getDailyBalanceFor(timestamp: UFix64): UFix64?
		
		access(all)
		fun getBalanceFor(timestamp: UFix64): UFix64?
		
		access(all)
		fun getDailyBalanceChange(timestamp: UFix64): Fix64
		
		access(all)
		fun getDailyBalanceChangeForToday(): Fix64
		
		access(all)
		fun getLastTimestampAdded(): UFix64?
		
		access(all)
		fun getFirstTimestampAdded(): UFix64?
	}
	
	access(all)
	resource interface ReceiverInterface{ 
		access(contract)
		fun earnScore(from: @{FungibleToken.Vault})
	}
	
	access(all)
	let scoreTokenVaultStorage: StoragePath
	
	access(all)
	let scoreTokenAdminStorage: StoragePath
	
	access(all)
	let scoreTokenReceiverPath: PublicPath
	
	access(all)
	let scoreTokenBalancePath: PublicPath
	
	access(all)
	let scoreTokenDailyBalancePath: PublicPath
	
	access(all)
	let scoreTokenReceiverTimestampPath: PublicPath
	
	init(){ 
		self.totalSupply = 0.0
		self.totalSupplies <- MoxyData.createNewOrderedDictionary()
		self.scoreTokenVaultStorage = /storage/scoreTokenVault
		self.scoreTokenAdminStorage = /storage/scoreTokenAdmin
		self.scoreTokenReceiverPath = /public/scoreTokenReceiver
		self.scoreTokenBalancePath = /public/scoreTokenBalance
		self.scoreTokenDailyBalancePath = /public/scoreTokenDailyBalance
		self.scoreTokenReceiverTimestampPath = /public/scoreTokenReceiverTimestamp
		
		// Create the Vault with the total supply of tokens and save it in storage
		//
		let vault <- create Vault(balance: self.totalSupply)
		self.account.storage.save(<-vault, to: self.scoreTokenVaultStorage)
		
		// Create a public capability to the stored Vault that only exposes
		// the `deposit` method through the `Receiver` interface
		//
		var capability_1 = self.account.capabilities.storage.issue<&{FungibleToken.Receiver}>(self.scoreTokenVaultStorage)
		self.account.capabilities.publish(capability_1, at: self.scoreTokenReceiverPath)
		
		// Link to receive tokens in a specific timestamp
		var capability_2 = self.account.capabilities.storage.issue<&{ScoreToken.ReceiverInterface}>(self.scoreTokenVaultStorage)
		self.account.capabilities.publish(capability_2, at: self.scoreTokenReceiverTimestampPath)
		
		// Create a public capability to the stored Vault that only exposes
		// the `balance` field through the `Balance` interface
		//
		var capability_3 = self.account.capabilities.storage.issue<&ScoreToken.Vault>(self.scoreTokenVaultStorage)
		self.account.capabilities.publish(capability_3, at: self.scoreTokenBalancePath)
		var capability_4 = self.account.capabilities.storage.issue<&ScoreToken.Vault>(self.scoreTokenVaultStorage)
		self.account.capabilities.publish(capability_4, at: self.scoreTokenDailyBalancePath)
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.scoreTokenAdminStorage)
		
		// Emit an event that shows that the contract was initialized
		//
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
