import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract Stats{ 
	// Events
	access(all)
	event StatsCreated(user_id: UInt32, address: Address)
	
	access(all)
	event Tipping(amount: UFix64, address: Address)
	
	// Paths
	access(all)
	let StatsVaultPublicPath: PublicPath
	
	// Variants
	access(self)
	var totalStatsVaultSupply: UInt32
	
	// Objects
	access(all)
	let FlowTokenVault: Capability<&FlowToken.Vault>
	
	access(all)
	let FlowTokenVaults:{ Address: Capability<&FlowToken.Vault>}
	
	access(all)
	let stats:{ Address: [StatsStruct]}
	
	/*
	  ** [Struct] StatsStruct
	  */
	
	access(all)
	struct StatsStruct{ 
		access(all)
		let nickname: String
		
		access(all)
		let time: UFix64 // Time
		
		
		access(all)
		let title: String
		
		access(all)
		let answer1: String
		
		access(all)
		let answer2: String
		
		access(all)
		let answer3: String
		
		access(all)
		let answer4: String
		
		access(all)
		let answer5: String
		
		access(all)
		let answer6: String
		
		access(all)
		let value1: UFix64
		
		access(all)
		let value2: UFix64
		
		access(all)
		let value3: UFix64
		
		access(all)
		let value4: UFix64
		
		access(all)
		let value5: UFix64
		
		access(all)
		let value6: UFix64
		
		access(all)
		let update_count: UInt8
		
		init(
			nickname: String,
			time: UFix64,
			title: String,
			answer1: String,
			answer2: String,
			answer3: String,
			answer4: String,
			answer5: String,
			answer6: String,
			value1: UFix64,
			value2: UFix64,
			value3: UFix64,
			value4: UFix64,
			value5: UFix64,
			value6: UFix64,
			update_count: UInt8
		){ 
			self.nickname = nickname
			self.time = time
			self.title = title
			self.answer1 = answer1
			self.answer2 = answer2
			self.answer3 = answer3
			self.answer4 = answer4
			self.answer5 = answer5
			self.answer6 = answer6
			self.value1 = value1
			self.value2 = value2
			self.value3 = value3
			self.value4 = value4
			self.value5 = value5
			self.value6 = value6
			self.update_count = update_count
		}
	}
	
	/*
	  ** [Interface] IStatsPrivate
	  */
	
	access(all)
	resource interface IStatsPrivate{ 
		access(all)
		var user_id: UInt32
		
		access(all)
		fun addStats(
			addr: Address,
			nickname: String,
			title: String,
			answer1: String,
			answer2: String,
			answer3: String,
			answer4: String,
			answer5: String,
			answer6: String,
			value1: UFix64,
			value2: UFix64,
			value3: UFix64,
			value4: UFix64,
			value5: UFix64,
			value6: UFix64
		)
		
		access(all)
		fun updateStats(
			addr: Address,
			index: UInt32,
			nickname: String,
			title: String,
			answer1: String,
			answer2: String,
			answer3: String,
			answer4: String,
			answer5: String,
			answer6: String,
			value1: UFix64,
			value2: UFix64,
			value3: UFix64,
			value4: UFix64,
			value5: UFix64,
			value6: UFix64
		)
	}
	
	/*
	  ** [Resource] StatsVault
	  */
	
	access(all)
	resource StatsVault: IStatsPrivate{ 
		
		// [private access]
		access(all)
		var user_id: UInt32
		
		// [public access]
		access(all)
		fun getId(): UInt32{ 
			return self.user_id
		}
		
		// [private access]
		access(all)
		fun addStats(addr: Address, nickname: String, title: String, answer1: String, answer2: String, answer3: String, answer4: String, answer5: String, answer6: String, value1: UFix64, value2: UFix64, value3: UFix64, value4: UFix64, value5: UFix64, value6: UFix64){ 
			let time = getCurrentBlock().timestamp
			let stat = StatsStruct(nickname: nickname, time: time, title: title, answer1: answer1, answer2: answer2, answer3: answer3, answer4: answer4, answer5: answer5, answer6: answer6, value1: value1, value2: value2, value3: value3, value4: value4, value5: value5, value6: value6, update_count: 0)
			if let data = Stats.stats[addr]{ 
				(Stats.stats[addr]!).append(stat)
			}
			emit StatsCreated(user_id: self.user_id, address: addr)
		}
		
		// [private access]
		access(all)
		fun updateStats(addr: Address, index: UInt32, nickname: String, title: String, answer1: String, answer2: String, answer3: String, answer4: String, answer5: String, answer6: String, value1: UFix64, value2: UFix64, value3: UFix64, value4: UFix64, value5: UFix64, value6: UFix64){ 
			let existStat = (Stats.stats[addr]!).remove(at: index)
			let stat = StatsStruct(nickname: nickname, time: existStat.time, title: title, answer1: answer1, answer2: answer2, answer3: answer3, answer4: answer4, answer5: answer5, answer6: answer6, value1: value1, value2: value2, value3: value3, value4: value4, value5: value5, value6: value6, update_count: existStat.update_count + 1)
			(Stats.stats[addr]!).insert(at: index, stat)
		}
		
		init(addr: Address, nickname: String, title: String, answer1: String, answer2: String, answer3: String, answer4: String, answer5: String, answer6: String, value1: UFix64, value2: UFix64, value3: UFix64, value4: UFix64, value5: UFix64, value6: UFix64, flow_vault_receiver: Capability<&FlowToken.Vault>){ 
			// TotalSupply
			self.user_id = Stats.totalStatsVaultSupply + 1
			Stats.totalStatsVaultSupply = Stats.totalStatsVaultSupply + 1
			
			// Event, Data
			emit StatsCreated(user_id: self.user_id, address: addr)
			let time = getCurrentBlock().timestamp
			let stat = StatsStruct(nickname: nickname, time: time, title: title, answer1: answer1, answer2: answer2, answer3: answer3, answer4: answer4, answer5: answer5, answer6: answer6, value1: value1, value2: value2, value3: value3, value4: value4, value5: value5, value6: value6, update_count: 0)
			Stats.stats[addr] = [stat]
			if Stats.FlowTokenVaults[addr] == nil{ 
				Stats.FlowTokenVaults[addr] = flow_vault_receiver
			}
		}
	}
	
	/*
	  ** [Resource] StatsPublic
	  */
	
	access(all)
	resource StatsPublic{} 
	
	/*
	  ** [create vault] createStatsVault
	  */
	
	access(all)
	fun createStatsVault(
		addr: Address,
		nickname: String,
		title: String,
		answer1: String,
		answer2: String,
		answer3: String,
		answer4: String,
		answer5: String,
		answer6: String,
		value1: UFix64,
		value2: UFix64,
		value3: UFix64,
		value4: UFix64,
		value5: UFix64,
		value6: UFix64,
		flow_vault_receiver: Capability<&FlowToken.Vault>
	): @StatsVault{ 
		pre{ 
			Stats.stats[addr] == nil:
				"This address already has account"
		}
		return <-create StatsVault(
			addr: addr,
			nickname: nickname,
			title: title,
			answer1: answer1,
			answer2: answer2,
			answer3: answer3,
			answer4: answer4,
			answer5: answer5,
			answer6: answer6,
			value1: value1,
			value2: value2,
			value3: value3,
			value4: value4,
			value5: value5,
			value6: value6,
			flow_vault_receiver: flow_vault_receiver
		)
	}
	
	/*
	  ** [create StatsPublic] createStatsPublic
	  */
	
	access(all)
	fun createStatsPublic(): @StatsPublic{ 
		return <-create StatsPublic()
	}
	
	/*
	  ** tipping
	  */
	
	access(all)
	fun tipping(addr: Address, payment: @FlowToken.Vault, fee: @FlowToken.Vault){ 
		pre{ 
			payment.balance <= 1.0:
				"Tip is too large."
			fee.balance > (fee.balance + payment.balance) * 0.024:
				"fee is less than 2.5%."
		}
		let amount = payment.balance + fee.balance
		(Stats.FlowTokenVault.borrow()!).deposit(from: <-fee)
		((Stats.FlowTokenVaults[addr]!).borrow()!).deposit(from: <-payment)
		emit Tipping(amount: amount, address: addr)
	}
	
	/*
	  ** init
	  */
	
	init(){ 
		self.StatsVaultPublicPath = /public/StatsVault
		self.totalStatsVaultSupply = 0
		self.FlowTokenVault = self.account.capabilities.get<&FlowToken.Vault>(
				/public/flowTokenReceiver
			)!
		self.FlowTokenVaults ={} 
		self.stats ={} 
	}
}
