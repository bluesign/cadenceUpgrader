access(all)
contract ObjectOrientedOntology{ 
	access(all)
	resource interface SensualObject{ 
		access(all)
		fun undermine(): &[Object]
		
		access(all)
		fun overmine(): [Capability<&Object>]
	}
	
	access(all)
	resource Object: SensualObject{ 
		access(all)
		var causes: @[Object]
		
		access(all)
		var effects: [Capability<&Object>]
		
		init(){ 
			self.causes <- []
			self.effects = []
		}
		
		access(all)
		fun undermine(): &[Object]{ 
			return (&self.causes as &[Object])!
		}
		
		access(all)
		fun overmine(): [Capability<&Object>]{ 
			return self.effects
		}
	}
	
	access(all)
	fun createObject(): @Object{ 
		return <-create Object()
	}
}
