import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import StarlyToken from "../0x142fa6570b62fd97/StarlyToken.cdc"

access(all)
contract TeleportCustodySolana{ 
	access(all)
	event TeleportAdminCreated(allowedAmount: UFix64)
	
	access(all)
	event Locked(amount: UFix64, to: [UInt8], toAddressType: String) // toAddressType: SOL, SPL
	
	
	access(all)
	event Unlocked(amount: UFix64, from: [UInt8], txHash: String)
	
	access(all)
	event FeeCollected(amount: UFix64, type: UInt8)
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let TeleportAdminStoragePath: StoragePath
	
	access(all)
	let TeleportAdminTeleportUserPath: PublicPath
	
	access(all)
	let TeleportAdminTeleportControlPath: PrivatePath
	
	access(all)
	let teleportAddressLength: Int
	
	access(all)
	let teleportTxHashLength: Int
	
	access(all)
	var isFrozen: Bool
	
	access(contract)
	var unlocked:{ String: Bool}
	
	access(contract)
	let lockVault: @StarlyToken.Vault
	
	access(all)
	resource Allowance{ 
		access(all)
		var balance: UFix64
		
		init(balance: UFix64){ 
			self.balance = balance
		}
	}
	
	access(all)
	resource Administrator{ 
		access(all)
		fun createNewTeleportAdmin(allowedAmount: UFix64): @TeleportAdmin{ 
			emit TeleportAdminCreated(allowedAmount: allowedAmount)
			return <-create TeleportAdmin(allowedAmount: allowedAmount)
		}
		
		access(all)
		fun freeze(){ 
			TeleportCustodySolana.isFrozen = true
		}
		
		access(all)
		fun unfreeze(){ 
			TeleportCustodySolana.isFrozen = false
		}
		
		access(all)
		fun createAllowance(allowedAmount: UFix64): @Allowance{ 
			return <-create Allowance(balance: allowedAmount)
		}
	}
	
	access(all)
	resource interface TeleportUser{ 
		access(all)
		var lockFee: UFix64
		
		access(all)
		var unlockFee: UFix64
		
		access(all)
		var allowedAmount: UFix64
		
		// toAddressType: SOL, SPL
		access(all)
		fun lock(from: @{FungibleToken.Vault}, to: [UInt8], toAddressType: String)
		
		access(all)
		fun depositAllowance(from: @Allowance)
	}
	
	access(all)
	resource interface TeleportControl{ 
		access(all)
		fun unlock(amount: UFix64, from: [UInt8], txHash: String): @{FungibleToken.Vault}
		
		access(all)
		fun withdrawFee(amount: UFix64): @{FungibleToken.Vault}
		
		access(all)
		fun updateLockFee(fee: UFix64)
		
		access(all)
		fun updateUnlockFee(fee: UFix64)
	}
	
	access(all)
	resource TeleportAdmin: TeleportUser, TeleportControl{ 
		access(all)
		var lockFee: UFix64
		
		access(all)
		var unlockFee: UFix64
		
		access(all)
		var allowedAmount: UFix64
		
		access(all)
		let feeCollector: @StarlyToken.Vault
		
		// toAddressType: SOL, SPL
		access(all)
		fun lock(from: @{FungibleToken.Vault}, to: [UInt8], toAddressType: String){ 
			pre{ 
				!TeleportCustodySolana.isFrozen:
					"Teleport service is frozen"
				to.length == TeleportCustodySolana.teleportAddressLength:
					"Teleport address should be teleportAddressLength bytes"
			}
			let vault <- from as! @StarlyToken.Vault
			let fee <- vault.withdraw(amount: self.lockFee)
			self.feeCollector.deposit(from: <-fee)
			let amount = vault.balance
			TeleportCustodySolana.lockVault.deposit(from: <-vault)
			emit Locked(amount: amount, to: to, toAddressType: toAddressType)
			emit FeeCollected(amount: self.lockFee, type: 0)
		}
		
		access(all)
		fun unlock(amount: UFix64, from: [UInt8], txHash: String): @{FungibleToken.Vault}{ 
			pre{ 
				!TeleportCustodySolana.isFrozen:
					"Teleport service is frozen"
				amount <= self.allowedAmount:
					"Amount unlocked must be less than the allowed amount"
				amount > self.unlockFee:
					"Amount unlocked must be greater than unlock fee"
				from.length == TeleportCustodySolana.teleportAddressLength:
					"Teleport address should be teleportAddressLength bytes"
				txHash.length == TeleportCustodySolana.teleportTxHashLength:
					"Teleport tx hash should be teleportTxHashLength bytes"
				!(TeleportCustodySolana.unlocked[txHash] ?? false):
					"Same unlock txHash has been executed"
			}
			self.allowedAmount = self.allowedAmount - amount
			TeleportCustodySolana.unlocked[txHash] = true
			emit Unlocked(amount: amount, from: from, txHash: txHash)
			let vault <- TeleportCustodySolana.lockVault.withdraw(amount: amount)
			let fee <- vault.withdraw(amount: self.unlockFee)
			self.feeCollector.deposit(from: <-fee)
			emit FeeCollected(amount: self.unlockFee, type: 1)
			return <-vault
		}
		
		access(all)
		fun withdrawFee(amount: UFix64): @{FungibleToken.Vault}{ 
			return <-self.feeCollector.withdraw(amount: amount)
		}
		
		access(all)
		fun updateLockFee(fee: UFix64){ 
			self.lockFee = fee
		}
		
		access(all)
		fun updateUnlockFee(fee: UFix64){ 
			self.unlockFee = fee
		}
		
		access(all)
		fun getFeeAmount(): UFix64{ 
			return self.feeCollector.balance
		}
		
		access(all)
		fun depositAllowance(from: @Allowance){ 
			self.allowedAmount = self.allowedAmount + from.balance
			destroy from
		}
		
		init(allowedAmount: UFix64){ 
			self.allowedAmount = allowedAmount
			self.feeCollector <- StarlyToken.createEmptyVault(vaultType: Type<@StarlyToken.Vault>()) as! @StarlyToken.Vault
			self.lockFee = 3.0
			self.unlockFee = 0.01
		}
	}
	
	access(all)
	fun getLockVaultBalance(): UFix64{ 
		return TeleportCustodySolana.lockVault.balance
	}
	
	init(){ 
		// Solana address length
		self.teleportAddressLength = 32
		
		// Solana tx hash length
		self.teleportTxHashLength = 128
		self.AdminStoragePath = /storage/teleportCustodySolanaAdmin
		self.TeleportAdminStoragePath = /storage/teleportCustodySolanaTeleportAdmin
		self.TeleportAdminTeleportUserPath = /public/teleportCustodySolanaTeleportUser
		self.TeleportAdminTeleportControlPath = /private/teleportCustodySolanaTeleportControl
		self.isFrozen = false
		self.unlocked ={} 
		self.lockVault <- StarlyToken.createEmptyVault(vaultType: Type<@StarlyToken.Vault>())
			as!
			@StarlyToken.Vault
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
	}
}