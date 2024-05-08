// VictoryCollectible - MAINNET
import VictoryCollectible from "./VictoryCollectible.cdc"

// FungibleToken - MAINNET
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

// NonFungibleToken - MAINNET
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

/*
	This is a VictoryCollectible sale contract for the DApp to use
	in order to list and sell VictoryCollectible.

	It allows:
	- Anyone to create Sale Offers and place them in a collection, making it
	  publicly accessible.
	- Anyone to accept the offer and buy the item.

 */

access(all)
contract VictoryCollectibleSaleOffer{ 
	// SaleOffer events.
	//
	// A sale offer has been created.
	access(all)
	event SaleOfferCreated(
		seller: Address,
		bundleID: UInt64,
		saleType: UInt8,
		price: UFix64,
		startTime: UInt32,
		endTime: UInt32,
		targetPrice: UFix64
	)
	
	// Someone has purchased an item that was offered for sale.
	access(all)
	event SaleOfferAccepted(seller: Address, bundleID: UInt64)
	
	// A sale offer has been destroyed, with or without being accepted.
	access(all)
	event SaleOfferFinished(seller: Address, bundleID: UInt64)
	
	// Collection events.
	//
	// A sale offer has been removed from the collection of Address.
	access(all)
	event CollectionRemovedSaleOffer(bundleID: UInt64, owner: Address)
	
	// A sale offer has had its price raised.
	access(all)
	event CollectionPriceRaised(owner: Address, bundleID: UInt64, price: UFix64, bidder: Address)
	
	// A sale offer has been inserted into the collection of owner.
	access(all)
	event CollectionInsertedSaleOffer(
		bundleID: UInt64,
		owner: Address,
		price: UFix64,
		saleType: UInt8,
		startTime: UInt32,
		endTime: UInt32,
		targetPrice: UFix64
	)
	
	// Named paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// SaleOfferPublicView
	// An interface providing a read-only view of a SaleOffer
	//
	access(all)
	resource interface SaleOfferPublicView{ 
		access(all)
		var saleCompleted: Bool
		
		access(all)
		var price: UFix64
		
		access(all)
		var winner: Address
		
		access(all)
		let bundleID: UInt64
		
		access(all)
		let saleType: UInt8
		
		access(all)
		let startTime: UInt32
		
		access(all)
		let endTime: UInt32
		
		access(all)
		let targetPrice: UFix64
		
		access(all)
		let royaltyFactor: UFix64
		
		access(all)
		let originalOwner: Address
		
		access(all)
		let seller: Address
	}
	
	// SaleOffer
	// A bundle of VictoryCollectible NFTs being offered to sale for a set fee paid in Flow.
	//
	access(all)
	resource SaleOffer: SaleOfferPublicView{ 
		// Whether the sale has completed with someone purchasing the item.
		access(all)
		var saleCompleted: Bool
		
		// The ID for the bundle
		access(all)
		let bundleID: UInt64
		
		// The sale payment price.
		access(all)
		var price: UFix64
		
		// The sale type
		access(all)
		let saleType: UInt8
		
		// The time to start the sale
		access(all)
		let startTime: UInt32
		
		// The time of the end of the sale
		access(all)
		let endTime: UInt32
		
		// The sale target price.
		access(all)
		let targetPrice: UFix64
		
		// The royalty factor for the sale
		access(all)
		let royaltyFactor: UFix64
		
		// The original owner of the item(s)
		access(all)
		let originalOwner: Address
		
		// The seller of the item(s)
		access(all)
		let seller: Address
		
		// The (current) winner of the item(s)
		access(all)
		var winner: Address
		
		// The VictoryCollectible NFT IDs for sale.
		access(self)
		let itemIDs: [UInt64]
		
		// The collection containing the IDs.
		access(self)
		let sellerItemProvider: Capability<&VictoryCollectible.Collection>
		
		// The Flow vault that will receive the payment if the sale completes successfully.
		access(self)
		let sellerPaymentReceiver: Capability<&{FungibleToken.Receiver}>
		
		// The Flow vault that will receive royalty from the payment if the sale completes successfully.
		access(self)
		let royaltyPaymentReceiver: Capability<&{FungibleToken.Receiver}>
		
		// Called by a purchaser to accept the sale offer.
		// If they send the correct payment, and if the item is still available,
		// the VictoryCollectible NFT will be placed in their VictoryCollectible.Collection.
		//
		// Also called when an auction end time is reached to complete the transaction with the highest bidder
		// NOTE: need to take action if buyer does not have sufficient funds
		//
		access(all)
		fun accept(buyerCollection: &VictoryCollectible.Collection, buyerPayment: @{FungibleToken.Vault}, ownerPaymentReceiver: Capability<&{FungibleToken.Receiver}>){ 
			pre{ 
				buyerPayment.balance == self.price:
					"payment does not equal offer price"
				self.saleCompleted == false:
					"the sale offer has already been accepted"
			}
			self.saleCompleted = true
			
			// if owner == original owner then transfer royalty to royalty receiver
			if self.seller == self.originalOwner{ 
				let royaltyPayment <- buyerPayment.withdraw(amount: self.price * self.royaltyFactor)
				(self.royaltyPaymentReceiver.borrow()!).deposit(from: <-royaltyPayment)
			}			  // else transfer royalty to original owner + royalty receiver
			  else{ 
				let royaltyPayment <- buyerPayment.withdraw(amount: self.price * self.royaltyFactor)
				(self.royaltyPaymentReceiver.borrow()!).deposit(from: <-royaltyPayment)
				let ownerPayment <- buyerPayment.withdraw(amount: self.price * self.royaltyFactor)
				(ownerPaymentReceiver.borrow()!).deposit(from: <-ownerPayment)
			}
			(			 
			 // deposit remainder in the seller's vault
			 self.sellerPaymentReceiver.borrow()!).deposit(from: <-buyerPayment)
			
			// withdraw NFTs from the seller and deposit them for the buyer
			for id in self.itemIDs{ 
				let nft <- (self.sellerItemProvider.borrow()!).withdraw(withdrawID: id)
				buyerCollection.deposit(token: <-nft)
			}
			
			// emit an event
			emit SaleOfferAccepted(seller: self.seller, bundleID: self.bundleID)
		}
		
		// Called by a bidder to raise the bid on a sale offer.
		//
		access(all)
		fun raisePrice(newPrice: UFix64, bidder: Address, bidderReceiver: Capability<&{FungibleToken.Receiver}>, bidVault: @{FungibleToken.Vault}){ 
			pre{ 
				self.saleCompleted == false:
					"the sale offer has already been accepted"
				// price can only go up unless this is the very first bid
				newPrice > self.price || newPrice == self.price && self.winner == self.seller:
					"price can only go up"
				// ensure buyer has enough currency to make good on the bid
				bidVault.balance >= newPrice:
					"insufficient funds to guarantee the bid"
			}
			self.price = newPrice
			self.winner = bidder
			(			 
			 // return the funds to the bidder
			 bidderReceiver.borrow()!).deposit(from: <-bidVault)
		}
		
		// destructor
		//
		// initializer
		// Take the information required to create a sale offer, notably the capability
		// to transfer the VictoryCollectible NFT and the capability to receive Flow in payment.
		//
		init(sellerItemProvider: Capability<&VictoryCollectible.Collection>, bundleID: UInt64, sellerPaymentReceiver: Capability<&{FungibleToken.Receiver}>, price: UFix64, saleType: UInt8, startTime: UInt32, endTime: UInt32, targetPrice: UFix64, royaltyPaymentReceiver: Capability<&{FungibleToken.Receiver}>, royaltyFactor: UFix64){ 
			pre{ 
				sellerItemProvider.borrow() != nil:
					"Cannot borrow seller"
				sellerPaymentReceiver.borrow() != nil:
					"Cannot borrow sellerPaymentReceiver"
				royaltyPaymentReceiver.borrow() != nil:
					"Cannot borrow royaltyPaymentReceiver"
				royaltyFactor < 1.0:
					"Royalty factor cannot be greater than 100%"
			}
			
			// initialize
			self.saleCompleted = false
			
			// store the bundle ID
			self.bundleID = bundleID
			
			// make sure the item ID list is valid
			let collectionRef = sellerItemProvider.borrow()!
			let itemIDs = collectionRef.getBundleIDs(bundleID: bundleID)
			for id in itemIDs{ 
				assert(collectionRef.borrowVictoryItem(id: id) != nil, message: "Specified NFT is not available in the owner's collection")
			}
			
			// assume all the items are owned by the same owner
			let firstNFT = collectionRef.borrowVictoryItem(id: itemIDs[0])
			self.originalOwner = (firstNFT!).originalOwner
			self.seller = ((firstNFT!).owner!).address
			self.sellerItemProvider = sellerItemProvider
			
			// store the item IDs
			self.itemIDs = []
			for id in itemIDs{ 
				self.itemIDs.append(id)
			}
			
			// store various other details of the offer
			self.sellerPaymentReceiver = sellerPaymentReceiver
			self.price = price
			self.saleType = saleType
			self.startTime = startTime
			self.endTime = endTime
			self.targetPrice = targetPrice
			self.royaltyPaymentReceiver = royaltyPaymentReceiver
			self.royaltyFactor = royaltyFactor
			
			// initialize winner to be the seller
			self.winner = self.seller
			
			// emit an event
			emit SaleOfferCreated(seller: self.seller, bundleID: self.bundleID, saleType: self.saleType, price: self.price, startTime: self.startTime, endTime: self.endTime, targetPrice: self.targetPrice)
		}
	}
	
	// CollectionManager
	// An interface for adding and removing SaleOffers to a collection, intended for
	// use by the collection's owner.
	//
	access(all)
	resource interface CollectionManager{ 
		access(all)
		fun createSaleOffer(
			sellerItemProvider: Capability<&VictoryCollectible.Collection>,
			bundleID: UInt64,
			sellerPaymentReceiver: Capability<&{FungibleToken.Receiver}>,
			price: UFix64,
			saleType: UInt8,
			startTime: UInt32,
			endTime: UInt32,
			targetPrice: UFix64,
			royaltyPaymentReceiver: Capability<&{FungibleToken.Receiver}>,
			royaltyFactor: UFix64
		): @SaleOffer
		
		access(all)
		fun insert(offer: @VictoryCollectibleSaleOffer.SaleOffer)
		
		access(all)
		fun remove(bundleID: UInt64): @SaleOffer
	}
	
	// CollectionPurchaser
	// An interface to allow purchasing items via SaleOffers in a collection.
	// This function is also provided by CollectionPublic, it is here to support
	// more fine-grained access to the collection for as yet unspecified future use cases.
	//
	access(all)
	resource interface CollectionPurchaser{ 
		access(all)
		fun purchase(
			bundleID: UInt64,
			buyerCollection: &VictoryCollectible.Collection,
			buyerPayment: @{FungibleToken.Vault},
			ownerPaymentReceiver: Capability<&{FungibleToken.Receiver}>
		)
	}
	
	// CollectionPublic
	// An interface to allow listing and borrowing SaleOffers, and purchasing items via SaleOffers in a collection.
	//
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun getSaleOfferIDs(): [UInt64]
		
		access(all)
		fun borrowSaleItem(bundleID: UInt64): &SaleOffer?
		
		access(all)
		fun placeBid(
			bundleID: UInt64,
			bidPrice: UFix64,
			bidder: Address,
			bidderReceiver: Capability<&{FungibleToken.Receiver}>,
			bidVault: @{FungibleToken.Vault}
		)
		
		access(all)
		fun purchase(
			bundleID: UInt64,
			buyerCollection: &VictoryCollectible.Collection,
			buyerPayment: @{FungibleToken.Vault},
			ownerPaymentReceiver: Capability<&{FungibleToken.Receiver}>
		)
	}
	
	// Collection
	// A resource that allows its owner to manage a list of SaleOffers, and purchasers to interact with them.
	//
	access(all)
	resource Collection: CollectionManager, CollectionPurchaser, CollectionPublic{ 
		access(self)
		var saleOffers: @{UInt64: SaleOffer}
		
		// createSaleOffer
		// Make creating a SaleOffer publicly accessible.
		//
		access(all)
		fun createSaleOffer(sellerItemProvider: Capability<&VictoryCollectible.Collection>, bundleID: UInt64, sellerPaymentReceiver: Capability<&{FungibleToken.Receiver}>, price: UFix64, saleType: UInt8, startTime: UInt32, endTime: UInt32, targetPrice: UFix64, royaltyPaymentReceiver: Capability<&{FungibleToken.Receiver}>, royaltyFactor: UFix64): @SaleOffer{ 
			return <-create SaleOffer(sellerItemProvider: sellerItemProvider, bundleID: bundleID, sellerPaymentReceiver: sellerPaymentReceiver, price: price, saleType: saleType, startTime: startTime, endTime: endTime, targetPrice: targetPrice, royaltyPaymentReceiver: royaltyPaymentReceiver, royaltyFactor: royaltyFactor)
		}
		
		// insert
		// Insert a SaleOffer into the collection, replacing one with the same itemID if present.
		//
		access(all)
		fun insert(offer: @VictoryCollectibleSaleOffer.SaleOffer){ 
			let bundleID: UInt64 = offer.bundleID
			let owner: Address = offer.originalOwner
			let price: UFix64 = offer.price
			let saleType: UInt8 = offer.saleType
			let startTime: UInt32 = offer.startTime
			let endTime: UInt32 = offer.endTime
			let targetPrice: UFix64 = offer.targetPrice
			
			// add the new offer to the dictionary which removes the old one
			let oldOffer <- self.saleOffers[bundleID] <- offer
			destroy oldOffer
			emit CollectionInsertedSaleOffer(bundleID: bundleID, owner: self.owner?.address!, price: price, saleType: saleType, startTime: startTime, endTime: endTime, targetPrice: targetPrice)
		}
		
		// remove
		// Remove and return a SaleOffer from the collection.
		access(all)
		fun remove(bundleID: UInt64): @SaleOffer{ 
			emit CollectionRemovedSaleOffer(bundleID: bundleID, owner: self.owner?.address!)
			return <-(self.saleOffers.remove(key: bundleID) ?? panic("missing SaleOffer"))
		}
		
		// purchase
		// If the caller passes a valid itemID and the item is still for sale, and passes a Flow vault
		// typed as a FungibleToken.Vault (Flow.deposit() handles the type safety of this)
		// containing the correct payment amount, this will transfer the VictoryItem to the caller's
		// VictoryCollectible collection.
		// It will then remove and destroy the offer.
		// Note that is means that events will be emitted in this order:
		//   1. Collection.CollectionRemovedSaleOffer
		//   2. VictoryCollectible.Withdraw
		//   3. VictoryCollectible.Deposit
		//   4. SaleOffer.SaleOfferFinished
		//
		access(all)
		fun purchase(bundleID: UInt64, buyerCollection: &VictoryCollectible.Collection, buyerPayment: @{FungibleToken.Vault}, ownerPaymentReceiver: Capability<&{FungibleToken.Receiver}>){ 
			pre{ 
				self.saleOffers[bundleID] != nil:
					"SaleOffer does not exist in the collection!"
			}
			let offer <- self.remove(bundleID: bundleID)
			offer.accept(buyerCollection: buyerCollection, buyerPayment: <-buyerPayment, ownerPaymentReceiver: ownerPaymentReceiver)
			destroy offer
		}
		
		// placeBid
		// Accept a bid on a bundle from a specified potential buyer.
		// Buyer vault is used to verify available balance.
		access(all)
		fun placeBid(bundleID: UInt64, bidPrice: UFix64, bidder: Address, bidderReceiver: Capability<&{FungibleToken.Receiver}>, bidVault: @{FungibleToken.Vault}){ 
			pre{ 
				self.saleOffers[bundleID] != nil:
					"SaleOffer does not exist in the collection!"
			}
			// remove the offer so we can change it
			let offer <- self.saleOffers.remove(key: bundleID)!
			// raise the price
			offer.raisePrice(newPrice: bidPrice, bidder: bidder, bidderReceiver: bidderReceiver, bidVault: <-bidVault)
			// restore the offer
			self.saleOffers[bundleID] <-! offer
			
			// emit an event
			emit CollectionPriceRaised(owner: self.owner?.address!, bundleID: bundleID, price: bidPrice, bidder: bidder)
		}
		
		// getSaleOfferIDs
		// Returns an array of the IDs that are in the collection
		//
		access(all)
		fun getSaleOfferIDs(): [UInt64]{ 
			return self.saleOffers.keys
		}
		
		// borrowSaleItem
		// Returns an Optional read-only view of the SaleItem for the given itemID if it is contained by this collection.
		// The optional will be nil if the provided itemID is not present in the collection.
		//
		access(all)
		fun borrowSaleItem(bundleID: UInt64): &SaleOffer?{ 
			if self.saleOffers[bundleID] == nil{ 
				return nil
			} else{ 
				return (&self.saleOffers[bundleID] as &SaleOffer?)!
			}
		}
		
		// destructor
		//
		// constructor
		//
		init(){ 
			self.saleOffers <-{} 
		}
	}
	
	// createEmptyCollection
	// Make creating a Collection publicly accessible.
	//
	access(all)
	fun createEmptyCollection(): @Collection{ 
		return <-create Collection()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/VictoryCollectibleSaleOfferCollection
		self.CollectionPublicPath = /public/VictoryCollectibleSaleOfferCollection
	}
}
