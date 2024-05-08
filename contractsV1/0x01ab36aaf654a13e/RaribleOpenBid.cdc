import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract RaribleOpenBid{ 
	access(all)
	event RaribleOpenBidInitialized()
	
	access(all)
	event OpenBidInitialized(OpenBidResourceId: UInt64)
	
	access(all)
	event OpenBidDestroyed(OpenBidResourceId: UInt64)
	
	access(all)
	event BidAvailable(
		bidAddress: Address,
		bidId: UInt64,
		vaultType: Type,
		bidPrice: UFix64,
		nftType: Type,
		nftId: UInt64,
		brutto: UFix64,
		cuts:{ 
			Address: UFix64
		}
	)
	
	access(all)
	event BidCompleted(bidId: UInt64, purchased: Bool)
	
	access(all)
	struct Cut{ 
		access(all)
		let receiver: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let amount: UFix64
		
		init(receiver: Capability<&{FungibleToken.Receiver}>, amount: UFix64){ 
			self.receiver = receiver
			self.amount = amount
		}
	}
	
	access(all)
	struct BidDetails{ 
		access(all)
		let bidId: UInt64
		
		access(all)
		let vaultType: Type
		
		access(all)
		let bidPrice: UFix64
		
		access(all)
		let nftType: Type
		
		access(all)
		let nftId: UInt64
		
		access(all)
		let brutto: UFix64
		
		access(all)
		let cuts: [Cut]
		
		access(all)
		var purchased: Bool
		
		access(contract)
		fun setToPurchased(){ 
			self.purchased = true
		}
		
		init(
			bidId: UInt64,
			vaultType: Type,
			bidPrice: UFix64,
			nftType: Type,
			nftId: UInt64,
			brutto: UFix64,
			cuts: [
				Cut
			]
		){ 
			self.bidId = bidId
			self.vaultType = vaultType
			self.bidPrice = bidPrice
			self.nftType = nftType
			self.nftId = nftId
			self.brutto = brutto
			self.cuts = cuts
			self.purchased = false
		}
	}
	
	access(all)
	resource interface BidPublic{ 
		access(all)
		fun purchase(item: @{NonFungibleToken.NFT}): @{FungibleToken.Vault}?
		
		access(all)
		fun getDetails(): BidDetails
	}
	
	access(all)
	resource Bid: BidPublic{ 
		access(self)
		let details: BidDetails
		
		access(contract)
		let vaultRefCapability: Capability<&{FungibleToken.Receiver, FungibleToken.Balance, FungibleToken.Provider}>
		
		access(contract)
		let rewardCapability: Capability<&{NonFungibleToken.CollectionPublic}>
		
		init(vaultRefCapability: Capability<&{FungibleToken.Receiver, FungibleToken.Balance, FungibleToken.Provider}>, offerPrice: UFix64, rewardCapability: Capability<&{NonFungibleToken.CollectionPublic}>, nftType: Type, nftId: UInt64, cuts: [Cut]){ 
			pre{ 
				rewardCapability.check():
					"reward capability not valid"
			}
			self.vaultRefCapability = vaultRefCapability
			self.rewardCapability = rewardCapability
			var price: UFix64 = offerPrice
			let cutsInfo:{ Address: UFix64} ={} 
			for cut in cuts{ 
				assert(cut.receiver.check(), message: "invalid cut receiver")
				price = price - cut.amount
				cutsInfo[cut.receiver.address] = cut.amount
			}
			assert(price > 0.0, message: "price must be > 0")
			let vaultRef = self.vaultRefCapability.borrow() ?? panic("cannot borrow vaultRefCapability")
			self.details = BidDetails(bidId: self.uuid, vaultType: vaultRef.getType(), bidPrice: price, nftType: nftType, nftId: nftId, brutto: offerPrice, cuts: cuts)
			emit BidAvailable(bidAddress: rewardCapability.address, bidId: self.details.bidId, vaultType: self.details.vaultType, bidPrice: self.details.bidPrice, nftType: self.details.nftType, nftId: self.details.nftId, brutto: self.details.brutto, cuts: cutsInfo)
		}
		
		access(all)
		fun purchase(item: @{NonFungibleToken.NFT}): @{FungibleToken.Vault}{ 
			pre{ 
				!self.details.purchased:
					"Bid has already been purchased"
				item.isInstance(self.details.nftType):
					"item NFT is not of specified type"
				item.id == self.details.nftId:
					"item NFT does not have specified ID"
			}
			self.details.setToPurchased()
			(self.rewardCapability.borrow()!).deposit(token: <-item)
			let payment <- (self.vaultRefCapability.borrow()!).withdraw(amount: self.details.brutto)
			for cut in self.details.cuts{ 
				if let receiver = cut.receiver.borrow(){ 
					let part <- payment.withdraw(amount: cut.amount)
					receiver.deposit(from: <-part)
				}
			}
			emit BidCompleted(bidId: self.details.bidId, purchased: self.details.purchased)
			return <-payment
		}
		
		access(all)
		fun getDetails(): BidDetails{ 
			return self.details
		}
	}
	
	access(all)
	resource interface OpenBidManager{ 
		access(all)
		fun createBid(
			vaultRefCapability: Capability<
				&{FungibleToken.Receiver, FungibleToken.Balance, FungibleToken.Provider}
			>,
			offerPrice: UFix64,
			rewardCapability: Capability<&{NonFungibleToken.CollectionPublic}>,
			nftType: Type,
			nftId: UInt64,
			cuts: [
				Cut
			]
		): UInt64
		
		access(all)
		fun removeBid(bidId: UInt64)
	}
	
	access(all)
	resource interface OpenBidPublic{ 
		access(all)
		fun getBidIds(): [UInt64]
		
		access(all)
		fun borrowBid(bidId: UInt64): &Bid?
		
		access(all)
		fun cleanup(bidId: UInt64)
	}
	
	access(all)
	resource OpenBid: OpenBidManager, OpenBidPublic{ 
		access(self)
		var bids: @{UInt64: Bid}
		
		access(all)
		fun createBid(vaultRefCapability: Capability<&{FungibleToken.Receiver, FungibleToken.Balance, FungibleToken.Provider}>, offerPrice: UFix64, rewardCapability: Capability<&{NonFungibleToken.CollectionPublic}>, nftType: Type, nftId: UInt64, cuts: [Cut]): UInt64{ 
			let bid <- create Bid(vaultRefCapability: vaultRefCapability, offerPrice: offerPrice, rewardCapability: rewardCapability, nftType: nftType, nftId: nftId, cuts: cuts)
			let bidId = bid.uuid
			let dummy <- self.bids[bidId] <- bid
			destroy dummy
			return bidId
		}
		
		access(all)
		fun removeBid(bidId: UInt64){ 
			destroy (self.bids.remove(key: bidId) ?? panic("missing bid"))
		}
		
		access(all)
		fun getBidIds(): [UInt64]{ 
			return self.bids.keys
		}
		
		access(all)
		fun borrowBid(bidId: UInt64): &Bid?{ 
			if self.bids[bidId] != nil{ 
				return &self.bids[bidId] as &Bid?
			} else{ 
				return nil
			}
		}
		
		access(all)
		fun cleanup(bidId: UInt64){ 
			pre{ 
				self.bids[bidId] != nil:
					"could not find Bid with given id"
			}
			let bid <- self.bids.remove(key: bidId)!
			assert(bid.getDetails().purchased == true, message: "Bid is not purchased, only admin can remove")
			destroy bid
		}
		
		init(){ 
			self.bids <-{} 
			emit OpenBidInitialized(OpenBidResourceId: self.uuid)
		}
	}
	
	access(all)
	fun createOpenBid(): @OpenBid{ 
		return <-create OpenBid()
	}
	
	access(all)
	let OpenBidStoragePath: StoragePath
	
	access(all)
	let OpenBidPublicPath: PublicPath
	
	init(){ 
		self.OpenBidStoragePath = /storage/RaribleOpenBid
		self.OpenBidPublicPath = /public/RaribleOpenBid
		emit RaribleOpenBidInitialized()
	}
}
