import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

/// FreshmintClaimSale provides functionality to operate a claim-style sale of NFTs.
///
/// In a claim sale, users can claim NFTs from a collection
/// for a fee. All NFTs in a sale are sold for the same price.
///
/// Unlike in the NFTStorefront contract, a user cannot purchase a specific NFT by ID.
/// On each claim, the user receives the next available NFT in the collection.
/// 
access(all)
contract FreshmintClaimSale{ 
	
	/// The SaleCreated event is emitted when a new sale is created.
	///
	access(all)
	event SaleCreated(uuid: UInt64, id: String, price: UFix64, paymentVaultType: Type, size: Int)
	
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
		remainingSupply: Int,
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
		fun remove(saleID: String): @Sale{ 
			let sale <- self.sales.remove(key: saleID) ?? panic("sale does not exist")
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
		let size: Int
		
		access(all)
		let supply: Int
		
		init(id: String, price: UFix64, paymentVaultType: Type, size: Int, supply: Int){ 
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
		let size: Int
		
		access(all)
		fun getPaymentVaultType(): Type
		
		access(all)
		fun getSupply(): Int
		
		access(all)
		fun getInfo(): SaleInfo
		
		access(all)
		fun claim(payment: @{FungibleToken.Vault}, address: Address)
		
		access(all)
		fun borrowPaymentReceiver(): &{FungibleToken.Receiver}
		
		access(all)
		fun borrowCollection(): &{
			NonFungibleToken.CollectionPublic,
			ViewResolver.ResolverCollection
		}
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
		let size: Int
		
		/// A capability to the underlying base NFT collection
		/// that will store the claimable NFTs.
		///
		access(self)
		let collection: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection}>
		
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
		
		/// An optional allowlist used to gate access to this sale.
		///
		access(self)
		let allowlist: Capability<&Allowlist>?
		
		init(id: String, collection: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection}>, receiverPath: PublicPath, paymentReceiver: Capability<&{FungibleToken.Receiver}>, price: UFix64, allowlist: Capability<&Allowlist>?){ 
			self.id = id
			self.price = price
			self.collection = collection
			self.receiverPath = receiverPath
			self.paymentReceiver = paymentReceiver
			
			// Check that payment receiver capability is linked
			self.paymentReceiver.borrow() ?? panic("init: failed to borrow payment receiver capability")
			
			// Check that collection capability is linked
			let collectionRef = self.collection.borrow() ?? panic("init: failed to borrow collection capability")
			
			// The size of the sale is the initial size of the collection
			self.size = collectionRef.getIDs().length
			self.allowlist = allowlist
			if let allowlist = self.allowlist{ 
				allowlist.borrow() ?? panic("init: failed to borrow allowlist capability")
			}
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
		
		/// getSupply returns the number of NFTs remaining in this sale.
		///
		access(all)
		fun getSupply(): Int{ 
			return self.borrowCollection().getIDs().length
		}
		
		/// borrowPaymentReceiver returns a reference to the
		/// payment receiver for this sale.
		///
		access(all)
		fun borrowPaymentReceiver(): &{FungibleToken.Receiver}{ 
			return self.paymentReceiver.borrow() ?? panic("failed to borrow payment receiver capability")
		}
		
		/// borrowCollection returns a public reference to the
		/// underlying collection for this sale.
		///
		/// Callers can use this to read information about NFTs in this sale.
		///
		access(all)
		fun borrowCollection(): &{NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection}{ 
			let collection = self.collection.borrow() ?? panic("failed to borrow sale collection")
			return collection as! &{NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection}
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
					allowlist.consumeClaim(address: address)
				} else{ 
					panic("address is not in the allowlist")
				}
			}
		}
		
		/// The claim function is called by a user to claim an NFT from this sale.
		///
		/// The user will receive the next available NFT in the collection
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
			let collection = self.collection.borrow() ?? panic("failed to borrow sale collection")
			let ids = collection.getIDs()
			if ids.length == 0{ 
				panic("Sale is sold out")
			}
			let paymentReceiver = self.borrowPaymentReceiver()
			paymentReceiver.deposit(from: <-payment)
			
			// Remove the next NFT from the collection.
			let nextID = ids[0]
			let nft <- collection.withdraw(withdrawID: nextID)
			let nftReceiver = getAccount(address).capabilities.get<&{NonFungibleToken.CollectionPublic}>(self.receiverPath).borrow<&{NonFungibleToken.CollectionPublic}>()!
			let remainingSupply = ids.length - 1
			emit NFTClaimed(saleUUID: self.uuid, saleID: self.id, saleAddress: self.owner?.address, remainingSupply: remainingSupply, nftType: nft.getType(), nftID: nft.id)
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
		
		/// consumeClaim is called when a user exercises one of their claims.
		///
		/// This function returns true if the address can claim an NFT.
		/// It returns false is the address is not in the allowlist or has
		/// excercised all of its claims.
		///
		/// Each call to consumeClaim decrements the address's claim
		/// count by one.
		///
		access(all)
		fun consumeClaim(address: Address){ 
			if let claims = self.claimsByAddress[address]{ 
				if claims != 0{ 
					self.claimsByAddress[address] = claims - 1
				}
			}
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
		collection: Capability<
			&{
				NonFungibleToken.Provider,
				NonFungibleToken.CollectionPublic,
				ViewResolver.ResolverCollection
			}
		>,
		receiverPath: PublicPath,
		paymentReceiver: Capability<&{FungibleToken.Receiver}>,
		price: UFix64,
		allowlist: Capability<&Allowlist>?
	): @Sale{ 
		let sale <-
			create Sale(
				id: id,
				collection: collection,
				receiverPath: receiverPath,
				paymentReceiver: paymentReceiver,
				price: price,
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
		self.SaleCollectionStoragePath = /storage/FreshmintClaimSaleCollection
		self.SaleCollectionPublicPath = /public/FreshmintClaimSaleCollection
	}
}
