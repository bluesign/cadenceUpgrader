access(all)
contract Stuff{ 
	access(all)
	var name: String
	
	access(all)
	fun changeName(newName: String){ 
		self.name = newName
	}
	
	init(){ 
		self.name = "Sahil Saha"
	}
}
