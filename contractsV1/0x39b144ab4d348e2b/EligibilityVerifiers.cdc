// EligibilityVerifiers are used to check the eligibility of accounts
//
// With drizzle, you can decide who is eligible for your rewards by using our different modes.
// 1. FLOAT Event. You can limit the eligibility to people who own FLOATs of specific FLOAT Event at the time of the DROP being created.
// 2. FLOAT Group. You can also limit the eligibility to people who own FLOATs in a FLOAT Group. You can set a threshold to the number of FLOATs the users should have.
// 3. Whitelist. You can upload a whitelist. Only accounts on the whitelist are eligible for rewards.
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FLOAT from "../0x2d4c3caffbeab845/FLOAT.cdc"

access(all)
contract EligibilityVerifiers{ 
	access(all)
	enum VerifyMode: UInt8{ 
		access(all)
		case oneOf
		
		access(all)
		case all
	}
	
	access(all)
	struct VerifyResultV2{ 
		access(all)
		let isEligible: Bool
		
		access(all)
		let usedNFTs: [UInt64]
		
		access(all)
		let extraData:{ String: AnyStruct}
		
		init(isEligible: Bool, usedNFTs: [UInt64], extraData:{ String: AnyStruct}){ 
			self.isEligible = isEligible
			self.usedNFTs = usedNFTs
			self.extraData = extraData
		}
	}
	
	access(all)
	struct interface INFTRecorder{ 
		access(all)
		let usedNFTs:{ UInt64: Address}
		
		access(all)
		fun addUsedNFTs(account: Address, nftTokenIDs: [UInt64])
	}
	
	access(all)
	struct interface IEligibilityVerifier{ 
		access(all)
		let type: String
		
		access(all)
		fun verify(account: Address, params:{ String: AnyStruct}): VerifyResultV2
	}
	
	access(all)
	struct FLOATEventData{ 
		access(all)
		let host: Address
		
		access(all)
		let eventID: UInt64
		
		init(host: Address, eventID: UInt64){ 
			self.host = host
			self.eventID = eventID
		}
	}
	
	access(all)
	struct FLOATGroupData{ 
		access(all)
		let host: Address
		
		access(all)
		let name: String
		
		init(host: Address, name: String){ 
			self.host = host
			self.name = name
		}
	}
	
	access(all)
	struct Whitelist: IEligibilityVerifier{ 
		access(all)
		let whitelist:{ Address: AnyStruct}
		
		access(all)
		let type: String
		
		init(whitelist:{ Address: AnyStruct}){ 
			self.whitelist = whitelist
			self.type = "Whitelist"
		}
		
		access(all)
		fun verify(account: Address, params:{ String: AnyStruct}): VerifyResultV2{ 
			return VerifyResultV2(isEligible: self.whitelist[account] != nil, usedNFTs: [], extraData:{} )
		}
	}
	
	access(all)
	struct FLOATsV2: IEligibilityVerifier, INFTRecorder{ 
		access(all)
		let events: [FLOATEventData]
		
		access(all)
		let threshold: UInt32
		
		access(all)
		let mintedBefore: UFix64
		
		access(all)
		let type: String
		
		access(all)
		let usedNFTs:{ UInt64: Address}
		
		init(events: [FLOATEventData], mintedBefore: UFix64, threshold: UInt32){ 
			pre{ 
				threshold > 0:
					"Threshold should greater than 0"
				events.length > 0:
					"Events should not be empty"
			}
			self.events = events
			self.threshold = threshold
			// The FLOAT should be received before this DROP be created
			// or the users can transfer their FLOATs and claim again
			self.mintedBefore = mintedBefore
			self.type = "FLOATs"
			self.usedNFTs ={} 
		}
		
		access(all)
		fun verify(account: Address, params:{ String: AnyStruct}): VerifyResultV2{ 
			let floatCollection = getAccount(account).capabilities.get<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath).borrow<&FLOAT.Collection>()
			if floatCollection == nil{ 
				return VerifyResultV2(isEligible: false, usedNFTs: [], extraData:{} )
			}
			let validFLOATs: [UInt64] = []
			for _event in self.events{ 
				let ownedIDs = (floatCollection!).ownedIdsFromEvent(eventId: _event.eventID)
				for floatID in ownedIDs{ 
					if self.usedNFTs[floatID] == nil{ 
						if let float = (floatCollection!).borrowFLOAT(id: floatID){ 
							if float.dateReceived <= self.mintedBefore{ 
								validFLOATs.append(floatID)
								if UInt32(validFLOATs.length) >= self.threshold{ 
									return VerifyResultV2(isEligible: true, usedNFTs: validFLOATs, extraData:{} )
								}
							}
						}
					}
				}
			}
			return VerifyResultV2(isEligible: false, usedNFTs: [], extraData:{} )
		}
		
		access(all)
		fun addUsedNFTs(account: Address, nftTokenIDs: [UInt64]){ 
			for tokenID in nftTokenIDs{ 
				self.usedNFTs[tokenID] = account
			}
		}
	}
	
	// Deprecated for FLOAT v2 removed Group
	access(all)
	struct FLOATGroupV2: IEligibilityVerifier, INFTRecorder{ 
		access(all)
		let group: FLOATGroupData
		
		access(all)
		let threshold: UInt32
		
		access(all)
		let mintedBefore: UFix64
		
		access(all)
		let type: String
		
		access(all)
		let usedNFTs:{ UInt64: Address}
		
		init(group: FLOATGroupData, mintedBefore: UFix64, threshold: UInt32){ 
			pre{ 
				threshold > 0:
					"threshold should greater than 0"
			}
			self.group = group
			self.threshold = threshold
			// The FLOAT should be received before this DROP be created
			// or the users can transfer their FLOATs and claim again
			self.mintedBefore = mintedBefore
			self.type = "FLOATGroup"
			self.usedNFTs ={} 
		}
		
		access(all)
		fun verify(account: Address, params:{ String: AnyStruct}): VerifyResultV2{ 
			// let floatEventCollection = getAccount(self.group.host)
			//	 .getCapability(FLOAT.FLOATEventsPublicPath)
			//	 .borrow<&FLOAT.FLOATEvents{FLOAT.FLOATEventsPublic}>()
			//	 ?? panic("Could not borrow the FLOAT Events Collection from the account.")
			
			// let group = floatEventCollection.getGroup(groupName: self.group.name) 
			//	 ?? panic("This group doesn't exist.")
			// let eventIDs = group.getEvents()
			
			// let floatCollection = getAccount(account)
			//	 .getCapability(FLOAT.FLOATCollectionPublicPath)
			//	 .borrow<&FLOAT.Collection{FLOAT.CollectionPublic}>()
			
			// if floatCollection == nil {
			//	 return VerifyResultV2(isEligible: false, usedNFTs: [], extraData: {})
			// } 
			
			// let validFLOATs: [UInt64] = []
			// // What if some one have several FLOATs of one event in the group?
			// // It should not pass the verification
			
			// // EventID: FloatID
			// let eventFLOAT: {UInt64: UInt64} = {}
			// for eventID in eventIDs {
			//	 let ownedIDs = floatCollection!.ownedIdsFromEvent(eventId: eventID)
			//	 for floatID in ownedIDs {
			//		 if eventFLOAT[eventID] != nil {
			//			 break
			//		 }
			
			//		 if self.usedNFTs[floatID] == nil {
			//			 if let float = floatCollection!.borrowFLOAT(id: floatID) {
			//				 if float.dateReceived <= self.mintedBefore {
			//					 validFLOATs.append(floatID)
			//					 eventFLOAT.insert(key: eventID, floatID)
			//					 if UInt32(eventFLOAT.keys.length) >= self.threshold {
			//						 return VerifyResultV2(isEligible: true, usedNFTs: validFLOATs, extraData: {})
			//					 }
			//				 }
			//			 }
			//		 }
			//	 }
			// }
			return VerifyResultV2(isEligible: false, usedNFTs: [], extraData:{} )
		}
		
		access(all)
		fun addUsedNFTs(account: Address, nftTokenIDs: [UInt64]){ 
			for tokenID in nftTokenIDs{ 
				self.usedNFTs[tokenID] = account
			}
		}
	}
	
	// pub struct Flovatar: IEligibilityVerifier {
	//	 pub fun verify(account: Address, params: {String: AnyStruct}): VerifyResultV2 {
	//		 let flovatarCollection = getAccount(account)
	//			 .getCapability(Flovatar.CollectionPublicPath)
	//			 .borrow<&{Flovatar.CollectionPublic}>()
	//		 if flovatarCollection == nil {
	//			 return VerifyResultV2(isEligible: false, extraData: {})
	//		 }
	//		 let flovatarIDs = flovatarCollection!.getIDs()
	//		 let isEligible = flovatarIDs.length > 0
	//		 return VerifyResultV2(isEligible: isEligible, extraData: {})
	//	 }
	//	 init() {}
	// }
	// Deprecated
	access(all)
	struct VerifyResult{ 
		access(all)
		let isEligible: Bool
		
		access(all)
		let extraData:{ String: AnyStruct}
		
		init(isEligible: Bool, extraData:{ String: AnyStruct}){ 
			self.isEligible = isEligible
			self.extraData = extraData
		}
	}
	
	// Depreacted
	access(all)
	struct FLOATGroup: IEligibilityVerifier{ 
		access(all)
		let group: FLOATGroupData
		
		access(all)
		let threshold: UInt32
		
		access(all)
		let receivedBefore: UFix64
		
		access(all)
		let type: String
		
		init(group: FLOATGroupData, threshold: UInt32){ 
			pre{ 
				threshold > 0:
					"threshold should greater than 0"
			}
			self.group = group
			self.threshold = threshold
			// The FLOAT should be received before this DROP be created
			// or the users can transfer their FLOATs and claim again
			self.receivedBefore = getCurrentBlock().timestamp
			self.type = "FLOATGroup"
		}
		
		access(all)
		fun verify(account: Address, params:{ String: AnyStruct}): VerifyResultV2{ 
			// let floatEventCollection = getAccount(self.group.host)
			//	 .getCapability(FLOAT.FLOATEventsPublicPath)
			//	 .borrow<&FLOAT.FLOATEvents{FLOAT.FLOATEventsPublic}>()
			//	 ?? panic("Could not borrow the FLOAT Events Collection from the account.")
			
			// let group = floatEventCollection.getGroup(groupName: self.group.name) 
			//	 ?? panic("This group doesn't exist.")
			// let eventIDs = group.getEvents()
			
			// let floatCollection = getAccount(account)
			//	 .getCapability(FLOAT.FLOATCollectionPublicPath)
			//	 .borrow<&FLOAT.Collection{FLOAT.CollectionPublic}>()
			
			// if floatCollection == nil {
			//	 return VerifyResultV2(isEligible: false, usedNFTs: [], extraData: {})
			// } 
			
			// var validCount: UInt32 = 0
			// for eventID in eventIDs {
			//	 let ownedIDs = floatCollection!.ownedIdsFromEvent(eventId: eventID)
			//	 for ownedEventID in ownedIDs {
			//		 if let float = floatCollection!.borrowFLOAT(id: ownedEventID) {
			//			 if float.dateReceived <= self.receivedBefore {
			//				 validCount = validCount + 1
			//				 if validCount >= self.threshold {
			//					 return VerifyResultV2(isEligible: true, usedNFTs: [], extraData: {})
			//				 }
			//			 }
			//		 }
			//	 }
			// }
			return VerifyResultV2(isEligible: false, usedNFTs: [], extraData:{} )
		}
	}
	
	// Depreacted
	access(all)
	struct FLOATs: IEligibilityVerifier{ 
		access(all)
		let events: [FLOATEventData]
		
		access(all)
		let threshold: UInt32
		
		access(all)
		let receivedBefore: UFix64
		
		access(all)
		let type: String
		
		init(events: [FLOATEventData], threshold: UInt32){ 
			pre{ 
				threshold > 0:
					"Threshold should greater than 0"
				events.length > 0:
					"Events should not be empty"
			}
			self.events = events
			self.threshold = threshold
			// The FLOAT should be received before this DROP be created
			// or the users can transfer their FLOATs and claim again
			self.receivedBefore = getCurrentBlock().timestamp
			self.type = "FLOATs"
		}
		
		access(all)
		fun verify(account: Address, params:{ String: AnyStruct}): VerifyResultV2{ 
			let floatCollection = getAccount(account).capabilities.get<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath).borrow<&FLOAT.Collection>()
			if floatCollection == nil{ 
				return VerifyResultV2(isEligible: false, usedNFTs: [], extraData:{} )
			}
			var validCount: UInt32 = 0
			for _event in self.events{ 
				let ownedIDs = (floatCollection!).ownedIdsFromEvent(eventId: _event.eventID)
				for ownedEventID in ownedIDs{ 
					if let float = (floatCollection!).borrowFLOAT(id: ownedEventID){ 
						if float.dateReceived <= self.receivedBefore{ 
							validCount = validCount + 1
							if validCount >= self.threshold{ 
								return VerifyResultV2(isEligible: true, usedNFTs: [], extraData:{} )
							}
						}
					}
				}
			}
			return VerifyResultV2(isEligible: false, usedNFTs: [], extraData:{} )
		}
	}
}
