access(all)
contract ActualInfinity{ 
	access(all)
	resource Creativity{ 
		access(all)
		var creativity: @Creativity
		
		init(){ 
			self.creativity <- create Creativity()
		}
	}
	
	access(all)
	fun _create(): @Creativity{ 
		return <-create Creativity()
	}
}
