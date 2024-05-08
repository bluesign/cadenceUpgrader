access(all)
contract betaLilaiQuest{ 
	// An array that stores NFT owners
	access(all)
	var owners:{ UInt64: Address}
	
	// Event to log ownership changes
	access(all)
	event OwnershipChanged(tokenId: UInt64, newOwner: Address)
	
	// Event for logging messages
	access(all)
	event LogEvent(message: String)
	
	// Function to emit log messages
	access(all)
	fun emitLogEvent(message: String){ 
		emit LogEvent(message: message)
	}
	
	// Enhanced ownership update with access control
	access(all)
	fun updateOwner(tokenId: UInt64, newOwner: Address, caller: Address){ 
		let currentOwner = self.owners[tokenId]!
		assert(caller == currentOwner, message: "Caller is not the owner of the NFT")
		self.owners[tokenId] = newOwner
		emit OwnershipChanged(tokenId: tokenId, newOwner: newOwner)
	}
	
	// NFT resource
	access(all)
	resource NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		var metadata:{ String: String}
		
		access(all)
		var jobStatus: String // Added to track the status of the job NFT
		
		
		init(id: UInt64, metadata:{ String: String}){ 
			self.id = id
			self.metadata = metadata
			self.jobStatus = "Open" // Default status
		
		}
		
		access(all)
		fun updateMetadata(newMetadata:{ String: String}){ 
			for key in newMetadata.keys{ 
				self.metadata[key] = newMetadata[key]!
			}
		}
		
		access(all)
		fun updateJobStatus(newStatus: String){ 
			self.jobStatus = newStatus
		}
	}
	
	// Interface for NFT receiver
	access(all)
	resource interface NFTReceiver{ 
		access(all)
		fun withdraw(id: UInt64): @NFT
		
		access(all)
		fun deposit(token: @NFT)
		
		access(all)
		fun getTokenIds(): [UInt64]
		
		access(all)
		fun getTokenMetadata(id: UInt64):{ String: String}
	}
	
	// NFT Collection resource
	access(all)
	resource NFTCollection: NFTReceiver{ 
		access(account)
		var ownedNFTs: @{UInt64: NFT}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(all)
		fun borrowNFT(id: UInt64): &NFT?{ 
			return (&self.ownedNFTs[id] as &NFT?)!
		}
		
		access(all)
		fun withdraw(id: UInt64): @NFT{ 
			let token <- self.ownedNFTs.remove(key: id)!
			return <-token
		}
		
		access(all)
		fun deposit(token: @NFT){ 
			self.ownedNFTs[token.id] <-! token
		}
		
		access(all)
		fun getTokenIds(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		fun getTokenMetadata(id: UInt64):{ String: String}{ 
			let metadata = self.ownedNFTs[id]?.metadata!
			return metadata
		}
	}
	
	// Factory method to create an NFTCollection
	access(all)
	fun createNFTCollection(): @NFTCollection{ 
		let collection <- create NFTCollection()
		emit LogEvent(message: "New LilaiQuest NFTCollection created and saved in storage.")
		return <-collection
	}
	
	// Interface for public access to NFTMinter
	access(all)
	resource interface NFTMinterPublic{ 
		access(all)
		fun mintJobNFT(metadata:{ String: String}): @NFT
	}
	
	access(all)
	event NFTMinted(id: UInt64)
	
	// NFTMinter resource conforming to NFTMinterPublic
	access(all)
	resource NFTMinter: NFTMinterPublic{ 
		access(all)
		var idCount: UInt64
		
		init(){ 
			self.idCount = 1
		}
		
		// Enhanced minting function for job NFTs
		access(all)
		fun mintJobNFT(metadata:{ String: String}): @NFT{ 
			// Create the NFT with the current idCount
			let token <- create NFT(id: self.idCount, metadata: metadata)
			// Emit the NFTMinted event with the ID of the newly created NFT
			emit NFTMinted(id: self.idCount)
			// Increment the idCount after the NFT is minted
			self.idCount = self.idCount + 1
			emit LogEvent(message: "New LilaiQuest NFT created.")
			return <-token
		}
	}
	
	// Contract initialization
	init(){ 
		self.owners ={} 
		// Save and link NFTCollection
		self.account.storage.save(<-create NFTCollection(), to: /storage/LilaiQuestNFTCollection)
		var capability_1 =
			self.account.capabilities.storage.issue<&{NFTReceiver}>(
				/storage/LilaiQuestNFTCollection
			)
		self.account.capabilities.publish(capability_1, at: /public/LilaiQuestNFTReceiver)
		// Save and link NFTMinter
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: /storage/LilaiQuestNFTMinter)
		var capability_2 =
			self.account.capabilities.storage.issue<&betaLilaiQuest.NFTMinter>(
				/storage/LilaiQuestNFTMinter
			)
		self.account.capabilities.publish(capability_2, at: /public/betaLilaiQuestNFTMinter)
	}
}
