/*
	Description: The Marketplace Contract for TheFabricant NFTs

	The contract is focussed on handling listings and offers of TheFabricant NFTs
	but is also able to accept other NFTs as well
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract TheFabricantMarketplace{ 
	
	// -----------------------------------------------------------------------
	// TheFabricantMarketplace contract Event definitions
	// -----------------------------------------------------------------------
	
	// emitted when contract has been deployed. Acts as a start marker for historical event indexing.
	access(all)
	event TheFabricantMarketplaceContractInitialized()
	
	// emitted when Admin changes/sets the channel fee capability where a proportion of sale amounts will be sent to 
	access(all)
	event ChannelFeeCapSet(channelFeeCapAddress: Address)
	
	// emitted when listings/offers are initialized and destroyed. Acts as start and end markers for historical event indexing
	access(all)
	event ListingsInitialized(listingsResourceID: UInt64)
	
	access(all)
	event ListingsDestroyed(listingsResourceID: UInt64)
	
	access(all)
	event OffersInitialized(offersResourceID: UInt64)
	
	access(all)
	event OffersDestroyed(offersResourceID: UInt64)
	
	// emitted when an nft is listed
	access(all)
	event NFTListed(
		listingID: String,
		nftType: Type,
		nftID: UInt64,
		ftVaultType: Type,
		price: UFix64,
		seller: Address
	)
	
	// emitted when an nft listing is delisted 
	access(all)
	event NFTDelisted(listingID: String, seller: Address)
	
	// emitted when an nft is purchased 
	access(all)
	event NFTPurchased(listingID: String, seller: Address, buyer: Address)
	
	// emitted when an offer is made for an nft
	access(all)
	event NFTOfferMade(
		offerID: String,
		nftType: Type,
		nftID: UInt64,
		price: UFix64,
		ftVaultType: Type,
		offerer: Address,
		initialNFTOwner: Address
	)
	
	// emitted when an offer is removed
	access(all)
	event NFTOfferRemoved(offerID: String, offerer: Address)
	
	// emitted when an offer is accepted
	access(all)
	event NFTOfferAccepted(offerID: String, offerer: Address, accepter: Address)
	
	// emitted when royalty is deposited for a listing/offer
	access(all)
	event RoyaltyDeposited(
		listingID: String,
		nftType: Type,
		nftID: UInt64,
		name: String,
		amount: UFix64,
		to: Address
	)
	
	// emitted when admin changes offer duration
	access(all)
	event OfferDurationChanged(duration: UFix64)
	
	// -----------------------------------------------------------------------
	// contract-level fields.	  
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	access(all)
	let ListingsStoragePath: StoragePath
	
	access(all)
	let ListingsPublicPath: PublicPath
	
	access(all)
	let OffersStoragePath: StoragePath
	
	access(all)
	let OffersPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// the FungibleToken capability that channel fee royalties will be transferred to 
	access(self)
	var channelFeeCap: Capability<&{FungibleToken.Receiver}>?
	
	// dictionary of listing/offerIDs and how many times each has been sold through a listing or offer
	access(self)
	var nftSaleCount:{ String: UInt32}
	
	// the duration of an offer until it expires
	access(all)
	var offerDuration: UFix64
	
	// SaleCut
	// A struct representing a recipient that must be sent a certain amount
	// of the payment when a token is sold.
	//
	access(all)
	struct SaleCut{ 
		// The name of the receiver
		access(all)
		let name: String
		
		// The receiver capability for the payment.
		access(all)
		let receiver: Capability<&{FungibleToken.Receiver}>
		
		// Royalty amounts are percentages
		// Initial sales will use initialAmount, secondary sales will use amount
		access(all)
		let initialAmount: UFix64
		
		access(all)
		let amount: UFix64
		
		init(
			name: String,
			receiver: Capability<&{FungibleToken.Receiver}>,
			initialAmount: UFix64,
			amount: UFix64
		){ 
			self.name = name
			self.receiver = receiver
			self.initialAmount = initialAmount
			self.amount = amount
		}
	}
	
	// ListingDetails
	// A struct containing a Listing's data.
	//
	access(all)
	struct ListingDetails{ 
		// The id of the listing which is the concat of the nftype and nftid
		access(all)
		let listingID: String
		
		// The Type of the NonFungibleToken.NFT that is being listed.
		access(all)
		let nftType: Type
		
		// The ID of the NFT within that type.
		access(all)
		let nftID: UInt64
		
		// The Type of the FungibleToken that payments must be made in.
		access(all)
		let salePaymentVaultType: Type
		
		// The amount that must be paid in the specified FungibleToken.
		access(all)
		let price: UFix64
		
		// This specifies the division of payment between recipients.
		access(all)
		let saleCuts: [SaleCut]
		
		init(
			listingID: String,
			nftType: Type,
			nftID: UInt64,
			salePaymentVaultType: Type,
			price: UFix64,
			saleCuts: [
				SaleCut
			]
		){ 
			self.listingID = listingID
			self.nftType = nftType
			self.nftID = nftID
			self.salePaymentVaultType = salePaymentVaultType
			self.price = price
			self.saleCuts = saleCuts
		}
	}
	
	// ListingsPublic 
	//
	// The interface that a user can publish a capability to their listing
	// to allow others to access their listing
	access(all)
	resource interface ListingPublic{ 
		access(all)
		fun getListingDetails(): TheFabricantMarketplace.ListingDetails
		
		access(all)
		fun borrowNFT(): &{NonFungibleToken.NFT}
		
		access(all)
		fun containsNFT(): Bool
	}
	
	// Listing
	// A resource that allows an NFT to be sold for an amount of a given FungibleToken,
	// and for the proceeds of that sale to be split between several recipients.
	// 
	access(all)
	resource Listing: ListingPublic{ 
		
		// The simple (non-Capability, non-complex) details of the listing
		access(self)
		let listingDetails: ListingDetails
		
		// A capability allowing this resource to withdraw the NFT with the given ID from its collection.
		// This capability allows the resource to withdraw *any* NFT
		access(contract)
		let nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
		
		// the capability allowing this resource to have FungibleToken deposited into once nft is purchased
		access(self)
		let paymentCapability: Capability<&{FungibleToken.Receiver}>
		
		// borrowNFT
		// This will assert in the same way as the NFT standard borrowNFT()
		// if the NFT is absent, for example if it has been sold via another listing.
		access(all)
		fun borrowNFT(): &{NonFungibleToken.NFT}{ 
			let ref = (self.nftProviderCapability.borrow()!).borrowNFT(self.getListingDetails().nftID)
			assert(ref.isInstance(self.getListingDetails().nftType), message: "token has wrong type")
			assert(ref.id == self.getListingDetails().nftID, message: "token has wrong ID")
			return ref!
		}
		
		// getListingDetails
		// Get the details of the current state of the Listing as a struct.
		access(all)
		fun getListingDetails(): ListingDetails{ 
			return self.listingDetails
		}
		
		// checks whether owner of listing contains the nft for cleanUp
		access(all)
		fun containsNFT(): Bool{ 
			return (self.nftProviderCapability.borrow()!).getIDs().contains(self.listingDetails.nftID)
		}
		
		// purchase
		// Purchase the listing, buying the token.
		// This pays the beneficiaries and returns the token to the buyer.
		// can only be called through the Listings resource
		access(all)
		fun purchase(payment: @{FungibleToken.Vault}): @{NonFungibleToken.NFT}{ 
			pre{ 
				payment.isInstance(self.listingDetails.salePaymentVaultType):
					"payment vault is not requested fungible token"
				payment.balance == self.listingDetails.price:
					"payment vault does not contain requested price"
			}
			
			// Fetch the token to return to the purchaser.
			let nft <- (self.nftProviderCapability.borrow()!).withdraw(withdrawID: self.listingDetails.nftID)
			
			// check the NFT resource such that it gives us the correct type and id
			assert(nft.isInstance(self.listingDetails.nftType), message: "withdrawn NFT is not of specified type")
			assert(nft.id == self.listingDetails.nftID, message: "withdrawn NFT does not have specified ID")
			
			// get the listingID 
			let listingID = self.listingDetails.listingID
			
			// Pay each beneficiary their amount of the payment, depending on whether that specific token has been sold before
			for cut in self.listingDetails.saleCuts{ 
				let cutAmount = TheFabricantMarketplace.nftSaleCount.containsKey(listingID) ? self.listingDetails.price * cut.amount : self.listingDetails.price * cut.initialAmount
				if let receiver = cut.receiver.borrow(){ 
					let paymentCut <- payment.withdraw(amount: cutAmount)
					receiver.deposit(from: <-paymentCut)
					emit RoyaltyDeposited(listingID: listingID, nftType: self.listingDetails.nftType, nftID: self.listingDetails.nftID, name: cut.name, amount: cutAmount, to: (receiver.owner!).address)
				}
			}
			(			 
			 // Then pay the rest to seller
			 self.paymentCapability.borrow()!).deposit(from: <-payment)
			
			// Increment saleCount for the nft
			if TheFabricantMarketplace.nftSaleCount.containsKey(listingID){ 
				TheFabricantMarketplace.nftSaleCount[listingID] = TheFabricantMarketplace.nftSaleCount[listingID]! + 1
			} else{ 
				TheFabricantMarketplace.nftSaleCount[listingID] = 1
			}
			return <-nft
		}
		
		// destructor
		//
		// initializer
		//
		init(listingID: String, nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>, nftType: Type, nftID: UInt64, paymentCapability: Capability<&{FungibleToken.Receiver}>, salePaymentVaultType: Type, price: UFix64, saleCuts: [SaleCut]){ 
			
			// Store the listing information
			self.listingDetails = ListingDetails(listingID: listingID, nftType: nftType, nftID: nftID, salePaymentVaultType: salePaymentVaultType, price: price, saleCuts: saleCuts)
			
			// Store the NFT provider
			self.nftProviderCapability = nftProviderCapability
			
			// Store the FungibleToken receiver capability
			self.paymentCapability = paymentCapability
			
			// This precondition will assert if the token is not available.
			let nft = (nftProviderCapability.borrow()!).borrowNFT(self.listingDetails.nftID)
			assert(nft.isInstance(self.listingDetails.nftType), message: "token is not of specified type")
			assert(nft.id == self.listingDetails.nftID, message: "token does not have specified ID")
		}
	}
	
	access(all)
	resource interface ListingsManager{ 
		access(all)
		fun createListing(
			nftProviderCapability: Capability<
				&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}
			>,
			nftType: Type,
			nftID: UInt64,
			paymentCapability: Capability<&{FungibleToken.Receiver}>,
			salePaymentVaultType: Type,
			price: UFix64,
			saleCuts: [
				SaleCut
			]
		): String
		
		access(all)
		fun removeListing(listingID: String)
	}
	
	// ListingsPublic
	// An interface to allow borrowing Listings, cleanup and purchasing items via Listings
	//
	access(all)
	resource interface ListingsPublic{ 
		access(all)
		fun getListingIDs(): [String]
		
		access(all)
		fun borrowListing(listingID: String): &Listing?
		
		access(all)
		fun cleanUp(listingID: String)
		
		access(all)
		fun purchaseListing(
			listingID: String,
			recipientCap: &{NonFungibleToken.Receiver},
			payment: @{FungibleToken.Vault}
		)
	}
	
	// Listings
	// resource that contains listings
	access(all)
	resource Listings: ListingsPublic, ListingsManager{ 
		
		// Dictionary of the listing details for each nft by listing id
		access(self)
		var listings: @{String: Listing}
		
		init(){ 
			// listings dictionary is empty at start
			self.listings <-{} 
			emit ListingsInitialized(listingsResourceID: self.uuid)
		}
		
		// destructor
		//
		// createListing
		// Create a listing if the nft is not already listed
		access(all)
		fun createListing(nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>, nftType: Type, nftID: UInt64, paymentCapability: Capability<&{FungibleToken.Receiver}>, salePaymentVaultType: Type, price: UFix64, saleCuts: [SaleCut]): String{ 
			pre{ 
				nftProviderCapability.check():
					"Owner's NFT provider capability is invalid"
				paymentCapability.check():
					"Owner's Payment capability is invalid"
				self.listings[TheFabricantMarketplace.typeID(type: nftType, id: nftID)] == nil:
					"NFT is already listed"
			}
			
			// create the listing id using the nftType and nftID
			let listingID = TheFabricantMarketplace.typeID(type: nftType, id: nftID)
			
			// create the listing
			let listing <- create Listing(listingID: listingID, nftProviderCapability: nftProviderCapability, nftType: nftType, nftID: nftID, paymentCapability: paymentCapability, salePaymentVaultType: salePaymentVaultType, price: price, saleCuts: saleCuts)
			
			// Add the new listing to the dictionary.
			let oldListing <- self.listings[listingID] <- listing
			// Note that oldListing will always be nil, but we have to handle it.
			destroy oldListing
			emit NFTListed(listingID: listingID, nftType: nftType, nftID: nftID, ftVaultType: salePaymentVaultType, price: price, seller: self.owner?.address!)
			return listingID
		}
		
		// removeListing
		// Remove a Listing that has not yet been purchased from the collection and destroy it.
		//
		access(all)
		fun removeListing(listingID: String){ 
			let listing <- self.listings.remove(key: listingID) ?? panic("missing Listing")
			emit NFTDelisted(listingID: listingID, seller: self.owner?.address!)
			destroy listing
		}
		
		// purchaseListing
		// purchase an availableListing
		// deposits the nft from seller to buyer,
		// deposits FungibleToken from buyer to seller
		access(all)
		fun purchaseListing(listingID: String, recipientCap: &{NonFungibleToken.Receiver}, payment: @{FungibleToken.Vault}){ 
			pre{ 
				self.listings[listingID] != nil:
					"No token matching this listingID for sale!"
			}
			let listing <- self.listings.remove(key: listingID) ?? panic("missing Listing")
			let nft <- listing.purchase(payment: <-payment)
			
			// deposit the NFT into the buyers collection
			recipientCap.deposit(token: <-nft)
			emit NFTPurchased(listingID: listingID, seller: self.owner?.address!, buyer: recipientCap.owner?.address!)
			destroy listing
		}
		
		// removes a listing if the owner of listing does not own the nft 
		// mainly used to prevent ghost listing in 2 cases
		// 1) when user transfers nft to another account 
		// 2) when user accepts an offer for the nft when there is still a listing available
		access(all)
		fun cleanUp(listingID: String){ 
			let ref = self.borrowListing(listingID: listingID)
			if ref != nil{ 
				if !(ref!).containsNFT(){ 
					self.removeListing(listingID: listingID)
				}
			}
		}
		
		// borrowListing
		// Returns a read-only view of the Listing for the given listingID if it is contained by this collection.
		//
		access(all)
		fun borrowListing(listingID: String): &Listing?{ 
			return &self.listings[listingID] as &Listing?
		}
		
		// getListingIDs
		// Returns an array of the Listing IDs that are in the collection
		//
		access(all)
		fun getListingIDs(): [String]{ 
			return self.listings.keys
		}
	}
	
	access(all)
	fun createListings(): @Listings{ 
		return <-create Listings()
	}
	
	// OfferDetails
	// A struct containing an Offer's data.
	//
	access(all)
	struct OfferDetails{ 
		// The id of the offer which is the concat of the nftype and nftid
		access(all)
		let offerID: String
		
		// The Type of the NonFungibleToken.NFT that is being listed.
		access(all)
		let nftType: Type
		
		// The ID of the NFT within that type.
		access(all)
		let nftID: UInt64
		
		// The Type of the FungibleToken that payments must be made in.
		access(all)
		let offerPaymentVaultType: Type
		
		// The amount that will be paid in the specified FungibleToken.
		access(all)
		let price: UFix64
		
		// This specifies the division of payment between recipients.
		access(all)
		let saleCuts: [SaleCut]
		
		// This specifies the start time of the offer
		access(all)
		let startTime: UFix64
		
		// This specifies the end time of the offer, after which offer cannot be accepted
		access(all)
		let endTime: UFix64
		
		init(
			offerID: String,
			nftType: Type,
			nftID: UInt64,
			offerPaymentVaultType: Type,
			price: UFix64,
			saleCuts: [
				SaleCut
			],
			startTime: UFix64,
			endTime: UFix64
		){ 
			self.offerID = offerID
			self.nftType = nftType
			self.nftID = nftID
			self.offerPaymentVaultType = offerPaymentVaultType
			self.price = price
			self.saleCuts = saleCuts
			self.startTime = startTime
			self.endTime = endTime
		}
	}
	
	// OfferPublic 
	//
	// The interface that a user can publish a capability to their offer
	// to allow others to access their offer
	access(all)
	resource interface OfferPublic{ 
		access(all)
		fun getOfferDetails(): TheFabricantMarketplace.OfferDetails
	}
	
	// Offer
	// A resource that allows an an offer to be made for an NFT for an amount of a given FungibleToken,
	// and for the proceeds of that offer to be split between several recipients.
	// 
	access(all)
	resource Offer: OfferPublic{ 
		// The simple (non-Capability, non-complex) details of the offer
		access(self)
		let offerDetails: OfferDetails
		
		// A capability allowing this resource to withdraw the FungibleToken with the given amount
		// This capability allows the resource to withdraw *any* FungibleToken
		access(contract)
		var ftProviderCapability: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>
		
		// The NonFungibleToken capability of the user who made the offer that the nft will be deposited into
		access(all)
		let nftReceiverCapability: Capability<&{NonFungibleToken.CollectionPublic}>
		
		// getOfferDetails
		// Get the details of the current state of the Offer as a struct.
		//
		access(all)
		fun getOfferDetails(): OfferDetails{ 
			return self.offerDetails
		}
		
		// accept
		// function that accepts an offer, returning the nft
		// This pays the beneficiaries and transfers the nft to the user who made the offer
		// can only be called through the Offers resource
		access(all)
		fun accept(nft: @{NonFungibleToken.NFT}): @{FungibleToken.Vault}{ 
			pre{ 
				nft.isInstance(self.offerDetails.nftType):
					"payment vault is not requested fungible token"
				(self.ftProviderCapability.borrow()!).balance >= self.offerDetails.price:
					"payment vault does not have enough fungibletoken"
			}
			
			// Withdraw the payment amount from offer's FungibleToken capability
			let payment <- (self.ftProviderCapability.borrow()!).withdraw(amount: self.offerDetails.price)
			
			// check the NFT resource such that it gives us the correct type and id
			assert(nft.isInstance(self.offerDetails.nftType), message: "withdrawn NFT is not of specified type")
			assert(nft.id == self.offerDetails.nftID, message: "withdrawn NFT does not have specified ID")
			
			// get the offerID of the offer
			let offerID = self.offerDetails.offerID
			
			// Pay each beneficiary their amount of the payment.
			for cut in self.offerDetails.saleCuts{ 
				let cutAmount = TheFabricantMarketplace.nftSaleCount.containsKey(offerID) ? self.offerDetails.price * cut.amount : self.offerDetails.price * cut.initialAmount
				if let receiver = cut.receiver.borrow(){ 
					let paymentCut <- payment.withdraw(amount: cutAmount)
					receiver.deposit(from: <-paymentCut)
					emit RoyaltyDeposited(listingID: offerID, nftType: self.offerDetails.nftType, nftID: self.offerDetails.nftID, name: cut.name, amount: cutAmount, to: (receiver.owner!).address)
				}
			}
			(			 
			 // Send the nft to user that made the offer
			 self.nftReceiverCapability.borrow()!).deposit(token: <-nft)
			
			// Increment saleCount for the nft
			if TheFabricantMarketplace.nftSaleCount.containsKey(offerID){ 
				TheFabricantMarketplace.nftSaleCount[offerID] = TheFabricantMarketplace.nftSaleCount[offerID]! + 1
			} else{ 
				TheFabricantMarketplace.nftSaleCount[offerID] = 1
			}
			
			// return the rest of the paymenet
			return <-payment
		}
		
		// destructor
		//
		// initializer
		//
		init(offerID: String, ftProviderCapability: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>, offerPaymentVaultType: Type, nftReceiverCapability: Capability<&{NonFungibleToken.CollectionPublic}>, nftType: Type, nftID: UInt64, price: UFix64, saleCuts: [SaleCut], startTime: UFix64, endTime: UFix64){ 
			
			// Store the offer information
			self.offerDetails = OfferDetails(offerID: offerID, nftType: nftType, nftID: nftID, offerPaymentVaultType: offerPaymentVaultType, price: price, saleCuts: saleCuts, startTime: startTime, endTime: endTime)
			
			// Store the FungibleToken provider
			self.ftProviderCapability = ftProviderCapability
			
			// Store the nft receiver capability
			self.nftReceiverCapability = nftReceiverCapability
			
			// This precondition will assert if the fungibletoken is not available.
			let ft = ftProviderCapability.borrow()!
			assert(ft.isInstance(self.offerDetails.offerPaymentVaultType), message: "token is not of specified type")
		}
	}
	
	access(all)
	resource interface OffersManager{ 
		access(all)
		fun makeOffer(
			initialNFTOwner: Address,
			ftProviderCapability: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>,
			offerPaymentVaultType: Type,
			nftType: Type,
			nftID: UInt64,
			nftReceiverCapability: Capability<&{NonFungibleToken.CollectionPublic}>,
			price: UFix64,
			saleCuts: [
				SaleCut
			]
		): String
		
		access(all)
		fun removeOffer(offerID: String)
	}
	
	// OffersPublic
	// An interface to allow other users to get offers' details, and accept offers
	//
	access(all)
	resource interface OffersPublic{ 
		access(all)
		fun getOfferIDs(): [String]
		
		access(all)
		view fun borrowOffer(offerID: String): &Offer?
		
		access(all)
		fun acceptOffer(
			offerID: String,
			recipientCap: Capability<&{FungibleToken.Receiver}>,
			nft: @{NonFungibleToken.NFT}
		)
		
		access(all)
		view fun timeRemaining(offerID: String): Fix64
		
		access(all)
		fun removeExpiredOffers()
		
		access(all)
		view fun isOfferExpired(offerID: String): Bool
	}
	
	// Offers
	// resource that contains offers
	access(all)
	resource Offers: OffersPublic, OffersManager{ 
		
		// Dictionary of the offer details for each ItemNFT by offerID
		access(self)
		var offers: @{String: Offer}
		
		init(){ 
			self.offers <-{} 
			emit OffersInitialized(offersResourceID: self.uuid)
		}
		
		// destructor
		//
		// makeOffer
		// Create an offer for an nft if user has not already made an offer
		access(all)
		fun makeOffer(initialNFTOwner: Address, ftProviderCapability: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>, offerPaymentVaultType: Type, nftType: Type, nftID: UInt64, nftReceiverCapability: Capability<&{NonFungibleToken.CollectionPublic}>, price: UFix64, saleCuts: [SaleCut]): String{ 
			pre{ 
				ftProviderCapability.check():
					"Offerer's FungibleToken provider capability is invalid"
				nftReceiverCapability.check():
					"Offerer's NFT Receiver capability is invalid"
				self.offers[TheFabricantMarketplace.typeID(type: nftType, id: nftID)] == nil:
					"Offer for nft already made"
				(ftProviderCapability.borrow()!).balance >= price:
					"Offerer has insufficient FungibleToken balance"
			}
			
			// create the offerID for the offer
			let offerID = TheFabricantMarketplace.typeID(type: nftType, id: nftID)
			
			// create the offer
			let offer <- create Offer(offerID: offerID, ftProviderCapability: ftProviderCapability, offerPaymentVaultType: offerPaymentVaultType, nftReceiverCapability: nftReceiverCapability, nftType: nftType, nftID: nftID, price: price, saleCuts: saleCuts, startTime: getCurrentBlock().timestamp, endTime: getCurrentBlock().timestamp + TheFabricantMarketplace.offerDuration)
			
			// Add the new offer to the dictionary.
			let oldOffer <- self.offers[offerID] <- offer
			// Note that oldOffer will always be nil, but we have to handle it.
			destroy oldOffer
			emit NFTOfferMade(offerID: offerID, nftType: nftType, nftID: nftID, price: price, ftVaultType: offerPaymentVaultType, offerer: self.owner?.address!, initialNFTOwner: initialNFTOwner)
			return offerID
		}
		
		// Removes an offer from offer dictionary
		//
		// Parameters: offerID: the ID of the token to be removed
		access(all)
		fun removeOffer(offerID: String){ 
			let offer <- self.offers.remove(key: offerID) ?? panic("missing Offer")
			
			// Emit the event for remove an offer
			emit NFTOfferRemoved(offerID: offerID, offerer: self.owner?.address!)
			destroy offer
		}
		
		// acceptOffer lets a user transfer nft to user who made the offer, and be sent FungibleToken based on price
		// only if offer has not expired
		access(all)
		fun acceptOffer(offerID: String, recipientCap: Capability<&{FungibleToken.Receiver}>, nft: @{NonFungibleToken.NFT}){ 
			pre{ 
				self.offers[offerID] != nil:
					"No token matching this offerID is being offered!"
				self.isOfferExpired(offerID: offerID) == false:
					"Offer has expired"
			}
			
			// remove offer from offer dictionary
			let offer <- self.offers.remove(key: offerID) ?? panic("missing Offer")
			
			// call accept from Offer resource, return the remaining FungibleToken amount to be transferred to user
			let ft <- offer.accept(nft: <-nft)
			(			 
			 // deposit FungibleToken amount to user
			 recipientCap.borrow()!).deposit(from: <-ft)
			emit NFTOfferAccepted(offerID: offerID, offerer: self.owner?.address!, accepter: recipientCap.address)
			destroy offer
		}
		
		// borrowOffer
		// Returns a read-only view of the Offer for the given offerID if it is contained by this collection.
		//
		access(all)
		view fun borrowOffer(offerID: String): &Offer?{ 
			return &self.offers[offerID] as &Offer?
		}
		
		// getOfferIDs
		// Returns an array of the Offer IDs that are in the collection
		//
		access(all)
		fun getOfferIDs(): [String]{ 
			return self.offers.keys
		}
		
		// public function that anyone can call to remove offers that have expired 
		access(all)
		fun removeExpiredOffers(){ 
			for offerID in self.offers.keys{ 
				if self.isOfferExpired(offerID: offerID){ 
					self.removeOffer(offerID: offerID)
				}
			}
		}
		
		// get the time remaining of an NFT's offer
		access(all)
		view fun timeRemaining(offerID: String): Fix64{ 
			let offerDuration = TheFabricantMarketplace.offerDuration
			let offer = (self.borrowOffer(offerID: offerID)!).getOfferDetails()
			let endTime = offer.endTime
			let currentTime = getCurrentBlock().timestamp
			let remaining = Fix64(endTime) - Fix64(currentTime)
			return remaining
		}
		
		// check if offer of NFT has expired
		access(all)
		view fun isOfferExpired(offerID: String): Bool{ 
			let timeRemaining = self.timeRemaining(offerID: offerID)
			return timeRemaining <= Fix64(0.0)
		}
	}
	
	// createCollection returns a new collection resource to the caller
	access(all)
	fun createOffers(): @Offers{ 
		return <-create Offers()
	}
	
	// Admin
	// Admin can change the marketplace's channelfees capability or change offers' duration 
	access(all)
	resource Admin{ 
		
		// change contract royalty address
		access(all)
		fun setChannelFeeCap(channelFeeCap: Capability<&{FungibleToken.Receiver}>){ 
			pre{ 
				channelFeeCap.check():
					"Channel Fee FungibleToken Receiver Capability invalid"
			}
			TheFabricantMarketplace.channelFeeCap = channelFeeCap
			emit ChannelFeeCapSet(channelFeeCapAddress: channelFeeCap.address)
		}
		
		// change the duration of offers before they expire
		access(all)
		fun setOfferDuration(duration: UFix64){ 
			TheFabricantMarketplace.offerDuration = duration
			emit OfferDurationChanged(duration: duration)
		}
	}
	
	// get the amount of times each nft is sold/accepted by listing/offerID
	access(all)
	fun getNFTSaleCounts():{ String: UInt32}{ 
		return TheFabricantMarketplace.nftSaleCount
	}
	
	// get the amount of times an nft is sold/accepted by listing/offerID
	access(all)
	fun getNFTSaleCount(typeID: String): UInt32{ 
		return TheFabricantMarketplace.nftSaleCount[typeID]!
	}
	
	// return the channelFeeCapability of the marketplace
	access(all)
	fun getChannelFeeCap(): Capability<&{FungibleToken.Receiver}>?{ 
		return TheFabricantMarketplace.channelFeeCap
	}
	
	// concat an nft's type and id into a single stirng
	access(all)
	view fun typeID(type: Type, id: UInt64): String{ 
		return type.identifier.concat("_").concat(id.toString())
	}
	
	access(all)
	init(){ 
		self.ListingsPublicPath = /public/fabricantPublicTheFabricantMarketplaceListings0021
		self.ListingsStoragePath = /storage/fabricantStorageTheFabricantMarketplaceListings0021
		self.OffersPublicPath = /public/fabricantPubliceTheFabricantMarketplaceListings0021
		self.OffersStoragePath = /storage/fabricantStorageTheFabricantMarketplaceOffers0021
		self.AdminStoragePath = /storage/fabricantTheFabricantMarketplaceAdmin0021
		self.channelFeeCap = nil
		// Offers have a 48 hours expiration time
		self.offerDuration = 172800.0
		self.nftSaleCount ={} 
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		emit TheFabricantMarketplaceContractInitialized()
	}
}
