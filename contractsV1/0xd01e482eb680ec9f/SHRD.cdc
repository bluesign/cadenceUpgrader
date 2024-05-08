import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MotoGPAdmin from "../0xa49cc0ee46c54bfb/MotoGPAdmin.cdc"

// The SRHD Fungible Token is designed to be uncapped, mintable and burnable,
// corresponding to the SHRD ERC-20 on Ethereum.
access(all)
contract SHRD: FungibleToken{ 
	access(all)
	fun getVersion(): String{ 
		return "1.0.0"
	}
	
	// TODO: SHRD contract has a private minter link that links a minter with a private capability
	// Only the vaultguard can access the private minter
	// Interface to enable creation of a private-pathed capability for minting
	access(all)
	resource interface SHRDMinterPrivate{ 
		access(all)
		fun mint(amount: UFix64): @SHRD.Vault
	}
	
	// Resource to enable creation of a private-pathed capability for minting
	// By accessing minting in this way, all mint functions can have access(contract) visibility
	access(all)
	resource SHRDMinter: SHRDMinterPrivate{ 
		access(all)
		fun mint(amount: UFix64): @SHRD.Vault{ 
			return <-SHRD.mint(amount: amount)
		}
	}
	
	// Total minted supply
	access(all)
	var totalSupply: UFix64
	
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
	
	// Event that is emitted when tokens are burned
	access(all)
	event TokensBurned(amount: UFix64)
	
	// The public path for the token balance
	access(all)
	let SHRDBalancePublicPath: PublicPath
	
	// The public path for the token receiver
	access(all)
	let SHRDReceiverPublicPath: PublicPath
	
	// The storage path for the token vault
	access(all)
	let SHRDVaultStoragePath: StoragePath
	
	// The private path for the token vault
	access(all)
	let SHRDVaultPrivatePath: PrivatePath
	
	// The storage path for the SHRDMinter
	access(all)
	let SHRDMinterStoragePath: StoragePath
	
	// The private path for the SHRDMinter which will be accessed by mintguards 
	access(all)
	let SHRDMinterPrivatePath: PrivatePath // suffix '2' should be removed after SHRDMinterPrivatePath has been deprecated and deleted (before mainnet deployment)
	
	
	// Vault
	//
	// Each user stores an instance of the Vault in their storage
	// The functions in the Vault are governed by the pre and post conditions
	// in FungibleToken when they are called.
	// The checks happen at runtime whenever a function is called.
	//
	// Resources can only be created in the context of the contract that they
	// are defined in, so there is no way for a malicious user to create Vaults
	// out of thin air.
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
		// Function that takes an amount as an argument
		// and withdraws that amount from the Vault.
		// It creates a new temporary Vault that is used to hold
		// the money that is being transferred. It returns the newly
		// created Vault to the context that called so it can be deposited
		// elsewhere.
		// @event TokensWithdrawn
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
		// been consumed and therefore the vault can be destroyed.
		// @event TokensDeposited
		//
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @SHRD.Vault
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
	
	// destroy
	//
	// SHRD are burnable
	// @event TokensBurned - emitted if a vault with balance larger than 0 is destroyed
	//
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
	
	// mint
	//
	access(contract)
	fun mint(amount: UFix64): @SHRD.Vault{ 
		pre{ 
			amount > 0.0:
				"Mint amount must be larger than 0.0"
		}
		self.totalSupply = self.totalSupply + amount
		let vault <- create Vault(balance: amount)
		emit TokensMinted(amount: amount)
		return <-vault
	}
	
	// mint with SHRD mint guard
	// init
	//
	// Contract constructor
	//
	// @event TokensInitialized
	init(){ 
		// Init supply fields
		self.totalSupply = UFix64(0)
		
		//Initialize the path fields
		//
		self.SHRDBalancePublicPath = /public/shrdBalance
		self.SHRDReceiverPublicPath = /public/shrdReceiver
		self.SHRDVaultStoragePath = /storage/shrdVault
		self.SHRDVaultPrivatePath = /private/shrdVault
		self.SHRDMinterStoragePath = /storage/shrdMinter
		self.SHRDMinterPrivatePath = /private/shrdMinter
		self.account.storage.save(<-create SHRDMinter(), to: self.SHRDMinterStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&SHRDMinter>(self.SHRDMinterStoragePath)
		self.account.capabilities.publish(capability_1, at: self.SHRDMinterPrivatePath)
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
