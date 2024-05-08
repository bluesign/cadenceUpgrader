// import sFlowToken from "../"./sFlowToken.cdc"/sFlowToken.cdc"

// Testnet
// import FungibleToken from "../0x9a0766d93b6608b7/FungibleToken.cdc"
// import FlowToken from "../0x7e60df042a9c0868/FlowToken.cdc"
// import FlowStakingCollection from "../0x95e019a17d0e23d7/FlowStakingCollection.cdc"
// import FlowIDTableStaking from "../0x9eca2b38b18b5dfe/FlowIDTableStaking.cdc"

// Mainnet
import sFlowToken from "./sFlowToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FlowStakingCollection from "../0x8d0e87b65159ae63/FlowStakingCollection.cdc"

import FlowIDTableStaking from "../0x8624b52f9ddcd04a/FlowIDTableStaking.cdc"

access(all)
contract sFlowStakingManagerV3{ 
	access(contract)
	var unstakeRequests: [UnstakeRequest]
	
	access(contract)
	var poolFee: UFix64
	
	access(contract)
	var nodeID: String
	
	access(contract)
	var delegatorID: UInt32
	
	access(contract)
	var prevNodeID: String
	
	access(contract)
	var prevDelegatorID: UInt32
	
	access(all)
	event StakeDeposited(amount: UFix64)
	
	access(all)
	event StakeWithdrawn(amount: UFix64)
	
	access(all)
	event StakeFastWithdrawn(amount: UFix64)
	
	access(all)
	event FeesTaken(amount: UFix64)
	
	access(all)
	struct UnstakeRequest{ 
		access(all)
		let address: Address
		
		access(all)
		let amount: UFix64
		
		init(address: Address, amount: UFix64){ 
			self.address = address
			self.amount = amount
		}
	}
	
	// getters
	access(all)
	fun getPoolFee(): UFix64{ 
		return sFlowStakingManagerV3.poolFee
	}
	
	access(all)
	fun getNodeId(): String{ 
		return sFlowStakingManagerV3.nodeID
	}
	
	access(all)
	fun getDelegatorId(): UInt32{ 
		return self.delegatorID
	}
	
	access(all)
	fun getPrevNodeId(): String{ 
		return self.prevNodeID
	}
	
	access(all)
	fun getPrevDelegatorId(): UInt32{ 
		return self.prevDelegatorID
	}
	
	access(all)
	fun getUnstakeRequests(): [UnstakeRequest]{ 
		return self.unstakeRequests
	}
	
	access(all)
	fun isStakingEnabled(): Bool{ 
		return FlowIDTableStaking.stakingEnabled()
	}
	
	// This returns flow that is not yet delegated (aka the balance of the account)
	access(all)
	fun getAccountFlowBalance(): UFix64{ 
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
		for info in delegatingInfo{ 
			if info.nodeID == self.nodeID && info.id == self.delegatorID{ 
				return info
			}
		}
		panic("No Delegating Information")
	}
	
	access(all)
	fun getsFlowPrice(): UFix64{ 
		let undelegatedFlowBalance = self.getAccountFlowBalance()
		let delegatingInfo =
			FlowStakingCollection.getAllDelegatorInfo(address: self.account.address)
		var delegatedFlowBalance = 0.0
		for info in delegatingInfo{ 
			delegatedFlowBalance = delegatedFlowBalance + info.tokensCommitted + info.tokensStaked + info.tokensUnstaking + info.tokensUnstaked + info.tokensRewarded
		}
		if undelegatedFlowBalance + delegatedFlowBalance == 0.0{ 
			return 1.0
		}
		if sFlowToken.totalSupply == 0.0{ 
			return 1.0
		}
		return (undelegatedFlowBalance + delegatedFlowBalance) / sFlowToken.totalSupply
	}
	
	// Convinience Methods
	access(contract)
	fun borrowFlowVault(): &FlowToken.Vault{ 
		let flowVault =
			self.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Could not borrow Manager's Flow Vault")
		return flowVault
	}
	
	access(contract)
	fun borrowStakingCollection(): &FlowStakingCollection.StakingCollection{ 
		let stakingCollection =
			self.account.storage.borrow<&FlowStakingCollection.StakingCollection>(
				from: FlowStakingCollection.StakingCollectionStoragePath
			)
			?? panic("Could not borrow ref to StakingCollection")
		return stakingCollection
	}
	
	access(contract)
	fun borrowsFlowMinterVault(): &sFlowToken.Minter{ 
		let minterVault =
			self.account.storage.borrow<&sFlowToken.Minter>(from: /storage/sFlowTokenMinter)
			?? panic("Could not borrow Manager's Minter Vault")
		return minterVault
	}
	
	access(contract)
	fun borrowsFlowVault(): &sFlowToken.Vault{ 
		let sFlowVault =
			self.account.storage.borrow<&sFlowToken.Vault>(from: /storage/sFlowTokenVault)
			?? panic("Could not borrow sFlow Token Vault")
		return sFlowVault
	}
	
	access(contract)
	fun borrowsFlowBurner(): &sFlowToken.Burner{ 
		let sFlowBurner =
			self.account.storage.borrow<&sFlowToken.Burner>(from: /storage/sFlowTokenBurner)
			?? panic("Could not borrow provider reference to the provider's Burner")
		return sFlowBurner
	}
	
	access(all)
	fun stake(from: @{FungibleToken.Vault}): @sFlowToken.Vault{ 
		let vault <- from as! @FlowToken.Vault
		let sFlowPrice: UFix64 = self.getsFlowPrice()
		let amount: UFix64 = vault.balance / sFlowPrice
		let managerFlowVault = self.borrowFlowVault()
		managerFlowVault.deposit(from: <-vault)
		let stakingCollectionRef = self.borrowStakingCollection()
		stakingCollectionRef.stakeNewTokens(
			nodeID: self.nodeID,
			delegatorID: self.delegatorID,
			amount: amount * sFlowPrice
		)
		emit StakeDeposited(amount: amount)
		let managerMinterVault = self.borrowsFlowMinterVault()
		return <-managerMinterVault.mintTokens(amount: amount)
	}
	
	access(all)
	fun unstake(accountAddress: Address, from: @{FungibleToken.Vault}){ 
		var withdrawableFlowAmount = 0.0
		let sFlowPrice = self.getsFlowPrice()
		let flowUnstakeAmount = from.balance * sFlowPrice
		let delegationInfo = self.getDelegatorInfo()
		let notAvailableForFastUnstake: Fix64 =
			Fix64(flowUnstakeAmount) - Fix64(delegationInfo.tokensCommitted)
		let managersFlowTokenVault = self.borrowsFlowVault()
		let managersFlowTokenBurnerVault = self.borrowsFlowBurner()
		if delegationInfo.tokensCommitted > 0.0{ 
			var fastUnstakeAmount = 0.0
			if delegationInfo.tokensCommitted > flowUnstakeAmount{ 
				fastUnstakeAmount = flowUnstakeAmount
			}
			if delegationInfo.tokensCommitted < flowUnstakeAmount{ 
				fastUnstakeAmount = delegationInfo.tokensCommitted
			}
			
			// unstake committed tokens
			let stakingCollectionRef: &FlowStakingCollection.StakingCollection = self.account.storage.borrow<&FlowStakingCollection.StakingCollection>(from: FlowStakingCollection.StakingCollectionStoragePath) ?? panic("Could not borrow ref to StakingCollection")
			stakingCollectionRef.requestUnstaking(nodeID: self.nodeID, delegatorID: self.delegatorID, amount: fastUnstakeAmount)
			stakingCollectionRef.withdrawUnstakedTokens(nodeID: self.nodeID, delegatorID: self.delegatorID, amount: fastUnstakeAmount)
			
			// withdraw token vault from protocol
			// send to user
			let unstakerAccount = getAccount(accountAddress)
			let unstakerReceiverRef = unstakerAccount.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow<&{FungibleToken.Receiver}>() ?? panic("Could not borrow receiver reference to recipient's Flow Vault")
			let managerProviderRef = self.borrowFlowVault()
			let managerFlowVault: @{FungibleToken.Vault} <- managerProviderRef.withdraw(amount: fastUnstakeAmount)
			unstakerReceiverRef.deposit(from: <-managerFlowVault)
			
			// Burn sFlow tokens
			let tokensToBurn <- from.withdraw(amount: fastUnstakeAmount / sFlowPrice)
			let tokensToKeep <- from
			managersFlowTokenVault.deposit(from: <-tokensToKeep)
			managersFlowTokenBurnerVault.burnTokens(from: <-tokensToBurn)
			emit StakeFastWithdrawn(amount: fastUnstakeAmount)
		} else{ 
			
			// If there are not tokens committed, we 
			// deposit the sFlow tokens back to the protocol
			// the sFlow tokens will be burned at a later date
			managersFlowTokenVault.deposit(from: <-from)
		}
		
		// Executed if a portion of the requested stake cannot be
		// "fastUnstaked". We create an unstakeRequest ticket to be
		// processed on the next epoch
		if notAvailableForFastUnstake > 0.0{ 
			self.unstakeRequests.append(UnstakeRequest(address: accountAddress, amount: UFix64(notAvailableForFastUnstake)))
			let stakingCollectionRef = self.borrowStakingCollection()
			stakingCollectionRef.requestUnstaking(nodeID: self.nodeID, delegatorID: self.delegatorID, amount: UFix64(notAvailableForFastUnstake))
		}
	}
	
	access(all)
	fun updateStakingCollection(){ 
		let delegatorInfo = self.getDelegatorInfo()
		let stakingCollectionRef = self.borrowStakingCollection()
		let storageAmount = 0.001
		
		// stakeUnstakedTokens is not needed to be called
		// as it will cancel out the tokenRequestedToUnstake
		// stakingCollectionRef.stakeUnstakedTokens(nodeID: self.nodeID, delegatorID: self.delegatorID, amount: delegatorInfo.tokensUnstaked)
		stakingCollectionRef.stakeRewardedTokens(
			nodeID: self.nodeID,
			delegatorID: self.delegatorID,
			amount: delegatorInfo.tokensRewarded
		)
		stakingCollectionRef.stakeNewTokens(
			nodeID: self.nodeID,
			delegatorID: self.delegatorID,
			amount: self.getAccountFlowBalance() - storageAmount
		)
	}
	
	access(all)
	fun processUnstakeRequests(){ 
		let minFlowBalance = 0.001
		let delegatorInfo = self.getDelegatorInfo()
		let stakingCollectionRef = self.borrowStakingCollection()
		if delegatorInfo.tokensUnstaked > 0.0{ 
			stakingCollectionRef.withdrawUnstakedTokens(nodeID: self.nodeID, delegatorID: self.delegatorID, amount: delegatorInfo.tokensUnstaked)
		}
		for index, request in self.unstakeRequests{ 
			let stakingAccount = getAccount(request.address)
			let requestAmount = request.amount
			let withdrawAmount = requestAmount * self.getsFlowPrice()
			if self.getAccountFlowBalance() > withdrawAmount + minFlowBalance{ 
				let unstakerReceiverRef = stakingAccount.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow<&{FungibleToken.Receiver}>() ?? panic("Could not borrow receiver reference to recipient's Flow Vault")
				let providerRef = self.borrowFlowVault()
				let managersFlowTokenVault = self.borrowsFlowVault()
				let managersFlowTokenBurnerVault = self.borrowsFlowBurner()
				let flowVault: @{FungibleToken.Vault} <- providerRef.withdraw(amount: withdrawAmount)
				let burnVault: @{FungibleToken.Vault} <- managersFlowTokenVault.withdraw(amount: withdrawAmount)
				unstakerReceiverRef.deposit(from: <-flowVault)
				managersFlowTokenBurnerVault.burnTokens(from: <-burnVault)
				self.unstakeRequests.removeFirst()
				emit StakeWithdrawn(amount: withdrawAmount)
			}
		}
	}
	
	access(all)
	resource Manager{ 
		init(){} 
		
		access(all)
		fun setNewDelegator(nodeID: String, delegatorID: UInt32){ 
			if nodeID == sFlowStakingManagerV3.nodeID{ 
				panic("Node id is same")
			}
			sFlowStakingManagerV3.prevNodeID = sFlowStakingManagerV3.nodeID
			sFlowStakingManagerV3.prevDelegatorID = sFlowStakingManagerV3.delegatorID
			sFlowStakingManagerV3.nodeID = nodeID
			sFlowStakingManagerV3.delegatorID = delegatorID
		}
		
		access(all)
		fun setPoolFee(amount: UFix64){ 
			sFlowStakingManagerV3.poolFee = amount
		}
		
		access(all)
		fun registerNewDelegator(id: String, amount: UFix64){ 
			let stakingCollectionRef: &FlowStakingCollection.StakingCollection =
				sFlowStakingManagerV3.account.storage.borrow<
					&FlowStakingCollection.StakingCollection
				>(from: FlowStakingCollection.StakingCollectionStoragePath)
				?? panic("Could not borrow ref to StakingCollection")
			stakingCollectionRef.registerDelegator(nodeID: id, amount: amount)
		}
		
		access(all)
		fun unstakeAll(nodeId: String, delegatorId: UInt32){ 
			let delegatingInfo =
				FlowStakingCollection.getAllDelegatorInfo(
					address: sFlowStakingManagerV3.account.address
				)
			if delegatingInfo.length == 0{ 
				panic("No Delegating Information")
			}
			for info in delegatingInfo{ 
				if info.nodeID == nodeId && info.id == delegatorId{ 
					let stakingCollectionRef: &FlowStakingCollection.StakingCollection = sFlowStakingManagerV3.account.storage.borrow<&FlowStakingCollection.StakingCollection>(from: FlowStakingCollection.StakingCollectionStoragePath) ?? panic("Could not borrow ref to StakingCollection")
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
	
	init(nodeID: String, delegatorID: UInt32){ 
		self.unstakeRequests = []
		self.poolFee = 0.0
		self.nodeID = nodeID
		self.delegatorID = delegatorID
		self.prevNodeID = ""
		self.prevDelegatorID = 0
		
		/// create a single admin collection and store it
		self.account.storage.save(<-create Manager(), to: /storage/sFlowStakingManagerV3)
		var capability_1 =
			self.account.capabilities.storage.issue<&sFlowStakingManagerV3.Manager>(
				/storage/sFlowStakingManagerV3
			)
		self.account.capabilities.publish(capability_1, at: /private/sFlowStakingManagerV3)
		?? panic("Could not get a capability to the manager")
	}
}
