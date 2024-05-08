import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import PonsNftContractInterface from "./PonsNftContractInterface.cdc"

import PonsNftContract from "./PonsNftContract.cdc"

import PonsNftContract_v1 from "./PonsNftContract_v1.cdc"

import PonsNftMarketContract from "./PonsNftMarketContract.cdc"

import PonsUtils from "./PonsUtils.cdc"

/*
	Pons NFT Market Contract v1

	This smart contract contains the concrete functionality of Pons NFT marketplace v1.
	In the v1 implementation, all Pons NFT marketplace information is straightforwardly stored inside the contract.
	The implementation also has separate commission ratios for freshly minted NFTs and resale NFTs.
*/

access(all)
contract PonsNftMarketContract_v1{ 
	/* PonsNftMarketContractInit_v1 is emitted on initialisation of this contract */
	access(all)
	event PonsNftMarketContractInit_v1()
	
	/* FundsHeldOnBehalfOfArtist is emitted when an NFT is purchased, but the artist's Capability to receive payment is invalid, and the market holds the funds on behalf of the artist */
	access(all)
	event FundsHeldOnBehalfOfArtist(
		ponsArtistId: String,
		nftId: String,
		flowUnits: PonsUtils.FlowUnits
	)
	
	/* The concrete Pons NFT Market resource. Striaghtforward implementation of the PonsNftMarket interface */
	access(all)
	resource PonsNftMarket_v1: PonsNftMarketContract.PonsNftMarket{ 
		/* Pons v1 collection to store the NFTs on sale */
		access(account)
		let collection: @PonsNftContract_v1.Collection
		
		/* Capability for the market to receive payment */
		access(account)
		var marketReceivePaymentCap: Capability<&{FungibleToken.Receiver}>
		
		/* Sales prices for each nftId */
		access(account)
		var salePrices:{ String: PonsUtils.FlowUnits}
		
		/* Seller capabilities to receive payment for each nftId */
		access(account)
		var saleReceivePaymentCaps:{ String: Capability<&{FungibleToken.Receiver}>}
		
		/* Stores the number of times each nftId has been listed on the market */
		/* 0 means freshly minted listing */
		/* 1 or above means resell listing */
		/* This helps the marketplace evaluate the validity of different listing certificate */
		access(account)
		var listingCounts:{ String: Int}
		
		/* Minimum minting price */
		access(account)
		var minimumMintingPrice: PonsUtils.FlowUnits
		
		/* Commission ratio of the market on freshly minted NFTs */
		access(account)
		var primaryCommissionRatio: PonsUtils.Ratio
		
		/* Commission ratio of the market on resold NFTs */
		access(account)
		var secondaryCommissionRatio: PonsUtils.Ratio
		
		/* Inserts or updates a sale price */
		access(account)
		fun insertSalePrice(nftId: String, price: PonsUtils.FlowUnits): PonsUtils.FlowUnits?{ 
			return self.salePrices.insert(key: nftId, price)
		}
		
		/* Removes a sale price */
		access(account)
		fun removeSalePrice(nftId: String): PonsUtils.FlowUnits?{ 
			return self.salePrices.remove(key: nftId)
		}
		
		/* Get the nftIds of all NFTs for sale */
		access(all)
		fun getForSaleIds(): [String]{ 
			return self.salePrices.keys
		}
		
		/* Get the price of an NFT */
		access(all)
		fun getPrice(nftId: String): PonsUtils.FlowUnits?{ 
			return self.salePrices[nftId]
		}
		
		/* Borrow an NFT from the marketplace, to browse its details */
		access(all)
		fun borrowNft(nftId: String): &PonsNftContractInterface.NFT?{ 
			return self.collection.borrowNft(nftId: nftId)
		}
		
		/* Given a Pons artist certificate, mint new Pons NFTs on behalf of the artist and list it on the marketplace for sale */
		/* The price of the first edition of the NFT minted is determined by the basePrice, which must be at least the minimumMintingPrice */
		/* When only one edition is minted, the incrementalPrice is inconsequential */
		/* When the Pons marketplace mints multiple editions of NFTs, the market price of each succeesive NFT is incremented by the incrementalPrice */
		access(all)
		fun mintForSale(_ artistCertificate: &PonsNftContract.PonsArtistCertificate, metadata:{ String: String}, quantity: Int, basePrice: PonsUtils.FlowUnits, incrementalPrice: PonsUtils.FlowUnits, _ royaltyRatio: PonsUtils.Ratio, _ receivePaymentCap: Capability<&{FungibleToken.Receiver}>): @[{PonsNftMarketContract.PonsListingCertificate}]{ 
			if !basePrice.isAtLeast(self.minimumMintingPrice){ 
				panic("NFTs minted on Pons must have a minimum price of ".concat(self.minimumMintingPrice.toString()))
			}
			
			// Create an array to store created listing certificates
			var mintListingCertificates: @[PonsListingCertificate_v1] <- []
			
			// For any mintIndex from 0 (inclusive) up to the quantity specified (exclusive)
			var mintIndex = 0
			var salePrice = basePrice
			while mintIndex < quantity{ 
				// Define the NFT editionLabel
				let editionLabel = quantity == 1 ? "One of a kind" : "Edition ".concat((mintIndex + 1).toString())
				
				// Mint the NFT using the Pons NFT v1 minter capability
				var nft: @PonsNftContractInterface.NFT <- (PonsNftContract_v1.MinterCapability.borrow()!).mintNft(artistCertificate, royalty: royaltyRatio, editionLabel: editionLabel, metadata: metadata)
				let nftId = nft.nftId
				let nftRef = &nft as &PonsNftContractInterface.NFT
				let serialNumber = PonsNftContract.getSerialNumber(nftRef)
				
				// Deposit the NFT into the market collection, and save all relevant market data 
				self.collection.depositNft(<-nft)
				self.salePrices.insert(key: nftId, salePrice)
				self.saleReceivePaymentCaps.insert(key: nftId, receivePaymentCap)
				self.listingCounts.insert(key: nftId, 0)
				
				// Emit the Pons NFT Market listing event
				PonsNftMarketContract.emitPonsNFTListed(nftId: nftId, serialNumber: serialNumber, editionLabel: editionLabel, price: salePrice)
				
				// First, create a new listing certificate for the NFT, where listerAddress is the market address so that the artist cannot directly unlist the NFT
				// Then, move the listing certificate to the array of minted listing certificates
				mintListingCertificates.append(<-create PonsListingCertificate_v1(listerAddress: PonsNftMarketContract.PonsNftMarketAddress, nftId: nftId, listingCount: 0))
				
				// Continue iterating on the next mintIndex and increment the price to sell, by the incrementalPrice
				mintIndex = mintIndex + 1
				salePrice = PonsUtils.sumFlowUnits(salePrice, incrementalPrice)
			}
			return <-mintListingCertificates
		}
		
		/* List a Pons NFT on the marketplace for sale */
		access(all)
		fun listForSale(_ nft: @PonsNftContractInterface.NFT, _ salePrice: PonsUtils.FlowUnits, _ receivePaymentCap: Capability<&{FungibleToken.Receiver}>): @{PonsNftMarketContract.PonsListingCertificate}{ 
			// Record the previous owner of the NFT
			// let ownerAddress = nft .owner !.address
			
			// Flow implementation seems to be inconsistent regarding owners of nested resources
			// https://github.com/onflow/cadence/issues/1320
			// As a temporary workaround, assume the receivePaymentCap points to a vault with the lister as owner
			let ownerAddress = ((receivePaymentCap.borrow()!).owner!).address
			let nftId = nft.nftId
			let nftRef = &nft as &PonsNftContractInterface.NFT
			let serialNumber = PonsNftContract.getSerialNumber(nftRef)
			let editionLabel = PonsNftContract.getEditionLabel(nftRef)
			let listingCount = (self.listingCounts[nftId] ?? 0) + 1
			
			// Deposit the NFT into the market collection, and save all relevant market data
			self.collection.depositNft(<-nft)
			self.salePrices.insert(key: nftId, salePrice)
			self.saleReceivePaymentCaps.insert(key: nftId, receivePaymentCap)
			self.listingCounts.insert(key: nftId, listingCount)
			
			// Create a new listing certificate for the NFT, where listerAddress is the address of the previous owner
			var ponsListingCertificate <- create PonsListingCertificate_v1(listerAddress: ownerAddress, nftId: nftId, listingCount: listingCount)
			
			// Emit the Pons NFT Market listing event
			PonsNftMarketContract.emitPonsNFTListed(nftId: nftId, serialNumber: serialNumber, editionLabel: editionLabel, price: salePrice)
			return <-ponsListingCertificate
		}
		
		/* Purchase a Pons NFT from the marketplace */
		access(all)
		fun purchase(nftId: String, _ purchaseVault: @{FungibleToken.Vault}): @PonsNftContractInterface.NFT{ 
			// Check that the NFT is available on the market
			if !self.salePrices.containsKey(nftId){ 
				panic("Pons NFT with ID ".concat(nftId).concat(" not on the market"))
			}
			
			// Check that the sufficient funds of Flow tokens have been provided
			let purchasePrice = self.salePrices.remove(key: nftId)!
			if !PonsUtils.FlowUnits(flowAmount: purchaseVault.balance).isAtLeast(purchasePrice){ 
				panic("Pons NFT with ID ".concat(nftId).concat(" is on sale for ").concat(purchasePrice.toString()).concat(", insufficient funds provided"))
			}
			
			// Withdraw the NFT from the market collection
			var nft <- self.collection.withdrawNft(nftId: nftId)
			let nftRef = &nft as &PonsNftContractInterface.NFT
			
			// Record the owner of the paying Vault if any, to identify the new owner of the NFT
			let vaultOwnerAddress = purchaseVault.owner?.address
			
			// Check whether the purchase is an original sale or resale, and calculate commissions and royalties accordingly
			let primarySale = self.listingCounts[nftId] == 0
			let royalties = primarySale ? nil as! PonsUtils.FlowUnits? : purchasePrice.scale(ratio: PonsNftContract.getRoyalty(nftRef))
			let commissionPrice = primarySale ? purchasePrice.scale(ratio: self.primaryCommissionRatio) : purchasePrice.scale(ratio: self.secondaryCommissionRatio)
			let sellerPrice = purchasePrice.cut(commissionPrice).cut(royalties ?? PonsUtils.FlowUnits(flowAmount: 0.0))
			
			// If royalties are due, pay the royalties
			if royalties != nil{ 
				// Withdraw royalties from the purchase funds
				var royaltiesVault <- purchaseVault.withdraw(amount: (royalties!).flowAmount)
				let artistRef = PonsNftContract.borrowArtist(nftRef)
				let artistReceivePaymentCapOptional = PonsNftContract.getArtistReceivePaymentCap(artistRef)
				
				// If the artist's Capability for receiving Flow tokens is valid
				if artistReceivePaymentCapOptional != nil && (artistReceivePaymentCapOptional!).check(){ 
					((					  // Deposit royalty funds to the artist
					  artistReceivePaymentCapOptional!).borrow()!).deposit(from: <-royaltiesVault)
				} else{ 
					// If the artist does not have a valid Capability to receive payments, hold the funds on behalf of the artist
					// Emit the funds held on behalf of artist event
					emit FundsHeldOnBehalfOfArtist(ponsArtistId: artistRef.ponsArtistId, nftId: nftId, flowUnits: royalties!)
					(self.marketReceivePaymentCap.borrow()!).deposit(from: <-royaltiesVault)
				}
			}
			
			// Pay the seller the amount due
			let sellerReceivePaymentCap = self.saleReceivePaymentCaps[nftId]!
			(sellerReceivePaymentCap.borrow()!).deposit(from: <-purchaseVault.withdraw(amount: sellerPrice.flowAmount))
			(			 
			 // Market takes the rest as commission
			 self.marketReceivePaymentCap.borrow()!).deposit(from: <-purchaseVault)
			
			// Emit the Pons NFT Market sold event
			PonsNftMarketContract.emitPonsNFTSold(nftId: nftId, serialNumber: PonsNftContract.getSerialNumber(nftRef), editionLabel: PonsNftContract.getEditionLabel(nftRef), price: purchasePrice)
			// If the purchasing account is known, emit the Pons NFT ownership event
			if vaultOwnerAddress != nil{ 
				PonsNftMarketContract.emitPonsNFTOwns(owner: vaultOwnerAddress!, nftId: nftId, serialNumber: PonsNftContract.getSerialNumber(nftRef), editionLabel: PonsNftContract.getEditionLabel(nftRef), price: purchasePrice)
			}
			return <-nft
		}
		
		/* Unlist a Pons NFT from the marketplace */
		access(all)
		fun unlist(_ ponsListingCertificate: @{PonsNftMarketContract.PonsListingCertificate}): @PonsNftContractInterface.NFT{ 
			// Cast the certificate to a @PonsListingCertificate_v1, which is the only resource type recognised in this contract
			var ponsListingCertificate_v1 <- ponsListingCertificate as! @PonsListingCertificate_v1
			
			// Retrieve the certificate nftId
			let nftId = ponsListingCertificate_v1.nftId
			
			// Verify that the certificate is still valid (i.e. issued for a listing that is currently for sale)
			if ponsListingCertificate_v1.listingCount != self.listingCounts[nftId]{ 
				panic("This Listing Certificate is not valid anymore")
			}
			
			// Consume the certificate
			destroy ponsListingCertificate_v1
			
			// Retrieve the NFT market data, and check that the NFT is not freshly minted
			let salePrice = self.salePrices.remove(key: nftId)!
			if self.listingCounts[nftId] == 0{ 
				panic
				"Pons NFT with ID ".concat(nftId).concat(" had just been freshly minted on Pons market, and cannot be unlisted. ").concat("Pons NFTs can be unlisted if a buyer of the Pons NFT lists the NFT again.")
			}
			
			// Withdraw the NFT from the market collection
			var nft <- self.collection.withdrawNft(nftId: nftId)
			let nftRef = &nft as &PonsNftContractInterface.NFT
			
			// Emit the Pons NFT Market unlisted event
			PonsNftMarketContract.emitPonsNFTUnlisted(nftId: nftId, serialNumber: PonsNftContract.getSerialNumber(nftRef), editionLabel: PonsNftContract.getEditionLabel(nftRef), price: salePrice)
			return <-nft
		}
		
		init(marketReceivePaymentCap: Capability<&{FungibleToken.Receiver}>, minimumMintingPrice: PonsUtils.FlowUnits, primaryCommissionRatio: PonsUtils.Ratio, secondaryCommissionRatio: PonsUtils.Ratio){ 
			self.collection <- PonsNftContract_v1.createEmptyCollection(nftType: Type<@PonsNftContract_v1.Collection>())
			self.marketReceivePaymentCap = marketReceivePaymentCap
			self.salePrices ={} 
			self.saleReceivePaymentCaps ={} 
			self.listingCounts ={} 
			self.minimumMintingPrice = minimumMintingPrice
			self.primaryCommissionRatio = primaryCommissionRatio
			self.secondaryCommissionRatio = secondaryCommissionRatio
		}
	}
	
	/* The concrete Pons Listing Certificate resource. Striaghtforward implementation of the PonsNftMarket interface, and also record the number of times the NFT has previously been listed */
	access(all)
	resource PonsListingCertificate_v1: PonsNftMarketContract.PonsListingCertificate{ 
		access(all)
		let listerAddress: Address
		
		access(all)
		let nftId: String
		
		access(all)
		let listingCount: Int
		
		init(listerAddress: Address, nftId: String, listingCount: Int){ 
			self.listerAddress = listerAddress
			self.nftId = nftId
			self.listingCount = listingCount
		}
	}
	
	init(){ 
		let account = self.account
		if account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) == nil{ 
			account.storage.save(<-FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()), to: /storage/flowTokenVault)
		}
		if !account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver).check(){ 
			account.link<&FlowToken.Vault>(/public/flowTokenReceiver, target: /storage/flowTokenVault)
		}
		if !account.capabilities.get<&FlowToken.Vault>(/public/flowTokenBalance).check(){ 
			// Create a public capability to the Vault that only exposes
			// the balance field through the Balance interface
			account.link<&FlowToken.Vault>(/public/flowTokenBalance, target: /storage/flowTokenVault)
		}
		let marketReceivePaymentCap =
			account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
		var ponsMarketV1 <-
			create PonsNftMarket_v1(
				marketReceivePaymentCap: marketReceivePaymentCap!,
				minimumMintingPrice: PonsUtils.FlowUnits(flowAmount: 1.0),
				primaryCommissionRatio: PonsUtils.Ratio(amount: 0.2),
				secondaryCommissionRatio: PonsUtils.Ratio(amount: 0.1)
			)
		// Activate PonsNftMarket_v1 as the active implementation of the Pons NFT marketplace
		PonsNftMarketContract.setPonsMarket(<-ponsMarketV1)
		
		// Emit the PonsNftMarketContractInit_v1 contract initialised event
		emit PonsNftMarketContractInit_v1()
	}
}
