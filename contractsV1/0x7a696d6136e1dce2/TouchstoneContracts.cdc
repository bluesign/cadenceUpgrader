// Created by Emerald City DAO for Touchstone (https://touchstone.city/)
access(all)
contract TouchstoneContracts{ 
	access(all)
	let ContractsBookStoragePath: StoragePath
	
	access(all)
	let ContractsBookPublicPath: PublicPath
	
	access(all)
	let GlobalContractsBookStoragePath: StoragePath
	
	access(all)
	let GlobalContractsBookPublicPath: PublicPath
	
	access(all)
	enum ReservationStatus: UInt8{ 
		access(all)
		case notFound // was never made
		
		
		access(all)
		case expired // this means someone made it but their Emerald Pass expired
		
		
		access(all)
		case active // is currently active
	
	}
	
	access(all)
	resource interface ContractsBookPublic{ 
		access(all)
		fun getContracts(): [String]
	}
	
	access(all)
	resource ContractsBook: ContractsBookPublic{ 
		access(all)
		let contractNames:{ String: Bool}
		
		access(all)
		fun addContract(contractName: String){ 
			pre{ 
				self.contractNames[contractName] == nil:
					"You already have a contract with this name."
			}
			let me: Address = (self.owner!).address
			self.contractNames[contractName] = true
			let globalContractsBook = TouchstoneContracts.account.storage.borrow<&GlobalContractsBook>(from: TouchstoneContracts.GlobalContractsBookStoragePath)!
			globalContractsBook.addUser(address: me)
			globalContractsBook.reserve(contractName: contractName, user: me)
		}
		
		access(all)
		fun removeContract(contractName: String){ 
			self.contractNames.remove(key: contractName)
		}
		
		access(all)
		fun getContracts(): [String]{ 
			return self.contractNames.keys
		}
		
		init(){ 
			self.contractNames ={} 
		}
	}
	
	access(all)
	resource interface GlobalContractsBookPublic{ 
		access(all)
		fun getAllUsers(): [Address]
		
		access(all)
		fun getAllReservations():{ String: Address}
		
		access(all)
		fun getAddressFromContractName(contractName: String): Address?
		
		access(all)
		view fun getReservationStatus(contractName: String): ReservationStatus
	}
	
	access(all)
	resource GlobalContractsBook: GlobalContractsBookPublic{ 
		access(all)
		let allUsers:{ Address: Bool}
		
		access(all)
		let reservedContractNames:{ String: Address}
		
		access(all)
		fun addUser(address: Address){ 
			self.allUsers[address] = true
		}
		
		access(all)
		fun reserve(contractName: String, user: Address){ 
			pre{ 
				self.getReservationStatus(contractName: contractName) != ReservationStatus.active:
					contractName.concat(" is already taken!")
			}
			self.reservedContractNames[contractName] = user
		}
		
		access(all)
		fun removeReservation(contractName: String){ 
			self.reservedContractNames.remove(key: contractName)
		}
		
		access(all)
		fun getAllUsers(): [Address]{ 
			return self.allUsers.keys
		}
		
		access(all)
		fun getAllReservations():{ String: Address}{ 
			return self.reservedContractNames
		}
		
		access(all)
		view fun getReservationStatus(contractName: String): ReservationStatus{ 
			if let reservedBy = self.reservedContractNames[contractName]{ 
				return ReservationStatus.active
			}
			return ReservationStatus.notFound
		}
		
		access(all)
		fun getAddressFromContractName(contractName: String): Address?{ 
			if self.getReservationStatus(contractName: contractName) == ReservationStatus.active{ 
				return self.reservedContractNames[contractName]
			}
			return nil
		}
		
		init(){ 
			self.allUsers ={} 
			self.reservedContractNames ={} 
		}
	}
	
	access(all)
	fun createContractsBook(): @ContractsBook{ 
		return <-create ContractsBook()
	}
	
	access(all)
	fun getUserTouchstoneCollections(user: Address): [String]{ 
		let collections =
			getAccount(user).capabilities.get<&ContractsBook>(
				TouchstoneContracts.ContractsBookPublicPath
			).borrow<&ContractsBook>()
			?? panic("This user has not set up a Collections yet.")
		return collections.getContracts()
	}
	
	access(all)
	fun getGlobalContractsBook(): &GlobalContractsBook{ 
		return self.account.capabilities.get<&GlobalContractsBook>(
			TouchstoneContracts.GlobalContractsBookPublicPath
		).borrow<&GlobalContractsBook>()!
	}
	
	init(){ 
		self.ContractsBookStoragePath = /storage/TouchstoneContractsBook
		self.ContractsBookPublicPath = /public/TouchstoneContractsBook
		self.GlobalContractsBookStoragePath = /storage/TouchstoneGlobalContractsBook
		self.GlobalContractsBookPublicPath = /public/TouchstoneGlobalContractsBook
		self.account.storage.save(
			<-create GlobalContractsBook(),
			to: TouchstoneContracts.GlobalContractsBookStoragePath
		)
		var capability_1 =
			self.account.capabilities.storage.issue<&GlobalContractsBook>(
				TouchstoneContracts.GlobalContractsBookStoragePath
			)
		self.account.capabilities.publish(
			capability_1,
			at: TouchstoneContracts.GlobalContractsBookPublicPath
		)
	}
}
