import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import Toucans from "../0x577a3c409c5dcb5e/Toucans.cdc"

import ToucansTokens from "../0x577a3c409c5dcb5e/ToucansTokens.cdc"

access(all)
contract FlovatarConfrariaToken: FungibleToken{ 
	access(all)
	var totalSupply: UFix64
	
	access(all)
	let VaultReceiverPath: PublicPath
	
	access(all)
	let VaultBalancePath: PublicPath
	
	access(all)
	let VaultStoragePath: StoragePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	access(all)
	event TokensMinted(amount: UFix64)
	
	access(all)
	event TokensBurned(amount: UFix64)
	
	access(all)
	event MinterCreated(allowedAmount: UFix64)
	
	access(all)
	event BurnerCreated()
	
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
			let vault <- from as! @FlovatarConfrariaToken.Vault
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
	
	access(all)
	resource Administrator{ 
		access(all)
		fun createNewMinter(allowedAmount: UFix64): @Minter{ 
			emit MinterCreated(allowedAmount: allowedAmount)
			return <-create Minter(allowedAmount: allowedAmount)
		}
		
		access(all)
		fun createNewBurner(): @Burner{ 
			emit BurnerCreated()
			return <-create Burner()
		}
	}
	
	access(all)
	resource Minter{ 
		access(all)
		var allowedAmount: UFix64
		
		access(all)
		fun mintTokens(amount: UFix64): @FlovatarConfrariaToken.Vault{ 
			pre{ 
				amount > 0.0:
					"Amount minted must be greater than zero"
				amount <= self.allowedAmount:
					"Amount minted must be less than the allowed amount"
			}
			FlovatarConfrariaToken.totalSupply = FlovatarConfrariaToken.totalSupply + amount
			self.allowedAmount = self.allowedAmount - amount
			emit TokensMinted(amount: amount)
			return <-create Vault(balance: amount)
		}
		
		init(allowedAmount: UFix64){ 
			self.allowedAmount = allowedAmount
		}
	}
	
	access(all)
	resource Burner{ 
		access(all)
		fun burnTokens(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @FlovatarConfrariaToken.Vault
			let amount = vault.balance
			destroy vault
			emit TokensBurned(amount: amount)
		}
	}
	
	init(){ 
		self.totalSupply = 100000.0
		self.VaultReceiverPath = /public/FlovatarConfrariaTokenReceiver
		self.VaultBalancePath = /public/FlovatarConfrariaTokenBalance
		self.VaultStoragePath = /storage/FlovatarConfrariaTokenVault
		self.AdminStoragePath = /storage/FlovatarConfrariaTokenAdmin
		let vault <- create Vault(balance: self.totalSupply)
		self.account.storage.save(<-vault, to: self.VaultStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{FungibleToken.Receiver, FungibleToken.Balance}>(self.VaultStoragePath)
		self.account.capabilities.publish(capability_1, at: self.VaultReceiverPath)
		var capability_2 = self.account.capabilities.storage.issue<&FlovatarConfrariaToken.Vault>(self.VaultStoragePath)
		self.account.capabilities.publish(capability_2, at: self.VaultBalancePath)
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
