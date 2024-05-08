import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import StoreFrontSuperAdmin from "./StoreFrontSuperAdmin.cdc"

access(all)
contract SecondaryMarketplace{ 
	
	// -----------------------------------------------------------------------
	// SecondaryMarketplace contract Event definitions
	// -----------------------------------------------------------------------
	
	// emitted when a secondary marketplace is created
	access(all)
	event TokenCreated(royalty: UFix64, currency: Type, seller: Address?, databaseId: String)
	
	// emitted when a token is listed for sale
	access(all)
	event TokenListed(id: UInt64, price: UFix64, seller: Address?, databaseId: String)
	
	// emitted when the price of a listed token has changed
	access(all)
	event TokenPriceChanged(id: UInt64, price: UFix64, databaseId: String)
	
	// emitted when a token is purchased
	access(all)
	event TokenPurchased(id: UInt64, price: UFix64, buyer: Address, databaseId: String)
	
	// emitted when a token has been withdrawn from the sale
	access(all)
	event TokenWithdrawn(id: UInt64, databaseId: String)
	
	// emitted when the royalty fee has been changed by the owner
	access(all)
	event RoyaltyChanged(royalty: UFix64, databaseId: String)
	
	access(all)
	resource interface TokenSale{ 
		access(all)
		var royalty: UFix64
		
		access(all)
		fun purchase(
			tokenId: UInt64,
			kind: Type,
			vault: @{FungibleToken.Vault},
			address: Address
		): @{NonFungibleToken.NFT}{ 
			post{ 
				result.id == tokenId:
					"The Id of the withdrawn token must be the same as the requested Id"
				result.isInstance(kind):
					"The Type of the withdrawn token must be the same as the requested Type"
			}
		}
		
		access(all)
		fun getPrice(tokenId: UInt64): UFix64?
		
		access(all)
		fun getTokenIds(): [UInt64]
	}
	
	// ItemMeta contains the metadata for an Secondary marketplace
	access(all)
	struct ItemMeta{ 
		access(all)
		let tokenId: UInt64
		
		access(all)
		let databaseId: String
		
		access(all)
		var price: UFix64
		
		access(all)
		let finishAtTimestamp: UFix64
		
		init(tokenId: UInt64, price: UFix64, finishAtTimestamp: UFix64, databaseId: String){ 
			self.price = price
			self.tokenId = tokenId
			self.finishAtTimestamp = finishAtTimestamp
			self.databaseId = databaseId
		}
		
		access(all)
		fun updatePrice(price: UFix64){ 
			self.price = price
		}
	}
	
	access(all)
	resource TokenSaleCollection: TokenSale{ 
		access(self)
		var collection: Capability<&{NonFungibleToken.Collection}>
		
		access(self)
		var items:{ UInt64: ItemMeta}
		
		access(self)
		var ownerCapability: Capability<&{FungibleToken.Receiver}>
		
		access(self)
		var royaltyCapability: Capability<&{FungibleToken.Receiver}>
		
		access(self)
		var beneficiaryCapability: Capability<&{FungibleToken.Receiver}>
		
		access(self)
		var storeFrontCapability: Capability<&StoreFrontSuperAdmin.SuperAdmin>
		
		access(all)
		var royalty: UFix64
		
		access(all)
		let currency: Type
		
		init(collection: Capability<&{NonFungibleToken.Collection}>, ownerCapability: Capability<&{FungibleToken.Receiver}>, royaltyCapability: Capability<&{FungibleToken.Receiver}>, beneficiaryCapability: Capability<&{FungibleToken.Receiver}>, royalty: UFix64, currency: Type, storeFrontAddress: Address, storeFrontPublicPath: PublicPath, databaseId: String){ 
			pre{ 
				collection.borrow() != nil:
					"Owner's Token Collection Capability is invalid!"
				ownerCapability.borrow() != nil:
					"Owner's Receiver Capability is invalid!"
				royaltyCapability.borrow() != nil:
					"Royalties Receiver Capability is invalid!"
				beneficiaryCapability.borrow() != nil:
					"Beneficiary Receiver Capability is invalid!"
			}
			self.storeFrontCapability = getAccount(storeFrontAddress).capabilities.get<&StoreFrontSuperAdmin.SuperAdmin>(storeFrontPublicPath)!
			self.collection = collection
			self.ownerCapability = ownerCapability
			self.royaltyCapability = royaltyCapability
			self.beneficiaryCapability = beneficiaryCapability
			self.items ={} 
			self.royalty = royalty
			self.currency = currency
			emit TokenCreated(royalty: royalty, currency: currency, seller: (collection.borrow()!).owner?.address, databaseId: databaseId)
		}
		
		access(all)
		fun listForSale(tokenId: UInt64, price: UFix64, finishAtTimestamp: UFix64, databaseId: String){ 
			pre{ 
				(self.collection.borrow()!).borrowNFT(tokenId) != nil:
					"Token does not exist in the owner's collection!"
			}
			self.items[tokenId] = ItemMeta(tokenId: tokenId, price: price, finishAtTimestamp: finishAtTimestamp, databaseId: databaseId)
			emit TokenListed(id: tokenId, price: price, seller: self.owner?.address, databaseId: databaseId)
		}
		
		access(all)
		fun cancelSale(tokenId: UInt64){ 
			pre{ 
				(self.collection.borrow()!).borrowNFT(tokenId) != nil:
					"Token does not exist in the owner's collection!"
			}
			assert(self.items[tokenId] != nil, message: "No token with this Id on sale!")
			let databaseId = (self.items[tokenId]!).databaseId
			self.items.remove(key: tokenId)
			self.items[tokenId] = nil
			emit TokenWithdrawn(id: tokenId, databaseId: databaseId)
		}
		
		access(all)
		fun purchase(tokenId: UInt64, kind: Type, vault: @{FungibleToken.Vault}, address: Address): @{NonFungibleToken.NFT}{ 
			pre{ 
				(self.collection.borrow()!).borrowNFT(tokenId) != nil:
					"No token matching this Id in collection!"
				vault.isInstance(self.currency):
					"Vault does not hold the required currency type"
				self.items[tokenId] != nil:
					"No token with this Id on sale!"
				vault.balance == (self.items[tokenId]!).price:
					"Amount does not match the token price"
			}
			if (self.items[tokenId]!).finishAtTimestamp < getCurrentBlock().timestamp{ 
				panic("token is not available")
			}
			let price = (self.items[tokenId]!).price
			let databaseId = (self.items[tokenId]!).databaseId
			self.items[tokenId] = nil
			let fee = (self.storeFrontCapability.borrow()!).getSecondaryMarketplaceFee()
			var amount = price * fee
			if amount > vault.balance{ 
				amount = vault.balance
			}
			let beneficiaryFee <- vault.withdraw(amount: amount)
			(self.beneficiaryCapability.borrow()!).deposit(from: <-beneficiaryFee)
			var royaltyAmount = price * self.royalty
			if royaltyAmount > vault.balance{ 
				royaltyAmount = vault.balance
			}
			let royaltyFee <- vault.withdraw(amount: royaltyAmount)
			(self.royaltyCapability.borrow()!).deposit(from: <-royaltyFee)
			(self.ownerCapability.borrow()!).deposit(from: <-vault)
			emit TokenPurchased(id: tokenId, price: price, buyer: address, databaseId: databaseId)
			return <-(self.collection.borrow()!).withdraw(withdrawID: tokenId)
		}
		
		access(all)
		fun changePrice(tokenId: UInt64, price: UFix64){ 
			pre{ 
				(self.collection.borrow()!).borrowNFT(tokenId) != nil:
					"Token does not exist in the owner's collection!"
			}
			assert(self.items[tokenId] != nil, message: "No token with this Id on sale!")
			(self.items[tokenId]!).updatePrice(price: price)
			emit TokenPriceChanged(id: tokenId, price: price, databaseId: (self.items[tokenId]!).databaseId)
		}
		
		access(all)
		fun changeRoyalty(_ royalty: UFix64, databaseId: String){ 
			self.royalty = royalty
			emit RoyaltyChanged(royalty: self.royalty, databaseId: databaseId)
		}
		
		access(all)
		fun getPrice(tokenId: UInt64): UFix64?{ 
			if let cap = self.collection.borrow(){ 
				if (cap!).getIDs().contains(tokenId){ 
					let token = (cap!).borrowNFT(tokenId)
					return (self.items[tokenId]!).price
				}
			}
			return nil
		}
		
		access(all)
		fun getTokenIds(): [UInt64]{ 
			return self.items.keys
		}
	}
	
	access(all)
	fun createTokenSaleCollection(
		collection: Capability<&{NonFungibleToken.Collection}>,
		ownerCapability: Capability<&{FungibleToken.Receiver}>,
		beneficiaryCapability: Capability<&{FungibleToken.Receiver}>,
		royaltyCapability: Capability<&{FungibleToken.Receiver}>,
		royalty: UFix64,
		currency: Type,
		storeFrontAddress: Address,
		storeFrontPublicPath: PublicPath,
		databaseId: String
	): @TokenSaleCollection{ 
		return <-create TokenSaleCollection(
			collection: collection,
			ownerCapability: ownerCapability,
			royaltyCapability: royaltyCapability,
			beneficiaryCapability: beneficiaryCapability,
			royalty: royalty,
			currency: currency,
			storeFrontAddress: storeFrontAddress,
			storeFrontPublicPath: storeFrontPublicPath,
			databaseId: databaseId
		)
	}
}
