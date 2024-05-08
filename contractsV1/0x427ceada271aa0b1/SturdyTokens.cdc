import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract SturdyTokens: NonFungibleToken{ 
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
	event TemplateUpdated(template: SturdyTokensTemplate)
	
	access(all)
	event SetLocked(setID: UInt64)
	
	access(all)
	event SetUnlocked(setID: UInt64)
	
	access(all)
	event Burned(owner: Address?, id: UInt64, templateID: UInt64, setID: UInt64)
	
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
	var sturdyTokensTemplates:{ UInt64: SturdyTokensTemplate}
	
	access(self)
	var sets: @{UInt64: Set}
	
	access(all)
	resource interface SturdyTokensCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowSturdyToken(id: UInt64): &SturdyTokens.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow SturdyTokens reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	struct SturdyTokensTemplate{ 
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
		let description: String
		
		init(address: Address, primaryCut: UFix64, secondaryCut: UFix64, description: String){ 
			pre{ 
				primaryCut >= 0.0 && primaryCut <= 1.0:
					"primaryCut value should be in valid range i.e [0,1]"
				secondaryCut >= 0.0 && secondaryCut <= 1.0:
					"secondaryCut value should be in valid range i.e [0,1]"
			}
			self.address = address
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
			let metadata = (SturdyTokens.sturdyTokensTemplates[self.templateID]!).getMetadata()
			let thumbnailCID = metadata["thumbnailCID"] != nil ? metadata["thumbnailCID"]! : metadata["imageCID"]!
			switch view{ 
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://ipfs.io/ipfs/".concat(thumbnailCID))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: SturdyTokens.CollectionStoragePath, publicPath: SturdyTokens.CollectionPublicPath, publicCollection: Type<&SturdyTokens.Collection>(), publicLinkedType: Type<&SturdyTokens.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-SturdyTokens.createEmptyCollection(nftType: Type<@SturdyTokens.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://ipfs.io/ipfs/bafkreigzbmx5vrynlnau2bchis76gz2jp7fylcs3kh6aqbfzhky22sko3y"), mediaType: "image/jpeg")
					return MetadataViews.NFTCollectionDisplay(name: "Sturdy Exchange", description: "", externalURL: MetadataViews.ExternalURL("https://sturdy.exchange/"), squareImage: media, bannerImage: media, socials:{} )
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: (SturdyTokens.sturdyTokensTemplates[self.templateID]!).name, description: (SturdyTokens.sturdyTokensTemplates[self.templateID]!).description, thumbnail: MetadataViews.HTTPFile(url: "https://ipfs.io/ipfs/".concat((SturdyTokens.sturdyTokensTemplates[self.templateID]!).getMetadata()["imageCID"]!)))
				case Type<MetadataViews.Medias>():
					let medias: [MetadataViews.Media] = []
					let videoCID = (SturdyTokens.sturdyTokensTemplates[self.templateID]!).getMetadata()["videoCID"]
					let imageCID = (SturdyTokens.sturdyTokensTemplates[self.templateID]!).getMetadata()["imageCID"]
					if videoCID != nil{ 
						medias.append(MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://ipfs.io/ipfs/".concat(videoCID!)), mediaType: "video/mp4"))
					} else if imageCID != nil{ 
						medias.append(MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://ipfs.io/ipfs/".concat(imageCID!)), mediaType: "image/jpeg"))
					}
					return MetadataViews.Medias(medias)
				case Type<MetadataViews.Royalties>():
					let setID = (SturdyTokens.sturdyTokensTemplates[self.templateID]!).addedToSet
					let setRoyalties = SturdyTokens.getSetRoyalties(setID: setID)
					let royalties: [MetadataViews.Royalty] = []
					for royalty in setRoyalties{ 
						royalties.append(MetadataViews.Royalty(receiver: getAccount(royalty.address).capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)!, cut: 0.05, description: royalty.description))
					}
					return MetadataViews.Royalties(royalties)
			}
			return nil
		}
		
		access(all)
		fun getNFTMetadata():{ String: String}{ 
			return (SturdyTokens.sturdyTokensTemplates[self.templateID]!).getMetadata()
		}
		
		access(all)
		fun getSetID(): UInt64{ 
			return (SturdyTokens.sturdyTokensTemplates[self.templateID]!).addedToSet
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
	resource Collection: SturdyTokensCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @SturdyTokens.NFT
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
		fun borrowSturdyToken(id: UInt64): &SturdyTokens.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &SturdyTokens.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let exampleNFT = nft as! &SturdyTokens.NFT
			return exampleNFT as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun burn(burnID: UInt64){ 
			let token <- self.withdraw(withdrawID: burnID) as! @SturdyTokens.NFT
			let templateID = token.templateID
			let setID = (SturdyTokens.sturdyTokensTemplates[templateID]!).addedToSet
			destroy token
			emit Burned(owner: self.owner?.address, id: burnID, templateID: templateID, setID: setID)
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
		
		access(all)
		var locked: Bool
		
		access(all)
		var nextSetSerialNumber: UInt64
		
		access(all)
		var isPublic: Bool
		
		access(all)
		var artistRoyalties: [Royalty]
		
		init(name: String, sturdyRoyaltyAddress: Address, sturdyRoyaltySecondaryCut: UFix64){ 
			self.name = name
			self.setID = SturdyTokens.nextSetID
			self.templateIDs = []
			self.lockedTemplates ={} 
			self.locked = false
			self.availableTemplateIDs = []
			self.nextSetSerialNumber = 1
			self.isPublic = false
			self.artistRoyalties = []
			SturdyTokens.nextSetID = SturdyTokens.nextSetID + 1
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
		fun addArtistRoyalty(royalty: Royalty){ 
			self.artistRoyalties.append(royalty)
		}
		
		access(all)
		fun addTemplate(templateID: UInt64, available: Bool){ 
			pre{ 
				SturdyTokens.sturdyTokensTemplates[templateID] != nil:
					"Template doesn't exist"
				!self.locked:
					"Cannot add template - set is locked"
				!self.templateIDs.contains(templateID):
					"Cannot add template - template is already added to the set"
				!((SturdyTokens.sturdyTokensTemplates[templateID]!).addedToSet != 0):
					"Cannot add template - template is already added to another set"
			}
			self.templateIDs.append(templateID)
			if available{ 
				self.availableTemplateIDs.append(templateID)
			}
			self.lockedTemplates[templateID] = !available
			(SturdyTokens.sturdyTokensTemplates[templateID]!).markAddedToSet(setID: self.setID)
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
			if (SturdyTokens.sturdyTokensTemplates[templateID]!).locked{ 
				panic("template is locked")
			}
			let newNFT: @NFT <- create SturdyTokens.NFT(initID: SturdyTokens.nextNFTID, initTemplateID: templateID, serialNumber: self.nextSetSerialNumber)
			SturdyTokens.totalSupply = SturdyTokens.totalSupply + 1
			SturdyTokens.nextNFTID = SturdyTokens.nextNFTID + 1
			self.nextSetSerialNumber = self.nextSetSerialNumber + 1
			self.availableTemplateIDs.remove(at: 0)
			emit Minted(id: newNFT.id, templateID: newNFT.templateID)
			return <-newNFT
		}
		
		access(all)
		fun mintNFTByTemplateID(templateID: UInt64): @NFT{ 
			let newNFT: @NFT <- create SturdyTokens.NFT(initID: templateID, initTemplateID: templateID, serialNumber: self.nextSetSerialNumber)
			SturdyTokens.totalSupply = SturdyTokens.totalSupply + 1
			self.nextSetSerialNumber = self.nextSetSerialNumber + 1
			self.lockTemplate(templateID: templateID)
			emit Minted(id: newNFT.id, templateID: newNFT.templateID)
			return <-newNFT
		}
		
		access(all)
		fun updateTemplateMetadata(templateID: UInt64, newMetadata:{ String: String}): SturdyTokensTemplate{ 
			pre{ 
				SturdyTokens.sturdyTokensTemplates[templateID] != nil:
					"Template doesn't exist"
				!self.locked:
					"Cannot edit template - set is locked"
			}
			(SturdyTokens.sturdyTokensTemplates[templateID]!).updateMetadata(newMetadata: newMetadata)
			emit TemplateUpdated(template: SturdyTokens.sturdyTokensTemplates[templateID]!)
			return SturdyTokens.sturdyTokensTemplates[templateID]!
		}
	}
	
	access(all)
	fun getSetName(setID: UInt64): String{ 
		pre{ 
			SturdyTokens.sets[setID] != nil:
				"Cannot borrow Set: The Set doesn't exist"
		}
		let set = (&SturdyTokens.sets[setID] as &Set?)!
		return set.name
	}
	
	access(all)
	fun getSetRoyalties(setID: UInt64): [Royalty]{ 
		pre{ 
			SturdyTokens.sets[setID] != nil:
				"Cannot borrow Set: The Set doesn't exist"
		}
		let set = (&SturdyTokens.sets[setID] as &Set?)!
		var sturdyRoyaltyPrimaryCut: UFix64 = 1.00
		// for royalty in set.artistRoyalties {
		//   sturdyRoyaltyPrimaryCut = sturdyRoyaltyPrimaryCut - royalty.primaryCut
		// }
		let royalties = [Royalty(address: 0xd43cf319894f9662, primaryCut: sturdyRoyaltyPrimaryCut, secondaryCut: 0.10, description: "Sturdy Royalty")]
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
			if SturdyTokens.sturdyTokensTemplates[templateID] != nil{ 
				panic("Template already exists")
			}
			SturdyTokens.sturdyTokensTemplates[templateID] = SturdyTokensTemplate(templateID: templateID, name: name, description: description, metadata: metadata)
			let set = self.borrowSet(setID: setID)
			set.addTemplate(templateID: templateID, available: false)
			recipient.deposit(token: <-set.mintNFTByTemplateID(templateID: templateID))
		}
		
		access(all)
		fun createSturdyTokensTemplate(name: String, description: String, metadata:{ String: String}){ 
			SturdyTokens.sturdyTokensTemplates[SturdyTokens.nextTemplateID] = SturdyTokensTemplate(templateID: SturdyTokens.nextTemplateID, name: name, description: description, metadata: metadata)
			SturdyTokens.nextTemplateID = SturdyTokens.nextTemplateID + 1
		}
		
		access(all)
		fun createSet(name: String, sturdyRoyaltyAddress: Address, sturdyRoyaltySecondaryCut: UFix64): UInt64{ 
			var newSet <- create Set(name: name, sturdyRoyaltyAddress: sturdyRoyaltyAddress, sturdyRoyaltySecondaryCut: sturdyRoyaltySecondaryCut)
			let setID = newSet.setID
			SturdyTokens.sets[setID] <-! newSet
			return setID
		}
		
		access(all)
		fun borrowSet(setID: UInt64): &Set{ 
			pre{ 
				SturdyTokens.sets[setID] != nil:
					"Cannot borrow Set: The Set doesn't exist"
			}
			return (&SturdyTokens.sets[setID] as &Set?)!
		}
		
		access(all)
		fun updateSturdyTokensTemplate(templateID: UInt64, newMetadata:{ String: String}){ 
			pre{ 
				SturdyTokens.sturdyTokensTemplates.containsKey(templateID) != nil:
					"Template does not exists."
			}
			(SturdyTokens.sturdyTokensTemplates[templateID]!).updateMetadata(newMetadata: newMetadata)
		}
		
		access(all)
		fun setInitialNFTID(initialNFTID: UInt64){ 
			pre{ 
				SturdyTokens.initialNFTID == 0:
					"initialNFTID is already initialized"
			}
			SturdyTokens.initialNFTID = initialNFTID
			SturdyTokens.nextNFTID = initialNFTID
			SturdyTokens.nextTemplateID = initialNFTID
		}
	}
	
	access(all)
	fun getSturdyTokensTemplateByID(templateID: UInt64): SturdyTokens.SturdyTokensTemplate{ 
		return SturdyTokens.sturdyTokensTemplates[templateID]!
	}
	
	access(all)
	fun getSturdyTokensTemplates():{ UInt64: SturdyTokens.SturdyTokensTemplate}{ 
		return SturdyTokens.sturdyTokensTemplates
	}
	
	access(all)
	fun getAvailableTemplateIDsInSet(setID: UInt64): [UInt64]{ 
		pre{ 
			SturdyTokens.sets[setID] != nil:
				"Cannot borrow Set: The Set doesn't exist"
		}
		let set = (&SturdyTokens.sets[setID] as &Set?)!
		return set.getAvailableTemplateIDs()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/SturdyTokensCollection
		self.CollectionPublicPath = /public/SturdyTokensCollection
		self.AdminStoragePath = /storage/SturdyTokensAdmin
		self.totalSupply = 0
		self.nextSetID = 1
		self.initialNFTID = 0
		self.nextNFTID = 0
		self.nextTemplateID = 0
		self.sets <-{} 
		self.sturdyTokensTemplates ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
