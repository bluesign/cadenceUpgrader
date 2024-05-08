import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import Interfaces from "./Interfaces.cdc"

import Helper from "./Helper.cdc"

access(all)
contract QueryStructs{ 
	access(all)
	struct BountyInfo{ 
		access(all)
		let id: UInt64
		
		access(all)
		let identifier:{ Interfaces.BountyEntityIdentifier}
		
		access(all)
		let properties:{ UInt8: Bool}
		
		access(all)
		let display: MetadataViews.Display
		
		access(all)
		let missionDetail: Interfaces.MissionDetail?
		
		access(all)
		let questDetail: Interfaces.QuestDetail?
		
		// bounty data
		access(all)
		let preconditions: [{Interfaces.UnlockCondition}]
		
		access(all)
		let participants:{ Address:{ String: AnyStruct}}
		
		access(all)
		let participantAmt: UInt64
		
		// reward info
		access(all)
		let rewardType: Helper.MissionRewardType
		
		access(all)
		let pointReward: Helper.PointReward?
		
		access(all)
		let floatReward: Helper.FLOATReward?
		
		init(
			id: UInt64,
			identifier:{ Interfaces.BountyEntityIdentifier},
			properties:{ 
				UInt8: Bool
			},
			display: MetadataViews.Display,
			missionDetail: Interfaces.MissionDetail?,
			questDetail: Interfaces.QuestDetail?,
			preconditions: [{
				Interfaces.UnlockCondition}
			],
			participants:{ 
				Address:{ 
					String: AnyStruct
				}
			},
			participantAmt: UInt64,
			rewardType: Helper.MissionRewardType,
			pointReward: Helper.PointReward?,
			floatReward: Helper.FLOATReward?
		){ 
			self.id = id
			self.identifier = identifier
			self.properties = properties
			self.display = display
			self.missionDetail = missionDetail
			self.questDetail = questDetail
			self.preconditions = preconditions
			self.participants = participants
			self.participantAmt = participantAmt
			self.rewardType = rewardType
			self.pointReward = pointReward
			self.floatReward = floatReward
		}
	}
	
	access(all)
	struct MissionData{ 
		access(all)
		let identifier:{ Interfaces.BountyEntityIdentifier}
		
		access(all)
		let display: MetadataViews.Display
		
		access(all)
		let detail: Interfaces.MissionDetail
		
		init(
			identifier:{ Interfaces.BountyEntityIdentifier},
			display: MetadataViews.Display,
			detail: Interfaces.MissionDetail
		){ 
			self.identifier = identifier
			self.display = display
			self.detail = detail
		}
	}
	
	access(all)
	struct QuestData{ 
		access(all)
		let identifier:{ Interfaces.BountyEntityIdentifier}
		
		access(all)
		let display: MetadataViews.Display
		
		access(all)
		let detail: Interfaces.QuestDetail
		
		init(
			identifier:{ Interfaces.BountyEntityIdentifier},
			display: MetadataViews.Display,
			detail: Interfaces.QuestDetail
		){ 
			self.identifier = identifier
			self.display = display
			self.detail = detail
		}
	}
}
