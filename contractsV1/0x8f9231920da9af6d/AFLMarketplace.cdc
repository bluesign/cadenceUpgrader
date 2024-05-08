import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import AFLNFT from "./AFLNFT.cdc"

import FiatToken from "./../../standardsV1/FiatToken.cdc"

import StorageHelper from "./StorageHelper.cdc"

access(all)
contract AFLMarketplace{ 
	// Capability to receive USDC marketplace fee from each sale
	access(contract)
	var marketplaceWallet: Capability<&FiatToken.Vault>
	
	// Market fee percentage
	access(contract)
	var cutPercentage: UFix64
	
	// commented out for testnet
	// Storage Path for Admin resource
	// pub let AdminStoragePath: StoragePath
	// Storage Path for SaleCollection resource
	// pub let SaleCollectionStoragePath: StoragePath
	// Storage Path for SalePublic resource
	// pub let SaleCollectionPublicPath: PublicPath
	// Emitted when a new AFLNFT is put up for sale
	access(all)
	event ForSale(id: UInt64, price: UFix64, owner: Address?)
	
	// Emitted when the price of an NFT is changed
	access(all)
	event PriceChanged(id: UInt64, newPrice: UFix64, owner: Address?)
	
	// Emitted when a token is purchased
	access(all)
	event TokenPurchased(id: UInt64, price: UFix64, owner: Address?, to: Address?)
	
	// Emitted when a seller withdraws their NFT from the sale
	access(all)
	event SaleCanceled(id: UInt64, owner: Address?)
	
	// Emitted when the cut percentage of the sale has been changed by the owner
	access(all)
	event CutPercentageChanged(newPercent: UFix64, owner: Address?)
	
	// Emitted when a new sale collection is created
	access(all)
	event SaleCollectionCreated(owner: Address?)
	
	// Emitted when marketplace wallet is changed
	access(all)
	event MarketplaceWalletChanged(address: Address)
	
	// SalePublic 
	//
	// The interface that a user can publish a capability to their sale
	// to allow others to access their sale
	access(all)
	resource interface SalePublic{ 
		access(all)
		fun purchase(
			tokenID: UInt64,
			recipientCap: Capability<&{AFLNFT.AFLNFTCollectionPublic}>,
			buyTokens: @{FungibleToken.Vault}
		)
		
		access(all)
		fun getPrice(tokenID: UInt64): UFix64?
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun getDetails():{ UInt64: UFix64}
		
		access(all)
		fun borrowMoment(id: UInt64): &AFLNFT.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Moment reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// SaleCollection
	//
	// NFT Collection object that allows a user to put their NFT up for sale
	// where others can send fungible tokens to purchase it
	//
	access(all)
	resource SaleCollection: SalePublic{ 
		
		// Dictionary of the NFTs that the user is putting up for sale
		access(all)
		var forSale: @{UInt64: AFLNFT.NFT}
		
		// Dictionary of the flow prices for each NFT by ID
		access(self)
		var prices:{ UInt64: UFix64}
		
		// The fungible token vault of the owner of this sale.
		// When someone buys a token, this resource can deposit
		// tokens into their account.
		access(account)
		let ownerVault: Capability<&FiatToken.Vault>
		
		init(vault: Capability<&FiatToken.Vault>){ 
			pre{ 
				// Check that both capabilities are for fungible token Vault receivers
				vault.check():
					"Owner's Receiver Capability is invalid!"
			}
			
			// create an empty collection to store the moments that are for sale
			self.forSale <-{} 
			self.ownerVault = vault
			// prices are initially empty because there are no moments for sale
			self.prices ={} 
		}
		
		// listForSale lists an NFT for sale in this sale collection
		// at the specified price
		//
		// Parameters: token: The NFT to be put up for sale
		//			 price: The price of the NFT
		access(all)
		fun listForSale(token: @AFLNFT.NFT, price: UFix64){ 
			
			// get the ID of the token
			let id = token.id
			
			// get the templateID
			let templateID = AFLNFT.getNFTData(nftId: id).templateId
			let teamBadgeIds: [UInt64] = [22436, 22437, 22438, 22439, 22440, 22441, 22442, 22443, 22444, 22445, 22446, 22447, 22448, 22449, 22450, 22451, 22452, 22453] // mainnet templateIds for team badges
			
			assert(!teamBadgeIds.contains(templateID), message: "Team Badges cannot be listed for sale.")
			
			// Set the token's price
			self.prices[token.id] = price
			let oldToken <- self.forSale[id] <- token
			destroy oldToken
			emit ForSale(id: id, price: price, owner: self.owner?.address)
		}
		
		// Withdraw removes a moment that was listed for sale
		// and clears its price
		//
		// Parameters: tokenID: the ID of the token to withdraw from the sale
		//
		// Returns: @AFLNFT.NFT: The nft that was withdrawn from the sale
		access(all)
		fun withdraw(tokenID: UInt64): @AFLNFT.NFT{ 
			// remove the price
			self.prices.remove(key: tokenID)
			// remove and return the token
			let token <- self.forSale.remove(key: tokenID) ?? panic("missing NFT")
			emit SaleCanceled(id: tokenID, owner: (self.owner!).address)
			return <-token
		}
		
		// purchase lets a user send tokens to purchase an NFT that is for sale
		// the purchased NFT is returned to the transaction context that called it
		//
		// Parameters: tokenID: the ID of the NFT to purchase
		//			 butTokens: the fungible tokens that are used to buy the NFT
		access(all)
		fun purchase(tokenID: UInt64, recipientCap: Capability<&{AFLNFT.AFLNFTCollectionPublic}>, buyTokens: @{FungibleToken.Vault}){ 
			pre{ 
				buyTokens.getType() == (self.ownerVault.borrow()!).getType():
					"The tokens being sent to purchase the NFT must be the same type as the listing"
				self.forSale[tokenID] != nil && self.prices[tokenID] != nil:
					"No token matching this ID for sale!"
				buyTokens.balance >= self.prices[tokenID] ?? UFix64(0):
					"Not enough tokens to buy the NFT!"
			}
			StorageHelper.topUpAccount(address: recipientCap.address)
			let recipient = recipientCap.borrow()!
			// Read the price for the token
			let salePrice = self.prices[tokenID]!
			
			// Set the price for the token to nil
			self.prices[tokenID] = nil
			let saleOwnerVaultRef = self.ownerVault.borrow() ?? panic("could not borrow reference to the owner vault")
			
			// remove price
			self.prices.remove(key: tokenID)
			// remove and return the token
			let token <- self.forSale.remove(key: tokenID) ?? panic("missing NFT")
			let marketplaceWallet = AFLMarketplace.marketplaceWallet.borrow() ?? panic("Couldn't borrow Vault reference")
			let marketplaceAmount = salePrice * AFLMarketplace.cutPercentage
			
			// withdraw and deposit marketplace fee
			let tempMarketplaceWallet <- buyTokens.withdraw(amount: marketplaceAmount)
			marketplaceWallet.deposit(from: <-tempMarketplaceWallet)
			
			// deposit remaining tokens to sale owner and transfer nft to recipient
			saleOwnerVaultRef.deposit(from: <-buyTokens)
			recipient.deposit(token: <-token)
			emit TokenPurchased(id: tokenID, price: salePrice, owner: self.owner?.address, to: (recipient.owner!).address)
		}
		
		// changePrice changes the price of a token that is currently for sale
		//
		// Parameters: tokenID: The ID of the NFT's price that is changing
		//			 newPrice: The new price for the NFT
		access(all)
		fun changePrice(tokenID: UInt64, newPrice: UFix64){ 
			pre{ 
				self.prices[tokenID] != nil:
					"Cannot change the price for a token that is not for sale"
			}
			// Set the new price
			self.prices[tokenID] = newPrice
			emit PriceChanged(id: tokenID, newPrice: newPrice, owner: self.owner?.address)
		}
		
		// getPrice returns the price of a specific token in the sale
		// 
		// Parameters: tokenID: The ID of the NFT whose price to get
		//
		// Returns: UFix64: The price of the token
		access(all)
		fun getPrice(tokenID: UInt64): UFix64?{ 
			return self.prices[tokenID]
		}
		
		/// getDetails returns the prices of all tokens listed for sale
		access(all)
		fun getDetails():{ UInt64: UFix64}{ 
			return self.prices
		}
		
		// getIDs returns an array of token IDs that are for sale
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.forSale.keys
		}
		
		// borrowMoment Returns a borrowed reference to a Moment in the collection
		// so that the caller can read data from it
		//
		// Parameters: id: The ID of the moment to borrow a reference to
		//
		// Returns: &AFL.NFT? Optional reference to a moment for sale 
		//						so that the caller can read its data
		//
		access(all)
		fun borrowMoment(id: UInt64): &AFLNFT.NFT?{ 
			if self.forSale[id] != nil{ 
				return (&self.forSale[id] as &AFLNFT.NFT?)!
			} else{ 
				return nil
			}
		}
	
	// If the sale collection is destroyed, 
	// destroy the tokens that are for sale inside of it
	}
	
	// createCollection returns a new collection resource to the caller
	access(all)
	fun createSaleCollection(ownerVault: Capability<&FiatToken.Vault>): @SaleCollection{ 
		emit SaleCollectionCreated(owner: ownerVault.address)
		return <-create SaleCollection(vault: ownerVault)
	}
	
	access(all)
	resource AFLMarketAdmin{ 
		// changePercentage changes the cut percentage of the tokens that are for sale
		//
		// Parameters: newPercent: The new cut percentage for the sale
		access(all)
		fun changePercentage(_ newPercent: UFix64){ 
			pre{ 
				newPercent <= 1.0:
					"Cannot set cut percentage to greater than 100%"
			}
			AFLMarketplace.cutPercentage = newPercent
			emit CutPercentageChanged(newPercent: newPercent, owner: (self.owner!).address)
		}
		
		access(all)
		fun changeMarketplaceWallet(_ newCap: Capability<&FiatToken.Vault>){ 
			AFLMarketplace.marketplaceWallet = newCap
			emit MarketplaceWalletChanged(address: newCap.address)
		}
	}
	
	access(all)
	fun getPercentage(): UFix64{ 
		return AFLMarketplace.cutPercentage
	}
	
	init(){ 
		self.cutPercentage = 0.10
		
		// commented out for testnet update 
		// self.AdminStoragePath = /storage/AFLMarketAdmin
		// self.SaleCollectionStoragePath = /storage/AFLMarketplaceSaleCollection
		// self.SaleCollectionPublicPath = /public/AFLMarketplaceSaleCollection
		self.marketplaceWallet = self.account.capabilities.get<&FiatToken.Vault>(
				/public/FiatTokenVaultReceiver
			)!
		// self.account.save(<- create AFLMarketAdmin(), to: AFLMarketplace.AdminStoragePath)
		self.account.storage.save(<-create AFLMarketAdmin(), to: /storage/AFLMarketAdmin)
	}
}
