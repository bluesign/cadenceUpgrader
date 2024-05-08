import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract OlympicPin: NonFungibleToken{ 
	
	// The total number of Cards in existence
	access(all)
	var totalSupply: UInt64
	
	// Event that emitted when the OlympicPin contract is initialized
	//
	access(all)
	event ContractInitialized()
	
	// Emitted when a new Pin struct is created
	access(all)
	event PinCreated(id: UInt32, metadata:{ String: String})
	
	// Emitted when a new series has been triggered by an admin
	access(all)
	event NewSeriesStarted(newCurrentSeries: UInt32)
	
	// Emitted when a new Set is created
	access(all)
	event SetCreated(setId: UInt32, series: UInt32, name: String)
	
	// Emitted when a new Pin is added to a Set
	access(all)
	event PinAddedToSet(setId: UInt32, pinId: UInt32)
	
	// Emitted when a Pin is retired from a Set and cannot be used to mint
	access(all)
	event PinRetiredFromSet(setId: UInt32, pinId: UInt32, numPieces: UInt32)
	
	// Emitted when a Set is locked, meaning pins cannot be added
	access(all)
	event SetLocked(setId: UInt32)
	
	// Emitted when a Piece is minted from a Set
	access(all)
	event PieceMinted(pieceId: UInt64, pinId: UInt32, setId: UInt32, serialNumber: UInt32)
	
	// Events for Collection-related actions
	//
	// Emitted when a piece is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when a piece is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Emitted when a Piece is destroyed
	access(all)
	event PieceDestroyed(id: UInt64)
	
	// -----------------------------------------------------------------------
	// OlympicPin contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// Series that this Set belongs to.
	// Series is a concept that indicates a group of Sets through time.
	// Many Sets can exist at a time, but only one series.
	access(all)
	var currentSeries: UInt32
	
	// Variable size dictionary of Pin structs
	access(self)
	var pins:{ UInt32: Pin}
	
	// Variable size dictionary of SetData structs
	access(self)
	var setDatas:{ UInt32: SetData}
	
	// Variable size dictionary of Set resources
	access(self)
	var sets: @{UInt32: Set}
	
	// The Id that is used to create pins. 
	// Every time a Pin is created, pinId is assigned 
	// to the new Pin's Id and then is incremented by 1.
	access(all)
	var nextPinId: UInt32
	
	// The Id that is used to create SetDatas. 
	// Every time a SetData is created, SetId is assigned 
	// to the new SetData's Id and then is incremented by 1.
	access(all)
	var nextSetId: UInt32
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	//Pin
	//
	access(all)
	struct Pin{ 
		access(all)
		let pinId: UInt32
		
		access(all)
		let metadata:{ String: String}
		
		init(metadata:{ String: String}){ 
			pre{ 
				metadata.length != 0:
					"New Pin metadata cannot be empty"
			}
			self.pinId = OlympicPin.nextPinId
			self.metadata = metadata
		}
	}
	
	//SetData
	//
	access(all)
	struct SetData{ 
		
		// Unique Id for the Set
		access(all)
		let setId: UInt32
		
		// Name of the Set
		access(all)
		let name: String
		
		// Series that this Set belongs to.
		// Series is a concept that indicates a group of Sets through time.
		// Many Sets can exist at a time, but only one series.
		access(all)
		let series: UInt32
		
		init(name: String){ 
			pre{ 
				name.length > 0:
					"New Set name cannot be empty"
			}
			self.setId = OlympicPin.nextSetId
			self.name = name
			self.series = OlympicPin.currentSeries
		}
	}
	
	// Set is a resource type that contains the functions to add and remove
	// pins from a set and mint NFTs.
	//
	// It is stored in a private field in the contract so that
	// the admin resource can call its methods.
	//
	// The admin can add pins to a Set so that the set can mint NFTs
	// that reference that PinId.
	// The NFTs that are minted by a Set will be listed as belonging to
	// the Set that minted it, as well as the Pin it references.
	// 
	// Admin can also retire pins from the Set, meaning that the retired
	// Pin can no longer have NFTs minted from it.
	//
	// If the admin locks the Set, no more pins can be added to it, but 
	// NFTs can still be minted.
	//
	// If retireAll() and lock() are called back-to-back, 
	// the Set is closed off forever and nothing more can be done with it.
	access(all)
	resource Set{ 
		
		// Unique Id for the set
		access(all)
		let setId: UInt32
		
		// Array of pins that are a part of this set.
		// When a Pin is added to the set, its Id gets appended here.
		// The Id does not get removed from this array when a Pin is retired.
		access(contract)
		var pins: [UInt32]
		
		// Map of Pin Ids that Indicates if a Pin in this Set can be minted.
		// When a Pin is added to a Set, it is mapped to false (not retired).
		// When a Pin is retired, this is set to true and cannot be changed.
		access(contract)
		var retired:{ UInt32: Bool}
		
		// Indicates if the Set is currently locked.
		// When a Set is created, it is unlocked 
		// and pins are allowed to be added to it.
		// When a set is locked, pins cannot be added.
		// A Set can never be changed from locked to unlocked,
		// the decision to lock a Set it is final.
		// If a Set is locked, pins cannot be added, but
		// Pieces can still be minted from pins
		// that exist in the Set.
		access(all)
		var locked: Bool
		
		// Mapping of Pin Ids that indicates the number of Pieces
		// that have been minted for specific pins in this Set.
		// When a Piece is minted, this value is stored in the Piece to
		access(contract)
		var numberMintedPerPin:{ UInt32: UInt32}
		
		init(name: String){ 
			self.setId = OlympicPin.nextSetId
			self.pins = []
			self.retired ={} 
			self.locked = false
			self.numberMintedPerPin ={} 
			
			// Create a new SetData for this Set and store it in contract storage
			OlympicPin.setDatas[self.setId] = SetData(name: name)
		}
		
		// addPin adds a pin to the set
		//
		// Parameters: pinId: The Id of the Pin that is being added
		//
		// Pre-Conditions:
		// The Pin needs to be an existing Pin
		// The Set needs to be not locked
		// The Pin can't have already been added to the Set
		//
		access(all)
		fun addPin(pinId: UInt32){ 
			pre{ 
				OlympicPin.pins[pinId] != nil:
					"Cannot add the Pin to Set: Pin doesn't exist."
				!self.locked:
					"Cannot add the Pin to the Set after the set has been locked."
				self.numberMintedPerPin[pinId] == nil:
					"The pin has already been added to the set."
			}
			
			// Add the Pin to the array of pins
			self.pins.append(pinId)
			
			// Open the Pin up for minting
			self.retired[pinId] = false
			
			// Initialize the Piece count to zero
			self.numberMintedPerPin[pinId] = 0
			emit PinAddedToSet(setId: self.setId, pinId: pinId)
		}
		
		// addPins adds multiple pins to the Set
		//
		// Parameters: pinIds: The Ids of the pins that are being added
		//					  as an array
		//
		access(all)
		fun addPins(pinIds: [UInt32]){ 
			for pinId in pinIds{ 
				self.addPin(pinId: pinId)
			}
		}
		
		// retirePin retires a Pin from the Set so that it can't mint new Piece
		//
		// Parameters: pinId: The Id of the Pin that is being retired
		//
		// Pre-Conditions:
		// The Pin is part of the Set and not retired (available for minting).
		// 
		access(all)
		fun retirePin(pinId: UInt32){ 
			pre{ 
				self.retired[pinId] != nil:
					"Cannot retire the Pin: Pin doesn't exist in this set!"
			}
			if !self.retired[pinId]!{ 
				self.retired[pinId] = true
				emit PinRetiredFromSet(setId: self.setId, pinId: pinId, numPieces: self.numberMintedPerPin[pinId]!)
			}
		}
		
		// retireAll retires all the pins in the Set
		// Afterwards, none of the retired pins will be able to mint new NFT
		//
		access(all)
		fun retireAll(){ 
			for pinId in self.pins{ 
				self.retirePin(pinId: pinId)
			}
		}
		
		// lock() locks the Set so that no more pins can be added to it
		//
		// Pre-Conditions:
		// The Set should not be locked
		access(all)
		fun lock(){ 
			if !self.locked{ 
				self.locked = true
				emit SetLocked(setId: self.setId)
			}
		}
		
		// mintPiece mints a new and returns the newly minted Piece
		// 
		// Parameters: pinId: The ID of the Pin that the Piece references
		//
		// Pre-Conditions:
		// The Pin must exist in the Set and be allowed to mint new Pieces
		//
		// Returns: The NFT that was minted
		//
		access(all)
		fun mintPiece(pinId: UInt32): @NFT{ 
			pre{ 
				self.retired[pinId] != nil:
					"Cannot mint the Piece: This pin doesn't exist."
				!self.retired[pinId]!:
					"Cannot mint the Piece from this pin: This pin has been retired."
			}
			
			// Gets the number of Pieces that have been minted for this Pin
			// to use as this Piece's serial number
			let numInPin = self.numberMintedPerPin[pinId]!
			
			// Mint the new Piece
			let newPiece: @NFT <- create NFT(pinId: pinId, setId: self.setId, serialNumber: numInPin + UInt32(1))
			
			// Increment the count of Pieces minted for this Pin
			self.numberMintedPerPin[pinId] = numInPin + UInt32(1)
			return <-newPiece
		}
		
		// batchMintPiece mints an arbitrary quantity of Pieces 
		// and returns them as a Collection
		//
		// Parameters: pinId: the ID of the Pin that the Pieces are minted for
		//			 quantity: The quantity of Pieces to be minted
		//
		// Returns: Collection object that contains all the Pieces that were minted
		//
		access(all)
		fun batchMintPiece(pinId: UInt32, quantity: UInt64): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintPiece(pinId: pinId))
				i = i + UInt64(1)
			}
			return <-newCollection
		}
		
		access(all)
		fun getPins(): [UInt32]{ 
			return self.pins
		}
		
		access(all)
		fun getRetired():{ UInt32: Bool}{ 
			return self.retired
		}
		
		access(all)
		fun getNumMintedPerPlay():{ UInt32: UInt32}{ 
			return self.numberMintedPerPin
		}
	}
	
	access(all)
	struct PieceData{ 
		access(all)
		let pinId: UInt32
		
		access(all)
		let setId: UInt32
		
		access(all)
		let serialNumber: UInt32
		
		init(pinId: UInt32, setId: UInt32, serialNumber: UInt32){ 
			self.pinId = pinId
			self.setId = setId
			self.serialNumber = serialNumber
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		
		// Global unique Piece Id
		access(all)
		let id: UInt64
		
		// Struct of Piece metadata
		access(all)
		let data: PieceData
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(pinId: UInt32, setId: UInt32, serialNumber: UInt32){ 
			
			// Increment the global Piece Ids
			OlympicPin.totalSupply = OlympicPin.totalSupply + UInt64(1)
			self.id = OlympicPin.totalSupply
			self.data = PieceData(pinId: pinId, setId: setId, serialNumber: serialNumber)
			emit PieceMinted(pieceId: self.id, pinId: self.data.pinId, setId: self.data.setId, serialNumber: self.data.serialNumber)
		}
	
	// If the Piece is destroyed, emit an event to indicate
	// to outside observers that it has been destroyed
	}
	
	access(all)
	resource Admin{ 
		// createPin creates a new Pin struct
		// and stores it in the pins dictionary in the Olympic smart contract
		//
		// Parameters: metadata: A dictionary mapping metadata titles to their data
		//
		// Returns: the Id of the new Pin object
		//
		access(all)
		fun createPin(metadata:{ String: String}): UInt32{ 
			// Create the new Pin
			var newPin = Pin(metadata: metadata)
			let newId = newPin.pinId
			
			// Increment nextPinId
			OlympicPin.nextPinId = OlympicPin.nextPinId + UInt32(1)
			emit PinCreated(id: newId, metadata: metadata)
			
			// Store it in the contract storage
			OlympicPin.pins[newId] = newPin
			return newId
		}
		
		// createSet creates a new Set struct
		// and stores it in the Sets dictionary in the Olympic smart contract
		//
		// Parameters: metadata: A dictionary mapping metadata titles to their data
		//
		// Returns: the Id of the new SetData object
		//
		access(all)
		fun createSet(name: String): UInt32{ 
			
			// Create the new Set
			var newSet <- create Set(name: name)
			let newId = newSet.setId
			
			// Increment the setId
			OlympicPin.nextSetId = OlympicPin.nextSetId + UInt32(1)
			emit SetCreated(setId: newId, series: OlympicPin.currentSeries, name: name)
			
			// Store it in the sets mapping field
			OlympicPin.sets[newId] <-! newSet
			return newId
		}
		
		// borrowSet returns a reference to a set in the OlympicPin
		// contract so that the admin can call methods on it
		//
		// Parameters: setId: The Id of the Set that you want to
		// get a reference to
		//
		// Returns: A reference to the Set with all of the fields
		// and methods exposed
		//
		access(all)
		fun borrowSet(setId: UInt32): &Set{ 
			pre{ 
				OlympicPin.sets[setId] != nil:
					"Cannot borrow Set: The Set doesn't exist"
			}
			
			// Get a reference to the Set and return it
			// use `&` to indicate the reference to the object and type
			return (&OlympicPin.sets[setId] as &Set?)!
		}
		
		// startNewSeries ends the current series by incrementing
		// the series number, meaning that Pieces minted after this
		// will use the new series number
		//
		// Returns: The new series number
		//
		access(all)
		fun startNewSeries(): UInt32{ 
			// End the current series and start a new one
			// by incrementing the OlympicPin series number
			OlympicPin.currentSeries = OlympicPin.currentSeries + UInt32(1)
			emit NewSeriesStarted(newCurrentSeries: OlympicPin.currentSeries)
			return OlympicPin.currentSeries
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(all)
	resource interface PieceCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowPiece(id: UInt64): &OlympicPin.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Piece reference: The Id of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: PieceCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		
		// Keep track of all the NFTs that a user owns from this contract.
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Piece does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			
			// Return the withdrawn token
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: ids: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: A collection that contains
		//										the withdrawn pieces
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
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @OlympicPin.NFT
			let id = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			
			// Only emit a deposit event if the Collection 
			// is in an account's storage
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
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
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowPiece returns a borrowed reference to a Piece
		// so that the caller can read data and call methods from it.
		// They can use this to read its setID, pinID, serialNumber,
		// or any of the setData or Pin data associated with it by
		// getting the setID or pinID and reading those fields from
		// the smart contract.
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(all)
		fun borrowPiece(id: UInt64): &OlympicPin.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &OlympicPin.NFT
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
	}
	
	// -----------------------------------------------------------------------
	// OlympicPin contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection creates a new, empty Collection object so that
	// a user can store it in their account storage.
	// Once they have a Collection in their storage, they are able to receive
	// Pieces in transactions.
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create OlympicPin.Collection()
	}
	
	// getAllPins returns all the pins in OlympicPin
	//
	// Returns: An array of all the pins that have been created
	access(all)
	fun getAllPins(): [OlympicPin.Pin]{ 
		return OlympicPin.pins.values
	}
	
	// getPinMetaData returns all the metadata associated with a specific Pin
	// 
	// Parameters: pinId: The id of the Pin that is being searched
	//
	// Returns: The metadata as a String to String mapping optional
	access(all)
	fun getPinMetaData(pinId: UInt32):{ String: String}?{ 
		return self.pins[pinId]?.metadata
	}
	
	// getPinMetaDataByField returns the metadata associated with a 
	//						specific field of the metadata
	// 
	// Parameters: pinId: The id of the Pin that is being searched
	//			 field: The field to search for
	//
	// Returns: The metadata field as a String Optional
	access(all)
	fun getPinMetaDataByField(pinId: UInt32, field: String): String?{ 
		// Don't force a revert if the pinId or field is invalid
		if let pin = OlympicPin.pins[pinId]{ 
			return pin.metadata[field]
		} else{ 
			return nil
		}
	}
	
	// getSetName returns the name that the specified Set
	//			is associated with.
	// 
	// Parameters: setId: The id of the Set that is being searched
	//
	// Returns: The name of the Set
	access(all)
	fun getSetName(setId: UInt32): String?{ 
		// Don't force a revert if the setId is invalid
		return OlympicPin.setDatas[setId]?.name
	}
	
	// getSetSeries returns the series that the specified Set
	//			  is associated with.
	// 
	// Parameters: setId: The id of the Set that is being searched
	//
	// Returns: The series that the Set belongs to
	access(all)
	fun getSetSeries(setId: UInt32): UInt32?{ 
		// Don't force a revert if the setId is invalid
		return OlympicPin.setDatas[setId]?.series
	}
	
	// getSetIdsByName returns the Ids that the specified Set name
	//				 is associated with.
	// 
	// Parameters: setName: The name of the Set that is being searched
	//
	// Returns: An array of the Ids of the Set if it exists, or nil if doesn't
	access(all)
	fun getSetIdsByName(setName: String): [UInt32]?{ 
		var setIds: [UInt32] = []
		
		// Iterate through all the setDatas and search for the name
		for setData in OlympicPin.setDatas.values{ 
			if setName == setData.name{ 
				// If the name is found, return the Id
				setIds.append(setData.setId)
			}
		}
		
		// If the name isn't found, return nil
		// Don't force a revert if the setName is invalid
		if setIds.length == 0{ 
			return nil
		} else{ 
			return setIds
		}
	}
	
	// getPinsInSet returns the list of Pin Ids that are in the Set
	// 
	// Parameters: setId: The id of the Set that is being searched
	//
	// Returns: An array of Pin Ids
	access(all)
	fun getPinsInSet(setId: UInt32): [UInt32]?{ 
		// Don't force a revert if the setId is invalid
		return OlympicPin.sets[setId]?.pins
	}
	
	// isEditionRetired returns a boolean that indicates if a Set/Pin combo
	//				  (otherwise known as an edition) is retired.
	//				  If an edition is retired, it still remains in the Set,
	//				  but Pieces can no longer be minted from it.
	// 
	// Parameters: setId: The id of the Set that is being searched
	//			 pinId: The id of the Pin that is being searched
	//
	// Returns: Boolean indicating if the edition is retired or not
	access(all)
	fun isEditionRetired(setId: UInt32, pinId: UInt32): Bool?{ 
		if let retired = OlympicPin.sets[setId]?.retired{ 
			let retired = retired[pinId]
			
			// Return the retired status
			return retired
		} else{ 
			
			// If the Set wasn't found, return nil
			return nil
		}
	}
	
	// isSetLocked returns a boolean that indicates if a Set
	//			 is locked. If it's locked, 
	//			 new Pins can no longer be added to it,
	//			 but NFTs can still be minted from Pins the set contains.
	// 
	// Parameters: setId: The id of the Set that is being searched
	//
	// Returns: Boolean indicating if the Set is locked or not
	access(all)
	fun isSetLocked(setId: UInt32): Bool?{ 
		// Don't force a revert if the setId is invalid
		return OlympicPin.sets[setId]?.locked
	}
	
	// getNumPiecesInEdition return the number of Pieces that have been 
	//						minted from a certain edition.
	//
	// Parameters: setId: The id of the Set that is being searched
	//			 pinId: The id of the Pin that is being searched
	//
	// Returns: The total number of NFTs 
	//		  that have been minted from an edition
	access(all)
	fun getNumPiecesInEdition(setId: UInt32, pinId: UInt32): UInt32?{ 
		if let numberMintedPerPin = OlympicPin.sets[setId]?.numberMintedPerPin{ 
			let amount = numberMintedPerPin[pinId]
			return amount
		} else{ 
			return nil
		}
	}
	
	init(){ 
		self.currentSeries = 0
		self.pins ={} 
		self.setDatas ={} 
		self.sets <-{} 
		self.totalSupply = 0
		self.nextPinId = 1
		self.nextSetId = 1
		self.CollectionStoragePath = /storage/PieceCollection
		self.CollectionPublicPath = /public/PieceCollection
		self.AdminStoragePath = /storage/OlympicPinAdmin
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: self.CollectionStoragePath)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{PieceCollectionPublic}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Admin resource and save it to storage
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
