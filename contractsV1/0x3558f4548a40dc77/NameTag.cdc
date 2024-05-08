
// Simplified version from https://flow-view-source.com/testnet/account/0xba1132bc08f82fe2/contract/Profile
// It allows to somone to update a stauts on the blockchain
access(all)
contract NameTag{ 
	access(all)
	let publicPath: PublicPath
	
	access(all)
	let storagePath: StoragePath
	
	access(all)
	resource interface Public{ 
		access(all)
		fun readTag(): String
	}
	
	access(all)
	resource interface Owner{ 
		access(all)
		fun readTag(): String
		
		access(all)
		fun changeTag(_ tag: String){ 
			pre{ 
				tag.length <= 15:
					"Tags must be under 15 characters long."
			}
		}
	}
	
	access(all)
	resource Base: Owner, Public{ 
		access(self)
		var tag: String
		
		init(){ 
			self.tag = ""
		}
		
		access(all)
		fun readTag(): String{ 
			return self.tag
		}
		
		access(all)
		fun changeTag(_ tag: String){ 
			self.tag = tag
		}
	}
	
	access(all)
	fun new(): @NameTag.Base{ 
		return <-create Base()
	}
	
	access(all)
	fun hasTag(_ address: Address): Bool{ 
		return getAccount(address).capabilities.get<&{NameTag.Public}>(NameTag.publicPath).check()
	}
	
	access(all)
	fun fetch(_ address: Address): &{NameTag.Public}{ 
		return getAccount(address).capabilities.get<&{NameTag.Public}>(NameTag.publicPath).borrow()!
	}
	
	init(){ 
		self.publicPath = /public/boulangeriev1PublicNameTag
		self.storagePath = /storage/boulangeriev1StorageNameTag
		self.account.storage.save(<-self.new(), to: self.storagePath)
		var capability_1 = self.account.capabilities.storage.issue<&Base>(self.storagePath)
		self.account.capabilities.publish(capability_1, at: self.publicPath)
	}
}
