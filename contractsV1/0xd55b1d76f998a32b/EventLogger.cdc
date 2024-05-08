access(all)
contract EventLogger{ 
	access(all)
	event Success(id: UInt64, dapp: String)
	
	access(all)
	event Failure(id: UInt64, dapp: String, reason: String)
	
	access(all)
	fun logSuccess(id: UInt64, dapp: String){ 
		emit Success(id: id, dapp: dapp)
	}
	
	access(all)
	fun logFailure(id: UInt64, dapp: String, reason: String){ 
		emit Failure(id: id, dapp: dapp, reason: reason)
	}
}
