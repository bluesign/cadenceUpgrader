import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

// BnGNFT.cdc
access(all)
contract BnGNFT: NonFungibleToken{ 
	
	// Declare the NFT resource type
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let metadata:{ String: String}
		
		// The unique ID that differentiates each NFT
		access(all)
		let id: UInt64
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// Initialize the field in the init function
		init(initID: UInt64, metadata:{ String: String}){ 
			self.id = initID
			self.metadata = metadata
		}
	}
	
	access(all)
	resource interface BnGNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowBnGNFT(id: UInt64): &BnGNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow BnGNFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// The definition of the Collection resource that
	// holds the NFTs that a user owns
	access(all)
	resource Collection: BnGNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// Dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// Initialize the NFTs field to an empty collection
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw 
		//
		// Function that removes an NFT from the collection 
		// and moves it to the calling context
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// If the NFT isn't found, the transaction panics and reverts
			let token <- self.ownedNFTs.remove(key: withdrawID)!
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			// Add the new token to the dictionary with a force assignment
			// If there is already a value at that key, it will fail and revert
			let token <- token as! @BnGNFT.NFT
			let id: UInt64 = token.id
			self.ownedNFTs[id] <-! token
			emit Deposit(id: id, to: self.owner?.address)
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		access(all)
		fun borrowBnGNFT(id: UInt64): &BnGNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &BnGNFT.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Creates a new empty Collection resource and returns it 
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// NFTMinter
	//
	// Resource that would be owned by an admin or by a smart contract 
	// that allows them to mint new NFTs when needed
	access(all)
	resource NFTMinter{ 
		
		// mintNFT 
		//
		// Function that mints a new NFT with a new ID
		// and returns it to the caller
		access(all)
		fun mintNFT(metadata:{ String: String}): @BnGNFT.NFT{ 
			
			// create a new NFT
			var newNFT <- create BnGNFT.NFT(initID: BnGNFT.totalSupply, metadata: metadata)
			BnGNFT.totalSupply = BnGNFT.totalSupply + 1 as UInt64
			return <-newNFT
		}
	}
	
	// Total supply of BnGNFT tokens. Doubles as the NFT id.
	access(all)
	var totalSupply: UInt64
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	init(){ 
		self.CollectionStoragePath = /storage/BnGNFTCollection
		self.CollectionPublicPath = /public/BnGNFTCollection
		self.MinterStoragePath = /storage/BnGNFTMinter
		self.totalSupply = 0
		
		// Store a minter resource in account storage
		self.account.storage.save(<-create NFTMinter(), to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
