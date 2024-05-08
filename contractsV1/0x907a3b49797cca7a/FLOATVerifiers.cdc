/**
## The FLOAT Verifiers for FLOATs on Flow Quests

> Author: Bohao Tang<tech@btang.cn>
*/

import FLOAT from "../0x2d4c3caffbeab845/FLOAT.cdc"

import Interfaces from "./Interfaces.cdc"

import UserProfile from "./UserProfile.cdc"

import CompetitionService from "./CompetitionService.cdc"

access(all)
contract FLOATVerifiers{ 
	access(all)
	struct EnsureFLOATExists: FLOAT.IVerifier{ 
		access(all)
		let eventId: UInt64
		
		access(all)
		fun verify(_ params:{ String: AnyStruct}){ 
			let claimee: Address = params["claimee"]! as! Address
			if let collection = getAccount(claimee).capabilities.get<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath).borrow<&FLOAT.Collection>(){ 
				let len = collection.ownedIdsFromEvent(eventId: self.eventId).length
				assert(len > 0, message: "You haven't the required FLOAT: #".concat(self.eventId.toString()))
			} else{ 
				panic("You do not have FLOAT Collection")
			}
		}
		
		init(eventId: UInt64){ 
			self.eventId = eventId
		}
	}
	
	access(all)
	struct BountyCompleted: FLOAT.IVerifier{ 
		access(all)
		let bountyId: UInt64
		
		access(all)
		fun verify(_ params:{ String: AnyStruct}){ 
			let claimee: Address = params["claimee"]! as! Address
			if let profile = getAccount(claimee).capabilities.get<&UserProfile.Profile>(UserProfile.ProfilePublicPath).borrow<&UserProfile.Profile>(){ 
				let isCompleted = profile.isBountyCompleted(bountyId: self.bountyId)
				assert(isCompleted, message: "You didn't finish the bounty #:".concat(self.bountyId.toString()))
			} else{ 
				panic("You do not have Profile resource")
			}
		}
		
		init(bountyId: UInt64){ 
			self.bountyId = bountyId
		}
	}
	
	access(all)
	struct MissionCompleted: FLOAT.IVerifier{ 
		access(all)
		let missionKey: String
		
		access(all)
		fun verify(_ params:{ String: AnyStruct}){ 
			let claimee: Address = params["claimee"]! as! Address
			if let profile = getAccount(claimee).capabilities.get<&UserProfile.Profile>(UserProfile.ProfilePublicPath).borrow<&UserProfile.Profile>(){ 
				let status = profile.getMissionStatus(missionKey: self.missionKey)
				assert(status.completed, message: "You didn't complete the mission #:".concat(self.missionKey))
			} else{ 
				panic("You do not have Profile resource")
			}
		}
		
		init(missionKey: String){ 
			self.missionKey = missionKey
		}
	}
}
