import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract FTWToken: FungibleToken{ 
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
	
	// Events
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
	event MinterCreated()
	
	access(all)
	resource Vault: FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance{ 
		access(all)
		var balance: UFix64
		
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @FTWToken.Vault
			emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
			self.balance = self.balance + vault.balance
			vault.balance = 0.0
			destroy vault
		}
		
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			self.balance = self.balance - amount
			emit TokensWithdrawn(amount: amount, from: self.owner?.address)
			return <-create Vault(balance: amount)
		}
		
		access(all)
		fun createEmptyVault(): @{FungibleToken.Vault}{ 
			return <-create Vault(balance: 0.0)
		}
		
		access(all)
		view fun isAvailableToWithdraw(amount: UFix64): Bool{ 
			return self.balance >= amount
		}
		
		init(balance: UFix64){ 
			self.balance = balance
		}
	
	// When tokens get burned
	}
	
	access(all)
	fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault}{ 
		return <-create Vault(balance: 0.0)
	}
	
	access(all)
	resource Administrator{ 
		access(all)
		fun createNewMinter(): @Minter{ 
			emit MinterCreated()
			return <-create Minter()
		}
	}
	
	access(all)
	resource Minter{ 
		access(all)
		fun mintToken(amount: UFix64): @{FungibleToken.Vault}{ 
			FTWToken.totalSupply = FTWToken.totalSupply + amount
			emit TokensMinted(amount: amount)
			return <-create Vault(balance: amount)
		}
		
		init(){} 
	}
	
	init(){ 
		self.totalSupply = 0.0
		self.VaultStoragePath = /storage/FTWTokenVault
		self.ReceiverPublicPath = /public/FTWTokenReceiver
		self.BalancePublicPath = /public/FTWTokenBalance
		self.AdminStoragePath = /storage/FTWTokenAdmin
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
}
