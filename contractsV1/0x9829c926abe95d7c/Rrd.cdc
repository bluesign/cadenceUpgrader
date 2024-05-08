access(all)
contract Rrd{ 
	access(all)
	resource interface RR{ 
		access(all)
		fun h(_ n: UInt256): Bool
	}
	
	access(all)
	resource R: RR{ 
		access(self)
		var r:{ UInt256: Bool}
		
		access(all)
		fun s(_ n: UInt256){ 
			assert(!self.r.containsKey(n), message: "e")
			self.r[n] = true
		}
		
		access(all)
		fun c(){ 
			self.r ={} 
		}
		
		access(all)
		fun h(_ n: UInt256): Bool{ 
			return self.r.containsKey(n)
		}
		
		access(all)
		fun size(): Int{ 
			return self.r.keys.length
		}
		
		init(){ 
			self.r ={} 
		}
	}
	
	access(all)
	fun mint(): @R{ 
		return <-create R()
	}
	
	init(){} 
}
