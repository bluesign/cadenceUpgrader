import FLOAT from "../0x2d4c3caffbeab845/FLOAT.cdc"

import FLOATEventSeries from "./FLOATEventSeries.cdc"

access(all)
contract FLOATEventSeriesGoals{ 
	/**	____ _  _ _  _ ____ ___ _ ____ _  _ ____ _	_ ___ _   _
		   *   |___ |  | |\ | |	 |  | |  | |\ | |__| |	|  |   \_/
			*  |	|__| | \| |___  |  | |__| | \| |  | |___ |  |	|
			 ***********************************************************/
	
	
	// Accomplish goal when a certain amount is collected
	access(all)
	struct CollectByAmountGoal: FLOATEventSeries.IAchievementGoal{ 
		// achievement title
		access(all)
		let title: String
		
		// variables
		access(self)
		let points: UInt64
		
		access(self)
		let amount: UInt64
		
		access(self)
		let requiredAmount: UInt64
		
		init(points: UInt64, amount: UInt64, requiredAmount: UInt64?, title: String?){ 
			pre{ 
				requiredAmount ?? 0 <= amount:
					"required amount should be less then amount."
			}
			self.points = points
			self.amount = amount
			self.requiredAmount = requiredAmount ?? 0
			self.title = title ?? ""
		}
		
		access(all)
		fun getPoints(): UInt64{ 
			return self.points
		}
		
		access(all)
		fun getGoalDetail():{ String: AnyStruct}{ 
			let ret:{ String: UInt64} ={} 
			ret["amount"] = self.amount
			ret["requiredAmount"] = self.requiredAmount
			return ret
		}
		
		// Check if user fits some criteria.
		access(account)
		fun verify(_ eventSeries: &FLOATEventSeries.EventSeries, user: Address): Bool{ 
			var claimedTotal: UInt64 = 0
			var claimedRequired: UInt64 = 0
			let slots = eventSeries.getSlots()
			for slot in slots{ 
				if let eventIdentifier = slot.getIdentifier(){ 
					// ensure event exists
					eventIdentifier.getEventPublic()
					// check if FLOAT is claimed
					let isOwned = FLOATEventSeriesGoals.isOwnedFLOAT(user: user, eventId: eventIdentifier.eventId)
					if isOwned{ 
						claimedTotal = claimedTotal + 1
						// required update
						if slot.isEventRequired(){ 
							claimedRequired = claimedRequired + 1
						}
					}
				}
			}
			return claimedTotal >= self.amount && claimedRequired >= self.requiredAmount
		}
	}
	
	// Accomplish goal when a certain percent is collected
	access(all)
	struct CollectByPercentGoal: FLOATEventSeries.IAchievementGoal{ 
		// achievement title
		access(all)
		let title: String
		
		// variables
		access(self)
		let points: UInt64
		
		access(self)
		let percent: UFix64
		
		init(points: UInt64, percentToCollect: UFix64, title: String?){ 
			self.points = points
			self.percent = percentToCollect
			self.title = title ?? ""
		}
		
		access(all)
		fun getPoints(): UInt64{ 
			return self.points
		}
		
		access(all)
		fun getGoalDetail():{ String: AnyStruct}{ 
			let ret:{ String: UFix64} ={} 
			ret["percent"] = self.percent
			return ret
		}
		
		// Check if user fits some criteria.
		access(account)
		fun verify(_ eventSeries: &FLOATEventSeries.EventSeries, user: Address): Bool{ 
			var claimedTotal: UFix64 = 0.0
			var slotTotal: UFix64 = 0.0
			let slots = eventSeries.getSlots()
			for slot in slots{ 
				slotTotal = slotTotal + 1.0
				if let eventIdentifier = slot.getIdentifier(){ 
					// ensure event exists
					eventIdentifier.getEventPublic()
					// check if FLOAT is claimed
					let isOwned = FLOATEventSeriesGoals.isOwnedFLOAT(user: user, eventId: eventIdentifier.eventId)
					if isOwned{ 
						claimedTotal = claimedTotal + 1.0
					}
				}
			}
			return claimedTotal / slotTotal >= self.percent
		}
	}
	
	// Accomplish goal when some FLOATs are collected
	access(all)
	struct CollectSpecificFLOATsGoal: FLOATEventSeries.IAchievementGoal{ 
		// achievement title
		access(all)
		let title: String
		
		// variables
		access(self)
		let points: UInt64
		
		access(self)
		let floats: [FLOATEventSeries.EventIdentifier]
		
		init(points: UInt64, floats: [FLOATEventSeries.EventIdentifier], title: String?){ 
			self.points = points
			self.floats = floats
			self.title = title ?? ""
		}
		
		access(all)
		fun getPoints(): UInt64{ 
			return self.points
		}
		
		access(all)
		fun getGoalDetail():{ String: AnyStruct}{ 
			let ret:{ String: [FLOATEventSeries.EventIdentifier]} ={} 
			ret["floats"] = self.floats
			return ret
		}
		
		// Check if user fits some criteria.
		access(account)
		fun verify(_ eventSeries: &FLOATEventSeries.EventSeries, user: Address): Bool{ 
			let requiredIDs: [String] = []
			for requiredFloat in self.floats{ 
				requiredIDs.append(requiredFloat.toString())
			}
			var claimedTotal: Int = 0
			let slots = eventSeries.getSlots()
			for slot in slots{ 
				if let eventIdentifier = slot.getIdentifier(){ 
					// only required
					if requiredIDs.contains(eventIdentifier.toString()){ 
						// ensure event exists
						eventIdentifier.getEventPublic()
						// check if FLOAT is claimed
						let isOwned = FLOATEventSeriesGoals.isOwnedFLOAT(user: user, eventId: eventIdentifier.eventId)
						if isOwned{ 
							claimedTotal = claimedTotal + 1
						}
					}
				}
			}
			return claimedTotal == requiredIDs.length
		}
	}
	
	// ------------- Utility Method -------------
	// get user FLOAT collection
	access(contract)
	fun getFLOATCollection(user: Address): &FLOAT.Collection?{ 
		return getAccount(user).capabilities.get<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath)
			.borrow<&FLOAT.Collection>()
	}
	
	// to check if owned some FLOAT of a Event
	access(contract)
	fun isOwnedFLOAT(user: Address, eventId: UInt64): Bool{ 
		if let collection = FLOATEventSeriesGoals.getFLOATCollection(user: user){ 
			let ids = collection.ownedIdsFromEvent(eventId: eventId)
			return ids.length > 0
		} else{ 
			return false
		}
	}
	
	// ------------- Display Struct -------------
	access(all)
	enum GoalStatus: UInt8{ 
		access(all)
		case todo
		
		access(all)
		case ready
		
		access(all)
		case accomplished
	}
	
	// Goal Status for display
	access(all)
	struct GoalStatusDisplay{ 
		// user status
		access(all)
		let status: GoalStatus
		
		// info 
		access(all)
		let identifer: String
		
		access(all)
		let title: String
		
		access(all)
		let points: UInt64
		
		access(all)
		let detail:{ String: AnyStruct}
		
		init(
			status: GoalStatus,
			identifer: String,
			title: String,
			points: UInt64,
			detail:{ 
				String: AnyStruct
			}
		){ 
			self.status = status
			self.identifer = identifer
			self.title = title
			self.points = points
			self.detail = detail
		}
	}
}
