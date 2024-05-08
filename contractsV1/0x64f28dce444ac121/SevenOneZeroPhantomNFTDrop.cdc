/*
	Description: Smart Contract for Managing the 710 Phantom NFT Drop

	author: Bilal Shahid bilal@zay.codes
*/

import SevenOneZeroPhantomNFT from "./SevenOneZeroPhantomNFT.cdc"

access(all)
contract SevenOneZeroPhantomNFTDrop{ 
	access(all)
	enum PhantomType: UInt8{ 
		access(all)
		case access_phantom
		
		access(all)
		case regular_phantom
	}
	
	// Events don't support enums, so using raw value
	access(all)
	event MintedPhantom(id: UInt64, typeId: UInt32, phantomType: UInt8)
	
	access(self)
	var accessSupply: UInt32
	
	access(self)
	let maxAccessSupply: UInt32
	
	access(self)
	var accessSaleSupply: UInt32
	
	access(self)
	let maxAccessSaleSupply: UInt32
	
	access(self)
	var regularSupply: UInt32
	
	access(self)
	let maxRegularSupply: UInt32
	
	access(self)
	var regularSaleSupply: UInt32
	
	access(self)
	let maxRegularSaleSupply: UInt32
	
	access(self)
	var sessionIDsMinted:{ String: Bool}
	
	access(self)
	var accessPhantomIDs:{ UInt64: UInt32}
	
	access(self)
	var regularPhantomIDs:{ UInt64: UInt32}
	
	access(self)
	fun incrementRegularPhantomCount(
		adminRef: &SevenOneZeroPhantomNFT.Admin,
		nftID: UInt64,
		isFromSale: Bool
	): UInt32{ 
		if isFromSale{ 
			self.regularSaleSupply = self.regularSaleSupply + 1
		}
		self.regularSupply = self.regularSupply + 1
		self.regularPhantomIDs[nftID] = self.regularSupply
		emit MintedPhantom(
			id: nftID,
			typeId: self.regularSupply,
			phantomType: PhantomType.regular_phantom.rawValue
		)
		return self.regularSupply
	}
	
	access(self)
	fun incrementAccessPhantomCount(
		adminRef: &SevenOneZeroPhantomNFT.Admin,
		nftID: UInt64,
		isFromSale: Bool
	): UInt32{ 
		if isFromSale{ 
			self.accessSaleSupply = self.accessSaleSupply + 1
		}
		self.accessSupply = self.accessSupply + 1
		self.accessPhantomIDs[nftID] = self.accessSupply
		emit MintedPhantom(
			id: nftID,
			typeId: self.accessSupply,
			phantomType: PhantomType.access_phantom.rawValue
		)
		return self.accessSupply
	}
	
	access(all)
	fun batchIncrementRegularPhantomCount(
		adminRef: &SevenOneZeroPhantomNFT.Admin,
		nftIDs: [
			UInt64
		],
		sessionID: String,
		isFromSale: Bool
	): [
		UInt32
	]{ 
		pre{ 
			!(self.sessionIDsMinted[sessionID] ?? false):
				"sessionID already used"
			!isFromSale || self.regularSaleSupply + UInt32(nftIDs.length) <= self.maxRegularSaleSupply:
				"Requesting too many regular phantoms to be sold"
			self.regularSupply + UInt32(nftIDs.length) <= self.maxRegularSupply:
				"Requesting too many regular phantoms"
			nftIDs.length <= 20:
				"Can not mint more than 20 phantoms at once"
		}
		post{ 
			self.sessionIDsMinted[sessionID] == true:
				"SessionID was not set to true as expected"
		}
		var accessIDs: [UInt32] = []
		self.sessionIDsMinted[sessionID] = true
		for nftID in nftIDs{ 
			accessIDs.append(self.incrementRegularPhantomCount(adminRef: adminRef, nftID: nftID, isFromSale: isFromSale))
		}
		return accessIDs
	}
	
	access(all)
	fun batchIncrementAccessPhantomCount(
		adminRef: &SevenOneZeroPhantomNFT.Admin,
		nftIDs: [
			UInt64
		],
		sessionID: String,
		isFromSale: Bool
	): [
		UInt32
	]{ 
		pre{ 
			!(self.sessionIDsMinted[sessionID] ?? false):
				"sessionID already used"
			!isFromSale || self.accessSaleSupply + UInt32(nftIDs.length) <= self.maxAccessSaleSupply:
				"Requesting too many access phantoms to be sold"
			self.accessSupply + UInt32(nftIDs.length) <= self.maxAccessSupply:
				"Requesting too many access phantoms"
			nftIDs.length <= 20:
				"Can not mint more than 20 phantoms at once"
		}
		post{ 
			self.sessionIDsMinted[sessionID] == true:
				"SessionID was not set to true as expected"
		}
		var accessIDs: [UInt32] = []
		self.sessionIDsMinted[sessionID] = true
		for nftID in nftIDs{ 
			accessIDs.append(self.incrementAccessPhantomCount(adminRef: adminRef, nftID: nftID, isFromSale: isFromSale))
		}
		return accessIDs
	}
	
	access(all)
	fun getAccessPhantomIDForNFT(nftID: UInt64): UInt32?{ 
		return self.accessPhantomIDs[nftID]
	}
	
	access(all)
	fun getRegularPhantomIDForNFT(nftID: UInt64): UInt32?{ 
		return self.regularPhantomIDs[nftID]
	}
	
	access(all)
	fun getRegularPhantomSupply(): UInt32{ 
		return self.regularSupply
	}
	
	access(all)
	fun getRegularPhantomSaleSupply(): UInt32{ 
		return self.regularSaleSupply
	}
	
	access(all)
	fun getAccessPhantomSupply(): UInt32{ 
		return self.accessSupply
	}
	
	access(all)
	fun getAccessPhantomSaleSupply(): UInt32{ 
		return self.accessSaleSupply
	}
	
	access(all)
	fun getIsSessionIDMinted(sessionID: String): Bool{ 
		return self.sessionIDsMinted[sessionID] ?? false
	}
	
	init(){ 
		self.regularSupply = 0
		self.accessSupply = 0
		self.regularSaleSupply = 0
		self.accessSaleSupply = 0
		
		// Total of 7100 tokens
		self.maxRegularSupply = 5690
		self.maxAccessSupply = 1410
		
		// 965 Cores and 100 Access are reserved to not be for sale
		self.maxRegularSaleSupply = self.maxRegularSupply - 965
		self.maxAccessSaleSupply = self.maxAccessSupply - 100
		self.sessionIDsMinted ={} 
		self.accessPhantomIDs ={} 
		self.regularPhantomIDs ={} 
	}
}
