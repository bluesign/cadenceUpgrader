access(all)
contract HelloWorld{ 
	access(all)
	var greeting: String
	
	// The init() function is required if the contract contains any fields.
	init(){ 
		self.greeting = "Hello, World NFTPL!"
	}
	
	access(all)
	fun changeGreeting(newGreeting: String){ 
		self.greeting = newGreeting
	}
	
	access(all)
	fun show(): String{ 
		return self.greeting
	}
}
