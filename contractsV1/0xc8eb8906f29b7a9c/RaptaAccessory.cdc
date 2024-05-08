import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract RaptaAccessory: NonFungibleToken{ 
	
	//STORAGE PATHS
	//Accessory Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	//Template Paths
	access(all)
	let TemplateStoragePath: StoragePath
	
	access(all)
	let TemplatePublicPath: PublicPath
	
	//EVENTS
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64, templateId: UInt64)
	
	access(all)
	event Destroyed(id: UInt64)
	
	access(all)
	event TemplateCreated(id: UInt64, name: String, category: String, mintLimit: UInt64)
	
	//VARIABLES
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var royalties: [Royalty]
	
	access(self)
	let totalMintedAccessories:{ UInt64: UInt64}
	
	access(account)
	var royaltyCut: UFix64
	
	access(account)
	var marketplaceCut: UFix64
	
	//ENUMERABLES
	access(all)
	enum RoyaltyType: UInt8{ 
		access(all)
		case fixed
		
		access(all)
		case percentage
	}
	
	//STRUCTS
	//Royalty Structs
	access(all)
	struct Royalties{ 
		access(all)
		let royalty: [Royalty]
		
		init(royalty: [Royalty]){ 
			self.royalty = royalty
		}
	}
	
	access(all)
	struct Royalty{ 
		access(all)
		let wallet: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let cut: UFix64
		
		access(all)
		let type: RoyaltyType
		
		init(wallet: Capability<&{FungibleToken.Receiver}>, cut: UFix64, type: RoyaltyType){ 
			self.wallet = wallet
			self.cut = cut
			self.type = type
		}
	}
	
	//Accessory Struct
	access(all)
	struct AccessoryData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let templateId: UInt64
		
		access(all)
		var name: String
		
		access(all)
		var description: String
		
		access(all)
		var category: String
		
		access(all)
		var nextSerialNumber: UInt64
		
		init(id: UInt64, templateId: UInt64){ 
			self.id = id
			self.templateId = templateId
			let template = RaptaAccessory.getAccessoryTemplate(id: templateId)!
			self.name = template.name
			self.description = template.description
			self.category = template.category
			self.nextSerialNumber = 1
		}
	}
	
	//Template Struct
	access(all)
	struct TemplateData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let category: String
		
		access(all)
		let png: String
		
		access(all)
		let layer: String
		
		access(all)
		let mintLimit: UInt64
		
		access(all)
		let totalMintedAccessories: UInt64
		
		view init(id: UInt64, name: String, description: String, category: String, png: String, layer: String, mintLimit: UInt64){ 
			self.id = id
			self.name = name
			self.description = description
			self.category = category
			self.png = png
			self.layer = layer
			self.mintLimit = mintLimit
			self.totalMintedAccessories = RaptaAccessory.getTotalMintedAccessoriesByTemplate(id: id)!
		}
	}
	
	//INTERFACES
	//Accessory Interfaces
	access(all)
	resource interface Public{ 
		access(all)
		fun getMint(): UInt64
		
		access(all)
		fun getTemplateId(): UInt64
		
		access(all)
		fun getCategory(): String
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowAccessory(id: UInt64): &RaptaAccessory.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow accessory reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	//Template Interfaces
	access(all)
	resource interface TemplatePublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		var name: String
		
		access(all)
		var description: String
		
		access(all)
		var category: String
		
		access(all)
		var mintLimit: UInt64
		
		access(all)
		var png: String
		
		access(all)
		var layer: String
	}
	
	access(all)
	resource interface TemplateCollectionPublic{ 
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun borrowAccessoryTemplate(id: UInt64): &RaptaAccessory.Template?
	}
	
	//RESOURCES
	//Accessory Resources
	access(all)
	resource NFT: NonFungibleToken.NFT, Public, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let mint: UInt64
		
		access(all)
		let templateId: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(contract)
		let royalties: Royalties
		
		init(templateId: UInt64, royalties: Royalties){ 
			self.id = self.uuid
			self.mint = RaptaAccessory.getTotalMintedAccessoriesByTemplate(id: templateId)! + 1
			self.templateId = templateId
			self.name = (RaptaAccessory.getAccessoryTemplate(id: templateId)!).name
			self.description = (RaptaAccessory.getAccessoryTemplate(id: templateId)!).description
			self.royalties = royalties
			RaptaAccessory.setTotalMintedAccessoriesByTemplate(id: templateId, value: self.mint)
		}
		
		access(all)
		fun getID(): UInt64{ 
			return self.id
		}
		
		access(all)
		fun getMint(): UInt64{ 
			return self.mint
		}
		
		access(all)
		fun getName(): String{ 
			return self.name
		}
		
		access(all)
		fun getTemplateId(): UInt64{ 
			return self.templateId
		}
		
		access(all)
		fun getTemplate(): RaptaAccessory.TemplateData{ 
			return RaptaAccessory.getAccessoryTemplate(id: self.templateId)!
		}
		
		access(all)
		fun getPNG(): String{ 
			return self.getTemplate().png!
		}
		
		access(all)
		fun getLayer(): String{ 
			return self.getTemplate().layer!
		}
		
		access(all)
		fun getCategory(): String{ 
			return self.getTemplate().category
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.getTemplate().png!))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://eqmusic.io/rapta/accessories/".concat(self.id.toString()).concat(".png"))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: RaptaAccessory.CollectionStoragePath, publicPath: RaptaAccessory.CollectionPublicPath, publicCollection: Type<&RaptaAccessory.Collection>(), publicLinkedType: Type<&RaptaAccessory.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-RaptaAccessory.createEmptyCollection(nftType: Type<@RaptaAccessory.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://eqmusic.io/media/raptaAccessoryCollection.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "Rapta Icon Accessory", description: "custom made gear, with real-life utility, made specially for your rapta icon", externalURL: MetadataViews.ExternalURL("https://eqmusic.io/rapta"), squareImage: media, bannerImage: media, socials:{ "hoo.be": MetadataViews.ExternalURL("https://hoo.be/rapta"), "twitter": MetadataViews.ExternalURL("https://twitter.com/_rapta"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/rapta")})
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @RaptaAccessory.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
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
		fun borrowAccessory(id: UInt64): &RaptaAccessory.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &RaptaAccessory.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT does not exist"
			}
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let accessory = nft as! &RaptaAccessory.NFT
			return accessory as &{ViewResolver.Resolver}
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
	
	//Template Resources
	access(all)
	resource Template: TemplatePublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		var name: String
		
		access(all)
		var description: String
		
		access(all)
		var category: String
		
		access(all)
		var mintLimit: UInt64
		
		access(all)
		var png: String
		
		access(all)
		var layer: String
		
		init(name: String, description: String, category: String, mintLimit: UInt64, png: String, layer: String){ 
			RaptaAccessory.totalSupply = RaptaAccessory.totalSupply + 1
			self.id = RaptaAccessory.totalSupply
			self.name = name
			self.description = description
			self.category = category
			self.mintLimit = mintLimit
			self.png = png
			self.layer = layer
		}
		
		access(all)
		fun updatePNG(newPNG: String){ 
			self.png = newPNG
		}
		
		access(all)
		fun updateLayer(newLayer: String){ 
			self.layer = newLayer
		}
		
		access(all)
		fun updateDescription(newDescription: String){ 
			self.description = newDescription
		}
		
		access(all)
		fun updateCategory(newCategory: String){ 
			self.category = newCategory
		}
		
		access(all)
		fun updateName(newName: String){ 
			self.name = newName
		}
		
		access(all)
		fun updateMintLimit(newLimit: UInt64){ 
			self.mintLimit = newLimit
		}
	}
	
	access(all)
	resource TemplateCollection: TemplateCollectionPublic{ 
		access(all)
		var ownedTemplates: @{UInt64: RaptaAccessory.Template}
		
		init(){ 
			self.ownedTemplates <-{} 
		}
		
		access(all)
		fun deposit(template: @RaptaAccessory.Template){ 
			let id: UInt64 = template.id
			let oldTemplate <- self.ownedTemplates[id] <- template
			destroy oldTemplate
		}
		
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.ownedTemplates.keys
		}
		
		access(all)
		fun borrowAccessoryTemplate(id: UInt64): &RaptaAccessory.Template?{ 
			if self.ownedTemplates[id] != nil{ 
				let ref = (&self.ownedTemplates[id] as &RaptaAccessory.Template?)!
				return ref as! &RaptaAccessory.Template
			} else{ 
				return nil
			}
		}
	}
	
	//FUNCTIONS
	//Accessory Functions
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	fun getpngForAccessory(address: Address, accessoryId: UInt64): String?{ 
		let account = getAccount(address)
		if let collection = account.capabilities.get<&{RaptaAccessory.CollectionPublic}>(self.CollectionPublicPath).borrow<&{RaptaAccessory.CollectionPublic}>(){ 
			return (collection.borrowAccessory(id: accessoryId)!).getPNG()
		}
		return nil
	}
	
	access(all)
	fun getAccessory(address: Address, accessoryId: UInt64): AccessoryData?{ 
		let account = getAccount(address)
		if let collection = account.capabilities.get<&{RaptaAccessory.CollectionPublic}>(self.CollectionPublicPath).borrow<&{RaptaAccessory.CollectionPublic}>(){ 
			if let accessory = collection.borrowAccessory(id: accessoryId){ 
				return AccessoryData(id: accessoryId, templateId: (accessory!).templateId)
			}
		}
		return nil
	}
	
	access(all)
	fun getAccessories(address: Address): [AccessoryData]{ 
		var accessoryData: [AccessoryData] = []
		let account = getAccount(address)
		if let collection = account.capabilities.get<&{RaptaAccessory.CollectionPublic}>(self.CollectionPublicPath).borrow<&{RaptaAccessory.CollectionPublic}>(){ 
			for id in collection.getIDs(){ 
				var accessory = collection.borrowAccessory(id: id)
				accessoryData.append(AccessoryData(id: id, templateId: (accessory!).templateId))
			}
		}
		return accessoryData
	}
	
	access(account)
	fun mintAccessory(templateId: UInt64): @RaptaAccessory.NFT{ 
		let template: RaptaAccessory.TemplateData = RaptaAccessory.getAccessoryTemplate(id: templateId)!
		let totalMintedAccessories: UInt64 = RaptaAccessory.getTotalMintedAccessoriesByTemplate(id: templateId)!
		if totalMintedAccessories >= template.mintLimit{ 
			panic("this collection has reached it's limit")
		}
		if templateId <= 3{ 
			panic("accessories from these series are not mintable")
		}
		var accessory <- create NFT(templateId: templateId, royalties: Royalties(royalty: RaptaAccessory.royalties))
		emit Mint(id: accessory.id, templateId: templateId)
		return <-accessory
	}
	
	//Template Functions
	access(account)
	fun createEmptyTemplateCollection(): @RaptaAccessory.TemplateCollection{ 
		return <-create TemplateCollection()
	}
	
	access(all)
	fun getAccessoryTemplates(): [TemplateData]{ 
		var accessoryTemplateData: [TemplateData] = []
		if let templateCollection = self.account.capabilities.get<&{RaptaAccessory.TemplateCollectionPublic}>(self.TemplatePublicPath).borrow<&{RaptaAccessory.TemplateCollectionPublic}>(){ 
			for id in templateCollection.getIDs(){ 
				var template = templateCollection.borrowAccessoryTemplate(id: id)
				accessoryTemplateData.append(TemplateData(id: id, name: (template!).name, description: (template!).description, category: (template!).category, png: (template!).png, layer: (template!).layer, mintLimit: (template!).mintLimit))
			}
		}
		return accessoryTemplateData
	}
	
	access(all)
	view fun getAccessoryTemplate(id: UInt64): TemplateData?{ 
		if let templateCollection = self.account.capabilities.get<&{RaptaAccessory.TemplateCollectionPublic}>(self.TemplatePublicPath).borrow<&{RaptaAccessory.TemplateCollectionPublic}>(){ 
			if let template = templateCollection.borrowAccessoryTemplate(id: id){ 
				return TemplateData(id: id, name: (template!).name, description: (template!).description, category: (template!).category, png: (template!).png, layer: (template!).layer, mintLimit: (template!).mintLimit)
			}
		}
		return nil
	}
	
	access(all)
	view fun getTotalMintedAccessoriesByTemplate(id: UInt64): UInt64?{ 
		return RaptaAccessory.totalMintedAccessories[id]
	}
	
	access(contract)
	fun setTotalMintedAccessoriesByTemplate(id: UInt64, value: UInt64){ 
		RaptaAccessory.totalMintedAccessories[id] = value
	}
	
	access(account)
	fun initialAccessories(templateId: UInt64): @RaptaAccessory.NFT{ 
		pre{ 
			RaptaAccessory.getAccessoryTemplate(id: templateId) != nil:
				"Template doesn't exist"
			RaptaAccessory.getTotalMintedAccessoriesByTemplate(id: templateId)! < (RaptaAccessory.getAccessoryTemplate(id: templateId)!).mintLimit:
				"Cannot mint RaptaAccessory - mint limit reached"
		}
		let newNFT: @NFT <- create RaptaAccessory.NFT(templateId: templateId, royalties: Royalties(royalty: RaptaAccessory.royalties))
		emit Mint(id: newNFT.id, templateId: templateId)
		return <-newNFT
	}
	
	access(contract)
	fun starterTemplate(name: String, description: String, category: String, mintLimit: UInt64, png: String, layer: String): @RaptaAccessory.Template{ 
		var newTemplate <- create Template(name: name, description: description, category: category, mintLimit: mintLimit, png: png, layer: layer)
		emit TemplateCreated(id: newTemplate.id, name: newTemplate.name, category: newTemplate.category, mintLimit: newTemplate.mintLimit)
		RaptaAccessory.setTotalMintedAccessoriesByTemplate(id: newTemplate.id, value: 0)
		return <-newTemplate
	}
	
	access(account)
	fun createAccessoryTemplate(name: String, description: String, category: String, mintLimit: UInt64, png: String, layer: String){ 
		var newTemplate <- create Template(name: name, description: description, category: category, mintLimit: mintLimit, png: png, layer: layer)
		emit TemplateCreated(id: newTemplate.id, name: newTemplate.name, category: newTemplate.category, mintLimit: newTemplate.mintLimit)
		RaptaAccessory.setTotalMintedAccessoriesByTemplate(id: newTemplate.id, value: 0)
		(self.account.storage.borrow<&RaptaAccessory.TemplateCollection>(from: RaptaAccessory.TemplateStoragePath)!).deposit(template: <-newTemplate)
	}
	
	//INITIALIZER
	init(){ 
		//Accessory Init
		self.CollectionStoragePath = /storage/RaptaAccessoryCollection
		self.CollectionPublicPath = /public/RaptaAccessoryCollection
		self.account.storage.save<@{NonFungibleToken.Collection}>(<-RaptaAccessory.createEmptyCollection(nftType: Type<@RaptaAccessory.Collection>()), to: RaptaAccessory.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{RaptaAccessory.CollectionPublic}>(RaptaAccessory.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: RaptaAccessory.CollectionPublicPath)
		self.royalties = []
		self.royaltyCut = 0.01
		self.marketplaceCut = 0.05
		
		//Template Init
		self.TemplateStoragePath = /storage/RaptaTemplateCollection
		self.TemplatePublicPath = /public/RaptaTemplateCollection
		self.totalSupply = 0
		self.totalMintedAccessories ={} 
		self.account.storage.save<@RaptaAccessory.TemplateCollection>(<-RaptaAccessory.createEmptyTemplateCollection(), to: RaptaAccessory.TemplateStoragePath)
		var capability_2 = self.account.capabilities.storage.issue<&{RaptaAccessory.TemplateCollectionPublic}>(RaptaAccessory.TemplateStoragePath)
		self.account.capabilities.publish(capability_2, at: RaptaAccessory.TemplatePublicPath)
		let jacket <- self.starterTemplate(name: "DZN_ x rapta designer vest concept", description: "a customized piece of gear readily available to apply to your Rapta icon. this accessory is not redeemable in real life but serves as part of a starter back to familiarize you with the process of applying gear to your icon. enjoy.", category: "jacket", mintLimit: 444, png: "uri.png", layer: "DZNxRaptaVest.png")
		let pants <- self.starterTemplate(name: "DZN_ x rapta designer pants concept", description: "a customized piece of gear readily available to apply to your Rapta icon. this accessory is not redeemable in real life but serves as part of a starter back to familiarize you with the process of applying gear to your icon. enjoy.", category: "pants", mintLimit: 444, png: "uri.png", layer: "DZNxRaptaPants.png")
		let shoes <- self.starterTemplate(name: "AFOnes", description: "a customized piece of gear readily available to apply to your Rapta icon. this accessory is not redeemable in real life but serves as part of a starter back to familiarize you with the process of applying gear to your icon. enjoy.", category: "shoes", mintLimit: 444, png: "uri.png", layer: "AFOnes.png")
		(self.account.storage.borrow<&RaptaAccessory.TemplateCollection>(from: RaptaAccessory.TemplateStoragePath)!).deposit(template: <-jacket)
		(self.account.storage.borrow<&RaptaAccessory.TemplateCollection>(from: RaptaAccessory.TemplateStoragePath)!).deposit(template: <-pants)
		(self.account.storage.borrow<&RaptaAccessory.TemplateCollection>(from: RaptaAccessory.TemplateStoragePath)!).deposit(template: <-shoes)
		emit ContractInitialized()
	}
}
