import Crypto

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract interface IPackNFT{ 
	/// StoragePath for Collection Resource
	///
	access(all)
	let CollectionStoragePath: StoragePath
	
	/// PublicPath expected for deposit
	///
	access(all)
	let CollectionPublicPath: PublicPath
	
	/// PublicPath for receiving PackNFT
	///
	access(all)
	let CollectionIPackNFTPublicPath: PublicPath
	
	/// StoragePath for the PackNFT Operator Resource (issuer owns this)
	///
	access(all)
	let OperatorStoragePath: StoragePath
	
	/// PrivatePath to share IOperator interfaces with Operator (typically with PDS account)
	///
	access(all)
	let OperatorPrivPath: PrivatePath
	
	/// Request for Reveal
	///
	access(all)
	event RevealRequest(id: UInt64, openRequest: Bool)
	
	/// Request for Open
	///
	/// This is emitted when owner of a PackNFT request for the entitled NFT to be
	/// deposited to its account
	access(all)
	event OpenRequest(id: UInt64)
	
	/// Burned
	///
	/// Emitted when a PackNFT has been burned
	access(all)
	event Burned(id: UInt64)
	
	/// Opened
	///
	/// Emitted when a packNFT has been opened
	access(all)
	event Opened(id: UInt64)
	
	access(all)
	enum Status: UInt8{ 
		access(all)
		case Sealed
		
		access(all)
		case Revealed
		
		access(all)
		case Opened
	}
	
	access(all)
	struct interface Collectible{ 
		access(all)
		let address: Address
		
		access(all)
		let contractName: String
		
		access(all)
		let id: UInt64
		
		access(all)
		fun hashString(): String
		
		init(address: Address, contractName: String, id: UInt64)
	}
	
	access(all)
	resource interface IPack{ 
		access(all)
		let issuer: Address
		
		access(all)
		var status: Status
		
		access(all)
		fun verify(nftString: String): Bool
		
		access(contract)
		fun reveal(id: UInt64, nfts: [{IPackNFT.Collectible}], salt: String)
		
		access(contract)
		fun open(id: UInt64, nfts: [{IPackNFT.Collectible}])
		
		init(commitHash: String, issuer: Address)
	}
	
	access(all)
	resource interface IOperator{ 
		access(all)
		fun mint(distId: UInt64, commitHash: String, issuer: Address): @{IPackNFT.NFT}
		
		access(all)
		fun reveal(id: UInt64, nfts: [{Collectible}], salt: String)
		
		access(all)
		fun open(id: UInt64, nfts: [{IPackNFT.Collectible}])
	}
	
	access(all)
	resource interface PackNFTOperator: IOperator{ 
		access(all)
		fun mint(distId: UInt64, commitHash: String, issuer: Address): @{IPackNFT.NFT}
		
		access(all)
		fun reveal(id: UInt64, nfts: [{Collectible}], salt: String)
		
		access(all)
		fun open(id: UInt64, nfts: [{IPackNFT.Collectible}])
	}
	
	access(all)
	resource interface IPackNFTToken{ 
		access(all)
		let id: UInt64
		
		access(all)
		let issuer: Address
	}
	
	access(all)
	resource interface NFT: NonFungibleToken.NFT, IPackNFTToken, IPackNFTOwnerOperator{ 
		access(all)
		let id: UInt64
		
		access(all)
		let issuer: Address
		
		access(all)
		fun reveal(openRequest: Bool)
		
		access(all)
		fun open()
	}
	
	access(all)
	resource interface IPackNFTOwnerOperator{ 
		access(all)
		fun reveal(openRequest: Bool)
		
		access(all)
		fun open()
	}
	
	access(all)
	resource interface IPackNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(all)
		fun borrowPackNFT(id: UInt64): &{IPackNFT.NFT}?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || (result!).id == id:
					"Cannot borrow PackNFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(contract)
	fun revealRequest(id: UInt64, openRequest: Bool)
	
	access(contract)
	fun openRequest(id: UInt64)
	
	access(all)
	fun publicReveal(id: UInt64, nfts: [{IPackNFT.Collectible}], salt: String)
}
