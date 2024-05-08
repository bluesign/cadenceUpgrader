import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import LilaiQuest from "./LilaiQuest.cdc"

access(all)
contract LilaiMarket{ 
	access(all)
	event ItemListed(id: UInt64, price: UFix64, seller: Address?)
	
	access(all)
	event ItemPriceChanged(id: UInt64, newPrice: UFix64, seller: Address?)
	
	access(all)
	event ItemPurchased(id: UInt64, price: UFix64, seller: Address?)
	
	access(all)
	event ItemWithdrawn(id: UInt64, owner: Address?)
	
	access(all)
	event CutPercentageChanged(newPercent: UFix64, seller: Address?)
	
	access(all)
	resource interface SalePublic{ 
		access(all)
		var cutPercentage: UFix64
		
		access(all)
		fun purchase(itemId: UInt64, buyTokens: @{FungibleToken.Vault}): @LilaiQuest.NFT
		
		access(all)
		fun getPrice(itemId: UInt64): UFix64?
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun borrowItem(id: UInt64): &LilaiQuest.NFT?
	}
	
	access(all)
	resource SaleCollection: SalePublic{ 
		access(all)
		var forSale: @LilaiQuest.NFTCollection
		
		access(self)
		var prices:{ UInt64: UFix64}
		
		access(self)
		var ownerCapability: Capability
		
		access(self)
		var beneficiaryCapability: Capability
		
		access(all)
		var cutPercentage: UFix64
		
		init(ownerCapability: Capability, beneficiaryCapability: Capability, cutPercentage: UFix64){ 
			self.forSale <- LilaiQuest.createNFTCollection()
			self.ownerCapability = ownerCapability
			self.beneficiaryCapability = beneficiaryCapability
			self.prices ={} 
			self.cutPercentage = cutPercentage
		}
		
		access(all)
		fun listForSale(item: @LilaiQuest.NFT, price: UFix64, caller: Address){ 
			assert(caller == self.owner?.address, message: "Caller is not the owner of the item")
			let id = item.id
			self.prices[id] = price
			self.forSale.deposit(token: <-item)
			emit ItemListed(id: id, price: price, seller: self.owner?.address)
		}
		
		access(all)
		fun withdraw(itemId: UInt64): @LilaiQuest.NFT{ 
			let item <- self.forSale.withdraw(id: itemId)
			self.prices.remove(key: itemId)
			emit ItemWithdrawn(id: item.id, owner: self.owner?.address)
			return <-item
		}
		
		access(all)
		fun purchase(itemId: UInt64, buyTokens: @{FungibleToken.Vault}): @LilaiQuest.NFT{ 
			pre{ 
				self.forSale.borrowNFT(id: itemId) != nil && self.prices[itemId] != nil:
					"No item matching this ID for sale!"
				buyTokens.balance == self.prices[itemId] ?? UFix64(0):
					"Not enough tokens to buy the item!"
			}
			let price = self.prices[itemId]!
			self.prices.remove(key: itemId)
			let beneficiaryCut <- buyTokens.withdraw(amount: price * self.cutPercentage)
			(self.beneficiaryCapability.borrow<&{FungibleToken.Receiver}>()!).deposit(from: <-beneficiaryCut)
			(self.ownerCapability.borrow<&{FungibleToken.Receiver}>()!).deposit(from: <-buyTokens)
			emit ItemPurchased(id: itemId, price: price, seller: self.owner?.address)
			return <-self.withdraw(itemId: itemId)
		}
		
		access(all)
		fun changePrice(itemId: UInt64, newPrice: UFix64){ 
			pre{ 
				self.prices[itemId] != nil:
					"Cannot change the price for an item that is not for sale"
			}
			self.prices[itemId] = newPrice
			emit ItemPriceChanged(id: itemId, newPrice: newPrice, seller: self.owner?.address)
		}
		
		access(all)
		fun changePercentage(newPercent: UFix64){ 
			pre{ 
				newPercent <= 1.0:
					"Cannot set cut percentage to greater than 100%"
			}
			self.cutPercentage = newPercent
			emit CutPercentageChanged(newPercent: newPercent, seller: self.owner?.address)
		}
		
		access(all)
		fun changeOwnerReceiver(newOwnerCapability: Capability){ 
			pre{ 
				newOwnerCapability.borrow<&{FungibleToken.Receiver}>() != nil:
					"Owner's Receiver Capability is invalid!"
			}
			self.ownerCapability = newOwnerCapability
		}
		
		access(all)
		fun changeBeneficiaryReceiver(newBeneficiaryCapability: Capability){ 
			pre{ 
				newBeneficiaryCapability.borrow<&{FungibleToken.Receiver}>() != nil:
					"Beneficiary's Receiver Capability is invalid!"
			}
			self.beneficiaryCapability = newBeneficiaryCapability
		}
		
		access(all)
		fun getPrice(itemId: UInt64): UFix64?{ 
			return self.prices[itemId]
		}
		
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.forSale.getTokenIds()
		}
		
		access(all)
		fun borrowItem(id: UInt64): &LilaiQuest.NFT?{ 
			let ref = self.forSale.borrowNFT(id: id)
			return ref
		}
	}
	
	access(all)
	fun createSaleCollection(
		ownerCapability: Capability<&{FungibleToken.Receiver}>,
		beneficiaryCapability: Capability<&{FungibleToken.Receiver}>,
		cutPercentage: UFix64
	): @SaleCollection{ 
		return <-create SaleCollection(
			ownerCapability: ownerCapability,
			beneficiaryCapability: beneficiaryCapability,
			cutPercentage: cutPercentage
		)
	}
}
