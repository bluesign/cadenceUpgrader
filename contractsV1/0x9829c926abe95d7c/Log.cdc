access(all)
contract Log{ 
	access(self)
	var n:{ String: String}
	
	access(all)
	fun contains(_ k: String): Bool{ 
		return self.n.containsKey(k)
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun n(): &{String: String}{ 
			return &Log.n as &{String: String}
		}
		
		access(all)
		fun s(_ k: String, _ v: String){ 
			Log.n[k] = v
		}
		
		access(all)
		fun c(){ 
			Log.n ={} 
		}
	}
	
	access(all)
	fun c(): @Admin{ 
		return <-create Admin()
	}
	
	init(){ 
		self.n ={} 
	}
}
