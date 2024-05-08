import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NyatheesOVO from "./NyatheesOVO.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract OVOMarketPlace{ 
	access(all)
	enum orderStatues: UInt8{ 
		access(all)
		case onSell
		
		access(all)
		case sold
		
		access(all)
		case canceled
	}
	
	access(all)
	struct orderData{ 
		// order Id
		access(all)
		let orderId: UInt64
		
		// order statue
		access(all)
		var orderStatue: orderStatues
		
		// tokenId of in this order
		access(all)
		let tokenId: UInt64
		
		// seller address
		access(all)
		let sellerAddr: Address
		
		// buyer address
		access(all)
		var buyerAddr: Address?
		
		// token name
		access(all)
		let tokenName: String
		
		// total price
		access(all)
		let totalPrice: UFix64
		
		// create time of this order
		access(all)
		let createTime: UFix64
		
		// sold time of this order
		access(all)
		let soldTime: UFix64
		
		init(
			orderId: UInt64,
			orderStatue: orderStatues,
			tokenId: UInt64,
			sellerAddr: Address,
			buyerAddr: Address?,
			tokenName: String,
			totalPrice: UFix64,
			createTime: UFix64,
			soldTime: UFix64
		){ 
			self.orderId = orderId
			self.orderStatue = orderStatue
			self.tokenId = tokenId
			self.sellerAddr = sellerAddr
			self.buyerAddr = buyerAddr
			self.tokenName = tokenName
			self.totalPrice = totalPrice
			self.createTime = createTime
			self.soldTime = soldTime
		}
	}
	
	access(all)
	event SellNFT(
		sellerAddr: Address,
		orderId: UInt64,
		tokenId: UInt64,
		totalPrice: UFix64,
		buyerFee: UFix64,
		sellerFee: UFix64,
		tokenName: String,
		createTime: UFix64
	)
	
	access(all)
	event BuyNFT(
		buyerAddr: Address,
		orderId: UInt64,
		tokenId: UInt64,
		totalPrice: UFix64,
		buyerFee: UFix64,
		sellerFee: UFix64,
		createTime: UFix64,
		soldTime: UFix64
	)
	
	access(all)
	event CancelOrder(orderId: UInt64, sellerAddr: Address, cancelTime: UFix64)
	
	access(all)
	event MarketControllerCreated()
	
	//path
	access(all)
	let MarketPublicPath: PublicPath
	
	access(all)
	let MarketControllerPrivatePath: PrivatePath
	
	access(all)
	let MarketControllerStoragePath: StoragePath
	
	// public functions to all users to buy and sell NFTs in this market
	access(all)
	resource interface MarketPublic{ 
		// @dev
		// orderId: get it from orderList
		// buyerAddr: the one who want to buy NFT
		// buyerTokenVault: the vault from the buyer to buy NFTs
		// this function will transfer NFT from onSellNFTList to the buyer
		// transfer fees to admin, deposit price to seller and set order statue to sold
		access(all)
		fun buyNFT(
			orderId: UInt64,
			buyerAddr: Address,
			tokenName: String,
			buyerTokenVault: @{FungibleToken.Vault}
		)
		
		// @dev
		// sellerAddr: as it means
		// tokenName: to support other tokens, you shuould pass tokenName like "FUSD"
		// totalPrice: total price of this NFT, which contains buyer fee
		// sellerNFT: the NFT seller want to sell
		// this function will create an order, move NFT resource to onSellNFTList
		// and set order statue to onSell
		access(all)
		fun sellNFT(
			sellerAddr: Address,
			tokenName: String,
			totalPrice: UFix64,
			tokenId: UInt64,
			sellerNFTProvider: &NyatheesOVO.Collection
		)
		
		// @dev
		// orderId: the order to cancel
		// sellerAddr: only the seller can cancel it`s own order
		// this will set order statue to canceled and return the NFT to the seller
		access(all)
		fun cancelOrder(orderId: UInt64, sellerAddr: Address)
		
		// @dev
		// this function will return order list
		access(all)
		fun getMarketOrderList(): [orderData]
		
		// @dev
		// this function will return an order data
		access(all)
		fun getMarketOrder(orderId: UInt64): orderData?
		
		// @dev
		// this function will return transaction fee
		access(all)
		fun getTransactionFee(tokenName: String): UFix64?
	}
	
	// private functions for admin to set some args
	access(all)
	resource interface MarketController{ 
		access(all)
		fun setTransactionFee(tokenName: String, fee_percentage: UFix64)
		
		access(all)
		fun setTransactionFeeReceiver(receiverAddr: Address)
		
		access(all)
		fun getTransactionFeeReceiver(): Address?
	}
	
	access(all)
	resource Market: MarketController, MarketPublic{ 
		
		// save on sell NFTs
		access(self)
		var onSellNFTList: @{UInt64:{ NonFungibleToken.NFT}}
		
		// order list
		access(self)
		var orderList:{ UInt64: orderData}
		
		// fee list, like "FUSD":0.05
		// 0.05 means 5%
		access(self)
		var transactionFeeList:{ String: UFix64}
		
		// record current orderId
		// it will increase 1 when a new order is created
		access(self)
		var orderId: UInt64
		
		// fees receiver
		access(self)
		var transactionFeeReceiverAddr: Address?
		
		// public functions
		access(all)
		fun buyNFT(orderId: UInt64, buyerAddr: Address, tokenName: String, buyerTokenVault: @{FungibleToken.Vault}){ 
			pre{ 
				buyerAddr != nil:
					"Buyer Address Can not be nil"
				orderId >= 0:
					"Wrong Token Id"
				self.orderList[orderId] != nil:
					"Order not exist"
				self.onSellNFTList[orderId] != nil:
					"Order was canceled or sold"
				self.transactionFeeList["FUSD_SellerFee"] != nil:
					"Seller Fee not set"
				self.transactionFeeList["FUSD_BuyerFee"] != nil:
					"buyer Fee not set"
			}
			
			// get order data
			// and it should exist
			var orderData = self.orderList[orderId]
			if (orderData!).orderStatue != orderStatues.onSell{ 
				panic("Unable to buy the order which was sold or canceled")
			}
			
			// get transaction fee for seller and buyer
			var sellerFeePersentage = self.transactionFeeList[tokenName.concat("_SellerFee")]!
			var buyerFeePersentage = self.transactionFeeList[tokenName.concat("_BuyerFee")]!
			if sellerFeePersentage == nil || buyerFeePersentage == nil{ 
				panic("Fees not found")
			}
			var sellerFUSDReceiver = getAccount((orderData!).sellerAddr).capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver).borrow<&{FungibleToken.Receiver}>() ?? panic("Unable to borrow seller receiver reference")
			var feeReceiverFUSDReceiver = getAccount(self.transactionFeeReceiverAddr!).capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver).borrow<&{FungibleToken.Receiver}>() ?? panic("Unable to borrow fee receiver reference")
			var totalPrice = (orderData!).totalPrice
			if totalPrice == nil || totalPrice <= 0.0{ 
				panic("Wrong total price")
			}
			
			// balance of buyer token vault should > total price
			// if we have buyer fee
			var buyerFee = totalPrice * (buyerFeePersentage * 100000000.0) / 100000000.0
			var sellerFee = totalPrice * (sellerFeePersentage * 100000000.0) / 100000000.0
			
			// deposit buyer fee if exist
			if buyerFeePersentage > 0.0{ 
				feeReceiverFUSDReceiver.deposit(from: <-buyerTokenVault.withdraw(amount: buyerFee))
			}
			
			// total price should >= buyer vault balance
			// after deposit fees
			if totalPrice > buyerTokenVault.balance{ 
				panic("Please provide enough money")
			}
			
			// deposit seller fee
			feeReceiverFUSDReceiver.deposit(from: <-buyerTokenVault.withdraw(amount: sellerFee))
			// deposit valut to seller
			sellerFUSDReceiver.deposit(from: <-buyerTokenVault)
			var buyerNFTCap = getAccount(buyerAddr).capabilities.get<&{NyatheesOVO.NFTCollectionPublic}>(NyatheesOVO.CollectionPublicPath).borrow<&{NyatheesOVO.NFTCollectionPublic}>() ?? panic("Unable to borrow NyatheesOVO Collection of the seller")
			// deposit NFT to buyer
			buyerNFTCap.deposit(token: <-self.onSellNFTList.remove(key: orderId)!)
			// update order info
			self.orderList[orderId] = OVOMarketPlace.orderData(orderId: (orderData!).orderId, orderStatue: orderStatues.sold, tokenId: (orderData!).tokenId, sellerAddr: (orderData!).sellerAddr, buyerAddr: buyerAddr, tokenName: (orderData!).tokenName, totalPrice: totalPrice, createTime: (orderData!).createTime, soldTime: getCurrentBlock().timestamp)
			emit BuyNFT(buyerAddr: buyerAddr, orderId: orderId, tokenId: (orderData!).tokenId, totalPrice: totalPrice, buyerFee: buyerFee, sellerFee: sellerFee, createTime: (orderData!).createTime, soldTime: getCurrentBlock().timestamp)
		}
		
		access(all)
		fun sellNFT(sellerAddr: Address, tokenName: String, totalPrice: UFix64, tokenId: UInt64, sellerNFTProvider: &NyatheesOVO.Collection){ 
			pre{ 
				tokenName != "":
					"Token Name Can Not Be \"\" "
				totalPrice > 0.0:
					"Total Price should > 0.0"
				sellerNFTProvider != nil:
					"NFT Provider can not be nil"
				tokenId >= 0:
					"Wrong Token Id"
				self.transactionFeeList["FUSD_SellerFee"] != nil:
					"Seller Fee not set"
				self.transactionFeeList["FUSD_BuyerFee"] != nil:
					"buyer Fee not set"
			}
			self.orderList.insert(key: self.orderId, orderData(orderId: self.orderId, orderStatue: orderStatues.onSell, tokenId: tokenId, sellerAddr: sellerAddr, buyerAddr: nil, tokenName: tokenName, totalPrice: totalPrice, createTime: getCurrentBlock().timestamp, soldTime: 0.0))
			if !sellerNFTProvider.idExists(id: tokenId){ 
				panic("The NFT not belongs to you")
			}
			
			// check metadata
			// user can not sell NFT which has sign = 1
			var metadata = (sellerNFTProvider.borrowNFTItem(id: tokenId)!).getMetadata()
			if metadata != nil && metadata["sign"] != nil && metadata["sign"] == "1"{ 
				panic("You can not sell this NFT")
			}
			
			// get transaction fee for seller and buyer
			var sellerFeePersentage = self.transactionFeeList[tokenName.concat("_SellerFee")]!
			var buyerFeePersentage = self.transactionFeeList[tokenName.concat("_BuyerFee")]!
			if sellerFeePersentage == nil || buyerFeePersentage == nil{ 
				panic("Fees not found")
			}
			self.onSellNFTList[self.orderId] <-! sellerNFTProvider.withdraw(withdrawID: tokenId)
			emit SellNFT(sellerAddr: sellerAddr, orderId: self.orderId, tokenId: tokenId, totalPrice: totalPrice, buyerFee: buyerFeePersentage, sellerFee: sellerFeePersentage, tokenName: tokenName, createTime: getCurrentBlock().timestamp)
			self.orderId = self.orderId + 1
		}
		
		access(all)
		fun cancelOrder(orderId: UInt64, sellerAddr: Address){ 
			pre{ 
				sellerAddr != nil:
					"Seller Address Can not be nil"
				orderId >= 0:
					"Wrong Token Id"
				self.orderList[orderId] != nil:
					"Order not exist"
				self.onSellNFTList[orderId] != nil:
					"Order was canceled or sold"
			}
			var orderData = self.orderList[orderId]
			if (orderData!).orderStatue != orderStatues.onSell{ 
				panic("Unable to cancel the order which was sold or canceled!")
			}
			if (orderData!).sellerAddr != sellerAddr{ 
				panic("Unable to cancel the order which not belongs to you!")
			}
			var tokenId = (orderData!).tokenId
			var sellerNFTCap = getAccount(sellerAddr).capabilities.get<&{NyatheesOVO.NFTCollectionPublic}>(NyatheesOVO.CollectionPublicPath).borrow<&{NyatheesOVO.NFTCollectionPublic}>() ?? panic("Unable to borrow NyatheesOVO Collection of the seller!")
			sellerNFTCap.deposit(token: <-self.onSellNFTList.remove(key: orderId)!)
			self.orderList[orderId] = OVOMarketPlace.orderData(orderId: (orderData!).orderId, orderStatue: orderStatues.canceled, tokenId: tokenId, sellerAddr: sellerAddr, buyerAddr: nil, tokenName: (orderData!).tokenName, totalPrice: (orderData!).totalPrice, createTime: (orderData!).createTime, soldTime: getCurrentBlock().timestamp)
			emit CancelOrder(orderId: orderId, sellerAddr: sellerAddr, cancelTime: getCurrentBlock().timestamp)
		}
		
		access(all)
		fun getMarketOrderList(): [orderData]{ 
			return self.orderList.values
		}
		
		access(all)
		fun getMarketOrder(orderId: UInt64): orderData?{ 
			return self.orderList[orderId]
		}
		
		access(all)
		fun getTransactionFee(tokenName: String): UFix64?{ 
			return self.transactionFeeList[tokenName]
		}
		
		// private functions
		access(all)
		fun setTransactionFee(tokenName: String, fee_percentage: UFix64){ 
			self.transactionFeeList[tokenName] = fee_percentage
		}
		
		access(all)
		fun setTransactionFeeReceiver(receiverAddr: Address){ 
			self.transactionFeeReceiverAddr = receiverAddr
		}
		
		access(all)
		fun getTransactionFeeReceiver(): Address?{ 
			return self.transactionFeeReceiverAddr
		}
		
		init(){ 
			self.onSellNFTList <-{} 
			self.orderList ={} 
			self.transactionFeeList ={} 
			self.orderId = 0
			self.transactionFeeReceiverAddr = nil
		}
	}
	
	init(){ 
		self.MarketPublicPath = /public/MarketPublic
		self.MarketControllerPrivatePath = /private/MarketControllerPrivate
		self.MarketControllerStoragePath = /storage/MarketControllerStorage
		let market <- create Market()
		self.account.storage.save(<-market, to: self.MarketControllerStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&OVOMarketPlace.Market>(
				self.MarketControllerStoragePath
			)
		self.account.capabilities.publish(capability_1, at: self.MarketPublicPath)
		emit MarketControllerCreated()
	}
}
