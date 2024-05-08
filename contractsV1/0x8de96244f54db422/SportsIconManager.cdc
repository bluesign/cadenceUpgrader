/*
	Description: Administrative Contract for SportsIcon NFT Collectibles

	Exposes all functionality for an administrator of SportsIcon to
	make creations and modifications pertaining to SportsIcon Collectibles
*/

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import IconsToken from "../0x24efe89a9efa3c6f/IconsToken.cdc"

import DapperUtilityCoin from "./../../standardsV1/DapperUtilityCoin.cdc"

import SportsIconBeneficiaries from "./SportsIconBeneficiaries.cdc"

import SportsIconCollectible from "./SportsIconCollectible.cdc"

import SportsIconPrimarySalePrices from "./SportsIconPrimarySalePrices.cdc"

import TokenForwarding from "./../../standardsV1/TokenForwarding.cdc"

import SportsIconNFTStorefront from "../0x03c8261a06cb1b42/SportsIconNFTStorefront.cdc"

access(all)
contract SportsIconManager{ 
	access(all)
	let ManagerStoragePath: StoragePath
	
	access(all)
	let ManagerPublicPath: PublicPath
	
	// -----------------------------------------------------------------------
	// SportsIcon Manager Events
	// -----------------------------------------------------------------------
	access(all)
	event SetMetadataUpdated(setID: UInt64)
	
	access(all)
	event EditionMetadataUpdated(setID: UInt64, editionNumber: UInt64)
	
	access(all)
	event PublicSalePriceUpdated(setID: UInt64, fungibleTokenType: String, price: UFix64?)
	
	access(all)
	event PublicSaleTimeUpdated(setID: UInt64, startTime: UFix64?, endTime: UFix64?)
	
	access(all)
	event PublicSaleUpdated(
		setID: UInt64,
		fungibleTokenType: String,
		price: UFix64,
		startTime: UFix64,
		endTime: UFix64
	)
	
	// Allows for access to where SportsIcon FUSD funds should head towards.
	// Mapping of `FungibleToken Identifier` -> `Receiver Capability`
	// Currently usable is FLOW and FUSD as payment receivers
	access(self)
	var adminPaymentReceivers:{ String: Capability<&{FungibleToken.Receiver}>}
	
	access(all)
	resource interface ManagerPublic{ 
		access(all)
		fun mintNftFromPublicSaleWithFUSD(
			setID: UInt64,
			quantity: UInt32,
			vault: @{FungibleToken.Vault}
		): @SportsIconCollectible.Collection
		
		access(all)
		fun mintNftFromPublicSaleWithFLOW(
			setID: UInt64,
			quantity: UInt32,
			vault: @{FungibleToken.Vault}
		): @SportsIconCollectible.Collection
		
		access(all)
		fun mintNftForPrimarySaleWithICONS(
			setID: UInt64,
			quantity: UInt32,
			vault: @{FungibleToken.Vault}
		): @SportsIconCollectible.Collection
		
		access(all)
		fun mintNftForPrimarySaleWithDUC(
			setID: UInt64,
			quantity: UInt32,
			vault: @{FungibleToken.Vault}
		): @SportsIconCollectible.Collection
	}
	
	access(all)
	resource Manager: ManagerPublic{ 
		/*
					Set creation
				*/
		
		access(all)
		fun addNFTSet(mediaURL: String, maxNumberOfEditions: UInt64, data:{ String: String}, mintBeneficiaries: SportsIconBeneficiaries.Beneficiaries, marketBeneficiaries: SportsIconBeneficiaries.Beneficiaries): UInt64{ 
			let setID = SportsIconCollectible.addNFTSet(mediaURL: mediaURL, maxNumberOfEditions: maxNumberOfEditions, data: data, mintBeneficiaries: mintBeneficiaries, marketBeneficiaries: marketBeneficiaries)
			return setID
		}
		
		/*
					Set deletion
				*/
		
		access(all)
		fun removeNFTSet(setID: UInt64){ 
			SportsIconCollectible.removeNFTSet(setID: setID)
		}
		
		access(all)
		fun updateMaxNumberOfEditions(setID: UInt64, maxNumberOfEditions: UInt64){ 
			SportsIconCollectible.updateMaxNumberOfEditions(setID: setID, maxNumberOfEditions: maxNumberOfEditions)
		}
		
		/*
					Modification of properties and metadata for a set
				*/
		
		access(all)
		fun updateSetMetadata(setID: UInt64, metadata:{ String: String}){ 
			SportsIconCollectible.updateSetMetadata(setID: setID, metadata: metadata)
			emit SetMetadataUpdated(setID: setID)
		}
		
		access(all)
		fun updateMediaURL(setID: UInt64, mediaURL: String){ 
			SportsIconCollectible.updateMediaURL(setID: setID, mediaURL: mediaURL)
			emit SetMetadataUpdated(setID: setID)
		}
		
		access(all)
		fun updateFLOWPublicSalePrice(setID: UInt64, price: UFix64?){ 
			SportsIconCollectible.updateFLOWPublicSalePrice(setID: setID, price: price)
			emit PublicSalePriceUpdated(setID: setID, fungibleTokenType: "FLOW", price: price)
		}
		
		access(all)
		fun updateFUSDPublicSalePrice(setID: UInt64, price: UFix64?){ 
			SportsIconCollectible.updateFUSDPublicSalePrice(setID: setID, price: price)
			emit PublicSalePriceUpdated(setID: setID, fungibleTokenType: "FUSD", price: price)
		}
		
		access(all)
		fun updateICONSPublicSalePrice(setID: UInt64, primarySaleListing: SportsIconPrimarySalePrices.PrimarySaleListing?){ 
			SportsIconPrimarySalePrices.updateSalePrice(setID: setID, currency: "ICONS", primarySaleListing: primarySaleListing)
			var price: UFix64? = nil
			if primarySaleListing != nil{ 
				price = (primarySaleListing!).totalPrice
			}
			emit PublicSalePriceUpdated(setID: setID, fungibleTokenType: "ICONS", price: price)
		}
		
		access(all)
		fun updateDUCPublicSalePrice(setID: UInt64, primarySaleListing: SportsIconPrimarySalePrices.PrimarySaleListing?){ 
			SportsIconPrimarySalePrices.updateSalePrice(setID: setID, currency: "DUC", primarySaleListing: primarySaleListing)
			var price: UFix64? = nil
			if primarySaleListing != nil{ 
				price = (primarySaleListing!).totalPrice
			}
			emit PublicSalePriceUpdated(setID: setID, fungibleTokenType: "DUC", price: price)
		}
		
		access(all)
		fun updateEditionMetadata(setID: UInt64, editionNumber: UInt64, metadata:{ String: String}){ 
			SportsIconCollectible.updateEditionMetadata(setID: setID, editionNumber: editionNumber, metadata: metadata)
			emit EditionMetadataUpdated(setID: setID, editionNumber: editionNumber)
		}
		
		/*
					Modification of a set's public sale settings
				*/
		
		// fungibleTokenType is expected to be 'FLOW' or 'FUSD' or 'ICONS' or 'DUC'
		access(all)
		fun setAdminPaymentReceiver(fungibleTokenType: String, paymentReceiver: Capability<&{FungibleToken.Receiver}>){ 
			SportsIconManager.setAdminPaymentReceiver(fungibleTokenType: fungibleTokenType, paymentReceiver: paymentReceiver)
		}
		
		access(all)
		fun updatePublicSaleStartTime(setID: UInt64, startTime: UFix64?){ 
			SportsIconCollectible.updatePublicSaleStartTime(setID: setID, startTime: startTime)
			let setMetadata = SportsIconCollectible.getMetadataForSetID(setID: setID)!
			emit PublicSaleTimeUpdated(setID: setID, startTime: setMetadata.getPublicSaleStartTime(), endTime: setMetadata.getPublicSaleEndTime())
		}
		
		access(all)
		fun updatePublicSaleEndTime(setID: UInt64, endTime: UFix64?){ 
			SportsIconCollectible.updatePublicSaleEndTime(setID: setID, endTime: endTime)
			let setMetadata = SportsIconCollectible.getMetadataForSetID(setID: setID)!
			emit PublicSaleTimeUpdated(setID: setID, startTime: setMetadata.getPublicSaleStartTime(), endTime: setMetadata.getPublicSaleEndTime())
		}
		
		access(all)
		fun updatePublicSaleTime(setID: UInt64, startTime: UFix64?, endTime: UFix64?){ 
			SportsIconCollectible.updatePublicSaleStartTime(setID: setID, startTime: startTime)
			SportsIconCollectible.updatePublicSaleEndTime(setID: setID, endTime: endTime)
			let setMetadata = SportsIconCollectible.getMetadataForSetID(setID: setID)!
			emit PublicSaleTimeUpdated(setID: setID, startTime: setMetadata.getPublicSaleStartTime(), endTime: setMetadata.getPublicSaleEndTime())
		}
		
		access(all)
		fun updateDucPublicSale(setID: UInt64, creatorReceiverCap: Capability<&{FungibleToken.Receiver}>, creatorAmount: UFix64, sportsIconReceiverCap: Capability<&{FungibleToken.Receiver}>, sportsIconAmount: UFix64, totalPrice: UFix64, startTime: UFix64, endTime: UFix64, maxNumberOfEditions: UInt64){ 
			let creatorCut = SportsIconNFTStorefront.SaleCut(receiver: creatorReceiverCap, amount: creatorAmount)
			let sportsIconCut = SportsIconNFTStorefront.SaleCut(receiver: sportsIconReceiverCap, amount: sportsIconAmount)
			let primarySaleListing = SportsIconPrimarySalePrices.PrimarySaleListing(totalPrice: totalPrice, saleCuts: [sportsIconCut, creatorCut])
			
			// Unset public sale price for other currencies that are supported
			// to ensure we don't have multiple set at once.
			self.updateICONSPublicSalePrice(setID: setID, primarySaleListing: nil)
			self.updateFLOWPublicSalePrice(setID: setID, price: nil)
			self.updateFUSDPublicSalePrice(setID: setID, price: nil)
			self.updateDUCPublicSalePrice(setID: setID, primarySaleListing: primarySaleListing)
			self.updatePublicSaleTime(setID: setID, startTime: startTime, endTime: endTime)
			self.updateMaxNumberOfEditions(setID: setID, maxNumberOfEditions: maxNumberOfEditions)
			emit PublicSaleUpdated(setID: setID, fungibleTokenType: "DUC", price: totalPrice, startTime: startTime, endTime: endTime)
		}
		
		/* Minting functions */
		// Mint a single next edition NFT
		access(self)
		fun mintSequentialEditionNFT(setID: UInt64): @SportsIconCollectible.NFT{ 
			return <-SportsIconCollectible.mintSequentialEditionNFT(setID: setID)
		}
		
		// Mint many editions of NFTs
		access(all)
		fun batchMintSequentialEditionNFTs(setID: UInt64, quantity: UInt32): @SportsIconCollectible.Collection{ 
			pre{ 
				quantity >= 1 && quantity <= 10:
					"May only mint between 1 and 10 collectibles at a single time."
			}
			let collection <- SportsIconCollectible.createEmptyCollection(nftType: Type<@SportsIconCollectible.Collection>()) as! @SportsIconCollectible.Collection
			var counter: UInt32 = 0
			while counter < quantity{ 
				collection.deposit(token: <-self.mintSequentialEditionNFT(setID: setID))
				counter = counter + 1
			}
			return <-collection
		}
		
		// Mint a specific edition of an NFT - usable for auctions, because edition numbers are set by ending auction ordering
		access(all)
		fun mintNFT(setID: UInt64, editionNumber: UInt64): @SportsIconCollectible.NFT{ 
			return <-SportsIconCollectible.mintNFT(setID: setID, editionNumber: editionNumber)
		}
		
		// DEPRECATED - replaced by `mintNftForPrimarySale`
		// Allows direct minting of a NFT as part of a public sale.
		// This function takes in a vault that can be of multiple types of fungible tokens.
		// The proper fungible token is to be checked prior to this function call
		access(self)
		fun mintNftFromPublicSale(setID: UInt64, quantity: UInt32, vault: @{FungibleToken.Vault}, price: UFix64, paymentReceiver: Capability<&{FungibleToken.Receiver}>): @SportsIconCollectible.Collection{ 
			pre{ 
				quantity >= 1 && quantity <= 10:
					"May only mint between 1 and 10 collectibles at a time"
				SportsIconCollectible.getMetadataForSetID(setID: setID) != nil:
					"SetID does not exist"
				(SportsIconCollectible.getMetadataForSetID(setID: setID)!).isPublicSaleActive():
					"Public minting is not currently allowed"
				(SportsIconCollectible.getMetadataForSetID(setID: setID)!).getFLOWPublicSalePrice() != nil || (SportsIconCollectible.getMetadataForSetID(setID: setID)!).getFUSDPublicSalePrice() != nil:
					"Public minting is not allowed without a price being set for this sale"
			}
			let totalPrice = price * UFix64(quantity)
			
			// Ensure that the provided balance is equal to our expected price for the NFTs
			assert(totalPrice == vault.balance)
			
			// Mint `quantity` number of NFTs from this drop to the collection
			var counter = UInt32(0)
			let uuids: [UInt64] = []
			let collection <- SportsIconCollectible.createEmptyCollection(nftType: Type<@SportsIconCollectible.Collection>()) as! @SportsIconCollectible.Collection
			while counter < quantity{ 
				let collectible <- self.mintSequentialEditionNFT(setID: setID)
				uuids.append(collectible.uuid)
				collection.deposit(token: <-collectible)
				counter = counter + UInt32(1)
			}
			// Retrieve the money from the given vault and place it in the appropriate locations
			let setInfo = SportsIconCollectible.getMetadataForSetID(setID: setID)!
			let mintBeneficiaries = setInfo.getMintBeneficiaries()
			let adminPaymentReceiver = paymentReceiver.borrow()!
			mintBeneficiaries.payOut(paymentReceiver: paymentReceiver, payment: <-vault, tokenIDs: uuids)
			return <-collection
		}
		
		// DEPRECATED - replaced by `mintNftForPrimarySale` equivalents
		// Ensure that the passed in vault is FUSD, and pass the expected FUSD sale price for this set
		access(all)
		fun mintNftFromPublicSaleWithFUSD(setID: UInt64, quantity: UInt32, vault: @{FungibleToken.Vault}): @SportsIconCollectible.Collection{ 
			pre{ 
				(SportsIconCollectible.getMetadataForSetID(setID: setID)!).getFUSDPublicSalePrice() != nil:
					"Public sale price not set for this set"
			}
			let fusdVault <- vault as! @FUSD.Vault
			let price = (SportsIconCollectible.getMetadataForSetID(setID: setID)!).getFUSDPublicSalePrice()!
			let paymentReceiver = SportsIconManager.adminPaymentReceivers["FUSD"]!
			return <-self.mintNftFromPublicSale(setID: setID, quantity: quantity, vault: <-fusdVault, price: price, paymentReceiver: paymentReceiver)
		}
		
		// DEPRECATED - replaced by `mintNftForPrimarySale` equivalents
		access(all)
		fun mintNftFromPublicSaleWithFLOW(setID: UInt64, quantity: UInt32, vault: @{FungibleToken.Vault}): @SportsIconCollectible.Collection{ 
			pre{ 
				(SportsIconCollectible.getMetadataForSetID(setID: setID)!).getFLOWPublicSalePrice() != nil:
					"Public sale price not set for this set"
			}
			let flowVault <- vault as! @FlowToken.Vault
			let price = (SportsIconCollectible.getMetadataForSetID(setID: setID)!).getFLOWPublicSalePrice()!
			let paymentReceiver = SportsIconManager.adminPaymentReceivers["FLOW"]!
			return <-self.mintNftFromPublicSale(setID: setID, quantity: quantity, vault: <-flowVault, price: price, paymentReceiver: paymentReceiver)
		}
		
		access(self)
		fun mintNftForPrimarySale(setID: UInt64, quantity: UInt32, paymentVault: @{FungibleToken.Vault}, primarySaleListing: SportsIconPrimarySalePrices.PrimarySaleListing, paymentReceiver: Capability<&{FungibleToken.Receiver}>): @SportsIconCollectible.Collection{ 
			pre{ 
				quantity >= 1 && quantity <= 10:
					"May only mint between 1 and 10 collectibles at a time"
				SportsIconCollectible.getMetadataForSetID(setID: setID) != nil:
					"SetID does not exist"
				(SportsIconCollectible.getMetadataForSetID(setID: setID)!).isPublicSaleActive():
					"Public minting is not currently allowed"
			}
			let totalPrice = primarySaleListing.totalPrice * UFix64(quantity)
			
			// Ensure that the provided balance is equal to our expected price for the NFTs
			assert(totalPrice == paymentVault.balance)
			
			// Mint `quantity` number of NFTs from this drop to the collection
			var counter = UInt32(0)
			let uuids: [UInt64] = []
			let collection <- SportsIconCollectible.createEmptyCollection(nftType: Type<@SportsIconCollectible.Collection>()) as! @SportsIconCollectible.Collection
			while counter < quantity{ 
				let collectible <- self.mintSequentialEditionNFT(setID: setID)
				uuids.append(collectible.uuid)
				collection.deposit(token: <-collectible)
				counter = counter + UInt32(1)
			}
			let adminPaymentReceiver = paymentReceiver.borrow()!
			var residualReceiver: &{FungibleToken.Receiver}? = adminPaymentReceiver
			for cut in primarySaleListing.getSaleCuts(){ 
				if let receiver = cut.receiver.borrow(){ 
					let paymentCut <- paymentVault.withdraw(amount: cut.amount)
					receiver.deposit(from: <-paymentCut)
					if residualReceiver == nil{ 
						residualReceiver = receiver
					}
				}
			}
			(residualReceiver!).deposit(from: <-paymentVault)
			return <-collection
		}
		
		// Ensure that the passed in vault is a ICONS vault, and pass the expected ICONS sale price for this set
		access(all)
		fun mintNftForPrimarySaleWithICONS(setID: UInt64, quantity: UInt32, vault: @{FungibleToken.Vault}): @SportsIconCollectible.Collection{ 
			pre{ 
				SportsIconPrimarySalePrices.getListing(setID: setID, currency: "ICONS") != nil:
					"Public sale price not set for this set"
				(SportsIconPrimarySalePrices.getListing(setID: setID, currency: "ICONS")!).totalPrice > 0.0:
					"Public sale price should be higher than 0"
			}
			let iconsVault <- vault as! @IconsToken.Vault
			let primarySaleListing = SportsIconPrimarySalePrices.getListing(setID: setID, currency: "ICONS")!
			let paymentReceiver = SportsIconManager.adminPaymentReceivers["ICONS"]!
			return <-self.mintNftForPrimarySale(setID: setID, quantity: quantity, paymentVault: <-iconsVault, primarySaleListing: primarySaleListing, paymentReceiver: paymentReceiver)
		}
		
		// Ensure that the passed in vault is a DUC vault, and pass the expected DUC sale price for this set
		access(all)
		fun mintNftForPrimarySaleWithDUC(setID: UInt64, quantity: UInt32, vault: @{FungibleToken.Vault}): @SportsIconCollectible.Collection{ 
			pre{ 
				SportsIconPrimarySalePrices.getListing(setID: setID, currency: "DUC") != nil:
					"Public sale price not set for this set"
				(SportsIconPrimarySalePrices.getListing(setID: setID, currency: "DUC")!).totalPrice > 0.0:
					"Public sale price should be higher than 0"
			}
			return <-self.mintNftForPrimarySale(setID: setID, quantity: quantity, paymentVault: <-(vault as! @DapperUtilityCoin.Vault), primarySaleListing: SportsIconPrimarySalePrices.getListing(setID: setID, currency: "DUC")!, paymentReceiver: SportsIconManager.adminPaymentReceivers["DUC"]!)
		}
		
		access(all)
		fun mintNftForGiveawayWithDUC(setID: UInt64): @SportsIconCollectible.NFT{ 
			pre{ 
				SportsIconPrimarySalePrices.getListing(setID: setID, currency: "DUC") != nil:
					"Public sale price not set for this set"
				(SportsIconPrimarySalePrices.getListing(setID: setID, currency: "DUC")!).totalPrice == 0.0:
					"Public sale price should equal 0"
			}
			return <-self.mintSequentialEditionNFT(setID: setID)
		}
	}
	
	/* Mutating functions */
	access(contract)
	fun setAdminPaymentReceiver(
		fungibleTokenType: String,
		paymentReceiver: Capability<&{FungibleToken.Receiver}>
	){ 
		pre{ 
			fungibleTokenType == "FLOW" || fungibleTokenType == "FUSD" || fungibleTokenType == "ICONS" || fungibleTokenType == "DUC":
				"Must provide either FLOW, FUSD, ICONS, or DUC as fungible token keys"
			paymentReceiver.borrow() != nil:
				"Invalid payment receiver capability provided"
			fungibleTokenType != "FLOW" || fungibleTokenType == "FLOW" && (paymentReceiver.borrow()!).isInstance(Type<@FlowToken.Vault>()):
				"Invalid FLOW token vault provided"
			fungibleTokenType != "FUSD" || fungibleTokenType == "FUSD" && (paymentReceiver.borrow()!).isInstance(Type<@FUSD.Vault>()):
				"Invalid FUSD token vault provided"
			fungibleTokenType != "ICONS" || fungibleTokenType == "ICONS" && (paymentReceiver.borrow()!).isInstance(Type<@IconsToken.Vault>()):
				"Invalid ICONS token vault provided"
			fungibleTokenType != "DUC" || fungibleTokenType == "DUC" && ((paymentReceiver.borrow()!).isInstance(Type<@DapperUtilityCoin.Vault>()) || (paymentReceiver.borrow()!).isInstance(Type<@TokenForwarding.Forwarder>())):
				"Invalid DUC token vault provided"
		}
		self.adminPaymentReceivers[fungibleTokenType] = paymentReceiver
	}
	
	/* Public Functions */
	access(all)
	fun getManagerPublic(): Capability<&SportsIconManager.Manager>{ 
		return self.account.capabilities.get<&SportsIconManager.Manager>(self.ManagerPublicPath)!
	}
	
	init(){ 
		self.ManagerStoragePath = /storage/sportsIconManager
		self.ManagerPublicPath = /public/sportsIconManager
		self.account.storage.save(<-create Manager(), to: self.ManagerStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&SportsIconManager.Manager>(
				self.ManagerStoragePath
			)
		self.account.capabilities.publish(capability_1, at: self.ManagerPublicPath)
		
		// If FUSD isn't setup on this manager account already, set it up - it is required to receive funds
		// and redirect sales of NFTs where we've lost the FUSD vault access to a seller on secondary market
		let existingVault = self.account.storage.borrow<&FUSD.Vault>(from: /storage/fusdVault)
		if existingVault == nil{ 
			self.account.storage.save(<-FUSD.createEmptyVault(vaultType: Type<@FUSD.Vault>()), to: /storage/fusdVault)
			var capability_2 = self.account.capabilities.storage.issue<&FUSD.Vault>(/storage/fusdVault)
			self.account.capabilities.publish(capability_2, at: /public/fusdReceiver)
			var capability_3 = self.account.capabilities.storage.issue<&FUSD.Vault>(/storage/fusdVault)
			self.account.capabilities.publish(capability_3, at: /public/fusdBalance)
		}
		self.adminPaymentReceivers ={} 
		self.adminPaymentReceivers["FUSD"] = self.account.capabilities.get<&FUSD.Vault>(
				/public/fusdReceiver
			)
		self.adminPaymentReceivers["FLOW"] = self.account.capabilities.get<&FlowToken.Vault>(
				/public/flowTokenReceiver
			)
	}
}
