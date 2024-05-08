access(all)
contract FirstFinalTouch{ 
	access(all)
	resource Dragon{ 
		access(all)
		var eyes: [Bool; 2]?
		
		init(){ 
			self.eyes = nil
		}
	}
	
	access(all)
	var dragon: @[Dragon]
	
	init(){ 
		self.dragon <- [<-create Dragon()]
	}
	
	access(all)
	fun finalize(){ 
		var dragon <- self.dragon.removeFirst()
		dragon.eyes = [true, true]
		destroy dragon
	}
}
