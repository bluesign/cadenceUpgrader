/*
 * Copyright (C) Wayports, Inc.
 *
 * SPDX-License-Identifier: (MIT)
 */


// WRLEvent
// The Wayports Racing League Events contract will keep track of
// all the races in the WRL. All events will be registered in the Flow blockchain
// in order to increase transparency for the users.
// The Administrador will register a new event on chain and will give persion to
// another account to insert the result of that event.
// Once the results are updated, a set of Stewards will analyze the race and judge
// if any penalty should be applied to one or more participants due to race incidents.
// After the analysis, the Stewards will be able to validate the Event.
//
access(all)
contract WRLEvent{ 
	
	// Interfaces
	
	// Validable interface is implemented by the Event resource, with it's methods
	// being used latter on by the Stewards to validate and penalize race participants
	//
	access(all)
	resource interface Validable{ 
		access(all)
		fun validate()
		
		access(all)
		fun addPenalty(participant: Address, time: UInt64)
	}
	
	// ResultSetter
	// Describe a function that should be exposed to an arbitrary account
	// by the Administrator resource, so this account can push the results to the chain
	//
	access(all)
	resource interface ResultSetter{ 
		access(all)
		fun setResults(stands:{ Address: UInt64})
	}
	
	// GetEventInfo
	// Implemented by the Administrator resource
	// in order to allow publicly accessible information about an event
	//
	access(all)
	resource interface GetEventInfo{ 
		access(all)
		fun getEventInfo(): EventInfo
	}
	
	// ValidatorReceiver
	// Implemented by the Steward resource, allows the holder of a Steward resource
	// to receive an Event Validator from the Administrator resource
	//
	access(all)
	resource interface ValidatorReceiver{ 
		access(all)
		fun receiveValidator(cap: Capability<&WRLEvent.Event>)
	}
	
	// EventViewerReceiver
	// Implemented by Steward resource, this interface exposes methods to display
	// information about the event being validated
	//
	access(all)
	resource interface EventViewerReceiver{ 
		access(all)
		fun receiveEventViewer(cap: Capability<&WRLEvent.Event>)
		
		access(all)
		fun getEventInfo(): EventInfo
	}
	
	// ResultSetterReceiver
	// Implemented by the Oracle resource, exposes publicly the method that will allow the Administrator
	// resource to deposit a capability to Oracle responsible for set the event results
	//
	access(all)
	resource interface ResultSetterReceiver{ 
		access(all)
		fun receiveResultSetter(cap: Capability<&WRLEvent.Event>)
	}
	
	// EventInfo
	// This struct is used to return information about an Event
	//
	access(all)
	struct EventInfo{ 
		access(all)
		let name: String
		
		access(all)
		let baseReward: UFix64
		
		access(all)
		let rewards: [UFix64; 3]
		
		access(all)
		let participants: [Address; 3]
		
		access(all)
		var finished: Bool
		
		access(all)
		var validations: Int
		
		access(all)
		var resultsUpdated: Bool
		
		access(all)
		var finalStands:{ Address: UInt64}
		
		access(all)
		var penalties:{ Address: UInt64}
		
		init(
			_ name: String,
			_ baseReward: UFix64,
			_ rewards: [
				UFix64; 3
			],
			_ participants: [
				Address; 3
			],
			_ finished: Bool,
			_ validations: Int,
			_ resultsUpdated: Bool,
			_ finalStands:{ 
				Address: UInt64
			},
			_ penalties:{ 
				Address: UInt64
			}
		){ 
			self.name = name
			self.participants = participants
			self.rewards = rewards
			self.baseReward = baseReward
			self.finished = finished
			self.resultsUpdated = resultsUpdated
			self.validations = validations
			self.finalStands = finalStands
			self.penalties = penalties
		}
	}
	
	// Event
	// This resource holds all the information about a given Event on the Wayport Racing League
	//
	access(all)
	resource Event: Validable, ResultSetter, GetEventInfo{ 
		// Name of the event
		access(all)
		let name: String
		
		// The base reward in Lilium that all drivers will receive
		// at the end of the race
		access(all)
		let baseReward: UFix64
		
		// An in-order array with the amount of Lilium that each driver
		// will receive at the end of the race according to the final stands
		access(all)
		let rewards: [UFix64; 3]
		
		// A list with all the participants addresses
		access(all)
		let participants: [Address; 3]
		
		// A flag that indicates if the event is finished
		access(all)
		var finished: Bool
		
		// A flag that indicates if the Oracle has updated the results
		access(all)
		var resultsUpdated: Bool
		
		// A counter that indicates how many Steward had validated the event
		access(all)
		var validations: Int
		
		// A dictionary composed by the participant address and the amount of time
		// that he/she took to complet the event
		access(all)
		var finalStands:{ Address: UInt64}
		
		// A dictionary containing all the penalties that were applied in the event by Stewards
		access(all)
		var penalties:{ Address: UInt64}
		
		init(name: String, participants: [Address; 3], rewards: [UFix64; 3], baseReward: UFix64){ 
			self.name = name
			self.participants = participants
			self.rewards = rewards
			self.baseReward = baseReward
			self.finished = false
			self.resultsUpdated = false
			self.validations = 0
			self.finalStands ={} 
			self.penalties ={} 
		}
		
		// setResults
		// This function updated the race stands, not allowing the update to happen
		// if it's already been updated or if the race is not finished yet
		//
		access(all)
		fun setResults(stands:{ Address: UInt64}){ 
			pre{ 
				self.finished:
					"Race is not finished"
				!self.resultsUpdated:
					"Results were alredy updated"
			}
			self.finalStands = stands
			self.resultsUpdated = true
		}
		
		// addPenalty
		// Adds a time penalty to a given participant. The penalty is applied to the finalStands dictionary
		// and also to the penalties dictionary in order to keep track of all the penalties applied on a given event
		//
		access(all)
		fun addPenalty(participant: Address, time: UInt64){ 
			pre{ 
				// The address must be among the address of the final stands
				self.finalStands.containsKey(participant):
					"The address was not registered in the event"
				// Only one penalty per event
				!self.penalties.containsKey(participant):
					"The participant already received a penalty in this event"
			}
			let participantTime = self.finalStands[participant]!
			self.finalStands[participant] = participantTime + time
			self.penalties.insert(key: participant, time)
		}
		
		// validate
		// Increase the validation counter by 1 unit
		//
		access(all)
		fun validate(){ 
			pre{ 
				self.resultsUpdated:
					"Results were not updated"
			}
			self.validations = self.validations + 1
		}
		
		// end
		// Sets the finished flag to true indicating that the event is over
		//
		access(all)
		fun end(){ 
			pre{ 
				!self.finished:
					"Race is already finished"
			}
			self.finished = true
		}
		
		// sortByTime
		// Returns an array of addresses sorted by finishing time of all participants
		//
		access(all)
		fun sortByTime(): [Address]{ 
			pre{ 
				self.resultsUpdated:
					"Results were not updated"
			}
			let rewardOrder: [Address] = []
			var i = 0
			for participant in self.finalStands.keys{ 
				let currentParticipantTime = self.finalStands[participant]!
				var j = 0
				while j < rewardOrder.length{ 
					let participantTime = self.finalStands[rewardOrder[j]]!
					if currentParticipantTime < participantTime{ 
						break
					}
					j = j + 1
				}
				rewardOrder.insert(at: j, participant)
			}
			return rewardOrder
		}
		
		// getEventInfo
		// Returns all fields of the Event
		//
		access(all)
		fun getEventInfo(): EventInfo{ 
			return EventInfo(self.name, self.baseReward, self.rewards, self.participants, self.finished, self.validations, self.resultsUpdated, self.finalStands, self.penalties)
		}
	}
	
	// EventViewer
	// This resource allows to the UI to easily query the current event being
	// analyzed by a Steward
	//
	access(all)
	resource EventViewer: EventViewerReceiver{ 
		// A capability that exposes the getEventInfo, that will return the info about an Event
		//
		access(all)
		var eventInfoCapability: Capability<&WRLEvent.Event>?
		
		init(){ 
			self.eventInfoCapability = nil
		}
		
		// receiveEventViewer
		// Receives the capability that will be used to return the event info
		//
		access(all)
		fun receiveEventViewer(cap: Capability<&WRLEvent.Event>){ 
			pre{ 
				cap.borrow() != nil:
					"Invalid Event Info Capability"
			}
			self.eventInfoCapability = cap
		}
		
		// getEventInfo
		// Uses the received capability to return the information about an Event
		//
		access(all)
		fun getEventInfo(): EventInfo{ 
			pre{ 
				self.eventInfoCapability != nil:
					"No event info capability"
			}
			let eventRef = (self.eventInfoCapability!).borrow()!
			return eventRef.getEventInfo()
		}
	}
	
	// Steward
	// The Steward resource interacts with some functions in the Event resource
	// to update information about penalties and validate the results updated by the Oracle
	// 
	access(all)
	resource Steward: ValidatorReceiver{ 
		// The capability that allows the interaction with a given Event
		//
		access(all)
		var validateEventCapability: Capability<&WRLEvent.Event>?
		
		init(){ 
			self.validateEventCapability = nil
		}
		
		// receiveValidator
		// Receives and updates the validateEventCapability
		//
		access(all)
		fun receiveValidator(cap: Capability<&WRLEvent.Event>){ 
			pre{ 
				cap.borrow() != nil:
					"Invalid Validator capability"
			}
			self.validateEventCapability = cap
		}
		
		// validateEvent
		// Uses the received capability to validate the Event by increasing the validations counter
		// 
		access(all)
		fun validateEvent(){ 
			pre{ 
				self.validateEventCapability != nil:
					"No validator capability"
			}
			let validatorRef = (self.validateEventCapability!).borrow()!
			validatorRef.validate()
		}
		
		// addPenalty
		// Takes a participant address and an amount of time to be added to the finishing time
		// of that participant, in order to penalize for any incidents that took place in the Event
		//
		access(all)
		fun addPenalty(participant: Address, time: UInt64){ 
			pre{ 
				self.validateEventCapability != nil:
					"No validator capability"
			}
			let validatorRef = (self.validateEventCapability!).borrow()!
			validatorRef.addPenalty(participant: participant, time: time)
		}
	}
	
	// Oracle
	// The Oracle resource will belong to a offchain trusted account that will
	// have access to the final race results for a given Event and will be resposible
	// update the finalStands of the Event
	//
	access(all)
	resource Oracle: ResultSetterReceiver{ 
		// The capability that will allow the interaction with the setResults function from the Event resource
		access(all)
		var resultSetter: Capability<&WRLEvent.Event>?
		
		init(){ 
			self.resultSetter = nil
		}
		
		// receiveResultSetter
		// Receives and stores the capability that allows interaction with Event resource
		access(all)
		fun receiveResultSetter(cap: Capability<&WRLEvent.Event>){ 
			pre{ 
				cap.borrow() != nil:
					"Invalid Validator capability"
			}
			self.resultSetter = cap
		}
		
		// setResults
		// Receives a dictionary containing the participant address and the time that participant
		// took to finish the race as the value and sets it as the Event finalStands
		access(all)
		fun setResults(results:{ Address: UInt64}){ 
			pre{ 
				self.resultSetter != nil:
					"No capability"
			}
			let resultSetterRef = (self.resultSetter!).borrow()!
			resultSetterRef.setResults(stands: results)
		}
	}
	
	// Administrator
	// The Administrator resource is the only resource able to create new
	// event resources, therefore the only one able to delegate Validators and ResultSetters
	access(all)
	resource Administrator{ 
		access(all)
		fun createEvent(
			eventName: String,
			participants: [
				Address; 3
			],
			rewards: [
				UFix64; 3
			],
			baseReward: UFix64
		): @Event{ 
			return <-create Event(
				name: eventName,
				participants: participants,
				rewards: rewards,
				baseReward: baseReward
			)
		}
	}
	
	// createSteward
	// Creates a new instance of Steward resource returns it
	//
	access(all)
	fun createSteward(): @Steward{ 
		return <-create Steward()
	}
	
	// createEventViewer
	// Creates a new instance of EventViewer resource and returns it
	//
	access(all)
	fun createEventViewer(): @EventViewer{ 
		return <-create EventViewer()
	}
	
	// createOracle
	// Creates a new instance of Oracle resource and returns it
	//
	access(all)
	fun createOracle(): @Oracle{ 
		return <-create Oracle()
	}
	
	init(){ 
		let adminAccount = self.account
		let admin <- create Administrator()
		adminAccount.storage.save(<-admin, to: /storage/admin)
	}
}
