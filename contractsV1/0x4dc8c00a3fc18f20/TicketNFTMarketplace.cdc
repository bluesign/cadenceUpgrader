import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import TicketNFT from "./TicketNFT.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract TicketNFTMarketplace{ 
	access(all)
	struct SaleItem{ 
		access(all)
		let price: UFix64
		
		access(all)
		let nftRef: &TicketNFT.NFT
		
		init(_price: UFix64, _nftRef: &TicketNFT.NFT){ 
			self.price = _price
			self.nftRef = _nftRef
		}
	}
	
	access(all)
	resource interface SaleCollectionPublic{ 
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun getPrice(id: UInt64): UFix64
		
		access(all)
		fun purchase(
			id: UInt64,
			recipientCollection: &TicketNFT.Collection,
			payment: @FlowToken.Vault
		)
		
		access(all)
		fun claimTicketNFT(id: UInt64, recipientCollection: &TicketNFT.Collection)
	}
	
	access(all)
	resource SaleCollection: SaleCollectionPublic{ 
		access(all)
		var forSale:{ UInt64: UFix64}
		
		access(all)
		let TicketNFTCollection: Capability<&TicketNFT.Collection>
		
		access(all)
		let FlowTokenVault: Capability<&FlowToken.Vault>
		
		access(all)
		fun listForSale(id: UInt64, price: UFix64){ 
			pre{ 
				price >= 0.0:
					"It doesn't make sense to list a ticket for less than 0.0"
				(self.TicketNFTCollection.borrow()!).getIDs().contains(id):
					"This SaleCollection owner does not have this NFT"
			}
			self.forSale[id] = price
		}
		
		access(all)
		fun unlistFromSale(id: UInt64){ 
			self.forSale.remove(key: id)
		}
		
		access(all)
		fun purchase(id: UInt64, recipientCollection: &TicketNFT.Collection, payment: @FlowToken.Vault){ 
			pre{ 
				payment.balance == self.forSale[id]:
					"The payment is not equal to the price of the NFT"
			}
			recipientCollection.deposit(token: <-(self.TicketNFTCollection.borrow()!).withdraw(withdrawID: id))
			(self.FlowTokenVault.borrow()!).deposit(from: <-payment)
			self.unlistFromSale(id: id)
		}
		
		access(all)
		fun claimTicketNFT(id: UInt64, recipientCollection: &TicketNFT.Collection){ 
			recipientCollection.deposit(token: <-(self.TicketNFTCollection.borrow()!).withdraw(withdrawID: id))
			self.unlistFromSale(id: id)
		}
		
		access(all)
		fun getPrice(id: UInt64): UFix64{ 
			return self.forSale[id] ?? panic("Can't get the NFT price")
		}
		
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.forSale.keys
		}
		
		init(_TicketNFTCollection: Capability<&TicketNFT.Collection>, _FlowTokenVault: Capability<&FlowToken.Vault>){ 
			self.forSale ={} 
			self.TicketNFTCollection = _TicketNFTCollection
			self.FlowTokenVault = _FlowTokenVault
		}
	}
	
	access(all)
	fun createSaleCollection(
		TicketNFTCollection: Capability<&TicketNFT.Collection>,
		FlowTokenVault: Capability<&FlowToken.Vault>
	): @SaleCollection{ 
		return <-create SaleCollection(
			_TicketNFTCollection: TicketNFTCollection,
			_FlowTokenVault: FlowTokenVault
		)
	}
	
	init(){} 
}
