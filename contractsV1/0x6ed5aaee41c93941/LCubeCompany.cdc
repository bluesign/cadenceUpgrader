access(all)
contract LCubeCompany{ 
	access(all)
	let CompanyPublicPath: PublicPath
	
	access(all)
	let CompanyStoragePath: StoragePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var totalCount: UInt64
	
	access(contract)
	var idSeq: UInt64
	
	access(all)
	event CompanyCreated(
		address: Address,
		name: String,
		stakeRate: UFix64,
		subAddresses: [
			String
		],
		subShares: [
			UFix64
		]
	)
	
	access(all)
	event CompanyDestroyed(address: Address, name: String)
	
	access(all)
	struct SubAccount{ 
		access(contract)
		var addr: String
		
		access(contract)
		var share: UFix64
		
		access(contract)
		var mail: String
		
		init(addr: String, share: UFix64, mail: String){ 
			self.addr = addr
			self.share = share
			self.mail = mail
		}
		
		access(all)
		fun getAddr(): String{ 
			return self.addr
		}
		
		access(all)
		fun getShare(): UFix64{ 
			return self.share
		}
		
		access(all)
		fun getMail(): String{ 
			return self.mail
		}
	}
	
	access(all)
	struct CompanyDetail{ 
		access(all)
		var companyName: String
		
		access(all)
		var desc: String
		
		access(all)
		var mail: String
		
		access(all)
		var stakeRate: UFix64
		
		init(companyName: String, desc: String, mail: String, stakeRate: UFix64){ 
			self.companyName = companyName
			self.desc = desc
			self.mail = mail
			self.stakeRate = stakeRate
		}
	}
	
	access(all)
	resource interface ICompany{ 
		access(all)
		fun getCompanyName(): String
		
		access(all)
		fun getDesc(): String
		
		access(all)
		fun getMail(): String
		
		access(all)
		fun getStakeRate(): UFix64
		
		access(all)
		fun getDetails(): AnyStruct
	}
	
	access(all)
	resource Company: ICompany{ 
		access(contract)
		var id: UInt64
		
		access(contract)
		var companyName: String
		
		access(contract)
		var desc: String
		
		access(contract)
		var mail: String
		
		access(contract)
		var stakeRate: UFix64
		
		access(contract)
		var subAccounts: [AnyStruct]
		
		access(all)
		fun getId(): UInt64{ 
			return self.id
		}
		
		access(all)
		fun getCompanyName(): String{ 
			return self.companyName
		}
		
		access(all)
		fun getDesc(): String{ 
			return self.desc
		}
		
		access(all)
		fun getMail(): String{ 
			return self.mail
		}
		
		access(all)
		fun getStakeRate(): UFix64{ 
			return self.stakeRate
		}
		
		access(all)
		fun getSubAccounts(): [AnyStruct]{ 
			return self.subAccounts
		}
		
		access(all)
		fun getDetails(): AnyStruct{ 
			return CompanyDetail(companyName: self.companyName, desc: self.desc, mail: self.mail, stakeRate: self.stakeRate)
		}
		
		init(companyName: String, desc: String, mail: String, stakeRate: UFix64, subAddresses: [String], subShares: [UFix64], subMails: [String]){ 
			self.id = LCubeCompany.idSeq
			self.companyName = companyName
			self.desc = desc
			self.mail = mail
			self.stakeRate = stakeRate
			var subAccounts: [SubAccount] = []
			var i: UInt32 = 0
			for subAddress in subAddresses{ 
				subAccounts.append(SubAccount(addr: subAddress, share: subShares[i], mail: subMails[i]))
				i = i + 1
			}
			self.subAccounts = subAccounts
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun createCompany(
			companyName: String,
			desc: String,
			mail: String,
			stakeRate: UFix64,
			subAddresses: [
				String
			],
			subShares: [
				UFix64
			],
			subMails: [
				String
			],
			address: Address
		): @Company{ 
			LCubeCompany.totalCount = LCubeCompany.totalCount + 1
			LCubeCompany.idSeq = LCubeCompany.idSeq + 1
			let a <-
				create Company(
					companyName: companyName,
					desc: desc,
					mail: mail,
					stakeRate: stakeRate,
					subAddresses: subAddresses,
					subShares: subShares,
					subMails: subMails
				)
			emit CompanyCreated(
				address: address,
				name: companyName,
				stakeRate: stakeRate,
				subAddresses: subAddresses,
				subShares: subShares
			)
			return <-a
		}
		
		access(all)
		fun destroyCompany(company: @Company, address: Address){ 
			emit CompanyDestroyed(address: address, name: company.getCompanyName())
			destroy company
		}
	}
	
	init(adminAccount: AuthAccount){ 
		self.totalCount = 0
		self.idSeq = 0
		self.CompanyPublicPath = /public/LCubeCompanyPublic
		self.CompanyStoragePath = /storage/LCubeCompanyStorage
		self.AdminStoragePath = /storage/LCubeAdminStorage
		let admin <- create Admin()
		adminAccount.save(<-admin, to: self.AdminStoragePath)
	}
}
