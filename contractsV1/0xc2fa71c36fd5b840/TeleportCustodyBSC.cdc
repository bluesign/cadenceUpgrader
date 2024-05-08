import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import StarlyToken from "../0x142fa6570b62fd97/StarlyToken.cdc"

access(all)
contract TeleportCustodyBSC{ 
	access(all)
	event TeleportAdminCreated(allowedAmount: UFix64)
	
	access(all)
	event Locked(amount: UFix64, to: [UInt8])
	
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
			TeleportCustodyBSC.isFrozen = true
		}
		
		access(all)
		fun unfreeze(){ 
			TeleportCustodyBSC.isFrozen = false
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
		
		access(all)
		fun lock(from: @{FungibleToken.Vault}, to: [UInt8])
		
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
		
		access(all)
		fun lock(from: @{FungibleToken.Vault}, to: [UInt8]){ 
			pre{ 
				!TeleportCustodyBSC.isFrozen:
					"Teleport service is frozen"
				to.length == TeleportCustodyBSC.teleportAddressLength:
					"Teleport address should be teleportAddressLength bytes"
			}
			let vault <- from as! @StarlyToken.Vault
			let fee <- vault.withdraw(amount: self.lockFee)
			self.feeCollector.deposit(from: <-fee)
			let amount = vault.balance
			TeleportCustodyBSC.lockVault.deposit(from: <-vault)
			emit Locked(amount: amount, to: to)
			emit FeeCollected(amount: self.lockFee, type: 0)
		}
		
		access(all)
		fun unlock(amount: UFix64, from: [UInt8], txHash: String): @{FungibleToken.Vault}{ 
			pre{ 
				!TeleportCustodyBSC.isFrozen:
					"Teleport service is frozen"
				amount <= self.allowedAmount:
					"Amount unlocked must be less than the allowed amount"
				amount > self.unlockFee:
					"Amount unlocked must be greater than unlock fee"
				from.length == TeleportCustodyBSC.teleportAddressLength:
					"Teleport address should be teleportAddressLength bytes"
				txHash.length == TeleportCustodyBSC.teleportTxHashLength:
					"Teleport tx hash should be teleportTxHashLength bytes"
				!(TeleportCustodyBSC.unlocked[txHash] ?? false):
					"Same unlock txHash has been executed"
			}
			self.allowedAmount = self.allowedAmount - amount
			TeleportCustodyBSC.unlocked[txHash] = true
			emit Unlocked(amount: amount, from: from, txHash: txHash)
			let vault <- TeleportCustodyBSC.lockVault.withdraw(amount: amount)
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
		return TeleportCustodyBSC.lockVault.balance
	}
	
	init(){ 
		self.teleportAddressLength = 20
		self.teleportTxHashLength = 64
		self.AdminStoragePath = /storage/teleportCustodyBSCAdmin
		self.TeleportAdminStoragePath = /storage/teleportCustodyBSCTeleportAdmin
		self.TeleportAdminTeleportUserPath = /public/teleportCustodyBSCTeleportUser
		self.TeleportAdminTeleportControlPath = /private/teleportCustodyBSCTeleportControl
		self.isFrozen = false
		self.unlocked ={} 
		self.lockVault <- StarlyToken.createEmptyVault(vaultType: Type<@StarlyToken.Vault>())
			as!
			@StarlyToken.Vault
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
	}
}
