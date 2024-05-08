import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract YDYToken: FungibleToken{ 
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
	event BurnerCreated()
	
	access(all)
	resource Vault: FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance{ 
		access(all)
		var balance: UFix64
		
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @YDYToken.Vault
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
			pre{ 
				YDYToken.totalSupply + amount <= 1000000000.0:
					"Adding this amount causes YDY tokens to go over max supply of 1 billion"
			}
			YDYToken.totalSupply = YDYToken.totalSupply + amount
			emit TokensMinted(amount: amount)
			return <-create Vault(balance: amount)
		}
		
		init(){} 
	}
	
	access(all)
	resource Burner{ 
		init(){} 
	}
	
	init(){ 
		self.totalSupply = 0.0
		self.VaultStoragePath = /storage/YDYTokenVault
		self.ReceiverPublicPath = /public/YDYTokenReceiver
		self.BalancePublicPath = /public/YDYTokenBalance
		self.AdminStoragePath = /storage/YDYTokenAdmin
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
}
