import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract MikoSeaMarket{ 
	//------------------------------------------------------------
	// Events
	//------------------------------------------------------------
	access(all)
	event NFTMikoSeaMarketInitialized()
	
	access(all)
	event MikoSeaMarketInitialized(marketResourceID: UInt64)
	
	access(all)
	event MikoSeaMarketDestroyed(marketResourceID: UInt64)
	
	access(all)
	event OrderCreated(
		orderId: UInt64,
		holderAddress: Address,
		nftType: Type,
		nftID: UInt64,
		price: UFix64
	)
	
	access(all)
	event OrderCompleted(
		orderId: UInt64,
		purchased: Bool,
		holderAddress: Address,
		buyerAddress: Address?,
		nftID: UInt64,
		nftType: Type,
		price: UFix64
	)
	
	//------------------------------------------------------------
	// Path
	//------------------------------------------------------------
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPublicPath: PublicPath
	
	access(all)
	let MarketStoragePath: StoragePath
	
	access(all)
	let MarketPublicPath: PublicPath
	
	//------------------------------------------------------------
	// MikoSeaMarket vairables
	//------------------------------------------------------------
	access(self)
	let adminCap: Capability<&{AdminPublicCollection}>
	
	access(all)
	var mikoseaCap: Capability<&{FungibleToken.Receiver}>
	
	access(all)
	var tokenPublicPath: PublicPath
	
	// maping transactionId - orderId
	access(all)
	let refIds:{ String: UInt64}
	
	// maping nftID - orderId
	access(all)
	let nftIds:{ UInt64: UInt64}
	
	//------------------------------------------------------------
	// OrderDetail Struct
	//------------------------------------------------------------
	access(all)
	resource OrderDetail{ 
		access(all)
		var purchased: Bool
		
		// MIKOSEANFT.NFT or MIKOSEANFTV2.NFT
		access(all)
		let nftType: Type
		
		access(all)
		let nftID: UInt64
		
		access(all)
		let holderCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
		
		// status:
		//   created
		//   validated
		//   done
		//   reject
		access(all)
		var status: String
		
		// unit yen
		access(all)
		let salePrice: UFix64
		
		// transactionOrderId
		access(all)
		var refId: String?
		
		access(all)
		var receiverCap: Capability<&{NonFungibleToken.Receiver}>?
		
		access(all)
		let royalties: MetadataViews.Royalties
		
		// unix time
		access(all)
		var expireAt: UFix64?
		
		// unix time
		access(all)
		let createdAt: UFix64
		
		// unix time
		access(all)
		var purchasedAt: UFix64?
		
		// unix time
		access(all)
		var cancelAt: UFix64?
		
		access(all)
		let metadata:{ String: String}
		
		init(
			nftType: Type,
			nftID: UInt64,
			holderCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
			salePrice: UFix64,
			royalties: MetadataViews.Royalties,
			metadata:{ 
				String: String
			}
		){ 
			self.holderCap = holderCap
			self.nftType = nftType
			self.nftID = nftID
			self.salePrice = salePrice
			self.royalties = royalties
			self.metadata = metadata
			self.refId = nil
			self.receiverCap = nil
			self.status = "created"
			self.purchased = false
			self.createdAt = getCurrentBlock().timestamp
			self.purchasedAt = nil
			self.cancelAt = nil
			self.expireAt = nil
			self.checkAfterCreate()
		}
		
		access(all)
		fun getId(): UInt64{ 
			return self.uuid
		}
		
		access(self)
		fun checkAfterCreate(){ 
			let collection = self.holderCap.borrow() ?? panic("COULD_NOT_BORROW_HOLDER")
			self.borrowNFT()
		}
		
		access(contract)
		fun withdraw(): @{NonFungibleToken.NFT}{ 
			let ref = self.holderCap.borrow() ?? panic("SOMETHING_WENT_WRONG")
			return <-ref.withdraw(withdrawID: self.nftID)
		}
		
		access(contract)
		fun setToPurchased(){ 
			self.purchased = true
			self.purchasedAt = getCurrentBlock().timestamp
			self.status = "done"
		}
		
		// when GMO payment success
		access(contract)
		fun onPaymentSuccess(refId: String, receiverCap: Capability<&{NonFungibleToken.Receiver}>){ 
			self.status = "validated"
			self.refId = refId
			self.receiverCap = receiverCap
		}
		
		access(self)
		fun checkBeforePurchase(_ receiverAddress: Address){ 
			let nft = self.borrowNFT()
			assert(self.purchased == false, message: "ORDER_IS_PURCHASED")
			assert(self.status == "validated", message: "STATUS_IS_INVALID")
			assert(
				self.receiverCap != nil && (self.receiverCap!).address == receiverAddress,
				message: "NOT_RECIPIENT".concat(", receive ").concat(
					(self.receiverCap!).address.toString()
				).concat(", receive ").concat(receiverAddress.toString())
			)
		}
		
		access(all)
		fun borrowNFT(): &{NonFungibleToken.NFT}{ 
			let ref = self.holderCap.borrow() ?? panic("ACCOUNT_NOT_SETUP")
			let nft = ref.borrowNFT(self.nftID)
			assert(nft.isInstance(self.nftType), message: "NFT_TYPE_ERROR")
			assert(nft.id == self.nftID, message: "NFT_ID_ERROR")
			return nft!
		}
		
		// pub fun borrowNFTSafe(): &NonFungibleToken.NFT? {
		//	 if let ref = self.holderCap.borrow() {
		//		 if let nft = ref.borrowNFTSafe(id: self.nftID) {
		//			 if (nft.isInstance(self.nftType)) {
		//				 return nft
		//			 }
		//		 }
		//	 }
		//	 return nil
		// }
		access(all)
		fun purchase(_ receiverAddress: Address){ 
			self.checkBeforePurchase(receiverAddress)
			log(self.receiverCap)
			log(receiverAddress)
			let receiverRef = (self.receiverCap!).borrow() ?? panic("ACCOUNT_NOT_SETUP")
			receiverRef.deposit(token: <-self.withdraw())
			self.setToPurchased()
			emit OrderCompleted(
				orderId: self.uuid,
				purchased: self.purchased,
				holderAddress: self.holderCap.address,
				buyerAddress: self.receiverCap?.address,
				nftID: self.nftID,
				nftType: self.nftType,
				price: self.salePrice
			)
		}
	
	// destructor
	}
	
	//------------------------------------------------------------
	// StorefrontPublic
	//------------------------------------------------------------
	access(all)
	resource interface StorefrontPublic{ 
		access(all)
		fun getIds(): [UInt64]
		
		access(all)
		fun getOrders(): [&OrderDetail]
		
		access(all)
		fun borrowOrder(_ orderId: UInt64): &OrderDetail?
	}
	
	//------------------------------------------------------------
	// Storefront
	//------------------------------------------------------------
	access(all)
	resource Storefront: StorefrontPublic{ 
		access(all)
		let orderIds: [UInt64]
		
		init(){ 
			self.orderIds = []
		}
		
		// get listing ids
		access(all)
		fun getIds(): [UInt64]{ 
			return self.orderIds
		}
		
		access(all)
		fun getOrders(): [&OrderDetail]{ 
			let res: [&OrderDetail] = []
			for orderId in self.getIds(){ 
				if let order = MikoSeaMarket.getAdminRef().borrowOrder(orderId){ 
					res.append(order)
				}
			}
			return res
		}
		
		access(all)
		fun borrowOrder(_ orderId: UInt64): &OrderDetail?{ 
			if !self.getIds().contains(orderId){ 
				return nil
			}
			return MikoSeaMarket.getAdminRef().borrowOrder(orderId)
		}
		
		access(all)
		fun createOrder(nftType: Type, nftID: UInt64, holderCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>, salePrice: UFix64, royalties: MetadataViews.Royalties, metadata:{ String: String}): UInt64{ 
			let orderId = MikoSeaMarket.getAdminRef().createOrder(nftType: nftType, nftID: nftID, holderCap: holderCap, salePrice: salePrice, royalties: royalties, metadata: metadata)
			self.orderIds.append(orderId)
			return orderId
		}
		
		access(all)
		fun removeOrder(_ orderId: UInt64){ 
			if let order = self.borrowOrder(orderId){ 
				MikoSeaMarket.getAdminRef().removeOrder(orderId)
			}
			if let orderIdIndex = self.orderIds.firstIndex(of: orderId){ 
				self.orderIds.remove(at: orderIdIndex)
			}
		}
	}
	
	//------------------------------------------------------------
	// Admin public
	//------------------------------------------------------------
	access(all)
	resource interface AdminPublicCollection{ 
		access(all)
		fun createOrder(
			nftType: Type,
			nftID: UInt64,
			holderCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
			salePrice: UFix64,
			royalties: MetadataViews.Royalties,
			metadata:{ 
				String: String
			}
		): UInt64
		
		access(all)
		fun removeOrder(_ orderId: UInt64)
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun borrowOrder(_ orderId: UInt64): &OrderDetail?
	}
	
	//------------------------------------------------------------
	// Admin
	//------------------------------------------------------------
	access(all)
	resource Admin: AdminPublicCollection{ 
		access(self)
		var orders: @{UInt64: OrderDetail}
		
		init(){ 
			self.orders <-{} 
		}
		
		access(all)
		fun borrowOrder(_ orderId: UInt64): &OrderDetail?{ 
			return &self.orders[orderId] as &OrderDetail?
		}
		
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.orders.keys
		}
		
		access(all)
		fun createOrder(nftType: Type, nftID: UInt64, holderCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>, salePrice: UFix64, royalties: MetadataViews.Royalties, metadata:{ String: String}): UInt64{ 
			let order <- create OrderDetail(nftType: nftType, nftID: nftID, holderCap: holderCap, salePrice: salePrice, royalties: royalties, metadata: metadata)
			let orderId = order.uuid
			let oldOrder <- self.orders[orderId] <- order
			destroy oldOrder
			MikoSeaMarket.nftIds.insert(key: nftID, orderId)
			emit OrderCreated(orderId: orderId, holderAddress: holderCap.address, nftType: nftType, nftID: nftID, price: salePrice)
			return orderId
		}
		
		access(all)
		fun cleanup(orderId: UInt64, holderCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>){ 
			let order <- self.orders.remove(key: orderId) ?? panic("NOT_FOUND_ORDER")
			assert(order.purchased == true, message: "ORDER_IS_PURCHASED")
			let nft = holderCap.borrow()?.borrowNFT(order.nftID)
			assert(nft.isInstance(order.nftType), message: "NFT_TYPE_ERROR")
			assert((nft!).id == order.nftID, message: "NFT_ID_ERROR")
			destroy order
		}
		
		access(all)
		fun cleanAll(){ 
			for orderId in self.orders.keys{ 
				let order <- self.orders.remove(key: orderId) ?? panic("NOT_FOUND_ORDER")
				destroy order
			}
		}
		
		access(all)
		fun removeOrder(_ orderId: UInt64){ 
			let order <- self.orders.remove(key: orderId) ?? panic("NOT_FOUND_ORDER")
			destroy order
		}
		
		// when GMO payment success
		access(all)
		fun onPaymentSuccess(orderId: UInt64, refId: String, receiverCap: Capability<&{NonFungibleToken.Receiver}>){ 
			let order = self.borrowOrder(orderId)!
			order.onPaymentSuccess(refId: refId, receiverCap: receiverCap)
			MikoSeaMarket.refIds[refId] = order.uuid
		}
		
		// admin transfer nft to user
		access(all)
		fun purchaseForUser(_ orderId: UInt64, receiverAddress: Address){ 
			let order = self.borrowOrder(orderId)
			(order!).purchase(receiverAddress)
		}
	}
	
	//------------------------------------------------------------
	// Contract fun
	//------------------------------------------------------------
	//------------------------------------------------------------
	// Create Empty Collection
	//------------------------------------------------------------
	access(all)
	fun createStorefront(): @Storefront{ 
		return <-create Storefront()
	}
	
	access(self)
	fun getAdminRef(): &{AdminPublicCollection}{ 
		return self.adminCap.borrow() ?? panic("NOT_FOUND_ADMIN")
	}
	
	access(all)
	fun getIDs(): [UInt64]{ 
		return self.getAdminRef().getIDs()
	}
	
	access(all)
	fun borrowOrder(_ orderId: UInt64): &OrderDetail?{ 
		return self.getAdminRef().borrowOrder(orderId)
	}
	
	access(all)
	fun getAdminAddress(): Address{ 
		return self.adminCap.address
	}
	
	// pub fun purchase(orderId: UInt64, receiverCap: Capability<&{NonFungibleToken.Receiver}>) {
	//	 return self.getAdminRef().purchase(orderId: orderId, receiverCap: receiverCap)
	// }
	//------------------------------------------------------------
	// Initializer
	//------------------------------------------------------------
	init(){ 
		self.AdminStoragePath = /storage/MarketAdmin
		self.AdminPublicPath = /public/MarketAdmin
		self.MarketStoragePath = /storage/MikoSeaMarket
		self.MarketPublicPath = /public/MikoSeaMarket
		self.refIds ={} 
		self.nftIds ={} 
		
		// default token path
		self.tokenPublicPath = /public/flowTokenReceiver
		self.mikoseaCap = self.account.capabilities.get<&{FungibleToken.Receiver}>(
				self.tokenPublicPath
			)!
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&{AdminPublicCollection}>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPublicPath)
		self.adminCap = self.account.capabilities.get<&{AdminPublicCollection}>(
				self.AdminPublicPath
			)!
		emit NFTMikoSeaMarketInitialized()
	}
}
