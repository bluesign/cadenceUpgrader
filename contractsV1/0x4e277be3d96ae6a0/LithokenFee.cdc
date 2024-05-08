// Fee manager
access(all)
contract LithokenFee{ 
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
	
	access(all)
	var sellerFee: UFix64
	
	access(all)
	var buyerFee: UFix64
	
	access(all)
	resource Manager{ 
		access(all)
		fun setSellerFee(_ fee: UFix64){ 
			LithokenFee.sellerFee = fee
			emit SellerFeeChanged(value: LithokenFee.sellerFee)
		}
		
		access(all)
		fun setBuyerFee(_ fee: UFix64){ 
			LithokenFee.buyerFee = fee
			emit BuyerFeeChanged(value: LithokenFee.buyerFee)
		}
		
		access(all)
		fun setFeeAddress(_ label: String, address: Address){ 
			LithokenFee.feeAddresses[label] = address
			emit FeeAddressUpdated(label: label, address: address)
		}
	}
	
	init(){ 
		self.sellerFee = 0.05
		emit SellerFeeChanged(value: LithokenFee.sellerFee)
		self.buyerFee = 0.05
		emit BuyerFeeChanged(value: LithokenFee.buyerFee)
		self.feeAddresses ={} 
		self.commonFeeManagerStoragePath = /storage/commonFeeManager
		self.account.storage.save(<-create Manager(), to: self.commonFeeManagerStoragePath)
	}
	
	access(all)
	fun feeAddress(): Address{ 
		return self.feeAddresses["lithoken"] ?? self.account.address
	}
	
	access(all)
	fun feeAddressByName(_ label: String): Address{ 
		return self.feeAddresses[label] ?? self.account.address
	}
	
	access(all)
	fun addressMap():{ String: Address}{ 
		return LithokenFee.feeAddresses
	}
}
