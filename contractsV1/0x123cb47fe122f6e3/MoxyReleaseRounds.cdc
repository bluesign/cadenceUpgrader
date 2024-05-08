import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import LockedMoxyToken from "./LockedMoxyToken.cdc"

import LockedMoxyVaultToken from "./LockedMoxyVaultToken.cdc"

import MoxyToken from "./MoxyToken.cdc"

import MoxyVaultToken from "./MoxyVaultToken.cdc"

import LinearRelease from "./LinearRelease.cdc"

import MoxyProcessQueue from "./MoxyProcessQueue.cdc"

import MoxyData from "./MoxyData.cdc"

access(all)
contract MoxyReleaseRounds{ 
	access(all)
	event RoundAdded(name: String)
	
	access(all)
	event AccountAddedToRound(round: String, address: Address, amount: UFix64)
	
	access(all)
	event MOXYLockedTokensReleasedTo(round: String, address: Address, amount: UFix64)
	
	// Unlock tokens events
	access(all)
	event UnlockedMOXYTokenForLinearReleases(address: Address, amount: UFix64)
	
	access(all)
	event UnlockedMVTokenForLinearReleases(address: Address, amount: UFix64)
	
	// Rounds user consent to participate on rounds releases
	access(all)
	event AccountAlreadyAcceptedRoundParticipation(address: Address, timestamp: UFix64)
	
	access(all)
	event AccountAcceptedRoundsParticipation(address: Address, timestamp: UFix64)
	
	// Events for rounds allocation process
	access(all)
	event StartingAllocationDailyReleaseRounds(timestamp: UFix64, accountsToProcess: Int)
	
	access(all)
	event FinishingAllocationDailyReleaseRounds(timestamp: UFix64, accountsProcessed: Int)
	
	access(all)
	event NoAmountToAllocateInRoundRelease(roundId: String, address: Address, timestamp: UFix64)
	
	access(all)
	event RoundAllocationPerformed(
		roundId: String,
		address: Address,
		totalReleased: UFix64,
		timestamp: UFix64
	)
	
	access(all)
	struct ParticipantRoundInfo{ 
		access(all)
		let address: Address
		
		access(all)
		let roundId: String
		
		access(all)
		let amount: UFix64
		
		access(all)
		let amountReleased: UFix64
		
		init(address: Address, roundId: String, amount: UFix64, amountReleased: UFix64){ 
			self.address = address
			self.roundId = roundId
			self.amount = amount
			self.amountReleased = amountReleased
		}
	}
	
	access(all)
	struct RoundInfo{ 
		access(all)
		let id: String
		
		access(all)
		let type: String
		
		access(all)
		let name: String
		
		access(all)
		let initialRelease: UFix64
		
		access(all)
		let lockTime: Int
		
		access(all)
		let months: Int
		
		access(all)
		let tgeDate: UFix64
		
		access(all)
		let endDate: UFix64
		
		access(all)
		let totalIncorporated: UFix64
		
		access(all)
		let totalAllocated: UFix64
		
		access(all)
		let totalReleased: UFix64
		
		access(all)
		let unlockPercentageAtTGE: UFix64
		
		access(all)
		let unlockPercentageAfterLockTime: UFix64
		
		access(all)
		let isReleaseStarted: Bool
		
		access(all)
		let allocateBeforeTGE: Bool
		
		init(
			id: String,
			type: String,
			name: String,
			initialRelease: UFix64,
			lockTime: Int,
			months: Int,
			days: Int,
			tgeDate: UFix64,
			endDate: UFix64,
			totalIncorporated: UFix64,
			totalAllocated: UFix64,
			totalReleased: UFix64,
			unlockPercentageAtTGE: UFix64,
			unlockPercentageAfterLockTime: UFix64,
			isReleaseStarted: Bool,
			allocateBeforeTGE: Bool
		){ 
			self.id = id
			self.type = type
			self.name = name
			self.initialRelease = initialRelease
			self.lockTime = lockTime
			self.months = months
			self.tgeDate = tgeDate
			self.endDate = endDate
			self.totalIncorporated = totalIncorporated
			self.totalAllocated = totalAllocated
			self.totalReleased = totalReleased
			self.unlockPercentageAtTGE = unlockPercentageAtTGE
			self.unlockPercentageAfterLockTime = unlockPercentageAfterLockTime
			self.isReleaseStarted = isReleaseStarted
			self.allocateBeforeTGE = allocateBeforeTGE
		}
	}
	
	access(all)
	struct RoundReleaseInfo{ 
		access(all)
		var amount: UFix64
		
		// amountReleased is the total amount that is released in this round
		access(all)
		var amountReleased: UFix64
		
		// date of the last release performed
		access(all)
		var lastReleaseDate: UFix64
		
		init(amount: UFix64, amountReleased: UFix64, lastReleaseDate: UFix64){ 
			self.amount = amount
			self.amountReleased = amountReleased
			self.lastReleaseDate = lastReleaseDate
		}
	}
	
	access(all)
	resource RoundRelease{ 
		// amount is the total amount that the user will receive in this round
		access(all)
		var amount: UFix64
		
		access(all)
		var linearReleases: [LinearRelease.LinearSchedule]
		
		// amountReleased is the total amount that is released in this round
		access(all)
		var amountReleased: UFix64
		
		// date of the last release performed
		access(all)
		var lastReleaseDate: UFix64
		
		access(all)
		var isAmountAtTGEPaid: Bool
		
		access(all)
		var isAmountAfterLockPaid: Bool
		
		access(all)
		fun getRoundReleaseInfo(): RoundReleaseInfo{ 
			var i = 0
			while i < self.linearReleases.length{ 
				i = i + 1
			}
			return RoundReleaseInfo(
				amount: self.amount,
				amountReleased: self.amountReleased,
				lastReleaseDate: self.lastReleaseDate
			)
		}
		
		access(all)
		fun getAllocationRemaining(): UFix64{ 
			return self.amount - self.amountReleased
		}
		
		access(all)
		fun getTotalToAllocateNow(): UFix64{ 
			var total = 0.0
			var i = 0
			while i < self.linearReleases.length{ 
				total = total + self.linearReleases[i].getTotalToUnlock()
				i = i + 1
			}
			return total
		}
		
		access(all)
		fun payLinearReleases(): UFix64{ 
			var total = 0.0
			var i = 0
			while i < self.linearReleases.length{ 
				total = total + self.linearReleases[i].getTotalToUnlock()
				self.linearReleases[i].updateLastReleaseDate()
				i = i + 1
			}
			self.amountReleased = self.amountReleased + total
			self.lastReleaseDate = getCurrentBlock().timestamp
			return total
		}
		
		access(all)
		fun addLinearRelease(linearRelease: LinearRelease.LinearSchedule){ 
			self.linearReleases.append(linearRelease)
		}
		
		access(all)
		fun getAmount(): UFix64{ 
			return self.amount
		}
		
		access(all)
		fun increaseAmount(amount: UFix64){ 
			self.amount = self.amount + amount
		}
		
		access(all)
		fun mergeWith(amount: UFix64, linearRelease: LinearRelease.LinearSchedule){ 
			self.amount = self.amount + amount
			self.addLinearRelease(linearRelease: linearRelease)
		}
		
		access(all)
		fun setStartDate(timestamp: UFix64){ 
			self.lastReleaseDate = timestamp
			var i = 0
			while i < self.linearReleases.length{ 
				self.linearReleases[i].setStartDate(timestamp: timestamp)
				i = i + 1
			}
		}
		
		access(all)
		fun getAmountAtTGEToPay(): UFix64{ 
			var total = 0.0
			var i = 0
			while i < self.linearReleases.length{ 
				total = total + self.linearReleases[i].getAmountAtTGEToPay()
				i = i + 1
			}
			return total
		}
		
		access(all)
		fun getAmountAtTGE(): UFix64{ 
			var total = 0.0
			var i = 0
			while i < self.linearReleases.length{ 
				total = total + self.linearReleases[i].getAmountAtTGE()
				i = i + 1
			}
			return total
		}
		
		access(all)
		fun getAmountAtTGEFor(amount: UFix64): UFix64{ 
			var total = 0.0
			var i = 0
			while i < self.linearReleases.length && total == 0.0{ 
				if self.linearReleases[i].totalAmount == amount{ 
					total = total + self.linearReleases[i].getAmountAtTGE()
				}
				i = i + 1
			}
			return total
		}
		
		access(all)
		fun getAmountAfterUnlockToPay(): UFix64{ 
			var total = 0.0
			var i = 0
			while i < self.linearReleases.length{ 
				total = total + self.linearReleases[i].getAmountAfterUnlockToPay()
				i = i + 1
			}
			return total
		}
		
		access(all)
		fun getAmountAfterUnlock(): UFix64{ 
			var total = 0.0
			var i = 0
			while i < self.linearReleases.length{ 
				total = total + self.linearReleases[i].getAmountAfterUnlock()
				i = i + 1
			}
			return total
		}
		
		access(all)
		fun getAmountAfterUnlockFor(amount: UFix64): UFix64{ 
			var total = 0.0
			var i = 0
			while i < self.linearReleases.length && total == 0.0{ 
				if self.linearReleases[i].totalAmount == amount{ 
					total = total + self.linearReleases[i].getAmountAfterUnlock()
				}
				i = i + 1
			}
			return total
		}
		
		access(all)
		fun getDailyAmountToPay(): UFix64{ 
			var total = 0.0
			var i = 0
			while i < self.linearReleases.length{ 
				total = total + self.linearReleases[i].getDailyAmountToPay()
				i = i + 1
			}
			return total
		}
		
		access(all)
		fun getDailyAmount(): UFix64{ 
			var total = 0.0
			var i = 0
			while i < self.linearReleases.length{ 
				total = total + self.linearReleases[i].getDailyAmount()
				i = i + 1
			}
			return total
		}
		
		access(all)
		fun getTotalDailyAmount(): UFix64{ 
			var total = 0.0
			var i = 0
			while i < self.linearReleases.length{ 
				total = total + self.linearReleases[i].getTotalDailyAmount()
				i = i + 1
			}
			return total
		}
		
		access(all)
		fun getTotalDailyAmountFor(amount: UFix64): UFix64{ 
			var total = 0.0
			var i = 0
			while i < self.linearReleases.length && total == 0.0{ 
				if self.linearReleases[i].totalAmount == amount{ 
					total = total + self.linearReleases[i].getTotalDailyAmount()
				}
				i = i + 1
			}
			return total
		}
		
		access(all)
		fun getFirstLinearRelease(): LinearRelease.LinearSchedule{ 
			return self.linearReleases.removeFirst()
		}
		
		init(amount: UFix64, linearRelease: LinearRelease.LinearSchedule){ 
			self.amount = amount
			self.lastReleaseDate = linearRelease.tgeDate
			self.linearReleases = [linearRelease]
			self.amountReleased = 0.0
			self.isAmountAtTGEPaid = false
			self.isAmountAfterLockPaid = false
		}
	}
	
	access(all)
	resource RoundReleases: RoundReleasesInfo{ 
		access(contract)
		let releases: @{String: RoundRelease}
		
		access(all)
		let lockedMOXYVault: Capability<&LockedMoxyToken.LockedVault>
		
		access(all)
		let lockedMVVault: Capability<&LockedMoxyVaultToken.LockedVault>
		
		access(all)
		fun setAddress(roundId: String, roundRelease: @RoundRelease){ 
			if self.releases[roundId] == nil{ 
				// Add to round
				self.releases[roundId] <-! roundRelease
			} else{ 
				// Update round adding the round release info increasing
				// amount for an address that already has a release round
				let amount = roundRelease.amount
				let linearRelease = roundRelease.getFirstLinearRelease()
				let release <- self.releases.remove(key: roundId)!
				release.mergeWith(amount: amount, linearRelease: linearRelease)
				let old <- self.releases[roundId] <- release
				destroy old
				destroy roundRelease
			}
		}
		
		access(all)
		fun setStartDate(timestamp: UFix64){ 
			for roundId in self.releases.keys{ 
				self.releases[roundId]?.setStartDate(timestamp: timestamp)!
			}
		}
		
		access(all)
		fun payLinearRelease(roundId: String): UFix64{ 
			let amount = self.releases[roundId]?.payLinearReleases()!
			return amount
		}
		
		// RoundReleases
		access(all)
		fun allocateDailyReleaseToNow(feeRemaining: UFix64): @{FungibleToken.Vault}{ 
			// Unlock MOXY tokens
			let lockedMOXYVault = self.lockedMOXYVault.borrow()!
			let moxyVault <- lockedMOXYVault.withdrawUnlocked()
			let address = (lockedMOXYVault.owner!).address
			let recipient = getAccount(address)
			let moxyVaultRef = recipient.capabilities.get<&{FungibleToken.Receiver}>(MoxyToken.moxyTokenReceiverPath).borrow<&{FungibleToken.Receiver}>() ?? panic("Could not borrow receiver reference to the recipient's Vault")
			let moxyAmount = moxyVault.balance
			var feeToDeduct = feeRemaining
			if feeToDeduct > moxyAmount{ 
				feeToDeduct = moxyAmount
			}
			let vaultFee <- moxyVault.withdraw(amount: feeToDeduct)
			moxyVaultRef.deposit(from: <-moxyVault)
			emit UnlockedMOXYTokenForLinearReleases(address: address, amount: moxyAmount)
			// Unlock MV tokens
			let lockedMVVault = self.lockedMVVault.borrow()!
			let mvVault <- lockedMVVault.withdrawUnlocked()
			let mvVaultRef = recipient.capabilities.get<&{MoxyVaultToken.ReceiverInterface}>(MoxyVaultToken.moxyVaultTokenReceiverTimestampPath).borrow<&{MoxyVaultToken.ReceiverInterface}>() ?? panic("Could not borrow receiver reference to the recipient's Vault")
			let mvAmount = mvVault.balance
			mvVaultRef.depositAmount(from: <-mvVault)
			emit UnlockedMOXYTokenForLinearReleases(address: address, amount: mvAmount)
			return <-vaultFee
		}
		
		access(all)
		fun getRoundReleaseInfo(roundId: String): RoundReleaseInfo{ 
			return self.releases[roundId]?.getRoundReleaseInfo()!
		}
		
		access(all)
		fun getAmountFor(roundId: String): UFix64{ 
			return self.releases[roundId]?.amount!
		}
		
		access(all)
		fun getAmountReleasedFor(roundId: String): UFix64{ 
			return self.releases[roundId]?.amountReleased!
		}
		
		access(all)
		fun getTotalToAllocateNowFor(roundId: String): UFix64{ 
			return self.releases[roundId]?.getTotalToAllocateNow()!
		}
		
		access(all)
		fun getAmountsDictFor(roundId: String, amount: UFix64):{ String: UFix64}{ 
			let amounts ={ "atTGE": self.releases[roundId]?.getAmountAtTGEFor(amount: amount)!, "afterUnlock": self.releases[roundId]?.getAmountAfterUnlockFor(amount: amount)!, "daily": self.releases[roundId]?.getTotalDailyAmountFor(amount: amount)!}
			return amounts
		}
		
		init(lockedMOXYVault: Capability<&LockedMoxyToken.LockedVault>, lockedMVVault: Capability<&LockedMoxyVaultToken.LockedVault>){ 
			self.releases <-{} 
			self.lockedMOXYVault = lockedMOXYVault
			self.lockedMVVault = lockedMVVault
		}
	}
	
	access(all)
	resource Round{ 
		access(all)
		let id: String
		
		access(all)
		let type: String
		
		access(all)
		let name: String
		
		access(all)
		let initialRelease: UFix64
		
		access(all)
		let lockTime: Int
		
		access(all)
		let months: Int
		
		access(all)
		var tgeDate: UFix64
		
		access(self)
		var accounts:{ Address: Capability<&RoundReleases>}
		
		access(all)
		var totalAllocated: UFix64
		
		access(all)
		var totalIncorporated: UFix64
		
		access(all)
		var totalReleased: UFix64
		
		access(all)
		var unlockPercentageAtTGE: UFix64
		
		access(all)
		var unlockPercentageAfterLockTime: UFix64
		
		access(all)
		var isReleaseStarted: Bool
		
		access(all)
		let allocateBeforeTGE: Bool
		
		access(all)
		var allocationQueue: @MoxyProcessQueue.Queue
		
		access(all)
		fun getRoundInfo(): RoundInfo{ 
			return RoundInfo(
				id: self.id,
				type: self.type,
				name: self.name,
				initialRelease: self.initialRelease,
				lockTime: self.lockTime,
				months: self.months,
				days: Int(self.getDays()),
				tgeDate: self.tgeDate,
				endDate: self.getEndDate(),
				totalIncorporated: self.totalIncorporated,
				totalAllocated: self.totalAllocated,
				totalReleased: self.totalReleased,
				unlockPercentageAtTGE: self.unlockPercentageAtTGE,
				unlockPercentageAfterLockTime: self.unlockPercentageAfterLockTime,
				isReleaseStarted: self.isReleaseStarted,
				allocateBeforeTGE: self.allocateBeforeTGE
			)
		}
		
		access(all)
		fun getRoundReleaseInfo(_ address: Address): RoundReleaseInfo?{ 
			if self.accounts[address] == nil{ 
				return nil
			}
			return ((self.accounts[address]!).borrow()!).getRoundReleaseInfo(roundId: self.id)
		}
		
		access(all)
		fun getAmountFor(address: Address): UFix64{ 
			if self.accounts[address] == nil{ 
				log("(amount) Address not found: ".concat(address.toString()).concat(" round: ").concat(self.id))
				return 0.0
			}
			return ((self.accounts[address]!).borrow()!).getAmountFor(roundId: self.id)
		}
		
		access(all)
		fun getAmountReleasedFor(address: Address): UFix64{ 
			if self.accounts[address] == nil{ 
				log("(amount released) Address not found: ".concat(address.toString()))
				return 0.0
			}
			return ((self.accounts[address]!).borrow()!).getAmountReleasedFor(roundId: self.id)
		}
		
		access(all)
		fun getTotalToAllocateNowFor(address: Address): UFix64{ 
			return ((self.accounts[address]!).borrow()!).getTotalToAllocateNowFor(roundId: self.id)
		}
		
		access(all)
		fun getAmountsDictFor(address: Address, amount: UFix64):{ String: UFix64}{ 
			return ((self.accounts[address]!).borrow()!).getAmountsDictFor(
				roundId: self.id,
				amount: amount
			)
		}
		
		access(all)
		fun getAccounts():{ Address: ParticipantRoundInfo}{ 
			let accounts:{ Address: ParticipantRoundInfo} ={} 
			for address in self.accounts.keys{ 
				let amount = self.getAmountFor(address: address)
				let amountReleased = self.getAmountReleasedFor(address: address)
				accounts[address] = ParticipantRoundInfo(address: address, roundId: self.id, amount: amount, amountReleased: amountReleased)
			}
			return accounts
		}
		
		access(all)
		fun getRoundAddresses(): [Address]{ 
			return self.accounts.keys
		}
		
		access(all)
		fun getAllocationRemaining(): UFix64{ 
			return self.initialRelease + self.totalIncorporated - self.totalAllocated
		}
		
		access(all)
		fun isReadyToStartRelease(): Bool{ 
			if self.allocateBeforeTGE == false{ 
				// Can start because is not required full allocation before TGE (i.e presale round)
				return true
			}
			return self.getAllocationRemaining() <= 0.0
		}
		
		access(all)
		fun isRoundStarted(): Bool{ 
			return self.isReleaseStarted
		}
		
		access(all)
		fun canAllocateAfterTGE(): Bool{ 
			return !self.allocateBeforeTGE
		}
		
		access(all)
		fun isInitialAllocationFinished(): Bool{ 
			return self.hasQueueFinished()
			|| self.canAllocateAfterTGE() && self.allocationQueue.isEmptyQueue()
		}
		
		//Round.setAddress
		access(contract)
		fun setAddress(address: Address, amount: UFix64, releasesRef: Capability<&RoundReleases>){ 
			self.setAddressOn(
				address: address,
				amount: amount,
				releasesRef: releasesRef,
				timestamp: self.tgeDate
			)
		}
		
		access(contract)
		fun setAddressOn(
			address: Address,
			amount: UFix64,
			releasesRef: Capability<&RoundReleases>,
			timestamp: UFix64
		){ 
			// Adding reference to address
			if self.accounts[address] == nil{ 
				self.accounts[address] = releasesRef
			}
			let roundReleases = (self.accounts[address]!).borrow()!
			let linearRelease = self.generateScheduleForDate(timestamp: timestamp, amount: amount)
			let roundRelease <- create RoundRelease(amount: amount, linearRelease: linearRelease)
			roundReleases.setAddress(roundId: self.id, roundRelease: <-roundRelease)
			self.allocationQueue.addAccount(address: address)
			self.totalAllocated = self.totalAllocated + amount
		}
		
		//Round.incorporateAddress
		access(contract)
		fun incorporateAddress(
			address: Address,
			amount: UFix64,
			releasesRef: Capability<&RoundReleases>,
			startTime: UFix64
		){ 
			let time0000 = MoxyData.getTimestampTo0000(timestamp: startTime)
			self.setAddressOn(
				address: address,
				amount: amount,
				releasesRef: releasesRef,
				timestamp: time0000
			)
			self.totalIncorporated = self.totalIncorporated + amount
		}
		
		access(all)
		fun isAddressInRound(address: Address): Bool{ 
			return self.accounts.containsKey(address)
		}
		
		// Round
		access(all)
		fun allocateDailyReleaseToNow(address: Address){ 
			// Get the amount from the last release to a given date
			let now = getCurrentBlock().timestamp
			let amountToAllocate = self.getTotalToAllocateNowTo(address: address)
			if amountToAllocate <= 0.0{ 
				if self.isInLockedPeriod(){ 
					log("Round: ".concat(self.id).concat(" is in lock period."))
				} else{ 
					log("Warning - No amount to allocate on Round: ".concat(self.id).concat(" Posible cause process already run."))
				}
				emit NoAmountToAllocateInRoundRelease(roundId: self.id, address: address, timestamp: now)
				return
			}
			let totalToRelease =
				((self.accounts[address]!).borrow()!).payLinearRelease(roundId: self.id)
			self.totalReleased = self.totalReleased + totalToRelease
			emit RoundAllocationPerformed(
				roundId: self.id,
				address: address,
				totalReleased: totalToRelease,
				timestamp: now
			)
		}
		
		access(all)
		fun getReleaseRatioFor(address: Address): UFix64{ 
			if self.totalAllocated <= 0.0{ 
				panic("Round does not have allocations yet. Release ratio could not be calculated")
			}
			let amount = self.getAmountFor(address: address)
			return amount / self.totalAllocated
		}
		
		access(all)
		fun getTotalToAllocateNowTo(address: Address): UFix64{ 
			return self.getTotalToAllocateNowFor(address: address)
		}
		
		access(all)
		fun getDailyAllocationsFrom(from: UFix64, to: UFix64): [UFix64]{ 
			let from0000 = MoxyData.getTimestampTo0000(timestamp: from)
			let to0000 = MoxyData.getTimestampTo0000(timestamp: to)
			let days = self.getDaysFromTo(from: from0000, to: to0000)
			let amount = self.dailyAllocationAmount()
			return [from0000, to0000, UFix64(days), amount, self.tgeDate, self.getEndDate()]
		}
		
		access(all)
		fun getDailyAllocationsFromToAddress(address: Address, from: UFix64, to: UFix64): [
			UFix64
		]?{ 
			let allocationInfo = self.getDailyAllocationsFrom(from: from, to: to)
			let amount = self.getAmountFor(address: address)
			let amountReleased = self.getAmountReleasedFor(address: address)
			allocationInfo.append(amount)
			allocationInfo.append(amountReleased)
			return allocationInfo
		}
		
		access(all)
		fun getDaysFromTo(from: UFix64, to: UFix64): UInt64{ 
			let from0000 = MoxyData.getTimestampTo0000(timestamp: from)
			let to0000 = MoxyData.getTimestampTo0000(timestamp: to)
			return UInt64((to0000 - from0000) / 86400.0)
		}
		
		access(all)
		fun startReleaseAddress(address: Address, initialVault: @{FungibleToken.Vault}){ 
			pre{ 
				!self.isReleaseStarted:
					"Release is already started."
			}
			var residualReceiver: &{LockedMoxyToken.Receiver}? = nil
			var unlockDate = 0.0
			let days = self.getDays()
			let amountsDict =
				self.getAmountsDictFor(address: address, amount: initialVault.balance)!
			let amount = initialVault.balance
			var am01 = amountsDict["atTGE"]!
			var am02 = amountsDict["afterUnlock"]!
			var am03 = amountsDict["daily"]!
			let amountAtTGEVault <- initialVault.withdraw(amount: am01) as! @MoxyToken.Vault
			let amountAfterUnlockVault <- initialVault.withdraw(amount: am02) as! @MoxyToken.Vault
			let amountVault <- initialVault.withdraw(amount: am03) as! @MoxyToken.Vault
			// Deposit residual amount if any
			amountVault.deposit(from: <-initialVault)
			// Get the locked recipient Vault
			let recipient = getAccount(address)
			let receiverRef =
				recipient.capabilities.get<&{LockedMoxyToken.Receiver}>(
					MoxyToken.moxyTokenLockedReceiverPath
				).borrow<&{LockedMoxyToken.Receiver}>()
				?? panic(
					"Could not borrow receiver reference to the recipient's Vault (moxyTokenLockedReceiverPath)"
				)
			// Deposit the withdrawn tokens in the recipient's receiver
			// The tokens will be locked upto the days defined on round with
			// starting point at TGE Date.
			receiverRef.depositFor(from: <-amountAtTGEVault, time: self.tgeDate)
			receiverRef.depositFor(from: <-amountAfterUnlockVault, time: self.getUnlockDate())
			// Generate linear schedule to send to Locked Token
			//let schedule <- self.generateScheduleFor(amount: amountVault.balance)
			let schedule = self.generateScheduleFor(amount: amount)
			receiverRef.depositFromFixedSchedule(from: <-amountVault, schedule: schedule)
			emit MOXYLockedTokensReleasedTo(round: self.id, address: address, amount: amount)
		}
		
		access(all)
		fun allocateAfterTGE(vault: @{FungibleToken.Vault}, address: Address){ 
			self.allocateOn(timestamp: self.tgeDate, vault: <-vault, address: address)
		}
		
		access(all)
		fun allocateOn(timestamp: UFix64, vault: @{FungibleToken.Vault}, address: Address){ 
			let amountsDict = self.getAmountsDictFor(address: address, amount: vault.balance)!
			let amount = vault.balance
			let startTime = MoxyData.getTimestampTo0000(timestamp: timestamp)
			var am01 = amountsDict["atTGE"]!
			var am02 = amountsDict["afterUnlock"]!
			var am03 = amountsDict["daily"]!
			let amountAtTGEVault <- vault.withdraw(amount: am01) as! @MoxyToken.Vault
			let amountAfterUnlockVault <- vault.withdraw(amount: am02) as! @MoxyToken.Vault
			let amountVault <- vault.withdraw(amount: am03) as! @MoxyToken.Vault
			// Get recipient reference to assign release schedule
			let recipient = getAccount(address)
			let receiverRef =
				recipient.capabilities.get<&{LockedMoxyToken.Receiver}>(
					MoxyToken.moxyTokenLockedReceiverPath
				).borrow<&{LockedMoxyToken.Receiver}>()
				?? panic(
					"Could not borrow receiver reference to the recipient's Vault (moxyTokenLockedReceiverPath)"
				)
			// Deposit the withdrawn tokens in the recipient's receiver
			// The tokens will be locked upto the days defined on round with
			// starting point at TGE Date.
			receiverRef.depositFor(from: <-amountAtTGEVault, time: startTime)
			let unlockDate = self.getUnlockDateStartingOn(timestamp: startTime)
			receiverRef.depositFor(from: <-amountAfterUnlockVault, time: unlockDate)
			let schedule = self.generateScheduleForDate(timestamp: startTime, amount: amount)
			let vaultConverted <- vault as! @MoxyToken.Vault
			receiverRef.depositFromFixedSchedule(from: <-amountVault, schedule: schedule)
			receiverRef.depositFor(from: <-vaultConverted, time: unlockDate)
			emit MOXYLockedTokensReleasedTo(round: self.id, address: address, amount: amount)
		}
		
		access(all)
		fun getUnlockDate(): UFix64{ 
			return self.getUnlockDateStartingOn(timestamp: self.tgeDate)
		}
		
		access(all)
		fun getUnlockDateStartingOn(timestamp: UFix64): UFix64{ 
			return timestamp + UFix64(self.lockTime) * 86400.0
		}
		
		// Generate a dictionary with the release schedule
		// for an specified amount
		access(all)
		fun generateScheduleFor(amount: UFix64): LinearRelease.LinearSchedule{ 
			return self.generateScheduleForDate(timestamp: self.tgeDate, amount: amount)
		}
		
		access(all)
		fun generateScheduleForDate(
			timestamp: UFix64,
			amount: UFix64
		): LinearRelease.LinearSchedule{ 
			let unlockAtTGEAmount = amount * (self.unlockPercentageAtTGE / 100.0)
			let unlockAfterLockTimeAmount = amount * (self.unlockPercentageAfterLockTime / 100.0)
			let totalToRelease = amount - (unlockAtTGEAmount + unlockAfterLockTimeAmount)
			let days = Int(self.getDays())
			let dailyAmount = totalToRelease / UFix64(days)
			let unlockDate = self.getUnlockDateStartingOn(timestamp: timestamp)
			let newLinearRelease =
				LinearRelease.createLinearSchedule(
					tgeDate: timestamp,
					totalAmount: amount,
					initialAmount: unlockAtTGEAmount,
					unlockDate: unlockDate,
					unlockAmount: unlockAfterLockTimeAmount,
					days: days,
					dailyAmount: dailyAmount
				)
			return newLinearRelease
		}
		
		access(all)
		fun getDaysFrom(months: Int): UFix64{ 
			// Dictionary represents the months in the left
			// and the days in the right
			let dictionary:{ Int: Int} ={
				24: 730, 20: 605, 16: 485, 12: 365, 10: 300, 6: 180, 3: 90, 1: 30, 0: 1}
			if dictionary[months] == nil{ 
				return UFix64(months * 30)
			}
			return UFix64(dictionary[months]!)
		}
		
		access(all)
		fun getDays(): UFix64{ 
			return self.getDaysFrom(months: self.months)
		}
		
		access(all)
		fun getEndDate(): UFix64{ 
			if !self.isTGESet(){ 
				return 0.0
			}
			return self.getUnlockDate() + self.getDays() * 86400.0
		}
		
		access(all)
		fun isTGESet(): Bool{ 
			return self.tgeDate > 0.0
		}
		
		access(all)
		fun isReleaseProcesStarted(): Bool{ 
			return self.totalReleased != 0.0
		}
		
		access(all)
		fun getLockedTokenTime(): UFix64{ 
			return UFix64(self.lockTime) * 86400.0
		}
		
		access(all)
		fun isInLockedPeriod(): Bool{ 
			return getCurrentBlock().timestamp < self.tgeDate + UFix64(self.lockTime) * 86400.0
		}
		
		access(all)
		fun dailyAllocationAmount(): UFix64{ 
			if self.months == 0{ 
				return self.initialRelease
			}
			let partial =
				self.initialRelease
				* ((self.unlockPercentageAtTGE + self.unlockPercentageAfterLockTime) / 100.0)
			let total = (self.initialRelease - partial) / self.getDays()
			return total
		}
		
		access(all)
		fun removeAddress(address: Address){ 
			if self.isReleaseProcesStarted(){ 
				return
			}
			let amount = self.getAmountFor(address: address)
			self.totalAllocated = self.totalAllocated - amount
			self.accounts.remove(key: address)
		}
		
		access(all)
		fun setStartDate(timestamp: UFix64){ 
			self.tgeDate = timestamp
			for address in self.accounts.keys{ 
				((self.accounts[address]!).borrow()!).setStartDate(timestamp: timestamp)
			}
		}
		
		// Returns the number of accounts that this round will process
		access(all)
		fun getAccountsToProcess(): Int{ 
			return self.accounts.length
		}
		
		access(all)
		fun isQueueAtBegining(): Bool{ 
			return self.allocationQueue.isAtBeginning()
		}
		
		access(all)
		fun hasQueueFinished(): Bool{ 
			return self.allocationQueue.isEmptyQueue() || self.allocationQueue.hasFinished()
		}
		
		access(all)
		fun getQueueNextAddresses(quantity: Int): @MoxyProcessQueue.Run{ 
			let run <- self.allocationQueue.lockRunWith(quantity: quantity)
			if run == nil{ 
				panic("Wait for queues to be released")
			}
			return <-run!
		}
		
		access(all)
		fun completeNextAddresses(run: @MoxyProcessQueue.Run){ 
			self.allocationQueue.completeNextAddresses(run: <-run)
		}
		
		access(all)
		fun removeAccount(address: Address){ 
			if self.accounts[address] == nil{ 
				return log("Can't remove. Address is not a rounds participant.")
			}
			let amount = self.getAmountFor(address: address)
			self.totalAllocated = self.totalAllocated - amount
			self.accounts.remove(key: address)
		}
		
		init(
			id: String,
			type: String,
			name: String,
			initialRelease: UFix64,
			lockTime: Int,
			months: Int,
			unlockPercentageAtTGE: UFix64,
			unlockPercentageAfterLockTime: UFix64,
			allocateBeforeTGE: Bool
		){ 
			pre{ 
				unlockPercentageAtTGE + unlockPercentageAfterLockTime <= 100.0:
					"Unlock percentage could not be greater than 100%"
			}
			self.id = id
			self.type = type
			self.name = name
			self.initialRelease = initialRelease
			self.lockTime = lockTime
			self.months = months
			self.accounts ={} 
			self.totalIncorporated = 0.0
			self.totalAllocated = 0.0
			self.tgeDate = 0.0
			self.totalReleased = 0.0
			self.unlockPercentageAtTGE = unlockPercentageAtTGE
			self.unlockPercentageAfterLockTime = unlockPercentageAfterLockTime
			self.isReleaseStarted = false
			self.allocateBeforeTGE = allocateBeforeTGE
			self.allocationQueue <- MoxyProcessQueue.createNewQueue()
		}
	}
	
	access(all)
	resource Rounds: MoxyRoundsInfo, MoxyRoundsCreator{ 
		access(contract)
		let rounds: @{String: Round}
		
		access(self)
		let releases:{ Address: Capability<&RoundReleases>}
		
		access(all)
		var tgeDate: UFix64
		
		access(all)
		fun setTGEDate(timestamp: UFix64){ 
			self.tgeDate = MoxyData.getTimestampTo0000(timestamp: timestamp)
		}
		
		// Check if allocatin is complete on all release rounds
		access(all)
		fun isReadyToStartRelease(): Bool{ 
			for roundId in self.rounds.keys{ 
				let isReady = self.rounds[roundId]?.isReadyToStartRelease()!
				if !isReady{ 
					return false
				}
			}
			return true
		}
		
		access(all)
		fun getAccountsToProcess(): Int{ 
			var quantity = 0
			for roundId in self.rounds.keys{ 
				quantity = quantity + self.rounds[roundId]?.getAccountsToProcess()!
			}
			return quantity
		}
		
		access(all)
		fun completeNextAddresses(roundId: String, run: @MoxyProcessQueue.Run){ 
			let round: @MoxyReleaseRounds.Round <-! self.rounds.remove(key: roundId)!
			round.completeNextAddresses(run: <-run)
			self.rounds[roundId] <-! round
		}
		
		access(all)
		fun allocateAfterTGE(roundId: String, vault: @{FungibleToken.Vault}, address: Address){ 
			let round <- self.rounds.remove(key: roundId)!
			round.allocateAfterTGE(vault: <-vault, address: address)
			let old <- self.rounds[roundId] <- round
			destroy old
		}
		
		access(all)
		fun allocateOn(timestamp: UFix64, roundId: String, vault: @{FungibleToken.Vault}, address: Address){ 
			let round <- self.rounds.remove(key: roundId)!
			let time0000 = MoxyData.getTimestampTo0000(timestamp: timestamp)
			round.allocateOn(timestamp: time0000, vault: <-vault, address: address)
			let old <- self.rounds[roundId] <- round
			destroy old
		}
		
		access(all)
		fun getAmountFor(roundId: String, address: Address): UFix64{ 
			return self.rounds[roundId]?.getAmountFor(address: address)!
		}
		
		access(all)
		fun isReadyToStartReleaseTo(roundId: String): Bool{ 
			return self.rounds[roundId]?.isReadyToStartRelease()!
		}
		
		access(all)
		fun haveAllRoundsStarted(): Bool{ 
			for roundId in self.rounds.keys{ 
				let isStarted = self.rounds[roundId]?.isReleaseStarted!
				if !isStarted{ 
					return false
				}
			}
			return true
		}
		
		access(all)
		fun isQueueAtBegining(): Bool{ 
			for roundId in self.rounds.keys{ 
				let isAtBegining = self.rounds[roundId]?.isQueueAtBegining()!
				if !isAtBegining{ 
					return false
				}
			}
			return true
		}
		
		access(all)
		fun haveAllQueuesFinished(): Bool{ 
			for roundId in self.rounds.keys{ 
				let isFinished = self.rounds[roundId]?.hasQueueFinished()!
				if !isFinished{ 
					return false
				}
			}
			return true
		}
		
		access(all)
		fun initialAllocationFinished(): Bool{ 
			// Check if all queues are finished but not in the cases
			// that the releasee can start after TGE 
			for roundId in self.rounds.keys{ 
				let isFinished = self.rounds[roundId]?.isInitialAllocationFinished()!
				if !isFinished{ 
					return false
				}
			}
			return true
		}
		
		access(all)
		fun getRoundsNames(): [String]{ 
			return self.rounds.keys
		}
		
		access(all)
		fun hasQueueFinished(roundId: String): Bool{ 
			return self.rounds[roundId]?.hasQueueFinished()!
		}
		
		access(all)
		fun getQueueNextAddresses(roundId: String, quantity: Int): @MoxyProcessQueue.Run{ 
			return <-self.rounds[roundId]?.getQueueNextAddresses(quantity: quantity)!
		}
		
		access(all)
		fun getRoundsLength(): Int{ 
			return self.rounds.length
		}
		
		access(all)
		fun setStartDate(timestamp: UFix64){ 
			for roundId in self.rounds.keys{ 
				self.rounds[roundId]?.setStartDate(timestamp: timestamp)!
			}
		}
		
		access(all)
		fun getAddresses(): [Address]{ 
			return self.releases.keys
		}
		
		access(all)
		fun getRoundAddresses(roundId: String): [Address]{ 
			return self.rounds[roundId]?.getRoundAddresses()!
		}
		
		access(all)
		fun addRound(_ id: String, type: String, name: String, initialRelease: UFix64, lockTime: Int, months: Int, unlockPercentageAtTGE: UFix64, unlockPercentageAfterLockTime: UFix64, allocateBeforeTGE: Bool){ 
			let round <- create Round(id: id, type: type, name: name, initialRelease: initialRelease, lockTime: lockTime, months: months, unlockPercentageAtTGE: unlockPercentageAtTGE, unlockPercentageAfterLockTime: unlockPercentageAfterLockTime, allocateBeforeTGE: allocateBeforeTGE)
			round.setStartDate(timestamp: self.tgeDate)
			let old <- self.rounds[id] <- round
			destroy old
			emit MoxyReleaseRounds.RoundAdded(name: name)
		}
		
		access(all)
		fun createRoundReleases(lockedMOXYVault: Capability<&LockedMoxyToken.LockedVault>, lockedMVVault: Capability<&LockedMoxyVaultToken.LockedVault>): @RoundReleases{ 
			return <-create RoundReleases(lockedMOXYVault: lockedMOXYVault, lockedMVVault: lockedMVVault)
		}
		
		access(all)
		fun acceptRounds(address: Address, releasesRef: Capability<&MoxyReleaseRounds.RoundReleases>){ 
			pre{ 
				address == (releasesRef.borrow()!).lockedMOXYVault.address:
					"Address does not match with Vault address"
				address == (releasesRef.borrow()!).lockedMVVault.address:
					"Address does not match with Vault address"
			}
			// User consents to partipate in rounds releases
			if self.releases[address] != nil{ 
				log("Address already accepted the Rounds participation.")
				emit AccountAlreadyAcceptedRoundParticipation(address: address, timestamp: getCurrentBlock().timestamp)
				return
			}
			// Capability added to releases collection for user future 
			// rounds participations
			self.releases[address] = releasesRef
			emit AccountAcceptedRoundsParticipation(address: address, timestamp: getCurrentBlock().timestamp)
		}
		
		access(all)
		fun removeFromRounds(address: Address){ 
			if self.releases[address] == nil{ 
				return log("Can't remove. Address is not a rounds participant.")
			}
			self.releases.remove(key: address)
			for roundId in self.rounds.keys{ 
				self.rounds[roundId]?.removeAccount(address: address)
			}
		}
		
		access(all)
		fun addressHasAcceptedRounds(address: Address): Bool{ 
			return self.releases[address] != nil
		}
		
		access(all)
		fun fullAllocateTo(roundId: String, address: Address){ 
			let amount = self.rounds[roundId]?.getAllocationRemaining()!
			self.setAddress(roundId: roundId, address: address, amount: amount)
		}
		
		//Rounds.setAddress
		access(all)
		fun setAddress(roundId: String, address: Address, amount: UFix64){ 
			if self.releases[address] == nil{ 
				panic("Required accept consent from address: ".concat(address.toString()))
			}
			// Make a new resource to store the roundID in the key and
			// a structure with the RoundRelease (with amount and amount released) in value
			let alreadyStarted = false
			let exceedsAllocation = self.rounds[roundId]?.getAllocationRemaining()! < amount
			if alreadyStarted || exceedsAllocation{ 
				var message = ""
				if alreadyStarted{ 
					message = roundId.concat(" - Cannot allocate to round: process already started")
				} else{ 
					message = roundId.concat(" - Amount exceeds initial Allocation. Max to allocate is ".concat((self.rounds[roundId]?.getAllocationRemaining()!).toString()))
				}
				panic(message)
			} else{ 
				// Sets the address
				let releasesRef = self.releases[address]!
				self.rounds[roundId]?.setAddress(address: address, amount: amount, releasesRef: releasesRef)!
			}
		}
		
		access(all)
		fun incorporateAddress(roundId: String, address: Address, amount: UFix64, startTime: UFix64){ 
			if self.releases[address] == nil{ 
				panic("Required accept consent from address: ".concat(address.toString()))
			}
			let releasesRef = self.releases[address]!
			self.rounds[roundId]?.incorporateAddress(address: address, amount: amount, releasesRef: releasesRef, startTime: startTime)!
		}
		
		// Rounds
		access(all)
		fun startReleaseRound(roundId: String, address: Address, initialVault: @{FungibleToken.Vault}){ 
			let round <- self.rounds.remove(key: roundId)!
			let amount = round.totalAllocated
			round.startReleaseAddress(address: address, initialVault: <-initialVault)
			let old <- self.rounds[roundId] <- round
			destroy old
		}
		
		access(all)
		fun hasRoundRelease(address: Address): Bool{ 
			return self.releases[address] != nil
		}
		
		//Rounds
		access(all)
		fun allocateDailyReleaseNowToAddress(address: Address, feeRemaining: UFix64): @{FungibleToken.Vault}{ 
			let roundReleases = (self.releases[address]!).borrow()!
			let feeVault <- roundReleases.allocateDailyReleaseToNow(feeRemaining: feeRemaining)
			for roundId in roundReleases.releases.keys{ 
				if self.rounds[roundId]?.isAddressInRound(address: address)!{ 
					self.rounds[roundId]?.allocateDailyReleaseToNow(address: address)!
				}
			}
			return <-feeVault
		}
		
		access(all)
		fun removeAddress(roundId: String, address: Address){ 
			self.rounds[roundId]?.removeAddress(address: address)
		}
		
		access(all)
		fun getAllocationRemaining(_ id: String): UFix64?{ 
			return self.rounds[id]?.getAllocationRemaining()
		}
		
		access(all)
		fun getDailyAllocationsFrom(roundId: String, from: UFix64, to: UFix64): [UFix64]?{ 
			return self.rounds[roundId]?.getDailyAllocationsFrom(from: from, to: to)
		}
		
		access(all)
		fun getDailyAllocationsFromToAddress(roundId: String, address: Address, from: UFix64, to: UFix64): [UFix64]??{ 
			return self.rounds[roundId]?.getDailyAllocationsFromToAddress(address: address, from: from, to: to)
		}
		
		access(all)
		fun getAmountReleasedFor(roundId: String, address: Address): UFix64{ 
			return self.rounds[roundId]?.getAmountReleasedFor(address: address)!
		}
		
		access(all)
		fun getRoundReleaseInfo(_ id: String, address: Address): RoundReleaseInfo?{ 
			let roundInfo = self.rounds[id]?.getRoundReleaseInfo(address)!
			return roundInfo
		}
		
		access(all)
		fun getAccounts(_ id: String):{ Address: ParticipantRoundInfo}?{ 
			return self.rounds[id]?.getAccounts()
		}
		
		access(all)
		fun getRoundsForAddress(address: Address):{ String: ParticipantRoundInfo}{ 
			let rounds:{ String: ParticipantRoundInfo} ={} 
			for roundId in self.rounds.keys{ 
				let amount = self.getAmountFor(roundId: roundId, address: address)
				if amount > 0.0{ 
					let amountReleased = self.getAmountReleasedFor(roundId: roundId, address: address)
					rounds[roundId] = ParticipantRoundInfo(address: address, roundId: roundId, amount: amount, amountReleased: amountReleased)
				}
			}
			return rounds
		}
		
		access(all)
		fun getRoundInfo(roundId: String): RoundInfo{ 
			return self.rounds[roundId]?.getRoundInfo()!
		}
		
		init(){ 
			self.rounds <-{} 
			self.releases ={} 
			//  set to JUL 10th, 2023 - GMT+0000
			self.tgeDate = 1688947200.0
		}
	}
	
	access(self)
	fun getRoundsCapability(): &Rounds{ 
		return self.account.capabilities.get<&MoxyReleaseRounds.Rounds>(self.moxyRoundsPrivate)
			.borrow<&MoxyReleaseRounds.Rounds>()!
	}
	
	access(all)
	fun getRounds(): [String]{ 
		let roundsManager = self.getRoundsCapability()
		return *roundsManager.rounds.keys
	}
	
	access(all)
	resource interface RoundReleasesInfo{} 
	
	access(all)
	resource interface MoxyRoundsInfo{ 
		access(all)
		fun getRoundsForAddress(address: Address):{ String: ParticipantRoundInfo}
		
		access(all)
		fun getAllocationRemaining(_ id: String): UFix64?
		
		access(all)
		fun getDailyAllocationsFrom(roundId: String, from: UFix64, to: UFix64): [UFix64]?
		
		access(all)
		fun getDailyAllocationsFromToAddress(
			roundId: String,
			address: Address,
			from: UFix64,
			to: UFix64
		): [
			UFix64
		]??
		
		access(all)
		fun getAccounts(_ id: String):{ Address: ParticipantRoundInfo}?
		
		access(all)
		fun addressHasAcceptedRounds(address: Address): Bool
		
		access(all)
		fun getAddresses(): [Address]
		
		access(all)
		fun getRoundAddresses(roundId: String): [Address]
		
		access(all)
		fun getRoundReleaseInfo(_ id: String, address: Address): RoundReleaseInfo?
		
		access(all)
		fun haveAllQueuesFinished(): Bool
		
		access(all)
		fun initialAllocationFinished(): Bool
		
		access(all)
		fun getRoundInfo(roundId: String): RoundInfo
	}
	
	access(all)
	resource interface MoxyRoundsCreator{ 
		access(all)
		fun createRoundReleases(
			lockedMOXYVault: Capability<&LockedMoxyToken.LockedVault>,
			lockedMVVault: Capability<&LockedMoxyVaultToken.LockedVault>
		): @RoundReleases
		
		access(all)
		fun acceptRounds(
			address: Address,
			releasesRef: Capability<&MoxyReleaseRounds.RoundReleases>
		)
	}
	
	access(all)
	let moxyRoundsStorage: StoragePath
	
	access(all)
	let moxyRoundsPrivate: PrivatePath
	
	access(all)
	let moxyRoundsInfoPublic: PublicPath
	
	access(all)
	let roundReleasesStorage: StoragePath
	
	access(all)
	let roundReleasesPrivate: PrivatePath
	
	access(all)
	let roundReleasesInfoPublic: PublicPath
	
	// Initialize contract
	init(){ 
		// Moxy Rounds initialization
		let moxyRounds <- create Rounds()
		moxyRounds.addRound(
			"seed",
			type: "Token Sale",
			name: "Seed",
			initialRelease: 45000000.0,
			lockTime: 0,
			months: 24,
			unlockPercentageAtTGE: 0.0,
			unlockPercentageAfterLockTime: 0.0,
			allocateBeforeTGE: true
		)
		moxyRounds.addRound(
			"private_1",
			type: "Token Sale",
			name: "Private 1",
			initialRelease: 75000000.0,
			lockTime: 0,
			months: 20,
			unlockPercentageAtTGE: 0.0,
			unlockPercentageAfterLockTime: 0.0,
			allocateBeforeTGE: true
		)
		moxyRounds.addRound(
			"private_2",
			type: "Token Sale",
			name: "Private 2",
			initialRelease: 113500000.0,
			lockTime: 0,
			months: 16,
			unlockPercentageAtTGE: 0.0,
			unlockPercentageAfterLockTime: 0.0,
			allocateBeforeTGE: true
		)
		moxyRounds.addRound(
			"public_presale",
			type: "Token Sale",
			name: "Public Whitelist",
			initialRelease: 18000000.0,
			lockTime: 0,
			months: 3,
			unlockPercentageAtTGE: 50.0,
			unlockPercentageAfterLockTime: 0.0,
			allocateBeforeTGE: false
		)
		moxyRounds.addRound(
			"public_ido",
			type: "Token Sale",
			name: "Public IDO",
			initialRelease: 11000000.0,
			lockTime: 0,
			months: 0,
			unlockPercentageAtTGE: 100.0,
			unlockPercentageAfterLockTime: 0.0,
			allocateBeforeTGE: true
		)
		moxyRounds.addRound(
			"team",
			type: "Token Allocation",
			name: "Team",
			initialRelease: 225000000.0,
			lockTime: 365,
			months: 24,
			unlockPercentageAtTGE: 0.0,
			unlockPercentageAfterLockTime: 0.0,
			allocateBeforeTGE: true
		)
		moxyRounds.addRound(
			"moxy_foundation",
			type: "Token Allocation",
			name: "Moxy Foundation",
			initialRelease: 375000000.0,
			lockTime: 180,
			months: 24,
			unlockPercentageAtTGE: 15.0,
			unlockPercentageAfterLockTime: 0.0,
			allocateBeforeTGE: true
		)
		moxyRounds.addRound(
			"advisors",
			type: "Token Allocation",
			name: "Advisors",
			initialRelease: 75000000.0,
			lockTime: 180,
			months: 24,
			unlockPercentageAtTGE: 0.0,
			unlockPercentageAfterLockTime: 0.0,
			allocateBeforeTGE: true
		)
		moxyRounds.addRound(
			"treasury",
			type: "Token Allocation",
			name: "Treasury",
			initialRelease: 150000000.0,
			lockTime: 90,
			months: 24,
			unlockPercentageAtTGE: 0.0,
			unlockPercentageAfterLockTime: 25.0,
			allocateBeforeTGE: true
		)
		moxyRounds.addRound(
			"ecosystem",
			type: "Token Allocation",
			name: "Ecosystem",
			initialRelease: 412500000.0,
			lockTime: 180,
			months: 24,
			unlockPercentageAtTGE: 0.0,
			unlockPercentageAfterLockTime: 0.0,
			allocateBeforeTGE: true
		)
		// Storage of Rounds
		self.moxyRoundsStorage = /storage/moxyRounds
		self.moxyRoundsPrivate = /private/moxyRounds
		self.moxyRoundsInfoPublic = /public/moxyRoundsInfoPublic
		self.account.storage.save(<-moxyRounds, to: self.moxyRoundsStorage)
		var capability_1 =
			self.account.capabilities.storage.issue<&MoxyReleaseRounds.Rounds>(
				self.moxyRoundsStorage
			)
		self.account.capabilities.publish(capability_1, at: self.moxyRoundsPrivate)
		var capability_2 =
			self.account.capabilities.storage.issue<&MoxyReleaseRounds.Rounds>(
				self.moxyRoundsStorage
			)
		self.account.capabilities.publish(capability_2, at: self.moxyRoundsInfoPublic)
		!		 // Storage of RoundRelease on user account
		 self.roundReleasesStorage = /storage/roundReleaseStorage
		self.roundReleasesPrivate = /private/roundReleasePrivate
		self.roundReleasesInfoPublic = /public/roundReleaseInfoPublic
	}
}
