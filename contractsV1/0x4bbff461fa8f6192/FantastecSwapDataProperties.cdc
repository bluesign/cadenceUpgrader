/**
# Contract: FantastecSwapDataProperties
# Description:

The purpose of this contract is to define the metadata objects that are properties of cards and collections
(as defined in the fantastecSwapDataV2 contract)
*/

access(all)
contract FantastecSwapDataProperties{ 
	access(contract)
	var arrayTypes: [String]
	
	access(all)
	struct interface MetadataElement{ 
		access(all)
		let id: UInt64
	}
	
	access(all)
	struct ProductCollectionChance{ 
		access(all)
		let collectionId: UInt64
		
		access(all)
		let chance: UFix64
		
		init(_ collectionId: UInt64, _ chance: UFix64){ 
			self.collectionId = collectionId
			self.chance = chance
		}
	}
	
	access(all)
	struct ProductContent: MetadataElement{ 
		access(all)
		let id: UInt64
		
		access(all)
		let content: [ProductCollectionChance]
		
		init(_ id: UInt64){ 
			self.id = id
			self.content = []
		}
		
		access(all)
		fun add(_ collectionId: UInt64, _ chance: UFix64){ 
			let productCollectionChance = ProductCollectionChance(collectionId, chance)
			self.content.append(productCollectionChance)
		}
	}
	
	access(all)
	struct Media: MetadataElement{ 
		access(all)
		let id: UInt64
		
		access(all)
		let url: String
		
		access(all)
		let type: String
		
		access(all)
		let mediaType: String
		
		access(all)
		let ipfsCid: String
		
		access(all)
		let hash: String
		
		init(_ id: UInt64, _ url: String, _ type: String, _ mediaType: String, _ ipfsCid: String, _ hash: String){ 
			self.id = id
			self.url = url
			self.type = type
			self.mediaType = mediaType
			self.ipfsCid = ipfsCid
			self.hash = hash
		}
	}
	
	access(all)
	struct Social: MetadataElement{ 
		access(all)
		let id: UInt64
		
		access(all)
		let url: String
		
		access(all)
		let type: String
		
		init(_ id: UInt64, _ url: String, _ type: String){ 
			self.id = id
			self.url = url
			self.type = type
		}
	}
	
	access(all)
	struct Partner: MetadataElement{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		init(_ id: UInt64, _ name: String){ 
			self.id = id
			self.name = name
		}
	}
	
	access(all)
	struct Team: MetadataElement{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let gender: String
		
		init(_ id: UInt64, _ name: String, _ gender: String){ 
			self.id = id
			self.name = name
			self.gender = gender
		}
	}
	
	access(all)
	struct Sport: MetadataElement{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		init(_ id: UInt64, _ name: String){ 
			self.id = id
			self.name = name
		}
	}
	
	access(all)
	struct Sku: MetadataElement{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		init(_ id: UInt64, _ name: String){ 
			self.id = id
			self.name = name
		}
	}
	
	access(all)
	struct Season: MetadataElement{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let startDate: String
		
		access(all)
		let endDate: String
		
		init(_ id: UInt64, _ name: String, _ startDate: String, _ endDate: String){ 
			self.id = id
			self.name = name
			self.startDate = startDate
			self.endDate = endDate
		}
	}
	
	access(all)
	struct Level: MetadataElement{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let scarcity: String
		
		init(_ id: UInt64, _ name: String, _ scarcity: String){ 
			self.id = id
			self.name = name
			self.scarcity = scarcity
		}
	}
	
	access(all)
	struct Player: MetadataElement{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let gender: String
		
		access(all)
		let position: String?
		
		access(all)
		let shirtNumber: String?
		
		init(_ id: UInt64, _ name: String, _ gender: String, _ position: String?, _ shirtNumber: String?){ 
			self.id = id
			self.name = name
			self.gender = gender
			self.position = position
			self.shirtNumber = shirtNumber
		}
	}
	
	access(all)
	struct Royalty: MetadataElement{ 
		access(all)
		let id: UInt64
		
		access(all)
		let address: Address
		
		access(all)
		let percentage: UFix64
		
		init(_ id: UInt64, _ address: Address, _ percentage: UFix64){ 
			pre{ 
				percentage <= 100.0:
					"percentage cannot be higher than 100"
			}
			self.id = id
			self.address = address
			self.percentage = percentage
		}
	}
	
	access(all)
	struct License: MetadataElement{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let url: String
		
		access(all)
		let dateAwarded: String
		
		init(_ id: UInt64, _ name: String, _ url: String, _ dateAwarded: String){ 
			self.id = id
			self.name = name
			self.url = url
			self.dateAwarded = dateAwarded
		}
	}
	
	access(all)
	struct CardId: MetadataElement{ 
		access(all)
		let id: UInt64
		
		init(_ id: UInt64){ 
			self.id = id
		}
	}
	
	access(all)
	struct MintVolume: MetadataElement{ 
		access(all)
		let id: UInt64
		
		access(all)
		let value: UInt64
		
		init(_ id: UInt64, _ value: UInt64){ 
			self.id = id
			self.value = value
		}
	}
	
	access(all)
	struct RedeemInfo: MetadataElement{ 
		access(all)
		let id: UInt64
		
		access(all)
		let retailerName: String
		
		access(all)
		let retailerPinHash: String
		
		access(all)
		let retailerAddress: Address
		
		access(all)
		let validFrom: UFix64?
		
		access(all)
		let validTo: UFix64?
		
		init(_ id: UInt64, _ retailerName: String, _ retailerPinHash: String, _ retailerAddress: Address, _ validFrom: UFix64?, _ validTo: UFix64?){ 
			self.id = id
			self.retailerName = retailerName
			self.retailerPinHash = retailerPinHash
			self.retailerAddress = retailerAddress
			self.validFrom = validFrom
			self.validTo = validTo
		}
	}
	
	access(all)
	struct RedeemInfoV2: MetadataElement{ 
		access(all)
		let id: UInt64
		
		access(all)
		let retailerName: String
		
		access(all)
		let retailerPinHash: String
		
		access(all)
		let retailerAddress: Address
		
		access(all)
		let validFrom: UFix64?
		
		access(all)
		let validTo: UFix64?
		
		access(all)
		let type: String
		
		access(all)
		let t_and_cs: String
		
		access(all)
		let description: String
		
		init(_ id: UInt64, _ retailerName: String, _ retailerPinHash: String, _ retailerAddress: Address, _ validFrom: UFix64?, _ validTo: UFix64?, _ type: String, _ t_and_cs: String, _ description: String){ 
			self.id = id
			self.retailerName = retailerName
			self.retailerPinHash = retailerPinHash
			self.retailerAddress = retailerAddress
			self.validFrom = validFrom
			self.validTo = validTo
			self.type = type
			self.t_and_cs = t_and_cs
			self.description = description
		}
	}
	
	access(all)
	struct NewsFeed: MetadataElement{ 
		access(all)
		let id: UInt64
		
		access(all)
		let title: String
		
		access(all)
		let publishedDate: UFix64
		
		access(all)
		let buttonUrl: String
		
		access(all)
		let buttonText: String
		
		init(_ id: UInt64, _ title: String, _ publishedDate: UFix64, _ buttonUrl: String, _ buttonText: String){ 
			self.id = id
			self.title = title
			self.publishedDate = publishedDate
			self.buttonUrl = buttonUrl
			self.buttonText = buttonText
		}
	}
	
	access(all)
	struct BlockedUsers: MetadataElement{ 
		access(all)
		let id: UInt64
		
		access(all)
		let blockedAddresses: [Address]
		
		init(_ id: UInt64, _ blockedAddresses: [Address]){ 
			self.id = id
			self.blockedAddresses = blockedAddresses
		}
	}
	
	access(all)
	fun IsArrayMetadataType(_ type: String): Bool{ 
		return self.arrayTypes.contains(type)
	}
	
	access(all)
	fun parseUInt64(_ string: String?): UInt64?{ 
		if string == nil{ 
			return nil
		}
		return UInt64.fromString(string!)
	}
	
	access(all)
	fun parseUFix64(_ string: String?): UFix64?{ 
		if string == nil{ 
			return nil
		}
		return UFix64.fromString(string!)
	}
	
	access(all)
	fun parseAddress(_ string: String?): Address?{ 
		if string == nil{ 
			return nil
		}
		var addressString = string!
		if addressString.slice(from: 0, upTo: 2) == "0x"{ 
			addressString = addressString.slice(from: 2, upTo: addressString.length)
		}
		let bytes = addressString.decodeHex()
		let numberOfBytes: UInt64 = UInt64(bytes.length)
		var i: UInt64 = 0
		var addressAsInt: UInt64 = 0
		var multiplier: UInt64 = 1
		while i < numberOfBytes{ 
			let index: UInt64 = numberOfBytes - 1 - i
			let intPart = UInt64(bytes[index]) * multiplier
			addressAsInt = addressAsInt + intPart
			i = i + 1
			multiplier = multiplier.saturatingMultiply(256)
		}
		let address = Address(addressAsInt)
		return address
	}
	
	access(all)
	fun addToMetadata(
		_ type: String,
		_ metadataArray: [{
			MetadataElement}
		],
		_ metadata:{ MetadataElement}
	): [{
		MetadataElement}
	]{ 
		if self.IsArrayMetadataType(type){ 
			var updatedMetadataArray = self.removeMetadataElementById(metadataArray, metadata.id)
			updatedMetadataArray.append(metadata)
			return updatedMetadataArray
		} else{ 
			if metadataArray.length > 0{ 
				metadataArray.removeFirst()
			}
			metadataArray.append(metadata)
			return metadataArray
		}
	}
	
	access(all)
	fun removeFromMetadata(_ type: String, _ metadataArray: [{MetadataElement}], _ id: UInt64?): [{
		MetadataElement}
	]{ 
		if self.IsArrayMetadataType(type){ 
			let updatedMetadataArray = self.removeMetadataElementById(metadataArray, id!)
			return updatedMetadataArray
		} else{ 
			let metadataExists = metadataArray.length > 0
			if metadataExists{ 
				metadataArray.removeFirst()
			}
			return metadataArray
		}
	}
	
	access(all)
	fun removeMetadataElementById(_ array: [{MetadataElement}], _ id: UInt64): [{MetadataElement}]{ 
		if array == nil{ 
			return []
		}
		var indexToRemove: Int = -1
		for index, element in array{ 
			if element.id == id{ 
				indexToRemove = index
				break
			}
		}
		if indexToRemove > -1{ 
			array.remove(at: indexToRemove)
		}
		return array
	}
	
	init(){ 
		self.arrayTypes = ["media", "socials", "royalties", "licenses", "cardIds"]
	}
}
