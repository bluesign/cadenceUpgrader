import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract BNU: FungibleToken{ 
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	access(all)
	event TokensMinted(amount: UFix64)
	
	access(all)
	event MinterCreated()
	
	// The storage path for the admin resource
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let StorageVaultPath: StoragePath
	
	access(all)
	let BalancePublicPath: PublicPath
	
	access(all)
	let ReceiverPath: PublicPath
	
	// Total supply of bnu in existence
	access(all)
	var totalSupply: UFix64
	
	access(all)
	resource Vault: FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance{ 
		
		// holds the balance of a users tokens
		access(all)
		var balance: UFix64
		
		// initialize the balance at resource creation time
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
			let vault <- from as! @BNU.Vault
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
	resource Minter{ 
		access(all)
		fun mintTokens(amount: UFix64): @BNU.Vault{ 
			pre{ 
				amount > 0.0:
					"Amount minted must be greater than zero"
			}
			BNU.totalSupply = BNU.totalSupply + amount
			emit TokensMinted(amount: amount)
			return <-create Vault(balance: amount)
		}
	}
	
	access(all)
	resource Administrator{ 
		access(all)
		fun createNewMinter(): @Minter{ 
			emit MinterCreated()
			return <-create Minter()
		}
	}
	
	init(){ 
		self.AdminStoragePath = /storage/bnuAdmin04
		self.ReceiverPath = /public/bnuReceiver04
		self.StorageVaultPath = /storage/bnuVault04
		self.BalancePublicPath = /public/bnuBalance04
		self.totalSupply = 0.0
		let admin <- create Administrator()
		
		// Emit an event that shows that the contract was initialized
		emit TokensInitialized(initialSupply: 0.0)
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&BNU.Vault>(self.StorageVaultPath)
		self.account.capabilities.publish(capability_1, at: self.ReceiverPath)
		var capability_2 = self.account.capabilities.storage.issue<&BNU.Vault>(self.StorageVaultPath)
		self.account.capabilities.publish(capability_2, at: self.BalancePublicPath)
	}
}
