access(all)
contract CarClubTracker{ 
	access(all)
	struct PurchaseRecord{ 
		access(all)
		let id: UInt64
		
		access(all)
		let userAddress: Address
		
		access(all)
		let itemType: String // "Single" or "Pack"
		
		
		access(all)
		let rollout: String
		
		init(_ id: UInt64, userAddress: Address, itemType: String, rollout: String){ 
			self.id = id
			self.userAddress = userAddress
			self.itemType = itemType
			self.rollout = rollout
		}
	}
	
	// Store for the purchase records
	access(all)
	var purchaseRecords:{ UInt64: PurchaseRecord}
	
	// Global ID counter for purchase records
	access(all)
	var nextId: UInt64
	
	// Function to add a new purchase record
	access(all)
	fun addPurchase(userAddress: Address, itemType: String, rollout: String){ 
		let newPurchase =
			PurchaseRecord(
				self.nextId,
				userAddress: userAddress,
				itemType: itemType,
				rollout: rollout
			)
		self.purchaseRecords[self.nextId] = newPurchase
		self.nextId = self.nextId + 1
	}
	
	init(){ 
		self.purchaseRecords ={} 
		self.nextId = 0
	}
}
