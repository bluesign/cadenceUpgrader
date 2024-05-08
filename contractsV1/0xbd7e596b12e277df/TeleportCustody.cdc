import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract TeleportCustody{ 
	
	// Event that is emitted when new tokens are teleported in from Ethereum (from: Ethereum Address, 20 bytes)
	access(all)
	event TokensTeleportedIn(amount: UFix64, from: [UInt8], hash: String)
	
	// Event that is emitted when tokens are destroyed and teleported to Ethereum (to: Ethereum Address, 20 bytes)
	access(all)
	event TokensTeleportedOut(amount: UFix64, to: [UInt8])
	
	// Event that is emitted when teleport fee is collected (type 0: out, 1: in)
	access(all)
	event FeeCollected(amount: UFix64, type: UInt8)
	
	// Event that is emitted when a new burner resource is created
	access(all)
	event TeleportAdminCreated(allowedAmount: UFix64)
	
	// The storage path for the admin resource (equivalent to root)
	access(all)
	let AdminStoragePath: StoragePath
	
	// The storage path for the teleport-admin resource (less priviledged than admin)  
	access(all)
	let TeleportAdminStoragePath: StoragePath
	
	// The private path for the teleport-admin resource
	access(all)
	let TeleportAdminPrivatePath: PrivatePath
	
	// The public path for the teleport user
	access(all)
	let TeleportUserPublicPath: PublicPath
	
	// Frozen flag controlled by Admin
	access(all)
	var isFrozen: Bool
	
	// Record teleported Ethereum hashes
	access(contract)
	var teleported:{ String: Bool}
	
	// Controls FLOW vault
	access(contract)
	let flowVault: @FlowToken.Vault
	
	access(all)
	resource Allowance{ 
		access(all)
		var balance: UFix64
		
		// initialize the balance at resource creation time
		init(balance: UFix64){ 
			self.balance = balance
		}
	}
	
	access(all)
	resource Administrator{ 
		
		// createNewTeleportAdmin
		//
		// Function that creates and returns a new teleport admin resource
		//
		access(all)
		fun createNewTeleportAdmin(allowedAmount: UFix64): @TeleportAdmin{ 
			emit TeleportAdminCreated(allowedAmount: allowedAmount)
			return <-create TeleportAdmin(allowedAmount: allowedAmount)
		}
		
		access(all)
		fun freeze(){ 
			TeleportCustody.isFrozen = true
		}
		
		access(all)
		fun unfreeze(){ 
			TeleportCustody.isFrozen = false
		}
		
		access(all)
		fun createAllowance(allowedAmount: UFix64): @Allowance{ 
			return <-create Allowance(balance: allowedAmount)
		}
		
		// deposit
		// 
		// Function that deposits FLOW token into the contract controlled
		// vault.
		//
		access(all)
		fun depositFlow(from: @FlowToken.Vault){ 
			TeleportCustody.flowVault.deposit(from: <-from)
		}
		
		access(all)
		fun withdrawFlow(amount: UFix64): @{FungibleToken.Vault}{ 
			return <-TeleportCustody.flowVault.withdraw(amount: amount)
		}
	}
	
	access(all)
	resource interface TeleportUser{ 
		// fee collected when token is teleported from Ethereum to Flow
		access(all)
		var inwardFee: UFix64
		
		// fee collected when token is teleported from Flow to Ethereum
		access(all)
		var outwardFee: UFix64
		
		// the amount of tokens that the admin is allowed to teleport
		access(all)
		var allowedAmount: UFix64
		
		// corresponding controller account on Ethereum
		access(all)
		fun getEthereumAdminAccount(): [UInt8]
		
		access(all)
		fun teleportOut(from: @FlowToken.Vault, to: [UInt8])
		
		access(all)
		fun depositAllowance(from: @Allowance)
		
		access(all)
		fun getFeeAmount(): UFix64
	}
	
	access(all)
	resource interface TeleportControl{ 
		access(all)
		fun teleportIn(amount: UFix64, from: [UInt8], hash: String): @{FungibleToken.Vault}
		
		access(all)
		fun withdrawFee(amount: UFix64): @{FungibleToken.Vault}
		
		access(all)
		fun updateInwardFee(fee: UFix64)
		
		access(all)
		fun updateOutwardFee(fee: UFix64)
		
		access(all)
		fun updateEthereumAdminAccount(account: [UInt8])
	}
	
	// TeleportAdmin resource
	//
	//  Resource object that has the capability to teleport tokens
	//  upon receiving teleport request from Ethereum side
	//
	access(all)
	resource TeleportAdmin: TeleportUser, TeleportControl{ 
		
		// the amount of tokens that the admin is allowed to teleport
		access(all)
		var allowedAmount: UFix64
		
		// receiver reference to collect teleport fee
		access(all)
		let feeCollector: @FlowToken.Vault
		
		// fee collected when token is teleported from Ethereum to Flow
		access(all)
		var inwardFee: UFix64
		
		// fee collected when token is teleported from Flow to Ethereum
		access(all)
		var outwardFee: UFix64
		
		// corresponding controller account on Ethereum
		access(contract)
		var ethereumAdminAccount: [UInt8]
		
		// teleportIn
		//
		// Function that release FLOW tokens from custody,
		// and returns them to the calling context.
		//
		access(all)
		fun teleportIn(amount: UFix64, from: [UInt8], hash: String): @{FungibleToken.Vault}{ 
			pre{ 
				!TeleportCustody.isFrozen:
					"Teleport service is frozen"
				amount <= self.allowedAmount:
					"Amount teleported must be less than the allowed amount"
				amount > self.inwardFee:
					"Amount teleported must be greater than inward teleport fee"
				from.length == 20:
					"Ethereum address should be 20 bytes"
				hash.length == 64:
					"Ethereum tx hash should be 32 bytes"
				!(TeleportCustody.teleported[hash] ?? false):
					"Same hash already teleported"
			}
			self.allowedAmount = self.allowedAmount - amount
			TeleportCustody.teleported[hash] = true
			emit TokensTeleportedIn(amount: amount, from: from, hash: hash)
			let vault <- TeleportCustody.flowVault.withdraw(amount: amount)
			let fee <- vault.withdraw(amount: self.inwardFee)
			self.feeCollector.deposit(from: <-fee)
			emit FeeCollected(amount: self.inwardFee, type: 1)
			return <-vault
		}
		
		// teleportOut
		//
		// Function that locks FLOW tokens into custody by depositing the
		// passed Vault into the contract's flowVault.
		//	
		access(all)
		fun teleportOut(from: @FlowToken.Vault, to: [UInt8]){ 
			pre{ 
				!TeleportCustody.isFrozen:
					"Teleport service is frozen"
				to.length == 20:
					"Ethereum address should be 20 bytes"
			}
			let vault <- from as! @FlowToken.Vault
			let fee <- vault.withdraw(amount: self.outwardFee)
			self.feeCollector.deposit(from: <-fee)
			emit FeeCollected(amount: self.outwardFee, type: 0)
			let amount = vault.balance
			TeleportCustody.flowVault.deposit(from: <-vault)
			emit TokensTeleportedOut(amount: amount, to: to)
		}
		
		access(all)
		fun withdrawFee(amount: UFix64): @{FungibleToken.Vault}{ 
			return <-self.feeCollector.withdraw(amount: amount)
		}
		
		access(all)
		fun updateInwardFee(fee: UFix64){ 
			self.inwardFee = fee
		}
		
		access(all)
		fun updateOutwardFee(fee: UFix64){ 
			self.outwardFee = fee
		}
		
		access(all)
		fun getEthereumAdminAccount(): [UInt8]{ 
			return self.ethereumAdminAccount
		}
		
		access(all)
		fun updateEthereumAdminAccount(account: [UInt8]){ 
			pre{ 
				account.length == 20:
					"Ethereum address should be 20 bytes"
			}
			self.ethereumAdminAccount = account
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
			self.feeCollector <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()) as! @FlowToken.Vault
			self.inwardFee = 0.01
			self.outwardFee = 10.0
			self.ethereumAdminAccount = []
		}
	}
	
	access(all)
	fun getLockedVaultBalance(): UFix64{ 
		return TeleportCustody.flowVault.balance
	}
	
	init(){ 
		
		// Initialize the path fields
		self.AdminStoragePath = /storage/flowTeleportCustodyAdmin
		self.TeleportAdminStoragePath = /storage/flowTeleportCustodyTeleportAdmin
		self.TeleportUserPublicPath = /public/flowTeleportCustodyTeleportUser
		self.TeleportAdminPrivatePath = /private/flowTeleportCustodyTeleportAdmin
		
		// Initialize contract variables
		self.isFrozen = false
		self.teleported ={} 
		
		// Setup internal FLOW vault
		self.flowVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
			as!
			@FlowToken.Vault
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
	}
}
