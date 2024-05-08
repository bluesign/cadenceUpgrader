access(all)
contract Metabolism{ 
	access(all)
	resource Cell{ 
		access(all)
		var is_dead: Bool
		
		init(){ 
			self.is_dead = false
		}
		
		access(all)
		fun kill(): @Cell{ 
			self.is_dead = true
			return <-create Cell()
		}
	}
	
	init(){ 
		self.account.storage.save(<-create Cell(), to: /storage/MetabolismCell)
	}
}
