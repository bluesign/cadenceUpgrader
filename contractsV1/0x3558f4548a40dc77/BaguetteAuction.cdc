/** 

# BaguetteAuction contract

This contract defines the auction system of Baguette. 
The auction contract acts as an escrow for both NFTs and fungible tokens involved in auctions.
Auctions are centralized in AuctionCollection maintained by admins.  

## Withdrawals and cancelations

Neither can an auction be canceled nor bid withdrawn.

## Auction ends

When the auction has expired, the settle function can be called to transfer the funds and the record.
The settle function is public, since it is risk free (nothing can be changed anyway).

## Create an auction
An Auction is created within an AuctionCollection. An AuctionCollection can be created in two ways:
- by the contract Admin, who can choose the auction parameters. It is used for the primary sales of a record.
- by a Manager who has been initialized by an Admin. The different parameters are fixed at creation by the Admin to the contract parameters at that time.

The second option is used for secondary sales.

Users can only create an auction by accepting an offer made on their NFT as the first bid.

## TimeExtension

An auction is extended by `timeExtension` minutes if a new bid is placed less than `timeExtension` minutes before the end.
*/

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import Record from "./Record.cdc"

import ArtistRegistery from "./ArtistRegistery.cdc"

access(all)
contract BaguetteAuction{ 
	
	// -----------------------------------------------------------------------
	// Variables 
	// -----------------------------------------------------------------------
	
	// Resource paths
	// Public path of an auction collection, allowing the place new bids and to access to public information
	access(all)
	let CollectionPublicPath: PublicPath
	
	// Public path of an auction collection, allowing to create new auctions
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	// Storage path of an auction collection
	access(all)
	let CollectionStoragePath: StoragePath
	
	// Manager public path, allowing an Admin to initialize it
	access(all)
	let ManagerPublicPath: PublicPath
	
	// Manager storage path, for a manager to create auction collections
	access(all)
	let ManagerStoragePath: StoragePath
	
	// Admin private path, allowing initialized Manager to create collections while hidding other admin functions
	access(all)
	let AdminPrivatePath: PrivatePath
	
	// Admin storage path
	access(all)
	let AdminStoragePath: StoragePath
	
	// Default parameters for auctions
	access(all)
	var parameters: AuctionParameters
	
	access(self)
	var marketVault: Capability<&FUSD.Vault>?
	
	access(self)
	var lostFVault: Capability<&FUSD.Vault>?
	
	access(self)
	var lostRCollection: Capability<&Record.Collection>?
	
	// total number of auctions and collections ever created
	access(all)
	var totalAuctions: UInt64
	
	access(all)
	var totalCollections: UInt64
	
	// -----------------------------------------------------------------------
	// Events 
	// -----------------------------------------------------------------------
	// A new auction has been created
	access(all)
	event Created(auctionID: UInt64, admin: Address, status: AuctionStatus)
	
	// A new bid has been placed
	access(all)
	event NewBid(auctionID: UInt64, status: AuctionStatus)
	
	// The auction has been settled
	access(all)
	event Settled(auctionID: UInt64)
	
	// Market and Artist share
	access(all)
	event MarketplaceEarned(auctionID: UInt64, amount: UFix64, owner: Address)
	
	access(all)
	event ArtistEarned(auctionID: UInt64, amount: UFix64, artistID: UInt64)
	
	// lost and found events
	access(all)
	event FUSDLostAndFound(auctionID: UInt64, amount: UFix64, address: Address)
	
	access(all)
	event RecordLostAndFound(auctionID: UInt64, recordID: UInt64, address: Address)
	
	// -----------------------------------------------------------------------
	// Resources 
	// -----------------------------------------------------------------------
	// Structure representing auction parameters
	access(all)
	struct AuctionParameters{ 
		access(all)
		let artistCut: UFix64 // share of the artist for a sale
		
		
		access(all)
		let marketCut: UFix64 // share of the marketplace for a sale
		
		
		access(all)
		let bidIncrement: UFix64 // minimal increment between bids
		
		
		access(all)
		let auctionLength: UFix64 // length of an auction (before any extension)
		
		
		access(all)
		let auctionDelay: UFix64 // delay before the start of an auction
		
		
		access(all)
		let timeExtension: UFix64 // extension when bid in the last `timeExtension` seconds
		
		
		init(
			artistCut: UFix64,
			marketCut: UFix64,
			bidIncrement: UFix64,
			auctionLength: UFix64,
			auctionDelay: UFix64,
			timeExtension: UFix64
		){ 
			self.artistCut = artistCut
			self.marketCut = marketCut
			self.bidIncrement = bidIncrement
			self.auctionLength = auctionLength
			self.auctionDelay = auctionDelay
			self.timeExtension = timeExtension
		}
	}
	
	// This structure holds the main information about an auction
	access(all)
	struct AuctionStatus{ 
		access(all)
		let id: UInt64
		
		access(all)
		let recordID: UInt64
		
		access(all)
		let metadata: Record.Metadata
		
		access(all)
		let owner: Address
		
		access(all)
		let leader: Address?
		
		access(all)
		let currentBid: UFix64?
		
		access(all)
		let nextMinBid: UFix64
		
		access(all)
		let numberOfBids: UInt64
		
		access(all)
		let bidIncrement: UFix64
		
		access(all)
		let startTime: Fix64
		
		access(all)
		let endTime: Fix64
		
		access(all)
		let timeExtension: UFix64
		
		access(all)
		let expired: Bool // the auction is expired and should be settled
		
		
		access(all)
		let timeRemaining: Fix64
		
		init(
			id: UInt64,
			recordID: UInt64,
			metadata: Record.Metadata,
			owner: Address,
			leader: Address?,
			currentBid: UFix64?,
			nextMinBid: UFix64,
			numberOfBids: UInt64,
			bidIncrement: UFix64,
			startTime: Fix64,
			endTime: Fix64,
			timeExtension: UFix64,
			expired: Bool
		){ 
			self.id = id
			self.recordID = recordID
			self.metadata = metadata
			self.owner = owner
			self.leader = leader
			self.currentBid = currentBid
			self.nextMinBid = nextMinBid
			self.numberOfBids = numberOfBids
			self.bidIncrement = bidIncrement
			self.startTime = startTime
			self.endTime = endTime
			self.timeExtension = timeExtension
			if expired{ 
				self.timeRemaining = 0.0
			} else{ 
				self.timeRemaining = endTime - Fix64(getCurrentBlock().timestamp)
			}
			self.expired = expired
		}
	}
	
	// Resource representing a unique Auction
	// The item is an optional resource, as it can be sent to the owner/bidder once the auction is settled
	// If the item is nil, the auction becomes invalid (it should be destroyed)
	// It acts as an escrow for the NFT and the fungible tokens, and contains all the capabilities to send the FT and NFT.
	access(all)
	resource Auction{ 
		// The id of this individual auction
		access(all)
		let auctionID: UInt64
		
		// The record for auction
		access(self)
		var item: @Record.NFT?
		
		// auction parameters
		access(all)
		let parameters: AuctionParameters
		
		access(self)
		var numberOfBids: UInt64 // amount of bids which have been placed
		
		
		access(self)
		var auctionStartTime: UFix64
		
		access(self)
		var auctionEndTime: UFix64
		
		// the auction has been settled and should be destroyed
		access(self)
		var auctionCompleted: Bool
		
		// Auction State
		access(self)
		var startPrice: UFix64
		
		access(self)
		var currentBid: UFix64
		
		access(self)
		let escrow: @FUSD.Vault
		
		//the capabilities pointing to the resource where you want the NFT and FT transfered to if you win this bid.
		access(self)
		var ownerAddr: Address
		
		access(self)
		var bidderAddr: Address?
		
		access(self)
		var bidderFVault: Capability<&FUSD.Vault>?
		
		access(self)
		var bidderRCollection: Capability<&Record.Collection>?
		
		access(self)
		let ownerFVault: Capability<&FUSD.Vault>
		
		access(self)
		let ownerRCollection: Capability<&Record.Collection>
		
		init(
			item: @Record.NFT,
			parameters: AuctionParameters,
			auctionStartTime: UFix64,
			startPrice: UFix64,
			ownerFVault: Capability<&FUSD.Vault>,
			ownerRCollection: Capability<&Record.Collection>
		){ 
			pre{ 
				ownerFVault.check():
					"The fungible vault should be valid."
				ownerRCollection.check():
					"The non fungible collection should be valid."
				item.tradable():
					"The item cannot be traded due to its current locked mode: it is probably waiting for its decryption key."
				startPrice > 0.0:
					"Starting price should be greater than 0"
			}
			BaguetteAuction.totalAuctions = BaguetteAuction.totalAuctions + 1 as UInt64
			self.auctionID = BaguetteAuction.totalAuctions
			self.item <- item
			self.startPrice = startPrice
			self.currentBid = 0.0
			self.parameters = parameters
			self.numberOfBids = 0
			self.auctionStartTime = auctionStartTime
			self.auctionEndTime = auctionStartTime + parameters.auctionLength
			self.auctionCompleted = false
			self.escrow <- FUSD.createEmptyVault(vaultType: Type<@FUSD.Vault>())
			self.bidderAddr = nil
			self.bidderFVault = nil
			self.bidderRCollection = nil
			self.ownerAddr = ownerFVault.address
			self.ownerFVault = ownerFVault
			self.ownerRCollection = ownerRCollection
		}
		
		// sendNFT sends the NFT to the Collection belonging to the provided Capability or to the lost and found if the capability is broken
		// if both the receiver collection and lost and found are unlinked, the record is destroyed in the `destroy` function of this Auction
		access(self)
		fun sendNFT(_ capability: Capability<&Record.Collection>){ 
			if let collectionRef = capability.borrow(){ 
				let item <- self.item <- nil
				collectionRef.deposit(token: <-item!)
				return
			} else if let collectionRef = (BaguetteAuction.lostRCollection!).borrow(){ 
				let item <- self.item <- nil
				let recordID = item?.id!
				collectionRef.deposit(token: <-item!)
				emit RecordLostAndFound(auctionID: self.auctionID, recordID: recordID, address: (collectionRef.owner!).address)
				return
			}
		}
		
		// sendBidTokens sends the bid tokens to the Vault Receiver belonging to the provided Capability or to the lost and found if the capability is broken
		access(self)
		fun sendBidTokens(_ capability: Capability<&FUSD.Vault>){ 
			if let vaultRef = capability.borrow(){ 
				if self.escrow.balance > 0.0{ 
					vaultRef.deposit(from: <-self.escrow.withdraw(amount: self.escrow.balance))
				}
				return
			} else if let vaultRef = (BaguetteAuction.lostFVault!).borrow(){ 
				let balance = self.escrow.balance
				if balance > 0.0{ 
					vaultRef.deposit(from: <-self.escrow.withdraw(amount: balance))
				}
				emit FUSDLostAndFound(auctionID: self.auctionID, amount: balance, address: (vaultRef.owner!).address)
				return
			}
		}
		
		// Send the previous bid back to the last bidder
		access(self)
		fun releasePreviousBid(){ 
			if let vaultCap = self.bidderFVault{ 
				self.sendBidTokens(vaultCap)
				return
			}
		}
		
		// Return the NFT to the owner if no bid has been placed
		access(self)
		fun retToOwner(){ 
			// deposit the NFT into the owner's collection
			self.sendNFT(self.ownerRCollection)
		}
		
		// Extend the auction by the amount of seconds
		access(self)
		fun extendWith(_ amount: UFix64){ 
			self.auctionEndTime = self.auctionEndTime + amount
		}
		
		// get the remaning time can be negative if it's expired
		access(all)
		view fun timeRemaining(): Fix64{ 
			let currentTime = getCurrentBlock().timestamp
			let remaining = Fix64(self.auctionEndTime) - Fix64(currentTime)
			return remaining
		}
		
		// Has the auction expired?
		access(all)
		view fun isAuctionExpired(): Bool{ 
			let timeRemaining = self.timeRemaining()
			return timeRemaining < Fix64(0.0)
		}
		
		// Has the auction been settled
		access(all)
		fun isAuctionCompleted(): Bool{ 
			return self.auctionCompleted
		}
		
		// What the next bid has to match
		access(all)
		view fun minNextBid(): UFix64{ 
			if self.currentBid != 0.0{ 
				return self.currentBid + self.parameters.bidIncrement
			}
			return self.startPrice
		}
		
		// Settle the auction once it's expired. 
		access(all)
		fun settleAuction(){ 
			pre{ 
				!self.auctionCompleted:
					"The auction is already settled" // cannot be settled twice
				
				self.item != nil:
					"Record in auction does not exist"
				self.isAuctionExpired():
					"Auction has not completed yet"
			}
			
			// return if there are no bids to settle
			if self.currentBid == 0.0{ 
				self.retToOwner()
				self.auctionCompleted = true
				emit Settled(auctionID: self.auctionID)
				return
			}
			
			// Send the market and artist share first
			let amountMarket = self.currentBid * self.parameters.marketCut
			let amountArtist = self.currentBid * self.parameters.artistCut
			let marketCut <- self.escrow.withdraw(amount: amountMarket)
			let artistCut <- self.escrow.withdraw(amount: amountArtist)
			let marketVault =
				(BaguetteAuction.marketVault!).borrow() ?? panic("The market vault link is broken.")
			marketVault.deposit(from: <-marketCut)
			emit MarketplaceEarned(
				auctionID: self.auctionID,
				amount: amountMarket,
				owner: (marketVault.owner!).address
			)
			let artistID = (self.item?.metadata!).artistID
			ArtistRegistery.sendArtistShare(id: artistID, deposit: <-artistCut)
			emit ArtistEarned(auctionID: self.auctionID, amount: amountArtist, artistID: artistID)
			
			// Send the FUSD to the seller and the NFT to the highest bidder
			self.sendNFT(self.bidderRCollection!)
			self.sendBidTokens(self.ownerFVault)
			self.auctionCompleted = true
			emit Settled(auctionID: self.auctionID)
		}
		
		// Place a new bid
		access(all)
		fun placeBid(
			bidTokens: @{FungibleToken.Vault},
			fVault: Capability<&FUSD.Vault>,
			rCollection: Capability<&Record.Collection>
		){ 
			pre{ 
				!self.auctionCompleted:
					"auction has already completed"
				bidTokens.balance >= self.minNextBid():
					"bid amount be larger or equal to the current price + minimum bid increment"
				fVault.check():
					"The fungible vault should be valid."
				rCollection.check():
					"The non fungible collection should be valid."
			}
			if self.escrow.balance != 0.0{ 
				// bidderFVault should not be nil as something has been placed in escrow
				self.sendBidTokens(self.bidderFVault!)
			}
			
			// Update the auction item
			self.escrow.deposit(from: <-bidTokens) // will fail if it is not a @FUSD.Vault
			
			
			// extend time if in last X seconds
			if self.timeRemaining() < Fix64(self.parameters.timeExtension){ 
				self.extendWith(self.parameters.timeExtension)
			}
			
			// Add the bidder's Vault and NFT receiver references
			self.bidderAddr = rCollection.address
			self.bidderFVault = fVault
			self.bidderRCollection = rCollection
			
			// Update the current price of the token
			self.currentBid = self.escrow.balance
			self.numberOfBids = self.numberOfBids + 1 as UInt64
			let status = self.getAuctionStatus()
			emit NewBid(auctionID: self.auctionID, status: status)
		}
		
		// Get the auction status
		// Will fail if the auction is completed (item is nil). 
		// A completed auction should be deleted anyway as it is worthless
		access(all)
		fun getAuctionStatus(): AuctionStatus{ 
			return AuctionStatus(
				id: self.auctionID,
				recordID: self.item?.id!,
				metadata: self.item?.metadata!,
				owner: self.ownerAddr,
				leader: self.bidderAddr,
				currentBid: self.currentBid,
				nextMinBid: self.minNextBid(),
				numberOfBids: self.numberOfBids,
				bidIncrement: self.parameters.bidIncrement,
				startTime: Fix64(self.auctionStartTime),
				endTime: Fix64(self.auctionEndTime),
				timeExtension: self.parameters.timeExtension,
				expired: self.isAuctionExpired()
			)
		}
	}
	
	// CollectionPublic
	//
	// Public methods of an AuctionCollection, allowing to settle an auction and retrieve information
	//
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		let collectionID: UInt64
		
		access(all)
		let parameters: AuctionParameters
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun getAuctionStatus(_ recordID: UInt64): AuctionStatus
		
		// the settle functions are public since they just transfer NFT/tokens when the auction is done
		access(all)
		fun settleAuction(_ recordID: UInt64)
	}
	
	// Bidder
	//
	// Public methods of an Collection, allowing to place bids
	//
	access(all)
	resource interface Bidder{ 
		access(all)
		let collectionID: UInt64
		
		access(all)
		let parameters: AuctionParameters
		
		access(all)
		fun placeBid(
			recordID: UInt64,
			bidTokens: @{FungibleToken.Vault},
			fVault: Capability<&FUSD.Vault>,
			rCollection: Capability<&Record.Collection>
		)
	}
	
	// AuctionCreator
	//
	// Interface giving access to the createAuction function
	//
	access(all)
	resource interface AuctionCreator{ 
		access(all)
		let collectionID: UInt64
		
		access(all)
		let parameters: AuctionParameters
		
		access(all)
		fun createAuction(
			record: @Record.NFT,
			startPrice: UFix64,
			ownerFVault: Capability<&FUSD.Vault>,
			ownerRCollection: Capability<&Record.Collection>
		)
	}
	
	// Collection
	//
	// Collection representing a set of auctions and their parameters
	//
	access(all)
	resource Collection: CollectionPublic, AuctionCreator, Bidder{ 
		access(all)
		let collectionID: UInt64
		
		access(all)
		let parameters: AuctionParameters
		
		// Auction Items, where the key is the recordID
		access(self)
		var auctionItems: @{UInt64: Auction}
		
		init(parameters: AuctionParameters){ 
			self.auctionItems <-{} 
			self.parameters = parameters
			BaguetteAuction.totalCollections = BaguetteAuction.totalCollections + 1 as UInt64
			self.collectionID = BaguetteAuction.totalCollections
		}
		
		// Create an auction with the parameters given at the collection initialization
		access(all)
		fun createAuction(record: @Record.NFT, startPrice: UFix64, ownerFVault: Capability<&FUSD.Vault>, ownerRCollection: Capability<&Record.Collection>){ 
			let id = record.id
			let auction <- create Auction(item: <-record, parameters: self.parameters, auctionStartTime: getCurrentBlock().timestamp + self.parameters.auctionDelay, startPrice: startPrice, ownerFVault: ownerFVault, ownerRCollection: ownerRCollection)
			let status = auction.getAuctionStatus()
			self.auctionItems[id] <-! auction
			emit Created(auctionID: status.id, admin: self.owner?.address!, status: status)
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.auctionItems.keys
		}
		
		access(all)
		fun getAuctionStatus(_ recordID: UInt64): AuctionStatus{ 
			pre{ 
				self.auctionItems[recordID] != nil:
					"NFT doesn't exist"
			}
			
			// Get the auction item resources
			return self.auctionItems[recordID]?.getAuctionStatus()!
		}
		
		// settleAuction sends the auction item to the highest bidder
		// and deposits the FungibleTokens into the auction owner's account
		// destroys the auction if it has already been settled
		access(all)
		fun settleAuction(_ recordID: UInt64){ 
			let auctionRef = &self.auctionItems[recordID] as &BaguetteAuction.Auction?
			if auctionRef.isAuctionExpired(){ 
				auctionRef.settleAuction()
				if !auctionRef.isAuctionCompleted(){ 
					panic("Auction was not settled properly")
				}
				destroy self.auctionItems.remove(key: recordID)!
			}
		}
		
		// placeBid sends the bidder's tokens to the bid vault and updates the
		// currentPrice of the current auction item
		access(all)
		fun placeBid(recordID: UInt64, bidTokens: @{FungibleToken.Vault}, fVault: Capability<&FUSD.Vault>, rCollection: Capability<&Record.Collection>){ 
			pre{ 
				self.auctionItems[recordID] != nil:
					"Auction does not exist in this drop"
			}
			
			// Get the auction item resources
			let itemRef = &self.auctionItems[recordID] as &BaguetteAuction.Auction?
			itemRef.placeBid(bidTokens: <-bidTokens, fVault: fVault, rCollection: rCollection)
		}
	}
	
	// An auction collection creator can create auction collections with default parameters
	access(all)
	resource interface CollectionCreator{ 
		access(all)
		fun createAuctionCollection(): @Collection
	}
	
	// Admin can change the default Auction parameters, the market vault and create custom collections
	access(all)
	resource Admin: CollectionCreator{ 
		access(all)
		fun setParameters(parameters: AuctionParameters){ 
			BaguetteAuction.parameters = parameters
		}
		
		access(all)
		fun setMarketVault(marketVault: Capability<&FUSD.Vault>){ 
			pre{ 
				marketVault.check():
					"The market vault should be valid."
			}
			BaguetteAuction.marketVault = marketVault
		}
		
		access(all)
		fun setLostAndFoundVaults(fVault: Capability<&FUSD.Vault>, rCollection: Capability<&Record.Collection>){ 
			pre{ 
				fVault.check():
					"The fungible token vault should be valid."
				rCollection.check():
					"The NFT collection should be valid."
			}
			BaguetteAuction.lostFVault = fVault
			BaguetteAuction.lostRCollection = rCollection
		}
		
		// create collection with default parameters
		access(all)
		fun createAuctionCollection(): @Collection{ 
			return <-create Collection(parameters: BaguetteAuction.parameters)
		}
		
		// create collection with custom parameters
		access(all)
		fun createCustomAuctionCollection(parameters: AuctionParameters): @Collection{ 
			return <-create Collection(parameters: parameters)
		}
	}
	
	// This interface is used to add a Admin capability to a client
	access(all)
	resource interface ManagerClient{ 
		access(all)
		fun addCapability(_ cap: Capability<&Admin>)
	}
	
	// An Manager can create an auction collection with the default parameters
	access(all)
	resource Manager: ManagerClient, CollectionCreator{ 
		access(self)
		var server: Capability<&Admin>?
		
		init(){ 
			self.server = nil
		}
		
		access(all)
		fun addCapability(_ cap: Capability<&Admin>){ 
			pre{ 
				cap.check():
					"Invalid server capablity"
				self.server == nil:
					"Server already set"
			}
			self.server = cap
		}
		
		access(all)
		fun createAuctionCollection(): @Collection{ 
			pre{ 
				self.server != nil:
					"Cannot create AuctionCollection if server is not set"
			}
			return <-((self.server!).borrow()!).createAuctionCollection()
		}
	}
	
	// -----------------------------------------------------------------------
	// Contract public functions
	// -----------------------------------------------------------------------
	// make it possible to delegate auction collection creation (with default parameters)
	access(all)
	fun createManager(): @Manager{ 
		return <-create Manager()
	}
	
	// -----------------------------------------------------------------------
	// Initialization function
	// -----------------------------------------------------------------------
	init(){ 
		self.totalAuctions = 0
		self.totalCollections = 0
		self.parameters = AuctionParameters(
				artistCut: 0.10,
				marketCut: 0.03,
				bidIncrement: 1.0,
				auctionLength: 259200.0, // 3 days
				
				auctionDelay: 0.0,
				timeExtension: 600.0
			) // 10 minutes
		
		self.marketVault = nil
		self.lostFVault = nil
		self.lostRCollection = nil
		self.CollectionPublicPath = /public/boulangeriev1AuctionCollection
		self.CollectionPrivatePath = /private/boulangeriev1AuctionCollection
		self.CollectionStoragePath = /storage/boulangeriev1AuctionCollection
		self.ManagerPublicPath = /public/boulangeriev1AuctionManager
		self.ManagerStoragePath = /storage/boulangeriev1AuctionManager
		self.AdminStoragePath = /storage/boulangeriev1AuctionAdmin
		self.AdminPrivatePath = /private/boulangeriev1AuctionAdmin
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath)
	}
}
