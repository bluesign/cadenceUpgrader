access(all)
contract Wallet{ 
	
	/// Total supply of ExampleTokens in existence
	access(all)
	var totalSupply: UFix64
	
	/// Storage and Public Paths
	access(all)
	let VaultStoragePath: StoragePath
	
	access(all)
	let VaultPublicPath: PublicPath
	
	access(all)
	let ReceiverPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	/// The event that is emitted when the contract is created
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	/// The event that is emitted when tokens are withdrawn from a Vault
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	/// The event that is emitted when tokens are deposited to a Vault
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	/// The event that is emitted when new tokens are minted
	access(all)
	event TokensMinted(amount: UFix64)
	
	/// The event that is emitted when tokens are destroyed
	access(all)
	event TokensBurned(amount: UFix64)
	
	/// The event that is emitted when a new minter resource is created
	access(all)
	event MinterCreated(allowedAmount: UFix64)
	
	/// The event that is emitted when a new burner resource is created
	access(all)
	event BurnerCreated()
	
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
	resource interface Provider{ 
		
		/// Subtracts tokens from the owner's Vault
		/// and returns a Vault with the removed tokens.
		///
		/// The function's access level is public, but this is not a problem
		/// because only the owner storing the resource in their account
		/// can initially call this function.
		///
		/// The owner may grant other accounts access by creating a private
		/// capability that allows specific other users to access
		/// the provider resource through a reference.
		///
		/// The owner may also grant all accounts access by creating a public
		/// capability that allows all users to access the provider
		/// resource through a reference.
		///
		/// @param amount: The amount of tokens to be withdrawn from the vault
		/// @return The Vault resource containing the withdrawn funds
		/// 
		access(all)
		fun withdraw(amount: UFix64): @Vault{ 
			post{ 
				// `result` refers to the return value
				result.balance == amount:
					"Withdrawal amount must be the same as the balance of the withdrawn Vault"
			}
		}
	}
	
	/// The interface that enforces the requirements for depositing
	/// tokens into the implementing type.
	///
	/// We do not include a condition that checks the balance because
	/// we want to give users the ability to make custom receivers that
	/// can do custom things with the tokens, like split them up and
	/// send them to different places.
	///
	access(all)
	resource interface Receiver{ 
		
		/// Takes a Vault and deposits it into the implementing resource type
		///
		/// @param from: The Vault resource containing the funds that will be deposited
		///
		access(all)
		fun deposit(from: @Vault)
	}
	
	access(all)
	resource interface Balance{ 
		
		/// The total balance of a vault
		///
		access(all)
		var balance: UFix64
		
		init(balance: UFix64){ 
			post{ 
				self.balance == balance:
					"Balance must be initialized to the initial balance"
			}
		}
	}
	
	access(all)
	resource Vault: Provider, Receiver, Balance{ 
		
		/// The total balance of this vault
		access(all)
		var balance: UFix64
		
		/// Initialize the balance at resource creation time
		init(balance: UFix64){ 
			self.balance = balance
		}
		
		/// Function that takes an amount as an argument
		/// and withdraws that amount from the Vault.
		/// It creates a new temporary Vault that is used to hold
		/// the money that is being transferred. It returns the newly
		/// created Vault to the context that called so it can be deposited
		/// elsewhere.
		///
		/// @param amount: The amount of tokens to be withdrawn from the vault
		/// @return The Vault resource containing the withdrawn funds
		///
		access(all)
		fun withdraw(amount: UFix64): @Vault{ 
			self.balance = self.balance - amount
			emit TokensWithdrawn(amount: amount, from: self.owner?.address)
			return <-create Vault(balance: amount)
		}
		
		/// Function that takes a Vault object as an argument and adds
		/// its balance to the balance of the owners Vault.
		/// It is allowed to destroy the sent Vault because the Vault
		/// was a temporary holder of the tokens. The Vault's balance has
		/// been consumed and therefore can be destroyed.
		///
		/// @param from: The Vault resource containing the funds that will be deposited
		///
		access(all)
		fun deposit(from: @Vault){ 
			let vault <- from as! @Wallet.Vault
			self.balance = self.balance + vault.balance
			emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
			vault.balance = 0.0
			destroy vault
		}
	}
	
	/// Function that creates a new Vault with a balance of zero
	/// and returns it to the calling context. A user must call this function
	/// and store the returned Vault in their storage in order to allow their
	/// account to be able to receive deposits of this token type.
	///
	/// @return The new Vault resource
	///
	access(all)
	fun createEmptyVault(): @Vault{ 
		return <-create Vault(balance: 0.0)
	}
	
	access(all)
	resource Administrator{ 
		
		/// Function that creates and returns a new minter resource
		///
		/// @param allowedAmount: The maximum quantity of tokens that the minter could create
		/// @return The Minter resource that would allow to mint tokens
		///
		access(all)
		fun createNewMinter(allowedAmount: UFix64): @Minter{ 
			emit MinterCreated(allowedAmount: allowedAmount)
			return <-create Minter(allowedAmount: allowedAmount)
		}
		
		/// Function that creates and returns a new burner resource
		///
		/// @return The Burner resource
		///
		access(all)
		fun createNewBurner(): @Burner{ 
			emit BurnerCreated()
			return <-create Burner()
		}
	}
	
	/// Resource object that token admin accounts can hold to mint new tokens.
	///
	access(all)
	resource Minter{ 
		
		/// The amount of tokens that the minter is allowed to mint
		access(all)
		var allowedAmount: UFix64
		
		/// Function that mints new tokens, adds them to the total supply,
		/// and returns them to the calling context.
		///
		/// @param amount: The quantity of tokens to mint
		/// @return The Vault resource containing the minted tokens
		///
		access(all)
		fun mintTokens(amount: UFix64): @Wallet.Vault{ 
			pre{ 
				amount > 0.0:
					"Amount minted must be greater than zero"
				amount <= self.allowedAmount:
					"Amount minted must be less than the allowed amount"
			}
			Wallet.totalSupply = Wallet.totalSupply + amount
			self.allowedAmount = self.allowedAmount - amount
			emit TokensMinted(amount: amount)
			return <-create Vault(balance: amount)
		}
		
		init(allowedAmount: UFix64){ 
			self.allowedAmount = allowedAmount
		}
	}
	
	/// Resource object that token admin accounts can hold to burn tokens.
	///
	access(all)
	resource Burner{ 
		
		/// Function that destroys a Vault instance, effectively burning the tokens.
		///
		/// Note: the burned tokens are automatically subtracted from the
		/// total supply in the Vault destructor.
		///
		/// @param from: The Vault resource containing the tokens to burn
		///
		access(all)
		fun burnTokens(from: @Vault){ 
			let vault <- from as! @Wallet.Vault
			let amount = vault.balance
			destroy vault
			emit TokensBurned(amount: amount)
		}
	}
	
	init(){ 
		self.totalSupply = 1000.0
		self.VaultStoragePath = /storage/exampleTokenVault
		self.VaultPublicPath = /public/exampleTokenMetadata
		self.ReceiverPublicPath = /public/exampleTokenReceiver
		self.AdminStoragePath = /storage/exampleTokenAdmin
		
		// Create the Vault with the total supply of tokens and save it in storage.
		let vault <- create Vault(balance: self.totalSupply)
		self.account.storage.save(<-vault, to: self.VaultStoragePath)
		
		// Create a public capability to the stored Vault that exposes
		// the `deposit` method through the `Receiver` interface.
		var capability_1 =
			self.account.capabilities.storage.issue<&{Receiver}>(self.VaultStoragePath)
		self.account.capabilities.publish(capability_1, at: self.ReceiverPublicPath)
		
		// Create a public capability to the stored Vault that only exposes
		// the `balance` field and the `resolveView` method through the `Balance` interface
		var capability_2 =
			self.account.capabilities.storage.issue<&Wallet.Vault>(self.VaultStoragePath)
		self.account.capabilities.publish(capability_2, at: self.VaultPublicPath)
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		
		// Emit an event that shows that the contract was initialized
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
