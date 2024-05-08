import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract QuestReward: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Events
	// -----------------------------------------------------------------------
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// -----------------------------------------------------------------------
	// Contract Events
	// -----------------------------------------------------------------------
	access(all)
	event Minted(id: UInt64, minterID: UInt64, rewardTemplateID: UInt32, rewardTemplate: RewardTemplate, minterAddress: Address?)
	
	access(all)
	event RewardTemplateAdded(minterID: UInt64, minterAddress: Address?, rewardTemplateID: UInt32, name: String, description: String, image: String)
	
	access(all)
	event RewardTemplateUpdated(minterID: UInt64, minterAddress: Address?, rewardTemplateID: UInt32, name: String, description: String, image: String)
	
	// -----------------------------------------------------------------------
	// Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	// -----------------------------------------------------------------------
	// Contract Fields
	// -----------------------------------------------------------------------
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var rewardTemplateSupply: UInt32
	
	access(all)
	var minterSupply: UInt64
	
	access(self)
	var numberMintedPerRewardTemplate:{ UInt32: UInt64}
	
	// -----------------------------------------------------------------------
	// Future Contract Extensions
	// -----------------------------------------------------------------------
	access(self)
	var metadata:{ String: AnyStruct}
	
	access(self)
	var resources: @{String: AnyResource}
	
	access(all)
	struct RewardTemplate{ 
		access(all)
		let minterID: UInt64
		
		access(all)
		let id: UInt32
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let image: String
		
		init(minterID: UInt64, id: UInt32, name: String, description: String, image: String){ 
			self.minterID = minterID
			self.id = id
			self.name = name
			self.description = description
			self.image = image
		}
	}
	
	access(all)
	resource interface Public{ 
		access(all)
		let id: UInt64
		
		access(all)
		let minterID: UInt64
		
		access(all)
		let rewardTemplateID: UInt32
		
		access(all)
		let dateMinted: UFix64
		
		access(all)
		var revealed: Bool
	}
	
	access(all)
	resource NFT: Public, NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let minterID: UInt64
		
		access(all)
		let rewardTemplateID: UInt32
		
		access(all)
		let dateMinted: UFix64
		
		access(all)
		var revealed: Bool
		
		access(self)
		var metadata:{ String: AnyStruct}
		
		access(self)
		var resources: @{String: AnyResource}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(minterID: UInt64, rewardTemplateID: UInt32, rewardTemplate: RewardTemplate, minterAddress: Address?){ 
			self.id = self.uuid
			self.minterID = minterID
			self.rewardTemplateID = rewardTemplateID
			self.dateMinted = getCurrentBlock().timestamp
			self.revealed = false
			self.metadata ={} 
			self.resources <-{} 
			QuestReward.totalSupply = QuestReward.totalSupply + 1
			QuestReward.numberMintedPerRewardTemplate[rewardTemplateID] = QuestReward.numberMintedPerRewardTemplate[rewardTemplateID]! + 1
			emit Minted(id: self.id, minterID: self.minterID, rewardTemplateID: self.rewardTemplateID, rewardTemplate: rewardTemplate, minterAddress: minterAddress)
		}
		
		access(all)
		fun reveal(){ 
			self.revealed = true
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun borrowQuestReward(id: UInt64): &QuestReward.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow QuestReward reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw QuestReward from Collection: Missing NFT")
			emit Withdraw(id: withdrawID, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @QuestReward.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowQuestReward(id: UInt64): &QuestReward.NFT?{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return (ref as! &QuestReward.NFT?)!
		}
		
		access(all)
		fun borrowEntireQuestReward(id: UInt64): &QuestReward.NFT?{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return (ref as! &QuestReward.NFT?)!
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface MinterPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		fun getRewardTemplate(id: UInt32): RewardTemplate?
		
		access(all)
		fun getRewardTemplates():{ UInt32: RewardTemplate}
	}
	
	access(all)
	resource Minter: MinterPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(self)
		var rewardTemplates:{ UInt32: RewardTemplate}
		
		access(self)
		var metadata:{ String: AnyStruct}
		
		access(self)
		var resources: @{String: AnyResource}
		
		init(name: String){ 
			self.id = QuestReward.minterSupply
			self.name = name
			self.rewardTemplates ={} 
			self.metadata ={} 
			self.resources <-{} 
			QuestReward.minterSupply = QuestReward.minterSupply + 1
		}
		
		access(all)
		fun mintReward(rewardTemplateID: UInt32): @NFT{ 
			pre{ 
				self.rewardTemplates[rewardTemplateID] != nil:
					"Reward Template does not exist"
			}
			return <-create NFT(minterID: self.id, rewardTemplateID: rewardTemplateID, rewardTemplate: self.getRewardTemplate(id: rewardTemplateID)!, minterAddress: self.owner?.address)
		}
		
		access(all)
		fun addRewardTemplate(name: String, description: String, image: String){ 
			let id: UInt32 = QuestReward.rewardTemplateSupply
			self.rewardTemplates[id] = RewardTemplate(minterID: self.id, id: id, name: name, description: description, image: image)
			QuestReward.rewardTemplateSupply = QuestReward.rewardTemplateSupply + 1
			QuestReward.numberMintedPerRewardTemplate[id] = 0
			emit RewardTemplateAdded(minterID: self.id, minterAddress: self.owner?.address, rewardTemplateID: id, name: name, description: description, image: image)
		}
		
		access(all)
		fun updateRewardTemplate(id: UInt32, name: String, description: String, image: String){ 
			pre{ 
				self.rewardTemplates[id] != nil:
					"Reward Template does not exist"
			}
			self.rewardTemplates[id] = RewardTemplate(minterID: self.id, id: id, name: name, description: description, image: image)
			emit RewardTemplateUpdated(minterID: self.id, minterAddress: self.owner?.address, rewardTemplateID: id, name: name, description: description, image: image)
		}
		
		access(all)
		fun getRewardTemplate(id: UInt32): RewardTemplate?{ 
			return self.rewardTemplates[id]
		}
		
		access(all)
		fun getRewardTemplates():{ UInt32: RewardTemplate}{ 
			return self.rewardTemplates
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	fun createMinter(name: String): @Minter{ 
		return <-create Minter(name: name)
	}
	
	access(all)
	fun getNumberMintedPerRewardTemplateKeys(): [UInt32]{ 
		return self.numberMintedPerRewardTemplate.keys
	}
	
	access(all)
	fun getNumberMintedPerRewardTemplate(id: UInt32): UInt64?{ 
		return self.numberMintedPerRewardTemplate[id]
	}
	
	access(all)
	fun getNumberMintedPerRewardTemplates():{ UInt32: UInt64}{ 
		return self.numberMintedPerRewardTemplate
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/WonderlandQuestRewardCollection_2
		self.CollectionPublicPath = /public/WonderlandQuestRewardCollection_2
		self.CollectionPrivatePath = /private/WonderlandQuestRewardCollection_2
		self.totalSupply = 0
		self.rewardTemplateSupply = 0
		self.minterSupply = 0
		self.numberMintedPerRewardTemplate ={} 
		self.metadata ={} 
		self.resources <-{} 
		emit ContractInitialized()
	}
}
