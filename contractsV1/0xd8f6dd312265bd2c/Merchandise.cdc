import CapsuleNFT from "./CapsuleNFT.cdc"

access(all)
contract Merchandise: CapsuleNFT{ 
	access(all)
	var totalMinted: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event CollectionCreated()
	
	access(all)
	event CollectionDestroyed(length: Int)
	
	access(all)
	event Withdraw(id: String, size: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: String, size: UInt64, to: Address?)
	
	access(all)
	event Minted(id: String)
	
	access(all)
	event MerchandiseMinted(id: String, item: String, collection: String, type: String, edition: String, description: String, retailPrice: UFix64, mediaUri: String, mintedTime: String, resourceId: UInt64)
	
	access(all)
	event MerchandiseDestroyed(id: String)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	/// NFT:
	/// A Merchandise as an NFT
	access(all)
	resource NFT: CapsuleNFT.INFT{ 
		access(all)
		let id: String
		
		access(all)
		let item: String
		
		access(all)
		let collection: String
		
		access(all)
		let type: String
		
		access(all)
		let edition: String
		
		access(all)
		let description: String
		
		access(all)
		let retailPrice: UFix64
		
		access(all)
		let mediaUri: String
		
		access(all)
		let mintedTime: String
		
		init(id: String, item: String, collection: String, type: String, edition: String, description: String, retailPrice: UFix64, mediaUri: String, mintedTime: String){ 
			self.id = id
			self.item = item
			self.collection = collection
			self.type = type
			self.edition = edition
			self.description = description
			self.retailPrice = retailPrice
			self.mediaUri = mediaUri
			self.mintedTime = mintedTime
		}
	}
	
	/// MerchandiseCollectionPublic:
	/// This is the interface that users can cast their Merchandise Collection as,
	/// in order to allow others to deposit a Merchandise into their Collection. 
	/// It also allows for reading the details of an Merchandise in the Collection.
	access(all)
	resource interface MerchandiseCollectionPublic{ 
		access(all)
		fun deposit(token: @{CapsuleNFT.NFT})
		
		access(all)
		fun getIDs(): [String]
		
		access(all)
		fun borrowNFT(id: String): &{CapsuleNFT.NFT}
		
		access(all)
		fun borrowMerchandise(id: String): &Merchandise.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Collectible reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	/// Collection:
	/// A collection of Merchandise NFTs owned by an account
	access(all)
	resource Collection: MerchandiseCollectionPublic, CapsuleNFT.Provider, CapsuleNFT.Receiver, CapsuleNFT.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with a `String` ID field
		access(all)
		var ownedNFTs: @{String:{ CapsuleNFT.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		/// Removes an NFT from the collection and moves it to the caller
		access(all)
		fun withdraw(id: String): @{CapsuleNFT.NFT}{ 
			let address: Address? = self.owner?.address
			let account: &Account = getAccount(address!)
			let startUsed: UInt64 = account.storage.used
			let token: @{CapsuleNFT.NFT} <- self.ownedNFTs.remove(key: id) ?? panic("Missing EventTicket NFT!")
			let endUsed: UInt64 = account.storage.used
			let delta: UInt64 = endUsed - startUsed
			emit Withdraw(id: token.id, size: delta, from: address)
			return <-token
		}
		
		/// Takes an NFT, adds it to the Collection dictionary and adds the ID to the id array
		access(all)
		fun deposit(token: @{CapsuleNFT.NFT}){ 
			let address: Address? = self.owner?.address
			let account: &Account = getAccount(address!)
			let startUsed: UInt64 = account.storage.used
			let token: @Merchandise.NFT <- token as! @Merchandise.NFT
			let id: String = token.id
			// Add the new token to the dictionary which removes the old one
			let oldToken: @{CapsuleNFT.NFT}? <- self.ownedNFTs[id] <- token
			let endUsed: UInt64 = account.storage.used
			let delta: UInt64 = endUsed - startUsed
			emit Deposit(id: id, size: delta, to: address)
			destroy oldToken
		}
		
		/// Returns an array of the IDs that are in the collection
		access(all)
		fun getIDs(): [String]{ 
			return self.ownedNFTs.keys
		}
		
		/// Gets a reference to an NFT in the collection so that the caller can read its metadata and call its methods
		access(all)
		fun borrowNFT(id: String): &{CapsuleNFT.NFT}{ 
			return (&self.ownedNFTs[id] as &{CapsuleNFT.NFT}?)!
		}
		
		/// Gets a reference to a Merchandise in the Collection
		access(all)
		fun borrowMerchandise(id: String): &Merchandise.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorised reference to allow downcasting
				let ref: &{CapsuleNFT.NFT} = (&self.ownedNFTs[id] as &{CapsuleNFT.NFT}?)!
				return ref as! &Merchandise.NFT
			} else{ 
				return nil
			}
		}
	}
	
	/// Public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(): @{CapsuleNFT.Collection}{ 
		emit CollectionCreated()
		return <-create Collection()
	}
	
	/// Resource that an admin or similar would own to be able to mint new NFTs
	access(all)
	resource NFTMinter{ 
		/// Mints a new Merchandise. 
		/// Deposits it in the recipients Collection using their PublicCollection reference.
		access(all)
		fun mintMerchandise(recipientCollection: &{CapsuleNFT.CollectionPublic}, id: String, item: String, collection: String, type: String, edition: String, description: String, retailPrice: UFix64, mediaUri: String, mintedTime: String){ 
			// Create a new Merchandise NFT
			var merchandise: @Merchandise.NFT <- create NFT(id: id, item: item, collection: collection, type: type, edition: edition, description: description, retailPrice: retailPrice, mediaUri: mediaUri, mintedTime: mintedTime)
			// Emit Events
			// emit Minted(id: id)
			emit MerchandiseMinted(id: id, item: item, collection: collection, type: type, edition: edition, description: description, retailPrice: retailPrice, mediaUri: mediaUri, mintedTime: mintedTime, resourceId: merchandise.uuid)
			// Increment the total of minted Merchandise
			Merchandise.totalMinted = Merchandise.totalMinted + 1
			
			// Deposit it in the recipient's account using their reference
			recipientCollection.deposit(token: <-merchandise)
		}
	}
	
	init(){ 
		// Initialize the total of minted Merchandise
		self.totalMinted = 0
		
		// Set the itemd paths
		self.CollectionStoragePath = /storage/CapsuleMerchandiseCollection
		self.CollectionPublicPath = /public/CapsuleMerchandiseCollection
		self.MinterStoragePath = /storage/CapsuleMerchandiseMinter
		
		// Create a Merchandise resource and save it to storage
		let collection: @Merchandise.Collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// Create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&Merchandise.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter: @Merchandise.NFTMinter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
