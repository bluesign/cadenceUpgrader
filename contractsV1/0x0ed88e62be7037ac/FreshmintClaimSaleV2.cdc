import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FreshmintQueue from "../0xb442022ad78b11a2/FreshmintQueue.cdc"

/// FreshmintClaimSaleV2 provides functionality to operate a claim-style sale of NFTs.
///
/// In a claim sale, users can claim NFTs from a queue for a fee.
/// All NFTs in a sale are sold for the same price.
///
/// Unlike in the NFTStorefront contract, a user cannot purchase a specific NFT by ID.
/// On each claim, the user receives the next available NFT in the queue.
/// 
access(all)
contract FreshmintClaimSaleV2{ 
	
	/// The SaleCreated event is emitted when a new sale is created.
	///
	access(all)
	event SaleCreated(uuid: UInt64, id: String, price: UFix64, paymentVaultType: Type, size: Int?)
	
	/// The SaleInserted event is emitted when a sale is inserted into a sale collection.
	///
	access(all)
	event SaleInserted(uuid: UInt64, id: String, address: Address?)
	
	/// The SaleRemoved event is emitted when a sale is removed from a sale collection.
	///
	access(all)
	event SaleRemoved(uuid: UInt64, id: String, address: Address?)
	
	/// The NFTClaimed event is emitted when an NFT is claimed from a sale.
	///
	access(all)
	event NFTClaimed(
		saleUUID: UInt64,
		saleID: String,
		saleAddress: Address?,
		remainingSupply: Int?,
		nftType: Type,
		nftID: UInt64
	)
	
	/// SaleCollectionStoragePath is the default storage path for a SaleCollection instance.
	///
	access(all)
	let SaleCollectionStoragePath: StoragePath
	
	/// SaleCollectionPublicPath is the default public path for a SaleCollectionPublic capability.
	///
	access(all)
	let SaleCollectionPublicPath: PublicPath
	
	/// SaleCollectionPublic is the public-facing capability for a sale collection.
	///
	/// Callers can use this interface to view and borrow sales in a collection.
	///
	access(all)
	resource interface SaleCollectionPublic{ 
		access(all)
		fun getIDs(): [String]
		
		access(all)
		fun borrowSale(id: String): &{SalePublic}?
	}
	
	/// A SaleCollection is a container that holds one or
	/// more Sale resources.
	///
	/// The sale creator does not need to use a sale collection,
	/// but it is useful when running multiple sales from different collections
	/// in the same account.
	///
	access(all)
	resource SaleCollection: SaleCollectionPublic{ 
		access(self)
		let sales: @{String: Sale}
		
		init(){ 
			self.sales <-{} 
		}
		
		access(all)
		fun insert(_ sale: @Sale){ 
			emit SaleInserted(uuid: sale.uuid, id: sale.id, address: self.owner?.address)
			let oldSale <- self.sales[sale.id] <- sale
			destroy oldSale
		}
		
		access(all)
		fun remove(id: String): @Sale{ 
			let sale <- self.sales.remove(key: id) ?? panic("sale does not exist")
			emit SaleRemoved(uuid: sale.uuid, id: sale.id, address: self.owner?.address)
			return <-sale
		}
		
		access(all)
		fun getIDs(): [String]{ 
			return self.sales.keys
		}
		
		access(all)
		fun borrowSale(id: String): &{SalePublic}?{ 
			return &self.sales[id] as &{SalePublic}?
		}
		
		/// Borrow a full reference to a sale.
		///
		/// Use this function to modify properties of the sale
		/// (e.g. to set an allowlist or claim limit).
		///
		access(all)
		fun borrowSaleAuth(id: String): &Sale?{ 
			return &self.sales[id] as &Sale?
		}
	}
	
	/// SaleInfo is a struct containing the information
	/// about a sale including its price, payment type, size and supply.
	///
	access(all)
	struct SaleInfo{ 
		access(all)
		let id: String
		
		access(all)
		let price: UFix64
		
		access(all)
		let paymentVaultType: Type
		
		access(all)
		let size: Int?
		
		access(all)
		let supply: Int?
		
		init(id: String, price: UFix64, paymentVaultType: Type, size: Int?, supply: Int?){ 
			self.id = id
			self.price = price
			self.paymentVaultType = paymentVaultType
			self.size = size
			self.supply = supply
		}
	}
	
	/// SalePublic is the public-facing capability for a sale.
	///
	/// Callers can use this interface to read the details of a sale
	/// and claim an NFT.
	///
	access(all)
	resource interface SalePublic{ 
		access(all)
		let id: String
		
		access(all)
		let price: UFix64
		
		access(all)
		let size: Int?
		
		access(all)
		let receiverPath: PublicPath
		
		access(all)
		fun getPaymentVaultType(): Type
		
		access(all)
		fun getSupply(): Int?
		
		access(all)
		fun getInfo(): SaleInfo
		
		access(all)
		fun getRemainingClaims(address: Address): UInt?
		
		access(all)
		fun claim(payment: @{FungibleToken.Vault}, address: Address)
		
		access(all)
		fun borrowPaymentReceiver(): &{FungibleToken.Receiver}
	}
	
	/// A Sale is a resource that lists NFTs that can be claimed for a fee.
	///
	/// A sale can optionally include an allowlist used to gate claiming.
	///
	access(all)
	resource Sale: SalePublic{ 
		access(all)
		let id: String
		
		access(all)
		let price: UFix64
		
		access(all)
		let size: Int?
		
		/// A capability to the queue that returns the NFTs to be sold in this sale.
		///
		access(self)
		let queue: Capability<&{FreshmintQueue.Queue}>
		
		/// When moving a claimed NFT into an account, 
		/// the sale will deposit the NFT into the NonFungibleToken.CollectionPublic 
		/// linked at this public path.
		///
		access(all)
		let receiverPath: PublicPath
		
		/// A capability to the receiver that will receive payments from this sale.
		///
		access(all)
		let paymentReceiver: Capability<&{FungibleToken.Receiver}>
		
		/// A dictionary that tracks the number of NFTs claimed per address.
		///
		access(self)
		let claims:{ Address: UInt}
		
		/// An optional limit on the number of NFTs that can be claimed per address.
		///
		access(all)
		var claimLimit: UInt?
		
		/// An optional allowlist used to gate access to this sale.
		///
		access(self)
		var allowlist: Capability<&Allowlist>?
		
		init(id: String, queue: Capability<&{FreshmintQueue.Queue}>, receiverPath: PublicPath, paymentReceiver: Capability<&{FungibleToken.Receiver}>, price: UFix64, claimLimit: UInt?, allowlist: Capability<&Allowlist>?){ 
			self.id = id
			self.price = price
			self.queue = queue
			self.receiverPath = receiverPath
			self.paymentReceiver = paymentReceiver
			
			// Check that payment receiver capability is linked
			self.paymentReceiver.borrow() ?? panic("failed to borrow payment receiver capability")
			
			// Check that queue capability is linked
			let queueRef = self.queue.borrow() ?? panic("failed to borrow queue capability")
			
			// The size of the sale is the initial size of the queue
			self.size = queueRef.remaining()
			self.claims ={} 
			self.claimLimit = claimLimit
			self.allowlist = allowlist
		}
		
		/// setClaimLimit sets the claim limit for this sale.
		///
		/// Pass nil to remove the claim limit from this sale.
		///
		access(all)
		fun setClaimLimit(limit: UInt?){ 
			self.claimLimit = limit
		}
		
		/// setAllowlist sets the allowlist for this sale.
		///
		/// Pass nil to remove the allowlist from this sale.
		///
		access(all)
		fun setAllowlist(allowlist: Capability<&Allowlist>?){ 
			self.allowlist = allowlist
		}
		
		/// getInfo returns a read-only summary of this sale.
		///
		access(all)
		fun getInfo(): SaleInfo{ 
			return SaleInfo(id: self.id, price: self.price, paymentVaultType: self.getPaymentVaultType(), size: self.size, supply: self.getSupply())
		}
		
		/// getPaymentVaultType returns the underlying type of the payment receiver.
		///
		access(all)
		fun getPaymentVaultType(): Type{ 
			return self.borrowPaymentReceiver().getType()
		}
		
		/// getRemainingClaims returns the number of claims remaining for a given address.
		///
		/// This function returns nil if there is no claim limit.
		///
		access(all)
		fun getRemainingClaims(address: Address): UInt?{ 
			if let claimLimit = self.claimLimit{ 
				let claims = self.claims[address] ?? 0
				return claimLimit - claims
			}
			
			// Return nil if there is no claim limit to indicate that 
			// this address has unlimited remaining claims.
			return nil
		}
		
		/// getSupply returns the number of NFTs remaining in this sale.
		///
		access(all)
		fun getSupply(): Int?{ 
			let queueRef = self.queue.borrow() ?? panic("failed to borrow queue capability")
			return queueRef.remaining()
		}
		
		/// borrowPaymentReceiver returns a reference to the
		/// payment receiver for this sale.
		///
		access(all)
		fun borrowPaymentReceiver(): &{FungibleToken.Receiver}{ 
			return self.paymentReceiver.borrow() ?? panic("failed to borrow payment receiver capability")
		}
		
		/// If an allowlist is set, check that the provided address can claim
		/// and decrement their claim counter.
		///
		access(self)
		fun checkAllowlist(address: Address){ 
			if let allowlistCap = self.allowlist{ 
				let allowlist = allowlistCap.borrow() ?? panic("failed to borrow allowlist")
				if let claims = allowlist.getClaims(address: address){ 
					if claims == 0{ 
						panic("address has already consumed all claims")
					}
					
					// Reduce the claim count by one
					allowlist.setClaims(address: address, claims: claims - 1)
				} else{ 
					panic("address is not in the allowlist")
				}
			}
		}
		
		/// The claim function is called by a user to claim an NFT from this sale.
		///
		/// The user will receive the next available NFT in the queue
		/// if they pass a vault with the correct price and,
		/// if an allowlist is set, their address exists in the allowlist.
		///
		/// The NFT is transfered to the provided address at the storage
		/// path defined in self.receiverPath.
		///
		access(all)
		fun claim(payment: @{FungibleToken.Vault}, address: Address){ 
			pre{ 
				payment.balance == self.price:
					"payment vault does not contain requested price"
			}
			self.checkAllowlist(address: address)
			let claims = self.claims[address] ?? 0
			
			// Enforce the claim limit if it is set
			if let claimLimit = self.claimLimit{ 
				assert(claims < claimLimit, message: "reached claim limit")
			}
			self.claims[address] = claims + 1
			let queue = self.queue.borrow() ?? panic("failed to borrow NFT queue")
			let paymentReceiver = self.borrowPaymentReceiver()
			paymentReceiver.deposit(from: <-payment)
			
			// Get the next NFT from the queue
			let nft <- queue.getNextNFT() ?? panic("sale is sold out")
			let nftReceiver = getAccount(address).capabilities.get<&{NonFungibleToken.CollectionPublic}>(self.receiverPath).borrow<&{NonFungibleToken.CollectionPublic}>()!
			emit NFTClaimed(saleUUID: self.uuid, saleID: self.id, saleAddress: self.owner?.address, remainingSupply: queue.remaining(), nftType: nft.getType(), nftID: nft.id)
			nftReceiver.deposit(token: <-nft)
		}
	}
	
	/// An Allowlist holds a set of addresses that 
	/// are pre-approved to claim NFTs from a sale.
	///
	/// Each address can be approved for one or more claims.
	///
	/// A single allowlist can be used by multiple sale instances.
	///
	access(all)
	resource Allowlist{ 
		
		/// Approved addresses are stored in dictionary.
		///
		/// The integer value is the number of NFTs an  
		/// address is entitled to claim.
		///
		access(self)
		let claimsByAddress:{ Address: UInt}
		
		init(){ 
			self.claimsByAddress ={} 
		}
		
		/// setClaims sets the number of claims that an address can make.
		///
		access(all)
		fun setClaims(address: Address, claims: UInt){ 
			self.claimsByAddress[address] = claims
		}
		
		/// getClaims returns the number of claims for an address
		/// or nil if the address is not in the allowlist.
		///
		access(all)
		fun getClaims(address: Address): UInt?{ 
			return self.claimsByAddress[address]
		}
	}
	
	/// makeAllowlistName is a utility function that constructs
	/// an allowlist name with a common prefix.
	///
	access(all)
	fun makeAllowlistName(name: String): String{ 
		return "Allowlist_".concat(name)
	}
	
	access(all)
	fun createEmptySaleCollection(): @SaleCollection{ 
		return <-create SaleCollection()
	}
	
	access(all)
	fun createSale(
		id: String,
		queue: Capability<&{FreshmintQueue.Queue}>,
		receiverPath: PublicPath,
		paymentReceiver: Capability<&{FungibleToken.Receiver}>,
		price: UFix64,
		claimLimit: UInt?,
		allowlist: Capability<&Allowlist>?
	): @Sale{ 
		let sale <-
			create Sale(
				id: id,
				queue: queue,
				receiverPath: receiverPath,
				paymentReceiver: paymentReceiver,
				price: price,
				claimLimit: claimLimit,
				allowlist: allowlist
			)
		emit SaleCreated(
			uuid: sale.uuid,
			id: sale.id,
			price: sale.price,
			paymentVaultType: sale.getPaymentVaultType(),
			size: sale.size
		)
		return <-sale
	}
	
	access(all)
	fun createAllowlist(): @Allowlist{ 
		return <-create Allowlist()
	}
	
	init(){ 
		self.SaleCollectionStoragePath = /storage/FreshmintClaimSaleV2Collection
		self.SaleCollectionPublicPath = /public/FreshmintClaimSaleV2Collection
	}
}
