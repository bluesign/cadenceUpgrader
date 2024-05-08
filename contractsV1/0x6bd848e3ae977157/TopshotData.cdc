access(all)
contract TopshotData{ 
	access(self)
	var shardedNFTMap:{ UInt64:{ UInt64: NFTData}}
	
	access(all)
	let numBuckets: UInt64
	
	access(all)
	event NFTDataUpdated(id: UInt64, data:{ String: String})
	
	access(all)
	struct NFTData{ 
		access(all)
		let data:{ String: String}
		
		access(all)
		let id: UInt64
		
		init(id: UInt64, data:{ String: String}){ 
			self.id = id
			self.data = data
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun upsertNFTData(data: NFTData){ 
			let bucket = data.id % TopshotData.numBuckets
			let newNFTMap = TopshotData.shardedNFTMap[bucket]!
			newNFTMap[data.id] = data
			TopshotData.shardedNFTMap[bucket] = newNFTMap
			emit NFTDataUpdated(id: data.id, data: data.data)
		}
		
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
		
		access(all)
		init(){} 
	}
	
	access(all)
	fun getNFTData(id: UInt64): NFTData?{ 
		let bucket = id % TopshotData.numBuckets
		return (self.shardedNFTMap[bucket]!)[id]
	}
	
	access(all)
	init(){ 
		self.numBuckets = UInt64(100)
		self.shardedNFTMap ={} 
		var i: UInt64 = 0
		while i < self.numBuckets{ 
			self.shardedNFTMap[i] ={} 
			i = i + UInt64(1)
		}
		self.account.storage.save<@Admin>(<-create Admin(), to: /storage/TopshotDataAdminV3)
	}
}
