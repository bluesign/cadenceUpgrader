access(all)
contract Deities{ 
	
	// Deity can be defined, but it cannot be instantiated.
	access(all)
	resource Deity{ 
		access(all)
		var name: String
		
		access(all)
		var gender: String?
		
		access(all)
		var ability: String?
		
		access(all)
		var purpose: String?
		
		init(name: String, gender: String?, ability: String?, purpose: String?){ 
			self.name = name
			self.gender = gender
			self.ability = ability
			self.purpose = purpose
		}
	}
}
