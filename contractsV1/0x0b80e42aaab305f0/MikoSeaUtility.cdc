import MIKOSEANFTV2 from "./MIKOSEANFTV2.cdc"

import MIKOSEANFT from "./MIKOSEANFT.cdc"

import MikoSeaMarket from "./MikoSeaMarket.cdc"

import MikoSeaNFTMetadata from "./MikoSeaNFTMetadata.cdc"

access(all)
contract MikoSeaUtility{ 
	// rate transform from yen to usd, ex: {"USD_TO_JPY": 171.2}
	access(all)
	var ratePrice:{ String: UFix64}
	
	access(self)
	var metadata:{ String: String}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// is not in used
	access(all)
	struct NFTDataCommon{} 
	
	access(all)
	struct NFTDataWithListing{} 
	
	access(all)
	struct NFTDataCommonWithListing{ 
		access(all)
		let id: UInt64
		
		access(all)
		let serialNumber: UInt64
		
		access(all)
		let image: String
		
		access(all)
		let name: String
		
		access(all)
		let nftMetadata:{ String: String}
		
		access(all)
		let nftType: String
		
		access(all)
		let projectId: UInt64
		
		access(all)
		let projectTitle: String
		
		access(all)
		let projectDescription: String
		
		access(all)
		let flowProjectId: UInt64
		
		access(all)
		let projectMaxSupply: UInt64
		
		access(all)
		let isNFTReveal: Bool
		
		access(all)
		let blockHeight: UInt64
		
		access(all)
		let holder: Address
		
		access(all)
		let isInMarket: Bool
		
		access(all)
		let listingId: UInt64?
		
		init(
			id: UInt64,
			serialNumber: UInt64,
			name: String,
			image: String,
			nftMetadata:{ 
				String: String
			},
			projectId: UInt64,
			isNFTReveal: Bool,
			projectTitle: String,
			projectDescription: String,
			maxSupply: UInt64,
			blockHeight: UInt64,
			holder: Address,
			listingId: UInt64?,
			nftType: String
		){ 
			self.id = id
			self.serialNumber = serialNumber
			self.projectId = projectId
			self.flowProjectId = projectId
			self.image = image
			self.isNFTReveal = isNFTReveal
			self.projectTitle = projectTitle
			self.projectDescription = projectDescription
			self.name = name
			self.nftMetadata = nftMetadata
			self.blockHeight = blockHeight
			self.projectMaxSupply = maxSupply
			self.holder = holder
			self.isInMarket = listingId != nil
			self.listingId = listingId
			self.nftType = nftType
		}
	}
	
	access(all)
	fun yenToDollar(yen: UFix64): UFix64{ 
		if MikoSeaUtility.ratePrice["USD_TO_JPY"] == nil{ 
			return 0.0
		}
		if MikoSeaUtility.ratePrice["USD_TO_JPY"]! <= 0.0{ 
			return 0.0
		}
		return yen / MikoSeaUtility.ratePrice["USD_TO_JPY"]!
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun updateRate(key: String, value: UFix64){ 
			MikoSeaUtility.ratePrice[key] = value
		}
	}
	
	access(all)
	fun floor(_ num: Fix64): Int{ 
		var strRes = ""
		var numStr = num.toString()
		var i = 0
		while i < numStr.length{ 
			if numStr[i] == "."{ 
				break
			}
			strRes = strRes.concat(numStr.slice(from: i, upTo: i + 1))
			i = i + 1
		}
		let numInt = Int.fromString(strRes) ?? 0
		if Fix64(numInt) == num{ 
			return numInt
		}
		if num >= 0.0{ 
			return numInt
		}
		return numInt - 1
	}
	
	access(all)
	fun getListingId(addr: Address, nftType: Type, nftID: UInt64): UInt64?{ 
		if let ref =
			getAccount(addr).capabilities.get<&{MikoSeaMarket.StorefrontPublic}>(
				MikoSeaMarket.MarketPublicPath
			).borrow(){ 
			for order in ref.getOrders(){ 
				if nftID == order.nftID && order.nftType == nftType && order.status != "done"{ 
					return order.getId()
				}
			}
		}
		return nil
	}
	
	access(all)
	fun getNftV2Detail(_ nftID: UInt64): NFTDataCommonWithListing?{ 
		if let addr = MIKOSEANFTV2.getHolder(nftID: nftID){ 
			let account = getAccount(addr)
			let collectioncap = account.capabilities.get<&{MIKOSEANFTV2.CollectionPublic}>(MIKOSEANFTV2.CollectionPublicPath)
			if let collectionRef = collectioncap.borrow(){ 
				if let nft = collectionRef.borrowMIKOSEANFTV2(id: nftID){ 
					let project = MIKOSEANFTV2.getProjectById(nft.nftData.projectId)!
					return NFTDataCommonWithListing(id: nft.id, serialNumber: nft.nftData.serialNumber, name: nft.getMetadata()["name"] ?? "", image: nft.getImage(), nftMetadata: nft.getMetadata(), projectId: project.projectId, isNFTReveal: project.isReveal, projectTitle: nft.getTitle(), projectDescription: nft.getDescription(), maxSupply: project.maxSupply, blockHeight: nft.nftData.blockHeight, holder: addr, listingId: MikoSeaUtility.getListingId(addr: addr, nftType: Type<@MIKOSEANFTV2.NFT>(), nftID: nft.id), nftType: "mikoseav2")
				}
			}
		}
		return nil
	}
	
	access(all)
	fun getNftV1Detail(addr: Address, nftID: UInt64): NFTDataCommonWithListing?{ 
		let account = getAccount(addr)
		let collectionCapability =
			account.capabilities.get<&{MIKOSEANFT.MikoSeaCollectionPublic}>(
				MIKOSEANFT.CollectionPublicPath
			)
		let collectionRef = collectionCapability.borrow()
		if let collectionRef = collectionCapability.borrow(){ 
			if let nft = collectionRef.borrowMiKoSeaNFT(id: nftID){ 
				let listingId = MikoSeaUtility.getListingId(addr: addr, nftType: Type<@MIKOSEANFTV2.NFT>(), nftID: nft.id)
				return NFTDataCommonWithListing(id: nft.id, serialNumber: nft.data.mintNumber, name: nft.getTitle(), image: nft.getImage(), nftMetadata: MikoSeaNFTMetadata.getNFTMetadata(nftType: "mikosea", nftID: nft.id) ??{} , projectId: nft.data.projectId, isNFTReveal: true, projectTitle: nft.getTitle(), projectDescription: nft.getDescription(), maxSupply: MIKOSEANFT.getProjectTotalSupply(nft.data.projectId), blockHeight: 0, holder: addr, listingId: MikoSeaUtility.getListingId(addr: addr, nftType: Type<@MIKOSEANFT.NFT>(), nftID: nft.id), nftType: "mikosea")
			}
		}
		return nil
	}
	
	access(all)
	fun parseNftV2List(_ nfts: [&MIKOSEANFTV2.NFT]): [NFTDataCommonWithListing]{ 
		let projects:{ UInt64: &MIKOSEANFTV2.ProjectData} ={} 
		let response: [NFTDataCommonWithListing] = []
		for nft in nfts{ 
			if projects[nft.nftData.projectId] == nil{ 
				projects[nft.nftData.projectId] = MIKOSEANFTV2.getProjectById(nft.nftData.projectId)!
			}
			let project = projects[nft.nftData.projectId]!
			if let addr = MIKOSEANFTV2.getHolder(nftID: nft.id){ 
				let listingId = MikoSeaUtility.getListingId(addr: addr, nftType: Type<@MIKOSEANFTV2.NFT>(), nftID: nft.id)
				response.append(NFTDataCommonWithListing(id: nft.id, serialNumber: nft.nftData.serialNumber, name: nft.getMetadata()["name"] ?? "", image: nft.getImage(), nftMetadata: nft.getMetadata(), projectId: project.projectId, isNFTReveal: project.isReveal, projectTitle: nft.getTitle(), projectDescription: nft.getDescription(), maxSupply: project.maxSupply, blockHeight: nft.nftData.blockHeight, holder: addr, listingId: MikoSeaUtility.getListingId(addr: addr, nftType: Type<@MIKOSEANFTV2.NFT>(), nftID: nft.id), nftType: "mikoseav2"))
			}
		}
		return response
	}
	
	init(){ 
		self.AdminStoragePath = /storage/MikoSeaUtilityAdminStoragePath
		self.CollectionStoragePath = /storage/MikoSeaUtilityCollectionStoragePath
		self.CollectionPublicPath = /public/MikoSeaUtilityCollectionPublicPath
		self.ratePrice ={ "USD_TO_JPY": 130.75}
		self.metadata ={} 
		
		// Put the Admin in storage
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
