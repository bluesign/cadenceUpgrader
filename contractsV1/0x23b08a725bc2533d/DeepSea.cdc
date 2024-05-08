access(all)
contract DeepSea{ 
	access(all)
	resource Deep{ 
		access(all)
		var mystery: @AnyResource?
		
		init(_ depth: Int){ 
			if depth > 1000{ 
				self.mystery <- nil
			} else if depth == Int(revertibleRandom() % 400 + 100){ 
				self.mystery <- create Coelacanth()
			} else{ 
				self.mystery <- create Deep(depth + 1)
			}
		}
	}
	
	access(all)
	resource Coelacanth{} 
	
	access(all)
	fun dive(): @Deep{ 
		return <-create Deep(0)
	}
}
