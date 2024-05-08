import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract NFTContract: NonFungibleToken{ 
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event NFTBorrowed(id: UInt64)
	
	access(all)
	event NFTDestroyed(id: UInt64)
	
	access(all)
	event NFTMinted(nftId: UInt64, templateId: UInt64, mintNumber: UInt64)
	
	access(all)
	event BrandCreated(brandId: UInt64, brandName: String, author: Address, data:{ String: String})
	
	access(all)
	event BrandUpdated(brandId: UInt64, brandName: String, author: Address, data:{ String: String})
	
	access(all)
	event SchemaCreated(schemaId: UInt64, schemaName: String, author: Address)
	
	access(all)
	event TemplateCreated(templateId: UInt64, brandId: UInt64, schemaId: UInt64, maxSupply: UInt64)
	
	// Paths
	access(all)
	let AdminResourceStoragePath: StoragePath
	
	access(all)
	let NFTMethodsCapabilityPrivatePath: PrivatePath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStorageCapability: StoragePath
	
	access(all)
	let AdminCapabilityPrivate: PrivatePath
	
	// Latest brand-id
	access(all)
	var lastIssuedBrandId: UInt64
	
	// Latest schema-id
	access(all)
	var lastIssuedSchemaId: UInt64
	
	// Latest brand-id
	access(all)
	var lastIssuedTemplateId: UInt64
	
	// Total supply of all NFTs that are minted using this contract
	access(all)
	var totalSupply: UInt64
	
	// A dictionary that stores all Brands against it's brand-id.
	access(self)
	var allBrands:{ UInt64: Brand}
	
	access(self)
	var allSchemas:{ UInt64: Schema}
	
	access(self)
	var allTemplates:{ UInt64: Template}
	
	access(self)
	var allNFTs:{ UInt64: NFTData}
	
	// Accounts ability to add capability
	access(self)
	var whiteListedAccounts: [Address]
	
	// Create Schema Support all the mentioned Types
	access(all)
	enum SchemaType: UInt8{ 
		access(all)
		case String
		
		access(all)
		case Int
		
		access(all)
		case Fix64
		
		access(all)
		case Bool
		
		access(all)
		case Address
		
		access(all)
		case Array
		
		access(all)
		case Any
	}
	
	// A structure that contain all the data related to a Brand
	access(all)
	struct Brand{ 
		access(all)
		let brandId: UInt64
		
		access(all)
		let brandName: String
		
		access(all)
		let author: Address
		
		access(contract)
		var data:{ String: String}
		
		init(brandName: String, author: Address, data:{ String: String}){ 
			pre{ 
				brandName.length > 0:
					"Brand name is required"
			}
			let newBrandId = NFTContract.lastIssuedBrandId
			self.brandId = newBrandId
			self.brandName = brandName
			self.author = author
			self.data = data
		}
		
		access(all)
		fun update(data:{ String: String}){ 
			self.data = data
		}
	}
	
	// A structure that contain all the data related to a Schema
	access(all)
	struct Schema{ 
		access(all)
		let schemaId: UInt64
		
		access(all)
		let schemaName: String
		
		access(all)
		let author: Address
		
		access(contract)
		let format:{ String: SchemaType}
		
		init(schemaName: String, author: Address, format:{ String: SchemaType}){ 
			pre{ 
				schemaName.length > 0:
					"Could not create schema: name is required"
			}
			let newSchemaId = NFTContract.lastIssuedSchemaId
			self.schemaId = newSchemaId
			self.schemaName = schemaName
			self.author = author
			self.format = format
		}
	}
	
	// A structure that contain all the data and methods related to Template
	access(all)
	struct Template{ 
		access(all)
		let templateId: UInt64
		
		access(all)
		let brandId: UInt64
		
		access(all)
		let schemaId: UInt64
		
		access(all)
		var maxSupply: UInt64
		
		access(all)
		var issuedSupply: UInt64
		
		access(all)
		var immutableData:{ String: AnyStruct}
		
		init(brandId: UInt64, schemaId: UInt64, maxSupply: UInt64, immutableData:{ String: AnyStruct}){ 
			pre{ 
				NFTContract.allBrands[brandId] != nil:
					"Brand Id must be valid"
				NFTContract.allSchemas[schemaId] != nil:
					"Schema Id must be valid"
				maxSupply > 0:
					"MaxSupply must be greater than zero"
				immutableData != nil:
					"ImmutableData must not be nil"
			}
			self.templateId = NFTContract.lastIssuedTemplateId
			self.brandId = brandId
			self.schemaId = schemaId
			self.maxSupply = maxSupply
			self.immutableData = immutableData
			self.issuedSupply = 0
			// Before creating template, we need to check template data, if it is valid against given schema or not
			let schema = NFTContract.allSchemas[schemaId]!
			var invalidKey: String = ""
			var isValidTemplate = true
			for key in immutableData.keys{ 
				let value = immutableData[key]!
				if schema.format[key] == nil{ 
					isValidTemplate = false
					invalidKey = "key $".concat(key.concat(" not found"))
					break
				}
				if schema.format[key] == NFTContract.SchemaType.String{ 
					if value as? String == nil{ 
						isValidTemplate = false
						invalidKey = "key $".concat(key.concat(" has type mismatch"))
						break
					}
				} else if schema.format[key] == NFTContract.SchemaType.Int{ 
					if value as? Int == nil{ 
						isValidTemplate = false
						invalidKey = "key $".concat(key.concat(" has type mismatch"))
						break
					}
				} else if schema.format[key] == NFTContract.SchemaType.Fix64{ 
					if value as? Fix64 == nil{ 
						isValidTemplate = false
						invalidKey = "key $".concat(key.concat(" has type mismatch"))
						break
					}
				} else if schema.format[key] == NFTContract.SchemaType.Bool{ 
					if value as? Bool == nil{ 
						isValidTemplate = false
						invalidKey = "key $".concat(key.concat(" has type mismatch"))
						break
					}
				} else if schema.format[key] == NFTContract.SchemaType.Address{ 
					if value as? Address == nil{ 
						isValidTemplate = false
						invalidKey = "key $".concat(key.concat(" has type mismatch"))
						break
					}
				} else if schema.format[key] == NFTContract.SchemaType.Array{ 
					if value as? [AnyStruct] == nil{ 
						isValidTemplate = false
						invalidKey = "key $".concat(key.concat(" has type mismatch"))
						break
					}
				} else if schema.format[key] == NFTContract.SchemaType.Any{ 
					if value as?{ String: AnyStruct} == nil{ 
						isValidTemplate = false
						invalidKey = "key $".concat(key.concat(" has type mismatch"))
						break
					}
				}
			}
			assert(isValidTemplate, message: "invalid template data. Error: ".concat(invalidKey))
		}
		
		// a method to increment issued supply for template
		access(contract)
		fun incrementIssuedSupply(): UInt64{ 
			pre{ 
				self.issuedSupply < self.maxSupply:
					"Template reached max supply"
			}
			self.issuedSupply = self.issuedSupply + 1
			return self.issuedSupply
		}
	}
	
	// A structure that link template and mint-no of NFT
	access(all)
	struct NFTData{ 
		access(all)
		let templateID: UInt64
		
		access(all)
		let mintNumber: UInt64
		
		init(templateID: UInt64, mintNumber: UInt64){ 
			self.templateID = templateID
			self.mintNumber = mintNumber
		}
	}
	
	// The resource that represents the Troon NFTs
	// 
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(contract)
		let data: NFTData
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(templateID: UInt64, mintNumber: UInt64){ 
			NFTContract.totalSupply = NFTContract.totalSupply + 1
			self.id = NFTContract.totalSupply
			NFTContract.allNFTs[self.id] = NFTData(templateID: templateID, mintNumber: mintNumber)
			self.data = NFTContract.allNFTs[self.id]!
			emit NFTMinted(nftId: self.id, templateId: templateID, mintNumber: mintNumber)
		}
	}
	
	// Collection is a resource that every user who owns NFTs 
	// will store in their account to manage their NFTS
	//
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: template does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @NFTContract.NFT
			let id = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			destroy oldToken
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			emit NFTBorrowed(id: id)
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
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
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// Special Capability, that is needed by user to utilize our contract. Only verified user can get this capability so it will add a KYC layer in our white-lable-solution
	access(all)
	resource interface UserSpecialCapability{ 
		access(all)
		fun addCapability(cap: Capability<&{NFTMethodsCapability}>)
	}
	
	// Interface, which contains all the methods that are called by any user to mint NFT and manage brand, schema and template funtionality
	access(all)
	resource interface NFTMethodsCapability{ 
		access(all)
		fun createNewBrand(brandName: String, data:{ String: String})
		
		access(all)
		fun updateBrandData(brandId: UInt64, data:{ String: String})
		
		access(all)
		fun createSchema(schemaName: String, format:{ String: SchemaType})
		
		access(all)
		fun createTemplate(brandId: UInt64, schemaId: UInt64, maxSupply: UInt64, immutableData:{ String: AnyStruct})
		
		access(all)
		fun mintNFT(templateId: UInt64, account: Address)
	}
	
	//AdminCapability to add whiteListedAccounts
	access(all)
	resource AdminCapability{ 
		access(all)
		fun addwhiteListedAccount(_user: Address){ 
			pre{ 
				NFTContract.whiteListedAccounts.contains(_user) == false:
					"user already exist"
			}
			NFTContract.whiteListedAccounts.append(_user)
		}
		
		access(all)
		fun isWhiteListedAccount(_user: Address): Bool{ 
			return NFTContract.whiteListedAccounts.contains(_user)
		}
		
		init(){} 
	}
	
	// AdminResource, where are defining all the methods related to Brands, Schema, Template and NFTs
	access(all)
	resource AdminResource: UserSpecialCapability, NFTMethodsCapability{ 
		// a variable which stores all Brands owned by a user
		access(self)
		var ownedBrands:{ UInt64: Brand}
		
		// a variable which stores all Schema owned by a user
		access(self)
		var ownedSchemas:{ UInt64: Schema}
		
		// a variable which stores all Templates owned by a user
		access(self)
		var ownedTemplates:{ UInt64: Template}
		
		// a variable that store user capability to utilize methods 
		access(contract)
		var capability: Capability<&{NFTMethodsCapability}>?
		
		// method which provide capability to user to utilize methods
		access(all)
		fun addCapability(cap: Capability<&{NFTMethodsCapability}>){ 
			pre{ 
				// we make sure the SpecialCapability is
				// valid before executing the method
				cap.borrow() != nil:
					"could not borrow a reference to the SpecialCapability"
				self.capability == nil:
					"resource already has the SpecialCapability"
				NFTContract.whiteListedAccounts.contains((self.owner!).address):
					"you are not authorized for this action"
			}
			// add the SpecialCapability
			self.capability = cap
		}
		
		//method to create new Brand, only access by the verified user
		access(all)
		fun createNewBrand(brandName: String, data:{ String: String}){ 
			pre{ 
				// the transaction will instantly revert if
				// the capability has not been added
				self.capability != nil:
					"I don't have the special capability :("
				NFTContract.whiteListedAccounts.contains((self.owner!).address):
					"you are not authorized for this action"
			}
			let newBrand = Brand(brandName: brandName, author: self.owner?.address!, data: data)
			NFTContract.allBrands[NFTContract.lastIssuedBrandId] = newBrand
			emit BrandCreated(brandId: NFTContract.lastIssuedBrandId, brandName: brandName, author: self.owner?.address!, data: data)
			self.ownedBrands[NFTContract.lastIssuedBrandId] = newBrand
			NFTContract.lastIssuedBrandId = NFTContract.lastIssuedBrandId + 1
		}
		
		//method to update the existing Brand, only author of brand can update this brand
		access(all)
		fun updateBrandData(brandId: UInt64, data:{ String: String}){ 
			pre{ 
				// the transaction will instantly revert if
				// the capability has not been added
				self.capability != nil:
					"I don't have the special capability :("
				NFTContract.whiteListedAccounts.contains((self.owner!).address):
					"you are not authorized for this action"
				NFTContract.allBrands[brandId] != nil:
					"brand Id does not exists"
			}
			let oldBrand = NFTContract.allBrands[brandId]
			if self.owner?.address! != (oldBrand!).author{ 
				panic("No permission to update others brand")
			}
			(NFTContract.allBrands[brandId]!).update(data: data)
			emit BrandUpdated(brandId: brandId, brandName: (oldBrand!).brandName, author: (oldBrand!).author, data: data)
		}
		
		//method to create new Schema, only access by the verified user
		access(all)
		fun createSchema(schemaName: String, format:{ String: SchemaType}){ 
			pre{ 
				// the transaction will instantly revert if 
				// the capability has not been added
				self.capability != nil:
					"I don't have the special capability :("
				NFTContract.whiteListedAccounts.contains((self.owner!).address):
					"you are not authorized for this action"
			}
			let newSchema = Schema(schemaName: schemaName, author: self.owner?.address!, format: format)
			NFTContract.allSchemas[NFTContract.lastIssuedSchemaId] = newSchema
			emit SchemaCreated(schemaId: NFTContract.lastIssuedSchemaId, schemaName: schemaName, author: self.owner?.address!)
			self.ownedSchemas[NFTContract.lastIssuedSchemaId] = newSchema
			NFTContract.lastIssuedSchemaId = NFTContract.lastIssuedSchemaId + 1
		}
		
		//method to create new Template, only access by the verified user
		access(all)
		fun createTemplate(brandId: UInt64, schemaId: UInt64, maxSupply: UInt64, immutableData:{ String: AnyStruct}){ 
			pre{ 
				// the transaction will instantly revert if 
				// the capability has not been added
				self.capability != nil:
					"I don't have the special capability :("
				NFTContract.whiteListedAccounts.contains((self.owner!).address):
					"you are not authorized for this action"
				self.ownedBrands[brandId] != nil:
					"Collection Id Must be valid"
				self.ownedSchemas[schemaId] != nil:
					"Schema Id Must be valid"
			}
			let newTemplate = Template(brandId: brandId, schemaId: schemaId, maxSupply: maxSupply, immutableData: immutableData)
			NFTContract.allTemplates[NFTContract.lastIssuedTemplateId] = newTemplate
			emit TemplateCreated(templateId: NFTContract.lastIssuedTemplateId, brandId: brandId, schemaId: schemaId, maxSupply: maxSupply)
			self.ownedTemplates[NFTContract.lastIssuedTemplateId] = newTemplate
			NFTContract.lastIssuedTemplateId = NFTContract.lastIssuedTemplateId + 1
		}
		
		//method to mint NFT, only access by the verified user
		access(all)
		fun mintNFT(templateId: UInt64, account: Address){ 
			pre{ 
				// the transaction will instantly revert if 
				// the capability has not been added
				self.capability != nil:
					"I don't have the special capability :("
				NFTContract.whiteListedAccounts.contains((self.owner!).address):
					"you are not authorized for this action"
				self.ownedTemplates[templateId] != nil:
					"Minter does not have specific template Id"
				NFTContract.allTemplates[templateId] != nil:
					"Template Id must be valid"
			}
			let receiptAccount = getAccount(account)
			let recipientCollection = receiptAccount.capabilities.get<&{NonFungibleToken.CollectionPublic}>(NFTContract.CollectionPublicPath).borrow<&{NonFungibleToken.CollectionPublic}>() ?? panic("Could not get receiver reference to the NFT Collection")
			var newNFT: @NFT <- create NFT(templateID: templateId, mintNumber: (NFTContract.allTemplates[templateId]!).incrementIssuedSupply())
			recipientCollection.deposit(token: <-newNFT)
		}
		
		init(){ 
			self.ownedBrands ={} 
			self.ownedSchemas ={} 
			self.ownedTemplates ={} 
			self.capability = nil
		}
	}
	
	//method to create empty Collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create NFTContract.Collection()
	}
	
	//method to create Admin Resources
	access(all)
	fun createAdminResource(): @AdminResource{ 
		return <-create AdminResource()
	}
	
	//method to get all brands
	access(all)
	fun getAllBrands():{ UInt64: Brand}{ 
		return NFTContract.allBrands
	}
	
	//method to get brand by id
	access(all)
	fun getBrandById(brandId: UInt64): Brand{ 
		pre{ 
			NFTContract.allBrands[brandId] != nil:
				"brand Id does not exists"
		}
		return NFTContract.allBrands[brandId]!
	}
	
	//method to get all schema
	access(all)
	fun getAllSchemas():{ UInt64: Schema}{ 
		return NFTContract.allSchemas
	}
	
	//method to get schema by id
	access(all)
	fun getSchemaById(schemaId: UInt64): Schema{ 
		pre{ 
			NFTContract.allSchemas[schemaId] != nil:
				"schema id does not exist"
		}
		return NFTContract.allSchemas[schemaId]!
	}
	
	//method to get all templates
	access(all)
	fun getAllTemplates():{ UInt64: Template}{ 
		return NFTContract.allTemplates
	}
	
	//method to get template by id
	access(all)
	fun getTemplateById(templateId: UInt64): Template{ 
		pre{ 
			NFTContract.allTemplates[templateId] != nil:
				"Template id does not exist"
		}
		return NFTContract.allTemplates[templateId]!
	}
	
	//method to get nft-data by id
	access(all)
	fun getNFTDataById(nftId: UInt64): NFTData{ 
		pre{ 
			NFTContract.allNFTs[nftId] != nil:
				"nft id does not exist"
		}
		return NFTContract.allNFTs[nftId]!
	}
	
	//Initialize all variables with default values
	init(){ 
		self.lastIssuedBrandId = 1
		self.lastIssuedSchemaId = 1
		self.lastIssuedTemplateId = 1
		self.totalSupply = 0
		self.allBrands ={} 
		self.allSchemas ={} 
		self.allTemplates ={} 
		self.allNFTs ={} 
		self.whiteListedAccounts = [self.account.address]
		self.AdminResourceStoragePath = /storage/TroonAdminResource
		self.CollectionStoragePath = /storage/TroonCollection
		self.CollectionPublicPath = /public/TroonCollection
		self.AdminStorageCapability = /storage/AdminCapability
		self.AdminCapabilityPrivate = /private/AdminCapability
		self.NFTMethodsCapabilityPrivatePath = /private/NFTMethodsCapability
		self.account.storage.save<@AdminCapability>(<-create AdminCapability(), to: /storage/AdminStorageCapability)
		var capability_1 = self.account.capabilities.storage.issue<&AdminCapability>(/storage/AdminStorageCapability)
		self.account.capabilities.publish(capability_1, at: self.AdminCapabilityPrivate)
		self.account.storage.save<@AdminResource>(<-create AdminResource(), to: self.AdminResourceStoragePath)
		var capability_2 = self.account.capabilities.storage.issue<&{NFTMethodsCapability}>(self.AdminResourceStoragePath)
		self.account.capabilities.publish(capability_2, at: self.NFTMethodsCapabilityPrivatePath)
		emit ContractInitialized()
	}
}
