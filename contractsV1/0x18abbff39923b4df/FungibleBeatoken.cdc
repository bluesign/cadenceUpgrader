// SPDX-License-Identifier: UNLICENSED
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract FungibleBeatoken: FungibleToken{ 
	
	// Total Supply
	access(all)
	var totalSupply: UFix64
	
	// Events
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	// Paths
	access(all)
	let minterPath: PrivatePath
	
	access(all)
	let minterStoragePath: StoragePath
	
	access(all)
	let publicReceiverPath: PublicPath
	
	access(all)
	let vaultStoragePath: StoragePath
	
	access(all)
	resource Vault: FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance{ 
		access(all)
		var balance: UFix64
		
		init(balance: UFix64){ 
			self.balance = balance
		}
		
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			self.balance = self.balance - amount
			emit TokensWithdrawn(amount: amount, from: self.owner?.address)
			return <-create Vault(balance: amount)
		}
		
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @FungibleBeatoken.Vault
			self.balance = self.balance + vault.balance
			emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
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
	resource VaultMinter{ 
		access(all)
		fun mintTokens(amount: UFix64): @FungibleBeatoken.Vault{ 
			FungibleBeatoken.totalSupply = FungibleBeatoken.totalSupply + amount
			return <-create Vault(balance: amount)
		}
	}
	
	access(all)
	fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault}{ 
		return <-create Vault(balance: 0.0)
	}
	
	init(){ 
		self.totalSupply = 0.0
		
		// minter paths
		self.minterPath = /private/beatokenMainMinter
		self.minterStoragePath = /storage/beatokenMainMinter
		
		// Vault paths
		self.publicReceiverPath = /public/beatokenReceiver
		self.vaultStoragePath = /storage/beatokenMainVault
		let vault <- create Vault(balance: self.totalSupply)
		self.account.storage.save(<-vault, to: self.vaultStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Vault>(self.vaultStoragePath)
		self.account.capabilities.publish(capability_1, at: self.publicReceiverPath)
		let minter <- create VaultMinter()
		self.account.storage.save(<-minter, to: self.minterStoragePath)
		var capability_2 = self.account.capabilities.storage.issue<&VaultMinter>(self.minterStoragePath)
		self.account.capabilities.publish(capability_2, at: self.minterPath)
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
