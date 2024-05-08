import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract Ticket: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Minted(to: Address, tokenId: UInt64, level: UInt8, issuePrice: UFix64)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event TicketDestroyed(id: UInt64)
	
	access(all)
	enum Level: UInt8{ 
		access(all)
		case One
		
		access(all)
		case Two
		
		access(all)
		case Three
	}
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let issuePrice: UFix64
		
		access(all)
		let level: UInt8
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64, issuePrice: UFix64, level: Level){ 
			self.id = id
			self.issuePrice = issuePrice
			self.level = level.rawValue
		}
	}
	
	access(all)
	resource interface TicketCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowTicket(id: UInt64): &Ticket.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Ticket reference: the ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		fun getCounts():{ UInt8: UInt64}
	}
	
	access(all)
	resource Collection: TicketCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		var counts:{ UInt8: UInt64}
		
		init(){ 
			self.ownedNFTs <-{} 
			self.counts ={} 
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let level = self.borrowTicket(id: withdrawID)?.level ?? panic("Level missing")
			self.counts[level] = self.counts[level]! - 1
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Ticket.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			self.counts[token.level] = (self.counts[token.level] ?? 0) + 1
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowTicket(id: UInt64): &Ticket.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Ticket.NFT
			}
			return nil
		}
		
		access(all)
		fun getCounts():{ UInt8: UInt64}{ 
			return self.counts
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
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, issuePrice: UFix64, level: Level){ 
			
			// create a new NFT
			var newNFT <- create NFT(id: Ticket.totalSupply + 1, issuePrice: issuePrice, level: level)
			let id = newNFT.id
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			Ticket.totalSupply = Ticket.totalSupply + 1
			emit Minted(to: (recipient.owner!).address, tokenId: id, level: level.rawValue, issuePrice: issuePrice)
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/BNMUTicketNFTCollection006
		self.CollectionPublicPath = /public/BNMUTicketNFTCollection006
		self.MinterStoragePath = /storage/BNMUTicketNFTMinter006
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&Ticket.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
