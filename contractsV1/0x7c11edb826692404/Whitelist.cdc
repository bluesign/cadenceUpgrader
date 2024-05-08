access(all)
contract Whitelist{ 
	access(self)
	let whitelist:{ Address: Bool}
	
	access(self)
	let bought:{ Address: Bool}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	event WhitelistUpdate(addresses: [Address], whitelisted: Bool)
	
	access(all)
	resource Admin{ 
		access(all)
		fun addWhitelist(addresses: [Address]){ 
			for address in addresses{ 
				Whitelist.whitelist[address] = true
			}
			emit WhitelistUpdate(addresses: addresses, whitelisted: true)
		}
		
		access(all)
		fun unWhitelist(addresses: [Address]){ 
			for address in addresses{ 
				Whitelist.whitelist[address] = false
			}
			emit WhitelistUpdate(addresses: addresses, whitelisted: false)
		}
	}
	
	access(account)
	fun markAsBought(address: Address){ 
		self.bought[address] = true
	}
	
	access(all)
	fun whitelisted(address: Address): Bool{ 
		return self.whitelist[address] ?? false
	}
	
	access(all)
	fun hasBought(address: Address): Bool{ 
		return self.bought[address] ?? false
	}
	
	init(){ 
		self.whitelist ={} 
		self.bought ={} 
		self.AdminStoragePath = /storage/BNMUWhitelistAdmin
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
