pub contract TokenTransferEventContract {
    // Define an event that takes the amount of tokens transferred as an argument
    pub event TokensTransferred(amount: UFix64, address: Address)
    pub event BasicTourCompleted(address: Address)
    pub event BasicTourIncomplete(value: UInt64, address: Address)

    // Define a public function to emit the event, which can be called by a transaction
    // This event will trigger a backend command to send TIT Tokens based on the Flow value transferred
    pub fun emitTokensTransferred(amount: UFix64, address: Address) {
        emit TokensTransferred(amount: amount, address: address)
    }

    // When this event is triggered, someone has completed the basic Tour of TIT palace and needs to receive their winnings.
    pub fun emitBasicTourCompleted(address: Address) {
        emit BasicTourCompleted(address: address)
    }

    //If they don't complete the tour, let's see how far that got with the value variable and also capture their address
    pub fun emitBasicTourIncomplete(value: UInt64, address: Address) {
        emit BasicTourIncomplete(value: value, address: address)
    }
}
