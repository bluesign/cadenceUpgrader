// SPDX-License-Identifier: MIT
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract InceptionAvatar: NonFungibleToken{ 
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
	event TemplateUpdated(template: InceptionAvatarTemplate)
	
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
	
	access(all)
	var InceptionAvatarTemplates:{ UInt64: InceptionAvatarTemplate}
	
	access(all)
	var sets: @{UInt64: Set}
	
	access(all)
	resource interface InceptionAvatarCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowInceptionAvatar(id: UInt64): &InceptionAvatar.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow InceptionAvatar reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	struct InceptionAvatarTemplate{ 
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
			InceptionAvatar.nextTemplateID = InceptionAvatar.nextTemplateID + 1
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
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.getNFTTemplate().name, description: self.getNFTTemplate().description, thumbnail: MetadataViews.HTTPFile(url: self.getNFTTemplate().getMetadata()["uri"]!))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://www.inceptionanimals.com/")
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.templateID)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: InceptionAvatar.CollectionStoragePath, publicPath: InceptionAvatar.CollectionPublicPath, publicCollection: Type<&InceptionAvatar.Collection>(), publicLinkedType: Type<&InceptionAvatar.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-InceptionAvatar.createEmptyCollection(nftType: Type<@InceptionAvatar.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://inceptionanimals.com/logo.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "Inception Animals", description: "A retro futuristic metaverse brand", externalURL: MetadataViews.ExternalURL("https://inceptionanimals.com/"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/Inceptionft")})
				case Type<MetadataViews.Traits>():
					let excludedTraits = ["mintedTime", "foo"]
					let traitsView = MetadataViews.dictToTraits(dict: (self.getNFTTemplate()!).getMetadata(), excludedNames: excludedTraits)
					return traitsView
				case Type<MetadataViews.Royalties>():
					// Note: replace the address for different merchant accounts across various networks
					let merchant = getAccount(0x609aa4e00da88742)
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: merchant.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)!, cut: 0.1, description: "Creator royalty in DUC")])
			}
			return nil
		}
		
		access(all)
		fun getNFTTemplate(): InceptionAvatarTemplate{ 
			return InceptionAvatar.InceptionAvatarTemplates[self.templateID]!
		}
		
		access(all)
		fun getNFTMetadata():{ String: String}{ 
			return (InceptionAvatar.InceptionAvatarTemplates[self.templateID]!).getMetadata()
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
	resource Collection: InceptionAvatarCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @InceptionAvatar.NFT
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
		fun borrowInceptionAvatar(id: UInt64): &InceptionAvatar.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &InceptionAvatar.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let exampleNFT = nft as! &InceptionAvatar.NFT
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
			self.setID = InceptionAvatar.nextSetID
			self.templateIDs = []
			self.lockedTemplates ={} 
			self.locked = false
			self.availableTemplateIDs = []
			self.nextSetSerialNumber = 1
			self.isPublic = false
			InceptionAvatar.nextSetID = InceptionAvatar.nextSetID + 1
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
				InceptionAvatar.InceptionAvatarTemplates[templateID] != nil:
					"Template doesn't exist"
				!self.locked:
					"Cannot add template - set is locked"
				!self.templateIDs.contains(templateID):
					"Cannot add template - template is already added to the set"
				!((InceptionAvatar.InceptionAvatarTemplates[templateID]!).addedToSet != 0):
					"Cannot add template - template is already added to another set"
			}
			self.templateIDs.append(templateID)
			self.availableTemplateIDs.append(templateID)
			self.lockedTemplates[templateID] = false
			(InceptionAvatar.InceptionAvatarTemplates[templateID]!).markAddedToSet(setID: self.setID)
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
			if (InceptionAvatar.InceptionAvatarTemplates[templateID]!).locked{ 
				panic("template is locked")
			}
			let newNFT: @NFT <- create InceptionAvatar.NFT(initID: InceptionAvatar.totalSupply, initTemplateID: templateID, serialNumber: self.nextSetSerialNumber)
			InceptionAvatar.totalSupply = InceptionAvatar.totalSupply + 1
			self.nextSetSerialNumber = self.nextSetSerialNumber + 1
			self.availableTemplateIDs.remove(at: 0)
			emit Minted(id: newNFT.id, templateID: newNFT.getNFTTemplate().templateID)
			return <-newNFT
		}
		
		access(all)
		fun updateTemplateMetadata(templateID: UInt64, newMetadata:{ String: String}): InceptionAvatarTemplate{ 
			pre{ 
				InceptionAvatar.InceptionAvatarTemplates[templateID] != nil:
					"Template doesn't exist"
				!self.locked:
					"Cannot edit template - set is locked"
			}
			(InceptionAvatar.InceptionAvatarTemplates[templateID]!).updateMetadata(newMetadata: newMetadata)
			emit TemplateUpdated(template: InceptionAvatar.InceptionAvatarTemplates[templateID]!)
			return InceptionAvatar.InceptionAvatarTemplates[templateID]!
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
		fun createInceptionAvatarTemplate(name: String, description: String, metadata:{ String: String}){ 
			InceptionAvatar.InceptionAvatarTemplates[InceptionAvatar.nextTemplateID] = InceptionAvatarTemplate(templateID: InceptionAvatar.nextTemplateID, name: name, description: description, metadata: metadata)
		}
		
		access(all)
		fun createSet(name: String){ 
			var newSet <- create Set(name: name)
			InceptionAvatar.sets[newSet.setID] <-! newSet
		}
		
		access(all)
		fun borrowSet(setID: UInt64): &Set{ 
			pre{ 
				InceptionAvatar.sets[setID] != nil:
					"Cannot borrow Set: The Set doesn't exist"
			}
			return (&InceptionAvatar.sets[setID] as &Set?)!
		}
		
		access(all)
		fun updateInceptionAvatarTemplate(templateID: UInt64, newMetadata:{ String: String}){ 
			pre{ 
				InceptionAvatar.InceptionAvatarTemplates.containsKey(templateID) != nil:
					"Template does not exits."
			}
			(InceptionAvatar.InceptionAvatarTemplates[templateID]!).updateMetadata(newMetadata: newMetadata)
		}
	}
	
	access(all)
	fun getInceptionAvatarTemplateByID(templateID: UInt64): InceptionAvatar.InceptionAvatarTemplate{ 
		return InceptionAvatar.InceptionAvatarTemplates[templateID]!
	}
	
	access(all)
	fun getInceptionAvatarTemplates():{ UInt64: InceptionAvatar.InceptionAvatarTemplate}{ 
		return InceptionAvatar.InceptionAvatarTemplates
	}
	
	access(all)
	fun getAvailableTemplateIDsInSet(setID: UInt64): [UInt64]{ 
		pre{ 
			InceptionAvatar.sets[setID] != nil:
				"Cannot borrow Set: The Set doesn't exist"
		}
		let set = (&InceptionAvatar.sets[setID] as &Set?)!
		return set.getAvailableTemplateIDs()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/InceptionAvatarCollection
		self.CollectionPublicPath = /public/InceptionAvatarCollection
		self.AdminStoragePath = /storage/InceptionAvatarAdmin
		self.totalSupply = 0
		self.nextTemplateID = 1
		self.nextSetID = 1
		self.sets <-{} 
		self.InceptionAvatarTemplates ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
