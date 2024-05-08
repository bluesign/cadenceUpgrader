/*
 * Copyright (c) 2021 24Karat. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * This file is part of Project: 24karat flow contract (https://github.com/24karat-gld/flow-24karat-contract)
 *
 * This source code is licensed under the MIT License found in the
 * LICENSE file in the root directory of this source tree or at
 * https://opensource.org/licenses/MIT.
 */

import KaratNFT from "./KaratNFT.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

/*
	This is a simple KaratNFT initial sale contract for the DApp to use
	in order to list and sell KaratNFT.

	It allows:
	- Anyone to create Sale Offers and place them in a collection, making it
	  publicly accessible.
	- Anyone to accept the offer and buy the item.

	It notably does not handle:
	- Multiple different sale NFT contracts.
	- Multiple different payment FT contracts.
	- Splitting sale payments to multiple recipients.

 */

access(all)
contract KaratNFTMarket{ 
	// SaleOffer events.
	//
	// A sale offer has been created.
	access(all)
	event SaleOfferCreated(itemID: UInt64, price: UFix64)
	
	// Someone has purchased an item that was offered for sale.
	access(all)
	event SaleOfferAccepted(itemID: UInt64)
	
	// A sale offer has been destroyed, with or without being accepted.
	access(all)
	event SaleOfferFinished(itemID: UInt64)
	
	// Collection events.
	//
	// A sale offer has been removed from the collection of Address.
	access(all)
	event CollectionRemovedSaleOffer(itemID: UInt64, owner: Address)
	
	// A sale offer has been inserted into the collection of Address.
	access(all)
	event CollectionInsertedSaleOffer(itemID: UInt64, owner: Address, price: UFix64)
	
	// Named paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var feeReceiverAddress: Address
	
	access(all)
	var feeRate: UFix64
	
	// SaleOfferPublicView
	// An interface providing a read-only view of a SaleOffer
	//
	access(all)
	resource interface SaleOfferPublicView{ 
		access(all)
		let itemID: UInt64
		
		access(all)
		let price: UFix64
	}
	
	// SaleOffer
	// A KaratNFT being offered to sale for a set fee paid in Kyen.
	//
	access(all)
	resource SaleOffer: SaleOfferPublicView{ 
		// Whether the sale has completed with someone purchasing the item.
		access(all)
		var saleCompleted: Bool
		
		// The KaratNFT ID for sale.
		access(all)
		let itemID: UInt64
		
		// The sale payment price.
		access(all)
		let price: UFix64
		
		access(all)
		let receiverPublicPath: PublicPath
		
		// The collection containing that ID.
		access(self)
		let sellerItemProvider: Capability<&KaratNFT.Collection>
		
		// The FungibleToken vault that will receive that payment if teh sale completes successfully.
		access(self)
		let sellerPaymentReceiver: Capability<&{FungibleToken.Receiver}>
		
		// Called by a purchaser to accept the sale offer.
		// If they send the correct payment in FungibleToken, and if the item is still available,
		// the KaratNFT will be placed in their KaratNFT.Collection .
		//
		access(all)
		fun accept(buyerCollection: &KaratNFT.Collection, buyerPayment: @{FungibleToken.Vault}){ 
			pre{ 
				buyerPayment.balance == self.price:
					"payment does not equal offer price"
				self.saleCompleted == false:
					"the sale offer has already been accepted"
			}
			let nft <- (self.sellerItemProvider.borrow()!).withdraw(withdrawID: self.itemID) as! @KaratNFT.NFT
			let fee = buyerPayment.balance * KaratNFTMarket.feeRate
			let roy = buyerPayment.balance * nft.metadata.royalty
			let feeValut <- buyerPayment.withdraw(amount: fee)
			let feeReceiver = getAccount(KaratNFTMarket.feeReceiverAddress).capabilities.get<&{FungibleToken.Receiver}>(self.receiverPublicPath).borrow() ?? panic("Cannot borrow fee receiver")
			feeReceiver.deposit(from: <-feeValut)
			let royaltyValut <- buyerPayment.withdraw(amount: roy)
			let royaltyReceiver = getAccount(nft.metadata.artistAddress).capabilities.get<&{FungibleToken.Receiver}>(self.receiverPublicPath).borrow() ?? panic("Cannot borrow fee receiver")
			royaltyReceiver.deposit(from: <-royaltyValut)
			(self.sellerPaymentReceiver.borrow()!).deposit(from: <-buyerPayment)
			buyerCollection.deposit(token: <-nft)
			self.saleCompleted = true
			emit SaleOfferAccepted(itemID: self.itemID)
		}
		
		// destructor
		//
		// initializer
		// Take the information required to create a sale offer, notably the capability
		// to transfer the KaratNFT and the capability to receive Kyen in payment.
		//
		init(sellerItemProvider: Capability<&KaratNFT.Collection>, itemID: UInt64, sellerPaymentReceiver: Capability<&{FungibleToken.Receiver}>, price: UFix64, receiverPublicPath: PublicPath){ 
			pre{ 
				sellerItemProvider.borrow() != nil:
					"Cannot borrow seller"
				sellerPaymentReceiver.borrow() != nil:
					"Cannot borrow sellerPaymentReceiver"
			}
			self.saleCompleted = false
			self.sellerItemProvider = sellerItemProvider
			self.itemID = itemID
			self.sellerPaymentReceiver = sellerPaymentReceiver
			self.price = price
			self.receiverPublicPath = receiverPublicPath
			emit SaleOfferCreated(itemID: self.itemID, price: self.price)
		}
	}
	
	// createSaleOffer
	// Make creating a SaleOffer publicly accessible.
	//
	access(all)
	fun createSaleOffer(
		sellerItemProvider: Capability<&KaratNFT.Collection>,
		itemID: UInt64,
		sellerPaymentReceiver: Capability<&{FungibleToken.Receiver}>,
		price: UFix64,
		receiverPublicPath: PublicPath
	): @SaleOffer{ 
		return <-create SaleOffer(
			sellerItemProvider: sellerItemProvider,
			itemID: itemID,
			sellerPaymentReceiver: sellerPaymentReceiver,
			price: price,
			receiverPublicPath: receiverPublicPath
		)
	}
	
	// CollectionManager
	// An interface for adding and removing SaleOffers to a collection, intended for
	// use by the collection's owner.
	//
	access(all)
	resource interface CollectionManager{ 
		access(all)
		fun insert(offer: @KaratNFTMarket.SaleOffer)
		
		access(all)
		fun remove(itemID: UInt64): @SaleOffer
	}
	
	// CollectionPublic
	// An interface to allow listing and borrowing SaleOffers, and purchasing items via SaleOffers in a collection.
	//
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun getSaleOfferIDs(): [UInt64]
		
		access(all)
		fun borrowSaleItem(itemID: UInt64): &SaleOffer?
		
		access(all)
		fun purchase(
			itemID: UInt64,
			buyerCollection: &KaratNFT.Collection,
			buyerPayment: @{FungibleToken.Vault}
		)
	}
	
	// Collection
	// A resource that allows its owner to manage a list of SaleOffers, and purchasers to interact with them.
	//
	access(all)
	resource Collection: CollectionManager, CollectionPublic{ 
		access(all)
		var saleOffers: @{UInt64: SaleOffer}
		
		// insert
		// Insert a SaleOffer into the collection, replacing one with the same itemID if present.
		//
		access(all)
		fun insert(offer: @KaratNFTMarket.SaleOffer){ 
			let itemID: UInt64 = offer.itemID
			let price: UFix64 = offer.price
			
			// add the new offer to the dictionary which removes the old one
			let oldOffer <- self.saleOffers[itemID] <- offer
			destroy oldOffer
			emit CollectionInsertedSaleOffer(itemID: itemID, owner: self.owner?.address!, price: price)
		}
		
		// remove
		// Remove and return a SaleOffer from the collection.
		access(all)
		fun remove(itemID: UInt64): @SaleOffer{ 
			emit CollectionRemovedSaleOffer(itemID: itemID, owner: self.owner?.address!)
			return <-(self.saleOffers.remove(key: itemID) ?? panic("missing SaleOffer"))
		}
		
		// purchase
		// If the caller passes a valid itemID and the item is still for sale, and passes a Karat vault
		// typed as a FungibleToken.Vault (Karat.deposit() handles the type safety of this)
		// containing the correct payment amount, this will transfer the KaratNFT to the caller's
		// KaratNFT collection.
		// It will then remove and destroy the offer.
		// Note that is means that events will be emitted in this order:
		//   1. Collection.CollectionRemovedSaleOffer
		//   2. KaratNFT.Withdraw
		//   3. KaratNFT.Deposit
		//   4. SaleOffer.SaleOfferFinished
		//
		access(all)
		fun purchase(itemID: UInt64, buyerCollection: &KaratNFT.Collection, buyerPayment: @{FungibleToken.Vault}){ 
			pre{ 
				self.saleOffers[itemID] != nil:
					"SaleOffer does not exist in the collection!"
			}
			let offer <- self.remove(itemID: itemID)
			offer.accept(buyerCollection: buyerCollection, buyerPayment: <-buyerPayment)
			destroy offer
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
		fun borrowSaleItem(itemID: UInt64): &SaleOffer?{ 
			if self.saleOffers[itemID] == nil{ 
				return nil
			} else{ 
				return (&self.saleOffers[itemID] as &SaleOffer?)!
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
	
	// Admin is a special authorization resource 
	access(all)
	resource Admin{ 
		access(all)
		fun setFeeRate(_ newRate: UFix64){ 
			KaratNFTMarket.feeRate = newRate
		}
		
		access(all)
		fun setFeeReceiver(_ addr: Address){ 
			KaratNFTMarket.feeReceiverAddress = addr
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	init(){ 
		self.AdminStoragePath = /storage/KaratNFTMarketAdmin
		self.CollectionStoragePath = /storage/KaratNFTMarketCollection
		self.CollectionPublicPath = /public/KaratNFTMarketCollection
		self.CollectionPrivatePath = /private/karatNFTCollectionProvider
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		self.feeReceiverAddress = 0x8f4f599546e2d7eb
		self.feeRate = 0.05
	}
}
