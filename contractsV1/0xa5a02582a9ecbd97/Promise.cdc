access(all)
contract Promise{ 
	access(self)
	var templates:{ UInt32: Template}
	
	access(self)
	var lastTemplateId: UInt32
	
	access(self)
	let reward: UInt64
	
	access(all)
	let collectionStoragePath: StoragePath
	
	access(all)
	let collectionPublicPath: PublicPath
	
	access(all)
	let vaultStoragePath: StoragePath
	
	access(all)
	let vaultPublicPath: PublicPath
	
	access(all)
	let profileStoragePath: StoragePath
	
	access(all)
	let profilePublicPath: PublicPath
	
	init(){ 
		self.templates ={} 
		self.lastTemplateId = 0
		self.reward = 3
		self.collectionStoragePath = /storage/PromiseCollection
		self.collectionPublicPath = /public/PromiseCollection
		self.vaultStoragePath = /storage/PromiseVault
		self.vaultPublicPath = /public/PromiseVault
		self.profileStoragePath = /storage/PromiseProfile
		self.profilePublicPath = /public/PromiseProfile
	}
	
	access(all)
	struct Template{ 
		access(all)
		let author: Address
		
		access(all)
		let authorName: String
		
		access(all)
		let content: String
		
		access(all)
		let templateId: UInt32
		
		access(all)
		var edition: UInt32
		
		init(
			author: Address,
			authorName: String,
			content: String,
			edition: UInt32,
			templateId: UInt32
		){ 
			self.edition = edition
			self.author = author
			self.content = content
			self.templateId = templateId
			self.authorName = authorName
		}
		
		access(all)
		fun incrementEdition(){ 
			self.edition = self.edition + 1
		}
	}
	
	access(all)
	struct NftInfo{ 
		access(all)
		let data: Template
		
		access(all)
		let createdAt: UFix64
		
		init(data: Template, createdAt: UFix64){ 
			self.data = data
			self.createdAt = createdAt
		}
	}
	
	access(all)
	resource NFT{ 
		access(all)
		let data: Template
		
		access(all)
		let edition: UInt32
		
		access(all)
		let createdAt: UFix64
		
		init(templateId: UInt32, author: Address, content: String){ 
			if Promise.templates[templateId] == nil{ 
				panic("Template ID does not exist")
			}
			(Promise.templates[templateId]!).incrementEdition()
			let template = Promise.templates[templateId]!
			self.data = Template(
					author: template.author,
					authorName: template.authorName,
					content: template.content,
					edition: template.edition,
					templateId: template.templateId
				)
			self.edition = (Promise.templates[templateId]!).edition
			self.createdAt = getCurrentBlock().timestamp
		}
	}
	
	access(all)
	resource interface PublicCollection{ 
		access(all)
		fun list(): [NftInfo]
	}
	
	access(all)
	resource Collection: PublicCollection{ 
		access(all)
		var nfts: @{UInt32: NFT}
		
		init(){ 
			self.nfts <-{} 
		}
		
		access(all)
		fun deposit(nft: @NFT){ 
			if self.nfts[nft.data.templateId] != nil{ 
				panic("You have already holded accountable for this promise")
			}
			self.nfts[nft.data.templateId] <-! nft
		}
		
		access(all)
		fun list(): [NftInfo]{ 
			var results: [NftInfo] = []
			for key in self.nfts.keys{ 
				let nft = &self.nfts[key] as &Promise.NFT?
				let nftInfo = NftInfo(data: nft.data, createdAt: nft.createdAt)
				results.append(nftInfo)
			}
			return results
		}
	}
	
	access(all)
	resource interface PublicVault{ 
		access(all)
		fun deposit(temporaryVault: @Vault)
		
		access(all)
		var balance: UInt64
	}
	
	access(all)
	resource Vault: PublicVault{ 
		access(all)
		var balance: UInt64
		
		init(balance: UInt64){ 
			self.balance = balance
		}
		
		access(all)
		fun withdraw(amount: UInt64): @Vault{ 
			if self.balance < amount{ 
				let temporaryVault <- create Vault(balance: 0)
				return <-temporaryVault
			}
			self.balance = self.balance - amount
			let temporaryVault <- create Vault(balance: amount)
			return <-temporaryVault
		}
		
		access(all)
		fun deposit(temporaryVault: @Vault){ 
			self.balance = self.balance + temporaryVault.balance
			destroy temporaryVault
		}
	}
	
	access(all)
	resource interface PublicProfile{ 
		access(all)
		let name: String
	}
	
	access(all)
	resource Profile: PublicProfile{ 
		access(all)
		let name: String
		
		access(all)
		let termsAcceptedAt: UInt64
		
		init(name: String, termsAcceptedAt: UInt64){ 
			self.name = name
			self.termsAcceptedAt = termsAcceptedAt
		}
	}
	
	access(all)
	fun createProfile(name: String, termsAcceptedAt: UInt64): @Profile{ 
		let profile <- create Profile(name: name, termsAcceptedAt: termsAcceptedAt)
		return <-profile
	}
	
	access(all)
	fun createVault(): @Vault{ 
		let vault <- create Vault(balance: 0)
		return <-vault
	}
	
	access(all)
	fun createCollection(): @Collection{ 
		let collection <- create Collection()
		return <-collection
	}
	
	access(all)
	fun createTemplate(author: Address, content: String): @NFT{ 
		let account = getAccount(author)
		let vault =
			account.capabilities.get<&{PublicVault}>(self.vaultPublicPath).borrow()
			?? panic("Could not borrow Vault")
		let userProfile =
			account.capabilities.get<&{Promise.PublicProfile}>(Promise.profilePublicPath).borrow()
			?? panic("Could not borrow user profile")
		let reward <- create Vault(balance: self.reward)
		vault.deposit(temporaryVault: <-reward)
		self.lastTemplateId = self.lastTemplateId + 1
		let template =
			Template(
				author: author,
				authorName: userProfile.name,
				content: content,
				edition: 0,
				templateId: self.lastTemplateId
			)
		self.templates[self.lastTemplateId] = template
		let nft <- create NFT(templateId: self.lastTemplateId, author: author, content: content)
		return <-nft
	}
	
	access(all)
	fun createNextEdition(author: Address, templateId: UInt32, payment: @Vault): @NFT?{ 
		if payment.balance < 1{ 
			panic("Not enough balance")
		}
		let template = self.templates[templateId]!
		if template.author == author{ 
			panic("Cannot hold accountable for own promises")
		}
		let nft <-!
			create NFT(templateId: templateId, author: template.author, content: template.content)
		destroy payment
		return <-nft
	}
}
