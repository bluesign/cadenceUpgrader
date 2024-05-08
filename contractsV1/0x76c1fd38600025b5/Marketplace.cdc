import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import ItemNFT from "../0xfc91de5e6566cc7c/ItemNFT.cdc"

import GarmentNFT from "../0xfc91de5e6566cc7c/GarmentNFT.cdc"

import MaterialNFT from "../0xfc91de5e6566cc7c/MaterialNFT.cdc"

import FBRC from "../0xfc91de5e6566cc7c/FBRC.cdc"

access(all)
contract Marketplace{ 
	
	// -----------------------------------------------------------------------
	// ItemNFT Market contract Event definitions
	// -----------------------------------------------------------------------
	
	// emitted when an ItemNFT is listed for sale
	access(all)
	event ItemListed(itemID: UInt64, price: UFix64, seller: Address?)
	
	// emitted when an ItemNFT listing is removed from the sale
	access(all)
	event ItemDelisted(itemID: UInt64, seller: Address?)
	
	// emitted when the price of a listed ItemNFT has changed
	access(all)
	event ItemPriceChanged(itemID: UInt64, newPrice: UFix64, seller: Address?)
	
	// emitted when an ItemNFT is purchased from the market
	access(all)
	event ItemPurchased(itemID: UInt64, price: UFix64, seller: Address?)
	
	// emitted when an offer is made for an ItemNFT
	access(all)
	event OfferCreated(itemID: UInt64, price: UFix64, buyer: Address?, itemAddress: Address?)
	
	// emitted when an offer is removed
	access(all)
	event OfferRemoved(itemID: UInt64, buyer: Address?, itemAddress: Address?)
	
	// emitted when the price of an offer has changed
	access(all)
	event OfferPriceChanged(itemID: UInt64, newPrice: UFix64, buyer: Address?)
	
	// emitted when an offer is accepted
	access(all)
	event ItemOfferAccepted(itemID: UInt64, price: UFix64, buyer: Address?, itemAddress: Address?)
	
	// emitted when admin changes offer duration
	access(all)
	event OfferDurationChanged(duration: UFix64)
	
	// royalty events emitted when an item is purchased or an offer is accepted
	access(all)
	event ItemRoyaltyDeposited(itemID: UInt64, amount: UFix64, to: Address?)
	
	access(all)
	event ArtistRoyaltyDeposited(itemID: UInt64, amount: UFix64, to: Address?)
	
	access(all)
	event MaterialRoyaltyDeposited(itemID: UInt64, amount: UFix64, to: Address?)
	
	access(all)
	event ContractRoyaltyDeposited(itemID: UInt64, amount: UFix64, to: Address?)
	
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
	
	access(all)
	let itemCollectionProviderPrivatePath: PrivatePath
	
	access(all)
	let flowTokenVaultProviderPrivatePath: PrivatePath
	
	// dictionary of itemIDs and how many times it has been sold
	access(self)
	var itemSaleCount:{ UInt64: UInt32}
	
	// the FlowToken capability that channel fee royalties will be transferred to 
	access(self)
	var contractCap: Capability<&FlowToken.Vault>
	
	// the duration of an offer until it expires
	access(all)
	var offerDuration: UFix64
	
	// SaleCut
	// A struct representing a recipient that must be sent a certain amount
	// of the payment when a token is sold.
	//
	access(all)
	struct SaleCut{ 
		// The receiver for the payment.
		access(all)
		let receiver: Capability<&{FungibleToken.Receiver}>
		
		// Royalty amounts are percentages
		// Initial sales will use initialAmount, secondary sales will use amount
		access(all)
		let initialAmount: UFix64
		
		// The amount of the payment in FlowToken that will be paid to the receiver.
		access(all)
		let amount: UFix64
		
		// initializer
		//
		init(
			receiver: Capability<&{FungibleToken.Receiver}>,
			initialAmount: UFix64,
			amount: UFix64
		){ 
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
		
		// The unique id of the ItemNFT
		access(all)
		let itemID: UInt64
		
		// The amount that must be paid in the specified FungibleToken.
		access(all)
		var price: UFix64
		
		// This specifies the division of payment between recipients.
		access(contract)
		var saleCuts: [SaleCut]
		
		// initializer
		//
		init(itemID: UInt64, saleCuts: [SaleCut], price: UFix64){ 
			self.itemID = itemID
			self.price = price
			self.saleCuts = saleCuts
		}
		
		// changes the price of the listing
		access(all)
		fun changePrice(newPrice: UFix64){ 
			self.price = newPrice
		}
		
		// gets the salecuts array
		access(all)
		fun getSaleCuts(): [SaleCut]{ 
			return self.saleCuts
		}
	}
	
	// ListingsPublic 
	//
	// The interface the a user can publish a capability to their sale
	// to allow others to access their sale
	access(all)
	resource interface ListingsPublic{ 
		access(all)
		fun getListings():{ UInt64: ListingDetails}
		
		access(all)
		fun getItemListingDetail(itemID: UInt64): Marketplace.ListingDetails
		
		access(all)
		fun borrowItem(itemID: UInt64): &ItemNFT.NFT?
		
		access(all)
		fun purchaseListing(
			itemID: UInt64,
			recipientCap: Capability<&{ItemNFT.ItemCollectionPublic}>,
			buyTokens: @{FungibleToken.Vault}
		)
		
		access(all)
		fun cleanUp()
	}
	
	access(all)
	resource Listings: ListingsPublic{ 
		
		// Dictionary of the listing details for each ItemNFT by ID
		access(self)
		var listings:{ UInt64: ListingDetails}
		
		// A capability allowing this resource to withdraw the ItemNFT with the given ID from its collection.
		access(contract)
		let itemProviderCapability: Capability<&ItemNFT.Collection>
		
		// The fungible token vault of the seller
		// so that when someone buys an ItemNFT, the tokens are deposited
		// to this Vault
		access(self)
		var ownerFlowTokenCapability: Capability<&FlowToken.Vault>
		
		init(itemProviderCapability: Capability<&ItemNFT.Collection>, ownerFlowTokenCapability: Capability<&FlowToken.Vault>){ 
			pre{ 
				// Check the FlowToken capability of seller
				ownerFlowTokenCapability.borrow() != nil:
					"Owner's FlowToken Receiver Capability is invalid!"
			}
			self.ownerFlowTokenCapability = ownerFlowTokenCapability
			self.itemProviderCapability = itemProviderCapability
			// listings dictionary is empty at start
			self.listings ={} 
		}
		
		// listForSale lists an ItemNFT for sale in this listings collection
		// at the specified price
		//
		// Parameters: token: The ItemNFT to be put up for sale
		//			 price: The price of the ItemNFT
		access(all)
		fun listForSale(itemID: UInt64, price: UFix64){ 
			pre{ 
				// Check that owner's FlowToken Capability is valid
				self.ownerFlowTokenCapability.borrow() != nil:
					"Owner's FlowToken Receiver Capability is invalid!"
				// Check item is not already listed
				self.listings[itemID] == nil:
					"Item is already listed"
			}
			
			// borrow itemRef
			let itemRef = (self.itemProviderCapability.borrow()!).borrowItem(id: itemID)! as &ItemNFT.NFT
			
			// get all FlowToken royalty capabilities
			let itemCap = getAccount(itemRef.royaltyVault.address).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
			let garmentCap = getAccount((itemRef.borrowGarment()!).royaltyVault.address).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
			let materialCap = getAccount((itemRef.borrowMaterial()!).royaltyVault.address).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
			
			// initialize sale cuts for item, garment, material and contract
			let saleCutArray = [SaleCut(receiver: itemCap, initialAmount: 0.30, amount: 0.1 / 3.0), SaleCut(receiver: garmentCap, initialAmount: 0.30, amount: 0.1 / 3.0), SaleCut(receiver: materialCap, initialAmount: 0.30, amount: 0.1 / 3.0), SaleCut(receiver: Marketplace.contractCap, initialAmount: 0.10, amount: 0.05)]
			
			// create listing
			self.listings[itemID] = ListingDetails(itemID: itemID, saleCuts: saleCutArray, price: price)
			emit ItemListed(itemID: itemID, price: price, seller: self.owner?.address)
		}
		
		// Withdraw removes a ItemNFT the was listed for sale
		// and clears its listing details
		//
		// Parameters: itemID: the ID of the token to withdraw from the sale
		//
		// Returns: @ItemNFT.NFT: The nft the was withdrawn from the sale
		access(all)
		fun removeListing(itemID: UInt64){ 
			pre{ 
				self.listings[itemID] != nil
			}
			
			//remove listing
			self.listings.remove(key: itemID)
			// Emit the event for removing a listing
			emit ItemDelisted(itemID: itemID, seller: self.owner?.address)
		}
		
		// purchase lets a user send FlowToken to purchase an NFT that is for sale
		access(all)
		fun purchaseListing(itemID: UInt64, recipientCap: Capability<&{ItemNFT.ItemCollectionPublic}>, buyTokens: @{FungibleToken.Vault}){ 
			pre{ 
				self.listings[itemID] != nil:
					"No token matching this itemID for sale!"
				buyTokens.balance == self.listings[itemID]?.price ?? 0.0:
					"Buy tokens not equal price!"
			}
			let recipient = recipientCap.borrow()!
			
			// get the price out of the optional
			let price = (self.listings[itemID]!).price
			
			// check owner FlowToken vault is valid
			let flowTokenVaultRef = self.ownerFlowTokenCapability.borrow() ?? panic("Could not borrow reference to owner token vault")
			
			// check seller NFT vault provider is valid
			let nftVaultRef = self.itemProviderCapability.borrow() ?? panic("Could not borrow reference to owner nft provider vault")
			
			// withdraw item from seller's NFT vault
			let item <- nftVaultRef.withdraw(withdrawID: itemID)
			
			// if this is the first time ItemNFT with id is sold or accepted, use cut.initialAmount to calculate royalty
			// if not, use cut.amount instead
			var count = 0 as Int
			for cut in (self.listings[itemID]!).saleCuts{ 
				let cutAmount = Marketplace.itemSaleCount.containsKey(itemID) ? price * cut.amount : price * cut.initialAmount
				if let receiver = cut.receiver.borrow(){ 
					let paymentCut <- buyTokens.withdraw(amount: cutAmount)
					switch count{ 
						case 0:
							emit ItemRoyaltyDeposited(itemID: itemID, amount: cutAmount, to: receiver.owner?.address)
						case 1:
							emit ArtistRoyaltyDeposited(itemID: itemID, amount: cutAmount, to: receiver.owner?.address)
						case 2:
							emit MaterialRoyaltyDeposited(itemID: itemID, amount: cutAmount, to: receiver.owner?.address)
						case 3:
							emit ContractRoyaltyDeposited(itemID: itemID, amount: cutAmount, to: receiver.owner?.address)
					}
					receiver.deposit(from: <-paymentCut)
				}
				count = count + 1 as Int
			}
			
			// increment the itemSaleCount
			if Marketplace.itemSaleCount.containsKey(itemID){ 
				Marketplace.itemSaleCount[itemID] = Marketplace.itemSaleCount[itemID]! + 1 as UInt32
			} else{ 
				Marketplace.itemSaleCount[itemID] = 1
			}
			
			//remove listing from listings map
			self.listings.remove(key: itemID)
			
			// deposit the purchasing flowToken tokens into the owners vault
			flowTokenVaultRef.deposit(from: <-buyTokens)
			
			// deposit the ItemNFT into the buyers collection
			recipient.deposit(token: <-item)
			emit ItemPurchased(itemID: itemID, price: price, seller: (flowTokenVaultRef.owner!).address)
		}
		
		//change the price of a listing with itemID
		access(all)
		fun changePrice(itemID: UInt64, newPrice: UFix64){ 
			(self.listings[itemID]!).changePrice(newPrice: newPrice)
			emit ItemPriceChanged(itemID: itemID, newPrice: newPrice, seller: self.owner?.address)
		}
		
		// cleanup
		// Remove all listings that are not in accounts collection anymore
		// Anyone can call, but at present it only benefits the account owner to do so.
		// Kind purchasers can however call it if they like.
		access(all)
		fun cleanUp(){ 
			let ref = (self.itemProviderCapability.borrow()!).getIDs()
			for itemID in self.listings.keys{ 
				if !ref.contains(itemID){ 
					self.removeListing(itemID: itemID)
				}
			}
		}
		
		// getPrice returns the price of a specific token in the sale
		// 
		// Parameters: itemID: The ID of the NFT whose price to get
		//
		// Returns: UFix64: The price of the token
		access(all)
		fun getListings():{ UInt64: ListingDetails}{ 
			return self.listings
		}
		
		// returns a single ItemNFT's listing details
		access(all)
		fun getItemListingDetail(itemID: UInt64): Marketplace.ListingDetails{ 
			return self.listings[itemID]!
		}
		
		// borrowItem Returns a borrowed reference to a Item in the collection
		// so the the caller can read data from it
		//
		// Parameters: id: The ID of the Item to borrow a reference to
		//
		// Returns: &ItemNFT.NFT? Optional reference to a Item for sale 
		//						so the the caller can read its data
		//
		access(all)
		fun borrowItem(itemID: UInt64): &ItemNFT.NFT?{ 
			let ref = (self.itemProviderCapability.borrow()!).borrowItem(id: itemID)! as &ItemNFT.NFT
			return ref
		}
	}
	
	access(all)
	fun createListings(
		itemProviderCapability: Capability<&ItemNFT.Collection>,
		ownerFlowTokenCapability: Capability<&FlowToken.Vault>
	): @Listings{ 
		return <-create Listings(
			itemProviderCapability: itemProviderCapability,
			ownerFlowTokenCapability: ownerFlowTokenCapability
		)
	}
	
	// OfferDetails
	// A struct containing an Offer's data.
	//
	access(all)
	struct OfferDetails{ 
		access(all)
		let address: Address
		
		access(all)
		let itemID: UInt64
		
		access(all)
		var price: UFix64
		
		access(all)
		let startTime: UFix64
		
		access(all)
		let endTime: UFix64
		
		// This specifies the division of payment between recipients.
		access(contract)
		var saleCuts: [SaleCut]
		
		// initializer
		//
		init(
			address: Address,
			itemID: UInt64,
			saleCuts: [
				SaleCut
			],
			price: UFix64,
			startTime: UFix64,
			endTime: UFix64
		){ 
			self.address = address
			self.itemID = itemID
			self.price = price
			self.startTime = startTime
			self.endTime = endTime
			self.saleCuts = saleCuts
		}
		
		//change the price of an offer with itemID
		access(all)
		fun changePrice(newPrice: UFix64){ 
			self.price = newPrice
		}
		
		// gets the salecuts array
		access(all)
		fun getSaleCuts(): [SaleCut]{ 
			return self.saleCuts
		}
	}
	
	access(all)
	resource interface OffersPublic{ 
		access(all)
		fun getOffers():{ UInt64: OfferDetails}
		
		access(all)
		fun getItemOfferDetail(itemID: UInt64): Marketplace.OfferDetails
		
		access(all)
		fun acceptOffer(ownerVault: Capability<&FlowToken.Vault>, item: @ItemNFT.NFT)
		
		access(all)
		view fun timeRemaining(itemID: UInt64): Fix64
		
		access(all)
		fun removeExpiredOffers()
		
		access(all)
		view fun isOfferExpired(itemID: UInt64): Bool
	}
	
	access(all)
	resource Offers: OffersPublic{ 
		
		// Dictionary of the offer details for each ItemNFT by ID
		access(self)
		var offers:{ UInt64: OfferDetails}
		
		// A capability allowing this resource to withdraw FlowToken from its vault for payment if an offer is accepted
		access(contract)
		var flowTokenProviderCapability: Capability<&FlowToken.Vault>
		
		// The item vault capability of the offerer
		// so that when someone accepts an offer, the item is deposited
		// to this Vault
		access(self)
		var itemVaultCapability: Capability<&{ItemNFT.ItemCollectionPublic}>
		
		init(itemVaultCapability: Capability<&{ItemNFT.ItemCollectionPublic}>, flowTokenProviderCapability: Capability<&FlowToken.Vault>){ 
			pre{ 
				// Check the Item capability of seller
				itemVaultCapability.borrow() != nil:
					"Owner's Item Vault Capability is invalid!"
			}
			self.itemVaultCapability = itemVaultCapability
			self.flowTokenProviderCapability = flowTokenProviderCapability
			self.offers ={} 
		}
		
		// listForSale lists an ItemNFT for sale in this sale collection
		// at the specified price
		//
		// Parameters: token: The ItemNFT to be put up for sale
		//			 price: The price of the ItemNFT
		access(all)
		fun makeOffer(itemAddress: Address, itemID: UInt64, price: UFix64){ 
			pre{ 
				// Check the Item capability of seller
				self.itemVaultCapability.borrow() != nil:
					"Owner's Item Vault Capability is invalid!"
				
				// Check that offer of Item with ID is not already made
				self.offers[itemID] == nil:
					"Offer of this item already made"
			}
			
			// from the itemAddress borrow the details of the item
			let collectionRef = getAccount(itemAddress).capabilities.get<&{ItemNFT.ItemCollectionPublic}>(ItemNFT.CollectionPublicPath).borrow<&{ItemNFT.ItemCollectionPublic}>()!
			let tokenRef = collectionRef.borrowItem(id: itemID)! as &ItemNFT.NFT
			
			// get the FlowToken capabilities
			let itemCap = getAccount(tokenRef.royaltyVault.address).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
			let garmentCap = getAccount((tokenRef.borrowGarment()!).royaltyVault.address).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
			let materialCap = getAccount((tokenRef.borrowMaterial()!).royaltyVault.address).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
			
			// initialize sale cuts for item, garment, material and contract
			let saleCutArray = [SaleCut(receiver: itemCap, initialAmount: 0.30, amount: 0.1 / 3.0), SaleCut(receiver: garmentCap, initialAmount: 0.30, amount: 0.1 / 3.0), SaleCut(receiver: materialCap, initialAmount: 0.30, amount: 0.1 / 3.0), SaleCut(receiver: Marketplace.contractCap, initialAmount: 0.10, amount: 0.05)]
			let offerDetails = OfferDetails(address: itemAddress, itemID: itemID, saleCuts: saleCutArray, price: price, startTime: getCurrentBlock().timestamp, endTime: getCurrentBlock().timestamp + Marketplace.offerDuration)
			
			// add the offer into offer dictionary 
			self.offers[itemID] = offerDetails
			emit OfferCreated(itemID: itemID, price: price, buyer: self.owner?.address, itemAddress: itemAddress)
		}
		
		// Removes an offer from offer dictionary
		//
		// Parameters: itemID: the ID of the token to be removed
		access(all)
		fun removeOffer(itemID: UInt64){ 
			pre{ 
				self.offers[itemID] != nil
			}
			let itemAddress = (self.offers[itemID]!).address
			self.offers.remove(key: itemID)
			// Emit the event for withdrawing a Item from the Sale
			emit OfferRemoved(itemID: itemID, buyer: self.owner?.address, itemAddress: itemAddress)
		}
		
		// accept lets a user send NFT to user who made an offer for it
		// FlowToken vault of offerer needs to have a balance higher than offer price
		// Offer needs to not have expired to be accepted
		access(all)
		fun acceptOffer(ownerVault: Capability<&FlowToken.Vault>, item: @ItemNFT.NFT){ 
			pre{ 
				self.offers[item.id] != nil:
					"No token matching this ID has an offer!"
				(self.flowTokenProviderCapability.borrow()!).balance >= (self.offers[item.id]!).price:
					"Offerer does not have enough FlowToken"
				self.isOfferExpired(itemID: item.id) == false:
					"Offer has expired"
			}
			let itemID = item.id
			
			// get the price out of the optional and withdraw the amount from buyer's flowToken Vault
			let price = (self.offers[itemID]!).price
			
			// withdraw the flow tokens from offerer's FlowToken vault
			let flowTokenVaultRef = self.flowTokenProviderCapability.borrow() ?? panic("Could not borrow reference to owner flowToken provider vault")
			let flowToken <- flowTokenVaultRef.withdraw(amount: price)
			
			// if this is the first time ItemNFT with id is sold or accepted, use cut.initialAmount to calculate royalty
			// if not, use cut.amount instead
			var count = 0 as Int
			for cut in (self.offers[itemID]!).saleCuts{ 
				let cutAmount = Marketplace.itemSaleCount.containsKey(itemID) ? price * cut.amount : price * cut.initialAmount
				if let receiver = cut.receiver.borrow(){ 
					let paymentCut <- flowToken.withdraw(amount: cutAmount)
					switch count{ 
						case 0:
							emit ItemRoyaltyDeposited(itemID: itemID, amount: cutAmount, to: receiver.owner?.address)
						case 1:
							emit ArtistRoyaltyDeposited(itemID: itemID, amount: cutAmount, to: receiver.owner?.address)
						case 2:
							emit MaterialRoyaltyDeposited(itemID: itemID, amount: cutAmount, to: receiver.owner?.address)
						case 3:
							emit ContractRoyaltyDeposited(itemID: itemID, amount: cutAmount, to: receiver.owner?.address)
					}
					receiver.deposit(from: <-paymentCut)
				}
				count = count + 1 as Int
			}
			
			// increment the itemSaleCount
			if Marketplace.itemSaleCount.containsKey(itemID){ 
				Marketplace.itemSaleCount[itemID] = Marketplace.itemSaleCount[itemID]! + 1 as UInt32
			} else{ 
				Marketplace.itemSaleCount[itemID] = 1
			}
			(			 
			 // deposit the remaining flowToken tokens into the owner's vault
			 ownerVault.borrow()!).deposit(from: <-flowToken)
			
			// check owner NFT vault is valid then deposit item
			let nftVaultRef = self.itemVaultCapability.borrow()!
			nftVaultRef.deposit(token: <-item)
			
			// clear offer from offers
			self.offers.remove(key: itemID)
			emit ItemOfferAccepted(itemID: itemID, price: price, buyer: self.owner?.address, itemAddress: ownerVault.address)
		}
		
		// changes the price of the offer
		access(all)
		fun changePrice(itemID: UInt64, newPrice: UFix64){ 
			(self.offers[itemID]!).changePrice(newPrice: newPrice)
			emit OfferPriceChanged(itemID: itemID, newPrice: newPrice, buyer: self.owner?.address)
		}
		
		// public function that anyone can call to remove offers that have expired 
		access(all)
		fun removeExpiredOffers(){ 
			for itemID in self.offers.keys{ 
				if self.isOfferExpired(itemID: itemID){ 
					self.offers.remove(key: itemID)
				}
			}
		}
		
		// getOffers returns all offerdetails
		access(all)
		fun getOffers():{ UInt64: OfferDetails}{ 
			return self.offers
		}
		
		// returns a single ItemNFT's offerdetails
		access(all)
		fun getItemOfferDetail(itemID: UInt64): Marketplace.OfferDetails{ 
			return self.offers[itemID]!
		}
		
		// get the time remaining of an ItemNFT's offer
		access(all)
		view fun timeRemaining(itemID: UInt64): Fix64{ 
			let offerDuration = Marketplace.offerDuration
			let endTime = (self.offers[itemID]!).endTime
			let currentTime = getCurrentBlock().timestamp
			let remaining = Fix64(endTime) - Fix64(currentTime)
			return remaining
		}
		
		// Check if offer of ItemNFT has expired
		access(all)
		view fun isOfferExpired(itemID: UInt64): Bool{ 
			let timeRemaining = self.timeRemaining(itemID: itemID)
			return timeRemaining <= Fix64(0.0)
		}
	}
	
	// createCollection returns a new collection resource to the caller
	access(all)
	fun createOffers(
		itemVaultCapability: Capability<&{ItemNFT.ItemCollectionPublic}>,
		flowTokenProviderCapability: Capability<&FlowToken.Vault>
	): @Offers{ 
		return <-create Offers(
			itemVaultCapability: itemVaultCapability,
			flowTokenProviderCapability: flowTokenProviderCapability
		)
	}
	
	access(all)
	resource Admin{ 
		
		// change contract royalty address
		access(all)
		fun setContractRoyaltyCap(contractCap: Capability<&FlowToken.Vault>){ 
			pre{ 
				contractCap.borrow() != nil:
					"Contract FlowToken Vault Capability invalid"
			}
			Marketplace.contractCap = contractCap
		}
		
		// change the duration of offers before they expire
		access(all)
		fun setOfferDuration(duration: UFix64){ 
			Marketplace.offerDuration = duration
			emit OfferDurationChanged(duration: duration)
		}
	}
	
	// borrow contract capability
	access(all)
	fun borrowContractCap(): &FlowToken.Vault?{ 
		return Marketplace.contractCap.borrow()
	}
	
	// get the amount of times each item is sold/accepted
	access(all)
	fun getItemsSaleCount():{ UInt64: UInt32}{ 
		return Marketplace.itemSaleCount
	}
	
	// get the amount of times an item is sold/accepted
	access(all)
	fun getItemSaleCount(itemID: UInt64): UInt32{ 
		return Marketplace.itemSaleCount[itemID]!
	}
	
	access(all)
	init(){ 
		self.ListingsPublicPath = /public/fabricantPublicMarketplaceListings0001
		self.ListingsStoragePath = /storage/fabricantStorageMarketplaceListings0001
		self.OffersPublicPath = /public/fabricantPubliceMarketplaceListings0001
		self.OffersStoragePath = /storage/fabricantStorageMarketplaceOffers0001
		self.AdminStoragePath = /storage/fabricantMarketplaceAdmin0001
		self
			.itemCollectionProviderPrivatePath = /private/fabricantMarketplaceItemCollectionProvider0001
		self
			.flowTokenVaultProviderPrivatePath = /private/fabricantMarketplaceFlowTokenVaultProvider0001
		
		// Offers have a 48 hours expiration time
		self.offerDuration = 172800.0
		self.itemSaleCount ={} 
		
		// setup deployer FlowToken account as marketplace royalty account
		if self.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) == nil{ 
			// Create the Vault with the total supply of tokens and save it in storage
			//
			let vault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
			self.account.storage.save(<-vault, to: /storage/flowTokenVault)
			var capability_1 = self.account.capabilities.storage.issue<&FlowToken.Vault>(/storage/flowTokenVault)
			self.account.capabilities.publish(capability_1, at: /public/flowTokenReceiver)
			
			// Create a public capability to the stored Vault that only exposes
			// the `balance` field through the `Balance` interface
			//
			var capability_2 = self.account.capabilities.storage.issue<&FlowToken.Vault>(/storage/flowTokenVault)
			self.account.capabilities.publish(capability_2, at: /public/flowTokenBalance)
		}
		// check that deployer's FlowToken capability is valid
		let flowTokenCapCheck =
			self.account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver).borrow()!
		self.contractCap = self.account.capabilities.get<&FlowToken.Vault>(
				/public/flowTokenReceiver
			)!
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
	}
}
