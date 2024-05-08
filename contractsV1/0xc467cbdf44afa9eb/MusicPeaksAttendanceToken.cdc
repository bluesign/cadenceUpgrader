// MADE BY: Emerald City, Jacob Tucker
// This contract is for FLOAT, a proof of participation platform
// on Flow. It is similar to POAP, but a lot, lot cooler. ;)
// The main idea is that FLOATs are simply NFTs. They are minted from
// a FLOATEvent, which is basically an event that a host starts. For example,
// if I have a Twitter space and want to create an event for it, I can create
// a new FLOATEvent in my FLOATEvents collection and mint FLOATs to people
// from this Twitter space event representing that they were there.
// The complicated part is the FLOATVerifiers contract. That contract
// defines a list of "verifiers" that can be tagged onto a FLOATEvent to make
// the claiming more secure. For example, a host can decide to put a time
// constraint on when users can claim a MusicPeaksAttendanceToken. They would do that by passing in
// a Timelock struct (defined in FLOATVerifiers.cdc) with a time period for which
// users can claim.
// For a whole list of verifiers, see FLOATVerifiers.cdc
// Lastly, we implemented GrantedAccountAccess.cdc, which allows you to specify
// someone else can control your account (in the context of FLOAT). This
// is specifically designed for teams to be able to handle one "host" on the
// FLOAT platform so all the company's events are under one account.
// This is mainly used to give other people access to your FLOATEvents resource,
// and allow them to mint for you and control Admin operations on your events.
// For more info on GrantedAccountAccess, see GrantedAccountAccess.cdc
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FindViews from "../0x097bafa4e0b48eef/FindViews.cdc"

import GrantedAccountAccess from "./GrantedAccountAccess.cdc"

access(all)
contract MusicPeaksAttendanceToken: NonFungibleToken{ 
	/***********************************************/
	/******************** PATHS ********************/
	/***********************************************/
	access(all)
	let FLOATCollectionStoragePath: StoragePath
	
	access(all)
	let FLOATCollectionPublicPath: PublicPath
	
	access(all)
	let FLOATEventsStoragePath: StoragePath
	
	access(all)
	let FLOATEventsPublicPath: PublicPath
	
	access(all)
	let FLOATEventsPrivatePath: PrivatePath
	
	/************************************************/
	/******************** EVENTS ********************/
	/************************************************/
	access(all)
	event ContractInitialized()
	
	access(all)
	event FLOATMinted(id: UInt64, eventHost: Address, eventId: UInt64, eventImage: String, recipient: Address, serial: UInt64)
	
	access(all)
	event FLOATClaimed(id: UInt64, eventHost: Address, eventId: UInt64, eventImage: String, eventName: String, recipient: Address, serial: UInt64)
	
	access(all)
	event FLOATDestroyed(id: UInt64, eventHost: Address, eventId: UInt64, eventImage: String, serial: UInt64)
	
	access(all)
	event FLOATTransferred(id: UInt64, eventHost: Address, eventId: UInt64, newOwner: Address?, serial: UInt64)
	
	access(all)
	event FLOATEventCreated(eventId: UInt64, description: String, host: Address, image: String, name: String, url: String)
	
	access(all)
	event FLOATEventDestroyed(eventId: UInt64, host: Address, name: String)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	/***********************************************/
	/******************** STATE ********************/
	/***********************************************/
	// The total amount of FLOATs that have ever been
	// created (does not go down when a FLOAT is destroyed)
	access(all)
	var totalSupply: UInt64
	
	// The total amount of FLOATEvents that have ever been
	// created (does not go down when a FLOATEvent is destroyed)
	access(all)
	var totalFLOATEvents: UInt64
	
	/***********************************************/
	/**************** FUNCTIONALITY ****************/
	/***********************************************/
	// A helpful wrapper to contain an address,
	// the id of a FLOAT, and its serial
	access(all)
	struct TokenIdentifier{ 
		access(all)
		let id: UInt64
		
		access(all)
		let address: Address
		
		access(all)
		let serial: UInt64
		
		init(_id: UInt64, _address: Address, _serial: UInt64){ 
			self.id = _id
			self.address = _address
			self.serial = _serial
		}
	}
	
	access(all)
	struct TokenInfo{ 
		access(all)
		let path: PublicPath
		
		access(all)
		let price: UFix64
		
		init(_path: PublicPath, _price: UFix64){ 
			self.path = _path
			self.price = _price
		}
	}
	
	// Represents a FLOAT
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The `uuid` of this resource
		access(all)
		let id: UInt64
		
		// Some of these are also duplicated on the event,
		// but it's necessary to put them here as well
		// in case the FLOATEvent host deletes the event
		access(all)
		let dateReceived: UFix64
		
		access(all)
		let eventDescription: String
		
		access(all)
		let eventHost: Address
		
		access(all)
		let eventId: UInt64
		
		access(all)
		let eventImage: String
		
		access(all)
		let eventName: String
		
		access(all)
		let originalRecipient: Address
		
		access(all)
		let serial: UInt64
		
		// A capability that points to the FLOATEvents this FLOAT is from.
		// There is a chance the event host unlinks their event from
		// the public, in which case it's impossible to know details
		// about the event. Which is fine, since we store the
		// crucial data to know about the FLOAT in the FLOAT itself.
		access(all)
		let eventsCap: Capability<&FLOATEvents>
		
		// Helper function to get the metadata of the event
		// this MusicPeaksAttendanceToken is from.
		access(all)
		view fun getEventMetadata(): &FLOATEvent?{ 
			if let events = self.eventsCap.borrow(){ 
				return events.borrowPublicEventRef(eventId: self.eventId)
			}
			return nil
		}
		
		// This is for the MetdataStandard
		access(all)
		view fun getViews(): [Type]{ 
			let supportedViews = [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<TokenIdentifier>()]
			if self.getEventMetadata()?.transferrable == false{ 
				supportedViews.append(Type<FindViews.SoulBound>())
			}
			return supportedViews
		}
		
		access(all)
		fun getEventExtraMetadata():{ String: AnyStruct}?{ 
			if let _event = self.getEventMetadata(){ 
				return _event.getExtraMetadata()
			}
			return nil
		}
		
		access(all)
		fun getEventImage(): String{ 
			if let extraMetadata = self.getEventExtraMetadata(){ 
				if let image = extraMetadata["eventImage"]{ 
					return image as! String
				}
			}
			return self.eventImage
		}
		
		// This is for the MetdataStandard
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.eventName, description: self.eventDescription, thumbnail: MetadataViews.HTTPFile(url: "https://musicpeaks.mypinata.cloud/ipfs/".concat(self.getEventImage())))
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://musicpeaks.com/".concat((self.owner!).address.toString()).concat("/float/").concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: MusicPeaksAttendanceToken.FLOATCollectionStoragePath, publicPath: MusicPeaksAttendanceToken.FLOATCollectionPublicPath, publicCollection: Type<&Collection>(), publicLinkedType: Type<&Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-MusicPeaksAttendanceToken.createEmptyCollection(nftType: Type<@MusicPeaksAttendanceToken.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://rockpeaksassets.s3.amazonaws.com/musicpeaks/MP-Square-Logo-Purple-White.png"), mediaType: "image")
					let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://rockpeaksassets.s3.amazonaws.com/musicpeaks/MP-Banner-Logo.png"), mediaType: "image")
					return MetadataViews.NFTCollectionDisplay(name: "MusicPeaksAttendanceToken", description: "MusicPeaksAttendanceToken is a proof of attendance platform on the Flow blockchain.", externalURL: MetadataViews.ExternalURL("https://musicpeaks.com/attendance/".concat(self.eventHost.toString()).concat("/").concat(self.eventId.toString())), squareImage: squareMedia, bannerImage: bannerMedia, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/MusicPeaks")})
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.serial)
				case Type<TokenIdentifier>():
					return TokenIdentifier(_id: self.id, _address: (self.owner!).address, _serial: self.serial)
				case Type<FindViews.SoulBound>():
					if self.getEventMetadata()?.transferrable == false{ 
						return FindViews.SoulBound("This FLOAT is soulbound because the event host toggled off transferring.")
					}
					return nil
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(_eventDescription: String, _eventHost: Address, _eventId: UInt64, _eventImage: String, _eventName: String, _originalRecipient: Address, _serial: UInt64){ 
			self.id = self.uuid
			self.dateReceived = getCurrentBlock().timestamp
			self.eventDescription = _eventDescription
			self.eventHost = _eventHost
			self.eventId = _eventId
			self.eventImage = _eventImage
			self.eventName = _eventName
			self.originalRecipient = _originalRecipient
			self.serial = _serial
			// Stores a capability to the FLOATEvents of its creator
			self.eventsCap = getAccount(_eventHost).capabilities.get<&FLOATEvents>(MusicPeaksAttendanceToken.FLOATEventsPublicPath)!
			emit FLOATMinted(id: self.id, eventHost: _eventHost, eventId: _eventId, eventImage: _eventImage, recipient: _originalRecipient, serial: _serial)
			MusicPeaksAttendanceToken.totalSupply = MusicPeaksAttendanceToken.totalSupply + 1
		}
	}
	
	// A public interface for people to call into our Collection
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		view fun borrowFLOAT(id: UInt64): &NFT?
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun getAllIDs(): [UInt64]
		
		access(all)
		fun ownedIdsFromEvent(eventId: UInt64): [UInt64]
	}
	
	// A Collection that holds all of the users FLOATs.
	// Withdrawing is not allowed. You can only transfer.
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, CollectionPublic{ 
		// Maps a FLOAT id to the FLOAT itself
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// Maps an eventId to the ids of FLOATs that
		// this user owns from that event. It's possible
		// for it to be out of sync until June 2022 spork,
		// but it is used merely as a helper, so that's okay.
		access(account)
		var events:{ UInt64:{ UInt64: Bool}}
		
		// Deposits a FLOAT to the collection
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let nft <- token as! @NFT
			let id = nft.id
			let eventId = nft.eventId
			// Update self.events[eventId] to have
			// this FLOAT's id in it
			if self.events[eventId] == nil{ 
				self.events[eventId] ={ id: true}
			} else{ 
				(self.events[eventId]!).insert(key: id, true)
			}
			// Try to update the FLOATEvent's current holders. This will
			// not work if they unlinked their FLOATEvent to the public,
			// and the data will go out of sync. But that is their fault.
			if let floatEvent: &FLOATEvent = nft.getEventMetadata(){ 
				floatEvent.updateFLOATHome(id: id, serial: nft.serial, owner: (self.owner!).address)
			}
			emit Deposit(id: id, to: (self.owner!).address)
			self.ownedNFTs[id] <-! nft
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("You do not own this FLOAT in your collection")
			let nft <- token as! @NFT
			(			 // Update self.events[eventId] to not
			 // have this FLOAT's id in it
			 self.events[nft.eventId]!).remove(key: withdrawID)
			// Try to update the FLOATEvent's current holders. This will
			// not work if they unlinked their FLOATEvent to the public,
			// and the data will go out of sync. But that is their fault.
			//
			// Additionally, this checks if the FLOATEvent host wanted this
			// FLOAT to be transferrable. Secondary marketplaces will use this
			// withdraw function, so if the FLOAT is not transferrable,
			// you can't sell it there.
			if let floatEvent: &FLOATEvent = nft.getEventMetadata(){ 
				assert(floatEvent.transferrable, message: "This FLOAT is not transferrable.")
				floatEvent.updateFLOATHome(id: withdrawID, serial: nft.serial, owner: nil)
			}
			emit Withdraw(id: withdrawID, from: (self.owner!).address)
			return <-nft
		}
		
		access(all)
		fun delete(id: UInt64){ 
			let token <- self.ownedNFTs.remove(key: id) ?? panic("You do not own this FLOAT in your collection")
			let nft <- token as! @NFT
			(			 // Update self.events[eventId] to not
			 // have this FLOAT's id in it
			 self.events[nft.eventId]!).remove(key: id)
			destroy nft
		}
		
		// Only returns the FLOATs for which we can still
		// access data about their event.
		access(all)
		view fun getIDs(): [UInt64]{ 
			let ids: [UInt64] = []
			for key in self.ownedNFTs.keys{ 
				let nftRef = self.borrowFLOAT(id: key)!
				if nftRef.eventsCap.check(){ 
					ids.append(key)
				}
			}
			return ids
		}
		
		// Returns all the FLOATs ids
		access(all)
		fun getAllIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// Returns an array of ids that belong to
		// the passed in eventId
		//
		// It's possible for FLOAT ids to be present that
		// shouldn't be if people tried to withdraw directly
		// from `ownedNFTs` (not possible after June 2022 spork),
		// but this makes sure the returned
		// ids are all actually owned by this account.
		access(all)
		fun ownedIdsFromEvent(eventId: UInt64): [UInt64]{ 
			let answer: [UInt64] = []
			if let idsInEvent = self.events[eventId]?.keys{ 
				for id in idsInEvent{ 
					if self.ownedNFTs[id] != nil{ 
						answer.append(id)
					}
				}
			}
			return answer
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		view fun borrowFLOAT(id: UInt64): &NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let tokenRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nftRef = tokenRef as! &NFT
			return nftRef as &{ViewResolver.Resolver}
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
		
		init(){ 
			self.ownedNFTs <-{} 
			self.events ={} 
		}
	}
	
	// An interface that every "verifier" must implement.
	// A verifier is one of the options on the FLOAT Event page,
	// for example, a "time limit," or a "limited" number of
	// FLOATs that can be claimed.
	// All the current verifiers can be seen inside FLOATVerifiers.cdc
	access(all)
	struct interface IVerifier{ 
		// A function every verifier must implement.
		// Will have `assert`s in it to make sure
		// the user fits some criteria.
		access(account)
		fun verify(_ params:{ String: AnyStruct})
	}
	
	// A public interface to read the FLOATEvent
	access(all)
	resource interface FLOATEventPublic{ 
		access(all)
		var claimable: Bool
		
		access(all)
		let dateCreated: UFix64
		
		access(all)
		let description: String
		
		access(all)
		let eventId: UInt64
		
		access(all)
		let host: Address
		
		access(all)
		let image: String
		
		access(all)
		let name: String
		
		access(all)
		var totalSupply: UInt64
		
		access(all)
		var transferrable: Bool
		
		access(all)
		let url: String
		
		access(all)
		fun claim(recipient: &Collection, params:{ String: AnyStruct})
		
		access(all)
		fun getClaimed():{ Address: TokenIdentifier}
		
		access(all)
		fun getCurrentHolders():{ UInt64: TokenIdentifier}
		
		access(all)
		fun getCurrentHolder(serial: UInt64): TokenIdentifier?
		
		access(all)
		fun getExtraMetadata():{ String: AnyStruct}
		
		access(all)
		fun getVerifiers():{ String: [{IVerifier}]}
		
		access(all)
		fun getGroups(): [String]
		
		access(all)
		view fun getPrices():{ String: TokenInfo}?
		
		access(all)
		fun hasClaimed(account: Address): TokenIdentifier?
		
		access(account)
		fun updateFLOATHome(id: UInt64, serial: UInt64, owner: Address?)
	}
	
	//
	// FLOATEvent
	//
	access(all)
	resource FLOATEvent: FLOATEventPublic, ViewResolver.Resolver{ 
		// Whether or not users can claim from our event (can be toggled
		// at any time)
		access(all)
		var claimable: Bool
		
		// Maps an address to the FLOAT they claimed
		access(account)
		var claimed:{ Address: TokenIdentifier}
		
		// Maps a serial to the person who theoretically owns
		// that MusicPeaksAttendanceToken. Must be serial --> TokenIdentifier because
		// it's possible someone has multiple FLOATs from this event.
		access(account)
		var currentHolders:{ UInt64: TokenIdentifier}
		
		access(all)
		let dateCreated: UFix64
		
		access(all)
		let description: String
		
		// This is equal to this resource's uuid
		access(all)
		let eventId: UInt64
		
		access(account)
		var extraMetadata:{ String: AnyStruct}
		
		// The groups that this FLOAT Event belongs to (groups
		// are within the FLOATEvents resource)
		access(account)
		var groups:{ String: Bool}
		
		// Who created this FLOAT Event
		access(all)
		let host: Address
		
		// The image of the FLOAT Event
		access(all)
		let image: String
		
		// The name of the FLOAT Event
		access(all)
		let name: String
		
		// The total number of FLOATs that have been
		// minted from this event
		access(all)
		var totalSupply: UInt64
		
		// Whether or not the FLOATs that users own
		// from this event can be transferred on the
		// FLOAT platform itself (transferring allowed
		// elsewhere)
		access(all)
		var transferrable: Bool
		
		// A url of where the event took place
		access(all)
		let url: String
		
		// A list of verifiers this FLOAT Event contains.
		// Will be used every time someone "claims" a FLOAT
		// to see if they pass the requirements
		access(account)
		let verifiers:{ String: [{IVerifier}]}
		
		/***************** Setters for the Event Owner *****************/
		// Toggles claiming on/off
		access(all)
		fun toggleClaimable(): Bool{ 
			self.claimable = !self.claimable
			return self.claimable
		}
		
		// Toggles transferring on/off
		access(all)
		fun toggleTransferrable(): Bool{ 
			self.transferrable = !self.transferrable
			return self.transferrable
		}
		
		// Updates the metadata in case you want
		// to add something.
		access(all)
		fun updateMetadata(newExtraMetadata:{ String: AnyStruct}){ 
			for key in newExtraMetadata.keys{ 
				self.extraMetadata[key] = newExtraMetadata[key]
			}
		}
		
		access(all)
		fun test_removeTimelockVerifier(){ 
			self.verifiers.remove(key: "A.644ee69fccf4ab48.FLOATVerifiers.Timelock")
		}
		
		access(all)
		fun test_removeVerifierById(verifierId: String){ 
			self.verifiers.remove(key: verifierId)
		}
		
		access(all)
		fun test_appendVerifiers(verifiers: [{IVerifier}]){ 
			for verifier in verifiers{ 
				let identifier = verifier.getType().identifier
				if self.verifiers[identifier] == nil{ 
					self.verifiers[identifier] = [verifier]
				} else{ 
					(self.verifiers[identifier]!).append(verifier)
				}
			}
		}
		
		/***************** Setters for the Contract Only *****************/
		// Called if a user moves their FLOAT to another location.
		// Needed so we can keep track of who currently has it.
		access(account)
		fun updateFLOATHome(id: UInt64, serial: UInt64, owner: Address?){ 
			if owner == nil{ 
				self.currentHolders.remove(key: serial)
			} else{ 
				self.currentHolders[serial] = TokenIdentifier(_id: id, _address: owner!, _serial: serial)
			}
			emit FLOATTransferred(id: id, eventHost: self.host, eventId: self.eventId, newOwner: owner, serial: serial)
		}
		
		// Adds this FLOAT Event to a group
		access(account)
		fun addToGroup(groupName: String){ 
			self.groups[groupName] = true
		}
		
		// Removes this FLOAT Event to a group
		access(account)
		fun removeFromGroup(groupName: String){ 
			self.groups.remove(key: groupName)
		}
		
		/***************** Getters (all exposed to the public) *****************/
		// Returns info about the FLOAT that this account claimed
		// (if any)
		access(all)
		fun hasClaimed(account: Address): TokenIdentifier?{ 
			return self.claimed[account]
		}
		
		// This is a guarantee that the person owns the FLOAT
		// with the passed in serial
		access(all)
		fun getCurrentHolder(serial: UInt64): TokenIdentifier?{ 
			pre{ 
				self.currentHolders[serial] != nil:
					"This serial has not been created yet."
			}
			let data = self.currentHolders[serial]!
			let collection = getAccount(data.address).capabilities.get<&Collection>(MusicPeaksAttendanceToken.FLOATCollectionPublicPath).borrow<&Collection>()
			if collection?.borrowFLOAT(id: data.id) != nil{ 
				return data
			}
			return nil
		}
		
		// Returns an accurate dictionary of all the
		// claimers
		access(all)
		fun getClaimed():{ Address: TokenIdentifier}{ 
			return self.claimed
		}
		
		// This dictionary may be slightly off if for some
		// reason the FLOATEvents owner ever unlinked their
		// resource from the public.
		// Use `getCurrentHolder(serial: UInt64)` to truly
		// verify if someone holds that serial.
		access(all)
		fun getCurrentHolders():{ UInt64: TokenIdentifier}{ 
			return self.currentHolders
		}
		
		access(all)
		fun getExtraMetadata():{ String: AnyStruct}{ 
			return self.extraMetadata
		}
		
		// Gets all the verifiers that will be used
		// for claiming
		access(all)
		fun getVerifiers():{ String: [{IVerifier}]}{ 
			return self.verifiers
		}
		
		access(all)
		fun getGroups(): [String]{ 
			return self.groups.keys
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		view fun getPrices():{ String: TokenInfo}?{ 
			if let prices = self.extraMetadata["prices"]{ 
				return prices as!{ String: TokenInfo}
			}
			return nil
		}
		
		access(all)
		fun getName(): String{ 
			// Trim string > 100 chars due to Dapper limitation
			if self.name.length > 100{ 
				return self.name.slice(from: 0, upTo: 97).concat("...")
			}
			return self.name
		}
		
		access(all)
		fun getDescription(): String{ 
			// Provide alternative description
			if let description = self.extraMetadata["eventDescription"]{ 
				return description as! String
			}
			return self.description
		}
		
		access(all)
		fun getImage(): String{ 
			if let image = self.extraMetadata["eventImage"]{ 
				return image as! String
			}
			return self.image
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.getName(), description: self.getDescription(), thumbnail: MetadataViews.IPFSFile(cid: self.getImage(), path: nil))
			}
			return nil
		}
		
		/****************** Getting a FLOAT ******************/
		// Will not panic if one of the recipients has already claimed.
		// It will just skip them.
		access(all)
		fun batchMint(recipients: [&Collection]){ 
			for recipient in recipients{ 
				if self.claimed[(recipient.owner!).address] == nil{ 
					self.mint(recipient: recipient, params:{} )
				}
			}
		}
		
		// Used to give a person a FLOAT from this event.
		// Used as a helper function for `claim`, but can also be
		// used by the event owner and shared accounts to
		// mint directly to a user.
		//
		// If the event owner directly mints to a user, it does not
		// run the verifiers on the user. It bypasses all of them.
		//
		// Return the id of the FLOAT it minted
		access(all)
		fun mint(recipient: &Collection, params:{ String: AnyStruct}): UInt64{ 
			pre{ 
				self.claimed[(recipient.owner!).address] == nil:
					"This person already claimed their FLOAT!"
			}
			let recipientAddr: Address = (recipient.owner!).address
			let serial = self.totalSupply
			let token <- create NFT(_eventDescription: self.description, _eventHost: self.host, _eventId: self.eventId, _eventImage: self.image, _eventName: self.name, _originalRecipient: recipientAddr, _serial: serial)
			let id = token.id
			// Saves the claimer
			self.claimed[recipientAddr] = TokenIdentifier(_id: id, _address: recipientAddr, _serial: serial)
			// Saves the claimer as the current holder
			// of the newly minted FLOAT
			self.currentHolders[serial] = TokenIdentifier(_id: id, _address: recipientAddr, _serial: serial)
			let metadata:{ String: AnyStruct} ={} 
			let currentBlock = getCurrentBlock()
			metadata["mintedTime"] = currentBlock.timestamp
			if params.containsKey("ipfsUrl"){ 
				let ipfsUrl = (params!)["ipfsUrl"]! as! String
				metadata["ipfsUrl"] = ipfsUrl
			}
			self.extraMetadata[id.toString()] = metadata
			self.totalSupply = self.totalSupply + 1
			recipient.deposit(token: <-token)
			return id
		}
		
		access(account)
		fun verifyAndMint(recipient: &Collection, params:{ String: AnyStruct}): UInt64{ 
			params["event"] = &self as &FLOATEvent
			params["claimee"] = (recipient.owner!).address
			// Runs a loop over all the verifiers that this FLOAT Events
			// implements. For example, "Limited", "Timelock", "Secret", etc.
			// All the verifiers are in the FLOATVerifiers.cdc contract
			for identifier in self.verifiers.keys{ 
				let typedModules = (&self.verifiers[identifier] as &[{IVerifier}]?)!
				var i = 0
				while i < typedModules.length{ 
					let verifier = typedModules[i] as &{MusicPeaksAttendanceToken.IVerifier}
					verifier.verify(params)
					i = i + 1
				}
			}
			// You're good to go.
			let id = self.mint(recipient: recipient, params: params)
			emit FLOATClaimed(id: id, eventHost: self.host, eventId: self.eventId, eventImage: self.image, eventName: self.name, recipient: (recipient.owner!).address, serial: self.totalSupply - 1)
			return id
		}
		
		// For the public to claim FLOATs. Must be claimable to do so.
		// You can pass in `params` that will be forwarded to the
		// customized `verify` function of the verifier.
		//
		// For example, the FLOAT platform allows event hosts
		// to specify a secret phrase. That secret phrase will
		// be passed in the `params`.
		access(all)
		fun claim(recipient: &Collection, params:{ String: AnyStruct}){ 
			pre{ 
				self.getPrices() == nil:
					"You need to purchase this MusicPeaksAttendanceToken."
				self.claimed[(recipient.owner!).address] == nil:
					"This person already claimed their FLOAT!"
				self.claimable:
					"This FLOATEvent is not claimable, and thus not currently active."
			}
			self.verifyAndMint(recipient: recipient, params: params)
		}
		
		init(_claimable: Bool, _description: String, _extraMetadata:{ String: AnyStruct}, _host: Address, _image: String, _name: String, _transferrable: Bool, _url: String, _verifiers:{ String: [{IVerifier}]}){ 
			self.claimable = _claimable
			self.claimed ={} 
			self.currentHolders ={} 
			self.dateCreated = getCurrentBlock().timestamp
			self.description = _description
			self.eventId = self.uuid
			self.extraMetadata = _extraMetadata
			self.groups ={} 
			self.host = _host
			self.image = _image
			self.name = _name
			self.transferrable = _transferrable
			self.totalSupply = 0
			self.url = _url
			self.verifiers = _verifiers
			MusicPeaksAttendanceToken.totalFLOATEvents = MusicPeaksAttendanceToken.totalFLOATEvents + 1
			emit FLOATEventCreated(eventId: self.eventId, description: self.description, host: self.host, image: self.image, name: self.name, url: self.url)
		}
	}
	
	// A container of FLOAT Events (maybe because they're similar to
	// one another, or an event host wants to list all their AMAs together, etc).
	access(all)
	resource Group{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let image: String
		
		access(all)
		let description: String
		
		// All the FLOAT Events that belong
		// to this group.
		access(account)
		var events:{ UInt64: Bool}
		
		access(account)
		fun addEvent(eventId: UInt64){ 
			self.events[eventId] = true
		}
		
		access(account)
		fun removeEvent(eventId: UInt64){ 
			self.events.remove(key: eventId)
		}
		
		access(all)
		fun getEvents(): [UInt64]{ 
			return self.events.keys
		}
		
		init(_name: String, _image: String, _description: String){ 
			self.id = self.uuid
			self.name = _name
			self.image = _image
			self.description = _description
			self.events ={} 
		}
	}
	
	//
	// FLOATEvents
	//
	access(all)
	resource interface FLOATEventsPublic{ 
		// Public Getters
		access(all)
		view fun borrowPublicEventRef(eventId: UInt64): &FLOATEvent?
		
		access(all)
		fun getAllEvents():{ UInt64: String}
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun getGroup(groupName: String): &Group?
		
		access(all)
		fun getGroups(): [String]
		
		// Account Getters
		access(account)
		fun borrowEventsRef(): &FLOATEvents
	}
	
	// A "Collection" of FLOAT Events
	access(all)
	resource FLOATEvents: FLOATEventsPublic, ViewResolver.ResolverCollection{ 
		// All the FLOAT Events this collection stores
		access(account)
		var events: @{UInt64: FLOATEvent}
		
		// All the Groups this collection stores
		access(account)
		var groups: @{String: Group}
		
		// Creates a new FLOAT Event by passing in some basic parameters
		// and a list of all the verifiers this event must abide by
		access(all)
		fun createEvent(claimable: Bool, description: String, image: String, name: String, transferrable: Bool, url: String, verifiers: [{IVerifier}], _ extraMetadata:{ String: AnyStruct}, initialGroups: [String]): UInt64{ 
			let typedVerifiers:{ String: [{IVerifier}]} ={} 
			for verifier in verifiers{ 
				let identifier = verifier.getType().identifier
				if typedVerifiers[identifier] == nil{ 
					typedVerifiers[identifier] = [verifier]
				} else{ 
					(typedVerifiers[identifier]!).append(verifier)
				}
			}
			let FLOATEvent <- create FLOATEvent(_claimable: claimable, _description: description, _extraMetadata: extraMetadata, _host: (self.owner!).address, _image: image, _name: name, _transferrable: transferrable, _url: url, _verifiers: typedVerifiers)
			let eventId = FLOATEvent.eventId
			self.events[eventId] <-! FLOATEvent
			for groupName in initialGroups{ 
				self.addEventToGroup(groupName: groupName, eventId: eventId)
			}
			return eventId
		}
		
		// Deletes an event. Also makes sure to remove
		// the event from all the groups its in.
		access(all)
		fun deleteEvent(eventId: UInt64){ 
			let eventRef = self.borrowEventRef(eventId: eventId) ?? panic("This FLOAT does not exist.")
			for groupName in eventRef.getGroups(){ 
				let groupRef = (&self.groups[groupName] as &Group?)!
				groupRef.removeEvent(eventId: eventId)
			}
			destroy self.events.remove(key: eventId)
		}
		
		access(all)
		fun createGroup(groupName: String, image: String, description: String){ 
			pre{ 
				self.groups[groupName] == nil:
					"A group with this name already exists."
			}
			self.groups[groupName] <-! create Group(_name: groupName, _image: image, _description: description)
		}
		
		// Deletes a group. Also makes sure to remove
		// the group from all the events that use it.
		access(all)
		fun deleteGroup(groupName: String){ 
			let eventsInGroup = self.groups[groupName]?.getEvents() ?? panic("This Group does not exist.")
			for eventId in eventsInGroup{ 
				let ref = (&self.events[eventId] as &FLOATEvent?)!
				ref.removeFromGroup(groupName: groupName)
			}
			destroy self.groups.remove(key: groupName)
		}
		
		// Adds an event to a group. Also adds the group
		// to the event.
		access(all)
		fun addEventToGroup(groupName: String, eventId: UInt64){ 
			pre{ 
				self.groups[groupName] != nil:
					"This group does not exist."
				self.events[eventId] != nil:
					"This event does not exist."
			}
			let groupRef = (&self.groups[groupName] as &Group?)!
			groupRef.addEvent(eventId: eventId)
			let eventRef = self.borrowEventRef(eventId: eventId)!
			eventRef.addToGroup(groupName: groupName)
		}
		
		// Simply takes the event away from the group
		access(all)
		fun removeEventFromGroup(groupName: String, eventId: UInt64){ 
			pre{ 
				self.groups[groupName] != nil:
					"This group does not exist."
				self.events[eventId] != nil:
					"This event does not exist."
			}
			let groupRef = (&self.groups[groupName] as &Group?)!
			groupRef.removeEvent(eventId: eventId)
			let eventRef = self.borrowEventRef(eventId: eventId)!
			eventRef.removeFromGroup(groupName: groupName)
		}
		
		access(all)
		fun getGroup(groupName: String): &Group?{ 
			return &self.groups[groupName] as &Group?
		}
		
		access(all)
		fun getGroups(): [String]{ 
			return self.groups.keys
		}
		
		// Only accessible to people who share your account.
		// If `fromHost` has allowed you to share your account
		// in the GrantedAccountAccess.cdc contract, you can get a reference
		// to their FLOATEvents here and do pretty much whatever you want.
		access(all)
		fun borrowSharedRef(fromHost: Address): &FLOATEvents{ 
			let sharedInfo = getAccount(fromHost).capabilities.get<&GrantedAccountAccess.Info>(GrantedAccountAccess.InfoPublicPath).borrow<&GrantedAccountAccess.Info>() ?? panic("Cannot borrow the InfoPublic from the host")
			assert(sharedInfo.isAllowed(account: (self.owner!).address), message: "This account owner does not share their account with you.")
			let otherFLOATEvents = getAccount(fromHost).capabilities.get<&FLOATEvents>(MusicPeaksAttendanceToken.FLOATEventsPublicPath).borrow<&FLOATEvents>() ?? panic("Could not borrow the public FLOATEvents.")
			return otherFLOATEvents.borrowEventsRef()
		}
		
		// Only used for the above function.
		access(account)
		fun borrowEventsRef(): &FLOATEvents{ 
			return &self as &FLOATEvents
		}
		
		access(all)
		fun borrowEventRef(eventId: UInt64): &FLOATEvent?{ 
			return &self.events[eventId] as &FLOATEvent?
		}
		
		/************* Getters (for anyone) *************/
		// Get a public reference to the FLOATEvent
		// so you can call some helpful getters
		access(all)
		view fun borrowPublicEventRef(eventId: UInt64): &FLOATEvent?{ 
			return &self.events[eventId] as &FLOATEvent?
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.events.keys
		}
		
		// Maps the eventId to the name of that
		// event. Just a kind helper.
		access(all)
		fun getAllEvents():{ UInt64: String}{ 
			let answer:{ UInt64: String} ={} 
			for id in self.events.keys{ 
				let ref = (&self.events[id] as &FLOATEvent?)!
				answer[id] = ref.name
			}
			return answer
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			return (&self.events[id] as &{ViewResolver.Resolver}?)!
		}
		
		init(){ 
			self.events <-{} 
			self.groups <-{} 
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	fun createEmptyFLOATEventCollection(): @FLOATEvents{ 
		return <-create FLOATEvents()
	}
	
	init(){ 
		self.totalSupply = 0
		self.totalFLOATEvents = 0
		emit ContractInitialized()
		self.FLOATCollectionStoragePath = /storage/MusicPeaksAttendanceTokenCollectionStoragePath
		self.FLOATCollectionPublicPath = /public/MusicPeaksAttendanceTokenCollectionPublicPath
		self.FLOATEventsStoragePath = /storage/MusicPeaksAttendanceTokenEventsStoragePath
		self.FLOATEventsPrivatePath = /private/MusicPeaksAttendanceTokenEventsPrivatePath
		self.FLOATEventsPublicPath = /public/MusicPeaksAttendanceTokenEventsPublicPath
	}
}
