// MADE BY: Bohao Tang
import FLOAT from "../0x2d4c3caffbeab845/FLOAT.cdc"

import FLOATEventSeries from "./FLOATEventSeries.cdc"

access(all)
contract FLOATChallengeVerifiers{ 
	//
	// ChallengeAchievementPoint
	// 
	// Specifies a FLOAT Challenge to limit who accomplished 
	// a number of achievement point can claim the FLOAT
	access(all)
	struct ChallengeAchievementPoint: FLOAT.IVerifier{ 
		access(all)
		let challengeIdentifier: FLOATEventSeries.EventSeriesIdentifier
		
		access(all)
		let challengeThresholdPoints: UInt64
		
		access(all)
		fun verify(_ params:{ String: AnyStruct}){ 
			let claimee: Address = params["claimee"]! as! Address
			if let achievementBoard = getAccount(claimee).capabilities.get<&FLOATEventSeries.AchievementBoard>(FLOATEventSeries.FLOATAchievementBoardPublicPath).borrow<&FLOATEventSeries.AchievementBoard>(){ 
				// build goal status by different ways
				if let record = achievementBoard.borrowAchievementRecordRef(host: self.challengeIdentifier.host, seriesId: self.challengeIdentifier.id){ 
					assert(record.score >= self.challengeThresholdPoints, message: "You do not meet the minimum required Achievement Point for Challenge#".concat(self.challengeIdentifier.id.toString()))
				} else{ 
					panic("You do not have Challenge Achievement Record for Challenge#".concat(self.challengeIdentifier.id.toString()))
				}
			} else{ 
				panic("You do not have Challenge Achievement Board")
			}
		}
		
		init(_challengeHost: Address, _challengeId: UInt64, thresholdPoints: UInt64){ 
			self.challengeThresholdPoints = thresholdPoints
			self.challengeIdentifier = FLOATEventSeries.EventSeriesIdentifier(_challengeHost, _challengeId)
			// ensure challenge exists
			self.challengeIdentifier.getEventSeriesPublic()
		}
	}
}
