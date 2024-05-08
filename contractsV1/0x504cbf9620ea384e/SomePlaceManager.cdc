/*
	Description: Administrative Contract for SomePlace NFT Collectibles
	
	Exposes all functionality for an administrator of SomePlace to
	make creations and modifications pertaining to SomePlace Collectibles
	
	author: zay.codes
*/

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import SomePlaceCollectible from "./SomePlaceCollectible.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

access(all)
contract SomePlaceManager{ 
	access(all)
	let ManagerStoragePath: StoragePath
	
	access(all)
	let ManagerPublicPath: PublicPath
	
	// -----------------------------------------------------------------------
	// SomePlace Manager Events
	// -----------------------------------------------------------------------
	access(all)
	event SetMetadataUpdated(setID: UInt64)
	
	access(all)
	event EditionMetadataUpdated(setID: UInt64, editionNumber: UInt64)
	
	access(all)
	event EditionTraitsUpdated(setID: UInt64, editionNumber: UInt64)
	
	access(all)
	event PublicSalePriceUpdated(setID: UInt64, fungibleTokenType: String, price: UFix64?)
	
	access(all)
	event PublicSaleTimeUpdated(setID: UInt64, startTime: UFix64?, endTime: UFix64?)
	
	// Allows for access to where SomePlace FUSD funds should head towards.
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
		): @SomePlaceCollectible.Collection
		
		access(all)
		fun mintNftFromPublicSaleWithFLOW(
			setID: UInt64,
			quantity: UInt32,
			vault: @{FungibleToken.Vault}
		): @SomePlaceCollectible.Collection
	}
	
	access(all)
	resource Manager: ManagerPublic{ 
		/*
					Set creation
				*/
		
		access(all)
		fun addNFTSet(maxNumberOfEditions: UInt64, metadata:{ String: String}): UInt64{ 
			let setID = SomePlaceCollectible.addNFTSet(maxNumberOfEditions: maxNumberOfEditions, metadata: metadata)
			return setID
		}
		
		/*
					Modification of properties and metadata for a set
				*/
		
		access(all)
		fun updateSetMetadata(setID: UInt64, metadata:{ String: String}){ 
			SomePlaceCollectible.updateSetMetadata(setID: setID, metadata: metadata)
			emit SetMetadataUpdated(setID: setID)
		}
		
		access(all)
		fun updateEditionMetadata(setID: UInt64, editionNumber: UInt64, metadata:{ String: String}){ 
			SomePlaceCollectible.updateEditionMetadata(setID: setID, editionNumber: editionNumber, metadata: metadata)
			emit EditionMetadataUpdated(setID: setID, editionNumber: editionNumber)
		}
		
		access(all)
		fun updateEditionTraits(setID: UInt64, editionNumber: UInt64, traits:{ String: String}){ 
			SomePlaceCollectible.updateEditionTraits(setID: setID, editionNumber: editionNumber, traits: traits)
			emit EditionTraitsUpdated(setID: setID, editionNumber: editionNumber)
		}
		
		access(all)
		fun updateFLOWPublicSalePrice(setID: UInt64, price: UFix64?){ 
			SomePlaceCollectible.updateFLOWPublicSalePrice(setID: setID, price: price)
			emit PublicSalePriceUpdated(setID: setID, fungibleTokenType: "FLOW", price: price)
		}
		
		access(all)
		fun updateFUSDPublicSalePrice(setID: UInt64, price: UFix64?){ 
			SomePlaceCollectible.updateFUSDPublicSalePrice(setID: setID, price: price)
			emit PublicSalePriceUpdated(setID: setID, fungibleTokenType: "FUSD", price: price)
		}
		
		access(all)
		fun updatePublicSaleStartTime(setID: UInt64, startTime: UFix64?){ 
			SomePlaceCollectible.updatePublicSaleStartTime(setID: setID, startTime: startTime)
			let setMetadata = SomePlaceCollectible.getMetadataForSetID(setID: setID)!
			emit PublicSaleTimeUpdated(setID: setID, startTime: setMetadata.getPublicSaleStartTime(), endTime: setMetadata.getPublicSaleEndTime())
		}
		
		access(all)
		fun updatePublicSaleEndTime(setID: UInt64, endTime: UFix64?){ 
			SomePlaceCollectible.updatePublicSaleEndTime(setID: setID, endTime: endTime)
			let setMetadata = SomePlaceCollectible.getMetadataForSetID(setID: setID)!
			emit PublicSaleTimeUpdated(setID: setID, startTime: setMetadata.getPublicSaleStartTime(), endTime: setMetadata.getPublicSaleEndTime())
		}
		
		/*
					Modification of manager properties
				*/
		
		// fungibleTokenType is expected to be 'FLOW' or 'FUSD'
		access(all)
		fun setAdminPaymentReceiver(fungibleTokenType: String, paymentReceiver: Capability<&{FungibleToken.Receiver}>){ 
			SomePlaceManager.setAdminPaymentReceiver(fungibleTokenType: fungibleTokenType, paymentReceiver: paymentReceiver)
		}
		
		/* Minting functions */
		// Mint a single next edition NFT
		access(self)
		fun mintSequentialEditionNFT(setID: UInt64): @SomePlaceCollectible.NFT{ 
			return <-SomePlaceCollectible.mintSequentialEditionNFT(setID: setID)
		}
		
		// Mint many editions of NFTs
		access(all)
		fun batchMintSequentialEditionNFTs(setID: UInt64, quantity: UInt32): @SomePlaceCollectible.Collection{ 
			pre{ 
				quantity >= 1 && quantity <= 5:
					"May only mint between 1 and 5 collectibles at a single time."
			}
			let collection <- SomePlaceCollectible.createEmptyCollection(nftType: Type<@SomePlaceCollectible.Collection>()) as! @SomePlaceCollectible.Collection
			var counter: UInt32 = 0
			while counter < quantity{ 
				collection.deposit(token: <-self.mintSequentialEditionNFT(setID: setID))
				counter = counter + 1
			}
			return <-collection
		}
		
		// Mint a specific edition of an NFT
		access(all)
		fun mintNFT(setID: UInt64, editionNumber: UInt64): @SomePlaceCollectible.NFT{ 
			return <-SomePlaceCollectible.mintNFT(setID: setID, editionNumber: editionNumber)
		}
		
		// Allows direct minting of a NFT as part of a public sale.
		// This function takes in a vault that can be of multiple types of fungible tokens.
		// The proper fungible token is to be checked prior to this function call
		access(self)
		fun mintNftFromPublicSale(setID: UInt64, quantity: UInt32, vault: @{FungibleToken.Vault}, price: UFix64, paymentReceiver: Capability<&{FungibleToken.Receiver}>): @SomePlaceCollectible.Collection{ 
			pre{ 
				quantity >= 1 && quantity <= 10:
					"May only mint between 1 and 10 collectibles at a time"
				SomePlaceCollectible.getMetadataForSetID(setID: setID) != nil:
					"SetID does not exist"
				(SomePlaceCollectible.getMetadataForSetID(setID: setID)!).isPublicSaleActive():
					"Public minting is not currently allowed"
			}
			let totalPrice = price * UFix64(quantity)
			
			// Ensure that the provided balance is equal to our expected price for the NFTs
			assert(totalPrice == vault.balance)
			
			// Mint `quantity` number of NFTs from this drop to the collection
			var counter = UInt32(0)
			let uuids: [UInt64] = []
			let collection <- SomePlaceCollectible.createEmptyCollection(nftType: Type<@SomePlaceCollectible.Collection>()) as! @SomePlaceCollectible.Collection
			while counter < quantity{ 
				let collectible <- self.mintSequentialEditionNFT(setID: setID)
				uuids.append(collectible.uuid)
				collection.deposit(token: <-collectible)
				counter = counter + UInt32(1)
			}
			let adminPaymentReceiver = paymentReceiver.borrow()!
			adminPaymentReceiver.deposit(from: <-vault)
			return <-collection
		}
		
		/*
					Public functions
				*/
		
		// Ensure that the passed in vault is FUSD, and pass the expected FUSD sale price for this set
		access(all)
		fun mintNftFromPublicSaleWithFUSD(setID: UInt64, quantity: UInt32, vault: @{FungibleToken.Vault}): @SomePlaceCollectible.Collection{ 
			pre{ 
				(SomePlaceCollectible.getMetadataForSetID(setID: setID)!).getFUSDPublicSalePrice() != nil:
					"Public sale price not set for this set"
			}
			let fusdVault <- vault as! @FUSD.Vault
			let price = (SomePlaceCollectible.getMetadataForSetID(setID: setID)!).getFUSDPublicSalePrice()!
			let paymentReceiver = SomePlaceManager.adminPaymentReceivers["FUSD"]!
			return <-self.mintNftFromPublicSale(setID: setID, quantity: quantity, vault: <-fusdVault, price: price, paymentReceiver: paymentReceiver)
		}
		
		// Ensure that the passed in vault is a FLOW vault, and pass the expected FLOW sale price for this set
		access(all)
		fun mintNftFromPublicSaleWithFLOW(setID: UInt64, quantity: UInt32, vault: @{FungibleToken.Vault}): @SomePlaceCollectible.Collection{ 
			pre{ 
				(SomePlaceCollectible.getMetadataForSetID(setID: setID)!).getFLOWPublicSalePrice() != nil:
					"Public sale price not set for this set"
			}
			let flowVault <- vault as! @FlowToken.Vault
			let price = (SomePlaceCollectible.getMetadataForSetID(setID: setID)!).getFLOWPublicSalePrice()!
			let paymentReceiver = SomePlaceManager.adminPaymentReceivers["FLOW"]!
			return <-self.mintNftFromPublicSale(setID: setID, quantity: quantity, vault: <-flowVault, price: price, paymentReceiver: paymentReceiver)
		}
	}
	
	/* Mutating functions */
	access(contract)
	fun setAdminPaymentReceiver(
		fungibleTokenType: String,
		paymentReceiver: Capability<&{FungibleToken.Receiver}>
	){ 
		pre{ 
			fungibleTokenType == "FLOW" || fungibleTokenType == "FUSD":
				"Must provide either flow or fusd as fungible token keys"
			paymentReceiver.borrow() != nil:
				"Invalid payment receivier capability provided"
			fungibleTokenType == "FLOW" && (paymentReceiver.borrow()!).isInstance(Type<@FlowToken.Vault>()):
				"Invalid flow token vault provided"
			fungibleTokenType == "FUSD" && (paymentReceiver.borrow()!).isInstance(Type<@FUSD.Vault>()):
				"Invalid flow token vault provided"
		}
		self.adminPaymentReceivers[fungibleTokenType] = paymentReceiver
	}
	
	/* Public Functions */
	access(all)
	fun getManagerPublic(): Capability<&SomePlaceManager.Manager>{ 
		return self.account.capabilities.get<&SomePlaceManager.Manager>(self.ManagerPublicPath)!
	}
	
	init(){ 
		self.ManagerStoragePath = /storage/somePlaceManager
		self.ManagerPublicPath = /public/somePlaceManager
		self.account.storage.save(<-create Manager(), to: self.ManagerStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&SomePlaceManager.Manager>(
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
