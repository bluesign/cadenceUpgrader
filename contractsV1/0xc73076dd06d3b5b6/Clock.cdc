// forked from bjartek's Clock.cdc: https://github.com/findonflow/find/blob/main/contracts/Clock.cdc
access(all)
contract Clock{ 
	access(contract)
	var mockClock: UFix64
	
	access(contract)
	var enabled: Bool
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event MockTimeEnabled()
	
	access(all)
	event MockTimeDisabled()
	
	access(all)
	event MockTimeAdvanced(amount: UFix64)
	
	access(all)
	let ClockManagerStoragePath: StoragePath
	
	access(all)
	resource ClockManager{ 
		access(all)
		fun turnMockTimeOn(){ 
			pre{ 
				Clock.enabled == false:
					"mock time is already ON"
			}
			Clock.enabled = true
			emit MockTimeEnabled()
		}
		
		access(all)
		fun turnMockTimeOff(){ 
			pre{ 
				Clock.enabled == true:
					"mock time is already OFF"
			}
			Clock.enabled = false
			emit MockTimeDisabled()
		}
		
		access(all)
		fun advanceClock(_ duration: UFix64){ 
			pre{ 
				Clock.enabled == true:
					"mock time keeping is not enabled"
			}
			Clock.mockClock = Clock.mockClock + duration
			emit MockTimeAdvanced(amount: duration)
		}
	}
	
	access(all)
	fun getTime(): UFix64{ 
		if self.enabled{ 
			return self.mockClock
		}
		return getCurrentBlock().timestamp
	}
	
	init(){ 
		self.mockClock = 0.0
		self.enabled = false
		self.ClockManagerStoragePath = /storage/kissoClockManager
		let clockManager <- create ClockManager()
		self.account.storage.save(<-clockManager, to: self.ClockManagerStoragePath)
		emit ContractInitialized()
	}
}
