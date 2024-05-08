import CapsuleNFT from "./CapsuleNFT.cdc"

access(all)
contract EventTickets: CapsuleNFT{ 
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
	event TicketMinted(id: String, ticketId: UInt64, ticketCategory: String, eventName: String, retailPrice: UFix64, mintedTime: String, rarity: String, edition: String, mediaUri: String, resourceId: UInt64)
	
	access(all)
	event TicketDestroyed(id: String)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	/// NFT:
	/// An EventTicket as an NFT
	access(all)
	resource NFT: CapsuleNFT.INFT{ 
		access(all)
		let id: String
		
		access(all)
		let ticketId: UInt64
		
		access(all)
		let ticketCategory: String
		
		access(all)
		let eventName: String
		
		access(all)
		let retailPrice: UFix64
		
		access(all)
		let mintedTime: String
		
		access(all)
		let rarity: String
		
		access(all)
		let edition: String
		
		access(all)
		let mediaUri: String
		
		init(id: String, ticketId: UInt64, ticketCategory: String, eventName: String, retailPrice: UFix64, mintedTime: String, rarity: String, edition: String, mediaUri: String){ 
			self.id = id
			self.ticketId = ticketId
			self.ticketCategory = ticketCategory
			self.eventName = eventName
			self.retailPrice = retailPrice
			self.mintedTime = mintedTime
			self.rarity = rarity
			self.edition = edition
			self.mediaUri = mediaUri
		}
	}
	
	/// EventTicketsCollectionPublic:
	/// This is the interface that users can cast their EventTicket Collection as, 
	/// in order to allow others to deposit an EventTicket into their Collection.
	/// It also allows for reading the details of an EventTicket in the Collection.
	access(all)
	resource interface EventTicketsCollectionPublic{ 
		access(all)
		fun deposit(token: @{CapsuleNFT.NFT})
		
		access(all)
		fun getIDs(): [String]
		
		access(all)
		fun borrowNFT(id: String): &{CapsuleNFT.NFT}
		
		access(all)
		fun borrowTicket(id: String): &EventTickets.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow EventTicket reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	/// Collection:
	/// A collection of EventTicket NFTs owned by an account
	access(all)
	resource Collection: EventTicketsCollectionPublic, CapsuleNFT.Provider, CapsuleNFT.Receiver, CapsuleNFT.CollectionPublic{ 
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
			let delta: UInt64 = startUsed - endUsed
			emit Withdraw(id: token.id, size: delta, from: address)
			return <-token
		}
		
		/// Takes an NFT, adds it to the Collections dictionary, and adds the ID to the id array
		access(all)
		fun deposit(token: @{CapsuleNFT.NFT}){ 
			let address: Address? = self.owner?.address
			let account: &Account = getAccount(address!)
			let startUsed: UInt64 = account.storage.used
			let token: @EventTickets.NFT <- token as! @EventTickets.NFT
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
		
		/// Gets a reference to an NFT in the Collection so that the caller can read its metadata and call its methods
		access(all)
		fun borrowNFT(id: String): &{CapsuleNFT.NFT}{ 
			return (&self.ownedNFTs[id] as &{CapsuleNFT.NFT}?)!
		}
		
		// Safe way to borrow a reference to an NFT that does not panic
		// Also now part of the CapsuleNFT.PublicCollection interface
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: An optional reference to the desired NFT, will be nil if the passed ID does not exist
		access(all)
		fun borrowNFTSafe(id: String): &{CapsuleNFT.NFT}?{ 
			if let nftRef = &self.ownedNFTs[id] as &{CapsuleNFT.NFT}?{ 
				return nftRef
			}
			return nil
		}
		
		access(all)
		fun borrowTicket(id: String): &EventTickets.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorised reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{CapsuleNFT.NFT}?)!
				return ref as! &EventTickets.NFT
			} else{ 
				return nil
			}
		}
	
	// If a transaction destroys the Collection resource,
	// All the NFTs contained within are also destroyed.
	//
	}
	
	/// Public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(): @{CapsuleNFT.Collection}{ 
		emit CollectionCreated()
		return <-create Collection()
	}
	
	/// Minter:
	/// Resource that an Admin (or similar) would own to be able to mint new EventTicket NFTs.
	access(all)
	resource NFTMinter{ 
		/// Mints a new EventTicket NFT with a new ID and deposits it in the recipients Collection.
		access(all)
		fun mintTicket(recipient: &{CapsuleNFT.CollectionPublic}, id: String, ticketId: UInt64, ticketCategory: String, eventName: String, retailPrice: UFix64, mintedTime: String, rarity: String, edition: String, mediaUri: String){ 
			// Create a new EventTicket
			var ticket: @EventTickets.NFT <- create NFT(id: id, ticketId: ticketId, ticketCategory: ticketCategory, eventName: eventName, retailPrice: retailPrice, mintedTime: mintedTime, rarity: rarity, edition: edition, mediaUri: mediaUri)
			// Emit Events
			// emit Minted(id: id)
			emit TicketMinted(id: id, ticketId: ticketId, ticketCategory: ticketCategory, eventName: eventName, retailPrice: retailPrice, mintedTime: mintedTime, rarity: rarity, edition: edition, mediaUri: mediaUri, resourceId: ticket.uuid)
			// Increment the total of minted EventTickets
			EventTickets.totalMinted = EventTickets.totalMinted + 1
			
			// Deposit it in the recipient's account using their reference
			recipient.deposit(token: <-ticket)
		}
	}
	
	init(){ 
		// Initialize the total minted number of EventTickets
		self.totalMinted = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/CapsuleTicketsCollection
		self.CollectionPublicPath = /public/CapsuleTicketsCollection
		self.MinterStoragePath = /storage/CapsuleTicketsMinter
		
		// Create a Collection resource and save it to storage
		let collection: @EventTickets.Collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&EventTickets.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter: @EventTickets.NFTMinter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
