// _____________________________________________________________________________
//	 _   _											__					  
//	 /  /|										  /	)				   /
// ---/| /-|----__---__---__----__----__----__-------/---------__---)__----__-/-
//   / |/  |  /___) (_ ` (_ ` /   ) /   ) /___)	 /		/   ) /   ) /   /  
// _/__/___|_(___ _(__)_(__)_(___(_(___/_(___ _____(____/___(___(_/_____(___/___
//									/										 
//								(_ /										  
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract MessageCard: NonFungibleToken{ 
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let TemplatesPublicPath: PublicPath
	
	access(all)
	let TemplatesPrivatePath: PrivatePath
	
	access(all)
	let TemplatesStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var totalTemplates: UInt64
	
	access(account)
	var thumbnailBaseUrl: String
	
	access(account)
	var description: String
	
	access(account)
	var royalties: MetadataViews.Royalties?
	
	access(account)
	var externalURLBase: String?
	
	access(account)
	var nftCollectionDisplay: MetadataViews.NFTCollectionDisplay?
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, templateId: UInt64)
	
	access(all)
	event Destroyed(id: UInt64)
	
	access(all)
	event UsedTemplateChanged(id: UInt64, templateId: UInt64)
	
	access(all)
	event TemplateCreated(templateId: UInt64, creator: Address, name: String, description: String)
	
	access(all)
	event TemplateDestroyed(templateId: UInt64, creator: Address, name: String)
	
	access(all)
	struct RenderResult{ 
		access(all)
		var dataType: String
		
		access(all)
		var data: AnyStruct
		
		access(all)
		var extraData:{ String: AnyStruct}
		
		init(dataType: String, data: AnyStruct, extraData:{ String: AnyStruct}){ 
			self.dataType = dataType
			self.data = data
			self.extraData = extraData
		}
	}
	
	access(all)
	struct interface IRenderer{ 
		access(all)
		fun render(params:{ String: AnyStruct}): RenderResult
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		var params:{ String: AnyStruct}
		
		access(all)
		var templatesCapability: Capability<&Templates>
		
		access(all)
		var templateId: UInt64
		
		access(account)
		fun updateParams(params:{ String: AnyStruct}){ 
			self.params = params
		}
		
		access(account)
		fun updateTemplate(templatesCapability: Capability<&Templates>, templateId: UInt64){ 
			pre{ 
				templateId != self.templateId:
					"Same templateId"
			}
			post{ 
				self.isValidTemplate():
					"Invalid template"
			}
			self.templatesCapability = templatesCapability
			self.templateId = templateId
			emit UsedTemplateChanged(id: self.id, templateId: self.templateId)
		}
		
		access(all)
		view fun isValidTemplate(): Bool{ 
			if let templates = self.templatesCapability.borrow(){ 
				if let template = templates.borrowPublicTemplateRef(templateId: self.templateId){ 
					return true
				}
			}
			return false
		}
		
		access(all)
		fun getRenderer():{ IRenderer}?{ 
			if let templates = self.templatesCapability.borrow(){ 
				if let template = templates.borrowPublicTemplateRef(templateId: self.templateId){ 
					return template.getRenderer()
				}
			}
			return nil
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			let views = [Type<MetadataViews.Display>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
			if MessageCard.royalties != nil{ 
				views.append(Type<MetadataViews.Royalties>())
			}
			if MessageCard.externalURLBase != nil{ 
				views.append(Type<MetadataViews.ExternalURL>())
			}
			if MessageCard.nftCollectionDisplay != nil{ 
				views.append(Type<MetadataViews.NFTCollectionDisplay>())
			}
			return views
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "#".concat(self.id.toString()), description: MessageCard.description, thumbnail: MetadataViews.HTTPFile(url: MessageCard.thumbnailBaseUrl.concat(self.id.toString())))
				case Type<MetadataViews.Royalties>():
					return MessageCard.royalties
				case Type<MetadataViews.ExternalURL>():
					if MessageCard.externalURLBase != nil{ 
						return MetadataViews.ExternalURL((MessageCard.externalURLBase!).concat((self.owner!).address.toString()).concat("/card/").concat(self.id.toString()))
					}
					return nil
				case Type<MetadataViews.Traits>():
					if let renderer = self.getRenderer(){ 
						let renderResult = renderer.render(params: self.params)
						return MetadataViews.Traits([MetadataViews.Trait(name: "dataType", value: renderResult.dataType, displayType: nil, rarity: nil), MetadataViews.Trait(name: "data", value: renderResult.data, displayType: nil, rarity: nil), MetadataViews.Trait(name: "extraData", value: renderResult.extraData, displayType: nil, rarity: nil)])
					}
					return nil
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: MessageCard.CollectionStoragePath, publicPath: MessageCard.CollectionPublicPath, publicCollection: Type<&Collection>(), publicLinkedType: Type<&Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-MessageCard.createEmptyCollection(nftType: Type<@MessageCard.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					return MessageCard.nftCollectionDisplay
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(params:{ String: AnyStruct}, templatesCapability: Capability<&Templates>, templateId: UInt64){ 
			post{ 
				self.isValidTemplate():
					"Invalid template"
			}
			MessageCard.totalSupply = MessageCard.totalSupply + 1
			self.id = MessageCard.totalSupply
			self.params = params
			self.templatesCapability = templatesCapability
			self.templateId = templateId
			emit Minted(id: self.id, templateId: templateId)
		}
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
		fun borrowMessageCard(id: UInt64): &MessageCard.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow MessageCard reference"
			}
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
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @MessageCard.NFT
			let id: UInt64 = token.id
			self.ownedNFTs[id] <-! token
			emit Deposit(id: id, to: self.owner?.address)
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
		fun borrowMessageCard(id: UInt64): &MessageCard.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)! as! &MessageCard.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)! as! &MessageCard.NFT
			return nft as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun updateParams(id: UInt64, params:{ String: AnyStruct}){ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)! as! &MessageCard.NFT
			nft.updateParams(params: params)
		}
		
		access(all)
		fun updateTemplate(id: UInt64, templatesCapability: Capability<&Templates>, templateId: UInt64){ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)! as! &MessageCard.NFT
			nft.updateTemplate(templatesCapability: templatesCapability, templateId: templateId)
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
	resource interface TemplatePublic{ 
		access(all)
		let templateId: UInt64
		
		access(all)
		fun getRenderer():{ IRenderer}
	}
	
	access(all)
	resource Template: TemplatePublic{ 
		access(all)
		let templateId: UInt64
		
		access(all)
		let creator: Address
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		var renderer:{ IRenderer}
		
		access(all)
		fun getRenderer():{ IRenderer}{ 
			return self.renderer
		}
		
		access(all)
		fun updateRenderer(renderer:{ IRenderer}){ 
			self.renderer = renderer
		}
		
		init(creator: Address, name: String, description: String, renderer:{ IRenderer}){ 
			MessageCard.totalTemplates = MessageCard.totalTemplates + 1
			self.templateId = MessageCard.totalTemplates
			self.creator = creator
			self.name = name
			self.description = description
			self.renderer = renderer
			emit TemplateCreated(templateId: self.templateId, creator: self.creator, name: self.name, description: self.description)
		}
	}
	
	access(all)
	resource interface TemplatesPublic{ 
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowPublicTemplateRef(templateId: UInt64): &Template?
		
		access(account)
		fun borrowTemplatesRef(): &Templates
	}
	
	access(all)
	resource Templates: TemplatesPublic{ 
		access(account)
		var templates: @{UInt64: Template}
		
		access(all)
		fun createTemplate(name: String, description: String, renderer:{ IRenderer}): UInt64{ 
			let template <- create Template(creator: (self.owner!).address, name: name, description: description, renderer: renderer)
			let templateId = template.templateId
			self.templates[templateId] <-! template
			return templateId
		}
		
		access(all)
		fun deleteTemplate(templateId: UInt64){ 
			let template <- self.templates.remove(key: templateId)
			assert(template != nil, message: "Not Found")
			destroy template
		}
		
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.templates.keys
		}
		
		access(all)
		view fun borrowPublicTemplateRef(templateId: UInt64): &Template?{ 
			return &self.templates[templateId] as &Template?
		}
		
		access(account)
		fun borrowTemplatesRef(): &Templates{ 
			return &self as &Templates
		}
		
		access(all)
		fun borrowTemplateRef(templateId: UInt64): &Template?{ 
			return &self.templates[templateId] as &Template?
		}
		
		init(){ 
			self.templates <-{} 
		}
	}
	
	access(all)
	resource Maintainer{ 
		access(all)
		fun setThumbnailBaseUrl(url: String){ 
			MessageCard.thumbnailBaseUrl = url
		}
		
		access(all)
		fun setDescription(description: String){ 
			MessageCard.description = description
		}
		
		access(all)
		fun setRoyalties(royalties: MetadataViews.Royalties){ 
			MessageCard.royalties = royalties
		}
		
		access(all)
		fun setExternalURLBase(externalURLBase: String){ 
			MessageCard.externalURLBase = externalURLBase
		}
		
		access(all)
		fun setNFTCollectionDisplay(nftCollectionDisplay: MetadataViews.NFTCollectionDisplay){ 
			MessageCard.nftCollectionDisplay = nftCollectionDisplay
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	fun createEmptyTemplateCollection(): @Templates{ 
		return <-create Templates()
	}
	
	access(all)
	fun mint(params:{ String: AnyStruct}, templatesCapability: Capability<&Templates>, templateId: UInt64): @NFT{ 
		return <-create NFT(params: params, templatesCapability: templatesCapability, templateId: templateId)
	}
	
	init(){ 
		self.CollectionPublicPath = /public/MessageCardCollectionPublicPath
		self.CollectionPrivatePath = /private/MessageCardCollectionPrivatePath
		self.CollectionStoragePath = /storage/MessageCardCollectionStoragePath
		self.TemplatesPublicPath = /public/MessageCardTemplatesPublicPath
		self.TemplatesPrivatePath = /private/MessageCardTemplatesPrivatePath
		self.TemplatesStoragePath = /storage/MessageCardTemplatesStoragePath
		self.totalSupply = 0
		self.totalTemplates = 0
		self.thumbnailBaseUrl = "https://i.imgur.com/QbZ5SVO.png#"
		self.description = "You can create or use any template to create a permanent digital message card."
		self.royalties = nil
		self.externalURLBase = nil
		self.nftCollectionDisplay = nil
		self.account.storage.save(<-create Maintainer(), to: /storage/MessageCardMaintainer)
		self.account.storage.save(<-create Collection(), to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&MessageCard.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
