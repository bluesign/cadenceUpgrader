import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract interface NFTPlus{ 
	access(all)
	event Transfer(id: UInt64, from: Address?, to: Address)
	
	access(all)
	fun receiver(_ address: Address): Capability<&{NonFungibleToken.Receiver}>
	
	access(all)
	fun collectionPublic(_ address: Address): Capability<&{NonFungibleToken.CollectionPublic}>
	
	access(all)
	struct interface Royalties{ 
		access(all)
		let address: Address
		
		access(all)
		let fee: UFix64
	}
	
	access(all)
	resource interface WithRoyalties{ 
		access(all)
		fun getRoyalties(): [{NFTPlus.Royalties}]
	}
	
	access(all)
	resource interface Transferable{ 
		access(all)
		fun transfer(tokenId: UInt64, to: Capability<&{NonFungibleToken.Receiver}>)
	}
	
	access(all)
	resource interface NFT: NonFungibleToken.NFT, WithRoyalties{ 
		access(all)
		let id: UInt64
		
		access(all)
		fun getRoyalties(): [{NFTPlus.Royalties}]
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun getRoyalties(id: UInt64): [{NFTPlus.Royalties}]
	}
	
	access(all)
	resource interface Collection:
		NonFungibleToken.Provider,
		NonFungibleToken.Receiver,
		NonFungibleToken.Collection,
		NonFungibleToken.CollectionPublic,
		Transferable,
		CollectionPublic{
	
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(all)
		fun getRoyalties(id: UInt64): [{NFTPlus.Royalties}]
	}
}
