// 0xea57707519a77b05
// 0xf2bc3e93aa675dd7
access(all)
contract TestImport{ 
	access(all)
	struct TestStruct{ 
		access(all)
		let a: Int
		
		init(){ 
			self.a = 123
		}
	}
}
