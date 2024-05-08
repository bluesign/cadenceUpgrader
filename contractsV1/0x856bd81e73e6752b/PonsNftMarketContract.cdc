import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import PonsNftContractInterface from "./PonsNftContractInterface.cdc"

import PonsNftContract from "./PonsNftContract.cdc"

import PonsUtils from "./PonsUtils.cdc"

/*
	Pons NFT Market Contract

	This smart contract contains the core functionality of the Pons NFT market.
	The contract defines the core mechanisms of minting, listing, purchasing, and unlisting NFTs, and also the Listing Certificate resource that proves a NFT listing.
	This smart contract serves as the API for users of the Pons NFT marketplace, and delegates concrete functionality to another resource which implements contract functionality, so that updates can be made to the marketplace in a controlled manner if necessary.
	When the Pons marketplace mints multiple editions of NFTs, the market price of each succeesive NFT is incremented by an incremental price.
	This is adjustable by the minting Pons artist.
*/

access(all)
contract PonsNftMarketContract{ 
	/* The storage path for the PonsNftMarket */
	access(all)
	let PonsNftMarketAddress: Address
	
	/* Standardised storage path for PonsListingCertificateCollection */
	access(all)
	let PonsListingCertificateCollectionStoragePath: StoragePath
	
	/* PonsMarketContractInit is emitted on initialisation of this contract */
	access(all)
	event PonsMarketContractInit()
	
	/* PonsNFTListed is emitted on the listing of Pons NFTs on the marketplace */
	access(all)
	event PonsNFTListed(
		nftId: String,
		serialNumber: UInt64,
		editionLabel: String,
		price: PonsUtils.FlowUnits
	)
	
	/* PonsNFTUnlisted is emitted on the unlisting of Pons NFTs from the marketplace */
	access(all)
	event PonsNFTUnlisted(
		nftId: String,
		serialNumber: UInt64,
		editionLabel: String,
		price: PonsUtils.FlowUnits
	)
	
	/* PonsNFTSold is emitted when a Pons NFT is sold */
	access(all)
	event PonsNFTSold(
		nftId: String,
		serialNumber: UInt64,
		editionLabel: String,
		price: PonsUtils.FlowUnits
	)
	
	/* PonsNFTSold is emitted when a Pons NFT is sold, and the new owner address is known */
	access(all)
	event PonsNFTOwns(
		owner: Address,
		nftId: String,
		serialNumber: UInt64,
		editionLabel: String,
		price: PonsUtils.FlowUnits
	)
	
	/* Allow the PonsNft events to be emitted by all implementations of Pons NFTs from the same account */
	access(account)
	fun emitPonsNFTListed(
		nftId: String,
		serialNumber: UInt64,
		editionLabel: String,
		price: PonsUtils.FlowUnits
	): Void{ 
		emit PonsNFTListed(
			nftId: nftId,
			serialNumber: serialNumber,
			editionLabel: editionLabel,
			price: price
		)
	}
	
	access(account)
	fun emitPonsNFTUnlisted(
		nftId: String,
		serialNumber: UInt64,
		editionLabel: String,
		price: PonsUtils.FlowUnits
	): Void{ 
		emit PonsNFTUnlisted(
			nftId: nftId,
			serialNumber: serialNumber,
			editionLabel: editionLabel,
			price: price
		)
	}
	
	access(account)
	fun emitPonsNFTSold(
		nftId: String,
		serialNumber: UInt64,
		editionLabel: String,
		price: PonsUtils.FlowUnits
	): Void{ 
		emit PonsNFTSold(
			nftId: nftId,
			serialNumber: serialNumber,
			editionLabel: editionLabel,
			price: price
		)
	}
	
	access(account)
	fun emitPonsNFTOwns(
		owner: Address,
		nftId: String,
		serialNumber: UInt64,
		editionLabel: String,
		price: PonsUtils.FlowUnits
	): Void{ 
		emit PonsNFTOwns(
			owner: owner,
			nftId: nftId,
			serialNumber: serialNumber,
			editionLabel: editionLabel,
			price: price
		)
	}
	
	/*
		Pons NFT Market Resource Interface
	
		This resource interface defines the mechanisms and requirements for Pons NFT market implementations.
	*/
	
	access(all)
	resource interface PonsNftMarket{ 
		/* Get the nftIds of all NFTs for sale */
		access(all)
		fun getForSaleIds(): [String]
		
		/* Get the price of an NFT */
		access(all)
		fun getPrice(nftId: String): PonsUtils.FlowUnits?
		
		/* Borrow an NFT from the marketplace, to browse its details */
		access(all)
		view fun borrowNft(nftId: String): &PonsNftContractInterface.NFT?
		
		/* Given a Pons artist certificate, mint new Pons NFTs on behalf of the artist and list it on the marketplace for sale */
		/* The price of the first edition of the NFT minted is determined by the basePrice */
		/* When only one edition is minted, the incrementalPrice is inconsequential */
		/* When the Pons marketplace mints multiple editions of NFTs, the market price of each successive NFT is incremented by the incrementalPrice */
		access(all)
		fun mintForSale(
			_ artistCertificate: &PonsNftContract.PonsArtistCertificate,
			metadata:{ 
				String: String
			},
			quantity: Int,
			basePrice: PonsUtils.FlowUnits,
			incrementalPrice: PonsUtils.FlowUnits,
			_ royaltyRatio: PonsUtils.Ratio,
			_ receivePaymentCap: Capability<&{FungibleToken.Receiver}>
		): @[{
			PonsListingCertificate}
		]{ 
			pre{ 
				quantity >= 0:
					"The quantity minted must not be a negative number"
				basePrice.flowAmount >= 0.0:
					"The base price must be a positive amount of Flow units"
				incrementalPrice.flowAmount >= 0.0:
					"The base price must be a positive amount of Flow units"
				royaltyRatio.amount >= 0.0:
					"The royalty ratio must be in the range 0% - 100%"
				royaltyRatio.amount <= 1.0:
					"The royalty ratio must be in the range 0% - 100%"
			}
		/*
					// For some reason not understood, the certificatesOwnedByMarket function fails to type-check in this post-condition
					post {
						PonsNftMarketContract .certificatesOwnedByMarket (& result as &[{PonsListingCertificate}]):
							"Failed to mint NFTs for sale" } */
		
		}
		
		/* List a Pons NFT on the marketplace for sale */
		access(all)
		fun listForSale(
			_ nft: @PonsNftContractInterface.NFT,
			_ salePrice: PonsUtils.FlowUnits,
			_ receivePaymentCap: Capability<&{FungibleToken.Receiver}>
		): @{PonsListingCertificate}
		
		/*{
					// WORKAROUND -- ignore
					// Flow implementation seems to be inconsistent regarding owners of nested resources
					// https://github.com/onflow/cadence/issues/1320
					post {
						result .listerAddress == before (nft .owner !.address):
							"Failed to list this Pons NFT" } }*/
		
		/* Purchase a Pons NFT from the marketplace */
		access(all)
		fun purchase(
			nftId: String,
			_ purchaseVault: @{FungibleToken.Vault}
		): @PonsNftContractInterface.NFT{ 
			pre{ 
				// Given that the purchaseVault is a FlowToken vault, preconditions on FungibleToken and FlowToken ensure that
				// the balance of the vault is positive, and that only amounts between zero and the balance of the vault can be withdrawn from the vault, so that
				// attempts to game the market using unreasonable royalty ratios (e.g. < 0% or > 100%) will result in failed assertions
				purchaseVault.isInstance(Type<@FlowToken.Vault>()):
					"Pons NFTs must be purchased using Flow tokens"
				self.borrowNft(nftId: nftId) != nil:
					"This Pons NFT is not on the market anymore"
			}
			post{ 
				result.nftId == nftId:
					"Failed to purchase the Pons NFT"
			}
		}
		
		/* Unlist a Pons NFT from the marketplace */
		access(all)
		fun unlist(
			_ ponsListingCertificate: @{PonsListingCertificate}
		): @PonsNftContractInterface.NFT{ 
			pre{ 
				// WORKAROUND -- ignore
				/*
								// Flow implementation seems to be inconsistent regarding owners of nested resources
								// https://github.com/onflow/cadence/issues/1320
								// For the moment, allow all listing certificate holders redeem...
								ponsListingCertificate .listerAddress == ponsListingCertificate .owner !.address:
									"Only the lister can redeem his Pons NFT"
								*/
				
				self.borrowNft(nftId: ponsListingCertificate.nftId) != nil:
					"This Pons NFT is not on the market anymore"
			}
		}
	}
	
	/*
		Pons Listing Certificate Resource Interface
	
		This resource interface defines basic information about listing certificates.
		Pons market implementations may provide additional details regarding the listing.
	*/
	
	access(all)
	resource interface PonsListingCertificate{ 
		access(all)
		listerAddress: Address
		
		access(all)
		nftId: String
	}
	
	/*
		Pons Listing Certificate Collection Resource
	
		This resource manages a user's listing certificates, and is stored in a standardised location.
	*/
	
	access(all)
	resource PonsListingCertificateCollection{ 
		access(all)
		var listingCertificates: @[{PonsListingCertificate}]
		
		init(){ 
			self.listingCertificates <- []
		}
		
		/* API to add listing certificates to a listing certificate collection */
		access(all)
		fun appendListingCertificate(_ listingCertificate: @{PonsListingCertificate}): Void{ 
			self.listingCertificates.append(<-listingCertificate)
		}
		
		/* API to remove listing certificates from a listing certificate collection */
		access(all)
		fun removeListingCertificate(at index: Int): @{PonsListingCertificate}{ 
			return <-self.listingCertificates.remove(at: index)
		}
	}
	
	access(all)
	fun createPonsListingCertificateCollection(): @PonsListingCertificateCollection{ 
		return <-create PonsListingCertificateCollection()
	}
	
	/* Checks whether all the listing certificates provided belong to the market */
	//	pub fun certificatesOwnedByMarket (_ listingCertificatesRef : &[{PonsListingCertificate}]) : Bool {
	//		var index = 0
	//		while index < listingCertificatesRef .length {
	//			if listingCertificatesRef [index] .listerAddress != PonsNftMarketContract .PonsNftMarketAddress {
	//				return false }
	//			index = index + 1 }
	//		return true }
	/* API to get the nftIds on the market for sale */
	access(all)
	fun getForSaleIds(): [String]{ 
		return PonsNftMarketContract.ponsMarket.getForSaleIds()
	}
	
	/* API to get the price of an NFT on the market */
	access(all)
	fun getPrice(nftId: String): PonsUtils.FlowUnits?{ 
		return PonsNftMarketContract.ponsMarket.getPrice(nftId: nftId)
	}
	
	/* API to borrow an NFT for browsing */
	access(all)
	view fun borrowNft(nftId: String): &PonsNftContractInterface.NFT?{ 
		return PonsNftMarketContract.ponsMarket.borrowNft(nftId: nftId)
	}
	
	/* API to borrow the active Pons market instance */
	access(all)
	fun borrowPonsMarket(): &{PonsNftMarket}{ 
		return &self.ponsMarket as &{PonsNftMarket}
	}
	
	/* A list recording all previously active instances of PonsNftMarket */
	access(account)
	var historicalPonsMarkets: @[{PonsNftMarket}]
	
	/* The currently active instance of PonsNftMarket */
	access(account)
	var ponsMarket: @{PonsNftMarket}
	
	/* Updates the currently active PonsNftMarket */
	access(account)
	fun setPonsMarket(_ ponsMarket: @{PonsNftMarket}): Void{ 
		var newPonsMarket <- ponsMarket
		newPonsMarket <-> PonsNftMarketContract.ponsMarket
		PonsNftMarketContract.historicalPonsMarkets.append(<-newPonsMarket)
	}
	
	init(){ 
		self.historicalPonsMarkets <- []
		// Activate InvalidPonsNftMarket as the active implementation of the Pons NFT market
		self.ponsMarket <- create InvalidPonsNftMarket()
		
		// Save the market address
		self.PonsNftMarketAddress = self.account.address
		// Save the standardised Pons listing certificate collection storage path
		self.PonsListingCertificateCollectionStoragePath = /storage/listingCertificateCollection
		
		// Emit the PonsNftMarket initialisation event
		emit PonsMarketContractInit()
	}
	
	/* An trivial instance of PonsNftMarket which panics on all calls, used on initialization of the PonsNftMarket contract. */
	access(all)
	resource InvalidPonsNftMarket: PonsNftMarket{ 
		access(all)
		fun getForSaleIds(): [String]{ 
			panic("not implemented")
		}
		
		access(all)
		fun getPrice(nftId: String): PonsUtils.FlowUnits?{ 
			panic("not implemented")
		}
		
		access(all)
		view fun borrowNft(nftId: String): &PonsNftContractInterface.NFT?{ 
			panic("not implemented")
		}
		
		access(all)
		fun mintForSale(_ artistCertificate: &PonsNftContract.PonsArtistCertificate, metadata:{ String: String}, quantity: Int, basePrice: PonsUtils.FlowUnits, incrementalPrice: PonsUtils.FlowUnits, _ royaltyRatio: PonsUtils.Ratio, _ receivePaymentCap: Capability<&{FungibleToken.Receiver}>): @[{PonsListingCertificate}]{ 
			panic("not implemented")
		}
		
		access(all)
		fun listForSale(_ nft: @PonsNftContractInterface.NFT, _ salePrice: PonsUtils.FlowUnits, _ receivePaymentCap: Capability<&{FungibleToken.Receiver}>): @{PonsListingCertificate}{ 
			panic("not implemented")
		}
		
		access(all)
		fun purchase(nftId: String, _ purchaseVault: @{FungibleToken.Vault}): @PonsNftContractInterface.NFT{ 
			panic("not implemented")
		}
		
		access(all)
		fun purchaseBySerialId(nftSerialId: UInt64, _ purchaseVault: @{FungibleToken.Vault}): @PonsNftContractInterface.NFT{ 
			panic("not implemented")
		}
		
		access(all)
		fun unlist(_ ponsListingCertificate: @{PonsListingCertificate}): @PonsNftContractInterface.NFT{ 
			panic("not implemented")
		}
	}
}
