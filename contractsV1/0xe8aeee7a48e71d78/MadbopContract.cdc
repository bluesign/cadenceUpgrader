import MadbopNFTs from "./MadbopNFTs.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract MadbopContract{ 
	
	// event for madbop data initalization
	access(all)
	event MadbopDataInitialized(brandId: UInt64, jukeboxSchema: [UInt64], nftSchema: [UInt64])
	
	// event when madbop data is updated
	access(all)
	event MadbopDataUpdated(brandId: UInt64, jukeboxSchema: [UInt64], nftSchema: [UInt64])
	
	// event when a jukebox is created
	access(all)
	event JukeboxCreated(templateId: UInt64, openDate: UFix64)
	
	// event when a jukebox is opened
	access(all)
	event JukeboxOpened(nftId: UInt64, receiptAddress: Address?)
	
	// path for jukebox storage
	access(all)
	let JukeboxStoragePath: StoragePath
	
	// path for jukebox public
	access(all)
	let JukeboxPublicPath: PublicPath
	
	// dictionary to store Jukebox data
	access(self)
	var allJukeboxes:{ UInt64: JukeboxData}
	
	// dictionary to store madbop data
	access(self)
	var madbopData: MadbopData
	
	// capability of MadbopNFTs of NFTMethods to call the mint function on this capability
	access(contract)
	let adminRef: Capability<&{MadbopNFTs.NFTMethodsCapability}>
	
	// all methods are accessed by only the admin
	access(all)
	struct MadbopData{ 
		access(all)
		var brandId: UInt64
		
		access(contract)
		var jukeboxSchema: [UInt64]
		
		access(contract)
		var nftSchema: [UInt64]
		
		init(brandId: UInt64, jukeboxSchema: [UInt64], nftSchema: [UInt64]){ 
			self.brandId = brandId
			self.jukeboxSchema = jukeboxSchema
			self.nftSchema = nftSchema
		}
		
		access(all)
		fun updateData(brandId: UInt64, jukeboxSchema: [UInt64], nftSchema: [UInt64]){ 
			self.brandId = brandId
			self.jukeboxSchema = jukeboxSchema
			self.nftSchema = nftSchema
		}
	}
	
	access(all)
	struct JukeboxData{ 
		access(all)
		let templateId: UInt64
		
		access(all)
		let openDate: UFix64
		
		init(templateId: UInt64, openDate: UFix64){ 
			self.templateId = templateId
			self.openDate = openDate
		}
	}
	
	access(all)
	resource interface JukeboxPublic{ 
		// making this function public to call by other users
		access(all)
		fun openJukebox(jukeboxNFT: @{NonFungibleToken.NFT}, receiptAddress: Address)
	}
	
	access(all)
	resource Jukebox: JukeboxPublic{ 
		access(all)
		fun createJukebox(templateId: UInt64, openDate: UFix64){ 
			pre{ 
				templateId != nil:
					"template id must not be null"
				MadbopContract.allJukeboxes[templateId] == nil:
					"Jukebox already created with the given template id"
				openDate > 0.0:
					"Open date should be greater than zero"
			}
			let templateData = MadbopNFTs.getTemplateById(templateId: templateId)
			assert(templateData != nil, message: "data for given template id does not exist")
			// brand Id of template must be Madbop brand Id
			assert(templateData.brandId == MadbopContract.madbopData.brandId, message: "Invalid Brand id")
			// template must be the Jukebox template
			assert(MadbopContract.madbopData.jukeboxSchema.contains(templateData.schemaId), message: "Template does not contain Jukebox standard")
			assert(openDate >= getCurrentBlock().timestamp, message: "open date must be greater than current date")
			// check all templates under the jukexbox are created or not
			var allNftTemplateExists = true
			let templateImmutableData = templateData.getImmutableData()
			let allIds = templateImmutableData["nftTemplates"]! as! [AnyStruct]
			assert(allIds.length <= 5, message: "templates limit exceeded")
			for tempID in allIds{ 
				var castedTempId = UInt64(tempID as! Int)
				let nftTemplateData = MadbopNFTs.getTemplateById(templateId: castedTempId)
				if nftTemplateData == nil{ 
					allNftTemplateExists = false
					break
				}
			}
			assert(allNftTemplateExists, message: "Invalid NFTs")
			let newJukebox = JukeboxData(templateId: templateId, openDate: openDate)
			MadbopContract.allJukeboxes[templateId] = newJukebox
			emit JukeboxCreated(templateId: templateId, openDate: openDate)
		}
		
		// update madbop data function will be updated when a new user creates a new brand with its own data
		// and pass new user details
		access(all)
		fun updateMadbopData(brandId: UInt64, jukeboxSchema: [UInt64], nftSchema: [UInt64]){ 
			pre{ 
				brandId != nil:
					"brand id must not be null"
				jukeboxSchema != nil:
					"jukebox schema array must not be null"
				nftSchema != nil:
					"nft schema array must not be null"
			}
			MadbopContract.madbopData.updateData(brandId: brandId, jukeboxSchema: jukeboxSchema, nftSchema: nftSchema)
			emit MadbopDataUpdated(brandId: brandId, jukeboxSchema: jukeboxSchema, nftSchema: nftSchema)
		}
		
		// open jukebox function called by user to open specific jukebox to mint all the nfts in and transfer it to
		// the user address
		access(all)
		fun openJukebox(jukeboxNFT: @{NonFungibleToken.NFT}, receiptAddress: Address){ 
			pre{ 
				jukeboxNFT != nil:
					"jukebox nft must not be null"
				receiptAddress != nil:
					"receipt address must not be null"
			}
			var jukeboxMadbopNFTData = MadbopNFTs.getMadbopNFTDataById(nftId: jukeboxNFT.id)
			var jukeboxTemplateData = MadbopNFTs.getTemplateById(templateId: jukeboxMadbopNFTData.templateID)
			// check if it is regiesterd or not
			assert(MadbopContract.allJukeboxes[jukeboxMadbopNFTData.templateID] != nil, message: "Jukebox is not registered")
			// check if current date is greater or equal than opendate 
			assert((MadbopContract.allJukeboxes[jukeboxMadbopNFTData.templateID]!).openDate <= getCurrentBlock().timestamp, message: "current date must be greater than or equal to the open date")
			let templateImmutableData = jukeboxTemplateData.getImmutableData()
			let allIds = templateImmutableData["nftTemplates"]! as! [AnyStruct]
			assert(allIds.length <= 5, message: "templates limit exceeded")
			for tempID in allIds{ 
				var castedTempId = UInt64(tempID as! Int)
				(MadbopContract.adminRef.borrow()!).mintNFT(templateId: castedTempId, account: receiptAddress)
			}
			emit JukeboxOpened(nftId: jukeboxNFT.id, receiptAddress: self.owner?.address)
			destroy jukeboxNFT
		}
	}
	
	access(all)
	fun getAllJukeboxes():{ UInt64: JukeboxData}{ 
		pre{ 
			MadbopContract.allJukeboxes != nil:
				"jukebox does not exist"
		}
		return MadbopContract.allJukeboxes
	}
	
	access(all)
	fun getJukeboxById(jukeboxId: UInt64): JukeboxData{ 
		pre{ 
			MadbopContract.allJukeboxes[jukeboxId] != nil:
				"jukebox id does not exist"
		}
		return MadbopContract.allJukeboxes[jukeboxId]!
	}
	
	access(all)
	fun getMadbopData(): MadbopData{ 
		pre{ 
			MadbopContract.madbopData != nil:
				"data does not exist"
		}
		return MadbopContract.madbopData
	}
	
	init(){ 
		self.allJukeboxes ={} 
		self.madbopData = MadbopData(brandId: 0, jukeboxSchema: [], nftSchema: [])
		var adminPrivateCap =
			self.account.capabilities.get<&{MadbopNFTs.NFTMethodsCapability}>(
				MadbopNFTs.NFTMethodsCapabilityPrivatePath
			)
		self.adminRef = adminPrivateCap!
		self.JukeboxStoragePath = /storage/MadbopJukebox
		self.JukeboxPublicPath = /public/MadbopJukebox
		self.account.storage.save(<-create Jukebox(), to: self.JukeboxStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&{JukeboxPublic}>(self.JukeboxStoragePath)
		self.account.capabilities.publish(capability_1, at: self.JukeboxPublicPath)
		emit MadbopDataInitialized(brandId: 0, jukeboxSchema: [], nftSchema: [])
	}
}
