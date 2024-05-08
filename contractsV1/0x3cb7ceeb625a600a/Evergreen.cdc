import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

// Evergreen contract defines a role-based model for distributing proceeds
// of primary and secondary sales of NFTs.
//
// Source: https://github.com/piprate/sequel-flow-contracts
//
access(all)
contract Evergreen{ 
	// Role defines a party in an NFT sale that may receive a commission fee
	// We deliberately abstract away from the concept of royalties in order
	// to support a broader variety of interactions with participant of NFT sales.
	access(all)
	struct Role{ 
		// id is an identifier of the role. Typical values:
		// * "Artist" - author of the NFT
		// * "Platform" - platform that minted the NFT or sponsored or facilitated the sale
		// * "Owner" - the current owner of the NFT (typically, the seller)
		access(all)
		let id: String
		
		// description is an optional field that described the role and/or the party.
		access(all)
		let description: String
		
		// initialSaleCommission is a commission rate charged by the role at the initial sale
		// (typically, immediately after minting). Allowed range: [0.0-1.0]
		access(all)
		let initialSaleCommission: UFix64
		
		// secondaryMarketCommission is a commission rate charged by the role
		// when the NFT is sold on the secondary market. Allowed range: [0.0-1.0]
		access(all)
		let secondaryMarketCommission: UFix64
		
		// address is the Flow address of the party that assumes this role.
		access(all)
		let address: Address
		
		// receiverPath (optional) is a public path to the parties fungible token receiver.
		// If specified, any non-zero commission payment will be deposited
		// to this receiver at the parties address (if valid).
		// If not specified, the receiver will be determined by the fungible
		// token's type used in the sale.
		access(all)
		let receiverPath: PublicPath?
		
		init(
			id: String,
			description: String,
			initialSaleCommission: UFix64,
			secondaryMarketCommission: UFix64,
			address: Address,
			receiverPath: PublicPath?
		){ 
			self.id = id
			self.description = description
			self.initialSaleCommission = initialSaleCommission
			self.secondaryMarketCommission = secondaryMarketCommission
			self.address = address
			self.receiverPath = receiverPath
		}
		
		access(all)
		fun commissionRate(initialSale: Bool): UFix64{ 
			return initialSale ? self.initialSaleCommission : self.secondaryMarketCommission
		}
	}
	
	// Profile defined a list of roles for the given NFT.
	// Each role may receive a commission fee at every sale.
	// The structure of this commission is defined in each role structure.
	access(all)
	struct Profile{ 
		// id is the profile DID, i.e. did:sequel:xyz
		access(all)
		let id: String
		
		// description is an optional field that described the purpose of this profile
		access(all)
		let description: String
		
		access(all)
		let roles: [Role]
		
		init(id: String, description: String, roles: [Role]){ 
			self.id = id
			self.description = description
			self.roles = roles
		}
		
		access(all)
		fun getRole(id: String): Role?{ 
			for role in self.roles{ 
				if role.id == id{ 
					return role
				}
			}
			return nil
		}
		
		access(all)
		fun buildRoyalties(defaultReceiverPath: PublicPath?): [MetadataViews.Royalty]{ 
			let royalties: [MetadataViews.Royalty] = []
			for role in self.roles{ 
				var path = role.receiverPath
				if path == nil{ 
					path = defaultReceiverPath
				}
				if path != nil{ 
					let receiverCap = getAccount(role.address).capabilities.get<&{FungibleToken.Receiver}>(path!)
					if receiverCap.check(){ 
						royalties.append(MetadataViews.Royalty(receiver: receiverCap!, cut: role.secondaryMarketCommission, description: role.description))
					}
				}
			}
			return royalties
		}
	}
	
	// Token defines an interface for "evergreen tokens" which are NFTs
	// that support Evergreen standard.
	access(all)
	resource interface Token{ 
		// getAssetID returns the asset ID (in DID format) that uniquely identifies
		// the NFT and all its editions.
		access(all)
		fun getAssetID(): String
		
		// getEvergreenProfile returns the token's Profile.
		access(all)
		fun getEvergreenProfile(): Profile
	}
	
	// An interface for reading the details of an evengreen token in the Collection.
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun borrowEvergreenToken(id: UInt64): &{Token}?
	}
}
