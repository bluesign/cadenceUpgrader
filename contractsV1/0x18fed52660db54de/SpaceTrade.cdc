import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import SpaceTradeFeeManager from "./SpaceTradeFeeManager.cdc"

import SpaceTradeBid from "./SpaceTradeBid.cdc"

access(all)
contract SpaceTrade{ 
	
	// Notify that this contract is available
	access(all)
	event ContractInitialized()
	
	// Bid collection owner have created a bid
	access(all)
	event BidCreated(id: UInt64, owner: Address, recipient: Address, expiration: UFix64)
	
	// Storage path for the bid collection
	access(all)
	let BidCollectionStoragePath: StoragePath
	
	// Where other users can access to accept a bid that we have created (public bids)
	access(all)
	let BidCollectionPublicPath: PublicPath
	
	// Path to BidAccessKey 
	access(all)
	let BidAccessKeyStoragePath: StoragePath
	
	access(all)
	resource BidAccessKey{ 
		access(contract)
		let bidID: UInt64
		
		access(contract)
		let bidRecipient: Address
		
		access(contract)
		let bidOwner: Address
		
		init(bidID: UInt64, bidRecipient: Address, bidOwner: Address){ 
			self.bidID = bidID
			self.bidRecipient = bidRecipient
			self.bidOwner = bidOwner
		}
		
		access(contract)
		view fun isAuthorizedRecipient(): Bool{ 
			pre{ 
				self.owner?.address != nil:
					"Provided BidAccessKey is not owned (must be stored in account storage)"
			}
			return self.bidRecipient == (self.owner!).address
		}
	}
	
	access(all)
	resource interface BidCollectionPublic{ 
		access(all)
		fun createBidAccessKey(id: UInt64): @BidAccessKey
		
		access(all)
		fun borrowBidDetails(id: UInt64): &SpaceTradeBid.Bid
		
		access(all)
		fun borrowBidUsingAccessKey(bidKey: &BidAccessKey): &SpaceTradeBid.Bid
		
		access(all)
		fun getBidIDsByReceiver(receiver: Address?): [UInt64]
	}
	
	access(all)
	resource BidCollection: BidCollectionPublic{ 
		// Bids we have created for others to accept (public bids)
		access(self)
		let bids: @{UInt64: SpaceTradeBid.Bid}
		
		// Bid counter used to create IDs
		access(all)
		var totalBids: UInt64
		
		init(){ 
			self.bids <-{} 
			self.totalBids = 0
		}
		
		access(all)
		fun createBid(recipient: Address, type: SpaceTradeBid.BidType, nftProposals: [SpaceTradeBid.NFTProposals], ftProposals: [SpaceTradeBid.FTProposals], nftRequests: [SpaceTradeBid.NFTRequests], ftRequests: [SpaceTradeBid.FTRequests], bidderFeeProviderCapability: Capability<&{FungibleToken.Balance, FungibleToken.Provider}>?, expiration: UFix64, lockedUntil: UFix64){ 
			let id = self.totalBids
			let bid <- SpaceTradeBid.createBid(id: id, type: type, recipient: recipient, nftProposals: nftProposals, ftProposals: ftProposals, nftRequests: nftRequests, ftRequests: ftRequests, bidderFeeProviderCapability: bidderFeeProviderCapability, expiration: expiration, lockedUntil: lockedUntil)
			let oldBid <- self.bids[id] <- bid
			destroy oldBid
			self.totalBids = self.totalBids + 1
			emit BidCreated(id: id, owner: (self.owner!).address, recipient: recipient, expiration: expiration)
		}
		
		access(all)
		fun createBidAccessKey(id: UInt64): @BidAccessKey{ 
			let bid = self.borrowBid(id: id)
			return <-create BidAccessKey(bidID: bid.id, bidRecipient: bid.recipient, bidOwner: (self.owner!).address)
		}
		
		access(all)
		fun borrowBid(id: UInt64): &SpaceTradeBid.Bid{ 
			pre{ 
				self.bids[id] != nil:
					"Bid with given id was not found"
			}
			return (&self.bids[id] as &SpaceTradeBid.Bid?)!
		}
		
		access(all)
		fun getBidIDs(): [UInt64]{ 
			return self.bids.keys
		}
		
		access(all)
		fun getBidIDsByReceiver(receiver: Address?): [UInt64]{ 
			let keys: [UInt64] = []
			for key in self.bids.keys{ 
				let bid = (&self.bids[key] as &SpaceTradeBid.Bid?)!
				if bid.recipient == receiver{ 
					keys.append(key)
				}
			}
			return keys
		}
		
		access(all)
		fun borrowBidUsingAccessKey(bidKey: &BidAccessKey): &SpaceTradeBid.Bid{ 
			pre{ 
				self.bids[bidKey.bidID] != nil:
					"Bid with given id was not found"
				bidKey.bidOwner == (self.owner!).address:
					"Provided key does not belong to this bid collection"
				bidKey.isAuthorizedRecipient():
					"No permission to view this private bid"
			}
			return (&self.bids[bidKey.bidID] as &SpaceTradeBid.Bid?)!
		}
		
		access(all)
		fun borrowBidDetails(id: UInt64): &SpaceTradeBid.Bid{ 
			pre{ 
				self.bids[id] != nil:
					"Bid with given id was not found"
			}
			return (&self.bids[id] as &SpaceTradeBid.Bid?)!
		}
	}
	
	access(all)
	fun createEmptyBidCollection(): @BidCollection{ 
		return <-create BidCollection()
	}
	
	init(){ 
		self.BidCollectionStoragePath = /storage/SpaceTradeBidCollection
		self.BidCollectionPublicPath = /public/SpaceTradeBidCollection
		self.BidAccessKeyStoragePath = /storage/BidAccessKeyStoragePath
		emit ContractInitialized()
	}
}
