/*
	ListenAuction 
	Author: Flowstarter
	Auction Resource represents an Auction and is always held internally by the contract
	Admin resource is required to create Auctions
 */

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ListenNFT from "./ListenNFT.cdc"

import ListenUSD from "./ListenUSD.cdc"

access(all)
contract ListenAuction{ 
	access(contract)
	var nextID: UInt64 // internal ticker for auctionIDs
	
	
	access(contract)
	var auctions: @{UInt64: Auction} // Dictionary of Auctions in existence
	
	
	access(contract)
	var EXTENSION_TIME: UFix64 // Currently globally set for all running auctions, consider refactoring to per auction basis for flexibility
	
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminCapabilityPath: CapabilityPath
	
	access(all)
	event ContractDeployed()
	
	access(all)
	event AuctionCreated(
		auctionID: UInt64,
		startTime: UFix64,
		endTime: UFix64,
		startingPrice: UFix64,
		bidStep: UFix64,
		prizeIDs: [
			UInt64
		]
	)
	
	access(all)
	event BidPlaced(auctionID: UInt64, bidder: Address, amount: UFix64)
	
	access(all)
	event AuctionExtended(auctionID: UInt64, endTime: UFix64)
	
	access(all)
	event AuctionSettled(id: UInt64, winnersAddress: Address, finalSalePrice: UFix64)
	
	access(all)
	event AuctionRemoved(auctionID: UInt64)
	
	access(all)
	resource Auction{ 
		access(contract)
		let startingPrice: UFix64
		
		access(contract)
		var bidStep: UFix64 // New bids must be at least bidStep greater than current highest bid
		
		
		access(contract)
		let startTime: UFix64
		
		access(contract)
		var nftCollection: @ListenNFT.Collection
		
		access(contract)
		var endTime: UFix64 // variable as can be extended if there is a bid in last 30min
		
		
		access(contract)
		var bid: @Bid
		
		access(contract)
		var history: [History]
		
		init(
			startTime: UFix64,
			endTime: UFix64,
			startingPrice: UFix64,
			bidStep: UFix64,
			nftCollection: @ListenNFT.Collection
		){ 
			self.startTime = startTime
			self.endTime = endTime
			self.startingPrice = startingPrice
			self.bidStep = bidStep
			self.nftCollection <- nftCollection
			self.bid <- create Bid(
					funds: <-ListenUSD.createEmptyVault(vaultType: Type<@ListenUSD.Vault>()),
					ftReceiverCap: nil,
					nftReceiverCap: nil
				)
			self.history = []
		}
		
		access(contract)
		fun extendAuction(){ 
			self.endTime = self.endTime + ListenAuction.EXTENSION_TIME
		}
		
		access(contract)
		fun placeBid(bid: @ListenAuction.Bid){ 
			var temp <- bid // new bid in temp variable
			
			self.bid <-> temp // swap temp with self.bid
			
			destroy temp
		}
		
		access(contract)
		fun updateHistory(history: History){ 
			self.history.append(history)
		}
		
		access(contract)
		fun getHistory(): [History]{ 
			return self.history
		}
		
		access(contract)
		fun updateBidStep(_ bidStep: UFix64){ 
			pre{ 
				bidStep != self.bidStep:
					"Bid step already set"
				!self.auctionHasStarted():
					"Bid step cannot be changed once auction has started"
			}
			self.bidStep = bidStep
		}
		
		access(all)
		fun hasBids(): Bool{ 
			return self.bid.ftReceiverCap != nil
		}
		
		access(all)
		view fun auctionHasStarted(): Bool{ 
			return ListenAuction.now() >= self.startTime
		}
		
		access(all)
		fun getAuctionState(): AuctionState{ 
			let currentTime = ListenAuction.now()
			if currentTime < self.startTime{ 
				return AuctionState.Upcoming
			}
			if currentTime >= self.endTime{ 
				return AuctionState.Complete
			}
			if currentTime < self.endTime - ListenAuction.EXTENSION_TIME{ 
				return AuctionState.Open
			}
			return AuctionState.Closing
		}
	}
	
	access(all)
	struct History{ 
		access(all)
		let auctionID: UInt64
		
		access(all)
		let amount: UFix64
		
		access(all)
		let time: UFix64
		
		access(all)
		let bidderAddress: String
		
		init(auctionID: UInt64, amount: UFix64, time: UFix64, bidderAddress: String){ 
			self.auctionID = auctionID
			self.amount = amount
			self.time = time
			self.bidderAddress = bidderAddress
		}
	}
	
	access(all)
	resource Bid{ 
		access(all)
		var vault: @ListenUSD.Vault
		
		access(all)
		var ftReceiverCap: Capability?
		
		access(all)
		var nftReceiverCap: Capability?
		
		init(funds: @ListenUSD.Vault, ftReceiverCap: Capability?, nftReceiverCap: Capability?){ 
			self.vault <- funds
			self.ftReceiverCap = ftReceiverCap
			self.nftReceiverCap = nftReceiverCap
		}
		
		access(contract)
		fun returnBidToOwner(){ 
			let ftReceiverCap = self.ftReceiverCap!
			var ownersVaultRef = ftReceiverCap.borrow<&{FungibleToken.Receiver}>()!
			let funds <- self.vault.withdraw(amount: self.vault.balance)
			ownersVaultRef.deposit(from: <-funds)
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun createAuction(
			startTime: UFix64,
			duration: UFix64,
			startingPrice: UFix64,
			bidStep: UFix64,
			nftCollection: @ListenNFT.Collection
		){ 
			var auction <-
				create Auction(
					startTime: startTime,
					endTime: startTime + duration,
					startingPrice: startingPrice,
					bidStep: bidStep,
					nftCollection: <-nftCollection
				)
			emit AuctionCreated(
				auctionID: ListenAuction.nextID,
				startTime: auction.startTime,
				endTime: auction.endTime,
				startingPrice: auction.startingPrice,
				bidStep: auction.bidStep,
				prizeIDs: auction.nftCollection.getIDs()
			)
			let temp <- ListenAuction.auctions.insert(key: ListenAuction.nextID, <-auction)
			destroy temp
			ListenAuction.nextID = ListenAuction.nextID + 1
		}
		
		access(all)
		fun removeAuction(auctionID: UInt64){ 
			let auctionRef =
				ListenAuction.borrowAuction(id: auctionID) ?? panic("Auction ID does not exist")
			let bidRef = auctionRef.bid as &ListenAuction.Bid
			assert(bidRef.vault.balance == 0.0, message: "Auction still has a bid, can't remove")
			for id in auctionRef.nftCollection.getIDs(){ 
				let nft <- auctionRef.nftCollection.withdraw(withdrawID: id)
				destroy nft
			}
			let auction <- ListenAuction.auctions.remove(key: auctionID)
			destroy auction
			emit AuctionRemoved(auctionID: auctionID)
		}
		
		access(all)
		fun updateExtensionTime(duration: UFix64){ 
			pre{ 
				ListenAuction.auctions.keys.length == 0:
					"Must be no active auctions to update rules"
			}
			ListenAuction.EXTENSION_TIME = duration
		}
		
		access(all)
		fun settleAuction(auctionID: UInt64){ 
			let auctionRef = ListenAuction.borrowAuction(id: auctionID)!
			let bidRef = auctionRef.bid as &ListenAuction.Bid
			assert(
				ListenAuction.now() >= auctionRef.endTime,
				message: "Auction must be finished to settle"
			)
			assert(bidRef.vault.balance > 0.0, message: "Auction must have a bid")
			let winnerNFTcap = &bidRef.nftReceiverCap! as &Capability
			let winnersReceiverRef = winnerNFTcap.borrow<&{NonFungibleToken.CollectionPublic}>()!
			for id in auctionRef.nftCollection.getIDs(){ 
				let nft <- auctionRef.nftCollection.withdraw(withdrawID: id)
				winnersReceiverRef.deposit(token: <-nft)
			}
			let finalSalePrice = bidRef.vault.balance
			let funds <- bidRef.vault.withdraw(amount: finalSalePrice)
			let ftReceiverCap =
				ListenAuction.account.capabilities.get_<YOUR_TYPE>(ListenUSD.ReceiverPublicPath)
			let vaultRef = ftReceiverCap.borrow<&{FungibleToken.Receiver}>()!
			vaultRef.deposit(from: <-funds)
			let auction <- ListenAuction.auctions.remove(key: auctionID)
			destroy auction
			emit AuctionSettled(
				id: auctionID,
				winnersAddress: winnerNFTcap.address,
				finalSalePrice: finalSalePrice
			)
		}
	}
	
	access(all)
	struct AuctionMeta{ 
		access(all)
		let auctionID: UInt64
		
		access(all)
		let startTime: UFix64
		
		access(all)
		let endTime: UFix64
		
		access(all)
		let startingPrice: UFix64
		
		access(all)
		let bidStep: UFix64
		
		access(all)
		let nftIDs: [UInt64]
		
		access(all)
		let nftCollection: [{String: String}]
		
		access(all)
		let currentBid: UFix64
		
		access(all)
		let auctionState: String
		
		access(all)
		let history: [History]
		
		init(
			auctionID: UInt64,
			startTime: UFix64,
			endTime: UFix64,
			startingPrice: UFix64,
			bidStep: UFix64,
			nftIDs: [
				UInt64
			],
			nftCollection: [{
				
					String: String
				}
			],
			currentBid: UFix64,
			auctionState: String,
			history: [
				History
			]
		){ 
			self.auctionID = auctionID
			self.startTime = startTime
			self.endTime = endTime
			self.startingPrice = startingPrice
			self.bidStep = bidStep
			self.nftIDs = nftIDs
			self.nftCollection = nftCollection
			self.currentBid = currentBid
			self.auctionState = auctionState
			self.history = history
		}
	}
	
	access(all)
	enum AuctionState: UInt8{ 
		access(all)
		case Open
		
		access(all)
		case Closing
		
		access(all)
		case Complete
		
		access(all)
		case Upcoming
	}
	
	access(all)
	view fun now(): UFix64{ 
		return getCurrentBlock().timestamp
	}
	
	access(all)
	fun stateToString(_ auctionState: AuctionState): String{ 
		switch auctionState{ 
			case AuctionState.Open:
				return "Open"
			case AuctionState.Closing:
				return "Closing"
			case AuctionState.Complete:
				return "Complete"
			case AuctionState.Upcoming:
				return "Upcoming"
			default:
				return "Upcoming"
		}
	}
	
	// borrowAuction
	//
	// convenience function to borrow an auction by ID
	access(contract)
	fun borrowAuction(id: UInt64): &Auction?{ 
		if ListenAuction.auctions[id] != nil{ 
			return &ListenAuction.auctions[id] as &ListenAuction.Auction?
		} else{ 
			return nil
		}
	}
	
	access(all)
	fun getAuctionMeta(auctionID: UInt64): AuctionMeta{ 
		let auctionRef =
			ListenAuction.borrowAuction(id: auctionID) ?? panic("No Auction with that ID exists")
		let bidRef = auctionRef.bid as &ListenAuction.Bid
		let vaultRef = bidRef.vault as &ListenUSD.Vault
		let auctionState = ListenAuction.stateToString(auctionRef.getAuctionState())
		let history: [History] = auctionRef.getHistory()
		let nftCollection: [{String: String}] = []
		for id in auctionRef.nftCollection.getIDs(){ 
			nftCollection.append(auctionRef.nftCollection.getListenNFTMetadata(id: id))
		}
		return AuctionMeta(
			auctionID: auctionID,
			startTime: auctionRef.startTime,
			endTime: auctionRef.endTime,
			startingPrice: auctionRef.startingPrice,
			bidStep: auctionRef.bidStep,
			nftIDs: auctionRef.nftCollection.getIDs(),
			nftCollection: nftCollection,
			currentBid: vaultRef.balance,
			auctionState: auctionState,
			history: history
		)
	}
	
	access(all)
	fun placeBid(
		auctionID: UInt64,
		funds: @ListenUSD.Vault,
		ftReceiverCap: Capability<&{FungibleToken.Receiver}>,
		nftReceiverCap: Capability
	){ 
		let auctionRef =
			ListenAuction.borrowAuction(id: auctionID) ?? panic("Auction ID does not exist")
		assert(funds.balance >= auctionRef.startingPrice, message: "Bid must be above starting bid")
		assert(ListenAuction.now() > auctionRef.startTime, message: "Auction hasn't started")
		assert(ListenAuction.now() < auctionRef.endTime, message: "Auction has finished")
		let bidRef = auctionRef.bid as &ListenAuction.Bid
		let currentHighestBid = bidRef.vault.balance
		let newBidAmount = funds.balance
		if auctionRef.hasBids(){ 
			// bid step only enforced after first bid is placed
			assert(newBidAmount >= currentHighestBid + auctionRef.bidStep, message: "Bid must be greater than current bid + bid step")
			bidRef.returnBidToOwner()
		}
		// create new bid
		let bid <-
			create Bid(funds: <-funds, ftReceiverCap: ftReceiverCap, nftReceiverCap: nftReceiverCap)
		auctionRef.placeBid(bid: <-bid)
		let ownersVaultRef = ftReceiverCap.borrow()! // <&{FungibleToken.Receiver}>()! 
		
		let history =
			History(
				auctionID: auctionID,
				amount: newBidAmount,
				time: ListenAuction.now(),
				bidderAddress: (ownersVaultRef.owner!).address.toString()
			)
		auctionRef.updateHistory(history: history)
		
		// extend auction endTime if bid is in final 30mins
		if ListenAuction.now() > auctionRef.endTime - ListenAuction.EXTENSION_TIME{ 
			auctionRef.extendAuction()
			emit AuctionExtended(auctionID: auctionID, endTime: auctionRef.endTime)
		}
		emit BidPlaced(
			auctionID: auctionID,
			bidder: ownersVaultRef.owner?.address!,
			amount: newBidAmount
		)
	}
	
	access(all)
	fun getAuctionIDs(): [UInt64]{ 
		return self.auctions.keys
	}
	
	init(){ 
		self.nextID = 0
		self.auctions <-{} 
		
		// Auction extension time is just 30 second for quick testing
		self.EXTENSION_TIME = 1800.0 // = 30 * 60 seconds = 30 mins
		
		self.AdminStoragePath = /storage/ListenAuctionAdmin
		self.AdminCapabilityPath = /private/ListenAuctionAdmin
		self.account.storage.save(<-create Admin(), to: ListenAuction.AdminStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&ListenAuction.Admin>(
				ListenAuction.AdminStoragePath
			)
		self.account.capabilities.publish(capability_1, at: ListenAuction.AdminCapabilityPath)
		emit ContractDeployed()
	}
}
