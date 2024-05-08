import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import AFLNFT from "./AFLNFT.cdc"

import FiatToken from "./../../standardsV1/FiatToken.cdc"

access(all)
contract AFLPack{ 
	// event when a pack is bought
	access(all)
	event PackBought(templateId: UInt64, receiptAddress: Address?)
	
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
		fun buyPackFromAdmin(templateIds: [UInt64], packTemplateId: UInt64, receiptAddress: Address, price: UFix64){ 
			pre{ 
				price > 0.0:
					"Price should be greater than zero"
				templateIds.length > 0:
					"template id  must not be zero"
				receiptAddress != nil:
					"receipt address must not be null"
			}
			var allNftTemplateExists = true
			assert(templateIds.length <= 10, message: "templates limit exceeded")
			let nftTemplateIds: [AnyStruct] = []
			for tempID in templateIds{ 
				let nftTemplateData = AFLNFT.getTemplateById(templateId: tempID)
				if nftTemplateData == nil{ 
					allNftTemplateExists = false
					break
				}
				nftTemplateIds.append(tempID)
			}
			let originalPackTemplateData = AFLNFT.getTemplateById(templateId: packTemplateId)
			let originalPackTemplateImmutableData = originalPackTemplateData.getImmutableData()
			originalPackTemplateImmutableData["nftTemplates"] = nftTemplateIds
			assert(allNftTemplateExists, message: "Invalid NFTs")
			AFLNFT.createTemplate(maxSupply: 1, immutableData: originalPackTemplateImmutableData)
			let lastIssuedTemplateId = AFLNFT.getLatestTemplateId()
			AFLNFT.mintNFT(templateId: lastIssuedTemplateId, account: receiptAddress)
			(AFLNFT.allTemplates[packTemplateId]!).incrementIssuedSupply()
			emit PackBought(templateId: lastIssuedTemplateId, receiptAddress: receiptAddress)
		}
		
		access(all)
		fun buyPack(templateIds: [UInt64], packTemplateId: UInt64, receiptAddress: Address, price: UFix64, flowPayment: @{FungibleToken.Vault}){ 
			pre{ 
				price > 0.0:
					"Price should be greater than zero"
				templateIds.length > 0:
					"template id  must not be zero"
				flowPayment.balance == price:
					"Your vault does not have balance to buy NFT"
				receiptAddress != nil:
					"receipt address must not be null"
			}
			var allNftTemplateExists = true
			assert(templateIds.length <= 10, message: "templates limit exceeded")
			let nftTemplateIds: [AnyStruct] = []
			for tempID in templateIds{ 
				let nftTemplateData = AFLNFT.getTemplateById(templateId: tempID)
				if nftTemplateData == nil{ 
					allNftTemplateExists = false
					break
				}
				nftTemplateIds.append(tempID)
			}
			let originalPackTemplateData = AFLNFT.getTemplateById(templateId: packTemplateId)
			let originalPackTemplateImmutableData = originalPackTemplateData.getImmutableData()
			originalPackTemplateImmutableData["nftTemplates"] = nftTemplateIds
			assert(allNftTemplateExists, message: "Invalid NFTs")
			AFLNFT.createTemplate(maxSupply: 1, immutableData: originalPackTemplateImmutableData)
			let lastIssuedTemplateId = AFLNFT.getLatestTemplateId()
			let receiptAccount = getAccount(AFLPack.ownerAddress)
			let recipientCollection = receiptAccount.capabilities.get<&FiatToken.Vault>(FiatToken.VaultReceiverPubPath).borrow<&FiatToken.Vault>() ?? panic("Could not get receiver reference to the flow receiver")
			recipientCollection.deposit(from: <-flowPayment)
			AFLNFT.mintNFT(templateId: lastIssuedTemplateId, account: receiptAddress)
			(AFLNFT.allTemplates[packTemplateId]!).incrementIssuedSupply()
			emit PackBought(templateId: lastIssuedTemplateId, receiptAddress: receiptAddress)
		}
		
		access(all)
		fun openPack(packNFT: @AFLNFT.NFT, receiptAddress: Address){ 
			pre{ 
				packNFT != nil:
					"pack nft must not be null"
				receiptAddress != nil:
					"receipt address must not be null"
			}
			var packNFTData = AFLNFT.getNFTData(nftId: packNFT.id)
			var packTemplateData = AFLNFT.getTemplateById(templateId: packNFTData.templateId)
			let templateImmutableData = packTemplateData.getImmutableData()
			let allIds = templateImmutableData["nftTemplates"]! as! [AnyStruct]
			assert(allIds.length <= 10, message: "templates limit exceeded")
			for tempID in allIds{ 
				AFLNFT.mintNFT(templateId: tempID as! UInt64, account: receiptAddress)
			}
			emit PackOpened(nftId: packNFT.id, receiptAddress: self.owner?.address)
			destroy packNFT
		}
		
		init(){} 
	}
	
	init(){ 
		self.ownerAddress = (self.account!).address
		var adminRefCap =
			self.account.capabilities.get<&FiatToken.Vault>(FiatToken.VaultReceiverPubPath)
		self.adminRef = adminRefCap!
		self.PackStoragePath = /storage/AFLPack
		self.PackPublicPath = /public/AFLPack
		self.account.storage.save(<-create Pack(), to: self.PackStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&{PackPublic}>(self.PackStoragePath)
		self.account.capabilities.publish(capability_1, at: self.PackPublicPath)
	}
}
