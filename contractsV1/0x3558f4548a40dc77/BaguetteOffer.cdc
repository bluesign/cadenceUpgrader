/** 

# BaguetteOffer contract

This contract defines the offer system of Baguette. 
The offer contract acts as an escrow for fungible tokens which can be exchange when presented the corresponding Record.
Offers are centralized in OfferCollection maintained by admins.  

## Withdrawals and cancelations

Offers can be cancelled by the offeror.

## Create an offer
An Offer is created within an OfferCollection. An OfferCollection can be created in two ways:
- by the contract Admin, who can choose the offer parameters. 
- by an Manager who has been initialized by an Admin. The different parameters are fixed at creation by the Admin to the contract parameters at that time.

## Accepting an offer

A seller can present an NFT with a corresponding offer and has two solutions to accept it:
- direct sale
- accept the offer as a first bid of an auction
*/

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import Record from "./Record.cdc"

import ArtistRegistery from "./ArtistRegistery.cdc"

import BaguetteAuction from "./BaguetteAuction.cdc"

access(all)
contract BaguetteOffer{ 
	
	// -----------------------------------------------------------------------
	// Variables 
	// -----------------------------------------------------------------------
	
	// Resource paths
	// Public path of an offer collection, allowing the place new offers and to access to public information
	access(all)
	let CollectionPublicPath: PublicPath
	
	// Storage path of an offer collection
	access(all)
	let CollectionStoragePath: StoragePath
	
	// Manager public path, allowing an Admin to initialize it
	access(all)
	let ManagerPublicPath: PublicPath
	
	// Manager storage path, for a manager to create offer collections
	access(all)
	let ManagerStoragePath: StoragePath
	
	// Offeror storage path
	access(all)
	let OfferorStoragePath: StoragePath
	
	// Admin storage path
	access(all)
	let AdminStoragePath: StoragePath
	
	// Admin private path, allowing initialized AuctionManager to create collections while hidding other admin functions
	access(all)
	let AdminPrivatePath: PrivatePath
	
	// Default parameters for offers
	access(all)
	var parameters: OfferParameters
	
	access(self)
	var marketVault: Capability<&FUSD.Vault>?
	
	access(self)
	var lostFVault: Capability<&FUSD.Vault>?
	
	access(self)
	var lostRCollection: Capability<&Record.Collection>?
	
	// total number of offers ever created
	access(all)
	var totalOffers: UInt64
	
	// -----------------------------------------------------------------------
	// Events 
	// -----------------------------------------------------------------------
	// A new offer has been made
	access(all)
	event NewOffer(offerID: UInt64, admin: Address, status: OfferStatus)
	
	// The offer had been canceled
	access(all)
	event OfferCanceled(offerID: UInt64)
	
	// The offer has been accepted directly
	access(all)
	event AcceptedDirectly(offerID: UInt64)
	
	// The offer has been accepted as first bid
	access(all)
	event AcceptedAsBid(offerID: UInt64)
	
	// Market and Artist share
	access(all)
	event MarketplaceEarned(offerID: UInt64, amount: UFix64, owner: Address)
	
	access(all)
	event ArtistEarned(offerID: UInt64, amount: UFix64, artistID: UInt64)
	
	// lost and found events
	access(all)
	event FUSDLostAndFound(offerID: UInt64, amount: UFix64, address: Address)
	
	access(all)
	event RecordLostAndFound(offerID: UInt64, recordID: UInt64, address: Address)
	
	// -----------------------------------------------------------------------
	// Resources 
	// -----------------------------------------------------------------------
	// Structure representing offer parameters
	access(all)
	struct OfferParameters{ 
		access(all)
		let artistCut: UFix64 // share of the artist for a sale
		
		
		access(all)
		let marketCut: UFix64 // share of the marketplace for a sale
		
		
		access(all)
		let offerIncrement: UFix64 // minimal increment between offers
		
		
		access(all)
		let timeBeforeCancel: UFix64 // minimal amount of time before an offer can be canceled
		
		
		init(
			artistCut: UFix64,
			marketCut: UFix64,
			offerIncrement: UFix64,
			timeBeforeCancel: UFix64
		){ 
			self.artistCut = artistCut
			self.marketCut = marketCut
			self.offerIncrement = offerIncrement
			self.timeBeforeCancel = timeBeforeCancel
		}
	}
	
	// This structure holds the main information about an offer
	access(all)
	struct OfferStatus{ 
		access(all)
		let id: UInt64
		
		access(all)
		let recordID: UInt64
		
		access(all)
		let offeror: Address
		
		access(all)
		let offer: UFix64
		
		access(all)
		let nextMinOffer: UFix64
		
		access(all)
		let offerIncrement: UFix64
		
		init(
			id: UInt64,
			recordID: UInt64,
			offeror: Address,
			offer: UFix64,
			nextMinOffer: UFix64,
			offerIncrement: UFix64
		){ 
			self.id = id
			self.recordID = recordID
			self.offeror = offeror
			self.offer = offer
			self.nextMinOffer = nextMinOffer
			self.offerIncrement = offerIncrement
		}
	}
	
	// Resource representing a unique Offer
	access(all)
	resource Offer{ 
		access(all)
		let creationTime: UFix64
		
		access(all)
		let offerID: UInt64
		
		access(all)
		let recordID: UInt64
		
		access(all)
		let parameters: OfferParameters
		
		access(self)
		let offer: UFix64
		
		access(self)
		let offeror: Address
		
		access(self)
		let escrow: @FUSD.Vault
		
		access(self)
		var isValid: Bool
		
		//the capabilities pointing to the resource where you want the NFT
		access(self)
		var offerorFVault: Capability<&FUSD.Vault>
		
		access(self)
		var offerorRCollection: Capability<&Record.Collection>
		
		init(
			parameters: OfferParameters,
			recordID: UInt64,
			offerTokens: @{FungibleToken.Vault},
			offerorFVault: Capability<&FUSD.Vault>,
			offerorRCollection: Capability<&Record.Collection>
		){ 
			pre{ 
				offerorFVault.check():
					"The fungible vault should be valid."
				offerorRCollection.check():
					"The non fungible collection should be valid."
			}
			self.creationTime = getCurrentBlock().timestamp
			BaguetteOffer.totalOffers = BaguetteOffer.totalOffers + 1 as UInt64
			self.offerID = BaguetteOffer.totalOffers
			self.parameters = parameters
			self.recordID = recordID
			self.escrow <- offerTokens as! @FUSD.Vault
			self.offer = self.escrow.balance
			self.offeror = offerorFVault.address
			self.offerorFVault = offerorFVault
			self.offerorRCollection = offerorRCollection
			self.isValid = true
		}
		
		// sendNFT sends the NFT to the Collection belonging to the provided Capability or to the lost and found if the capability is broken
		// if both the receiver collection and lost and found are unlinked, the record is destroyed
		access(self)
		fun sendNFT(record: @Record.NFT, rCollection: Capability<&Record.Collection>){ 
			if let collectionRef = rCollection.borrow(){ 
				collectionRef.deposit(token: <-record)
				return
			}
			if let collectionRef = (BaguetteOffer.lostRCollection!).borrow(){ 
				let recordID = record.id
				collectionRef.deposit(token: <-record)
				emit RecordLostAndFound(offerID: self.offerID, recordID: recordID, address: (collectionRef.owner!).address)
				return
			}
			
			// should never happen in practice
			destroy record
		}
		
		// sendOfferTokens sends the bid tokens to the Vault Receiver belonging to the provided Capability
		access(self)
		fun sendOfferTokens(_ capability: Capability<&FUSD.Vault>){ 
			if let vaultRef = capability.borrow(){ 
				if self.escrow.balance > 0.0{ 
					vaultRef.deposit(from: <-self.escrow.withdraw(amount: self.escrow.balance))
				}
				return
			} else if let vaultRef = (BaguetteOffer.lostFVault!).borrow(){ 
				let balance = self.escrow.balance
				if balance > 0.0{ 
					vaultRef.deposit(from: <-self.escrow.withdraw(amount: balance))
					emit FUSDLostAndFound(offerID: self.offerID, amount: balance, address: (vaultRef.owner!).address)
				}
				return
			}
		}
		
		// Send the previous bid back to the last bidder
		access(contract)
		fun cancelOffer(){ 
			pre{ 
				self.isValid:
					"Offer is not valid."
			}
			self.isValid = false
			self.sendOfferTokens(self.offerorFVault)
		}
		
		// Accept the offer directly
		access(contract)
		fun acceptOffer(record: @Record.NFT, ownerFVault: Capability<&FUSD.Vault>){ 
			pre{ 
				record.tradable():
					"The item cannot be traded due to its current locked mode: it is probably waiting for its decryption key."
				self.isValid:
					"Offer is not valid."
			}
			let amountMarket = self.offer * self.parameters.marketCut
			let amountArtist = self.offer * self.parameters.artistCut
			let marketCut <- self.escrow.withdraw(amount: amountMarket)
			let artistCut <- self.escrow.withdraw(amount: amountArtist)
			let marketVault =
				(BaguetteOffer.marketVault!).borrow() ?? panic("The market vault link is broken.")
			marketVault.deposit(from: <-marketCut)
			emit MarketplaceEarned(
				offerID: self.offerID,
				amount: amountMarket,
				owner: (marketVault.owner!).address
			)
			let artistID = record.metadata.artistID
			ArtistRegistery.sendArtistShare(id: artistID, deposit: <-artistCut)
			emit ArtistEarned(offerID: self.offerID, amount: amountArtist, artistID: artistID)
			self.sendOfferTokens(ownerFVault)
			self.sendNFT(record: <-record, rCollection: self.offerorRCollection)
			self.isValid = false
			emit AcceptedDirectly(offerID: self.offerID)
		}
		
		// create an auction with the offer as first bid
		// if the offeror vault and collections are not valid anymore, it could block the function
		// instead, the tokens are sent to LostAndFound, and the NFT returned to the owner,
		// to deter bad behavior
		access(contract)
		fun acceptAuctionOffer(
			auctionCollection: &BaguetteAuction.Collection,
			record: @Record.NFT,
			ownerFVault: Capability<&FUSD.Vault>,
			ownerRCollection: Capability<&Record.Collection>
		){ 
			pre{ 
				record.tradable():
					"The item cannot be traded due to its current locked mode: it is probably waiting for its decryption key."
				self.isValid:
					"Offer is not valid."
			}
			if !self.offerorFVault.check() || !self.offerorRCollection.check(){ 
				self.sendOfferTokens(BaguetteOffer.lostFVault!)
				self.sendNFT(record: <-record, rCollection: ownerRCollection)
				self.isValid = false
				return
			}
			let recordID = record.id
			auctionCollection.createAuction(
				record: <-record,
				startPrice: self.offer,
				ownerFVault: ownerFVault,
				ownerRCollection: ownerRCollection
			)
			auctionCollection.placeBid(
				recordID: recordID,
				bidTokens: <-self.escrow.withdraw(amount: self.offer),
				fVault: self.offerorFVault,
				rCollection: self.offerorRCollection
			)
			self.isValid = false
			emit AcceptedAsBid(offerID: self.offerID)
		}
		
		// What the next offer has to match
		access(all)
		fun minNextOffer(): UFix64{ 
			return self.offer + self.parameters.offerIncrement
		}
		
		// Get the auction status
		// Will fail is offer is not valid
		// It is worthless and should be destroyed
		access(all)
		fun getOfferStatus(): OfferStatus{ 
			pre{ 
				self.isValid:
					"Offer is not valid."
			}
			return OfferStatus(
				id: self.offerID,
				recordID: self.recordID,
				offeror: self.offeror,
				offer: self.offer,
				nextMinOffer: self.minNextOffer(),
				offerIncrement: self.parameters.offerIncrement
			)
		}
	}
	
	// CollectionPublic
	//
	// Public methods of an OfferCollection, getting status of offers
	//
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		let parameters: OfferParameters
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun getOfferStatus(_ recordID: UInt64): OfferStatus
	}
	
	// Seller
	//
	// Interface exposing functions to accept an offer
	//
	access(all)
	resource interface Seller{ 
		access(all)
		let parameters: OfferParameters
		
		access(all)
		fun acceptDirectOffer(record: @Record.NFT, ownerFVault: Capability<&FUSD.Vault>)
		
		access(all)
		fun acceptAuctionOffer(
			record: @Record.NFT,
			ownerFVault: Capability<&FUSD.Vault>,
			ownerRCollection: Capability<&Record.Collection>
		)
	}
	
	// Offeror
	//
	// Interface exposing function to post or cancel an offer
	//
	access(all)
	resource interface Offeror{ 
		access(contract)
		fun addOffer(
			recordID: UInt64,
			offerTokens: @{FungibleToken.Vault},
			offerorFVault: Capability<&FUSD.Vault>,
			offerorRCollection: Capability<&Record.Collection>
		)
		
		access(contract)
		fun cancelOffer(recordID: UInt64, offerID: UInt64)
	}
	
	// AuctionCreatorClient
	//
	// Allows to receive an auctionCreator capability to create auctions when accepting offers
	//
	access(all)
	resource interface AuctionCreatorClient{ 
		access(all)
		fun addCapability(_ cap: Capability<&BaguetteAuction.Collection>)
	}
	
	// Collection
	//
	// Collection allowing to create new auctions
	//
	access(all)
	resource Collection: CollectionPublic, Seller, Offeror, AuctionCreatorClient{ 
		access(all)
		let parameters: OfferParameters
		
		access(self)
		var auctionServer: Capability<&BaguetteAuction.Collection>?
		
		access(self)
		var auctionServerAccepted: UInt64?
		
		// Auction Items, where the key is the recordID
		access(self)
		var offerItems: @{UInt64: Offer}
		
		init(parameters: OfferParameters){ 
			self.offerItems <-{} 
			self.parameters = parameters
			self.auctionServer = nil
			self.auctionServerAccepted = nil
		}
		
		access(all)
		fun setAuctionServerAccepted(serverID: UInt64){ 
			self.auctionServerAccepted = serverID
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.offerItems.keys
		}
		
		access(all)
		fun getOfferStatus(_ recordID: UInt64): OfferStatus{ 
			pre{ 
				self.offerItems[recordID] != nil:
					"NFT doesn't exist"
			}
			
			// Get the auction item resources
			return self.offerItems[recordID]?.getOfferStatus()!
		}
		
		access(all)
		fun acceptDirectOffer(record: @Record.NFT, ownerFVault: Capability<&FUSD.Vault>){ 
			pre{ 
				self.offerItems[record.id] != nil:
					"NFT doesn't exist"
			}
			let recordID = record.id
			let itemRef = &self.offerItems[recordID] as &BaguetteOffer.Offer?
			itemRef.acceptOffer(record: <-record, ownerFVault: ownerFVault)
			destroy self.offerItems.remove(key: recordID)!
		}
		
		access(all)
		fun acceptAuctionOffer(record: @Record.NFT, ownerFVault: Capability<&FUSD.Vault>, ownerRCollection: Capability<&Record.Collection>){ 
			pre{ 
				self.offerItems[record.id] != nil:
					"NFT doesn't exist"
				self.auctionServer != nil:
					"Auction server not set"
				(self.auctionServer!).check():
					"Auction server link broken"
			}
			let recordID = record.id
			let itemRef = &self.offerItems[recordID] as &BaguetteOffer.Offer?
			itemRef.acceptAuctionOffer(auctionCollection: (self.auctionServer!).borrow()!, record: <-record, ownerFVault: ownerFVault, ownerRCollection: ownerRCollection)
			destroy self.offerItems.remove(key: recordID)!
		}
		
		access(contract)
		fun addOffer(recordID: UInt64, offerTokens: @{FungibleToken.Vault}, offerorFVault: Capability<&FUSD.Vault>, offerorRCollection: Capability<&Record.Collection>){ 
			// check if there is an existing offer
			if self.offerItems[recordID] != nil{ 
				let itemRef = &self.offerItems[recordID] as &BaguetteOffer.Offer?
				if itemRef.getOfferStatus().nextMinOffer > offerTokens.balance{ 
					panic("The offer is not high enough")
				}
				let id = itemRef.offerID
				itemRef.cancelOffer()
				destroy self.offerItems.remove(key: recordID)!
				emit OfferCanceled(offerID: id)
			}
			let offer <- create Offer(parameters: self.parameters, recordID: recordID, offerTokens: <-offerTokens, offerorFVault: offerorFVault, offerorRCollection: offerorRCollection)
			let offerStatus = offer.getOfferStatus()
			let old <- self.offerItems[recordID] <- offer
			destroy old
			emit NewOffer(offerID: offerStatus.id, admin: self.owner?.address!, status: offerStatus)
		}
		
		access(contract)
		fun cancelOffer(recordID: UInt64, offerID: UInt64){ 
			pre{ 
				self.offerItems[recordID] != nil:
					"No offer for this item."
			}
			let itemRef = &self.offerItems[recordID] as &BaguetteOffer.Offer?
			if itemRef.offerID != offerID{ 
				panic("The ID of the offer does not match the current offer on this item.")
			}
			if itemRef.creationTime + self.parameters.timeBeforeCancel > getCurrentBlock().timestamp{ 
				panic("The offer cannot be canceled yet.")
			}
			let id = itemRef.offerID
			itemRef.cancelOffer()
			destroy self.offerItems.remove(key: recordID)!
			emit OfferCanceled(offerID: id)
		}
		
		access(all)
		fun addCapability(_ cap: Capability<&BaguetteAuction.Collection>){ 
			pre{ 
				cap.check():
					"Invalid server capablity"
				self.auctionServer == nil:
					"Server already set"
				self.auctionServerAccepted != nil:
					"No auction server can be accepted yet"
				(cap.borrow()!).collectionID == self.auctionServerAccepted!:
					"This is not the correct auction server"
			}
			self.auctionServer = cap
		}
	}
	
	// CollectionCreator
	//
	// An auction collection creator can create offer collection with default parameters
	//
	access(all)
	resource interface CollectionCreator{ 
		access(all)
		fun createOfferCollection(): @Collection
	}
	
	// Admin
	//
	// Admin can change the default Offer parameters, the market vault and create custom collections
	//
	access(all)
	resource Admin: CollectionCreator{ 
		access(all)
		fun setParameters(parameters: OfferParameters){ 
			BaguetteOffer.parameters = parameters
		}
		
		access(all)
		fun setMarketVault(marketVault: Capability<&FUSD.Vault>){ 
			pre{ 
				marketVault.check():
					"The market vault should be valid."
			}
			BaguetteOffer.marketVault = marketVault
		}
		
		access(all)
		fun setLostAndFoundVaults(fVault: Capability<&FUSD.Vault>, rCollection: Capability<&Record.Collection>){ 
			pre{ 
				fVault.check():
					"The fungible token vault should be valid."
				rCollection.check():
					"The NFT collection should be valid."
			}
			BaguetteOffer.lostFVault = fVault
			BaguetteOffer.lostRCollection = rCollection
		}
		
		// create collection with default parameters
		access(all)
		fun createOfferCollection(): @Collection{ 
			return <-create Collection(parameters: BaguetteOffer.parameters)
		}
		
		// create collection with custom parameters
		access(all)
		fun createCustomOfferCollection(parameters: OfferParameters): @Collection{ 
			return <-create Collection(parameters: parameters)
		}
	}
	
	// ManagerClient
	//
	// This interface is used to add a Admin capability to a client
	//
	access(all)
	resource interface ManagerClient{ 
		access(all)
		fun addCapability(_ cap: Capability<&Admin>)
	}
	
	// Manager
	//
	// An Manager can create OfferCollection with the default parameters
	//
	access(all)
	resource Manager: ManagerClient, CollectionCreator{ 
		access(self)
		var server: Capability<&Admin>?
		
		init(){ 
			self.server = nil
		}
		
		access(all)
		fun addCapability(_ cap: Capability<&Admin>){ 
			pre{ 
				cap.check():
					"Invalid server capablity"
				self.server == nil:
					"Server already set"
			}
			self.server = cap
		}
		
		access(all)
		fun createOfferCollection(): @Collection{ 
			pre{ 
				self.server != nil:
					"Cannot create OfferCollection if server is not set"
			}
			return <-((self.server!).borrow()!).createOfferCollection()
		}
	}
	
	// OfferorCollection
	//
	// Lists all the offers of a buyer and give them the possibility to cancel offers
	//
	access(all)
	resource OfferorCollection{ 
		access(self)
		let offers:{ UInt64: UInt64} // recordID -> offerID
		
		
		init(){ 
			self.offers ={} 
		}
		
		access(all)
		fun addOffer(
			offerCollection: &Collection,
			recordID: UInt64,
			offerTokens: @{FungibleToken.Vault},
			offerorFVault: Capability<&FUSD.Vault>,
			offerorRCollection: Capability<&Record.Collection>
		){ 
			offerCollection.addOffer(
				recordID: recordID,
				offerTokens: <-offerTokens,
				offerorFVault: offerorFVault,
				offerorRCollection: offerorRCollection
			)
			self.offers[recordID] = BaguetteOffer.totalOffers
		}
		
		access(all)
		fun cancelOffer(offerCollection: &Collection, recordID: UInt64){ 
			pre{ 
				self.offers[recordID] != nil:
					"There is no offer for this item."
			}
			offerCollection.cancelOffer(recordID: recordID, offerID: self.offers[recordID]!)
			self.offers.remove(key: recordID)
		}
		
		access(all)
		fun hasOffer(recordID: UInt64): Bool{ 
			return false
		}
	}
	
	// -----------------------------------------------------------------------
	// Contract public functions
	// -----------------------------------------------------------------------
	// 
	access(all)
	fun createManager(): @Manager{ 
		return <-create Manager()
	}
	
	// 
	access(all)
	fun createOfferor(): @OfferorCollection{ 
		return <-create OfferorCollection()
	}
	
	// -----------------------------------------------------------------------
	// Initialization function
	// -----------------------------------------------------------------------
	init(){ 
		self.totalOffers = 0
		self.parameters = OfferParameters(
				artistCut: 0.10,
				marketCut: 0.03,
				offerIncrement: 1.0,
				timeBeforeCancel: 86400.0
			)
		self.marketVault = nil
		self.lostFVault = nil
		self.lostRCollection = nil
		self.CollectionPublicPath = /public/boulangeriev1OfferCollection
		self.CollectionStoragePath = /storage/boulangeriev1OfferCollection
		self.ManagerPublicPath = /public/boulangeriev1OfferManager
		self.ManagerStoragePath = /storage/boulangeriev1OfferManager
		self.OfferorStoragePath = /storage/boulangeriev1OfferOfferor
		self.AdminStoragePath = /storage/boulangeriev1OfferAdmin
		self.AdminPrivatePath = /private/boulangeriev1OfferAdmin
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath)
	}
}
