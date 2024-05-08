access(all)
contract HelloFlow{ 
	access(all)
	let greeting: String
	
	init(){ 
		self.greeting = "Hello, Flow! Love, G"
	}
	
	access(all)
	fun hello(): String{ 
		return self.greeting
	}
}
