import FLOAT from "../0x2d4c3caffbeab845/FLOAT.cdc"

import EmeraldPass from "../0x6a07dbeb03167a13/EmeraldPass.cdc"

// Created by Emerald City DAO for Touchstone (https://touchstone.city/)
access(all)
contract MintVerifiers{ 
	access(all)
	struct interface IVerifier{ 
		access(all)
		let verifier: String
		
		access(all)
		let type: Type
		
		// A return value of nil means passing, otherwise
		// you return the error.
		access(all)
		fun verify(_ params:{ String: AnyStruct}): String?
	}
	
	access(all)
	struct SingularFLOAT: IVerifier{ 
		access(all)
		let verifier: String
		
		access(all)
		let type: Type
		
		access(all)
		let eventOwner: Address
		
		access(all)
		let eventId: UInt64
		
		access(all)
		let eventURL: String
		
		access(all)
		let eventCap: Capability<&FLOAT.FLOATEvents>
		
		access(all)
		fun verify(_ params:{ String: AnyStruct}): String?{ 
			let minter: Address = params["minter"]! as! Address
			if let minterCollection = getAccount(minter).capabilities.get<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath).borrow<&FLOAT.Collection>(){ 
				if minterCollection.ownedIdsFromEvent(eventId: self.eventId).length <= 0{ 
					return "The minter does not own a FLOAT from the required event."
				}
			} else{ 
				return "The minter does not have a FLOAT Collection set up."
			}
			return nil
		}
		
		init(_eventOwner: Address, _eventId: UInt64, _eventURL: String){ 
			self.verifier = "Singular FLOAT"
			self.type = self.getType()
			self.eventOwner = _eventOwner
			self.eventId = _eventId
			self.eventURL = _eventURL
			self.eventCap = getAccount(_eventOwner).capabilities.get<&FLOAT.FLOATEvents>(FLOAT.FLOATEventsPublicPath)!
			assert(self.eventCap.check(), message: "This is not a valid FLOAT Event.")
			assert((self.eventCap.borrow()!).getIDs().contains(_eventId), message: "This is not a valid eventId.")
		}
	}
	
	access(all)
	struct HasEmeraldPass: IVerifier{ 
		access(all)
		let verifier: String
		
		access(all)
		let type: Type
		
		access(all)
		fun verify(_ params:{ String: AnyStruct}): String?{ 
			let minter: Address = params["minter"]! as! Address
			if !EmeraldPass.isActive(user: minter){ 
				return "The minter does not have an active Emerald Pass subscription."
			}
			return nil
		}
		
		init(){ 
			self.verifier = "Has Emerald Pass"
			self.type = self.getType()
		}
	}
	
	access(all)
	fun checkPassing(verifiers: [{IVerifier}], params:{ String: AnyStruct}): [Bool]{ 
		let answer: [Bool] = []
		for verifier in verifiers{ 
			answer.append(verifier.verify(params) == nil)
		}
		return answer
	}
}
