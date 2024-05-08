/**
> Author: FIXeS World <https://fixes.world/>

# FGameLotteryFactory

This contract contains the factory for creating new Lottery Pool.

*/

import FlowToken from "./../../standardsV1/FlowToken.cdc"

// Fixes Imports
import Fixes from "./Fixes.cdc"

import FixesInscriptionFactory from "./FixesInscriptionFactory.cdc"

import FRC20FTShared from "./FRC20FTShared.cdc"

import FRC20Indexer from "./FRC20Indexer.cdc"

import FGameLottery from "./FGameLottery.cdc"

import FGameLotteryRegistry from "./FGameLotteryRegistry.cdc"

access(all)
contract FGameLotteryFactory{ 
	/* --- Public Methods - Controller --- */
	access(all)
	view fun getFIXESLotteryPoolName(): String{ 
		return "FIXES_BASIS_LOTTERY_POOL"
	}
	
	access(all)
	view fun getFIXESMintingLotteryPoolName(): String{ 
		return "FIXES_MINTING_LOTTERY_POOL"
	}
	
	/// Initialize the $FIXES Lottery Pool
	/// This pool is for directly paying $FIXES to purchase lottery tickets.
	///
	access(all)
	fun initializeFIXESLotteryPool(
		_ controller: &FGameLotteryRegistry.RegistryController,
		newAccount: Capability<&AuthAccount>
	){ 
		// initialize with 3 days
		let epochInterval: UFix64 = UFix64(3 * 24 * 60 * 60) // 3 days
		
		self._initializeLotteryPool(
			controller,
			name: self.getFIXESLotteryPoolName(),
			rewardTick: "fixes",
			ticketPrice: FixesInscriptionFactory.estimateLotteryFIXESTicketsCost(1, nil),
			epochInterval: epochInterval,
			newAccount: newAccount
		)
	}
	
	/// Initialize the $FIXES Minting Lottery Pool
	/// This pool pays 1 $FLOW each time, while minting $FIXES x 4. The excess FLOW is used to purchase lottery tickets.
	///
	access(all)
	fun initializeFIXESMintingLotteryPool(
		_ controller: &FGameLotteryRegistry.RegistryController,
		newAccount: Capability<&AuthAccount>
	){ 
		// initialize with 3 days
		let epochInterval: UFix64 = UFix64(3 * 24 * 60 * 60) // 3 days
		
		// let epochInterval: UFix64 = UFix64(2 * 60) // 2 min
		let rewardTick: String = "" // empty string means $FLOW
		
		let fixesMintingStr = FixesInscriptionFactory.buildMintFRC20(tick: "fixes", amt: 1000.0)
		var estimateMintingCost = FixesInscriptionFactory.estimateFrc20InsribeCost(fixesMintingStr)
		assert(estimateMintingCost < 0.25, message: "Minting cost is too high")
		// ensure the minting cost is at least 0.2
		if estimateMintingCost < 0.2{ 
			estimateMintingCost = 0.21630 // the minting price on mainnet
		
		}
		var ticketPrice: UFix64 = 1.0 - 4.0 * estimateMintingCost // ticket price = 1.0 - 4 x $FIXES minting price
		
		self._initializeLotteryPool(
			controller,
			name: self.getFIXESMintingLotteryPoolName(),
			rewardTick: rewardTick,
			ticketPrice: ticketPrice,
			epochInterval: epochInterval,
			newAccount: newAccount
		)
	}
	
	/// Genereal initialize the Lottery Pool
	///
	access(contract)
	fun _initializeLotteryPool(
		_ controller: &FGameLotteryRegistry.RegistryController,
		name: String,
		rewardTick: String,
		ticketPrice: UFix64,
		epochInterval: UFix64,
		newAccount: Capability<&AuthAccount>
	){ 
		let registry = FGameLotteryRegistry.borrowRegistry()
		assert(
			registry.getLotteryPoolAddress(name) == nil,
			message: "Lottery pool name is not available"
		)
		// Create the Lottery Pool
		controller.createLotteryPool(
			name: name,
			rewardTick: rewardTick,
			ticketPrice: ticketPrice,
			epochInterval: epochInterval,
			newAccount: newAccount
		)
	}
	
	/* --- Public methods - User --- */
	/// PowerUp Types
	///
	access(all)
	enum PowerUpType: UInt8{ 
		access(all)
		case x1
		
		access(all)
		case x2
		
		access(all)
		case x3
		
		access(all)
		case x4
		
		access(all)
		case x5
		
		access(all)
		case x10
	}
	
	/// Get the value of the PowerUp
	///
	access(all)
	view fun getPowerUpValue(_ type: PowerUpType): UFix64{ 
		switch type{ 
			case PowerUpType.x2:
				return 2.0
			case PowerUpType.x3:
				return 3.0
			case PowerUpType.x4:
				return 4.0
			case PowerUpType.x5:
				return 5.0
			case PowerUpType.x10:
				return 10.0
		}
		// Default is x1
		return 1.0
	}
	
	/// Check if the FIXES Minting is available
	///
	access(all)
	view fun isFIXESMintingAvailable(): Bool{ 
		// Singleton Resource
		let frc20Indexer = FRC20Indexer.getIndexer()
		if let tokenMeta = frc20Indexer.getTokenMeta(tick: "fixes"){ 
			return tokenMeta.max > tokenMeta.supplied
		}
		return false
	}
	
	/// Get the cost of buying FIXES Minting Lottery Tickets
	///
	access(all)
	view fun getFIXESMintingLotteryFlowCost(
		_ ticketAmount: UInt64,
		_ powerup: PowerUpType,
		_ withMinting: Bool
	): UFix64{ 
		let powerupValue: UFix64 = self.getPowerUpValue(powerup)
		// singleton resource
		let registry = FGameLotteryRegistry.borrowRegistry()
		// Ticket info
		let poolName = self.getFIXESMintingLotteryPoolName()
		let lotteryPoolAddr =
			registry.getLotteryPoolAddress(poolName) ?? panic("Lottery pool not found")
		let lotteryPoolRef =
			FGameLottery.borrowLotteryPool(lotteryPoolAddr) ?? panic("Lottery pool not found")
		let ticketPrice = lotteryPoolRef.getTicketPrice()
		if self.isFIXESMintingAvailable() && withMinting{ 
			return 1.0 * UFix64(ticketAmount) * powerupValue
		} else{ 
			return ticketPrice * UFix64(ticketAmount) * powerupValue
		}
	}
	
	/// Use $FLOW to buy FIXES Minting Lottery Tickets
	/// Return the inscription ids of the minting transactions
	///
	access(all)
	fun buyFIXESMintingLottery(
		flowVault: @FlowToken.Vault,
		ticketAmount: UInt64,
		powerup: PowerUpType,
		withMinting: Bool,
		recipient: Capability<&FGameLottery.TicketCollection>,
		inscriptionStore: &Fixes.InscriptionsStore
	): @FlowToken.Vault{ 
		pre{ 
			recipient.address == inscriptionStore.owner?.address:
				"Recipient must be the owner of the inscription store"
		}
		
		// Singleton Resource
		let frc20Indexer = FRC20Indexer.getIndexer()
		let registry = FGameLotteryRegistry.borrowRegistry()
		
		// check if the FLOW balance is sufficient
		let powerupValue: UFix64 = self.getPowerUpValue(powerup)
		
		// Ticket info
		let poolName = self.getFIXESMintingLotteryPoolName()
		let lotteryPoolAddr =
			registry.getLotteryPoolAddress(poolName) ?? panic("Lottery pool not found")
		let lotteryPoolRef =
			FGameLottery.borrowLotteryPool(lotteryPoolAddr) ?? panic("Lottery pool not found")
		let ticketPrice = lotteryPoolRef.getTicketPrice()
		let ticketsPayment = ticketPrice * UFix64(ticketAmount) * powerupValue
		// check if the FLOW balance is sufficient
		assert(flowVault.balance >= ticketsPayment, message: "Insufficient FLOW balance")
		
		// for minting available
		if withMinting && self.isFIXESMintingAvailable(){ 
			let totalCost: UFix64 = 1.0 * UFix64(ticketAmount) * powerupValue
			log("Total cost: ".concat(totalCost.toString()))
			assert(flowVault.balance >= totalCost, message: "Insufficient FLOW balance")
			
			// check if the total mint amount is valid
			let totalMintAmount = ticketAmount * UInt64(powerupValue) * 4
			log("Total Mints: ".concat(totalMintAmount.toString()))
			assert(totalMintAmount > 0 && totalMintAmount <= 120, message: "Total mint amount must be between 1 and 120")
			
			// Mint $FIXES information
			let fixesMeta = frc20Indexer.getTokenMeta(tick: "fixes") ?? panic("FIXES Token meta not found")
			let fixesMintingStr = FixesInscriptionFactory.buildMintFRC20(tick: "fixes", amt: fixesMeta.limit)
			var i: UInt64 = 0
			while i < totalMintAmount && self.isFIXESMintingAvailable(){ 
				// required $FLOW per mint
				let estimatedReqValue = FixesInscriptionFactory.estimateFrc20InsribeCost(fixesMintingStr)
				let costReserve <- flowVault.withdraw(amount: estimatedReqValue)
				// create minting $FIXES inscription and store it
				let insId = FixesInscriptionFactory.createAndStoreFrc20Inscription(fixesMintingStr, <-(costReserve as! @FlowToken.Vault), inscriptionStore)
				// apply the minting $FIXES inscription
				let insRef = inscriptionStore.borrowInscriptionWritableRef(insId)!
				frc20Indexer.mint(ins: insRef)
				// next
				i = i + 1
			}
		}
		
		// wrap the inscription change
		let change <-
			FRC20FTShared.wrapFungibleVaultChange(
				ftVault: <-flowVault.withdraw(amount: ticketsPayment),
				from: recipient.address
			)
		// buy the tickets
		lotteryPoolRef.buyTickets(
			// withdraw flow token from the vault
			payment: <-change,
			amount: ticketAmount,
			powerup: powerupValue,
			recipient: recipient
		)
		
		// return the remaining FLOW
		return <-flowVault
	}
	
	/// Get the cost of buying FIXES Lottery Tickets
	///
	access(all)
	view fun getFIXESLotteryFlowCost(
		_ ticketAmount: UInt64,
		_ powerup: PowerUpType,
		_ recipient: Address
	): UFix64{ 
		// check if the FLOW balance is sufficient
		let ticketPrice = FixesInscriptionFactory.estimateLotteryFIXESTicketsCost(1, nil)
		let powerupValue: UFix64 = self.getPowerUpValue(powerup)
		let ticketsPayment: UFix64 = ticketPrice * UFix64(ticketAmount) * powerupValue
		var requiredFlow: UFix64 =
			FixesInscriptionFactory.estimateFrc20InsribeCost(
				FixesInscriptionFactory.buildLotteryBuyFIXESTickets(ticketAmount, powerupValue)
			)
		
		// Singleton Resource
		let frc20Indexer = FRC20Indexer.getIndexer()
		
		// Mint $FIXES information
		let fixesMeta =
			frc20Indexer.getTokenMeta(tick: "fixes") ?? panic("FIXES Token meta not found")
		let fixesMintingStr =
			FixesInscriptionFactory.buildMintFRC20(tick: "fixes", amt: fixesMeta.limit)
		
		// check balance of the $FIXES token if it is sufficient to buy the tickets
		let balance = frc20Indexer.getBalance(tick: "fixes", addr: recipient)
		// ensure the balance is sufficient
		if balance < ticketsPayment{ 
			// mint enough $FIXES to buy the tickets
			let totalMintAmount = UInt64((ticketsPayment - balance) / fixesMeta.limit) + 1
			requiredFlow = requiredFlow + UFix64(totalMintAmount) * FixesInscriptionFactory.estimateFrc20InsribeCost(fixesMintingStr)
		}
		return requiredFlow
	}
	
	/// Use $FIXES to buy FIXES Lottery Tickets
	///
	access(all)
	fun buyFIXESLottery(
		flowVault: @FlowToken.Vault,
		ticketAmount: UInt64,
		powerup: PowerUpType,
		recipient: Capability<&FGameLottery.TicketCollection>,
		inscriptionStore: &Fixes.InscriptionsStore
	): @FlowToken.Vault{ 
		pre{ 
			recipient.address == inscriptionStore.owner?.address:
				"Recipient must be the owner of the inscription store"
		}
		
		// Singleton Resource
		let frc20Indexer = FRC20Indexer.getIndexer()
		let registry = FGameLotteryRegistry.borrowRegistry()
		
		// the recipient address
		let recipientAddr = recipient.address
		
		// lottery pool
		let poolName = self.getFIXESLotteryPoolName()
		let lotteryPoolAddr =
			registry.getLotteryPoolAddress(poolName) ?? panic("Lottery pool not found")
		let lotteryPoolRef =
			FGameLottery.borrowLotteryPool(lotteryPoolAddr) ?? panic("Lottery pool not found")
		let ticketPrice = lotteryPoolRef.getTicketPrice()
		
		// check if the FLOW balance is sufficient
		let powerupValue: UFix64 = self.getPowerUpValue(powerup)
		let ticketsPayment: UFix64 = ticketPrice * UFix64(ticketAmount) * powerupValue
		
		// Mint $FIXES information
		let fixesMeta =
			frc20Indexer.getTokenMeta(tick: "fixes") ?? panic("FIXES Token meta not found")
		let fixesMintingStr =
			FixesInscriptionFactory.buildMintFRC20(tick: "fixes", amt: fixesMeta.limit)
		
		// check balance of the $FIXES token if it is sufficient to buy the tickets
		var balance = frc20Indexer.getBalance(tick: "fixes", addr: recipientAddr)
		// ensure the balance is sufficient
		if balance < ticketsPayment{ 
			// mint enough $FIXES to buy the tickets
			let totalMintAmount = UInt64((ticketsPayment - balance) / fixesMeta.limit) + 1
			var i: UInt64 = 0
			while i < totalMintAmount && self.isFIXESMintingAvailable(){ 
				// required $FLOW per mint
				let estimatedReqValue = FixesInscriptionFactory.estimateFrc20InsribeCost(fixesMintingStr)
				let costReserve <- flowVault.withdraw(amount: estimatedReqValue)
				// create minting $FIXES inscription and store it
				let insId = FixesInscriptionFactory.createAndStoreFrc20Inscription(fixesMintingStr, <-(costReserve as! @FlowToken.Vault), inscriptionStore)
				// apply the inscription
				let insRef = inscriptionStore.borrowInscriptionWritableRef(insId)!
				frc20Indexer.mint(ins: insRef)
				// next
				i = i + 1
			}
		} // end if
		
		
		// check current balance
		balance = frc20Indexer.getBalance(tick: "fixes", addr: recipientAddr)
		var ticketAmountFinal = ticketAmount
		if ticketsPayment > balance{ 
			ticketAmountFinal = UInt64(balance / (ticketPrice * powerupValue))
		}
		assert(ticketAmountFinal > 0, message: "Insufficient $FIXES balance")
		
		// build the inscription string
		let buyTicketsInsStr =
			FixesInscriptionFactory.buildLotteryBuyFIXESTickets(ticketAmountFinal, powerupValue)
		let estimatedBuyTicketsInsCost =
			FixesInscriptionFactory.estimateFrc20InsribeCost(buyTicketsInsStr)
		let costReserve <- flowVault.withdraw(amount: estimatedBuyTicketsInsCost)
		// create the withdraw inscription
		let insId =
			FixesInscriptionFactory.createAndStoreFrc20Inscription(
				buyTicketsInsStr,
				<-(costReserve as! @FlowToken.Vault),
				inscriptionStore
			)
		// apply the inscription
		let insRef = inscriptionStore.borrowInscriptionWritableRef(insId)!
		// withdraw the $FIXES from the recipient
		let change <- frc20Indexer.withdrawChange(ins: insRef)
		
		// buy the tickets
		lotteryPoolRef.buyTickets(
			// withdraw flow token from the vault
			payment: <-change,
			amount: ticketAmountFinal,
			powerup: powerupValue,
			recipient: recipient
		)
		// return the remaining FLOW
		return <-flowVault
	}
}
