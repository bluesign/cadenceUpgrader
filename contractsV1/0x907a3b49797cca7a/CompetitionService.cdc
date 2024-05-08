/**
## The contract of main service on Flow Quest

> Author: Bohao Tang<tech@btang.cn>

Join a flow development competition.
*/

import Interfaces from "./Interfaces.cdc"

import Helper from "./Helper.cdc"

import UserProfile from "./UserProfile.cdc"

import Community from "./Community.cdc"

access(all)
contract CompetitionService{ 
	/**	___  ____ ___ _  _ ____
		   *   |__] |__|  |  |__| [__
			*  |	|  |  |  |  | ___]
			 *************************/
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let ControllerStoragePath: StoragePath
	
	access(all)
	let ServiceStoragePath: StoragePath
	
	access(all)
	let ServicePublicPath: PublicPath
	
	/**	____ _  _ ____ _  _ ___ ____
		   *   |___ |  | |___ |\ |  |  [__
			*  |___  \/  |___ | \|  |  ___]
			 ******************************/
	
	// participant events
	access(all)
	event ProfileRegistered(seasonId: UInt64, participant: Address)
	
	access(all)
	event ProfileBountyCompleted(
		bountyId: UInt64,
		communityId: UInt64,
		key: String,
		category: UInt8,
		participant: Address
	)
	
	// season bounty events
	access(all)
	event BountyAdded(communityId: UInt64, key: String, category: UInt8, bountyId: UInt64)
	
	access(all)
	event BountyPropertyUpdated(bountyId: UInt64, property: UInt8, value: Bool)
	
	access(all)
	event BountyRewardUpdatedAsNone(bountyId: UInt64)
	
	access(all)
	event BountyRewardUpdatedAsPoints(bountyId: UInt64, points: UInt64, referralPoints: UInt64)
	
	access(all)
	event BountyRewardUpdatedAsFLOAT(bountyId: UInt64, host: Address, eventId: UInt64)
	
	access(all)
	event BountyPreconditionAdded(bountyId: UInt64, unlockCondType: UInt8)
	
	access(all)
	event BountyPreconditionRemoved(bountyId: UInt64, unlockCondType: UInt8, index: Int)
	
	// season events
	access(all)
	event SeasonCreated(seasonId: UInt64)
	
	access(all)
	event SeasonPropertyEndDateUpdated(seasonId: UInt64, key: UInt8, value: UFix64)
	
	access(all)
	event SeasonPropertyReferralThresholdUpdated(seasonId: UInt64, key: UInt8, value: UInt64)
	
	access(all)
	event SeasonPropertyStringUpdated(seasonId: UInt64, key: UInt8, value: String)
	
	// service events
	access(all)
	event ServiceWhitelistUpdated(target: Address, flag: Bool)
	
	access(all)
	event ServiceAdminResourceClaimed(claimer: Address, uuid: UInt64)
	
	access(all)
	event ContractInitialized()
	
	/**	____ ___ ____ ___ ____
		   *   [__   |  |__|  |  |___
			*  ___]  |  |  |  |  |___
			 ************************/
	
	// NOTHING
	/**	____ _  _ _  _ ____ ___ _ ____ _  _ ____ _	_ ___ _   _
		   *   |___ |  | |\ | |	 |  | |  | |\ | |__| |	|  |   \_/
			*  |	|__| | \| |___  |  | |__| | \| |  | |___ |  |	|
			 ***********************************************************/
	
	access(all)
	enum BountyProperty: UInt8{ 
		access(all)
		case Launched
		
		access(all)
		case Featured
		
		access(all)
		case ForBeginner
		
		access(all)
		case ForExpert
	}
	
	access(all)
	resource interface BountyInfoPublic{ 
		access(all)
		fun getBountyIdentifier(): Community.BountyEntityIdentifier
		
		access(all)
		fun isLaunched(): Bool
		
		access(all)
		fun isFeatured(): Bool
		
		access(all)
		fun getProperties():{ UInt8: Bool}
		
		access(all)
		fun getParticipants():{ Address:{ String: AnyStruct}}
		
		access(all)
		fun getParticipantsAddress(): [Address]
		
		access(all)
		fun getParticipantsAmount(): Int
	}
	
	access(all)
	resource BountyInfo: Interfaces.BountyInfoPublic, BountyInfoPublic{ 
		access(contract)
		let identifier: Community.BountyEntityIdentifier
		
		access(contract)
		let properties:{ BountyProperty: Bool}
		
		access(contract)
		let preconditions: [{Interfaces.UnlockCondition}]
		
		access(contract)
		let participants:{ Address:{ String: AnyStruct}}
		
		access(contract)
		var rewardInfo:{ Helper.RewardInfo}
		
		access(contract)
		var rewardType: Helper.MissionRewardType
		
		init(identifier: Community.BountyEntityIdentifier, preconditions: [{Interfaces.UnlockCondition}], reward:{ Helper.RewardInfo}){ 
			self.identifier = identifier
			self.properties ={} 
			self.preconditions = preconditions
			self.rewardType = reward.type
			self.rewardInfo = reward
			self.participants ={} 
		}
		
		// ---- readonly methods ----
		access(all)
		fun getID(): UInt64{ 
			return self.uuid
		}
		
		access(all)
		fun getPreconditions(): [{Interfaces.UnlockCondition}]{ 
			return self.preconditions
		}
		
		access(all)
		fun getParticipants():{ Address:{ String: AnyStruct}}{ 
			return self.participants
		}
		
		access(all)
		fun getParticipantsAddress(): [Address]{ 
			return self.participants.keys
		}
		
		access(all)
		fun getParticipantsAmount(): Int{ 
			return self.participants.keys.length
		}
		
		access(all)
		fun getIdentifier():{ Interfaces.BountyEntityIdentifier}{ 
			return self.identifier
		}
		
		access(all)
		fun getBountyIdentifier(): Community.BountyEntityIdentifier{ 
			return self.identifier
		}
		
		access(all)
		fun isLaunched(): Bool{ 
			return self.properties[BountyProperty.Launched] ?? false
		}
		
		access(all)
		fun isFeatured(): Bool{ 
			return self.properties[BountyProperty.Featured] ?? false
		}
		
		access(all)
		fun isForBeginner(): Bool{ 
			return self.properties[BountyProperty.ForBeginner] ?? false
		}
		
		access(all)
		fun isForExpert(): Bool{ 
			return self.properties[BountyProperty.ForExpert] ?? false
		}
		
		access(all)
		fun getProperties():{ UInt8: Bool}{ 
			let ret:{ UInt8: Bool} ={} 
			for key in self.properties.keys{ 
				ret[key.rawValue] = self.properties[key]
			}
			return ret
		}
		
		access(all)
		fun getRequiredMissionKeys(): [String]{ 
			let ret: [String] = []
			if self.identifier.category == Interfaces.BountyType.mission{ 
				ret.append(self.identifier.key)
			} else{ 
				let quest = self.identifier.getQuestConfig()
				for one in quest.missions{ 
					ret.append(one.key)
				}
			}
			return ret
		}
		
		access(all)
		fun getRewardType(): Helper.MissionRewardType{ 
			return self.rewardType
		}
		
		access(all)
		fun getPointReward(): Helper.PointReward{ 
			if self.rewardType == Helper.MissionRewardType.Points{ 
				return self.rewardInfo as! Helper.PointReward
			}
			panic("Reward type is not Points")
		}
		
		access(all)
		fun getFLOATReward(): Helper.FLOATReward{ 
			if self.rewardType == Helper.MissionRewardType.FLOAT{ 
				return self.rewardInfo as! Helper.FLOATReward
			}
			panic("Reward type is not FLOAT")
		}
		
		// ---- writable methods ----
		access(all)
		fun onParticipantCompleted(acct: Address){ 
			let now = getCurrentBlock().timestamp
			if self.participants[acct] == nil{ 
				self.participants[acct] ={ "datetime": now, "updatedAt": now, "times": 1 as UInt64}
			} else{ 
				let record = (&self.participants[acct] as &{String: AnyStruct}?)!
				record["updatedAt"] = now
				record["times"] = (record["times"] as! UInt64?)! + 1
			}
			emit ProfileBountyCompleted(bountyId: self.getID(), communityId: self.identifier.communityId, key: self.identifier.key, category: self.identifier.category.rawValue, participant: acct)
		}
		
		access(contract)
		fun updateBountyProperty(property: BountyProperty, value: Bool){ 
			let oldValue = self.properties[property] ?? false
			if oldValue != value{ 
				self.properties[property] = value
				emit BountyPropertyUpdated(bountyId: self.getID(), property: property.rawValue, value: value)
			}
		}
		
		access(contract)
		fun updateRewardInfo(reward:{ Helper.RewardInfo}){ 
			self.rewardType = reward.type
			self.rewardInfo = reward
			
			// emit event by type
			if reward.type == Helper.MissionRewardType.Points{ 
				let pointsReward = reward as! Helper.PointReward
				emit BountyRewardUpdatedAsPoints(bountyId: self.getID(), points: pointsReward.rewardPoints, referralPoints: pointsReward.referralPoints)
			} else if reward.type == Helper.MissionRewardType.FLOAT{ 
				let floatReward = reward as! Helper.FLOATReward
				emit BountyRewardUpdatedAsFLOAT(bountyId: self.getID(), host: floatReward.eventIdentifier.host, eventId: floatReward.eventIdentifier.eventId)
			} else{ 
				emit BountyRewardUpdatedAsNone(bountyId: self.getID())
			}
		}
		
		access(contract)
		fun addPrecondition(cond:{ Interfaces.UnlockCondition}){ 
			self.preconditions.append(cond)
			emit BountyPreconditionAdded(bountyId: self.getID(), unlockCondType: cond.type)
		}
		
		access(contract)
		fun removePrecondition(idx: Int){ 
			pre{ 
				idx < self.preconditions.length:
					"Out of bound"
			}
			let cond = self.preconditions.remove(at: idx)
			emit BountyPreconditionRemoved(bountyId: self.getID(), unlockCondType: cond.type, index: idx)
		}
		
		// ---- internal methods ----
		// check if the bounty unlocked
		access(contract)
		fun isUnlocked(_ profile: Address): Bool{ 
			let params:{ String: AnyStruct} ={ "profile": profile}
			var unlocked = true
			for cond in self.preconditions{ 
				unlocked = unlocked && cond.isUnlocked(params)
			}
			return unlocked
		}
	}
	
	access(all)
	enum CompetitionProperty: UInt8{ 
		access(all)
		case EndDate
		
		access(all)
		case ReferralThreshold
		
		access(all)
		case Title
		
		access(all)
		case RankingRewards
	}
	
	access(all)
	resource interface CompetitionPublic{ 
		access(all)
		fun isDefault(): Bool
		
		// --- Properties ---
		access(all)
		fun getEndDate(): UFix64
		
		access(all)
		fun getReferralThreshold(): UInt64
		
		access(all)
		fun getTitle(): String
		
		access(all)
		fun getRankingRewards(): String
	}
	
	access(all)
	resource CompetitionSeason: Interfaces.CompetitionPublic, CompetitionPublic{ 
		access(self)
		let default: Bool
		
		// Season Properties
		access(contract)
		let properties:{ CompetitionProperty: AnyStruct}
		
		access(contract)
		var profiles:{ Address: Bool}
		
		// leaderboard Rank -> Score
		access(contract)
		var leaderboardRanking: [UInt64]
		
		// leaderboard Address -> Rank
		access(contract)
		var leaderboardAddressMap:{ Address: Int}
		
		// leaderboard Score -> Address
		access(contract)
		var leaderboardScores:{ UInt64:{ Address: Bool}}
		
		init(isDefault: Bool, endDate: UFix64, referralThreshold: UInt64){ 
			self.default = isDefault
			self.properties ={} 
			self.profiles ={} 
			// setup properties
			self.properties[CompetitionProperty.EndDate] = endDate
			self.properties[CompetitionProperty.ReferralThreshold] = referralThreshold
			// leaderboard
			self.leaderboardRanking = []
			self.leaderboardAddressMap ={} 
			self.leaderboardScores ={} 
		}
		
		// ---- readonly methods ----
		access(all)
		fun getSeasonId(): UInt64{ 
			return self.uuid
		}
		
		access(all)
		fun isDefault(): Bool{ 
			return self.default
		}
		
		access(all)
		fun isActive(): Bool{ 
			return self.default ? true : self.getEndDate() > getCurrentBlock().timestamp
		}
		
		// properties
		access(all)
		fun getEndDate(): UFix64{ 
			return self.default ? 0.0 : (self.properties[CompetitionProperty.EndDate] as! UFix64?)!
		}
		
		access(all)
		fun getReferralThreshold(): UInt64{ 
			return self.default ? UInt64.max : (self.properties[CompetitionProperty.ReferralThreshold] as! UInt64?)!
		}
		
		access(all)
		fun getTitle(): String{ 
			return self.default ? "" : self.properties[CompetitionProperty.Title] as! String? ?? ""
		}
		
		access(all)
		fun getRankingRewards(): String{ 
			return self.default ? "" : self.properties[CompetitionProperty.RankingRewards] as! String? ?? ""
		}
		
		access(all)
		fun getRank(_ addr: Address): Int{ 
			let profileRef = UserProfile.borrowUserProfilePublic(addr)
			let point = self.default ? profileRef.getProfilePoints() : profileRef.getSeasonPoints(seasonId: self.getSeasonId())
			let lastRank = self.leaderboardRanking.length - 1
			if point == 0{ 
				return lastRank
			} else{ 
				return self.leaderboardRanking.firstIndex(of: point) ?? lastRank
			}
		}
		
		access(all)
		fun getLeaderboardRanking(limit: Int?):{ UInt64: [Address]}{ 
			let maxAmount = limit ?? 100
			let totalLen = self.leaderboardRanking.length
			let rankingScores = self.leaderboardRanking.slice(from: 0, upTo: maxAmount > totalLen ? totalLen : maxAmount)
			let ret:{ UInt64: [Address]} ={} 
			for score in rankingScores{ 
				if let addrs = self.leaderboardScores[score]{ 
					if addrs.keys.length > 0{ 
						ret[score] = addrs.keys
					}
				}
			}
			return ret
		}
		
		// ---- writable methods ----
		access(account)
		fun onProfileRegistered(acct: Address){ 
			if self.profiles[acct] == nil{ 
				self.profiles[acct] = true
				emit ProfileRegistered(seasonId: self.getSeasonId(), participant: acct)
			}
		}
		
		access(contract)
		fun updateRanking(addr: Address, newPoint: UInt64, oldPoint: UInt64){ 
			if newPoint == oldPoint{ 
				return
			}
			let oldRank = self.leaderboardAddressMap[addr]
			// remove old rank
			if oldRank != nil && self.leaderboardScores[oldPoint] != nil{ 
				(self.leaderboardScores[oldPoint]!).remove(key: addr)
				if (self.leaderboardScores[oldPoint]!).length == 0{ 
					// Remove oldPoint from ranking
					let oldPointFirstIndex = self.leaderboardRanking.firstIndex(of: oldPoint)
					if oldPointFirstIndex != nil{ 
						self.leaderboardRanking.remove(at: oldPointFirstIndex!)
					}
				}
			}
			// update current rank
			if self.leaderboardScores[newPoint] != nil{ 
				(self.leaderboardScores[newPoint]!).insert(key: addr, true)
			} else{ 
				self.leaderboardScores[newPoint] ={ addr: true}
			}
			
			// search the rank
			let firstIndex = self.leaderboardRanking.firstIndex(of: newPoint)
			if firstIndex == nil{ 
				var left = 0
				var right = self.leaderboardRanking.length - 1
				while left <= right{ 
					let mid = left == right ? left : (left + right) / 2
					if self.leaderboardRanking.length <= mid || newPoint > self.leaderboardRanking[mid]{ 
						right = mid - 1
					} else{ 
						left = mid + 1
					}
				}
				self.leaderboardRanking.insert(at: left, newPoint)
				self.leaderboardAddressMap[addr] = left
			} else{ 
				self.leaderboardAddressMap[addr] = firstIndex
			}
		}
		
		access(contract)
		fun updateReferralThreshold(threshold: UInt64){ 
			self.properties[CompetitionProperty.ReferralThreshold] = threshold
			emit SeasonPropertyReferralThresholdUpdated(seasonId: self.getSeasonId(), key: CompetitionProperty.ReferralThreshold.rawValue, value: threshold)
		}
		
		access(contract)
		fun updateEndDate(datetime: UFix64){ 
			pre{ 
				datetime > getCurrentBlock().timestamp:
					"Cannot update end date before now."
			}
			self.properties[CompetitionProperty.EndDate] = datetime
			emit SeasonPropertyEndDateUpdated(seasonId: self.getSeasonId(), key: CompetitionProperty.EndDate.rawValue, value: datetime)
		}
		
		access(contract)
		fun updatePropertyString(property: CompetitionProperty, value: String){ 
			pre{ 
				property == CompetitionProperty.Title || property == CompetitionProperty.RankingRewards:
					"Invalid property"
			}
			self.properties[property] = value
			emit SeasonPropertyStringUpdated(seasonId: self.getSeasonId(), key: property.rawValue, value: value)
		}
	}
	
	access(all)
	resource interface CompetitionServicePublic{ 
		// Admin related
		access(all)
		fun isAdminValid(_ addr: Address): Bool
		
		access(all)
		fun claim(claimer: &UserProfile.Profile): @CompetitionAdmin
		
		// Bounty
		access(all)
		fun borrowBountyInfoByKey(_ key: String): &BountyInfo
		
		access(all)
		fun borrowBountyDetail(_ bountyId: UInt64): &BountyInfo
		
		// season related
		access(all)
		fun borrowSeasonDetail(seasonId: UInt64): &CompetitionSeason
		
		access(all)
		fun borrowPermanentSeason(): &CompetitionSeason
		
		access(all)
		fun borrowLastActiveSeason(): &CompetitionSeason?
	}
	
	// The singleton instance of competition service
	access(all)
	resource CompetitionServiceStore:
		CompetitionServicePublic,
		Interfaces.CompetitionServicePublic{
	
		access(self)
		let adminWhitelist:{ Address: Bool}
		
		// all seasons
		access(self)
		var latestActiveSeasonId: UInt64
		
		access(self)
		var seasons: @{UInt64: CompetitionSeason}
		
		// MissionKey -> BountyID
		access(self)
		var keyIdMapping:{ String: UInt64}
		
		access(self)
		var bounties: @{UInt64: BountyInfo}
		
		access(self)
		var primaryBounties: [UInt64]
		
		// Referral Mapping
		access(self)
		var referralCodesToAddrs:{ String: Address}
		
		access(self)
		var referralAddrsToCodes:{ Address: String}
		
		init(){ 
			self.bounties <-{} 
			self.primaryBounties = []
			self.keyIdMapping ={} 
			self.referralAddrsToCodes ={} 
			self.referralCodesToAddrs ={} 
			self.adminWhitelist ={} 
			self.seasons <-{} 
			self.latestActiveSeasonId = 0
			self.seasons[0] <-! create CompetitionSeason(
					isDefault: true,
					endDate: 0.0,
					referralThreshold: UInt64.max
				)
		}
		
		// ---- factory methods ----
		access(all)
		fun createSeasonPointsController(): @SeasonPointsController{ 
			return <-create SeasonPointsController()
		}
		
		access(all)
		fun claim(claimer: &UserProfile.Profile): @CompetitionAdmin{ 
			let claimerAddr = claimer.owner?.address ?? panic("Failed to load profile")
			assert(self.isAdminValid(claimerAddr), message: "Admin is invalid")
			let admin <- create CompetitionAdmin()
			emit ServiceAdminResourceClaimed(claimer: claimerAddr, uuid: admin.uuid)
			return <-admin
		}
		
		// ---- readonly methods ----
		access(all)
		fun isAdminValid(_ addr: Address): Bool{ 
			return self.adminWhitelist[addr] ?? false
		}
		
		access(all)
		fun getReferralAddress(_ code: String): Address?{ 
			return self.referralCodesToAddrs[code]
		}
		
		access(all)
		fun getReferralCode(_ addr: Address): String?{ 
			return self.referralAddrsToCodes[addr]
		}
		
		// --- bounties ---
		access(all)
		fun getBountyIDs(): [UInt64]{ 
			return self.bounties.keys
		}
		
		access(all)
		fun getPrimaryBountyIDs(): [UInt64]{ 
			return self.primaryBounties
		}
		
		access(all)
		fun hasBountyByKey(_ key: String): Bool{ 
			return self.keyIdMapping[key] != nil
		}
		
		access(all)
		fun borrowBountyInfo(_ bountyId: UInt64): &{Interfaces.BountyInfoPublic}{ 
			return self.borrowBountyPrivateRef(bountyId)
		}
		
		access(all)
		fun borrowBountyInfoByKey(_ key: String): &BountyInfo{ 
			let bountyId = self.keyIdMapping[key] ?? panic("Missing missionKey.")
			return self.borrowBountyDetail(bountyId)
		}
		
		access(all)
		fun borrowBountyDetail(_ bountyId: UInt64): &BountyInfo{ 
			return self.borrowBountyPrivateRef(bountyId)
		}
		
		access(all)
		fun borrowMissionRef(_ missionKey: String): &{
			Interfaces.BountyEntityPublic,
			Interfaces.MissionInfoPublic
		}{ 
			let bountyId = self.keyIdMapping[missionKey] ?? panic("Missing missionKey.")
			let bountyRef = self.borrowBountyPrivateRef(bountyId)
			assert(
				bountyRef.identifier.category == Interfaces.BountyType.mission,
				message: "Bounty should be a mission."
			)
			return bountyRef.identifier.getMissionConfig()
		}
		
		/**
				 * check if bounty completed
				 */
		
		access(all)
		fun checkBountyCompleteStatus(acct: Address, bountyId: UInt64): Bool{ 
			// get profile and update points
			let profileRef = UserProfile.borrowUserProfilePublic(acct)
			let completedInProfile = profileRef.isBountyCompleted(bountyId: bountyId)
			// already completed
			if completedInProfile{ 
				return completedInProfile
			}
			let bounty = self.borrowBountyPrivateRef(bountyId)
			// result
			var isCompleted = false
			// ensure mission completed
			if bounty.identifier.category == Interfaces.BountyType.mission{ 
				let status = profileRef.getMissionStatus(missionKey: bounty.identifier.key)
				isCompleted = status.completed
			} else{ 
				let questRef = bounty.identifier.getQuestConfig()
				var allCompleted = true
				for identifier in questRef.missions{ 
					let status = profileRef.getMissionStatus(missionKey: identifier.key)
					allCompleted = allCompleted && status.completed
				}
				isCompleted = allCompleted
			}
			return isCompleted
		}
		
		// --- seasons ---
		access(all)
		fun getActiveSeasonID(): UInt64{ 
			let season =
				&self.seasons[self.latestActiveSeasonId] as &CompetitionSeason?
				?? panic("Failed to get current active season.")
			assert(season.isActive(), message: "The current season is not active.")
			return season.getSeasonId()
		}
		
		access(all)
		fun borrowSeason(seasonId: UInt64): &{Interfaces.CompetitionPublic}{ 
			return self.borrowSeasonPrivateRef(seasonId)
		}
		
		access(all)
		fun borrowSeasonDetail(seasonId: UInt64): &CompetitionSeason{ 
			return self.borrowSeasonPrivateRef(seasonId)
		}
		
		access(all)
		fun borrowPermanentSeason(): &CompetitionSeason{ 
			return self.borrowSeasonPrivateRef(0)
		}
		
		access(all)
		fun borrowLastActiveSeason(): &CompetitionSeason?{ 
			return self.latestActiveSeasonId == 0
				? nil
				: self.borrowSeasonPrivateRef(self.latestActiveSeasonId)
		}
		
		access(contract)
		fun borrowSeasonPrivateRef(_ seasonId: UInt64): &CompetitionSeason{ 
			return &self.seasons[seasonId] as &CompetitionSeason?
			?? panic("Failed to get the season: ".concat(seasonId.toString()))
		}
		
		// ---- writable methods ----
		access(all)
		fun updateWhitelistFlag(addr: Address, flag: Bool){ 
			self.adminWhitelist[addr] = flag
			emit ServiceWhitelistUpdated(target: addr, flag: flag)
		}
		
		access(contract)
		fun setReferralCode(addr: Address, code: String){ 
			self.referralAddrsToCodes[addr] = code
			self.referralCodesToAddrs[code] = addr
		}
		
		access(contract)
		fun startNewSeason(endDate: UFix64, referralThreshold: UInt64): UInt64{ 
			// ensure one time one season
			if self.latestActiveSeasonId != 0{ 
				let season = &self.seasons[self.latestActiveSeasonId] as &CompetitionSeason? ?? panic("Failed to found last season")
				assert(!season.isActive(), message: "Last season is active")
			}
			let season <-
				create CompetitionSeason(
					isDefault: false,
					endDate: endDate,
					referralThreshold: referralThreshold
				)
			let seasonId = season.uuid
			self.seasons[seasonId] <-! season
			self.latestActiveSeasonId = seasonId
			emit SeasonCreated(seasonId: seasonId)
			return seasonId
		}
		
		access(contract)
		fun addBounty(
			identifier: Community.BountyEntityIdentifier,
			preconditions: [{
				Interfaces.UnlockCondition}
			],
			reward:{ Helper.RewardInfo},
			primary: Bool
		){ 
			pre{ 
				self.keyIdMapping[identifier.key] == nil:
					"Already registered."
			}
			// ensure missions added to bounties
			if identifier.category == Interfaces.BountyType.quest{ 
				let questCfg = identifier.getQuestConfig()
				for one in questCfg.missions{ 
					assert(self.keyIdMapping[one.key] != nil, message: "Mission not registered.")
				}
			}
			let bounty <-
				create BountyInfo(
					identifier: identifier,
					preconditions: preconditions,
					reward: reward
				)
			let uid = bounty.uuid
			self.bounties[bounty.uuid] <-! bounty
			self.keyIdMapping[identifier.key] = uid
			if identifier.category == Interfaces.BountyType.quest || primary{ 
				self.primaryBounties.append(uid)
			}
			emit BountyAdded(
				communityId: identifier.communityId,
				key: identifier.key,
				category: identifier.category.rawValue,
				bountyId: uid
			)
		}
		
		access(account)
		fun onBountyCompleted(bountyId: UInt64, acct: Address){ 
			let bounty =
				&self.bounties[bountyId] as &BountyInfo? ?? panic("Failed to borrow bounty")
			bounty.onParticipantCompleted(acct: acct)
		}
		
		// ---- internal methods ----
		access(contract)
		fun borrowBountyPrivateRef(_ bountyId: UInt64): &BountyInfo{ 
			return &self.bounties[bountyId] as &BountyInfo?
			?? panic("Failed to borrow bounty: ".concat(bountyId.toString()))
		}
	}
	
	// ---- Admin resource ----
	/// Mainly used to manage competition
	access(all)
	resource CompetitionAdmin{ 
		// Bounty related
		access(all)
		fun addBounty(
			identifier: Community.BountyEntityIdentifier,
			preconditions: [{
				Interfaces.UnlockCondition}
			],
			reward:{ Helper.RewardInfo},
			primary: Bool
		){ 
			let serviceIns = CompetitionService.borrowServiceRef()
			assert(
				serviceIns.isAdminValid(self.owner?.address ?? panic("Missing owner")),
				message: "Not admin"
			)
			serviceIns.addBounty(
				identifier: identifier,
				preconditions: preconditions,
				reward: reward,
				primary: primary
			)
		}
		
		access(all)
		fun updateBountyProperty(bountyId: UInt64, property: BountyProperty, value: Bool){ 
			let bounty = self.borrowBountyPrivRef(bountyId: bountyId)
			bounty.updateBountyProperty(property: property, value: value)
		}
		
		access(all)
		fun updateBountyReward(bountyId: UInt64, reward:{ Helper.RewardInfo}){ 
			let bounty = self.borrowBountyPrivRef(bountyId: bountyId)
			bounty.updateRewardInfo(reward: reward)
		}
		
		access(all)
		fun addBountyPrecondition(bountyId: UInt64, cond:{ Interfaces.UnlockCondition}){ 
			let bounty = self.borrowBountyPrivRef(bountyId: bountyId)
			bounty.addPrecondition(cond: cond)
		}
		
		access(all)
		fun removeBountyPrecondition(bountyId: UInt64, idx: Int){ 
			let bounty = self.borrowBountyPrivRef(bountyId: bountyId)
			bounty.removePrecondition(idx: idx)
		}
		
		// Season related
		access(all)
		fun startNewSeason(endDate: UFix64, referralThreshold: UInt64): UInt64{ 
			let serviceIns = CompetitionService.borrowServiceRef()
			assert(
				serviceIns.isAdminValid(self.owner?.address ?? panic("Missing owner")),
				message: "Not admin"
			)
			return serviceIns.startNewSeason(endDate: endDate, referralThreshold: referralThreshold)
		}
		
		access(all)
		fun updateEndDate(seasonId: UInt64, datetime: UFix64){ 
			let serviceIns = CompetitionService.borrowServiceRef()
			assert(
				serviceIns.isAdminValid(self.owner?.address ?? panic("Missing owner")),
				message: "Not admin"
			)
			let season = serviceIns.borrowSeasonPrivateRef(seasonId)
			season.updateEndDate(datetime: datetime)
		}
		
		access(all)
		fun updateReferralThreshold(seasonId: UInt64, threshold: UInt64){ 
			let serviceIns = CompetitionService.borrowServiceRef()
			assert(
				serviceIns.isAdminValid(self.owner?.address ?? panic("Missing owner")),
				message: "Not admin"
			)
			let season = serviceIns.borrowSeasonPrivateRef(seasonId)
			season.updateReferralThreshold(threshold: threshold)
		}
		
		access(all)
		fun updateSeasonPropertyString(
			seasonId: UInt64,
			property: CompetitionProperty,
			value: String
		){ 
			let serviceIns = CompetitionService.borrowServiceRef()
			assert(
				serviceIns.isAdminValid(self.owner?.address ?? panic("Missing owner")),
				message: "Not admin"
			)
			let season = serviceIns.borrowSeasonPrivateRef(seasonId)
			season.updatePropertyString(property: property, value: value)
		}
		
		// Internal use
		access(self)
		fun borrowBountyPrivRef(bountyId: UInt64): &BountyInfo{ 
			let serviceIns = CompetitionService.borrowServiceRef()
			assert(
				serviceIns.isAdminValid(self.owner?.address ?? panic("Missing owner")),
				message: "Not admin"
			)
			return serviceIns.borrowBountyPrivateRef(bountyId)
		}
	}
	
	/// Mainly used to update user profile
	access(all)
	resource SeasonPointsController{ 
		access(all)
		fun updateNewParams(
			acct: Address,
			missionKey: String,
			step: Int,
			params:{ 
				String: AnyStruct
			}
		){ 
			// get profile and update points
			let profileRef = UserProfile.borrowUserProfilePublic(acct)
			profileRef.updateMissionNewParams(missionKey: missionKey, step: step, params: params)
		}
		
		access(all)
		fun missionStepCompleted(acct: Address, missionKey: String, step: Int){ 
			// get profile and update points
			let profileRef = UserProfile.borrowUserProfilePublic(acct)
			profileRef.updateMissionVerificationResult(
				missionKey: missionKey,
				step: step,
				result: true
			)
		}
		
		access(all)
		fun missionStepFailure(acct: Address, missionKey: String, step: Int){ 
			// get profile and update points
			let profileRef = UserProfile.borrowUserProfilePublic(acct)
			profileRef.updateMissionVerificationResult(
				missionKey: missionKey,
				step: step,
				result: false
			)
		}
		
		access(all)
		fun completeBounty(acct: Address, bountyId: UInt64){ 
			let serviceIns = CompetitionService.borrowServiceRef()
			let bounty = serviceIns.borrowBountyPrivateRef(bountyId)
			// ensure bounty unlocked
			assert(bounty.isUnlocked(acct), message: "Bounty is locked")
			
			// get profile and update points
			let profileRef = UserProfile.borrowUserProfilePublic(acct)
			assert(
				!profileRef.isBountyCompleted(bountyId: bountyId),
				message: "Ensure bounty not completed"
			)
			let checkCompleted =
				serviceIns.checkBountyCompleteStatus(acct: acct, bountyId: bountyId)
			// ensure bounty completed
			assert(checkCompleted, message: "Bounty not completed")
			
			// distribute rewards
			if bounty.rewardType == Helper.MissionRewardType.Points{ 
				let reward = bounty.getPointReward()
				// add to default season
				self.addPoints(acct: acct, seasonId: 0, points: reward.rewardPoints)
				
				// add to active season
				if let season = serviceIns.borrowLastActiveSeason(){ 
					if season.isActive(){ 
						let seasonId = season.getSeasonId()
						self.addPoints(acct: acct, seasonId: seasonId, points: reward.rewardPoints)
						
						// get inviter profile and update referral points
						let referralFrom = profileRef.getReferredFrom()
						// referral points only add to season points
						if referralFrom != nil && reward.referralPoints > 0{ 
							self.addPoints(acct: referralFrom!, seasonId: seasonId, points: reward.referralPoints)
						}
					}
				}
			} else if bounty.rewardType == Helper.MissionRewardType.FLOAT{} 
			// NOTHING for now
			profileRef.completeBounty(bountyId: bountyId)
		}
		
		access(all)
		fun setupReferralCode(acct: Address){ 
			// get profile
			let profileRef = UserProfile.borrowUserProfilePublic(acct)
			let oldCode = profileRef.getReferralCode()
			assert(oldCode == nil, message: "Referral Code is already generated.")
			let serviceIns = CompetitionService.borrowServiceRef()
			let seasonId = serviceIns.getActiveSeasonID()
			let season = serviceIns.borrowSeasonPrivateRef(seasonId)
			let profilePoints = profileRef.getSeasonPoints(seasonId: seasonId)
			assert(
				profilePoints >= season.getReferralThreshold(),
				message: "profile points is not enough"
			)
			let hash = getCurrentBlock().id
			let acctHash = acct.toString().utf8
			let codeArr: [UInt8] = []
			var i = 0
			while i < 4{ 
				codeArr.append(hash[hash.length - 1 - i])
				codeArr.append(acctHash[i])
				i = i + 1
			}
			let code = String.encodeHex(codeArr)
			// set to season
			serviceIns.setReferralCode(addr: acct, code: code)
			
			// set code in profile
			profileRef.setupReferralCode(code: code)
		}
		
		access(self)
		fun addPoints(acct: Address, seasonId: UInt64, points: UInt64){ 
			// get profile and update points
			let profileRef = UserProfile.borrowUserProfilePublic(acct)
			let oldPoint = profileRef.getSeasonPoints(seasonId: seasonId)
			profileRef.addPoints(seasonId: seasonId, points: points)
			
			// update leaderboard
			let serviceIns = CompetitionService.borrowServiceRef()
			let season = serviceIns.borrowSeasonPrivateRef(seasonId)
			season.updateRanking(
				addr: acct,
				newPoint: profileRef.getSeasonPoints(seasonId: seasonId),
				oldPoint: oldPoint
			)
		}
	}
	
	// ---- public methods ----
	access(all)
	fun borrowServicePublic(): &CompetitionServiceStore{ 
		return self.getPublicCapability().borrow()
		?? panic("Missing the capability of service store resource")
	}
	
	access(all)
	fun getPublicCapability(): Capability<&CompetitionServiceStore>{ 
		return self.account.capabilities.get<&CompetitionServiceStore>(self.ServicePublicPath)!
	}
	
	access(account)
	fun borrowServiceRef(): &CompetitionServiceStore{ 
		return self.account.storage.borrow<&CompetitionServiceStore>(from: self.ServiceStoragePath)
		?? panic("Missing the service store resource")
	}
	
	init(){ 
		// Admin resource paths
		self.AdminStoragePath = /storage/DevCompetitionAdminPathV4
		self.ControllerStoragePath = /storage/DevCompetitionControllerPathV4
		self.ServiceStoragePath = /storage/DevCompetitionServicePath
		self.ServicePublicPath = /public/DevCompetitionServicePath
		let store <- create CompetitionServiceStore()
		// Store the resource of Quest Seasons in the account
		self.account.storage.save(<-store, to: self.ServiceStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&CompetitionServiceStore>(
				self.ServiceStoragePath
			)
		self.account.capabilities.publish(capability_1, at: self.ServicePublicPath)
		emit ContractInitialized()
	}
}
