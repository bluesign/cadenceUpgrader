// SPDX-License-Identifier: UNLICENSED
import FungibleBeatoken from "./FungibleBeatoken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import NonFungibleBeatoken from "./NonFungibleBeatoken.cdc"

access(all)
contract MarketplaceBeatoken{ 
	access(all)
	let publicSale: PublicPath
	
	access(all)
	let storageSale: StoragePath
	
	access(all)
	event ForSale(id: UInt64, price: UFix64)
	
	access(all)
	event PriceChanged(id: UInt64, newPrice: UFix64)
	
	access(all)
	event TokenPurchased(id: UInt64, price: UFix64)
	
	access(all)
	event SaleWithdrawn(id: UInt64)
	
	access(all)
	resource interface SalePublic{ 
		access(all)
		fun purchase(
			tokenID: UInt64,
			recipient: &NonFungibleBeatoken.Collection,
			buyTokens: @FungibleBeatoken.Vault
		)
		
		access(all)
		fun idPrice(tokenID: UInt64): UFix64?
		
		access(all)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(all)
		fun getIDs(): [UInt64]
	}
	
	access(all)
	resource SaleCollection: SalePublic{ 
		access(self)
		let ownerCollection: Capability<&NonFungibleBeatoken.Collection>
		
		access(self)
		let ownerVault: Capability<&FungibleBeatoken.Vault>
		
		access(self)
		let prices:{ UInt64: UFix64}
		
		access(all)
		var forSale: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(collection: Capability<&NonFungibleBeatoken.Collection>, vault: Capability<&FungibleBeatoken.Vault>){ 
			pre{ 
				collection.check():
					"Owner's Moment Collection Capability is invalid!"
				vault.check():
					"Owner's Receiver Capability is invalid!"
			}
			self.forSale <-{} 
			self.prices ={} 
			self.ownerCollection = collection
			self.ownerVault = vault
		}
		
		access(all)
		fun withdraw(tokenID: UInt64): @{NonFungibleToken.NFT}{ 
			self.prices.remove(key: tokenID)
			let token <- self.forSale.remove(key: tokenID) ?? panic("missing NFT")
			emit SaleWithdrawn(id: tokenID)
			return <-token
		}
		
		access(all)
		fun listForSale(token: @{NonFungibleToken.NFT}, price: UFix64){ 
			let id = token.id
			self.prices[id] = price
			let oldToken <- self.forSale[id] <- token
			destroy oldToken
			emit ForSale(id: id, price: price)
		}
		
		access(all)
		fun changePrice(tokenID: UInt64, newPrice: UFix64){ 
			self.prices[tokenID] = newPrice
			emit PriceChanged(id: tokenID, newPrice: newPrice)
		}
		
		access(all)
		fun purchase(tokenID: UInt64, recipient: &NonFungibleBeatoken.Collection, buyTokens: @FungibleBeatoken.Vault){ 
			pre{ 
				self.forSale[tokenID] != nil && self.prices[tokenID] != nil:
					"No token matching this ID for sale!"
				buyTokens.balance >= self.prices[tokenID] ?? 0.0:
					"Not enough tokens to by the NFT!"
			}
			let price = self.prices[tokenID]!
			self.prices[tokenID] = nil
			let vaultRef = self.ownerVault.borrow() ?? panic("Could not borrow reference to owner token vault")
			vaultRef.deposit(from: <-buyTokens)
			recipient.deposit(token: <-self.withdraw(tokenID: tokenID))
			emit TokenPurchased(id: tokenID, price: price)
		}
		
		access(all)
		fun idPrice(tokenID: UInt64): UFix64?{ 
			return self.prices[tokenID]
		}
		
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.forSale.keys
		}
		
		access(all)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}{ 
			return &self.forSale[id] as &{NonFungibleToken.NFT}?
		}
		
		access(all)
		fun cancelSale(tokenID: UInt64, recipient: &NonFungibleBeatoken.Collection){ 
			pre{ 
				self.prices[tokenID] != nil:
					"Token with the specified ID is not already for sale"
			}
			self.prices.remove(key: tokenID)
			self.prices[tokenID] = nil
			recipient.deposit(token: <-self.withdraw(tokenID: tokenID))
		}
	}
	
	access(all)
	fun createSaleCollection(
		ownerCollection: Capability<&NonFungibleBeatoken.Collection>,
		ownerVault: Capability<&FungibleBeatoken.Vault>
	): @SaleCollection{ 
		return <-create SaleCollection(collection: ownerCollection, vault: ownerVault)
	}
	
	init(){ 
		self.publicSale = /public/beatokenNFTSale
		self.storageSale = /storage/beatokenNFTSale
	}
}
