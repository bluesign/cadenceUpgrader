import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import RandomBeaconHistory from "../0xe467b9dd11fa00df/RandomBeaconHistory.cdc"

// import "Xorshift128plus"
access(all)
contract FlowtyRaffles{ 
	access(all)
	let ManagerStoragePath: StoragePath
	
	access(all)
	let ManagerPublicPath: PublicPath
	
	access(all)
	event ManagerCreated(uuid: UInt64)
	
	access(all)
	event RaffleCreated(address: Address?, raffleID: UInt64)
	
	access(all)
	event RaffleReceiptCommitted(
		address: Address?,
		raffleID: UInt64,
		receiptID: UInt64,
		commitBlock: UInt64
	)
	
	access(all)
	event RaffleReceiptRevealed(
		address: Address?,
		raffleID: UInt64,
		receiptID: UInt64,
		commitBlock: UInt64,
		revealHeight: UInt64,
		sourceType: Type,
		index: Int,
		value: String?,
		valueType: Type
	)
	
	access(all)
	struct DrawingResult{ 
		access(all)
		let index: Int
		
		access(all)
		let value: AnyStruct
		
		init(_ index: Int, _ value: AnyStruct){ 
			self.index = index
			self.value = value
		}
	}
	
	/*
		RaffleSourcePublic - Some helper methods on a raffle source that anyone should be able to call.
		For the most part, these methods assist in others being able to verify the entries in a raffle
		indepdenently, and are also used when a raffle performs a dtawing by:
			1. Asking for how many entries a raffle has
			2. Generating a random number
			3. Selecting a random index in the entries list based on the length of entries
			4. Obtaining the entry at the selected index
	
		NOTE: While the comments on each of these methods is the INTENDED behavior that an an implementation should use,
		there is not way for the raffle itself to know if a source is acting in good faith. Make sure you choose a raffle
		source implementation with care, as choosing one from an unknown party could result in unfair outcomes.
		*/
	
	access(all)
	resource interface RaffleSourcePublic{ 
		/*
				getEntries - return all entries in this raffle.
				NOTE: This will not work if a raffle is so large that returning all its entries will exceed computation limits
				*/
		
		access(all)
		fun getEntries(): [AnyStruct]
		
		// getEntryCount - return the total number of entries in this raffle source
		access(all)
		fun getEntryCount(): Int
		
		// getEntryAt - return the entry at a specific index of a raffle source
		access(all)
		fun getEntryAt(index: Int): AnyStruct
	}
	
	access(all)
	resource interface RaffleSourcePrivate{ 
		/*
				revealCallback - a callback used when a raffle is revealed. This could be used to do things like
				remove an entry once it has been picked. As with similar notes above in the RaffleSourcePublic interface,
				make sure you trust the implementation of this callback so that it does not introduce unforeseen risk
				to your raffle
				*/
		
		access(all)
		fun revealCallback(drawingResult: DrawingResult)
		
		/*
				addEntries - adds an array of values into the raffle source, if it is permitted.
				NOTE: Some raffle source implementations might not permit this. As with other parts of this raffles
				implementation, be mindful of the source you are using and what it does
				*/
		
		access(all)
		fun addEntries(_ v: [AnyStruct])
		
		/*
				addEntry - adds value into the raffle source, if it is permitted.
				NOTE: Some raffle source implementations might not permit this. As with other parts of this raffles
				implementation, be mindful of the source you are using and what it does
				*/
		
		access(all)
		fun addEntry(_ v: AnyStruct)
	}
	
	access(all)
	resource interface RafflePublic{ 
		access(all)
		fun borrowSourcePublic(): &{RaffleSourcePublic}?
		
		access(all)
		fun getDetails(): Details
	}
	
	access(all)
	resource Receipt{ 
		// the block at which this receipt is allowed to be revealed
		access(all)
		let commitBlock: UInt64
		
		// we record the uuid of the source used so that it cannot be swapped out 
		// between stages
		access(all)
		let sourceUuid: UInt64
		
		// the block this receipt was revealed on
		access(all)
		var revealBlock: UInt64?
		
		// the result of this receipt once it has been reveald 
		access(all)
		var result: DrawingResult?
		
		/*
				reveal - reveals the result of this receipt. A receipt can only be revealed if the current block is 
				greater than or equal to the receipt's commit block. For raffles which do not need the commit-reveal scheme, setting
				the commit block to the same block that a receipt was created in will allow the receipt to be both created and revealed in
				the same transaction
				*/
		
		access(contract)
		fun reveal(_ source: &{RaffleSourcePublic, RaffleSourcePrivate}): DrawingResult{ 
			pre{ 
				self.commitBlock! <= getCurrentBlock().height:
					"receipt cannot be revealed yet"
				self.result == nil:
					"receipt has already been revealed"
			}
			
			// get a random number using this receipts commit block and uuid as the seed and salt
			let rand = FlowtyRaffles.randUInt64(atBlockHeight: self.commitBlock, salt: self.uuid)
			
			// obtain a random value in our raffle source based on its entry count
			let index = Int(rand % UInt64(source.getEntryCount()))
			let value = source.getEntryAt(index: index)
			self.result = DrawingResult(index, value)
			return self.result!
		}
		
		init(commitBlock: UInt64, source: &{RaffleSourcePublic, RaffleSourcePrivate}){ 
			self.commitBlock = commitBlock // what block is this allowed to be revealed on?
			
			self.sourceUuid = source.uuid
			self.revealBlock = nil
			self.result = nil
		}
	}
	
	access(all)
	struct Details{ 
		access(all)
		let start: UInt64?
		
		access(all)
		let end: UInt64?
		
		access(all)
		let display: MetadataViews.Display?
		
		access(all)
		let externalURL: MetadataViews.ExternalURL?
		
		access(all)
		let commitBlocksAhead: UInt64
		
		init(
			start: UInt64?,
			end: UInt64?,
			display: MetadataViews.Display?,
			externalURL: MetadataViews.ExternalURL?,
			commitBlocksAhead: UInt64
		){ 
			self.start = start
			self.end = end
			self.display = display
			self.externalURL = externalURL
			self.commitBlocksAhead = commitBlocksAhead
		}
	}
	
	access(all)
	resource Raffle: RafflePublic{ 
		// Basic details about this raffle
		access(all)
		let details: Details
		
		// a set of addresses which are allowed to perform reveals on a raffle.
		// set this to nil to allow anyone to reveal a drawing
		access(all)
		var revealers:{ Address: Bool}?
		
		// The source of entries for this raffle. This allows a raffle to delegate out 
		// what is being drawn. Some raffles might be for Addresses, others might be for
		// UInt64s or Strings
		access(all)
		let source: @{RaffleSourcePublic, RaffleSourcePrivate}
		
		// Used to track all drawings done from this raffle. When a receipt is made,
		// it has no result until revealed, and can only be revealed if the current block is 
		// equal to or greater than the block a receipt was made on + details.commitBlocksAhead
		access(all)
		let receipts: @{UInt64: Receipt}
		
		access(all)
		fun borrowSourcePublic(): &{RaffleSourcePublic}?{ 
			return &self.source as &{RaffleSourcePublic, RaffleSourcePrivate}
		}
		
		// commitDrawing - stage one to performing a drawing.
		access(contract)
		fun commitDrawing(commitBlock: UInt64): UInt64{ 
			let ref = &self.source as &{RaffleSourcePublic, RaffleSourcePrivate}
			let receipt <- create Receipt(commitBlock: commitBlock, source: ref)
			let uuid = receipt.uuid
			destroy self.receipts.insert(key: uuid, <-receipt)
			return uuid
		}
		
		// revealDrawing - stage two to performing a drawing. This step will let a receipt resolve its result
		// using the commit stage block height and receipt uuid to create a random number.
		access(contract)
		fun revealDrawing(id: UInt64): DrawingResult{ 
			pre{ 
				self.receipts[id] != nil:
					"receipt id not found"
			}
			let receipt = (&self.receipts[id] as &Receipt?)!
			let ref = &self.source as &{RaffleSourcePublic, RaffleSourcePrivate}
			let res: FlowtyRaffles.DrawingResult = receipt.reveal(ref)
			
			// perform a callback to the source in case it wants to handle anything based on the result
			// NOTE: This type of blind callback should be handled with extreme care by anyone making a non-standard 
			// implementation of a raffle source. It introduces risks such as re-entrancy.
			ref.revealCallback(drawingResult: res)
			return res
		}
		
		access(all)
		fun addEntries(_ v: [AnyStruct]){ 
			let blockTs = UInt64(getCurrentBlock().timestamp)
			self.source.addEntries(v)
		}
		
		access(all)
		fun addEntry(_ v: AnyStruct){ 
			let blockTs = UInt64(getCurrentBlock().timestamp)
			self.source.addEntry(v)
		}
		
		access(all)
		fun getDetails(): Details{ 
			return self.details
		}
		
		init(source: @{RaffleSourcePublic, RaffleSourcePrivate}, details: Details, revealers: [Address]?){ 
			self.details = details
			self.source <- source
			self.receipts <-{} 
			self.revealers = nil
			/*
						if an array of permitted revealers has been specified, add it to our set of addresses
						to be used for verification later when revealing. If revealers is empty or nil, anyone will be
						able to reveal a drawing
						*/
			
			if let r = revealers{ 
				let d:{ Address: Bool} ={} 
				for addr in r{ 
					d[addr] = true
				}
				if d.length > 0{ 
					self.revealers = d
				}
			}
		}
	}
	
	/*
		ManagerPublic - a set of public methods that anyone can use on a raffle manager.
		
		Most required methods actually exist on the raffle itself, the Manager serves as a means to get a public interface of a raffle.
		
		In addition to getting a raffle, the manager public also provides a way to reveal a raffle's outcome which is available for anyone to do
		based on the commit-reveal scheme underneath the raffle's management itself.
		*/
	
	access(all)
	resource interface ManagerPublic{ 
		access(all)
		fun borrowRafflePublic(id: UInt64): &{RafflePublic}?
		
		access(all)
		fun revealDrawing(manager: &Manager, raffleID: UInt64, receiptID: UInt64): DrawingResult
		
		access(contract)
		fun _revealDrawing(raffleID: UInt64, receiptID: UInt64, drawer: &Manager): DrawingResult
	}
	
	/*
		ManagerPrivate - Methods only available to the trusted entitier for a specific manager resource.
		This is made into its own interface so that a manager can be delegated out to others in the event that community run
		raffles are desired. One could make a capability to the private manager and share it with others they trust.
		*/
	
	access(all)
	resource interface ManagerPrivate{ 
		access(all)
		fun borrowRaffle(id: UInt64): &Raffle?
		
		access(all)
		fun commitDrawing(raffleID: UInt64): UInt64
	}
	
	// This is an empty interface to give reveal requests the ability to vet whether or not
	// the calling manager is permitted to perform a reveal on a given drawing or not
	access(all)
	resource interface ManagerIdentity{} 
	
	access(all)
	resource Manager: ManagerPublic, ManagerPrivate{ 
		access(all)
		let raffles: @{UInt64: Raffle}
		
		access(all)
		fun borrowRafflePublic(id: UInt64): &{RafflePublic}?{ 
			return self.borrowRaffle(id: id)
		}
		
		access(all)
		fun borrowRaffle(id: UInt64): &Raffle?{ 
			if self.raffles[id] == nil{ 
				return nil
			}
			return &self.raffles[id] as &Raffle?
		}
		
		/*
				createRaffle - creates a new raffle with the specified details. Making a raffle requires specifying
				1. the source for the raffle. This will dictate where entries are drawn from.
				2. details about the raffle, including start, end, display, and external url links
				3. how many blocks ahead a result must be to be revealed. Setting commitBlocksAhead to 0 means a reveal can be done in the same block as the commit, and is subject to reversion risks
					discussed here: https://developers.flow.com/build/advanced-concepts/randomness#guidelines-for-safe-usage
				*/
		
		access(all)
		fun createRaffle(source: @{RaffleSourcePublic, RaffleSourcePrivate}, details: Details, revealers: [Address]?): UInt64{ 
			let raffle <- create Raffle(source: <-source, details: details, revealers: revealers)
			let uuid = raffle.uuid
			emit RaffleCreated(address: self.owner?.address, raffleID: uuid)
			destroy self.raffles.insert(key: uuid, <-raffle)
			return uuid
		}
		
		/*
				commitDrawing - commits a new drawing for a raffle, creating a receipt resource with the specified commit block height
				to be revealed at a later date.
				*/
		
		access(all)
		fun commitDrawing(raffleID: UInt64): UInt64{ 
			let raffle = self.borrowRaffle(id: raffleID) ?? panic("raffle not found")
			let currentBlock = getCurrentBlock()
			let blockTs = UInt64(currentBlock.timestamp)
			let commitBlock = raffle.details.commitBlocksAhead + currentBlock.height
			let receiptID = raffle.commitDrawing(commitBlock: commitBlock)
			emit RaffleReceiptCommitted(address: self.owner?.address, raffleID: raffleID, receiptID: receiptID, commitBlock: commitBlock)
			return receiptID
		}
		
		/*
				revealDrawing - reveals the result of a drawing, taking the committed data in the commit stage and using it to
				generate a random number to draw an entry from our raffle source
				*/
		
		access(all)
		fun revealDrawing(manager: &Manager, raffleID: UInt64, receiptID: UInt64): DrawingResult{ 
			let ref = &self as &Manager
			return manager._revealDrawing(raffleID: raffleID, receiptID: receiptID, drawer: ref)
		}
		
		access(contract)
		fun _revealDrawing(raffleID: UInt64, receiptID: UInt64, drawer: &Manager): DrawingResult{ 
			let raffle = self.borrowRaffle(id: raffleID) ?? panic("raffle not found")
			assert(raffle.revealers == nil || (raffle.revealers!)[(drawer.owner!).address] == true, message: "drawer is not permitted to perform reveals on this raffle")
			let drawingResult = raffle.revealDrawing(id: receiptID)
			let receipt = (raffle.receipts[receiptID] as &FlowtyRaffles.Receipt?)!
			var v = FlowtyRaffles.extractString(drawingResult.value)
			emit RaffleReceiptRevealed(address: self.owner?.address, raffleID: raffleID, receiptID: receiptID, commitBlock: receipt.commitBlock, revealHeight: getCurrentBlock().height, sourceType: raffle.source.getType(), index: drawingResult.index, value: v, valueType: drawingResult.value.getType())
			return drawingResult
		}
		
		init(){ 
			self.raffles <-{} 
		}
	}
	
	// taken from
	// https://github.com/onflow/random-coin-toss/blob/4271cd571b7761af36b0f1037767171aeca18387/contracts/CoinToss.cdc#L95
	access(all)
	fun randUInt64(atBlockHeight: UInt64, salt: UInt64): UInt64{ 
		// // query the Random Beacon history core-contract - if `blockHeight` <= current block height, panic & revert
		// let sourceOfRandomness = RandomBeaconHistory.sourceOfRandomness(atBlockHeight: atBlockHeight)
		// assert(sourceOfRandomness.blockHeight == atBlockHeight, message: "RandomSource block height mismatch")
		
		// // instantiate a PRG object, seeding a source of randomness with `salt` and returns a pseudo-random
		// // generator object.
		// let prg = Xorshift128plus.PRG(
		//	 sourceOfRandomness: sourceOfRandomness.value,
		//	 salt: salt.toBigEndianBytes()
		// )
		
		// return prg.nextUInt64()
		// TODO: use commented-out implementation once we can test using the randomness beacon in the cadence testing framework
		return revertibleRandom()
	}
	
	access(all)
	fun extractString(_ value: AnyStruct?): String?{ 
		if value == nil{ 
			return nil
		}
		let v = value!
		let t = v.getType()
		if t.isSubtype(of: Type<Integer>()){ 
			return (v as! Integer).toString()
		}
		if t.isSubtype(of: Type<FixedPoint>()){ 
			return (v as! FixedPoint).toString()
		}
		switch t{ 
			case Type<Address>():
				return (v as! Address).toString()
			case Type<String>():
				return value as! String
		}
		return nil
	}
	
	access(all)
	fun createManager(): @Manager{ 
		return <-create Manager()
	}
	
	init(){ 
		let identifier = "FlowtyRaffles_".concat(self.account.address.toString())
		self.ManagerStoragePath = StoragePath(identifier: identifier)!
		self.ManagerPublicPath = PublicPath(identifier: identifier)!
	}
}
