import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MoxyData from "./MoxyData.cdc"

access(all)
contract PlayToken: FungibleToken{ 
	
	/// Total supply of PlayTokens in existence
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
			// Returns the balance for the requested day or zero
			// if no records at that day.
			return self.dailyBalances.getValueOrMostRecentFor(timestamp: timestamp)
		}
		
		access(all)
		fun getBalanceFor(timestamp: UFix64): UFix64?{ 
			return self.dailyBalances.getValueFor(timestamp: timestamp)
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
			self.balance = self.balance - amount
			emit TokensWithdrawn(amount: amount, from: self.owner?.address)
			return <-create Vault(balance: amount)
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
			// PLAY Tokens can't be transferred
			panic("PLAY can't be deposited")
		}
		
		access(all)
		fun convertedFromMOXY(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @PlayToken.Vault
			self.dailyBalances.setAmountFor(timestamp: getCurrentBlock().timestamp, amount: vault.balance)
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
		fun mintTokens(amount: UFix64): @PlayToken.Vault{ 
			pre{ 
				amount > 0.0:
					"Amount minted must be greater than zero"
				amount <= self.allowedAmount:
					"Amount minted must be less than the allowed amount"
			}
			PlayToken.totalSupplies.setAmountFor(timestamp: getCurrentBlock().timestamp, amount: amount)
			PlayToken.totalSupply = PlayToken.totalSupply + amount
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
			let vault <- from as! @PlayToken.Vault
			let amount = vault.balance
			destroy vault
			emit TokensBurned(amount: amount)
		}
	}
	
	access(all)
	fun getTotalSupplyFor(timestamp: UFix64): UFix64{ 
		return self.totalSupplies.getValueOrMostRecentFor(timestamp: timestamp)
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
	}
	
	access(all)
	resource interface ReceiverInterface{ 
		access(all)
		fun convertedFromMOXY(from: @{FungibleToken.Vault})
	}
	
	access(all)
	let playTokenVaultStorage: StoragePath
	
	access(all)
	let playTokenAdminStorage: StoragePath
	
	access(all)
	let playTokenReceiverPath: PublicPath
	
	access(all)
	let playTokenReceiverInterfacePath: PublicPath
	
	access(all)
	let playTokenBalancePath: PublicPath
	
	access(all)
	let playTokenDailyBalancePath: PublicPath
	
	init(){ 
		// Initial total supply defined for PLAY token to starting strength
		// of Proof of Play
		self.totalSupply = 350000000.0
		self.totalSupplies <- MoxyData.createNewOrderedDictionary()
		self.totalSupplies.setAmountFor(timestamp: getCurrentBlock().timestamp, amount: self.totalSupply)
		self.playTokenVaultStorage = /storage/playTokenVault
		self.playTokenAdminStorage = /storage/playTokenAdmin
		self.playTokenReceiverPath = /public/playTokenReceiver
		self.playTokenReceiverInterfacePath = /public/playTokenReceiverInterface
		self.playTokenBalancePath = /public/playTokenBalance
		self.playTokenDailyBalancePath = /public/playTokenDailyBalancePath
		
		// Create the Vault with the total supply of tokens and save it in storage
		//
		let vault <- create Vault(balance: self.totalSupply)
		self.account.storage.save(<-vault, to: self.playTokenVaultStorage)
		
		// Create a public capability to the stored Vault that only exposes
		// the `deposit` method through the `Receiver` interface
		//
		var capability_1 = self.account.capabilities.storage.issue<&{FungibleToken.Receiver}>(self.playTokenVaultStorage)
		self.account.capabilities.publish(capability_1, at: self.playTokenReceiverPath)
		var capability_2 = self.account.capabilities.storage.issue<&{PlayToken.ReceiverInterface}>(self.playTokenVaultStorage)
		self.account.capabilities.publish(capability_2, at: self.playTokenReceiverInterfacePath)
		
		// Create a public capability to the stored Vault that only exposes
		// the `balance` field through the `Balance` interface
		//
		var capability_3 = self.account.capabilities.storage.issue<&PlayToken.Vault>(self.playTokenVaultStorage)
		self.account.capabilities.publish(capability_3, at: self.playTokenBalancePath)
		var capability_4 = self.account.capabilities.storage.issue<&PlayToken.Vault>(self.playTokenVaultStorage)
		self.account.capabilities.publish(capability_4, at: self.playTokenDailyBalancePath)
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.playTokenAdminStorage)
		
		// Emit an event that shows that the contract was initialized
		//
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
