// ExampleNFT.cdc
//
// This is a complete version of the ExampleNFT contract
// that includes withdraw and deposit functionality, as well as a
// collection resource that can be used to bundle NFTs together.
//
// It also includes a definition for the Minter resource,
// which can be used by admins to mint new NFTs.
//
// Learn more about non-fungible tokens in this tutorial: https://developers.flow.com/cadence/tutorial/05-non-fungible-tokens-1
access(all)
contract ExampleNFT{ 
	// Declare Path constants so paths do not have to be hardcoded
	// in transactions and scripts
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// Declare the NFT resource type
	access(all)
	resource NFT{ 
		// The unique ID that differentiates each NFT
		access(all)
		let id: UInt64
		
		// Initialize both fields in the init function
		init(initID: UInt64){ 
			self.id = initID
		}
	}
	
	// We define this interface purely as a way to allow users
	// to create public, restricted references to their NFT Collection.
	// They would use this to publicly expose only the deposit, getIDs,
	// and idExists fields in their Collection
	access(all)
	resource interface NFTReceiver{ 
		access(all)
		fun deposit(token: @NFT)
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun idExists(id: UInt64): Bool
	}
	
	// The definition of the Collection resource that
	// holds the NFTs that a user owns
	access(all)
	resource Collection: NFTReceiver{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64: NFT}
		
		// Initialize the NFTs field to an empty collection
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw 
		//
		// Function that removes an NFT from the collection 
		// and moves it to the calling context
		access(all)
		fun withdraw(withdrawID: UInt64): @NFT{ 
			// If the NFT isn't found, the transaction panics and reverts
			let token <- self.ownedNFTs.remove(key: withdrawID)!
			return <-token
		}
		
		// deposit 
		//
		// Function that takes a NFT as an argument and 
		// adds it to the collections dictionary
		access(all)
		fun deposit(token: @NFT){ 
			// add the new token to the dictionary with a force assignment
			// if there is already a value at that key, it will fail and revert
			self.ownedNFTs[token.id] <-! token
		}
		
		// idExists checks to see if a NFT 
		// with the given ID exists in the collection
		access(all)
		fun idExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
	}
	
	// creates a new empty Collection resource and returns it 
	access(all)
	fun createEmptyCollection(): @Collection{ 
		return <-create Collection()
	}
	
	// NFTMinter
	//
	// Resource that would be owned by an admin or by a smart contract 
	// that allows them to mint new NFTs when needed
	access(all)
	resource NFTMinter{ 
		// the ID that is used to mint NFTs
		// it is only incremented so that NFT ids remain
		// unique. It also keeps track of the total number of NFTs
		// in existence
		access(all)
		var idCount: UInt64
		
		init(){ 
			self.idCount = 1
		}
		
		// mintNFT 
		//
		// Function that mints a new NFT with a new ID
		// and returns it to the caller
		access(all)
		fun mintNFT(): @NFT{ 
			// create a new NFT
			var newNFT <- create NFT(initID: self.idCount)
			// change the id so that each ID is unique
			self.idCount = self.idCount + 1
			return <-newNFT
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/nftTutorialCollection
		self.CollectionPublicPath = /public/nftTutorialCollection
		self.MinterStoragePath = /storage/nftTutorialMinter
		// store an empty NFT Collection in account storage
		self.account.storage.save(<-self.createEmptyCollection(), to: self.CollectionStoragePath)
		// publish a reference to the Collection in storage
		var capability_1 =
			self.account.capabilities.storage.issue<&{NFTReceiver}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		// store a minter resource in account storage
		self.account.storage.save(<-create NFTMinter(), to: self.MinterStoragePath)
	}
}
