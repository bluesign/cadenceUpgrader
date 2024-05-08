import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract CarbonHive: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event FundingRoundCreated(id: UInt32, projectID: UInt32, name: String)
	
	access(all)
	event ReportCreated(id: UInt32, projectID: UInt32)
	
	access(all)
	event ProjectCreated(id: UInt32, name: String)
	
	access(all)
	event FundingRoundAddedToProject(projectID: UInt32, fundingRoundID: UInt32)
	
	access(all)
	event ReportAddedToProject(projectID: UInt32, reportID: UInt32)
	
	access(all)
	event ReportAddedToFundingRound(projectID: UInt32, fundingRoundID: UInt32, reportID: UInt32)
	
	access(all)
	event CompletedFundingRound(projectID: UInt32, fundingRoundID: UInt32, numImpacts: UInt32)
	
	access(all)
	event ProjectClosed(projectID: UInt32)
	
	access(all)
	event ImpactMinted(impactID: UInt64, projectID: UInt32, fundingRoundID: UInt32, serialNumber: UInt32, amount: UInt32, location: String, locationDescriptor: String, vintagePeriod: String)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event ImpactDestroyed(id: UInt64)
	
	access(self)
	var projectDatas:{ UInt32: ProjectData}
	
	access(self)
	var fundingRoundDatas:{ UInt32: FundingRoundData}
	
	access(self)
	var reportDatas:{ UInt32: ReportData}
	
	access(self)
	var projects: @{UInt32: Project}
	
	access(all)
	let ImpactCollectionStoragePath: StoragePath
	
	access(all)
	let ImpactCollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var nextFundingRoundID: UInt32
	
	access(all)
	var nextProjectID: UInt32
	
	access(all)
	var nextReportID: UInt32
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	struct FundingRoundData{ 
		access(all)
		let fundingRoundID: UInt32
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let formula: String
		
		access(all)
		let formulaType: String
		
		access(all)
		let unit: String
		
		access(all)
		let vintagePeriod: String
		
		access(all)
		let totalAmount: UInt32
		
		access(all)
		let roundEnds: Fix64
		
		access(all)
		let location: String
		
		access(all)
		let locationDescriptor: String
		
		access(all)
		let projectID: UInt32
		
		access(self)
		let reports: [UInt32]
		
		access(self)
		let metadata:{ String: String}
		
		init(name: String, description: String, formula: String, formulaType: String, unit: String, vintagePeriod: String, totalAmount: UInt32, roundEnds: Fix64, location: String, locationDescriptor: String, projectID: UInt32, metadata:{ String: String}){ 
			pre{ 
				name != "":
					"New fundingRound name cannot be empty"
			}
			self.fundingRoundID = CarbonHive.nextFundingRoundID
			self.name = name
			self.description = description
			self.formula = formula
			self.formulaType = formulaType
			self.unit = unit
			self.vintagePeriod = vintagePeriod
			self.totalAmount = totalAmount
			self.roundEnds = roundEnds
			self.location = location
			self.locationDescriptor = locationDescriptor
			self.projectID = projectID
			self.reports = []
			self.metadata = metadata
			CarbonHive.nextFundingRoundID = CarbonHive.nextFundingRoundID + 1 as UInt32
			emit FundingRoundCreated(id: self.fundingRoundID, projectID: projectID, name: name)
		}
		
		access(all)
		fun addReport(reportID: UInt32){ 
			self.reports.append(reportID)
		}
	}
	
	access(all)
	struct ProjectData{ 
		access(all)
		let projectID: UInt32
		
		access(all)
		var closed: Bool
		
		access(all)
		let url: String
		
		access(all)
		let name: String
		
		access(all)
		let developer: String
		
		access(all)
		let description: String
		
		access(all)
		let location: String
		
		access(all)
		let locationDescriptor: String
		
		access(all)
		let type: String
		
		access(self)
		let metadata:{ String: String}
		
		access(all)
		fun close(){ 
			self.closed = true
		}
		
		init(closed: Bool, url: String, metadata:{ String: String}, name: String, developer: String, description: String, location: String, locationDescriptor: String, type: String){ 
			pre{ 
				name != "":
					"New project name cannot be empty"
			}
			self.projectID = CarbonHive.nextProjectID
			self.closed = closed
			self.url = url
			self.metadata = metadata
			self.name = name
			self.developer = developer
			self.description = description
			self.location = location
			self.locationDescriptor = locationDescriptor
			self.type = type
			CarbonHive.nextProjectID = CarbonHive.nextProjectID + 1 as UInt32
			emit ProjectCreated(id: self.projectID, name: name)
		}
	}
	
	access(all)
	struct ReportData{ 
		access(all)
		let reportID: UInt32
		
		access(all)
		let date: String
		
		access(all)
		let projectID: UInt32
		
		access(all)
		let fundingRoundID: UInt32
		
		access(all)
		let description: String
		
		access(all)
		let reportContent: String
		
		access(all)
		let reportContentType: String
		
		access(self)
		let metadata:{ String: String}
		
		init(date: String, projectID: UInt32, fundingRoundID: UInt32, description: String, reportContent: String, reportContentType: String, metadata:{ String: String}){ 
			self.reportID = CarbonHive.nextReportID
			self.date = date
			self.projectID = projectID
			self.fundingRoundID = fundingRoundID
			self.description = description
			self.reportContent = reportContent
			self.reportContentType = reportContentType
			self.metadata = metadata
			CarbonHive.nextReportID = CarbonHive.nextReportID + 1 as UInt32
			emit ReportCreated(id: self.reportID, projectID: projectID)
		}
	}
	
	// Admin can call the Project resoure's methods to add FundingRound,
	// add Report and Mint Impact.
	//
	// Project can have zero to many FundingRounds and Reports.
	//
	// Impact NFT belogs to the project that minted it, and references the actual FundingRound
	// the Impact was minted for.
	access(all)
	resource Project{ 
		access(all)
		let projectID: UInt32
		
		access(self)
		var fundingRounds: [UInt32]
		
		access(self)
		var fundingRoundCompleted:{ UInt32: Bool}
		
		access(all)
		var closed: Bool
		
		access(all)
		let url: String
		
		access(self)
		var metadata:{ String: String}
		
		access(all)
		let name: String
		
		access(all)
		let developer: String
		
		access(all)
		let description: String
		
		access(all)
		let location: String
		
		access(all)
		let locationDescriptor: String
		
		access(all)
		let type: String
		
		access(self)
		var reports: [UInt32]
		
		access(self)
		var impactMintedPerFundingRound:{ UInt32: UInt32}
		
		access(self)
		var impactAmountPerFundingRound:{ UInt32: UInt32}
		
		access(all)
		fun getFundingRounds(): [UInt32]{ 
			return self.fundingRounds
		}
		
		access(all)
		fun getFundingRoundCompleted(fundingRoundID: UInt32): Bool?{ 
			return self.fundingRoundCompleted[fundingRoundID]
		}
		
		access(all)
		fun getReports(): [UInt32]{ 
			return self.reports
		}
		
		access(all)
		fun getImpactMintedPerFundingRound(fundingRoundID: UInt32): UInt32?{ 
			return self.impactMintedPerFundingRound[fundingRoundID]
		}
		
		access(all)
		fun getImpactAmountPerFundingRound(fundingRoundID: UInt32): UInt32?{ 
			return self.impactAmountPerFundingRound[fundingRoundID]
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		init(name: String, description: String, url: String, developer: String, type: String, location: String, locationDescriptor: String, metadata:{ String: String}){ 
			self.projectID = CarbonHive.nextProjectID
			self.fundingRounds = []
			self.reports = []
			self.fundingRoundCompleted ={} 
			self.closed = false
			self.url = url
			self.impactMintedPerFundingRound ={} 
			self.impactAmountPerFundingRound ={} 
			self.metadata = metadata
			self.type = type
			self.name = name
			self.description = description
			self.developer = developer
			self.location = location
			self.locationDescriptor = locationDescriptor
			CarbonHive.projectDatas[self.projectID] = ProjectData(closed: self.closed, url: url, metadata: metadata, name: name, developer: developer, description: description, location: location, locationDescriptor: locationDescriptor, type: type)
		}
		
		access(all)
		fun addReport(reportID: UInt32){ 
			pre{ 
				CarbonHive.reportDatas[reportID] != nil:
					"Cannot add the Report to Project: Report doesn't exist."
			}
			self.reports.append(reportID)
			emit ReportAddedToProject(projectID: self.projectID, reportID: reportID)
		}
		
		// Add report to both Funding Round and owning Project
		access(all)
		fun addReportToFundingRound(reportID: UInt32, fundingRoundID: UInt32){ 
			pre{ 
				CarbonHive.reportDatas[reportID] != nil:
					"Cannot add the Report to Funding Round: Report doesn't exist."
				CarbonHive.fundingRoundDatas[fundingRoundID] != nil:
					"Cannot add the Report to Funding Round: Funding Round doesn't exist."
			}
			let fundingRound = CarbonHive.fundingRoundDatas[fundingRoundID]!
			self.reports.append(reportID)
			fundingRound.addReport(reportID: reportID)
			CarbonHive.fundingRoundDatas[fundingRoundID] = fundingRound
			emit ReportAddedToFundingRound(projectID: self.projectID, fundingRoundID: fundingRoundID, reportID: reportID)
		}
		
		access(all)
		fun addFundingRound(fundingRoundID: UInt32){ 
			pre{ 
				CarbonHive.fundingRoundDatas[fundingRoundID] != nil:
					"Cannot add the FundingRound to Project: FundingRound doesn't exist."
				!self.closed:
					"Cannot add the FundingRound to the Project after the Project has been closed."
				self.impactMintedPerFundingRound[fundingRoundID] == nil:
					"The FundingRound has already beed added to the Project."
			}
			self.fundingRounds.append(fundingRoundID)
			self.fundingRoundCompleted[fundingRoundID] = false
			self.impactMintedPerFundingRound[fundingRoundID] = 0
			self.impactAmountPerFundingRound[fundingRoundID] = 0
			emit FundingRoundAddedToProject(projectID: self.projectID, fundingRoundID: fundingRoundID)
		}
		
		access(all)
		fun completeFundingRound(fundingRoundID: UInt32){ 
			pre{ 
				self.fundingRoundCompleted[fundingRoundID] != nil:
					"Cannot complete the FundingRound: FundingRound doesn't exist in this Project!"
			}
			if !self.fundingRoundCompleted[fundingRoundID]!{ 
				self.fundingRoundCompleted[fundingRoundID] = true
				emit CompletedFundingRound(projectID: self.projectID, fundingRoundID: fundingRoundID, numImpacts: self.impactMintedPerFundingRound[fundingRoundID]!)
			}
		}
		
		access(all)
		fun completeAllFundingRound(){ 
			for fundingRound in self.fundingRounds{ 
				self.completeFundingRound(fundingRoundID: fundingRound)
			}
		}
		
		access(all)
		fun close(){ 
			if !self.closed{ 
				self.closed = true
				let projectData = CarbonHive.projectDatas[self.projectID] ?? panic("Could not finf project data")
				projectData.close()
				CarbonHive.projectDatas[self.projectID] = projectData
				emit ProjectClosed(projectID: self.projectID)
			}
		}
		
		access(all)
		fun mintImpact(fundingRoundID: UInt32, amount: UInt32, location: String, locationDescriptor: String, vintagePeriod: String, content: @{CarbonHive.Content}): @NFT{ 
			pre{ 
				CarbonHive.fundingRoundDatas[fundingRoundID] != nil:
					"Cannot mint the Impact: This FundingRound doesn't exist."
				!self.fundingRoundCompleted[fundingRoundID]!:
					"Cannot mint the Impact from this FundingRound: This FundingRound has been completed."
			}
			let block = getCurrentBlock()
			let time = Fix64(block.timestamp)
			let fundingRound = CarbonHive.fundingRoundDatas[fundingRoundID]!
			if fundingRound.roundEnds < time{ 
				panic("The funding round ended on ".concat(fundingRound.roundEnds.toString()).concat(" now: ").concat(block.timestamp.toString()))
			}
			let amountInFundingRound = self.impactAmountPerFundingRound[fundingRoundID]!
			let remainingAmount = fundingRound.totalAmount - amountInFundingRound
			if amount >= remainingAmount{ 
				panic("Not enough amount left for minting impact: ".concat(amountInFundingRound.toString()).concat(" amount minted, ").concat(remainingAmount.toString()).concat(" amount remaining."))
			}
			let impactsInFundingRound = self.impactMintedPerFundingRound[fundingRoundID]!
			let newImpact: @NFT <- create NFT(projectID: self.projectID, fundingRoundID: fundingRoundID, serialNumber: impactsInFundingRound + 1 as UInt32, amount: amount, location: location, locationDescriptor: locationDescriptor, vintagePeriod: vintagePeriod, content: <-content)
			self.impactMintedPerFundingRound[fundingRoundID] = impactsInFundingRound + 1 as UInt32
			self.impactAmountPerFundingRound[fundingRoundID] = amountInFundingRound + amount
			return <-newImpact
		}
	}
	
	access(all)
	struct ImpactData{ 
		access(all)
		let projectID: UInt32
		
		access(all)
		let fundingRoundID: UInt32
		
		access(all)
		let serialNumber: UInt32
		
		access(all)
		let amount: UInt32
		
		access(all)
		let location: String
		
		access(all)
		let locationDescriptor: String
		
		access(all)
		let vintagePeriod: String
		
		init(projectID: UInt32, fundingRoundID: UInt32, serialNumber: UInt32, amount: UInt32, location: String, locationDescriptor: String, vintagePeriod: String){ 
			self.projectID = projectID
			self.fundingRoundID = fundingRoundID
			self.serialNumber = serialNumber
			self.amount = amount
			self.location = location
			self.locationDescriptor = locationDescriptor
			self.vintagePeriod = vintagePeriod
		}
	}
	
	access(all)
	resource interface Content{ 
		access(all)
		fun getData(): String
		
		access(all)
		fun getContentType(): String
	}
	
	access(all)
	resource ImpactContent: Content{ 
		access(contract)
		let data: String
		
		access(contract)
		let type: String
		
		init(data: String, type: String){ 
			self.data = data
			self.type = type
		}
		
		access(all)
		fun getData(): String{ 
			return self.data
		}
		
		access(all)
		fun getContentType(): String{ 
			return self.type
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let data: ImpactData
		
		access(self)
		let content: @{CarbonHive.Content}
		
		access(all)
		fun getContentData(): String{ 
			return self.content.getData()
		}
		
		access(all)
		fun getContentType(): String{ 
			return self.content.getContentType()
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(projectID: UInt32, fundingRoundID: UInt32, serialNumber: UInt32, amount: UInt32, location: String, locationDescriptor: String, vintagePeriod: String, content: @{CarbonHive.Content}){ 
			CarbonHive.totalSupply = CarbonHive.totalSupply + 1 as UInt64
			self.id = CarbonHive.totalSupply
			self.data = ImpactData(projectID: projectID, fundingRoundID: fundingRoundID, serialNumber: serialNumber, amount: amount, location: location, locationDescriptor: locationDescriptor, vintagePeriod: vintagePeriod)
			self.content <- content
			emit ImpactMinted(impactID: self.id, projectID: self.data.projectID, fundingRoundID: self.data.fundingRoundID, serialNumber: self.data.serialNumber, amount: self.data.amount, location: self.data.location, locationDescriptor: self.data.locationDescriptor, vintagePeriod: self.data.vintagePeriod)
		}
	}
	
	access(all)
	resource interface ProjectAdmin{ 
		access(all)
		fun createFundingRound(name: String, description: String, formula: String, formulaType: String, unit: String, vintagePeriod: String, totalAmount: UInt32, roundEnds: Fix64, location: String, locationDescriptor: String, projectID: UInt32, metadata:{ String: String}): UInt32
		
		access(all)
		fun createReport(date: String, projectID: UInt32, fundingRoundID: UInt32, description: String, reportContent: String, reportContentType: String, metadata:{ String: String}): UInt32
		
		access(all)
		fun createProject(name: String, description: String, url: String, developer: String, type: String, location: String, locationDescriptor: String, metadata:{ String: String})
		
		access(all)
		fun borrowProject(projectID: UInt32): &Project?
	}
	
	access(all)
	resource interface ContentAdmin{ 
		access(all)
		fun createContent(data: String, contentType: String): @{CarbonHive.Content}
	}
	
	access(all)
	resource Admin: ProjectAdmin, ContentAdmin{ 
		access(all)
		fun createFundingRound(name: String, description: String, formula: String, formulaType: String, unit: String, vintagePeriod: String, totalAmount: UInt32, roundEnds: Fix64, location: String, locationDescriptor: String, projectID: UInt32, metadata:{ String: String}): UInt32{ 
			var newFundingRound = FundingRoundData(name: name, description: description, formula: formula, formulaType: formulaType, unit: unit, vintagePeriod: vintagePeriod, totalAmount: totalAmount, roundEnds: roundEnds, location: location, locationDescriptor: locationDescriptor, projectID: projectID, metadata: metadata)
			let newID = newFundingRound.fundingRoundID
			CarbonHive.fundingRoundDatas[newID] = newFundingRound
			return newID
		}
		
		access(all)
		fun createReport(date: String, projectID: UInt32, fundingRoundID: UInt32, description: String, reportContent: String, reportContentType: String, metadata:{ String: String}): UInt32{ 
			var newReport = ReportData(date: date, projectID: projectID, fundingRoundID: fundingRoundID, description: description, reportContent: reportContent, reportContentType: reportContentType, metadata: metadata)
			let newID = newReport.reportID
			CarbonHive.reportDatas[newID] = newReport
			return newID
		}
		
		access(all)
		fun createProject(name: String, description: String, url: String, developer: String, type: String, location: String, locationDescriptor: String, metadata:{ String: String}){ 
			var newProject <- create Project(name: name, description: description, url: url, developer: developer, type: type, location: location, locationDescriptor: locationDescriptor, metadata: metadata)
			CarbonHive.projects[newProject.projectID] <-! newProject
		}
		
		access(all)
		fun createContent(data: String, contentType: String): @{CarbonHive.Content}{ 
			return <-create ImpactContent(data: data, type: contentType)
		}
		
		access(all)
		fun borrowProject(projectID: UInt32): &Project?{ 
			return &CarbonHive.projects[projectID] as &Project?
		}
		
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(all)
	resource interface ImpactCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowImpact(id: UInt64): &CarbonHive.NFT?
	}
	
	access(all)
	resource Collection: ImpactCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Impact does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <- create Collection()
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @CarbonHive.NFT
			let id = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			destroy oldToken
		}
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			let keys = tokens.getIDs()
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			destroy tokens
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowImpact(id: UInt64): &CarbonHive.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &CarbonHive.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create CarbonHive.Collection()
	}
	
	access(all)
	fun getProjectData(projectID: UInt32): ProjectData?{ 
		return self.projectDatas[projectID]
	}
	
	access(all)
	fun getReportData(reportID: UInt32): ReportData?{ 
		return self.reportDatas[reportID]
	}
	
	access(all)
	fun getFundingRoundData(fundingRoundID: UInt32): FundingRoundData?{ 
		return self.fundingRoundDatas[fundingRoundID]
	}
	
	access(all)
	fun getFundingRoundsInProject(projectID: UInt32): [UInt32]?{ 
		return CarbonHive.projects[projectID]?.getFundingRounds()
	}
	
	access(all)
	fun getReportsInProject(projectID: UInt32): [UInt32]?{ 
		return CarbonHive.projects[projectID]?.getReports()
	}
	
	access(all)
	fun getAmountUsedInFundingRound(projectID: UInt32, fundingRoundID: UInt32): UInt32?{ 
		if let projectToRead <- CarbonHive.projects.remove(key: projectID){ 
			let amount = projectToRead.getImpactAmountPerFundingRound(fundingRoundID: fundingRoundID)
			CarbonHive.projects[projectID] <-! projectToRead
			return amount
		} else{ 
			// If the project wasn't found return nil
			return nil
		}
	}
	
	init(){ 
		self.ImpactCollectionPublicPath = /public/ImpactCollection
		self.ImpactCollectionStoragePath = /storage/ImpactCollection
		self.AdminStoragePath = /storage/CarbonHiveAdmin
		self.projectDatas ={} 
		self.fundingRoundDatas ={} 
		self.reportDatas ={} 
		self.projects <-{} 
		self.totalSupply = 0
		self.nextFundingRoundID = 1
		self.nextProjectID = 1
		self.nextReportID = 1
		self.account.storage.save<@Collection>(<-create Collection(), to: self.ImpactCollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{ImpactCollectionPublic}>(self.ImpactCollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.ImpactCollectionPublicPath)
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
