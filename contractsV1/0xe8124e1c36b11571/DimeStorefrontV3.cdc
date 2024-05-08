/* SPDX-License-Identifier: UNLICENSED */
import DimeCollectibleV3 from "../0xf5cdaace879e5a79/DimeCollectibleV3.cdc"

import DimeRoyalties from "../0xb1f55a636af51134/DimeRoyalties.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract DimeStorefrontV3{ 
	
	// SaleOffer events
	// A sale offer has been created.
	access(all)
	event SaleOfferCreated(itemId: UInt64, price: UFix64)
	
	// Someone has purchased an item that was offered for sale.
	access(all)
	event SaleOfferAccepted(itemId: UInt64)
	
	// A sale offer has been removed from the collection of Address.
	access(all)
	event SaleOfferRemoved(itemId: UInt64, owner: Address)
	
	// Named paths
	access(all)
	let StorefrontStoragePath: StoragePath
	
	access(all)
	let StorefrontPrivatePath: PrivatePath
	
	access(all)
	let StorefrontPublicPath: PublicPath
	
	// This struct represents the recipients of the earnings from a sale.
	// Earnings--the price paid for an item, minus Dime's fee and any creator
	// royalties--are distributed among the recipients' vaults according to
	// their allotments
	access(all)
	struct SaleShares{ 
		access(self)
		let allotments:{ Address: UFix64}
		
		init(allotments:{ Address: UFix64}){ 
			var total = 0.0
			for allotment in allotments.values{ 
				assert(allotment > 0.0, message: "Each recipient must receive an allotment > 0")
				total = total + allotment
			}
			assert(total == 1.0, message: "Total sale shares must equal exactly 1")
			self.allotments = allotments
		}
		
		access(all)
		fun getShares():{ Address: UFix64}{ 
			return self.allotments
		}
	}
	
	// An interface providing a read-only view of a SaleOffer
	access(all)
	resource interface SaleOfferPublic{ 
		access(all)
		let itemId: UInt64
		
		access(all)
		let isInitialSale: Bool
		
		access(all)
		var price: UFix64
		
		access(all)
		fun getSaleShares(): SaleShares
	}
	
	// A DimeCollectibleV3 NFT being offered to sale for a set fee
	access(all)
	resource SaleOffer: SaleOfferPublic{ 
		// Whether the sale has completed with someone purchasing the item.
		access(all)
		var saleCompleted: Bool
		
		// The collection containing the NFT.
		access(self)
		let sellerItemProvider: Capability<&DimeCollectibleV3.Collection>
		
		// The NFT for sale.
		access(all)
		let itemId: UInt64
		
		// This is derived from the item's history
		access(all)
		let isInitialSale: Bool
		
		// Set by the seller, can be modified
		access(all)
		var price: UFix64
		
		access(self)
		var saleShares: SaleShares
		
		access(all)
		fun getSaleShares(): SaleShares{ 
			return self.saleShares
		}
		
		// Take the information required to create a sale offer. Other than the NFT and
		// a provider for it, all that is needed is the sales info, since everything
		// else is derived from the NFT itself
		init(nft: &DimeCollectibleV3.NFT, sellerItemProvider: Capability<&DimeCollectibleV3.Collection>, price: UFix64, saleShares: SaleShares){ 
			self.saleCompleted = false
			self.sellerItemProvider = sellerItemProvider
			self.itemId = nft.id
			self.isInitialSale = nft.getHistory().length == 0
			self.price = price
			self.saleShares = saleShares
			emit SaleOfferCreated(itemId: self.itemId, price: self.price)
		}
		
		access(all)
		fun setPrice(newPrice: UFix64){ 
			self.price = newPrice
		}
		
		access(all)
		fun setSaleShares(newShares: SaleShares){ 
			self.saleShares = newShares
		}
	}
	
	// The public view of a Storefront, allowing anyone to view the offers withing
	// the Storefront
	access(all)
	resource interface StorefrontPublic{ 
		access(all)
		fun getSaleOfferIds(): [UInt64]
		
		access(all)
		fun borrowSaleOffer(itemId: UInt64): &SaleOffer?
	}
	
	// The private view of a Storefront (accessible only to owner) allowing a
	// user to manage their Storefront by adding SaleOffers, removing them,
	// and changing the price and shares of existing offers
	access(all)
	resource interface StorefrontManager{ 
		access(all)
		fun createSaleOffers(
			itemProvider: Capability<&DimeCollectibleV3.Collection>,
			items: [
				UInt64
			],
			price: UFix64,
			saleShares: SaleShares
		)
		
		access(all)
		fun removeSaleOffers(itemIds: [UInt64], beingPurchased: Bool)
		
		access(all)
		fun setPrices(itemIds: [UInt64], newPrice: UFix64)
		
		access(all)
		fun setSaleShares(itemIds: [UInt64], newShares: SaleShares)
	}
	
	// The resource representing a user's storefront of SaleOffers, implementing
	// the public storefront interface (allowing buyers to interact with the
	// storefront) and the private interface (allowing the owner to manage it).`
	access(all)
	resource Storefront: StorefrontPublic, StorefrontManager{ 
		access(self)
		var saleOffers: @{UInt64: SaleOffer}
		
		// Returns an array of the Ids that are in the collection
		access(all)
		fun getSaleOfferIds(): [UInt64]{ 
			return self.saleOffers.keys
		}
		
		// Returns an Optional read-only view of the SaleItem for the given itemId if it is contained by this collection.
		// The optional will be nil if the provided itemId is not present in the collection.
		access(all)
		fun borrowSaleOffer(itemId: UInt64): &SaleOffer?{ 
			if self.saleOffers[itemId] == nil{ 
				return nil
			}
			return &self.saleOffers[itemId] as &SaleOffer?
		}
		
		access(all)
		fun createSaleOffers(itemProvider: Capability<&DimeCollectibleV3.Collection>, items: [UInt64], price: UFix64, saleShares: SaleShares){ 
			assert(itemProvider.borrow() != nil, message: "Couldn't get a capability to the seller's collection")
			for itemId in items{ 
				let nft = (itemProvider.borrow()!).borrowCollectible(id: itemId) ?? panic("Couldn't borrow nft from seller")
				if nft.getHistory().length > 0 && !nft.tradeable{ 
					panic("Tried to put an untradeable item on sale")
				}
				let newOffer <- create SaleOffer(nft: nft, sellerItemProvider: itemProvider, price: price, saleShares: saleShares)
				
				// Add the new offer to the dictionary, overwriting an old one if it exists
				let oldOffer <- self.saleOffers[itemId] <- newOffer
				destroy oldOffer
			}
		}
		
		// Remove and return a SaleOffer from the collection
		access(all)
		fun removeSaleOffers(itemIds: [UInt64], beingPurchased: Bool){ 
			for itemId in itemIds{ 
				let offer <- self.saleOffers.remove(key: itemId) ?? panic("missing SaleOffer")
				if beingPurchased{ 
					emit SaleOfferAccepted(itemId: itemId)
				} else{ 
					emit SaleOfferRemoved(itemId: itemId, owner: self.owner?.address!)
				}
				destroy offer
			}
		}
		
		access(contract)
		fun push(offer: @SaleOffer){ 
			let oldOffer <- self.saleOffers[offer.itemId] <- offer
			destroy oldOffer
		}
		
		access(contract)
		fun pop(itemId: UInt64): @SaleOffer?{ 
			let offer <- self.saleOffers.remove(key: itemId)
			return <-offer
		}
		
		access(all)
		fun setPrices(itemIds: [UInt64], newPrice: UFix64){ 
			for itemId in itemIds{ 
				assert(self.saleOffers[itemId] != nil, message: "Tried to change price of an item that's not on sale")
				let offer <- self.pop(itemId: itemId)!
				offer.setPrice(newPrice: newPrice)
				self.push(offer: <-offer)
			}
		}
		
		access(all)
		fun setSaleShares(itemIds: [UInt64], newShares: SaleShares){ 
			for itemId in itemIds{ 
				assert(self.saleOffers[itemId] != nil, message: "Tried to change sale shares of an item that's not on sale")
				let offer <- self.pop(itemId: itemId)!
				offer.setSaleShares(newShares: newShares)
				self.push(offer: <-offer)
			}
		}
		
		init(){ 
			self.saleOffers <-{} 
		}
	}
	
	// Make creating a Storefront publicly accessible.
	access(all)
	fun createStorefront(): @Storefront{ 
		return <-create Storefront()
	}
	
	init(){ 
		self.StorefrontStoragePath = /storage/DimeStorefrontV3
		self.StorefrontPrivatePath = /private/DimeStorefrontV3
		self.StorefrontPublicPath = /public/DimeStorefrontV3
	}
}
