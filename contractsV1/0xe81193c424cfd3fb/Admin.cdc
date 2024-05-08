// SPDX-License-Identifier: MIT
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import Debug from "./Debug.cdc"

import Clock from "./Clock.cdc"

import Templates from "./Templates.cdc"

import Wearables from "./Wearables.cdc"

import Doodles from "./Doodles.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import Redeemables from "./Redeemables.cdc"

import TransactionsRegistry from "./TransactionsRegistry.cdc"

import DoodlePacks from "./DoodlePacks.cdc"

import DoodlePackTypes from "./DoodlePackTypes.cdc"

import OpenDoodlePacks from "./OpenDoodlePacks.cdc"

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
	
	// This is just an empty resource to signal that you can control the admin, more logic can be added here or changed later if you want to
	access(all)
	resource Server{} 
	
	/// ==================================================================================
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
		fun registerWearableSet(_ s: Wearables.Set){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Wearables.addSet(s)
		}
		
		access(all)
		fun retireWearableSet(_ id: UInt64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Wearables.retireSet(id)
		}
		
		access(all)
		fun registerWearablePosition(_ p: Wearables.Position){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Wearables.addPosition(p)
		}
		
		access(all)
		fun retireWearablePosition(_ id: UInt64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Wearables.retirePosition(id)
		}
		
		access(all)
		fun registerWearableTemplate(_ t: Wearables.Template){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Wearables.addTemplate(t)
		}
		
		access(all)
		fun retireWearableTemplate(_ id: UInt64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Wearables.retireTemplate(id)
		}
		
		access(all)
		fun updateWearableTemplateDescription(templateId: UInt64, description: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Wearables.updateTemplateDescription(templateId: templateId, description: description)
		}
		
		access(all)
		fun mintWearable(recipient: &{NonFungibleToken.Receiver}, template: UInt64, context:{ String: String}){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Wearables.mintNFT(recipient: recipient, template: template, context: context)
		}
		
		access(all)
		fun mintWearableDirect(recipientAddress: Address, template: UInt64, context:{ String: String}): @Wearables.NFT{ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let newWearable <- Wearables.mintNFTDirect(recipientAddress: recipientAddress, template: template, context: context)
			return <-newWearable
		}
		
		access(all)
		fun mintEditionWearable(recipient: &{NonFungibleToken.Receiver}, data: Wearables.WearableMintData, context:{ String: String}){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Wearables.mintEditionNFT(recipient: recipient, template: data.template, setEdition: data.setEdition, positionEdition: data.positionEdition, templateEdition: data.templateEdition, taggedTemplateEdition: data.taggedTemplateEdition, tagEditions: data.tagEditions, context: context)
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
		fun setFeature(action: String, enabled: Bool){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Templates.setFeature(action: action, enabled: enabled)
		}
		
		access(all)
		fun resetCounter(){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Templates.resetCounters()
		}
		
		access(all)
		fun registerDoodlesBaseCharacter(_ d: Doodles.BaseCharacter){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Doodles.setBaseCharacter(d)
		}
		
		access(all)
		fun retireDoodlesBaseCharacter(_ id: UInt64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Doodles.retireBaseCharacter(id)
		}
		
		access(all)
		fun registerDoodlesSpecies(_ d: Doodles.Species){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Doodles.addSpecies(d)
		}
		
		access(all)
		fun retireDoodlesSpecies(_ id: UInt64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Doodles.retireSpecies(id)
		}
		
		access(all)
		fun registerDoodlesSet(_ d: Doodles.Set){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Doodles.addSet(d)
		}
		
		access(all)
		fun retireDoodlesSet(_ id: UInt64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Doodles.retireSet(id)
		}
		
		access(all)
		fun mintDoodles(recipientAddress: Address, doodleName: String, baseCharacter: UInt64, context:{ String: String}): @Doodles.NFT{ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let doodle <- Doodles.adminMintDoodle(recipientAddress: recipientAddress, doodleName: doodleName, baseCharacter: baseCharacter, context: context)
			return <-doodle
		}
		
		access(all)
		fun createRedeemablesSet(name: String, canRedeem: Bool, redeemLimitTimestamp: UFix64, active: Bool){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Redeemables.createSet(name: name, canRedeem: canRedeem, redeemLimitTimestamp: redeemLimitTimestamp, active: active)
		}
		
		access(all)
		fun updateRedeemablesSetActive(setId: UInt64, active: Bool){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Redeemables.updateSetActive(setId: setId, active: active)
		}
		
		access(all)
		fun updateRedeemablesSetCanRedeem(setId: UInt64, canRedeem: Bool){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Redeemables.updateSetCanRedeem(setId: setId, canRedeem: canRedeem)
		}
		
		access(all)
		fun updateRedeemablesSetRedeemLimitTimestamp(setId: UInt64, redeemLimitTimestamp: UFix64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Redeemables.updateSetRedeemLimitTimestamp(setId: setId, redeemLimitTimestamp: redeemLimitTimestamp)
		}
		
		access(all)
		fun createRedeemablesTemplate(setId: UInt64, name: String, description: String, brand: String, royalties: [MetadataViews.Royalty], type: String, thumbnail: MetadataViews.Media, image: MetadataViews.Media, active: Bool, extra:{ String: AnyStruct}){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Redeemables.createTemplate(setId: setId, name: name, description: description, brand: brand, royalties: royalties, type: type, thumbnail: thumbnail, image: image, active: active, extra: extra)
		}
		
		access(all)
		fun updateRedeemablesTemplateActive(templateId: UInt64, active: Bool){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Redeemables.updateTemplateActive(templateId: templateId, active: active)
		}
		
		access(all)
		fun mintRedeemablesNFT(recipient: &{NonFungibleToken.Receiver}, templateId: UInt64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Redeemables.mintNFT(recipient: recipient, templateId: templateId)
		}
		
		access(all)
		fun burnRedeemablesUnredeemedSet(setId: UInt64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Redeemables.burnUnredeemedSet(setId: setId)
		}
		
		access(all)
		fun registerDoodlesDropsWearablesMintTransaction(packTypeId: UInt64, packId: UInt64, transactionId: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			TransactionsRegistry.registerDoodlesDropsWearablesMint(packTypeId: packTypeId, packId: packId, transactionId: transactionId)
		}
		
		access(all)
		fun registerDoodlesDropsRedeemablesMintTransaction(packTypeId: UInt64, packId: UInt64, transactionId: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			TransactionsRegistry.registerDoodlesDropsRedeemablesMint(packTypeId: packTypeId, packId: packId, transactionId: transactionId)
		}
		
		access(all)
		fun registerTransaction(name: String, args: [String], value: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			TransactionsRegistry.register(name: name, args: args, value: value)
		}
		
		access(all)
		fun mintPack(recipient: &{NonFungibleToken.Receiver}, typeId: UInt64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			DoodlePacks.mintNFT(recipient: recipient, typeId: typeId)
		}
		
		access(all)
		fun addPackType(id: UInt64, name: String, description: String, thumbnail: MetadataViews.Media, image: MetadataViews.Media, amountOfTokens: UInt8, templateDistributions: [DoodlePackTypes.TemplateDistribution], maxSupply: UInt64?): DoodlePackTypes.PackType{ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			return DoodlePackTypes.addPackType(id: id, name: name, description: description, thumbnail: thumbnail, image: image, amountOfTokens: amountOfTokens, templateDistributions: templateDistributions, maxSupply: maxSupply)
		}
		
		access(all)
		fun updatePackRevealBlocks(revealBlocks: UInt64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			OpenDoodlePacks.updateRevealBlocks(revealBlocks: revealBlocks)
		}
		
		init(){ 
			self.capability = nil
		}
	}
	
	init(){ 
		self.AdminProxyPublicPath = /public/characterAdminProxy
		self.AdminProxyStoragePath = /storage/characterAdminProxy
		
		//create a dummy server for now, if we have a resource later we want to use instead of server we can change to that
		self.AdminServerPrivatePath = /private/characterAdminServer
		self.AdminServerStoragePath = /storage/characterAdminServer
		self.account.storage.save(<-create Server(), to: self.AdminServerStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&Server>(self.AdminServerStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminServerPrivatePath)
	}
}
