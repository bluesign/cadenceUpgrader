import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import Debug from "./Debug.cdc"

import Clock from "./Clock.cdc"

import AeraNFT from "./AeraNFT.cdc"

import AeraPack from "./AeraPack.cdc"

import AeraPackExtraData from "./AeraPackExtraData.cdc"

import AeraPanels from "./AeraPanels.cdc"

import AeraRewards from "./AeraRewards.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FindViews from "../0x097bafa4e0b48eef/FindViews.cdc"

access(all)
contract Admin{ 
	
	//store the proxy for the admin
	access(all)
	let AdminProxyPublicPath: PublicPath
	
	access(all)
	let AdminProxyStoragePath: StoragePath
	
	access(all)
	let AdminServerStoragePath: StoragePath
	
	access(all)
	let AdminServerPrivatePath: PrivatePath
	
	access(all)
	event BurnedPack(packId: UInt64, packTypeId: UInt64)
	
	// This is just an empty resource to signal that you can control the admin, more logic can be added here or changed later if you want to
	access(all)
	resource Server{} 
	
	/// ===================================================================================
	// Admin things
	/// ===================================================================================
	//Admin client to use for capability receiver pattern
	access(all)
	fun createAdminProxyClient(): @AdminProxy{ 
		return <-create AdminProxy()
	}
	
	//interface to use for capability receiver pattern
	access(all)
	resource interface AdminProxyClient{ 
		access(all)
		fun addCapability(_ cap: Capability<&Server>)
	}
	
	//admin proxy with capability receiver 
	access(all)
	resource AdminProxy: AdminProxyClient{ 
		access(self)
		var capability: Capability<&Server>?
		
		access(all)
		fun addCapability(_ cap: Capability<&Server>){ 
			pre{ 
				cap.check():
					"Invalid server capablity"
				self.capability == nil:
					"Server already set"
			}
			self.capability = cap
		}
		
		access(all)
		fun registerGame(_ game: AeraNFT.Game){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			AeraNFT.addGame(game)
		}
		
		access(all)
		fun registerPlayMetadata(_ play: AeraNFT.PlayMetadata){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			AeraNFT.addPlayMetadata(play)
		}
		
		access(all)
		fun registerLicense(_ license: AeraNFT.License){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			AeraNFT.addLicense(license)
		}
		
		access(all)
		fun registerPlayer(_ player: AeraNFT.Player){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			AeraNFT.addPlayer(player)
		}
		
		access(all)
		fun mintAeraWithBadges(recipient: &{NonFungibleToken.Receiver}, edition: UInt64, play: AeraNFT.Play, badges: [AeraNFT.Badge]){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			AeraNFT.mintNFT(recipient: recipient, edition: edition, play: play, badges: badges)
		}
		
		access(all)
		fun mintAera(recipient: &{NonFungibleToken.Receiver}, edition: UInt64, play: AeraNFT.Play){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			AeraNFT.mintNFT(recipient: recipient, edition: edition, play: play, badges: [])
		}
		
		access(all)
		fun advanceClock(_ time: UFix64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Debug.enable(true)
			Clock.enable()
			Clock.tick(time)
		}
		
		access(all)
		fun debug(_ value: Bool){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Debug.enable(value)
		}
		
		access(all)
		fun setPacksLeftForType(_ type: UInt64, amount: UInt64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let packs = Admin.account.storage.borrow<&AeraPack.Collection>(from: AeraPack.CollectionStoragePath)!
			packs.setPacksLeftForType(type, amount: amount)
		}
		
		access(all)
		fun registerPackMetadata(typeId: UInt64, metadata: AeraPack.Metadata, items: Int, tier: String, receiverPath: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			AeraPack.registerMetadata(typeId: typeId, metadata: metadata)
			AeraPackExtraData.registerItemsForPackType(typeId: typeId, items: items)
			AeraPackExtraData.registerTierForPackType(typeId: typeId, tier: tier)
			AeraPackExtraData.registerReceiverPathForPackType(typeId: typeId, receiverPath: receiverPath)
		}
		
		access(all)
		fun batchMintPacks(typeId: UInt64, hashes: [String]){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let recipient = Admin.account.capabilities.get<&{NonFungibleToken.Receiver}>(AeraPack.CollectionPublicPath).borrow()!
			for hash in hashes{ 
				AeraPack.mintNFT(recipient: recipient, typeId: typeId, hash: hash)
			}
		}
		
		access(all)
		fun requeue(packId: UInt64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let cap = Admin.account.storage.borrow<&AeraPack.Collection>(from: AeraPack.DLQCollectionStoragePath)!
			cap.requeue(packId: packId)
		}
		
		access(all)
		fun fulfill(packId: UInt64, rewardIds: [UInt64], salt: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			AeraPack.fulfill(packId: packId, rewardIds: rewardIds, salt: salt)
		}
		
		access(all)
		fun transfer(fromPath: String, toPath: String, ids: [UInt64]){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let sp = StoragePath(identifier: fromPath) ?? panic("Invalid path ".concat(fromPath))
			let treasuryPath = PublicPath(identifier: toPath) ?? panic("Invalid toPath ".concat(toPath))
			let collection = Admin.account.capabilities.get<&{NonFungibleToken.Receiver}>(treasuryPath).borrow() ?? panic("Could not borrow nft.cp at toPath ".concat(toPath).concat(" address ").concat(Admin.account.address.toString()))
			self.sendNFT(storagePath: fromPath, recipient: collection, ids: ids)
		}
		
		access(all)
		fun sendNFT(storagePath: String, recipient: &{NonFungibleToken.Receiver}, ids: [UInt64]){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let sp = StoragePath(identifier: storagePath) ?? panic("Invalid path ".concat(storagePath))
			let collection = Admin.account.storage.borrow<&{NonFungibleToken.Collection}>(from: sp) ?? panic("Could not borrow collection at path ".concat(storagePath))
			for id in ids{ 
				recipient.deposit(token: <-collection.withdraw(withdrawID: id))
			}
		}
		
		access(all)
		fun getAuthPointer(pathIdentifier: String, id: UInt64): FindViews.AuthNFTPointer{ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let privatePath = PrivatePath(identifier: pathIdentifier)!
			var cap = Admin.account.capabilities.get<&{ViewResolver.ResolverCollection, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(privatePath)
			if !cap.check(){ 
				let storagePath = StoragePath(identifier: pathIdentifier)!
				Admin.account.link<&{MetadataViews.ResolverCollection, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(privatePath, target: storagePath)
				cap = Admin.account.capabilities.get<&{ViewResolver.ResolverCollection, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(privatePath)
			}
			return FindViews.AuthNFTPointer(cap: cap!, id: id)
		}
		
		access(all)
		fun getProviderCapForPath(path: PrivatePath): Capability<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection}>{ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			return Admin.account.capabilities.get<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection}>(path)!
		}
		
		access(all)
		fun getProviderCap(): Capability<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection}>{ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			return Admin.account.capabilities.get<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection}>(AeraNFT.CollectionPrivatePath)!
		}
		
		access(all)
		fun burn(storagePath: String, ids: [UInt64]){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let sp = StoragePath(identifier: storagePath) ?? panic("Invalid path ".concat(storagePath))
			let collection = Admin.account.storage.borrow<&{NonFungibleToken.Collection}>(from: sp) ?? panic("Could not borrow collection at path ".concat(storagePath))
			for id in ids{ 
				let item <- collection.withdraw(withdrawID: id) as! @AeraPack.NFT
				emit BurnedPack(packId: id, packTypeId: item.getTypeID())
				destroy <-item
			}
		}
		
		access(all)
		fun burnNFT(storagePath: String, ids: [UInt64]){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let sp = StoragePath(identifier: storagePath) ?? panic("Invalid path ".concat(storagePath))
			let collection = Admin.account.storage.borrow<&AeraNFT.Collection>(from: sp) ?? panic("Could not borrow collection at path ".concat(storagePath))
			for id in ids{ 
				collection.burn(id)
			}
		}
		
		access(all)
		fun registerPanelTemplate(panel: AeraPanels.PanelTemplate, mint_count: UInt64?){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			AeraPanels.addPanelTemplate(panel: panel, mint_count: mint_count)
		}
		
		access(all)
		fun registerChapterTemplate(_ chapter: AeraPanels.ChapterTemplate){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			AeraPanels.addChapterTemplate(chapter)
		}
		
		access(all)
		fun mintAeraPanel(recipient: &{NonFungibleToken.Receiver}, edition: UInt64, panelTemplateId: UInt64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			AeraPanels.mintNFT(recipient: recipient, edition: edition, panelTemplateId: panelTemplateId)
		}
		
		access(all)
		fun registerRewardTemplate(reward: AeraRewards.RewardTemplate, maxQuantity: UInt64?){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			AeraRewards.addRewardTemplate(reward: reward, maxQuantity: maxQuantity)
		}
		
		access(all)
		fun mintAeraReward(recipient: &{NonFungibleToken.Receiver}, rewardTemplateId: UInt64, rewardFields:{ UInt64:{ String: String}}): UInt64{ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			return AeraRewards.mintNFT(recipient: recipient, rewardTemplateId: rewardTemplateId, rewardFields: rewardFields)
		}
		
		init(){ 
			self.capability = nil
		}
	}
	
	init(){ 
		self.AdminProxyPublicPath = /public/onefootballAdminProxy
		self.AdminProxyStoragePath = /storage/onefootballAdminProxy
		
		//create a dummy server for now, if we have a resource later we want to use instead of server we can change to that
		self.AdminServerPrivatePath = /private/onefootballAdminServer
		self.AdminServerStoragePath = /storage/onefootballAdminServer
		self.account.storage.save(<-create Server(), to: self.AdminServerStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&Server>(self.AdminServerStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminServerPrivatePath)
	}
}
