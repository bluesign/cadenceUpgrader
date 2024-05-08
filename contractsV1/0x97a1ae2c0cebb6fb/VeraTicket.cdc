import VeraEvent from "./VeraEvent.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

// VeraTicket
// Ticket NFT items Contract!
//
access(all)
contract VeraTicket: NonFungibleToken{ 
	
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
	
	access(all)
	event Destroy(id: UInt64)
	
	// Named Paths
	//
	access(all)
	let VeraTicketStorage: StoragePath
	
	access(all)
	let VeraTicketPubStorage: PublicPath
	
	access(all)
	let VeraMinterStorage: StoragePath
	
	// totalSupply
	// The total number of Tickets that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// Declare an enum named `Color` which has the raw value type `UInt8`,
	// and declare three enum cases: `red`, `green`, and `blue`
	//
	access(all)
	enum NFTType: UInt8{ 
		access(all)
		case GeneralAdmission
		
		access(all)
		case AssignedSeating
	}
	
	// NFT
	// A Ticket as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		access(all)
		let eventID: UInt64
		
		access(all)
		let type: VeraTicket.NFTType
		
		access(all)
		let tier: UInt64
		
		access(all)
		let subtier: UInt64
		
		access(all)
		let tokenURI: String
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(initID: UInt64, initEventID: UInt64, initType: VeraTicket.NFTType, initTier: UInt64, initSubTier: UInt64, initTokenURI: String){ 
			self.id = initID
			self.eventID = initEventID
			self.type = initType
			self.tier = initTier
			self.subtier = initSubTier
			self.tokenURI = initTokenURI
		}
	}
	
	// NFT
	// A Ticket as an NFT
	//
	access(all)
	struct NFTStruct{ 
		access(all)
		let eventID: UInt64
		
		access(all)
		let type: VeraTicket.NFTType
		
		access(all)
		let tier: UInt64
		
		access(all)
		let subtier: UInt64
		
		access(all)
		let tokenURI: String
		
		// initializer
		//
		init(initEventID: UInt64, initType: VeraTicket.NFTType, initTier: UInt64, initSubTier: UInt64, initTokenURI: String){ 
			self.eventID = initEventID
			self.type = initType
			self.tier = initTier
			self.subtier = initSubTier
			self.tokenURI = initTokenURI
		}
	}
	
	// This is the interface that users can cast their Tickets Collection as
	// to allow others to deposit Tickets into their Collection. It also allows for reading
	// the details of Tickets in the Collection.
	access(all)
	resource interface TicketsCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowTicket(id: UInt64): &VeraTicket.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Ticket reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		fun destroyTicket(eventID: UInt64, id: UInt64, tier: UInt64, subtier: UInt64)
	}
	
	// Collection
	// A collection of Ticket NFTs owned by an account
	//
	access(all)
	resource Collection: TicketsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
			let token <- token as! @VeraTicket.NFT
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
		
		// borrowTicket
		// Gets a reference to an NFT in the collection as a Ticket,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the Ticket.
		//
		access(all)
		fun borrowTicket(id: UInt64): &VeraTicket.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &VeraTicket.NFT
			} else{ 
				return nil
			}
		}
		
		// destructor
		access(all)
		fun destroyTicket(eventID: UInt64, id: UInt64, tier: UInt64, subtier: UInt64){ 
			if self.ownedNFTs[id] != nil{ 
				let token <- self.ownedNFTs.remove(key: id) ?? panic("missing NFT")
				destroy token
				// let eventCollection = VeraTicket.account.borrow<&VeraEvent.EventCollection>(from: VeraEvent.VeraEventStorage)!
				//eventCollection.decrementTicketMinted(eventId: eventID, tier: tier, subtier: subtier)
				emit Destroy(id: id)
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
	
	access(all)
	resource NFTMinter{ 
		
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic, VeraTicket.TicketsCollectionPublic}, eventID: UInt64, type: VeraTicket.NFTType, tier: UInt64, subtier: UInt64, tokenURI: String){ 
			let veraevent: VeraEvent.EventStruct = VeraEvent.getEvent(id: eventID)
			var eventMaxTickets: UInt64 = veraevent.maxTickets
			var eventTotalTicketsMinted: UInt64 = veraevent.totalTicketsMinted
			var maxTickets: UInt64 = 0
			var ticketsMinted: UInt64 = 0
			if type == VeraTicket.NFTType.GeneralAdmission{ 
				var eventtier: VeraEvent.Tier = veraevent.getTier(tier: tier)!
				maxTickets = eventtier.maxTickets
				ticketsMinted = eventtier.ticketsMinted
			} else if type == VeraTicket.NFTType.AssignedSeating{ 
				var eventtier: VeraEvent.Tier = veraevent.getTier(tier: tier)!
				var eventsubtier: VeraEvent.SubTier = veraevent.getSubTier(tier: tier, subtier: subtier)!
				maxTickets = eventsubtier.maxTickets
				ticketsMinted = eventsubtier.ticketsMinted
			}
			if ticketsMinted < maxTickets && eventTotalTicketsMinted < eventMaxTickets{ 
				// deposit it in the recipient's account using their reference
				recipient.deposit(token: <-create VeraTicket.NFT(initID: VeraTicket.totalSupply, initEventID: eventID, initType: type, initTier: tier, initSubTier: subtier, initTokenURI: tokenURI))
				emit Minted(id: VeraTicket.totalSupply)
				VeraTicket.totalSupply = VeraTicket.totalSupply + 1 as UInt64
			} else{ 
				panic("Max Tickets Minted")
			}
		}
		
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun mintMultipleNFT(recipient: &{NonFungibleToken.CollectionPublic, VeraTicket.TicketsCollectionPublic}, eventID: UInt64, tickets: [VeraTicket.NFTStruct], gatickets: UInt64, astickets: UInt64){ 
			let eventCollection = VeraTicket.account.storage.borrow<&VeraEvent.EventCollection>(from: VeraEvent.VeraEventStorage)!
			let veraevent: VeraEvent.EventStruct = VeraEvent.getEvent(id: eventID)
			var eventMaxTickets: UInt64 = veraevent.maxTickets
			var eventTotalTicketsMinted: UInt64 = veraevent.totalTicketsMinted + gatickets + astickets
			var maxTickets: UInt64 = 0
			var ticketsMinted: UInt64 = 0
			if tickets.length > 100{ 
				panic("Cannot Mint Tickets more than 100 in one batch")
			}
			if eventTotalTicketsMinted > eventMaxTickets{ 
				panic("Cannot Mint Tickets more than Event Max Tickets")
			}
			var gaMaxTicket: UInt64 = 0
			var asMaxTicket: UInt64 = 0
			var gaTicketsMinted: UInt64 = 0
			var asTicketsMinted: UInt64 = 0
			for nft in tickets{ 
				var eventtier: VeraEvent.Tier = veraevent.getTier(tier: nft.tier)!
				maxTickets = eventtier.maxTickets
				if nft.type == VeraTicket.NFTType.GeneralAdmission{ 
					gaTicketsMinted = gaTicketsMinted + eventtier.ticketsMinted
					gaMaxTicket = gaMaxTicket + maxTickets
				} else if nft.type == VeraTicket.NFTType.AssignedSeating{ 
					asTicketsMinted = asTicketsMinted + eventtier.ticketsMinted
					asMaxTicket = asMaxTicket + maxTickets
				}
			}
			gaTicketsMinted = gaTicketsMinted + gatickets
			asTicketsMinted = asTicketsMinted + astickets
			if gaTicketsMinted > gaMaxTicket || asTicketsMinted > asMaxTicket{ 
				panic("Max Tickets Minted")
			}
			for nft in tickets{ 
				// deposit it in the recipient's account using their reference
				recipient.deposit(token: <-create VeraTicket.NFT(initID: VeraTicket.totalSupply, initEventID: eventID, initType: nft.type, initTier: nft.tier, initSubTier: nft.subtier, initTokenURI: nft.tokenURI))
				emit Minted(id: VeraTicket.totalSupply)
				eventCollection.incrementTicketMinted(eventId: eventID, tier: nft.tier, subtier: nft.subtier)
				VeraTicket.totalSupply = VeraTicket.totalSupply + 1 as UInt64
			}
		}
		
		access(all)
		fun mintMultipleNFTV2(recipient: &{NonFungibleToken.CollectionPublic, VeraTicket.TicketsCollectionPublic}, eventID: UInt64, tickets: [VeraTicket.NFTStruct], gatickets: UInt64, astickets: UInt64){ 
			if tickets.length > 100{ 
				panic("Cannot Mint Tickets more than 100 in one batch")
			}
			for nft in tickets{ 
				// deposit it in the recipient's account using their reference
				recipient.deposit(token: <-create VeraTicket.NFT(initID: VeraTicket.totalSupply, initEventID: eventID, initType: nft.type, initTier: nft.tier, initSubTier: nft.subtier, initTokenURI: nft.tokenURI))
				emit Minted(id: VeraTicket.totalSupply)
				///  eventCollection.incrementTicketMinted(eventId: eventID, tier: nft.tier, subtier: nft.subtier)
				VeraTicket.totalSupply = VeraTicket.totalSupply + 1 as UInt64
			}
		}
	}
	
	// fetch
	// Get a reference to a Ticket from an account's Collection, if available.
	// If an account does not have a Tickets.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &VeraTicket.NFT?{ 
		let collection = getAccount(from).capabilities.get<&VeraTicket.Collection>(VeraTicket.VeraTicketPubStorage).borrow<&VeraTicket.Collection>() ?? panic("Couldn't get collection")
		// We trust Tickets.Collection.borowTicket to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowTicket(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.VeraTicketStorage = /storage/veraTicketCollection
		self.VeraTicketPubStorage = /public/veraTicketCollection
		self.VeraMinterStorage = /storage/veraTicketMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.VeraMinterStorage)
		emit ContractInitialized()
	}
}
