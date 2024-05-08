import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract DimeCollectible: NonFungibleToken{ 
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64)
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterPublicPath: PublicPath
	
	// The total number of DimeCollectibles that have been minted
	access(all)
	var totalSupply: UInt64
	
	// DimeCollectible as a NFT
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// The token's original creator
		access(all)
		let creator: Address
		
		// The url corresponding to the token's content
		access(all)
		let content: String
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(initID: UInt64, initCreator: Address, initContent: String){ 
			self.id = initID
			self.creator = initCreator
			self.content = initContent
		}
	}
	
	// This is the interface that users can cast their Collection as
	// to allow others to deposit into it. It also allows for
	// reading the details of items in the Collection.
	access(all)
	resource interface DimeCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowCollectible(id: UInt64): &DimeCollectible.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of NFTs owned by an account
	//
	access(all)
	resource Collection: DimeCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// Dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// Removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// Takes a NFT and adds it to the collection dictionary
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @DimeCollectible.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// Returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// Gets a reference to an NFT in the collection as a DimeCollectible.
		access(all)
		fun borrowCollectible(id: UInt64): &DimeCollectible.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &DimeCollectible.NFT
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
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// Public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Resource to mint new NFTs
	access(all)
	resource NFTMinter{ 
		// Mints an NFT with a new ID and deposits it in the recipient's
		// collection using their collection reference
		access(all)
		fun mintNFT(collection: &{NonFungibleToken.CollectionPublic}, tokenId: UInt64, creator: Address, content: String){ 
			emit Minted(id: tokenId)
			
			// deposit it in the collection using the reference
			collection.deposit(token: <-create DimeCollectible.NFT(initID: tokenId, initCreator: creator, initContent: content))
			DimeCollectible.totalSupply = DimeCollectible.totalSupply + 1 as UInt64
		}
	}
	
	// Get a reference to an item in an account's Collection, if available.
	// If an account does not have a DimeCollectible.Collection, panic.
	// If it has a collection but does not contain the itemId, return nil.
	// If it has a collection and that collection contains the itemId,
	// return a reference to it
	access(all)
	fun fetch(_ from: Address, itemId: UInt64): &DimeCollectible.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&DimeCollectible.Collection>(DimeCollectible.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		return collection.borrowCollectible(id: itemId)
	}
	
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/DimeCollection
		self.CollectionPublicPath = /public/DimeCollection
		self.MinterStoragePath = /storage/DimeMinter
		self.MinterPublicPath = /public/DimeMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage.
		// Create a public link so all users can use the same global one
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&NFTMinter>(self.MinterStoragePath)
		self.account.capabilities.publish(capability_1, at: self.MinterPublicPath)
		emit ContractInitialized()
	}
}
