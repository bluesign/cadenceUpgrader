access(all)
contract Waterfalls{ 
	access(all)
	resource Carp{} 
	
	access(all)
	resource Dragon{ 
		init(_ carp: @Carp){ 
			destroy carp
		}
	}
	
	access(all)
	resource Waterfall{ 
		access(all)
		let wall: UInt64
		
		init(_ wall: UInt64){ 
			self.wall = wall
		}
		
		access(all)
		fun hatch(): @Carp{ 
			return <-create Carp()
		}
		
		access(all)
		fun climb(carp: @Carp): @Dragon?{ 
			if revertibleRandom<UInt64>() < self.wall{ 
				destroy carp
				return nil
			}
			return <-create Dragon(<-carp)
		}
	}
	
	access(all)
	fun _create(wall: UInt64): @Waterfall{ 
		return <-create Waterfall(wall)
	}
}
