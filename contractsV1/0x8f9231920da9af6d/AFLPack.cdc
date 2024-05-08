import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import AFLNFT from "./AFLNFT.cdc"

import FiatToken from "./../../standardsV1/FiatToken.cdc"

import StorageHelper from "./StorageHelper.cdc"

import PackRestrictions from "./PackRestrictions.cdc"

access(all)
contract AFLPack{ 
	// event when a pack is bought
	access(all)
	event PackBought(templateId: UInt64, receiptAddress: Address?)
	
	access(all)
	event PurchaseDetails(
		buyer: Address,
		momentsInPack: [{
			
				String: UInt64
			}
		],
		pricePaid: UFix64,
		packID: UInt64,
		settledOnChain: Bool
	)
	
	// event when a pack is opened
	access(all)
	event PackOpened(nftId: UInt64, receiptAddress: Address?)
	
	// path for pack storage
	access(all)
	let PackStoragePath: StoragePath
	
	// path for pack public
	access(all)
	let PackPublicPath: PublicPath
	
	access(self)
	var ownerAddress: Address
	
	access(contract)
	let adminRef: Capability<&FiatToken.Vault>
	
	access(all)
	resource interface PackPublic{ 
		// making this function public to call by authorized users
		access(all)
		fun openPack(packNFT: @AFLNFT.NFT, receiptAddress: Address)
	}
	
	access(all)
	resource Pack: PackPublic{ 
		access(all)
		fun updateOwnerAddress(owner: Address){ 
			pre{ 
				owner != nil:
					"owner must not be null"
			}
			AFLPack.ownerAddress = owner
		}
		
		access(all)
		fun buyPackFromAdmin(templateIds: [{String: UInt64}], packTemplateId: UInt64, receiptAddress: Address, price: UFix64){ 
			pre{ 
				templateIds.length > 0:
					"template id  must not be zero"
				receiptAddress != nil:
					"receipt address must not be null"
			}
			StorageHelper.topUpAccount(address: receiptAddress)
			var allNftTemplateExists = true
			assert(templateIds.length <= 10, message: "templates limit exceeded")
			let nftTemplateIds: [{String: UInt64}] = []
			for tempID in templateIds{ 
				let nftTemplateData = AFLNFT.getTemplateById(templateId: tempID["id"]!)
				if nftTemplateData == nil{ 
					allNftTemplateExists = false
					break
				}
				nftTemplateIds.append(tempID)
			}
			let originalPackTemplateData = AFLNFT.getTemplateById(templateId: packTemplateId)
			let originalPackTemplateImmutableData = originalPackTemplateData.getImmutableData()
			originalPackTemplateImmutableData["nftTemplates"] = nftTemplateIds
			originalPackTemplateImmutableData["packTemplateId"] = packTemplateId
			assert(allNftTemplateExists, message: "Invalid NFTs")
			AFLNFT.createTemplate(maxSupply: 1, immutableData: originalPackTemplateImmutableData)
			let lastIssuedTemplateId = AFLNFT.getLatestTemplateId()
			AFLNFT.mintNFT(templateInfo:{ "id": lastIssuedTemplateId}, account: receiptAddress)
			(AFLNFT.allTemplates[packTemplateId]!).incrementIssuedSupply()
			emit PackBought(templateId: lastIssuedTemplateId, receiptAddress: receiptAddress)
			emit PurchaseDetails(buyer: receiptAddress, momentsInPack: templateIds, pricePaid: price, packID: packTemplateId, settledOnChain: false)
		}
		
		access(all)
		fun buyPack(templateIds: [{String: UInt64}], packTemplateId: UInt64, receiptAddress: Address, price: UFix64, flowPayment: @{FungibleToken.Vault}){ 
			pre{ 
				templateIds.length > 0:
					"template id  must not be zero"
				flowPayment.balance == price:
					"Your vault does not have balance to buy NFT"
				receiptAddress != nil:
					"receipt address must not be null"
			}
			StorageHelper.topUpAccount(address: receiptAddress)
			var allNftTemplateExists = true
			assert(templateIds.length <= 10, message: "templates limit exceeded")
			let nftTemplateIds: [{String: UInt64}] = []
			for tempID in templateIds{ 
				let nftTemplateData = AFLNFT.getTemplateById(templateId: tempID["id"]!)
				if nftTemplateData == nil{ 
					allNftTemplateExists = false
					break
				}
				nftTemplateIds.append(tempID)
			}
			let originalPackTemplateData = AFLNFT.getTemplateById(templateId: packTemplateId)
			let originalPackTemplateImmutableData = originalPackTemplateData.getImmutableData()
			originalPackTemplateImmutableData["nftTemplates"] = nftTemplateIds
			originalPackTemplateImmutableData["packTemplateId"] = packTemplateId
			assert(allNftTemplateExists, message: "Invalid NFTs")
			AFLNFT.createTemplate(maxSupply: 1, immutableData: originalPackTemplateImmutableData)
			let lastIssuedTemplateId = AFLNFT.getLatestTemplateId()
			let receiptAccount = getAccount(AFLPack.ownerAddress)
			let recipientCollection = receiptAccount.capabilities.get<&FiatToken.Vault>(FiatToken.VaultReceiverPubPath).borrow<&FiatToken.Vault>() ?? panic("Could not get receiver reference to the flow receiver")
			recipientCollection.deposit(from: <-flowPayment)
			AFLNFT.mintNFT(templateInfo:{ "id": lastIssuedTemplateId}, account: receiptAddress)
			(AFLNFT.allTemplates[packTemplateId]!).incrementIssuedSupply()
			emit PackBought(templateId: lastIssuedTemplateId, receiptAddress: receiptAddress)
			emit PurchaseDetails(buyer: receiptAddress, momentsInPack: templateIds, pricePaid: price, packID: packTemplateId, settledOnChain: true)
		}
		
		access(all)
		fun openPack(packNFT: @AFLNFT.NFT, receiptAddress: Address){ 
			pre{ 
				packNFT != nil:
					"pack nft must not be null"
				receiptAddress != nil:
					"receipt address must not be null"
			}
			StorageHelper.topUpAccount(address: receiptAddress)
			var packNFTData = AFLNFT.getNFTData(nftId: packNFT.id)
			var packTemplateData = AFLNFT.getTemplateById(templateId: packNFTData.templateId)
			let templateImmutableData = packTemplateData.getImmutableData()
			let allIds = templateImmutableData["nftTemplates"]! as! [AnyStruct]
			let packSlug = templateImmutableData["slug"]! as! String
			let optionalPackTemplateId = templateImmutableData["packTemplateId"]
			if optionalPackTemplateId != nil{ 
				let packTemplateId: UInt64 = templateImmutableData["packTemplateId"]! as! UInt64
				PackRestrictions.accessCheck(id: packTemplateId)
			}
			assert(allIds.length <= 10, message: "templates limit exceeded")
			for tempID in allIds{ 
				if packSlug == "ripper-skippers"{ 
					let templateInfo ={ "id": tempID as! UInt64}
					AFLNFT.mintNFT(templateInfo: templateInfo!, account: receiptAddress)
				} else{ 
					let templateInfo = tempID as?{ String: UInt64}
					AFLNFT.mintNFT(templateInfo: templateInfo!, account: receiptAddress)
				}
			}
			emit PackOpened(nftId: packNFT.id, receiptAddress: self.owner?.address)
			destroy packNFT
		}
		
		init(){} 
	}
	
	init(){ 
		self.ownerAddress = (self.account!).address
		self.adminRef = self.account.capabilities.get<&FiatToken.Vault>(
				FiatToken.VaultReceiverPubPath
			)!
		self.PackStoragePath = /storage/AFLPack
		self.PackPublicPath = /public/AFLPack
		self.account.storage.save(<-create Pack(), to: self.PackStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&{PackPublic}>(self.PackStoragePath)
		self.account.capabilities.publish(capability_1, at: self.PackPublicPath)
	}
}
