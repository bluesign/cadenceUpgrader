import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import DimeCollectible from "./DimeCollectible.cdc"

/*
	This contract allows:
	- Anyone to create Sale Offers and place them in a collection, making it
	  publicly accessible.
	- Anyone to accept the offer and buy the item.
 */

access(all)
contract DimeMarket{ 
	// SaleOffer events
	// A sale offer has been created.
	access(all)
	event SaleOfferCreated(itemId: UInt64, price: UFix64)
	
	// Someone has purchased an item that was offered for sale.
	access(all)
	event SaleOfferAccepted(itemId: UInt64)
	
	// A sale offer has been destroyed, with or without being accepted.
	access(all)
	event SaleOfferFinished(itemId: UInt64)
	
	// Collection events
	// A sale offer has been removed from the collection of Address.
	access(all)
	event CollectionRemovedSaleOffer(itemId: UInt64, owner: Address)
	
	// A sale offer has been inserted into the collection of Address.
	access(all)
	event CollectionInsertedSaleOffer(
		itemId: UInt64,
		creator: Address,
		content: String,
		owner: Address,
		price: UFix64
	)
	
	// Named paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// An interface providing a read-only view of a SaleOffer
	access(all)
	resource interface SaleOfferPublicView{ 
		access(all)
		let itemId: UInt64
		
		access(all)
		let creator: Address
		
		access(all)
		let content: String
		
		access(all)
		let price: UFix64
	}
	
	// A DimeCollectible NFT being offered to sale for a set fee
	access(all)
	resource SaleOffer: SaleOfferPublicView{ 
		// Whether the sale has completed with someone purchasing the item.
		access(all)
		var saleCompleted: Bool
		
		// The NFT for sale.
		access(all)
		let itemId: UInt64
		
		access(all)
		let creator: Address
		
		access(all)
		let content: String
		
		// The sale payment price.
		access(all)
		let price: UFix64
		
		// The collection containing that Id.
		access(self)
		let sellerItemProvider: Capability<&DimeCollectible.Collection>
		
		// Called by a purchaser to accept the sale offer.
		// As of now, there is no transfer of FTs for payment. Instead,
		// we handle the transfer of non-token currency prior to calling accept.
		access(all)
		fun accept(buyerCollection: &DimeCollectible.Collection){ 
			pre{ 
				self.saleCompleted == false:
					"the sale offer has already been accepted"
			}
			self.saleCompleted = true
			let nft <- (self.sellerItemProvider.borrow()!).withdraw(withdrawID: self.itemId)
			buyerCollection.deposit(token: <-nft)
			emit SaleOfferAccepted(itemId: self.itemId)
		}
		
		// Take the information required to create a sale offer: the capability
		// to transfer the DimeCollectible NFT and the capability to receive payment
		init(sellerItemProvider: Capability<&DimeCollectible.Collection>, itemId: UInt64, creator: Address, content: String, price: UFix64){ 
			pre{ 
				sellerItemProvider.borrow() != nil:
					"Cannot borrow seller"
			}
			self.saleCompleted = false
			let collectionRef = sellerItemProvider.borrow()!
			self.sellerItemProvider = sellerItemProvider
			self.itemId = itemId
			self.price = price
			self.creator = creator
			self.content = content
			emit SaleOfferCreated(itemId: self.itemId, price: self.price)
		}
	}
	
	// Make creating a SaleOffer publicly accessible
	access(all)
	fun createSaleOffer(
		sellerItemProvider: Capability<&DimeCollectible.Collection>,
		itemId: UInt64,
		creator: Address,
		content: String,
		price: UFix64
	): @SaleOffer{ 
		return <-create SaleOffer(
			sellerItemProvider: sellerItemProvider,
			itemId: itemId,
			creator: creator,
			content: content,
			price: price
		)
	}
	
	// An interface for adding and removing SaleOffers to a collection, intended for
	// use by the collection's owner
	access(all)
	resource interface CollectionManager{ 
		access(all)
		fun insert(offer: @DimeMarket.SaleOffer)
		
		access(all)
		fun remove(itemId: UInt64): @SaleOffer
	}
	
	// An interface to allow purchasing items via SaleOffers in a collection.
	// This function is also provided by CollectionPublic, it is here to support
	// more fine-grained access to the collection for as yet unspecified future use cases
	access(all)
	resource interface CollectionPurchaser{ 
		access(all)
		fun purchase(itemId: UInt64, buyerCollection: &DimeCollectible.Collection)
	}
	
	// An interface to allow listing and borrowing SaleOffers, and purchasing items via SaleOffers in a collection
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun getSaleOfferIds(): [UInt64]
		
		access(all)
		fun borrowSaleItem(itemId: UInt64): &SaleOffer?
		
		access(all)
		fun purchase(itemId: UInt64, buyerCollection: &DimeCollectible.Collection)
	}
	
	// A resource that allows its owner to manage a list of SaleOffers, and purchasers to interact with them
	access(all)
	resource Collection: CollectionManager, CollectionPurchaser, CollectionPublic{ 
		access(all)
		var saleOffers: @{UInt64: SaleOffer}
		
		// Insert a SaleOffer into the collection, replacing one with the same itemId if present
		access(all)
		fun insert(offer: @DimeMarket.SaleOffer){ 
			let itemId: UInt64 = offer.itemId
			let creator: Address = offer.creator
			let content: String = offer.content
			let price: UFix64 = offer.price
			
			// Add the new offer to the dictionary, overwriting an old one if it exists
			let oldOffer <- self.saleOffers[itemId] <- offer
			destroy oldOffer
			emit CollectionInsertedSaleOffer(itemId: itemId, creator: creator, content: content, owner: self.owner?.address!, price: price)
		}
		
		// Remove and return a SaleOffer from the collection
		access(all)
		fun remove(itemId: UInt64): @SaleOffer{ 
			emit CollectionRemovedSaleOffer(itemId: itemId, owner: self.owner?.address!)
			return <-(self.saleOffers.remove(key: itemId) ?? panic("missing SaleOffer"))
		}
		
		// If the caller passes a valid itemId and the item is still for sale, and passes a
		// vault containing the correct payment amount, this will transfer the
		// NFT to the caller's Collection. It will then remove and destroy the offer.
		// Note that this means that events will be emitted in this order:
		//   1. Collection.CollectionRemovedSaleOffer
		//   2. DimeCollectible.Withdraw
		//   3. DimeCollectible.Deposit
		//   4. SaleOffer.SaleOfferFinished
		access(all)
		fun purchase(itemId: UInt64, buyerCollection: &DimeCollectible.Collection){ 
			pre{ 
				self.saleOffers[itemId] != nil:
					"SaleOffer does not exist in the collection!"
			}
			let offer <- self.remove(itemId: itemId)
			offer.accept(buyerCollection: buyerCollection)
			//FIXME: Is this correct? Or should we return it to the caller to dispose of?
			destroy offer
		}
		
		// Returns an array of the Ids that are in the collection
		access(all)
		fun getSaleOfferIds(): [UInt64]{ 
			return self.saleOffers.keys
		}
		
		// Returns an Optional read-only view of the SaleItem for the given itemId if it is contained by this collection.
		// The optional will be nil if the provided itemId is not present in the collection.
		access(all)
		fun borrowSaleItem(itemId: UInt64): &SaleOffer?{ 
			if self.saleOffers[itemId] == nil{ 
				return nil
			} else{ 
				return &self.saleOffers[itemId] as &DimeMarket.SaleOffer?
			}
		}
		
		init(){ 
			self.saleOffers <-{} 
		}
	}
	
	// Make creating a Collection publicly accessible.
	access(all)
	fun createEmptyCollection(): @Collection{ 
		return <-create Collection()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/DimeMarketCollection
		self.CollectionPublicPath = /public/DimeMarketCollection
	}
}
