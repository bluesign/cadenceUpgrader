import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import Collectible from "./Collectible.cdc"

import Edition from "./Edition.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

access(all)
contract MarketPlace{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// Event that is emitted when a new NFT is put up for sale
	access(all)
	event ForSale(id: UInt64, owner: Address, price: UFix64)
	
	// Event that is emitted when the price of an NFT changes
	access(all)
	event PriceChanged(id: UInt64, owner: Address, newPrice: UFix64, oldPrice: UFix64)
	
	// Event that is emitted when a token is purchased
	access(all)
	event TokenPurchased(id: UInt64, price: UFix64, from: Address, to: Address)
	
	// Event that is emitted when a seller withdraws their NFT from the sale
	access(all)
	event SaleWithdrawn(id: UInt64, owner: Address)
	
	// Secondary commission events
	access(all)
	event Earned(nftID: UInt64, amount: UFix64, owner: Address, type: String)
	
	access(all)
	event FailEarned(nftID: UInt64, amount: UFix64, owner: Address, type: String)
	
	access(all)
	resource interface SaleCollectionPublic{ 
		access(all)
		fun purchase(
			tokenID: UInt64,
			recipientCap: Capability<&{Collectible.CollectionPublic}>,
			buyTokens: @FUSD.Vault
		)
		
		access(all)
		fun idPrice(tokenID: UInt64): UFix64?
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun borrowCollectible(id: UInt64): &Collectible.NFT?
	}
	
	// SaleCollection
	//
	// NFT Collection object that allows a user to put their NFT up for sale
	// where others can send fungible tokens to purchase it
	//
	access(all)
	resource SaleCollection: SaleCollectionPublic{ 
		
		// Dictionary of the NFTs that the user is putting up for sale
		access(self)
		var forSale: @{UInt64: Collectible.NFT}
		
		// Dictionary of the prices for each NFT by ID
		access(self)
		var prices:{ UInt64: UFix64}
		
		// The fungible token vault of the owner of this sale.
		// When someone buys a token, this resource can deposit
		// tokens into their account.
		access(account)
		let ownerVault: Capability<&FUSD.Vault>
		
		init(vault: Capability<&FUSD.Vault>){ 
			self.forSale <-{} 
			self.ownerVault = vault
			self.prices ={} 
		}
		
		access(self)
		fun getEditionNumber(id: UInt64): UInt64?{ 
			let ref = self.borrowCollectible(id: id)
			if ref == nil{ 
				return nil
			}
			return (ref!).editionNumber
		}
		
		// withdraw gives the owner the opportunity to remove a sale from the collection
		access(all)
		fun withdraw(tokenID: UInt64): @Collectible.NFT{ 
			// remove the price
			self.prices.remove(key: tokenID)
			
			// remove and return the token
			let token <- self.forSale.remove(key: tokenID) ?? panic("missing NFT")
			let vaultRef = self.ownerVault.borrow() ?? panic("Could not borrow reference to owner token vault")
			return <-token
		}
		
		// listForSale lists an NFT for sale in this collection
		access(all)
		fun listForSale(token: @Collectible.NFT, price: UFix64){ 
			pre{ 
				price > 0.00:
					"Price should be more than 0"
				price <= 999999.99:
					"Price should be less than 1 000 000.00"
			}
			let id = token.id
			
			// store the price in the price array
			self.prices[id] = price
			
			// put the NFT into the the forSale dictionary
			let oldToken <- self.forSale[id] <- token
			destroy oldToken
			let vaultRef = self.ownerVault.borrow() ?? panic("Could not borrow reference to owner token vault")
			emit ForSale(id: id, owner: (vaultRef.owner!).address, price: price)
		}
		
		// changePrice changes the price of a token that is currently for sale
		access(all)
		fun changePrice(tokenID: UInt64, newPrice: UFix64){ 
			pre{ 
				self.prices[tokenID] != nil:
					"NFT does not exist on sale"
				newPrice > 0.00:
					"Price should be more than 0"
				newPrice <= 999999.99:
					"Price should be less than 1 000 000.00"
			}
			let oldPrice = self.prices[tokenID]!
			self.prices[tokenID] = newPrice
			let vaultRef = self.ownerVault.borrow() ?? panic("Could not borrow reference to owner token vault")
			emit PriceChanged(id: tokenID, owner: (vaultRef.owner!).address, newPrice: newPrice, oldPrice: oldPrice)
		}
		
		// remove nft from sale. this uses is to differ between cancel sale and buy NFT
		access(all)
		fun withdrawFromSale(tokenID: UInt64): @Collectible.NFT{ 
			pre{ 
				self.prices[tokenID] != nil:
					"NFT does not exist on sale"
			}
			let vaultRef = self.ownerVault.borrow() ?? panic("Could not borrow reference to owner token vault")
			emit SaleWithdrawn(id: tokenID, owner: (vaultRef.owner!).address)
			return <-self.withdraw(tokenID: tokenID)
		}
		
		// idPrice returns the price of a specific token in the sale
		access(all)
		fun idPrice(tokenID: UInt64): UFix64?{ 
			return self.prices[tokenID]
		}
		
		// getIDs returns an array of token IDs that are for sale
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.forSale.keys
		}
		
		access(all)
		fun borrowCollectible(id: UInt64): &Collectible.NFT?{ 
			if self.forSale[id] != nil{ 
				let ref = &self.forSale[id] as &Collectible.NFT?
				return ref as! &Collectible.NFT?
			} else{ 
				return nil
			}
		}
		
		access(self)
		fun handlePayments(tokenID: UInt64, buyTokens: @FUSD.Vault, price: UFix64){ 
			let vaultRef = self.ownerVault.borrow() ?? panic("Could not borrow reference to owner token vault")
			
			// this is validated during process of the cration NFT
			let editionNumber = self.getEditionNumber(id: tokenID)!
			let royaltyRef = MarketPlace.account.capabilities.get<&{Edition.EditionCollectionPublic}>(Edition.CollectionPublicPath).borrow()!
			let royaltyStatus = royaltyRef.getEdition(editionNumber)!
			for key in royaltyStatus.royalty.keys{ 
				let commission = price * (royaltyStatus.royalty[key]!).secondSalePercent * 0.01
				let account = getAccount(key)
				let vaultCap = account.capabilities.get<&FUSD.Vault>(/public/fusdReceiver)
				if vaultCap.check(){ 
					let vaultCommissionRecepientRef = vaultCap.borrow()!
					vaultCommissionRecepientRef.deposit(from: <-buyTokens.withdraw(amount: commission))
					emit Earned(nftID: tokenID, amount: commission, owner: key, type: (royaltyStatus.royalty[key]!).description)
				} else{ 
					emit FailEarned(nftID: tokenID, amount: commission, owner: key, type: (royaltyStatus.royalty[key]!).description)
				}
			}
			let amount = buyTokens.balance
			
			// deposit the purchasing tokens into the owners vault
			vaultRef.deposit(from: <-(buyTokens as!{ FungibleToken.Vault}))
			emit Earned(nftID: tokenID, amount: amount, owner: (vaultRef.owner!).address, type: "SELLER")
		}
		
		// purchase lets a user send tokens to purchase an NFT that is for sale
		access(all)
		fun purchase(tokenID: UInt64, recipientCap: Capability<&{Collectible.CollectionPublic}>, buyTokens: @FUSD.Vault){ 
			pre{ 
				self.forSale[tokenID] != nil && self.prices[tokenID] != nil:
					"No token matching this ID for sale!"
				buyTokens.balance == self.prices[tokenID] ?? 0.0:
					"Not exact amount tokens to buy the NFT!"
			}
			let vaultRef = self.ownerVault.borrow() ?? panic("Could not borrow reference to owner token vault")
			
			// get the value out of the optional
			let price = self.prices[tokenID]!
			self.prices[tokenID] = nil
			let recipient = recipientCap.borrow() ?? panic("Could not borrow reference to buyer NFT storage")
			
			// Send money to seller and share the secondary commission
			self.handlePayments(tokenID: tokenID, buyTokens: <-buyTokens, price: price)
			let token <- self.withdraw(tokenID: tokenID)
			
			// deposit the NFT into the buyers collection
			recipient.deposit(token: <-token)
			emit TokenPurchased(id: tokenID, price: price, from: (vaultRef.owner!).address, to: (recipient.owner!).address)
		}
	}
	
	// structure for display NFTs data
	access(all)
	struct SaleData{ 
		access(all)
		let metadata: Collectible.Metadata
		
		access(all)
		let id: UInt64
		
		access(all)
		let price: UFix64?
		
		access(all)
		let editionNumber: UInt64
		
		init(metadata: Collectible.Metadata, id: UInt64, price: UFix64?, editionNumber: UInt64){ 
			self.metadata = metadata
			self.id = id
			self.price = price
			self.editionNumber = editionNumber
		}
	}
	
	// get info for NFT including metadata
	access(all)
	fun getSaleDatas(address: Address): [SaleData]{ 
		var saleData: [SaleData] = []
		let account = getAccount(address)
		let CollectibleCollection =
			account.capabilities.get<&{MarketPlace.SaleCollectionPublic}>(
				MarketPlace.CollectionPublicPath
			).borrow()
			?? panic("Could not borrow sale reference")
		for id in CollectibleCollection.getIDs(){ 
			var Collectible = CollectibleCollection.borrowCollectible(id: id)
			var price = CollectibleCollection.idPrice(tokenID: id)
			saleData.append(SaleData(metadata: (Collectible!).metadata, id: id, price: price, editionNumber: (Collectible!).editionNumber))
		}
		return saleData
	}
	
	// createCollection returns a new collection resource to the caller
	access(all)
	fun createSaleCollection(ownerVault: Capability<&FUSD.Vault>): @SaleCollection{ 
		return <-create SaleCollection(vault: ownerVault)
	}
	
	init(){ 
		self.CollectionPublicPath = /public/NFTbloctoXtinglesCollectibleSale
		self.CollectionStoragePath = /storage/NFTbloctoXtinglesCollectibleSale
	}
}
