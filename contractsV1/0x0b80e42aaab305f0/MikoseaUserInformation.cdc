access(all)
contract MikoseaUserInformation{ 
	access(all)
	let storagePath: StoragePath
	
	access(all)
	let publicPath: PublicPath
	
	access(all)
	let adminPath: StoragePath
	
	access(contract)
	let userData:{ Address: UserInfo}
	
	access(all)
	struct UserInfo{ 
		access(all)
		var metadata:{ String: String}
		
		init(metadata:{ String: String}){ 
			self.metadata = metadata
		}
		
		access(all)
		fun byKey(key: String): String?{ 
			return self.metadata[key]
		}
		
		access(all)
		fun setKeyValue(key: String, value: String){ 
			self.metadata[key] = value
		}
		
		access(all)
		fun update(metadata:{ String: String}){ 
			self.metadata = metadata
		}
	}
	
	access(all)
	resource Admin{ 
		init(){} 
		
		access(all)
		fun upsert(address: Address, metadata:{ String: String}){ 
			MikoseaUserInformation.userData[address] = UserInfo(metadata: metadata)
		}
		
		access(all)
		fun upsertKeyValue(address: Address, key: String, value: String){ 
			if let user = MikoseaUserInformation.userData[address]{ 
				user.setKeyValue(key: key, value: value)
				self.upsert(address: address, metadata: user.metadata)
			} else{ 
				self.upsert(address: address, metadata:{ key: value})
			}
		}
	}
	
	access(all)
	fun findByAddress(address: Address): UserInfo?{ 
		return MikoseaUserInformation.userData[address]
	}
	
	init(){ 
		// Initialize contract paths
		self.storagePath = /storage/MikoseaUserInformation
		self.publicPath = /public/MikoseaUserInformation
		self.adminPath = /storage/MikoseaUserInformationAdmin
		self.userData ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.adminPath)
	}
}
