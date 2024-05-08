import CheezeNFT from "./CheezeNFT.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

access(all)
contract CheezeMarket{ 
	access(self)
	var storedNFTs: @{UInt64: CheezeNFT.NFT}
	
	access(self)
	var listings:{ UInt64: ListingDetails}
	
	access(self)
	var cutReceiver: Capability<&FUSD.Vault>
	
	access(self)
	var firstSaleCutPercent: UFix64
	
	access(self)
	var royaltyCutPercent: UFix64
	
	access(self)
	var maxRoyaltyPercent: UFix64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event NFTPutOnSale(nft_id: UInt64, price: UFix64)
	
	access(all)
	event NFTSaleRevoked(nft_id: UInt64)
	
	access(all)
	event NFTSold(nft_id: UInt64)
	
	access(all)
	struct ListingDetails{ 
		access(all)
		var price: UFix64
		
		access(all)
		var sellerPaymentReceiver: Capability<&FUSD.Vault>
		
		access(all)
		var sellerNftReturnReceiver: Capability<&CheezeNFT.Collection>
		
		access(all)
		var royaltyReceiver: Capability<&FUSD.Vault>?
		
		access(all)
		var royaltyPercent: UFix64?
		
		init(
			price: UFix64,
			sellerPaymentReceiver: Capability<&FUSD.Vault>,
			sellerNftReturnReceiver: Capability<&CheezeNFT.Collection>,
			royaltyReceiver: Capability<&FUSD.Vault>?,
			royaltyPercent: UFix64?
		){ 
			pre{ 
				royaltyReceiver == nil == (royaltyPercent == nil)
			}
			self.price = price
			self.sellerPaymentReceiver = sellerPaymentReceiver
			self.sellerNftReturnReceiver = sellerNftReturnReceiver
			self.royaltyReceiver = royaltyReceiver
			self.royaltyPercent = royaltyPercent
		}
	}
	
	access(all)
	fun putOnSale(
		token: @CheezeNFT.NFT,
		price: UFix64,
		paymentReceiver: Capability<&FUSD.Vault>,
		nftReturnReceiver: Capability<&CheezeNFT.Collection>,
		royaltyReceiver: Capability<&FUSD.Vault>?,
		royaltyPercent: UFix64?
	){ 
		// Client sets royaltyPercent if and only if this is not a secondary sale
		pre{ 
			royaltyReceiver == nil == (royaltyPercent == nil)
			royaltyPercent == nil || royaltyPercent! <= self.maxRoyaltyPercent
		}
		
		// Check receiver works
		paymentReceiver.borrow() ?? panic("Cannot borrow payment receiver")
		nftReturnReceiver.borrow() ?? panic("Cannot borrow NFT return receiver")
		var tokenID = token.id
		var oldStoredNFTs <- self.storedNFTs[tokenID] <- token
		// XXX: only one NFT with given ID exists
		assert(oldStoredNFTs == nil)
		destroy oldStoredNFTs
		self.listings[tokenID] = ListingDetails(
				price: price,
				sellerPaymentReceiver: paymentReceiver,
				sellerNftReturnReceiver: nftReturnReceiver,
				royaltyReceiver: royaltyReceiver,
				royaltyPercent: royaltyPercent
			)
		emit NFTPutOnSale(nft_id: tokenID, price: price)
	}
	
	access(all)
	fun isOnSale(tokenID: UInt64): Bool{ 
		return self.isNFTStored(tokenID: tokenID)
	}
	
	access(all)
	view fun priceFor(tokenID: UInt64): UFix64{ 
		pre{ 
			self.isNFTStored(tokenID: tokenID)
		}
		return (self.listings[tokenID]!).price
	}
	
	access(all)
	fun buy(tokenID: UInt64, payment: @FUSD.Vault): @CheezeNFT.NFT{ 
		pre{ 
			payment.balance == self.priceFor(tokenID: tokenID)
			self.isNFTStored(tokenID: tokenID)
		}
		post{ 
			!self.isNFTStored(tokenID: tokenID)
		}
		let price = self.priceFor(tokenID: tokenID)
		let listing = self.listings[tokenID]!
		let receiver = listing.sellerPaymentReceiver.borrow()!
		if listing.royaltyPercent == nil{ 
			let beneficiaryCut <- payment.withdraw(amount: price * self.firstSaleCutPercent)
			(self.cutReceiver.borrow()!).deposit(from: <-beneficiaryCut)
			receiver.deposit(from: <-payment)
		} else{ 
			let royaltyTotal = price * listing.royaltyPercent!
			
			// Beneficiary Cut from royalty
			let beneficiaryCut <- payment.withdraw(amount: royaltyTotal * self.royaltyCutPercent)
			(self.cutReceiver.borrow()!).deposit(from: <-beneficiaryCut)
			
			// Royalty
			let royalty <- payment.withdraw(amount: royaltyTotal - royaltyTotal * self.royaltyCutPercent)
			((listing.royaltyReceiver!).borrow()!).deposit(from: <-royalty)
			// Payment
			receiver.deposit(from: <-payment)
		}
		self.listings[tokenID] = nil
		let token <- self.storedNFTs.remove(key: tokenID)!
		emit NFTSold(nft_id: tokenID)
		return <-token
	}
	
	access(contract)
	fun revokeSale(tokenID: UInt64){ 
		pre{ 
			self.isNFTStored(tokenID: tokenID)
		}
		post{ 
			!self.isNFTStored(tokenID: tokenID)
		}
		let token <- self.storedNFTs.remove(key: tokenID)!
		((self.listings[tokenID]!).sellerNftReturnReceiver.borrow()!).deposit(token: <-token)
		self.listings[tokenID] = nil
		emit NFTSaleRevoked(nft_id: tokenID)
	}
	
	access(contract)
	view fun isNFTStored(tokenID: UInt64): Bool{ 
		let nftStored = self.storedNFTs[tokenID] != nil
		let listingStored = self.storedNFTs[tokenID] != nil
		assert(nftStored == listingStored)
		return nftStored
	}
	
	access(all)
	resource Administrator{ 
		access(all)
		fun revokeSale(tokenID: UInt64){ 
			CheezeMarket.revokeSale(tokenID: tokenID)
		}
		
		access(all)
		fun setCutReceiver(receiver: Capability<&FUSD.Vault>){ 
			CheezeMarket.cutReceiver = receiver
		}
		
		access(all)
		fun setFirstSaleCutPercent(percent: UFix64){ 
			CheezeMarket.firstSaleCutPercent = percent
		}
		
		access(all)
		fun setRoyaltyCutPercent(percent: UFix64){ 
			CheezeMarket.firstSaleCutPercent = percent
		}
		
		access(all)
		fun setMaxRoyaltyPercent(percent: UFix64){ 
			CheezeMarket.maxRoyaltyPercent = percent
		}
	}
	
	init(){ 
		self.storedNFTs <-{} 
		self.listings ={} 
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: /storage/cheezeMarketAdmin)
		
		// XXX: cannot use Administrator.setX() cuz Cadence does not get
		//	  that we do initialization and will show errors
		self.cutReceiver = self.account.capabilities.get<&FUSD.Vault>(/public/fusdReceiver)!
		self.firstSaleCutPercent = 0.25
		self.royaltyCutPercent = 0.10
		self.maxRoyaltyPercent = 0.3
		emit ContractInitialized()
	}
}
