import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import Tickets from "./Tickets.cdc"

access(all)
contract TicketsAuction{ 
	access(contract)
	let unclaimedBids: @{Address: [Bid]}
	
	access(contract)
	let auctions: @{UInt64: Auction}
	
	access(all)
	var startAt: UFix64
	
	access(all)
	var endAt: UFix64?
	
	access(all)
	var startPrice: UFix64
	
	access(all)
	let bidType: Type
	
	access(all)
	var increment: UFix64
	
	access(all)
	var total: UInt64
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let FlowReceiverPath: PublicPath
	
	access(all)
	event ConfigChange(type: String, value: [UFix64])
	
	access(all)
	event AuctionAvailable(auctionID: UInt64)
	
	access(all)
	event AuctionCompleted(auctionID: UInt64, bidder: Address?, lastPrice: UFix64?, purchased: Bool)
	
	access(all)
	event NewBid(uuid: UInt64, auctionID: UInt64, bidder: Address, bidPrice: UFix64)
	
	access(all)
	resource Bid{ 
		access(self)
		let vault: @{FungibleToken.Vault}
		
		access(contract)
		var price: UFix64
		
		access(contract)
		let refund: Capability<&{FungibleToken.Receiver}>
		
		access(contract)
		let recipient: Capability<&{NonFungibleToken.CollectionPublic}>
		
		access(contract)
		var ref: String?
		
		init(
			vault: @{FungibleToken.Vault},
			price: UFix64,
			refund: Capability<&{FungibleToken.Receiver}>,
			recipient: Capability<&{NonFungibleToken.CollectionPublic}>,
			ref: String?
		){ 
			pre{ 
				refund.check():
					"Refund vault invalid"
				recipient.check():
					"Recipient collection invalid"
				vault.getType() == (refund.borrow()!).getType():
					"Should you same type of fund to return"
			}
			self.vault <- vault
			self.price = price
			self.refund = refund
			self.recipient = recipient
			self.ref = ref
		}
		
		access(all)
		fun doRefund(): Bool{ 
			if let recipient = self.refund.borrow(){ 
				if self.vault.getType() == recipient.getType(){ 
					recipient.deposit(from: <-self.vault.withdraw(amount: self.vault.balance))
					return true
				}
			}
			return false
		}
		
		access(all)
		fun doIncrease(from: @{FungibleToken.Vault}, ref: String?){ 
			self.vault.deposit(from: <-from)
			self.price = self.vault.balance
			self.ref = ref
		}
		
		access(all)
		fun payout(){ 
			Tickets.payAndRewardDiamond(
				recipient: self.recipient,
				payment: <-self.vault.withdraw(amount: self.vault.balance),
				ref: self.ref
			)
		}
		
		access(all)
		fun bidder(): Address{ 
			return self.refund.address
		}
		
		access(all)
		fun bidAmount(): UFix64{ 
			return self.vault.balance
		}
	}
	
	access(all)
	resource interface AuctionPublic{ 
		access(all)
		fun placeBid(
			refund: Capability<&{FungibleToken.Receiver}>,
			recipient: Capability<&{NonFungibleToken.CollectionPublic}>,
			vault: @{FungibleToken.Vault},
			ref: String?
		)
		
		access(all)
		fun currentBidForUser(address: Address): UFix64
	}
	
	access(all)
	resource Auction: AuctionPublic{ 
		access(all)
		let id: UInt64
		
		access(contract)
		var bid: @Bid?
		
		access(all)
		fun currentBidForUser(address: Address): UFix64{ 
			if self.bid?.bidder() == address{ 
				return self.bid?.bidAmount()!
			}
			return 0.0
		}
		
		access(all)
		fun placeBid(refund: Capability<&{FungibleToken.Receiver}>, recipient: Capability<&{NonFungibleToken.CollectionPublic}>, vault: @{FungibleToken.Vault}, ref: String?){ 
			pre{ 
				refund.address == recipient.address:
					"Should use same"
			}
			if self.bid?.bidder() == refund.address{ 
				return self.increaseBid(vault: <-vault, ref: ref)
			}
			return self.createBid(refund: refund, recipient: recipient, vault: <-vault, ref: ref)
		}
		
		access(contract)
		fun complete(){ 
			pre{ 
				getCurrentBlock().timestamp > TicketsAuction.endAt ?? 0.0:
					"Auction has not ended"
			}
			if self.bid == nil{ 
				emit AuctionCompleted(auctionID: self.id, bidder: nil, lastPrice: nil, purchased: false)
				return
			}
			self.bid?.payout()
			emit AuctionCompleted(auctionID: self.id, bidder: self.bid?.bidder(), lastPrice: self.bid?.price, purchased: true)
		}
		
		access(self)
		fun increaseBid(vault: @{FungibleToken.Vault}, ref: String?){ 
			pre{ 
				TicketsAuction.isOpen():
					"Auction not open"
				self.bid != nil:
					"Invalid call"
				vault.balance >= TicketsAuction.increment
			}
			if let bid <- self.bid <- nil{ 
				bid.doIncrease(from: <-vault, ref: ref)
				let old <- self.bid <- bid
				destroy old
			} else{ 
				destroy vault
				panic("Never call this")
			}
			emit NewBid(uuid: self.bid?.uuid!, auctionID: self.id, bidder: self.bid?.bidder()!, bidPrice: self.bid?.price!)
		}
		
		access(self)
		fun createBid(refund: Capability<&{FungibleToken.Receiver}>, recipient: Capability<&{NonFungibleToken.CollectionPublic}>, vault: @{FungibleToken.Vault}, ref: String?){ 
			pre{ 
				TicketsAuction.isOpen():
					"Auction not open"
				vault.isInstance(TicketsAuction.bidType):
					"payment vault is not requested fungible token"
			}
			let price = vault.balance
			assert(price >= TicketsAuction.startPrice, message: "Bid price must be greater than start price")
			assert(price >= (self.bid?.price ?? 0.0) + TicketsAuction.increment, message: "bid amount must be larger or equal to the current price + minimum bid increment")
			let lastBid <- self.bid <- create Bid(vault: <-vault, price: price, refund: refund, recipient: recipient, ref: ref)
			let bidder = refund.address
			emit NewBid(uuid: self.bid?.uuid!, auctionID: self.id, bidder: bidder, bidPrice: self.bid?.price!)
			if lastBid == nil{ 
				destroy lastBid
				return
			}
			let bid <- lastBid!
			if bid.doRefund(){ 
				destroy bid
				return
			}
			self.addUnclaimedBid(bid: <-bid)
		}
		
		access(self)
		fun addUnclaimedBid(bid: @Bid){ 
			let bidder = bid.bidder()
			var bids <- TicketsAuction.unclaimedBids.remove(key: bidder)
			if bids == nil{ 
				bids <-! [] as @[Bid]
			}
			let dummy <- bids!
			dummy.append(<-bid)
			let old <- TicketsAuction.unclaimedBids[bidder] <- dummy
			destroy old
		}
		
		init(id: UInt64){ 
			self.id = id
			self.bid <- nil
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun setTime(startAt: UFix64, endAt: UFix64){ 
			TicketsAuction.startAt = startAt
			TicketsAuction.endAt = endAt
			emit ConfigChange(type: "setTime", value: [startAt, endAt])
		}
		
		access(all)
		fun setPrice(startPrice: UFix64, increment: UFix64){ 
			TicketsAuction.startPrice = startPrice
			TicketsAuction.increment = increment
			emit ConfigChange(type: "setStartPrice", value: [startPrice, increment])
		}
		
		access(all)
		fun createAuction(): UInt64{ 
			pre{ 
				TicketsAuction.total < 71:
					"Can not create more auction"
			}
			TicketsAuction.total = TicketsAuction.total + 1
			let auction <- create Auction(id: TicketsAuction.total)
			let auctionID = auction.id
			let oldAuction <- TicketsAuction.auctions[auctionID] <- auction
			
			// Note that oldAuction will always be nil, but we have to handle it.
			destroy oldAuction
			emit AuctionAvailable(auctionID: auctionID)
			return auctionID
		}
		
		access(all)
		fun completeAuction(auctionID: UInt64){ 
			let auction <-
				TicketsAuction.auctions.remove(key: auctionID) ?? panic("missing auction")
			auction.complete()
			destroy auction
		}
		
		access(all)
		fun refundUnclaimedBidForUser(address: Address){ 
			if let bids <- TicketsAuction.unclaimedBids.remove(key: address){ 
				var i = 0
				while i < bids.length{ 
					let ref = (&bids[i] as &TicketsAuction.Bid)!
					assert(ref.doRefund(), message: "Can't not refund")
					i = i + 1
				}
				destroy bids
			}
		}
	}
	
	access(all)
	view fun isOpen(): Bool{ 
		let now = getCurrentBlock().timestamp
		if self.startAt > now{ 
			return false
		}
		if self.endAt != nil && self.endAt! < now{ 
			return false
		}
		return true
	}
	
	access(all)
	fun getUnclaimBids(): [Address]{ 
		return self.unclaimedBids.keys
	}
	
	access(all)
	fun getAuctionIDs(): [UInt64]{ 
		return self.auctions.keys
	}
	
	access(all)
	fun borrow(auctionID: UInt64): &Auction?{ 
		if self.auctions[auctionID] != nil{ 
			return (&self.auctions[auctionID] as &Auction?)!
		} else{ 
			return nil
		}
	}
	
	init(){ 
		// Thu Apr 14 2022 12:00:00 GMT+0000
		self.startAt = 1649937600.0
		// Sat Apr 16 2022 13:00:00 GMT+0000
		self.endAt = 1650114000.0
		self.startPrice = 333.3
		self.bidType = Type<@FlowToken.Vault>()
		self.unclaimedBids <-{} 
		self.auctions <-{} 
		self.total = 0
		self.increment = 0.1
		self.FlowReceiverPath = /public/flowTokenReceiver
		self.AdminStoragePath = /storage/BNMUAdminTicketsAuctions
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
