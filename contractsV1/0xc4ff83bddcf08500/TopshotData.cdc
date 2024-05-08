access(all)
contract TopshotData{ 
	access(self)
	var nftMap:{ UInt64: NFTData}
	
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
			TopshotData.nftMap[data.id] = data
			emit NFTDataUpdated(id: data.id, data: data.data)
		}
		
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(all)
	fun getNFTData(id: UInt64): NFTData?{ 
		return self.nftMap[id]
	}
	
	access(all)
	init(){ 
		self.nftMap ={} 
		self.account.storage.save<@Admin>(<-create Admin(), to: /storage/TopshotDataAdmin)
	}
}
