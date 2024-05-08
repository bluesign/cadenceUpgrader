/**
## The Interfaces of Flow Quest

> Author: Bohao Tang<tech@btang.cn>

*/

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import Helper from "./Helper.cdc"

access(all)
contract Interfaces{ 
	
	// =================== Profile ====================
	access(all)
	struct LinkedIdentity{ 
		access(all)
		let platform: String
		
		access(all)
		let uid: String
		
		access(all)
		let display: MetadataViews.Display
		
		init(platform: String, uid: String, display: MetadataViews.Display){ 
			self.platform = platform
			self.uid = uid
			self.display = display
		}
	}
	
	access(all)
	struct MissionStatus{ 
		access(all)
		let steps: [Bool]
		
		access(all)
		let completed: Bool
		
		init(steps: [Bool]){ 
			self.steps = steps
			var completed = true
			for one in steps{ 
				completed = one && completed
			}
			self.completed = completed
		}
	}
	
	// Profile
	access(all)
	resource interface ProfilePublic{ 
		// readable
		access(all)
		fun getId(): UInt64
		
		access(all)
		fun getReferredFrom(): Address?
		
		access(all)
		fun getReferralCode(): String?
		
		access(all)
		fun getIdentities(): [LinkedIdentity]
		
		access(all)
		fun getIdentity(platform: String): LinkedIdentity
		
		access(all)
		fun getBountiesCompleted():{ UInt64: UFix64}
		
		access(all)
		fun isBountyCompleted(bountyId: UInt64): Bool
		
		access(all)
		fun getMissionStatus(missionKey: String): MissionStatus
		
		access(all)
		fun getMissionsParticipanted(): [String]
		
		// season points
		access(all)
		fun isRegistered(seasonId: UInt64): Bool
		
		access(all)
		fun getSeasonsJoined(): [UInt64]
		
		access(all)
		fun getSeasonPoints(seasonId: UInt64): UInt64
		
		access(all)
		fun getProfilePoints(): UInt64
		
		// writable
		access(account)
		fun addPoints(seasonId: UInt64, points: UInt64)
		
		access(account)
		fun completeBounty(bountyId: UInt64)
		
		access(account)
		fun updateMissionNewParams(missionKey: String, step: Int, params:{ String: AnyStruct})
		
		access(account)
		fun updateMissionVerificationResult(missionKey: String, step: Int, result: Bool)
		
		access(account)
		fun setupReferralCode(code: String)
	}
	
	// =================== Community ====================
	access(all)
	enum BountyType: UInt8{ 
		access(all)
		case mission
		
		access(all)
		case quest
	}
	
	access(all)
	struct interface BountyEntityIdentifier{ 
		access(all)
		let category: BountyType
		
		// The offchain key of the mission
		access(all)
		let key: String
		
		// The community belongs to
		access(all)
		let communityId: UInt64
		
		// get Bounty Entity
		access(all)
		fun getBountyEntity(): &{BountyEntityPublic}
		
		// To simple string uid
		access(all)
		fun toString(): String{ 
			return self.communityId.toString().concat(":").concat(self.key)
		}
	}
	
	access(all)
	struct interface BountyEntityPublic{ 
		access(all)
		let category: BountyType
		
		// The offchain key of the mission
		access(all)
		let key: String
		
		// The community belongs to
		access(all)
		let communityId: UInt64
		
		// display
		access(all)
		fun getStandardDisplay(): MetadataViews.Display
		
		// To simple string uid
		access(all)
		fun toString(): String{ 
			return self.communityId.toString().concat(":").concat(self.key)
		}
	}
	
	access(all)
	struct interface MissionInfoPublic{ 
		access(all)
		fun getDetail(): MissionDetail
	}
	
	access(all)
	struct MissionDetail{ 
		access(all)
		let steps: UInt64
		
		access(all)
		let stepsCfg: String
		
		init(steps: UInt64, stepsCfg: String){ 
			self.steps = steps
			self.stepsCfg = stepsCfg
		}
	}
	
	access(all)
	struct interface QuestInfoPublic{ 
		access(all)
		fun getDetail(): QuestDetail
	}
	
	access(all)
	struct QuestDetail{ 
		access(all)
		let missions: [{BountyEntityIdentifier}]
		
		access(all)
		let achievement: Helper.EventIdentifier?
		
		init(missions: [{BountyEntityIdentifier}], achievement: Helper.EventIdentifier?){ 
			self.missions = missions
			self.achievement = achievement
		}
	}
	
	// =================== Competition ====================
	access(all)
	struct interface UnlockCondition{ 
		access(all)
		let type: UInt8
		
		access(all)
		fun isUnlocked(_ params:{ String: AnyStruct}): Bool
	}
	
	// Bounty information
	access(all)
	resource interface BountyInfoPublic{ 
		access(all)
		fun getID(): UInt64
		
		access(all)
		fun getPreconditions(): [{UnlockCondition}]
		
		access(all)
		fun getIdentifier():{ BountyEntityIdentifier}
		
		access(all)
		fun getRequiredMissionKeys(): [String]
		
		access(all)
		fun getRewardType(): Helper.MissionRewardType
		
		access(all)
		fun getPointReward(): Helper.PointReward
		
		access(all)
		fun getFLOATReward(): Helper.FLOATReward
	}
	
	// Competition public interface
	access(all)
	resource interface CompetitionPublic{ 
		// status
		access(all)
		fun isActive(): Bool
		
		// information
		access(all)
		fun getSeasonId(): UInt64
		
		// leaderboard
		access(all)
		fun getRank(_ addr: Address): Int
		
		access(all)
		fun getLeaderboardRanking(limit: Int?):{ UInt64: [Address]}
		
		// onProfile
		access(account)
		fun onProfileRegistered(acct: Address)
	}
	
	access(all)
	resource interface CompetitionServicePublic{ 
		access(all)
		fun getReferralAddress(_ code: String): Address?
		
		access(all)
		fun getReferralCode(_ addr: Address): String?
		
		// season
		access(all)
		fun getActiveSeasonID(): UInt64
		
		access(all)
		fun borrowSeason(seasonId: UInt64): &{CompetitionPublic}
		
		// bounties
		access(all)
		fun getBountyIDs(): [UInt64]
		
		access(all)
		fun getPrimaryBountyIDs(): [UInt64]
		
		access(all)
		fun hasBountyByKey(_ key: String): Bool
		
		access(all)
		fun checkBountyCompleteStatus(acct: Address, bountyId: UInt64): Bool
		
		access(all)
		fun borrowBountyInfo(_ bountyId: UInt64): &{BountyInfoPublic}
		
		access(all)
		fun borrowMissionRef(_ missionKey: String): &{BountyEntityPublic, MissionInfoPublic}
		
		access(account)
		fun onBountyCompleted(bountyId: UInt64, acct: Address)
	}
}
