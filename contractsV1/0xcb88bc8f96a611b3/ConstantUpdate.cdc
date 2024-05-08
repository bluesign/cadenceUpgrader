access(all)
contract ConstantUpdate{ 
	access(all)
	event HardMaximum(value: UFix64)
	
	access(all)
	let hardMaximum: UFix64
	
	access(all)
	fun doSomethingUnrelated(): Bool{ 
		return true
	}
	
	access(all)
	fun broadcastHardMaximum(){ 
		emit HardMaximum(value: self.hardMaximum)
	}
	
	init(){ 
		self.hardMaximum = 100.0
	}
}
