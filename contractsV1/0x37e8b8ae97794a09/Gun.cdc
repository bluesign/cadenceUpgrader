access(all)
contract Gun{ 
	access(all)
	var effect: String
	
	access(all)
	init(){ 
		self.effect = "peew peew"
	}
	
	access(all)
	fun sayHi(): String{ 
		return self.effect
	}
}
