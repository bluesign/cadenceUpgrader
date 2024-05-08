import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract brasil: FungibleToken{ 
	access(all)
	var totalSupply: UFix64
	
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
	
	access(all)
	let TokenMinterStoragePath: StoragePath
	
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
			let vault <- from as! @brasil.Vault
			self.balance = self.balance + vault.balance
			emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
			vault.balance = 0.0
			destroy vault // Make sure we get rid of the vault
		
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
		fun mintToken(amount: UFix64): @{FungibleToken.Vault}{ 
			brasil.totalSupply = brasil.totalSupply + amount
			return <-create Vault(balance: amount)
		}
	}
	
	init(){ 
		self.totalSupply = 0.0
		self.TokenMinterStoragePath = /storage/brasilMinter
		self.account.storage.save(<-create Minter(), to: brasil.TokenMinterStoragePath)
	}
}
