import HeroSurname from "./HeroSurname.cdc"

access(all)
contract Hero{ 
	access(all)
	var name: String
	
	access(all)
	init(){ 
		self.name = "My name is Bond...".concat(HeroSurname.surname)
	}
	
	access(all)
	fun sayName(): String{ 
		return self.name
	}
}
