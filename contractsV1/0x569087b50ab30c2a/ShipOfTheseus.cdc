// ゆく河の流れは絶えずして、しかも、もとの水にあらず。淀みに浮かぶうたかたはかつ消えかつ結びて、久しくとどまりたるためしなし。
// 世の中にある人と栖とまたかくのごとし。
//
// Of the flowing river the flood ever changeth, on the still pool the foam gathering, vanishing, stayeth not.
// Such too is the lot of men and of the dwellings of men in this world of ours.
access(all)
contract ShipOfTheseus{ 
	access(all)
	var theShip: @[Ship]
	
	access(all)
	struct Memory{ 
		access(all)
		let timestamp: UFix64
		
		access(all)
		let event: String
		
		access(all)
		let executor: Address
		
		init(timestamp: UFix64, _event: String, executor: Address){ 
			self.timestamp = timestamp
			self.event = _event
			self.executor = executor
		}
	}
	
	access(all)
	resource Ship{ 
		access(all)
		let id: UInt64
		
		access(account)
		var memories: [Memory]
		
		init(id: UInt64, memories: [Memory], executor: Address){ 
			self.id = id
			self.memories = memories
			self.memories.insert(
				at: 0,
				Memory(timestamp: getCurrentBlock().timestamp, _event: "init", executor: executor)
			)
		}
		
		access(all)
		fun touch(executor: &AuthAccount){ 
			self.memories.insert(
				at: 0,
				Memory(
					timestamp: getCurrentBlock().timestamp,
					_event: "touch",
					executor: executor.address
				)
			)
		}
		
		access(all)
		fun getMemories(): [Memory]{ 
			return self.memories
		}
	}
	
	access(all)
	fun touch(executor: &AuthAccount){ 
		let ship = &self.theShip[0] as &Ship
		ship.touch(executor: executor)
	}
	
	access(all)
	fun renew(executor: &AuthAccount): @Ship{ 
		// Here, the ship is replaced by a new resource object, with the same ID and memories, but a different UUID.
		let ship <- self.theShip.removeFirst()!
		self.theShip.append(
			<-create Ship(id: ship.id, memories: ship.getMemories(), executor: executor.address)
		)
		return <-ship
	}
	
	init(){ 
		self.theShip <- [<-create Ship(id: 0, memories: [], executor: self.account.address)]
	}
}
