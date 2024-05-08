import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MoxyData from "./MoxyData.cdc"

access(all)
contract MoxyVaultToken: FungibleToken{ 
	
	/// Total supply of MoxyVaultTokens in existence
	access(all)
	var totalSupply: UFix64
	
	access(contract)
	var totalSupplies: @MoxyData.OrderedDictionary
	
	access(all)
	var numberOfHolders: UInt
	
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
	
	access(all)
	event MVToMOXYConverterCreated(conversionAmount: UFix64, timestamp: UFix64)
	
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
			if balance > 0.0{ 
				self.dailyBalances.setAmountFor(timestamp: getCurrentBlock().timestamp, amount: balance)
			}
		}
		
		access(all)
		fun getDailyBalanceFor(timestamp: UFix64): UFix64?{ 
			return self.dailyBalances.getValueOrMostRecentFor(timestamp: timestamp)
		}
		
		access(all)
		fun getDailyBalancesChangesUpTo(timestamp: UFix64):{ UFix64: UFix64}{ 
			return self.dailyBalances.getValueChangesUpTo(timestamp: timestamp)
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
			panic("MV token can't be withdrawn")
		}
		
		access(account)
		fun withdrawAmount(amount: UFix64): @{FungibleToken.Vault}{ 
			let vault <- self.vaultToConvert(amount: amount)
			return <-vault
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
			panic("MV tokens can't be directly deposited.")
		}
		
		// Deposit keeping original daily balances that cames from the vault
		access(account)
		fun depositAmount(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @MoxyVaultToken.Vault
			if self.owner != nil && self.balance == 0.0 && vault.balance > 0.0{ 
				MoxyVaultToken.numberOfHolders = MoxyVaultToken.numberOfHolders + 1
			}
			let dailyBalances = vault.dailyBalances.getDictionary()
			for time in dailyBalances.keys{ 
				self.dailyBalances.setAmountFor(timestamp: time, amount: dailyBalances[time]!)
			}
			self.balance = self.balance + vault.balance
			emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
			vault.dailyBalances.withdrawValueFromOldest(amount: vault.balance)
			vault.balance = 0.0
			destroy vault
		}
		
		access(account)
		fun depositDueConversion(from: @{FungibleToken.Vault}){ 
			let timestamp = getCurrentBlock().timestamp
			return self.depositFor(from: <-from, timestamp: timestamp)
		}
		
		access(contract)
		fun depositFor(from: @{FungibleToken.Vault}, timestamp: UFix64){ 
			let vault <- from as! @MoxyVaultToken.Vault
			if self.owner != nil && self.balance == 0.0 && vault.balance > 0.0{ 
				MoxyVaultToken.numberOfHolders = MoxyVaultToken.numberOfHolders + 1
			}
			self.dailyBalances.setAmountFor(timestamp: timestamp, amount: vault.balance)
			self.balance = self.balance + vault.balance
			emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
			vault.dailyBalances.withdrawValueFromOldest(amount: vault.balance)
			vault.balance = 0.0
			destroy vault
		}
		
		access(contract)
		fun depositWithAges(balance: UFix64, ages:{ UFix64: UFix64}){ 
			post{ 
				total == balance:
					"Cannot assigning ages, please check amounts."
			}
			if self.owner != nil && self.balance == 0.0 && balance > 0.0{ 
				MoxyVaultToken.numberOfHolders = MoxyVaultToken.numberOfHolders + 1
			}
			var total = 0.0
			for time in ages.keys{ 
				self.dailyBalances.setAmountFor(timestamp: time, amount: ages[time]!)
				total = total + ages[time]!
			}
			self.balance = self.balance + balance
		}
		
		access(all)
		fun createNewMVConverter(privateVaultRef: Capability<&MoxyVaultToken.Vault>, allowedAmount: UFix64): @MVConverter{ 
			return <-create MVConverter(privateVaultRef: privateVaultRef, allowedAmount: allowedAmount, address: (self.owner!).address)
		}
		
		access(contract)
		fun vaultToConvert(amount: UFix64): @{FungibleToken.Vault}{ 
			// Withdraw can only be done when a conversion MV to MOX is requested
			// withdraw are done from oldest deposits to newer deposits
			let balanceBefore = self.balance
			let dict = self.dailyBalances.withdrawValueFromOldest(amount: amount)
			self.balance = self.balance - amount
			if self.balance == 0.0 && balanceBefore > 0.0 && self.owner != nil{ 
				MoxyVaultToken.numberOfHolders = MoxyVaultToken.numberOfHolders - 1
			}
			emit TokensWithdrawn(amount: amount, from: self.owner?.address)
			let vault <- MoxyVaultToken.createEmptyVault(vaultType: Type<@MoxyVaultToken.Vault>())
			vault.depositWithAges(balance: amount, ages: dict)
			return <-vault
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
		access(account)
		fun createNewMinter(allowedAmount: UFix64): @Minter{ 
			emit MinterCreated(allowedAmount: allowedAmount)
			return <-create Minter(allowedAmount: allowedAmount)
		}
		
		/// createNewBurner
		///
		/// Function that creates and returns a new burner resource
		///
		access(account)
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
		fun mintTokens(amount: UFix64): @MoxyVaultToken.Vault{ 
			let timestamp = getCurrentBlock().timestamp
			return <-self.mintTokensFor(amount: amount, timestamp: timestamp)
		}
		
		access(all)
		fun mintTokensFor(amount: UFix64, timestamp: UFix64): @MoxyVaultToken.Vault{ 
			pre{ 
				amount > 0.0:
					"Amount minted must be greater than zero"
				amount <= self.allowedAmount:
					"Amount minted must be less than the allowed amount"
			}
			if !MoxyVaultToken.totalSupplies.canUpdateTo(timestamp: timestamp){ 
				panic("Cannot mint MV token for events before the last registerd")
			}
			MoxyVaultToken.totalSupplies.setAmountFor(timestamp: timestamp, amount: amount)
			MoxyVaultToken.totalSupply = MoxyVaultToken.totalSupply + amount
			self.allowedAmount = self.allowedAmount - amount
			emit TokensMinted(amount: amount)
			let vault <- create Vault(balance: amount)
			return <-vault
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
			let vault <- from as! @MoxyVaultToken.Vault
			let amount = vault.balance
			destroy vault
			emit TokensBurned(amount: amount)
		}
	}
	
	access(all)
	resource MVConverter: Converter{ 
		access(all)
		var privateVaultRef: Capability<&MoxyVaultToken.Vault>
		
		access(all)
		var allowedAmount: UFix64
		
		access(all)
		var address: Address
		
		access(all)
		fun getDailyVault(amount: UFix64): @{FungibleToken.Vault}{ 
			pre{ 
				amount > 0.0:
					"Amount to burn must be greater than zero"
				amount <= self.allowedAmount:
					"Amount to burn must be equal or less than the allowed amount. Allowed amount: ".concat(self.allowedAmount.toString()).concat(" amount: ").concat(amount.toString())
			}
			self.allowedAmount = self.allowedAmount - amount
			let vault <- (self.privateVaultRef.borrow()!).vaultToConvert(amount: amount) as! @MoxyVaultToken.Vault
			return <-vault
		}
		
		init(privateVaultRef: Capability<&MoxyVaultToken.Vault>, allowedAmount: UFix64, address: Address){ 
			self.privateVaultRef = privateVaultRef
			self.allowedAmount = allowedAmount
			self.address = address
		}
	}
	
	access(all)
	resource interface DailyBalancesInterface{ 
		access(all)
		fun getDailyBalanceFor(timestamp: UFix64): UFix64?
		
		access(all)
		fun getDailyBalanceChange(timestamp: UFix64): Fix64
		
		access(all)
		fun getLastTimestampAdded(): UFix64?
		
		access(all)
		fun getFirstTimestampAdded(): UFix64?
		
		access(all)
		fun getDailyBalancesChangesUpTo(timestamp: UFix64):{ UFix64: UFix64}
	}
	
	access(all)
	resource interface ReceiverInterface{ 
		access(account)
		fun depositDueConversion(from: @{FungibleToken.Vault})
		
		access(account)
		fun depositAmount(from: @{FungibleToken.Vault})
	}
	
	access(all)
	resource interface Converter{ 
		access(all)
		fun getDailyVault(amount: UFix64): @{FungibleToken.Vault}
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
	let moxyVaultTokenVaultStorage: StoragePath
	
	access(all)
	let moxyVaultTokenVaultPrivate: PrivatePath
	
	access(all)
	let moxyVaultTokenAdminStorage: StoragePath
	
	access(all)
	let moxyVaultTokenReceiverPath: PublicPath
	
	access(all)
	let moxyVaultTokenBalancePath: PublicPath
	
	access(all)
	let moxyVaultTokenDailyBalancePath: PublicPath
	
	access(all)
	let moxyVaultTokenReceiverTimestampPath: PublicPath
	
	// Paths for Locked tonkens 
	access(all)
	let moxyVaultTokenLockedVaultStorage: StoragePath
	
	access(all)
	let moxyVaultTokenLockedVaultPrivate: PrivatePath
	
	access(all)
	let moxyVaultTokenLockedBalancePath: PublicPath
	
	access(all)
	let moxyVaultTokenLockedReceiverPath: PublicPath
	
	init(){ 
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
		self.account.storage.save(<-vault, to: self.moxyVaultTokenVaultStorage)
		
		// Private access to MoxyVault token Vault
		var capability_1 = self.account.capabilities.storage.issue<&MoxyVaultToken.Vault>(self.moxyVaultTokenVaultStorage)
		self.account.capabilities.publish(capability_1, at: self.moxyVaultTokenVaultPrivate)
		
		// Create a public capability to the stored Vault that only exposes
		// the `deposit` method through the `Receiver` interface
		//
		var capability_2 = self.account.capabilities.storage.issue<&{FungibleToken.Receiver}>(self.moxyVaultTokenVaultStorage)
		self.account.capabilities.publish(capability_2, at: self.moxyVaultTokenReceiverPath)
		
		// Link to receive tokens in a specific timestamp
		var capability_3 = self.account.capabilities.storage.issue<&{MoxyVaultToken.ReceiverInterface}>(self.moxyVaultTokenVaultStorage)
		self.account.capabilities.publish(capability_3, at: self.moxyVaultTokenReceiverTimestampPath)
		
		// Create a public capability to the stored Vault that only exposes
		// the `balance` field through the `Balance` interface
		//
		var capability_4 = self.account.capabilities.storage.issue<&MoxyVaultToken.Vault>(self.moxyVaultTokenVaultStorage)
		self.account.capabilities.publish(capability_4, at: self.moxyVaultTokenBalancePath)
		var capability_5 = self.account.capabilities.storage.issue<&MoxyVaultToken.Vault>(self.moxyVaultTokenVaultStorage)
		self.account.capabilities.publish(capability_5, at: self.moxyVaultTokenDailyBalancePath)
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.moxyVaultTokenAdminStorage)
		
		// Emit an event that shows that the contract was initialized
		//
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
