import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import StarVaultInterfaces from "../0x5c6dad1decebccb4/StarVaultInterfaces.cdc"

import StarVaultConfig from "../0x5c6dad1decebccb4/StarVaultConfig.cdc"

import StarVaultFactory from "../0x5c6dad1decebccb4/StarVaultFactory.cdc"

import LPStaking from "../0x5c6dad1decebccb4/LPStaking.cdc"

access(all)
contract RewardPool{ 
	access(all)
	let pid: Int
	
	access(all)
	let stakeToken: Address
	
	access(all)
	let duration: UFix64
	
	access(all)
	var periodFinish: UFix64
	
	access(all)
	var rewardRate: UFix64
	
	access(all)
	var lastUpdateTime: UFix64
	
	access(all)
	var rewardPerTokenStored: UFix64
	
	access(all)
	var queuedRewards: UFix64
	
	access(all)
	var currentRewards: UFix64
	
	access(all)
	var historicalRewards: UFix64
	
	access(all)
	var totalSupply: UFix64
	
	access(all)
	var userRewardPerTokenPaid:{ Address: UFix64}
	
	access(all)
	var rewards:{ Address: UFix64}
	
	access(self)
	var balances:{ Address: UFix64}
	
	access(all)
	fun getBalance(account: Address): UFix64{ 
		let collectionRef =
			getAccount(account).capabilities.get<&LPStaking.LPStakingCollection>(
				StarVaultConfig.LPStakingCollectionPublicPath
			).borrow()
		if collectionRef != nil{ 
			return (collectionRef!).getTokenBalance(tokenAddress: self.stakeToken)
		} else{ 
			return 0.0
		}
	}
	
	access(all)
	fun balanceOf(account: Address): UFix64{ 
		var balance: UFix64 = 0.0
		if self.balances.containsKey(account){ 
			balance = self.balances[account]!
		}
		return balance
	}
	
	access(all)
	fun updateReward(account: Address?){ 
		self.rewardPerTokenStored = self.rewardPerToken()
		self.lastUpdateTime = self.lastTimeRewardApplicable()
		if account != nil{ 
			let _account = account!
			self.rewards[_account] = self.earned(account: _account)
			self.userRewardPerTokenPaid[_account] = self.rewardPerTokenStored
			let balance = self.balanceOf(account: _account)
			let newBalance = self.getBalance(account: _account)
			self.totalSupply = self.totalSupply - balance + newBalance
			self.balances[_account] = newBalance
		}
	}
	
	access(all)
	fun lastTimeRewardApplicable(): UFix64{ 
		let now = getCurrentBlock().timestamp
		if now >= self.periodFinish{ 
			return self.periodFinish
		} else{ 
			return now
		}
	}
	
	access(all)
	fun rewardPerToken(): UFix64{ 
		if self.totalSupply == 0.0{ 
			return self.rewardPerTokenStored
		}
		return self.rewardPerTokenStored
		+ (self.lastTimeRewardApplicable() - self.lastUpdateTime) * self.rewardRate
		/ self.totalSupply
	}
	
	access(all)
	fun earned(account: Address): UFix64{ 
		var userRewardPerTokenPaid: UFix64 = 0.0
		if self.userRewardPerTokenPaid.containsKey(account){ 
			userRewardPerTokenPaid = self.userRewardPerTokenPaid[account]!
		}
		var rewards: UFix64 = 0.0
		if self.rewards.containsKey(account){ 
			rewards = self.rewards[account]!
		}
		let balance = self.balanceOf(account: account)
		return balance * (self.rewardPerToken() - userRewardPerTokenPaid) + rewards
	}
	
	access(all)
	fun getReward(account: Address){ 
		self.updateReward(account: account)
		let reward = self.earned(account: account)
		if reward > 0.0{ 
			self.rewards[account] = 0.0
			let provider = self.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
			let vault <- provider.withdraw(amount: reward)
			let receiver = getAccount(account).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow()!
			receiver.deposit(from: <-vault)
		}
	}
	
	access(all)
	fun queueNewRewards(vault: @{FungibleToken.Vault}){ 
		pre{ 
			vault.balance > 0.0:
				"RewardPool: queueNewRewards empty vault"
		}
		let balance = vault.balance
		let receiver =
			self.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
				.borrow()!
		receiver.deposit(from: <-vault)
		self.notifyRewardAmount(rewards: balance)
	}
	
	access(self)
	fun notifyRewardAmount(rewards: UFix64){ 
		self.updateReward(account: nil)
		self.historicalRewards = self.historicalRewards + rewards
		let now = getCurrentBlock().timestamp
		var _rewards = rewards
		if now >= self.periodFinish{ 
			self.rewardRate = _rewards / self.duration
		} else{ 
			let remaining = self.periodFinish - now
			let leftover = remaining * self.rewardRate
			_rewards = _rewards + leftover
			self.rewardRate = _rewards / self.duration
		}
		self.currentRewards = _rewards
		self.lastUpdateTime = now
		self.periodFinish = now + self.duration
	}
	
	access(all)
	resource PoolPublic: StarVaultInterfaces.PoolPublic{ 
		access(all)
		fun pid(): Int{ 
			return RewardPool.pid
		}
		
		access(all)
		fun stakeToken(): Address{ 
			return RewardPool.stakeToken
		}
		
		access(all)
		fun duration(): UFix64{ 
			return RewardPool.duration
		}
		
		access(all)
		fun periodFinish(): UFix64{ 
			return RewardPool.periodFinish
		}
		
		access(all)
		fun rewardRate(): UFix64{ 
			return RewardPool.rewardRate
		}
		
		access(all)
		fun lastUpdateTime(): UFix64{ 
			return RewardPool.lastUpdateTime
		}
		
		access(all)
		fun rewardPerTokenStored(): UFix64{ 
			return RewardPool.rewardPerTokenStored
		}
		
		access(all)
		fun queuedRewards(): UFix64{ 
			return RewardPool.queuedRewards
		}
		
		access(all)
		fun currentRewards(): UFix64{ 
			return RewardPool.currentRewards
		}
		
		access(all)
		fun historicalRewards(): UFix64{ 
			return RewardPool.historicalRewards
		}
		
		access(all)
		fun totalSupply(): UFix64{ 
			return RewardPool.totalSupply
		}
		
		access(all)
		fun balanceOf(account: Address): UFix64{ 
			return RewardPool.balanceOf(account: account)
		}
		
		access(all)
		fun updateReward(account: Address?){ 
			return RewardPool.updateReward(account: account)
		}
		
		access(all)
		fun lastTimeRewardApplicable(): UFix64{ 
			return RewardPool.lastTimeRewardApplicable()
		}
		
		access(all)
		fun rewardPerToken(): UFix64{ 
			return RewardPool.rewardPerToken()
		}
		
		access(all)
		fun earned(account: Address): UFix64{ 
			return RewardPool.earned(account: account)
		}
		
		access(all)
		fun getReward(account: Address){ 
			return RewardPool.getReward(account: account)
		}
		
		access(all)
		fun queueNewRewards(vault: @{FungibleToken.Vault}){ 
			return RewardPool.queueNewRewards(vault: <-vault)
		}
	}
	
	init(pid: Int, stakeToken: Address){ 
		self.pid = pid
		self.stakeToken = stakeToken
		self.duration = 3600.0
		self.periodFinish = 0.0
		self.rewardRate = 0.0
		self.lastUpdateTime = 0.0
		self.rewardPerTokenStored = 0.0
		self.queuedRewards = 0.0
		self.currentRewards = 0.0
		self.historicalRewards = 0.0
		self.totalSupply = 0.0
		self.userRewardPerTokenPaid ={} 
		self.rewards ={} 
		self.balances ={} 
		let poolStoragePath = StarVaultConfig.PoolStoragePath
		destroy <-self.account.storage.load<@AnyResource>(from: poolStoragePath)
		self.account.storage.save(<-create PoolPublic(), to: poolStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&{StarVaultInterfaces.PoolPublic}>(
				poolStoragePath
			)
		self.account.capabilities.publish(capability_1, at: StarVaultConfig.PoolPublicPath)
		let collectionStoragePath = StarVaultConfig.LPStakingCollectionStoragePath
		destroy <-self.account.storage.load<@AnyResource>(from: collectionStoragePath)
		self.account.storage.save(
			<-LPStaking.createEmptyLPStakingCollection(),
			to: collectionStoragePath
		)
		var capability_2 =
			self.account.capabilities.storage.issue<
				&{StarVaultInterfaces.LPStakingCollectionPublic}
			>(collectionStoragePath)
		self.account.capabilities.publish(
			capability_2,
			at: StarVaultConfig.LPStakingCollectionPublicPath
		)
	}
}
