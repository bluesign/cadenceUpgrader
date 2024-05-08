// Simple fee manager
//
access(all)
contract CommonFee{ 
	access(all)
	let commonFeeManagerStoragePath: StoragePath
	
	access(all)
	event SellerFeeChanged(value: UFix64)
	
	access(all)
	event BuyerFeeChanged(value: UFix64)
	
	// Seller fee in %
	access(all)
	var sellerFee: UFix64
	
	// BuyerFee fee in %
	access(all)
	var buyerFee: UFix64
	
	access(all)
	resource Manager{ 
		access(all)
		fun setBuyerFee(_ fee: UFix64){ 
			CommonFee.buyerFee = fee
			emit BuyerFeeChanged(value: CommonFee.buyerFee)
		}
		
		access(all)
		fun setSellerFee(_ fee: UFix64){ 
			CommonFee.sellerFee = fee
			emit SellerFeeChanged(value: CommonFee.sellerFee)
		}
	}
	
	init(){ 
		self.sellerFee = 2.5
		emit SellerFeeChanged(value: CommonFee.sellerFee)
		self.buyerFee = 2.5
		emit BuyerFeeChanged(value: CommonFee.buyerFee)
		self.commonFeeManagerStoragePath = /storage/commonFeeManager
		self.account.storage.save(<-create Manager(), to: self.commonFeeManagerStoragePath)
	}
	
	access(all)
	fun feeAddress(): Address{ 
		return self.account.address
	}
}
