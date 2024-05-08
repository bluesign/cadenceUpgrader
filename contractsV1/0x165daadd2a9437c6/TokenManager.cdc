import Rumble from "./Rumble.cdc"

access(all)
contract TokenManager{ 
	access(all)
	var cooldown: UFix64
	
	access(all)
	let VaultPublicPath: PublicPath
	
	access(all)
	let VaultStoragePath: StoragePath
	
	access(all)
	resource interface Public{ 
		access(all)
		fun deposit(from: @Rumble.Vault)
		
		access(all)
		view fun canWithdraw(): Bool
		
		access(all)
		fun getBalance(): UFix64
		
		access(account)
		fun distribute(to: Address, amount: UFix64)
	}
	
	access(all)
	resource LockedVault: Public{ 
		access(self)
		let tokens: @Rumble.Vault
		
		access(all)
		var withdrawTimestamp: UFix64
		
		access(all)
		fun deposit(from: @Rumble.Vault){ 
			self.tokens.deposit(from: <-from)
			self.withdrawTimestamp = getCurrentBlock().timestamp + TokenManager.cooldown
		}
		
		access(all)
		fun withdraw(amount: UFix64): @Rumble.Vault{ 
			pre{ 
				self.canWithdraw():
					"User cannot withdraw yet."
			}
			let tokens <- self.tokens.withdraw(amount: amount) as! @Rumble.Vault
			return <-tokens
		}
		
		access(account)
		fun distribute(to: Address, amount: UFix64){ 
			let recipientVault = getAccount(to).capabilities.get<&LockedVault>(TokenManager.VaultPublicPath).borrow<&LockedVault>() ?? panic("This user does not have a vault set up.")
			let tokens <- self.tokens.withdraw(amount: amount) as! @Rumble.Vault
			recipientVault.deposit(from: <-tokens)
		}
		
		access(all)
		view fun canWithdraw(): Bool{ 
			return getCurrentBlock().timestamp >= self.withdrawTimestamp
		}
		
		access(all)
		fun getBalance(): UFix64{ 
			return self.tokens.balance
		}
		
		init(){ 
			self.tokens <- Rumble.createEmptyVault(vaultType: Type<@Rumble.Vault>())
			self.withdrawTimestamp = getCurrentBlock().timestamp
		}
	}
	
	access(all)
	fun createEmptyVault(): @LockedVault{ 
		return <-create LockedVault()
	}
	
	access(all)
	fun checkUserDepositStatusIsValid(user: Address, amount: UFix64): Bool{ 
		let userVault =
			getAccount(user).capabilities.get<&LockedVault>(TokenManager.VaultPublicPath).borrow<
				&LockedVault
			>()
			?? panic("This user does not have a vault set up.")
		return userVault.getBalance() >= amount
	}
	
	access(account)
	fun changeCooldown(newCooldown: UFix64){ 
		self.cooldown = newCooldown
	}
	
	init(){ 
		self.cooldown = 0.0
		self.VaultPublicPath = /public/BloxsmithLockedVault
		self.VaultStoragePath = /storage/BloxsmithLockedVault
	}
}
