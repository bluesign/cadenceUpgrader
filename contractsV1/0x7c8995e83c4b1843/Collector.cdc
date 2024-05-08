// SPDX-License-Identifier: UNLICENSED
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Collector: NonFungibleToken{ 
	// Emitted when the Collector contract is created
	access(all)
	event ContractInitialized()
	
	// Emitted when a new Set is created
	access(all)
	event SetCreated(id: UInt64, name: String)
	
	// Emitted when a Set is locked, meaning Set data cannot be updated
	access(all)
	event SetLocked(id: UInt64, name: String)
	
	// Emitted when a Set is unlocked, meaning Set data can be updated
	access(all)
	event SetUnlocked(id: UInt64, name: String)
	
	// Emitted when a Set is updated
	access(all)
	event SetUpdated(id: UInt64, name: String)
	
	// Emitted when a new Template is created
	access(all)
	event TemplateCreated(id: UInt64, name: String)
	
	// Emitted when a Template is locked, meaning Template data cannot be updated
	access(all)
	event TemplateLocked(id: UInt64, name: String)
	
	// Emitted when a Template is updated
	access(all)
	event TemplateUpdated(id: UInt64, name: String)
	
	// Emitted when a Template is added to a Set
	access(all)
	event TemplateAddedToSet(id: UInt64, name: String, setID: UInt64, setName: String)
	
	// Emitted when an NFT is minted
	access(all)
	event Minted(id: UInt64, templateID: UInt64, setID: UInt64)
	
	// Emitted when an NFT is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when an NFT is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	// The total number of Collector NFT that have been minted
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var nextTemplateID: UInt64
	
	access(all)
	var nextSetID: UInt64
	
	// Variable size dictionary of Template structs
	access(self)
	var Templates:{ UInt64: Template}
	
	// Variable size dictionary of SetData structs
	access(self)
	var SetsData:{ UInt64: SetData}
	
	// Variable size dictionary of Set resources
	access(self)
	var sets: @{UInt64: Set}
	
	// An Template is a Struct that holds data associated with a specific NFT
	access(all)
	struct Template{ 
		access(all)
		let id: UInt64
		
		access(all)
		var name: String
		
		access(all)
		var description: String
		
		access(all)
		var image: String
		
		access(all)
		var locked: Bool
		
		access(all)
		var addedToSet: UInt64
		
		access(self)
		var metadata:{ String: AnyStruct}
		
		init(id: UInt64, name: String, description: String, image: String, metadata:{ String: AnyStruct}){ 
			pre{ 
				metadata.length != 0:
					"New template metadata cannot be empty"
			}
			self.id = id
			self.name = name
			self.description = description
			self.image = image
			self.metadata = metadata
			self.locked = false
			self.addedToSet = 0
			Collector.nextTemplateID = Collector.nextTemplateID + 1
			emit TemplateCreated(id: self.id, name: self.name)
		}
		
		access(all)
		fun updateName(newName: String){ 
			pre{ 
				self.locked == false:
					"Cannot update name: template is locked"
			}
			self.name = newName
			emit TemplateUpdated(id: self.id, name: self.name)
		}
		
		access(all)
		fun updateDescription(newDescription: String){ 
			pre{ 
				self.locked == false:
					"Cannot update description: template is locked"
			}
			self.description = newDescription
			emit TemplateUpdated(id: self.id, name: self.name)
		}
		
		access(all)
		fun updateImage(newImage: String){ 
			pre{ 
				self.locked == false:
					"Cannot update image: template is locked"
			}
			self.image = newImage
			emit TemplateUpdated(id: self.id, name: self.name)
		}
		
		access(all)
		fun updateMetadata(newMetadata:{ String: AnyStruct}){ 
			pre{ 
				self.locked == false:
					"Cannot update metadata: template is locked"
				newMetadata.length != 0:
					"New template metadata cannot be empty"
			}
			self.metadata = newMetadata
			emit TemplateUpdated(id: self.id, name: self.name)
		}
		
		access(all)
		fun markAddedToSet(setID: UInt64){ 
			pre{ 
				self.addedToSet == 0:
					"Template is already to a set"
			}
			self.addedToSet = setID
			let setName = (Collector.SetsData[setID]!).name
			emit TemplateAddedToSet(id: self.id, name: self.name, setID: setID, setName: setName)
		}
		
		access(all)
		fun lock(){ 
			pre{ 
				self.locked == false:
					"Template is already locked"
			}
			self.locked = true
			emit TemplateLocked(id: self.id, name: self.name)
		}
		
		access(all)
		fun getMetadata():{ String: AnyStruct}{ 
			return self.metadata
		}
	}
	
	// An SetData is a Struct that holds data associated with a specific Set
	access(all)
	struct SetData{ 
		access(all)
		let id: UInt64
		
		access(all)
		var name: String
		
		access(all)
		var description: String
		
		access(all)
		var image: String
		
		access(self)
		var metadata:{ String: AnyStruct}
		
		access(all)
		var maxSize: UInt64?
		
		init(id: UInt64, name: String, description: String, image: String, metadata:{ String: AnyStruct}, maxSize: UInt64?){ 
			self.id = id
			self.name = name
			self.description = description
			self.image = image
			self.metadata = metadata
			self.maxSize = maxSize
		}
		
		access(all)
		fun getMetadata():{ String: AnyStruct}{ 
			return self.metadata
		}
	}
	
	/* DEPRECATED - DO NOT USE */
	access(all)
	struct CollectorMetadataView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let image: String
		
		access(all)
		let externalUrl: String?
		
		access(all)
		let bgArchitecture: String?
		
		access(all)
		let bgPanelling: String?
		
		access(all)
		let bgArchitecturalSupport: String?
		
		access(all)
		let bgLighting: String?
		
		access(all)
		let wineStorageContainer: String?
		
		access(all)
		let wineBottle: String?
		
		access(all)
		let wineBottleClosure: String?
		
		access(all)
		let wineBottleGlassware: String?
		
		access(all)
		let setID: UInt64
		
		access(all)
		let templateID: UInt64
		
		access(all)
		let serialNumber: UInt64
		
		access(all)
		let mintingDate: UFix64
		
		init(id: UInt64, name: String, description: String, image: String, externalUrl: String?, bgArchitecture: String?, bgPanelling: String?, bgArchitecturalSupport: String?, bgLighting: String?, wineStorageContainer: String?, wineBottle: String?, wineBottleClosure: String?, wineBottleGlassware: String?, setID: UInt64, templateID: UInt64, serialNumber: UInt64, mintingDate: UFix64){ 
			self.id = id
			self.name = name
			self.description = description
			self.image = image
			self.externalUrl = externalUrl
			self.bgArchitecture = bgArchitecture
			self.bgPanelling = bgPanelling
			self.bgArchitecturalSupport = bgArchitecturalSupport
			self.bgLighting = bgLighting
			self.wineStorageContainer = wineStorageContainer
			self.wineBottle = wineBottle
			self.wineBottleClosure = wineBottleClosure
			self.wineBottleGlassware = wineBottleGlassware
			self.setID = setID
			self.templateID = templateID
			self.serialNumber = serialNumber
			self.mintingDate = mintingDate
		}
	}
	
	// This is an implementation of a custom metadata view for Cuvée Collective
	access(all)
	struct CollectorMetadataViewV2{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let image: String
		
		access(all)
		let externalUrl: String?
		
		access(all)
		let architecture: String?
		
		access(all)
		let panelling: String?
		
		access(all)
		let visualElements: String?
		
		access(all)
		let ambience: String?
		
		access(all)
		let wineStorage: String?
		
		access(all)
		let wineBox: String?
		
		access(all)
		let bottle: String?
		
		access(all)
		let setID: UInt64
		
		access(all)
		let templateID: UInt64
		
		access(all)
		let serialNumber: UInt64
		
		access(all)
		let mintingDate: UFix64
		
		init(id: UInt64, name: String, description: String, image: String, externalUrl: String?, architecture: String?, panelling: String?, visualElements: String?, ambience: String?, wineStorage: String?, wineBox: String?, bottle: String?, setID: UInt64, templateID: UInt64, serialNumber: UInt64, mintingDate: UFix64){ 
			self.id = id
			self.name = name
			self.description = description
			self.image = image
			self.externalUrl = externalUrl
			self.architecture = architecture
			self.panelling = panelling
			self.visualElements = visualElements
			self.ambience = ambience
			self.wineStorage = wineStorage
			self.wineBox = wineBox
			self.bottle = bottle
			self.setID = setID
			self.templateID = templateID
			self.serialNumber = serialNumber
			self.mintingDate = mintingDate
		}
	}
	
	// A resource that represents the Collector NFT
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let setID: UInt64
		
		access(all)
		let templateID: UInt64
		
		access(all)
		let serialNumber: UInt64
		
		access(all)
		let mintingDate: UFix64
		
		init(id: UInt64, templateID: UInt64, serialNumber: UInt64){ 
			pre{ 
				Collector.getTemplate(id: templateID) != nil:
					"Template not found"
			}
			let setID = (Collector.getTemplate(id: templateID)!).addedToSet
			self.id = id
			self.setID = setID
			self.templateID = templateID
			self.serialNumber = serialNumber
			self.mintingDate = getCurrentBlock().timestamp
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Traits>(), Type<CollectorMetadataViewV2>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.getTemplate().name, description: self.getTemplate().description, thumbnail: MetadataViews.HTTPFile(url: self.getTemplate().image))
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.serialNumber)
				case Type<MetadataViews.Royalties>():
					var royalties: [MetadataViews.Royalty] = []
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.ExternalURL>():
					let externalUrl = self.getMetadata()["external_url"] ?? ""
					return MetadataViews.ExternalURL(externalUrl as! String)
				case Type<MetadataViews.Editions>():
					let setData = Collector.SetsData[self.setID]!
					let editionInfo = MetadataViews.Edition(name: setData.name, number: self.serialNumber, max: setData.maxSize)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Traits>():
					let excludedTraits = ["external_url", "bottle"]
					let traitsView = MetadataViews.dictToTraits(dict: self.getMetadata(), excludedNames: excludedTraits)
					
					// mintingDate is a unix timestamp, we should mark it with a displayType so platforms know how to show it
					let mintingDateTrait = MetadataViews.Trait(name: "minting_date", value: self.mintingDate, displayType: "Date", rarity: nil)
					traitsView.addTrait(mintingDateTrait)
					return traitsView
				case Type<CollectorMetadataViewV2>():
					let externalUrl = self.getMetadata()["external_url"] ?? ""
					let architecture = self.getMetadata()["architecture"] ?? ""
					let panelling = self.getMetadata()["panelling"] ?? ""
					let visualElements = self.getMetadata()["visual_elements"] ?? ""
					let ambience = self.getMetadata()["ambience"] ?? ""
					let wineStorage = self.getMetadata()["wine_storage"] ?? ""
					let wineBox = self.getMetadata()["wine_box"] ?? ""
					let bottle = self.getMetadata()["bottle"] ?? ""
					return CollectorMetadataViewV2(id: self.id, name: self.getTemplate().name, description: self.getTemplate().description, image: self.getTemplate().image, externalUrl: externalUrl as? String, architecture: architecture as? String, panelling: panelling as? String, visualElements: visualElements as? String, ambience: ambience as? String, wineStorage: wineStorage as? String, wineBox: wineBox as? String, bottle: bottle as? String, setID: self.setID, templateID: self.templateID, serialNumber: self.serialNumber, mintingDate: self.mintingDate)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Collector.CollectionStoragePath, publicPath: Collector.CollectionPublicPath, publicCollection: Type<&Collector.Collection>(), publicLinkedType: Type<&Collector.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Collector.createEmptyCollection(nftType: Type<@Collector.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let externalUrl = "https://www.cuveecollective.com/marketplace/collections/collector"
					return MetadataViews.NFTCollectionDisplay(name: "Cuv\u{e9}e Collective - Collector", description: "Our genesis collection for Cuv\u{e9}e Collective, called The Collector. The Collector NFT gives the NFT holder access to all future NFT drops 24 hours before they are open to the public, in addition to core Cuv\u{e9}e Collective benefits to include members-only discord channels, community voting status, concierge services, Sommelier hotline, and airdrops, events, and giveaways.", externalURL: MetadataViews.ExternalURL(externalUrl), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://assets.test-cuveecollective.com/nfts/collector/nft_collector_1.jpg"), mediaType: "image/jpeg"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://assets.cuveecollective.com/nfts/collector/nft_collector_1_banner.jpg"), mediaType: "image/jpeg"), socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/cuveecollective"), "instagram": MetadataViews.ExternalURL("https://twitter.com/cuveecollectivehq"), "discord": MetadataViews.ExternalURL("https://cuveecollective.com/discord")})
			}
			return nil
		}
		
		access(all)
		fun getSetData(): SetData{ 
			return Collector.SetsData[self.setID]!
		}
		
		access(all)
		view fun getTemplate(): Template{ 
			return Collector.Templates[self.templateID]!
		}
		
		access(all)
		fun getMetadata():{ String: AnyStruct}{ 
			return (Collector.Templates[self.templateID]!).getMetadata()
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface NFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowCollector(id: UInt64): &Collector.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow collector reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: NFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Collector.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		fun batchDeposit(collection: @Collection){ 
			let keys = collection.getIDs()
			for key in keys{ 
				self.deposit(token: <-collection.withdraw(withdrawID: key))
			}
			destroy collection
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref!
		}
		
		access(all)
		fun borrowCollector(id: UInt64): &Collector.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref! as! &Collector.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			let exampleNFT = nft! as! &Collector.NFT
			return exampleNFT as &{ViewResolver.Resolver}
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
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// A Set is special resource type that contains functions to mint Collector NFTs, 
	// add Templates, update Templates and Set metadata, and lock Sets and Templates.
	access(all)
	resource Set{ 
		access(all)
		let id: UInt64
		
		access(all)
		var locked: Bool
		
		access(all)
		var isPublic: Bool
		
		access(all)
		var nextSerialNumber: UInt64
		
		access(self)
		var templateIDs: [UInt64]
		
		access(self)
		var availableTemplateIDs: [UInt64]
		
		init(name: String, description: String, image: String, metadata:{ String: AnyStruct}, maxSize: UInt64?){ 
			pre{ 
				metadata.length != 0:
					"Set metadata cannot be empty"
			}
			self.id = Collector.nextSetID
			self.locked = false
			self.isPublic = false
			self.nextSerialNumber = 1
			self.templateIDs = []
			self.availableTemplateIDs = []
			Collector.SetsData[self.id] = SetData(id: self.id, name: name, description: description, image: image, metadata: metadata, maxSize: maxSize)
			Collector.nextSetID = Collector.nextSetID + 1
			emit SetCreated(id: self.id, name: name)
		}
		
		access(all)
		fun updateImage(newImage: String){ 
			pre{ 
				self.locked == false:
					"Cannot update image: set is locked"
			}
			let oldData = Collector.SetsData[self.id]!
			Collector.SetsData[self.id] = SetData(id: self.id, name: oldData.name, description: oldData.description, image: newImage, metadata: oldData.getMetadata(), maxSize: oldData.maxSize)
			emit SetUpdated(id: self.id, name: oldData.name)
		}
		
		access(all)
		fun updateMetadata(newMetadata:{ String: AnyStruct}){ 
			pre{ 
				self.locked == false:
					"Cannot update metadata: set is locked"
				newMetadata.length != 0:
					"New set metadata cannot be empty"
			}
			let oldData = Collector.SetsData[self.id]!
			Collector.SetsData[self.id] = SetData(id: self.id, name: oldData.name, description: oldData.description, image: oldData.image, metadata: newMetadata, maxSize: oldData.maxSize)
			emit SetUpdated(id: self.id, name: oldData.name)
		}
		
		access(all)
		fun makePublic(){ 
			pre{ 
				self.isPublic == false:
					"Set is already public"
			}
			self.isPublic = true
		}
		
		access(all)
		fun makePrivate(){ 
			pre{ 
				self.isPublic == true:
					"Set is already private"
			}
			self.isPublic = false
		}
		
		access(all)
		fun addTemplate(id: UInt64){ 
			pre{ 
				Collector.Templates[id] != nil:
					"Template doesn't exist"
				!self.locked:
					"Cannot add template: set is locked"
				!self.templateIDs.contains(id):
					"Cannot add template: template is already added to the set"
				!((Collector.Templates[id]!).addedToSet != 0):
					"Cannot add template: template is already added to another set"
			}
			if let maxSize = (Collector.SetsData[self.id]!).maxSize{ 
				if UInt64(self.templateIDs.length) >= maxSize{ 
					panic("Set is full")
				}
			}
			self.templateIDs.append(id)
			self.availableTemplateIDs.append(id)
			(			 
			 // This function will automatically emit TemplateAddedToSet event
			 Collector.Templates[id]!).markAddedToSet(setID: self.id)
		}
		
		access(all)
		fun addTemplates(templateIDs: [UInt64]){ 
			for templateID in templateIDs{ 
				self.addTemplate(id: templateID)
			}
		}
		
		access(all)
		fun lock(){ 
			pre{ 
				self.locked == false:
					"Set is already locked"
			}
			self.locked = true
			emit SetLocked(id: self.id, name: (Collector.SetsData[self.id]!).name)
		}
		
		access(all)
		fun unlock(){ 
			pre{ 
				self.locked == true:
					"Set is already unlocked"
			}
			self.locked = false
			emit SetUnlocked(id: self.id, name: (Collector.SetsData[self.id]!).name)
		}
		
		access(all)
		fun mintNFT(): @NFT{ 
			let templateID = self.availableTemplateIDs[0]
			let newNFT: @NFT <- create Collector.NFT(id: Collector.totalSupply + 1, templateID: templateID, serialNumber: self.nextSerialNumber)
			Collector.totalSupply = Collector.totalSupply + 1
			self.nextSerialNumber = self.nextSerialNumber + 1
			self.availableTemplateIDs.remove(at: 0)
			emit Minted(id: newNFT.id, templateID: newNFT.templateID, setID: newNFT.setID)
			return <-newNFT
		}
		
		access(all)
		fun updateTemplateName(id: UInt64, newName: String){ 
			pre{ 
				Collector.Templates[id] != nil:
					"Template doesn't exist"
				self.templateIDs.contains(id):
					"Cannot edit template: template is not part of this set"
				!self.locked:
					"Cannot edit template: set is locked"
			}
			(			 
			 // This function will automatically emit TemplateUpdated event
			 Collector.Templates[id]!).updateName(newName: newName)
		}
		
		access(all)
		fun updateTemplateDescription(id: UInt64, newDescription: String){ 
			pre{ 
				Collector.Templates[id] != nil:
					"Template doesn't exist"
				self.templateIDs.contains(id):
					"Cannot edit template: template is not part of this set"
				!self.locked:
					"Cannot edit template: set is locked"
			}
			(			 
			 // This function will automatically emit TemplateUpdated event
			 Collector.Templates[id]!).updateDescription(newDescription: newDescription)
		}
		
		access(all)
		fun updateTemplateImage(id: UInt64, newImage: String){ 
			pre{ 
				Collector.Templates[id] != nil:
					"Template doesn't exist"
				self.templateIDs.contains(id):
					"Cannot edit template: template is not part of this set"
				!self.locked:
					"Cannot edit template: set is locked"
			}
			(			 
			 // This function will automatically emit TemplateUpdated event
			 Collector.Templates[id]!).updateImage(newImage: newImage)
		}
		
		access(all)
		fun updateTemplateMetadata(id: UInt64, newMetadata:{ String: AnyStruct}){ 
			pre{ 
				Collector.Templates[id] != nil:
					"Template doesn't exist"
				self.templateIDs.contains(id):
					"Cannot edit template: template is not part of this set"
				!self.locked:
					"Cannot edit template: set is locked"
			}
			(			 
			 // This function will automatically emit TemplateUpdated event
			 Collector.Templates[id]!).updateMetadata(newMetadata: newMetadata)
		}
		
		access(all)
		fun lockTemplate(id: UInt64){ 
			pre{ 
				Collector.Templates[id] != nil:
					"Template doesn't exist"
				self.templateIDs.contains(id):
					"Cannot lock template: template is not part of this set"
				!self.locked:
					"Cannot lock template: set is locked"
			}
			(			 
			 // This function will automatically emit TemplateLocked event
			 Collector.Templates[id]!).lock()
		}
		
		access(all)
		fun getMetadata():{ String: AnyStruct}{ 
			return (Collector.SetsData[self.id]!).getMetadata()
		}
		
		access(all)
		fun getAvailableTemplateIDs(): [UInt64]{ 
			return self.availableTemplateIDs
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, setID: UInt64){ 
			let set = self.borrowSet(id: setID)
			if set.getAvailableTemplateIDs().length == 0{ 
				panic("Set is empty")
			}
			recipient.deposit(token: <-set.mintNFT())
		}
		
		access(all)
		fun createTemplate(name: String, description: String, image: String, metadata:{ String: AnyStruct}): UInt64{ 
			let templateID = Collector.nextTemplateID
			
			// This function will automatically emit TemplateCreated event
			Collector.Templates[templateID] = Template(id: templateID, name: name, description: description, image: image, metadata: metadata)
			return templateID
		}
		
		access(all)
		fun updateTemplateName(id: UInt64, newName: String){ 
			pre{ 
				Collector.Templates.containsKey(id) != nil:
					"Template doesn't exits"
			}
			(			 
			 // This function will automatically emit TemplateUpdated event
			 Collector.Templates[id]!).updateName(newName: newName)
		}
		
		access(all)
		fun updateTemplateDescription(id: UInt64, newDescription: String){ 
			pre{ 
				Collector.Templates.containsKey(id) != nil:
					"Template doesn't exits"
			}
			(			 
			 // This function will automatically emit TemplateUpdated event
			 Collector.Templates[id]!).updateDescription(newDescription: newDescription)
		}
		
		access(all)
		fun updateTemplateImage(id: UInt64, newImage: String){ 
			pre{ 
				Collector.Templates.containsKey(id) != nil:
					"Template doesn't exits"
			}
			(			 
			 // This function will automatically emit TemplateUpdated event
			 Collector.Templates[id]!).updateImage(newImage: newImage)
		}
		
		access(all)
		fun updateTemplateMetadata(id: UInt64, newMetadata:{ String: String}){ 
			pre{ 
				Collector.Templates.containsKey(id) != nil:
					"Template doesn't exits"
			}
			(			 
			 // This function will automatically emit TemplateUpdated event
			 Collector.Templates[id]!).updateMetadata(newMetadata: newMetadata)
		}
		
		access(all)
		fun lockTemplate(id: UInt64){ 
			pre{ 
				Collector.Templates.containsKey(id) != nil:
					"Template doesn't exits"
			}
			(			 
			 // This function will automatically emit TemplateLocked event
			 Collector.Templates[id]!).lock()
		}
		
		access(all)
		fun createSet(name: String, description: String, image: String, metadata:{ String: String}, maxSize: UInt64?){ 
			var newSet <- create Set(name: name, description: description, image: image, metadata: metadata, maxSize: maxSize)
			Collector.sets[newSet.id] <-! newSet
		}
		
		access(all)
		fun borrowSet(id: UInt64): &Set{ 
			pre{ 
				Collector.sets[id] != nil:
					"Cannot borrow set: set doesn't exist"
			}
			let ref = &Collector.sets[id] as &Set?
			return ref!
		}
		
		access(all)
		fun updateSetImage(id: UInt64, newImage: String){ 
			let set = self.borrowSet(id: id)
			set.updateImage(newImage: newImage)
		}
		
		access(all)
		fun updateSetMetadata(id: UInt64, newMetadata:{ String: AnyStruct}){ 
			let set = self.borrowSet(id: id)
			set.updateMetadata(newMetadata: newMetadata)
		}
	}
	
	access(all)
	view fun getTemplate(id: UInt64): Collector.Template?{ 
		return self.Templates[id]
	}
	
	access(all)
	fun getTemplates():{ UInt64: Collector.Template}{ 
		return self.Templates
	}
	
	access(all)
	fun getSetIDs(): [UInt64]{ 
		return self.sets.keys
	}
	
	access(all)
	fun getSetData(id: UInt64): Collector.SetData?{ 
		return Collector.SetsData[id]
	}
	
	access(all)
	fun getSetsData():{ UInt64: Collector.SetData}{ 
		return self.SetsData
	}
	
	access(all)
	fun getSetSize(id: UInt64): UInt64{ 
		pre{ 
			self.sets[id] != nil:
				"Cannot borrow set: set doesn't exist"
		}
		let set = &self.sets[id] as &Set?
		return (set!).nextSerialNumber - 1
	}
	
	access(all)
	fun getAvailableTemplateIDsInSet(id: UInt64): [UInt64]{ 
		pre{ 
			self.sets[id] != nil:
				"Cannot borrow set: set doesn't exist"
		}
		let set = &self.sets[id] as &Set?
		return (set!).getAvailableTemplateIDs()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/CollectorCollection
		self.CollectionPublicPath = /public/CollectorCollection
		self.AdminStoragePath = /storage/CollectorAdmin
		self.AdminPrivatePath = /private/CollectorAdminUpgrade
		self.totalSupply = 0
		self.nextTemplateID = 1
		self.nextSetID = 1
		self.sets <-{} 
		self.SetsData ={} 
		self.Templates ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Collector.Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath) ?? panic("Could not get a capability to the admin")
		emit ContractInitialized()
	}
}
