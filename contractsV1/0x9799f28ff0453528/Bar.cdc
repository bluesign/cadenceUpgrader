access(all)
contract Bar{ 
	access(all)
	event Test(x: String)
	
	access(all)
	var X: String
	
	access(all)
	var Z: String
	
	access(all)
	init(x: String){ 
		self.X = x
		self.Z = "ZZZZ"
	}
	
	access(all)
	fun hello(){ 
		emit Test(x: self.X)
	}
}
