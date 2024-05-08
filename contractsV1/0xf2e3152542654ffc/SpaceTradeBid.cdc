import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import SpaceTradeFeeManager from "./SpaceTradeFeeManager.cdc"

import SpaceTradeAssetCatalog from "./SpaceTradeAssetCatalog.cdc"

access(all)
contract SpaceTradeBid{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event BidCanceled(id: UInt64, owner: Address, recipient: Address)
	
	access(all)
	event BidAccepted(id: UInt64, owner: Address, recipient: Address)
	
	access(all)
	enum BidType: UInt8{ 
		// Standard trade that can contain requests and proposals
		access(all)
		case trade
		
		// Gifs cannot have any requested assets in it
		access(all)
		case gift
	}
	
	// Contain NFTs that we can withdraw when accepting the bid
	access(all)
	resource NFTBundle{ 
		access(all)
		let collectionName: String
		
		access(all)
		let nfts: @[{NonFungibleToken.NFT}]
		
		init(collectionName: String, nfts: @[{NonFungibleToken.NFT}]){ 
			self.collectionName = collectionName
			self.nfts <- nfts
		}
		
		access(all)
		fun transfer(receiver: Capability<&{NonFungibleToken.CollectionPublic}>){ 
			let collectionRef =
				receiver.borrow()
				?? panic(
					"Transfer to receiver from NFTBundle failed as we could not borrow the receiver capability for: "
						.concat(self.collectionName)
				)
			var index = 0
			while index < self.nfts.length{ 
				collectionRef.deposit(token: <-self.nfts.remove(at: index))
			}
		}
	}
	
	// A wrapper for token vault that we can withdraw from when accepting the bid
	access(all)
	resource FTBundle{ 
		access(all)
		let tokenName: String
		
		access(all)
		var vault: @{FungibleToken.Vault}?
		
		init(tokenName: String, vault: @{FungibleToken.Vault}){ 
			self.tokenName = tokenName
			self.vault <- vault
		}
		
		access(all)
		fun transfer(receiver: Capability<&{FungibleToken.Receiver}>){ 
			let receiverRef =
				receiver.borrow()
				?? panic(
					"Transfer to receiver failed as we could not borrow the receiver capability for fungible token: "
						.concat(self.tokenName)
				)
			let vault <- self.vault <- nil
			receiverRef.deposit(from: <-vault!)
		}
	}
	
	// Contains NFTs and FTs that we can withdraw from when accepting the bid
	access(all)
	resource BidFulfilledBundle{ 
		access(all)
		let nfts: @[NFTBundle?]
		
		access(all)
		let fts: @[FTBundle?]
		
		init(nfts: @[NFTBundle], fts: @[FTBundle]){ 
			self.nfts <- nfts
			self.fts <- fts
		}
		
		// Key in receivers is the collectionName as defined in SpaceTradeAssetCatalog
		access(all)
		fun transferNFTs(receivers:{ String: Capability<&{NonFungibleToken.CollectionPublic}>}){ 
			var index = 0
			while index < self.nfts.length{ 
				let vault = (&self.nfts[index] as &SpaceTradeBid.NFTBundle?)!
				let receiver = receivers[vault.collectionName] ?? panic("Unable to borrow collection public from capability in BidFulfilledBundle while transfering NFTs for: ".concat(vault.collectionName))
				vault.transfer(receiver: receiver)
				index = index + 1
			}
		}
		
		// Key in receivers is the tokenName as defined in SpaceTradeAssetCatalog
		access(all)
		fun transferFTs(receivers:{ String: Capability<&{FungibleToken.Receiver}>}){ 
			var index = 0
			while index < self.fts.length{ 
				let vault = (&self.fts[index] as &SpaceTradeBid.FTBundle?)!
				let receiver = receivers[vault.tokenName] ?? panic("Unable to borrow collection public from capability in BidFulfilledBundle while transfering NFTs for: ".concat(vault.tokenName))
				vault.transfer(receiver: receiver)
				index = index + 1
			}
		}
	}
	
	access(all)
	struct NFTProposals{ 
		access(all)
		let collectionName: String
		
		access(all)
		let nftType: Type
		
		access(all)
		let ids: [UInt64]
		
		//  Capability for withdrawing NFTs from the collection when this bid is accepted
		access(self)
		let providerCapability: Capability<&{NonFungibleToken.Provider}>
		
		init(
			collectionName: String,
			ids: [
				UInt64
			],
			providerCapability: Capability<
				&{NonFungibleToken.CollectionPublic, NonFungibleToken.Provider}
			>
		){ 
			pre{ 
				ids.length > 0:
					"ids field must contain at least one id for: ".concat(collectionName)
				SpaceTradeAssetCatalog.isSupportedNFT(collectionName):
					"Proposed collection is not currently supported: ".concat(collectionName)
			}
			self.nftType = (SpaceTradeAssetCatalog.getNFTCollectionMetadata(collectionName)!)
					.nftType
			
			// Make sure NFTs with given id exists and has correct type
			for id in ids{ 
				let collectionRef = providerCapability.borrow() ?? panic("Could not borrow collection public from proposed collection for: ".concat(collectionName))
				let nftRef = collectionRef.borrowNFT(id)
				assert(nftRef.id == id, message: "Proposed NFT has not correct ID in collection: ".concat(collectionName))
				assert(nftRef.isInstance(self.nftType), message: "Proposed NFT has not correct type in collection: ".concat(collectionName))
			}
			self.collectionName = collectionName
			self.ids = ids
			self.providerCapability = providerCapability
		}
		
		// Withdraw proposed NFTs, only accesible by this contract when a bid is accepted	 
		access(contract)
		fun withdraw(): @NFTBundle{ 
			let nfts: @[{NonFungibleToken.NFT}] <- []
			for id in self.ids{ 
				let providerCollectionRef = self.providerCapability.borrow() ?? panic("Could not borrow NFT provider collection from bidder")
				let nft <- providerCollectionRef.withdraw(withdrawID: id)
				
				// Make sure that the NFT which we are withdrawing is the type that we accept
				assert(nft.isInstance(self.nftType), message: "Withdrawed NFT from proposed collection is not required type in collection: ".concat(self.collectionName))
				assert(nft.id == id, message: "Withdrawed NFT from proposed collection does not have specified ID in collection: ".concat(self.collectionName))
				nfts.append(<-nft)
			}
			return <-create NFTBundle(collectionName: self.collectionName, nfts: <-nfts)
		}
	}
	
	access(all)
	struct NFTRequests{ 
		access(all)
		let collectionName: String
		
		access(all)
		let nftType: Type
		
		access(all)
		let ids: [UInt64]
		
		// Where we will deposit NFTs here once the recipient accepts the bid
		access(self)
		let bidderCollectionPublicCapability: Capability<&{NonFungibleToken.CollectionPublic}>
		
		init(
			collectionName: String,
			ids: [
				UInt64
			],
			bidderCollectionPublicCapability: Capability<&{NonFungibleToken.CollectionPublic}>
		){ 
			pre{ 
				ids.length > 0:
					"ids field must contain at least one id for requested collection: ".concat(collectionName)
				SpaceTradeAssetCatalog.isSupportedNFT(collectionName):
					"Requested collection is not currently supported: ".concat(collectionName)
			}
			self.ids = ids
			self.collectionName = collectionName
			self.nftType = (SpaceTradeAssetCatalog.getNFTCollectionMetadata(collectionName)!)
					.nftType
			self.bidderCollectionPublicCapability = bidderCollectionPublicCapability
		}
		
		access(contract)
		fun transfer(providerCapability: Capability<&{NonFungibleToken.Provider}>){ 
			let providerCollectionRef =
				providerCapability.borrow()
				?? panic(
					"Could not borrow NFT provider capability from recipient for collection: "
						.concat(self.collectionName)
				)
			let receiverCollectionPublicRef =
				self.bidderCollectionPublicCapability.borrow()
				?? panic(
					"Could not borrow NFT collection public capability from bidder for collection: "
						.concat(self.collectionName)
				)
			for id in self.ids{ 
				let nft <- providerCollectionRef.withdraw(withdrawID: id)
				
				// Make sure that the NFT which we are withdrawing is the type that we accept
				assert(nft.isInstance(self.nftType), message: "Withdrawn NFT from requested collection is not of specified type in collection: ".concat(self.collectionName))
				assert(nft.id == id, message: "Withdrawn NFT from requested collection does not have specified ID in collection: ".concat(self.collectionName))
				receiverCollectionPublicRef.deposit(token: <-nft)
			}
		}
	}
	
	access(all)
	struct FTProposals{ 
		access(all)
		let tokenName: String
		
		access(all)
		let vaultType: Type
		
		access(all)
		let amount: UFix64
		
		// Where the contract can withdraw the tokens from
		access(all)
		let providerCapability: Capability<&{FungibleToken.Provider}>
		
		init(
			tokenName: String,
			amount: UFix64,
			providerCapability: Capability<&{FungibleToken.Balance, FungibleToken.Provider}>
		){ 
			pre{ 
				amount > 0.0:
					"Proposed amount must be greater than 0"
				SpaceTradeAssetCatalog.isSupportedFT(tokenName):
					"Proposed fungible token is not currently supported: ".concat(tokenName)
				(providerCapability.borrow() ?? panic("Unable to borrow provider for proposed fungible token for: ".concat(tokenName))).balance >= amount:
					"Proposed fungible token balance is less than the specified amount for: ".concat(tokenName)
			}
			self.amount = amount
			self.tokenName = tokenName
			self.vaultType = (SpaceTradeAssetCatalog.getFTMetadata(tokenName)!).vaultType
			self.providerCapability = providerCapability
		}
		
		access(contract)
		fun withdraw(): @FTBundle{ 
			let providerTokenRef =
				self.providerCapability.borrow()
				?? panic("Could not borrow token provider from bidder for: ".concat(self.tokenName))
			let tokenVault <- providerTokenRef.withdraw(amount: self.amount)
			
			// Make sure that the fungible token vault is the type that we accept
			assert(
				tokenVault.isInstance(self.vaultType),
				message: "Withdraw fungible tokens from bidder is not expected type for: ".concat(
					self.tokenName
				)
			)
			assert(
				tokenVault.balance == self.amount,
				message: "Withdraw fungible token balance from bidder is not equal to expected amount for: "
					.concat(self.tokenName)
			)
			return <-create FTBundle(tokenName: self.tokenName, vault: <-tokenVault)
		}
	}
	
	access(all)
	struct FTRequests{ 
		access(all)
		let tokenName: String
		
		access(all)
		let vaultType: Type
		
		access(all)
		let amount: UFix64
		
		// Where we desire the requested tokens to be deposited to
		access(all)
		let requesterTokenReceiver: Capability<&{FungibleToken.Receiver}>
		
		init(
			tokenName: String,
			amount: UFix64,
			requesterTokenReceiver: Capability<&{FungibleToken.Receiver}>
		){ 
			pre{ 
				amount > 0.0:
					"Amount must be more than 0 for: ".concat(tokenName)
				SpaceTradeAssetCatalog.isSupportedFT(tokenName):
					"Requested fungible token is not currently supported: ".concat(tokenName)
			}
			self.vaultType = (SpaceTradeAssetCatalog.getFTMetadata(tokenName)!).vaultType
			self.tokenName = tokenName
			self.amount = amount
			self.requesterTokenReceiver = requesterTokenReceiver
		}
		
		// Transfer to requester
		access(contract)
		fun transfer(providerCapability: Capability<&{FungibleToken.Provider}>){ 
			let providerRef =
				providerCapability.borrow()
				?? panic(
					"Could not borrow token provider capability from bidder for: ".concat(
						self.tokenName
					)
				)
			let tokenVault <- providerRef.withdraw(amount: self.amount)
			assert(
				tokenVault.isInstance(self.vaultType),
				message: "Withdrawed fungible tokens from recipient is not expected type for: "
					.concat(self.tokenName)
			)
			assert(
				tokenVault.balance == self.amount,
				message: "Withdrawed fungible token balance from recipient is not equal to requested amount for: "
					.concat(self.tokenName)
			)
			let requesterCollectionRef =
				self.requesterTokenReceiver.borrow()
				?? panic(
					"Could not borrow fungible token receiver capability from bidder for: ".concat(
						self.tokenName
					)
				)
			requesterCollectionRef.deposit(from: <-tokenVault)
		}
	}
	
	// Restrict read-only, enable public access
	access(all)
	resource interface BidDetails{ 
		access(all)
		let id: UInt64
		
		access(all)
		let type: BidType
		
		access(all)
		let recipient: Address
		
		access(all)
		let nftProposals: [NFTProposals]
		
		access(all)
		let ftProposals: [FTProposals]
		
		access(all)
		let nftRequests: [NFTRequests]
		
		access(all)
		let ftRequests: [FTRequests]
		
		access(all)
		var open: Bool
		
		access(all)
		var accepted: Bool
		
		access(all)
		let expiration: UFix64
		
		access(all)
		let lockedUntil: UFix64
	}
	
	access(all)
	resource interface BidAccept{ 
		access(all)
		fun accept(
			nftProviderCapabilities:{ 
				String: Capability<&{NonFungibleToken.Provider}>
			},
			ftProviderCapabilities:{ 
				String: Capability<&{FungibleToken.Provider}>
			},
			feeProviderCapability: Capability<&{FungibleToken.Balance, FungibleToken.Provider}>?
		): @BidFulfilledBundle
	}
	
	access(all)
	resource Bid: BidDetails, BidAccept{ 
		// Unique ID for this bid
		access(all)
		let id: UInt64
		
		// Type of this bid
		access(all)
		let type: BidType
		
		// A public bid can be accepted by anyone, this will be defined if it is a private bid
		access(all)
		let recipient: Address
		
		// Proposed NFTs
		access(all)
		let nftProposals: [NFTProposals]
		
		// Proposed tokens
		access(all)
		let ftProposals: [FTProposals]
		
		// Requested NFTs
		access(all)
		let nftRequests: [NFTRequests]
		
		// Requested tokens
		access(all)
		let ftRequests: [FTRequests]
		
		// Where fees will be withdrawn from once bid is accepted
		access(all)
		let bidderFeeProviderCapability: Capability<&{FungibleToken.Balance, FungibleToken.Provider}>?
		
		// The owner can close this bid 
		access(all)
		var open: Bool
		
		// Indicates that recipient accepted this bid
		access(all)
		var accepted: Bool
		
		// Uniq timestamp for when this bid expires
		access(all)
		let expiration: UFix64
		
		// This bid is locked until given date
		access(all)
		let lockedUntil: UFix64
		
		init(id: UInt64, type: BidType, recipient: Address, nftProposals: [NFTProposals], ftProposals: [FTProposals], nftRequests: [NFTRequests], ftRequests: [FTRequests], bidderFeeProviderCapability: Capability<&{FungibleToken.Balance, FungibleToken.Provider}>?, expiration: UFix64, lockedUntil: UFix64){ 
			pre{ 
				expiration >= lockedUntil:
					"Bid should not expire before lock timestamp"
				// Empty bid does not make sense
				nftProposals.length > 0 || ftProposals.length > 0 || nftRequests.length > 0 || ftRequests.length > 0:
					"This bid does not contain any proposal or request"
				type == BidType.gift ? nftRequests.length == 0 && ftRequests.length == 0 : true:
					"A gift should not contain asset request"
			}
			self.id = id
			self.type = type
			self.recipient = recipient
			self.nftProposals = nftProposals
			self.ftProposals = ftProposals
			self.nftRequests = nftRequests
			self.ftRequests = ftRequests
			self.open = true
			self.accepted = false
			self.expiration = expiration
			self.lockedUntil = lockedUntil
			self.bidderFeeProviderCapability = bidderFeeProviderCapability
			self.verifyFee(bidderFeeProviderCapability)
		}
		
		access(self)
		fun verifyFee(_ bidderFeeProviderCapability: Capability<&{FungibleToken.Balance, FungibleToken.Provider}>?){ 
			if SpaceTradeFeeManager.fee == nil || self.type == SpaceTradeBid.BidType.gift{ 
				// All good - no fees or recipient who accepts this is the supplier
				return
			}
			assert(bidderFeeProviderCapability != nil, message: "Bidder must provide fee provider as bidder is the fee supplier")
			let bidderFeeProvider = (bidderFeeProviderCapability!).borrow() ?? panic("Could not borrow bidder's fee provider from capability")
			assert(bidderFeeProvider.balance >= (SpaceTradeFeeManager.fee!).tokenAmount, message: "Bidder has not enough to cover fees for this bid")
		}
		
		access(all)
		fun cancel(){ 
			self.open = false
			emit BidCanceled(id: self.id, owner: (self.owner!).address, recipient: self.recipient)
		}
		
		access(all)
		fun accept(nftProviderCapabilities:{ String: Capability<&{NonFungibleToken.Provider}>}, ftProviderCapabilities:{ String: Capability<&{FungibleToken.Provider}>}, feeProviderCapability: Capability<&{FungibleToken.Balance, FungibleToken.Provider}>?): @BidFulfilledBundle{ 
			pre{ 
				self.open == true:
					"Bid is closed"
				getCurrentBlock().timestamp < self.expiration:
					"Bid has expired"
				getCurrentBlock().timestamp >= self.lockedUntil:
					"Bid is locked"
			}
			self.open = false
			self.accepted = true
			
			// Collect fees
			self.handleFees(acceptorFeeProviderCapability: feeProviderCapability)
			
			// Satisfy bidder
			self.satisfyBidder(nftProviderCapabilities: nftProviderCapabilities, ftProviderCapabilities: ftProviderCapabilities)
			
			// Satisfy acceptor
			let BidFulfilledBundle <- self.satisfyFulfiller()
			emit BidAccepted(id: self.id, owner: (self.owner!).address, recipient: self.recipient)
			return <-BidFulfilledBundle
		}
		
		access(self)
		fun satisfyFulfiller(): @BidFulfilledBundle{ 
			let nftBundles: @[NFTBundle] <- []
			let ftBundles: @[FTBundle] <- []
			
			// Withdraw NFTs
			for proposedNFT in self.nftProposals{ 
				nftBundles.append(<-proposedNFT.withdraw())
			}
			
			// Withdraw tokens
			for proposedToken in self.ftProposals{ 
				ftBundles.append(<-proposedToken.withdraw())
			}
			return <-create BidFulfilledBundle(nfts: <-nftBundles, fts: <-ftBundles)
		}
		
		access(self)
		fun satisfyBidder(nftProviderCapabilities:{ String: Capability<&{NonFungibleToken.Provider}>}, ftProviderCapabilities:{ String: Capability<&{FungibleToken.Provider}>}){ 
			for nftRequests in self.nftRequests{ 
				let providerCapability = nftProviderCapabilities[nftRequests.collectionName] ?? panic("Unable to transfer NFTs to bidder as provider capability for collection is not provided for: ".concat(nftRequests.collectionName))
				nftRequests.transfer(providerCapability: providerCapability)
			}
			for ftRequests in self.ftRequests{ 
				let providerCapability = ftProviderCapabilities[ftRequests.tokenName] ?? panic("Unable to transfer FTs to bidder as provider capability for fungible token is not provided for: ".concat(ftRequests.tokenName))
				ftRequests.transfer(providerCapability: providerCapability)
			}
		}
		
		access(self)
		fun handleFees(acceptorFeeProviderCapability: Capability<&{FungibleToken.Provider}>?){ 
			if self.type == SpaceTradeBid.BidType.gift{ 
				return
			}
			if let fee = SpaceTradeFeeManager.fee{ 
				let providerCapability = self.bidderFeeProviderCapability ?? panic("Fee is required, but provider capability is not provided")
				let providerRef = providerCapability.borrow() ?? panic("Could not borrow fungible token provider for fees")
				let vault <- providerRef.withdraw(amount: fee.tokenAmount)
				assert(vault.isInstance(fee.vaultType), message: "Provided fungible token for fee is not of correct type for: ".concat(fee.tokenName))
				assert(vault.balance == fee.tokenAmount, message: "Withdraw amount for fee is not enough to cover fees for this trade")
				fee.deposit(payment: <-vault)
			}
		}
	}
	
	access(all)
	fun createBid(
		id: UInt64,
		type: BidType,
		recipient: Address,
		nftProposals: [
			NFTProposals
		],
		ftProposals: [
			FTProposals
		],
		nftRequests: [
			NFTRequests
		],
		ftRequests: [
			FTRequests
		],
		bidderFeeProviderCapability: Capability<&{FungibleToken.Balance, FungibleToken.Provider}>?,
		expiration: UFix64,
		lockedUntil: UFix64
	): @Bid{ 
		return <-create Bid(
			id: id,
			type: type,
			recipient: recipient,
			nftProposals: nftProposals,
			ftProposals: ftProposals,
			nftRequests: nftRequests,
			ftRequests: ftRequests,
			bidderFeeProviderCapability: bidderFeeProviderCapability,
			expiration: expiration,
			lockedUntil: lockedUntil
		)
	}
	
	init(){ 
		emit ContractInitialized()
	}
}
