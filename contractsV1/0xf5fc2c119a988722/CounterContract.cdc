access(all)
contract CounterContract{ 
	access(all)
	let CounterStoragePath: StoragePath
	
	access(all)
	let CounterPublicPath: PublicPath
	
	access(all)
	event AddedCount(currentCount: UInt64)
	
	access(all)
	resource interface HasCount{ 
		access(all)
		fun currentCount(): UInt64
	}
	
	access(all)
	resource Counter: HasCount{ 
		access(contract)
		var count: UInt64
		
		init(){ 
			self.count = 0
		}
		
		access(all)
		fun plusOne(hash: String){ 
			self.count = self.count + 1
		}
		
		access(all)
		fun currentCount(): UInt64{ 
			return self.count
		}
	}
	
	access(all)
	fun currentCount(): UInt64{ 
		let counter = self.account.capabilities.get<&{HasCount}>(self.CounterPublicPath)
		let counterRef = counter.borrow()!
		return counterRef.currentCount()
	}
	
	// initializer
	//
	init(){ 
		self.CounterStoragePath = /storage/testCounterPrivatePath
		self.CounterPublicPath = /public/testCounterPublicPath
		let counter <- create Counter()
		self.account.storage.save(<-counter, to: self.CounterStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&{HasCount}>(self.CounterStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CounterPublicPath)
	}
}
