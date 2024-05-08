// Gaia Fees
//
// Simple fee manager
//
access(all)
contract GaiaFee{ 
	access(all)
	let commonFeeManagerStoragePath: StoragePath
	
	access(all)
	event SellerFeeChanged(value: UFix64)
	
	access(all)
	event BuyerFeeChanged(value: UFix64)
	
	access(all)
	event FeeAddressUpdated(label: String, address: Address)
	
	access(self)
	var feeAddresses:{ String: Address}
	
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
			GaiaFee.sellerFee = fee
			emit SellerFeeChanged(value: GaiaFee.sellerFee)
		}
		
		access(all)
		fun setBuyerFee(_ fee: UFix64){ 
			GaiaFee.buyerFee = fee
			emit BuyerFeeChanged(value: GaiaFee.buyerFee)
		}
		
		access(all)
		fun setFeeAddress(_ label: String, address: Address){ 
			GaiaFee.feeAddresses[label] = address
			emit FeeAddressUpdated(label: label, address: address)
		}
	}
	
	init(){ 
		self.sellerFee = 0.05
		emit SellerFeeChanged(value: GaiaFee.sellerFee)
		self.buyerFee = 0.0 // Gaia Buyer Fee
		
		emit BuyerFeeChanged(value: GaiaFee.buyerFee)
		self.feeAddresses ={} 
		self.commonFeeManagerStoragePath = /storage/commonFeeManager
		self.account.storage.save(<-create Manager(), to: self.commonFeeManagerStoragePath)
	}
	
	access(all)
	fun feeAddress(): Address{ 
		return self.feeAddresses["gaia"] ?? self.account.address
	}
	
	access(all)
	fun feeAddressByName(_ label: String): Address{ 
		return self.feeAddresses[label] ?? self.account.address
	}
	
	access(all)
	fun addressMap():{ String: Address}{ 
		return GaiaFee.feeAddresses
	}
}
