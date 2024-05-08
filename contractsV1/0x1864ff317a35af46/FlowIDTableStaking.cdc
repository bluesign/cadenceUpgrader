/*

	FlowIDTableStaking

	The Flow ID Table and Staking contract manages
	node operators' and delegators' information
	and flow tokens that are staked as part of the Flow Protocol.

	It is recommended to check out the staking page on the Flow Docs site
	before looking at the smart contract. It will help with understanding
	https://docs.onflow.org/token/staking/

	Nodes submit their stake to the public addNodeInfo Function
	during the staking auction phase.

	This records their info and committd tokens. They also will get a Node
	Object that they can use to stake, unstake, and withdraw rewards.

	Each node has multiple token buckets that hold their tokens
	based on their status. committed, staked, unstaked, unlocked, and rewarded.

	The Admin has the authority to remove node records,
	refund insufficiently staked nodes, pay rewards,
	and move tokens between buckets. These will happen once every epoch.

	All the node info and staking info is publicly accessible
	to any transaction in the network

	Node Roles are represented by integers:
		1 = collection
		2 = consensus
		3 = execution
		4 = verification
		5 = access

 */

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract FlowIDTableStaking{ 
	/********************* ID Table and Staking Events **********************/
	access(all)
	event NewNodeCreated(nodeID: String, role: UInt8, amountCommitted: UFix64)
	
	access(all)
	event TokensCommitted(nodeID: String, amount: UFix64)
	
	access(all)
	event TokensStaked(nodeID: String, amount: UFix64)
	
	access(all)
	event TokensUnStaked(nodeID: String, amount: UFix64)
	
	access(all)
	event NodeRemovedAndRefunded(nodeID: String, amount: UFix64)
	
	access(all)
	event RewardsPaid(nodeID: String, amount: UFix64)
	
	access(all)
	event UnlockedTokensWithdrawn(nodeID: String, amount: UFix64)
	
	access(all)
	event RewardTokensWithdrawn(nodeID: String, amount: UFix64)
	
	access(all)
	event NewDelegatorCutPercentage(newCutPercentage: UFix64)
	
	/// Delegator Events
	access(all)
	event NewDelegatorCreated(nodeID: String, delegatorID: UInt32)
	
	access(all)
	event DelegatorRewardsPaid(nodeID: String, delegatorID: UInt32, amount: UFix64)
	
	access(all)
	event DelegatorUnlockedTokensWithdrawn(nodeID: String, delegatorID: UInt32, amount: UFix64)
	
	access(all)
	event DelegatorRewardTokensWithdrawn(nodeID: String, delegatorID: UInt32, amount: UFix64)
	
	/// Holds the identity table for all the nodes in the network.
	/// Includes nodes that aren't actively participating
	/// key = node ID
	/// value = the record of that node's info, tokens, and delegators
	access(contract)
	var nodes: @{String: NodeRecord}
	
	/// The minimum amount of tokens that each node type has to stake
	/// in order to be considered valid
	/// key = node role
	/// value = amount of tokens
	access(contract)
	var minimumStakeRequired:{ UInt8: UFix64}
	
	/// The total amount of tokens that are staked for all the nodes
	/// of each node type during the current epoch
	/// key = node role
	/// value = amount of tokens
	access(contract)
	var totalTokensStakedByNodeType:{ UInt8: UFix64}
	
	/// The total amount of tokens that are paid as rewards every epoch
	/// could be manually changed by the admin resource
	access(all)
	var epochTokenPayout: UFix64
	
	/// The ratio of the weekly awards that each node type gets
	/// key = node role
	/// value = decimal number between 0 and 1 indicating a percentage
	access(contract)
	var rewardRatios:{ UInt8: UFix64}
	
	/// The percentage of rewards that every node operator takes from
	/// the users that are delegating to it
	access(all)
	var nodeDelegatingRewardCut: UFix64
	
	/// Paths for storing staking resources
	access(all)
	let NodeStakerStoragePath: Path
	
	access(all)
	let NodeStakerPublicPath: Path
	
	access(all)
	let StakingAdminStoragePath: StoragePath
	
	access(all)
	let DelegatorStoragePath: Path
	
	/*********** ID Table and Staking Composite Type Definitions *************/
	/// Contains information that is specific to a node in Flow
	/// only lives in this contract
	access(all)
	resource NodeRecord{ 
		
		/// The unique ID of the node
		/// Set when the node is created
		access(all)
		let id: String
		
		/// The type of node:
		/// 1 = collection
		/// 2 = consensus
		/// 3 = execution
		/// 4 = verification
		/// 5 = access
		access(all)
		var role: UInt8
		
		/// The address used for networking
		access(all)
		var networkingAddress: String
		
		/// the public key for networking
		access(all)
		var networkingKey: String
		
		/// the public key for staking
		access(all)
		var stakingKey: String
		
		/// The total tokens that this node currently has staked, including delegators
		/// This value must always be above the minimum requirement to stay staked
		/// or accept delegators
		access(all)
		var tokensStaked: @FlowToken.Vault
		
		/// The tokens that this node has committed to stake for the next epoch.
		access(all)
		var tokensCommitted: @FlowToken.Vault
		
		/// The tokens that this node has unstaked from the previous epoch
		/// Moves to the tokensUnlocked bucket at the end of the epoch.
		access(all)
		var tokensUnstaked: @FlowToken.Vault
		
		/// Tokens that this node is able to withdraw whenever they want
		/// Staking rewards are paid to this bucket
		access(all)
		var tokensUnlocked: @FlowToken.Vault
		
		/// Staking rewards are paid to this bucket
		/// Can be withdrawn whenever
		access(all)
		var tokensRewarded: @FlowToken.Vault
		
		/// list of delegators for this node operator
		access(all)
		let delegators: @{UInt32: DelegatorRecord}
		
		/// The incrementing ID used to register new delegators
		access(all)
		var delegatorIDCounter: UInt32
		
		/// The amount of tokens that this node has requested to unstake
		/// for the next epoch
		access(all)
		var tokensRequestedToUnstake: UFix64
		
		/// weight as determined by the amount staked after the staking auction
		access(all)
		var initialWeight: UInt64
		
		init(
			id: String,
			role: UInt8, /// role that the node will have for future epochs
			
			networkingAddress: String,
			networkingKey: String,
			stakingKey: String,
			tokensCommitted: @{FungibleToken.Vault}
		){ 
			pre{ 
				id.length == 64:
					"Node ID length must be 32 bytes (64 hex characters)"
				FlowIDTableStaking.nodes[id] == nil:
					"The ID cannot already exist in the record"
				role >= UInt8(1) && role <= UInt8(5):
					"The role must be 1, 2, 3, 4, or 5"
				networkingAddress.length > 0:
					"The networkingAddress cannot be empty"
			}
			
			/// Assert that the addresses and keys are not already in use
			/// They must be unique
			for nodeID in FlowIDTableStaking.nodes.keys{ 
				assert(networkingAddress != FlowIDTableStaking.nodes[nodeID]?.networkingAddress, message: "Networking Address is already in use!")
				assert(networkingKey != FlowIDTableStaking.nodes[nodeID]?.networkingKey, message: "Networking Key is already in use!")
				assert(stakingKey != FlowIDTableStaking.nodes[nodeID]?.stakingKey, message: "Staking Key is already in use!")
			}
			self.id = id
			self.role = role
			self.networkingAddress = networkingAddress
			self.networkingKey = networkingKey
			self.stakingKey = stakingKey
			self.initialWeight = 0
			self.delegators <-{} 
			self.delegatorIDCounter = 0
			self.tokensCommitted <- tokensCommitted as! @FlowToken.Vault
			self.tokensStaked <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
				as!
				@FlowToken.Vault
			self.tokensUnstaked <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
				as!
				@FlowToken.Vault
			self.tokensUnlocked <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
				as!
				@FlowToken.Vault
			self.tokensRewarded <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
				as!
				@FlowToken.Vault
			self.tokensRequestedToUnstake = 0.0
			emit NewNodeCreated(
				nodeID: self.id,
				role: self.role,
				amountCommitted: self.tokensCommitted.balance
			)
		}
		
		/// borrow a reference to to one of the delegators for a node in the record
		/// This gives the caller access to all the public fields on the
		/// object and is basically as if the caller owned the object
		/// The only thing they cannot do is destroy it or move it
		/// This will only be used by the other epoch contracts
		access(contract)
		fun borrowDelegatorRecord(_ delegatorID: UInt32): &DelegatorRecord{ 
			pre{ 
				self.delegators[delegatorID] != nil:
					"Specified delegator ID does not exist in the record"
			}
			return &self.delegators[delegatorID] as &FlowIDTableStaking.DelegatorRecord?
		}
	}
	
	// Struct to create to get read-only info about a node
	access(all)
	struct NodeInfo{ 
		access(all)
		let id: String
		
		access(all)
		let role: UInt8
		
		access(all)
		let networkingAddress: String
		
		access(all)
		let networkingKey: String
		
		access(all)
		let stakingKey: String
		
		access(all)
		let tokensStaked: UFix64
		
		access(all)
		let totalTokensStaked: UFix64
		
		access(all)
		let tokensCommitted: UFix64
		
		access(all)
		let tokensUnstaked: UFix64
		
		access(all)
		let tokensUnlocked: UFix64
		
		access(all)
		let tokensRewarded: UFix64
		
		/// list of delegator IDs for this node operator
		access(all)
		let delegators: [UInt32]
		
		access(all)
		let delegatorIDCounter: UInt32
		
		access(all)
		let tokensRequestedToUnstake: UFix64
		
		access(all)
		let initialWeight: UInt64
		
		init(nodeID: String){ 
			let nodeRecord = FlowIDTableStaking.borrowNodeRecord(nodeID)
			self.id = nodeRecord.id
			self.role = nodeRecord.role
			self.networkingAddress = nodeRecord.networkingAddress
			self.networkingKey = nodeRecord.networkingKey
			self.stakingKey = nodeRecord.stakingKey
			self.tokensStaked = nodeRecord.tokensStaked.balance
			self.totalTokensStaked = FlowIDTableStaking.getTotalCommittedBalance(nodeID)
			self.tokensCommitted = nodeRecord.tokensCommitted.balance
			self.tokensUnstaked = nodeRecord.tokensUnstaked.balance
			self.tokensUnlocked = nodeRecord.tokensUnlocked.balance
			self.tokensRewarded = nodeRecord.tokensRewarded.balance
			self.delegators = *nodeRecord.delegators.keys
			self.delegatorIDCounter = nodeRecord.delegatorIDCounter
			self.tokensRequestedToUnstake = nodeRecord.tokensRequestedToUnstake
			self.initialWeight = nodeRecord.initialWeight
		}
	}
	
	/// Records the staking info associated with a delegator
	/// Stored in the NodeRecord resource for the node that a delegator
	/// is associated with
	access(all)
	resource DelegatorRecord{ 
		
		/// Tokens this delegator has committed for the next epoch
		/// The actual tokens are stored in the node's committed bucket
		access(all)
		var tokensCommitted: @FlowToken.Vault
		
		/// Tokens this delegator has staked for the current epoch
		/// The actual tokens are stored in the node's staked bucket
		access(all)
		var tokensStaked: @FlowToken.Vault
		
		/// Tokens this delegator has unstaked and is locked for the current epoch
		access(all)
		var tokensUnstaked: @FlowToken.Vault
		
		/// Tokens this delegator has been rewarded and can withdraw
		access(all)
		let tokensRewarded: @FlowToken.Vault
		
		/// Tokens that this delegator unstaked and can withdraw
		access(all)
		let tokensUnlocked: @FlowToken.Vault
		
		/// Tokens that the delegator has requested to unstake
		access(all)
		var tokensRequestedToUnstake: UFix64
		
		init(){ 
			self.tokensCommitted <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
				as!
				@FlowToken.Vault
			self.tokensStaked <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
				as!
				@FlowToken.Vault
			self.tokensUnstaked <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
				as!
				@FlowToken.Vault
			self.tokensRewarded <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
				as!
				@FlowToken.Vault
			self.tokensUnlocked <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
				as!
				@FlowToken.Vault
			self.tokensRequestedToUnstake = 0.0
		}
	}
	
	/// Struct that can be returned to show all the info about a delegator
	access(all)
	struct DelegatorInfo{ 
		access(all)
		let id: UInt32
		
		access(all)
		let nodeID: String
		
		access(all)
		let tokensCommitted: UFix64
		
		access(all)
		let tokensStaked: UFix64
		
		access(all)
		let tokensUnstaked: UFix64
		
		access(all)
		let tokensRewarded: UFix64
		
		access(all)
		let tokensUnlocked: UFix64
		
		access(all)
		let tokensRequestedToUnstake: UFix64
		
		init(nodeID: String, delegatorID: UInt32){ 
			let nodeRecord = FlowIDTableStaking.borrowNodeRecord(nodeID)
			let delegatorRecord = nodeRecord.borrowDelegatorRecord(delegatorID)
			self.id = delegatorID
			self.nodeID = nodeID
			self.tokensCommitted = delegatorRecord.tokensCommitted.balance
			self.tokensStaked = delegatorRecord.tokensStaked.balance
			self.tokensUnstaked = delegatorRecord.tokensUnstaked.balance
			self.tokensUnlocked = delegatorRecord.tokensUnlocked.balance
			self.tokensRewarded = delegatorRecord.tokensRewarded.balance
			self.tokensRequestedToUnstake = delegatorRecord.tokensRequestedToUnstake
		}
	}
	
	/// Resource that the node operator controls for staking
	access(all)
	resource NodeStaker{ 
		
		/// Unique ID for the node operator
		access(all)
		let id: String
		
		init(id: String){ 
			self.id = id
		}
		
		/// Add new tokens to the system to stake during the next epoch
		access(all)
		fun stakeNewTokens(_ tokens: @{FungibleToken.Vault}){ 
			let nodeRecord = FlowIDTableStaking.borrowNodeRecord(self.id)
			emit TokensCommitted(nodeID: nodeRecord.id, amount: tokens.balance)
			
			/// Add the new tokens to tokens committed
			nodeRecord.tokensCommitted.deposit(from: <-tokens)
		}
		
		/// Stake tokens that are in the tokensUnlocked bucket
		/// but haven't been officially staked
		access(all)
		fun stakeUnlockedTokens(amount: UFix64){ 
			let nodeRecord = FlowIDTableStaking.borrowNodeRecord(self.id)
			
			/// Add the removed tokens to tokens committed
			nodeRecord.tokensCommitted.deposit(
				from: <-nodeRecord.tokensUnlocked.withdraw(amount: amount)
			)
			emit TokensCommitted(nodeID: nodeRecord.id, amount: amount)
		}
		
		/// Stake tokens that are in the tokensRewarded bucket
		/// but haven't been officially staked
		access(all)
		fun stakeRewardedTokens(amount: UFix64){ 
			let nodeRecord = FlowIDTableStaking.borrowNodeRecord(self.id)
			
			/// Add the removed tokens to tokens committed
			nodeRecord.tokensCommitted.deposit(
				from: <-nodeRecord.tokensRewarded.withdraw(amount: amount)
			)
			emit TokensCommitted(nodeID: nodeRecord.id, amount: amount)
		}
		
		/// Request amount tokens to be removed from staking
		/// at the end of the next epoch
		access(all)
		fun requestUnStaking(amount: UFix64){ 
			let nodeRecord = FlowIDTableStaking.borrowNodeRecord(self.id)
			assert(
				nodeRecord.tokensStaked.balance + nodeRecord.tokensCommitted.balance
				>= amount + nodeRecord.tokensRequestedToUnstake,
				message: "Not enough tokens to unstake!"
			)
			assert(
				nodeRecord.delegators.length == 0
				|| nodeRecord.tokensStaked.balance + nodeRecord.tokensCommitted.balance - amount
				>= FlowIDTableStaking.getMinimumStakeRequirements()[nodeRecord.role]!,
				message: "Cannot unstake below the minimum if there are delegators"
			)
			
			/// Get the balance of the tokens that are currently committed
			let amountCommitted = nodeRecord.tokensCommitted.balance
			
			/// If the request can come from committed, withdraw from committed to unlocked
			if amountCommitted >= amount{ 
				
				/// withdraw the requested tokens from committed since they have not been staked yet
				nodeRecord.tokensUnlocked.deposit(from: <-nodeRecord.tokensCommitted.withdraw(amount: amount))
			} else{ 
				/// Get the balance of the tokens that are currently committed
				let amountCommitted = nodeRecord.tokensCommitted.balance
				if amountCommitted > 0.0{ 
					nodeRecord.tokensUnlocked.deposit(from: <-nodeRecord.tokensCommitted.withdraw(amount: amountCommitted))
				}
				
				/// update request to show that leftover amount is requested to be unstaked
				/// at the end of the current epoch
				nodeRecord.tokensRequestedToUnstake = nodeRecord.tokensRequestedToUnstake + (amount - amountCommitted)
			}
		}
		
		/// Requests to unstake all of the node operators staked and committed tokens,
		/// as well as all the staked and committed tokens of all of their delegators
		access(all)
		fun unstakeAll(){ 
			let nodeRecord = FlowIDTableStaking.borrowNodeRecord(self.id)
			
			// iterate through all their delegators, uncommit their tokens
			// and request to unstake their staked tokens
			for delegator in nodeRecord.delegators.keys{ 
				let delRecord = nodeRecord.borrowDelegatorRecord(delegator)
				if delRecord.tokensCommitted.balance > 0.0{ 
					delRecord.tokensUnlocked.deposit(from: <-delRecord.tokensCommitted.withdraw(amount: delRecord.tokensCommitted.balance))
				}
				delRecord.tokensRequestedToUnstake = delRecord.tokensStaked.balance
			}
			
			/// if the request can come from committed, withdraw from committed to unlocked
			if nodeRecord.tokensCommitted.balance >= 0.0{ 
				
				/// withdraw the requested tokens from committed since they have not been staked yet
				nodeRecord.tokensUnlocked.deposit(from: <-nodeRecord.tokensCommitted.withdraw(amount: nodeRecord.tokensCommitted.balance))
			}
			
			/// update request to show that leftover amount is requested to be unstaked
			/// at the end of the current epoch
			nodeRecord.tokensRequestedToUnstake = nodeRecord.tokensStaked.balance
		}
		
		/// Withdraw tokens from the unlocked bucket
		access(all)
		fun withdrawUnlockedTokens(amount: UFix64): @{FungibleToken.Vault}{ 
			let nodeRecord = FlowIDTableStaking.borrowNodeRecord(self.id)
			emit UnlockedTokensWithdrawn(nodeID: nodeRecord.id, amount: amount)
			return <-nodeRecord.tokensUnlocked.withdraw(amount: amount)
		}
		
		/// Withdraw tokens from the rewarded bucket
		access(all)
		fun withdrawRewardedTokens(amount: UFix64): @{FungibleToken.Vault}{ 
			let nodeRecord = FlowIDTableStaking.borrowNodeRecord(self.id)
			emit RewardTokensWithdrawn(nodeID: nodeRecord.id, amount: amount)
			return <-nodeRecord.tokensRewarded.withdraw(amount: amount)
		}
	}
	
	/// Resource object that the delegator stores in their account
	/// to perform staking actions
	access(all)
	resource NodeDelegator{ 
		
		/// Each delegator for a node operator has a unique ID
		access(all)
		let id: UInt32
		
		/// The ID of the node operator that this delegator delegates to
		access(all)
		let nodeID: String
		
		init(id: UInt32, nodeID: String){ 
			self.id = id
			self.nodeID = nodeID
		}
		
		/// Delegate new tokens to the node operator
		access(all)
		fun delegateNewTokens(from: @{FungibleToken.Vault}){ 
			let nodeRecord = FlowIDTableStaking.borrowNodeRecord(self.nodeID)
			let delRecord = nodeRecord.borrowDelegatorRecord(self.id)
			delRecord.tokensCommitted.deposit(from: <-from)
		}
		
		/// Delegate tokens from the unlocked bucket to the node operator
		access(all)
		fun delegateUnlockedTokens(amount: UFix64){ 
			let nodeRecord = FlowIDTableStaking.borrowNodeRecord(self.nodeID)
			let delRecord = nodeRecord.borrowDelegatorRecord(self.id)
			delRecord.tokensCommitted.deposit(
				from: <-delRecord.tokensUnlocked.withdraw(amount: amount)
			)
		}
		
		/// Delegate tokens from the rewards bucket to the node operator
		access(all)
		fun delegateRewardedTokens(amount: UFix64){ 
			let nodeRecord = FlowIDTableStaking.borrowNodeRecord(self.nodeID)
			let delRecord = nodeRecord.borrowDelegatorRecord(self.id)
			delRecord.tokensCommitted.deposit(
				from: <-delRecord.tokensRewarded.withdraw(amount: amount)
			)
		}
		
		/// Request to unstake delegated tokens during the next epoch
		access(all)
		fun requestUnstaking(amount: UFix64){ 
			let nodeRecord = FlowIDTableStaking.borrowNodeRecord(self.nodeID)
			let delRecord = nodeRecord.borrowDelegatorRecord(self.id)
			assert(
				delRecord.tokensStaked.balance + delRecord.tokensCommitted.balance
				>= amount + delRecord.tokensRequestedToUnstake,
				message: "Not enough tokens to unstake!"
			)
			
			/// if the request can come from committed, withdraw from committed to unlocked
			if delRecord.tokensCommitted.balance >= amount{ 
				
				/// withdraw the requested tokens from committed since they have not been staked yet
				delRecord.tokensUnlocked.deposit(from: <-delRecord.tokensCommitted.withdraw(amount: amount))
			} else{ 
				/// Get the balance of the tokens that are currently committed
				let amountCommitted = delRecord.tokensCommitted.balance
				if amountCommitted > 0.0{ 
					delRecord.tokensUnlocked.deposit(from: <-delRecord.tokensCommitted.withdraw(amount: amountCommitted))
				}
				
				/// update request to show that leftover amount is requested to be unstaked
				/// at the end of the current epoch
				delRecord.tokensRequestedToUnstake = delRecord.tokensRequestedToUnstake + (amount - amountCommitted)
			}
		}
		
		/// Withdraw tokens from the unlocked bucket
		access(all)
		fun withdrawUnlockedTokens(amount: UFix64): @{FungibleToken.Vault}{ 
			let nodeRecord = FlowIDTableStaking.borrowNodeRecord(self.nodeID)
			let delRecord = nodeRecord.borrowDelegatorRecord(self.id)
			emit DelegatorUnlockedTokensWithdrawn(
				nodeID: nodeRecord.id,
				delegatorID: self.id,
				amount: amount
			)
			
			/// remove the tokens from the unlocked bucket
			return <-delRecord.tokensUnlocked.withdraw(amount: amount)
		}
		
		/// Withdraw tokens from the rewarded bucket
		access(all)
		fun withdrawRewardedTokens(amount: UFix64): @{FungibleToken.Vault}{ 
			let nodeRecord = FlowIDTableStaking.borrowNodeRecord(self.nodeID)
			let delRecord = nodeRecord.borrowDelegatorRecord(self.id)
			emit DelegatorRewardTokensWithdrawn(
				nodeID: nodeRecord.id,
				delegatorID: self.id,
				amount: amount
			)
			
			/// remove the tokens from the unlocked bucket
			return <-delRecord.tokensRewarded.withdraw(amount: amount)
		}
	}
	
	/// Admin resource that has the ability to create new staker objects,
	/// remove insufficiently staked nodes at the end of the staking auction,
	/// and pay rewards to nodes at the end of an epoch
	access(all)
	resource Admin{ 
		
		/// Remove a node from the record
		access(all)
		fun removeNode(_ nodeID: String): @NodeRecord{ 
			
			// Remove the node from the table
			let node <-
				FlowIDTableStaking.nodes.remove(key: nodeID)
				?? panic("Could not find a node with the specified ID")
			return <-node
		}
		
		/// Iterates through all the registered nodes and if it finds
		/// a node that has insufficient tokens committed for the next epoch
		/// it moves their committed tokens to their unlocked bucket
		/// This will only be called once per epoch
		/// after the staking auction phase
		///
		/// Also sets the initial weight of all the accepted nodes
		access(all)
		fun endStakingAuction(approvedNodeIDs:{ String: Bool}){ 
			let allNodeIDs = FlowIDTableStaking.getNodeIDs()
			
			/// remove nodes that have insufficient stake
			for nodeID in allNodeIDs{ 
				let nodeRecord = FlowIDTableStaking.borrowNodeRecord(nodeID)
				let totalTokensCommitted = FlowIDTableStaking.getTotalCommittedBalance(nodeID)
				
				/// If the tokens that they have committed for the next epoch
				/// do not meet the minimum requirements
				if totalTokensCommitted < FlowIDTableStaking.minimumStakeRequired[nodeRecord.role]! || approvedNodeIDs[nodeID] == nil{ 
					emit NodeRemovedAndRefunded(nodeID: nodeRecord.id, amount: nodeRecord.tokensCommitted.balance + nodeRecord.tokensStaked.balance)
					if nodeRecord.tokensCommitted.balance > 0.0{ 
						/// move their committed tokens back to their unlocked tokens
						nodeRecord.tokensUnlocked.deposit(from: <-nodeRecord.tokensCommitted.withdraw(amount: nodeRecord.tokensCommitted.balance))
					}
					
					/// Set their request to unstake equal to all their staked tokens
					/// since they are forced to unstake
					nodeRecord.tokensRequestedToUnstake = nodeRecord.tokensStaked.balance
					nodeRecord.initialWeight = 0
				} else{ 
					/// Set initial weight of all the committed nodes
					/// TODO: Figure out how to calculate the initial weight for each node
					nodeRecord.initialWeight = 100
				}
			}
		}
		
		/// Called at the end of the epoch to pay rewards to node operators
		/// based on the tokens that they have staked
		access(all)
		fun payRewards(){ 
			let allNodeIDs = FlowIDTableStaking.getNodeIDs()
			let flowTokenMinter =
				FlowIDTableStaking.account.storage.borrow<&FlowToken.Minter>(
					from: /storage/flowTokenMinter
				)
				?? panic("Could not borrow minter reference")
			
			// calculate total reward sum for each node type
			// by multiplying the total amount of rewards by the ratio for each node type
			var rewardsForNodeTypes:{ UInt8: UFix64} ={} 
			rewardsForNodeTypes[UInt8(1)] = FlowIDTableStaking.epochTokenPayout
				* FlowIDTableStaking.rewardRatios[UInt8(1)]!
			rewardsForNodeTypes[UInt8(2)] = FlowIDTableStaking.epochTokenPayout
				* FlowIDTableStaking.rewardRatios[UInt8(2)]!
			rewardsForNodeTypes[UInt8(3)] = FlowIDTableStaking.epochTokenPayout
				* FlowIDTableStaking.rewardRatios[UInt8(3)]!
			rewardsForNodeTypes[UInt8(4)] = FlowIDTableStaking.epochTokenPayout
				* FlowIDTableStaking.rewardRatios[UInt8(4)]!
			rewardsForNodeTypes[UInt8(5)] = 0.0
			
			/// iterate through all the nodes
			for nodeID in allNodeIDs{ 
				let nodeRecord = FlowIDTableStaking.borrowNodeRecord(nodeID)
				if nodeRecord.tokensStaked.balance == 0.0{ 
					continue
				}
				
				/// Calculate the amount of tokens that this node operator receives
				let rewardAmount = rewardsForNodeTypes[nodeRecord.role]! * (nodeRecord.tokensStaked.balance / FlowIDTableStaking.totalTokensStakedByNodeType[nodeRecord.role]!)
				
				/// Mint the tokens to reward the operator
				let tokenReward <- flowTokenMinter.mintTokens(amount: rewardAmount)
				emit RewardsPaid(nodeID: nodeRecord.id, amount: tokenReward.balance)
				
				// Iterate through all delegators and reward them their share
				// of the rewards for the tokens they have staked for this node
				for delegator in nodeRecord.delegators.keys{ 
					let delRecord = nodeRecord.borrowDelegatorRecord(delegator)
					if delRecord.tokensStaked.balance == 0.0{ 
						continue
					}
					let delegatorRewardAmount = rewardsForNodeTypes[nodeRecord.role]! * (delRecord.tokensStaked.balance / FlowIDTableStaking.totalTokensStakedByNodeType[nodeRecord.role]!)
					let delegatorReward <- flowTokenMinter.mintTokens(amount: delegatorRewardAmount)
					
					// take the node operator's cut
					tokenReward.deposit(from: <-delegatorReward.withdraw(amount: delegatorReward.balance * FlowIDTableStaking.nodeDelegatingRewardCut))
					emit DelegatorRewardsPaid(nodeID: nodeRecord.id, delegatorID: delegator, amount: delegatorRewardAmount)
					if delegatorReward.balance > 0.0{ 
						delRecord.tokensRewarded.deposit(from: <-delegatorReward)
					} else{ 
						destroy delegatorReward
					}
				}
				
				/// Deposit the node Rewards into their tokensRewarded bucket
				nodeRecord.tokensRewarded.deposit(from: <-tokenReward)
			}
		}
		
		/// Called at the end of the epoch to move tokens between buckets
		/// for stakers
		/// Tokens that have been committed are moved to the staked bucket
		/// Tokens that were unstaked during the last epoch are fully unlocked
		/// Unstaking requests are filled by moving those tokens from staked to unstaked
		access(all)
		fun moveTokens(){ 
			let allNodeIDs = FlowIDTableStaking.getNodeIDs()
			for nodeID in allNodeIDs{ 
				let nodeRecord = FlowIDTableStaking.borrowNodeRecord(nodeID)
				
				// Update total number of tokens staked by all the nodes of each type
				FlowIDTableStaking.totalTokensStakedByNodeType[nodeRecord.role] = FlowIDTableStaking.totalTokensStakedByNodeType[nodeRecord.role]! + nodeRecord.tokensCommitted.balance
				if nodeRecord.tokensCommitted.balance > 0.0{ 
					emit TokensStaked(nodeID: nodeRecord.id, amount: nodeRecord.tokensCommitted.balance)
					nodeRecord.tokensStaked.deposit(from: <-nodeRecord.tokensCommitted.withdraw(amount: nodeRecord.tokensCommitted.balance))
				}
				if nodeRecord.tokensUnstaked.balance > 0.0{ 
					nodeRecord.tokensUnlocked.deposit(from: <-nodeRecord.tokensUnstaked.withdraw(amount: nodeRecord.tokensUnstaked.balance))
				}
				if nodeRecord.tokensRequestedToUnstake > 0.0{ 
					emit TokensUnStaked(nodeID: nodeRecord.id, amount: nodeRecord.tokensRequestedToUnstake)
					nodeRecord.tokensUnstaked.deposit(from: <-nodeRecord.tokensStaked.withdraw(amount: nodeRecord.tokensRequestedToUnstake))
				}
				
				// move all the delegators' tokens between buckets
				for delegator in nodeRecord.delegators.keys{ 
					let delRecord = nodeRecord.borrowDelegatorRecord(delegator)
					FlowIDTableStaking.totalTokensStakedByNodeType[nodeRecord.role] = FlowIDTableStaking.totalTokensStakedByNodeType[nodeRecord.role]! + delRecord.tokensCommitted.balance
					
					// mark their committed tokens as staked
					if delRecord.tokensCommitted.balance > 0.0{ 
						delRecord.tokensStaked.deposit(from: <-delRecord.tokensCommitted.withdraw(amount: delRecord.tokensCommitted.balance))
					}
					if delRecord.tokensUnstaked.balance > 0.0{ 
						delRecord.tokensUnlocked.deposit(from: <-delRecord.tokensUnstaked.withdraw(amount: delRecord.tokensUnstaked.balance))
					}
					if delRecord.tokensRequestedToUnstake > 0.0{ 
						delRecord.tokensUnstaked.deposit(from: <-delRecord.tokensStaked.withdraw(amount: delRecord.tokensRequestedToUnstake))
						emit TokensUnStaked(nodeID: nodeRecord.id, amount: delRecord.tokensRequestedToUnstake)
					}
					
					// subtract their requested tokens from the total staked for their node type
					FlowIDTableStaking.totalTokensStakedByNodeType[nodeRecord.role] = FlowIDTableStaking.totalTokensStakedByNodeType[nodeRecord.role]! - delRecord.tokensRequestedToUnstake
					delRecord.tokensRequestedToUnstake = 0.0
				}
				
				// subtract their requested tokens from the total staked for their node type
				FlowIDTableStaking.totalTokensStakedByNodeType[nodeRecord.role] = FlowIDTableStaking.totalTokensStakedByNodeType[nodeRecord.role]! - nodeRecord.tokensRequestedToUnstake
				
				// Reset the tokens requested field so it can be used for the next epoch
				nodeRecord.tokensRequestedToUnstake = 0.0
			}
		}
		
		// Changes the total weekly payout to a new value
		access(all)
		fun updateEpochTokenPayout(_ newPayout: UFix64){ 
			FlowIDTableStaking.epochTokenPayout = newPayout
		}
		
		/// Admin calls this to change the percentage
		/// of delegator rewards every node operator takes
		access(all)
		fun changeCutPercentage(_ newCutPercentage: UFix64){ 
			pre{ 
				newCutPercentage > 0.0 && newCutPercentage < 1.0:
					"Cut percentage must be between 0 and 1!"
			}
			FlowIDTableStaking.nodeDelegatingRewardCut = newCutPercentage
			emit NewDelegatorCutPercentage(
				newCutPercentage: FlowIDTableStaking.nodeDelegatingRewardCut
			)
		}
	}
	
	/// Any node can call this function to register a new Node
	/// It returns the resource for nodes that they can store in
	/// their account storage
	access(all)
	fun addNodeRecord(
		id: String,
		role: UInt8,
		networkingAddress: String,
		networkingKey: String,
		stakingKey: String,
		tokensCommitted: @{FungibleToken.Vault}
	): @NodeStaker{ 
		let initialBalance = tokensCommitted.balance
		let newNode <-
			create NodeRecord(
				id: id,
				role: role,
				networkingAddress: networkingAddress,
				networkingKey: networkingKey,
				stakingKey: stakingKey,
				tokensCommitted: <-tokensCommitted
			)
		
		// Insert the node to the table
		FlowIDTableStaking.nodes[id] <-! newNode
		
		// return a new NodeStaker object that the node operator stores in their account
		return <-create NodeStaker(id: id)
	}
	
	/// Registers a new delegator with a unique ID for the specified node operator
	/// and returns a delegator object to the caller
	/// The node operator would make a public capability for potential delegators
	/// to access this function
	access(all)
	fun registerNewDelegator(nodeID: String): @NodeDelegator{ 
		let nodeRecord = FlowIDTableStaking.borrowNodeRecord(nodeID)
		assert(
			FlowIDTableStaking.getTotalCommittedBalance(nodeID)
			> FlowIDTableStaking.minimumStakeRequired[nodeRecord.role]!,
			message: "Cannot register a delegator if the node operator is below the minimum stake"
		)
		nodeRecord.delegatorIDCounter = nodeRecord.delegatorIDCounter + UInt32(1)
		nodeRecord.delegators[nodeRecord.delegatorIDCounter] <-! create DelegatorRecord()
		emit NewDelegatorCreated(nodeID: nodeRecord.id, delegatorID: nodeRecord.delegatorIDCounter)
		return <-create NodeDelegator(id: nodeRecord.delegatorIDCounter, nodeID: nodeRecord.id)
	}
	
	/// borrow a reference to to one of the nodes in the record
	/// This gives the caller access to all the public fields on the
	/// objects and is basically as if the caller owned the object
	/// The only thing they cannot do is destroy it or move it
	/// This will only be used by the other epoch contracts
	access(contract)
	fun borrowNodeRecord(_ nodeID: String): &NodeRecord{ 
		pre{ 
			FlowIDTableStaking.nodes[nodeID] != nil:
				"Specified node ID does not exist in the record"
		}
		return &FlowIDTableStaking.nodes[nodeID] as &FlowIDTableStaking.NodeRecord?
	}
	
	/****************** Getter Functions for the staking Info *******************/
	/// Gets an array of the node IDs that are proposed for the next epoch
	/// Nodes that are proposed are nodes that have enough tokens staked + committed
	/// for the next epoch
	access(all)
	fun getProposedNodeIDs(): [String]{ 
		var proposedNodes: [String] = []
		for nodeID in FlowIDTableStaking.getNodeIDs(){ 
			let delRecord = FlowIDTableStaking.borrowNodeRecord(nodeID)
			if self.getTotalCommittedBalance(nodeID) >= self.minimumStakeRequired[delRecord.role]!{ 
				proposedNodes.append(nodeID)
			}
		}
		return proposedNodes
	}
	
	/// Gets an array of all the nodeIDs that are staked.
	/// Only nodes that are participating in the current epoch
	/// can be staked, so this is an array of all the active
	/// node operators
	access(all)
	fun getStakedNodeIDs(): [String]{ 
		var stakedNodes: [String] = []
		for nodeID in FlowIDTableStaking.getNodeIDs(){ 
			let nodeRecord = FlowIDTableStaking.borrowNodeRecord(nodeID)
			if nodeRecord.tokensStaked.balance >= self.minimumStakeRequired[nodeRecord.role]!{ 
				stakedNodes.append(nodeID)
			}
		}
		return stakedNodes
	}
	
	/// Gets an array of all the node IDs that have ever applied
	access(all)
	fun getNodeIDs(): [String]{ 
		return FlowIDTableStaking.nodes.keys
	}
	
	/// Gets the total amount of tokens that have been staked and
	/// committed for a node. The sum from the node operator and all
	/// its delegators
	access(all)
	fun getTotalCommittedBalance(_ nodeID: String): UFix64{ 
		let nodeRecord = self.borrowNodeRecord(nodeID)
		if nodeRecord.tokensCommitted.balance + nodeRecord.tokensStaked.balance
		< nodeRecord.tokensRequestedToUnstake{ 
			return 0.0
		} else{ 
			var sum: UFix64 = 0.0
			sum = nodeRecord.tokensCommitted.balance + nodeRecord.tokensStaked.balance - nodeRecord.tokensRequestedToUnstake
			for delegator in nodeRecord.delegators.keys{ 
				let delRecord = nodeRecord.borrowDelegatorRecord(delegator)
				sum = sum + delRecord.tokensCommitted.balance + delRecord.tokensStaked.balance - delRecord.tokensRequestedToUnstake
			}
			return sum
		}
	}
	
	/// Functions to return contract fields
	access(all)
	fun getMinimumStakeRequirements():{ UInt8: UFix64}{ 
		return self.minimumStakeRequired
	}
	
	access(all)
	fun getTotalTokensStakedByNodeType():{ UInt8: UFix64}{ 
		return self.totalTokensStakedByNodeType
	}
	
	access(all)
	fun getEpochTokenPayout(): UFix64{ 
		return self.epochTokenPayout
	}
	
	access(all)
	fun getRewardRatios():{ UInt8: UFix64}{ 
		return self.rewardRatios
	}
	
	init(){ 
		self.nodes <-{} 
		self.NodeStakerStoragePath = /storage/flowStaker
		self.NodeStakerPublicPath = /public/flowStaker
		self.StakingAdminStoragePath = /storage/flowStakingAdmin
		self.DelegatorStoragePath = /storage/flowStakingDelegator
		
		// minimum stakes for each node types
		self.minimumStakeRequired ={ 
				UInt8(1): 250000.0,
				UInt8(2): 500000.0,
				UInt8(3): 1250000.0,
				UInt8(4): 135000.0,
				UInt8(5): 0.0
			}
		self.totalTokensStakedByNodeType ={ 
				UInt8(1): 0.0,
				UInt8(2): 0.0,
				UInt8(3): 0.0,
				UInt8(4): 0.0,
				UInt8(5): 0.0
			}
		
		// 1.25M FLOW paid out in the first week. Decreasing in subsequent weeks
		self.epochTokenPayout = 1250000.0
		
		// initialize the cut of rewards that node operators take to 3%
		self.nodeDelegatingRewardCut = 0.03
		
		// The preliminary percentage of rewards that go to each node type every epoch
		// subject to change
		self.rewardRatios ={ 
				UInt8(1): 0.168,
				UInt8(2): 0.518,
				UInt8(3): 0.078,
				UInt8(4): 0.236,
				UInt8(5): 0.0
			}
		
		// save the admin object to storage
		self.account.storage.save(<-create Admin(), to: self.StakingAdminStoragePath)
	}
}
