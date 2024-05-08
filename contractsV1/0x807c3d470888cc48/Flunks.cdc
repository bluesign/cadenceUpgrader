// SPDX-License-Identifier: UNLICENSED
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Flunks: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event SetCreated(setID: UInt64)
	
	access(all)
	event NFTTemplateCreated(templateID: UInt64, metadata:{ String: String})
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, templateID: UInt64)
	
	access(all)
	event TemplateAddedToSet(setID: UInt64, templateID: UInt64)
	
	access(all)
	event TemplateLockedFromSet(setID: UInt64, templateID: UInt64)
	
	access(all)
	event TemplateUpdated(template: FlunksTemplate)
	
	access(all)
	event SetLocked(setID: UInt64)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var nextTemplateID: UInt64
	
	access(all)
	var nextSetID: UInt64
	
	access(self)
	var FlunksTemplates:{ UInt64: FlunksTemplate}
	
	access(self)
	var sets: @{UInt64: Set}
	
	access(all)
	resource interface FlunksCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowFlunks(id: UInt64): &Flunks.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Flunks reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	struct FlunksTemplate{ 
		access(all)
		let templateID: UInt64
		
		access(all)
		var name: String
		
		access(all)
		var description: String
		
		access(all)
		var locked: Bool
		
		access(all)
		var addedToSet: UInt64
		
		access(self)
		var metadata:{ String: String}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun lockTemplate(){ 
			self.locked = true
		}
		
		access(all)
		fun updateMetadata(newMetadata:{ String: String}){ 
			pre{ 
				newMetadata.length != 0:
					"New Template metadata cannot be empty"
			}
			self.metadata = newMetadata
		}
		
		access(all)
		fun markAddedToSet(setID: UInt64){ 
			self.addedToSet = setID
		}
		
		init(templateID: UInt64, name: String, description: String, metadata:{ String: String}){ 
			pre{ 
				metadata.length != 0:
					"New Template metadata cannot be empty"
			}
			self.templateID = templateID
			self.name = name
			self.description = description
			self.metadata = metadata
			self.locked = false
			self.addedToSet = 0
			Flunks.nextTemplateID = Flunks.nextTemplateID + 1
			emit NFTTemplateCreated(templateID: self.templateID, metadata: self.metadata)
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let templateID: UInt64
		
		access(all)
		let serialNumber: UInt64
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Edition>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.getNFTTemplate().name.concat(" #").concat(self.serialNumber.toString()), description: self.getNFTTemplate().description, thumbnail: MetadataViews.HTTPFile(url: self.getNFTTemplate().getMetadata()["uri"]!))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://flunks.io/")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Flunks.CollectionStoragePath, publicPath: Flunks.CollectionPublicPath, publicCollection: Type<&Flunks.Collection>(), publicLinkedType: Type<&Flunks.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Flunks.createEmptyCollection(nftType: Type<@Flunks.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/flunks_public/website-assets/banner_2023.png"), mediaType: "image/png")
					let logoFull = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/zeero-public/logo_full.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "Flunks", description: "Flunks are cute but mischievous high-schoolers wreaking havoc #onFlow", externalURL: MetadataViews.ExternalURL("https://flunks.io/"), squareImage: logoFull, bannerImage: bannerMedia, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/flunks_nft")})
				case Type<MetadataViews.Traits>():
					let excludedTraits = ["mimetype", "uri", "pixelUri", "path", "cid"]
					let traitsView = MetadataViews.dictToTraits(dict: self.getNFTTemplate().getMetadata(), excludedNames: excludedTraits)
					return traitsView
				case Type<MetadataViews.Edition>():
					return MetadataViews.Edition(name: "Flunks", number: self.serialNumber, max: 9999)
				case Type<MetadataViews.Royalties>():
					// Note: replace the address for different merchant accounts across various networks
					let merchant = getAccount(0x0cce91b08cb58286)
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: merchant.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)!, cut: 0.05, description: "Flunks creator royalty in DUC")])
			}
			return nil
		}
		
		access(all)
		fun getNFTTemplate(): FlunksTemplate{ 
			return Flunks.FlunksTemplates[self.templateID]!
		}
		
		access(all)
		fun getNFTMetadata():{ String: String}{ 
			return (Flunks.FlunksTemplates[self.templateID]!).getMetadata()
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, initTemplateID: UInt64, serialNumber: UInt64){ 
			self.id = initID
			self.templateID = initTemplateID
			self.serialNumber = serialNumber
		}
	}
	
	access(all)
	resource Collection: FlunksCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Flunks.NFT
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
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowFlunks(id: UInt64): &Flunks.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Flunks.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let exampleNFT = nft as! &Flunks.NFT
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
	
	access(all)
	resource Set{ 
		access(all)
		let setID: UInt64
		
		access(all)
		let name: String
		
		access(self)
		var templateIDs: [UInt64]
		
		access(self)
		var availableTemplateIDs: [UInt64]
		
		access(self)
		var lockedTemplates:{ UInt64: Bool}
		
		access(all)
		var locked: Bool
		
		access(all)
		var nextSetSerialNumber: UInt64
		
		access(all)
		var isPublic: Bool
		
		init(name: String){ 
			self.name = name
			self.setID = Flunks.nextSetID
			self.templateIDs = []
			self.lockedTemplates ={} 
			self.locked = false
			self.availableTemplateIDs = []
			self.nextSetSerialNumber = 1
			self.isPublic = false
			Flunks.nextSetID = Flunks.nextSetID + 1
			emit SetCreated(setID: self.setID)
		}
		
		access(all)
		fun getAvailableTemplateIDs(): [UInt64]{ 
			return self.availableTemplateIDs
		}
		
		access(all)
		fun makeSetPublic(){ 
			self.isPublic = true
		}
		
		access(all)
		fun makeSetPrivate(){ 
			self.isPublic = false
		}
		
		access(all)
		fun addTemplate(templateID: UInt64){ 
			pre{ 
				Flunks.FlunksTemplates[templateID] != nil:
					"Template doesn't exist"
				!self.locked:
					"Cannot add template - set is locked"
				!self.templateIDs.contains(templateID):
					"Cannot add template - template is already added to the set"
				!((Flunks.FlunksTemplates[templateID]!).addedToSet != 0):
					"Cannot add template - template is already added to another set"
			}
			self.templateIDs.append(templateID)
			self.availableTemplateIDs.append(templateID)
			self.lockedTemplates[templateID] = false
			(Flunks.FlunksTemplates[templateID]!).markAddedToSet(setID: self.setID)
			emit TemplateAddedToSet(setID: self.setID, templateID: templateID)
		}
		
		access(all)
		fun addTemplates(templateIDs: [UInt64]){ 
			for template in templateIDs{ 
				self.addTemplate(templateID: template)
			}
		}
		
		access(all)
		fun lockTemplate(templateID: UInt64){ 
			pre{ 
				self.lockedTemplates[templateID] != nil:
					"Cannot lock the template: Template is locked already!"
				!self.availableTemplateIDs.contains(templateID):
					"Cannot lock a not yet minted template!"
			}
			if !self.lockedTemplates[templateID]!{ 
				self.lockedTemplates[templateID] = true
				emit TemplateLockedFromSet(setID: self.setID, templateID: templateID)
			}
		}
		
		access(all)
		fun lockAllTemplates(){ 
			for template in self.templateIDs{ 
				self.lockTemplate(templateID: template)
			}
		}
		
		access(all)
		fun lock(){ 
			if !self.locked{ 
				self.locked = true
				emit SetLocked(setID: self.setID)
			}
		}
		
		access(all)
		fun mintNFT(): @NFT{ 
			let templateID = self.availableTemplateIDs[0]
			if (Flunks.FlunksTemplates[templateID]!).locked{ 
				panic("template is locked")
			}
			let newNFT: @NFT <- create Flunks.NFT(initID: Flunks.totalSupply, initTemplateID: templateID, serialNumber: self.nextSetSerialNumber)
			Flunks.totalSupply = Flunks.totalSupply + 1
			self.nextSetSerialNumber = self.nextSetSerialNumber + 1
			self.availableTemplateIDs.remove(at: 0)
			emit Minted(id: newNFT.id, templateID: newNFT.getNFTTemplate().templateID)
			return <-newNFT
		}
		
		access(all)
		fun updateTemplateMetadata(templateID: UInt64, newMetadata:{ String: String}): FlunksTemplate{ 
			pre{ 
				Flunks.FlunksTemplates[templateID] != nil:
					"Template doesn't exist"
				!self.locked:
					"Cannot edit template - set is locked"
			}
			(Flunks.FlunksTemplates[templateID]!).updateMetadata(newMetadata: newMetadata)
			emit TemplateUpdated(template: Flunks.FlunksTemplates[templateID]!)
			return Flunks.FlunksTemplates[templateID]!
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, setID: UInt64){ 
			let set = self.borrowSet(setID: setID)
			if (set.getAvailableTemplateIDs()!).length == 0{ 
				panic("set is empty")
			}
			if set.locked{ 
				panic("set is locked")
			}
			recipient.deposit(token: <-set.mintNFT())
		}
		
		access(all)
		fun createFlunksTemplate(name: String, description: String, metadata:{ String: String}){ 
			Flunks.FlunksTemplates[Flunks.nextTemplateID] = FlunksTemplate(templateID: Flunks.nextTemplateID, name: name, description: description, metadata: metadata)
		}
		
		access(all)
		fun createSet(name: String){ 
			var newSet <- create Set(name: name)
			Flunks.sets[newSet.setID] <-! newSet
		}
		
		access(all)
		fun borrowSet(setID: UInt64): &Set{ 
			pre{ 
				Flunks.sets[setID] != nil:
					"Cannot borrow Set: The Set doesn't exist"
			}
			return (&Flunks.sets[setID] as &Set?)!
		}
		
		access(all)
		fun updateFlunksTemplate(templateID: UInt64, newMetadata:{ String: String}){ 
			pre{ 
				Flunks.FlunksTemplates.containsKey(templateID):
					"Template does not exit."
			}
			(Flunks.FlunksTemplates[templateID]!).updateMetadata(newMetadata: newMetadata)
		}
	}
	
	access(all)
	fun getFlunksTemplateByID(templateID: UInt64): Flunks.FlunksTemplate{ 
		return Flunks.FlunksTemplates[templateID]!
	}
	
	access(all)
	fun getFlunksTemplates():{ UInt64: Flunks.FlunksTemplate}{ 
		return Flunks.FlunksTemplates
	}
	
	access(all)
	fun getAvailableTemplateIDsInSet(setID: UInt64): [UInt64]{ 
		pre{ 
			Flunks.sets[setID] != nil:
				"Cannot borrow Set: The Set doesn't exist"
		}
		let set = (&Flunks.sets[setID] as &Set?)!
		return set.getAvailableTemplateIDs()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/FlunksCollection
		self.CollectionPublicPath = /public/FlunksCollection
		self.AdminStoragePath = /storage/FlunksAdmin
		self.totalSupply = 0
		self.nextTemplateID = 1
		self.nextSetID = 1
		self.sets <-{} 
		self.FlunksTemplates ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
