access(all)
contract AllCodeNFTContract{ 
	access(all)
	resource NFT{ 
		access(all)
		let id: UInt64
		
		init(initID: UInt64){ 
			self.id = initID
		}
	}
	
	access(all)
	resource interface NFTReceiver{ 
		access(all)
		fun deposit(token: @NFT, metadata:{ String: String})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun idExists(id: UInt64): Bool
		
		access(all)
		fun getMetadata(id: UInt64):{ String: String}
	}
	
	access(all)
	resource Collection: NFTReceiver{ 
		access(all)
		var ownedNFTs: @{UInt64: NFT}
		
		access(all)
		var metadataObjs:{ UInt64:{ String: String}}
		
		init(){ 
			self.ownedNFTs <-{} 
			self.metadataObjs ={} 
		}
		
		access(all)
		fun withdraw(withdrawID: UInt64): @NFT{ 
			let token <- self.ownedNFTs.remove(key: withdrawID)!
			return <-token
		}
		
		access(all)
		fun deposit(token: @NFT, metadata:{ String: String}){ 
			self.metadataObjs[token.id] = metadata
			self.ownedNFTs[token.id] <-! token
		}
		
		access(all)
		fun idExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		fun updateMetadata(id: UInt64, metadata:{ String: String}){ 
			self.metadataObjs[id] = metadata
		}
		
		access(all)
		fun getMetadata(id: UInt64):{ String: String}{ 
			return self.metadataObjs[id]!
		}
	}
	
	access(all)
	fun createEmptyCollection(): @Collection{ 
		return <-create Collection()
	}
	
	access(all)
	resource NFTMinter{ 
		access(all)
		var idCount: UInt64
		
		init(){ 
			self.idCount = 1
		}
		
		access(all)
		fun mintNFT(): @NFT{ 
			var newNFT <- create NFT(initID: self.idCount)
			self.idCount = self.idCount + 1 as UInt64
			return <-newNFT
		}
	}
	
	//The init contract is required if the contract contains any fields
	init(){ 
		self.account.storage.save(<-self.createEmptyCollection(), to: /storage/NFTCollection)
		var capability_1 =
			self.account.capabilities.storage.issue<&{NFTReceiver}>(/storage/NFTCollection)
		self.account.capabilities.publish(capability_1, at: /public/NFTReceiver)
		self.account.storage.save(<-create NFTMinter(), to: /storage/NFTMinter)
	}
}
