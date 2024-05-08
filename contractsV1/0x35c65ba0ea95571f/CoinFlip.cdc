import FungibleToken from "./../../standardsV1/FungibleToken.cdc" //mainnet


import FlowToken from "./../../standardsV1/FlowToken.cdc" //mainnet


access(all)
contract CoinFlip{ 
	// BetCreated triggers when a bet is created
	access(all)
	event BetCreated(bettor: Address, amount: UFix64, guess: String)
	
	// OutcomeCreated triggers when the outcome is derived from the blockID
	access(all)
	event OutcomeCreated(blockID: String)
	
	// PayoutSent triggers when the payout has been sent to the winner
	access(all)
	event PayoutSent(amount: UFix64, winner: Address)
	
	// declare public fields
	access(all)
	let bettor: Address
	
	access(all)
	let banker: Address
	
	access(all)
	let amount: UFix64
	
	access(all)
	let guess: String
	
	access(all)
	var blockID: String
	
	access(all)
	var winner: Address
	
	// makeBet creates a new bet
	access(all)
	fun makeBet(bettor: Address, banker: Address, amount: UFix64, guess: String){ 
		emit BetCreated(bettor: bettor, amount: amount, guess: guess)
	}
	
	// Randomization event that occurs after a bet is placed
	access(all)
	fun DecidingOutcome(blockID: String){ 
		emit OutcomeCreated(blockID: blockID)
	}
	
	// PayoutBet sends the winnings to the winner if they were correct in their guess, 
	// or to the FlowBook wallet if they were wrong
	access(all)
	fun PayoutBet(amount: UFix64, winner: Address){ 
		emit PayoutSent(amount: amount, winner: winner)
	}
	
	init(){ 
		self.bettor = 0x1654653399040a61
		self.banker = 0x1654653399040a61
		self.winner = 0x1654653399040a61
		self.amount = 184467440737.09551615
		self.guess = "Heads"
		self.blockID = "0x1654653399040a61"
	}
}
