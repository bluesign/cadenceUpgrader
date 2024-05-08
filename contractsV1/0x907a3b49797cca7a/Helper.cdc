import FLOAT from "../0x2d4c3caffbeab845/FLOAT.cdc"

access(all)
contract Helper{ 
	
	// -------- FLOAT Event Helper --------
	
	// identifier of an Event
	access(all)
	struct EventIdentifier{ 
		// event owner address
		access(all)
		let host: Address
		
		// event id
		access(all)
		let eventId: UInt64
		
		init(_ address: Address, _ eventId: UInt64){ 
			self.host = address
			self.eventId = eventId
		}
		
		// get the reference of the given event
		access(all)
		fun getEventPublic(): &FLOAT.FLOATEvent{ 
			let ownerEvents =
				getAccount(self.host).capabilities.get<&FLOAT.FLOATEvents>(
					FLOAT.FLOATEventsPublicPath
				).borrow<&FLOAT.FLOATEvents>()
				?? panic("Could not borrow the public FLOATEvents.")
			return ownerEvents.borrowPublicEventRef(eventId: self.eventId)
			?? panic("Failed to get event reference.")
		}
		
		// convert identifier to string
		access(all)
		fun toString(): String{ 
			return self.host.toString().concat("#").concat(self.eventId.toString())
		}
	}
	
	// -------- Mission Rewards --------
	access(all)
	enum MissionRewardType: UInt8{ 
		access(all)
		case Points
		
		access(all)
		case FLOAT
		
		access(all)
		case None
	}
	
	access(all)
	struct interface RewardInfo{ 
		access(all)
		let type: MissionRewardType
	}
	
	access(all)
	struct PointReward: RewardInfo{ 
		access(all)
		let type: MissionRewardType
		
		access(all)
		let rewardPoints: UInt64
		
		access(all)
		let referralPoints: UInt64
		
		init(_ points: UInt64, _ referralPoints: UInt64?){ 
			self.type = MissionRewardType.Points
			self.rewardPoints = points
			self.referralPoints = referralPoints ?? 0
		}
	}
	
	access(all)
	struct FLOATReward: RewardInfo{ 
		access(all)
		let type: MissionRewardType
		
		access(all)
		let eventIdentifier: EventIdentifier
		
		init(_ identifier: EventIdentifier){ 
			self.type = MissionRewardType.FLOAT
			self.eventIdentifier = identifier
		}
	}
	
	access(all)
	struct NoneReward: RewardInfo{ 
		access(all)
		let type: MissionRewardType
		
		init(){ 
			self.type = MissionRewardType.None
		}
	}
}
