access(all)
contract TriviaGame{ 
	// An array that stores NFT owners
	access(all)
	var owners:{ UInt64: Address}
	
	// Define an event to log ownership changes
	access(all)
	event OwnershipChanged(tokenId: UInt64, newOwner: Address)
	
	// Function to update the owner of an NFT
	access(all)
	fun updateOwner(tokenId: UInt64, newOwner: Address, caller: Address){ 
		// Check if the caller is the current owner of the NFT
		let currentOwner = self.owners[tokenId]!
		assert(caller == currentOwner, message: "Caller is not the owner of the NFT")
		// Update the owner
		self.owners[tokenId] = newOwner
		// Emit the event for the ownership change
		emit OwnershipChanged(tokenId: tokenId, newOwner: newOwner)
	}
	
	access(all)
	resource NFT{ 
		// Unique ID for each NFT
		access(all)
		let id: UInt64
		
		// String mapping to hold metadata
		access(all)
		var metadata:{ String: String}
		
		// Constructor method
		init(id: UInt64, metadata:{ String: String}){ 
			self.id = id
			self.metadata = metadata
		}
		
		// Method to update metadata
		access(all)
		fun updateMetadata(newMetadata:{ String: String}){ 
			for key in newMetadata.keys{ 
				self.metadata[key] = newMetadata[key]!
			}
		}
	}
	
	access(all)
	resource interface NFTReceiver{ 
		// Withdraw a token by its ID and returns the token.
		access(all)
		fun withdraw(id: UInt64): @NFT
		
		// Deposit an NFT to this NFTReceiver instance.
		access(all)
		fun deposit(token: @NFT)
		
		// Get all NFT IDs belonging to this NFTReceiver instance.
		access(all)
		fun getTokenIds(): [UInt64]
		
		// Get the metadata of an NFT instance by its ID.
		access(all)
		fun getTokenMetadata(id: UInt64):{ String: String}
	}
	
	access(all)
	resource NFTCollection: NFTReceiver{ 
		// Keeps track of NFTs this collection.
		access(account)
		var ownedNFTs: @{UInt64: NFT}
		
		// Constructor
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// Destructor
		// Withdraws and return an NFT token.
		access(all)
		fun withdraw(id: UInt64): @NFT{ 
			let token <- self.ownedNFTs.remove(key: id)
			return <-token!
		}
		
		// Deposits a token to this NFTCollection instance.
		access(all)
		fun deposit(token: @NFT){ 
			self.ownedNFTs[token.id] <-! token
		}
		
		// Returns an array of the IDs that are in this collection.
		access(all)
		fun getTokenIds(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// Returns the metadata of an NFT based on the ID.
		access(all)
		fun getTokenMetadata(id: UInt64):{ String: String}{ 
			let metadata = self.ownedNFTs[id]?.metadata
			return metadata!
		}
	}
	
	// Public factory method to create a collection
	// so it is callable from the contract scope.
	access(all)
	fun createNFTCollection(): @NFTCollection{ 
		return <-create NFTCollection()
	}
	
	access(all)
	resource NFTMinter{ 
		// Declare a global variable to count ID.
		access(all)
		var idCount: UInt64
		
		init(){ 
			// Instantialize the ID counter.
			self.idCount = 1
		}
		
		access(all)
		fun mint(_ metadata:{ String: String}): @NFT{ 
			// Create a new @NFT resource with the current ID.
			let token <- create NFT(id: self.idCount, metadata: metadata)
			// Save the current owner's address to the dictionary.
			TriviaGame.owners[self.idCount] = TriviaGame.account.address
			// Increment the ID
			self.idCount = self.idCount + 1
			return <-token
		}
	}
	
	init(){ 
		// Set `owners` to an empty dictionary.
		self.owners ={} 
		// Create a new `@NFTCollection` instance and save it in `/storage/NFTCollection` domain,
		// which is only accessible by the contract owner's account.
		self.account.storage.save(<-create NFTCollection(), to: /storage/NFTCollection)
		// "Link" only the `@NFTReceiver` interface from the `@NFTCollection` stored at `/storage/NFTCollection` domain to the `/public/NFTReceiver` domain, which is accessible to any user.
		var capability_1 =
			self.account.capabilities.storage.issue<&{NFTReceiver}>(/storage/NFTCollection)
		self.account.capabilities.publish(capability_1, at: /public/NFTReceiver)
		// Create a new `@NFTMinter` instance and save it in `/storage/NFTMinter` domain, accesible
		// only by the contract owner's account.
		self.account.storage.save(<-create NFTMinter(), to: /storage/NFTMinter)
	}
}
