import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract MindtrixViews{ 
	access(all)
	struct MindtrixDisplay{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail:{ MetadataViews.File}
		
		access(all)
		let metadata:{ String: String}
		
		init(
			name: String,
			description: String,
			thumbnail:{ MetadataViews.File},
			metadata:{ 
				String: String
			}
		){ 
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.metadata = metadata
		}
	}
	
	access(all)
	struct Serials{ 
		access(all)
		let dic:{ String: String}
		
		access(all)
		let arr: [String]
		
		access(all)
		let str: String
		
		init(data:{ String: String}){ 
			let arr =
				[
					data["essenceRealmSerial"] ?? "0",
					data["essenceTypeSerial"] ?? "0",
					data["showSerial"] ?? "0",
					data["episodeSerial"] ?? "0",
					data["audioEssenceSerial"] ?? "0",
					data["nftEditionSerial"] ?? "0"
				]
			let str =
				(data["essenceRealmSerial"] ?? "0").concat(data["essenceTypeSerial"] ?? "0").concat(
					data["showSerial"] ?? "0"
				).concat(data["episodeSerial"] ?? "0").concat(data["audioEssenceSerial"] ?? "0")
					.concat(data["nftEditionSerial"] ?? "0")
			self.dic = data
			self.arr = arr
			self.str = str
		}
	}
	
	// AudioEssence is optional and only exists when an NFT is a VoiceSerial.audio.
	access(all)
	struct AudioEssence{ 
		// e.g. startTime = "96.0" = 00:01:36
		access(all)
		let startTime: String
		
		// e.g. endTime = "365.0" = 00:06:05
		access(all)
		let endTime: String
		
		// e.g. fullEpisodeDuration = "1864.0" = 00:31:04
		access(all)
		let fullEpisodeDuration: String
		
		init(startTime: String, endTime: String, fullEpisodeDuration: String){ 
			self.startTime = startTime
			self.endTime = endTime
			self.fullEpisodeDuration = fullEpisodeDuration
		}
	}
	
	// verify the conditions that a user should pass during minting
	access(all)
	struct interface IVerifier{ 
		access(all)
		fun verify(_ params:{ String: AnyStruct}, _ isAssert: Bool):{ String: Bool}
	}
	
	access(all)
	struct FT{ 
		access(all)
		let path: PublicPath
		
		access(all)
		let price: UFix64
		
		init(path: PublicPath, price: UFix64){ 
			self.path = path
			self.price = price
		}
	}
	
	access(all)
	struct Prices{ 
		access(all)
		var ftDic:{ String: FT}
		
		init(ftDic:{ String: FT}){ 
			self.ftDic = ftDic
		}
	}
	
	access(all)
	struct NFTIdentifier{ 
		access(all)
		let uuid: UInt64
		
		// UInt64 from getSerialNumber()
		access(all)
		let serial: UInt64
		
		// owner of the token at that time
		access(all)
		let holder: Address
		
		// The time this identifier is created, could be a claimTime, transferTime
		access(all)
		let createdTime: UFix64
		
		init(uuid: UInt64, serial: UInt64, holder: Address){ 
			self.uuid = uuid
			self.serial = serial
			self.holder = holder
			self.createdTime = getCurrentBlock().timestamp
		}
	}
	
	access(all)
	struct EssenceIdentifier{ 
		access(all)
		let uuid: UInt64
		
		// UInt64 from getSerialNumber()
		access(all)
		let serials: [String]
		
		// owner of the token at that time
		access(all)
		let holder: Address
		
		access(all)
		let showGuid: String
		
		access(all)
		let episodeGuid: String
		
		// The time this identifier is created, could be a claimTime, transferTime
		access(all)
		let createdTime: UFix64
		
		init(
			uuid: UInt64,
			serials: [
				String
			],
			holder: Address,
			showGuid: String,
			episodeGuid: String,
			createdTime: UFix64
		){ 
			self.uuid = uuid
			self.serials = serials
			self.showGuid = showGuid
			self.episodeGuid = episodeGuid
			self.holder = holder
			self.createdTime = getCurrentBlock().timestamp
		}
	}
	
	access(all)
	resource interface IPack{ 
		access(all)
		let id: UInt64
		
		access(all)
		var isOpen: Bool
		
		access(all)
		let templateId: UInt64
	}
	
	access(all)
	struct interface IPackTemplate{ 
		access(all)
		let templateId: UInt64
		
		access(all)
		let strMetadata:{ String: String}
		
		access(all)
		let intMetadata:{ String: UInt64}
		
		access(all)
		let totalSupply: UInt64
		
		access(account)
		fun verifyMintingConditions(
			recipientAddress: Address,
			recipientMintQuantityPerTransaction: UInt64
		): Bool
	}
	
	access(all)
	resource interface IPackAdminCreator{ 
		access(all)
		fun createPackTemplate(
			strMetadata:{ 
				String: String
			},
			intMetadata:{ 
				String: UInt64
			},
			totalSupply: UInt64,
			verifiers:{ 
				String:{ MindtrixViews.IVerifier}
			}
		): UInt64
		
		access(all)
		fun createPack(
			packTemplate:{ MindtrixViews.IPackTemplate},
			adminRef: Capability<&{MindtrixViews.IPackAdminOpener}>,
			owner: Address,
			royalties: [
				MetadataViews.Royalty
			]
		): @{NonFungibleToken.NFT}
	}
	
	access(all)
	resource interface IPackAdminOpener{ 
		access(all)
		fun openPack(
			userPack: &{MindtrixViews.IPack},
			packID: UInt64,
			owner: Address,
			royalties: [
				MetadataViews.Royalty
			]
		): @[{
			NonFungibleToken.NFT}
		]
	}
	
	access(all)
	struct interface IComponent{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
	}
	
	// IHashVerifier should be implemented in the Tracker resource to verify the hash from the NFT
	access(all)
	resource interface IHashVerifier{ 
		access(all)
		fun getMetadataHash(): [UInt8]
		
		access(all)
		fun verifyHash(setID: UInt64, packID: UInt64, metadataHash: [UInt8]): Bool
	}
	
	access(all)
	resource interface IHashProvider{ 
		access(all)
		fun borrowHashVerifier(setID: UInt64, packID: UInt64): &{IHashVerifier}
	}
}
