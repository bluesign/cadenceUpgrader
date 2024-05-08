// SPDX-License-Identifier: UNLICENSED
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import Patch from "./Patch.cdc"

access(all)
contract Backpack: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event SetCreated(setID: UInt64)
	
	access(all)
	event NFTTemplateCreated(templateID: UInt64, metadata:{ String: String}, slots: UInt64)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64, templateID: UInt64)
	
	access(all)
	event Burn(id: UInt64)
	
	access(all)
	event TemplateAddedToSet(setID: UInt64, templateID: UInt64)
	
	access(all)
	event TemplateLockedFromSet(setID: UInt64, templateID: UInt64)
	
	access(all)
	event TemplateUpdated(template: BackpackTemplate)
	
	access(all)
	event SetLocked(setID: UInt64)
	
	access(all)
	event PatchAddedToBackpack(backpackId: UInt64, patchIds: [UInt64])
	
	access(all)
	event PatchRemovedFromBackpack(backpackId: UInt64, patchIds: [UInt64])
	
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
	var BackpackTemplates:{ UInt64: BackpackTemplate}
	
	access(self)
	var sets: @{UInt64: Set}
	
	access(all)
	resource interface BackpackCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowBackpack(id: UInt64): &Backpack.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Backpack reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	struct BackpackTemplate{ 
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
		
		access(all)
		var slots: UInt64
		
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
		fun updateMetadata(newMetadata:{ String: String}, newSlots: UInt64){ 
			pre{ 
				newMetadata.length != 0:
					"New Template metadata cannot be empty"
				newSlots <= 20:
					"Slot cannot be more than 20"
			}
			self.metadata = newMetadata
			self.slots = newSlots
		}
		
		access(all)
		fun incrementSlot(){ 
			pre{ 
				self.slots + 1 <= 20:
					"reached maximum slot capacity"
			}
			self.slots = self.slots + 1
		}
		
		access(all)
		fun markAddedToSet(setID: UInt64){ 
			self.addedToSet = setID
		}
		
		init(templateID: UInt64, name: String, description: String, metadata:{ String: String}, slots: UInt64){ 
			pre{ 
				metadata.length != 0:
					"New Template metadata cannot be empty"
			}
			self.templateID = templateID
			self.name = name
			self.description = description
			self.metadata = metadata
			self.slots = slots
			self.locked = false
			self.addedToSet = 0
			Backpack.nextTemplateID = Backpack.nextTemplateID + 1
			emit NFTTemplateCreated(templateID: self.templateID, metadata: self.metadata, slots: slots)
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
		
		access(self)
		let patches: @Patch.Collection
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Edition>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.getNFTTemplate().name, description: self.getNFTTemplate().description, thumbnail: MetadataViews.HTTPFile(url: self.getNFTTemplate().getMetadata()["uri"]!))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://flunks.io/")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Backpack.CollectionStoragePath, publicPath: Backpack.CollectionPublicPath, publicCollection: Type<&Backpack.Collection>(), publicLinkedType: Type<&Backpack.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Backpack.createEmptyCollection(nftType: Type<@Backpack.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/flunks_public/website-assets/classroom.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "Backpack", description: "Backpack #onFlow", externalURL: MetadataViews.ExternalURL("https://flunks.io/"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/flunks_nft")})
				case Type<MetadataViews.Traits>():
					let excludedTraits = ["mimetype", "uri", "pixelUri", "path", "cid"]
					let traitsView = MetadataViews.dictToTraits(dict: self.getNFTTemplate().getMetadata(), excludedNames: excludedTraits)
					return traitsView
				case Type<MetadataViews.Edition>():
					return MetadataViews.Edition(name: "Backpack", number: self.serialNumber, max: 9999)
				case Type<MetadataViews.Royalties>():
					// Note: replace the address for different merchant accounts across various networks
					let merchant = getAccount(0x0cce91b08cb58286)
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: merchant.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)!, cut: 0.05, description: "Flunks creator royalty in DUC")])
			}
			return nil
		}
		
		access(all)
		fun getNFTTemplate(): BackpackTemplate{ 
			return Backpack.BackpackTemplates[self.templateID]!
		}
		
		access(contract)
		fun addPatches(patches: @Patch.Collection){ 
			pre{ 
				UInt64(patches.getIDs().length) + UInt64(self.patches.getIDs().length) <= self.getSlots():
					"reached maximum patch capacity"
			}
			let patchIDs = patches.getIDs()
			self.patches.batchDeposit(collection: <-patches)
			emit PatchAddedToBackpack(backpackId: self.id, patchIds: patchIDs)
		}
		
		access(all)
		view fun getSlots(): UInt64{ 
			return (Backpack.BackpackTemplates[self.templateID]!).slots
		}
		
		access(all)
		fun getPatchIds(): [UInt64]{ 
			return self.patches.getIDs()
		}
		
		access(all)
		fun getNFTMetadata():{ String: String}{ 
			return (Backpack.BackpackTemplates[self.templateID]!).getMetadata()
		}
		
		access(contract)
		fun removePatches(patchTokenIDs: [UInt64]): @Patch.Collection{ 
			let removedPatches <- Patch.createEmptyCollection(nftType: Type<@Patch.Collection>()) as! @Patch.Collection
			for patchTokenId in patchTokenIDs{ 
				removedPatches.deposit(token: <-self.patches.withdraw(withdrawID: patchTokenId))
			}
			let patchIDs = removedPatches.getIDs()
			emit PatchRemovedFromBackpack(backpackId: self.id, patchIds: patchIDs)
			return <-removedPatches
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, initTemplateID: UInt64, serialNumber: UInt64){ 
			self.id = initID
			self.templateID = initTemplateID
			self.serialNumber = serialNumber
			self.patches <- Patch.createEmptyCollection(nftType: Type<@Patch.Collection>()) as! @Patch.Collection
		}
	}
	
	access(all)
	resource Collection: BackpackCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @Backpack.NFT
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
		fun borrowBackpack(id: UInt64): &Backpack.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Backpack.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let exampleNFT = nft as! &Backpack.NFT
			return exampleNFT as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun addPatches(tokenID: UInt64, patches: @Patch.Collection){ 
			pre{ 
				self.ownedNFTs.keys.contains(tokenID):
					"invalid tokenID - not in collection"
			}
			let backpackRef = self.borrowBackpack(id: tokenID)!
			backpackRef.addPatches(patches: <-patches)
		}
		
		access(all)
		fun removePatches(tokenID: UInt64, patchTokenIDs: [UInt64]): @Patch.Collection{ 
			pre{ 
				self.ownedNFTs.keys.contains(tokenID):
					"invalid tokenID - not in collection"
			}
			let backpackRef = self.borrowBackpack(id: tokenID)!
			return <-backpackRef.removePatches(patchTokenIDs: patchTokenIDs)
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
			self.setID = Backpack.nextSetID
			self.templateIDs = []
			self.lockedTemplates ={} 
			self.locked = false
			self.availableTemplateIDs = []
			self.nextSetSerialNumber = 1
			self.isPublic = false
			Backpack.nextSetID = Backpack.nextSetID + 1
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
				Backpack.BackpackTemplates[templateID] != nil:
					"Template doesn't exist"
				!self.locked:
					"Cannot add template - set is locked"
				!self.templateIDs.contains(templateID):
					"Cannot add template - template is already added to the set"
				!((Backpack.BackpackTemplates[templateID]!).addedToSet != 0):
					"Cannot add template - template is already added to another set"
			}
			self.templateIDs.append(templateID)
			self.availableTemplateIDs.append(templateID)
			self.lockedTemplates[templateID] = false
			(Backpack.BackpackTemplates[templateID]!).markAddedToSet(setID: self.setID)
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
			if (Backpack.BackpackTemplates[templateID]!).locked{ 
				panic("template is locked")
			}
			let newNFT: @NFT <- create Backpack.NFT(initID: Backpack.totalSupply, initTemplateID: templateID, serialNumber: self.nextSetSerialNumber)
			Backpack.totalSupply = Backpack.totalSupply + 1
			self.nextSetSerialNumber = self.nextSetSerialNumber + 1
			self.availableTemplateIDs.remove(at: 0)
			emit Mint(id: newNFT.id, templateID: newNFT.getNFTTemplate().templateID)
			return <-newNFT
		}
		
		access(all)
		fun updateTemplateMetadata(templateID: UInt64, newMetadata:{ String: String}, newSlots: UInt64): BackpackTemplate{ 
			pre{ 
				Backpack.BackpackTemplates[templateID] != nil:
					"Template doesn't exist"
				!self.locked:
					"Cannot edit template - set is locked"
			}
			(Backpack.BackpackTemplates[templateID]!).updateMetadata(newMetadata: newMetadata, newSlots: newSlots)
			emit TemplateUpdated(template: Backpack.BackpackTemplates[templateID]!)
			return Backpack.BackpackTemplates[templateID]!
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
		fun createBackpackTemplate(name: String, description: String, metadata:{ String: String}, slots: UInt64){ 
			Backpack.BackpackTemplates[Backpack.nextTemplateID] = BackpackTemplate(templateID: Backpack.nextTemplateID, name: name, description: description, metadata: metadata, slots: slots)
		}
		
		access(all)
		fun createSet(name: String){ 
			var newSet <- create Set(name: name)
			Backpack.sets[newSet.setID] <-! newSet
		}
		
		access(all)
		fun borrowSet(setID: UInt64): &Set{ 
			pre{ 
				Backpack.sets[setID] != nil:
					"Cannot borrow Set: The Set doesn't exist"
			}
			return (&Backpack.sets[setID] as &Set?)!
		}
		
		access(all)
		fun updateBackpackTemplate(templateID: UInt64, newMetadata:{ String: String}, newSlots: UInt64){ 
			pre{ 
				Backpack.BackpackTemplates.containsKey(templateID) != nil:
					"Template does not exits."
			}
			(Backpack.BackpackTemplates[templateID]!).updateMetadata(newMetadata: newMetadata, newSlots: newSlots)
		}
		
		access(all)
		fun incrementBackpackSlot(templateID: UInt64){ 
			pre{ 
				Backpack.BackpackTemplates.containsKey(templateID) != nil:
					"Template does not exits."
			}
			(Backpack.BackpackTemplates[templateID]!).incrementSlot()
			emit TemplateUpdated(template: Backpack.BackpackTemplates[templateID]!)
		}
	}
	
	access(all)
	fun getBackpackTemplateByID(templateID: UInt64): Backpack.BackpackTemplate{ 
		return Backpack.BackpackTemplates[templateID]!
	}
	
	access(all)
	fun getBackpackTemplates():{ UInt64: Backpack.BackpackTemplate}{ 
		return Backpack.BackpackTemplates
	}
	
	access(all)
	fun getAvailableTemplateIDsInSet(setID: UInt64): [UInt64]{ 
		pre{ 
			Backpack.sets[setID] != nil:
				"Cannot borrow Set: The Set doesn't exist"
		}
		let set = (&Backpack.sets[setID] as &Set?)!
		return set.getAvailableTemplateIDs()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/BackpackCollection
		self.CollectionPublicPath = /public/BackpackCollection
		self.AdminStoragePath = /storage/BackpackAdmin
		self.totalSupply = 0
		self.nextTemplateID = 1
		self.nextSetID = 1
		self.sets <-{} 
		self.BackpackTemplates ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
