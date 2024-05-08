/*
	Description: Central Smart Contract for LCube Tickets

	This smart contract contains the core functionality for 
	LCube Tickets, created by LCube

	The contract manages the data associated with all the ticket types and events
	that are used as templates for the Tickets NFTs

	When a new ticket type wants to be added to the records, an Admin creates
	a new ticket type struct that is stored in the smart contract.

	Then an Admin can create new Events. Event consist of a public struct that 
	contains public information about a event, and a private resource used
	to mint new tickets based off of ticket types that have been linked to the Event.

	The admin resource has the power to do all of the important actions
	in the smart contract. When admins want to call functions in a event,
	they call their borrowEvent function to get a reference 
	to a event in the contract. Then, they can call functions on the event using that reference.

	In this way, the smart contract and its defined resources interact 
	with great teamwork.
	
	When tickets are minted, they are initialized with a TicketData struct and
	are returned by the minter.

	The contract also defines a Collection resource. This is an object that 
	every LCubeTicket owner will store in their account
	to manage their NFT collection.

	The main LCubeTicket account will also have its own Ticket collections
	it can use to hold its own tickets that have not yet been sent to a user.

	Note: All state changing functions will panic if an invalid argument is
	provided or one of its pre-conditions or post conditions aren't met.
	Functions that don't modify state will simply return 0 or nil 
	and those cases need to be handled by the caller.

*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract LCubeTickets: NonFungibleToken{ 
	// -----------------------------------------------------------------------
	// LCube tickets contract Events
	// -----------------------------------------------------------------------
	// Emitted when the LCube tickets contract is created
	access(all)
	event ContractInitialized()
	
	// Emitted when a new Event struct is created
	access(all)
	event EventCreated(eventID: UInt32)
	
	// Emitted when a new TicketType struct is created
	access(all)
	event TicketTypeCreated(eventID: UInt32, ticketTypeID: UInt32, name: String)
	
	// Emitted when a new TicketType is added to an Event
	access(all)
	event TicketTypeAddedToEvent(eventID: UInt32, ticketTypeID: UInt32)
	
	// Emitted when a TicketType is retired from a Event and cannot be used to mint
	access(all)
	event TicketTypeRetiredFromEvent(eventID: UInt32, ticketTypeID: UInt32, numTickets: UInt32)
	
	// Emitted when a Event is locked, meaning TicketTypes cannot be added
	access(all)
	event EventLocked(eventID: UInt32)
	
	// Emitted when an Event is closed, meaning Tickets cannot be minted
	access(all)
	event EventClosed(eventID: UInt32)
	
	// Emitted when a TicketType is sold, meaning Tickets cannot be minted
	access(all)
	event TicketTypeSold(eventID: UInt32, ticketTypeID: UInt32)
	
	// Emitted when a Ticket is minted from an TicketType
	access(all)
	event TicketMinted(ticketID: UInt64, eventID: UInt32, ticketTypeID: UInt32, serialNumber: UInt32)
	
	// Events for Collection-related actions
	//
	// Emitted when a Ticket is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when a Ticket is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Emitted when a Ticket is transferred from a Collection
	access(all)
	event Transfer(id: UInt64, from: Address?, to: Address?)
	
	// Emitted when a Ticket is destroyed
	access(all)
	event TicketDestroyed(id: UInt64)
	
	// Variable size dictionary of TicketType structs
	access(self)
	var ticketTypeDatas:{ UInt32: TicketType}
	
	// Variable size dictionary of Event structs
	access(self)
	var eventDatas:{ UInt32: EventData}
	
	// Variable size dictionary of TicketType resources
	access(self)
	var events: @{UInt32: Event}
	
	// The ID that is used to create Events. 
	// Every time a Event is created, eventID is assigned 
	// to the new Event's ID and then is incremented by 1.
	access(all)
	var totalEvents: UInt32
	
	// The ID that is used to create TicketTypes. Every time a TicketTypes is created
	// ticketTypeID is assigned to the new ticketType's ID and then is incremented by 1.
	access(all)
	var totalTicketTypes: UInt32
	
	// The total number of Tickets NFTs that have been created
	// Because NFTs can be destroyed, it doesn't necessarily mean that this
	// reflects the total number of NFTs in existence, just the number that
	// have been minted to date. Also used as global ticket IDs for minting.
	access(all)
	var totalSupply: UInt64
	
	// -----------------------------------------------------------------------
	// LCube contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// -----------------------------------------------------------------------
	// Event is a Struct that holds metadata associated 
	// with specific information : like name, venue, event_type,
	// Ray Allen hit the 3 to tie the Heat and Spurs in the 2013 finals game 6
	// or when Lance Stephenson blew in the ear of Lebron James.
	//
	// Tickets NFTs will all reference a single Event and a single TicketType.
	// The Tickets are publicly accessible, so anyone can
	// read the metadata associated with a specific Ticket ID
	//
	access(all)
	struct EventData{ 
		// The unique ID for the Event
		access(all)
		let eventID: UInt32
		
		access(all)
		let name: String
		
		access(all)
		let startTime: String?
		
		access(all)
		let venue: String?
		
		access(all)
		let eventType: String?
		
		access(all)
		let timeZone: Int?
		
		access(all)
		let gateTime: String?
		
		access(all)
		let image: String?
		
		access(all)
		let description: String?
		
		init(eventID: UInt32, name: String, startTime: String?, venue: String?, eventType: String?, timeZone: Int?, gateTime: String?, image: String?, description: String?){ 
			pre{ 
				eventID != 0:
					"Event ID cannot be 0"
			}
			self.eventID = eventID
			self.name = name
			self.venue = venue
			self.startTime = startTime
			self.eventType = eventType
			self.timeZone = timeZone
			self.gateTime = gateTime
			self.image = image
			self.description = description
		}
	}
	
	// A TicketType contains details for Ticket Categories
	// that make up a related group of collectibles.
	// TicketTypeData is a struct that is stored in a field of the contract.
	// Anyone can query the constant information
	// about a set by calling various getters located 
	// at the end of the contract. Only the admin has the ability 
	// to modify any data in the private Set resource.
	//
	access(all)
	struct TicketType{ 
		// Unique ID for the TicketType
		access(all)
		let ticketTypeID: UInt32
		
		// EventID to which the ticket belongs
		access(all)
		let eventID: UInt32
		
		// Name of the TicketType
		// ex. VIP, GA, etc.
		access(all)
		let name: String
		
		// Initial price of the ticket type in primary market
		access(all)
		let initialPrice: UFix64
		
		// Maximum number of tickets that can exist with this ticket type
		access(all)
		let totalAmount: UInt32
		
		// Image for this TicketType
		access(all)
		let image: String?
		
		// Description of the ticket type
		access(all)
		let description: String?
		
		init(ticketTypeID: UInt32, eventID: UInt32, name: String, initialPrice: UFix64, totalAmount: UInt32, image: String?, description: String?){ 
			pre{ 
				ticketTypeID != 0:
					"TicketTypeID cannot be 0"
				eventID != 0:
					"EventID cannot be 0"
			}
			self.ticketTypeID = ticketTypeID
			self.eventID = eventID
			self.name = name
			self.initialPrice = initialPrice
			self.totalAmount = totalAmount
			self.image = image
			self.description = description
		}
	}
	
	// Event is a resource type that contains the functions to add and remove
	// TicketTypes from an event and mint Tickets.
	//
	// It is stored in a private field in the contract so that
	// the admin resource can call its methods.
	//
	// The admin can add TicketTypes to a Event so that the event can mint Tickets
	// that reference that ticket type data.
	// The Tickets that are minted by a Event will be listed as belonging to
	// the Event that minted it, as well as the TicketType it references.
	// 
	// Admin can also retire TicketTypes from the Events, meaning that the retired
	// TicketType can no longer have Tickets minted from it.
	//
	// If the admin locks the Event, no more Plays can be added to it, but 
	// Tickets can still be minted.
	//
	// If an Event is closed, no more tickets can be minted.
	//
	// If retireAll() and lock() are called back-to-back, 
	// the Set is closed off forever and nothing more can be done with it.
	access(all)
	resource Event{ 
		// Unique ID for the Event
		access(all)
		let eventID: UInt32
		
		// Array of TicketTypes that are a part of this Event.
		// When a TicketType is added to the Event, its ID gets appended here.
		// The ID does not get removed from this array when a TicketType is retired.
		access(contract)
		var ticketTypes: [UInt32]
		
		// Map of TicketType IDs that Indicates if a TicketType in this Event can be minted.
		// When a TicketType is added to a Event, it is mapped to false (not retired).
		// When a TicketType is retired, this is set to true and cannot be changed.
		access(contract)
		var retired:{ UInt32: Bool}
		
		// Indicates if the Event is currently locked.
		// When a Event is created, it is unlocked 
		// and TicketTypes are allowed to be added to it.
		// When a event is locked, TicketTypes cannot be added.
		// A Event can never be changed from locked to unlocked,
		// the decision to lock a Event it is final.
		// If a Event is locked, TicketTypes cannot be added, but
		// Tickets can still be minted from TicketTypes
		// that exist in the Event.
		access(all)
		var locked: Bool
		
		// Mapping of TicketTypes IDs that indicates the number of Tickets 
		// that have been minted for specific TicketTypes in this Event.
		// When a Ticket is minted, this value is stored in the Ticket to
		// show its place in the Event, eg. 13 of 60.
		access(contract)
		var numberMintedPerTicketType:{ UInt32: UInt32}
		
		init(eventID: UInt32, name: String, startTime: String?, venue: String?, eventType: String?, timeZone: Int?, gateTime: String?, image: String?, description: String?){ 
			self.eventID = eventID
			self.ticketTypes = []
			self.retired ={} 
			self.locked = false
			self.numberMintedPerTicketType ={} 
			// Create a new EventData for this Event and store it in contract storage
			LCubeTickets.eventDatas[self.eventID] = EventData(eventID: eventID, name: name, startTime: startTime, venue: venue, eventType: eventType, timeZone: timeZone, gateTime: gateTime, image: image, description: description)
		}
		
		// addTicketType adds a ticketType to the event
		//
		// Parameters: ticketTypeID: The ID of the ticketType that is being added
		//
		// Pre-Conditions:
		// The TicketType needs to be an existing TicketType
		// The Event needs to be not locked
		// The TicketType can't have already been added to the Event
		//
		access(all)
		fun addTicketType(ticketTypeID: UInt32){ 
			pre{ 
				LCubeTickets.ticketTypeDatas[ticketTypeID] != nil:
					"Cannot add the TicketType to Event: TicketType doesn't exist."
				!self.locked:
					"Cannot add the ticketType to the Event after the set has been locked."
				self.numberMintedPerTicketType[ticketTypeID] == nil:
					"The TicketType has already beed added to the event."
			}
			// Add the TicketType to the array of TicketTypes
			self.ticketTypes.append(ticketTypeID)
			// Open the TicketType up for minting
			self.retired[ticketTypeID] = false
			// Initialize the Tickets count to zero
			self.numberMintedPerTicketType[ticketTypeID] = 0
			emit TicketTypeAddedToEvent(eventID: self.eventID, ticketTypeID: ticketTypeID)
		}
		
		// addTicketTypes adds multiple TicketTypes to the Event
		//
		// Parameters: ticketTypesIDs: The IDs of the TicketTypes that are being added
		//					  as an array
		//
		access(all)
		fun addTicketTypes(ticketTypeIDs: [UInt32]){ 
			for ticketType in ticketTypeIDs{ 
				self.addTicketType(ticketTypeID: ticketType)
			}
		}
		
		// retireTicketType retires a TicketType from the Evebt so that it can't mint new Tickets
		//
		// Parameters: ticketTypeID: The ID of the TicketType that is being retired
		//
		// Pre-Conditions:
		// The TicketType is part of the Event and not retired (available for minting).
		// 
		access(all)
		fun retireTicketType(ticketTypeID: UInt32){ 
			pre{ 
				self.retired[ticketTypeID] != nil:
					"Cannot retire the TicketType: TicketType doesn't exist in this event!"
			}
			if !self.retired[ticketTypeID]!{ 
				self.retired[ticketTypeID] = true
				emit TicketTypeRetiredFromEvent(eventID: self.eventID, ticketTypeID: ticketTypeID, numTickets: self.numberMintedPerTicketType[ticketTypeID]!)
			}
		}
		
		// retireAll retires all the ticketTypes in the Event
		// Afterwards, none of the retired TicketTypes will be able to mint new Tickets
		//
		access(all)
		fun retireAll(){ 
			for ticketType in self.ticketTypes{ 
				self.retireTicketType(ticketTypeID: ticketType)
			}
		}
		
		// mintTicket mints a new Ticket and returns the newly minted Ticket
		// 
		// Parameters: ticketTypeID: The ID of the TicketType that the Ticket references
		//
		// Pre-Conditions:
		// The TicketType must exist in the Event and be allowed to mint new Tickets
		//
		// Returns: The NFT that was minted
		// 
		access(all)
		fun mintTicket(ticketTypeID: UInt32, metadata: String?): @NFT{ 
			pre{ 
				self.retired[ticketTypeID] != nil:
					"Cannot mint the ticket: This TicketType doesn't exist."
				!self.retired[ticketTypeID]!:
					"Cannot mint the ticket from this ticketType: This ticketType has been retired."
			}
			// Gets the number of Tickets that have been minted for this TicketType
			// to use as this Ticket's serial number
			let numInTicketType = self.numberMintedPerTicketType[ticketTypeID]!
			// Mint the new ticket
			let newTicket: @NFT <- create NFT(serialNumber: numInTicketType + 1, ticketTypeID: ticketTypeID, eventID: self.eventID, metadata: metadata)
			// Increment the count of Tickets minted for this TicketType
			self.numberMintedPerTicketType[ticketTypeID] = numInTicketType + 1
			return <-newTicket
		}
		
		// batchMintTicket mints an arbitrary quantity of Tickets 
		// and returns them as a Collection
		//
		// Parameters: ticketTypeID: the ID of the ticketType that the Tickets are minted for
		//			 quantity: The quantity of Tickets to be minted
		//
		// Returns: Collection object that contains all the Tickets that were minted
		//
		access(all)
		fun batchMintTicket(ticketTypeID: UInt32, metadatas: [String?], quantity: UInt64): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintTicket(ticketTypeID: ticketTypeID, metadata: metadatas[i]))
				i = i + 1
			}
			return <-newCollection
		}
		
		access(all)
		fun getTicketTypes(): [UInt32]{ 
			return self.ticketTypes
		}
		
		access(all)
		fun getRetired():{ UInt32: Bool}{ 
			return self.retired
		}
		
		access(all)
		fun getNumMintedPerTicketType():{ UInt32: UInt32}{ 
			return self.numberMintedPerTicketType
		}
	}
	
	// Struct that contains all of the important data about a event
	// Can be easily queried by instantiating the `QueryEventData` object
	// with the desired event ID
	// let eventData = LCubeTickets.QueryEventData(eventID: 12)
	//
	access(all)
	struct QueryEventData{ 
		access(all)
		let eventID: UInt32
		
		access(all)
		let name: String
		
		access(self)
		var ticketTypes: [UInt32]
		
		access(self)
		var retired:{ UInt32: Bool}
		
		access(all)
		var locked: Bool
		
		access(self)
		var numberMintedPerTicketType:{ UInt32: UInt32}
		
		init(eventID: UInt32){ 
			pre{ 
				LCubeTickets.events[eventID] != nil:
					"The event with the provided ID does not exist"
			}
			let _event = (&LCubeTickets.events[eventID] as &Event?)!
			let eventData = LCubeTickets.eventDatas[eventID]!
			self.eventID = eventID
			self.name = eventData.name
			self.ticketTypes = *_event.ticketTypes
			self.retired = *_event.retired
			self.locked = _event.locked
			self.numberMintedPerTicketType = *_event.numberMintedPerTicketType
		}
		
		access(all)
		fun getTicketTypes(): [UInt32]{ 
			return self.ticketTypes
		}
		
		access(all)
		fun getRetired():{ UInt32: Bool}{ 
			return self.retired
		}
		
		access(all)
		fun getNumberMintedPerTicketType():{ UInt32: UInt32}{ 
			return self.numberMintedPerTicketType
		}
	}
	
	access(all)
	struct TicketData{ 
		// The ID of the Event that the Ticket comes from
		access(all)
		let eventID: UInt32
		
		// The ID of the TicketType that the Ticket references
		access(all)
		let ticketTypeID: UInt32
		
		// The place in the edition that this Ticket was minted
		// Otherwise know as the serial number
		access(all)
		let serialNumber: UInt32
		
		// Metadata regarding the ticket itself
		// e.g : seat, row, etc.
		access(all)
		let metadata: String?
		
		init(eventID: UInt32, ticketTypeID: UInt32, serialNumber: UInt32, metadata: String?){ 
			self.eventID = eventID
			self.ticketTypeID = ticketTypeID
			self.serialNumber = serialNumber
			self.metadata = metadata
		}
	}
	
	// This is an implementation of a custom metadata view for LCube Ticket.
	// This view contains the ticket metadata.
	//
	access(all)
	struct LCubeTicketMetadataView{ 
		access(all)
		let eventName: String?
		
		access(all)
		let ticketTypeName: String?
		
		access(all)
		let venue: String?
		
		access(all)
		let startDate: String?
		
		access(all)
		let serialNumber: UInt32
		
		access(all)
		let ticketTypeID: UInt32
		
		access(all)
		let eventID: UInt32
		
		access(all)
		let numTicketsInTicketType: UInt32?
		
		init(eventName: String?, ticketTypeName: String?, venue: String?, startDate: String?, serialNumber: UInt32, ticketTypeID: UInt32, eventID: UInt32, numTicketsInTicketType: UInt32?){ 
			self.eventName = eventName
			self.ticketTypeName = ticketTypeName
			self.venue = venue
			self.startDate = startDate
			self.serialNumber = serialNumber
			self.ticketTypeID = ticketTypeID
			self.eventID = eventID
			self.numTicketsInTicketType = numTicketsInTicketType
		}
	}
	
	// The resource that represents the Ticket NFTs
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// Global unique ticket ID
		access(all)
		let id: UInt64
		
		// Struct of Ticket metadata
		access(all)
		let data: TicketData
		
		init(serialNumber: UInt32, ticketTypeID: UInt32, eventID: UInt32, metadata: String?){ 
			// Increment the global Ticket IDs
			LCubeTickets.totalSupply = LCubeTickets.totalSupply + 1
			self.id = LCubeTickets.totalSupply
			// Set the metadata struct
			self.data = TicketData(eventID: eventID, ticketTypeID: ticketTypeID, serialNumber: serialNumber, metadata: metadata)
			emit TicketMinted(ticketID: self.id, eventID: self.data.eventID, ticketTypeID: self.data.ticketTypeID, serialNumber: self.data.serialNumber)
		}
		
		// If the Ticket is destroyed, emit an event to indicate 
		// to outside ovbservers that it has been destroyed
		access(all)
		fun name(): String{ 
			let ticketTypeName: String = LCubeTickets.getTicketTypeName(ticketTypeID: self.data.ticketTypeID) ?? ""
			let eventName: String = LCubeTickets.getEventName(eventID: self.data.eventID) ?? ""
			return eventName.concat(" ").concat(ticketTypeName)
		}
		
		access(all)
		fun description(): String{ 
			let eventName: String = LCubeTickets.getEventName(eventID: self.data.eventID) ?? ""
			let ticketTypeName: String = LCubeTickets.getTicketTypeName(ticketTypeID: self.data.ticketTypeID) ?? ""
			let serialNumber: String = self.data.serialNumber.toString()
			return " A ticketType ".concat(ticketTypeName).concat("From event ").concat(eventName).concat(" ticket with serial number ").concat(serialNumber)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<LCubeTicketMetadataView>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name(), description: self.description(), thumbnail: MetadataViews.HTTPFile(url: "https://ipfs.dapperlabs.com/ipfs/Qmbdj1agtbzpPWZ81wCGaDiMKRFaRN3TU6cfztVCu6nh4o"))
				case Type<LCubeTicketMetadataView>():
					return LCubeTicketMetadataView(eventName: LCubeTickets.getEventName(eventID: self.data.eventID), ticketTypeName: LCubeTickets.getTicketTypeName(ticketTypeID: self.data.ticketTypeID), venue: LCubeTickets.getEventVenue(eventID: self.data.eventID), startDate: LCubeTickets.getEventStartDate(eventID: self.data.eventID), serialNumber: self.data.serialNumber, ticketTypeID: self.data.ticketTypeID, eventID: self.data.eventID, numTicketsInTicketType: LCubeTickets.getNumTicketsInTicketType(eventID: self.data.eventID, ticketTypeID: self.data.ticketTypeID))
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Admin is a special authorization resource that 
	// allows the owner to perform important functions to modify the 
	// various aspects of the TicketTypes, Events, and Tickets
	//
	access(all)
	resource Admin{ 
		// createTicketType creates a new TicketType struct 
		// and stores it in the TicketTypes dictionary in the LCubeTickets smart contract
		//
		// Parameters: ticketTypeID : The ticketTypeID
		//			 eventID : The eventID
		//			 name : name of the ticketType, examples {"Vip", "GA", "VIP ONLY MEMBERS"}
		//			 initialPrice : initial price of tickets for the primary market
		//			 image: an URL for an image of that ticket type
		//			 description: a description for the ticketType. example {"ticket type created by manu member of LCube for launch party event"}
		//
		// Returns: the ID of the new TicketType object
		//
		access(all)
		fun createTicketType(ticketTypeID: UInt32, eventID: UInt32, name: String, initialPrice: UFix64, totalAmount: UInt32, image: String?, description: String?): UInt32{ 
			// Create the new TicketType
			var newTicketType = TicketType(ticketTypeID: ticketTypeID, eventID: eventID, name: name, initialPrice: initialPrice, totalAmount: totalAmount, image: image, description: description)
			let newID = newTicketType.ticketTypeID
			// Increment the ID so that it isn't used again
			LCubeTickets.totalTicketTypes = LCubeTickets.totalTicketTypes + 1
			emit TicketTypeCreated(eventID: newTicketType.eventID, ticketTypeID: newTicketType.ticketTypeID, name: newTicketType.name)
			// Store it in the contract storage
			LCubeTickets.ticketTypeDatas[newID] = newTicketType
			return newID
		}
		
		// createEvent creates a new Event resource and stores it
		// in the event mapping in the LCubeTickets contract
		//
		// Parameters: name: The name of the Event
		//			 startTime : Start time of the event
		//			 venue : The venue where the event will take place.  example {"Madison Square Garden"}
		//			 eventType : The type of the event  example {Sports}
		//			 timeZone : timeZone of the event
		//			 gateTime : the time the gates will open
		//			 image : an image for the event (URL)
		//			 description : description of the event. example {NBA finals between Lakers and Golden States}
		//
		// Returns: The ID of the created event
		access(all)
		fun createEvent(name: String, startTime: String, venue: String, eventType: String, timeZone: Int, gateTime: String, image: String?, description: String?): UInt32{ 
			// Increment the eventID 
			LCubeTickets.totalEvents = LCubeTickets.totalEvents + 1
			// Create the new Event
			var newEvent <- create Event(eventID: LCubeTickets.totalEvents, name: name, startTime: startTime, venue: venue, eventType: eventType, timeZone: timeZone, gateTime: gateTime, image: image, description: description)
			let newID = newEvent.eventID
			emit EventCreated(eventID: newEvent.eventID)
			// Store it in the events mapping field
			LCubeTickets.events[newID] <-! newEvent
			return newID
		}
		
		// borrowEvent returns a reference to a event in the LCubeTickets
		// contract so that the admin can call methods on it
		//
		// Parameters: eventID: The ID of the Event that you want to
		// get a reference to
		//
		// Returns: A reference to the Event with all of the fields
		// and methods exposed
		//
		access(all)
		fun borrowEvent(eventID: UInt32): &Event{ 
			pre{ 
				LCubeTickets.events[eventID] != nil:
					"Cannot borrow Event: Event doesn't exist"
			}
			// Get a reference to the event and return it
			// use `&` to indicate the reference to the object and type
			return (&LCubeTickets.events[eventID] as &Event?)!
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	// This is the interface that users can cast their Ticket Collection as
	// to allow others to deposit Tickets into their Collection. It also allows for reading
	// the IDs of Tickets in the Collection.
	access(all)
	resource interface LCubeTicketsCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowTicket(id: UInt64): &LCubeTickets.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Ticket reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection is a resource that every user who owns NFTs 
	// will store in their account to manage their NFTS
	//
	access(all)
	resource Collection: LCubeTicketsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// Dictionary of Moment conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an Ticket from the Collection and moves it to the caller
		//
		// Parameters: withdrawID: The ID of the NFT 
		// that is to be removed from the Collection
		//
		// returns: @NonFungibleToken.NFT the token that was withdrawn
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// Borrow nft and check if locked
			let nft = self.borrowNFT(withdrawID)
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Ticket does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			// Return the withdrawn token
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: ids: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: A collection that contains
		//										the withdrawn moments
		//
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			// Create a new empty Collection
			var batchCollection <- create Collection()
			// Iterate through the ids and withdraw them from the Collection
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			// Return the withdrawn tokens
			return <-batchCollection
		}
		
		// deposit takes a Ticket and adds it to the Collections dictionary
		//
		// Paramters: token: the NFT to be deposited in the collection
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			// Cast the deposited token as a TopShot NFT to make sure
			// it is the correct type
			let token <- token as! @LCubeTickets.NFT
			// Get the token's ID
			let id = token.id
			// Add the new token to the dictionary
			let oldToken <- self.ownedNFTs[id] <- token
			// Only emit a deposit event if the Collection 
			// is in an account's storage
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			// Destroy the empty old token that was "removed"
			destroy oldToken
		}
		
		// batchDeposit takes a Collection object as an argument
		// and deposits each contained NFT into this Collection
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			// Get an array of the IDs to be deposited
			let keys = tokens.getIDs()
			// Iterate through the keys in the collection and deposit each one
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			// Destroy the empty Collection
			destroy tokens
		}
		
		// getIDs returns an array of the IDs that are in the Collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT Returns a borrowed reference to a Ticket in the Collection
		// so that the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		//
		// Note: This only allows the caller to read the ID of the NFT,
		// not any lCube ticket specific data. Please use borrowTicket to 
		// read Ticket data.
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowTicket returns a borrowed reference to a Ticket
		// so that the caller can read data and call methods from it.
		// They can use this to read its eventID, ticketTypeID, serialNumber,
		// or any of the eventData or ticketTypeData associated with it by
		// getting the eventID or ticketTypeID and reading those fields from
		// the smart contract.
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(all)
		fun borrowTicket(id: UInt64): &LCubeTickets.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &LCubeTickets.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let lCubeTicketNFT = nft as! &LCubeTickets.NFT
			return lCubeTicketNFT
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
	// If a transaction destroys the Collection object,
	// All the NFTs contained within are also destroyed!
	//
	}
	
	// -----------------------------------------------------------------------
	// LCubeTickets contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection creates a new, empty Collection object so that
	// a user can store it in their account storage.
	// Once they have a Collection in their storage, they are able to receive
	// Tickets in transactions.
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create LCubeTickets.Collection()
	}
	
	// getAllTicketTypes returns all the TicketTypes in lCube tickets
	//
	// Returns: An array of all the TicketTypes that have been created
	access(all)
	fun getAllTicketTypes(): [LCubeTickets.TicketType]{ 
		return LCubeTickets.ticketTypeDatas.values
	}
	
	access(all)
	fun getTicketTypeName(ticketTypeID: UInt32): String?{ 
		if let ticketType = LCubeTickets.ticketTypeDatas[ticketTypeID]{ 
			return ticketType.name
		} else{ 
			return nil
		}
	}
	
	access(all)
	fun getTicketTypeInitialPrice(ticketTypeID: UInt32): UFix64?{ 
		if let ticketType = LCubeTickets.ticketTypeDatas[ticketTypeID]{ 
			return ticketType.initialPrice
		} else{ 
			return nil
		}
	}
	
	access(all)
	fun getTicketTypeTotalAmount(ticketTypeID: UInt32): UInt32?{ 
		if let ticketType = LCubeTickets.ticketTypeDatas[ticketTypeID]{ 
			return ticketType.totalAmount
		} else{ 
			return nil
		}
	}
	
	access(all)
	fun getTicketTypeImage(ticketTypeID: UInt32): String?{ 
		if let ticketType = LCubeTickets.ticketTypeDatas[ticketTypeID]{ 
			return ticketType.image
		} else{ 
			return nil
		}
	}
	
	access(all)
	fun getTicketTypeDescription(ticketTypeID: UInt32): String?{ 
		if let ticketType = LCubeTickets.ticketTypeDatas[ticketTypeID]{ 
			return ticketType.description
		} else{ 
			return nil
		}
	}
	
	// getEventData returns the data that the specified Event
	//			is associated with.
	// 
	// Parameters: eventID: The id of the Event that is being searched
	//
	// Returns: The QueryEventData struct that has all the important information about the Event
	access(all)
	fun getEventData(eventID: UInt32): QueryEventData?{ 
		if LCubeTickets.events[eventID] == nil{ 
			return nil
		} else{ 
			return QueryEventData(eventID: eventID)
		}
	}
	
	// getEventName returns the name that the specified Event
	//			is associated with.
	// 
	// Parameters: eventID: The id of the Event that is being searched
	//
	// Returns: The name of the Event
	access(all)
	fun getEventName(eventID: UInt32): String?{ 
		// Don't force a revert if the eventID is invalid
		return LCubeTickets.eventDatas[eventID]?.name
	}
	
	// getEventVenue returns the venue that the specified Event
	//			is associated with.
	// 
	// Parameters: eventID: The id of the Event that is being searched
	//
	// Returns: The venue of the Event
	access(all)
	fun getEventVenue(eventID: UInt32): String?{ 
		// Don't force a revert if the eventID is invalid
		return LCubeTickets.eventDatas[eventID]?.venue
	}
	
	// getEventStartDate returns the StartDate that the specified Event
	//			is associated with.
	// 
	// Parameters: eventID: The id of the Event that is being searched
	//
	// Returns: The StartDate of the Event
	access(all)
	fun getEventStartDate(eventID: UInt32): String?{ 
		// Don't force a revert if the eventID is invalid
		return LCubeTickets.eventDatas[eventID]?.startTime
	}
	
	// getEventIDsByName returns the IDs that the specified Event name
	//				 is associated with.
	// 
	// Parameters: eventName: The name of the Event that is being searched
	//
	// Returns: An array of the IDs of the Event if it exists, or nil if doesn't
	access(all)
	fun getEventIDsByName(eventName: String): [UInt32]?{ 
		var eventIDs: [UInt32] = []
		// Iterate through all the eventDatas and search for the name
		for eventData in LCubeTickets.eventDatas.values{ 
			if eventName == eventData.name{ 
				// If the name is found, return the ID
				eventIDs.append(eventData.eventID)
			}
		}
		// If the name isn't found, return nil
		// Don't force a revert if the eventName is invalid
		if eventIDs.length == 0{ 
			return nil
		} else{ 
			return eventIDs
		}
	}
	
	// getTicketTypesInEvent returns the list of TicketTypeIDs that are in the Event
	// 
	// Parameters: eventID: The id of the Event that is being searched
	//
	// Returns: An array of TicketTypeIDs
	access(all)
	fun getTicketTypesInEvent(eventID: UInt32): [UInt32]?{ 
		// Don't force a revert if the eventID is invalid
		return LCubeTickets.events[eventID]?.ticketTypes
	}
	
	// getNumTicketsInTicketType return the number of Ticket that have been 
	//						minted from a certain TicketType on an event.
	//
	// Parameters: eventID: The id of the Event that is being searched
	//			 ticketTypeID: The id of the ticketType that is being searched
	//
	// Returns: The total number of Tickets 
	//		  that have been minted from an from a certain TicketType on an event.
	access(all)
	fun getNumTicketsInTicketType(eventID: UInt32, ticketTypeID: UInt32): UInt32?{ 
		if let eventData = self.getEventData(eventID: eventID){ 
			// Read the numMintedPerTicketType
			let amount = eventData.getNumberMintedPerTicketType()[ticketTypeID]
			return amount
		} else{ 
			// If the set wasn't found return nil
			return nil
		}
	}
	
	// -----------------------------------------------------------------------
	// LCubeTickets initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		// Initialize contract fields
		self.ticketTypeDatas ={} 
		self.eventDatas ={} 
		self.events <-{} 
		self.totalEvents = 0
		self.totalTicketTypes = 0
		self.totalSupply = 0
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: /storage/LCubeTicketsCollection)
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{LCubeTicketsCollectionPublic}>(/storage/LCubeTicketsCollection)
		self.account.capabilities.publish(capability_1, at: /public/LCubeTicketsCollection)
		// Put the Minter in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: /storage/LCubeTicketAdmin)
		emit ContractInitialized()
	}
}
