/* SPDX-License-Identifier: UNLICENSED */

import DimeCollectibleV4 from "../0xf5cdaace879e5a79/DimeCollectibleV4.cdc"
import DimeRoyaltiesV2 from "../0xb1f55a636af51134/DimeRoyaltiesV2.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FUSD from "../0x3c5959b568896393/FUSD.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

pub contract DimeStorefrontV4 {

	// SaleOffer events
	// A sale offer has been created.
	pub event SaleOfferCreated(itemId: UInt64, price: UFix64)
	// Someone has purchased an item that was offered for sale.
	pub event SaleOfferAccepted(itemId: UInt64)
	// A sale offer has been removed from the collection of Address.
	pub event SaleOfferRemoved(itemId: UInt64, owner: Address)

	// Named paths
	pub let StorefrontStoragePath: StoragePath
	pub let StorefrontPrivatePath: PrivatePath
	pub let StorefrontPublicPath: PublicPath

	// An interface providing a read-only view of a SaleOffer
	pub resource interface SaleOfferPublic {
		pub let itemId: UInt64

		pub let isInitialSale: Bool
		pub var price: UFix64
		pub fun getSaleShares(): MetadataViews.Royalties
	}

	// A DimeCollectibleV4 NFT being offered to sale for a set fee
	pub resource SaleOffer: SaleOfferPublic {
		// Whether the sale has completed with someone purchasing the item.
		pub var saleCompleted: Bool

		// The collection containing the NFT.
		access(self) let sellerItemProvider: Capability<&DimeCollectibleV4.Collection{NonFungibleToken.Provider}>

		// The NFT for sale.
		pub let itemId: UInt64

		// This is derived from the item's history
		pub let isInitialSale: Bool

		// Set by the seller, can be modified
		pub var price: UFix64
		access(self) var saleShares: MetadataViews.Royalties
		pub fun getSaleShares(): MetadataViews.Royalties {
			return self.saleShares
		}

		// Take the information required to create a sale offer. Other than the NFT and
		// a provider for it, all that is needed is the sales info, since everything
		// else is derived from the NFT itself
		init(nft: &DimeCollectibleV4.NFT,
			sellerItemProvider: Capability<&DimeCollectibleV4.Collection{NonFungibleToken.Provider}>,
			price: UFix64, saleShares: MetadataViews.Royalties) {
			self.saleCompleted = false
			self.sellerItemProvider = sellerItemProvider

			self.itemId = nft.id
			self.isInitialSale = nft.getHistory().length == 0
			self.price = price
			self.saleShares = saleShares

			emit SaleOfferCreated(itemId: self.itemId, price: self.price)
		}

		pub fun setPrice(newPrice: UFix64) {
			self.price = newPrice
		}

		pub fun setSaleShares(newShares: MetadataViews.Royalties) {
			self.saleShares = newShares
		}
	}

	// The public view of a Storefront, allowing anyone to view the offers withing
	// the Storefront
	pub resource interface StorefrontPublic {
		pub fun getSaleOfferIds(): [UInt64]
		pub fun borrowSaleOffer(itemId: UInt64): &SaleOffer{SaleOfferPublic}?
   	}

	// The private view of a Storefront (accessible only to owner) allowing a
	// user to manage their Storefront by adding SaleOffers, removing them,
	// and changing the price and shares of existing offers
	pub resource interface StorefrontManager {
		pub fun createSaleOffers(
			itemProvider: Capability<&DimeCollectibleV4.Collection{DimeCollectibleV4.DimeCollectionPublic, NonFungibleToken.Provider}>,
			items: [UInt64],
			price: UFix64,
			saleShares: MetadataViews.Royalties
		)
		pub fun removeSaleOffers(itemIds: [UInt64], beingPurchased: Bool)
		pub fun setPrices(itemIds: [UInt64], newPrice: UFix64)
		pub fun setSaleShares(itemIds: [UInt64], newShares: MetadataViews.Royalties)
	}

	// The resource representing a user's storefront of SaleOffers, implementing
	// the public storefront interface (allowing buyers to interact with the
	// storefront) and the private interface (allowing the owner to manage it).`
	pub resource Storefront : StorefrontPublic, StorefrontManager {
		access(self) var saleOffers: @{UInt64: SaleOffer}

		// Returns an array of the Ids that are in the collection
		pub fun getSaleOfferIds(): [UInt64] {
			return self.saleOffers.keys
		}

		// Returns an Optional read-only view of the SaleItem for the given itemId if it is contained by this collection.
		// The optional will be nil if the provided itemId is not present in the collection.
		pub fun borrowSaleOffer(itemId: UInt64): &SaleOffer{SaleOfferPublic}? {
			if self.saleOffers[itemId] == nil {
				return nil
			}
			return &self.saleOffers[itemId] as &SaleOffer{SaleOfferPublic}?
		}

		pub fun createSaleOffers(
			itemProvider: Capability<&DimeCollectibleV4.Collection{DimeCollectibleV4.DimeCollectionPublic, NonFungibleToken.Provider}>,
			items: [UInt64],
			price: UFix64,
			saleShares: MetadataViews.Royalties
		) {
			assert(itemProvider.borrow() != nil, message: "Couldn't get a capability to the seller's collection")

			for itemId in items {
				let nft = itemProvider.borrow()!.borrowCollectible(id: itemId) ?? panic("Couldn't borrow nft from seller")
				if (nft.getHistory().length > 0 && !nft.tradeable) {
					panic("Tried to put an untradeable item on sale")
				}
			
				let newOffer <- create SaleOffer(
					nft: nft,
					sellerItemProvider: itemProvider,
					price: price,
					saleShares: saleShares
				)

				// Add the new offer to the dictionary, overwriting an old one if it exists
				let oldOffer <- self.saleOffers[itemId] <- newOffer
				destroy oldOffer
			}
		}

		// Remove and return a SaleOffer from the collection
		pub fun removeSaleOffers(itemIds: [UInt64], beingPurchased: Bool) {
			for itemId in itemIds {
				let offer <- (self.saleOffers.remove(key: itemId) ?? panic("missing SaleOffer"))
				if beingPurchased {
					emit SaleOfferAccepted(itemId: itemId)
				} else {
					emit SaleOfferRemoved(itemId: itemId, owner: self.owner?.address!)
				}
				destroy offer
			}
		}

		access(contract) fun push(offer: @SaleOffer) {
			let oldOffer <- self.saleOffers[offer.itemId] <- offer
			destroy oldOffer
		}

		access(contract) fun pop(itemId: UInt64): @SaleOffer? {
			let offer <- self.saleOffers.remove(key: itemId)
			return <- offer
		}

		pub fun setPrices(itemIds: [UInt64], newPrice: UFix64) {
			for itemId in itemIds {
				assert(self.saleOffers[itemId] != nil,
					message: "Tried to change price of an item that's not on sale")

				let offer <- self.pop(itemId: itemId)!
				offer.setPrice(newPrice: newPrice)
				self.push(offer: <- offer)
			}
		}

		pub fun setSaleShares(itemIds: [UInt64], newShares: MetadataViews.Royalties) {
			for itemId in itemIds {
				assert(self.saleOffers[itemId] != nil,
					message: "Tried to change sale shares of an item that's not on sale")

				let offer <- self.pop(itemId: itemId)!
				offer.setSaleShares(newShares: newShares)
				self.push(offer: <- offer)
			}
		}

		destroy () {
			destroy self.saleOffers
		}

		init () {
			self.saleOffers <- {}
		}
	}

	// Make creating a Storefront publicly accessible.
	pub fun createStorefront(): @Storefront {
		return <- create Storefront()
	}

	init () {
		self.StorefrontStoragePath = /storage/DimeStorefrontV4
		self.StorefrontPrivatePath = /private/DimeStorefrontV4
		self.StorefrontPublicPath = /public/DimeStorefrontV4
	}
}
