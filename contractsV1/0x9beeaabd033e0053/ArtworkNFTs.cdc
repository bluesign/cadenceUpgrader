import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

// ArtworkNFTs
// NFT items for Artwork NFT!
//
access(all)
contract ArtworkNFTs: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, typeID: UInt64, hashCode: String)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of ArtworkNFTs that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// NFT
	// A Artwork as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// The token's type, e.g. 0 == Image, Video
		access(all)
		let typeID: UInt64
		
		// the NFT hash code
		access(all)
		let hashCode: String
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(initID: UInt64, initTypeID: UInt64, initHashCode: String){ 
			self.id = initID
			self.typeID = initTypeID
			self.hashCode = initHashCode
		}
	}
	
	// This is the interface that users can cast their ArtworkNFTs Collection as
	// to allow others to deposit ArtworkNFTs into their Collection. It also allows for reading
	// the details of ArtworkNFTs in the Collection.
	access(all)
	resource interface ArtworkNFTsCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowArtworkNFT(id: UInt64): &ArtworkNFTs.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow ArtworkNFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of ArtworkNFT NFTs owned by an account
	//
	access(all)
	resource Collection: ArtworkNFTsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
			let token <- token as! @ArtworkNFTs.NFT
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
		
		// borrowArtworkNFT
		// Gets a reference to an NFT in the collection as a ArtworkNFT,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the ArtworkNFT.
		//
		access(all)
		fun borrowArtworkNFT(id: UInt64): &ArtworkNFTs.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &ArtworkNFTs.NFT
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, typeID: UInt64, hashCode: String){ 
			emit Minted(id: ArtworkNFTs.totalSupply, typeID: typeID, hashCode: hashCode)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create ArtworkNFTs.NFT(initID: ArtworkNFTs.totalSupply, initTypeID: typeID, initHashCode: hashCode))
			ArtworkNFTs.totalSupply = ArtworkNFTs.totalSupply + 1 as UInt64
		}
	}
	
	// fetch
	// Get a reference to a ArtworkNFT from an account's Collection, if available.
	// If an account does not have a ArtworkNFTs.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &ArtworkNFTs.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&ArtworkNFTs.Collection>(ArtworkNFTs.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust ArtworkNFTs.Collection.borowArtworkNFT to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowArtworkNFT(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/PaprikaArtworkNFTsCollection
		self.CollectionPublicPath = /public/PaprikaArtworkNFTsCollection
		self.MinterStoragePath = /storage/PaprikaArtworkNFTsMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
