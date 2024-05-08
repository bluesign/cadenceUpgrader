import BloomlyNFT from "./BloomlyNFT.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

// Contract Interface
access(all)
contract BloomlyDrop{ 
	/**###################### Contract Events #########################**/
	// Emits an event wlethen new drop created
	access(all)
	event DropCreated(
		author: Address,
		dropId: UInt64,
		brandId: UInt64,
		startTime: UFix64,
		endTime: UFix64?,
		assets:{ 
			UInt64: Asset
		},
		dropType: String,
		price: UFix64,
		whitelist: [
			Address
		]?
	)
	
	// Emits updateDrop Event
	access(all)
	event DropUpdated(
		author: Address,
		dropId: UInt64,
		brandId: UInt64,
		startTime: UFix64,
		endTime: UFix64?,
		assets:{ 
			UInt64: Asset
		},
		dropType: String,
		price: UFix64,
		whitelist: [
			Address
		]?
	)
	
	// Emits removeDrop emit
	access(all)
	event DropRemoved(author: Address, dropId: UInt64, brandId: UInt64)
	
	// Emits an event when user purchase asset
	access(all)
	event AssetPurchased(
		dropId: UInt64,
		brandId: UInt64,
		assetId: UInt64,
		supply: UInt64,
		price: UFix64,
		userAccount: Address
	)
	
	// Emits an event when user claim asset from airdrop
	access(all)
	event AirdropClaimed(
		dropId: UInt64,
		brandId: UInt64,
		assetId: UInt64,
		supply: UInt64,
		userAccount: Address
	)
	
	// Emits an event when user purchase asset
	access(all)
	event OffRampAssetPurchased(
		dropId: UInt64,
		brandId: UInt64,
		assetId: UInt64,
		supply: UInt64,
		price: UFix64,
		userAccount: Address
	)
	
	/**###################### Contract State Variables #########################**/
	// Contract storage variable to store all drops list against specific brand i.e. {brandId: {dropId: Drop}}
	access(contract)
	var dropList:{ UInt64:{ UInt64: Drop}}
	
	// User asset claimed amount list against each drop
	access(contract)
	var userClaimedDrop:{ Address:{ UInt64:{ UInt64: UInt64}}}
	
	// Admin resource capability private path
	access(all)
	var adminCapPrivatePath: PrivatePath
	
	// Admin resource capability storage path
	access(all)
	var adminCapStoragePath: StoragePath
	
	// Drop client resource capability private path
	access(all)
	var clientCapPrivatePath: PrivatePath
	
	// Drop client resource capability storage path
	access(all)
	var clientCapStoragePath: StoragePath
	
	// Super Admin storage path
	access(all)
	var SuperAdminStoragePath: StoragePath
	
	// Token vault resource capability to deposit token to user account
	access(contract)
	var withdrawalVault: Capability<&FlowToken.Vault>
	
	// NFT client resource capability for the purpose to mint nft for user
	access(contract)
	var nftCap: Capability<&{BloomlyNFT.NFTMethodsCapability}>
	
	/**###################### Contract Custom Data Structures #########################**/
	/** Drop Metadata Structure
		This structure is used to define metadata of drop
	  **/
	
	access(all)
	struct DropMetadata{ 
		// Name of drop
		access(all)
		var dropName: String
		
		// Description of drop
		access(all)
		var dropDescription: String
		
		// Drop other metadata information i.e. information about drop
		access(contract)
		var extra:{ String: AnyStruct}
		
		// Initialization of Drop
		init(dropName: String, dropDescription: String, extra:{ String: AnyStruct}){ 
			self.dropName = dropName
			self.dropDescription = dropDescription
			self.extra = extra
		}
		
		// functiont to get extra data
		access(all)
		fun getExtra():{ String: AnyStruct}{ 
			return self.extra
		}
	}
	
	/** Drop Data Structure
		  This structure is used to create new drop with mentioned details
	  **/
	
	access(all)
	struct Drop{ 
		// unique drop Id
		access(all)
		let dropId: UInt64
		
		// brand Id
		access(all)
		let brandId: UInt64
		
		// Drop metadata i.e. information about drop
		access(all)
		var dropMetadata: DropMetadata?
		
		// Start time of drop after only then user can purchase/claim
		access(all)
		var startTime: UFix64
		
		// End time of drop after purchase/claim get stopped
		access(all)
		var endTime: UFix64?
		
		// List of assets available for sale for drop i.e., {templateId: Asset}
		access(contract)
		var assets:{ UInt64: Asset}
		
		// Drop type i.e., Airdrop or Sale
		access(all)
		var dropType: String
		
		// whitelist drop users
		access(contract)
		var whitelist: [Address]?
		
		// Price of asset/nft
		access(all)
		var price: UFix64
		
		// Initialization of Drop
		init(
			dropId: UInt64,
			brandId: UInt64,
			dropMetadata: DropMetadata?,
			startTime: UFix64,
			endTime: UFix64?,
			assets:{ 
				UInt64: Asset
			},
			dropType: String,
			whitelist: [
				Address
			]?,
			price: UFix64
		){ 
			self.dropId = dropId
			self.brandId = brandId
			self.dropMetadata = dropMetadata
			self.startTime = startTime
			self.endTime = endTime
			self.assets = assets
			self.dropType = dropType
			self.whitelist = whitelist
			self.price = price
		}
		
		// function to get drop metadata
		access(all)
		fun getDropMetadata(): DropMetadata?{ 
			return self.dropMetadata
		}
		
		// function to get asset data
		access(all)
		fun getAsset():{ UInt64: Asset}{ 
			return self.assets
		}
		
		access(all)
		fun updateDrop(
			startTime: UFix64,
			endTime: UFix64?,
			dropMetadata: DropMetadata?,
			assets:{ 
				UInt64: Asset
			},
			dropType: String,
			whitelist: [
				Address
			]?,
			price: UFix64
		){ 
			pre{ 
				startTime >= getCurrentBlock().timestamp:
					"Start time should be greater than current time"
				endTime == nil || endTime! > getCurrentBlock().timestamp:
					"End time should be greater than current time"
				endTime == nil || endTime! > startTime:
					"End time should be greater than start time"
			}
			self.startTime = startTime
			self.endTime = endTime
			self.price = price
			self.whitelist = whitelist
			self.dropType = self.dropType
			if dropMetadata != nil{ 
				self.dropMetadata = dropMetadata!
			}
			if assets != nil{ 
				self.assets = assets!
			}
		}
	}
	
	/** NFT metadata structure
		  This structure defines the metadata of asset and used at the time of minting
	  **/
	
	access(all)
	struct AssetMetadata{ 
		// BrandId of asset
		access(all)
		let brandId: UInt64
		
		// name of asset
		access(all)
		let name: String
		
		// description of asset
		access(all)
		let description: String
		
		// thumbnail of asset
		access(all)
		let thumbnail: String
		
		// mutableData of asset that can be changed by asset creator 
		access(contract)
		let mutableData:{ String: AnyStruct}?
		
		// immutableData of asset that cannot be changed by anyone
		access(contract)
		let immutableData:{ String: AnyStruct}?
		
		// royalties of asset that is used by peer-to-peer marketplace
		access(all)
		let royalties: [MetadataViews.Royalty]
		
		// status of asset whether asset is transferable or not
		access(all)
		let transferable: Bool
		
		// Initialisation of Asset
		init(
			brandId: UInt64,
			name: String,
			description: String,
			thumbnail: String,
			mutableData:{ 
				String: AnyStruct
			}?,
			immutableData:{ 
				String: AnyStruct
			}?,
			royalties: [
				MetadataViews.Royalty
			],
			transferable: Bool
		){ 
			self.brandId = brandId
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.mutableData = mutableData
			self.immutableData = immutableData
			self.royalties = royalties
			self.transferable = transferable
		}
		
		// function to get immutable data
		access(all)
		fun getImmutableData():{ String: AnyStruct}?{ 
			return self.immutableData
		}
		
		access(all)
		fun getMutableData():{ String: AnyStruct}?{ 
			return self.mutableData
		}
	}
	
	/** Asset Data Structure
		  This structure defines the asset information available for sale in specific drop
	  **/
	
	access(all)
	struct Asset{ 
		// Supply of asset/nft
		access(all)
		var supply: UInt64?
		
		// Type of asset i.e., PACK or TEMPLATE or NFT
		access(all)
		var assetType: String
		
		// Asset claim limit for a user
		access(all)
		var limit: UInt64
		
		// Initialisation of Asset
		init(supply: UInt64?, assetType: String, limit: UInt64){ 
			self.supply = supply
			self.assetType = assetType
			self.limit = limit
		}
		
		access(all)
		fun decrementSupply(supply: UInt64){ 
			pre{ 
				self.supply! - supply >= 0:
					"Insufficient drop supply"
			}
			self.supply = self.supply! - supply
		}
	}
	
	/**###################### Contract Resources #########################**/
	/** Drop Client Resource
		  This resource can create a new drop, claim and purchase drop asset 
	  **/
	
	access(all)
	resource Client{ 
		/** CreateDrop Method
				This method create new drop
			**/
		
		access(all)
		fun createDrop(
			dropId: UInt64,
			brandId: UInt64,
			dropMetadata: DropMetadata?,
			startTime: UFix64,
			endTime: UFix64?,
			assets:{ 
				UInt64: Asset
			},
			dropType: String,
			whitelist: [
				Address
			]?,
			price: UFix64
		){ 
			pre{ 
				assets.keys.length > 0:
					"Create drop with atleast one asset id"
				startTime >= getCurrentBlock().timestamp:
					"Start time should be greater than current time"
				endTime == nil || endTime! >= startTime:
					"End time should be greater than start time"
				dropType == "Airdrop" || dropType == "Sale":
					"Drop type not supported"
			}
			let brand = BloomlyNFT.getBrandById(brandId: brandId)
			assert(
				(brand!).authors.contains((self.owner!).address),
				message: "Only owner can create drop"
			)
			let BloomlyBrand = BloomlyDrop.dropList[brandId] ??{} 
			assert(BloomlyBrand[dropId] == nil, message: "Drop with this id already exists")
			// Checks on assets
			for assetId in assets.keys{ 
				assert((assets[assetId]!).assetType == "PACK" || (assets[assetId]!).assetType == "TEMPLATE" || (assets[assetId]!).assetType == "NFT", message: "Invalid asset type")
				if (assets[assetId]!).supply != nil{ 
					assert((assets[assetId]!).supply! > 0, message: "Asset supply should be greater than zero")
				}
				if (assets[assetId]!).assetType == "TEMPLATE"{ 
					BloomlyNFT.getTemplateById(templateId: assetId)
				}
			}
			// Create new asset object
			let newDrop: Drop =
				Drop(
					dropId: dropId,
					brandId: brandId,
					dropMetadata: dropMetadata,
					startTime: startTime,
					endTime: endTime,
					assets: assets,
					dropType: dropType,
					whitelist: whitelist,
					price: price
				)
			// Add new drop in dropList storage variable
			BloomlyBrand[dropId] = newDrop
			BloomlyDrop.dropList[brandId] = BloomlyBrand
			// Emit newly drop event
			emit DropCreated(
				author: (self.owner!).address,
				dropId: dropId,
				brandId: brandId,
				startTime: startTime,
				endTime: endTime,
				assets: assets,
				dropType: dropType,
				price: price,
				whitelist: whitelist
			)
		}
		
		access(all)
		fun updateDrop(
			dropId: UInt64,
			brandId: UInt64,
			dropMetadata: DropMetadata?,
			startTime: UFix64,
			endTime: UFix64?,
			assets:{ 
				UInt64: Asset
			},
			dropType: String,
			whitelist: [
				Address
			]?,
			price: UFix64
		){ 
			pre{ 
				assets.keys.length > 0:
					"Update drop with atleast one asset id"
				dropType == "Airdrop" || dropType == "Sale":
					"Drop type not supported"
			}
			let brand = BloomlyNFT.getBrandById(brandId: brandId)
			let BloomlyBrand = BloomlyDrop.dropList[brandId] ??{} 
			let drop = BloomlyBrand[dropId] ?? nil
			assert(
				(brand!).authors.contains((self.owner!).address),
				message: "Only owner can update drop"
			)
			assert(BloomlyBrand.length != 0, message: "Brand Id does not exists")
			assert(drop != nil, message: "Drop Id does not exists")
			for assetId in assets.keys{ 
				assert((assets[assetId]!).assetType == "PACK" || (assets[assetId]!).assetType == "TEMPLATE" || (assets[assetId]!).assetType == "NFT", message: "Invalid asset type")
				if (assets[assetId]!).supply != nil{ 
					assert((assets[assetId]!).supply! > 0, message: "Asset supply should be greater than zero")
				}
				if (assets[assetId]!).assetType == "TEMPLATE"{ 
					let templateDetails = BloomlyNFT.getTemplateById(templateId: assetId)
					assert(templateDetails.brandId == brandId, message: "Only owner can update drop")
				}
			}
			drop?.updateDrop(
				startTime: startTime,
				endTime: endTime,
				dropMetadata: dropMetadata,
				assets: assets,
				dropType: dropType,
				whitelist: whitelist,
				price: price
			)
			BloomlyBrand[dropId] = drop
			BloomlyDrop.dropList[brandId] = BloomlyBrand
			emit DropUpdated(
				author: (self.owner!).address,
				dropId: dropId,
				brandId: brandId,
				startTime: startTime,
				endTime: endTime,
				assets: assets,
				dropType: dropType,
				price: price,
				whitelist: whitelist
			)
		}
		
		access(all)
		fun deleteDrop(dropId: UInt64, brandId: UInt64){ 
			let brand = BloomlyNFT.getBrandById(brandId: brandId)
			let BloomlyBrand = BloomlyDrop.dropList[brandId] ??{} 
			let drop = BloomlyBrand[dropId] ?? nil
			assert(BloomlyBrand.length != 0, message: "Brand Id does not exists")
			assert(drop != nil, message: "Drop Id does not exists")
			assert(
				(brand!).authors.contains((self.owner!).address),
				message: "Only owner can remove drop"
			)
			BloomlyBrand.remove(key: dropId)
			BloomlyDrop.dropList[brandId] = BloomlyBrand
			emit DropRemoved(author: (self.owner!).address, dropId: dropId, brandId: brandId)
		}
	}
	
	// Private method for minting assets
	access(contract)
	fun mintDropAssets(
		dropId: UInt64,
		brandId: UInt64,
		assetId: UInt64,
		supply: UInt64,
		receiverRef: &{BloomlyNFT.BloomlyNFTCollectionPublic},
		assetMetadata: AssetMetadata,
		dropType: String
	){ 
		pre{ 
			supply <= 5:
				"You can purchase only five mints"
			supply > 0:
				"Asset supply should be greater than zero"
		}
		var BloomlyBrand = BloomlyDrop.dropList[brandId] ??{} 
		assert(BloomlyBrand.length != 0, message: "Brand Id does not exists")
		var drop = BloomlyBrand[dropId] ?? nil
		assert(drop != nil, message: "Drop Id does not exists")
		assert((drop!).dropType == dropType, message: "Invalid drop type")
		assert(getCurrentBlock().timestamp >= (drop!).startTime, message: "Drop is not started yet")
		assert(
			(drop!).endTime == nil || getCurrentBlock().timestamp <= (drop!).endTime!,
			message: "Drop is already expired"
		)
		assert((drop!).assets[assetId] != nil, message: "Asset in drop does not exists")
		assert(
			((drop!).assets[assetId]!).assetType == "TEMPLATE",
			message: "Asset should be of template type"
		)
		var userAccount = receiverRef.owner!
		var allClaimedBrands = BloomlyDrop.userClaimedDrop[userAccount.address] ??{} 
		var allClaimedDrops = allClaimedBrands[brandId] ??{} 
		var claimedAmount = allClaimedDrops[dropId] ?? 0
		if ((drop!).assets[assetId]!).limit != 0{ 
			assert(claimedAmount + supply <= ((drop!).assets[assetId]!).limit, message: "You've reached the limit to claim this drop asset")
		}
		allClaimedDrops[dropId] = claimedAmount + supply
		allClaimedBrands[brandId] = allClaimedDrops
		BloomlyDrop.userClaimedDrop[userAccount.address] = allClaimedBrands
		if ((drop!).assets[assetId]!).supply != nil{ 
			assert(((drop!).assets[assetId]!).supply! - supply >= 0, message: "Insufficient asset supply")
			((drop!).assets[assetId]!).decrementSupply(supply: supply)
			BloomlyBrand[dropId] = drop
			BloomlyDrop.dropList[brandId] = BloomlyBrand
		}
		// check whitelist
		if (drop!).whitelist != nil && ((drop!).whitelist!).length > 0{ 
			assert(((drop!).whitelist!).contains(userAccount.address), message: "You are not eligible to purchase this drop assets")
		}
		// Get royalities
		var royalty: [MetadataViews.Royalty] = []
		let templateData = BloomlyNFT.getTemplateById(templateId: assetId)
		let payouts = BloomlyNFT.getBrandPayouts(brandId: brandId)
		let isRoyaltyEnabled = templateData.getRoyaltyEnabledCheck()
		let templateRoyalty = templateData.getRoyalties()
		if isRoyaltyEnabled == true{ 
			if templateRoyalty != nil{ 
				royalty = templateRoyalty!
			} else if payouts != nil && (payouts!).royalties != nil{ 
				royalty = (payouts!).royalties
			} else{ 
				royalty = []
			}
		}
		// Borrow NFT resource capability and mint the NFT of given supply
		let capMint =
			BloomlyDrop.nftCap.borrow() ?? panic("Couldn't borrow the NFT resource capability")
		var i: UInt64 = 0
		while i < supply{ 
			capMint.mintNFT(brandId: brandId, templateId: assetId, receiverRef: receiverRef, immutableData: assetMetadata.immutableData, mutableData: assetMetadata.mutableData, name: assetMetadata.name, description: assetMetadata.description, thumbnail: assetMetadata.thumbnail, transferable: assetMetadata.transferable, royalties: royalty)
			i = i + 1
		}
	}
	
	//A Super-Admin resource can create Admimn resrouce
	access(all)
	resource SuperAdmin{ 
		//method to create Admin resource 
		access(all)
		fun createAdminResource(adminAddress: Address): @Admin{ 
			let allAdmins = BloomlyNFT.getAllAdmins()
			assert(
				allAdmins.contains(adminAddress) == true,
				message: "Not added as Admin in Bloomly NFT Contract"
			)
			return <-create Admin()
		}
	}
	
	/** Admin Data Structure
		This structure is used to create new admin resource which can create new Client Resource and perform other admin operation
	  **/
	
	access(all)
	resource Admin{ 
		/** createClientResource Method
			  This method create new drop resource
			**/
		
		access(all)
		fun createClientResource(): @BloomlyDrop.Client{ 
			let allAdmins = BloomlyNFT.getAllAdmins()
			assert(
				allAdmins.contains((self.owner!).address) == true,
				message: "Only Admin can create admin resource"
			)
			return <-create BloomlyDrop.Client()
		}
		
		/** Purchase Drop Method 
				This method purchase a asset with supply for uset that is available for sale in certain drop
			**/
		
		access(all)
		fun offRampPurchase(
			dropId: UInt64,
			brandId: UInt64,
			assetId: UInt64,
			supply: UInt64,
			receiverRef: &{BloomlyNFT.BloomlyNFTCollectionPublic},
			assetMetadata: AssetMetadata
		){ 
			let allAdmins = BloomlyNFT.getAllAdmins()
			assert(
				allAdmins.contains((self.owner!).address) == true,
				message: "Only Admin can purchase offramp drop"
			)
			let dropType = "Sale"
			var BloomlyBrand = BloomlyDrop.dropList[brandId] ??{} 
			var drop = BloomlyBrand[dropId] ?? nil
			assert(BloomlyBrand.length != 0, message: "Brand Id does not exists")
			assert(drop != nil, message: "Drop Id does not exists")
			BloomlyDrop.mintDropAssets(
				dropId: dropId,
				brandId: brandId,
				assetId: assetId,
				supply: supply,
				receiverRef: receiverRef,
				assetMetadata: assetMetadata,
				dropType: dropType
			)
			// Emit an event of newly claimed asset from drop
			emit OffRampAssetPurchased(
				dropId: dropId,
				brandId: brandId,
				assetId: assetId,
				supply: supply,
				price: (drop!).price * UFix64(supply),
				userAccount: (receiverRef.owner!).address
			)
		}
		
		/** Purchase Drop Method 
			  This method purchase a asset with supply for uset that is available for sale in certain drop
			**/
		
		access(all)
		fun flowPurchase(
			dropId: UInt64,
			brandId: UInt64,
			assetId: UInt64,
			supply: UInt64,
			receiverRef: &{BloomlyNFT.BloomlyNFTCollectionPublic},
			assetMetadata: AssetMetadata,
			flowPayment: @{FungibleToken.Vault},
			flowRate: UFix64
		){ 
			let allAdmins = BloomlyNFT.getAllAdmins()
			assert(
				allAdmins.contains((self.owner!).address) == true,
				message: "Only Admin can purchase drop"
			)
			var BloomlyBrand = BloomlyDrop.dropList[brandId] ??{} 
			var drop = BloomlyBrand[dropId] ?? nil
			assert(BloomlyBrand.length != 0, message: "Brand Id does not exists")
			assert(drop != nil, message: "Drop Id does not exists")
			var balance: UFix64 = flowPayment.balance
			assert(
				balance == flowRate * (drop!).price * UFix64(supply),
				message: "Your vault does not have balance to buy NFT"
			)
			// get contributors
			var contributors:{ Address: UFix64} ={} 
			let templateData = BloomlyNFT.getTemplateById(templateId: assetId)
			let brandDetailts = BloomlyNFT.getBrandById(brandId: brandId)
			let payouts = BloomlyNFT.getBrandPayouts(brandId: brandId)
			if templateData != nil{ 
				let templateContirbutors = templateData.getContibutors()
				if templateContirbutors != nil{ 
					contributors = templateContirbutors!
				} else if payouts != nil && (payouts!).contributors != nil{ 
					contributors = (payouts!).contributors!
				}
			}
			var paymentItr = 0
			//Firs we need to distribute Platform Fee for Bloomly
			let platformCut = brandDetailts.platormFee * balance
			let brandVault <- flowPayment.withdraw(amount: platformCut)
			// let receiverRefBloomlyVault =  BloomlyDrop.withdrawalVault.borrow()
			// 		?? panic("Could not borrow a reference to the receiver") 
			let platformFeeReceiverAddress: Address = 0x91c415324f0e3f83
			let receiverRefBloomlyVault =
				getAccount(platformFeeReceiverAddress).capabilities.get<&FlowToken.Vault>(
					/public/flowTokenReceiver
				).borrow<&FlowToken.Vault>()
				?? panic("Could not borrow a reference to the receiver")
			receiverRefBloomlyVault.deposit(from: <-brandVault)
			//balance = flowPayment.balance
			for contributor in contributors.keys{ 
				let cut = contributors[contributor]!
				let contributorAccount = getAccount(contributor)
				let amount: UFix64 = balance * cut
				let tempValut <- flowPayment.withdraw(amount: amount)
				// by borrowing the reference from the public capability
				let receiverRefVault = contributorAccount.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver).borrow<&FlowToken.Vault>() ?? panic("Could not borrow a reference to the receiver")
				receiverRefVault.deposit(from: <-tempValut)
			}
			assert(flowPayment.balance == 0.0, message: "amount is greater than drop amount")
			destroy flowPayment
			let dropType = "Sale"
			// Mint asset
			BloomlyDrop.mintDropAssets(
				dropId: dropId,
				brandId: brandId,
				assetId: assetId,
				supply: supply,
				receiverRef: receiverRef,
				assetMetadata: assetMetadata,
				dropType: dropType
			)
			// Emit an event of newly claimed asset from drop
			emit AssetPurchased(
				dropId: dropId,
				brandId: brandId,
				assetId: assetId,
				supply: supply,
				price: balance,
				userAccount: (receiverRef.owner!).address
			)
		}
		
		/** ClaimAirdrop Method 
			  This method claim a asset with supply for uset that is available for sale in certain drop
			**/
		
		access(all)
		fun claimAirdrop(
			dropId: UInt64,
			brandId: UInt64,
			assetId: UInt64,
			supply: UInt64,
			receiverRef: &{BloomlyNFT.BloomlyNFTCollectionPublic},
			assetMetadata: AssetMetadata
		){ 
			let allAdmins = BloomlyNFT.getAllAdmins()
			assert(
				allAdmins.contains((self.owner!).address) == true,
				message: "Only Admin can claim drop"
			)
			let dropType = "Airdrop"
			BloomlyDrop.mintDropAssets(
				dropId: dropId,
				brandId: brandId,
				assetId: assetId,
				supply: supply,
				receiverRef: receiverRef,
				assetMetadata: assetMetadata,
				dropType: dropType
			)
			emit AirdropClaimed(
				dropId: dropId,
				brandId: brandId,
				assetId: assetId,
				supply: supply,
				userAccount: (receiverRef.owner!).address
			)
		}
	}
	
	/**###################### Contract Storage Variable's View Methods #########################**/
	/** getAllDrops Method 
			This method return the list of drops 
	  **/
	
	access(all)
	fun getDropsByBrandId(brandId: UInt64):{ UInt64: Drop}{ 
		return self.dropList[brandId] ??{} 
	}
	
	/** getDropById Method 
			This method return specific drop against dropId
	  **/
	
	access(all)
	fun getDropById(dropId: UInt64, brandId: UInt64): Drop?{ 
		let drops = self.dropList[brandId] ??{} 
		return drops[dropId]
	}
	
	access(all)
	fun getAddressClaimed(user: Address):{ UInt64:{ UInt64: UInt64}}{ 
		return self.userClaimedDrop[user] ??{} 
	}
	
	// Initialisation of Contract 
	init(){ 
		// Initialise initial dropList storage variable
		self.dropList ={} 
		// Initialise claimedList storage variable
		self.userClaimedDrop ={} 
		// Initialise admin resource capability private path
		self.adminCapPrivatePath = /private/BloomlyDropAdminCapability
		// Initialise admin resource capability storage path
		self.adminCapStoragePath = /storage/BloomlyDropAdminResource
		// Initialise Drop client resource capability private path
		self.clientCapPrivatePath = /private/BloomlyDropClientCapability
		// Initialise Drop client resource capability storage path
		self.clientCapStoragePath = /storage/BloomlyDropClientPath
		// Initialise super-admin resource capability private path
		self.SuperAdminStoragePath = /storage/BloomlySuperAdmin
		// Get withdrawal account from address
		let withdrawalAcct = self.account
		// Initialise token resource vault capability
		self.withdrawalVault = withdrawalAcct.capabilities.get<&FlowToken.Vault>(
				/public/flowTokenReceiver
			)!
		// Initialise NFT resource capability
		self.nftCap = self.account.capabilities.get<&{BloomlyNFT.NFTMethodsCapability}>(
				BloomlyNFT.NFTMethodsCapabilityPrivatePath
			)!
		// Create and Store SuperAdmin in contract storage 
		self.account.storage.save(<-create SuperAdmin(), to: self.SuperAdminStoragePath)
		self.account.storage.save(<-create Admin(), to: self.adminCapStoragePath)
		// Link new Drop client resource capability in contract storage
		var capability_1 =
			self.account.capabilities.storage.issue<&BloomlyDrop.Admin>(self.adminCapStoragePath)
		self.account.capabilities.publish(capability_1, at: self.adminCapPrivatePath)
	}
}
