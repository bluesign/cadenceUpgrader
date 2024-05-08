import NFTContract from "../0x73b22c80a051e2ff/NFTContract.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract NowWhereContract{ 
	// -----------------------------------------------------------------------
	// Nowwhere contract Event definitions
	// -----------------------------------------------------------------------
	access(all)
	event ContractInitialized()
	
	// Emitted when a new Drop is created
	access(all)
	event DropCreated(dropId: UInt64, creator: Address, startDate: UFix64, endDate: UFix64)
	
	// Emitted when a Drop is purchased
	access(all)
	event DropPurchased(
		dropId: UInt64,
		templateId: UInt64,
		mintNumbers: UInt64,
		receiptAddress: Address
	)
	
	// Emitted when a Drop is purchased using flow
	access(all)
	event DropPurchasedWithFlow(
		dropId: UInt64,
		templateId: UInt64,
		mintNumbers: UInt64,
		receiptAddress: Address,
		price: UFix64
	)
	
	// Emitted when a Drop is removed
	access(all)
	event DropRemoved(dropId: UInt64)
	
	// Contract level paths for storing resources
	access(all)
	let DropAdminStoragePath: StoragePath
	
	// The capability that is used for calling the admin functions 
	access(contract)
	let adminRef: Capability<&{NFTContract.NFTMethodsCapability}>
	
	// Variable size dictionary of Drop structs
	access(self)
	var allDrops:{ UInt64: Drop}
	
	// -----------------------------------------------------------------------
	// Nowwhere contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// Drop is a struct 
	access(all)
	struct Drop{ 
		access(all)
		let dropId: UInt64
		
		access(all)
		let startDate: UFix64
		
		access(all)
		let endDate: UFix64
		
		access(all)
		let templates:{ UInt64: AnyStruct}
		
		init(dropId: UInt64, startDate: UFix64, endDate: UFix64, templates:{ UInt64: AnyStruct}){ 
			self.dropId = dropId
			self.startDate = startDate
			self.endDate = endDate
			self.templates = templates
		}
	}
	
	// DropAdmin
	// This is the main resource to manage the NFTs that they are creating and purchasing.
	access(all)
	resource DropAdmin{ 
		access(contract)
		var ownerVault: Capability<&{FungibleToken.Receiver}>?
		
		access(all)
		fun addOwnerVault(_ownerVault: Capability<&{FungibleToken.Receiver}>){ 
			self.ownerVault = _ownerVault
		}
		
		access(all)
		fun createDrop(
			dropId: UInt64,
			startDate: UFix64,
			endDate: UFix64,
			templates:{ 
				UInt64: AnyStruct
			}
		){ 
			pre{ 
				dropId != nil:
					"invalid drop id"
				NowWhereContract.allDrops[dropId] == nil:
					"drop id already exists"
				startDate >= getCurrentBlock().timestamp:
					"Start Date should be greater or Equal than current time"
				endDate > startDate:
					"End date should be greater than start date"
				templates != nil:
					"templates must not be null"
			}
			var areValidTemplates: Bool = true
			for templateId in templates.keys{ 
				var template = NFTContract.getTemplateById(templateId: templateId)
				if template == nil{ 
					areValidTemplates = false
					break
				}
			}
			assert(areValidTemplates, message: "templateId is not valid")
			var newDrop =
				Drop(dropId: dropId, startDate: startDate, endDate: endDate, templates: templates)
			NowWhereContract.allDrops[newDrop.dropId] = newDrop
			emit DropCreated(
				dropId: dropId,
				creator: self.owner?.address!,
				startDate: startDate,
				endDate: endDate
			)
		}
		
		access(all)
		fun removeDrop(dropId: UInt64){ 
			pre{ 
				dropId != nil:
					"invalid drop id"
				NowWhereContract.allDrops[dropId] != nil:
					"drop id does not exist"
				(NowWhereContract.allDrops[dropId]!).endDate > getCurrentBlock().timestamp:
					"Drop is not ended yet"
			}
			NowWhereContract.allDrops.remove(key: dropId)
			emit DropRemoved(dropId: dropId)
		}
		
		access(all)
		fun purchaseNFT(
			dropId: UInt64,
			templateId: UInt64,
			mintNumbers: UInt64,
			receiptAddress: Address
		){ 
			pre{ 
				mintNumbers > 0:
					"mint number must be greater than zero"
				mintNumbers <= 10:
					"mint numbers must be less than ten"
				templateId > 0:
					"template id must be greater than zero"
				dropId != nil:
					"invalid drop id"
				receiptAddress != nil:
					"invalid receipt Address"
				NowWhereContract.allDrops[dropId] != nil:
					"drop id does not exist"
				(NowWhereContract.allDrops[dropId]!).startDate <= getCurrentBlock().timestamp:
					"drop not started yet"
				(NowWhereContract.allDrops[dropId]!).endDate > getCurrentBlock().timestamp:
					"drop already ended"
				(NowWhereContract.allDrops[dropId]!).templates[templateId] != nil:
					"template id does not exist"
			}
			var template = NFTContract.getTemplateById(templateId: templateId)
			assert(
				template.issuedSupply + mintNumbers <= template.maxSupply,
				message: "template reached to its max supply"
			)
			var i: UInt64 = 0
			while i < mintNumbers{ 
				(NowWhereContract.adminRef.borrow()!).mintNFT(templateId: templateId, account: receiptAddress)
				i = i + 1
			}
			emit DropPurchased(
				dropId: dropId,
				templateId: templateId,
				mintNumbers: mintNumbers,
				receiptAddress: receiptAddress
			)
		}
		
		access(all)
		fun purchaseNFTWithFlow(
			dropId: UInt64,
			templateId: UInt64,
			mintNumbers: UInt64,
			receiptAddress: Address,
			price: UFix64,
			flowPayment: @{FungibleToken.Vault}
		){ 
			pre{ 
				price > 0.0:
					"Price should be greater than zero"
				receiptAddress != nil:
					"invalid receipt Address"
				flowPayment.balance == price:
					"Your vault does not have balance to buy NFT"
				mintNumbers > 0:
					"mint number must be greater than zero"
				mintNumbers <= 10:
					"mint numbers must be less than ten"
				templateId > 0:
					"template id must be greater than zero"
				dropId != nil:
					"invalid drop id"
				receiptAddress != nil:
					"invalid receipt Address"
				NowWhereContract.allDrops[dropId] != nil:
					"drop id does not exist"
				(NowWhereContract.allDrops[dropId]!).startDate <= getCurrentBlock().timestamp:
					"drop not started yet"
				(NowWhereContract.allDrops[dropId]!).endDate > getCurrentBlock().timestamp:
					"drop already ended"
				(NowWhereContract.allDrops[dropId]!).templates[templateId] != nil:
					"template id does not exist"
			}
			let vaultRef =
				(self.ownerVault!).borrow()
				?? panic("Could not borrow reference to owner token vault")
			vaultRef.deposit(from: <-flowPayment)
			var template = NFTContract.getTemplateById(templateId: templateId)
			assert(
				template.issuedSupply + mintNumbers <= template.maxSupply,
				message: "template reached to its max supply"
			)
			var i: UInt64 = 0
			while i < mintNumbers{ 
				(NowWhereContract.adminRef.borrow()!).mintNFT(templateId: templateId, account: receiptAddress)
				i = i + 1
			}
			emit DropPurchasedWithFlow(
				dropId: dropId,
				templateId: templateId,
				mintNumbers: mintNumbers,
				receiptAddress: receiptAddress,
				price: price
			)
		}
		
		init(){ 
			self.ownerVault = nil
		}
	}
	
	// getDropById returns the IDs that the specified Drop id
	// is associated with 
	access(all)
	fun getDropById(dropId: UInt64): Drop{ 
		return self.allDrops[dropId]!
	}
	
	// getAllDrops returns all the Drops in NowWhereContract
	// Returns: A dictionary of all the Drop that have been created
	access(all)
	fun getAllDrops():{ UInt64: Drop}{ 
		return self.allDrops
	}
	
	init(){ 
		// Initialize contract fields
		self.allDrops ={} 
		self.DropAdminStoragePath = /storage/NowwhereDropAdmin
		// get the private capability to the admin resource interface
		// to call the functions of this interface.
		self.adminRef = self.account.capabilities.get<&{NFTContract.NFTMethodsCapability}>(
				NFTContract.NFTMethodsCapabilityPrivatePath
			)!
		
		// Put the Drop Admin in storage
		self.account.storage.save(<-create DropAdmin(), to: self.DropAdminStoragePath)
		emit ContractInitialized()
	}
}
