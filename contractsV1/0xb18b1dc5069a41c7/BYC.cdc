/*

	BYC - Barter Yard Club

 */

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract BYC{ 
	
	// nfts that allow no fee barters
	access(all)
	var noFeeBarterNFTs:{ String: PublicPath}
	
	// fees payable by token
	access(contract)
	var feeByTokenIdentifier:{ String: UFix64}
	
	access(contract)
	var feeReceiverCapByIdentifier:{ String: Capability<&{FungibleToken.Receiver}>}
	
	// fees levied from barters are stored here
	access(contract)
	var feeVaultsByIdentifier: @{String:{ FungibleToken.Vault}}
	
	access(contract)
	var FT_TOKEN_FEE_PERCENTAGE: UFix64
	
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	// PATHS
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	access(all)
	let BarterCollectionStoragePath: StoragePath
	
	access(all)
	let BarterCollectionPublicPath: PublicPath
	
	access(all)
	let BarterCollectionPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	// EVENTS
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	access(all)
	event BarterCreated(
		offerID: UInt64,
		offeringAddress: Address,
		counterpartyID: UInt64?,
		counterpartyAddress: Address?
	)
	
	access(all)
	event BarterExecuted(id: UInt64)
	
	access(all)
	event BarterDestroyed(id: UInt64)
	
	access(all)
	event FeePaid(amount: UFix64, type: String, payer: Address)
	
	access(all)
	event FeesAcceptedUpdated(identifier: String, fee: UFix64?)
	
	access(all)
	event NoFeeBarterNFTsUpdated(identifier: String)
	
	access(all)
	event NoFeeBarterNFTsRemoved(identifier: String)
	
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	// STRUCTURES
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	access(all)
	struct FTMeta{ 
		access(all)
		let amount: UFix64?
		
		access(all)
		let providerType: String?
		
		access(all)
		let receiverType: String?
		
		access(all)
		let publicReceiverPath: String?
		
		init(_ asset: &FTAsset){ 
			self.amount = asset.amount
			self.publicReceiverPath = asset.publicReceiverPath?.toString()
			if asset.providerCap != nil{ 
				self.providerType = (asset.providerCap?.borrow()!!).getType().identifier
			} else{ 
				self.providerType = nil
			}
			if asset.receiverCap != nil{ 
				self.receiverType = (asset.receiverCap?.borrow()!!).getType().identifier
			} else{ 
				self.receiverType = nil
			}
		}
	}
	
	access(all)
	struct NFTMeta{ 
		access(all)
		let id: UInt64?
		
		access(all)
		let providerType: String?
		
		access(all)
		let receiverType: String?
		
		access(all)
		let collectionPublicPath: String?
		
		init(_ asset: &NFTAsset){ 
			self.id = asset.id
			self.collectionPublicPath = asset.collectionPublicPath?.toString()
			if asset.providerCap != nil{ 
				self.providerType = (asset.providerCap?.borrow()!!).getType().identifier
			} else{ 
				self.providerType = nil
			}
			if asset.receiverCap != nil{ 
				self.receiverType = (asset.receiverCap?.borrow()!!).getType().identifier
			} else{ 
				self.receiverType = nil
			}
		}
	}
	
	// FTAsset
	//
	// Everything required to send a fixed amount of FT from a provider to a receiver
	// if used as a requestedAssets it will have a receiver and amount and the provider will be passed in the transaction that settles the Barter
	// to check if the requested assets are owned by the specified account we also need to supply the path for the capability
	// the provider side is checked using providerIsValid()
	//
	access(all)
	struct FTAsset{ 
		access(all)
		var providerCap: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>?
		
		access(all)
		var receiverCap: Capability<&{FungibleToken.Receiver, FungibleToken.Balance}>?
		
		access(all)
		var publicReceiverPath: PublicPath?
		
		access(all)
		let amount: UFix64?
		
		init(
			providerCap: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>?,
			receiverCap: Capability<&{FungibleToken.Receiver, FungibleToken.Balance}>?,
			amount: UFix64?,
			publicReceiverPath: PublicPath?
		){ 
			if providerCap != nil{ 
				assert((providerCap!).borrow() != nil, message: "Invalid FT provider Capability")
			}
			if receiverCap != nil{ 
				assert((receiverCap!).borrow() != nil, message: "Invaoid FT receiver Capability")
			}
			self.providerCap = providerCap
			self.receiverCap = receiverCap
			self.amount = amount
			self.publicReceiverPath = publicReceiverPath
		}
		
		access(all)
		fun providerIsValid(): Bool{ 
			assert(
				(self.providerCap!).borrow() != nil,
				message: "invalid FT provider capability:".concat(
					(self.providerCap!).getType().identifier
				)
			)
			assert(
				((self.providerCap!).borrow()!).balance >= self.amount!,
				message: "Provider has insufficient tokens! Requested:".concat(
					(self.amount!).toString()
				).concat("/").concat(
					(self.providerCap?.borrow()!!).balance.toString().concat(" available!")
				)
			)
			return true
		}
		
		access(all)
		fun receiverIsValid(): Bool{ 
			assert(self.receiverCap?.borrow() != nil, message: "invalid receiver capability")
			return true
		}
		
		access(all)
		fun isValid(): Bool{ 
			self.providerIsValid()
			self.receiverIsValid()
			return true
		}
		
		access(all)
		fun getMeta(): FTMeta{ 
			return FTMeta(&self as &FTAsset)
		}
		
		access(contract)
		fun transfer(_ waiveFee: Bool){ 
			// levy fee
			var percentage = 1.0
			if !waiveFee{ 
				BYC.depositFees(<-((self.providerCap!).borrow()!).withdraw(amount: self.amount! * BYC.FT_TOKEN_FEE_PERCENTAGE))
				percentage = 1.0 - BYC.FT_TOKEN_FEE_PERCENTAGE
			}
			((			  // transfer amount minus fee
			  self.receiverCap!).borrow()!).deposit(
				from: <-((self.providerCap!).borrow()!).withdraw(amount: self.amount! * percentage)
			)
		}
	}
	
	// NFT Asset Resource
	//
	// Contains everything required to send a NFT from a provider to a receiver.
	//
	access(all)
	struct NFTAsset{ 
		access(all)
		var providerCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>?
		
		access(all)
		var receiverCap: Capability<&{NonFungibleToken.CollectionPublic}>?
		
		access(all)
		let collectionPublicPath: PublicPath?
		
		access(all)
		let id: UInt64?
		
		init(
			providerCap: Capability<
				&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}
			>?,
			receiverCap: Capability<&{NonFungibleToken.CollectionPublic}>?,
			id: UInt64?,
			collectionPublicPath: PublicPath?
		){ 
			if providerCap != nil{ 
				assert((providerCap!).borrow() != nil, message: "Invalid NFT Provider Capability")
			}
			if receiverCap != nil{ 
				assert((receiverCap!).borrow() != nil, message: "Invalid NFT Receiver Capability")
			}
			self.providerCap = providerCap
			self.receiverCap = receiverCap
			self.id = id
			self.collectionPublicPath = collectionPublicPath
		}
		
		access(all)
		fun providerIsValid(): Bool{ 
			assert(self.providerCap?.borrow() != nil, message: "invalid provider capability")
			assert(
				((self.providerCap!).borrow()!).getIDs().contains(self.id!),
				message: "Provider does not have the requested NFT! Requested:".concat(
					(self.id!).toString()
				)
			)
			return true
		}
		
		// maybe change name to signify program stops running if invalid
		access(all)
		fun isValid(): Bool{ 
			assert(self.providerIsValid(), message: "invalid provider")
			assert(
				((self.providerCap!).borrow()!).getType()
				== ((self.receiverCap!).borrow()!).getType(),
				message: "Provider and Receiver NFT capability types do not match"
			)
			assert(self.receiverCap?.borrow() != nil, message: "invalid receiver capability")
			return true
		}
		
		access(all)
		fun doesAddressOwnNFT(_ address: Address): Bool{ 
			let account = getAccount(address)
			let collectionRef =
				account.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
					self.collectionPublicPath!
				).borrow<&{NonFungibleToken.CollectionPublic}>()
			// return collectionRef!.getIDs().contains(self.id!)
			return (collectionRef!).borrowNFT(id: self.id!) != nil
		}
		
		access(all)
		fun getMeta(): NFTMeta{ 
			return NFTMeta(&self as &NFTAsset)
		}
		
		access(contract)
		fun transfer(){ 
			(self.receiverCap?.borrow()!!).deposit(
				token: <-(self.providerCap?.borrow()!!).withdraw(withdrawID: self.id!)
			)
		}
	}
	
	// Metadata details of a Barter
	//
	access(all)
	struct BarterMeta{ 
		access(all)
		let barterID: UInt64
		
		access(all)
		var counterpartyID: UInt64?
		
		access(all)
		let previousID: UInt64?
		
		access(all)
		let nftAssetsOffered: [NFTMeta]
		
		access(all)
		let ftAssetsOffered: [FTMeta]
		
		access(all)
		let nftAssetsRequested: [NFTMeta]
		
		access(all)
		let ftAssetsRequested: [FTMeta]
		
		access(all)
		let proposerFeeType: String
		
		access(all)
		let proposerFeeAmount: UFix64
		
		access(all)
		let offerAddress: Address
		
		access(all)
		let counterpartyAddress: Address?
		
		access(all)
		let expiresAt: UFix64
		
		init(_ barterRef: &Barter){ 
			self.barterID = barterRef.uuid
			self.previousID = barterRef.previousID
			self.counterpartyID = barterRef.linkedID
			self.nftAssetsOffered = barterRef.getNFTAssetsOffered()
			self.ftAssetsOffered = barterRef.getFTAssetsOffered()
			self.nftAssetsRequested = barterRef.getNFTAssetsRequested()
			self.ftAssetsRequested = barterRef.getFTAssetsRequested()
			self.proposerFeeType = barterRef.getProposerFeeType().identifier
			self.proposerFeeAmount = barterRef.getProposerFeeAmount()
			self.offerAddress = barterRef.getOfferAddress()
			self.counterpartyAddress = barterRef.counterpartyAddress
			self.expiresAt = barterRef.expiresAt
		}
	}
	
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	// RESOURCES
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	// Barter Resource Interfaces
	//
	access(all)
	resource interface BarterPublic{ 
		access(all)
		let counterpartyAddress: Address?
		
		access(all)
		let previousID: UInt64?
		
		access(all)
		var linkedID: UInt64?
		
		access(all)
		let expiresAt: UFix64
		
		access(all)
		fun getMetadata(): BarterMeta
		
		access(all)
		fun getNFTAssetsOffered(): [NFTMeta]
		
		access(all)
		fun getFTAssetsOffered(): [FTMeta]
		
		access(all)
		fun getNFTAssetsRequested(): [NFTMeta]
		
		access(all)
		fun getFTAssetsRequested(): [FTMeta]
		
		access(all)
		fun getProposerFeeType(): Type
		
		access(all)
		fun getProposerFeeAmount(): UFix64
		
		access(all)
		fun getOfferAddress(): Address
	}
	
	// Barter Resource
	//
	// Held in the account of the creator = 'Proposer'
	//
	access(all)
	resource Barter: BarterPublic, IRestricted, ViewResolver.Resolver{ 
		access(all)
		let previousID: UInt64? // nil for new Barters, ID if barter is a response to a previous Barter
		
		
		access(all)
		var linkedID: UInt64? // two identical barters are stored, one in the offering users account and one in the accepting users account..
		
		
		access(all)
		let counterpartyAddress: Address?
		
		access(all)
		let expiresAt: UFix64
		
		// Assets involved in this Barter
		access(contract)
		let nftAssetsOffered: [NFTAsset]
		
		access(contract)
		let ftAssetsOffered: [FTAsset]
		
		access(contract)
		let nftAssetsRequested: [NFTAsset]
		
		access(contract)
		let ftAssetsRequested: [FTAsset]
		
		access(contract)
		let proposerFeeCapability: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>
		
		// Resource initalization
		//
		init(ftAssetsOffered: [FTAsset], nftAssetsOffered: [NFTAsset], ftAssetsRequested: [FTAsset], nftAssetsRequested: [NFTAsset], counterpartyAddress: Address?, expiresAt: UFix64, previousBarterID: UInt64?, proposerFeeCapability: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>){ 
			pre{ 
				expiresAt > getCurrentBlock().timestamp:
					"Expiry time must be in the future!"
				nftAssetsOffered.length > 0 || ftAssetsOffered.length > 0:
					"Must offer at least 1 asset!"
			}
			let feeProviderRef = proposerFeeCapability.borrow() ?? panic("cannot borrow fee capability")
			assert(BYC.feeByTokenIdentifier[feeProviderRef.getType().identifier] != nil, message: "Fee capability provided is not of a supported type.")
			assert(feeProviderRef.balance > BYC.feeByTokenIdentifier[(proposerFeeCapability.borrow()!).getType().identifier]!, message: "Account has insufficient funds to cover fees.")
			for asset in ftAssetsOffered{ 
				assert(asset.providerIsValid(), message: "Invalid FT Provider details detected ")
			}
			for asset in nftAssetsOffered{ 
				assert(asset.providerIsValid(), message: "Invalid NFT Provider details detected ")
			}
			for asset in ftAssetsRequested{ 
				// we only assert the receiver is of correct type not the balance of the account is sufficient as the offering party may wish to request more funds than the requesting party currently has in that particular account
				assert(asset.receiverIsValid(), message: "Invalid Requested FT details detected. ")
			}
			for asset in nftAssetsRequested{ 
				assert(asset.doesAddressOwnNFT(counterpartyAddress!), message: "Invalid Requested NFT details detected")
			}
			self.counterpartyAddress = counterpartyAddress
			self.previousID = previousBarterID
			self.linkedID = nil
			self.ftAssetsOffered = ftAssetsOffered
			self.nftAssetsOffered = nftAssetsOffered
			self.ftAssetsRequested = ftAssetsRequested
			self.nftAssetsRequested = nftAssetsRequested
			self.expiresAt = expiresAt
			self.proposerFeeCapability = proposerFeeCapability
		}
		
		// Accept Barter Function
		//
		// Caller must provide all necessary Caps (their Providers and counterpartyies CollectionPublic Receivers)
		// Once populated the barter is executed
		//
		access(contract)
		fun acceptBarter(offeredNFTReceiverCaps: [Capability<&{NonFungibleToken.CollectionPublic}>], requestedNFTProviderCaps: [Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>], offeredFTReceiverCaps: [Capability<&{FungibleToken.Receiver, FungibleToken.Balance}>], requestedFTProviderCaps: [Capability<&{FungibleToken.Provider, FungibleToken.Balance}>], feeCapability: Capability<&{FungibleToken.Provider}>){ 
			pre{ 
				getCurrentBlock().timestamp <= self.expiresAt:
					"Barter has expired."
				offeredFTReceiverCaps.length == self.ftAssetsOffered.length
				offeredNFTReceiverCaps.length == self.nftAssetsOffered.length:
					offeredNFTReceiverCaps.length.toString().concat(" ").concat(self.nftAssetsOffered.length.toString())
				requestedFTProviderCaps.length == self.ftAssetsRequested.length
				requestedNFTProviderCaps.length == self.nftAssetsRequested.length:
					requestedNFTProviderCaps.length.toString().concat(" ").concat(self.nftAssetsRequested.length.toString())
			}
			
			// add offer nft receiver caps
			for i, asset in self.nftAssetsOffered{ 
				self.nftAssetsOffered[i].receiverCap = offeredNFTReceiverCaps[i]
			}
			// add requested NFT Provider Caps
			for i, asset in self.nftAssetsRequested{ 
				self.nftAssetsRequested[i].providerCap = requestedNFTProviderCaps[i]
			}
			// add offered ft receiver caps
			for i, asset in self.ftAssetsOffered{ 
				self.ftAssetsOffered[i].receiverCap = offeredFTReceiverCaps[i]
			}
			// add requested ft provider caps
			for i, asset in self.ftAssetsRequested{ 
				self.ftAssetsRequested[i].providerCap = requestedFTProviderCaps[i]
			}
			
			// check both parties accounts for NFTs that allow free barters
			let acceptorAddress = feeCapability.address
			let proposerAddress = self.proposerFeeCapability.address
			var waiveProposerFee = false
			var waiveAcceptorFee = false
			
			// loop through all accepted nft identifiers and check if each party has any of those nfts
			for nftIdentifier in BYC.noFeeBarterNFTs.keys{ 
				let collectionPath = BYC.noFeeBarterNFTs[nftIdentifier]!
				waiveProposerFee = BYC.checkAddressOwnsNFT(address: proposerAddress, collectionPath: collectionPath, nftIdentifier: nftIdentifier) || waiveProposerFee // || to preserve previous loop checks
				
				waiveAcceptorFee = BYC.checkAddressOwnsNFT(address: acceptorAddress, collectionPath: collectionPath, nftIdentifier: nftIdentifier) || waiveAcceptorFee
				if waiveProposerFee && waiveAcceptorFee{ 
					break
				} // no need to check further
			
			}
			let acceptorFee = BYC.feeByTokenIdentifier[(feeCapability.borrow()!).getType().identifier]!
			let proposerFee = BYC.feeByTokenIdentifier[(self.proposerFeeCapability.borrow()!).getType().identifier]!
			
			// if for any reason these capabilities are unlinked or broken then the trade will fail!
			// perhaps better pattern to store fees in contract level dictionary and admin can withdraw at later date
			let proposerFeeReceiver = (BYC.feeReceiverCapByIdentifier[(self.proposerFeeCapability.borrow()!).getType().identifier]!).borrow()!
			let acceptorFeeReceiver = (BYC.feeReceiverCapByIdentifier[(feeCapability.borrow()!).getType().identifier]!).borrow()!
			
			// Each user pays a fee unless they have a BYC approved NFT
			if !waiveProposerFee{ 
				proposerFeeReceiver.deposit(from: <-(feeCapability.borrow()!).withdraw(amount: proposerFee))
				emit FeePaid(amount: proposerFee, type: proposerFeeReceiver.getType().identifier, payer: feeCapability.address)
			}
			if !waiveAcceptorFee{ 
				acceptorFeeReceiver.deposit(from: <-(self.proposerFeeCapability.borrow()!).withdraw(amount: acceptorFee))
				emit FeePaid(amount: acceptorFee, type: proposerFeeReceiver.getType().identifier, payer: self.proposerFeeCapability.address)
			}
			self.executeBarter(waiveProposerFee, waiveAcceptorFee)
		}
		
		// Execute Barter Function
		//
		// This function iterates through the assets sending them from provider to receiver
		// We can assert as we go through as the whole state reverts if any asset is not validated
		//
		access(contract)
		fun executeBarter(_ waiveProposerFee: Bool, _ waiveAcceptorFee: Bool){ 
			for nft in self.nftAssetsOffered{ 
				assert(nft.isValid())
				nft.transfer()
			}
			for ft in self.ftAssetsOffered{ 
				assert(ft.isValid())
				ft.transfer(waiveProposerFee)
			}
			for nft in self.nftAssetsRequested{ 
				assert(nft.isValid())
				nft.transfer()
			}
			for ft in self.ftAssetsRequested{ 
				assert(ft.isValid())
				ft.transfer(waiveAcceptorFee)
			}
		}
		
		access(contract)
		fun setLinkedID(_ id: UInt64){ 
			self.linkedID = id
		}
		
		access(all)
		fun getOfferAddress(): Address{ 
			return self.nftAssetsOffered.length > 0 ? (self.nftAssetsOffered[0].providerCap!).address : (self.ftAssetsOffered[0].providerCap!).address
		}
		
		access(all)
		fun getMetadata(): BarterMeta{ 
			return BarterMeta(&self as &Barter)
		}
		
		access(all)
		fun getNFTAssetsOffered(): [NFTMeta]{ 
			let assetsMeta: [NFTMeta] = []
			for asset in self.nftAssetsOffered{ 
				assetsMeta.append(asset.getMeta())
			}
			return assetsMeta
		}
		
		access(all)
		fun getFTAssetsOffered(): [FTMeta]{ 
			let assetsMeta: [FTMeta] = []
			for asset in self.ftAssetsOffered{ 
				assetsMeta.append(asset.getMeta())
			}
			return assetsMeta
		}
		
		access(all)
		fun getNFTAssetsRequested(): [NFTMeta]{ 
			let assetsMeta: [NFTMeta] = []
			for asset in self.nftAssetsRequested{ 
				assetsMeta.append(asset.getMeta())
			}
			return assetsMeta
		}
		
		access(all)
		fun getFTAssetsRequested(): [FTMeta]{ 
			let assetsMeta: [FTMeta] = []
			for asset in self.ftAssetsRequested{ 
				assetsMeta.append(asset.getMeta())
			}
			return assetsMeta
		}
		
		access(all)
		fun getProposerFeeType(): Type{ 
			return (self.proposerFeeCapability.borrow()!).getType()
		}
		
		access(all)
		fun getProposerFeeAmount(): UFix64{ 
			pre{ 
				self.proposerFeeCapability != nil
			}
			return BYC.feeByTokenIdentifier[(self.proposerFeeCapability.borrow()!).getType().identifier]!
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<BarterMeta>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "Barter Yard Club - ID#".concat(self.uuid.toString()), description: "A Barter Yard Club - Barter resource, representing a Barter of NFTs and FTs between two parties.", thumbnail: MetadataViews.HTTPFile(url: "http://barteryard.club/images/BarterThumbnail.png"))
				case Type<BarterMeta>():
					return self.getMetadata()
			}
			return nil
		}
	}
	
	// Barter Collection Interfaces
	//
	// two identical barters are stored, one in the offering users account and one in the accepting users account..
	// this id links them and the restricted interface is used internally to clean up the counterparty users barter
	// this allows the user to see all barters without relying on a backend
	access(all)
	resource interface IRestricted{ 
		access(all)
		var linkedID: UInt64?
	}
	
	access(all)
	resource interface BarterCollectionPublic{ 
		access(all)
		fun deposit(barter: @Barter)
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
		
		access(all)
		fun borrowBarter(id: UInt64): &Barter?
		
		access(all)
		fun clean(barterRef: &Barter, id: UInt64)
		
		access(all)
		fun acceptBarter(
			id: UInt64,
			offeredNFTReceiverCaps: [
				Capability<&{NonFungibleToken.CollectionPublic}>
			],
			requestedNFTProviderCaps: [
				Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
			],
			offeredFTReceiverCaps: [
				Capability<&{FungibleToken.Receiver, FungibleToken.Balance}>
			],
			requestedFTProviderCaps: [
				Capability<&{FungibleToken.Provider, FungibleToken.Balance}>
			],
			feeCapability: Capability<&{FungibleToken.Provider}>
		)
		
		access(all)
		fun counterBarter(
			barterAddress: Address,
			barterID: UInt64,
			ftAssetsOffered: [
				FTAsset
			],
			nftAssetsOffered: [
				NFTAsset
			],
			ftAssetsRequested: [
				FTAsset
			],
			nftAssetsRequested: [
				NFTAsset
			],
			expiresAt: UFix64,
			feeCapability: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>
		): @Barter
	}
	
	// Barter Collection Resource
	//
	// Lives in users account
	//
	access(all)
	resource BarterCollection: BarterCollectionPublic, ViewResolver.ResolverCollection{ 
		access(contract)
		let barters: @{UInt64: Barter}
		
		init(){ 
			self.barters <-{} 
		}
		
		access(all)
		fun borrowBarter(id: UInt64): &Barter?{ 
			return &self.barters[id] as &Barter?
		}
		
		// public but access restricted by requiring matching reference
		access(all)
		fun clean(barterRef: &Barter, id: UInt64){ 
			if barterRef.uuid != self.barters[id]?.linkedID{ 
				return
			} // early return if referenced id not matching
			
			destroy <-self.barters.remove(key: id)
		}
		
		access(all)
		fun deposit(barter: @Barter){ 
			self.barters[barter.uuid] <-! barter
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			return (&self.barters[id] as &{ViewResolver.Resolver}?)!
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.barters.keys
		}
		
		// Accept barter function
		//
		// takes a barterID, removes that Barter and calls the accept barter function on it then cleans up afterwards....
		// the Offered Receiver Caps and Requested Provider Caps are required to complete the barter
		//
		access(all)
		fun acceptBarter(id: UInt64, offeredNFTReceiverCaps: [Capability<&{NonFungibleToken.CollectionPublic}>], requestedNFTProviderCaps: [Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>], offeredFTReceiverCaps: [Capability<&{FungibleToken.Receiver, FungibleToken.Balance}>], requestedFTProviderCaps: [Capability<&{FungibleToken.Provider, FungibleToken.Balance}>], feeCapability: Capability<&{FungibleToken.Provider}>){ 
			let barter <- self.barters.remove(key: id)!
			barter.acceptBarter(offeredNFTReceiverCaps: offeredNFTReceiverCaps, requestedNFTProviderCaps: requestedNFTProviderCaps, offeredFTReceiverCaps: offeredFTReceiverCaps, requestedFTProviderCaps: requestedFTProviderCaps, feeCapability: feeCapability)
			
			// add more info to event
			emit BarterExecuted(id: barter.uuid)
			for uuid in self.barters.keys{ 
				let barterRef = &self.barters[uuid] as &Barter?
				if (barterRef!).previousID == barter.uuid{ 
					let oldBarter <- self.barters.remove(key: uuid)!
					let linkedCollection = getAccount(oldBarter.getOfferAddress()).capabilities.get<&{BYC.BarterCollectionPublic}>(BYC.BarterCollectionPublicPath).borrow<&{BYC.BarterCollectionPublic}>()!
					linkedCollection.clean(barterRef: &oldBarter as &Barter, id: oldBarter.linkedID!)
					destroy oldBarter
				}
			}
			// cleanup boths accounts
			let linkedCollection = getAccount(barter.getOfferAddress()).capabilities.get<&{BYC.BarterCollectionPublic}>(BYC.BarterCollectionPublicPath).borrow<&{BYC.BarterCollectionPublic}>()!
			linkedCollection.clean(barterRef: &barter as &Barter, id: barter.linkedID!)
			destroy barter
		}
		
		// counter barter function
		//
		// creates a new barter as a response to an existing barter
		//
		access(all)
		fun counterBarter(barterAddress: Address, barterID: UInt64, ftAssetsOffered: [FTAsset], nftAssetsOffered: [NFTAsset], ftAssetsRequested: [FTAsset], nftAssetsRequested: [NFTAsset], expiresAt: UFix64, feeCapability: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>): @Barter{ 
			let barterCollectionCap = getAccount(barterAddress).capabilities.get_<YOUR_TYPE>(BYC.BarterCollectionPublicPath)
			let barterCollectionRef = barterCollectionCap.borrow<&{BarterCollectionPublic}>()!
			let barterRef = barterCollectionRef.borrowBarter(id: barterID)!
			var counterpartyAddress = barterRef.getOfferAddress()
			let counterpartyCollection = getAccount(counterpartyAddress!).capabilities.get<&{BYC.BarterCollectionPublic}>(BYC.BarterCollectionPublicPath).borrow<&{BYC.BarterCollectionPublic}>()!
			
			// If the caller is the counterparty reject the previous offer (they are responding to an offer)
			// if the caller is another address we just create a new barter with previousBarterID set to id of the barter being countered
			if self.owner?.address == barterRef.counterpartyAddress{ 
				// clean destroys the counter party barter
				counterpartyCollection.clean(barterRef: (&self.barters[barterID] as &Barter?)!, id: barterRef.linkedID!)
				destroy <-self.barters.remove(key: barterID)
			}
			return <-BYC.createBarter(ftAssetsOffered: ftAssetsOffered, nftAssetsOffered: nftAssetsOffered, ftAssetsRequested: ftAssetsRequested, nftAssetsRequested: nftAssetsRequested, counterpartyAddress: counterpartyAddress, expiresAt: expiresAt, feeCapability: feeCapability, previousBarterID: barterID)
		}
		
		// Reject Barter
		//
		// This function is called to reject an offer received
		// Can also be used to cancel an offer made by the user
		//
		access(all)
		fun rejectBarter(id: UInt64){ 
			pre{ 
				self.barters.containsKey(id):
					"Barter with ID: ".concat(id.toString()).concat(" not found!")
			}
			let barterRef = (&self.barters[id] as &Barter?)!
			if barterRef.counterpartyAddress != nil{ // if not a 1-sided barter proposal 
				
				let callerIsCounterparty = self.owner?.address == barterRef.counterpartyAddress
				// check if caller is canceling offer they made or rejecting an offer received
				let linkedAddress = callerIsCounterparty ? barterRef.getOfferAddress() : barterRef.counterpartyAddress!
				let linkedCollection = getAccount(linkedAddress).capabilities.get<&{BYC.BarterCollectionPublic}>(BYC.BarterCollectionPublicPath).borrow<&{BYC.BarterCollectionPublic}>()!
				linkedCollection.clean(barterRef: barterRef, id: barterRef.linkedID!)
			}
			destroy <-self.barters.remove(key: id)
		}
	}
	
	// Admin Resource
	//
	//
	access(all)
	resource Admin{ 
		//
		access(all)
		fun updateFeeByIdentifier(
			identifier: String,
			fee: UFix64,
			feeCap: Capability<&{FungibleToken.Receiver}>
		){ 
			BYC.feeReceiverCapByIdentifier[identifier] = feeCap
			BYC.feeByTokenIdentifier[identifier] = fee
			emit FeesAcceptedUpdated(identifier: identifier, fee: fee)
		}
		
		access(all)
		fun removeFeeByIdentifier(identifier: String){ 
			pre{ 
				BYC.feeByTokenIdentifier[identifier] == nil:
					"Cannot find fee vault identifier: ".concat(identifier)
			}
			BYC.feeByTokenIdentifier[identifier] = nil
			BYC.feeReceiverCapByIdentifier[identifier] = nil
			emit FeesAcceptedUpdated(identifier: identifier, fee: nil)
		}
		
		//
		access(all)
		fun addNoFeeBarterNFT(identifier: String, collectionPath: PublicPath){ 
			BYC.noFeeBarterNFTs[identifier] = collectionPath
			emit NoFeeBarterNFTsUpdated(identifier: identifier)
		}
		
		access(all)
		fun removeNoFeeBarterNFT(identifier: String){ 
			pre{ 
				BYC.noFeeBarterNFTs[identifier] == nil:
					"Cannot find NFT identifier: ".concat(identifier)
			}
			BYC.noFeeBarterNFTs[identifier] = nil
			emit NoFeeBarterNFTsRemoved(identifier: identifier)
		}
		
		access(all)
		fun updateFungibleTokenFee(percentage: UFix64){ 
			pre{ 
				percentage < 1.0:
					"Fee must be less than 1.0 (100%)"
			}
			BYC.FT_TOKEN_FEE_PERCENTAGE = percentage
		}
		
		access(all)
		fun withdrawFees(identifier: String): @{FungibleToken.Vault}{ 
			return <-(BYC.feeVaultsByIdentifier[identifier]?.withdraw!)(
				amount: BYC.feeVaultsByIdentifier[identifier]?.balance!
			)
		}
	}
	
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	// PUBLIC FUNCTIONS
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	// flexible create barter function that can:
	// 1. create a barter proposal if no counterparty is provided
	// 2. create 2 barters if counterparty already has barterCollection setup
	// 3. create 1 barter if counterparty doesn't have barterCollection setup
	access(all)
	fun createBarter(
		ftAssetsOffered: [
			FTAsset
		],
		nftAssetsOffered: [
			NFTAsset
		],
		ftAssetsRequested: [
			FTAsset
		],
		nftAssetsRequested: [
			NFTAsset
		],
		counterpartyAddress: Address?,
		expiresAt: UFix64,
		feeCapability: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>,
		previousBarterID: UInt64?
	): @Barter{ 
		pre{ 
			expiresAt >= getCurrentBlock().timestamp:
				"Expiry time must be in the future!"
		}
		if counterpartyAddress == nil{ // create barter 1 sided 'proposal' 
			
			let a <- create Barter(ftAssetsOffered: ftAssetsOffered, nftAssetsOffered: nftAssetsOffered, ftAssetsRequested: [], nftAssetsRequested: [], counterpartyAddress: nil, expiresAt: expiresAt, previousBarterID: previousBarterID, proposerFeeCapability: feeCapability)
			emit BarterCreated(offerID: a.uuid, offeringAddress: a.getOfferAddress(), counterpartyID: previousBarterID, counterpartyAddress: nil)
			return <-a
		}
		let remoteCollectionRef =
			getAccount(counterpartyAddress!).capabilities.get<&{BarterCollectionPublic}>(
				BYC.BarterCollectionPublicPath
			).borrow<&{BarterCollectionPublic}>()
		if remoteCollectionRef != nil{ // we send a linked copy of the Barter to the counterparty 
			
			let a <- create Barter(ftAssetsOffered: ftAssetsOffered, nftAssetsOffered: nftAssetsOffered, ftAssetsRequested: ftAssetsRequested, nftAssetsRequested: nftAssetsRequested, counterpartyAddress: counterpartyAddress, expiresAt: expiresAt, previousBarterID: previousBarterID, proposerFeeCapability: feeCapability)
			assert(a.getOfferAddress() != counterpartyAddress, message: "Provider of Assets cannot be the counter party") // we assert after so we can use the existing function
			
			let b <- create Barter(ftAssetsOffered: ftAssetsOffered, nftAssetsOffered: nftAssetsOffered, ftAssetsRequested: ftAssetsRequested, nftAssetsRequested: nftAssetsRequested, counterpartyAddress: counterpartyAddress, expiresAt: expiresAt, previousBarterID: previousBarterID, proposerFeeCapability: feeCapability)
			a.setLinkedID(b.uuid)
			b.setLinkedID(a.uuid)
			emit BarterCreated(offerID: a.uuid, offeringAddress: a.getOfferAddress(), counterpartyID: b.uuid, counterpartyAddress: counterpartyAddress)
			(remoteCollectionRef!).deposit(barter: <-b)
			return <-a
		} else{ // we return a single Barter to the user making the offer.. 
			
			let a <- create Barter(ftAssetsOffered: ftAssetsOffered, nftAssetsOffered: nftAssetsOffered, ftAssetsRequested: ftAssetsRequested, nftAssetsRequested: nftAssetsRequested, counterpartyAddress: counterpartyAddress, expiresAt: expiresAt, previousBarterID: previousBarterID, proposerFeeCapability: feeCapability)
			emit BarterCreated(offerID: a.uuid, offeringAddress: a.getOfferAddress(), counterpartyID: nil, counterpartyAddress: counterpartyAddress)
			return <-a
		}
	}
	
	access(all)
	fun createEmptyCollection(): @BarterCollection{ 
		return <-create BarterCollection()
	}
	
	access(all)
	fun readFeesCollected():{ String: UFix64}{ 
		let fees:{ String: UFix64} ={} 
		for key in BYC.feeVaultsByIdentifier.keys{ 
			fees.insert(key: key, BYC.feeVaultsByIdentifier[key]?.balance!)
		}
		return fees
	}
	
	access(account)
	fun depositFees(_ fees: @{FungibleToken.Vault}){ 
		let identifier = fees.getType().identifier
		if BYC.feeVaultsByIdentifier[identifier] == nil{ 
			BYC.feeVaultsByIdentifier[identifier] <-! fees
		} else{ 
			(BYC.feeVaultsByIdentifier[identifier]?.deposit!)(from: <-fees)
		}
	}
	
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	// Helper Functions
	//
	// used to check for NFTs that allow fees to be waived
	access(all)
	fun checkAddressOwnsNFT(
		address: Address,
		collectionPath: PublicPath,
		nftIdentifier: String
	): Bool{ 
		let collectionRef =
			getAccount(address).capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				collectionPath
			).borrow()
		if collectionRef == nil{ 
			return false
		}
		for id in (collectionRef!).getIDs(){ 
			let nft = (collectionRef!).borrowNFT(id: id)
			if nft.getType().identifier == nftIdentifier{ 
				return true
			}
		}
		return false
	}
	
	access(all)
	fun getFeesAccepted():{ String: UFix64}{ 
		return self.feeByTokenIdentifier
	}
	
	access(all)
	fun getNoFeeBarterNFTs(): [String]{ 
		return self.noFeeBarterNFTs.keys
	}
	
	init(){ 
		self.BarterCollectionStoragePath = /storage/BYC_Swap
		self.BarterCollectionPublicPath = /public/BYC_Swap
		self.BarterCollectionPrivatePath = /private/BYC_Swap
		self.AdminStoragePath = /storage/BYC_Admin
		self.feeVaultsByIdentifier <-{} 
		self.FT_TOKEN_FEE_PERCENTAGE = 0.01
		self.feeByTokenIdentifier ={} 
		self.feeReceiverCapByIdentifier ={} 
		self.noFeeBarterNFTs ={} 
		if self.account.storage.borrow<&Admin>(from: BYC.AdminStoragePath) == nil{ 
			self.account.storage.save(<-create Admin(), to: BYC.AdminStoragePath)
		}
	}
}
