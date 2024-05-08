// SPDX-License-Identifier: Unlicense
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract StoreFrontAuction{ 
	// The total amount of AuctionItems that have been created
	access(all)
	var totalAuctions: UInt64
	
	/// Path where the public capability for the `Collection` is available
	access(all)
	let collectionPublicPath: PublicPath
	
	/// Path where the `Collection` is stored
	access(all)
	let collectionStoragePath: StoragePath
	
	// Events
	access(all)
	event AuctionItemsCreated(
		auctionId: UInt64,
		nftID: UInt64,
		startPrice: UFix64,
		seller: Address?
	)
	
	access(all)
	event AuctionBidCreated(auctionId: UInt64, bidPrice: UFix64, buyer: Address?)
	
	access(all)
	event AuctionSettled(auctionId: UInt64, price: UFix64)
	
	access(all)
	event AuctionCanceled(auctionId: UInt64)
	
	// AuctionItem contains the Resources and metadata for a single auction
	access(all)
	resource AuctionItem{ 
		access(all)
		var NFT: @{NonFungibleToken.NFT}?
		
		access(all)
		let bidVault: @{FungibleToken.Vault}
		
		access(all)
		var meta: ItemMeta
		
		init(NFT: @{NonFungibleToken.NFT}, bidVault: @{FungibleToken.Vault}, meta: ItemMeta){ 
			self.NFT <- NFT
			self.bidVault <- bidVault
			self.meta = meta
			StoreFrontAuction.totalAuctions = StoreFrontAuction.totalAuctions + UInt64(1)
		}
		
		// depositBidTokens deposits the bidder's tokens into the AuctionItem's Vault
		access(all)
		fun depositBidTokens(vault: @{FungibleToken.Vault}){ 
			self.bidVault.deposit(from: <-vault)
		}
		
		// withdrawNFT removes the NFT from the AuctionItem and returns it to the caller
		access(all)
		fun withdrawNFT(): @{NonFungibleToken.NFT}{ 
			let NFT <- self.NFT <- nil
			return <-NFT!
		}
		
		// updateRecipientVaultCap updates the bidder's Vault capability, providing the
		// us with a way to return their FungibleTokens
		access(contract)
		fun updateRecipientVaultCap(cap: Capability<&{FungibleToken.Receiver}>){ 
			let meta = self.meta
			meta.recipientVaultCap = cap
			self.meta = meta
		}
		
		// sendNFT sends the NFT to the Collection belonging to the provided Capability
		access(contract)
		fun sendNFT(_ capability: Capability<&{NonFungibleToken.CollectionPublic}>){ 
			// borrow a reference to the owner's NFT receiver
			if let collectionRef = capability.borrow(){ 
				let NFT <- self.withdrawNFT()
				// deposit the token into the owner's collection
				collectionRef.deposit(token: <-NFT)
			} else{ 
				panic("Unable to borrow collection reference")
			}
		}
		
		// sendBidTokens sends the bid tokens to the Vault Receiver belonging to the provided Capability
		access(contract)
		fun sendBidTokens(_ capability: Capability<&{FungibleToken.Receiver}>){ 
			// borrow a reference to the owner's NFT receiver
			if let vaultRef = capability.borrow(){ 
				let bidVaultRef = &self.bidVault as &{FungibleToken.Vault}
				vaultRef.deposit(from: <-bidVaultRef.withdraw(amount: bidVaultRef.balance))
			} else{ 
				panic("Couldn't get vault reference")
			}
		}
	}
	
	// ItemMeta contains the metadata for an AuctionItem
	access(all)
	struct ItemMeta{ 
		// Auction Settings
		access(all)
		let auctionID: UInt64
		
		access(all)
		let minimumBidIncrement: UFix64
		
		// Auction State
		access(all)
		var startPrice: UFix64
		
		access(all)
		var currentPrice: UFix64
		
		access(all)
		var auctionCompleted: Bool
		
		access(all)
		let finishAtTimestamp: UFix64
		
		// Recipient's Receiver Capabilities
		access(all)
		var recipientCollectionCap: Capability<&{NonFungibleToken.CollectionPublic}>
		
		access(all)
		var recipientVaultCap: Capability<&{FungibleToken.Receiver}>?
		
		// Owner's Receiver Capabilities
		access(all)
		let ownerCollectionCap: Capability<&{NonFungibleToken.CollectionPublic}>
		
		access(all)
		let ownerVaultCap: Capability<&{FungibleToken.Receiver}>
		
		init(
			minimumBidIncrement: UFix64,
			startPrice: UFix64,
			ownerCollectionCap: Capability<&{NonFungibleToken.CollectionPublic}>,
			ownerVaultCap: Capability<&{FungibleToken.Receiver}>,
			finishAtTimestamp: UFix64
		){ 
			self.auctionID = StoreFrontAuction.totalAuctions + UInt64(1)
			self.minimumBidIncrement = minimumBidIncrement
			self.startPrice = startPrice
			self.currentPrice = startPrice
			self.auctionCompleted = false
			self.recipientCollectionCap = ownerCollectionCap
			self.recipientVaultCap = ownerVaultCap
			self.ownerCollectionCap = ownerCollectionCap
			self.ownerVaultCap = ownerVaultCap
			self.finishAtTimestamp = finishAtTimestamp
		}
	}
	
	// AuctionPublic is a resource interface that restricts users to
	// retreiving the auction price list and placing bids
	access(all)
	resource interface AuctionPublic{ 
		access(all)
		fun getAuctionPrices():{ UInt64: UFix64}
		
		access(all)
		fun placeBid(
			id: UInt64,
			bidTokens: @{FungibleToken.Vault},
			vaultCap: Capability<&{FungibleToken.Receiver}>,
			collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>
		)
	}
	
	// AuctionCollection contains a dictionary of AuctionItems and provides
	// methods for manipulating the AuctionItems
	access(all)
	resource AuctionCollection: AuctionPublic{ 
		// Auction Items
		access(all)
		var auctionItems: @{UInt64: AuctionItem}
		
		init(){ 
			self.auctionItems <-{} 
		}
		
		// addTokenToauctionItems adds an NFT to the auction items and sets the meta data
		// for the auction item
		access(all)
		fun addTokenToAuctionItems(token: @{NonFungibleToken.NFT}, minimumBidIncrement: UFix64, startPrice: UFix64, bidVault: @{FungibleToken.Vault}, collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>, vaultCap: Capability<&{FungibleToken.Receiver}>, finishAtTimestamp: UFix64){ 
			// create a new auction meta resource
			let meta = ItemMeta(minimumBidIncrement: minimumBidIncrement, startPrice: startPrice, ownerCollectionCap: collectionCap, ownerVaultCap: vaultCap, finishAtTimestamp: finishAtTimestamp)
			let nftID = token.id
			// create a new auction items resource container
			let item <- create AuctionItem(NFT: <-token, bidVault: <-bidVault, meta: meta)
			let id = item.meta.auctionID
			// update the auction items dictionary with the new resources
			let oldItem <- self.auctionItems[id] <- item
			destroy oldItem
			emit AuctionItemsCreated(auctionId: id, nftID: nftID, startPrice: startPrice, seller: (collectionCap.borrow()!).owner?.address)
		}
		
		// getAuctionPrices returns a dictionary of available NFT IDs with their current price
		access(all)
		fun getAuctionPrices():{ UInt64: UFix64}{ 
			pre{ 
				self.auctionItems.keys.length > 0:
					"There are no auction items"
			}
			let priceList:{ UInt64: UFix64} ={} 
			for id in self.auctionItems.keys{ 
				let itemRef = (&self.auctionItems[id] as &AuctionItem?)!
				if itemRef.meta.auctionCompleted == false{ 
					priceList[id] = itemRef.meta.currentPrice
				}
			}
			return priceList
		}
		
		// settleAuction sends the auction item to the highest bidder
		// and deposits the FungibleTokens into the auction owner's account
		access(all)
		fun settleAuction(_ id: UInt64){ 
			let itemRef = (&self.auctionItems[id] as &AuctionItem?)!
			let itemMeta = itemRef.meta
			if itemMeta.auctionCompleted{ 
				panic("This auction is already settled")
			}
			if itemRef.NFT == nil{ 
				panic("Auction doesn't exist")
			}
			// return if there are no bids to settle
			if itemMeta.currentPrice == itemMeta.startPrice{ 
				self.returnAuctionItemToOwner(id)
				log("No bids. Nothing to settle")
				return
			}
			self.exchangeTokens(id)
			itemMeta.auctionCompleted = true
			emit AuctionSettled(auctionId: id, price: itemMeta.currentPrice)
			if let item <- self.auctionItems.remove(key: id){ 
				item.meta = *itemMeta
				self.auctionItems[id] <-! item
			}
		}
		
		// exchangeTokens sends the purchased NFT to the buyer and the bidTokens to the seller
		access(all)
		fun exchangeTokens(_ id: UInt64){ 
			let itemRef = (&self.auctionItems[id] as &AuctionItem?)!
			if itemRef.NFT == nil{ 
				panic("Auction doesn't exist")
			}
			let itemMeta = itemRef.meta
			itemRef.sendNFT(itemMeta.recipientCollectionCap)
			itemRef.sendBidTokens(itemMeta.ownerVaultCap)
		}
		
		// placeBid sends the bidder's tokens to the bid vault and updates the
		// currentPrice of the current auction item
		access(all)
		fun placeBid(id: UInt64, bidTokens: @{FungibleToken.Vault}, vaultCap: Capability<&{FungibleToken.Receiver}>, collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>){ 
			pre{ 
				self.auctionItems[id] != nil:
					"NFT doesn't exist"
			}
			// Get the auction item resources
			let itemRef = (&self.auctionItems[id] as &AuctionItem?)!
			let itemMeta = itemRef.meta
			if itemMeta.auctionCompleted{ 
				panic("auction has already completed")
			}
			if bidTokens.balance - itemMeta.currentPrice < itemMeta.minimumBidIncrement{ 
				panic("bid amount be larger than minimum bid increment")
			}
			if itemMeta.finishAtTimestamp < getCurrentBlock().timestamp{ 
				panic("auction is not available")
			}
			if itemRef.bidVault.balance != UFix64(0){ 
				if let vaultCap = itemMeta.recipientVaultCap{ 
					itemRef.sendBidTokens(itemMeta.recipientVaultCap!)
				} else{ 
					panic("unable to get recipient Vault capability")
				}
			}
			// Update the auction item
			itemRef.depositBidTokens(vault: <-bidTokens)
			itemRef.updateRecipientVaultCap(cap: vaultCap)
			// Update the current price of the token
			itemMeta.currentPrice = itemRef.bidVault.balance
			// Add the bidder's Vault and NFT receiver references
			itemMeta.recipientCollectionCap = collectionCap
			itemRef.meta = *itemMeta
			emit AuctionBidCreated(auctionId: id, bidPrice: itemMeta.currentPrice, buyer: (collectionCap.borrow()!).owner?.address)
		}
		
		// releasePreviousBid returns the outbid user's tokens to
		// their vault receiver
		access(all)
		fun releasePreviousBid(_ id: UInt64){ 
			// get a reference to the auction items resources
			let itemRef = (&self.auctionItems[id] as &AuctionItem?)!
			let itemMeta = itemRef.meta
			// release the bidTokens from the vault back to the bidder
			if let vaultCap = itemMeta.recipientVaultCap{ 
				itemRef.sendBidTokens(itemMeta.recipientVaultCap!)
			} else{ 
				log("unable to get vault capability")
			}
		}
		
		// returnAuctionItemToOwner releases any bids and returns the NFT
		// to the owner's Collection
		access(all)
		fun returnAuctionItemToOwner(_ id: UInt64){ 
			let itemRef = (&self.auctionItems[id] as &AuctionItem?)!
			let itemMeta = itemRef.meta
			// release the bidder's tokens
			self.releasePreviousBid(id)
			// clear the NFT's meta data
			let oldItem <- self.auctionItems[id] <- nil
			destroy oldItem
		}
		
		// cancel auction and returns the NFT to the owner's Collection
		access(all)
		fun cancelAndReturnAuctionItemToOwner(_ id: UInt64){ 
			self.returnAuctionItemToOwner(id)
			emit AuctionCanceled(auctionId: id)
		}
	}
	
	// createAuctionCollection returns a new AuctionCollection resource to the caller
	access(all)
	fun createAuctionCollection(): @AuctionCollection{ 
		let auctionCollection <- create AuctionCollection()
		return <-auctionCollection
	}
	
	init(){ 
		self.totalAuctions = UInt64(0)
		self.collectionPublicPath = /public/StoreFrontAuctionCollection0x21a1619c469b1b4b
		self.collectionStoragePath = /storage/StoreFrontAuctionCollection0x21a1619c469b1b4b
	}
}
