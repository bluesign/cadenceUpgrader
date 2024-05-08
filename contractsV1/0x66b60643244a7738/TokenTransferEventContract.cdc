access(all)
contract TokenTransferEventContract{ 
	// Define an event that takes the amount of tokens transferred as an argument
	access(all)
	event TokensTransferred(amount: UFix64, address: Address)
	
	access(all)
	event BasicTourCompleted(address: Address)
	
	access(all)
	event BasicTourIncomplete(value: UInt64, address: Address)
	
	// Define a public function to emit the event, which can be called by a transaction
	// This event will trigger a backend command to send TIT Tokens based on the Flow value transferred
	access(all)
	fun emitTokensTransferred(amount: UFix64, address: Address){ 
		emit TokensTransferred(amount: amount, address: address)
	}
	
	// When this event is triggered, someone has completed the basic Tour of TIT palace and needs to receive their winnings.
	access(all)
	fun emitBasicTourCompleted(address: Address){ 
		emit BasicTourCompleted(address: address)
	}
	
	//If they don't complete the tour, let's see how far that got with the value variable and also capture their address
	access(all)
	fun emitBasicTourIncomplete(value: UInt64, address: Address){ 
		emit BasicTourIncomplete(value: value, address: address)
	}
}
