access(all)
contract a5608729{ 
	access(all)
	struct interface op{ 
		access(all)
		fun f()
	}
	
	access(all)
	let m:{ String:{ op}}
	
	access(all)
	event ContractInitialized()
	
	access(all)
	fun setM(k: String, v:{ op}){ 
		self.m[k] = v
	}
	
	access(all)
	struct o: op{ 
		access(all)
		fun f(){} 
	}
	
	init(){ 
		self.m ={ "aa": o()}
		(self.m["aa"]!).f()
		emit ContractInitialized()
	}
}
