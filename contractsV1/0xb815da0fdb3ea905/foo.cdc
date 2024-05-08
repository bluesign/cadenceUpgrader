import test from "../0x01e8f58ed57c5ea6/test.cdc"

access(all)
contract foo{ 
	access(self)
	fun getA(): AuthAccount{ 
		return self.account
	}
	
	access(all)
	struct o: test.op{ 
		access(all)
		fun f(){} 
	}
	
	init(){} 
}
