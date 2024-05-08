import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

/// NFTProviderAggregator
///
/// A general-purpose contract for aggregating multiple NFT providers into a single provider capability
/// conforming to the NonFungibleToken standard.
///
/// There are two types of accounts:
///	- Manager: An account holding an Aggregator resource - any account can create Aggregator resources.
///	- Supplier: An account holding a Supplier resource created using a capability from the parent Aggregator
///	resource.
///
/// The manager has access to the aggregated NFT provider and can add/remove any NFT provider capability.
/// Suppliers can remove only NFT provider capabilities they added themselves.
///
/// Setup steps:
///	1. Create an Aggregator resource, save it in the manager account's storage, and publish a SupplierFactory
///	capability for each designated supplier.
///	2. Claim the SupplierFactory capability, create a Supplier resource, and save it in the supplier account's
///	storage (repeat for each supplier).
///	3. Add a NFT provider capability (repeat as needed for each supplier and each collection) - the
///	transaction may be merged with that of step 2. Only NFT provider capabilities targeting collections of
///	valid NFT type can be added (i.e., the type defined when the Aggregator resource is created).
///
/// Once the setup steps are completed, use the aggregated provider capability to withdraw NFTs scattered across
/// the multiple collections added to the Aggregator resource.
///
/// NFT provider capabilities should be removed when they are not needed anymore. Destroying a Supplier resource
/// removes all the NFT provider capabilities it previously added to the parent Aggregator resource. Destroying
/// an Aggregator resource removes all the resource's NFT provider capabilities and render child Supplier
/// resources inoperable, they should be destroyed too.
///
access(all)
contract NFTProviderAggregator{ 
	
	/// Event emitted when an Aggregator resource is created
	access(all)
	event AggregatorResourceInitialized(nftTypeIdentifier: String)
	
	/// Event emitted when a Supplier resource is created
	access(all)
	event SupplierResourceInitialized(
		nftTypeIdentifier: String,
		aggregatorUUID: UInt64,
		aggregatorAddressAtCreation: Address?
	)
	
	/// Event emitted when a NFT Provider Capability is added
	access(all)
	event NFTProviderCapabilityAdded(
		nftTypeIdentifier: String,
		collectionUUID: UInt64,
		collectionAddressAtInsertion: Address
	)
	
	/// Event emitted when a NFT Provider Capability is removed
	access(all)
	event NFTProviderCapabilityRemoved(nftTypeIdentifier: String, collectionUUID: UInt64)
	
	/// Storage paths for Aggregator and Supplier resources
	access(all)
	let AggregatorStoragePath: StoragePath
	
	access(all)
	let SupplierStoragePath: StoragePath
	
	/// Public paths for Aggregator{SupplierPublic} capabilities
	access(all)
	let SupplierPublicPath: PublicPath
	
	/// Private paths for Aggregator{SupplierFactory}, Aggregator{SupplierAccess},
	/// and Aggregator{NonFungibleToken.Provider} capabilities
	access(all)
	let SupplierFactoryPrivatePath: PrivatePath
	
	access(all)
	let SupplierAccessPrivatePath: PrivatePath
	
	access(all)
	let AggregatedProviderPrivatePath: PrivatePath
	
	/// Interface that a supplier would commonly use for publicly exposing
	/// the Supplier resource's getter functions through a public capability
	///
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
	
	/// Interface that a manager would commonly use for exposing the Aggregator resource's
	/// createSupplier function to each designated supplier through a private capability
	///
	access(all)
	resource interface SupplierFactory{ 
		access(all)
		fun createSupplier(): @Supplier
	}
	
	/// Interface used by a manager for exposing core Aggregator resource's functions to the Supplier
	/// resource through a private capability passed to the Supplier at resource creation time
	///
	access(all)
	resource interface SupplierAccess{ 
		access(contract)
		fun addNFTProviderCapability(
			nftProviderCapability: Capability<
				&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}
			>
		): UInt64
		
		access(contract)
		fun removeNFTProviderCapability(collectionUUID: UInt64)
		
		access(contract)
		fun getIDs(): [UInt64]
		
		access(contract)
		fun getCollectionUUIDs(): [UInt64]
	}
	
	/// Resource saved in the manager's storage to aggregate NFT provider capabilities. Managers can
	/// let designated suppliers create Supplier resources to add and remove NFT provider capabilities.
	///
	access(all)
	resource Aggregator: NonFungibleToken.Provider, SupplierAccess, SupplierFactory{ 
		/// Constant NFT type identifier
		access(self)
		let nftTypeIdentifier: String
		
		/// Constant useBorrowNFTSafe boolean - when true, the Aggregator's withdraw method will use
		/// borrowNFTSafe instead of getIDs to check whether a given NFT ID is present in a collection
		access(self)
		let useBorrowNFTSafe: Bool
		
		/// Constant supplier access capability that is passed to each child Supplier resource
		access(self)
		let supplierAccessCapability: Capability<&Aggregator>
		
		/// Dictionary of supplied NFT provider capabilities
		access(self)
		var nftProviderCapabilities:{ UInt64: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>}
		
		/// Add NFT provider capability (may be called by Supplier or directly by Aggregator)
		access(all)
		fun addNFTProviderCapability(nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>): UInt64{ 
			pre{ 
				self.isNFTProviderCapabilityValid(nftProviderCapability: nftProviderCapability):
					"Invalid NFT provider capability!"
			}
			var collectionUUID = (nftProviderCapability.borrow()!).uuid
			self.nftProviderCapabilities.insert(key: collectionUUID, nftProviderCapability)
			emit NFTProviderCapabilityAdded(nftTypeIdentifier: self.nftTypeIdentifier, collectionUUID: collectionUUID, collectionAddressAtInsertion: nftProviderCapability.address)
			return collectionUUID
		}
		
		/// Remove NFT provider capability; it can be called by Supplier, only for capability they
		/// added, or by Aggregator, for any capability
		///
		access(all)
		fun removeNFTProviderCapability(collectionUUID: UInt64){ 
			pre{ 
				self.nftProviderCapabilities.containsKey(collectionUUID):
					"NFT provider capability does not exist (not added yet or removed by Aggregator)!"
			}
			self.nftProviderCapabilities.remove(key: collectionUUID)
			emit NFTProviderCapabilityRemoved(nftTypeIdentifier: self.nftTypeIdentifier, collectionUUID: collectionUUID)
		}
		
		/// Borrow the provider of an NFT located in one of multiple collections through iterating over each collection
		///
		access(all)
		fun borrowNFTProvider(id: UInt64): &{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}{ 
			for collectionUUID in self.nftProviderCapabilities.keys{ 
				// Check capabilities can still be borrowed since a NFT provider capability may pass the
				// pre-condition checks at the time of being added with the addNFTProviderCapability method but
				// may be unlinked later or the target collection be destroyed.
				if (self.nftProviderCapabilities[collectionUUID]!).check(){ 
					// Retrieve reference to the NFT provider
					let nftProviderRef = (self.nftProviderCapabilities[collectionUUID]!).borrow()!
					// Check NFT provider UUID still matches that of the nftProviderCapabilities dictionary
					assert(nftProviderRef.uuid == collectionUUID, message: "NFT provider capability has invalid collection UUID! Must be removed.")
					// Checks if NFT exists - one of two ways is used depending on the value of useBorrowNFTSafe
					//
					// While the getIDs() method exists in all NFT contracts, the borrowNFTSafe() is a recent
					// addition to the NonFungibleToken standard interface and therefore most NFT contracts don't
					// have an implementation for it yet. Unlike getIDs().contains(), borrowNFTSafe() allows a
					// constant time implementation to check if an NFT exists in a collection without panicking.
					// This is useful for large NFT collections where calling getIDs() may otherwise exceed the
					// computation limit.
					//
					if self.useBorrowNFTSafe && nftProviderRef.borrowNFTSafe(id: id) != nil || !self.useBorrowNFTSafe && nftProviderRef.getIDs().contains(id){ 
						// Check NFT provider capability targets a collection with valid NFT type
						assert(nftProviderRef.getType().identifier == self.nftTypeIdentifier, message: "NFT provider capability targets a collection with invalid NFT type! Must be removed.")
						return nftProviderRef
					}
				}
			}
			panic("missing NFT")
		}
		
		/// Withdraw an NFT located in one of multiple collections through iterating over each collection
		///
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			return <-self.borrowNFTProvider(id: withdrawID).withdraw(withdrawID: withdrawID)
		}
		
		/// Borrow an NFT located in one of multiple collections through iterating over each collection
		///
		access(all)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}{ 
			return self.borrowNFTProvider(id: id).borrowNFT(id)!
		}
		
		/// Create and return a Supplier resource
		///
		/// @param supplierAccessCapability: The capability of the parent Aggregator resource
		/// @param nftTypeIdentifier: The constant NFT type of the parent Aggregator resource
		/// @param aggregatorUUID: The UUID of the parent Aggregator resource
		/// @param aggregatorAddressAtCreation: the address of the account owning the Aggregator resource at creation
		///
		/// @return Supplier resource
		///
		access(all)
		fun createSupplier(): @Supplier{ 
			return <-create Supplier(supplierAccessCapability: self.supplierAccessCapability, nftTypeIdentifier: self.nftTypeIdentifier, aggregatorUUID: self.uuid, aggregatorAddressAtCreation: self.owner?.address)
		}
		
		/// Return an array of the NFT IDs accessible through nftProviderCapabilities
		///
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
					assert(collectionUUID == collectionRef.uuid, message: "NFT provider capability has invalid collection UUID! Must be removed.!")
					let nftIDs = collectionRef.getIDs()
					if nftIDs.length != 0{ 
						// Check NFT provider capability targets a collection with valid NFT type
						assert(collectionRef.getType().identifier == self.nftTypeIdentifier, message: "NFT provider capability targets a collection with invalid NFT type! Must be removed.")
						ids.appendAll(nftIDs)
					}
				}
			}
			return ids
		}
		
		/// Return an array of all the collection UUIDs
		///
		access(all)
		fun getCollectionUUIDs(): [UInt64]{ 
			return self.nftProviderCapabilities.keys
		}
		
		/// Check whether a given NFT provider capability is valid
		///
		access(self)
		view fun isNFTProviderCapabilityValid(nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>): Bool{ 
			let nftProviderRef = nftProviderCapability.borrow() ?? panic("NFT provider couldn't be borrowed! Cannot be added.")
			assert(nftProviderRef.getType().identifier == self.nftTypeIdentifier, message: "NFT provider capability targets a collection with invalid NFT type! Cannot be added.")
			for collectionUUID in self.nftProviderCapabilities.keys{ 
				let _nftProviderRef = (self.nftProviderCapabilities[collectionUUID]!).borrow() ?? panic("NFT provider couldn't be borrowed! Must be removed.")
				if _nftProviderRef.uuid == nftProviderRef.uuid{ 
					panic("NFT provider capability already exists! Cannot be added.")
				}
			}
			return true
		}
		
		/// Initialize fields at Aggregator resource creation
		///
		init(nftTypeIdentifier: String, useBorrowNFTSafe: Bool, supplierAccessCapability: Capability<&Aggregator>){ 
			self.nftProviderCapabilities ={} 
			self.nftTypeIdentifier = nftTypeIdentifier
			self.useBorrowNFTSafe = useBorrowNFTSafe
			self.supplierAccessCapability = supplierAccessCapability
			emit AggregatorResourceInitialized(nftTypeIdentifier: nftTypeIdentifier)
		}
	}
	
	/// Resource generated by a parent Aggregator (held by the manager account) and saved in each of the
	/// supplier accounts' storage, the primary function of which is to allow adding and removing NFT
	/// provider capabilities
	///
	access(all)
	resource Supplier: SupplierPublic{ 
		/// CollectionUUIDs of NFT provider capabilities added by the supplier
		access(self)
		var supplierAddedCollectionUUIDs:{ UInt64: Bool}
		
		/// Constant UUID of the parent Aggregator resource
		access(self)
		let aggregatorUUID: UInt64
		
		/// Constant supplier access capability used to borrow the parent Aggregator resource
		access(self)
		let supplierAccessCapability: Capability<&Aggregator>
		
		/// Borrow a reference to the parent Aggregator resource
		access(self)
		fun borrowAggregator(): &Aggregator{ 
			return self.supplierAccessCapability.borrow()!
		}
		
		/// Add NFT provider capability to parent Aggregator resource
		///
		access(all)
		fun addNFTProviderCapability(nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>){ 
			let collectionUUID = self.borrowAggregator().addNFTProviderCapability(nftProviderCapability: nftProviderCapability)
			self.supplierAddedCollectionUUIDs.insert(key: collectionUUID, true)
		}
		
		/// Remove NFT provider capability from parent Aggregator resource
		/// (can be called only for capabilities added by a given Supplier instance)
		///
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
		///
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.borrowAggregator().getIDs()
		}
		
		/// Return the UUID of linked Aggregator resource
		///
		access(all)
		fun getAggregatorUUID(): UInt64{ 
			return self.aggregatorUUID
		}
		
		/// Return an array of the collection UUIDs added by the supplier
		///
		access(all)
		fun getSupplierAddedCollectionUUIDs(): [UInt64]{ 
			return self.supplierAddedCollectionUUIDs.keys
		}
		
		/// Return an array of all the collection UUIDs for capabilities currently present in the parent
		/// manager
		///
		access(all)
		fun getCollectionUUIDs(): [UInt64]{ 
			return self.borrowAggregator().getCollectionUUIDs()
		}
		
		/// Remove supplied NFT provider capabilities when the Supplier is destroyed
		///
		/// Initialize fields at Supplier resource creation
		///
		init(supplierAccessCapability: Capability<&Aggregator>, nftTypeIdentifier: String, aggregatorUUID: UInt64, aggregatorAddressAtCreation: Address?){ 
			pre{ 
				supplierAccessCapability.borrow() != nil:
					"Must pass a Aggregator capability"
			}
			self.aggregatorUUID = aggregatorUUID
			self.supplierAccessCapability = supplierAccessCapability
			self.supplierAddedCollectionUUIDs ={} 
			emit SupplierResourceInitialized(nftTypeIdentifier: nftTypeIdentifier, aggregatorUUID: aggregatorUUID, aggregatorAddressAtCreation: aggregatorAddressAtCreation)
		}
	}
	
	/// Create and return an Aggregator resource - anyone can call this function.
	///
	/// @param nftTypeIdentifier: The type of NFTs that will be valid for the NFT providers added to the Aggregator resource.
	/// @param useBorrowNFTSafe: A bool to choose whether to call borrowNFTSafe or getIDs().contains() when
	///	checking if a NFT exists.
	/// @param supplierAccessCapability: A capability targeting the storage path where the new Aggregator resource
	///	will be saved at right after being created.
	///
	/// @return Aggregator resource
	///
	access(all)
	fun createAggregator(
		nftTypeIdentifier: String,
		useBorrowNFTSafe: Bool,
		supplierAccessCapability: Capability<&Aggregator>
	): @Aggregator{ 
		return <-create Aggregator(
			nftTypeIdentifier: nftTypeIdentifier,
			useBorrowNFTSafe: useBorrowNFTSafe,
			supplierAccessCapability: supplierAccessCapability
		)
	}
	
	/// Initialize fields at contract creation
	///
	init(){ 
		/// Set storage paths
		self.AggregatorStoragePath = /storage/nftProviderAggregator
		self.SupplierStoragePath = /storage/nftProviderSupplier
		
		/// Set private paths
		self.SupplierFactoryPrivatePath = /private/nftProviderSupplierFactory
		self.SupplierAccessPrivatePath = /private/nftProviderSupplierAccess
		self.AggregatedProviderPrivatePath = /private/aggregatedNFTProvider
		
		/// Set public path
		self.SupplierPublicPath = /public/nftProviderSupplier
	}
}
