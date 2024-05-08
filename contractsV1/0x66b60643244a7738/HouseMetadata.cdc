access(all)
contract HouseMetadata{ 
	// Event definitions
	access(all)
	event MetadataAdded(
		id: UInt64,
		userAddress: Address,
		auctionType: String,
		currentBid: UFix64,
		timeStamp: String,
		txID: String,
		tresorID: UInt64
	)
	
	access(all)
	event MetadataRemoved(id: UInt64)
	
	access(all)
	struct Metadata{ 
		access(all)
		let id: UInt64
		
		access(all)
		let userAddress: Address
		
		access(all)
		let auctionType: String
		
		access(all)
		let currentBid: UFix64
		
		access(all)
		let timeStamp: String
		
		access(all)
		let txID: String
		
		access(all)
		let tresorID: UInt64
		
		init(
			id: UInt64,
			userAddress: Address,
			auctionType: String,
			currentBid: UFix64,
			timeStamp: String,
			txID: String,
			tresorID: UInt64
		){ 
			self.id = id
			self.userAddress = userAddress
			self.auctionType = auctionType
			self.currentBid = currentBid
			self.timeStamp = timeStamp
			self.txID = txID
			self.tresorID = tresorID
		}
	}
	
	// Store for the metadata
	access(all)
	var metadataRecords:{ UInt64: Metadata}
	
	// Global ID counter
	access(all)
	var nextId: UInt64
	
	access(all)
	fun addMetadata(
		userAddress: Address,
		auctionType: String,
		currentBid: UFix64,
		timeStamp: String,
		txID: String,
		tresorID: UInt64
	){ 
		let newMetadata =
			Metadata(
				id: self.nextId,
				userAddress: userAddress,
				auctionType: auctionType,
				currentBid: currentBid,
				timeStamp: timeStamp,
				txID: txID,
				tresorID: tresorID
			)
		self.metadataRecords[self.nextId] = newMetadata
		
		// Emitting an event for adding metadata
		emit MetadataAdded(
			id: self.nextId,
			userAddress: userAddress,
			auctionType: auctionType,
			currentBid: currentBid,
			timeStamp: timeStamp,
			txID: txID,
			tresorID: tresorID
		)
		self.nextId = self.nextId + 1
	}
	
	access(all)
	fun removeMetadataByTxID(txIDToRemove: String){ 
		var keyToRemove: UInt64? = nil
		for key in self.metadataRecords.keys{ 
			if (self.metadataRecords[key]!).txID == txIDToRemove{ 
				keyToRemove = key
				break // Assuming you want to remove the first match
			
			}
		}
		if let key = keyToRemove{ 
			self.metadataRecords.remove(key: key)
			emit MetadataRemoved(id: key)
		}
	}
	
	init(){ 
		self.metadataRecords ={} 
		self.nextId = 0
	}
}
