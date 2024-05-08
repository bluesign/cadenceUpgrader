import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract GameEscrowMarker: FungibleToken{ 
	access(all)
	var totalSupply: UFix64
	
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	access(contract)
	let GameEscrowVaults:{						   /*gameID*/
						   String:{									/*Token Identifier*/
									String: Capability<&{FungibleToken.Vault}>}}
	
	access(all)
	resource Vault: FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance{ 
		access(all)
		var balance: UFix64
		
		access(contract)
		var tokenIdentifier: String?
		
		access(contract)
		var gameID: String?
		
		init(balance: UFix64){ 
			self.balance = balance
			self.tokenIdentifier = nil
			self.gameID = nil
		}
		
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			if self.balance < amount{ 
				panic("Not Enough Escrowed")
			}
			let copy <- create Vault(balance: amount)
			copy.tokenIdentifier = self.tokenIdentifier
			copy.gameID = self.gameID
			self.balance = self.balance - amount
			copy.balance = amount
			return <-copy
		}
		
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			let gameEscrowVault: @GameEscrowMarker.Vault <- from as! @GameEscrowMarker.Vault
			if self.tokenIdentifier == nil{ 
				self.tokenIdentifier = gameEscrowVault.tokenIdentifier
				self.gameID = gameEscrowVault.gameID
			} else if self.tokenIdentifier != gameEscrowVault.tokenIdentifier || self.gameID != gameEscrowVault.gameID{ 
				panic("Incompatible Vault")
			}
			self.balance = self.balance + gameEscrowVault.balance
			destroy gameEscrowVault
		}
		
		access(contract)
		fun getVault(): &{FungibleToken.Vault}{ 
			let gameCapabilities = GameEscrowMarker.GameEscrowVaults[self.gameID!] ?? panic("Not Initialized")
			let capability = gameCapabilities[self.tokenIdentifier!] ?? panic("No Compatible Vault Found")
			return capability.borrow() ?? panic("Invalid Capability")
		}
		
		access(all)
		fun depositToEscrowVault(gameID: String, vault: @{FungibleToken.Vault}){ 
			if self.tokenIdentifier == nil{ 
				self.tokenIdentifier = vault.getType().identifier
				self.gameID = gameID
			} else if self.tokenIdentifier != vault.getType().identifier || self.gameID != gameID{ 
				panic("Incompatible Vault")
			}
			self.balance = self.balance + vault.balance
			self.getVault().deposit(from: <-vault)
		}
		
		access(all)
		fun withdrawFromEscrowVault(amount: UFix64): @{FungibleToken.Vault}{ 
			if self.balance > amount{ 
				panic("Not Enough")
			}
			self.balance = self.balance - amount
			return <-self.getVault().withdraw(amount: amount)
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
	resource GameEscrowAdmin{ 
		access(all)
		fun RegisterGameEscrowVault(gameID: String, capability: Capability<&{FungibleToken.Vault}>){ 
			let gameCapabilities = GameEscrowMarker.GameEscrowVaults[gameID] ??{} 
			let vault = capability.borrow()!
			let tokenIdentifier = vault.getType().identifier
			if gameCapabilities.containsKey(tokenIdentifier){ 
				let reference = (gameCapabilities[tokenIdentifier]!).borrow()
				if reference != nil{ 
					vault.deposit(from: <-(reference!).withdraw(amount: (reference!).balance))
				}
			}
			gameCapabilities[tokenIdentifier] = capability
			GameEscrowMarker.GameEscrowVaults[gameID] = gameCapabilities
		}
	}
	
	init(){ 
		self.totalSupply = 0.0
		self.GameEscrowVaults ={} 
		self.AdminStoragePath = /storage/GameEscrowMarker
		self.AdminPrivatePath = /private/GameEscrowMarker
		let admin <- create GameEscrowAdmin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&GameEscrowAdmin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath)
	}
}
