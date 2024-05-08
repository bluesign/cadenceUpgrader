// LicensedNFT
// Adds royalties to NFT
//
access(all)
contract interface LicensedNFT{ 
	access(all)
	struct interface Royalty{ 
		access(all)
		let address: Address
		
		access(all)
		let fee: UFix64
	}
	
	access(all)
	resource interface NFT{ 
		access(all)
		fun getRoyalties(): [{LicensedNFT.Royalty}]
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun getRoyalties(id: UInt64): [{LicensedNFT.Royalty}]
	}
	
	access(all)
	resource interface Collection: CollectionPublic{ 
		access(all)
		fun getRoyalties(id: UInt64): [{LicensedNFT.Royalty}]
	}
}
