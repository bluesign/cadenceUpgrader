access(all)
contract YaoyorozunoKami{ 
	access(all)
	resource Kami{ 
		access(all)
		let name: String
		
		init(name: String){ 
			self.name = name
		}
	}
	
	access(all)
	resource Creator{ 
		access(all)
		fun _create(name: String): @Kami{ 
			return <-create Kami(name: name)
		}
	}
	
	init(){ 
		self.account.storage.save(<-create Creator(), to: /storage/Creator)
		var capability_1 = self.account.capabilities.storage.issue<&Creator>(/storage/Creator)
		self.account.capabilities.publish(capability_1, at: /public/Creator)
	}
}
