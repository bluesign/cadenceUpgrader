import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import Flowmap from "../0x483f0fe77f0d59fb/Flowmap.cdc"

import FlowBlocksTradingScore from "./FlowBlocksTradingScore.cdc"

access(all)
contract FlowmapMarketSub100k{ 
	
	// -----------------------------------------------------------------------
	// Contract Events
	// -----------------------------------------------------------------------
	access(all)
	event ContractInitialized()
	
	access(all)
	event FlowmapListed(id: UInt64, price: UFix64, listingFee: UFix64)
	
	access(all)
	event FlowmapListingCancelled(id: UInt64)
	
	access(all)
	event FlowmapPurchased(id: UInt64, price: UFix64, purchaseFee: UFix64)
	
	access(all)
	event FlowmapListingPurged(id: UInt64, price: UFix64)
	
	// -----------------------------------------------------------------------
	// Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	// -----------------------------------------------------------------------
	// Contract Fields
	// -----------------------------------------------------------------------
	access(all)
	var listingFee: UFix64
	
	access(all)
	var purchaseFee: UFix64
	
	access(all)
	var listingDuration: UFix64
	
	access(all)
	var marketPaused: Bool
	
	access(all)
	var totalVolume: UFix64
	
	access(all)
	var totalSales: UInt64
	
	access(self)
	var sellers: [Address]
	
	access(self)
	var sales:{ UInt64: Sale}
	
	access(all)
	struct Sale{ 
		access(all)
		let id: UInt64
		
		access(all)
		let flowmapID: UInt64
		
		access(all)
		let seller: Address
		
		access(all)
		let buyer: Address
		
		access(all)
		let purchaseDate: UFix64
		
		access(all)
		let price: UFix64
		
		access(all)
		let expirationDate: UFix64
		
		init(
			id: UInt64,
			flowmapID: UInt64,
			seller: Address,
			buyer: Address,
			purchaseDate: UFix64,
			price: UFix64,
			expirationDate: UFix64
		){ 
			self.id = id
			self.flowmapID = flowmapID
			self.seller = seller
			self.buyer = buyer
			self.purchaseDate = purchaseDate
			self.price = price
			self.expirationDate = expirationDate
		}
	}
	
	access(all)
	resource interface SalePublic{ 
		access(all)
		fun purchase(tokenID: UInt64, buyTokens: @FlowToken.Vault, buyer: Address): @Flowmap.NFT
		
		access(all)
		fun getPrice(tokenID: UInt64): UFix64?
		
		access(all)
		fun getExpirationDate(tokenID: UInt64): UFix64?
		
		access(all)
		fun getPrices():{ UInt64: UFix64}
		
		access(all)
		fun getExpirationDates():{ UInt64: UFix64}
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun checkCapability(): Bool
		
		access(all)
		fun purgeExpiredListings()
		
		access(all)
		fun purgeGhostListings()
	}
	
	access(all)
	resource SaleCollection: SalePublic{ 
		access(self)
		var prices:{ UInt64: UFix64}
		
		access(self)
		var expirationDates:{ UInt64: UFix64}
		
		access(self)
		var ownerCollection: Capability<&Flowmap.Collection>
		
		init(ownerCollection: Capability<&Flowmap.Collection>){ 
			pre{ 
				ownerCollection.check():
					"Owner's Flowmap Collection Capability is invalid!"
			}
			self.expirationDates ={} 
			self.prices ={} 
			self.ownerCollection = ownerCollection
		}
		
		access(all)
		fun listForSale(tokenID: UInt64, price: UFix64, listingFee: @FlowToken.Vault){ 
			pre{ 
				tokenID <= 99999:
					"Can't list for sale: ID must be less than 100,000"
				listingFee.balance == FlowmapMarketSub100k.listingFee:
					"Can't list for sale: listingFee payment doesn't match contract listingFee"
				price >= FlowmapMarketSub100k.purchaseFee:
					"Can't list for sale: price must be greater than purchaseFee"
				(self.ownerCollection.borrow()!).borrowFlowmap(id: tokenID) != nil:
					"Can't list for sale: ID doesn't exist in owner's Flowmap Collection"
				FlowmapMarketSub100k.marketPaused == false:
					"Can't list for sale: Market is paused"
			}
			self.prices[tokenID] = price
			self.expirationDates[tokenID] = getCurrentBlock().timestamp + FlowmapMarketSub100k.listingDuration
			
			// Add seller to list of sellers
			FlowmapMarketSub100k.addSeller(seller: (self.owner!).address)
			(			 
			 // Contract address receives listing fee
			 FlowmapMarketSub100k.account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver).borrow<&FlowToken.Vault>()!).deposit(from: <-listingFee)
			emit FlowmapListed(id: tokenID, price: price, listingFee: FlowmapMarketSub100k.listingFee)
		}
		
		access(all)
		fun cancelSale(tokenID: UInt64){ 
			pre{ 
				self.prices[tokenID] != nil:
					"Can't cancel Sale: ID doesn't exist in this SaleCollection"
			}
			self.prices.remove(key: tokenID)
			self.expirationDates.remove(key: tokenID)
			emit FlowmapListingCancelled(id: tokenID)
		}
		
		access(all)
		fun purchase(tokenID: UInt64, buyTokens: @FlowToken.Vault, buyer: Address): @Flowmap.NFT{ 
			pre{ 
				self.prices[tokenID] != nil:
					"Can't purchase: ID doesn't exist in this SaleCollection"
				self.expirationDates[tokenID]! > getCurrentBlock().timestamp:
					"Can't purchase: Sale has expired"
				buyTokens.balance == self.prices[tokenID]!:
					"Can't purchase: buyTokens balance must match the price"
				FlowmapMarketSub100k.marketPaused == false:
					"Can't purchase: Market is paused"
			}
			let price = self.prices[tokenID]!
			(			 
			 // Contract address receives purchase fee
			 FlowmapMarketSub100k.account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver).borrow<&FlowToken.Vault>()!).deposit(from: <-buyTokens.withdraw(amount: FlowmapMarketSub100k.purchaseFee))
			(			 
			 // Seller receives the rest
			 getAccount((self.owner!).address).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver).borrow<&FlowToken.Vault>()!).deposit(from: <-buyTokens)
			let boughtFlowmap <- (self.ownerCollection.borrow()!).withdraw(withdrawID: tokenID) as! @Flowmap.NFT
			
			// Save sales data onchain
			let sale = Sale(id: FlowmapMarketSub100k.totalSales, flowmapID: tokenID, seller: (self.owner!).address, buyer: buyer, purchaseDate: getCurrentBlock().timestamp, price: price, expirationDate: self.expirationDates[tokenID]!)
			FlowmapMarketSub100k.sales[FlowmapMarketSub100k.totalSales] = sale
			FlowmapMarketSub100k.totalVolume = FlowmapMarketSub100k.totalVolume + price
			FlowmapMarketSub100k.totalSales = FlowmapMarketSub100k.totalSales + 1
			
			// Add trading points
			FlowBlocksTradingScore.increaseTradingScore(wallet: (self.owner!).address, points: 100)
			FlowBlocksTradingScore.increaseTradingScore(wallet: buyer, points: 100)
			
			// Clear listing
			self.prices.remove(key: tokenID)
			self.expirationDates.remove(key: tokenID)
			emit FlowmapPurchased(id: tokenID, price: price, purchaseFee: FlowmapMarketSub100k.purchaseFee)
			return <-boughtFlowmap
		}
		
		access(all)
		fun getPrice(tokenID: UInt64): UFix64?{ 
			return self.prices[tokenID]
		}
		
		access(all)
		fun getExpirationDate(tokenID: UInt64): UFix64?{ 
			return self.expirationDates[tokenID]
		}
		
		access(all)
		fun getPrices():{ UInt64: UFix64}{ 
			return self.prices
		}
		
		access(all)
		fun getExpirationDates():{ UInt64: UFix64}{ 
			return self.expirationDates
		}
		
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.prices.keys
		}
		
		access(all)
		fun checkCapability(): Bool{ 
			return self.ownerCollection.check()
		}
		
		access(all)
		fun purgeExpiredListings(){ 
			let currentTimestamp = getCurrentBlock().timestamp
			for id in self.expirationDates.keys{ 
				if self.expirationDates[id]! < currentTimestamp{ 
					emit FlowmapListingPurged(id: id, price: self.prices[id]!)
					self.prices.remove(key: id)
					self.expirationDates.remove(key: id)
				}
			}
		}
		
		access(all)
		fun purgeGhostListings(){ 
			let IDs = (self.ownerCollection.borrow()!).getIDs()
			for id in self.prices.keys{ 
				if !IDs.contains(id){ 
					emit FlowmapListingPurged(id: id, price: self.prices[id]!)
					self.prices.remove(key: id)
					self.expirationDates.remove(key: id)
				}
			}
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun setListingFee(fee: UFix64){ 
			FlowmapMarketSub100k.listingFee = fee
		}
		
		access(all)
		fun setPurchaseFee(fee: UFix64){ 
			FlowmapMarketSub100k.purchaseFee = fee
		}
		
		access(all)
		fun setListingDuration(duration: UFix64){ 
			FlowmapMarketSub100k.listingDuration = duration
		}
		
		access(all)
		fun pauseMarket(){ 
			FlowmapMarketSub100k.marketPaused = true
		}
		
		access(all)
		fun unpauseMarket(){ 
			FlowmapMarketSub100k.marketPaused = false
		}
		
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(all)
	fun createSaleCollection(ownerCollection: Capability<&Flowmap.Collection>): @SaleCollection{ 
		return <-create SaleCollection(ownerCollection: ownerCollection)
	}
	
	access(contract)
	fun addSeller(seller: Address){ 
		if !self.sellers.contains(seller){ 
			self.sellers.append(seller)
		}
	}
	
	access(all)
	fun getSellers(): [Address]{ 
		return self.sellers
	}
	
	access(all)
	fun getSales():{ UInt64: Sale}{ 
		return self.sales
	}
	
	access(all)
	fun getSale(id: UInt64): Sale?{ 
		return self.sales[id]
	}
	
	access(all)
	fun getSaleIDs(): [UInt64]{ 
		return self.sales.keys
	}
	
	init(){ 
		// Set named paths
		self.CollectionStoragePath = /storage/FlowmapMarketSub100kSaleCollection_3
		self.CollectionPublicPath = /public/FlowmapMarketSub100kSaleCollection_3
		self.AdminStoragePath = /storage/FlowmapMarketSub100kAdmin_3
		self.AdminPrivatePath = /private/FlowmapMarketSub100kAdminUpgrade_3
		
		// Initialize fields
		self.listingFee = 0.85
		self.purchaseFee = 0.85
		self.listingDuration = 1814400.0
		self.marketPaused = false
		self.totalVolume = 0.0
		self.totalSales = 0
		self.sellers = []
		self.sales ={} 
		
		// Put Admin in storage
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&FlowmapMarketSub100k.Admin>(
				self.AdminStoragePath
			)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath)
		?? panic("Could not get a capability to the admin")
		emit ContractInitialized()
	}
}
