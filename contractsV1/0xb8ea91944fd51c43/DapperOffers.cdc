import Offers from "./Offers.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

// DapperOffers
//
// Each account that wants to create offers for NFTs installs an DapperOffer
// resource and creates individual Offers for NFTs within it.
//
// The DapperOffer resource contains the methods to add, remove, borrow and
// get details on Offers contained within it.
//
access(all)
contract DapperOffers{ 
	// DapperOffers
	// This contract has been deployed.
	// Event consumers can now expect events from this contract.
	//
	access(all)
	event DapperOffersInitialized()
	
	/// DapperOfferInitialized
	// A DapperOffer resource has been created.
	//
	access(all)
	event DapperOfferInitialized(DapperOfferResourceId: UInt64)
	
	// DapperOfferDestroyed
	// A DapperOffer resource has been destroyed.
	// Event consumers can now stop processing events from this resource.
	//
	access(all)
	event DapperOfferDestroyed(DapperOfferResourceId: UInt64)
	
	// DapperOfferPublic
	// An interface providing a useful public interface to a Offer.
	//
	access(all)
	resource interface DapperOfferPublic{ 
		// getOfferIds
		// Get a list of Offer ids created by the resource.
		//
		access(all)
		fun getOfferIds(): [UInt64]
		
		// borrowOffer
		// Borrow an Offer to either accept the Offer or get details on the Offer.
		//
		access(all)
		fun borrowOffer(offerId: UInt64): &Offers.Offer?
		
		// cleanup
		// Remove an Offer
		//
		access(all)
		fun cleanup(offerId: UInt64)
		
		// addProxyCapability
		// Assign proxy capabilities (DapperOfferProxyManager) to an DapperOffer resource.
		//
		access(all)
		fun addProxyCapability(account: Address, cap: Capability<&DapperOffer>)
	}
	
	// DapperOfferManager
	// An interface providing a management interface for an DapperOffer resource.
	//
	access(all)
	resource interface DapperOfferManager{ 
		// createOffer
		// Allows the DapperOffer owner to create Offers.
		//
		access(all)
		fun createOffer(
			vaultRefCapability: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>,
			nftReceiverCapability: Capability<&{NonFungibleToken.CollectionPublic}>,
			nftType: Type,
			nftId: UInt64,
			amount: UFix64,
			royalties: [
				Offers.Royalty
			]
		): UInt64
		
		// removeOffer
		// Allows the DapperOffer owner to remove offers
		//
		access(all)
		fun removeOffer(offerId: UInt64)
	}
	
	// DapperOfferProxyManager
	// An interface providing removeOffer on behalf of an DapperOffer owner.
	//
	access(all)
	resource interface DapperOfferProxyManager{ 
		// removeOffer
		// Allows the DapperOffer owner to remove offers
		//
		access(all)
		fun removeOffer(offerId: UInt64)
		
		// removeOfferFromProxy
		// Allows the DapperOffer proxy owner to remove offers
		//
		access(all)
		fun removeOfferFromProxy(account: Address, offerId: UInt64)
	}
	
	// DapperOffer
	// A resource that allows its owner to manage a list of Offers, and anyone to interact with them
	// in order to query their details and accept the Offers for NFTs that they represent.
	//
	access(all)
	resource DapperOffer: DapperOfferManager, DapperOfferPublic, DapperOfferProxyManager{ 
		// The dictionary of Address to DapperOfferProxyManager capabilities.
		access(self)
		var removeOfferCapability:{ Address: Capability<&DapperOffer>}
		
		// The dictionary of Offer uuids to Offer resources.
		access(self)
		var offers: @{UInt64: Offers.Offer}
		
		// addProxyCapability
		// Assign proxy capabilities (DapperOfferProxyManager) to an DapperOffer resource.
		//
		access(all)
		fun addProxyCapability(account: Address, cap: Capability<&DapperOffer>){ 
			pre{ 
				cap.borrow() != nil:
					"Invalid admin capability"
			}
			self.removeOfferCapability[account] = cap
		}
		
		// removeOfferFromProxy
		// Allows the DapperOffer proxy owner to remove offers
		//
		access(all)
		fun removeOfferFromProxy(account: Address, offerId: UInt64){ 
			pre{ 
				self.removeOfferCapability[account] != nil:
					"Cannot remove offers until the token admin has deposited the account registration capability"
			}
			let adminRef = (self.removeOfferCapability[account]!).borrow()!
			adminRef.removeOffer(offerId: offerId)
		}
		
		// createOffer
		// Allows the DapperOffer owner to create Offers.
		//
		access(all)
		fun createOffer(vaultRefCapability: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>, nftReceiverCapability: Capability<&{NonFungibleToken.CollectionPublic}>, nftType: Type, nftId: UInt64, amount: UFix64, royalties: [Offers.Royalty]): UInt64{ 
			let offer <- Offers.makeOffer(vaultRefCapability: vaultRefCapability, nftReceiverCapability: nftReceiverCapability, nftType: nftType, nftId: nftId, amount: amount, royalties: royalties)
			let offerId = offer.uuid
			let dummy <- self.offers[offerId] <- offer
			destroy dummy
			return offerId
		}
		
		// removeOffer
		// Remove an Offer that has not yet been accepted from the collection and destroy it.
		//
		access(all)
		fun removeOffer(offerId: UInt64){ 
			destroy (self.offers.remove(key: offerId) ?? panic("missing offer"))
		}
		
		// getOfferIds
		// Returns an array of the Offer resource IDs that are in the collection
		//
		access(all)
		fun getOfferIds(): [UInt64]{ 
			return self.offers.keys
		}
		
		// borrowOffer
		// Returns a read-only view of the Offer for the given OfferID if it is contained by this collection.
		//
		access(all)
		fun borrowOffer(offerId: UInt64): &Offers.Offer?{ 
			if self.offers[offerId] != nil{ 
				return (&self.offers[offerId] as &Offers.Offer?)!
			} else{ 
				return nil
			}
		}
		
		// cleanup
		// Remove an Offer *if* it has been accepted.
		// Anyone can call, but at present it only benefits the account owner to do so.
		// Kind purchasers can however call it if they like.
		//
		access(all)
		fun cleanup(offerId: UInt64){ 
			pre{ 
				self.offers[offerId] != nil:
					"could not find Offer with given id"
			}
			let offer <- self.offers.remove(key: offerId)!
			assert(offer.getDetails().purchased == true, message: "Offer is not purchased, only admin can remove")
			destroy offer
		}
		
		// constructor
		//
		init(){ 
			self.removeOfferCapability ={} 
			self.offers <-{} 
			// Let event consumers know that this storefront will no longer exist.
			emit DapperOfferInitialized(DapperOfferResourceId: self.uuid)
		}
	
	// destructor
	//
	}
	
	// createDapperOffer
	// Make creating an DapperOffer publicly accessible.
	//
	access(all)
	fun createDapperOffer(): @DapperOffer{ 
		return <-create DapperOffer()
	}
	
	access(all)
	let DapperOffersStoragePath: StoragePath
	
	access(all)
	let DapperOffersPublicPath: PublicPath
	
	init(){ 
		self.DapperOffersStoragePath = /storage/DapperOffers
		self.DapperOffersPublicPath = /public/DapperOffers
		emit DapperOffersInitialized()
	}
}
