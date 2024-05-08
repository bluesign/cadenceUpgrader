import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

/// NFTProviderAggregator
///
/// A general-purpose contract for aggregating multiple NFT providers into a single provider capability.
///
/// There are two types of accounts:
///	- Manager: An account holding an Aggregator resource - any account can create Aggregator resources.
///	- Supplier: An account holding a Supplier resource created by a parent Aggregator resource.
///
/// Setup steps:
///	 1. Create an Aggregator resource and save it in the manager account's storage
///	 2. Create one or more Supplier resources and save them in each supplier account's storage
///	 3. Add NFT provider capabilities
///
/// Once the setup steps are completed, use the aggregated provider capability as in the
/// transfer_from_aggregated_provider.cdc transaction to withdraw NFTs scattered across the multiple
/// collections added to the Aggregator resource.
///
/// NFT provider capabilities should be removed when they are not needed anymore. If an Aggregator resource
/// is destroyed, the NFT provider capabilities it contains are removed. The child Supplier resources become
/// inoperable and should be destroyed too.
///
/// A given NFT provider capability can be removed either by the supplier that previously added it or by the
/// manager holding the parent Aggregator resource.
///
/// Only NFT provider capabilities targeting non-empty collections of valid NFT type can be added to the
/// Aggregator resource (i.e., the type defined when the Aggregator resource was created).
///
access(all)
contract NFTProviderAggregator{ 
	
	/// Events for resource creation and addition/removal of a NFT provider capability
	access(all)
	event AggregatorResourceInitialized(nftType: Type)
	
	access(all)
	event SupplierResourceInitialized(
		nftType: Type,
		aggregatorUUID: UInt64,
		aggregatorAddressAtCreation: Address?
	)
	
	access(all)
	event NFTProviderCapabilityAdded(
		nftType: Type,
		collectionUUID: UInt64,
		collectionAddressAtInsertion: Address
	)
	
	access(all)
	event NFTProviderCapabilityRemoved(nftType: Type, collectionUUID: UInt64)
	
	/// Storage locations for Aggregator and Supplier
	access(all)
	let AggregatorStoragePath: StoragePath
	
	access(all)
	let SupplierStoragePath: StoragePath
	
	/// Private locations for Aggregator{SupplierAccess} and
	/// Aggregator{NonFungibleToken.Provider}
	/// Note: Aggregator{NonFungibleToken.Provider} acts as compositve NFT provider.
	access(all)
	let AggregatorSupplierAccessPrivatePath: PrivatePath
	
	access(all)
	let AggregatedProviderPrivatePath: PrivatePath
	
	/// Public location for Supplier
	access(all)
	let SupplierPublicPath: PublicPath
	
	/// Interface that an account would commonly publish for their Supplier resource
	access(all)
	resource interface SupplierPublic{ 
		access(all)
		fun getAggregatorUUID(): UInt64
		
		access(all)
		fun getSupplierAddedCollectionUUIDs(): [UInt64]
		
		access(all)
		fun getCollectionUUIDs(): [UInt64]
		
		access(all)
		fun getIDs(): [UInt64]
	}
	
	/// Interface used to restrict the Aggregator's capability provided to Supplier at
	/// resource creation time
	access(all)
	resource interface SupplierAccess{ 
		access(all)
		fun addNFTProviderCapability(
			nftProviderCapability: Capability<
				&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}
			>
		): UInt64
		
		access(all)
		fun removeNFTProviderCapability(collectionUUID: UInt64)
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun getCollectionUUIDs(): [UInt64]
	}
	
	/// Resource saved in the manager account's storage to offer a set of supplier accounts the ability to
	/// expose providers for a given NFT collection. It does that by allowing the creation of
	/// Supplier resources to be deposited in each of the supplier accounts' storage.
	access(all)
	resource Aggregator: NonFungibleToken.Provider, SupplierAccess{ 
		/// Hold the constant NFT type
		access(self)
		let nftType: Type
		
		/// Hold the constant useBorrowNFTSafe type - see usage in withdraw function.
		/// Note: If useBorrowNFTSafe is true, Aggregator's withdraw method will use borrowNFTSafe
		/// instead of getIDs to check whether a given NFT ID is present in a collection or not.
		access(self)
		let useBorrowNFTSafe: Bool
		
		/// Hold supplied NFT provider capabilities
		access(self)
		var nftProviderCapabilities:{ UInt64: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>}
		
		/// Add NFT provider capability (may be called by Supplier or directly by Aggregator)
		access(all)
		fun addNFTProviderCapability(nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>): UInt64{ 
			pre{ 
				self.isNFTProviderCapabilityValid(nftProviderCapability: nftProviderCapability):
					"NFT provider capability not valid!"
			}
			var collectionUUID = (nftProviderCapability.borrow()!).uuid
			self.nftProviderCapabilities.insert(key: collectionUUID, nftProviderCapability)
			emit NFTProviderCapabilityAdded(nftType: self.nftType, collectionUUID: collectionUUID, collectionAddressAtInsertion: nftProviderCapability.address)
			return collectionUUID
		}
		
		/// Remove NFT provider capability; it can be called by Supplier, only for capability they
		/// added, or by Aggregator, for any capability
		access(all)
		fun removeNFTProviderCapability(collectionUUID: UInt64){ 
			pre{ 
				self.nftProviderCapabilities.containsKey(collectionUUID):
					"NFT provider capability does not exist (not added yet or removed by Aggregator)!"
			}
			self.nftProviderCapabilities.remove(key: collectionUUID)
			emit NFTProviderCapabilityRemoved(nftType: self.nftType, collectionUUID: collectionUUID)
		}
		
		/// Withdraw an NFT located in one of multiple collections through iterating over each collection
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			for collectionUUID in self.nftProviderCapabilities.keys{ 
				// Check capabilities can still be borrowed since a NFT provider capability may pass the
				// pre-condition checks at the time of being added with the addNFTProviderCapability method but
				// may be unlinked later or the target collection be destroyed.
				if (self.nftProviderCapabilities[collectionUUID]!).check(){ 
					// Retrieve reference to the NFT provider
					let nftProviderRef = (self.nftProviderCapabilities[collectionUUID]!).borrow()!
					// Check UUID still matches that of the nftProviderCapabilities dictionary
					assert(collectionUUID == nftProviderRef.uuid, message: "Invalid collection UUID!")
					// Checks if NFT with ID = withdrawID exists - one of two ways is used depending on
					// the value of useBorrowNFTSafe
					//
					// While the getIDs() method exists in all NFT contracts, the borrowNFTSafe() is a recent
					// addition to the NonFungibleToken standard interface and therefore most NFT contracts don't
					// have an implementation for it yet. Unlike getIDs().contains(), borrowNFTSafe() allows a
					// constant time implementation to check if an NFT exists in a collection without panicking.
					// This is useful for large NFT collections where calling getIDs() may otherwise exceed the
					// computation limit.
					//
					if self.useBorrowNFTSafe{ 
						if let nftRef = nftProviderRef.borrowNFTSafe(id: withdrawID){ 
							// Check NFT provider capability targets a collection with valid NFT type
							assert(nftRef.isInstance(self.nftType), message: "NFT provider capability targets a collection with invalid NFT type!")
							return <-nftProviderRef.withdraw(withdrawID: withdrawID)
						}
					} else if nftProviderRef.getIDs().contains(withdrawID){ 
						// Check NFT provider capability targets a collection with valid NFT type
						assert(nftProviderRef.borrowNFT(withdrawID).isInstance(self.nftType), message: "NFT provider capability targets a collection with invalid NFT type!")
						return <-nftProviderRef.withdraw(withdrawID: withdrawID)
					}
				}
			}
			panic("missing NFT")
		}
		
		/// Create and return a Supplier resource
		access(all)
		fun createSupplier(aggregatorCapability: Capability<&Aggregator>): @Supplier{ 
			return <-create Supplier(aggregatorCapability: aggregatorCapability, nftType: self.nftType, aggregatorUUID: self.uuid, aggregatorAddressAtCreation: self.owner?.address)
		}
		
		/// Return an array of the NFT IDs accessible through nftProviderCapabilities
		access(all)
		fun getIDs(): [UInt64]{ 
			let ids: [UInt64] = []
			for collectionUUID in self.nftProviderCapabilities.keys{ 
				// Check capability can still be borrowed since a NFT provider capability may pass the
				// pre-condition checks at the time of being added with the addNFTProviderCapability method
				// but may be unlinked later or the target collection be destroyed.
				if (self.nftProviderCapabilities[collectionUUID]!).check(){ 
					let collectionRef = (self.nftProviderCapabilities[collectionUUID]!).borrow()! as! &{NonFungibleToken.CollectionPublic}
					// Check UUID still matches that of the nftProviderCapabilities dictionary
					assert(collectionUUID == collectionRef.uuid, message: "Invalid collection UUID!")
					let nftIDs = collectionRef.getIDs()
					if nftIDs.length != 0{ 
						// Check NFT provider capability targets a collection with valid NFT type
						assert(collectionRef.borrowNFT(nftIDs[0]).isInstance(self.nftType), message: "NFT provider capability targets a collection with invalid NFT type!")
						ids.appendAll(nftIDs)
					}
				}
			}
			return ids
		}
		
		/// Return an array of all the collection UUIDs
		access(all)
		fun getCollectionUUIDs(): [UInt64]{ 
			return self.nftProviderCapabilities.keys
		}
		
		/// Internal utility function to check whether a given NFT provider capability is valid
		access(self)
		view fun isNFTProviderCapabilityValid(nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>): Bool{ 
			let nftProviderRef = nftProviderCapability.borrow() ?? panic("no such cap")
			if !self.useBorrowNFTSafe{ 
				let nftIDs = nftProviderRef.getIDs()
				if nftIDs.length == 0{ 
					panic("NFT provider capability targets an empty collection!")
				}
				if !nftProviderRef.borrowNFT(nftIDs[0]).isInstance(self.nftType){ 
					panic("NFT provider capability targets a collection with invalid NFT type!")
				}
			}
			for collectionUUID in self.nftProviderCapabilities.keys{ 
				let _nftProviderRef = (self.nftProviderCapabilities[collectionUUID]!).borrow() ?? panic("no such cap")
				if _nftProviderRef.uuid == nftProviderRef.uuid{ 
					panic("NFT provider capability already exists!")
				}
			}
			return true
		}
		
		/// Initialize fields at Aggregator resource creation
		init(nftType: Type, useBorrowNFTSafe: Bool){ 
			self.nftType = nftType
			self.useBorrowNFTSafe = useBorrowNFTSafe
			self.nftProviderCapabilities ={} 
			emit AggregatorResourceInitialized(nftType: nftType)
		}
	}
	
	/// Resource created by a parent Aggregator (held by the manager account) and saved in each of the
	/// supplier accounts' storage, the primary function of which is to allow adding and removing NFT
	/// provider capabilities
	access(all)
	resource Supplier: SupplierPublic{ 
		/// Hold collectionUUIDs of NFT provider capabilities added by the supplier
		access(self)
		var supplierAddedCollectionUUIDs:{ UInt64: Bool}
		
		/// Hold the constant UUID of the parent delegation manager
		access(self)
		let aggregatorUUID: UInt64
		
		/// Hold the constant capability used to access Aggregator
		access(self)
		let aggregatorCapability: Capability<&Aggregator>
		
		/// Utility function to borrow a reference to Aggregator
		access(self)
		fun borrowAggregator(): &Aggregator{ 
			return self.aggregatorCapability.borrow()!
		}
		
		/// Add NFT provider capability to parent Aggregator resource
		access(all)
		fun addNFTProviderCapability(nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>){ 
			let collectionUUID = self.borrowAggregator().addNFTProviderCapability(nftProviderCapability: nftProviderCapability)
			self.supplierAddedCollectionUUIDs.insert(key: collectionUUID, true)
		}
		
		/// Remove NFT provider capability from parent Aggregator resource
		/// (can be called only for capabilities added by a given Supplier instance
		access(all)
		fun removeNFTProviderCapability(collectionUUID: UInt64){ 
			pre{ 
				self.supplierAddedCollectionUUIDs.containsKey(collectionUUID):
					"Collection UUID does not exist in added collection UUIDs!"
			}
			self.borrowAggregator().removeNFTProviderCapability(collectionUUID: collectionUUID)
			self.supplierAddedCollectionUUIDs.remove(key: collectionUUID)
		}
		
		/// Return an array of the NFT IDs accessible through the Aggregator's provider capabilities
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.borrowAggregator().getIDs()
		}
		
		/// Return the UUID of linked Aggregator resource
		access(all)
		fun getAggregatorUUID(): UInt64{ 
			return self.aggregatorUUID
		}
		
		/// Return an array of the collection UUIDs added by the supplier
		access(all)
		fun getSupplierAddedCollectionUUIDs(): [UInt64]{ 
			return self.supplierAddedCollectionUUIDs.keys
		}
		
		/// Return an array of all the collection UUIDs for capabilities currently present in the parent
		/// manager
		access(all)
		fun getCollectionUUIDs(): [UInt64]{ 
			return self.borrowAggregator().getCollectionUUIDs()
		}
		
		/// Initialize fields at Supplier resource creation
		init(aggregatorCapability: Capability<&Aggregator>, nftType: Type, aggregatorUUID: UInt64, aggregatorAddressAtCreation: Address?){ 
			pre{ 
				aggregatorCapability.borrow() != nil:
					"Must pass a Aggregator capability"
			}
			self.aggregatorUUID = aggregatorUUID
			self.aggregatorCapability = aggregatorCapability
			self.supplierAddedCollectionUUIDs ={} 
			emit SupplierResourceInitialized(nftType: nftType, aggregatorUUID: aggregatorUUID, aggregatorAddressAtCreation: aggregatorAddressAtCreation)
		}
	}
	
	/// Create and return a Aggregator resource for a particular NFT type and with or without
	/// the ability to call borrowNFTSafe instead of getIDs().contains() to check wether a NFT exists
	access(all)
	fun createAggregator(nftType: Type, useBorrowNFTSafe: Bool): @Aggregator{ 
		return <-create Aggregator(nftType: nftType, useBorrowNFTSafe: useBorrowNFTSafe)
	}
	
	/// Initialize fields at contract creation
	init(){ 
		/// Set storage paths
		self.AggregatorStoragePath = /storage/aggregator
		self.SupplierStoragePath = /storage/supplier
		
		/// Set private paths
		self.AggregatorSupplierAccessPrivatePath = /private/aggregator
		self.AggregatedProviderPrivatePath = /private/aggregatedProvider
		
		/// Set public path
		self.SupplierPublicPath = /public/supplier
	}
}
