import FlowtyRaffles from "./FlowtyRaffles.cdc"

/*
FlowtyRaffleSource - Contains a basic implementation of RaffleSource which can be used for all `AnyStruct`
types. For example, if a consumer of this resource wanted to make a raffle that uses an array of Addresses as the pool
to draw from, they could use the AnyStructRaffleSource with an entry type of Type<Address>() and would be guaranteed to only
be able to put addresses in their array of entries.

This is enforced so that consumers of that source can have safety when reading entries from the array in case they want to handle any additional
logic alongside the raffle itself, such as distributing a prize when a raffle is drawn

In addition to entryType, a field called `removeAfterReveal` is also provided, which, if enabled, will remove an entry
from the entries array any time a reveal is performed. This is useful for cases where you don't want the same entry to be able to be drawn
multiple times.
*/

access(all)
contract FlowtyRaffleSource{ 
	access(all)
	resource AnyStructRaffleSource:
		FlowtyRaffles.RaffleSourcePublic,
		FlowtyRaffles.RaffleSourcePrivate{
	
		access(all)
		let entries: [AnyStruct]
		
		access(all)
		let entryType: Type
		
		access(all)
		let removeAfterReveal: Bool
		
		access(all)
		fun getEntryType(): Type{ 
			return self.entryType
		}
		
		access(all)
		fun getEntryAt(index: Int): AnyStruct{ 
			return self.entries[index]
		}
		
		access(all)
		fun getEntries(): [AnyStruct]{ 
			return self.entries
		}
		
		access(all)
		fun getEntryCount(): Int{ 
			return self.entries.length
		}
		
		access(all)
		fun addEntry(_ v: AnyStruct){ 
			pre{ 
				v.getType() == self.entryType:
					"incorrect entry type"
			}
			self.entries.append(v)
		}
		
		access(all)
		fun addEntries(_ v: [AnyStruct]){ 
			pre{ 
				VariableSizedArrayType(self.entryType) == v.getType():
					"incorrect array type"
			}
			self.entries.appendAll(v)
		}
		
		access(all)
		fun revealCallback(drawingResult: FlowtyRaffles.DrawingResult){ 
			if !self.removeAfterReveal{ 
				return
			}
			self.entries.remove(at: drawingResult.index)
		}
		
		init(entryType: Type, removeAfterReveal: Bool){ 
			self.entries = []
			self.entryType = entryType
			self.removeAfterReveal = removeAfterReveal
		}
	}
	
	access(all)
	fun createRaffleSource(entryType: Type, removeAfterReveal: Bool): @AnyStructRaffleSource{ 
		pre{ 
			entryType.isSubtype(of: Type<AnyStruct>()):
				"entry type must be a subtype of AnyStruct"
		}
		return <-create AnyStructRaffleSource(
			entryType: entryType,
			removeAfterReveal: removeAfterReveal
		)
	}
}
