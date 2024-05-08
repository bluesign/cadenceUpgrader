import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

//
access(all)
contract NyatheesOVO: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, metadata:{ String: String})
	
	access(all)
	event MintedForMysteryBox(id: UInt64, uuid: UInt64, metadata:{ String: String})
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let MinterPrivatePath: PrivatePath
	
	// totalSupply
	// The total number of NFTItem that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// NFT
	// A NFT Item as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// The token's metadata
		access(self)
		let metadata:{ String: String}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		// initializer
		//
		init(initID: UInt64, metadata:{ String: String}){ 
			self.id = initID
			self.metadata = metadata
		}
	}
	
	// This is the interface that users can cast their NFTItem Collection as
	// to allow others to deposit NFTItem into their Collection. It also allows for reading
	// the details of NFTItem in the Collection.
	access(all)
	resource interface NFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun idExists(id: UInt64): Bool
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowNFTItem(id: UInt64): &NyatheesOVO.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow NFTItem reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// return the content for this NFT
	// only for mystery box
	access(all)
	resource interface MinterPrivate{ 
		access(all)
		fun mintNFTForMysterBox(receiver: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String})
	}
	
	// Collection
	// A collection of NFTItem NFTs owned by an account
	//
	access(all)
	resource Collection: NFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
		
		access(all)
		fun idExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @NyatheesOVO.NFT
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
		
		// borrowNFTItem
		// Gets a reference to an NFT in the collection as a NFTItem,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the NFTItem.
		//
		access(all)
		fun borrowNFTItem(id: UInt64): &NyatheesOVO.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &NyatheesOVO.NFT
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
	resource NFTMinter: MinterPrivate{ 
		
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}){ 
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create NyatheesOVO.NFT(initID: NyatheesOVO.totalSupply, metadata: metadata))
			emit Minted(id: NyatheesOVO.totalSupply, metadata: metadata)
			NyatheesOVO.totalSupply = NyatheesOVO.totalSupply + 1 as UInt64
		}
		
		access(all)
		fun mintNFTForMysterBox(receiver: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}){ 
			
			// deposit it in the recipient's account using their reference
			var newNFT <- create NyatheesOVO.NFT(initID: NyatheesOVO.totalSupply, metadata: metadata)
			emit MintedForMysteryBox(id: NyatheesOVO.totalSupply, uuid: newNFT.uuid, metadata: metadata)
			receiver.deposit(token: <-newNFT)
			NyatheesOVO.totalSupply = NyatheesOVO.totalSupply + 1 as UInt64
		}
	}
	
	// fetch
	// Get a reference to a NFTItem from an account's Collection, if available.
	// If an account does not have a NFTItem.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &NyatheesOVO.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&NyatheesOVO.Collection>(NyatheesOVO.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust NFTItem.Collection.NFTItem to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowNFTItem(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/NyatheesOVOCollection
		self.CollectionPublicPath = /public/NyatheesOVOCollection
		self.MinterStoragePath = /storage/NyatheesOVOMinter
		self.CollectionPrivatePath = /private/NyatheesOVOMintForBox
		self.MinterPrivatePath = /private/MinterForBox
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&NyatheesOVO.NFTMinter>(self.MinterStoragePath)
		self.account.capabilities.publish(capability_1, at: self.MinterPrivatePath)
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		// create a public capability for the collection
		var capability_2 = self.account.capabilities.storage.issue<&NyatheesOVO.Collection>(NyatheesOVO.CollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: NyatheesOVO.CollectionPublicPath)
		emit ContractInitialized()
	}
}
