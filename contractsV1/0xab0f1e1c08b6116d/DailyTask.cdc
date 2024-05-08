import ExpToken from "./ExpToken.cdc"

access(all)
contract DailyTask{ 
	
	// Task Types
	// {TaskName: IfValid}, e.g. SWAP_ONCE, MINT_FLOAT, BUY_NBA
	// Not using enums to represent task types because it's not convenient to add, delete, or modify them
	access(all)
	let taskTypes:{ String: Bool}
	
	// {playerAddr: {taskType: taskStatus}}
	// 0: incomplete
	// 1: completed
	// 2: reward claimed
	access(all)
	let playerTaskComplete:{ Address:{ String: Int}}
	
	access(all)
	event NewTaskType(taskType: String)
	
	access(all)
	event CompleteTask(day: UInt64, taskType: String, playerAddr: Address)
	
	access(all)
	event claimTaskReward(day: UInt64, taskType: String, playerAddr: Address, amount: UFix64)
	
	// Determine current date using block's timestamp modulo the number of seconds in a day
	access(all)
	fun getCurrentDate(): UInt64{ 
		let secondsInADay: UFix64 = 86400.0 // 24 hours * 60 minutes * 60 seconds
		
		return UInt64(getCurrentBlock().timestamp / secondsInADay)
	}
	
	// Generate a random task for the day
	access(all)
	fun getTodayTaskType(): String{ 
		let today = self.getCurrentDate()
		let totalTaskTypeCount = self.taskTypes.keys.length
		return self.taskTypes.keys[Int(today) % Int(totalTaskTypeCount)]
	}
	
	// Complete the task, called by other GamingIntegration, based on the current timestamp within a day as the unit
	access(account)
	fun completeDailyTask(playerAddr: Address, taskType: String){ 
		let today = self.getCurrentDate()
		if self.playerTaskComplete.containsKey(playerAddr) == false{ 
			self.playerTaskComplete[playerAddr] ={} 
		}
		emit CompleteTask(day: today, taskType: taskType, playerAddr: playerAddr)
		if (self.playerTaskComplete[playerAddr]!).containsKey(taskType) == false{ 
			(self.playerTaskComplete[playerAddr]!).insert(key: taskType, 1)
			return
		}
		let curStatus = (self.playerTaskComplete[playerAddr]!)[taskType]!
		// Task completed
		if curStatus == 2{ 
			return
		}
		(self.playerTaskComplete[playerAddr]!).insert(key: taskType, 1)
	}
	
	// Claim reward for today's task
	access(all)
	fun claimTodayReward(
		dayIndex: UInt64,
		taskType: String,
		userCertificateCap: Capability<&ExpToken.UserCertificate>
	): @ExpToken.Vault{ 
		let playerAddr = ((userCertificateCap.borrow()!).owner!).address
		assert(
			(self.playerTaskComplete[playerAddr]!)[taskType]! == 1,
			message: "Task has been claimed or remains incomplete"
		)
		(self.playerTaskComplete[playerAddr]!).insert(key: taskType, 2)
		let expReward = 100.0
		let expVault <- ExpToken.mintTokens(amount: expReward)
		emit claimTaskReward(
			day: dayIndex,
			taskType: taskType,
			playerAddr: playerAddr,
			amount: expReward
		)
		return <-expVault
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun setNewTaskType(taskType: String){ 
			emit NewTaskType(taskType: taskType)
			DailyTask.taskTypes[taskType] = true
		}
	}
	
	init(){ 
		self.taskTypes ={} 
		self.taskTypes["SWAP_ONCE"] = true
		self.taskTypes["MINT_FLOAT"] = true
		self.taskTypes["BUY_NBA"] = true
		self.playerTaskComplete ={} 
		self.account.storage.save(<-create Admin(), to: /storage/adminPath_dailyTask)
	}
}
