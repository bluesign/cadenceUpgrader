import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

// Peek Token
// NFT Token representing shares of creator accounts on Peek.
//
access(all)
contract PeekToken: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, userUUID: String)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of PeekToken's that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// NFT
	// A Peek token as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// The UUID of the Peek user this token represents a share of.
		access(all)
		let userUUID: String
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(initID: UInt64, initUserUUID: String){ 
			self.id = initID
			self.userUUID = initUserUUID
		}
	}
	
	// This is the interface that users can cast their PeekToken Collection as
	// to allow others to deposit PeekToken's into their Collection. It also allows for reading
	// the details of PeekToken's in the Collection.
	access(all)
	resource interface PeekTokenCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowPeekToken(id: UInt64): &PeekToken.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow PeekToken reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of PeekToken NFTs owned by an account
	//
	access(all)
	resource Collection: PeekTokenCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @PeekToken.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs
		// Returns an array of the IDs that are in the collection
		//
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// borrowPeekToken
		// Gets a reference to an NFT in the collection as a PeekToken,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the PeekToken.
		//
		access(all)
		fun borrowPeekToken(id: UInt64): &PeekToken.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &PeekToken.NFT
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
		
		// destructor
		// initializer
		//
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// NFTMinter
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, userUUID: String){ 
			emit Minted(id: PeekToken.totalSupply, userUUID: userUUID)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create PeekToken.NFT(initID: PeekToken.totalSupply, initUserUUID: userUUID))
			PeekToken.totalSupply = PeekToken.totalSupply + 1 as UInt64
		}
	}
	
	// fetch
	// Get a reference to a PeekToken from an account's Collection, if available.
	// If an account does not have a PeekToken.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &PeekToken.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&PeekToken.Collection>(PeekToken.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust PeekToken.Collection.borowPeekToken to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowPeekToken(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/PeekTokenCollection
		self.CollectionPublicPath = /public/PeekTokenCollection
		self.MinterStoragePath = /storage/PeekTokenMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
