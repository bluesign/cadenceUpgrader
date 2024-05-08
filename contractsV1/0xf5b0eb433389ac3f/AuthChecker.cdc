access(all)
contract AuthChecker{ 
	access(all)
	event AddressNonceEvent(nonceString: String)
	
	access(all)
	fun checkLogin(_ nonceString: String): Void{ 
		pre{ 
			nonceString.length != 0:
				"Empty string"
		}
		emit AddressNonceEvent(nonceString: nonceString)
	}
}
