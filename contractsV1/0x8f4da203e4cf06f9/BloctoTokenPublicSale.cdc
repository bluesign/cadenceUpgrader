/*

	BloctoTokenPublicSale

	The BloctoToken Public Sale contract is used for 
	BLT token public sale. Qualified purchasers
	can purchase with tUSDT (Teleported Tether) to get
	BLTs without lockup

 */

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import BloctoToken from "../0x0f9df91c9121c460/BloctoToken.cdc"

import TeleportedTetherToken from "../0xcfdd90d4a00f7b5b/TeleportedTetherToken.cdc"

access(all)
contract BloctoTokenPublicSale{ 
	/****** Sale Events ******/
	access(all)
	event NewPrice(price: UFix64)
	
	access(all)
	event NewPersonalCap(personalCap: UFix64)
	
	access(all)
	event Purchased(address: Address, amount: UFix64, ticketId: UInt64)
	
	access(all)
	event Distributed(address: Address, tusdtAmount: UFix64, bltAmount: UFix64)
	
	access(all)
	event Refunded(address: Address, amount: UFix64)
	
	/****** Sale Enums ******/
	access(all)
	enum PurchaseState: UInt8{ 
		access(all)
		case initial
		
		access(all)
		case distributed
		
		access(all)
		case refunded
	}
	
	/****** Sale Resources ******/
	// BLT holder vault
	access(contract)
	let bltVault: @BloctoToken.Vault
	
	// tUSDT holder vault
	access(contract)
	let tusdtVault: @TeleportedTetherToken.Vault
	
	/// Paths for storing sale resources
	access(all)
	let SaleAdminStoragePath: StoragePath
	
	/****** Sale Variables ******/
	access(contract)
	var isSaleActive: Bool
	
	// BLT token price (tUSDT per BLT)
	access(contract)
	var price: UFix64
	
	// BLT communitu sale purchase cap (in tUSDT)
	access(contract)
	var personalCap: UFix64
	
	// All purchase records
	access(contract)
	var purchases:{ Address: PurchaseInfo}
	
	// Workaround random number generator
	access(all)
	resource Random{} 
	
	access(all)
	struct PurchaseInfo{ 
		// Purchaser address
		access(all)
		let address: Address
		
		// Purchase amount in tUSDT
		access(all)
		var amount: UFix64
		
		// Refunded amount in tUSDT
		access(all)
		var refundAmount: UFix64
		
		// Random ticked ID
		access(all)
		let ticketId: UInt64
		
		// State of the purchase
		access(all)
		var state: PurchaseState
		
		init(address: Address, amount: UFix64){ 
			// Create random resource 
			let random <- create Random()
			let ticketId = random.uuid
			destroy random
			self.address = address
			self.amount = amount
			self.refundAmount = 0.0
			self.ticketId = ticketId % 1_073_741_824 // 2^30
			
			self.state = PurchaseState.initial
		}
	}
	
	// BLT purchase method
	// User pays tUSDT and get unlocked BloctoToken
	// Note that "address" can potentially be faked, but there's no incentive doing so
	access(all)
	fun purchase(from: @TeleportedTetherToken.Vault, address: Address){ 
		pre{ 
			self.isSaleActive:
				"Token sale is not active"
			self.purchases[address] == nil:
				"Already purchased by the same account"
			from.balance <= self.personalCap:
				"Purchase amount exceeds personal cap"
		}
		let amount = from.balance
		self.tusdtVault.deposit(from: <-from)
		let purchaseInfo = PurchaseInfo(address: address, amount: amount)
		self.purchases[address] = purchaseInfo
		emit Purchased(address: address, amount: amount, ticketId: purchaseInfo.ticketId)
	}
	
	access(all)
	fun getIsSaleActive(): Bool{ 
		return self.isSaleActive
	}
	
	// Get all purchaser addresses
	access(all)
	fun getPurchasers(): [Address]{ 
		return self.purchases.keys
	}
	
	// Get all purchase records
	access(all)
	fun getPurchases():{ Address: PurchaseInfo}{ 
		return self.purchases
	}
	
	// Get purchase record from an address
	access(all)
	fun getPurchase(address: Address): PurchaseInfo?{ 
		return self.purchases[address]
	}
	
	access(all)
	fun getBltVaultBalance(): UFix64{ 
		return self.bltVault.balance
	}
	
	access(all)
	fun getTusdtVaultBalance(): UFix64{ 
		return self.tusdtVault.balance
	}
	
	access(all)
	fun getPrice(): UFix64{ 
		return self.price
	}
	
	access(all)
	fun getPersonalCap(): UFix64{ 
		return self.personalCap
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun unfreeze(){ 
			BloctoTokenPublicSale.isSaleActive = true
		}
		
		access(all)
		fun freeze(){ 
			BloctoTokenPublicSale.isSaleActive = false
		}
		
		// Distribute BLT with an allocation amount
		// If user's purchase amount exceeds allocation amount, the remainder will be refunded
		access(all)
		fun distribute(address: Address, allocationAmount: UFix64){ 
			pre{ 
				BloctoTokenPublicSale.purchases[address] != nil:
					"Cannot find purchase record for the address"
				BloctoTokenPublicSale.purchases[address]?.state == PurchaseState.initial:
					"Already distributed or refunded"
			}
			let receiverRef =
				getAccount(address).capabilities.get<&{FungibleToken.Receiver}>(
					BloctoToken.TokenPublicReceiverPath
				).borrow<&{FungibleToken.Receiver}>()
				?? panic("Could not borrow BloctoToken receiver reference")
			let purchaseInfo =
				BloctoTokenPublicSale.purchases[address]
				?? panic("Count not get purchase info for the address")
			
			// Make sure allocation amount does not exceed purchase amount
			assert(
				allocationAmount <= purchaseInfo.amount,
				message: "Allocation amount exceeds purchase amount"
			)
			let refundAmount = purchaseInfo.amount - allocationAmount
			let bltAmount = allocationAmount / BloctoTokenPublicSale.price
			let bltVault <- BloctoTokenPublicSale.bltVault.withdraw(amount: bltAmount)
			
			// Set the state of the purchase to DISTRIBUTED
			purchaseInfo.state = PurchaseState.distributed
			purchaseInfo.amount = allocationAmount
			purchaseInfo.refundAmount = refundAmount
			BloctoTokenPublicSale.purchases[address] = purchaseInfo
			
			// Deposit the withdrawn tokens in the recipient's receiver
			receiverRef.deposit(from: <-bltVault)
			emit Distributed(address: address, tusdtAmount: allocationAmount, bltAmount: bltAmount)
			
			// Refund the remaining amount
			if refundAmount > 0.0{ 
				let tUSDTReceiverRef = getAccount(address).capabilities.get<&{FungibleToken.Receiver}>(TeleportedTetherToken.TokenPublicReceiverPath).borrow<&{FungibleToken.Receiver}>() ?? panic("Could not borrow tUSDT vault receiver public reference")
				let tusdtVault <- BloctoTokenPublicSale.tusdtVault.withdraw(amount: refundAmount)
				tUSDTReceiverRef.deposit(from: <-tusdtVault)
				emit Refunded(address: address, amount: refundAmount)
			}
		}
		
		access(all)
		fun refund(address: Address){ 
			pre{ 
				BloctoTokenPublicSale.purchases[address] != nil:
					"Cannot find purchase record for the address"
				BloctoTokenPublicSale.purchases[address]?.state == PurchaseState.initial:
					"Already distributed or refunded"
			}
			let receiverRef =
				getAccount(address).capabilities.get<&{FungibleToken.Receiver}>(
					TeleportedTetherToken.TokenPublicReceiverPath
				).borrow<&{FungibleToken.Receiver}>()
				?? panic("Could not borrow tUSDT vault receiver public reference")
			let purchaseInfo =
				BloctoTokenPublicSale.purchases[address]
				?? panic("Count not get purchase info for the address")
			let tusdtVault <- BloctoTokenPublicSale.tusdtVault.withdraw(amount: purchaseInfo.amount)
			
			// Set the state of the purchase to REFUNDED
			purchaseInfo.state = PurchaseState.refunded
			BloctoTokenPublicSale.purchases[address] = purchaseInfo
			receiverRef.deposit(from: <-tusdtVault)
			emit Refunded(address: address, amount: purchaseInfo.amount)
		}
		
		access(all)
		fun updatePrice(price: UFix64){ 
			pre{ 
				price > 0.0:
					"Sale price cannot be 0"
			}
			BloctoTokenPublicSale.price = price
			emit NewPrice(price: price)
		}
		
		access(all)
		fun updatePersonalCap(personalCap: UFix64){ 
			BloctoTokenPublicSale.personalCap = personalCap
			emit NewPersonalCap(personalCap: personalCap)
		}
		
		access(all)
		fun withdrawBlt(amount: UFix64): @{FungibleToken.Vault}{ 
			return <-BloctoTokenPublicSale.bltVault.withdraw(amount: amount)
		}
		
		access(all)
		fun withdrawTusdt(amount: UFix64): @{FungibleToken.Vault}{ 
			return <-BloctoTokenPublicSale.tusdtVault.withdraw(amount: amount)
		}
		
		access(all)
		fun depositBlt(from: @{FungibleToken.Vault}){ 
			BloctoTokenPublicSale.bltVault.deposit(from: <-from)
		}
		
		access(all)
		fun depositTusdt(from: @{FungibleToken.Vault}){ 
			BloctoTokenPublicSale.tusdtVault.deposit(from: <-from)
		}
	}
	
	init(){ 
		// Needs Admin to start manually
		self.isSaleActive = false
		
		// 1 BLT = 0.4 tUSDT
		self.price = 0.4
		
		// Each user can purchase at most 500 tUSDT worth of BLT
		self.personalCap = 500.0
		self.purchases ={} 
		self.SaleAdminStoragePath = /storage/bloctoTokenPublicSaleAdmin
		self.bltVault <- BloctoToken.createEmptyVault(vaultType: Type<@BloctoToken.Vault>())
			as!
			@BloctoToken.Vault
		self.tusdtVault <- TeleportedTetherToken.createEmptyVault(
				vaultType: Type<@TeleportedTetherToken.Vault>()
			)
			as!
			@TeleportedTetherToken.Vault
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.SaleAdminStoragePath)
	}
}
