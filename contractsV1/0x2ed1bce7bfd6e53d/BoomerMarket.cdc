import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import Boomer from "./Boomer.cdc"

access(all)
contract BoomerMarket{ 
	
	// -----------------------------------------------------------------------
	// BoomerMarket contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	
	// The next listing ID that is used to create Listing. 
	// Every time a Listing is created, nextListingID is assigned 
	// to the new Listing's ID and then is incremented by 1.
	access(all)
	var nextListingID: UInt64
	
	/// Path where the `SaleCollection` is stored
	access(all)
	let marketStoragePath: StoragePath
	
	/// Path where the public capability for the `SaleCollection` is
	access(all)
	let marketPublicPath: PublicPath
	
	/// Path where the `MarketManager` is stored
	access(all)
	let managerPath: StoragePath
	
	/// Event used on Listing is created 
	access(all)
	event BoomerListed(
		listingID: UInt64,
		nftID: UInt64,
		price: UFix64,
		saleCuts:{ 
			Address: UFix64
		},
		seller: Address?
	)
	
	/// Event used on Listing is purchased 
	access(all)
	event BoomerPurchased(id: UInt64, price: UFix64)
	
	/// Event used on Listing is removed 
	access(all)
	event BoomerListingRemoved(listingID: UInt64, owner: Address?)
	
	/// Event used on SaleCuts is changed 
	access(all)
	event CutPercentageChanged(newPercent: UFix64, seller: Address?)
	
	// -----------------------------------------------------------------------
	// BoomerMarket contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// ----------------------------------------------------------------------- 
	// Listing is a Struct that holds all informations about 
	// the NFT put up to sell
	//
	access(all)
	struct Listing{ 
		access(all)
		let ID: UInt64
		
		// The ID of the NFT within that type.
		access(all)
		let nftID: UInt64
		
		// The Type of the FungibleToken that payments must be made in.
		access(all)
		let salePaymentVaultType: Type
		
		// The amount that must be paid in the specified FungibleToken.
		access(all)
		let salePrice: UFix64
		
		// This specifies the division of payment between recipients.
		access(all)
		let saleCuts: [SaleCut]
		
		access(all)
		let sellerCapability: Capability
		
		// initializer
		//
		init(
			ID: UInt64,
			nftID: UInt64,
			salePrice: UFix64,
			saleCuts: [
				SaleCut
			],
			salePaymentVaultType: Type,
			sellerCapability: Capability
		){ 
			pre{ 
				//saleCuts.length > 0 : "Listing must have at least one payment cut recipient"
				salePrice > 0.0:
					"Listing must have non-zero price"
				sellerCapability.borrow<&{FungibleToken.Receiver}>() != nil:
					"Sellers's Receiver Capability is invalid!"
				BoomerMarket.totalSaleCuts(saleCuts: saleCuts) < 100.0:
					"SaleCuts can't be greater or equal a 100"
			}
			self.ID = ID
			self.nftID = nftID
			self.saleCuts = saleCuts
			self.salePrice = salePrice
			self.salePaymentVaultType = salePaymentVaultType
			self.sellerCapability = sellerCapability
		}
	}
	
	// SaleCut
	// A struct representing a recipient that must be sent a certain amount
	// of the payment when a token is sold.
	//
	access(all)
	struct SaleCut{ 
		// The receiver for the payment.
		// Note that we do not store an address to find the Vault that this represents,
		// as the link or resource that we fetch in this way may be manipulated,
		// so to find the address that a cut goes to you must get this struct and then
		// call receiver.borrow()!.owner.address on it.
		// This can be done efficiently in a script.
		access(all)
		let receiver: Capability<&{FungibleToken.Receiver}>
		
		// The percentage of the payment that will be paid to the receiver.
		access(all)
		let percentage: UFix64
		
		// initializer
		//
		init(receiver: Capability<&{FungibleToken.Receiver}>, percentage: UFix64){ 
			self.receiver = receiver
			self.percentage = percentage
		}
	}
	
	// ManagerPublic 
	//
	// The interface that a user can publish a capability to their sale
	// to allow others to access their sale
	access(all)
	resource interface ManagerPublic{ 
		access(all)
		fun purchase(listingID: UInt64, buyTokens: &{FungibleToken.Vault}): @Boomer.NFT
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun borrowBoomer(listingID: UInt64): &Boomer.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == listingID:
					"Cannot borrow Boomer reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		fun getListings(): [Listing]
	}
	
	// MarketManager
	// An interface for adding and removing Listings within a Storefront,
	// intended for use by the Storefront's own
	//
	access(all)
	resource interface MarketManager{ 
		// createListing
		// Allows the Storefront owner to create and insert Listings.
		//
		access(all)
		fun createListing(
			nftID: UInt64,
			salePrice: UFix64,
			saleCuts: [
				SaleCut
			],
			salePaymentVaultType: Type,
			sellerCapability: Capability
		)
		
		// removeListing
		// Allows the Storefront owner to remove any sale listing, acepted or not.
		//
		access(all)
		fun removeListing(listingID: UInt64)
	}
	
	access(all)
	resource Manager: ManagerPublic, MarketManager{ 
		
		/// A collection of the moments that the user has for sale
		access(self)
		var ownerCollection: Capability<&Boomer.Collection>
		
		access(self)
		var listings:{ UInt64: Listing}
		
		init(ownerCollection: Capability<&Boomer.Collection>){ 
			pre{ 
				// Check that the owner's moment collection capability is correct
				ownerCollection.borrow() != nil:
					"Owner's Boomer Collection Capability is invalid!"
			}
			
			// create an empty collection to store the moments that are for sale
			self.ownerCollection = ownerCollection
			
			// listings are initially empty because there are no moments for sale
			self.listings ={} 
		}
		
		/// listForSale lists an NFT for sale in this sale collection
		/// at the specified price
		///
		/// Parameters: tokenID: The id of the NFT to be put up for sale
		///			 price: The price of the NFT
		access(all)
		fun createListing(nftID: UInt64, salePrice: UFix64, saleCuts: [SaleCut], salePaymentVaultType: Type, sellerCapability: Capability){ 
			pre{ 
				(self.ownerCollection.borrow()!).borrowBoomerNFT(id: nftID) != nil:
					"Boomer does not exist in the owner's collection"
			}
			let listingID = BoomerMarket.nextListingID
			BoomerMarket.nextListingID = listingID + 1
			let listing = Listing(ID: listingID, nftID: nftID, salePrice: salePrice, saleCuts: saleCuts, salePaymentVaultType: salePaymentVaultType, sellerCapability: sellerCapability)
			self.listings[listingID] = listing
			let saleCutsInfo:{ Address: UFix64} ={} 
			for cut in saleCuts{ 
				saleCutsInfo[cut.receiver.address] = cut.percentage
			}
			emit BoomerListed(listingID: listingID, nftID: nftID, price: salePrice, saleCuts: saleCutsInfo, seller: self.owner?.address)
		}
		
		/// cancelSale cancels a moment sale and clears its price
		///
		/// Parameters: tokenID: the ID of the token to withdraw from the sale
		///
		access(all)
		fun removeListing(listingID: UInt64){ 
			// Remove the price from the prices dictionary
			self.listings.remove(key: listingID)
			
			// Emit the event for withdrawing a moment from the Sale
			emit BoomerListingRemoved(listingID: listingID, owner: self.owner?.address)
		}
		
		/// purchase lets a user send tokens to purchase an NFT that is for sale
		/// the purchased NFT is returned to the transaction context that called it
		///
		/// Parameters: tokenID: the ID of the NFT to purchase
		///			 buyTokens: the fungible tokens that are used to buy the NFT
		///
		/// Returns: @Boomer.NFT: the purchased NFT
		access(all)
		fun purchase(listingID: UInt64, buyTokens: &{FungibleToken.Vault}): @Boomer.NFT{ 
			pre{ 
				self.listings.containsKey(listingID):
					"listingID not found"
				buyTokens.isInstance((self.listings[listingID]!).salePaymentVaultType):
					"payment vault is not requested fungible token"
			}
			let listing = self.listings[listingID]!
			let price = listing.salePrice
			let buyerVault <- buyTokens.withdraw(amount: price)
			for saleCut in listing.saleCuts{ 
				let receiverCut <- buyerVault.withdraw(amount: price * (saleCut.percentage / 100.0))
				(saleCut.receiver.borrow()!).deposit(from: <-receiverCut)
			}
			(			 
			 // Deposit the remaining tokens into the owners vault
			 listing.sellerCapability.borrow<&{FungibleToken.Receiver}>()!).deposit(from: <-buyerVault)
			let nft <- (self.ownerCollection.borrow()!).withdraw(withdrawID: listing.nftID) as! @Boomer.NFT
			emit BoomerPurchased(id: listingID, price: price)
			for listingKey in self.listings.keys{ 
				if (self.listings[listingKey]!).nftID == listing.nftID{ 
					self.removeListing(listingID: listingKey)
				}
			}
			return <-nft
		}
		
		/// getIDs returns an array of token IDs that are for sale
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.listings.keys
		}
		
		/// borrowBoomer Returns a borrowed reference to a Boomer for sale
		/// so that the caller can read data from it
		///
		/// Parameters: id: The ID of the moment to borrow a reference to
		///
		/// Returns: &Boomer.NFT? Optional reference to a moment for sale 
		///						so that the caller can read its data
		///
		access(all)
		fun borrowBoomer(listingID: UInt64): &Boomer.NFT?{ 
			let ref = (self.ownerCollection.borrow()!).borrowBoomerNFT(id: (self.listings[listingID]!).nftID)
			return ref
		}
		
		/// getListings returns an array of Listing that are for sale
		access(all)
		fun getListings(): [Listing]{ 
			return self.listings.values
		}
	}
	
	// -----------------------------------------------------------------------
	// BoomerMarket contract-level function definitions
	// -----------------------------------------------------------------------
	// createManager creates a new Manager resource
	//
	access(all)
	fun createManager(ownerCapability: Capability<&Boomer.Collection>): @Manager{ 
		return <-create Manager(ownerCollection: ownerCapability)
	}
	
	// createSaleCut creates a new SaleCut to a receiver user
	// with a specific percentage.
	//
	access(all)
	fun createSaleCut(
		receiver: Capability<&{FungibleToken.Receiver}>,
		percentage: UFix64
	): SaleCut{ 
		return SaleCut(receiver: receiver, percentage: percentage)
	}
	
	// totalSaleCuts sum all percentages in a array of SaleCut
	//
	access(all)
	view fun totalSaleCuts(saleCuts: [SaleCut]): UFix64{ 
		var total: UFix64 = 0.0
		for cut in saleCuts{ 
			total = cut.percentage + total
		}
		return total
	}
	
	init(){ 
		self.marketStoragePath = /storage/boomerMarketCollection
		self.marketPublicPath = /public/boomerMarketCollection
		self.managerPath = /storage/boomerMarketManager
		self.nextListingID = 1
	}
}
