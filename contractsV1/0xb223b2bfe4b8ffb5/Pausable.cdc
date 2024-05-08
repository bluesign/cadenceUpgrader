import ContractVersion from "./ContractVersion.cdc"

access(all)
contract Pausable: ContractVersion{ 
	access(all)
	fun getVersion(): String{ 
		return "1.1.5"
	}
	
	access(all)
	event Paused(account: Address)
	
	access(all)
	event Unpaused(account: Address)
	
	access(all)
	resource interface PausableExternal{ 
		access(all)
		fun isPaused(): Bool
	}
	
	access(all)
	resource interface PausableInternal{ 
		access(all)
		fun pause()
		
		access(all)
		fun unPause()
	}
	
	access(all)
	resource PausableResource: PausableInternal, PausableExternal{ 
		access(self)
		var paused: Bool
		
		init(paused: Bool){ 
			self.paused = paused
		}
		
		access(all)
		fun isPaused(): Bool{ 
			return self.paused
		}
		
		access(all)
		fun pause(){ 
			pre{ 
				self.paused == false:
					"Invalid: The resource is paused already"
			}
			self.paused = true
			emit Paused(account: (self.owner!).address)
		}
		
		access(all)
		fun unPause(){ 
			pre{ 
				self.paused == true:
					"Invalid: The resource is not paused"
			}
			self.paused = false
			emit Unpaused(account: (self.owner!).address)
		}
	}
	
	access(all)
	fun createResource(paused: Bool): @PausableResource{ 
		return <-create PausableResource(paused: paused)
	}
	
	init(){} 
}
