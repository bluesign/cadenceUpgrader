// As of September 2023, Unicode 0x30000 to 0xDFFFF are undefined,
// but something might be discovered in the future.
access(all)
contract UndefinedCode{ 
	access(all)
	event Find(codePoint: UInt32)
	
	access(all)
	resource Code{ 
		access(all)
		let point: UInt32
		
		init(){ 
			self.point = self.random() % (0xDFFFF - 0x30000) + 0x30000
			emit Find(codePoint: self.point)
		}
		
		access(self)
		fun random(): UInt32{ 
			let id = getCurrentBlock().id
			return (UInt32(id[0]) << 16) + (UInt32(id[1]) << 8) + UInt32(id[2])
		}
	}
	
	access(all)
	fun find(): @Code{ 
		return <-create Code()
	}
}
