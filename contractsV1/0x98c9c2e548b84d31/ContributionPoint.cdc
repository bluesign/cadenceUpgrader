// import FungibleToken from "../"./FungibleToken.cdc"/FungibleToken.cdc"
// import Pausable from "../"./Pausable.cdc"/Pausable.cdc"
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import Pausable from "./Pausable.cdc"

access(all)
contract ContributionPoint: FungibleToken, Pausable{ 
	/// Total supply of ExampleTokens in existence
	access(all)
	var totalSupply: UFix64
	
	/// Storage and Public Paths
	access(all)
	let VaultStoragePath: StoragePath
	
	access(all)
	let ReceiverPublicPath: PublicPath
	
	access(all)
	let BalancePublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	/// If current contract is paused
	access(contract)
	var paused: Bool
	
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
	
	/// PauserCreated
	///
	/// The event that is emitted when a new pauser resource is created
	access(all)
	event PauserCreated()
	
	/// Paused
	///
	/// Emitted when the pause is triggered.
	access(all)
	event Paused()
	
	/// Unpaused
	///
	/// Emitted when the pause is lifted.
	access(all)
	event Unpaused()
	
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
	resource Vault: FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, Pausable.Checker{ 
		
		/// The total balance of this vault
		access(all)
		var balance: UFix64
		
		// initialize the balance at resource creation time
		init(balance: UFix64){ 
			self.balance = balance
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
			// only callable when not paused
			self.whenNotPaused()
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
			let vault <- from as! @ContributionPoint.Vault
			self.balance = self.balance + vault.balance
			emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
			vault.balance = 0.0
			destroy vault
		}
		
		/// Returns true if the contract is paused, and false otherwise.
		///
		access(all)
		fun paused(): Bool{ 
			return ContributionPoint.paused
		}
		
		/// a function callable only when the contract is not paused.
		/// 
		access(contract)
		fun whenNotPaused(){} 
		
		/// a function callable only when the contract is paused.
		/// 
		access(contract)
		fun whenPaused(){} 
		
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
		
		/// createNewPauser
		///
		/// Function that creates and returns a new pauser resource
		///
		access(all)
		fun createNewPauser(): @Pauser{ 
			emit PauserCreated()
			return <-create Pauser()
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
		fun mintTokens(amount: UFix64): @ContributionPoint.Vault{ 
			pre{ 
				amount > 0.0:
					"Amount minted must be greater than zero"
				amount <= self.allowedAmount:
					"Amount minted must be less than the allowed amount"
			}
			ContributionPoint.totalSupply = ContributionPoint.totalSupply + amount
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
			let vault <- from as! @ContributionPoint.Vault
			let amount = vault.balance
			destroy vault
			emit TokensBurned(amount: amount)
		}
	}
	
	/// Pauser
	///
	/// Resource object that token admin accounts can hold to pause tokens withdrawal.
	///
	access(all)
	resource Pauser: Pausable.Pauser{ 
		
		/// pause
		/// 
		access(all)
		fun pause(){ 
			pre{ 
				!ContributionPoint.paused:
					"Pausable: paused"
			}
			ContributionPoint.paused = true
			emit Paused()
		}
		
		/// unpause
		///
		access(all)
		fun unpause(){ 
			pre{ 
				ContributionPoint.paused:
					"Pausable: not paused"
			}
			ContributionPoint.paused = false
			emit Unpaused()
		}
	}
	
	init(){ 
		// Set named paths
		self.AdminStoragePath = /storage/ThingFundContributePointAdmin
		self.VaultStoragePath = /storage/ThingFundContributePointVault
		self.ReceiverPublicPath = /public/ThingFundContributePointReceiver
		self.BalancePublicPath = /public/ThingFundContributePointBalance
		
		// Set total supply
		self.totalSupply = 0.0
		
		// Set paused default
		self.paused = false
		
		// Create the Vault with the total supply of tokens and save it in storage
		//
		let vault <- create Vault(balance: self.totalSupply)
		self.account.storage.save(<-vault, to: self.VaultStoragePath)
		
		// Create a public capability to the stored Vault that only exposes
		// the `deposit` method through the `Receiver` interface
		//
		var capability_1 = self.account.capabilities.storage.issue<&{FungibleToken.Receiver}>(self.VaultStoragePath)
		self.account.capabilities.publish(capability_1, at: self.ReceiverPublicPath)
		
		// Create a public capability to the stored Vault that only exposes
		// the `balance` field through the `Balance` interface
		//
		var capability_2 = self.account.capabilities.storage.issue<&ContributionPoint.Vault>(self.VaultStoragePath)
		self.account.capabilities.publish(capability_2, at: self.BalancePublicPath)
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		
		// Emit an event that shows that the contract was initialized
		//
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
