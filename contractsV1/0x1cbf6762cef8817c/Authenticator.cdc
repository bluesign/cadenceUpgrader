import DapperUtilityCoin from "./../../standardsV1/DapperUtilityCoin.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract Authenticator: NonFungibleToken{ 
	// #region DATA
	/**
		* Total number of minted NFTs
		*/
	
	access(all)
	var totalSupply: UInt64
	
	/**
		* Addresses of the owner of each NFT id
		*/
	
	access(contract)
	let licenseOwners:{ UInt64: Address}
	
	/**
		* Addresses of the owner of each Content Provider Label
		*/
	
	access(contract)
	let cpOwners:{ String: Address}
	
	/**
		* A boolean that indicates if the Content Provider Label is not banned
		*/
	
	access(contract)
	let cpActive:{ String: Bool}
	
	/**
		* The Address of the SmartContract Admin
		*/
	
	access(all)
	var adminAddress: Address
	
	/**
		* Admin's Dapper Wallet Address
		*/
	
	access(all)
	var adminDapperWalletAddress: Address
	
	// endregion
	// #region CONSTANTS
	/**
		* The public path to store the NFTs Collection
		*/
	
	access(all)
	let licenseCollectionPubPath: PublicPath
	
	/**
		* The public path to store the Content Provider Collection
		*/
	
	access(all)
	let cpCollectionPubPath: PublicPath
	
	/**
		* The public path to store the Admin Container
		*/
	
	access(all)
	let adminContainerPubPath: PublicPath
	
	/**
		* The storage path to store the NFTs Collection
		*/
	
	access(all)
	var licenseCollectionStoragePath: StoragePath
	
	/**
		* The storage path to store the Content Provider Collection
		*/
	
	access(all)
	var cpCollectionStoragePath: StoragePath
	
	/**
		* The storage path to store the Admin Container
		*/
	
	access(all)
	var adminContainerStoragePath: StoragePath
	
	/**
		* Default NFT name
		*/
	
	access(all)
	var defaultNftName: String
	
	/**
		* Default NFT Image
		*/
	
	access(all)
	var defaultNftImage: String
	
	/**
		* Default NFT Image
		*/
	
	access(all)
	var defaultNftExternalUrl: String
	
	/**
		* Price in Dollar of each bought NFT
		* Ideally this price would be set individually for each "NFT Template", this will be the case in the future
		*/
	
	access(all)
	var nftPrice: UFix64
	
	/**
		* Constant that allows the user to buy any Object
		* Ideally each allowed Object would be on a "NFT Template", this will be the case in the future
		*/
	
	access(self)
	let allowBuyAnyObject: Bool
	
	/**
		* Constant that allows the user to buy any Category
		* Ideally each allowed Category would be on a "NFT Template", this will be the case in the future
		*/
	
	access(self)
	let allowBuyAnyCategory: Bool
	
	/**
		* Default 'transferable' variable for bought NFT. Leave nil to use the default value of createNFTLicense.
		* Ideally this value would be set individually for each "NFT Template", this will be the case in the future
		*/
	
	access(self)
	let boughtNftIsTransferable: Bool?
	
	/**
		* Default 'expiration' variable for bought NFT. Leave nil to use the default value of createNFTLicense.
		* Ideally this value would be set individually for each "NFT Template", this will be the case in the future
		*/
	
	access(self)
	let boughtNftExpiration: UInt?
	
	/**
		* Default 'image' variable for bought NFT. Leave nil to use the default value of createNFTLicense.
		* Ideally this value would be set individually for each "NFT Template", this will be the case in the future
		*/
	
	access(all)
	let boughtNftImage: String?
	
	/**
		* Default 'name' variable for bought NFT. Leave nil to use the default value of createNFTLicense.
		* Ideally this value would be set individually for each "NFT Template", this will be the case in the future
		*/
	
	access(all)
	let boughtNftName: String?
	
	// endregion
	// #region EVENTS
	/**
		* When the contract is initialized
		*/
	
	access(all)
	event ContractInitialized()
	
	/**
		* When the token is withdrawn from the collection
		*/
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	/**
		* When the token is deposit to a collection
		*/
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	/**
		* When the token is deposit to a collection without a previous owner
		*/
	
	access(all)
	event MintLicense(id: UInt64, owner: Address?, contentProviderLabel: String, objectLabel: String?, categoryLabel: String?, expiration: UInt?, transferable: Bool)
	
	/**
		* When the token is deposit to a collection from a previous owner
		*/
	
	access(all)
	event Transfer(id: UInt64, from: Address?, to: Address?)
	
	/**
		* When a category is created
		*/
	
	access(all)
	event CreateCategory(contentProvider: String, label: String, title: String)
	
	/**
		* When an object is created
		*/
	
	access(all)
	event CreateObject(contentProvider: String, label: String, categories: [String])
	
	/**
		* When a content provider is created
		*/
	
	access(all)
	event RegisterContentProvider(label: String, address: Address)
	
	/**
		* When a content provider is removed
		*/
	
	access(all)
	event RemoveContentProvider(label: String)
	
	// endregion
	// #region LIFECYCLE
	init(){ 
		self.totalSupply = 0
		self.licenseOwners ={} 
		self.cpOwners ={} 
		self.cpActive ={} 
		self.adminAddress = self.account.address
		self.adminDapperWalletAddress = self.account.address
		self.licenseCollectionPubPath = /public/ltrAuthLicenseCollection
		self.cpCollectionPubPath = /public/ltrAuthCpCollection
		self.adminContainerPubPath = /public/ltrAuthAdminContainer
		self.licenseCollectionStoragePath = /storage/ltrAuthLicenseCollection
		self.cpCollectionStoragePath = /storage/ltrAuthCpCollection
		self.adminContainerStoragePath = /storage/ltrAuthAdminContainer
		self.nftPrice = 89.50
		self.defaultNftName = "Letter Key"
		self.defaultNftImage = "https://the.letterplatform.com/token/img/default.png"
		self.defaultNftExternalUrl = "https://the.letterplatform.com/license/"
		self.allowBuyAnyObject = true
		self.allowBuyAnyCategory = false
		self.boughtNftIsTransferable = nil
		self.boughtNftExpiration = nil
		self.boughtNftImage = nil
		self.boughtNftName = nil
		emit ContractInitialized()
		self.account.storage.save(<-create Admin(), to: /storage/AuthenticatorAdmin)
	}
	
	// endregion
	// #region PUBLIC METHODS
	/**
		* Creates an empty NFT Collection
		*/
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	/**
		* Creates an empty Content Provider Collection
		*/
	
	access(all)
	fun createEmptyCpCollection(): @CpCollection{ 
		return <-create CpCollection()
	}
	
	/**
		* Creates an empty Admin Container
		*/
	
	access(all)
	fun createEmptyAdminContainer(): @AdminContainer{ 
		return <-create AdminContainer()
	}
	
	access(all)
	fun ownerOf(tokenId: UInt64): Address?{ 
		return self.licenseOwners[tokenId]
	}
	
	access(all)
	fun allTokens(): [UInt64]{ 
		return self.licenseOwners.keys
	}
	
	access(all)
	fun getAddressOfContentProvider(label: String): Address?{ 
		return self.cpOwners[label]
	}
	
	access(all)
	fun getActiveContentProviders(): [String]{ 
		let resp: [String] = []
		for cpLabel in self.cpActive.keys{ 
			if self.cpActive[cpLabel] ?? false{ 
				resp.append(cpLabel)
			}
		}
		return resp
	}
	
	access(all)
	fun getDescription(name: String?, cpLabel: String, objectLabel: String?, categoryLabel: String?): String{ 
		let mainText = (name ?? Authenticator.defaultNftName).concat(" is a custom-minted NFT that grants access to the platform. It is the passport to safely verify login credentials to unlock content, forums with journalists and experts, exclusive on-line events and all the benefits only Letter members have. ")
		let cpText = "Content Provider: ".concat(cpLabel).concat(". ")
		let objectText = objectLabel != nil ? "Object: ".concat(objectLabel!).concat(". ") : ""
		let categoryText = categoryLabel != nil ? "Category: ".concat(categoryLabel!).concat(". ") : ""
		return mainText.concat(cpText).concat(objectText).concat(categoryText)
	}
	
	// endregion
	// #region RESOURCE INTERFACES
	access(all)
	resource interface PublicObject{ 
		access(all)
		let label: String
		
		access(all)
		let contentProviderLabel: String
		
		access(all)
		let metadata: String?
		
		access(all)
		let codeGenerationUrl: String?
		
		access(all)
		let privateInfoUrl: String?
		
		access(all)
		fun borrowCategoriesAsPublic():{ String: &Category}
	}
	
	access(all)
	resource interface PublicCategory{ 
		access(all)
		let label: String
		
		access(all)
		let contentProviderLabel: String
		
		access(all)
		let title: String?
		
		access(all)
		fun borrowObjectsAsPublic():{ String: &Object}
	}
	
	access(all)
	resource interface PublicContentProvider{ 
		access(all)
		let label: String
		
		access(all)
		fun borrowObjectsAsPublic():{ String: &Object}
		
		access(all)
		fun borrowCategoriesAsPublic():{ String: &Category}
		
		access(all)
		fun borrowObjectAsPublic(label: String): &Object?
		
		access(all)
		fun borrowCategoryAsPublic(label: String): &Category?
		
		access(all)
		fun buyLicenseWithFUSD(vault: @FUSD.Vault, objectLabel: String?, categoryLabel: String?): @NFT
		
		access(all)
		fun buyLicenseWithDUC(vault: @DapperUtilityCoin.Vault, objectLabel: String?, categoryLabel: String?): @NFT
	}
	
	access(all)
	resource interface PublicAdminContainer{ 
		access(all)
		fun deposit(admin: @Admin)
	}
	
	access(all)
	resource interface PublicCpCollection{ 
		access(all)
		fun deposit(token: @ContentProvider)
		
		access(all)
		fun getLabels(): [String]
		
		access(all)
		fun borrowContentProviderAsPublic(label: String): &ContentProvider
	}
	
	access(all)
	resource interface PublicLicenseCollection{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun balance(): Int
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowNFTAsPublic(id: UInt64): &NFT?
		
		access(all)
		fun hasAccess(label: String, contentProvider: String): Bool
		
		access(all)
		fun getAccessExpiration(label: String, contentProvider: String): Int?
	}
	
	access(all)
	resource interface PublicNFT{ 
		// NonFungibleToken.INFT
		access(all)
		let id: UInt64
		
		// Authenticator logic
		access(all)
		let contentProviderLabel: String
		
		access(all)
		let transferable: Bool
		
		access(all)
		let expiration: UInt?
		
		// MetadataViews.Resolver
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		var image: String
		
		access(all)
		fun getViews(): [Type]
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?
		
		access(all)
		fun borrowObjectAsPublic(): &Object?
		
		access(all)
		fun borrowCategoryAsPublic(): &Category?
		
		access(contract)
		fun hasAccess(label: String, contentProviderLabel: String): Bool
	}
	
	// endregion
	// #region RESOURCES
	/**
		* Responsible for adding and removing Content Providers
		*/
	
	access(all)
	resource Admin{ 
		access(all)
		fun createContentProvider(label: String): @ContentProvider{ 
			pre{ // throws an error if the condition is false 
				
				Authenticator.cpActive[label] == nil:
					"There is already another content provider with the inputed label"
			}
			return <-create ContentProvider(label: label)
		}
		
		access(all)
		fun banContentProvider(label: String){ 
			Authenticator.cpActive[label] = false
			emit RemoveContentProvider(label: label)
		}
		
		access(all)
		fun unbanContentProvider(label: String){ 
			pre{ // throws an error if the condition is false 
				
				Authenticator.cpActive[label] != nil:
					"Content Provider not found"
			}
			Authenticator.cpActive[label] = true
			emit RegisterContentProvider(label: label, address: Authenticator.cpOwners[label]!)
		}
		
		access(all)
		fun registerAdmin(adminAddress: Address?, adminDapperWalletAddress: Address?){ 
			if adminAddress != nil{ 
				Authenticator.adminAddress = adminAddress!
			}
			if adminDapperWalletAddress != nil{ 
				Authenticator.adminDapperWalletAddress = adminDapperWalletAddress!
			}
		}
		
		access(all)
		fun changeStoragePaths(licenseCollectionStoragePath: StoragePath?, cpCollectionStoragePath: StoragePath?, adminContainerStoragePath: StoragePath?){ 
			if licenseCollectionStoragePath != nil{ 
				Authenticator.licenseCollectionStoragePath = licenseCollectionStoragePath!
			}
			if cpCollectionStoragePath != nil{ 
				Authenticator.cpCollectionStoragePath = cpCollectionStoragePath!
			}
			if adminContainerStoragePath != nil{ 
				Authenticator.adminContainerStoragePath = adminContainerStoragePath!
			}
		}
		
		access(all)
		fun changeNftPrice(nftPrice: UFix64){ 
			Authenticator.nftPrice = nftPrice!
		}
		
		access(all)
		fun changeDefaultNftStrings(defaultNftName: String?, defaultNftImage: String?, defaultNftExternalUrl: String?){ 
			if defaultNftName != nil{ 
				Authenticator.defaultNftName = defaultNftName!
			}
			if defaultNftImage != nil{ 
				Authenticator.defaultNftImage = defaultNftImage!
			}
			if defaultNftExternalUrl != nil{ 
				Authenticator.defaultNftExternalUrl = defaultNftExternalUrl!
			}
		}
	}
	
	access(all)
	resource Object: PublicObject{ 
		access(all)
		let label: String
		
		access(all)
		let contentProviderLabel: String
		
		access(all)
		let metadata: String?
		
		access(all)
		let hiddenMetadata: String?
		
		access(all)
		let codeGenerationUrl: String?
		
		access(all)
		let privateInfoUrl: String?
		
		access(self)
		let categories:{ String: Capability<&Category>}
		
		init(label: String, contentProviderLabel: String, metadata: String?, hiddenMetadata: String?, codeGenerationUrl: String?, privateInfoUrl: String?){ 
			self.label = label
			self.contentProviderLabel = contentProviderLabel
			self.metadata = metadata
			self.hiddenMetadata = hiddenMetadata
			self.codeGenerationUrl = codeGenerationUrl
			self.privateInfoUrl = privateInfoUrl
			self.categories ={} 
		}
		
		access(contract)
		fun addCategory(label: String, obj: Capability<&Category>){ 
			self.categories[label] = obj
		}
		
		access(all)
		fun borrowCategoriesAsPublic():{ String: &Category}{ 
			let resp:{ String: &Category} ={} 
			for catLabel in self.categories.keys{ 
				resp[catLabel] = (self.categories[catLabel]!).borrow()
			}
			return resp
		}
	}
	
	access(all)
	resource Category: PublicCategory{ 
		access(all)
		let label: String
		
		access(all)
		let contentProviderLabel: String
		
		access(all)
		let title: String?
		
		access(self)
		let objects:{ String: Capability<&Object>}
		
		init(label: String, contentProviderLabel: String, title: String?){ 
			self.label = label
			self.contentProviderLabel = contentProviderLabel
			self.title = title
			self.objects ={} 
		}
		
		access(contract)
		fun addObject(label: String, obj: Capability<&Object>){ 
			self.objects[label] = obj
		}
		
		access(all)
		fun borrowObjectsAsPublic():{ String: &Object}{ 
			let resp:{ String: &Object} ={} 
			for objLabel in self.objects.keys{ 
				resp[objLabel] = (self.objects[objLabel]!).borrow()
			}
			return resp
		}
		
		access(all)
		fun borrowObjectAsPrivate(label: String): &Object?{ 
			return self.objects[label]?.borrow() ?? nil
		}
	}
	
	/**
		* Responsible for creating Objects, Categories and License NFTs
		*/
	
	access(all)
	resource ContentProvider: PublicContentProvider{ 
		access(all)
		let label: String
		
		access(self)
		let objects:{ String: Capability<&Object>}
		
		access(self)
		let categories:{ String: Capability<&Category>}
		
		init(label: String){ 
			self.label = label
			self.objects ={} 
			self.categories ={} 
		}
		
		access(all)
		fun borrowObjectsAsPublic():{ String: &Object}{ 
			let resp:{ String: &Object} ={} 
			for objLabel in self.objects.keys{ 
				resp[objLabel] = (self.objects[objLabel]!).borrow()
			}
			return resp
		}
		
		access(all)
		fun borrowCategoriesAsPublic():{ String: &Category}{ 
			let resp:{ String: &Category} ={} 
			for catLabel in self.categories.keys{ 
				resp[catLabel] = (self.categories[catLabel]!).borrow()
			}
			return resp
		}
		
		access(all)
		fun borrowObjectAsPublic(label: String): &Object?{ 
			return self.objects[label]?.borrow() ?? nil
		}
		
		access(all)
		fun borrowCategoryAsPublic(label: String): &Category?{ 
			return self.categories[label]?.borrow() ?? nil
		}
		
		access(all)
		fun createObject(label: String, metadata: String?, hiddenMetadata: String?, codeGenerationUrl: String?, privateInfoUrl: String?): @Object{ 
			pre{ 
				Authenticator.cpActive[self.label] == true:
					"Content Provider is banned"
				self.objects[label] == nil:
					"There is already an object with the same label"
			}
			return <-create Object(label: label, contentProviderLabel: self.label, metadata: metadata, hiddenMetadata: hiddenMetadata, codeGenerationUrl: codeGenerationUrl, privateInfoUrl: privateInfoUrl)
		}
		
		access(all)
		fun publishObject(object: Capability<&Object>, categoryLabels: [String]){ 
			pre{ 
				Authenticator.cpActive[self.label] == true:
					"Content Provider is banned"
				object.borrow() != nil:
					"Cant borrow object"
				self.objects[(object.borrow()!).label] == nil:
					"There is already an object with the same label"
			}
			post{ 
				self.objects[(object.borrow()!).label] != nil:
					"The object was not published"
			}
			let objRef = object.borrow() ?? panic("Can't borrow object")
			for catLabel in categoryLabels{ 
				let catCap = self.categories[catLabel] ?? panic("category ".concat(catLabel).concat(" not found"))
				let catRef = catCap.borrow() ?? panic("Can't borrow category")
				catRef.addObject(label: objRef.label, obj: object)
				objRef.addCategory(label: catLabel, obj: catCap)
			}
			self.objects[objRef.label] = object
			emit CreateObject(contentProvider: self.label, label: objRef.label, categories: categoryLabels)
		}
		
		access(all)
		fun createCategory(label: String, title: String?): @Category{ 
			pre{ 
				Authenticator.cpActive[self.label] == true:
					"Content Provider is banned"
				self.categories[label] == nil:
					"There is already a category with the same label"
			}
			return <-create Category(label: label, contentProviderLabel: self.label, title: title)
		}
		
		access(all)
		fun publishCategory(category: Capability<&Category>){ 
			pre{ 
				Authenticator.cpActive[self.label] == true:
					"Content Provider is banned"
				self.categories[(category.borrow()!).label] == nil:
					"There is already a category with the same label"
			}
			post{ 
				self.categories[(category.borrow()!).label] != nil:
					"The category was not published"
			}
			let ref = category.borrow() ?? panic("Can't borrow category")
			self.categories[ref.label] = category
			emit CreateCategory(contentProvider: self.label, label: ref.label, title: ref.title ?? "")
		}
		
		access(all)
		fun buyLicenseWithFUSD(vault: @FUSD.Vault, objectLabel: String?, categoryLabel: String?): @NFT{ 
			pre{ 
				vault.balance == Authenticator.nftPrice:
					"Invalid Price"
				objectLabel == nil || Authenticator.allowBuyAnyObject:
					"Object not for sale"
				categoryLabel == nil || Authenticator.allowBuyAnyCategory:
					"Category not for sale"
				objectLabel == nil || categoryLabel == nil:
					"Invalid License"
			}
			let adminFusdReceiver = (getAccount(Authenticator.adminAddress).capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver)!).borrow() ?? panic("Could not borrow receiver reference to the Admin's FUSD Vault")
			adminFusdReceiver.deposit(from: <-vault)
			return <-self.createLicenseNFT(transferable: Authenticator.boughtNftIsTransferable, expiration: Authenticator.boughtNftExpiration, objectLabel: objectLabel, categoryLabel: categoryLabel, image: Authenticator.boughtNftImage, name: Authenticator.boughtNftName, url: nil)
		}
		
		access(all)
		fun buyLicenseWithDUC(vault: @DapperUtilityCoin.Vault, objectLabel: String?, categoryLabel: String?): @NFT{ 
			pre{ 
				vault.balance == Authenticator.nftPrice:
					"Invalid Price"
				objectLabel == nil || Authenticator.allowBuyAnyObject:
					"Object not for sale"
				categoryLabel == nil || Authenticator.allowBuyAnyCategory:
					"Category not for sale"
				objectLabel == nil || categoryLabel == nil:
					"Invalid License"
			}
			let adminDucReceiver = (getAccount(Authenticator.adminDapperWalletAddress).capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)!).borrow() ?? panic("Could not borrow receiver reference to the Admin's DUC Vault")
			adminDucReceiver.deposit(from: <-vault)
			return <-self.createLicenseNFT(transferable: Authenticator.boughtNftIsTransferable, expiration: Authenticator.boughtNftExpiration, objectLabel: objectLabel, categoryLabel: categoryLabel, image: Authenticator.boughtNftImage, name: Authenticator.boughtNftName, url: nil)
		}
		
		access(all)
		fun createLicenseNFT(transferable: Bool?, expiration: UInt?, objectLabel: String?, categoryLabel: String?, image: String?, name: String?, url: String?): @NFT{ 
			pre{ 
				Authenticator.cpActive[self.label] == true:
					"Content Provider is banned"
				expiration == nil || Int(expiration ?? 0) > Int(getCurrentBlock().timestamp):
					"Expiration date is in the past"
			}
			let object: Capability<&Object>? = objectLabel == nil ? nil : self.objects[objectLabel!]
			let category: Capability<&Category>? = categoryLabel == nil ? nil : self.categories[categoryLabel!]
			return <-create NFT(contentProviderLabel: self.label, transferable: transferable ?? true, expiration: expiration, object: object, category: category, image: image, name: name, url: url)
		}
	}
	
	access(all)
	resource AdminContainer: PublicAdminContainer{ 
		access(self)
		var admin: @Admin?
		
		init(){ 
			self.admin <- nil
		}
		
		access(all)
		fun deposit(admin: @Admin){ 
			self.admin <-! admin
		}
		
		access(all)
		fun borrowAdmin(): &Admin{ 
			return (&self.admin as &Admin?)!
		}
	}
	
	access(all)
	resource CpCollection: PublicCpCollection{ 
		access(self)
		var ownedCPs: @{String: ContentProvider}
		
		init(){ 
			self.ownedCPs <-{} 
		}
		
		access(all)
		fun deposit(token: @ContentProvider){ 
			Authenticator.cpOwners[token.label] = (self.owner!).address
			if Authenticator.cpActive[token.label] == nil{ 
				Authenticator.cpActive[token.label] = true
				emit RegisterContentProvider(label: token.label, address: (self.owner!).address)
			}
			self.ownedCPs[token.label] <-! token
		}
		
		access(all)
		fun withdraw(withdrawID: String): @ContentProvider{ 
			let token <- self.ownedCPs.remove(key: withdrawID) ?? panic("This collection doesnt contain the required Content Provider")
			return <-token
		}
		
		access(all)
		fun getLabels(): [String]{ 
			return self.ownedCPs.keys
		}
		
		access(all)
		fun borrowContentProviderAsPublic(label: String): &ContentProvider{ 
			return (&self.ownedCPs[label] as &ContentProvider?)!
		}
		
		access(all)
		fun borrowContentProvider(label: String): &ContentProvider{ 
			return (&self.ownedCPs[label] as &ContentProvider?)!
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver, PublicNFT{ 
		// NonFungibleToken.INFT
		access(all)
		let id: UInt64
		
		// Authenticator logic
		access(all)
		let contentProviderLabel: String
		
		access(all)
		let transferable: Bool
		
		access(all)
		let expiration: UInt?
		
		// Authenticator private
		access(all)
		let object: Capability<&Object>?
		
		access(all)
		let category: Capability<&Category>?
		
		// MetadataViews.Resolver
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		var image: String
		
		access(all)
		var url: String
		
		init(contentProviderLabel: String, transferable: Bool, expiration: UInt?, object: Capability<&Object>?, category: Capability<&Category>?, image: String?, name: String?, url: String?){ 
			self.id = Authenticator.totalSupply
			self.contentProviderLabel = contentProviderLabel
			self.transferable = transferable
			self.expiration = expiration
			self.object = object
			self.category = category
			self.name = (name ?? "").length > 0 ? name! : Authenticator.defaultNftName
			self.description = Authenticator.getDescription(name: self.name, cpLabel: contentProviderLabel, objectLabel: (object?.borrow() ?? nil)?.label, categoryLabel: (category?.borrow() ?? nil)?.label)
			self.image = image ?? Authenticator.defaultNftImage
			self.url = url ?? Authenticator.defaultNftExternalUrl.concat(self.id.toString())
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.image))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(self.url)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Authenticator.licenseCollectionStoragePath, publicPath: Authenticator.licenseCollectionPubPath, publicCollection: Type<&Authenticator.Collection>(), publicLinkedType: Type<&Authenticator.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Authenticator.createEmptyCollection(nftType: Type<@Authenticator.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: Authenticator.defaultNftImage), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: self.name, description: self.description, externalURL: MetadataViews.ExternalURL(Authenticator.defaultNftExternalUrl), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/letterplatform"), "medium": MetadataViews.ExternalURL("https://medium.com/@letterplatform"), "instagram": MetadataViews.ExternalURL("https://instagram.com/letterplatform"), "facebook": MetadataViews.ExternalURL("https://facebook.com/letterplatform"), "linkedIn": MetadataViews.ExternalURL("https://linkedIn.com/in/letterplatform"), "reddit": MetadataViews.ExternalURL("https://reddit.com/u/letterplatform"), "tikTok": MetadataViews.ExternalURL("https://tikTok.com/@letterplatform"), "youTube": MetadataViews.ExternalURL("https://youTube.com/@letterplatform")})
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
			}
			return nil
		}
		
		access(all)
		fun borrowObjectAsPublic(): &Object?{ 
			return self.object?.borrow() ?? nil
		}
		
		access(all)
		fun borrowCategoryAsPublic(): &Category?{ 
			return self.category?.borrow() ?? nil
		}
		
		access(all)
		fun borrowObjectAsPrivate(): &Object?{ 
			return self.object?.borrow() ?? nil
		}
		
		access(all)
		fun borrowCategoryAsPrivate(): &Category?{ 
			return self.category?.borrow() ?? nil
		}
		
		access(contract)
		fun hasAccess(label: String, contentProviderLabel: String): Bool{ 
			if self.expiration != nil && Int(self.expiration ?? 0) < Int(getCurrentBlock().timestamp){ 
				return false
			}
			if self.contentProviderLabel != contentProviderLabel{ 
				return false
			}
			if self.object == nil && self.category == nil{ 
				// has access to every content from this content provider
				return true
			}
			let object = self.borrowObjectAsPublic()
			if object?.contentProviderLabel == contentProviderLabel && object?.label == label{ 
				// has access to this specific object
				return true
			}
			let category = self.borrowCategoryAsPublic()
			if category?.contentProviderLabel == contentProviderLabel && category?.borrowObjectsAsPublic()?.containsKey(label) == true{ 
				// has access to all objects in this category
				return true
			}
			return false
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, PublicLicenseCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let license <- token as! @NFT
			if Authenticator.licenseOwners[license.id] == nil{ 
				Authenticator.totalSupply = Authenticator.totalSupply + 1
				emit MintLicense(id: license.id, owner: (self.owner!).address, contentProviderLabel: license.contentProviderLabel, objectLabel: license.borrowObjectAsPublic()?.label, categoryLabel: license.borrowCategoryAsPublic()?.label, expiration: license.expiration, transferable: license.transferable)
			}
			emit Deposit(id: license.id, to: (self.owner!).address)
			emit Transfer(id: license.id, from: Authenticator.licenseOwners[license.id], to: (self.owner!).address)
			Authenticator.licenseOwners[license.id] = (self.owner!).address
			self.ownedNFTs[license.id] <-! license
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("This collection doesnt contain the required license")
			let license <- token as! @NFT
			if !license.transferable{ 
				panic("This License can't be transfered, it is setup as non-transferable")
			}
			emit Withdraw(id: withdrawID, from: (self.owner!).address)
			return <-license
		}
		
		access(all)
		fun balance(): Int{ 
			return self.ownedNFTs.length
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let authenticatorNFT = nft as! &Authenticator.NFT
			return authenticatorNFT as &{ViewResolver.Resolver}
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}? ?? panic("Nothing exists at this index")
		}
		
		access(all)
		fun borrowNFTAsPublic(id: UInt64): &NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &NFT
			}
			return nil
		}
		
		access(all)
		fun borrowPrivateNFT(id: UInt64): &NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &NFT
			}
			return nil
		}
		
		access(all)
		fun getBestNftIdOfObject(label: String, contentProvider: String): UInt64?{ 
			var accessExpiration: UInt = 0
			var nftId: UInt64? = nil
			for tokenID in self.ownedNFTs.keys{ 
				let nft = self.borrowNFTAsPublic(id: tokenID)
				if nft?.hasAccess(label: label, contentProviderLabel: contentProvider) == true{ 
					if (nft!).expiration == nil{ 
						return (nft!).id // never expires
					
					}
					if Int((nft!).expiration ?? 0) > Int(accessExpiration){ 
						accessExpiration = (nft!).expiration!
						nftId = (nft!).id
					}
				}
			}
			return nftId
		}
		
		access(all)
		fun hasAccess(label: String, contentProvider: String): Bool{ 
			for tokenID in self.ownedNFTs.keys{ 
				let nft = self.borrowNFTAsPublic(id: tokenID)
				if nft?.hasAccess(label: label, contentProviderLabel: contentProvider) == true{ 
					return true
				}
			}
			return false
		}
		
		access(all)
		fun getAccessExpiration(label: String, contentProvider: String): Int?{ 
			var accessExpiration: Int = -1
			for tokenID in self.ownedNFTs.keys{ 
				let nft = self.borrowNFTAsPublic(id: tokenID)
				if nft?.hasAccess(label: label, contentProviderLabel: contentProvider) == true{ 
					if (nft!).expiration == nil{ 
						return nil // never expires
					
					}
					if Int((nft!).expiration!) > accessExpiration{ 
						accessExpiration = Int((nft!).expiration!)
					}
				}
			}
			return accessExpiration
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
// #endregion
}
