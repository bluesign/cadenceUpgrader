import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract Swap{ 
	
	// Swap fee: 2.5%
	access(all)
	fun Fee(): UFix64{ 
		return 0.025
	}
	
	// Swap fee receiver address
	access(all)
	fun FeeAddress(): Address{ 
		return 0x3896d4b8f0636f6d
	}
	
	// An order has been created
	access(all)
	event OrderCreated(
		orderID: UInt64,
		address: Address,
		nftType: Type,
		nftUUID: UInt64,
		nftID: UInt64,
		currency: Type,
		price: UFix64,
		expiry: UInt64
	)
	
	// An order has been canceled
	access(all)
	event OrderCanceled(
		orderID: UInt64,
		nftType: Type,
		nftUUID: UInt64,
		nftID: UInt64,
		currency: Type,
		price: UFix64,
		expiry: UInt64
	)
	
	// An order has been filled
	access(all)
	event OrderFilled(
		orderID: UInt64,
		nftType: Type,
		nftUUID: UInt64,
		nftID: UInt64,
		currency: Type,
		price: UFix64,
		expiry: UInt64
	)
	
	// The storage location of the Swap resource
	access(all)
	let SwapStoragePath: StoragePath
	
	// The public location of the Swap link
	access(all)
	let SwapPublicPath: PublicPath
	
	// A struct representing a payment that must be sent when an order is executed
	access(all)
	struct Payment{ 
		// The receiver for the payment of a sell order
		access(all)
		let receiver: Capability<&{FungibleToken.Receiver}>
		
		// The amount of the FungibleToken that will be paid
		access(all)
		let amount: UFix64
		
		init(receiver: Capability<&{FungibleToken.Receiver}>, amount: UFix64){ 
			self.receiver = receiver
			self.amount = amount
		}
	}
	
	// A struct containing an order's data
	access(all)
	struct OrderDetails{ 
		// Whether this order has been filled or not
		access(all)
		var filled: Bool
		
		// The Type of the NonFungibleToken.NFT
		access(all)
		let nftType: Type
		
		// The Resource ID of the NFT
		access(all)
		let nftUUID: UInt64
		
		// The unique identifier of the NFT in the contract
		access(all)
		let nftID: UInt64
		
		// The Type of the FungibleToken that payments must be made in
		access(all)
		let currency: Type
		
		// The amount that must be paid in the specified FungibleToken
		access(all)
		let price: UFix64
		
		// This specifies the division of payment between recipients
		access(all)
		let payments: [Payment]
		
		// This specifies the division of royalties between recipients
		access(all)
		let royalties: [Payment]
		
		// This specifies the division of fees between recipients
		access(all)
		let fees: [Payment]
		
		// Time when order expires
		access(all)
		let expiry: UInt64
		
		// Set an order to filled so it can't be executed again
		access(contract)
		fun setToFilled(){ 
			self.filled = true
		}
		
		init(
			nftType: Type,
			nftUUID: UInt64,
			nftID: UInt64,
			currency: Type,
			payments: [
				Payment
			],
			royalties: [
				Payment
			],
			fees: [
				Payment
			],
			expiry: UInt64
		){ 
			pre{ 
				// Validate the UUID and ID when sell order
				nftUUID != nil && nftID != nil:
					"sell orders require the UUID and ID of the NFT"
				
				// Validate the expiry timestamp
				expiry > UInt64(getCurrentBlock().timestamp):
					"expiry should be in the future"
				
				// Validate the existance of at least one payment recipient when sell order
				payments.length > 0:
					"sell orders must have at least one payment recipient"
			}
			self.filled = false
			self.nftType = nftType
			self.nftUUID = nftUUID
			self.nftID = nftID
			self.currency = currency
			self.payments = payments
			self.royalties = royalties
			self.fees = fees
			self.expiry = expiry
			var price = 0.0
			for payment in self.payments{ 
				payment.receiver.borrow() ?? panic("cannot borrow payment receiver")
				price = price + payment.amount
			}
			assert(price > 0.0, message: "item price must not be 0")
			let priceBeforeFees = price
			var totalFeeAmount = 0.0
			for fee in self.fees{ 
				totalFeeAmount = totalFeeAmount + fee.amount
				price = price + fee.amount
			}
			
			// Add the royalties
			var totalRoyalties = 0.0
			for royalty in self.royalties{ 
				royalty.receiver.borrow() ?? panic("cannot borrow royalty receiver")
				price = price + royalty.amount
				totalRoyalties = totalRoyalties + royalty.amount
			}
			assert(
				totalFeeAmount / (priceBeforeFees + totalFeeAmount + totalRoyalties) >= Swap.Fee(),
				message: "fee is lower than required fee"
			)
			assert(
				totalRoyalties / (priceBeforeFees + totalFeeAmount + totalRoyalties) <= 0.1,
				message: "royalties are over 10%"
			)
			self.price = price
		}
	}
	
	// An interface providing a public interface to an Order.
	access(all)
	resource interface OrderPublic{ 
		access(all)
		fun borrowNFT(): &{NonFungibleToken.NFT}?
		
		// Get the token in exchange of the currency vault
		access(all)
		fun fill(payment: @{FungibleToken.Vault}): @{NonFungibleToken.NFT}
		
		// Get the details of an Order
		access(all)
		fun getDetails(): OrderDetails
		
		// For a sell Order, checks whether the NFT is present in provided capability
		// `false` means the NFT was transfered out of the account
		access(all)
		fun isValid(): Bool
	}
	
	// A resource that allows an NFT to be sold for an amount of a given FungibleToken,
	// and for the proceeds of that sale to be split between several recipients.
	access(all)
	resource Order: OrderPublic{ 
		// The details of the Order
		access(self)
		let details: OrderDetails
		
		// A capability allowing this resource to withdraw any NFT with the given ID from its collection.
		access(contract)
		let nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
		
		// Return the reference of the NFT that is for sale.
		// If the NFT is absent, it will return nil.
		access(all)
		fun borrowNFT(): &{NonFungibleToken.NFT}?{ 
			// Sell orders require the NFT type and ID
			let ref = (self.nftProviderCapability.borrow()!).borrowNFT(self.details.nftID)
			if ref.isInstance(self.details.nftType) && ref.id == self.details.nftID{ 
				return ref as! &{NonFungibleToken.NFT}
			}
			return nil
		}
		
		// Get the details of an order.
		access(all)
		fun getDetails(): OrderDetails{ 
			return self.details
		}
		
		// For a sell Order, checks whether the NFT is present in provided capability
		// `false` means the NFT was transfered out of the account
		access(all)
		fun isValid(): Bool{ 
			if let providerRef = self.nftProviderCapability.borrow(){ 
				let availableIDs = providerRef.getIDs()
				return availableIDs.contains(self.details.nftID)
			}
			return false
		}
		
		// Fill the order
		// Send payments and returns the token to the buyer
		access(all)
		fun fill(payment: @{FungibleToken.Vault}): @{NonFungibleToken.NFT}{ 
			pre{ 
				self.details.filled == false:
					"order has already been filled"
				payment.isInstance(self.details.currency):
					"payment is not in required currency"
				payment.balance == self.details.price:
					"payment price is different"
				self.details.expiry > UInt64(getCurrentBlock().timestamp):
					"order is expired"
				self.owner != nil:
					"resource doesn't have the assigned owner"
			}
			
			// Make sure the order cannot be filled again
			self.details.setToFilled()
			
			// Fetch the token to return to the buyer
			let nft <- (self.nftProviderCapability.borrow()!).withdraw(withdrawID: self.details.nftID)
			
			// Check if the withdrawn NFT has the specified Type and ID
			assert(nft.isInstance(self.details.nftType), message: "withdrawn NFT is not of specified type")
			assert(nft.id == self.details.nftID, message: "withdrawn NFT does not have specified ID")
			
			// Rather than aborting the transaction if any receiver is absent when we try to pay it,
			// we send the payment to the first valid receiver, which should be the seller.
			var residualReceiver: &{FungibleToken.Receiver}? = nil
			
			// Pay each beneficiary their amount of the payment
			// Set the first valid receiver as the residual receiver
			for p in self.details.payments{ 
				if let receiver = p.receiver.borrow(){ 
					let vault <- payment.withdraw(amount: p.amount)
					receiver.deposit(from: <-vault)
					if residualReceiver == nil{ 
						residualReceiver = receiver
					}
				}
			}
			
			// Pay royalties
			for r in self.details.royalties{ 
				if let receiver = r.receiver.borrow(){ 
					let vault <- payment.withdraw(amount: r.amount)
					receiver.deposit(from: <-vault)
				}
			}
			
			// Pay fees to the fee receiver defined in the contract
			let feeAddress = Swap.FeeAddress()
			let feeReceiver = getAccount(feeAddress).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
			for f in self.details.fees{ 
				if let receiver = feeReceiver.borrow(){ 
					let vault <- payment.withdraw(amount: f.amount)
					receiver.deposit(from: <-vault)
				}
			}
			
			// At least one receiver was valid and paid
			assert(residualReceiver != nil, message: "no valid payment receivers")
			(			 
			 // At this point, if all receivers were valid, then the payment Vault will have
			 // zero tokens left, and this will be a no-op that consumes the empty vault
			 // otherwise the remaining payment will be deposited to the residual receiver
			 residualReceiver!).deposit(from: <-payment)
			emit OrderFilled(orderID: self.uuid, nftType: self.details.nftType, nftUUID: self.details.nftUUID, nftID: self.details.nftID, currency: self.details.currency, price: self.details.price, expiry: self.details.expiry)
			return <-nft
		}
		
		init(nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>, nftType: Type, nftUUID: UInt64, nftID: UInt64, currency: Type, payments: [Payment], royalties: [Payment], fees: [Payment], expiry: UInt64){ 
			// Store the order instructions
			self.details = OrderDetails(nftType: nftType, nftUUID: nftUUID, nftID: nftID, currency: currency, payments: payments, royalties: royalties, fees: fees, expiry: expiry)
			
			// Store the NFT provider
			self.nftProviderCapability = nftProviderCapability
			
			// Check that the provider has the NFT
			let provider = self.nftProviderCapability.borrow()
			assert(provider != nil, message: "cannot borrow nftProviderCapability")
			let nft = (provider!).borrowNFT(self.details.nftID)
			assert(nft.isInstance(self.details.nftType), message: "token is not of specified type")
			assert(nft.id == self.details.nftID, message: "token does not have specified ID")
		}
	}
	
	// An interface for adding and removing orders
	access(all)
	resource interface PortfolioManager{ 
		
		// Allows the portfolio owner to create a sell order
		access(all)
		fun createSellOrder(
			nftProviderCapability: Capability<
				&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}
			>,
			nftType: Type,
			nftID: UInt64,
			currency: Type,
			payments: [
				Payment
			],
			royalties: [
				Payment
			],
			fees: [
				Payment
			],
			expiry: UInt64
		): UInt64
		
		// Allows the portfolio owner to cancel any orders, filled or not
		access(all)
		fun cancelOrder(orderID: UInt64)
	}
	
	// An interface to allow order filling
	access(all)
	resource interface PortfolioPublic{ 
		access(all)
		fun getOrderIDs(): [UInt64]
		
		access(all)
		fun getSellOrderIDs(nftType: Type, nftID: UInt64): [UInt64]
		
		access(all)
		view fun borrowOrder(orderID: UInt64): &Order?
		
		access(all)
		fun clean(orderID: UInt64)
	}
	
	// A resource that allows its owner to manage a portfolio, and anyone to interact with them
	// in order to query their details and fill the NFTs that they represent.
	access(all)
	resource Portfolio: PortfolioManager, PortfolioPublic{ 
		// The dictionary of orders uuids to order resources.
		access(contract)
		var orders: @{UInt64: Order}
		
		// Dictionary to keep track of sell order ids for an NFT
		// nftType.identifier -> nftID -> orderID
		access(contract)
		var sellOrders:{ String:{ UInt64: UInt64}}
		
		// Create and publish a sell order for an NFT
		access(all)
		fun createSellOrder(nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>, nftType: Type, nftID: UInt64, currency: Type, payments: [Payment], royalties: [Payment], fees: [Payment], expiry: UInt64): UInt64{ 
			
			// Check that the seller does indeed hold the NFT
			let collectionRef = nftProviderCapability.borrow() ?? panic("Could not borrow reference to collection")
			let nftRef = collectionRef.borrowNFT(nftID)
			let uuid = nftRef.uuid
			let order <- create Order(nftProviderCapability: nftProviderCapability, nftType: nftType, nftUUID: uuid, nftID: nftID, currency: currency, payments: payments, royalties: royalties, fees: fees, expiry: expiry)
			let orderID = order.uuid
			let price = order.getDetails().price
			
			// Add the new order to the dictionary.
			let oldOrder <- self.orders[orderID] <- order
			
			// Note that oldOrder will always be nil, but we have to handle it.
			destroy oldOrder
			
			// Add the `orderID` in the tracked sell orders and remove any previous sell order for the same nft
			if self.sellOrders.containsKey(nftType.identifier){ 
				if (self.sellOrders[nftType.identifier]!).containsKey(nftID){ 
					let previousOrderID = (self.sellOrders[nftType.identifier]!)[nftID]!
					self.cancelOrder(orderID: previousOrderID)
				}
			}
			self.addSellOrder(nftIdentifier: nftType.identifier, nftID: nftID, orderID: orderID)
			emit OrderCreated(orderID: orderID, address: self.owner?.address!, nftType: nftType, nftUUID: uuid, nftID: nftID, currency: currency, price: price, expiry: expiry)
			return orderID
		}
		
		// Helper function that allows to add a sell order for a given nft in a map
		access(contract)
		fun addSellOrder(nftIdentifier: String, nftID: UInt64, orderID: UInt64){ 
			if !self.sellOrders.containsKey(nftIdentifier){ 
				self.sellOrders.insert(key: nftIdentifier,{ nftID: orderID})
			} else if !(self.sellOrders[nftIdentifier]!).containsKey(nftID){ 
				(self.sellOrders[nftIdentifier]!).insert(key: nftID, orderID)
			} else{ 
				(self.sellOrders[nftIdentifier]!).remove(key: nftID)
				(self.sellOrders[nftIdentifier]!).insert(key: nftID, orderID)
			}
		}
		
		// Helper function that allows to remove existing sell orders of given nft from a map
		access(contract)
		fun removeSellOrder(nftIdentifier: String, nftID: UInt64, orderID: UInt64){ 
			if self.sellOrders.containsKey(nftIdentifier){ 
				if (self.sellOrders[nftIdentifier]!).containsKey(nftID){ 
					if (self.sellOrders[nftIdentifier]!)[nftID]! == orderID{ 
						(self.sellOrders[nftIdentifier]!).remove(key: nftID)
					}
				}
			}
		}
		
		// Remove an order that has not yet been filled and destroy it.
		// It can only be executed by the PortfolioManager resource owner.
		access(all)
		fun cancelOrder(orderID: UInt64){ 
			let order <- self.orders.remove(key: orderID) ?? panic("missing Order")
			let details = order.getDetails()
			self.removeSellOrder(nftIdentifier: details.nftType.identifier, nftID: details.nftID, orderID: orderID)
			
			// This will emit an OrderCanceled event.
			destroy order
		}
		
		// Returns an array of all the orderIDs that are in the collection
		access(all)
		fun getOrderIDs(): [UInt64]{ 
			return self.orders.keys
		}
		
		// Returns the sell orderID of the given `nftType` and `nftID`
		access(all)
		fun getSellOrderIDs(nftType: Type, nftID: UInt64): [UInt64]{ 
			if self.sellOrders.containsKey(nftType.identifier){ 
				if (self.sellOrders[nftType.identifier]!).containsKey(nftID){ 
					return [(self.sellOrders[nftType.identifier]!)[nftID]!]
				}
			}
			return []
		}
		
		// Allows anyone to clean filled or invalid orders
		access(all)
		fun clean(orderID: UInt64){ 
			pre{ 
				self.orders[orderID] != nil:
					"could not find order with given id"
				(self.borrowOrder(orderID: orderID)!).getDetails().filled == true || (self.borrowOrder(orderID: orderID)!).getDetails().expiry <= UInt64(getCurrentBlock().timestamp):
					"order not filled or expired"
			}
			let orderRef = self.borrowOrder(orderID: orderID)!
			let details = orderRef.getDetails()
			var shouldClean = false
			if details.expiry <= UInt64(getCurrentBlock().timestamp){ 
				// Order is expired and should be cleaned
				shouldClean = true
			} else if details.filled == true{ 
				// Order was filled and should be cleaned
				shouldClean = true
			} else if !orderRef.isValid(){ 
				// Order does not have NFT and should be cleaned
				shouldClean = true
			}
			assert(shouldClean, message: "given order is valid")
			let order <- self.orders.remove(key: orderID)!
			self.removeSellOrder(nftIdentifier: details.nftType.identifier, nftID: details.nftID, orderID: orderID)
			destroy order
		}
		
		// Returns a read-only view of the order
		access(all)
		view fun borrowOrder(orderID: UInt64): &Order?{ 
			if self.orders[orderID] != nil{ 
				return &self.orders[orderID] as &Order?
			} else{ 
				return nil
			}
		}
		
		init(){ 
			self.orders <-{} 
			self.sellOrders ={} 
		}
	}
	
	// Make creating a Portfolio publicly accessible
	access(all)
	fun createPortfolio(): @Portfolio{ 
		return <-create Portfolio()
	}
	
	init(){ 
		self.SwapStoragePath = /storage/Swap
		self.SwapPublicPath = /public/Swap
	}
}
