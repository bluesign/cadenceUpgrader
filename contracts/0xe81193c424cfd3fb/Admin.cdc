// SPDX-License-Identifier: MIT

import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import Debug from "./Debug.cdc"
import Clock from "./Clock.cdc"
import Templates from "./Templates.cdc"
import Wearables from "./Wearables.cdc"
import Doodles from "./Doodles.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import Redeemables from "./Redeemables.cdc"
import TransactionsRegistry from "./TransactionsRegistry.cdc"
import DoodlePacks from "./DoodlePacks.cdc"
import DoodlePackTypes from "./DoodlePackTypes.cdc"
import OpenDoodlePacks from "./OpenDoodlePacks.cdc"

pub contract Admin {

	//store the proxy for the admin
	pub let AdminProxyPublicPath: PublicPath
	pub let AdminProxyStoragePath: StoragePath
	pub let AdminServerStoragePath: StoragePath
	pub let AdminServerPrivatePath: PrivatePath


	// This is just an empty resource to signal that you can control the admin, more logic can be added here or changed later if you want to
	pub resource Server {

	}

	/// ==================================================================================
	// Admin things
	/// ===================================================================================

	//Admin client to use for capability receiver pattern
	pub fun createAdminProxyClient() : @AdminProxy {
		return <- create AdminProxy()
	}

	//interface to use for capability receiver pattern
	pub resource interface AdminProxyClient {
		pub fun addCapability(_ cap: Capability<&Server>)
	}


	//admin proxy with capability receiver
	pub resource AdminProxy: AdminProxyClient {

		access(self) var capability: Capability<&Server>?

		pub fun addCapability(_ cap: Capability<&Server>) {
			pre {
				cap.check() : "Invalid server capablity"
				self.capability == nil : "Server already set"
			}
			self.capability = cap
		}

		pub fun registerWearableSet(_ s: Wearables.Set) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Wearables.addSet(s)
		}

		pub fun retireWearableSet(_ id:UInt64) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Wearables.retireSet(id)
		}

		pub fun registerWearablePosition(_ p: Wearables.Position) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Wearables.addPosition(p)
		}

		pub fun retireWearablePosition(_ id:UInt64) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Wearables.retirePosition(id)
		}

		pub fun registerWearableTemplate(_ t: Wearables.Template) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Wearables.addTemplate(t)
		}

		pub fun retireWearableTemplate(_ id:UInt64) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Wearables.retireTemplate(id)
		}

		pub fun updateWearableTemplateDescription(templateId: UInt64, description: String) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Wearables.updateTemplateDescription(templateId: templateId, description: description)
		}

		pub fun mintWearable(
			recipient: &{NonFungibleToken.Receiver},
			template: UInt64,
			context: {String : String}
		){

			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}

			Wearables.mintNFT(
				recipient: recipient,
				template: template,
				context: context
			)
		}

		pub fun mintWearableDirect(
			recipientAddress: Address,
			template: UInt64,
			context: {String : String}
		): @Wearables.NFT {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}

			let newWearable <- Wearables.mintNFTDirect(
				recipientAddress: recipientAddress,
				template: template,
				context: context
			)

			return <- newWearable
		}

		pub fun mintEditionWearable(
			recipient: &{NonFungibleToken.Receiver},
			data: Wearables.WearableMintData,
			context: {String : String}
		){

			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}

			Wearables.mintEditionNFT(
				recipient: recipient,
				template: data.template,
				setEdition: data.setEdition,
				positionEdition: data.positionEdition,
				templateEdition: data.templateEdition,
				taggedTemplateEdition: data.taggedTemplateEdition,
				tagEditions: data.tagEditions,
				context: context
			)
		}

		pub fun advanceClock(_ time: UFix64) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Debug.enable(true)
			Clock.enable()
			Clock.tick(time)
		}


		pub fun debug(_ value: Bool) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Debug.enable(value)
		}

		pub fun setFeature(action: String, enabled: Bool) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Templates.setFeature(action: action, enabled: enabled)
		}

		pub fun resetCounter() {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Templates.resetCounters()
		}

		pub fun registerDoodlesBaseCharacter(_ d: Doodles.BaseCharacter) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Doodles.setBaseCharacter(d)
		}

		pub fun retireDoodlesBaseCharacter(_ id: UInt64) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Doodles.retireBaseCharacter(id)
		}

		pub fun registerDoodlesSpecies(_ d: Doodles.Species) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Doodles.addSpecies(d)
		}

		pub fun retireDoodlesSpecies(_ id: UInt64) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Doodles.retireSpecies(id)
		}

		pub fun registerDoodlesSet(_ d: Doodles.Set) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Doodles.addSet(d)
		}

		pub fun retireDoodlesSet(_ id: UInt64) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Doodles.retireSet(id)
		}

		pub fun mintDoodles(
			recipientAddress: Address,
			doodleName: String,
			baseCharacter: UInt64,
			context: {String : String}
		): @Doodles.NFT {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}

			let doodle <- Doodles.adminMintDoodle(
				recipientAddress: recipientAddress,
				doodleName: doodleName,
				baseCharacter: baseCharacter,
				context: context
			)

			return <- doodle
		}

		pub fun createRedeemablesSet(name: String, canRedeem: Bool, redeemLimitTimestamp: UFix64, active: Bool) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Redeemables.createSet(name: name, canRedeem: canRedeem, redeemLimitTimestamp: redeemLimitTimestamp, active: active
			)
		}

		pub fun updateRedeemablesSetActive(setId: UInt64, active: Bool) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Redeemables.updateSetActive(setId: setId, active: active)
		}

		pub fun updateRedeemablesSetCanRedeem(setId: UInt64, canRedeem: Bool) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Redeemables.updateSetCanRedeem(setId: setId, canRedeem: canRedeem)
		}

		pub fun updateRedeemablesSetRedeemLimitTimestamp(setId: UInt64, redeemLimitTimestamp: UFix64) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Redeemables.updateSetRedeemLimitTimestamp(setId: setId, redeemLimitTimestamp: redeemLimitTimestamp)
		}

		pub fun createRedeemablesTemplate(
			setId: UInt64,
			name: String,
			description: String,
			brand: String,
			royalties: [MetadataViews.Royalty],
			type: String,
			thumbnail: MetadataViews.Media,
			image: MetadataViews.Media,
			active: Bool,
			extra: {String: AnyStruct}
		) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Redeemables.createTemplate(
				setId: setId,
				name: name,
				description: description,
				brand: brand,
				royalties: royalties,
				type: type,
				thumbnail: thumbnail,
				image: image,
				active: active,
				extra: extra
			)
		}

		pub fun updateRedeemablesTemplateActive(templateId: UInt64, active: Bool) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Redeemables.updateTemplateActive(templateId: templateId, active: active)
		}
		
		pub fun mintRedeemablesNFT(recipient: &{NonFungibleToken.Receiver}, templateId: UInt64){
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Redeemables.mintNFT(recipient: recipient, templateId: templateId)
		}

		pub fun burnRedeemablesUnredeemedSet(setId: UInt64) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			Redeemables.burnUnredeemedSet(setId: setId)
		}

		pub fun registerDoodlesDropsWearablesMintTransaction(packTypeId: UInt64, packId: UInt64, transactionId: String) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			TransactionsRegistry.registerDoodlesDropsWearablesMint(packTypeId: packTypeId, packId: packId, transactionId: transactionId)
		}

		pub fun registerDoodlesDropsRedeemablesMintTransaction(packTypeId: UInt64, packId: UInt64, transactionId: String) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			TransactionsRegistry.registerDoodlesDropsRedeemablesMint(packTypeId: packTypeId, packId: packId, transactionId: transactionId)
		}

		pub fun registerTransaction(name: String, args: [String], value: String) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			TransactionsRegistry.register(name: name, args: args, value: value)
		}

		pub fun mintPack(
			recipient: &{NonFungibleToken.Receiver},
			typeId: UInt64
		) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}

			DoodlePacks.mintNFT(recipient: recipient, typeId: typeId)
		}

		pub fun addPackType(
			id: UInt64,
			name: String,
			description: String,
			thumbnail: MetadataViews.Media,
			image: MetadataViews.Media,
			amountOfTokens: UInt8,
			templateDistributions: [DoodlePackTypes.TemplateDistribution],
			maxSupply: UInt64?
		): DoodlePackTypes.PackType {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}

			return DoodlePackTypes.addPackType(
				id: id,
				name: name,
				description: description,
				thumbnail: thumbnail,
				image: image,
				amountOfTokens: amountOfTokens,
				templateDistributions: templateDistributions,
				maxSupply: maxSupply
			)
		}

		pub fun updatePackRevealBlocks(revealBlocks: UInt64) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}

			OpenDoodlePacks.updateRevealBlocks(revealBlocks: revealBlocks)
		}

		init() {
			self.capability = nil
		}

	}

	init() {

		self.AdminProxyPublicPath= /public/characterAdminProxy
		self.AdminProxyStoragePath=/storage/characterAdminProxy

		//create a dummy server for now, if we have a resource later we want to use instead of server we can change to that
		self.AdminServerPrivatePath=/private/characterAdminServer
		self.AdminServerStoragePath=/storage/characterAdminServer
		self.account.save(<- create Server(), to: self.AdminServerStoragePath)
		self.account.link<&Server>( self.AdminServerPrivatePath, target: self.AdminServerStoragePath)
	}

}