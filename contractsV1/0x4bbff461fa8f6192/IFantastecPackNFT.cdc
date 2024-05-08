import Crypto

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FantastecNFT from "./FantastecNFT.cdc"

access(all)
contract interface IFantastecPackNFT{ 
	/// StoragePath for Collection Resource
	access(all)
	let CollectionStoragePath: StoragePath
	
	/// PublicPath expected for deposit
	access(all)
	let CollectionPublicPath: PublicPath
	
	/// PublicPath for receiving NFT
	access(all)
	let CollectionIFantastecPackNFTPublicPath: PublicPath
	
	/// StoragePath for the NFT Operator Resource (issuer owns this)
	access(all)
	let OperatorStoragePath: StoragePath
	
	/// PrivatePath to share IOperator interfaces with Operator (typically with PDS account)
	access(all)
	let OperatorPrivPath: PrivatePath
	
	/// Burned
	/// Emitted when a NFT has been burned
	access(all)
	event Burned(id: UInt64)
	
	access(all)
	resource interface IOperator{ 
		access(all)
		fun mint(packId: UInt64, productId: UInt64): @{IFantastecPackNFT.NFT}
		
		access(all)
		fun addFantastecNFT(id: UInt64, nft: @FantastecNFT.NFT)
		
		access(all)
		fun open(id: UInt64, recipient: Address)
	}
	
	access(all)
	resource interface FantastecPackNFTOperator: IOperator{ 
		access(all)
		fun mint(packId: UInt64, productId: UInt64): @{IFantastecPackNFT.NFT}
		
		access(all)
		fun addFantastecNFT(id: UInt64, nft: @FantastecNFT.NFT)
		
		access(all)
		fun open(id: UInt64, recipient: Address)
	}
	
	access(all)
	resource interface IFantastecPack{ 
		access(all)
		var ownedNFTs: @{UInt64: FantastecNFT.NFT}
		
		access(all)
		fun addFantastecNFT(nft: @FantastecNFT.NFT)
		
		access(all)
		fun open(recipient: Address)
	}
	
	access(all)
	resource interface NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
	}
	
	access(all)
	resource interface IFantastecPackNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
	}
}
