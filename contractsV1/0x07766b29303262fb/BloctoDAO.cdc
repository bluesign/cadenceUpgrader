import Crypto

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import BloctoPass from "../0x0f9df91c9121c460/BloctoPass.cdc"

import BloctoTokenStaking from "../0x0f9df91c9121c460/BloctoTokenStaking.cdc"

import BloctoToken from "../0x0f9df91c9121c460/BloctoToken.cdc"

access(all)
contract BloctoDAO{ 
	access(contract)
	var topics: [Topic]
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	enum CountStatus: UInt8{ 
		access(all)
		case invalid
		
		access(all)
		case success
		
		access(all)
		case finished
	}
	
	// Admin resourse holder can create Proposers
	access(all)
	resource Admin{ 
		access(all)
		fun createProposer(): @BloctoDAO.Proposer{ 
			return <-create Proposer()
		}
	}
	
	// Proposer resource holder can propose new topics
	access(all)
	resource Proposer{ 
		access(all)
		fun addTopic(
			title: String,
			description: String,
			options: [
				String
			],
			startAt: UFix64?,
			endAt: UFix64?,
			minVoteStakingAmount: UFix64?
		){ 
			BloctoDAO.topics.append(
				Topic(
					proposer: (self.owner!).address,
					title: title,
					description: description,
					options: options,
					startAt: startAt,
					endAt: endAt,
					minVoteStakingAmount: minVoteStakingAmount
				)
			)
		}
		
		access(all)
		fun updateTopic(
			id: Int,
			title: String?,
			description: String?,
			startAt: UFix64?,
			endAt: UFix64?,
			voided: Bool?
		){ 
			pre{ 
				BloctoDAO.topics[id].proposer == (self.owner!).address:
					"Only original proposer can update"
			}
			BloctoDAO.topics[id].update(
				title: title,
				description: description,
				startAt: startAt,
				endAt: endAt,
				voided: voided
			)
		}
	}
	
	// Voter resource holder can vote on topics 
	access(all)
	resource Voter{ 
		// voted topic id <-> options index mapping
		access(self)
		var records:{ UInt64: Int}
		
		access(all)
		fun vote(topicId: UInt64, optionIndex: Int){ 
			pre{ 
				self.records[topicId] == nil:
					"Already voted"
				optionIndex < BloctoDAO.topics[topicId].options.length:
					"Invalid option"
			}
			BloctoDAO.topics[topicId].vote(
				voterAddr: (self.owner!).address,
				optionIndex: optionIndex
			)
			self.records[topicId] = optionIndex
		}
		
		access(all)
		fun getVotedOption(topicId: UInt64): Int?{ 
			return self.records[topicId]
		}
		
		init(){ 
			self.records ={} 
		}
	}
	
	access(all)
	struct VoteRecord{ 
		access(all)
		let address: Address
		
		access(all)
		let optionIndex: Int
		
		access(all)
		let amount: UFix64
		
		init(address: Address, optionIndex: Int, amount: UFix64){ 
			self.address = address
			self.optionIndex = optionIndex
			self.amount = amount
		}
	}
	
	access(all)
	struct Topic{ 
		access(all)
		let proposer: Address
		
		access(all)
		var title: String
		
		access(all)
		var description: String
		
		access(all)
		let minVoteStakingAmount: UFix64
		
		access(all)
		var options: [String]
		
		// address <-> address selected options index mapping
		access(self)
		var voted:{ Address: Int}
		
		// options index <-> result mapping
		access(all)
		var votesCountActual: [UFix64]
		
		access(all)
		let createdAt: UFix64
		
		access(all)
		var updatedAt: UFix64
		
		access(all)
		var startAt: UFix64
		
		access(all)
		var endAt: UFix64
		
		access(all)
		var sealed: Bool
		
		access(all)
		var countIndex: Int
		
		access(all)
		var voided: Bool
		
		init(
			proposer: Address,
			title: String,
			description: String,
			options: [
				String
			],
			startAt: UFix64?,
			endAt: UFix64?,
			minVoteStakingAmount: UFix64?
		){ 
			pre{ 
				title.length <= 1000:
					"New title too long"
				description.length <= 1000:
					"New description too long"
			}
			self.proposer = proposer
			self.title = title
			self.options = options
			self.description = description
			self.minVoteStakingAmount = minVoteStakingAmount != nil ? minVoteStakingAmount! : 0.0
			self.votesCountActual = []
			for option in options{ 
				self.votesCountActual.append(0.0)
			}
			self.voted ={} 
			self.sealed = false
			self.countIndex = 0
			self.createdAt = getCurrentBlock().timestamp
			self.updatedAt = getCurrentBlock().timestamp
			self.startAt = startAt != nil ? startAt! : getCurrentBlock().timestamp
			self.endAt = endAt != nil ? endAt! : self.createdAt + 86400.0 * 14.0
			self.voided = false
		}
		
		access(all)
		fun update(
			title: String?,
			description: String?,
			startAt: UFix64?,
			endAt: UFix64?,
			voided: Bool?
		){ 
			pre{ 
				title?.length ?? 0 <= 1000:
					"Title too long"
				description?.length ?? 0 <= 1000:
					"Description too long"
				voided != true:
					"Can't update after started"
				getCurrentBlock().timestamp < self.startAt:
					"Can't update after started"
			}
			self.title = title != nil ? title! : self.title
			self.description = description != nil ? description! : self.description
			self.endAt = endAt != nil ? endAt! : self.endAt
			self.startAt = startAt != nil ? startAt! : self.startAt
			self.voided = voided != nil ? voided! : self.voided
			self.updatedAt = getCurrentBlock().timestamp
		}
		
		access(all)
		fun vote(voterAddr: Address, optionIndex: Int){ 
			pre{ 
				self.isStarted():
					"Vote not started"
				!self.isEnded():
					"Vote ended"
				self.voted[voterAddr] == nil:
					"Already voted"
			}
			let voterStaked = BloctoDAO.getStakedBLT(address: voterAddr)
			assert(voterStaked >= self.minVoteStakingAmount, message: "Not eligible")
			self.voted[voterAddr] = optionIndex
		}
		
		// return if count ended
		access(all)
		fun count(size: Int): CountStatus{ 
			if self.isEnded() == false{ 
				return CountStatus.invalid
			}
			if self.sealed{ 
				return CountStatus.finished
			}
			let votedList = self.voted.keys
			var batchEnd = self.countIndex + size
			if batchEnd > votedList.length{ 
				batchEnd = votedList.length
			}
			while self.countIndex != batchEnd{ 
				let address = votedList[self.countIndex]
				let voterStaked = BloctoDAO.getStakedBLT(address: address)
				let votedOptionIndex = self.voted[address]!
				self.votesCountActual[votedOptionIndex] = self.votesCountActual[votedOptionIndex] + voterStaked
				self.countIndex = self.countIndex + 1
			}
			self.sealed = self.countIndex == votedList.length
			return CountStatus.success
		}
		
		access(all)
		view fun isEnded(): Bool{ 
			return getCurrentBlock().timestamp >= self.endAt
		}
		
		access(all)
		view fun isStarted(): Bool{ 
			return getCurrentBlock().timestamp >= self.startAt
		}
		
		access(all)
		fun getVotes(page: Int, pageSize: Int?): [VoteRecord]{ 
			var records: [VoteRecord] = []
			let size = pageSize != nil ? pageSize! : 100
			let addresses = self.voted.keys
			var pageStart = (page - 1) * size
			var pageEnd = pageStart + size
			if pageEnd > addresses.length{ 
				pageEnd = addresses.length
			}
			while pageStart < pageEnd{ 
				let address = addresses[pageStart]
				let optionIndex = self.voted[address]!
				let amount = BloctoDAO.getStakedBLT(address: address)
				records.append(VoteRecord(address: address, optionIndex: optionIndex, amount: amount))
				pageStart = pageStart + 1
			}
			return records
		}
		
		access(all)
		fun getTotalVoted(): Int{ 
			return self.voted.keys.length
		}
	}
	
	access(all)
	fun getStakedBLT(address: Address): UFix64{ 
		let collectionRef =
			getAccount(address).capabilities.get<
				&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}
			>(/public/bloctoPassCollection).borrow<
				&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}
			>()
			?? panic("Could not borrow collection public reference")
		let ids = collectionRef.getIDs()
		var amount = 0.0
		for id in ids{ 
			let bloctoPassRef = collectionRef.borrowBloctoPassPublic(id: id)
			let stakerInfo = bloctoPassRef.getStakingInfo()
			amount = amount + stakerInfo.tokensStaked
		}
		return amount
	}
	
	access(all)
	fun getTopics(): [Topic]{ 
		return self.topics
	}
	
	access(all)
	fun getTopicsLength(): Int{ 
		return self.topics.length
	}
	
	access(all)
	fun getTopic(id: UInt64): Topic{ 
		return self.topics[id]
	}
	
	access(all)
	fun count(topicId: UInt64, maxSize: Int): CountStatus{ 
		return self.topics[topicId].count(size: maxSize)
	}
	
	access(all)
	fun initVoter(): @BloctoDAO.Voter{ 
		return <-create Voter()
	}
	
	init(){ 
		self.topics = []
		self.AdminStoragePath = /storage/bloctoDAOAdmin
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
