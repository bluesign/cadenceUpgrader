//  SPDX-License-Identifier: UNLICENSED
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract AniqueCredit: FungibleToken{ 
	
	// Total supply of all tokens in existence.
	access(all)
	var totalSupply: UFix64
	
	/// TokensInitialized
	///
	/// The event that is emitted when the contract is created
	///
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	/// TokensWithdrawn
	///
	/// The event that is emitted when tokens are withdrawn from a Vault
	///
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	/// TokensDeposited
	///
	/// The event that is emitted when tokens are deposited into a Vault
	///
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	/// TokensMinted
	///
	/// The event that is emitted when new tokens are minted
	access(all)
	event TokensMinted(amount: UFix64, to: Address?)
	
	/// TokensBurned
	///
	/// The event that is emitted when tokens are destroyed
	access(all)
	event TokensBurned(amount: UFix64, from: Address?)
	
	access(all)
	let vaultStoragePath: StoragePath
	
	access(all)
	let vaultPublicPath: PublicPath
	
	access(all)
	let minterStoragePath: StoragePath
	
	access(all)
	let minterPrivatePath: PrivatePath
	
	access(all)
	let burnerStoragePath: StoragePath
	
	access(all)
	let burnerPrivatePath: PrivatePath
	
	access(all)
	let adminStoragePath: StoragePath
	
	access(all)
	resource interface Provider{ 
		access(all)
		fun withdrawByAdmin(amount: UFix64, admin: &AniqueCredit.Admin): @AniqueCredit.Vault{ 
			post{ 
				// `result` refers to the return value of the function
				result.balance == UFix64(amount):
					"Withdrawal amount must be the same as the balance of the withdrawn Vault"
				admin != nil:
					"admin must be set"
			}
		}
	}
	
	access(all)
	resource interface Receiver{ 
		
		/// deposit takes a Vault and deposits it into the implementing resource type
		///
		access(all)
		fun deposit(from: @{FungibleToken.Vault})
	}
	
	access(all)
	resource interface Balance{ 
		access(all)
		var balance: UFix64
	}
	
	access(all)
	resource Vault: Provider, Receiver, Balance, FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance{ 
		access(all)
		var balance: UFix64
		
		// initialize the balance at resource creation time
		init(balance: UFix64){ 
			self.balance = balance
		}
		
		// withdraw
		access(all)
		fun withdrawByAdmin(amount: UFix64, admin: &AniqueCredit.Admin): @AniqueCredit.Vault{ 
			self.balance = self.balance - amount
			emit TokensWithdrawn(amount: amount, from: self.owner?.address)
			return <-create Vault(balance: amount)
		}
		
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			pre{ 
				false:
					"Use withdrawByAdmin"
			}
			return <-create Vault(balance: 0.0)
		}
		
		// deposit
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @AniqueCredit.Vault
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
	
	access(all)
	fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault}{ 
		return <-create Vault(balance: 0.0)
	}
	
	// VaultMinter
	//
	// Resource object that an admin can control to mint new tokens
	access(all)
	resource VaultMinter{ 
		
		// Function that mints new tokens and deposits into an account's vault
		// using their `Receiver` reference.
		// We say `&AnyResource{Receiver}` to say that the recipient can be any resource
		// as long as it implements the Receiver interface
		access(all)
		fun mintTokens(amount: UFix64, recipient: &{Receiver}){ 
			AniqueCredit.totalSupply = AniqueCredit.totalSupply + amount
			recipient.deposit(from: <-create Vault(balance: amount))
			emit TokensMinted(amount: amount, to: recipient.owner?.address)
		}
	}
	
	// VaultBurner
	//
	// Resource object that an admin can control to burn minted tokens
	access(all)
	resource VaultBurner{ 
		
		// Function that burns minted tokens and withdwaw from an account's vault
		// using their `Provider` reference.
		// We say `&AnyResource{Provider}` to say that the sender can be any resource
		// as long as it implements the Provider interface
		access(all)
		fun burnTokens(amount: UFix64, account: &{Provider}, admin: &AniqueCredit.Admin){ 
			let vault <- account.withdrawByAdmin(amount: amount, admin: admin)
			destroy vault
			emit TokensBurned(amount: amount, from: account.owner?.address)
		}
	}
	
	access(all)
	resource Admin{ 
		// createNewAdmin creates a new Admin resource
		//
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
		
		access(all)
		fun createNewVaultMinter(): @VaultMinter{ 
			return <-create VaultMinter()
		}
		
		access(all)
		fun createNewVaultBurner(): @VaultBurner{ 
			return <-create VaultBurner()
		}
	}
	
	// The init function for the contract. All fields in the contract must
	// be initialized at deployment. This is just an example of what
	// an implementation could do in the init function. The numbers are arbitrary.
	init(){ 
		self.totalSupply = 0.0
		self.vaultStoragePath = /storage/AniqueCreditVault
		self.vaultPublicPath = /public/AniqueCreditReceiver
		self.minterStoragePath = /storage/AniqueCreditMinter
		self.minterPrivatePath = /private/AniqueCreditMinter
		self.burnerStoragePath = /storage/AniqueCreditBurner
		self.burnerPrivatePath = /private/AniqueCreditBurner
		self.adminStoragePath = /storage/AniqueCreditAdmin
		let vault <- create Vault(balance: self.totalSupply)
		self.account.storage.save(<-vault, to: self.vaultStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Vault>(self.vaultStoragePath)
		self.account.capabilities.publish(capability_1, at: self.vaultPublicPath)
		self.account.storage.save(<-create VaultMinter(), to: self.minterStoragePath)
		var capability_2 = self.account.capabilities.storage.issue<&VaultMinter>(self.minterStoragePath)
		self.account.capabilities.publish(capability_2, at: self.minterPrivatePath)
		self.account.storage.save(<-create VaultBurner(), to: self.burnerStoragePath)
		var capability_3 = self.account.capabilities.storage.issue<&VaultBurner>(self.burnerStoragePath)
		self.account.capabilities.publish(capability_3, at: self.burnerPrivatePath)
		self.account.storage.save<@Admin>(<-create Admin(), to: self.adminStoragePath)
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
