access(all)
contract Purification{ 
	access(all)
	struct Desire{} 
	
	access(all)
	resource Human{ 
		access(contract)
		var desires: [Desire]
		
		init(){ 
			self.desires = []
		}
		
		access(all)
		fun live(){ 
			self.desires.append(Desire())
		}
		
		access(contract)
		fun purified(){ 
			self.desires.removeFirst()
		}
	}
	
	access(all)
	fun purify(human: &Human){ 
		while human.desires.length > 0{ 
			human.purified()
		}
	}
	
	access(all)
	fun birth(): @Human{ 
		return <-create Human()
	}
}
