import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

// AvatarArtNFT
// NFT items for AvatarArt!
access(all)
contract AvatarArtNFT: NonFungibleToken{ 
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(tokenId: UInt64, metadata: String)
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let ReceiverPublicPath: PublicPath
	
	// totalSupply
	// The total number of AvatarArtNFT that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// NFT
	// A AvatarArtNFT as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		access(all)
		let metadata: String
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(initID: UInt64, metadata: String){ 
			self.id = initID
			self.metadata = metadata
		}
	}
	
	// This is the interface that users can cast their AvatarArtNFT Collection as
	// to allow others to deposit AvatarArtNFT into their Collection. It also allows for reading
	// the details of AvatarArtNFT in the Collection.
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowAvatarArtNFT(id: UInt64): &AvatarArtNFT.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow AvatarArtNFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of AvatarArtNFT NFTs owned by an account
	//
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
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
			let token <- token as! @AvatarArtNFT.NFT
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
		
		// borrowAvatarArtNFT
		// Gets a reference to an NFT in the collection as a AvatarArtNFT,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the AvatarArtNFT.
		//
		access(all)
		fun borrowAvatarArtNFT(id: UInt64): &AvatarArtNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &AvatarArtNFT.NFT
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
		fun mintNFT(metadata: String, recipient: &{AvatarArtNFT.CollectionPublic}){ 
			// ID start from 1000
			let id = 1000 as UInt64 + AvatarArtNFT.totalSupply
			emit Minted(tokenId: id, metadata: metadata)
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create AvatarArtNFT.NFT(initID: id, metadata: metadata))
			AvatarArtNFT.totalSupply = AvatarArtNFT.totalSupply + 1
		}
	}
	
	// fetch
	// Get a reference to a AvatarArtNFT from an account's Collection, if available.
	// If an account does not have a AvatarArtNFT.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &AvatarArtNFT.NFT?{ 
		let collection = getAccount(from).capabilities.get<&AvatarArtNFT.Collection>(AvatarArtNFT.CollectionPublicPath).borrow<&AvatarArtNFT.Collection>() ?? panic("Couldn't get collection")
		// We trust AvatarArtNFT.Collection.borowAvatarArtNFT to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowAvatarArtNFT(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/avatarArtNFTCollection04
		self.CollectionPublicPath = /public/avatarArtNFTCollection04
		self.MinterStoragePath = /storage/avatarArtNFTMinter04
		self.ReceiverPublicPath = /public/avatarArtReceiver04
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
