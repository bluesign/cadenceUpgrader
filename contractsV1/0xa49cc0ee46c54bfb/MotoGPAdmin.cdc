access(all)
contract MotoGPAdmin{ 
	access(all)
	fun getVersion(): String{ 
		return "1.0.1"
	}
	
	access(all)
	resource Admin{ 
		// createAdmin
		// only an admin can ever create
		// a new Admin resource
		//
		access(all)
		fun createAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	init(){ 
		self.account.storage.save(<-create Admin(), to: /storage/motogpAdmin)
	}
}
