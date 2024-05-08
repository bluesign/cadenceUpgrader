import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FuseCollective from "./FuseCollective.cdc"

access(all)
contract FuseCollectiveSaleManager{ 
	// -----------------------------------------------------------------------
	//  Events
	// -----------------------------------------------------------------------
	// Emitted when the contract is initialized
	access(all)
	event ContractInitialized()
	
	access(all)
	event UpdateFuseCollectiveCollectionMetadata()
	
	access(all)
	event UpdateFuseCollectiveEditionMetadata(id: UInt64)
	
	access(all)
	event AdminMint(id: UInt64)
	
	access(all)
	event PublicMint(id: UInt64)
	
	access(all)
	event UpdateSaleInfo(saleStartTime: UFix64, salePrice: UFix64, maxQuantityPerMint: UInt64)
	
	access(all)
	event UpdatePaymentReceiver(address: Address)
	
	// -----------------------------------------------------------------------
	// Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let ManagerStoragePath: StoragePath
	
	// -----------------------------------------------------------------------
	// FuseCollectiveSaleManager fields
	// -----------------------------------------------------------------------
	access(self)
	let mintedEditions:{ UInt64: Bool}
	
	access(self)
	var sequentialMintMin: UInt64
	
	access(contract)
	var paymentReceiver: Capability<&{FungibleToken.Receiver}>
	
	access(all)
	var maxSupply: UInt64
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var maxQuantityPerMint: UInt64
	
	access(all)
	var saleStartTime: UFix64
	
	access(all)
	var salePrice: UFix64
	
	// -----------------------------------------------------------------------
	// Manager resource
	// -----------------------------------------------------------------------
	access(all)
	resource Manager{ 
		access(all)
		fun updateMaxQuantityPerMint(_ amount: UInt64){ 
			FuseCollectiveSaleManager.maxQuantityPerMint = amount
			emit UpdateSaleInfo(
				saleStartTime: FuseCollectiveSaleManager.saleStartTime,
				salePrice: FuseCollectiveSaleManager.salePrice,
				maxQuantityPerMint: FuseCollectiveSaleManager.maxQuantityPerMint
			)
		}
		
		access(all)
		fun updatePrice(_ price: UFix64){ 
			FuseCollectiveSaleManager.salePrice = price
			emit UpdateSaleInfo(
				saleStartTime: FuseCollectiveSaleManager.saleStartTime,
				salePrice: FuseCollectiveSaleManager.salePrice,
				maxQuantityPerMint: FuseCollectiveSaleManager.maxQuantityPerMint
			)
		}
		
		access(all)
		fun updateSaleStartTime(_ saleStartTime: UFix64){ 
			FuseCollectiveSaleManager.saleStartTime = saleStartTime
			emit UpdateSaleInfo(
				saleStartTime: FuseCollectiveSaleManager.saleStartTime,
				salePrice: FuseCollectiveSaleManager.salePrice,
				maxQuantityPerMint: FuseCollectiveSaleManager.maxQuantityPerMint
			)
		}
		
		access(all)
		fun updateFuseCollectiveCollectionMetadata(metadata:{ String: String}){ 
			FuseCollective.setCollectionMetadata(metadata: metadata)
			emit UpdateFuseCollectiveCollectionMetadata()
		}
		
		access(all)
		fun updateFuseCollectiveEditionMetadata(editionNumber: UInt64, metadata:{ String: String}){ 
			FuseCollective.setEditionMetadata(editionNumber: editionNumber, metadata: metadata)
			emit UpdateFuseCollectiveEditionMetadata(id: editionNumber)
		}
		
		access(all)
		fun setPaymentReceiver(paymentReceiver: Capability<&{FungibleToken.Receiver}>){ 
			FuseCollectiveSaleManager.paymentReceiver = paymentReceiver
			emit UpdatePaymentReceiver(address: paymentReceiver.address)
		}
		
		access(all)
		fun mintAtEdition(edition: UInt64): @{NonFungibleToken.NFT}{ 
			emit AdminMint(id: edition)
			return <-FuseCollectiveSaleManager.mint(edition: edition)
		}
	}
	
	access(contract)
	fun mint(edition: UInt64): @{NonFungibleToken.NFT}{ 
		pre{ 
			edition >= 1 && edition <= self.maxSupply:
				"Requested edition is outside of allowed bounds."
			self.mintedEditions[edition] == nil:
				"Requested edition has already been minted"
			self.totalSupply + 1 <= self.maxSupply:
				"Unable to mint any more editions, reached max supply"
		}
		self.mintedEditions[edition] = true
		self.totalSupply = self.totalSupply + 1
		let fuseCollectiveNft <- FuseCollective.mint(nftID: edition)
		return <-fuseCollectiveNft
	}
	
	// Look for the next available nft, and mint there
	access(self)
	fun mintSequential(): @{NonFungibleToken.NFT}{ 
		var curEditionNumber = self.sequentialMintMin
		while self.mintedEditions.containsKey(UInt64(curEditionNumber)){ 
			curEditionNumber = curEditionNumber + 1
		}
		self.sequentialMintMin = curEditionNumber
		emit PublicMint(id: UInt64(curEditionNumber))
		let newNft <- self.mint(edition: UInt64(curEditionNumber))
		return <-newNft
	}
	
	// -----------------------------------------------------------------------
	// Public Functions
	// -----------------------------------------------------------------------
	// Accepts payment for nfts, payment is moved to the `self.paymentReceiver` capability field
	access(all)
	fun publicBatchMintSequential(buyVault: @{FungibleToken.Vault}, quantity: UInt64): @{
		NonFungibleToken.Collection
	}{ 
		pre{ 
			quantity >= 1 && quantity <= self.maxQuantityPerMint:
				"Invalid quantity provided"
			getCurrentBlock().timestamp >= self.saleStartTime:
				"Sale has not yet started"
			self.totalSupply + quantity <= self.maxSupply:
				"Unable to mint, mint goes above max supply"
		}
		
		// -- Receive Payments --
		let totalPrice = self.salePrice * UFix64(quantity)
		// Ensure that the provided balance is equal to our expected price for the NFTs
		assert(totalPrice == buyVault.balance, message: "Invalid amount of Flow provided")
		let flowVault <- buyVault as! @FlowToken.Vault
		(self.paymentReceiver.borrow()!).deposit(
			from: <-flowVault.withdraw(amount: flowVault.balance)
		)
		assert(
			flowVault.balance == 0.0,
			message: "Reached unexpected state with payment - balance is not empty"
		)
		destroy flowVault
		
		// -- Mint the NFT --
		// For `quantity` number of NFTs, mint a sequential edition NFT
		let fuseCollectiveCollection <-
			FuseCollective.createEmptyCollection(nftType: Type<@FuseCollective.Collection>())
		var i = 0
		while UInt64(i) < quantity{ 
			let nft <- self.mintSequential()
			fuseCollectiveCollection.deposit(token: <-nft)
			i = i + 1
		}
		assert(
			fuseCollectiveCollection.getIDs().length == Int(quantity),
			message: "Failed to mint expected amount of NFTs"
		)
		
		// -- Return the resulting collection --
		return <-fuseCollectiveCollection
	}
	
	init(){ 
		// Non-human modifiable variables
		self.maxSupply = 1000
		self.totalSupply = 0
		self.sequentialMintMin = 1
		
		// Updateable variables by admin
		self.maxQuantityPerMint = 1
		self.saleStartTime = 2276359811.0
		self.salePrice = 10000000.0
		
		// Manager resource is only saved to the deploying account's storage
		self.ManagerStoragePath = /storage/FuseCollectiveSaleManager
		self.account.storage.save(<-create Manager(), to: self.ManagerStoragePath)
		
		// Start with no existing editions minted
		self.mintedEditions ={} 
		
		// Default payment receiver will be the contract deploying account
		self.paymentReceiver = self.account.capabilities.get<&FlowToken.Vault>(
				/public/flowTokenReceiver
			)
		emit ContractInitialized()
	}
}
