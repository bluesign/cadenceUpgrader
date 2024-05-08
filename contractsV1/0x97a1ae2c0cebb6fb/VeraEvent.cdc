// VeraEvent
// Events Contract!
//
access(all)
contract VeraEvent{ 
	
	// Event
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event EventCreated(eventId: UInt64)
	
	access(all)
	event EventUpdated(eventId: UInt64)
	
	// Named Paths
	//
	access(all)
	let VeraEventStorage: StoragePath
	
	access(all)
	let VeraEventPubStorage: PublicPath
	
	access(all)
	let VeraAdminStorage: StoragePath
	
	// totalEvents
	// The total number of Events that have been created
	//
	access(all)
	var totalEvents: UInt64
	
	// Declare an enum named `Color` which has the raw value type `UInt8`,
	// and declare three enum cases: `red`, `green`, and `blue`
	//
	access(all)
	enum EventType: UInt8{ 
		access(all)
		case Public
		
		access(all)
		case Private
	}
	
	// Declare an enum named `Color` which has the raw value type `UInt8`,
	// and declare three enum cases: `red`, `green`, and `blue`
	//
	access(all)
	enum TierType: UInt8{ 
		access(all)
		case GeneralAdmission
		
		access(all)
		case AssignedSeating
	}
	
	// Declare an enum named `Color` which has the raw value type `UInt8`,
	// and declare three enum cases: `red`, `green`, and `blue`
	//
	access(all)
	enum RoyaltyType: UInt8{ 
		access(all)
		case Fixed
		
		access(all)
		case Percent
	}
	
	// Royalty Struct
	// type can be Fixed or Percent
	access(all)
	struct Royalty{ 
		access(all)
		let id: UInt64
		
		access(all)
		var type: RoyaltyType
		
		access(all)
		var value: UInt64
		
		init(id: UInt64, type: RoyaltyType, value: UInt64){ 
			self.id = id
			self.type = type
			self.value = value
		}
	}
	
	// AccountRoyalty Struct
	// type can be Fixed or Percent
	access(all)
	struct AccountRoyalty{ 
		access(all)
		let id: UInt64
		
		access(all)
		var account: Address
		
		access(all)
		var royaltyValue: UFix64
		
		init(id: UInt64, account: Address, royaltyValue: UFix64){ 
			self.id = id
			self.account = account
			self.royaltyValue = royaltyValue
		}
	}
	
	access(all)
	struct SubTier{ 
		access(all)
		let id: UInt64
		
		access(all)
		var name: String
		
		access(all)
		var cost: UFix64
		
		access(all)
		let maxTickets: UInt64
		
		access(all)
		var ticketsMinted: UInt64
		
		init(id: UInt64, name: String, cost: UFix64, maxTickets: UInt64){ 
			self.id = id
			self.name = name
			self.cost = cost
			self.maxTickets = maxTickets
			self.ticketsMinted = 0
		}
		
		access(all)
		fun incrementTicketMinted(){ 
			self.ticketsMinted = self.ticketsMinted + 1
		}
		
		access(all)
		fun decrementTicketMinted(){ 
			self.ticketsMinted = self.ticketsMinted - 1
		}
	}
	
	access(all)
	struct Tier{ 
		access(all)
		let id: UInt64
		
		access(all)
		let type: VeraEvent.TierType
		
		access(all)
		var name: String
		
		access(all)
		var cost: UFix64
		
		access(all)
		let maxTickets: UInt64
		
		access(all)
		var ticketsMinted: UInt64
		
		access(all)
		var subtier:{ UInt64: VeraEvent.SubTier}
		
		init(
			id: UInt64,
			type: VeraEvent.TierType,
			name: String,
			cost: UFix64,
			maxTickets: UInt64,
			subtier:{ 
				UInt64: VeraEvent.SubTier
			}
		){ 
			self.id = id
			self.type = type
			self.name = name
			self.cost = cost
			self.maxTickets = maxTickets
			self.ticketsMinted = 0
			self.subtier = subtier
		}
		
		access(all)
		fun incrementTicketMinted(){ 
			self.ticketsMinted = self.ticketsMinted + 1
		}
		
		access(all)
		fun decrementTicketMinted(){ 
			self.ticketsMinted = self.ticketsMinted - 1
		}
	}
	
	access(all)
	struct EventStruct{ 
		access(all)
		let id: UInt64
		
		access(all)
		var type: VeraEvent.EventType
		
		access(all)
		var tier:{ UInt64: VeraEvent.Tier}
		
		access(all)
		var maxTickets: UInt64
		
		access(all)
		var buyLimit: UInt64
		
		access(all)
		var defaultRoyaltyPercent: UFix64
		
		access(all)
		var defaultRoyaltyAddress: Address
		
		access(all)
		var totalTicketsMinted: UInt64
		
		access(all)
		var eventURI: String
		
		access(all)
		var royalty: Royalty
		
		access(all)
		var royalties:{ UInt64: VeraEvent.AccountRoyalty}
		
		init(
			id: UInt64,
			type: VeraEvent.EventType,
			tier:{ 
				UInt64: VeraEvent.Tier
			},
			maxTickets: UInt64,
			buyLimit: UInt64,
			defaultRoyaltyAddress: Address,
			defaultRoyaltyPercent: UFix64,
			royalty: Royalty,
			royalties:{ 
				UInt64: VeraEvent.AccountRoyalty
			},
			eventURI: String
		){ 
			self.id = id
			self.type = type
			self.tier = tier
			self.maxTickets = maxTickets
			self.buyLimit = buyLimit
			self.defaultRoyaltyAddress = defaultRoyaltyAddress
			self.defaultRoyaltyPercent = defaultRoyaltyPercent
			self.royalty = royalty
			self.royalties = royalties
			self.eventURI = eventURI
			self.totalTicketsMinted = 0
		}
		
		access(all)
		fun incrementTicketMinted(tier: UInt64, subtier: UInt64){ 
			self.totalTicketsMinted = self.totalTicketsMinted + 1
		}
		
		access(all)
		fun decrementTicketMinted(tier: UInt64, subtier: UInt64){ 
			self.totalTicketsMinted = self.totalTicketsMinted - 1
		}
		
		access(all)
		fun getTier(tier: UInt64): VeraEvent.Tier{ 
			let tier = self.tier[tier] ?? panic("missing Tier")
			return tier
		}
		
		access(all)
		fun getSubTier(tier: UInt64, subtier: UInt64): VeraEvent.SubTier{ 
			let tier = self.tier[tier] ?? panic("missing Tier")
			let subtier = tier.subtier[subtier] ?? panic("missing Sub Tier")
			return subtier
		}
	}
	
	access(all)
	resource EventCollection{ 
		access(all)
		var eventsCollection:{ UInt64: VeraEvent.EventStruct}
		
		access(all)
		var metadataObjs:{ UInt64:{ String: String}}
		
		access(all)
		fun addEvent(veraevent: VeraEvent.EventStruct, metadata:{ String: String}){ 
			let eventId = veraevent.id
			self.eventsCollection[eventId] = veraevent
			self.metadataObjs[eventId] = metadata
			emit EventCreated(eventId: eventId)
		}
		
		access(all)
		fun updateEvent(veraevent: VeraEvent.EventStruct, metadata:{ String: String}){ 
			let eventId = veraevent.id
			self.eventsCollection[eventId] = veraevent
			self.metadataObjs[eventId] = metadata
			emit EventUpdated(eventId: eventId)
		}
		
		access(all)
		fun getEvent(eventId: UInt64): VeraEvent.EventStruct{ 
			let veraevent = self.eventsCollection[eventId] ?? panic("missing Event")
			return veraevent
		}
		
		access(all)
		fun getMetadata(eventId: UInt64):{ String: String}{ 
			let metadata = self.metadataObjs[eventId] ?? panic("missing Metadata")
			return metadata
		}
		
		access(all)
		fun incrementTicketMinted(eventId: UInt64, tier: UInt64, subtier: UInt64){ 
			let veraevent = self.eventsCollection[eventId] ?? panic("missing Event")
			(self.eventsCollection[eventId]!).incrementTicketMinted(tier: tier, subtier: subtier)
			if let eventTier: VeraEvent.Tier = (self.eventsCollection[eventId]!).tier[tier]{ 
				((self.eventsCollection[eventId]!).tier[tier]!).incrementTicketMinted()
			}
			if let eventSubtier: VeraEvent.SubTier =
				((self.eventsCollection[eventId]!).tier[tier]!).subtier[subtier]{ 
				(((self.eventsCollection[eventId]!).tier[tier]!).subtier[subtier]!)
					.incrementTicketMinted()
			}
		}
		
		access(all)
		fun decrementTicketMinted(eventId: UInt64, tier: UInt64, subtier: UInt64){ 
			let veraevent = self.eventsCollection[eventId] ?? panic("missing Event")
			(self.eventsCollection[eventId]!).decrementTicketMinted(tier: tier, subtier: subtier)
			if let eventTier: VeraEvent.Tier = (self.eventsCollection[eventId]!).tier[tier]{ 
				((self.eventsCollection[eventId]!).tier[tier]!).decrementTicketMinted()
			}
			if let eventSubtier: VeraEvent.SubTier =
				((self.eventsCollection[eventId]!).tier[tier]!).subtier[subtier]{ 
				(((self.eventsCollection[eventId]!).tier[tier]!).subtier[subtier]!)
					.decrementTicketMinted()
			}
		}
		
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.eventsCollection.keys
		}
		
		// initializer
		//
		init(){ 
			self.eventsCollection ={} 
			self.metadataObjs ={} 
		}
	}
	
	access(self)
	fun createEmptyCollection(): @VeraEvent.EventCollection{ 
		return <-create EventCollection()
	}
	
	access(all)
	resource EventAdmin{ 
		
		// createEvent
		// Create an Event
		//
		access(all)
		fun createEvent(
			type: VeraEvent.EventType,
			tier:{ 
				UInt64: VeraEvent.Tier
			},
			maxTickets: UInt64,
			buyLimit: UInt64,
			defaultRoyaltyAddress: Address,
			defaultRoyaltyPercent: UFix64,
			royalty: Royalty,
			royalties:{ 
				UInt64: VeraEvent.AccountRoyalty
			},
			eventURI: String,
			metadata:{ 
				String: String
			}
		){ 
			// deposit it in the recipient's account using their reference
			let veraevent =
				VeraEvent.EventStruct(
					id: VeraEvent.totalEvents,
					type: type,
					tier: tier,
					maxTickets: maxTickets,
					buyLimit: buyLimit,
					defaultRoyaltyAddress: defaultRoyaltyAddress,
					defaultRoyaltyPercent: defaultRoyaltyPercent,
					royalty: royalty,
					royalties: royalties,
					eventURI: eventURI
				)
			let collection =
				VeraEvent.account.storage.borrow<&VeraEvent.EventCollection>(
					from: VeraEvent.VeraEventStorage
				)!
			collection.addEvent(veraevent: veraevent, metadata: metadata)
			VeraEvent.totalEvents = VeraEvent.totalEvents + 1 as UInt64
		}
		
		// updateEvent
		// Update an Event
		//
		access(all)
		fun updateEvent(
			id: UInt64,
			type: VeraEvent.EventType,
			tier:{ 
				UInt64: VeraEvent.Tier
			},
			maxTickets: UInt64,
			buyLimit: UInt64,
			defaultRoyaltyAddress: Address,
			defaultRoyaltyPercent: UFix64,
			royalty: Royalty,
			royalties:{ 
				UInt64: VeraEvent.AccountRoyalty
			},
			eventURI: String,
			metadata:{ 
				String: String
			}
		){ 
			// deposit it in the recipient's account using their reference
			let veraevent =
				VeraEvent.EventStruct(
					id: id,
					type: type,
					tier: tier,
					maxTickets: maxTickets,
					buyLimit: buyLimit,
					defaultRoyaltyAddress: defaultRoyaltyAddress,
					defaultRoyaltyPercent: defaultRoyaltyPercent,
					royalty: royalty,
					royalties: royalties,
					eventURI: eventURI
				)
			let collection =
				VeraEvent.account.storage.borrow<&VeraEvent.EventCollection>(
					from: VeraEvent.VeraEventStorage
				)!
			collection.updateEvent(veraevent: veraevent, metadata: metadata)
		}
	}
	
	// mintNFT
	// Mints a new NFT with a new ID
	// and deposit it in the recipients collection using their collection reference
	//
	access(all)
	fun getEvent(id: UInt64): VeraEvent.EventStruct{ 
		let collection =
			VeraEvent.account.storage.borrow<&VeraEvent.EventCollection>(
				from: VeraEvent.VeraEventStorage
			)!
		return collection.getEvent(eventId: id)
	}
	
	access(all)
	fun getMetadata(id: UInt64):{ String: String}{ 
		let collection =
			VeraEvent.account.storage.borrow<&VeraEvent.EventCollection>(
				from: VeraEvent.VeraEventStorage
			)!
		return collection.getMetadata(eventId: id)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.VeraEventStorage = /storage/veraeventCollection
		self.VeraEventPubStorage = /public/veraeventCollection
		self.VeraAdminStorage = /storage/veraEventdmin
		
		// Initialize the total events
		self.totalEvents = 0
		
		// Create a Minter resource and save it to storage
		let eventAdmin <- create EventAdmin()
		self.account.storage.save(<-eventAdmin, to: self.VeraAdminStorage)
		
		// Create a Collection resource and save it to storage
		let eventCollection <- self.createEmptyCollection()
		self.account.storage.save(<-eventCollection, to: self.VeraEventStorage)
		emit ContractInitialized()
	}
}
