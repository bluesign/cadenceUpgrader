import GaiaFee from "./GaiaFee.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NFTStorefront from "./../../standardsV1/NFTStorefront.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract GaiaOrder{ 
	access(all)
	let BUYER_FEE: String
	
	access(all)
	let SELLER_FEE: String
	
	access(all)
	let OTHER: String
	
	access(all)
	let ROYALTY: String
	
	access(all)
	let REWARD: String
	
	init(){ 
		// market buyer fee (on top of the price)
		self.BUYER_FEE = "BUYER_FEE"
		
		// market seller fee
		self.SELLER_FEE = "SELLER_FEE"
		
		// additional payments
		self.OTHER = "OTHER"
		
		// royalty
		self.ROYALTY = "ROYALTY"
		
		// seller reward
		self.REWARD = "REWARD"
	}
	
	// PaymentPart
	// 
	access(all)
	struct PaymentPart{ 
		// receiver address
		access(all)
		let address: Address
		
		// payment rate
		access(all)
		let rate: UFix64
		
		init(address: Address, rate: UFix64){ 
			self.address = address
			self.rate = rate
		}
	}
	
	// Payment
	// Describes payment in the event OrderAvailable
	// 
	access(all)
	struct Payment{ 
		// type of payment
		access(all)
		let type: String
		
		// receiver address
		access(all)
		let address: Address
		
		// payment rate
		access(all)
		let rate: UFix64
		
		// payment amount
		access(all)
		let amount: UFix64
		
		init(type: String, address: Address, rate: UFix64, amount: UFix64){ 
			self.type = type
			self.address = address
			self.rate = rate
			self.amount = amount
		}
	}
	
	// OrderAvailable
	// Order created and available for purchase
	// 
	access(all)
	event OrderAvailable(
		orderAddress: Address,
		orderId: UInt64,
		nftType: String,
		nftId: UInt64,
		vaultType: String,
		price: UFix64,
		payments: [
			Payment
		]
	)
	
	access(all)
	event OrderClosed(
		orderAddress: Address,
		orderId: UInt64,
		nftType: String,
		nftId: UInt64,
		vaultType: String,
		price: UFix64,
		buyerAddress: Address,
		cuts: [
			PaymentPart
		]
	)
	
	access(all)
	event OrderCancelled(
		orderAddress: Address,
		orderId: UInt64,
		nftType: String,
		nftId: UInt64,
		vaultType: String,
		price: UFix64,
		cuts: [
			PaymentPart
		]
	)
	
	// addOrder
	// Wrapper for NFTStorefront.createListing
	//
	access(all)
	fun addOrder(
		storefront: &NFTStorefront.Storefront,
		nftProvider: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
		nftType: Type,
		nftId: UInt64,
		vaultPath: PublicPath,
		vaultType: Type,
		price: UFix64,
		extraCuts: [
			PaymentPart
		],
		royalties: [
			PaymentPart
		]
	): UInt64{ 
		let orderAddress = (storefront.owner!).address
		let payments: [Payment] = []
		let saleCuts: [NFTStorefront.SaleCut] = []
		var percentage = 1.0
		let addPayment = fun (type: String, address: Address, rate: UFix64){ 
				assert(rate >= 0.0 && rate < 1.0, message: "Rate must be in range [0..1)")
				let amount = price * rate
				let receiver = getAccount(address).capabilities.get<&{FungibleToken.Receiver}>(vaultPath)
				assert(receiver.borrow() != nil, message: "Missing or mis-typed fungible token receiver")
				payments.append(Payment(type: type, address: address, rate: rate, amount: amount))
				saleCuts.append(NFTStorefront.SaleCut(receiver: receiver!, amount: amount))
				percentage = percentage - rate
			}
		if GaiaFee.buyerFee > 0.0{ 
			addPayment(GaiaOrder.BUYER_FEE, GaiaFee.feeAddress(), GaiaFee.buyerFee)
		}
		if GaiaFee.sellerFee > 0.0{ 
			addPayment(GaiaOrder.SELLER_FEE, GaiaFee.feeAddress(), GaiaFee.sellerFee)
		}
		for cut in extraCuts{ 
			addPayment(GaiaOrder.OTHER, cut.address, cut.rate)
		}
		for royalty in royalties{ 
			addPayment(GaiaOrder.ROYALTY, royalty.address, royalty.rate)
		}
		addPayment(GaiaOrder.REWARD, orderAddress, percentage)
		let orderId =
			storefront.createListing(
				nftProviderCapability: nftProvider,
				nftType: nftType,
				nftID: nftId,
				salePaymentVaultType: vaultType,
				saleCuts: saleCuts
			)
		emit OrderAvailable(
			orderAddress: orderAddress,
			orderId: orderId,
			nftType: nftType.identifier,
			nftId: nftId,
			vaultType: vaultType.identifier,
			price: price,
			payments: payments
		)
		return orderId
	}
	
	// closeOrder
	// Purchase nft by o
	//
	access(all)
	fun closeOrder(
		storefront: &NFTStorefront.Storefront,
		orderId: UInt64,
		orderAddress: Address,
		listing: &NFTStorefront.Listing,
		paymentVault: @{FungibleToken.Vault},
		buyerAddress: Address
	): @{NonFungibleToken.NFT}{ 
		let details = listing.getDetails()
		let cuts: [PaymentPart] = []
		for saleCut in details.saleCuts{ 
			cuts.append(PaymentPart(address: saleCut.receiver.address, rate: saleCut.amount))
		}
		emit OrderClosed(
			orderAddress: orderAddress,
			orderId: orderId,
			nftType: details.nftType.identifier,
			nftId: details.nftID,
			vaultType: details.salePaymentVaultType.identifier,
			price: details.salePrice,
			buyerAddress: buyerAddress,
			cuts: cuts
		)
		let item <- listing.purchase(payment: <-paymentVault)
		storefront.cleanup(listingResourceID: orderId)
		return <-item
	}
	
	// removeOrder
	// Cancel sale, dismiss order
	//
	access(all)
	fun removeOrder(
		storefront: &NFTStorefront.Storefront,
		orderId: UInt64,
		orderAddress: Address,
		listing: &NFTStorefront.Listing
	){ 
		let details = listing.getDetails()
		let cuts: [PaymentPart] = []
		for saleCut in details.saleCuts{ 
			cuts.append(PaymentPart(address: saleCut.receiver.address, rate: saleCut.amount))
		}
		emit OrderCancelled(
			orderAddress: orderAddress,
			orderId: orderId,
			nftType: details.nftType.identifier,
			nftId: details.nftID,
			vaultType: details.salePaymentVaultType.identifier,
			price: details.salePrice,
			cuts: cuts
		)
		storefront.removeListing(listingResourceID: orderId)
	}
}
