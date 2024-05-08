access(all)
contract C{ 
	access(all)
	struct S{ 
		access(all)
		let cap: Capability
		
		init(cap: Capability){ 
			self.cap = cap
		}
	}
}
