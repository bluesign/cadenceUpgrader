/**
> Author: FIXeS World <https://fixes.world/>

# FGameLottery

This contract is a lottery game contract. It allows users to buy tickets and participate in the lottery.
The lottery is drawn every epoch. The lottery result is generated randomly and verified with the participants' tickets.

*/

// Fixes Imports
import Fixes from "./Fixes.cdc"

import FixesHeartbeat from "./FixesHeartbeat.cdc"

import FRC20FTShared from "./FRC20FTShared.cdc"

import FRC20Indexer from "./FRC20Indexer.cdc"

import FRC20AccountsPool from "./FRC20AccountsPool.cdc"

import FRC20Staking from "./FRC20Staking.cdc"

access(all)
contract FGameLottery{ 
	/* --- Events --- */
	/// Event emitted when the contract is initialized
	access(all)
	event ContractInitialized()
	
	/// Event emitted when a new lottery ticket is created
	access(all)
	event TicketAdded(
		poolAddr: Address,
		lotteryId: UInt64,
		address: Address,
		ticketId: UInt64,
		numbers: [
			UInt8; 6
		]
	)
	
	/// Event emitted when a ticket's powerup is updated
	access(all)
	event TicketPowerupChanged(
		poolAddr: Address,
		lotteryId: UInt64,
		address: Address,
		ticketId: UInt64,
		powerup: UFix64
	)
	
	/// Event emitted when a ticket status is updated
	access(all)
	event TicketStatusChanged(
		poolAddr: Address,
		lotteryId: UInt64,
		address: Address,
		ticketId: UInt64,
		fromStatus: UInt8,
		toStatus: UInt8
	)
	
	/// Event emitted when tickets is purchased
	access(all)
	event TicketPurchased(
		poolAddr: Address,
		lotteryId: UInt64,
		address: Address,
		ticketIds: [
			UInt64
		],
		costTick: String,
		costAmount: UFix64
	)
	
	/// Event emitted when a ticket is verified
	access(all)
	event TicketVerified(
		poolAddr: Address,
		lotteryId: UInt64,
		address: Address,
		ticketId: UInt64,
		numbers: [
			UInt8; 6
		],
		status: UInt8,
		prizeRank: UInt8
	)
	
	/// Event emitted when a ticket is disbursed
	access(all)
	event TicketPrizeDisbursed(
		poolAddr: Address,
		lotteryId: UInt64,
		address: Address,
		ticketId: UInt64,
		prizeAmount: UFix64
	)
	
	/// Event emitted when a new lottery is started
	access(all)
	event LotteryStarted(poolAddr: Address, lotteryId: UInt64, startTime: UFix64)
	
	/// Event emitted when a lottery is drawn
	access(all)
	event LotteryDrawn(
		poolAddr: Address,
		lotteryId: UInt64,
		numbers: [
			UInt8; 6
		],
		participantAmount: UInt64,
		totalBought: UFix64,
		jackpotAmount: UFix64
	)
	
	/// Event emitted when a lottery is verified with non-jackpot updated
	access(all)
	event LotteryParticipantsVerified(
		poolAddr: Address,
		lotteryId: UInt64,
		participants: [
			Address
		],
		winners: UInt64,
		nonJackpotTotal: UFix64
	)
	
	/// Event emitted when a lottery is verified with jackpot updated
	access(all)
	event LotteryJackpotWinnerUpdated(poolAddr: Address, lotteryId: UInt64, winner: Address)
	
	/// Event emitted when a lottery is verified with jackpot updated
	access(all)
	event LotteryJackpotFinialized(
		poolAddr: Address,
		lotteryId: UInt64,
		jackpotAmount: UFix64,
		nonJackpotTotal: UFix64,
		nonJackpotDowngradeRatio: UFix64
	)
	
	/// Event emitted when a lottery is disbursing prizes
	access(all)
	event LotteryPrizesDisbursed(poolAddr: Address, lotteryId: UInt64)
	
	/// Event emitted when a lottery jackpot is donated
	access(all)
	event LotteryJackpotDonated(poolAddr: Address, donationAmount: UFix64)
	
	/* --- Variable, Enums and Structs --- */
	access(all)
	let userCollectionStoragePath: StoragePath
	
	access(all)
	let userCollectionPublicPath: PublicPath
	
	access(all)
	let lotteryPoolStoragePath: StoragePath
	
	access(all)
	let lotteryPoolPublicPath: PublicPath
	
	access(all)
	var MAX_WHITE_NUMBER: UInt8
	
	access(all)
	var MAX_RED_NUMBER: UInt8
	
	/* --- Interfaces & Resources --- */
	/// Struct for the ticket number
	/// The ticket number is a combination of 5 white numbers and 1 red number
	/// The white numbers are between 1 and MAX_WHITE_NUMBER
	/// The red number is between 1 and MAX_RED_NUMBER
	///
	access(all)
	struct TicketNumber{ 
		// White numbers
		access(all)
		let white: [UInt8; 5]
		
		// Red number
		access(all)
		let red: UInt8
		
		init(white: [UInt8; 5], red: UInt8){ 
			// Check if the white numbers are valid
			for number in white{ 
				assert(number >= 1 && number <= FGameLottery.MAX_WHITE_NUMBER, message: "White numbers must be between 1 and MAX_WHITE_NUMBER")
			}
			// Check if the red number is valid
			assert(
				red >= 1 && red <= FGameLottery.MAX_RED_NUMBER,
				message: "Red number must be between 1 and MAX_RED_NUMBER"
			)
			self.white = white
			self.red = red
		}
		
		/// Get the ticket numbers
		access(all)
		view fun getNumbers(): [UInt8; 6]{ 
			return [
				self.white[0],
				self.white[1],
				self.white[2],
				self.white[3],
				self.white[4],
				self.red
			]
		}
	}
	
	/// Create a new random ticket number
	///
	access(contract)
	fun createRandomTicketNumber(): TicketNumber{ 
		// Generate random numbers for the ticket
		var whiteNumbers: [UInt8; 5] = [0, 0, 0, 0, 0]
		// generate the random white numbers, the numbers are between 1 and MAX_WHITE_NUMBER
		var i = 0
		while i < 5{ 
			let rndUInt8 = UInt8(revertibleRandom() % UInt64(UInt8.max))
			let newNum = rndUInt8 % FGameLottery.MAX_WHITE_NUMBER + 1
			// we need to check if the number is already in the array
			if !whiteNumbers.contains(newNum){ 
				whiteNumbers[i] = newNum
				i = i + 1
			}
		}
		// sort the white numbers in ascending order
		// there is no sort method for array, so we use fast sort algorithm to sort the array
		i = 0
		while i < 4{ 
			var j = i + 1
			while j < 5{ 
				if whiteNumbers[i] > whiteNumbers[j]{ 
					let temp = whiteNumbers[i]
					whiteNumbers[i] = whiteNumbers[j]
					whiteNumbers[j] = temp
				}
				j = j + 1
			}
			i = i + 1
		}
		// generate the random red number, the number is between 1 and MAX_RED_NUMBER
		let rndUInt8 = UInt8(revertibleRandom() % UInt64(UInt8.max))
		var redNumber: UInt8 = rndUInt8 % FGameLottery.MAX_RED_NUMBER + 1
		return TicketNumber(white: whiteNumbers, red: redNumber)
	}
	
	/// Enum for the ticket status
	///
	access(all)
	enum TicketStatus: UInt8{ 
		access(all)
		case ACTIVE
		
		access(all)
		case LOSE
		
		access(all)
		case WIN
		
		access(all)
		case WIN_DISBURSED
	}
	
	/// Enum for the prize rank
	///
	access(all)
	enum PrizeRank: UInt8{ 
		access(all)
		case JACKPOT // 100% Jackpot Pool + Math.min(50%, Remaining) of Current Pool
		
		
		access(all)
		case SECOND // 50000x Ticket Price
		
		
		access(all)
		case THIRD // 5000x Ticket Price
		
		
		access(all)
		case FOURTH // 25x Ticket Price
		
		
		access(all)
		case FIFTH // 4x Ticket Price
		
		
		access(all)
		case SIXTH // 2x Ticket Price
	
	}
	
	/// Ticket entry resource interface
	///
	access(all)
	resource interface TicketEntryPublic{ 
		// variables
		access(all)
		let pool: Address
		
		access(all)
		let lotteryId: UInt64
		
		access(all)
		let numbers: TicketNumber
		
		access(all)
		let boughtAt: UFix64
		
		// view functions
		access(all)
		view fun getStatus(): TicketStatus
		
		access(all)
		view fun getTicketId(): UInt64
		
		access(all)
		view fun getTicketOwner(): Address
		
		access(all)
		view fun getNumbers(): [UInt8; 6]
		
		access(all)
		view fun getPowerup(): UFix64
		
		access(all)
		view fun getWinPrizeRank(): PrizeRank?
		
		access(all)
		view fun getEstimatedPrizeAmount(): UFix64?
		
		// borrow methods
		access(all)
		view fun borrowLottery(): &Lottery
		
		// write methods - only the contract can call these methods
		access(contract)
		fun onPrizeVerify()
		
		access(contract)
		fun onPrizeDisburse(_ prizeAmount: UFix64)
	}
	
	/// Resource for the ticket entry
	///
	access(all)
	resource TicketEntry: TicketEntryPublic{ 
		/// Lottery Pool Address for the ticket
		access(all)
		let pool: Address
		
		/// Lottery ID for the ticket
		access(all)
		let lotteryId: UInt64
		
		/// Ticket numbers
		access(all)
		let numbers: TicketNumber
		
		/// Ticket bought at
		access(all)
		let boughtAt: UFix64
		
		/// Ticket powerup, default is 1, you can increase the powerup to increase the winning amount
		access(self)
		var powerup: UFix64
		
		/// Ticket status
		access(self)
		var status: TicketStatus
		
		/// Winner prize rank
		access(self)
		var winPrizeRank: PrizeRank?
		
		init(pool: Address, lotteryId: UInt64, powerup: UFix64?, numbers: TicketNumber?){ 
			pre{ 
				powerup == nil || powerup! >= 1.0:
					"Powerup must be greater than 0"
				powerup == nil || powerup! <= 10.0:
					"Powerup must be less than or equal to 10"
				FGameLottery.borrowLotteryPool(pool) != nil:
					"Lottery pool not found"
			}
			self.pool = pool
			self.lotteryId = lotteryId
			self.boughtAt = getCurrentBlock().timestamp
			// Create a new random ticket number
			self.numbers = numbers ?? FGameLottery.createRandomTicketNumber()
			// Set the default powerup to 1
			self.powerup = powerup ?? 1.0
			// Set the default status to ACTIVE
			self.status = TicketStatus.ACTIVE
			// Set the default win prize rank to nil
			self.winPrizeRank = nil
			
			// ensure lottery is active
			let lotteryRef = self.borrowLottery()
			assert(lotteryRef.getStatus() == LotteryStatus.ACTIVE, message: "Lottery is not active")
		}
		
		/// Get the ticket ID
		///
		access(all)
		view fun getTicketId(): UInt64{ 
			return self.uuid
		}
		
		/// Get the ticket owner
		///
		access(all)
		view fun getTicketOwner(): Address{ 
			return self.owner?.address ?? panic("Ticket owner is missing")
		}
		
		/// Get the ticket numbers
		///
		access(all)
		view fun getNumbers(): [UInt8; 6]{ 
			return self.numbers.getNumbers()
		}
		
		/// Get the ticket powerup
		///
		access(all)
		view fun getPowerup(): UFix64{ 
			return self.powerup
		}
		
		/// Get the ticket status
		///
		access(all)
		view fun getStatus(): TicketStatus{ 
			return self.status
		}
		
		/// Get the winner prize rank
		///
		access(all)
		view fun getWinPrizeRank(): PrizeRank?{ 
			return self.winPrizeRank
		}
		
		/// Get the estimated prize amount
		///
		access(all)
		view fun getEstimatedPrizeAmount(): UFix64?{ 
			let prizeRank = self.getWinPrizeRank()
			if prizeRank == nil{ 
				return nil
			}
			let lotteryRef = self.borrowLottery()
			let drawnResult = lotteryRef.getResult()
			if drawnResult == nil{ 
				return nil
			}
			let pool = FGameLottery.borrowLotteryPool(self.pool) ?? panic("Lottery pool not found")
			let ticketOwner = self.getTicketOwner()
			let feeRatio = pool.getServiceFee()
			// Get the prize amount
			if prizeRank! == PrizeRank.JACKPOT{ 
				// Disburse the jackpot prize
				let winners = (drawnResult!).jackpotWinners
				if winners == nil || (winners!).length == 0 || !(winners!).contains(ticketOwner){ 
					return nil
				}
				let jackpotAmount = (drawnResult!).jackpotAmount
				let jackpotWinnerAmt = winners?.length!
				let basicPrize = jackpotAmount / UFix64(jackpotWinnerAmt)
				// 16% prize is service fee
				return basicPrize * (1.0 - feeRatio)
			} else{ 
				// Get the base prize amount
				let basePrize = pool.getWinnerPrizeByRank(prizeRank!)
				
				// Disburse the prize amount
				let prizeAmountWithPowerup = basePrize * self.getPowerup()
				let prizeDowngradeRatio = (drawnResult!).nonJackpotDowngradeRatio
				let basicPrize = prizeAmountWithPowerup * prizeDowngradeRatio
				if (prizeRank!).rawValue <= PrizeRank.THIRD.rawValue{ 
					// 16% prize is service fee
					return basicPrize * (1.0 - feeRatio)
				} else{ 
					return basicPrize
				}
			}
		}
		
		/// Borrow the lottery
		///
		access(all)
		view fun borrowLottery(): &Lottery{ 
			let lotteryPool = self._borrowLotteryPool()
			return lotteryPool.borrowLottery(self.lotteryId) ?? panic("Lottery not found")
		}
		
		/** Update Ticket Data */
		access(contract)
		fun setPowerup(powerup: UFix64){ 
			pre{ 
				powerup >= 1.0:
					"Powerup must be greater than 0"
				powerup <= 10.0:
					"Powerup must be less than or equal to 10"
				powerup > self.powerup:
					"New powerup must be greater than the current powerup"
			}
			self.powerup = powerup
			emit TicketPowerupChanged(poolAddr: self.pool, lotteryId: self.lotteryId, address: self.getTicketOwner(), ticketId: self.getTicketId(), powerup: powerup)
		}
		
		access(contract)
		fun onPrizeVerify(){ 
			if self.status != TicketStatus.ACTIVE{ 
				return
			}
			// Verify the ticket numbers with the lottery result
			let lotteryRef = self.borrowLottery()
			let lotteryResult = lotteryRef.getResult()
			if lotteryResult == nil{ 
				return
			}
			// --- check the ticket numbers and set the status ---
			let resultNumbers = (lotteryResult!).numbers
			// get all the matched white numbers
			let matchedWhiteNumbers: [UInt8] = []
			// Check the white numbers
			for number in resultNumbers.white{ 
				if self.numbers.white.contains(number){ 
					matchedWhiteNumbers.append(number)
				}
			}
			// check if the red number is matched
			let isRedMatched = self.numbers.red == resultNumbers.red
			
			// Set the ticket status based on the matched numbers
			if matchedWhiteNumbers.length == 5 && isRedMatched{ 
				// Jackpot: 5 white numbers and 1 red number are matched
				self._setStatus(toStatus: TicketStatus.WIN)
				self.winPrizeRank = PrizeRank.JACKPOT
			} else if matchedWhiteNumbers.length == 5{ 
				// Second: 5 white numbers are matched
				self._setStatus(toStatus: TicketStatus.WIN)
				self.winPrizeRank = PrizeRank.SECOND
			} else if matchedWhiteNumbers.length == 4 && isRedMatched{ 
				// Third: 4 white numbers and 1 red number are matched
				self._setStatus(toStatus: TicketStatus.WIN)
				self.winPrizeRank = PrizeRank.THIRD
			} else if matchedWhiteNumbers.length == 4 || matchedWhiteNumbers.length == 3 && isRedMatched{ 
				// Fourth: 4 white numbers are matched or 3 white numbers and 1 red number are matched
				self._setStatus(toStatus: TicketStatus.WIN)
				self.winPrizeRank = PrizeRank.FOURTH
			} else if matchedWhiteNumbers.length == 3 || matchedWhiteNumbers.length == 2 && isRedMatched{ 
				// Fifth: 3 white numbers or 2 white numbers and 1 red number are matched
				self._setStatus(toStatus: TicketStatus.WIN)
				self.winPrizeRank = PrizeRank.FIFTH
			} else if isRedMatched{ 
				// Sixth: at least 1 red number is matched
				self._setStatus(toStatus: TicketStatus.WIN)
				self.winPrizeRank = PrizeRank.SIXTH
			} else{ 
				// Lose: no number is matched
				self._setStatus(toStatus: TicketStatus.LOSE)
			}
			
			// emit event
			emit TicketVerified(poolAddr: self.pool, lotteryId: self.lotteryId, address: self.getTicketOwner(), ticketId: self.getTicketId(), numbers: self.getNumbers(), status: self.status.rawValue, prizeRank: self.winPrizeRank?.rawValue ?? 0)
		}
		
		access(contract)
		fun onPrizeDisburse(_ prizeAmount: UFix64){ 
			// Only the ticket with WIN status and the prize rank can be disbursed
			if self.status != TicketStatus.WIN{ 
				return
			}
			if self.winPrizeRank == nil{ 
				return
			}
			
			// Set the ticket status to WIN_DISBURSED
			self._setStatus(toStatus: TicketStatus.WIN_DISBURSED)
			
			// emit event
			emit TicketPrizeDisbursed(poolAddr: self.pool, lotteryId: self.lotteryId, address: self.getTicketOwner(), ticketId: self.getTicketId(), prizeAmount: prizeAmount)
		}
		
		/** --- Internal Methods --- */
		access(self)
		view fun _borrowLotteryPool(): &LotteryPool{ 
			return FGameLottery.borrowLotteryPool(self.pool) ?? panic("Lottery pool not found")
		}
		
		access(self)
		fun _setStatus(toStatus: TicketStatus){ 
			let oldStatus = self.status
			self.status = toStatus
			emit TicketStatusChanged(poolAddr: self.pool, lotteryId: self.lotteryId, address: self.getTicketOwner(), ticketId: self.getTicketId(), fromStatus: oldStatus.rawValue, toStatus: toStatus.rawValue)
		}
	}
	
	/// User's ticket collection resource interface
	///
	access(all)
	resource interface TicketCollectionPublic{ 
		// --- read methods ---
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun getTicketAmount(): Int
		
		access(all)
		fun borrowTicket(ticketId: UInt64): &TicketEntry?
		
		// --- write methods ---
		access(contract)
		fun addTicket(_ ticket: @TicketEntry)
	}
	
	/// User's ticket collection
	///
	access(all)
	resource TicketCollection: TicketCollectionPublic{ 
		access(self)
		let tickets: @{UInt64: TicketEntry}
		
		access(self)
		let dscSortedIDs: [UInt64]
		
		init(){ 
			self.tickets <-{} 
			self.dscSortedIDs = []
		}
		
		/// @deprecated after Cadence 1.0
		/** ---- Public Methods ---- */
		/// Get the ticket IDs
		///
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.dscSortedIDs
		}
		
		/// Get the ticket amount
		///
		access(all)
		view fun getTicketAmount(): Int{ 
			return self.dscSortedIDs.length
		}
		
		/// Borrow a ticket from the collection
		///
		access(all)
		fun borrowTicket(ticketId: UInt64): &TicketEntry?{ 
			return &self.tickets[ticketId] as &TicketEntry?
		}
		
		/** ---- Private Methods ---- */
		/// Add a new ticket to the collection
		///
		access(contract)
		fun addTicket(_ ticket: @TicketEntry){ 
			pre{ 
				self.owner != nil:
					"Only the collection with an owner can add a ticket"
				self.tickets[ticket.getTicketId()] == nil:
					"Ticket already exists"
			}
			// Basic information
			let ticketId = ticket.getTicketId()
			self.tickets[ticketId] <-! ticket
			// Add the ticket ID to the sorted array in descending order (newest first)
			self.dscSortedIDs.insert(at: 0, ticketId)
			let ref = self.borrowTicketRef(ticketId: ticketId)
			emit TicketAdded(poolAddr: ref.pool, lotteryId: ref.lotteryId, address: (self.owner!).address, ticketId: ticketId, numbers: ref.getNumbers())
		}
		
		/** --- Internal Methods --- */
		/// Borrow a ticket reference
		///
		access(self)
		fun borrowTicketRef(ticketId: UInt64): &TicketEntry{ 
			return &self.tickets[ticketId] as &TicketEntry? ?? panic("Ticket not found")
		}
	}
	
	/// Ticket identifier struct
	///
	access(all)
	struct TicketIdentifier{ 
		access(all)
		let address: Address
		
		access(all)
		let ticketId: UInt64
		
		init(_ address: Address, _ ticketId: UInt64){ 
			self.address = address
			self.ticketId = ticketId
		}
		
		/// Borrow the ticket entry
		///
		access(all)
		fun borrowTicket(): &TicketEntry?{ 
			let userCol = FGameLottery.getUserTicketCollection(self.address)
			if let colRef = userCol.borrow(){ 
				return colRef.borrowTicket(ticketId: self.ticketId)
			}
			return nil
		}
	}
	
	/// Enum for the lottery status
	///
	access(all)
	enum LotteryStatus: UInt8{ 
		access(all)
		case ACTIVE
		
		access(all)
		case READY_TO_DRAW
		
		access(all)
		case DRAWN
		
		access(all)
		case DRAWN_AND_VERIFIED
	}
	
	/// Struct for the lottery result
	///
	access(all)
	struct LotteryResult{ 
		access(all)
		let numbers: TicketNumber
		
		access(all)
		let totalBought: UFix64
		
		access(all)
		var verifyingProgress: UFix64
		
		access(all)
		var disbursingProgress: UFix64
		
		access(all)
		let winners:{ Address: UInt64}
		
		access(all)
		var nonJackpotTotal: UFix64
		
		access(all)
		var nonJackpotDowngradeRatio: UFix64
		
		access(all)
		let nonJackpotWinners:{ UInt8: UInt64}
		
		access(all)
		var jackpotAmount: UFix64
		
		access(all)
		var jackpotWinners: [Address]?
		
		init(numbers: TicketNumber, totalBought: UFix64, jackpotAmount: UFix64){ 
			self.numbers = numbers
			self.totalBought = totalBought
			self.winners ={} 
			self.jackpotAmount = jackpotAmount
			self.jackpotWinners = nil
			self.verifyingProgress = 0.0
			self.disbursingProgress = 0.0
			self.nonJackpotTotal = 0.0
			self.nonJackpotDowngradeRatio = 1.0
			self.nonJackpotWinners ={} 
		}
		
		/// Add a winner
		///
		access(contract)
		fun addWinner(_ address: Address){ 
			self.winners[address] = (self.winners[address] ?? 0) + 1
		}
		
		/// Increment the non-jackpot total
		///
		access(contract)
		fun incrementNonJackpotTotal(_ rank: PrizeRank, _ amount: UFix64){ 
			self.nonJackpotWinners[rank.rawValue] = (self.nonJackpotWinners[rank.rawValue] ?? 0) + 1
			self.nonJackpotTotal = self.nonJackpotTotal + amount
		}
		
		/// Set the non-jackpot downgraded ratio
		///
		access(contract)
		fun setNonJackpotDowngradeRatio(_ ratio: UFix64){ 
			if ratio >= 0.0 && ratio <= 1.0{ 
				self.nonJackpotDowngradeRatio = ratio
			}
		}
		
		/// Set the jackpot info
		///
		access(contract)
		fun updateJackpot(_ amount: UFix64){ 
			self.jackpotAmount = amount
		}
		
		/// Add a jackpot winner
		///
		access(contract)
		fun addJackpotWinner(_ address: Address){ 
			if self.jackpotWinners == nil{ 
				self.jackpotWinners = [address]
			} else{ 
				self.jackpotWinners?.append(address)
			}
		}
		
		/// Set the distribution progress
		///
		access(contract)
		fun setVerifyingProgress(_ progress: UFix64){ 
			if progress >= 0.0 && progress <= 1.0{ 
				self.verifyingProgress = progress
			}
		}
		
		access(contract)
		fun setDisbursingProgress(_ progress: UFix64){ 
			if progress >= 0.0 && progress <= 1.0{ 
				self.disbursingProgress = progress
			}
		}
	}
	
	/// Struct for the lottery info
	///
	access(all)
	struct LotteryBasicInfo{ 
		access(all)
		let epochIndex: UInt64
		
		access(all)
		let epochStartAt: UFix64
		
		access(all)
		let currentPool: UFix64
		
		access(all)
		let participantsAmount: UInt64
		
		access(all)
		let status: LotteryStatus
		
		access(all)
		let disbursing: Bool
		
		view init(
			epochIndex: UInt64,
			epochStartAt: UFix64,
			status: LotteryStatus,
			disbursing: Bool,
			currentPool: UFix64,
			participantsAmt: UInt64
		){ 
			self.epochIndex = epochIndex
			self.epochStartAt = epochStartAt
			self.status = status
			self.disbursing = disbursing
			self.currentPool = currentPool
			self.participantsAmount = participantsAmt
		}
	}
	
	/// Lottery public resource interface
	///
	access(all)
	resource interface LotteryPublic{ 
		/// Lottery info - public view
		access(all)
		view fun getInfo(): LotteryBasicInfo
		
		/// Lottery status
		access(all)
		view fun getStatus(): LotteryStatus
		
		/// Lotter result
		access(all)
		view fun getResult(): LotteryResult?
		
		/// Return the participant addresses
		access(all)
		view fun getParticipants(): [Address]
		
		/// Return the participant amount
		access(all)
		view fun getParticipantAmount(): UInt64
		
		/// Get the total bought balance
		access(all)
		view fun getCurrentLotteryBalance(): UFix64
		
		/// Check if the lottery is disbursing prizes
		access(all)
		view fun isDisbursing(): Bool
	}
	
	/// Lottery resource
	///
	access(all)
	resource Lottery: LotteryPublic{ 
		/// Lottery epoch index
		access(all)
		let epochIndex: UInt64
		
		/// Lottery epoch start time
		access(all)
		let epochStartAt: UFix64
		
		/// Lottery total bought
		access(self)
		let current: @FRC20FTShared.Change
		
		/// Participants tickets: [Address: [TicketID]]
		access(self)
		let participants:{ Address: [UInt64]}
		
		/// Lottery final status
		access(self)
		var drawnResult: LotteryResult?
		
		/// Lottery draw checker queue
		access(self)
		var checkingQueue: [Address]?
		
		/// Lottery winners
		access(self)
		let disbursingQueque: [TicketIdentifier]
		
		init(epochIndex: UInt64, jackpotPoolRef: &FRC20FTShared.Change){ 
			self.epochIndex = epochIndex
			self.epochStartAt = getCurrentBlock().timestamp
			self.participants ={} 
			self.disbursingQueque = []
			self.drawnResult = nil
			self.checkingQueue = nil
			// Set the current pool
			let tick = jackpotPoolRef.getOriginalTick()
			if tick != ""{ 
				self.current <- FRC20FTShared.createEmptyChange(tick: tick, from: jackpotPoolRef.from)
			} else{ 
				self.current <- FRC20FTShared.createEmptyFlowChange(from: jackpotPoolRef.from)
			}
		}
		
		/// @deprecated after Cadence 1.0
		/** ---- Public Methods ---- */
		/// Lottery info - public view
		///
		access(all)
		view fun getInfo(): LotteryBasicInfo{ 
			return LotteryBasicInfo(epochIndex: self.epochIndex, epochStartAt: self.epochStartAt, status: self.getStatus(), disbursing: self.isDisbursing(), currentPool: self.getCurrentLotteryBalance(), participantsAmt: self.getParticipantAmount())
		}
		
		/// Get the lottery status
		///
		access(all)
		view fun getStatus(): LotteryStatus{ 
			let now = getCurrentBlock().timestamp
			let poolRef = self.borrowLotteryPool()
			let interval = poolRef.getEpochInterval()
			let epochCloseTime = self.epochStartAt + interval
			if now < epochCloseTime{ 
				return LotteryStatus.ACTIVE
			} else if self.drawnResult == nil{ 
				return LotteryStatus.READY_TO_DRAW
			} else if self.checkingQueue == nil || (self.checkingQueue!).length > 0{ 
				return LotteryStatus.DRAWN
			} else{ 
				return LotteryStatus.DRAWN_AND_VERIFIED
			}
		}
		
		/// Lotter result
		///
		access(all)
		view fun getResult(): LotteryResult?{ 
			return self.drawnResult
		}
		
		/// Return the participant addresses
		///
		access(all)
		view fun getParticipants(): [Address]{ 
			return self.participants.keys
		}
		
		/// Return the participant amount
		///
		access(all)
		view fun getParticipantAmount(): UInt64{ 
			return UInt64(self.participants.keys.length)
		}
		
		/// Get the total bought balance
		///
		access(all)
		view fun getCurrentLotteryBalance(): UFix64{ 
			return self.current.getBalance()
		}
		
		/// Check if the lottery is disbursing prizes
		///
		access(all)
		view fun isDisbursing(): Bool{ 
			let status = self.getStatus()
			return status == LotteryStatus.DRAWN_AND_VERIFIED && self.disbursingQueque.length > 0
		}
		
		/** ---- Contract level Methods ----- */
		/// Create a new ticket and add it to user's collection
		///
		access(contract)
		fun buyNewTicket(payment: @FRC20FTShared.Change, recipient: Capability<&TicketCollection>, powerup: UFix64?) // default is 1.0, you can increase the powerup to increase the winning amount																													
																													: UInt64{ 
			pre{ 
				self.getStatus() == LotteryStatus.ACTIVE:
					"The lottery is not active"
			}
			
			// deposit the payment to the total bought
			FRC20FTShared.depositToChange(receiver: self.borrowCurrentLotteryChange(), change: <-payment)
			
			// Create a new ticket
			let collection = recipient.borrow() ?? panic("Recipient not found")
			let ticket <- create TicketEntry(pool: self.borrowLotteryPool().getAddress(), lotteryId: self.epochIndex, powerup: powerup, numbers: nil)
			let ticketId = ticket.getTicketId()
			// Add the ticket to the collection
			collection.addTicket(<-ticket)
			
			// Add the ticket to the participants
			if self.participants[recipient.address] == nil{ 
				self.participants[recipient.address] = [ticketId]
			} else{ 
				self.participants[recipient.address]?.append(ticketId)
			}
			return ticketId
		}
		
		/// Generate random number to draw the lottery
		///
		access(contract)
		fun drawLottery(){ 
			// Only execute the method if the lottery is ready to draw
			if self.getStatus() != LotteryStatus.READY_TO_DRAW{ 
				return
			}
			// borrow the lottery pool
			let pool = self.borrowLotteryPool()
			
			// Generate the random numbers
			let lotteryNumbers = FGameLottery.createRandomTicketNumber()
			let jackpotAmount = pool.getJackpotPoolBalance()
			let participantAmount = self.getParticipantAmount()
			let totalBought = self.current.getBalance()
			self.drawnResult = LotteryResult(numbers: lotteryNumbers, totalBought: totalBought, jackpotAmount: jackpotAmount)
			// set the verifying progress to 1.0 if there is no participant
			if participantAmount == 0{ 
				(self.drawnResult!).setVerifyingProgress(1.0)
				(self.drawnResult!).setDisbursingProgress(1.0)
			}
			self.checkingQueue = self.participants.keys
			
			// emit event
			emit LotteryDrawn(poolAddr: pool.getAddress(), lotteryId: self.epochIndex, numbers: lotteryNumbers.getNumbers(), participantAmount: participantAmount, totalBought: totalBought, jackpotAmount: jackpotAmount)
		}
		
		/// Claim the winning amount
		///
		access(contract)
		fun verifyParticipantsTickets(_ maxEntries: Int){ 
			// This method is used to verify the participants' tickets
			// only execute the method if the lottery is drawn and the checking queue is not empty
			if self.getStatus() != LotteryStatus.DRAWN{ 
				return
			}
			if self.checkingQueue == nil || (self.checkingQueue!).length == 0{ 
				return
			}
			if self.drawnResult == nil{ 
				return
			}
			
			// borrow the lottery pool
			let pool = self.borrowLotteryPool()
			
			// variables
			let participants: [Address] = []
			var winnersCnt: UInt64 = 0
			var nonJackpotAmount = 0.0
			// get the checking addresses
			var i = 0
			while i < maxEntries && (self.checkingQueue!).length > 0{ 
				// remove the first address from the queue
				let addr = (self.checkingQueue!).removeFirst()
				participants.append(addr)
				// user collection
				let userColCap = FGameLottery.getUserTicketCollection(addr)
				var checkedEntries = 1
				if let userColRef = userColCap.borrow(){ 
					// retrieve the participant tickets
					if let ticketsRef = &self.participants[addr] as &[UInt64]?{ 
						while ticketsRef.length > 0 && checkedEntries < maxEntries{ 
							let ticketId = ticketsRef.removeFirst()
							if let ticketRef = userColRef.borrowTicket(ticketId: ticketId){ 
								// verify the ticket
								ticketRef.onPrizeVerify()
								// if the ticket is a winner, update prize amount by rank
								if let prizeRank = ticketRef.getWinPrizeRank(){ 
									// update the winner count
									winnersCnt = winnersCnt + 1
									// add the winner to the result
									self.drawnResult?.addWinner(addr)
									// add the ticket to the disbursing queue
									self.disbursingQueque.append(TicketIdentifier(addr, ticketId))
									// update result data
									if prizeRank == PrizeRank.JACKPOT{ 
										self.drawnResult?.addJackpotWinner(addr)
										// emit event
										emit LotteryJackpotWinnerUpdated(poolAddr: pool.getAddress(), lotteryId: self.epochIndex, winner: addr)
									} else{ 
										let basePrize = pool.getWinnerPrizeByRank(prizeRank)
										let powerup = ticketRef.getPowerup()
										let prize = basePrize * powerup
										nonJackpotAmount = nonJackpotAmount + prize
										self.drawnResult?.incrementNonJackpotTotal(prizeRank, prize)
									}
								} // end if prizeRank
							
							} // end if ticketRef
							
							// one entry is checked
							checkedEntries = checkedEntries + 1
						}
						// if there are remaining tickets, add addr back to the queue
						if ticketsRef.length > 0{ 
							(self.checkingQueue!).append(addr)
						}
					}
				} // end if userColRef
				
				i = i + checkedEntries
			}
			
			// update the distribution progress
			let totalParticipants = self.getParticipantAmount()
			let remainingUnChecked = UInt64((self.checkingQueue!).length)
			let progress = UFix64(totalParticipants - remainingUnChecked) / UFix64(totalParticipants)
			self.drawnResult?.setVerifyingProgress(progress)
			
			// emit event
			emit LotteryParticipantsVerified(poolAddr: pool.getAddress(), lotteryId: self.epochIndex, participants: participants, winners: winnersCnt, nonJackpotTotal: nonJackpotAmount)
			
			// if the checking queue is empty, finalize the jackpot
			if remainingUnChecked == 0{ 
				let nonJackpotTotal = self.drawnResult?.nonJackpotTotal ?? 0.0
				let totalBought = self.drawnResult?.totalBought ?? 0.0
				let jackpotRef = pool.borrowJackpotPool()
				let oldJackpotAmount = jackpotRef.getBalance()
				// min new jackpot amount is 50% of the total bought
				let minNewJackpotAmount = totalBought * 0.5
				var ratio = 1.0
				var newJackpotAmount = 0.0
				if minNewJackpotAmount >= nonJackpotTotal || totalBought >= nonJackpotTotal && oldJackpotAmount + totalBought - nonJackpotTotal >= minNewJackpotAmount{ 
					// no need to downgrade the non-jackpot prize
					let restAmount = totalBought - nonJackpotTotal
					newJackpotAmount = oldJackpotAmount + restAmount
					// finalize the jackpot
					self.drawnResult?.updateJackpot(newJackpotAmount)
					
					// deposit the new added amount to the jackpot pool
					FRC20FTShared.depositToChange(receiver: jackpotRef, change: <-self.current.withdrawAsChange(amount: restAmount))
				// all remaining non-jackpot prize will be added to the jackpot
				} else if totalBought < nonJackpotTotal && oldJackpotAmount + totalBought - nonJackpotTotal >= minNewJackpotAmount{ 
					// withdraw from the jackpot pool to cover the non-jackpot prize
					let requiredAmount = nonJackpotTotal - totalBought
					let newJackpotAmount = oldJackpotAmount - requiredAmount
					// finalize the jackpot
					self.drawnResult?.updateJackpot(newJackpotAmount)
					
					// withdraw the required amount from the jackpot pool
					let change <- jackpotRef.withdrawAsChange(amount: requiredAmount)
					// deposit the required amount to the total bought
					FRC20FTShared.depositToChange(receiver: self.borrowCurrentLotteryChange(), change: <-change)
				} else{ 
					// ensure the jackpot amount is at least 50% of the total bought
					if minNewJackpotAmount > oldJackpotAmount{ 
						let jackpotRequired = minNewJackpotAmount - oldJackpotAmount
						// withdraw the required amount from the current pool to ensure the jackpot
						let change <- self.current.withdrawAsChange(amount: jackpotRequired)
						// deposit the required amount to the jackpot pool
						FRC20FTShared.depositToChange(receiver: jackpotRef, change: <-change)
					} else if minNewJackpotAmount < oldJackpotAmount{ 
						let jackpotRest = oldJackpotAmount - minNewJackpotAmount
						// withdraw the rest amount from the jackpot pool
						let change <- jackpotRef.withdrawAsChange(amount: jackpotRest)
						// deposit the rest amount to the current pool
						FRC20FTShared.depositToChange(receiver: self.borrowCurrentLotteryChange(), change: <-change)
					}
					newJackpotAmount = minNewJackpotAmount
					// finalize the jackpot, the new jackpot amount is the min new jackpot amount
					self.drawnResult?.updateJackpot(minNewJackpotAmount)
					
					// calculate the non-jackpot downgrade ratio
					if nonJackpotTotal > 0.0{ 
						let currentPoolBalance = self.current.getBalance()
						ratio = currentPoolBalance / nonJackpotTotal
						// finalize the non-jackpot prize
						self.drawnResult?.setNonJackpotDowngradeRatio(ratio)
					}
				}
				
				// emit event
				emit LotteryJackpotFinialized(poolAddr: pool.getAddress(), lotteryId: self.epochIndex, jackpotAmount: newJackpotAmount, nonJackpotTotal: nonJackpotTotal, nonJackpotDowngradeRatio: ratio)
			}
		}
		
		/// Disburse the prizes to the winners
		///
		access(contract)
		fun disbursePrizes(_ maxEntries: Int){ 
			// This method is used to disburse the prizes to the winners
			if !self.isDisbursing(){ 
				return
			}
			
			// variables
			var i = 0
			while i < maxEntries && self.disbursingQueque.length > 0{ 
				let ticketIdentifier = self.disbursingQueque.removeFirst()
				if let ticketRef = ticketIdentifier.borrowTicket(){ 
					self._disbursePrize(ticket: ticketRef)
				}
				i = i + 1
			}
			
			// update the disbursing progress
			let totalWinners = self.drawnResult?.winners?.keys?.length ?? 0
			let remainingWinners = self.disbursingQueque.length
			if totalWinners > 0{ 
				let progress = UFix64(totalWinners - remainingWinners) / UFix64(totalWinners)
				self.drawnResult?.setDisbursingProgress(progress)
			}
			
			// emit event
			if self.disbursingQueque.length == 0{ 
				let pool = self.borrowLotteryPool()
				emit LotteryPrizesDisbursed(poolAddr: pool.getAddress(), lotteryId: self.epochIndex)
			}
		}
		
		/** ---- Internal Methods ----- */
		/// Disburse the prize to the winners
		///
		access(self)
		fun _disbursePrize(ticket: &TicketEntry){ 
			// Only status is DRAWN_AND_VERIFIED and the ticket status is WIN can withdraw the prize
			if self.getStatus() != LotteryStatus.DRAWN_AND_VERIFIED{ 
				return
			}
			let ticketStatus = ticket.getStatus()
			if ticketStatus != TicketStatus.WIN{ 
				return
			}
			let prizeRank = ticket.getWinPrizeRank()
			if prizeRank == nil{ 
				return
			}
			// Borrow the FRC20 indexer
			let frc20Indexer = FRC20Indexer.getIndexer()
			// Borrow the lottery pool
			let pool = self.borrowLotteryPool()
			
			// Disburse the prize to the ticket owner
			let ticketOwner = ticket.getTicketOwner()
			
			// Initialize the reward change
			let rewardChange <- FRC20FTShared.createEmptyChange(tick: self.current.getOriginalTick(), from: ticketOwner)
			// ref to the reward change
			let rewardChangeRef = &rewardChange as &FRC20FTShared.Change
			// Initialize the fee change
			let feeChange: @FRC20FTShared.Change <- FRC20FTShared.createEmptyChange(tick: self.current.getOriginalTick(), from: pool.getAddress())
			let feeChangeRef = &feeChange as &FRC20FTShared.Change
			// Get the fee ratio of the pool
			let feeRatio = pool.getServiceFee()
			
			// Get the prize amount
			if prizeRank! == PrizeRank.JACKPOT{ 
				// Disburse the jackpot prize
				let jackpotPoolRef = pool.borrowJackpotPool()
				let winners = (self.drawnResult!).jackpotWinners
				if winners == nil || (winners!).length == 0 || !(winners!).contains(ticketOwner){ 
					destroy rewardChange
					destroy feeChange
					return
				}
				let jackpotAmount = (self.drawnResult!).jackpotAmount
				let jackpotWinnerAmt = winners?.length!
				let withdrawAmount = jackpotAmount / UFix64(jackpotWinnerAmt)
				if jackpotPoolRef.getBalance() < withdrawAmount{ 
					destroy rewardChange
					destroy feeChange
					return
				}
				let prizeChange <- jackpotPoolRef.withdrawAsChange(amount: withdrawAmount)
				
				// 16% (default) of prize will be charged as the service fee
				let serviceFee = prizeChange.getBalance() * feeRatio
				FRC20FTShared.depositToChange(receiver: feeChangeRef, change: <-prizeChange.withdrawAsChange(amount: serviceFee))
				
				// Deposit the prize to the ticket owner
				FRC20FTShared.depositToChange(receiver: rewardChangeRef, change: <-prizeChange)
			} else{ 
				// Get the base prize amount
				let basePrize = pool.getWinnerPrizeByRank(prizeRank!)
				
				// Disburse the prize amount
				let prizeAmountWithPowerup = basePrize * ticket.getPowerup()
				let prizeDowngradeRatio = (self.drawnResult!).nonJackpotDowngradeRatio
				let prizeChange <- self.current.withdrawAsChange(amount: prizeAmountWithPowerup * prizeDowngradeRatio)
				
				// if PrizeRank is 3rd or higher, 16% of prize will be charged as the service fee
				// if PrizeRank is lower than 3rd, no service fee will be charged
				if (prizeRank!).rawValue <= PrizeRank.THIRD.rawValue{ 
					let serviceFee = prizeChange.getBalance() * feeRatio
					FRC20FTShared.depositToChange(receiver: feeChangeRef, change: <-prizeChange.withdrawAsChange(amount: serviceFee))
				}
				
				// Deposit the prize to the ticket owner
				FRC20FTShared.depositToChange(receiver: rewardChangeRef, change: <-prizeChange)
			}
			
			// deposit the fee to the service pools
			if feeChange.getBalance() > 0.0{ 
				let feeTickName = feeChange.getOriginalTick()
				let totalFeeAmount = feeChange.getBalance()
				// Borrow the FRC20 accounts pool
				let acctsPool: &FRC20AccountsPool.Pool = FRC20AccountsPool.borrowAccountsPool()
				let globalSharedStore = FRC20FTShared.borrowGlobalStoreRef()
				let stakingFRC20Tick = globalSharedStore.getByEnum(FRC20FTShared.ConfigType.PlatofrmMarketplaceStakingToken) as! String? ?? "flows"
				if feeTickName == ""{ 
					// this is $FLOW token
					let serviceFee = totalFeeAmount * 0.5
					// 50% of service fee will be deposited to the platform pool
					let serviceFeeVault <- feeChange.withdrawAsVault(amount: serviceFee)
					let frc20Indexer = FRC20Indexer.getIndexer()
					let platformFlowRecipient = frc20Indexer.borowPlatformTreasuryReceiver()
					platformFlowRecipient.deposit(from: <-serviceFeeVault)
					// 50% of service fee will be deposited to the shared pool
					let sharedFeeVault <- feeChange.extractAsVault()
					if let flowsStakingRecipient = acctsPool.borrowFRC20StakingFlowTokenReceiver(tick: stakingFRC20Tick){ 
						flowsStakingRecipient.deposit(from: <-sharedFeeVault)
					} else{ 
						platformFlowRecipient.deposit(from: <-sharedFeeVault)
					}
				} else{ 
					// Here is FRC20 token, all service fee will be deposited to the Staking shared pool
					if let stakingAddress = acctsPool.getFRC20StakingAddress(tick: stakingFRC20Tick){ 
						if let stakingPool = FRC20Staking.borrowPool(stakingAddress){ 
							if let rewardStrategy = stakingPool.borrowRewardStrategy(feeTickName){ 
								// Donate the tokens
								rewardStrategy.addIncome(income: <-feeChange.withdrawAsChange(amount: totalFeeAmount))
							}
						}
					}
					if feeChange.getBalance() > 0.0{ 
						// return to lottery pool address
						frc20Indexer.returnChange(change: <-feeChange.withdrawAsChange(amount: totalFeeAmount))
					}
				}
			}
			// zero balance destroy
			destroy feeChange
			
			// Get the prize amount
			let prizeAmount = rewardChange.getBalance()
			// deposit the prize to the ticket owner
			frc20Indexer.returnChange(change: <-rewardChange)
			
			// Update the ticket status to WIN_DISBURSED and emit event
			ticket.onPrizeDisburse(prizeAmount)
		}
		
		access(self)
		fun borrowCurrentLotteryChange(): &FRC20FTShared.Change{ 
			return &self.current as &FRC20FTShared.Change
		}
		
		access(self)
		view fun borrowLotteryPool(): &LotteryPool{ 
			let ownerAddr = self.owner?.address ?? panic("Owner is missing")
			let ref = FGameLottery.borrowLotteryPool(ownerAddr) ?? panic("Lottery pool not found")
			return ref.borrowSelf()
		}
	}
	
	access(all)
	resource interface LotteryPoolPublic{ 
		// --- read methods ---
		access(all)
		view fun getName(): String
		
		access(all)
		view fun getAddress(): Address
		
		access(all)
		view fun getCurrentEpochIndex(): UInt64
		
		access(all)
		view fun getEpochInterval(): UFix64
		
		access(all)
		view fun getLotteryToken(): String
		
		access(all)
		view fun getTicketPrice(): UFix64
		
		access(all)
		view fun getJackpotPoolBalance(): UFix64
		
		access(all)
		view fun getServiceFee(): UFix64
		
		access(all)
		view fun isEpochAutoStart(): Bool
		
		access(all)
		view fun getWinnerPrizeByRank(_ rank: PrizeRank): UFix64
		
		// --- read methods: default implement ---
		/// Check if the current lottery is active
		access(all)
		view fun isCurrentLotteryActive(): Bool{ 
			let currentLotteryRef = self.borrowCurrentLottery()
			return currentLotteryRef != nil
			&& (currentLotteryRef!).getStatus() == LotteryStatus.ACTIVE
		}
		
		/// Check if the current lottery is ready to draw
		access(all)
		view fun isCurrentLotteryReadyToDraw(): Bool{ 
			let currentLotteryRef = self.borrowCurrentLottery()
			let status = currentLotteryRef?.getStatus()
			return currentLotteryRef != nil && status == LotteryStatus.READY_TO_DRAW
		}
		
		/// Check if the current lottery is finished
		access(all)
		view fun isCurrentLotteryFinished(): Bool{ 
			let currentLotteryRef = self.borrowCurrentLottery()
			let status = currentLotteryRef?.getStatus()
			return currentLotteryRef == nil || status == LotteryStatus.DRAWN
			|| status == LotteryStatus.DRAWN_AND_VERIFIED
		}
		
		// --- write methods ---
		/// Buy lottery tickets
		access(all)
		fun buyTickets(
			payment: @FRC20FTShared.Change,
			amount: UInt64,
			powerup: UFix64?,
			recipient: Capability<&TicketCollection>
		)
		
		/// Donate to the jackpot pool
		access(all)
		fun donateToJackpot(payment: @FRC20FTShared.Change)
		
		// --- borrow methods ---
		access(all)
		view fun borrowLottery(_ epochIndex: UInt64): &Lottery?
		
		access(all)
		view fun borrowCurrentLottery(): &Lottery?
		
		// Internal usage
		access(contract)
		view fun borrowSelf(): &LotteryPool
	}
	
	access(all)
	resource interface LotteryPoolAdmin{ 
		// --- write methods ---
		access(all)
		fun startNewEpoch()
	}
	
	/// Lottery pool resource
	///
	access(all)
	resource LotteryPool: LotteryPoolPublic, LotteryPoolAdmin, FixesHeartbeat.IHeartbeatHook{ 
		/// Lottery pool constants
		access(all)
		let name: String
		
		access(self)
		let initEpochInterval: UFix64
		
		access(self)
		let initTicketPrice: UFix64
		
		// Lottery pool variables
		access(self)
		let jackpotPool: @FRC20FTShared.Change
		
		access(self)
		let lotteries: @{UInt64: Lottery}
		
		access(self)
		var currentEpochIndex: UInt64
		
		access(self)
		var finishedEpoches: [UInt64]
		
		access(self)
		var lastSealedEpochIndex: UInt64?
		
		init(name: String, rewardTick: String, ticketPrice: UFix64, epochInterval: UFix64){ 
			pre{ 
				ticketPrice > 0.0:
					"Ticket price must be greater than 0"
				epochInterval > 0.0:
					"Epoch interval must be greater than 0"
			}
			self.name = name
			let accountAddr = FGameLottery.account.address
			if rewardTick != ""{ 
				self.jackpotPool <- FRC20FTShared.createEmptyChange(tick: rewardTick, from: accountAddr)
			} else{ 
				self.jackpotPool <- FRC20FTShared.createEmptyFlowChange(from: accountAddr)
			}
			self.initTicketPrice = ticketPrice
			self.initEpochInterval = epochInterval
			self.currentEpochIndex = 0
			self.finishedEpoches = []
			self.lastSealedEpochIndex = nil
			self.lotteries <-{} 
		}
		
		/// @deprecated after Cadence 1.0
		/** ---- Public Methods ---- */
		access(all)
		view fun getName(): String{ 
			return self.name
		}
		
		access(all)
		view fun getAddress(): Address{ 
			return self.owner?.address ?? panic("Owner is missing")
		}
		
		access(all)
		view fun getCurrentEpochIndex(): UInt64{ 
			return self.currentEpochIndex
		}
		
		access(all)
		view fun getEpochInterval(): UFix64{ 
			let store = self.borrowConfigStore()
			let interval = store.getByEnum(FRC20FTShared.ConfigType.GameLotteryEpochInterval) as! UFix64?
			return interval ?? self.initEpochInterval
		}
		
		access(all)
		view fun getTicketPrice(): UFix64{ 
			let store = self.borrowConfigStore()
			let price = store.getByEnum(FRC20FTShared.ConfigType.GameLotteryTicketPrice) as! UFix64?
			return price ?? self.initTicketPrice
		}
		
		access(all)
		view fun getServiceFee(): UFix64{ 
			let store = self.borrowConfigStore()
			let fee = store.getByEnum(FRC20FTShared.ConfigType.GameLotteryServiceFee) as! UFix64?
			return fee ?? 0.16
		}
		
		access(all)
		view fun isEpochAutoStart(): Bool{ 
			let store = self.borrowConfigStore()
			let autoStart = store.getByEnum(FRC20FTShared.ConfigType.GameLotteryAutoStart) as! Bool?
			return autoStart ?? true
		}
		
		access(all)
		view fun getLotteryToken(): String{ 
			return self.jackpotPool.getOriginalTick()
		}
		
		access(all)
		view fun getJackpotPoolBalance(): UFix64{ 
			return self.jackpotPool.getBalance()
		}
		
		access(all)
		view fun getWinnerPrizeByRank(_ rank: PrizeRank): UFix64{ 
			// Get the ticket price
			let ticketPrice = self.getTicketPrice()
			// Calculate the winner prize
			var prize: UFix64 = 0.0
			switch rank{ 
				case PrizeRank.JACKPOT:
					prize = self.jackpotPool.getBalance()
					break
				case PrizeRank.SECOND:
					prize = ticketPrice * 50000.0
					break
				case PrizeRank.THIRD:
					prize = ticketPrice * 5000.0
					break
				case PrizeRank.FOURTH:
					prize = ticketPrice * 25.0
					break
				case PrizeRank.FIFTH:
					prize = ticketPrice * 4.0
					break
				case PrizeRank.SIXTH:
					prize = ticketPrice * 2.0
					break
			}
			return prize
		}
		
		access(all)
		view fun borrowLottery(_ epochIndex: UInt64): &Lottery?{ 
			return self.borrowLotteryRef(epochIndex)
		}
		
		access(all)
		view fun borrowCurrentLottery(): &Lottery?{ 
			return self.borrowLotteryRef(self.currentEpochIndex)
		}
		
		/** ---- Public Methods: write ----- */
		/// Buy lottery tickets
		access(all)
		fun buyTickets(payment: @FRC20FTShared.Change, amount: UInt64, powerup: UFix64?, recipient: Capability<&TicketCollection>){ 
			pre{ 
				amount > 0:
					"Amount must be greater than 0"
				payment.getOriginalTick() == self.jackpotPool.getOriginalTick():
					"Invalid payment token"
				self.isCurrentLotteryActive():
					"The current lottery is not active"
			}
			
			// Ensure the payment is enough
			let price = self.getTicketPrice()
			let oneTicketCost = price * (powerup ?? 1.0)
			let totalCost = oneTicketCost * UFix64(amount)
			assert(payment.getBalance() == totalCost, message: "Payment balance should be equal to the total cost")
			
			// Get the current lottery
			let lotteryRef = self.borrowLotteryRef(self.currentEpochIndex) ?? panic("Lottery not found")
			
			// Create tickets
			let purchasedIds: [UInt64] = []
			var i: UInt64 = 0
			while i < amount{ 
				// Withdraw the payment
				let one <- payment.withdrawAsChange(amount: oneTicketCost)
				// Create a new ticket
				let newTicketId = lotteryRef.buyNewTicket(payment: <-one, recipient: recipient, powerup: powerup)
				purchasedIds.append(newTicketId)
				i = i + 1
			}
			assert(payment.getBalance() == 0.0, message: "The payment balance should be 0 after the purchase")
			destroy payment
			
			// emit event
			emit TicketPurchased(poolAddr: self.getAddress(), lotteryId: self.currentEpochIndex, address: recipient.address, ticketIds: purchasedIds, costTick: self.jackpotPool.getOriginalTick(), costAmount: totalCost)
		}
		
		/// Donate to the jackpot pool
		///
		access(all)
		fun donateToJackpot(payment: @FRC20FTShared.Change){ 
			pre{ 
				payment.getOriginalTick() == self.jackpotPool.getOriginalTick():
					"Invalid payment token"
				payment.getBalance() > 0.0:
					"Payment balance must be greater than 0"
			}
			let jackpotRef = self.borrowJackpotPool()
			let donatableAmount = payment.getBalance()
			
			// deposit the new added amount to the jackpot pool
			FRC20FTShared.depositToChange(receiver: jackpotRef, change: <-payment)
			emit LotteryJackpotDonated(poolAddr: self.getAddress(), donationAmount: donatableAmount)
		}
		
		/** ---- Admin Methods ----- */
		/// Start a new epoch
		///
		access(all)
		fun startNewEpoch(){ 
			pre{ 
				self.isCurrentLotteryFinished():
					"The current lottery is not finished"
			}
			
			// Create a new lottery
			let newEpochIndex = self.currentEpochIndex + 1
			let newLottery <- create Lottery(epochIndex: newEpochIndex, jackpotPoolRef: self.borrowJackpotPool())
			let startedAt = newLottery.epochStartAt
			
			// Save the new lottery
			self.lotteries[newEpochIndex] <-! newLottery
			self.currentEpochIndex = newEpochIndex
			
			// emit event
			emit LotteryStarted(poolAddr: self.getAddress(), lotteryId: newEpochIndex, startTime: startedAt)
		}
		
		/** ---- Heartbeat Implementation Methods ----- */
		/// The methods that is invoked when the heartbeat is executed
		/// Before try-catch is deployed, please ensure that there will be no panic inside the method.
		///
		access(account)
		fun onHeartbeat(_ deltaTime: UFix64){ 
			// Step 0. Handle the current lottery
			
			// Active or ready to draw is one step
			if self.isCurrentLotteryActive(){}												// DO NOTHING if the current lottery is active
												else if self.isCurrentLotteryReadyToDraw(){ 
				// Draw the current lottery if it is ready
				let lotteryRef = self.borrowLotteryRef(self.currentEpochIndex)!
				// draw the lottery
				lotteryRef.drawLottery()
				// append the current epoch index to the finished epoches
				self.finishedEpoches.append(self.currentEpochIndex)
			}
			// Check if the current lottery is finished, and start a new epoch if the auto start is enabled
			// This is the second step, because the current lottery may be finished after the draw
			if self.isCurrentLotteryFinished(){ 
				// if the current lottery is finished
				// Start a new epoch if the auto start is enabled
				if self.isEpochAutoStart(){ 
					self.startNewEpoch()
				}
			}
			
			// Step 1. Handle the finished epoches
			if self.finishedEpoches.length > 0{ 
				let firstFinsihedEpochIndex = self.finishedEpoches[0]
				let lotteryRef = self.borrowLotteryRef(firstFinsihedEpochIndex)!
				
				// max entries to compute in one heartbeat
				let heartbeatComputeEntries = 200
				
				// verify the participants' tickets
				var status = lotteryRef.getStatus()
				// we need to verify the participants' tickets if the lottery is drawn
				if status == LotteryStatus.DRAWN{ 
					// verify the participants' tickets
					lotteryRef.verifyParticipantsTickets(heartbeatComputeEntries)
				} else if status == LotteryStatus.DRAWN_AND_VERIFIED && lotteryRef.isDisbursing(){ 
					// disburse the prizes to the winners
					lotteryRef.disbursePrizes(heartbeatComputeEntries)
				}
				
				// check if the lottery is finished
				status = lotteryRef.getStatus()
				if status == LotteryStatus.DRAWN_AND_VERIFIED && !lotteryRef.isDisbursing(){ 
					// remove the first finished epoch index and set the last sealed epoch index
					self.lastSealedEpochIndex = self.finishedEpoches.removeFirst()
				}
			}
		}
		
		// --- Internal Methods ---
		access(contract)
		view fun borrowSelf(): &LotteryPool{ 
			return &self as &LotteryPool
		}
		
		access(contract)
		fun borrowJackpotPool(): &FRC20FTShared.Change{ 
			return &self.jackpotPool as &FRC20FTShared.Change
		}
		
		access(self)
		view fun borrowConfigStore(): &FRC20FTShared.SharedStore{ 
			return FRC20FTShared.borrowStoreRef((self.owner!).address) ?? panic("Config store not found")
		}
		
		access(self)
		view fun borrowLotteryRef(_ epochIndex: UInt64): &Lottery?{ 
			return &self.lotteries[epochIndex] as &Lottery?
		}
	}
	
	/* --- Account Access Methods --- */
	/// Create a new lottery pool
	///
	access(account)
	fun createLotteryPool(
		name: String,
		rewardTick: String,
		ticketPrice: UFix64,
		epochInterval: UFix64
	): @LotteryPool{ 
		return <-create LotteryPool(
			name: name,
			rewardTick: rewardTick,
			ticketPrice: ticketPrice,
			epochInterval: epochInterval
		)
	}
	
	/* --- Public methods  --- */
	/// Create a ticket collection
	///
	access(all)
	fun createTicketCollection(): @TicketCollection{ 
		return <-create TicketCollection()
	}
	
	/// Get the user's ticket collection capability
	///
	access(all)
	fun getUserTicketCollection(_ addr: Address): Capability<&TicketCollection>{ 
		return getAccount(addr).capabilities.get<&TicketCollection>(self.userCollectionPublicPath)!
	}
	
	/// Borrow Lottery Pool
	///
	access(all)
	view fun borrowLotteryPool(_ addr: Address): &LotteryPool?{ 
		return getAccount(addr).capabilities.get<&LotteryPool>(FGameLottery.lotteryPoolPublicPath)
			.borrow()
	}
	
	init(){ 
		// Set the maximum white and red numbers
		self.MAX_WHITE_NUMBER = 33
		self.MAX_RED_NUMBER = 16
		
		// Identifiers
		let identifier = "FGameLottery_".concat(self.account.address.toString())
		self.userCollectionStoragePath = StoragePath(
				identifier: identifier.concat("_UserCollection")
			)!
		self.userCollectionPublicPath = PublicPath(
				identifier: identifier.concat("_UserCollection")
			)!
		self.lotteryPoolStoragePath = StoragePath(identifier: identifier.concat("_LotteryPool"))!
		self.lotteryPoolPublicPath = PublicPath(identifier: identifier.concat("_LotteryPool"))!
		
		// Emit the ContractInitialized event
		emit ContractInitialized()
	}
}
