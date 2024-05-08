import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

// Basketballs
// NFT basketballs!
//
access(all)
contract Basketballs: NonFungibleToken{ 
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event EditionCreated(editionID: UInt32, name: String, description: String, imageURL: String)
	
	access(all)
	event BasketballMinted(id: UInt64, editionID: UInt32, serialNumber: UInt64)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var nextEditionID: UInt32
	
	access(self)
	var editions:{ UInt32: Edition}
	
	access(all)
	struct EditionMetadata{ 
		access(all)
		let editionID: UInt32
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let imageURL: String
		
		access(all)
		let circulatingCount: UInt64
		
		init(editionID: UInt32, name: String, description: String, imageURL: String, circulatingCount: UInt64){ 
			self.editionID = editionID
			self.name = name
			self.description = description
			self.imageURL = imageURL
			self.circulatingCount = circulatingCount
		}
	}
	
	access(all)
	struct Edition{ 
		access(all)
		let editionID: UInt32
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let imageURL: String
		
		access(account)
		var nextSerialInEdition: UInt64
		
		init(name: String, description: String, imageURL: String){ 
			self.editionID = Basketballs.nextEditionID
			self.name = name
			self.description = description
			self.imageURL = imageURL
			self.nextSerialInEdition = 1
			Basketballs.nextEditionID = Basketballs.nextEditionID + 1 as UInt32
			emit EditionCreated(editionID: self.editionID, name: self.name, description: self.description, imageURL: self.imageURL)
		}
		
		access(all)
		fun mintBasketball(): @NFT{ 
			let basketball: @NFT <- create NFT(editionID: self.editionID, serialNumber: self.nextSerialInEdition)
			self.nextSerialInEdition = self.nextSerialInEdition + 1 as UInt64
			Basketballs.editions[self.editionID] = self
			return <-basketball
		}
		
		access(all)
		fun mintBasketballs(quantity: UInt64): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintBasketball())
				i = i + 1 as UInt64
			}
			return <-newCollection
		}
	}
	
	// NFT
	// A Basketball as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let editionID: UInt32
		
		access(all)
		let serialNumber: UInt64
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(editionID: UInt32, serialNumber: UInt64){ 
			Basketballs.totalSupply = Basketballs.totalSupply + 1 as UInt64
			self.id = Basketballs.totalSupply
			self.editionID = editionID
			self.serialNumber = serialNumber
			emit BasketballMinted(id: self.id, editionID: self.editionID, serialNumber: self.serialNumber)
		}
	}
	
	// This is the interface that users can cast their Basketballs Collection as
	// to allow others to deposit Basketballs into their Collection. It also allows for reading
	// the details of Basketballs in the Collection.
	access(all)
	resource interface BasketballsCollectionPublic{ 
		access(all)
		fun borrowBasketball(id: UInt64): &Basketballs.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Basketball reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of Basketball NFTs owned by an account
	//
	access(all)
	resource Collection: BasketballsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an UInt64 ID field
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
			let token <- token as! @Basketballs.NFT
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
		
		// borrowBasketball
		// Gets a reference to an NFT in the collection as a Basketball,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the Basketball.
		//
		access(all)
		fun borrowBasketball(id: UInt64): &Basketballs.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Basketballs.NFT
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
	
	access(all)
	resource Admin{ 
		access(all)
		fun createEdition(name: String, description: String, imageURL: String): UInt32{ 
			let edition = Edition(name: name, description: description, imageURL: imageURL)
			Basketballs.editions[edition.editionID] = edition
			return edition.editionID
		}
		
		access(all)
		fun mintBasketball(editionID: UInt32): @NFT{ 
			pre{ 
				Basketballs.editions[editionID] != nil:
					"Mint failed: Edition does not exist"
			}
			let edition: Edition = Basketballs.editions[editionID]!
			let basketball: @NFT <- edition.mintBasketball()
			return <-basketball
		}
		
		access(all)
		fun mintBasketballs(editionID: UInt32, quantity: UInt64): @Collection{ 
			pre{ 
				Basketballs.editions[editionID] != nil:
					"Mint failed: Edition does not exist"
			}
			let edition: Edition = Basketballs.editions[editionID]!
			let collection: @Collection <- edition.mintBasketballs(quantity: quantity)
			return <-collection
		}
		
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// fetch
	// Get a reference to a Basketball from an account's Collection, if available.
	// If an account does not have a Basketballs.Collection, panic.
	// If it has a collection but does not contain the itemId, return nil.
	// If it has a collection and that collection contains the itemId, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &Basketballs.NFT?{ 
		let collection = getAccount(from).capabilities.get<&Basketballs.Collection>(Basketballs.CollectionPublicPath).borrow<&Basketballs.Collection>() ?? panic("Couldn't get collection")
		// We trust Basketballs.Collection.borowBasketball to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowBasketball(id: itemID)
	}
	
	access(all)
	fun getAllEditions(): [Edition]{ 
		return self.editions.values
	}
	
	access(all)
	fun getEditionMetadata(editionID: UInt32): EditionMetadata{ 
		let edition = self.editions[editionID]!
		let metadata = EditionMetadata(editionID: edition.editionID, name: edition.name, description: edition.description, imageURL: edition.imageURL, circulatingCount: edition.nextSerialInEdition - 1 as UInt64)
		return metadata
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/BallmartBasketballsCollection
		self.CollectionPublicPath = /public/BallmartBasketballsCollection
		self.CollectionPrivatePath = /private/BallmartBasketballsCollection
		self.AdminStoragePath = /storage/BallmartBasketballsAdmin
		
		// Initialize the total supply
		self.totalSupply = 0
		self.editions ={} 
		self.nextEditionID = 1
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
