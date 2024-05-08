/**
## The contract of user profile on Flow Quest

> Author: Bohao Tang<tech@btang.cn>

*/

import Interfaces from "./Interfaces.cdc"

access(all)
contract UserProfile{ 
	/**	___  ____ ___ _  _ ____
		   *   |__] |__|  |  |__| [__
			*  |	|  |  |  |  | ___]
			 *************************/
	
	access(all)
	let ProfileStoragePath: StoragePath
	
	access(all)
	let ProfilePublicPath: PublicPath
	
	/**	____ _  _ ____ _  _ ___ ____
		   *   |___ |  | |___ |\ |  |  [__
			*  |___  \/  |___ | \|  |  ___]
			 ******************************/
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event ProfileCreated(profileId: UInt64, referredFrom: Address?)
	
	access(all)
	event ProfileUpsertIdentity(
		profile: Address,
		platform: String,
		uid: String,
		name: String,
		image: String
	)
	
	access(all)
	event ProfileSeasonAddPoints(profile: Address, seasonId: UInt64, points: UInt64)
	
	access(all)
	event ProfileSeasonNewSeason(profile: Address, seasonId: UInt64)
	
	access(all)
	event ProfileBountyCompleted(profile: Address, bountyId: UInt64)
	
	access(all)
	event MissionRecordUpdateParams(
		profile: Address,
		missionKey: String,
		step: Int,
		keys: [
			String
		],
		round: UInt64
	)
	
	access(all)
	event MissionRecordUpdateResult(
		profile: Address,
		missionKey: String,
		step: Int,
		result: Bool,
		round: UInt64
	)
	
	access(all)
	event ProfileSetupReferralCode(profile: Address, code: String)
	
	/**	____ ___ ____ ___ ____
		   *   [__   |  |__|  |  |___
			*  ___]  |  |  |  |  |___
			 ************************/
	
	access(all)
	var totalProfiles: UInt64
	
	access(contract)
	let platformMapping:{ String: Address}
	
	/**	____ _  _ _  _ ____ ___ _ ____ _  _ ____ _	_ ___ _   _
		   *   |___ |  | |\ | |	 |  | |  | |\ | |__| |	|  |   \_/
			*  |	|__| | \| |___  |  | |__| | \| |  | |___ |  |	|
			 ***********************************************************/
	
	access(all)
	struct VerificationStep{ 
		access(all)
		let params: [{String: AnyStruct}]
		
		access(all)
		let results:{ Int: Bool}
		
		init(){ 
			self.params = []
			self.results ={} 
		}
		
		access(contract)
		fun updateParams(idx: Int, params:{ String: AnyStruct}){ 
			pre{ 
				idx <= self.params.length:
					"Out of bound"
			}
			if idx == self.params.length{ 
				self.params.append(params)
			} else{ 
				self.params[idx] = params
			}
		}
		
		access(contract)
		fun updateResult(idx: Int, result: Bool){ 
			pre{ 
				idx <= self.params.length:
					"Out of bound"
				self.results[idx] == nil:
					"Verification result exists"
			}
			self.results[idx] = result
		}
		
		access(all)
		fun isValid(): Bool{ 
			var valid: Bool = false
			for key in self.results.keys{ 
				valid = valid || self.results[key]!
				if valid{ 
					break
				}
			}
			return valid
		}
	}
	
	/**
		Profile mission record
		 */
	
	access(all)
	struct MissionRecord{ 
		access(all)
		let steps: [VerificationStep]
		
		access(all)
		var timesCompleted: UInt64
		
		init(_ stepAmt: Int){ 
			self.timesCompleted = 0
			self.steps = []
			var i = 0
			while i < stepAmt{ 
				self.steps.append(VerificationStep())
				i = i + 1
			}
		}
		
		access(all)
		fun getLatestIndex(): Int{ 
			return Int(self.timesCompleted)
		}
		
		access(contract)
		fun updateVerifactionParams(step: Int, params:{ String: AnyStruct}){ 
			self.steps[step].updateParams(idx: self.getLatestIndex(), params: params)
		}
		
		// latest result and times completed
		access(contract)
		fun updateVerificationResult(step: Int, result: Bool){ 
			self.steps[step].updateResult(idx: self.getLatestIndex(), result: result)
			// update completed one time
			if step == self.steps.length - 1 && result{ 
				self.timesCompleted = self.timesCompleted + 1
			}
		}
	}
	
	access(all)
	struct SeasonRecord{ 
		access(all)
		let seasonId: UInt64
		
		access(all)
		var points: UInt64
		
		init(seasonId: UInt64){ 
			self.seasonId = seasonId
			self.points = 0
		}
		
		// update verification result
		access(contract)
		fun addPoints(points: UInt64){ 
			self.points = self.points + points
		}
	}
	
	// Profile writable
	access(all)
	resource interface ProfilePrivate{ 
		access(all)
		fun registerForNewSeason(seasonId: UInt64)
		
		access(all)
		fun upsertIdentity(platform: String, identity: Interfaces.LinkedIdentity)
	}
	
	access(all)
	resource Profile: Interfaces.ProfilePublic, ProfilePrivate{ 
		access(self)
		let campetitionServiceCap: Capability<&{Interfaces.CompetitionServicePublic}>
		
		access(self)
		var linkedIdentities:{ String: Interfaces.LinkedIdentity}
		
		access(self)
		var seasonScores:{ UInt64: SeasonRecord}
		
		access(self)
		let referredFromAddress: Address?
		
		access(self)
		var referralCode: String?
		
		access(contract)
		var missionScores:{ String: MissionRecord}
		
		access(contract)
		var bountiesCompleted:{ UInt64: UFix64}
		
		init(cap: Capability<&{Interfaces.CompetitionServicePublic}>, referredFrom: Address?){ 
			self.campetitionServiceCap = cap
			self.linkedIdentities ={} 
			self.missionScores ={} 
			self.bountiesCompleted ={} 
			self.referredFromAddress = referredFrom
			self.referralCode = nil
			UserProfile.totalProfiles = UserProfile.totalProfiles + 1
			self.seasonScores ={} 
			self.seasonScores[0] = SeasonRecord(seasonId: 0)
			emit ProfileCreated(profileId: self.uuid, referredFrom: referredFrom)
		}
		
		// ---- readonly methods ----
		access(all)
		fun getId(): UInt64{ 
			return self.uuid
		}
		
		access(all)
		fun getReferredFrom(): Address?{ 
			return self.referredFromAddress
		}
		
		access(all)
		fun getReferralCode(): String?{ 
			return self.referralCode
		}
		
		access(all)
		fun getIdentities(): [Interfaces.LinkedIdentity]{ 
			return self.linkedIdentities.values
		}
		
		access(all)
		fun getIdentity(platform: String): Interfaces.LinkedIdentity{ 
			return self.linkedIdentities[platform] ?? panic("Platform not found.")
		}
		
		access(all)
		fun isRegistered(seasonId: UInt64): Bool{ 
			return self.seasonScores[seasonId] != nil
		}
		
		access(all)
		fun getSeasonsJoined(): [UInt64]{ 
			return self.seasonScores.keys
		}
		
		access(all)
		fun getSeasonPoints(seasonId: UInt64): UInt64{ 
			if let seasonRef = self.borrowSeasonRecordRef(seasonId){ 
				return seasonRef.points
			} else{ 
				return 0
			}
		}
		
		access(all)
		fun getProfilePoints(): UInt64{ 
			if let seasonRef = self.borrowSeasonRecordRef(0){ 
				return seasonRef.points
			} else{ 
				return 0
			}
		}
		
		access(all)
		fun getMissionStatus(missionKey: String): Interfaces.MissionStatus{ 
			let score = self.getMissionScore(missionKey: missionKey)
			let steps: [Bool] = []
			for step in score.steps{ 
				steps.append(step.isValid())
			}
			return Interfaces.MissionStatus(steps: steps)
		}
		
		// get mission score keys
		access(all)
		fun getMissionsParticipanted(): [String]{ 
			return self.missionScores.keys
		}
		
		// get a copy of bountiesCompleted
		access(all)
		fun getBountiesCompleted():{ UInt64: UFix64}{ 
			return self.bountiesCompleted
		}
		
		access(all)
		fun isBountyCompleted(bountyId: UInt64): Bool{ 
			return self.bountiesCompleted[bountyId] != nil
		}
		
		// get a copy of mission score
		access(all)
		fun getMissionScore(missionKey: String): MissionRecord{ 
			return self.missionScores[missionKey] ?? panic("Missing mission record")
		}
		
		// ---- writable methods ----
		access(all)
		fun registerForNewSeason(seasonId: UInt64){ 
			let profileAddr = self.owner?.address ?? panic("Owner not exist")
			let serviceRef = self.campetitionServiceCap.borrow() ?? panic("Failed to get service capability.")
			let competitionRef = serviceRef.borrowSeason(seasonId: seasonId)
			assert(competitionRef.isActive(), message: "Competition is not active.")
			
			// add to competition
			competitionRef.onProfileRegistered(acct: profileAddr)
			assert(self.seasonScores[seasonId] == nil, message: "Already registered.")
			self.seasonScores[seasonId] = SeasonRecord(seasonId: seasonId)
			emit ProfileSeasonNewSeason(profile: profileAddr, seasonId: seasonId)
		}
		
		access(all)
		fun upsertIdentity(platform: String, identity: Interfaces.LinkedIdentity){ 
			let profileAddr = self.owner?.address ?? panic("Owner not exist")
			let uid = platform.concat("#").concat(identity.uid)
			assert(UserProfile.platformMapping[uid] == nil || UserProfile.platformMapping[uid] == profileAddr, message: "Platfrom UID registered")
			UserProfile.platformMapping[uid] = profileAddr
			self.linkedIdentities[platform] = identity
			emit ProfileUpsertIdentity(profile: profileAddr, platform: platform, uid: identity.uid, name: identity.display.name, image: identity.display.thumbnail.uri())
		}
		
		access(account)
		fun addPoints(seasonId: UInt64, points: UInt64){ 
			let profileAddr = self.owner?.address ?? panic("Owner not exist")
			
			// add point to a season
			if let seasonRef = self.borrowSeasonRecordRef(seasonId){ 
				seasonRef.addPoints(points: points)
			} else{ 
				self.registerForNewSeason(seasonId: seasonId)
				let ref = self.borrowSeasonRecordRef(seasonId)!
				ref.addPoints(points: points)
			}
			emit ProfileSeasonAddPoints(profile: profileAddr, seasonId: seasonId, points: points)
		}
		
		access(account)
		fun completeBounty(bountyId: UInt64){ 
			let profileAddr = self.owner?.address ?? panic("Owner not exist")
			let serviceRef = self.campetitionServiceCap.borrow() ?? panic("Failed to get service capability.")
			let bountyInfo = serviceRef.borrowBountyInfo(bountyId)
			let requiredMissions = bountyInfo.getRequiredMissionKeys()
			var invalid = false
			for key in requiredMissions{ 
				let recordRef = self.fetchOrCreateMissionRecordRef(missionKey: key)
				if recordRef.timesCompleted == 0{ 
					invalid = true
					break
				}
			}
			assert(!invalid, message: "required missions are not completed.")
			// set bounties as completed
			self.bountiesCompleted[bountyId] = getCurrentBlock().timestamp
			
			// callback to service
			serviceRef.onBountyCompleted(bountyId: bountyId, acct: profileAddr)
			emit ProfileBountyCompleted(profile: profileAddr, bountyId: bountyId)
		}
		
		access(account)
		fun updateMissionNewParams(missionKey: String, step: Int, params:{ String: AnyStruct}){ 
			let profileAddr = self.owner?.address ?? panic("Owner not exist")
			let missionScoreRef = self.fetchOrCreateMissionRecordRef(missionKey: missionKey)
			missionScoreRef.updateVerifactionParams(step: step, params: params)
			emit MissionRecordUpdateParams(profile: profileAddr, missionKey: missionKey, step: step, keys: params.keys, round: missionScoreRef.timesCompleted)
		}
		
		// latest result and times completed
		access(account)
		fun updateMissionVerificationResult(missionKey: String, step: Int, result: Bool){ 
			let profileAddr = self.owner?.address ?? panic("Owner not exist")
			let missionScoreRef = self.fetchOrCreateMissionRecordRef(missionKey: missionKey)
			missionScoreRef.updateVerificationResult(step: step, result: result)
			emit MissionRecordUpdateResult(profile: profileAddr, missionKey: missionKey, step: step, result: result, round: missionScoreRef.timesCompleted)
		}
		
		access(account)
		fun setupReferralCode(code: String){ 
			pre{ 
				self.referralCode == nil:
					"referral code should be nil"
			}
			let profileAddr = self.owner?.address ?? panic("Owner not exist")
			self.referralCode = code
			emit ProfileSetupReferralCode(profile: profileAddr, code: code)
		}
		
		// ---- internal methods ----
		// get reference of the mission record
		access(self)
		fun fetchOrCreateMissionRecordRef(missionKey: String): &MissionRecord{ 
			var record = &self.missionScores[missionKey] as &MissionRecord?
			if record == nil{ 
				let serviceRef = self.campetitionServiceCap.borrow() ?? panic("Failed to get service capability.")
				let info = serviceRef.borrowMissionRef(missionKey)
				let missionDetail = info.getDetail()
				self.missionScores[missionKey] = MissionRecord(Int(missionDetail.steps))
				record = &self.missionScores[missionKey] as &MissionRecord?
			}
			return record!
		}
		
		access(self)
		fun borrowSeasonRecordRef(_ seasonId: UInt64): &SeasonRecord?{ 
			return &self.seasonScores[seasonId] as &SeasonRecord?
		}
	}
	
	// ---- public methods ----
	access(all)
	fun createUserProfile(
		serviceCap: Capability<&{Interfaces.CompetitionServicePublic}>,
		_ referredFrom: Address?
	): @Profile{ 
		return <-create Profile(cap: serviceCap, referredFrom: referredFrom)
	}
	
	access(all)
	fun borrowUserProfilePublic(_ acct: Address): &Profile{ 
		return getAccount(acct).capabilities.get<&Profile>(UserProfile.ProfilePublicPath).borrow()
		?? panic("Failed to borrow user profile: ".concat(acct.toString()))
	}
	
	access(all)
	fun getPlatformLinkedAddress(platform: String, uid: String): Address?{ 
		let uid = platform.concat("#").concat(uid)
		return UserProfile.platformMapping[uid]
	}
	
	init(){ 
		self.totalProfiles = 0
		self.platformMapping ={} 
		self.ProfileStoragePath = /storage/DevCompetitionProfilePathV5
		self.ProfilePublicPath = /public/DevCompetitionProfilePathV5
		emit ContractInitialized()
	}
}
