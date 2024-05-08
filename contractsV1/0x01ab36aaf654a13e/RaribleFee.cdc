// Simple fee manager
//
access(all)
contract RaribleFee{ 
	access(all)
	let commonFeeManagerStoragePath: StoragePath
	
	access(all)
	event SellerFeeChanged(value: UFix64)
	
	access(all)
	event BuyerFeeChanged(value: UFix64)
	
	// Seller fee [0..1)
	access(all)
	var sellerFee: UFix64
	
	// BuyerFee fee [0..1)
	access(all)
	var buyerFee: UFix64
	
	access(all)
	resource Manager{ 
		access(all)
		fun setSellerFee(_ fee: UFix64){ 
			RaribleFee.sellerFee = fee
			emit SellerFeeChanged(value: RaribleFee.sellerFee)
		}
		
		access(all)
		fun setBuyerFee(_ fee: UFix64){ 
			RaribleFee.buyerFee = fee
			emit BuyerFeeChanged(value: RaribleFee.buyerFee)
		}
	}
	
	init(){ 
		self.sellerFee = 0.025
		emit SellerFeeChanged(value: RaribleFee.sellerFee)
		self.buyerFee = 0.025
		emit BuyerFeeChanged(value: RaribleFee.buyerFee)
		self.commonFeeManagerStoragePath = /storage/commonFeeManager
		self.account.storage.save(<-create Manager(), to: self.commonFeeManagerStoragePath)
	}
	
	access(all)
	fun feeAddress(): Address{ 
		return self.account.address
	}
}
