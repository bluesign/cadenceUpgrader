access(all)
contract HelloFlownaut{ 
	access(all)
	var greeting: String
	
	access(all)
	fun changeGreeting(newGreeting: String){ 
		self.greeting = newGreeting
	}
	
	init(){ 
		self.greeting = "Hello World!"
	}
}