/*

	BloctoTokenSale

	The BloctoToken Sale contract is used for 
	BLT token community sale. Qualified purchasers
	can purchase with tUSDT (Teleported Tether) to get
	BLTs at the same price and lock-up terms as private sale

 */

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import BloctoToken from "./BloctoToken.cdc"

import BloctoPass from "./BloctoPass.cdc"

import TeleportedTetherToken from "../0xcfdd90d4a00f7b5b/TeleportedTetherToken.cdc"

access(all)
contract BloctoTokenSale{ 
	/****** Sale Events ******/
	access(all)
	event NewPrice(price: UFix64)
	
	access(all)
	event NewLockupSchedule(lockupSchedule:{ UFix64: UFix64})
	
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
	
	// BLT lockup schedule, used for lockup terms
	access(contract)
	var lockupScheduleId: Int
	
	// BLT communitu sale purchase cap (in tUSDT)
	access(contract)
	var personalCap: UFix64
	
	// All purchase records
	access(contract)
	var purchases:{ Address: PurchaseInfo}
	
	access(all)
	struct PurchaseInfo{ 
		// Purchaser address
		access(all)
		let address: Address
		
		// Purchase amount in tUSDT
		access(all)
		let amount: UFix64
		
		// Random ticked ID
		access(all)
		let ticketId: UInt64
		
		// State of the purchase
		access(all)
		var state: PurchaseState
		
		init(address: Address, amount: UFix64){ 
			self.address = address
			self.amount = amount
			self.ticketId = revertibleRandom<UInt64>() % 1_000_000_000
			self.state = PurchaseState.initial
		}
	}
	
	// BLT purchase method
	// User pays tUSDT and get a BloctoPass NFT with lockup terms
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
		let collectionRef =
			getAccount(address).capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				BloctoPass.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>()
			?? panic("Could not borrow blocto pass collection public reference")
		
		// Make sure user does not already have a BloctoPass
		assert(collectionRef.getIDs().length == 0, message: "User already has a BloctoPass")
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
	fun getLockupSchedule():{ UFix64: UFix64}{ 
		return BloctoPass.getPredefinedLockupSchedule(id: self.lockupScheduleId)
	}
	
	access(all)
	fun getPersonalCap(): UFix64{ 
		return self.personalCap
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun unfreeze(){ 
			BloctoTokenSale.isSaleActive = true
		}
		
		access(all)
		fun freeze(){ 
			BloctoTokenSale.isSaleActive = false
		}
		
		access(all)
		fun distribute(address: Address){ 
			pre{ 
				BloctoTokenSale.purchases[address] != nil:
					"Cannot find purchase record for the address"
				BloctoTokenSale.purchases[address]?.state == PurchaseState.initial:
					"Already distributed or refunded"
			}
			let collectionRef =
				getAccount(address).capabilities.get<&{NonFungibleToken.CollectionPublic}>(
					BloctoPass.CollectionPublicPath
				).borrow<&{NonFungibleToken.CollectionPublic}>()
				?? panic("Could not borrow blocto pass collection public reference")
			
			// Make sure user does not already have a BloctoPass
			assert(collectionRef.getIDs().length == 0, message: "User already has a BloctoPass")
			let purchaseInfo =
				BloctoTokenSale.purchases[address]
				?? panic("Count not get purchase info for the address")
			let minterRef =
				BloctoTokenSale.account.storage.borrow<&BloctoPass.NFTMinter>(
					from: BloctoPass.MinterStoragePath
				)
				?? panic("Could not borrow reference to the BloctoPass minter!")
			let bltAmount = purchaseInfo.amount / BloctoTokenSale.price
			let bltVault <- BloctoTokenSale.bltVault.withdraw(amount: bltAmount)
			let metadata ={ "origin": "Community Sale"}
			
			// Lockup schedule for community sale:
			// let lockupSchedule = {
			//	 0.0					  : 1.0,
			//	 saleDate				 : 1.0,
			//	 saleDate + 6.0 * months  : 17.0 / 18.0,
			//	 saleDate + 7.0 * months  : 16.0 / 18.0,
			//	 saleDate + 8.0 * months  : 15.0 / 18.0,
			//	 saleDate + 9.0 * months  : 14.0 / 18.0,
			//	 saleDate + 10.0 * months : 13.0 / 18.0,
			//	 saleDate + 11.0 * months : 12.0 / 18.0,
			//	 saleDate + 12.0 * months : 11.0 / 18.0,
			//	 saleDate + 13.0 * months : 10.0 / 18.0,
			//	 saleDate + 14.0 * months : 9.0 / 18.0,
			//	 saleDate + 15.0 * months : 8.0 / 18.0,
			//	 saleDate + 16.0 * months : 7.0 / 18.0,
			//	 saleDate + 17.0 * months : 6.0 / 18.0,
			//	 saleDate + 18.0 * months : 5.0 / 18.0,
			//	 saleDate + 19.0 * months : 4.0 / 18.0,
			//	 saleDate + 20.0 * months : 3.0 / 18.0,
			//	 saleDate + 21.0 * months : 2.0 / 18.0,
			//	 saleDate + 22.0 * months : 1.0 / 18.0,
			//	 saleDate + 23.0 * months : 0.0
			// }
			
			// Set the state of the purchase to DISTRIBUTED
			purchaseInfo.state = PurchaseState.distributed
			BloctoTokenSale.purchases[address] = purchaseInfo
			minterRef.mintNFTWithPredefinedLockup(
				recipient: collectionRef,
				metadata: metadata,
				vault: <-bltVault,
				lockupScheduleId: BloctoTokenSale.lockupScheduleId
			)
			emit Distributed(
				address: address,
				tusdtAmount: purchaseInfo.amount,
				bltAmount: bltAmount
			)
		}
		
		access(all)
		fun refund(address: Address){ 
			pre{ 
				BloctoTokenSale.purchases[address] != nil:
					"Cannot find purchase record for the address"
				BloctoTokenSale.purchases[address]?.state == PurchaseState.initial:
					"Already distributed or refunded"
			}
			let receiverRef =
				getAccount(address).capabilities.get<&{FungibleToken.Receiver}>(
					TeleportedTetherToken.TokenPublicReceiverPath
				).borrow<&{FungibleToken.Receiver}>()
				?? panic("Could not borrow tUSDT vault receiver public reference")
			let purchaseInfo =
				BloctoTokenSale.purchases[address]
				?? panic("Count not get purchase info for the address")
			let tusdtVault <- BloctoTokenSale.tusdtVault.withdraw(amount: purchaseInfo.amount)
			
			// Set the state of the purchase to REFUNDED
			purchaseInfo.state = PurchaseState.refunded
			BloctoTokenSale.purchases[address] = purchaseInfo
			receiverRef.deposit(from: <-tusdtVault)
			emit Refunded(address: address, amount: purchaseInfo.amount)
		}
		
		access(all)
		fun updatePrice(price: UFix64){ 
			pre{ 
				price > 0.0:
					"Sale price cannot be 0"
			}
			BloctoTokenSale.price = price
			emit NewPrice(price: price)
		}
		
		access(all)
		fun updateLockupScheduleId(lockupScheduleId: Int){ 
			BloctoTokenSale.lockupScheduleId = lockupScheduleId
			emit NewLockupSchedule(
				lockupSchedule: BloctoPass.getPredefinedLockupSchedule(id: lockupScheduleId)
			)
		}
		
		access(all)
		fun updatePersonalCap(personalCap: UFix64){ 
			BloctoTokenSale.personalCap = personalCap
			emit NewPersonalCap(personalCap: personalCap)
		}
		
		access(all)
		fun withdrawBlt(amount: UFix64): @{FungibleToken.Vault}{ 
			return <-BloctoTokenSale.bltVault.withdraw(amount: amount)
		}
		
		access(all)
		fun withdrawTusdt(amount: UFix64): @{FungibleToken.Vault}{ 
			return <-BloctoTokenSale.tusdtVault.withdraw(amount: amount)
		}
		
		access(all)
		fun depositBlt(from: @{FungibleToken.Vault}){ 
			BloctoTokenSale.bltVault.deposit(from: <-from)
		}
		
		access(all)
		fun depositTusdt(from: @{FungibleToken.Vault}){ 
			BloctoTokenSale.tusdtVault.deposit(from: <-from)
		}
	}
	
	init(){ 
		// Needs Admin to start manually
		self.isSaleActive = false
		
		// 1 BLT = 0.1 tUSDT
		self.price = 0.1
		
		// Refer to BloctoPass contract
		self.lockupScheduleId = 0
		
		// Each user can purchase at most 1000 tUSDT worth of BLT
		self.personalCap = 1000.0
		self.purchases ={} 
		self.SaleAdminStoragePath = /storage/bloctoTokenSaleAdmin
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
