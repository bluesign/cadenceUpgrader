import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract interface Interfaces{ 
	
	// ARTIFACTAdminOpener is a interface resource used to
	// to open pack from a user wallet
	// 
	access(all)
	resource interface ARTIFACTAdminOpener{ 
		access(all)
		fun openPack(
			userPack: &{IPack},
			packID: UInt64,
			owner: Address,
			royalties: [
				MetadataViews.Royalty
			],
			packOption:{ IPackOption}?
		): @[{
			NonFungibleToken.NFT}
		]
	}
	
	// Resource interface to pack  
	// 
	access(all)
	resource interface IPack{ 
		access(all)
		let id: UInt64
		
		access(all)
		var isOpen: Bool
		
		access(all)
		let templateId: UInt64
	}
	
	// Struct interface to pack template 
	// 
	access(all)
	struct interface IPackTemplate{ 
		access(all)
		let templateId: UInt64
		
		access(all)
		let metadata:{ String: String}
		
		access(all)
		let totalSupply: UInt64
	}
	
	access(all)
	struct interface IHashMetadata{ 
		access(all)
		let hash: String
		
		access(all)
		let start: UInt64
		
		access(all)
		let end: UInt64
	}
	
	access(all)
	struct interface IPackOption{ 
		access(all)
		let options: [String]
		
		access(all)
		let hash:{ IHashMetadata}
	}
}
