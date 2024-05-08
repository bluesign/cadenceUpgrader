import StarlyCard from "./StarlyCard.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import StarlyCardStaking from "../0x29fcd0b5e444242a/StarlyCardStaking.cdc"

import StakedStarlyCard from "../0x29fcd0b5e444242a/StakedStarlyCard.cdc"

import StarlyCardMarket from "./StarlyCardMarket.cdc"

access(all)
contract StarlyCardBid{ 
	access(all)
	var totalCount: UInt64
	
	access(all)
	event StarlyCardBidCreated(
		bidID: UInt64,
		nftID: UInt64,
		starlyID: String,
		bidPrice: UFix64,
		bidVaultType: String,
		bidderAddress: Address
	)
	
	access(all)
	event StarlyCardBidAccepted(bidID: UInt64, nftID: UInt64, starlyID: String)
	
	// Declined by the card owner
	access(all)
	event StarlyCardBidDeclined(bidID: UInt64, nftID: UInt64, starlyID: String)
	
	// Bid cancelled by the bidder
	access(all)
	event StarlyCardBidCancelled(bidID: UInt64, nftID: UInt64, starlyID: String)
	
	// Bid invalidated due to changed conditions, i.e. remaining resource
	access(all)
	event StarlyCardBidInvalidated(bidID: UInt64, nftID: UInt64, starlyID: String)
	
	// Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	resource interface BidPublicView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let nftID: UInt64
		
		access(all)
		let starlyID: String
		
		access(all)
		let remainingResource: UFix64
		
		access(all)
		let bidPrice: UFix64
		
		access(all)
		let bidVaultType: Type
	}
	
	access(all)
	resource Bid: BidPublicView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let nftID: UInt64
		
		access(all)
		let starlyID: String
		
		// card's remainig resource
		access(all)
		let remainingResource: UFix64
		
		// The price offered by the bidder
		access(all)
		let bidPrice: UFix64
		
		// The Type of the FungibleToken that payments must be made in
		access(all)
		let bidVaultType: Type
		
		access(self)
		let bidVault: @{FungibleToken.Vault}
		
		access(all)
		let bidderAddress: Address
		
		access(self)
		let bidderFungibleReceiver: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		fun accept(bidderCardCollection: &StarlyCard.Collection, sellerFungibleReceiver: Capability<&{FungibleToken.Receiver}>, sellerCardCollection: Capability<&StarlyCard.Collection>, sellerStakedCardCollection: &StakedStarlyCard.Collection, sellerMarketCollection: &StarlyCardMarket.Collection){ 
			pre{ 
				self.bidVault.balance == self.bidPrice:
					"The amount of locked funds is incorrect"
			}
			let currentRemainingResource = StarlyCardStaking.getRemainingResourceWithDefault(starlyID: self.starlyID)
			if currentRemainingResource != self.remainingResource{ 
				emit StarlyCardBidInvalidated(bidID: self.id, nftID: self.nftID, starlyID: self.starlyID)
				return
			}
			self.unstakeCardIfStaked(sellerStakedCardCollection: sellerStakedCardCollection)
			self.removeMarketSaleOfferIfExists(sellerMarketCollection: sellerMarketCollection)
			// transfer card
			let nft <- (sellerCardCollection.borrow()!).withdraw(withdrawID: self.nftID)
			bidderCardCollection.deposit(token: <-nft)
			(sellerFungibleReceiver.borrow()!).deposit(from: <-self.bidVault.withdraw(amount: self.bidPrice))
			emit StarlyCardBidAccepted(bidID: self.id, nftID: self.nftID, starlyID: self.starlyID)
		}
		
		access(self)
		fun removeMarketSaleOfferIfExists(sellerMarketCollection: &StarlyCardMarket.Collection){ 
			let marketOfferIds = sellerMarketCollection.getSaleOfferIDs()
			if marketOfferIds.contains(self.nftID){ 
				let offer <- sellerMarketCollection.remove(itemID: self.nftID)
				destroy offer
			}
		}
		
		access(self)
		fun unstakeCardIfStaked(sellerStakedCardCollection: &StakedStarlyCard.Collection){ 
			let stakeIds = sellerStakedCardCollection.getIDs()
			for stakeId in stakeIds{ 
				let cardStake = sellerStakedCardCollection.borrowStakePrivate(id: stakeId)
				if cardStake.getStarlyID() == self.starlyID{ 
					sellerStakedCardCollection.unstake(id: stakeId)
					return
				}
			}
		}
		
		init(nftID: UInt64, starlyID: String, bidPrice: UFix64, bidVaultType: Type, bidderAddress: Address, bidderFungibleReceiver: Capability<&{FungibleToken.Receiver}>, bidderFungibleProvider: &{FungibleToken.Provider}){ 
			pre{ 
				bidPrice > 0.0:
					"The bid price must be non zero"
				bidderFungibleProvider.isInstance(bidVaultType):
					"Wrong Bid fungible provider type"
			}
			self.id = StarlyCardBid.totalCount
			self.nftID = nftID
			self.starlyID = starlyID
			self.bidPrice = bidPrice
			self.bidVaultType = bidVaultType
			self.bidderAddress = bidderAddress
			self.bidderFungibleReceiver = bidderFungibleReceiver
			self.remainingResource = StarlyCardStaking.getRemainingResourceWithDefault(starlyID: starlyID)
			self.bidVault <- bidderFungibleProvider.withdraw(amount: bidPrice)
			StarlyCardBid.totalCount = StarlyCardBid.totalCount + 1 as UInt64
			emit StarlyCardBidCreated(bidID: self.id, nftID: self.nftID, starlyID: self.starlyID, bidPrice: self.bidPrice, bidVaultType: self.bidVaultType.identifier, bidderAddress: self.bidderAddress)
		}
	}
	
	access(all)
	resource interface CollectionManager{ 
		access(all)
		fun insert(bid: @StarlyCardBid.Bid)
		
		access(all)
		fun remove(bidID: UInt64): @Bid
		
		access(all)
		fun cancel(bidID: UInt64)
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun getBidIDs(): [UInt64]
		
		access(all)
		fun borrowBid(bidID: UInt64): &Bid?
		
		access(all)
		fun accept(
			bidID: UInt64,
			bidderCardCollection: &StarlyCard.Collection,
			sellerFungibleReceiver: Capability<&{FungibleToken.Receiver}>,
			sellerCardCollection: Capability<&StarlyCard.Collection>,
			sellerStakedCardCollection: &StakedStarlyCard.Collection,
			sellerMarketCollection: &StarlyCardMarket.Collection
		)
		
		access(all)
		fun decline(bidID: UInt64)
	}
	
	access(all)
	resource Collection: CollectionManager, CollectionPublic{ 
		access(all)
		var bids: @{UInt64: Bid}
		
		access(all)
		fun getBidIDs(): [UInt64]{ 
			return self.bids.keys
		}
		
		access(all)
		fun borrowBid(bidID: UInt64): &Bid?{ 
			if self.bids[bidID] == nil{ 
				return nil
			}
			return &self.bids[bidID] as &Bid?
		}
		
		access(all)
		fun insert(bid: @StarlyCardBid.Bid){ 
			let oldBid <- self.bids[bid.id] <- bid
			destroy oldBid
		}
		
		access(all)
		fun remove(bidID: UInt64): @Bid{ 
			return <-(self.bids.remove(key: bidID) ?? panic("missing bid"))
		}
		
		access(all)
		fun accept(bidID: UInt64, bidderCardCollection: &StarlyCard.Collection, sellerFungibleReceiver: Capability<&{FungibleToken.Receiver}>, sellerCardCollection: Capability<&StarlyCard.Collection>, sellerStakedCardCollection: &StakedStarlyCard.Collection, sellerMarketCollection: &StarlyCardMarket.Collection){ 
			let bid <- self.remove(bidID: bidID)
			bid.accept(bidderCardCollection: bidderCardCollection, sellerFungibleReceiver: sellerFungibleReceiver, sellerCardCollection: sellerCardCollection, sellerStakedCardCollection: sellerStakedCardCollection, sellerMarketCollection: sellerMarketCollection)
			destroy bid
		}
		
		access(all)
		fun decline(bidID: UInt64){ 
			let bid <- self.remove(bidID: bidID)
			emit StarlyCardBidDeclined(bidID: bidID, nftID: bid.nftID, starlyID: bid.starlyID)
			destroy bid
		}
		
		access(all)
		fun cancel(bidID: UInt64){ 
			let bid <- self.remove(bidID: bidID)
			emit StarlyCardBidCancelled(bidID: bidID, nftID: bid.nftID, starlyID: bid.starlyID)
			destroy bid
		}
		
		init(){ 
			self.bids <-{} 
		}
	}
	
	access(all)
	fun createBid(
		nftID: UInt64,
		starlyID: String,
		bidPrice: UFix64,
		bidVaultType: Type,
		bidderAddress: Address,
		bidderFungibleReceiver: Capability<&{FungibleToken.Receiver}>,
		bidderFungibleProvider: &{FungibleToken.Provider}
	): @Bid{ 
		return <-create Bid(
			nftID: nftID,
			starlyID: starlyID,
			bidPrice: bidPrice,
			bidVaultType: bidVaultType,
			bidderAddress: bidderAddress,
			bidderFungibleReceiver: bidderFungibleReceiver,
			bidderFungibleProvider: bidderFungibleProvider
		)
	}
	
	access(all)
	fun createEmptyCollection(): @Collection{ 
		return <-create Collection()
	}
	
	init(){ 
		self.totalCount = 0
		self.CollectionStoragePath = /storage/starlyCardBidCollection
		self.CollectionPublicPath = /public/starlyCardBidCollection
	}
}
