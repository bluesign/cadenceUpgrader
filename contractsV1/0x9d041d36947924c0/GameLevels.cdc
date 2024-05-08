access(all)
contract interface GameLevels{ 
	access(all)
	fun createLevel(_ name: String): AnyStruct?{ 
		return nil
	}
	
	access(all)
	fun getAvailableLevels(): [String]{ 
		return []
	}
}
