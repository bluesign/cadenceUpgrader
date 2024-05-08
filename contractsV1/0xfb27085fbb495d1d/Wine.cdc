// SPDX-License-Identifier: UNLICENSED
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Wine: NonFungibleToken{ 
	// Emitted when the Wine contract is created
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
	
	// The total number of Wine NFT that have been minted
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
		var maxSupply: UInt64
		
		access(all)
		var locked: Bool
		
		access(all)
		var addedToSet: UInt64
		
		access(self)
		var metadata:{ String: AnyStruct}
		
		init(id: UInt64, name: String, description: String, image: String, maxSupply: UInt64, metadata:{ String: AnyStruct}){ 
			pre{ 
				maxSupply > 0:
					"Supply must be more than zero"
				metadata.length != 0:
					"New template metadata cannot be empty"
			}
			self.id = id
			self.name = name
			self.description = description
			self.image = image
			self.metadata = metadata
			self.maxSupply = maxSupply
			self.locked = false
			self.addedToSet = 0
			Wine.nextTemplateID = Wine.nextTemplateID + 1
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
		fun updateMaxSupply(newMaxSupply: UInt64){ 
			pre{ 
				self.locked == false:
					"Cannot update image: template is locked"
				self.maxSupply > newMaxSupply:
					"Cannot reduce max supply"
			}
			self.maxSupply = newMaxSupply
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
			let setName = (Wine.SetsData[setID]!).name
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
		
		init(id: UInt64, name: String, description: String, image: String, metadata:{ String: AnyStruct}){ 
			self.id = id
			self.name = name
			self.description = description
			self.image = image
			self.metadata = metadata
		}
		
		access(all)
		fun getMetadata():{ String: AnyStruct}{ 
			return self.metadata
		}
	}
	
	// A resource that represents the Wine NFT
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let setID: UInt64
		
		access(all)
		let templateID: UInt64
		
		access(all)
		let editionNumber: UInt64
		
		access(all)
		let serialNumber: UInt64
		
		access(all)
		let mintingDate: UFix64
		
		init(id: UInt64, templateID: UInt64, editionNumber: UInt64, serialNumber: UInt64){ 
			pre{ 
				Wine.getTemplate(id: templateID) != nil:
					"Template not found"
			}
			let setID = (Wine.getTemplate(id: templateID)!).addedToSet
			self.id = id
			self.setID = setID
			self.templateID = templateID
			self.editionNumber = editionNumber
			self.serialNumber = serialNumber
			self.mintingDate = getCurrentBlock().timestamp
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Traits>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					let nftName = self.getTemplate().name.concat(" #").concat(self.editionNumber.toString())
					return MetadataViews.Display(name: nftName, description: self.getTemplate().description, thumbnail: MetadataViews.HTTPFile(url: self.getTemplate().image))
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.serialNumber)
				case Type<MetadataViews.Royalties>():
					var royalties: [MetadataViews.Royalty] = []
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(self.getExternalUrl())
				case Type<MetadataViews.Editions>():
					let template = Wine.Templates[self.templateID]!
					let editionInfo = MetadataViews.Edition(name: template.name, number: self.editionNumber, max: template.maxSupply)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Traits>():
					let excludedTraits = ["external_base_url"]
					let traitsView = MetadataViews.dictToTraits(dict: self.getMetadata(), excludedNames: excludedTraits)
					
					// mintingDate is a unix timestamp, we should mark it with a displayType so platforms know how to show it
					let mintingDateTrait = MetadataViews.Trait(name: "minting_date", value: self.mintingDate, displayType: "Date", rarity: nil)
					traitsView.addTrait(mintingDateTrait)
					return traitsView
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Wine.CollectionStoragePath, publicPath: Wine.CollectionPublicPath, publicCollection: Type<&Wine.Collection>(), publicLinkedType: Type<&Wine.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Wine.createEmptyCollection(nftType: Type<@Wine.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let setData = Wine.SetsData[self.setID]!
					let squareImageUrl = setData.getMetadata()["image.media_type"] as! String?
					return MetadataViews.NFTCollectionDisplay(name: setData.name, description: setData.description, externalURL: MetadataViews.ExternalURL((setData.getMetadata()["external_url"] as! String?)!), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: setData.image), mediaType: squareImageUrl ?? "image/jpeg"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: (setData.getMetadata()["banner_image.url"] as! String?)!), mediaType: (setData.getMetadata()["banner_image.media_type"] as! String?)!), socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/cuveecollective"), "instagram": MetadataViews.ExternalURL("https://twitter.com/cuveecollectivehq"), "discord": MetadataViews.ExternalURL("https://cuveecollective.com/discord")})
			}
			return nil
		}
		
		access(all)
		fun getSetData(): SetData{ 
			return Wine.SetsData[self.setID]!
		}
		
		access(all)
		view fun getTemplate(): Template{ 
			return Wine.Templates[self.templateID]!
		}
		
		access(all)
		fun getMetadata():{ String: AnyStruct}{ 
			return (Wine.Templates[self.templateID]!).getMetadata()
		}
		
		access(all)
		fun getExternalUrl(): String{ 
			let template = self.getTemplate()
			let extBaseUrl = template.getMetadata()["external_base_url"] as! String?
			return (extBaseUrl!).concat("/").concat(template.id.toString())
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
		fun borrowWine(id: UInt64): &Wine.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow wine reference: the ID of the returned reference is incorrect"
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
			let token <- token as! @Wine.NFT
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
		fun borrowWine(id: UInt64): &Wine.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref! as! &Wine.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			let wineNFT = nft! as! &Wine.NFT
			return wineNFT as &{ViewResolver.Resolver}
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
	
	// A Set is special resource type that contains functions to mint Wine NFTs, 
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
		var templateSupplies:{ UInt64: UInt64}
		
		init(name: String, description: String, image: String, metadata:{ String: AnyStruct}){ 
			pre{ 
				metadata.length != 0:
					"Set metadata cannot be empty"
			}
			self.id = Wine.nextSetID
			self.locked = false
			self.isPublic = false
			self.nextSerialNumber = 1
			self.templateIDs = []
			self.templateSupplies ={} 
			Wine.SetsData[self.id] = SetData(id: self.id, name: name, description: description, image: image, metadata: metadata)
			Wine.nextSetID = Wine.nextSetID + 1
			emit SetCreated(id: self.id, name: name)
		}
		
		access(all)
		fun updateImage(newImage: String){ 
			pre{ 
				self.locked == false:
					"Cannot update image: set is locked"
			}
			let oldData = Wine.SetsData[self.id]!
			Wine.SetsData[self.id] = SetData(id: self.id, name: oldData.name, description: oldData.description, image: newImage, metadata: oldData.getMetadata())
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
			let oldData = Wine.SetsData[self.id]!
			Wine.SetsData[self.id] = SetData(id: self.id, name: oldData.name, description: oldData.description, image: oldData.image, metadata: newMetadata)
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
				Wine.Templates[id] != nil:
					"Template doesn't exist"
				!self.locked:
					"Cannot add template: set is locked"
				!self.templateIDs.contains(id):
					"Cannot add template: template is already added to the set"
				!((Wine.Templates[id]!).addedToSet != 0):
					"Cannot add template: template is already added to another set"
			}
			self.templateIDs.append(id)
			self.templateSupplies[id] = 0
			(			 
			 // This function will automatically emit TemplateAddedToSet event
			 Wine.Templates[id]!).markAddedToSet(setID: self.id)
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
			emit SetLocked(id: self.id, name: (Wine.SetsData[self.id]!).name)
		}
		
		access(all)
		fun unlock(){ 
			pre{ 
				self.locked == true:
					"Set is already unlocked"
			}
			self.locked = false
			emit SetUnlocked(id: self.id, name: (Wine.SetsData[self.id]!).name)
		}
		
		access(all)
		fun mintNFT(templateID: UInt64): @NFT{ 
			let nextEditionNumber = self.templateSupplies[templateID]! + 1
			if nextEditionNumber >= (Wine.Templates[templateID]!).maxSupply{ 
				panic("Supply unavailable")
			}
			let newNFT: @NFT <- create Wine.NFT(id: Wine.totalSupply + 1, templateID: templateID, editionNumber: nextEditionNumber, serialNumber: self.nextSerialNumber)
			Wine.totalSupply = Wine.totalSupply + 1
			self.nextSerialNumber = self.nextSerialNumber + 1
			self.templateSupplies[templateID] = self.templateSupplies[templateID]! + 1
			emit Minted(id: newNFT.id, templateID: newNFT.templateID, setID: newNFT.setID)
			return <-newNFT
		}
		
		access(all)
		fun updateTemplateName(id: UInt64, newName: String){ 
			pre{ 
				Wine.Templates[id] != nil:
					"Template doesn't exist"
				self.templateIDs.contains(id):
					"Cannot edit template: template is not part of this set"
				!self.locked:
					"Cannot edit template: set is locked"
			}
			(			 
			 // This function will automatically emit TemplateUpdated event
			 Wine.Templates[id]!).updateName(newName: newName)
		}
		
		access(all)
		fun updateTemplateDescription(id: UInt64, newDescription: String){ 
			pre{ 
				Wine.Templates[id] != nil:
					"Template doesn't exist"
				self.templateIDs.contains(id):
					"Cannot edit template: template is not part of this set"
				!self.locked:
					"Cannot edit template: set is locked"
			}
			(			 
			 // This function will automatically emit TemplateUpdated event
			 Wine.Templates[id]!).updateDescription(newDescription: newDescription)
		}
		
		access(all)
		fun updateTemplateImage(id: UInt64, newImage: String){ 
			pre{ 
				Wine.Templates[id] != nil:
					"Template doesn't exist"
				self.templateIDs.contains(id):
					"Cannot edit template: template is not part of this set"
				!self.locked:
					"Cannot edit template: set is locked"
			}
			(			 
			 // This function will automatically emit TemplateUpdated event
			 Wine.Templates[id]!).updateImage(newImage: newImage)
		}
		
		access(all)
		fun updateTemplateMaxSupply(id: UInt64, newMaxSupply: UInt64){ 
			pre{ 
				Wine.Templates[id] != nil:
					"Template doesn't exist"
				self.templateIDs.contains(id):
					"Cannot edit template: template is not part of this set"
				!self.locked:
					"Cannot edit template: set is locked"
			}
			(			 
			 // This function will automatically emit TemplateUpdated event
			 Wine.Templates[id]!).updateMaxSupply(newMaxSupply: newMaxSupply)
		}
		
		access(all)
		fun updateTemplateMetadata(id: UInt64, newMetadata:{ String: AnyStruct}){ 
			pre{ 
				Wine.Templates[id] != nil:
					"Template doesn't exist"
				self.templateIDs.contains(id):
					"Cannot edit template: template is not part of this set"
				!self.locked:
					"Cannot edit template: set is locked"
			}
			(			 
			 // This function will automatically emit TemplateUpdated event
			 Wine.Templates[id]!).updateMetadata(newMetadata: newMetadata)
		}
		
		access(all)
		fun lockTemplate(id: UInt64){ 
			pre{ 
				Wine.Templates[id] != nil:
					"Template doesn't exist"
				self.templateIDs.contains(id):
					"Cannot lock template: template is not part of this set"
				!self.locked:
					"Cannot lock template: set is locked"
			}
			(			 
			 // This function will automatically emit TemplateLocked event
			 Wine.Templates[id]!).lock()
		}
		
		access(all)
		fun getMetadata():{ String: AnyStruct}{ 
			return (Wine.SetsData[self.id]!).getMetadata()
		}
		
		access(all)
		fun getTemplateIDs(): [UInt64]{ 
			return self.templateIDs
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, setID: UInt64, templateID: UInt64){ 
			let set = self.borrowSet(id: setID)
			if set.getTemplateIDs().length == 0{ 
				panic("Set is empty")
			}
			recipient.deposit(token: <-set.mintNFT(templateID: templateID))
		}
		
		access(all)
		fun createTemplate(name: String, description: String, image: String, maxSupply: UInt64, metadata:{ String: AnyStruct}): UInt64{ 
			let templateID = Wine.nextTemplateID
			
			// This function will automatically emit TemplateCreated event
			Wine.Templates[templateID] = Template(id: templateID, name: name, description: description, image: image, maxSupply: maxSupply, metadata: metadata)
			return templateID
		}
		
		access(all)
		fun updateTemplateName(id: UInt64, newName: String){ 
			pre{ 
				Wine.Templates.containsKey(id) != nil:
					"Template doesn't exits"
			}
			(			 
			 // This function will automatically emit TemplateUpdated event
			 Wine.Templates[id]!).updateName(newName: newName)
		}
		
		access(all)
		fun updateTemplateDescription(id: UInt64, newDescription: String){ 
			pre{ 
				Wine.Templates.containsKey(id) != nil:
					"Template doesn't exits"
			}
			(			 
			 // This function will automatically emit TemplateUpdated event
			 Wine.Templates[id]!).updateDescription(newDescription: newDescription)
		}
		
		access(all)
		fun updateTemplateImage(id: UInt64, newImage: String){ 
			pre{ 
				Wine.Templates.containsKey(id) != nil:
					"Template doesn't exits"
			}
			(			 
			 // This function will automatically emit TemplateUpdated event
			 Wine.Templates[id]!).updateImage(newImage: newImage)
		}
		
		access(all)
		fun updateTemplateMaxSupply(id: UInt64, newMaxSupply: UInt64){ 
			pre{ 
				Wine.Templates.containsKey(id) != nil:
					"Template doesn't exits"
			}
			(			 
			 // This function will automatically emit TemplateUpdated event
			 Wine.Templates[id]!).updateMaxSupply(newMaxSupply: newMaxSupply)
		}
		
		access(all)
		fun updateTemplateMetadata(id: UInt64, newMetadata:{ String: String}){ 
			pre{ 
				Wine.Templates.containsKey(id) != nil:
					"Template doesn't exits"
			}
			(			 
			 // This function will automatically emit TemplateUpdated event
			 Wine.Templates[id]!).updateMetadata(newMetadata: newMetadata)
		}
		
		access(all)
		fun lockTemplate(id: UInt64){ 
			pre{ 
				Wine.Templates.containsKey(id) != nil:
					"Template doesn't exits"
			}
			(			 
			 // This function will automatically emit TemplateLocked event
			 Wine.Templates[id]!).lock()
		}
		
		access(all)
		fun createSet(name: String, description: String, image: String, metadata:{ String: String}){ 
			var newSet <- create Set(name: name, description: description, image: image, metadata: metadata)
			Wine.sets[newSet.id] <-! newSet
		}
		
		access(all)
		fun borrowSet(id: UInt64): &Set{ 
			pre{ 
				Wine.sets[id] != nil:
					"Cannot borrow set: set doesn't exist"
			}
			let ref = &Wine.sets[id] as &Set?
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
	view fun getTemplate(id: UInt64): Wine.Template?{ 
		return self.Templates[id]
	}
	
	access(all)
	fun getTemplates():{ UInt64: Wine.Template}{ 
		return self.Templates
	}
	
	access(all)
	fun getSetIDs(): [UInt64]{ 
		return self.sets.keys
	}
	
	access(all)
	fun getSetData(id: UInt64): Wine.SetData?{ 
		return Wine.SetsData[id]
	}
	
	access(all)
	fun getSetsData():{ UInt64: Wine.SetData}{ 
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
	fun getTemplateIDsInSet(id: UInt64): [UInt64]{ 
		pre{ 
			self.sets[id] != nil:
				"Cannot borrow set: set doesn't exist"
		}
		let set = &self.sets[id] as &Set?
		return (set!).getTemplateIDs()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/WineCollection
		self.CollectionPublicPath = /public/WineCollection
		self.AdminStoragePath = /storage/WineAdmin
		self.AdminPrivatePath = /private/WineAdminUpgrade
		self.totalSupply = 0
		self.nextTemplateID = 1
		self.nextSetID = 1
		self.sets <-{} 
		self.SetsData ={} 
		self.Templates ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Wine.Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath) ?? panic("Could not get a capability to the admin")
		emit ContractInitialized()
	}
}
