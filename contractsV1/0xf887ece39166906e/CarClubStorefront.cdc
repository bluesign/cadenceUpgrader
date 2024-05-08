// Mainnet
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import CarClub from "./CarClub.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import VroomToken from "./VroomToken.cdc"

// Testnet
// import NonFungibleToken from "../0x631e88ae7f1d7c20/NonFungibleToken.cdc"
// import CarClub from "../0x6e9ac121d7106a09/CarClub.cdc"
// import FungibleToken from "../0x9a0766d93b6608b7/FungibleToken.cdc"
// import VroomToken from "../0x6e9ac121d7106a09/VroomToken.cdc"
access(all)
contract CarClubStorefront{ 
	access(all)
	event CarClubStorefrontInitialized()
	
	access(all)
	event StorefrontInitialized(storefrontResourceID: UInt64)
	
	access(all)
	event StorefrontDestroyed(storefrontResourceID: UInt64)
	
	access(all)
	event ListingAvailable(
		storefrontAddress: Address,
		listingResourceID: UInt64,
		nftType: Type,
		nftIDs: [
			UInt64
		],
		ftVaultType: Type,
		price: UFix64
	)
	
	access(all)
	event ListingCompleted(
		listingResourceID: UInt64,
		storefrontResourceID: UInt64,
		purchased: Bool,
		nftType: Type,
		nftIDs: [
			UInt64
		]
	)
	
	access(all)
	let StorefrontStoragePath: StoragePath
	
	access(all)
	let StorefrontPublicPath: PublicPath
	
	access(all)
	struct ListingDetails{ 
		access(all)
		var storefrontID: UInt64
		
		// Whether this listing has been purchased or not.
		access(all)
		var purchased: Bool
		
		// The Type of the NonFungibleToken.NFT that is being listed.
		access(all)
		let nftType: Type
		
		// The ID of the NFT within that type.
		access(all)
		let nftIDs: [UInt64]
		
		// The Type of the FungibleToken that payments must be made in.
		access(all)
		let salePaymentVaultType: Type
		
		// The amount that must be paid in the specified FungibleToken.
		access(all)
		let salePrice: UFix64
		
		access(all)
		let receiver: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let discount: UFix64?
		
		// setToPurchased
		// Irreversibly set this listing as purchased.
		//
		access(contract)
		fun setToPurchased(){ 
			self.purchased = true
		}
		
		// initializer
		//
		init(
			nftType: Type,
			nftIDs: [
				UInt64
			],
			salePaymentVaultType: Type,
			storefrontID: UInt64,
			salePrice: UFix64,
			receiver: Capability<&{FungibleToken.Receiver}>,
			discount: UFix64?
		){ 
			self.storefrontID = storefrontID
			self.purchased = false
			self.nftType = nftType
			self.nftIDs = nftIDs
			self.salePaymentVaultType = salePaymentVaultType
			self.salePrice = salePrice
			self.receiver = receiver
			//Store the discounts
			self.discount = discount
		}
	}
	
	// ListingPublic
	// An interface providing a useful public interface to a Listing.
	//
	access(all)
	resource interface ListingPublic{ 
		// borrowNFT
		// This will assert in the same way as the NFT standard borrowNFT()
		// if the NFT is absent, for example if it has been sold via another listing.
		//
		// pub fun borrowNFT(): &NonFungibleToken.NFT
		
		// purchase
		// Purchase the listing, buying the token.
		// This pays the beneficiaries and returns the token to the buyer.
		//
		access(all)
		fun purchase(payment: @{FungibleToken.Vault}, collection: &{NonFungibleToken.Collection})
		
		// getDetails
		//
		access(all)
		fun getDetails(): ListingDetails
	}
	
	// Listing
	// A resource that allows an NFT to be sold for an amount of a given FungibleToken,
	// and for the proceeds of that sale to be split between several recipients.
	access(all)
	resource Listing: ListingPublic{ 
		// The simple (non-Capability, non-complex) details of the sale
		access(self)
		let details: ListingDetails
		
		access(contract)
		let nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
		
		// borrowNFT
		// This will assert in the same way as the NFT standard borrowNFT()
		// if the NFT is absent, for example if it has been sold via another listing.
		/*
				pub fun borrowNFT(): &NonFungibleToken.NFT {
						let ref = self.nftProviderCapability.borrow()!.borrowNFT(id: self.getDetails().nftIDs)
						//- CANNOT DO THIS IN PRECONDITION: "member of restricted type is not accessible: isInstance"
						//  result.isInstance(self.getDetails().nftType): "token has wrong type"
						assert(ref.isInstance(self.getDetails().nftType), message: "token has wrong type")
						assert(ref.id == self.getDetails().nftIDs, message: "token has wrong ID")
						return (ref as &NonFungibleToken.NFT?)!
				}*/
		
		// getDetails
		// Get the details of the current state of the Listing as a struct.
		access(all)
		fun getDetails(): ListingDetails{ 
			return self.details
		}
		
		// Purchase the listing, buying the token.
		//The purchase function receives payment and capability from the collection to which the NFT is to be sent. 
		//This checks the user's address and determines whether they are entitled to a discount
		access(all)
		fun purchase(payment: @{FungibleToken.Vault}, collection: &{NonFungibleToken.Collection}){ 
			pre{ 
				self.details.purchased == false:
					"This listing has already been purchased."
				payment.balance >= self.details.salePrice:
					"Insufficient funds to purchase the listing."
			}
			for nftID in self.details.nftIDs{ 
				let nft <- (self.nftProviderCapability.borrow()!).withdraw(withdrawID: nftID)
				assert(nft.isInstance(self.details.nftType), message: "Withdrawn NFT is not of the expected type.")
				collection.deposit(token: <-nft)
			}
			(self.details.receiver.borrow()!).deposit(from: <-payment)
			self.details.setToPurchased()
			emit ListingCompleted(listingResourceID: self.uuid, storefrontResourceID: self.details.storefrontID, purchased: true, nftType: self.details.nftType, nftIDs: self.details.nftIDs) // Emitting all NFT IDs involved in the listing
		
		}
		
		// destructor
		// initializer
		init(nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>, nftType: Type, nftIDs: [UInt64], salePaymentVaultType: Type, salePrice: UFix64, storefrontID: UInt64, receiver: Capability<&{FungibleToken.Receiver}>, discount: UFix64?){ 
			// Store the sale information
			self.details = ListingDetails(nftType: nftType, nftIDs: nftIDs, salePaymentVaultType: salePaymentVaultType, storefrontID: storefrontID, salePrice: salePrice, receiver: receiver, discount: discount)
			
			// Store the NFT provider
			self.nftProviderCapability = nftProviderCapability
			
			// Check that the provider contains the NFT.
			// We will check it again when the token is sold.
			// We cannot move this into a function because initializers cannot call member functions.
			let provider = self.nftProviderCapability.borrow()
			assert(provider != nil, message: "cannot borrow nftProviderCapability")
		
		// This will precondition assert if the token is not available.
		/*
					let nft = provider!.borrowNFT(id: self.details.nftIDs)
					assert(nft.isInstance(self.details.nftType), message: "token is not of specified type")*/
		
		}
	}
	
	// StorefrontManager
	// An interface for adding and removing Listings within a Storefront,
	// intended for use by the Storefront's own
	//
	access(all)
	resource interface StorefrontManager{ 
		// createListing
		// Allows the Storefront owner to create and insert Listings.
		//
		access(all)
		fun createListing(
			nftProviderCapability: Capability<
				&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}
			>,
			nftType: Type,
			nftIDs: [
				UInt64
			],
			receiver: Capability<&{FungibleToken.Receiver}>,
			salePaymentVaultType: Type,
			salePrice: UFix64,
			discount: UFix64?
		): UInt64
		
		// removeListing
		// Allows the Storefront owner to remove any sale listing, acepted or not.
		//
		access(all)
		fun removeListing(listingResourceID: UInt64)
	}
	
	// StorefrontPublic
	// An interface to allow listing and borrowing Listings, and purchasing items via Listings
	// in a Storefront.
	//
	access(all)
	resource interface StorefrontPublic{ 
		access(all)
		fun getListingIDs(): [UInt64]
		
		access(all)
		fun borrowListing(listingResourceID: UInt64): &Listing?
		
		access(all)
		fun cleanup(listingResourceID: UInt64)
	}
	
	// Storefront
	// A resource that allows its owner to manage a list of Listings, and anyone to interact with them
	// in order to query their details and purchase the NFTs that they represent.
	//
	access(all)
	resource Storefront: StorefrontManager, StorefrontPublic{ 
		// The dictionary of Listing uuids to Listing resources.
		access(self)
		var listings: @{UInt64: Listing}
		
		// insert
		// Create and publish a Listing for an NFT.
		//
		access(all)
		fun createListing(nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>, nftType: Type, nftIDs: [UInt64], receiver: Capability<&{FungibleToken.Receiver}>, salePaymentVaultType: Type, salePrice: UFix64, discount: UFix64?): UInt64{ 
			let listing <- create Listing(nftProviderCapability: nftProviderCapability, nftType: nftType, nftIDs: nftIDs, salePaymentVaultType: salePaymentVaultType, salePrice: salePrice, storefrontID: self.uuid, receiver: receiver, discount: discount)
			let listingResourceID = listing.uuid
			let listingPrice = listing.getDetails().salePrice
			
			// Add the new listing to the dictionary.
			let oldListing <- self.listings[listingResourceID] <- listing
			// Note that oldListing will always be nil, but we have to handle it.
			destroy oldListing
			emit ListingAvailable(storefrontAddress: self.owner?.address!, listingResourceID: listingResourceID, nftType: nftType, nftIDs: nftIDs, ftVaultType: salePaymentVaultType, price: listingPrice)
			return listingResourceID
		}
		
		// removeListing
		// Remove a Listing that has not yet been purchased from the collection and destroy it.
		//
		access(all)
		fun removeListing(listingResourceID: UInt64){ 
			let listing <- self.listings.remove(key: listingResourceID) ?? panic("missing Listing")
			
			// This will emit a ListingCompleted event.
			destroy listing
		}
		
		// getListingIDs
		// Returns an array of the Listing resource IDs that are in the collection
		//
		access(all)
		fun getListingIDs(): [UInt64]{ 
			return self.listings.keys
		}
		
		// borrowSaleItem
		// Returns a read-only view of the SaleItem for the given listingID if it is contained by this collection.
		//
		access(all)
		fun borrowListing(listingResourceID: UInt64): &Listing?{ 
			if self.listings[listingResourceID] != nil{ 
				return &self.listings[listingResourceID] as &Listing?
			} else{ 
				return nil
			}
		}
		
		// cleanup
		// Remove an listing *if* it has been purchased.
		// Anyone can call, but at present it only benefits the account owner to do so.
		// Kind purchasers can however call it if they like.
		//
		access(all)
		fun cleanup(listingResourceID: UInt64){ 
			pre{ 
				self.listings[listingResourceID] != nil:
					"could not find listing with given id"
			}
			let listing <- self.listings.remove(key: listingResourceID)!
			assert(listing.getDetails().purchased == true, message: "listing is not purchased, only admin can remove")
			destroy listing
		}
		
		// destructor
		//
		// constructor
		//
		init(){ 
			self.listings <-{} 
			
			// Let event consumers know that this storefront exists
			emit StorefrontInitialized(storefrontResourceID: self.uuid)
		}
	}
	
	// createStorefront
	// Make creating a Storefront publicly accessible.
	//
	access(all)
	fun createStorefront(): @Storefront{ 
		return <-create Storefront()
	}
	
	init(){ 
		self.StorefrontStoragePath = /storage/CarClubStorefront
		self.StorefrontPublicPath = /public/CarClubStorefront
		emit CarClubStorefrontInitialized()
	}
}
