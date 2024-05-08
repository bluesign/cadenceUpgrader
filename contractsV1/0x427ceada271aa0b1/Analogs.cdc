import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Analogs: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event AccountInitialized()
	
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
	event TemplateUpdated(template: AnalogsTemplate)
	
	access(all)
	event SetLocked(setID: UInt64)
	
	access(all)
	event SetUnlocked(setID: UInt64)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var initialNFTID: UInt64
	
	access(all)
	var nextNFTID: UInt64
	
	access(all)
	var nextTemplateID: UInt64
	
	access(all)
	var nextSetID: UInt64
	
	access(self)
	var analogsTemplates:{ UInt64: AnalogsTemplate}
	
	access(self)
	var sets: @{UInt64: Set}
	
	access(all)
	resource interface AnalogsCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowAnalog(id: UInt64): &Analogs.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Analogs reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	struct AnalogsTemplate{ 
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
			emit NFTTemplateCreated(templateID: self.templateID, metadata: self.metadata)
		}
	}
	
	access(all)
	struct Royalty{ 
		access(all)
		let address: Address
		
		access(all)
		let primaryCut: UFix64
		
		access(all)
		let secondaryCut: UFix64
		
		access(all)
		let description: String
		
		init(address: Address, primaryCut: UFix64, secondaryCut: UFix64, description: String){ 
			pre{ 
				primaryCut >= 0.0 && primaryCut <= 1.0:
					"primaryCut value should be in valid range i.e [0,1]"
				secondaryCut >= 0.0 && secondaryCut <= 1.0:
					"secondaryCut value should be in valid range i.e [0,1]"
			}
			self.address = address
			self.primaryCut = primaryCut
			self.secondaryCut = secondaryCut
			self.description = description
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let templateID: UInt64
		
		access(all)
		var serialNumber: UInt64
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Display>(), Type<MetadataViews.Medias>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let metadata = (Analogs.analogsTemplates[self.templateID]!).getMetadata()
			let thumbnailCID = metadata["thumbnailCID"] != nil ? metadata["thumbnailCID"]! : metadata["imageCID"]!
			switch view{ 
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://ipfs.io/ipfs/".concat(thumbnailCID))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Analogs.CollectionStoragePath, publicPath: Analogs.CollectionPublicPath, publicCollection: Type<&Analogs.Collection>(), publicLinkedType: Type<&Analogs.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Analogs.createEmptyCollection(nftType: Type<@Analogs.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://ipfs.io/ipfs/bafkreidhuylwtdgug3vuamphju44r7eam5wlels4tejbkz4nvelnluktcm"), mediaType: "image/jpeg")
					return MetadataViews.NFTCollectionDisplay(name: "Heavy Metal Analogs", description: "", externalURL: MetadataViews.ExternalURL("https://sturdy.exchange/"), squareImage: media, bannerImage: media, socials:{} )
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: (Analogs.analogsTemplates[self.templateID]!).name, description: (Analogs.analogsTemplates[self.templateID]!).description, thumbnail: MetadataViews.HTTPFile(url: "https://ipfs.io/ipfs/".concat(thumbnailCID)))
				case Type<MetadataViews.Medias>():
					let medias: [MetadataViews.Media] = []
					let videoCID = (Analogs.analogsTemplates[self.templateID]!).getMetadata()["videoCID"]
					let imageCID = thumbnailCID
					if videoCID != nil{ 
						medias.append(MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://ipfs.io/ipfs/".concat(videoCID!)), mediaType: "video/mp4"))
					} else if imageCID != nil{ 
						medias.append(MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://ipfs.io/ipfs/".concat(imageCID)), mediaType: "image/jpeg"))
					}
					return MetadataViews.Medias(medias)
				case Type<MetadataViews.Royalties>():
					let setID = (Analogs.analogsTemplates[self.templateID]!).addedToSet
					let setRoyalties = Analogs.getSetRoyalties(setID: setID)
					let royalties: [MetadataViews.Royalty] = []
					for royalty in setRoyalties{ 
						royalties.append(MetadataViews.Royalty(receiver: getAccount(royalty.address).capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)!, cut: royalty.secondaryCut, description: royalty.description))
					}
					return MetadataViews.Royalties(royalties)
			}
			return nil
		}
		
		access(all)
		fun getNFTMetadata():{ String: String}{ 
			return (Analogs.analogsTemplates[self.templateID]!).getMetadata()
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
	resource Collection: AnalogsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @Analogs.NFT
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
		fun borrowAnalog(id: UInt64): &Analogs.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Analogs.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let exampleNFT = nft as! &Analogs.NFT
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
		emit AccountInitialized()
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
		
		access(self)
		var metadata:{ String: String}
		
		access(all)
		var locked: Bool
		
		access(all)
		var nextSetSerialNumber: UInt64
		
		access(all)
		var isPublic: Bool
		
		access(all)
		var analogRoyaltyAddress: Address
		
		access(all)
		var analogRoyaltySecondaryCut: UFix64
		
		access(all)
		var artistRoyalties: [Royalty]
		
		init(name: String, analogRoyaltyAddress: Address, analogRoyaltySecondaryCut: UFix64, imageCID: String){ 
			self.name = name
			self.setID = Analogs.nextSetID
			self.templateIDs = []
			self.lockedTemplates ={} 
			self.locked = false
			self.availableTemplateIDs = []
			self.nextSetSerialNumber = 1
			self.isPublic = false
			self.analogRoyaltyAddress = analogRoyaltyAddress
			self.analogRoyaltySecondaryCut = analogRoyaltySecondaryCut
			self.artistRoyalties = []
			self.metadata ={ "imageCID": imageCID}
			Analogs.nextSetID = Analogs.nextSetID + 1
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
		fun updateAnalogRoyaltyAddress(analogRoyaltyAddress: Address){ 
			self.analogRoyaltyAddress = analogRoyaltyAddress
		}
		
		access(all)
		fun updateAnalogRoyaltySecondaryCut(analogRoyaltySecondaryCut: UFix64){ 
			self.analogRoyaltySecondaryCut = analogRoyaltySecondaryCut
		}
		
		access(all)
		fun addArtistRoyalty(royalty: Royalty){ 
			self.artistRoyalties.append(royalty)
		}
		
		access(all)
		fun addTemplate(templateID: UInt64, available: Bool){ 
			pre{ 
				Analogs.analogsTemplates[templateID] != nil:
					"Template doesn't exist"
				!self.locked:
					"Cannot add template - set is locked"
				!self.templateIDs.contains(templateID):
					"Cannot add template - template is already added to the set"
				!((Analogs.analogsTemplates[templateID]!).addedToSet != 0):
					"Cannot add template - template is already added to another set"
			}
			self.templateIDs.append(templateID)
			if available{ 
				self.availableTemplateIDs.append(templateID)
			}
			self.lockedTemplates[templateID] = !available
			(Analogs.analogsTemplates[templateID]!).markAddedToSet(setID: self.setID)
			emit TemplateAddedToSet(setID: self.setID, templateID: templateID)
		}
		
		access(all)
		fun addTemplates(templateIDs: [UInt64], available: Bool){ 
			for template in templateIDs{ 
				self.addTemplate(templateID: template, available: available)
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
		fun unlock(){ 
			if self.locked{ 
				self.locked = false
				emit SetUnlocked(setID: self.setID)
			}
		}
		
		access(all)
		fun mintNFT(): @NFT{ 
			let templateID = self.availableTemplateIDs[0]
			if (Analogs.analogsTemplates[templateID]!).locked{ 
				panic("template is locked")
			}
			let newNFT: @NFT <- create Analogs.NFT(initID: Analogs.nextNFTID, initTemplateID: templateID, serialNumber: self.nextSetSerialNumber)
			Analogs.totalSupply = Analogs.totalSupply + 1
			Analogs.nextNFTID = Analogs.nextNFTID + 1
			self.nextSetSerialNumber = self.nextSetSerialNumber + 1
			self.availableTemplateIDs.remove(at: 0)
			emit Minted(id: newNFT.id, templateID: newNFT.templateID)
			return <-newNFT
		}
		
		access(all)
		fun mintNFTByTemplateID(templateID: UInt64): @NFT{ 
			let newNFT: @NFT <- create Analogs.NFT(initID: templateID, initTemplateID: templateID, serialNumber: self.nextSetSerialNumber)
			Analogs.totalSupply = Analogs.totalSupply + 1
			self.nextSetSerialNumber = self.nextSetSerialNumber + 1
			self.lockTemplate(templateID: templateID)
			emit Minted(id: newNFT.id, templateID: newNFT.templateID)
			return <-newNFT
		}
		
		access(all)
		fun updateTemplateMetadata(templateID: UInt64, newMetadata:{ String: String}): AnalogsTemplate{ 
			pre{ 
				Analogs.analogsTemplates[templateID] != nil:
					"Template doesn't exist"
				!self.locked:
					"Cannot edit template - set is locked"
			}
			(Analogs.analogsTemplates[templateID]!).updateMetadata(newMetadata: newMetadata)
			emit TemplateUpdated(template: Analogs.analogsTemplates[templateID]!)
			return Analogs.analogsTemplates[templateID]!
		}
		
		access(all)
		fun getImageCID(): String?{ 
			return self.metadata["imageCID"]
		}
		
		access(all)
		fun updateImageCID(imageCID: String){ 
			self.metadata["imageCID"] = imageCID
		}
	}
	
	access(all)
	fun getSetName(setID: UInt64): String{ 
		pre{ 
			Analogs.sets[setID] != nil:
				"Cannot borrow Set: The Set doesn't exist"
		}
		let set = (&Analogs.sets[setID] as &Set?)!
		return set.name
	}
	
	access(all)
	fun getSetImageCID(setID: UInt64): String?{ 
		pre{ 
			Analogs.sets[setID] != nil:
				"Cannot borrow Set: The Set doesn't exist"
		}
		let set = (&Analogs.sets[setID] as &Set?)!
		return set.getImageCID()
	}
	
	access(all)
	fun getSetRoyalties(setID: UInt64): [Royalty]{ 
		pre{ 
			Analogs.sets[setID] != nil:
				"Cannot borrow Set: The Set doesn't exist"
		}
		let set = (&Analogs.sets[setID] as &Set?)!
		var analogRoyaltyPrimaryCut: UFix64 = 1.00
		for royalty in set.artistRoyalties{ 
			analogRoyaltyPrimaryCut = analogRoyaltyPrimaryCut - royalty.primaryCut
		}
		let royalties = [Royalty(address: set.analogRoyaltyAddress, primaryCut: analogRoyaltyPrimaryCut, secondaryCut: set.analogRoyaltySecondaryCut, description: "Sturdy Royalty")]
		royalties.appendAll(*set.artistRoyalties)
		return royalties
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, setID: UInt64){ 
			let set = self.borrowSet(setID: setID)
			if (set.getAvailableTemplateIDs()!).length == 0{ 
				panic("Set is empty")
			}
			if set.locked{ 
				panic("Set is locked")
			}
			recipient.deposit(token: <-set.mintNFT())
		}
		
		access(all)
		fun createAndMintNFT(recipient: &{NonFungibleToken.CollectionPublic}, templateID: UInt64, setID: UInt64, name: String, description: String, metadata:{ String: String}){ 
			if Analogs.analogsTemplates[Analogs.nextTemplateID] != nil{ 
				panic("Template already exists")
			}
			Analogs.analogsTemplates[templateID] = AnalogsTemplate(templateID: templateID, name: name, description: description, metadata: metadata)
			let set = self.borrowSet(setID: setID)
			set.addTemplate(templateID: templateID, available: false)
			recipient.deposit(token: <-set.mintNFTByTemplateID(templateID: templateID))
		}
		
		access(all)
		fun createAnalogsTemplate(name: String, description: String, metadata:{ String: String}){ 
			Analogs.analogsTemplates[Analogs.nextTemplateID] = AnalogsTemplate(templateID: Analogs.nextTemplateID, name: name, description: description, metadata: metadata)
			Analogs.nextTemplateID = Analogs.nextTemplateID + 1
		}
		
		access(all)
		fun createSet(name: String, analogRoyaltyAddress: Address, analogRoyaltySecondaryCut: UFix64, imageCID: String): UInt64{ 
			var newSet <- create Set(name: name, analogRoyaltyAddress: analogRoyaltyAddress, analogRoyaltySecondaryCut: analogRoyaltySecondaryCut, imageCID: imageCID)
			let setID = newSet.setID
			Analogs.sets[setID] <-! newSet
			return setID
		}
		
		access(all)
		fun borrowSet(setID: UInt64): &Set{ 
			pre{ 
				Analogs.sets[setID] != nil:
					"Cannot borrow Set: The Set doesn't exist"
			}
			return (&Analogs.sets[setID] as &Set?)!
		}
		
		access(all)
		fun updateSetImageCID(setID: UInt64, imageCID: String){ 
			pre{ 
				Analogs.sets[setID] != nil:
					"Cannot borrow Set: The Set doesn't exist"
			}
			let set = (&Analogs.sets[setID] as &Set?)!
			return set.updateImageCID(imageCID: imageCID)
		}
		
		access(all)
		fun updateAnalogsTemplate(templateID: UInt64, newMetadata:{ String: String}){ 
			pre{ 
				Analogs.analogsTemplates.containsKey(templateID) != nil:
					"Template does not exists."
			}
			(Analogs.analogsTemplates[templateID]!).updateMetadata(newMetadata: newMetadata)
		}
		
		access(all)
		fun setInitialNFTID(initialNFTID: UInt64){ 
			pre{ 
				Analogs.initialNFTID == 0:
					"initialNFTID is already initialized"
			}
			Analogs.initialNFTID = initialNFTID
			Analogs.nextNFTID = initialNFTID
			Analogs.nextTemplateID = initialNFTID
		}
	}
	
	access(all)
	fun getAnalogsTemplateByID(templateID: UInt64): Analogs.AnalogsTemplate{ 
		return Analogs.analogsTemplates[templateID]!
	}
	
	access(all)
	fun getAnalogsTemplates():{ UInt64: Analogs.AnalogsTemplate}{ 
		return Analogs.analogsTemplates
	}
	
	access(all)
	fun getAvailableTemplateIDsInSet(setID: UInt64): [UInt64]{ 
		pre{ 
			Analogs.sets[setID] != nil:
				"Cannot borrow Set: The Set doesn't exist"
		}
		let set = (&Analogs.sets[setID] as &Set?)!
		return set.getAvailableTemplateIDs()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/AnalogsCollection
		self.CollectionPublicPath = /public/AnalogsCollection
		self.AdminStoragePath = /storage/AnalogsAdmin
		self.totalSupply = 0
		self.nextSetID = 1
		self.initialNFTID = 0
		self.nextNFTID = 0
		self.nextTemplateID = 0
		self.sets <-{} 
		self.analogsTemplates ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
