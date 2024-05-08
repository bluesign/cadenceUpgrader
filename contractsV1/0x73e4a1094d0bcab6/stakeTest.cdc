access(all)
contract stakeTest{ 
	access(all)
	var stakers: [Address]
	
	access(all)
	fun append(_ x: Address){ 
		self.stakers.append(x)
	}
	
	init(){ 
		self.stakers = []
	}
}
