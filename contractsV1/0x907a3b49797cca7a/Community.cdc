/**
## The contract of Community Space on Flow Quest

> Author: Bohao Tang<tech@btang.cn>

*/

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import Interfaces from "./Interfaces.cdc"

import Helper from "./Helper.cdc"

access(all)
contract Community{ 
	/**	___  ____ ___ _  _ ____
		   *   |__] |__|  |  |__| [__
			*  |	|  |  |  |  | ___]
			 *************************/
	
	access(all)
	let CommunityStoragePath: StoragePath
	
	access(all)
	let CommunityPublicPath: PublicPath
	
	/**	____ _  _ ____ _  _ ___ ____
		   *   |___ |  | |___ |\ |  |  [__
			*  |___  \/  |___ | \|  |  ___]
			 ******************************/
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event MissionCreated(key: String, communityId: UInt64, owner: Address, steps: UInt64)
	
	access(all)
	event QuestCreated(
		key: String,
		communityId: UInt64,
		owner: Address,
		missionKeys: [
			String
		],
		achievementHost: Address?,
		achievementId: UInt64?
	)
	
	access(all)
	event QuestAchievementUpdated(
		key: String,
		communityId: UInt64,
		owner: Address,
		achievementHost: Address,
		achievementId: UInt64
	)
	
	access(all)
	event CommunityCreated(
		id: UInt64,
		key: String,
		owner: Address,
		name: String,
		description: String,
		image: String
	)
	
	access(all)
	event CommunityUpdateBasics(
		id: UInt64,
		owner: Address,
		name: String,
		description: String,
		image: String,
		banner: String?
	)
	
	access(all)
	event CommunityUpdateSocial(id: UInt64, owner: Address, key: String, value: String)
	
	access(all)
	event CommunityTransfered(id: UInt64, from: Address, to: Address)
	
	/**	____ ___ ____ ___ ____
		   *   [__   |  |__|  |  |___
			*  ___]  |  |  |  |  |___
			 ************************/
	
	access(contract)
	let communityIdMapping:{ UInt64: Address}
	
	access(contract)
	let communityKeyMapping:{ String: UInt64}
	
	access(contract)
	let entityMapping:{ String: Address}
	
	/**	____ _  _ _  _ ____ ___ _ ____ _  _ ____ _	_ ___ _   _
		   *   |___ |  | |\ | |	 |  | |  | |\ | |__| |	|  |   \_/
			*  |	|__| | \| |___  |  | |__| | \| |  | |___ |  |	|
			 ***********************************************************/
	
	/**
		The identifier of BountyEntity
		*/
	
	access(all)
	struct BountyEntityIdentifier: Interfaces.BountyEntityIdentifier{ 
		access(all)
		let category: Interfaces.BountyType
		
		access(all)
		let communityId: UInt64
		
		access(all)
		let key: String
		
		init(category: Interfaces.BountyType, communityId: UInt64, key: String){ 
			self.category = category
			self.communityId = communityId
			self.key = key
		}
		
		access(all)
		fun getBountyEntity(): &{Interfaces.BountyEntityPublic}{ 
			if self.category == Interfaces.BountyType.quest{ 
				return self.getQuestConfig()
			} else{ 
				return self.getMissionConfig()
			}
		}
		
		access(all)
		fun getMissionConfig(): &MissionConfig{ 
			let community = self.getOwnerCommunity()
			return community.borrowMissionRef(key: self.key) ?? panic("Failed to borrow mission.")
		}
		
		access(all)
		fun getQuestConfig(): &QuestConfig{ 
			let community = self.getOwnerCommunity()
			return community.borrowQuestRef(key: self.key) ?? panic("Failed to borrow quest.")
		}
		
		access(self)
		fun getOwnerCommunity(): &CommunityIns{ 
			let owner = Community.entityMapping[self.key] ?? panic("Failed to found owner address")
			return Community.borrowCommunity(host: owner, id: self.communityId) ?? panic("Failed to borrow community.")
		}
	}
	
	access(all)
	struct MissionConfig: Interfaces.BountyEntityPublic, Interfaces.MissionInfoPublic{ 
		access(all)
		let category: Interfaces.BountyType
		
		access(all)
		let communityId: UInt64
		
		access(all)
		let key: String
		
		access(all)
		let title: String
		
		access(all)
		let description: String
		
		access(all)
		let image: String?
		
		access(all)
		let steps: UInt64
		
		access(all)
		let extra:{ String: String}
		
		// changable
		access(all)
		var stepsCfg: MetadataViews.HTTPFile
		
		init(communityId: UInt64, key: String, title: String, description: String, image: String?, steps: UInt64, stepsCfg: String){ 
			self.category = Interfaces.BountyType.mission
			self.communityId = communityId
			self.key = key
			self.title = title
			self.description = description
			self.image = image
			// details
			self.steps = steps
			// changable
			self.extra ={} 
			self.stepsCfg = MetadataViews.HTTPFile(url: stepsCfg)
		}
		
		// display
		access(all)
		fun getStandardDisplay(): MetadataViews.Display{ 
			var thumbnail:{ MetadataViews.File}? = nil
			if self.image != nil{ 
				thumbnail = MetadataViews.HTTPFile(url: "https://nftstorage.link/ipfs/".concat(self.image!))
			} else{ 
				let ref = Community.borrowCommunityById(id: self.communityId) ?? panic("Community not found")
				thumbnail = ref.getStandardDisplay().thumbnail
			}
			return MetadataViews.Display(name: self.title, description: self.description, thumbnail: thumbnail!)
		}
		
		access(all)
		fun getDetail(): Interfaces.MissionDetail{ 
			return Interfaces.MissionDetail(steps: self.steps, stepsCfg: self.stepsCfg.uri())
		}
		
		// update extra data
		access(contract)
		fun updateExtra(toMerge:{ String: String}){ 
			for key in toMerge.keys{ 
				self.extra[key] = toMerge[key]
			}
		}
		
		access(contract)
		fun updateMissionStepsCfg(stepsCfg: String){ 
			self.stepsCfg = MetadataViews.HTTPFile(url: stepsCfg)
		}
	}
	
	access(all)
	struct QuestConfig: Interfaces.BountyEntityPublic, Interfaces.QuestInfoPublic{ 
		access(all)
		let category: Interfaces.BountyType
		
		access(all)
		let communityId: UInt64
		
		access(all)
		let key: String
		
		access(all)
		let title: String
		
		access(all)
		let description: String
		
		access(all)
		let image: String
		
		access(all)
		let missions: [{Interfaces.BountyEntityIdentifier}]
		
		access(all)
		var achievement: Helper.EventIdentifier?
		
		init(communityId: UInt64, key: String, title: String, description: String, image: String, missions: [BountyEntityIdentifier], achievement: Helper.EventIdentifier?){ 
			self.category = Interfaces.BountyType.quest
			self.communityId = communityId
			self.key = key
			self.title = title
			self.description = description
			self.image = image
			// details
			self.missions = missions
			self.achievement = achievement
		}
		
		// display
		access(all)
		fun getStandardDisplay(): MetadataViews.Display{ 
			return MetadataViews.Display(name: self.title, description: self.description, thumbnail: MetadataViews.HTTPFile(url: "https://nftstorage.link/ipfs/".concat(self.image)))
		}
		
		access(all)
		fun getDetail(): Interfaces.QuestDetail{ 
			return Interfaces.QuestDetail(missions: self.missions, achievement: self.achievement)
		}
		
		access(contract)
		fun updateAchievement(achi: Helper.EventIdentifier){ 
			self.achievement = achi
		}
	}
	
	access(all)
	struct CommunityDisplay{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let imageUrl: String
		
		access(all)
		let bannerUrl: String?
		
		access(all)
		let socials:{ String: String}
		
		init(_ ref: &CommunityIns){ 
			self.name = ref.name
			self.description = ref.description
			self.imageUrl = "https://nftstorage.link/ipfs/".concat(ref.imageIpfs)
			self.bannerUrl = ref.bannerIpfs != nil
					? "https://nftstorage.link/ipfs/".concat(ref.bannerIpfs!)
					: nil
			self.socials = *ref.socials
		}
	}
	
	access(all)
	struct CommuntiyBountyBasics{ 
		access(all)
		let category: Interfaces.BountyType
		
		access(all)
		let key: String
		
		access(all)
		let createdAt: UFix64
		
		init(_ category: Interfaces.BountyType, _ key: String, _ createdAt: UFix64){ 
			self.category = category
			self.key = key
			self.createdAt = createdAt
		}
	}
	
	access(all)
	resource interface CommunityPublic{ 
		access(all)
		let key: String
		
		access(all)
		fun getID(): UInt64
		
		access(all)
		fun getStandardDisplay(): MetadataViews.Display
		
		access(all)
		fun getDetailedDisplay(): CommunityDisplay
		
		access(all)
		fun getMissionKeys(): [String]
		
		access(all)
		fun getQuestKeys(): [String]
		
		access(all)
		fun borrowMissionRef(key: String): &MissionConfig?
		
		access(all)
		fun borrowQuestRef(key: String): &QuestConfig?
	}
	
	access(all)
	resource CommunityIns: CommunityPublic, ViewResolver.Resolver{ 
		access(all)
		let key: String
		
		access(all)
		let name: String
		
		access(all)
		var description: String
		
		access(all)
		var imageIpfs: String
		
		access(all)
		var bannerIpfs: String?
		
		access(all)
		let socials:{ String: String}
		
		access(all)
		let bounties: [CommuntiyBountyBasics]
		
		access(contract)
		let missions:{ String: MissionConfig}
		
		access(contract)
		let quests:{ String: QuestConfig}
		
		init(key: String, name: String, description: String, image: String, banner: String?, socials:{ String: String}?){ 
			self.key = key
			self.name = name
			self.description = description
			self.imageIpfs = image
			self.bannerIpfs = banner
			self.socials = socials ??{} 
			self.missions ={} 
			self.quests ={} 
			self.bounties = []
		}
		
		access(all)
		fun updateBasics(desc: String, image: String, banner: String?){ 
			self.description = desc
			self.imageIpfs = image
			self.bannerIpfs = banner
			emit CommunityUpdateBasics(id: self.uuid, owner: (self.owner!).address, name: self.name, description: desc, image: image, banner: banner)
		}
		
		access(all)
		fun updateSocial(key: String, value: String){ 
			self.socials[key] = value
			emit CommunityUpdateSocial(id: self.uuid, owner: (self.owner!).address, key: key, value: value)
		}
		
		access(all)
		fun addMission(key: String, mission: MissionConfig){ 
			pre{ 
				self.owner != nil:
					"Owner exists."
				Community.entityMapping[key] == nil:
					"Mapping bounty entity exists."
				Community.communityIdMapping[mission.communityId] != nil:
					"Community mapping doesn't exist."
			}
			let owner = (self.owner!).address
			Community.entityMapping[key] = owner
			self.missions[key] = mission
			self.bounties.append(CommuntiyBountyBasics(Interfaces.BountyType.mission, key, getCurrentBlock().timestamp))
			emit MissionCreated(key: key, communityId: self.uuid, owner: owner, steps: mission.steps)
		}
		
		access(all)
		fun addQuest(key: String, quest: QuestConfig){ 
			pre{ 
				self.owner != nil:
					"Owner exists."
				Community.entityMapping[key] == nil:
					"Mapping bounty entity exists."
				Community.communityIdMapping[quest.communityId] != nil:
					"Community mapping doesn't exist."
			}
			let owner = (self.owner!).address
			Community.entityMapping[key] = owner
			self.quests[key] = quest
			self.bounties.append(CommuntiyBountyBasics(Interfaces.BountyType.quest, key, getCurrentBlock().timestamp))
			
			// mission keys
			let missionKeys: [String] = []
			for one in quest.missions{ 
				assert(Community.entityMapping[one.key] != nil, message: "Failed to find mission:".concat(one.key))
				missionKeys.append(one.key)
			}
			emit QuestCreated(key: key, communityId: self.uuid, owner: owner, missionKeys: missionKeys, achievementHost: quest.achievement?.host, achievementId: quest.achievement?.eventId)
		}
		
		access(all)
		fun updateQuestAchievement(key: String, achi: Helper.EventIdentifier){ 
			pre{ 
				self.owner != nil:
					"Owner exists."
			}
			let quest = self.borrowQuestRef(key: key) ?? panic("Failed to find quest.")
			quest.updateAchievement(achi: achi)
			emit QuestAchievementUpdated(key: key, communityId: self.uuid, owner: (self.owner!).address, achievementHost: achi.host, achievementId: achi.eventId)
		}
		
		access(all)
		fun updateMissionStepsCfg(key: String, stepsCfg: String){ 
			let mission = self.missions[key] ?? panic("Failed to find mission:".concat(key))
			mission.updateMissionStepsCfg(stepsCfg: stepsCfg)
		}
		
		/************* Internals *************/
		access(contract)
		fun getRef(): &CommunityIns{ 
			return &self as &CommunityIns
		}
		
		/************* Getters (for anyone) *************/
		access(all)
		fun getID(): UInt64{ 
			return self.uuid
		}
		
		access(all)
		fun getMissionKeys(): [String]{ 
			return self.missions.keys
		}
		
		access(all)
		fun getQuestKeys(): [String]{ 
			return self.quests.keys
		}
		
		access(all)
		fun borrowMissionRef(key: String): &MissionConfig?{ 
			return &self.missions[key] as &MissionConfig?
		}
		
		access(all)
		fun borrowQuestRef(key: String): &QuestConfig?{ 
			return &self.quests[key] as &QuestConfig?
		}
		
		access(all)
		fun getStandardDisplay(): MetadataViews.Display{ 
			return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: "https://nftstorage.link/ipfs/".concat(self.imageIpfs)))
		}
		
		access(all)
		fun getDetailedDisplay(): CommunityDisplay{ 
			return CommunityDisplay(self.getRef())
		}
		
		// This is for the MetdataStandard
		access(all)
		view fun getViews(): [Type]{ 
			let supportedViews = [Type<MetadataViews.Display>(), Type<CommunityDisplay>()]
			return supportedViews
		}
		
		// This is for the MetdataStandard
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return self.getStandardDisplay()
				case Type<CommunityDisplay>():
					return self.getDetailedDisplay()
			}
			return nil
		}
	}
	
	access(all)
	resource interface CommunityBuilderPublic{ 
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun borrowCommunity(id: UInt64): &CommunityIns
		
		access(all)
		fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}
		
		access(contract)
		fun takeover(ins: @CommunityIns)
	}
	
	access(all)
	resource CommunityBuilder: CommunityBuilderPublic{ 
		access(contract)
		var communities: @{UInt64: CommunityIns}
		
		init(){ 
			self.communities <-{} 
		}
		
		access(all)
		fun createCommunity(key: String, name: String, description: String, image: String, banner: String?, socials:{ String: String}?): UInt64{ 
			pre{ 
				self.owner?.address != nil:
					"no owner"
				Community.communityKeyMapping[key] == nil:
					"Unique key is occupied"
			}
			let community <- create CommunityIns(key: key, name: name, description: description, image: image, banner: banner, socials: socials)
			let id = community.uuid
			self.communities[id] <-! community
			let owner = (self.owner!).address
			// set to mapping
			Community.communityIdMapping[id] = owner
			Community.communityKeyMapping[key] = id
			emit CommunityCreated(id: id, key: key, owner: owner, name: name, description: description, image: image)
			return id
		}
		
		access(all)
		fun borrowCommunityPrivateRef(id: UInt64): &CommunityIns{ 
			return &self.communities[id] as &CommunityIns? ?? panic("Failed to borrow community.")
		}
		
		access(all)
		fun transferCommunity(id: UInt64, recipient: &CommunityBuilder){ 
			let community <- self.communities.remove(key: id) ?? panic("Failed to transfer community")
			recipient.takeover(ins: <-community)
			emit CommunityTransfered(id: id, from: (self.owner!).address, to: (recipient.owner!).address)
		}
		
		/************* Internal *************/
		access(contract)
		fun takeover(ins: @CommunityIns){ 
			let id = ins.getID()
			self.communities[id] <-! ins
			Community.communityIdMapping[id] = (self.owner!).address
		}
		
		/************* Getters (for anyone) *************/
		access(all)
		fun borrowCommunity(id: UInt64): &CommunityIns{ 
			return &self.communities[id] as &CommunityIns? ?? panic("Failed to borrow community.")
		}
		
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.communities.keys
		}
		
		access(all)
		fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}{ 
			return &self.communities[id] as &{ViewResolver.Resolver}? ?? panic("Failed to borrow community")
		}
	}
	
	access(all)
	struct CommunityIdentitier{ 
		access(all)
		let owner: Address
		
		access(all)
		let key: String
		
		access(all)
		let id: UInt64
		
		init(_ owner: Address, _ key: String, _ id: UInt64){ 
			self.owner = owner
			self.key = key
			self.id = id
		}
		
		access(all)
		fun borrowCommunity(): &CommunityIns?{ 
			return Community.borrowCommunity(host: self.owner, id: self.id)
		}
	}
	
	// ----- public methods -----
	access(all)
	fun createCommunityBuilder(): @CommunityBuilder{ 
		return <-create CommunityBuilder()
	}
	
	// Global borrow community
	/**
		 * Get all communities
		 */
	
	access(all)
	fun getCommunities(): [CommunityIdentitier]{ 
		let ret: [CommunityIdentitier] = []
		for key in self.communityKeyMapping.keys{ 
			if let communityId = self.communityKeyMapping[key]{ 
				if let owner = self.communityIdMapping[communityId]{ 
					ret.append(CommunityIdentitier(owner, key, communityId))
				}
			}
		}
		return ret
	}
	
	access(all)
	fun borrowCommunityByKey(key: String): &CommunityIns?{ 
		if let id = Community.communityKeyMapping[key]{ 
			return Community.borrowCommunityById(id: id)
		}
		return nil
	}
	
	access(all)
	fun borrowCommunityById(id: UInt64): &CommunityIns?{ 
		if let host = Community.communityIdMapping[id]{ 
			return Community.borrowCommunity(host: host, id: id)
		}
		return nil
	}
	
	access(all)
	fun borrowCommunity(host: Address, id: UInt64): &CommunityIns?{ 
		if let builder =
			getAccount(host).capabilities.get<&CommunityBuilder>(Community.CommunityPublicPath)
				.borrow(){ 
			return builder.borrowCommunity(id: id)
		}
		return nil
	}
	
	init(){ 
		self.CommunityStoragePath = /storage/DevCompetitionCommunityPathV3
		self.CommunityPublicPath = /public/DevCompetitionCommunityPathV3
		self.entityMapping ={} 
		self.communityIdMapping ={} 
		self.communityKeyMapping ={} 
		emit ContractInitialized()
	}
}
