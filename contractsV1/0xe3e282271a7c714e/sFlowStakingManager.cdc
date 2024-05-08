import sFlowToken from "./sFlowToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FlowStakingCollection from "../0x8d0e87b65159ae63/FlowStakingCollection.cdc"

import FlowIDTableStaking from "../0x8624b52f9ddcd04a/FlowIDTableStaking.cdc"

access(all)
contract sFlowStakingManager{ 
	
	/// Unstaking Request List
	access(contract)
	var unstakeList: [{String: AnyStruct}]
	
	access(contract)
	var minimumPoolTaking: UFix64
	
	access(contract)
	var nodeID: String
	
	access(contract)
	var delegatorID: UInt32
	
	access(contract)
	var prevNodeID: String
	
	access(contract)
	var prevDelegatorID: UInt32
	
	access(all)
	fun getCurrentUnstakeAmount(userAddress: Address): UFix64{ 
		var requestedUnstakeAmount: UFix64 = 0.0
		for unstakeTicket in sFlowStakingManager.unstakeList{ 
			let tempAddress: AnyStruct = unstakeTicket["address"]!
			let accountAddress: Address = tempAddress as! Address
			let accountStaker = getAccount(accountAddress)
			let tempAmount: AnyStruct = unstakeTicket["amount"]!
			let amount: UFix64 = tempAmount as! UFix64
			if userAddress == accountAddress{ 
				requestedUnstakeAmount = requestedUnstakeAmount + amount
			}
		}
		return requestedUnstakeAmount
	}
	
	access(all)
	fun getCurrentPoolAmount(): UFix64{ 
		let vaultRef =
			self.account.capabilities.get<&FlowToken.Vault>(/public/flowTokenBalance).borrow<
				&FlowToken.Vault
			>()
			?? panic("Could not borrow Balance reference to the Vault")
		return vaultRef.balance
	}
	
	access(all)
	fun getDelegatorInfo(): FlowIDTableStaking.DelegatorInfo{ 
		let delegatingInfo =
			FlowStakingCollection.getAllDelegatorInfo(address: self.account.address)
		if delegatingInfo.length == 0{ 
			panic("No Delegating Information")
		}
		for info in delegatingInfo{ 
			if info.nodeID == self.nodeID && info.id == self.delegatorID{ 
				return info
			}
		}
		panic("No Delegating Information")
	}
	
	access(all)
	fun getPrevDelegatorInfo(): FlowIDTableStaking.DelegatorInfo{ 
		if self.prevNodeID == ""{ 
			panic("No Prev Delegating Information")
		}
		let delegatingInfo =
			FlowStakingCollection.getAllDelegatorInfo(address: self.account.address)
		if delegatingInfo.length == 0{ 
			panic("No Prev Delegating Information")
		}
		for info in delegatingInfo{ 
			if info.nodeID == self.prevNodeID && info.id == self.prevDelegatorID{ 
				return info
			}
		}
		panic("No Prev Delegating Information")
	}
	
	access(all)
	fun getCurrentPrice(): UFix64{ 
		let amountInPool = self.getCurrentPoolAmount()
		var amountInStaking = 0.0
		let delegatingInfo =
			FlowStakingCollection.getAllDelegatorInfo(address: self.account.address)
		for info in delegatingInfo{ 
			amountInStaking = amountInStaking + info.tokensCommitted + info.tokensStaked + info.tokensUnstaking + info.tokensRewarded + info.tokensUnstaked
		}
		if amountInPool + amountInStaking == 0.0 || sFlowToken.totalSupply == 0.0{ 
			return 1.0
		}
		return (amountInPool + amountInStaking) / sFlowToken.totalSupply
	}
	
	access(all)
	fun stake(from: @{FungibleToken.Vault}): @sFlowToken.Vault{ 
		let vault <- from as! @FlowToken.Vault
		let currentPrice: UFix64 = self.getCurrentPrice()
		let amount: UFix64 = vault.balance / currentPrice
		let managerFlowVault =
			self.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Could not borrow Manager's Flow Vault")
		managerFlowVault.deposit(from: <-vault)
		let managerMinterVault =
			self.account.storage.borrow<&sFlowToken.Minter>(from: /storage/sFlowTokenMinter)
			?? panic("Could not borrow Manager's Minter Vault")
		return <-managerMinterVault.mintTokens(amount: amount)
	}
	
	access(all)
	fun unstake(accountAddress: Address, from: @{FungibleToken.Vault}){ 
		self.unstakeList.append({"address": accountAddress, "amount": from.balance})
		let managersFlowTokenVault =
			self.account.storage.borrow<&sFlowToken.Vault>(from: /storage/sFlowTokenVault)
			?? panic("Could not borrow Manager's Minter Vault")
		managersFlowTokenVault.deposit(from: <-from)
	}
	
	access(all)
	fun createInstance(): @Instance{ 
		return <-create Instance()
	}
	
	access(all)
	resource interface InstanceInterface{ 
		access(all)
		fun setCapability(cap: Capability<&Manager>)
		
		access(all)
		fun setNewDelegator(nodeID: String, delegatorID: UInt32)
		
		access(all)
		fun setMinimumPoolTaking(amount: UFix64)
		
		access(all)
		fun registerNewDelegator(id: String, amount: UFix64)
		
		access(all)
		fun unstakeAll(nodeId: String, delegatorId: UInt32)
	}
	
	access(all)
	resource Instance: InstanceInterface{ 
		access(self)
		var managerCapability: Capability<&Manager>?
		
		init(){ 
			self.managerCapability = nil
		}
		
		access(all)
		fun setCapability(cap: Capability<&Manager>){ 
			pre{ 
				cap.borrow() != nil:
					"Invalid manager capability"
			}
			self.managerCapability = cap
		}
		
		access(all)
		fun setNewDelegator(nodeID: String, delegatorID: UInt32){ 
			pre{ 
				self.managerCapability != nil:
					"Cannot manage staking until the manger capability not set"
			}
			let managerRef = (self.managerCapability!).borrow()!
			managerRef.setNewDelegator(nodeID: nodeID, delegatorID: delegatorID)
		}
		
		access(all)
		fun setMinimumPoolTaking(amount: UFix64){ 
			pre{ 
				self.managerCapability != nil:
					"Cannot manage staking until the manger capability not set"
			}
			let managerRef = (self.managerCapability!).borrow()!
			managerRef.setMinimumPoolTaking(amount: amount)
		}
		
		access(all)
		fun registerNewDelegator(id: String, amount: UFix64){ 
			pre{ 
				self.managerCapability != nil:
					"Cannot manage staking until the manger capability not set"
			}
			let managerRef = (self.managerCapability!).borrow()!
			managerRef.registerNewDelegator(id: id, amount: amount)
		}
		
		access(all)
		fun unstakeAll(nodeId: String, delegatorId: UInt32){ 
			pre{ 
				self.managerCapability != nil:
					"Cannot manage staking until the manger capability not set"
			}
			let managerRef = (self.managerCapability!).borrow()!
			managerRef.unstakeAll(nodeId: nodeId, delegatorId: delegatorId)
		}
	}
	
	access(all)
	resource Manager{ 
		init(){} 
		
		access(all)
		fun setNewDelegator(nodeID: String, delegatorID: UInt32){ 
			if nodeID == sFlowStakingManager.nodeID{ 
				panic("Node id is same")
			}
			sFlowStakingManager.prevNodeID = sFlowStakingManager.nodeID
			sFlowStakingManager.prevDelegatorID = sFlowStakingManager.delegatorID
			sFlowStakingManager.nodeID = nodeID
			sFlowStakingManager.delegatorID = delegatorID
		}
		
		access(all)
		fun setMinimumPoolTaking(amount: UFix64){ 
			sFlowStakingManager.minimumPoolTaking = amount
		}
		
		access(all)
		fun registerNewDelegator(id: String, amount: UFix64){ 
			let stakingCollectionRef: &FlowStakingCollection.StakingCollection =
				sFlowStakingManager.account.storage.borrow<
					&FlowStakingCollection.StakingCollection
				>(from: FlowStakingCollection.StakingCollectionStoragePath)
				?? panic("Could not borrow ref to StakingCollection")
			stakingCollectionRef.registerDelegator(nodeID: id, amount: amount)
		}
		
		access(all)
		fun unstakeAll(nodeId: String, delegatorId: UInt32){ 
			let delegatingInfo =
				FlowStakingCollection.getAllDelegatorInfo(
					address: sFlowStakingManager.account.address
				)
			if delegatingInfo.length == 0{ 
				panic("No Delegating Information")
			}
			for info in delegatingInfo{ 
				if info.nodeID == nodeId && info.id == delegatorId{ 
					let stakingCollectionRef: &FlowStakingCollection.StakingCollection = sFlowStakingManager.account.storage.borrow<&FlowStakingCollection.StakingCollection>(from: FlowStakingCollection.StakingCollectionStoragePath) ?? panic("Could not borrow ref to StakingCollection")
					if info.tokensCommitted > 0.0 || info.tokensStaked > 0.0{ 
						stakingCollectionRef.requestUnstaking(nodeID: nodeId, delegatorID: delegatorId, amount: info.tokensCommitted + info.tokensStaked)
					}
					if info.tokensRewarded > 0.0{ 
						stakingCollectionRef.withdrawRewardedTokens(nodeID: nodeId, delegatorID: delegatorId, amount: info.tokensRewarded)
					}
					if info.tokensUnstaked > 0.0{ 
						stakingCollectionRef.withdrawUnstakedTokens(nodeID: nodeId, delegatorID: delegatorId, amount: info.tokensUnstaked)
					}
				}
			}
		}
	}
	
	access(all)
	fun manageCollection(){ 
		log("starting manageCollection()")
		let accountStorageAmount = 0.001
		var requiredStakedAmount: UFix64 = 0.0
		var index = 0
		for unstakeTicket in sFlowStakingManager.unstakeList{ 
			let tempAddress: AnyStruct = unstakeTicket["address"]!
			let accountAddress: Address = tempAddress as! Address
			let accountStaker = getAccount(accountAddress)
			let tempAmount: AnyStruct = unstakeTicket["amount"]!
			let amount: UFix64 = tempAmount as! UFix64
			let requiredFlow = amount * sFlowStakingManager.getCurrentPrice()
			if sFlowStakingManager.getCurrentPoolAmount() > requiredFlow + sFlowStakingManager.minimumPoolTaking{ 
				let providerRef = sFlowStakingManager.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("Could not borrow provider reference to the provider's Vault")
				
				// Deposit the withdrawn tokens in the provider's receiver
				let sentVault: @{FungibleToken.Vault} <- providerRef.withdraw(amount: requiredFlow)
				let receiverRef = accountStaker.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow<&{FungibleToken.Receiver}>() ?? panic("Could not borrow receiver reference to the recipient's Vault")
				receiverRef.deposit(from: <-sentVault)
				let managersFlowTokenVault = sFlowStakingManager.account.storage.borrow<&sFlowToken.Vault>(from: /storage/sFlowTokenVault) ?? panic("Could not borrow provider reference to the provider's Vault")
				
				// Deposit the withdrawn tokens in the provider's receiver
				let burningVault: @{FungibleToken.Vault} <- managersFlowTokenVault.withdraw(amount: amount)
				let managersFlowTokenBurnerVault = sFlowStakingManager.account.storage.borrow<&sFlowToken.Burner>(from: /storage/sFlowTokenBurner) ?? panic("Could not borrow provider reference to the provider's Vault")
				managersFlowTokenBurnerVault.burnTokens(from: <-burningVault)
				sFlowStakingManager.unstakeList.remove(at: index)
				continue
			}
			requiredStakedAmount = requiredStakedAmount + requiredFlow
			index = index + 1
		}
		var bStakeNew: Bool = true
		log("required stake amount: ")
		log(requiredStakedAmount)
		if requiredStakedAmount > 0.0{ 
			requiredStakedAmount = requiredStakedAmount + sFlowStakingManager.minimumPoolTaking + accountStorageAmount - sFlowStakingManager.getCurrentPoolAmount()
			let delegatingInfo = sFlowStakingManager.getDelegatorInfo()
			if delegatingInfo.tokensUnstaked > 0.0{ 
				let stakingCollectionRef: &FlowStakingCollection.StakingCollection = sFlowStakingManager.account.storage.borrow<&FlowStakingCollection.StakingCollection>(from: FlowStakingCollection.StakingCollectionStoragePath) ?? panic("Could not borrow ref to StakingCollection")
				var amount: UFix64 = 0.0
				if delegatingInfo.tokensUnstaked >= requiredStakedAmount{ 
					amount = requiredStakedAmount
				} else{ 
					amount = delegatingInfo.tokensUnstaked
				}
				stakingCollectionRef.withdrawUnstakedTokens(nodeID: sFlowStakingManager.nodeID, delegatorID: sFlowStakingManager.delegatorID, amount: amount)
				requiredStakedAmount = requiredStakedAmount - amount
				bStakeNew = false
			}
		}
		log("required stake amount: ")
		log(requiredStakedAmount)
		if requiredStakedAmount > 0.0{ 
			let delegatingInfo = sFlowStakingManager.getDelegatorInfo()
			if delegatingInfo.tokensRewarded > 0.0{ 
				let stakingCollectionRef: &FlowStakingCollection.StakingCollection = sFlowStakingManager.account.storage.borrow<&FlowStakingCollection.StakingCollection>(from: FlowStakingCollection.StakingCollectionStoragePath) ?? panic("Could not borrow ref to StakingCollection")
				var amount: UFix64 = 0.0
				if delegatingInfo.tokensRewarded >= requiredStakedAmount{ 
					amount = requiredStakedAmount
				} else{ 
					amount = delegatingInfo.tokensRewarded
				}
				stakingCollectionRef.withdrawRewardedTokens(nodeID: sFlowStakingManager.nodeID, delegatorID: sFlowStakingManager.delegatorID, amount: amount)
				requiredStakedAmount = requiredStakedAmount - amount
				bStakeNew = false
			}
		}
		log("required stake amount: ")
		log(requiredStakedAmount)
		if requiredStakedAmount > 0.0{ 
			let delegatingInfo = sFlowStakingManager.getDelegatorInfo()
			if delegatingInfo.tokensCommitted > 0.0{ 
				let stakingCollectionRef: &FlowStakingCollection.StakingCollection = sFlowStakingManager.account.storage.borrow<&FlowStakingCollection.StakingCollection>(from: FlowStakingCollection.StakingCollectionStoragePath) ?? panic("Could not borrow ref to StakingCollection")
				var amount: UFix64 = 0.0
				if delegatingInfo.tokensCommitted >= requiredStakedAmount{ 
					amount = requiredStakedAmount
				} else{ 
					amount = delegatingInfo.tokensCommitted
				}
				stakingCollectionRef.requestUnstaking(nodeID: sFlowStakingManager.nodeID, delegatorID: sFlowStakingManager.delegatorID, amount: amount)
				requiredStakedAmount = requiredStakedAmount - amount
				bStakeNew = false
			}
		}
		log("required stake amount: ")
		log(requiredStakedAmount)
		if requiredStakedAmount > 0.0{ 
			let delegatingInfo = sFlowStakingManager.getDelegatorInfo()
			if delegatingInfo.tokensUnstaking + delegatingInfo.tokensRequestedToUnstake < requiredStakedAmount{ 
				let amount: UFix64 = requiredStakedAmount - delegatingInfo.tokensUnstaking - delegatingInfo.tokensRequestedToUnstake
				let stakingCollectionRef: &FlowStakingCollection.StakingCollection = sFlowStakingManager.account.storage.borrow<&FlowStakingCollection.StakingCollection>(from: FlowStakingCollection.StakingCollectionStoragePath) ?? panic("Could not borrow ref to StakingCollection")
				stakingCollectionRef.requestUnstaking(nodeID: sFlowStakingManager.nodeID, delegatorID: sFlowStakingManager.delegatorID, amount: amount)
				bStakeNew = false
			}
		}
		log("required stake amount: ")
		log(requiredStakedAmount)
		if requiredStakedAmount == 0.0 && bStakeNew && FlowIDTableStaking.stakingEnabled(){ 
			let delegatingInfo = sFlowStakingManager.getDelegatorInfo()
			let stakingCollectionRef: &FlowStakingCollection.StakingCollection = sFlowStakingManager.account.storage.borrow<&FlowStakingCollection.StakingCollection>(from: FlowStakingCollection.StakingCollectionStoragePath) ?? panic("Could not borrow ref to StakingCollection")
			stakingCollectionRef.stakeUnstakedTokens(nodeID: sFlowStakingManager.nodeID, delegatorID: sFlowStakingManager.delegatorID, amount: delegatingInfo.tokensUnstaked)
			stakingCollectionRef.stakeRewardedTokens(nodeID: sFlowStakingManager.nodeID, delegatorID: sFlowStakingManager.delegatorID, amount: delegatingInfo.tokensRewarded)
			if sFlowStakingManager.getCurrentPoolAmount() > sFlowStakingManager.minimumPoolTaking{ 
				stakingCollectionRef.stakeNewTokens(nodeID: sFlowStakingManager.nodeID, delegatorID: sFlowStakingManager.delegatorID, amount: sFlowStakingManager.getCurrentPoolAmount() - sFlowStakingManager.minimumPoolTaking - accountStorageAmount)
			}
		}
		if sFlowStakingManager.prevNodeID != "" && FlowIDTableStaking.stakingEnabled(){ 
			let delegatingInfo = sFlowStakingManager.getPrevDelegatorInfo()
			let stakingCollectionRef: &FlowStakingCollection.StakingCollection = sFlowStakingManager.account.storage.borrow<&FlowStakingCollection.StakingCollection>(from: FlowStakingCollection.StakingCollectionStoragePath) ?? panic("Could not borrow ref to StakingCollection")
			if delegatingInfo.tokensCommitted > 0.0 || delegatingInfo.tokensStaked > 0.0{ 
				stakingCollectionRef.requestUnstaking(nodeID: sFlowStakingManager.prevNodeID, delegatorID: sFlowStakingManager.prevDelegatorID, amount: delegatingInfo.tokensCommitted + delegatingInfo.tokensStaked)
			}
			if delegatingInfo.tokensRewarded > 0.0{ 
				stakingCollectionRef.withdrawRewardedTokens(nodeID: sFlowStakingManager.prevNodeID, delegatorID: sFlowStakingManager.prevDelegatorID, amount: delegatingInfo.tokensRewarded)
			}
			if delegatingInfo.tokensUnstaked > 0.0{ 
				stakingCollectionRef.withdrawUnstakedTokens(nodeID: sFlowStakingManager.prevNodeID, delegatorID: sFlowStakingManager.prevDelegatorID, amount: delegatingInfo.tokensUnstaked)
			}
			if delegatingInfo.tokensCommitted == 0.0 && delegatingInfo.tokensStaked == 0.0 && delegatingInfo.tokensUnstaking == 0.0 && delegatingInfo.tokensRewarded == 0.0 && delegatingInfo.tokensUnstaked == 0.0{ 
				sFlowStakingManager.prevNodeID = ""
				sFlowStakingManager.prevDelegatorID = 0
			}
		}
	}
	
	init(nodeID: String, delegatorID: UInt32){ 
		self.unstakeList = []
		
		/// create a single admin collection and store it
		self.account.storage.save(<-create Manager(), to: /storage/sFlowStakingManager)
		var capability_1 =
			self.account.capabilities.storage.issue<&sFlowStakingManager.Manager>(
				/storage/sFlowStakingManager
			)
		self.account.capabilities.publish(capability_1, at: /private/sFlowStakingManager)
		?? panic("Could not get a capability to the manager")
		self.minimumPoolTaking = 0.0
		self.nodeID = nodeID
		self.delegatorID = delegatorID
		self.prevNodeID = ""
		self.prevDelegatorID = 0
	}
}
