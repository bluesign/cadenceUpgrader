access(all)
contract WithdrawalTracker{ 
	access(all)
	event WithdrawalTotalTrackerCreated(withdrawalLimit: UFix64, runningTotal: UFix64)
	
	access(all)
	event WithdrawalLimitSet(oldLimit: UFix64, newLimit: UFix64, runningTotal: UFix64)
	
	access(all)
	event RunningTotalUpdated(amount: UFix64, runningTotal: UFix64, withdrawalLimit: UFix64)
	
	// So the total can be checked publicly via a Capability
	access(all)
	resource interface WithdrawalTotalChecker{ 
		access(all)
		fun getCurrentRunningTotal(): UFix64
		
		access(all)
		fun getCurrentWithdrawalLimit(): UFix64
	}
	
	// For admins, if needed
	access(all)
	resource interface SetWithdrawalLimit{ 
		access(all)
		fun setWithdrawalLimit(withdrawalLimit: UFix64)
	}
	
	// Anyone can create one.
	// Place it in your storage, expose CheckRunningTotal in /public/,
	// and if you need to you can pass a Capability to SetWithdrawalLimit to an admin,
	// but really you should just update it yourself.
	access(all)
	resource WithdrawalTotalTracker: WithdrawalTotalChecker, SetWithdrawalLimit{ 
		access(self)
		var withdrawalLimit: UFix64
		
		access(self)
		var runningTotal: UFix64
		
		access(all)
		fun getCurrentRunningTotal(): UFix64{ 
			return self.runningTotal
		}
		
		access(all)
		fun getCurrentWithdrawalLimit(): UFix64{ 
			return self.withdrawalLimit
		}
		
		// The user can call this if they wish to avoid an exception from updateRunningTotal
		access(all)
		view fun wouldExceedLimit(withdrawalAmount: UFix64): Bool{ 
			return self.runningTotal + withdrawalAmount > self.withdrawalLimit
		}
		
		access(all)
		fun updateRunningTotal(withdrawalAmount: UFix64){ 
			pre{ 
				!self.wouldExceedLimit(withdrawalAmount: withdrawalAmount):
					"Withdrawal would cause total to exceed withdrawalLimit"
			}
			self.runningTotal = self.runningTotal + withdrawalAmount
			emit RunningTotalUpdated(amount: withdrawalAmount, runningTotal: self.runningTotal, withdrawalLimit: self.withdrawalLimit)
		}
		
		access(all)
		fun setWithdrawalLimit(withdrawalLimit: UFix64){ 
			emit WithdrawalLimitSet(oldLimit: self.withdrawalLimit, newLimit: withdrawalLimit, runningTotal: self.runningTotal)
			self.withdrawalLimit = withdrawalLimit
		}
		
		init(initialLimit: UFix64, initialRunningTotal: UFix64){ 
			self.withdrawalLimit = initialLimit
			self.runningTotal = initialRunningTotal
			emit WithdrawalTotalTrackerCreated(withdrawalLimit: self.withdrawalLimit, runningTotal: self.runningTotal)
		}
	}
	
	access(all)
	fun createWithdrawalTotalTracker(
		initialLimit: UFix64,
		initialRunningTotal: UFix64
	): @WithdrawalTotalTracker{ 
		return <-create WithdrawalTotalTracker(
			initialLimit: initialLimit,
			initialRunningTotal: initialRunningTotal
		)
	}
}
