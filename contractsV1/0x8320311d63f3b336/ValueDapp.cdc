access(all)
contract ValueDapp{ 
	access(all)
	var value: UFix64
	
	init(){ 
		self.value = UFix64(0)
	}
	
	access(all)
	fun setValue(_ value: UFix64){ 
		self.value = value
	}
}
