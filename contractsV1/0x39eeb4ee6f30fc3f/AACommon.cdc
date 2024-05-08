access(all)
contract AACommon{ 
	access(all)
	struct PaymentCut{ 
		// typicaly they are Storage, Insurance, Contractor
		access(all)
		let type: String
		
		access(all)
		let recipient: Address
		
		access(all)
		let rate: UFix64
		
		init(type: String, recipient: Address, rate: UFix64){ 
			assert(rate >= 0.0 && rate <= 1.0, message: "Rate should be other than 0")
			self.type = type
			self.recipient = recipient
			self.rate = rate
		}
	}
	
	access(all)
	struct Payment{ 
		// typicaly they are Storage, Insurance, Contractor
		access(all)
		let type: String
		
		access(all)
		let recipient: Address
		
		access(all)
		let rate: UFix64
		
		access(all)
		let amount: UFix64
		
		init(type: String, recipient: Address, rate: UFix64, amount: UFix64){ 
			self.type = type
			self.recipient = recipient
			self.rate = rate
			self.amount = amount
		}
	}
	
	access(all)
	fun itemIdentifier(type: Type, id: UInt64): String{ 
		return type.identifier.concat("-").concat(id.toString())
	}
}
