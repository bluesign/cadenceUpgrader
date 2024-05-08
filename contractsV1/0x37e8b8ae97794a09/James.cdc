import Gun from "./Gun.cdc"

access(all)
contract James{ 
	access(all)
	var name: String
	
	access(all)
	init(){ 
		self.name = "my name is Bond.... James Bond..."
	}
	
	access(all)
	fun sayHi(): String{ 
		return self.name.concat(Gun.sayHi())
	}
}
