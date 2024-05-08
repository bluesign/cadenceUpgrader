import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract interface NonFungibleTokenMinter{ 
	access(all)
	event Minted(to: Address, id: UInt64, metadata:{ String: String})
	
	access(all)
	resource interface MinterProvider{ 
		access(all)
		fun mintNFT(
			id: UInt64,
			recipient: &{NonFungibleToken.CollectionPublic},
			metadata:{ 
				String: String
			}
		)
	}
	
	access(all)
	resource interface NFTMinter: MinterProvider{ 
		access(all)
		fun mintNFT(id: UInt64, recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String})
	}
}
