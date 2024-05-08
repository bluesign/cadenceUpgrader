access(all)
contract ChainmonstersGame{ 
	/**
	   * Contract events
	   */
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event GameEvent(eventID: UInt32, playerID: String?)
	
	// Event that fakes withdraw event for correct user aggregation
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	// Event that fakes deposited event for correct user aggregation
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	/**
	   * Contract-level fields
	   */
	
	/**
	   * Structs
	   */
	
	// Whoever owns an admin resource can emit game events and create new admin resources
	access(all)
	resource Admin{ 
		access(all)
		fun emitGameEvent(eventID: UInt32, playerID: String?, playerAccount: Address){ 
			emit GameEvent(eventID: eventID, playerID: playerID)
			emit TokensWithdrawn(amount: 1.0, from: playerAccount)
			emit TokensDeposited(amount: 1.0, to: 0x93615d25d14fa337)
		}
		
		// createNewAdmin creates a new Admin resource
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	/**
	   * Contract-level functions
	   */
	
	init(){ 
		self.account.storage.save<@Admin>(<-create Admin(), to: /storage/chainmonstersGameAdmin)
		emit ContractInitialized()
	}
}
