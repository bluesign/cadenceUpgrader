import test from "../0x4dd4b29c1ac89044/test.cdc"

access(all)
contract pf{ 
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
