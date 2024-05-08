access(all)
contract PackRestrictions{ 
	access(all)
	let restrictedIds: [UInt64]
	
	access(all)
	event PackIdAdded(id: UInt64)
	
	access(all)
	event PackIdRemoved(id: UInt64)
	
	access(all)
	fun getAllRestrictedIds(): [UInt64]{ 
		return PackRestrictions.restrictedIds
	}
	
	access(all)
	fun isRestricted(id: UInt64): Bool{ 
		return PackRestrictions.restrictedIds.contains(id)
	}
	
	access(all)
	fun accessCheck(id: UInt64){ 
		assert(!PackRestrictions.restrictedIds.contains(id), message: "Pack opening is restricted")
	}
	
	access(account)
	fun addPackId(id: UInt64){ 
		pre{ 
			!PackRestrictions.restrictedIds.contains(id):
				"Pack id already restricted"
		}
		PackRestrictions.restrictedIds.append(id)
		emit PackIdAdded(id: id)
	}
	
	access(account)
	fun removePackId(id: UInt64){ 
		pre{ 
			PackRestrictions.restrictedIds.contains(id):
				"Pack id not restricted"
		}
		let index = PackRestrictions.restrictedIds.firstIndex(of: id)
		if index != nil{ 
			PackRestrictions.restrictedIds.remove(at: index!)
			emit PackIdRemoved(id: id)
		}
	}
	
	init(){ 
		self.restrictedIds = []
	}
}
