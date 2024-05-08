import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

// Owners NFT
//
access(all)
contract Owners: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let OperatorStoragePath: StoragePath
	
	access(all)
	let OperatorPublicPath: PublicPath
	
	// totalSupply
	// The total number of Twitter Account NFT that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// NFT
	// A Twitter Account as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// The Twitter account ID
		access(all)
		let twitterID: UInt64
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(initID: UInt64, initTwitterID: UInt64){ 
			self.id = initID
			self.twitterID = initTwitterID
		}
	}
	
	// This is the interface that users can cast their Owners Collection as
	// to allow others to deposit Owners into their Collection. It also allows for reading
	// the details of Owners in the Collection.
	access(all)
	resource interface OwnersCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowOwners(id: UInt64): &Owners.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Owners reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of Owners NFTs owned by an account
	//
	access(all)
	resource Collection: OwnersCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
			let token <- token as! @Owners.NFT
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
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowOwners
		// Gets a reference to an NFT in the collection as a Owners,
		// This is safe as there are no functions that can be called on the Owners.
		//
		access(all)
		fun borrowOwners(id: UInt64): &Owners.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Owners.NFT
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, twitterID: UInt64){ 
			emit Minted(id: Owners.totalSupply)
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create Owners.NFT(initID: Owners.totalSupply, initTwitterID: twitterID))
			Owners.totalSupply = Owners.totalSupply + 1
		}
	}
	
	access(all)
	resource interface NFTOperatorPublic{ 
		// give the operator ability to mint new NFT
		access(all)
		fun addMinterCapability(cap: Capability<&NFTMinter>)
		
		// give the operator abililty to transfer NFT from admin wallet
		access(all)
		fun addTransferCapability(cap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>)
	}
	
	// account operator store this resource in their account
	// in order to be able to receive minter capability
	access(all)
	resource NFTOperator: NFTOperatorPublic{ 
		access(all)
		var operatorCapability: Capability<&NFTMinter>?
		
		access(all)
		var nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>?
		
		init(){ 
			self.operatorCapability = nil
			self.nftProviderCapability = nil
		}
		
		access(all)
		fun addMinterCapability(cap: Capability<&NFTMinter>){ 
			pre{ 
				cap.borrow() != nil:
					"Invalid nft minter capability"
			}
			self.operatorCapability = cap
		}
		
		access(all)
		fun addTransferCapability(cap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>){ 
			pre{ 
				cap.borrow() != nil:
					"Invalid nft provider capability"
			}
			self.nftProviderCapability = cap
		}
	}
	
	access(all)
	fun createNFTOperator(): @NFTOperator{ 
		return <-create NFTOperator()
	}
	
	// fetch
	// Get a reference to a Owners from an account's Collection, if available.
	// If an account does not have a Owners.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &Owners.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&Owners.Collection>(Owners.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust Owners.Collection.borowOwners to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowOwners(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		
		// Set our named paths
		self.CollectionStoragePath = /storage/OwnersCollectionV1
		self.CollectionPublicPath = /public/OwnersCollectionV1
		self.MinterStoragePath = /storage/OwnersMinterV1
		self.OperatorStoragePath = /storage/OwnersOperatorV1
		self.OperatorPublicPath = /public/OwnersOperatorV1
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
