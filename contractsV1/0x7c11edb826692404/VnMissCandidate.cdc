access(all)
contract VnMissCandidate{ 
	access(self)
	let listCandidate:{ UInt64: Candidate}
	
	access(self)
	let top40:{ UInt64: Bool}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let MaxCandidate: Int
	
	access(all)
	event NewCandidate(id: UInt64, name: String, fundAddress: Address)
	
	access(all)
	event CandidateUpdate(id: UInt64, name: String, fundAddress: Address)
	
	access(all)
	struct Candidate{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let code: String
		
		access(all)
		let description: String
		
		access(all)
		let fundAdress: Address
		
		access(all)
		let properties:{ String: String}
		
		init(
			id: UInt64,
			name: String,
			code: String,
			description: String,
			fundAddress: Address,
			properties:{ 
				String: String
			}
		){ 
			self.id = id
			self.name = name
			self.code = code
			self.description = description
			self.fundAdress = fundAddress
			self.properties = properties
		}
		
		access(all)
		fun buildName(level: String, id: UInt64): String{ 
			return self.name.concat(" ").concat(self.code).concat(" - ").concat(level).concat("#")
				.concat(id.toString())
		}
		
		access(all)
		fun inTop40(): Bool{ 
			return VnMissCandidate.top40[self.id] ?? false
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun createCandidate(
			id: UInt64,
			name: String,
			code: String,
			description: String,
			fundAddress: Address,
			properties:{ 
				String: String
			}
		){ 
			pre{ 
				VnMissCandidate.listCandidate.length < VnMissCandidate.MaxCandidate:
					"Exceed maximum"
			}
			VnMissCandidate.listCandidate[id] = Candidate(
					id: id,
					name: name,
					code: code,
					description: description,
					fundAddress: fundAddress,
					properties: properties
				)
			emit NewCandidate(id: id, name: name, fundAddress: fundAddress)
		}
		
		access(all)
		fun markTop40(ids: [UInt64], isTop40: Bool){ 
			for id in ids{ 
				VnMissCandidate.top40[id] = isTop40
			}
		}
		
		access(all)
		fun updateCandidate(
			id: UInt64,
			name: String,
			code: String,
			description: String,
			fundAddress: Address,
			properties:{ 
				String: String
			}
		){ 
			pre{ 
				VnMissCandidate.listCandidate.containsKey(id):
					"Candidate not exist"
			}
			VnMissCandidate.listCandidate[id] = Candidate(
					id: id,
					name: name,
					code: code,
					description: description,
					fundAddress: fundAddress,
					properties: properties
				)
			emit CandidateUpdate(id: id, name: name, fundAddress: fundAddress)
		}
	}
	
	access(all)
	fun getCandidate(id: UInt64): Candidate?{ 
		return self.listCandidate[id]
	}
	
	init(){ 
		self.listCandidate ={} 
		self.AdminStoragePath = /storage/BNVNMissCandidateAdmin
		self.MaxCandidate = 71
		self.top40 ={} 
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
