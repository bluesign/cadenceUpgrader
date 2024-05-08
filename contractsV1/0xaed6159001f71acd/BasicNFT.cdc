access(all)
contract BasicNFT{ 
	access(all)
	var totalSupply: UInt64
	
	init(){ 
		self.totalSupply = 0
	}
	
	access(all)
	resource interface NFTPublic{ 
		access(all)
		fun getID(): UInt64
		
		access(all)
		fun getURL(): String
	}
	
	access(all)
	resource NFT: NFTPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		var metadata:{ String: String}
		
		init(InitURL: String){ 
			self.id = BasicNFT.totalSupply
			self.metadata ={ "URL": InitURL}
			BasicNFT.totalSupply = BasicNFT.totalSupply + 1
		}
		
		access(all)
		fun getID(): UInt64{ 
			return self.id
		}
		
		access(all)
		fun getURL(): String{ 
			return self.metadata["URL"]!
		}
	}
	
	access(all)
	fun createNFT(url: String): @NFT{ 
		return <-create NFT(InitURL: url)
	}
}
