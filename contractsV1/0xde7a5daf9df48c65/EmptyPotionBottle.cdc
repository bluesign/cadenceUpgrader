import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

// Token contract of EmptyPotionBottle (EPB)
access(all)
contract EmptyPotionBottle: FungibleToken{ 
	
	// -----------------------------------------------------------------------
	// EmptyPotionBottle contract Events
	// -----------------------------------------------------------------------
	
	// Event that is emitted when the contract is created
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	// Event that is emitted when tokens are withdrawn from a Vault
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	// Event that is emitted when tokens are deposited to a Vault
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	// Event that is emitted when new tokens are minted
	access(all)
	event TokensMinted(amount: UFix64)
	
	// Event that is emitted when tokens are destroyed
	access(all)
	event TokensBurned(amount: UFix64)
	
	// Event that is emitted when a new minter resource is created
	access(all)
	event MinterCreated()
	
	// Event that is emitted when a new burner resource is created
	access(all)
	event BurnerCreated()
	
	// Event that is emitted when a new MinterProxy resource is created
	access(all)
	event MinterProxyCreated()
	
	// -----------------------------------------------------------------------
	// EmptyPotionBottle contract Named Paths
	// -----------------------------------------------------------------------
	// Defines EmptyPotionBottle vault storage path
	access(all)
	let VaultStoragePath: StoragePath
	
	// Defines EmptyPotionBottle vault public balance path
	access(all)
	let BalancePublicPath: PublicPath
	
	// Defines EmptyPotionBottle vault public receiver path
	access(all)
	let ReceiverPublicPath: PublicPath
	
	// Defines EmptyPotionBottle admin storage path
	access(all)
	let AdminStoragePath: StoragePath
	
	// Defines EmptyPotionBottle minter storage path
	access(all)
	let MinterStoragePath: StoragePath
	
	// Defines EmptyPotionBottle minters' MinterProxy storage path
	access(all)
	let MinterProxyStoragePath: StoragePath
	
	// Defines EmptyPotionBottle minters' MinterProxy capability public path
	access(all)
	let MinterProxyPublicPath: PublicPath
	
	// -----------------------------------------------------------------------
	// EmptyPotionBottle contract fields
	// These contain actual values that are stored in the smart contract
	// -----------------------------------------------------------------------
	// Total supply of EmptyPotionBottle in existence
	access(all)
	var totalSupply: UFix64
	
	// Vault
	//
	// Each user stores an instance of only the Vault in their storage
	// The functions in the Vault are governed by the pre and post conditions
	// in FungibleToken when they are called.
	// The checks happen at runtime whenever a function is called.
	//
	// Resources can only be created in the context of the contract that they
	// are defined in, so there is no way for a malicious user to create Vaults
	// out of thin air. A special Minter resource needs to be defined to mint
	// new tokens.
	//
	access(all)
	resource Vault: FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance{ 
		
		// holds the balance of a users tokens
		access(all)
		var balance: UFix64
		
		// initialize the balance at resource creation time
		init(balance: UFix64){ 
			self.balance = balance
		}
		
		// withdraw
		//
		// Function that takes an integer amount as an argument
		// and withdraws that amount from the Vault.
		// It creates a new temporary Vault that is used to hold
		// the money that is being transferred. It returns the newly
		// created Vault to the context that called so it can be deposited
		// elsewhere.
		//
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			self.balance = self.balance - amount
			emit TokensWithdrawn(amount: amount, from: self.owner?.address)
			return <-create Vault(balance: amount)
		}
		
		// deposit
		//
		// Function that takes a Vault object as an argument and adds
		// its balance to the balance of the owners Vault.
		// It is allowed to destroy the sent Vault because the Vault
		// was a temporary holder of the tokens. The Vault's balance has
		// been consumed and therefore can be destroyed.
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @EmptyPotionBottle.Vault
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
	
	// createEmptyVault
	//
	// Function that creates a new Vault with a balance of zero
	// and returns it to the calling context. A user must call this function
	// and store the returned Vault in their storage in order to allow their
	// account to be able to receive deposits of this token type.
	//
	access(all)
	fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault}{ 
		return <-create Vault(balance: 0.0)
	}
	
	// Administrator
	//
	// Resource object that token admin accounts can hold to create new minters and burners.
	//
	access(all)
	resource Administrator{ 
		// createNewMinter
		//
		// Function that creates and returns a new minter resource
		//
		access(all)
		fun createNewMinter(): @Minter{ 
			emit MinterCreated()
			return <-create Minter()
		}
		
		// createNewBurner
		//
		// Function that creates and returns a new burner resource
		//
		access(all)
		fun createNewBurner(): @Burner{ 
			emit BurnerCreated()
			return <-create Burner()
		}
	}
	
	// Minter
	//
	// Resource object that token admin accounts can hold to mint new tokens.
	//
	access(all)
	resource Minter{ 
		
		// mintTokens
		//
		// Function that mints new tokens, adds them to the total supply,
		// and returns them to the calling context.
		//
		access(all)
		fun mintTokens(amount: UFix64): @EmptyPotionBottle.Vault{ 
			pre{ 
				amount > 0.0:
					"Amount minted must be greater than zero"
			}
			EmptyPotionBottle.totalSupply = EmptyPotionBottle.totalSupply + amount
			emit TokensMinted(amount: amount)
			return <-create Vault(balance: amount)
		}
	}
	
	// Burner
	//
	// Resource object that token admin accounts can hold to burn tokens.
	//
	access(all)
	resource Burner{ 
		
		// burnTokens
		//
		// Function that destroys a Vault instance, effectively burning the tokens.
		//
		// Note: the burned tokens are automatically subtracted from the 
		// total supply in the Vault destructor.
		//
		access(all)
		fun burnTokens(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @EmptyPotionBottle.Vault
			let amount = vault.balance
			destroy vault
			emit TokensBurned(amount: amount)
		}
	}
	
	access(all)
	resource interface MinterProxyPublic{ 
		access(all)
		fun setMinterCapability(cap: Capability<&Minter>)
	}
	
	// MinterProxy
	//
	// Resource object holding a capability that can be used to mint new tokens.
	// The resource that this capability represents can be deleted by the admin
	// in order to unilaterally revoke minting capability if needed.
	access(all)
	resource MinterProxy: MinterProxyPublic{ 
		
		// access(self) so nobody else can copy the capability and use it.
		access(self)
		var minterCapability: Capability<&Minter>?
		
		// Anyone can call this, but only the admin can create Minter capabilities,
		// so the type system constrains this to being called by the admin.
		access(all)
		fun setMinterCapability(cap: Capability<&Minter>){ 
			self.minterCapability = cap
		}
		
		access(all)
		fun mintTokens(amount: UFix64): @EmptyPotionBottle.Vault{ 
			return <-((self.minterCapability!).borrow()!).mintTokens(amount: amount)
		}
		
		init(){ 
			self.minterCapability = nil
		}
	}
	
	// createMinterProxy
	//
	// Function that creates a MinterProxy.
	// Anyone can call this, but the MinterProxy cannot mint without a Minter capability,
	// and only the admin can provide that.
	//
	access(all)
	fun createMinterProxy(): @MinterProxy{ 
		emit MinterProxyCreated()
		return <-create MinterProxy()
	}
	
	init(){ 
		self.VaultStoragePath = /storage/emptyPotionBottleVault
		self.ReceiverPublicPath = /public/emptyPotionBottleReceiver
		self.BalancePublicPath = /public/emptyPotionBottleBalance
		self.AdminStoragePath = /storage/emptyPotionBottleAdmin
		self.MinterStoragePath = /storage/emptyPotionBottleMinter
		self.MinterProxyPublicPath = /public/emptyPotionBottleMinterProxy
		self.MinterProxyStoragePath = /storage/emptyPotionBottleMinterProxy
		self.totalSupply = 0.0
		
		// Create the Vault with the total supply of tokens and save it in storage
		let vault <- create Vault(balance: self.totalSupply)
		self.account.storage.save(<-vault, to: self.VaultStoragePath)
		
		// Create a public capability to the stored Vault that only exposes
		// the `deposit` method through the `Receiver` interface
		var capability_1 = self.account.capabilities.storage.issue<&EmptyPotionBottle.Vault>(self.VaultStoragePath)
		self.account.capabilities.publish(capability_1, at: self.ReceiverPublicPath)
		
		// Create a public capability to the stored Vault that only exposes
		// the `balance` field through the `Balance` interface
		var capability_2 = self.account.capabilities.storage.issue<&EmptyPotionBottle.Vault>(self.VaultStoragePath)
		self.account.capabilities.publish(capability_2, at: self.BalancePublicPath)
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		
		// Emit an event that shows that the contract was initialized
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
