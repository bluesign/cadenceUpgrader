import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import Collectible from "../0xf5b0eb433389ac3f/Collectible.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import Edition from "../0xf5b0eb433389ac3f/Edition.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

access(all)
contract OpenEditionV3{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	struct OpenEditionStatus{ 
		access(all)
		let id: UInt64
		
		access(all)
		let price: UFix64
		
		access(all)
		let active: Bool
		
		access(all)
		let timeRemaining: Fix64
		
		access(all)
		let endTime: Fix64
		
		access(all)
		let startTime: Fix64
		
		access(all)
		let metadata: Collectible.Metadata?
		
		access(all)
		let completed: Bool
		
		access(all)
		let expired: Bool
		
		access(all)
		let cancelled: Bool
		
		init(
			id: UInt64,
			price: UFix64,
			active: Bool,
			timeRemaining: Fix64,
			metadata: Collectible.Metadata?,
			startTime: Fix64,
			endTime: Fix64,
			completed: Bool,
			expired: Bool,
			cancelled: Bool
		){ 
			self.id = id
			self.price = price
			self.active = active
			self.timeRemaining = timeRemaining
			self.metadata = metadata
			self.startTime = startTime
			self.endTime = endTime
			self.completed = completed
			self.expired = expired
			self.cancelled = cancelled
		}
	}
	
	// The total amount of OpenEditions that have been created
	access(all)
	var totalOpenEditions: UInt64
	
	// Events
	access(all)
	event OpenEditionCollectionCreated()
	
	access(all)
	event Created(id: UInt64, price: UFix64, startTime: UFix64, numberOfMaxNFT: UInt64)
	
	access(all)
	event Purchase(
		openEditionId: UInt64,
		buyer: Address,
		price: UFix64,
		NFTid: UInt64,
		edition: UInt64,
		purchaseTime: UFix64
	)
	
	access(all)
	event Earned(nftID: UInt64, amount: UFix64, owner: Address, type: String)
	
	access(all)
	event FailEarned(nftID: UInt64, amount: UFix64, owner: Address, type: String)
	
	access(all)
	event Settled(id: UInt64, price: UFix64, amountMintedNFT: UInt64)
	
	access(all)
	event Canceled(id: UInt64)
	
	// OpenEditionItem contains the Resources and metadata for a single sale
	access(all)
	resource OpenEditionItem{ 
		
		// Number of purchased NFTs
		access(self)
		var numberOfMintedNFT: UInt64
		
		// The id of this individual open edition
		access(all)
		let openEditionID: UInt64
		
		// The current price
		access(all)
		let price: UFix64
		
		// The time the open edition should start at
		access(self)
		var startTime: UFix64
		
		// The length in seconds for this open edition
		access(self)
		var saleLength: UFix64
		
		// After settle open edition
		access(self)
		var completed: Bool
		
		// Set if an open edition will be cancelled
		access(self)
		var cancelled: Bool
		
		// Common number for all copies one item
		access(self)
		let editionNumber: UInt64
		
		// Metadata for minted NFT
		access(self)
		let metadata: Collectible.Metadata
		
		//The vault receive FUSD in case of the recipient of commissiona is unreachable 
		access(self)
		let platformVaultCap: Capability<&FUSD.Vault>
		
		// Number of max purchased NFTs
		access(self)
		var numberOfMaxNFT: UInt64
		
		init(
			price: UFix64,
			startTime: UFix64,
			saleLength: UFix64,
			editionNumber: UInt64,
			metadata: Collectible.Metadata,
			platformVaultCap: Capability<&FUSD.Vault>,
			numberOfMaxNFT: UInt64
		){ 
			OpenEditionV3.totalOpenEditions = OpenEditionV3.totalOpenEditions + 1 as UInt64
			self.price = price
			self.startTime = startTime
			self.saleLength = saleLength
			self.editionNumber = editionNumber
			self.numberOfMintedNFT = 0
			self.openEditionID = OpenEditionV3.totalOpenEditions
			self.completed = false
			self.cancelled = false
			self.metadata = metadata
			self.platformVaultCap = platformVaultCap
			self.numberOfMaxNFT = numberOfMaxNFT
		}
		
		access(all)
		fun settleOpenEdition(clientEdition: &Edition.EditionCollection){ 
			pre{ 
				!self.cancelled:
					"Open edition was cancelled"
				!self.completed:
					"The open edition has already settled"
				self.isExpired():
					"Open edition time has not expired yet"
			}
			self.completed = true
			
			// Write final amount of copies for this NFT
			clientEdition.changeMaxEdition(
				id: self.editionNumber,
				maxEdition: self.numberOfMintedNFT
			)
			emit Settled(
				id: self.openEditionID,
				price: self.price,
				amountMintedNFT: self.numberOfMintedNFT
			)
		}
		
		//this can be negative if is expired
		access(self)
		view fun timeRemaining(): Fix64{ 
			let length = self.saleLength
			let startTime = self.startTime
			let currentTime = getCurrentBlock().timestamp
			let remaining = Fix64(startTime + length) - Fix64(currentTime)
			return remaining
		}
		
		access(all)
		fun getPrice(): UFix64{ 
			return self.price
		}
		
		access(self)
		view fun isExpired(): Bool{ 
			let timeRemaining = self.timeRemaining()
			return timeRemaining < Fix64(0.0)
		}
		
		access(self)
		fun sendCommissionPayments(buyerTokens: @FUSD.Vault, tokenID: UInt64){ 
			// Capability to resource with commission information
			let editionRef =
				OpenEditionV3.account.capabilities.get<&{Edition.EditionCollectionPublic}>(
					Edition.CollectionPublicPath
				).borrow()!
			
			// Commission informaton for all copies of on item
			let editionStatus = editionRef.getEdition(self.editionNumber)!
			
			// Vault for platform account
			let platformVault = self.platformVaultCap.borrow()!
			for key in editionStatus.royalty.keys{ 
				// Commission is paid all recepient except platform
				if (editionStatus.royalty[key]!).firstSalePercent > 0.0 && key != (platformVault.owner!).address{ 
					let commission = self.price * (editionStatus.royalty[key]!).firstSalePercent * 0.01
					let account = getAccount(key)
					let vaultCap = account.capabilities.get<&FUSD.Vault>(/public/fusdReceiver)
					
					// vaultCap was checked during creation of commission info on Edition contract, therefore this is extra check
					// if vault capability is not avaliable, the rest tokens will sent to platform vault					 
					if vaultCap.check(){ 
						let vault = vaultCap.borrow()!
						vault.deposit(from: <-buyerTokens.withdraw(amount: commission))
						emit Earned(nftID: tokenID, amount: commission, owner: key, type: (editionStatus.royalty[key]!).description)
					} else{ 
						emit FailEarned(nftID: tokenID, amount: commission, owner: key, type: (editionStatus.royalty[key]!).description)
					}
				}
			}
			
			// Platform get the rest of Fungible tokens and tokens from failed transactions
			let amount = buyerTokens.balance
			platformVault.deposit(from: <-(buyerTokens as!{ FungibleToken.Vault}))
			emit Earned(
				nftID: tokenID,
				amount: amount,
				owner: (platformVault.owner!).address,
				type: "PLATFORM"
			)
		}
		
		access(all)
		fun purchase(
			buyerTokens: @FUSD.Vault,
			buyerCollectionCap: Capability<&{Collectible.CollectionPublic}>,
			minterCap: Capability<&Collectible.NFTMinter>
		){ 
			pre{ 
				self.startTime < getCurrentBlock().timestamp:
					"The open edition has not started yet"
				!self.isExpired():
					"The open edition time expired"
				!self.cancelled:
					"Open edition was cancelled"
				buyerTokens.balance == self.price:
					"Not exact amount tokens to buy the NFT"
				self.numberOfMintedNFT < self.numberOfMaxNFT || self.numberOfMaxNFT == 0:
					"Number of minted nfts have reached max value"
			}
			
			// Get minter reference to create NFT
			let minterRef = minterCap.borrow()!
			
			// Change amount of copies in this edition
			self.numberOfMintedNFT = self.numberOfMintedNFT + UInt64(1)
			
			// Change copy number in NFT
			let metadata =
				Collectible.Metadata(
					link: self.metadata.link,
					name: self.metadata.name,
					author: self.metadata.author,
					description: self.metadata.description,
					// Copy number for this NFT in metadata	 
					edition: self.numberOfMintedNFT,
					properties: self.metadata.properties
				)
			
			// Mint NFT
			let newNFT <- minterRef.mintNFT(metadata: metadata, editionNumber: self.editionNumber)
			
			// NFT number
			let NFTid = newNFT.id
			
			// Get buyer's NFT Collection reference
			let buyerNFTCollection = buyerCollectionCap.borrow()!
			
			// Sent NFT to buyer	
			buyerNFTCollection.deposit(token: <-newNFT)
			
			// Pay commission to recipients
			self.sendCommissionPayments(buyerTokens: <-buyerTokens, tokenID: NFTid)
			
			// Set end of purchases, when amount of purchased nfts attained max value
			if self.numberOfMaxNFT == self.numberOfMintedNFT && self.numberOfMintedNFT > 0{ 
				self.saleLength = getCurrentBlock().timestamp - self.startTime
			}
			
			// Purchase event
			emit Purchase(
				openEditionId: self.openEditionID,
				buyer: ((buyerCollectionCap.borrow()!).owner!).address,
				price: self.price,
				NFTid: NFTid,
				edition: self.numberOfMintedNFT,
				purchaseTime: getCurrentBlock().timestamp
			)
		}
		
		access(all)
		fun getOpenEditionStatus(): OpenEditionStatus{ 
			return OpenEditionStatus(
				id: self.openEditionID,
				price: self.price,
				active: !self.completed && !self.isExpired(),
				timeRemaining: self.timeRemaining(),
				metadata: self.metadata,
				startTime: Fix64(self.startTime),
				endTime: Fix64(self.startTime + self.saleLength),
				completed: self.completed,
				expired: self.isExpired(),
				cancelled: self.cancelled
			)
		}
		
		access(all)
		fun cancelOpenEdition(clientEdition: &Edition.EditionCollection){ 
			pre{ 
				!self.completed:
					"The open edition has already settled"
				!self.cancelled:
					"Open edition has been cancelled earlier"
			}
			// Write final amount of copies for this NFT
			clientEdition.changeMaxEdition(
				id: self.editionNumber,
				maxEdition: self.numberOfMintedNFT
			)
			self.cancelled = true
		}
	}
	
	// OpenEditionPublic is a resource interface that restricts users to
	// retreiving the auction price list and placing bids
	access(all)
	resource interface OpenEditionCollectionPublic{ 
		access(all)
		fun getOpenEditionStatuses():{ UInt64: OpenEditionStatus}?
		
		access(all)
		fun getOpenEditionStatus(_ id: UInt64): OpenEditionStatus?
		
		access(all)
		fun getPrice(_ id: UInt64): UFix64?
		
		access(all)
		fun purchase(
			id: UInt64,
			buyerTokens: @FUSD.Vault,
			collectionCap: Capability<&{Collectible.CollectionPublic}>
		)
	}
	
	// OpenEditionCollection contains a dictionary of OpenEditionItems and provides
	// methods for manipulating the OpenEditionItems
	access(all)
	resource OpenEditionCollection: OpenEditionCollectionPublic{ 
		// OpenEdition Items
		access(account)
		var openEditionsItems: @{UInt64: OpenEditionItem}
		
		access(contract)
		let minterCap: Capability<&Collectible.NFTMinter>
		
		init(minterCap: Capability<&Collectible.NFTMinter>){ 
			self.openEditionsItems <-{} 
			self.minterCap = minterCap
		}
		
		access(all)
		fun keys(): [UInt64]{ 
			return self.openEditionsItems.keys
		}
		
		// addTokenToauctionItems adds an NFT to the auction items and sets the meta data
		// for the auction item
		access(all)
		fun createOpenEdition(price: UFix64, startTime: UFix64, saleLength: UFix64, editionNumber: UInt64, metadata: Collectible.Metadata, platformVaultCap: Capability<&FUSD.Vault>, numberOfMaxNFT: UInt64){ 
			pre{ 
				saleLength > 0.00:
					"Sale lenght should be more than 0.00"
				startTime > getCurrentBlock().timestamp:
					"Start time can't be in the past"
				price > 0.00:
					"Price should be more than 0.00"
				price <= 999999.99:
					"Price should be less than 1 000 000.00"
				platformVaultCap.check():
					"Platform vault should be reachable"
			}
			let editionRef = OpenEditionV3.account.capabilities.get<&{Edition.EditionCollectionPublic}>(Edition.CollectionPublicPath).borrow()!
			
			// Check edition info in contract Edition in order to manage commission and all amount of copies of the same item
			// This error throws inside Edition contract. But I put this check for redundant
			if editionRef.getEdition(editionNumber) == nil{ 
				panic("Edition doesn't exist")
			}
			let item <- create OpenEditionItem(price: price, startTime: startTime, saleLength: saleLength, editionNumber: editionNumber, metadata: metadata, platformVaultCap: platformVaultCap, numberOfMaxNFT: numberOfMaxNFT)
			let id = item.openEditionID
			
			// update the auction items dictionary with the new resources
			let oldItem <- self.openEditionsItems[id] <- item
			destroy oldItem
			emit Created(id: id, price: price, startTime: startTime, numberOfMaxNFT: numberOfMaxNFT)
		}
		
		// getOpenEditionPrices returns a dictionary of available NFT IDs with their current price
		access(all)
		fun getOpenEditionStatuses():{ UInt64: OpenEditionStatus}?{ 
			if self.openEditionsItems.keys.length == 0{ 
				return nil
			}
			let priceList:{ UInt64: OpenEditionStatus} ={} 
			for id in self.openEditionsItems.keys{ 
				let itemRef = &self.openEditionsItems[id] as &OpenEditionV3.OpenEditionItem?
				priceList[id] = itemRef.getOpenEditionStatus()
			}
			return priceList
		}
		
		access(all)
		fun getOpenEditionStatus(_ id: UInt64): OpenEditionStatus?{ 
			if self.openEditionsItems[id] == nil{ 
				return nil
			}
			
			// Get the auction item resources
			let itemRef = &self.openEditionsItems[id] as &OpenEditionV3.OpenEditionItem?
			return itemRef.getOpenEditionStatus()
		}
		
		access(all)
		fun getPrice(_ id: UInt64): UFix64?{ 
			if self.openEditionsItems[id] == nil{ 
				return nil
			}
			
			// Get the open edition item resources
			let itemRef = &self.openEditionsItems[id] as &OpenEditionV3.OpenEditionItem?
			return itemRef.getPrice()
		}
		
		// settleOpenEdition sends the auction item to the highest bidder
		// and deposits the FungibleTokens into the auction owner's account
		access(all)
		fun settleOpenEdition(id: UInt64, clientEdition: &Edition.EditionCollection){ 
			pre{ 
				self.openEditionsItems[id] != nil:
					"Open Edition does not exist"
			}
			let itemRef = &self.openEditionsItems[id] as &OpenEditionV3.OpenEditionItem?
			itemRef.settleOpenEdition(clientEdition: clientEdition)
		}
		
		access(all)
		fun cancelOpenEdition(id: UInt64, clientEdition: &Edition.EditionCollection){ 
			pre{ 
				self.openEditionsItems[id] != nil:
					"Open Edition does not exist"
			}
			let itemRef = &self.openEditionsItems[id] as &OpenEditionV3.OpenEditionItem?
			itemRef.cancelOpenEdition(clientEdition: clientEdition)
			emit Canceled(id: id)
		}
		
		// purchase sends the buyer's tokens to the buyer's tokens vault	  
		access(all)
		fun purchase(id: UInt64, buyerTokens: @FUSD.Vault, collectionCap: Capability<&{Collectible.CollectionPublic}>){ 
			pre{ 
				self.openEditionsItems[id] != nil:
					"Open Edition does not exist"
				collectionCap.check():
					"NFT storage does not exist on the account"
			}
			
			// Get the auction item resources
			let itemRef = &self.openEditionsItems[id] as &OpenEditionV3.OpenEditionItem?
			itemRef.purchase(buyerTokens: <-buyerTokens, buyerCollectionCap: collectionCap, minterCap: self.minterCap)
		}
	}
	
	// createOpenEditionCollection returns a OpenEditionCollection resource
	access(self)
	fun createOpenEditionCollection(
		minterCap: Capability<&Collectible.NFTMinter>
	): @OpenEditionCollection{ 
		let openEditionCollection <- create OpenEditionCollection(minterCap: minterCap)
		emit OpenEditionCollectionCreated()
		return <-openEditionCollection
	}
	
	init(){ 
		self.totalOpenEditions = 10 as UInt64
		self.CollectionPublicPath = /public/NFTbloctoXtinglesOpenEditionV3
		self.CollectionStoragePath = /storage/NFTbloctoXtinglesOpenEditionV3
		let minterCap =
			self.account.capabilities.get<&Collectible.NFTMinter>(Collectible.MinterPrivatePath)!
		let openEdition <- OpenEditionV3.createOpenEditionCollection(minterCap: minterCap)
		self.account.storage.save(<-openEdition, to: OpenEditionV3.CollectionStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&{OpenEditionV3.OpenEditionCollectionPublic}>(
				OpenEditionV3.CollectionStoragePath
			)
		self.account.capabilities.publish(capability_1, at: OpenEditionV3.CollectionPublicPath)
	}
}
