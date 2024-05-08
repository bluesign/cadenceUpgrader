/*
NFTRegistry

Niftory NFTs should ideally be functionally the same. This would allow
other applications to refer to any Niftory NFT without having to know about
the properties of any individual NFT project. For example, a developer should
not be required to import code from a specific NFT project just to get the
path of where a collection should be found in a users account.

To make this possible, this NFTRegistry associates a single String identifier
to struct of metadata required for the type of agnostic access described above.
This includes

- Paths of NonFungibleToken.Collection
- Paths of the NFT project's Manager
- Paths of the MutableSetManager
- Paths of the MetadataViewManager

*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import MutableMetadataSetManager from "./MutableMetadataSetManager.cdc"

import MetadataViewsManager from "./MetadataViewsManager.cdc"

import NiftoryNonFungibleToken from "./NiftoryNonFungibleToken.cdc"

access(all)
contract NiftoryNFTRegistry{ 
	
	// ========================================================================
	// Constants
	// ========================================================================
	
	// Suggested paths where this Registry could be stored
	access(all)
	let PUBLIC_PATH: PublicPath
	
	access(all)
	let PRIVATE_PATH: PrivatePath
	
	access(all)
	let STORAGE_PATH: StoragePath
	
	// Suggested RegistryItem path suffixes
	access(all)
	let NFT_COLLECTION_PATH_SUFFIX: String
	
	access(all)
	let NFT_MANAGER_PATH_SUFFIX: String
	
	access(all)
	let SET_MANAGER_PATH_SUFFIX: String
	
	access(all)
	let METADATA_VIEWS_MANAGER_PATH_SUFFIX: String
	
	// ========================================================================
	// RegistryItem
	// ========================================================================
	// Struct to co-locate Path related metadata for a stored resource
	access(all)
	struct Paths{ 
		
		// Public path of capability
		access(all)
		let public: PublicPath
		
		// Private path of capability
		access(all)
		let private: PrivatePath
		
		// Storage path of resource
		access(all)
		let storage: StoragePath
		
		init(public: PublicPath, private: PrivatePath, storage: StoragePath){ 
			self.public = public
			self.private = private
			self.storage = storage
		}
	}
	
	access(all)
	struct StoredResource{ 
		
		// Account where resource is stored
		access(all)
		let account: Address
		
		// Relevant paths of stored resource
		access(all)
		let paths: Paths
		
		init(account: Address, paths: Paths){ 
			self.account = account
			self.paths = paths
		}
	}
	
	access(all)
	struct Record{ 
		
		// Address of the actual contract
		access(all)
		let contractAddress: Address
		
		// NFT collection's standard paths
		access(all)
		let collectionPaths: Paths
		
		// NFT's Manager path metadata
		access(all)
		let nftManager: StoredResource
		
		// MutableMetadataSetManager path metadata
		access(all)
		let setManager: StoredResource
		
		// MetadataViewsManager path metadata
		access(all)
		let metadataViewsManager: StoredResource
		
		init(
			contractAddress: Address,
			collectionPaths: Paths,
			nftManager: StoredResource,
			setManager: StoredResource,
			metadataViewsManager: StoredResource
		){ 
			self.contractAddress = contractAddress
			self.collectionPaths = collectionPaths
			self.nftManager = nftManager
			self.setManager = setManager
			self.metadataViewsManager = metadataViewsManager
		}
	}
	
	// ========================================================================
	// Registry
	// ========================================================================
	access(all)
	resource interface Public{ 
		
		// Return all entries from the registry
		access(all)
		fun all():{ String: Record}
		
		// Return information for a particular brand in the registry
		access(all)
		fun infoFor(_ brand: String): Record
	}
	
	access(all)
	resource interface Private{ 
		
		// Get a modifiable ref of the underlying registry
		access(all)
		fun _auth(): &{String: Record}
		
		// Register a new brand
		access(all)
		fun register(brand: String, entry: Record)
		
		// Deregister an existing brand
		access(all)
		fun deregister(_ brand: String)
	}
	
	access(all)
	resource Registry: Public, Private{ 
		
		// ========================================================================
		// Attributes
		// ========================================================================
		
		// The registry is stored as a simple String -> RegistryItem map, so the
		// admin here must be careful to keep track of the keys present
		access(self)
		let _registry:{ String: Record}
		
		// ========================================================================
		// Public
		// ========================================================================
		access(all)
		fun all():{ String: Record}{ 
			return self._registry
		}
		
		access(all)
		fun infoFor(_ brand: String): Record{ 
			pre{ 
				self._registry.containsKey(brand):
					"NFT ".concat(brand).concat(" is not registered")
			}
			return self._registry[brand]!
		}
		
		// ========================================================================
		// Private
		// ========================================================================
		access(all)
		fun _auth(): &{String: Record}{ 
			return &self._registry as &{String: Record}
		}
		
		access(all)
		fun register(brand: String, entry: Record){ 
			self._registry[brand] = entry
		}
		
		access(all)
		fun deregister(_ brand: String){ 
			pre{ 
				self._registry.containsKey(brand):
					"NFT ".concat(brand).concat(" is not registered")
			}
			self._registry.remove(key: brand)
		}
		
		// ========================================================================
		// init/destroy
		// ========================================================================
		init(){ 
			self._registry ={} 
		}
	}
	
	// ========================================================================
	// Contract functions
	// ========================================================================
	// Create a new Registry
	access(all)
	fun _create(): @Registry{ 
		return <-create Registry()
	}
	
	// Helper to generate a Paths struct with common public/private/storage paths
	access(all)
	fun generatePaths(prefix: String, suffix: String): Paths{ 
		let public = PublicPath(identifier: prefix.concat(suffix))!
		let private = PrivatePath(identifier: prefix.concat(suffix))!
		let storage = StoragePath(identifier: prefix.concat(suffix))!
		return Paths(public: public, private: private, storage: storage)
	}
	
	// Generate collection paths
	access(all)
	fun generateCollectionPaths(project: String): Paths{ 
		return self.generatePaths(prefix: project, suffix: self.NFT_COLLECTION_PATH_SUFFIX)
	}
	
	// Generate NFT manager paths
	access(all)
	fun generateNFTManagerPaths(project: String): Paths{ 
		return self.generatePaths(prefix: project, suffix: self.NFT_MANAGER_PATH_SUFFIX)
	}
	
	// Generate MutableMetadataSetManager paths
	access(all)
	fun generateSetManagerPaths(project: String): Paths{ 
		return self.generatePaths(prefix: project, suffix: self.SET_MANAGER_PATH_SUFFIX)
	}
	
	// Generate MetadataViewsManager paths
	access(all)
	fun generateMetadataViewsManagerPaths(project: String): Paths{ 
		return self.generatePaths(prefix: project, suffix: self.METADATA_VIEWS_MANAGER_PATH_SUFFIX)
	}
	
	// Default way to construct a RegistryItem, using suggested contract suffixes
	access(all)
	fun generateRecordFull(
		contractAddress: Address,
		nftManagerAddress: Address,
		setManagerAddress: Address,
		metadataViewsManagerAddress: Address,
		project: String
	): Record{ 
		let collectionPaths = self.generateCollectionPaths(project: project)
		let nftManager =
			StoredResource(
				account: nftManagerAddress,
				paths: self.generateNFTManagerPaths(project: project)
			)
		let setManager =
			StoredResource(
				account: setManagerAddress,
				paths: self.generateSetManagerPaths(project: project)
			)
		let metadataViewsManager =
			StoredResource(
				account: metadataViewsManagerAddress,
				paths: self.generateMetadataViewsManagerPaths(project: project)
			)
		return Record(
			contractAddress: contractAddress,
			collectionPaths: collectionPaths,
			nftManager: nftManager,
			setManager: setManager,
			metadataViewsManager: metadataViewsManager
		)
	}
	
	// Default way to construct a RegistryItem, using suggested contract suffixes
	access(all)
	fun generateRecord(account: Address, project: String): Record{ 
		return self.generateRecordFull(
			contractAddress: account,
			nftManagerAddress: account,
			setManagerAddress: account,
			metadataViewsManagerAddress: account,
			project: project
		)
	}
	
	// Nicely formatted error for a resource not found that's listed in the
	// registry
	access(all)
	fun _notFoundError(_ registryAddress: Address, _ brand: String, _ entity: String): String{ 
		return entity.concat(" not found for registry at ").concat(registryAddress.toString())
			.concat(" for brand ").concat(brand).concat(".")
	}
	
	// Get a registry record for a registry address and brand
	access(all)
	fun getRegistryRecord(_ registryAddress: Address, _ brand: String): Record{ 
		let registry =
			getAccount(registryAddress).capabilities.get<&{Public}>(self.PUBLIC_PATH).borrow()
			?? panic(self._notFoundError(registryAddress, brand, "Registry Record"))
		return registry.infoFor(brand)
	}
	
	// Get the collection paths for a registry address and brand
	access(all)
	fun getCollectionPaths(_ registryAddress: Address, _ brand: String): Paths{ 
		let record = self.getRegistryRecord(registryAddress, brand)
		return record.collectionPaths
	}
	
	// Get the NFT Manager for a registry address and brand
	access(all)
	fun getNFTManagerPublic(_ registryAddress: Address, _ brand: String): &{
		NiftoryNonFungibleToken.ManagerPublic
	}{ 
		let record = self.getRegistryRecord(registryAddress, brand)
		let manager =
			getAccount(record.nftManager.account).capabilities.get<
				&{NiftoryNonFungibleToken.ManagerPublic}
			>(record.nftManager.paths.public)
		return manager.borrow() ?? panic(self._notFoundError(registryAddress, brand, "NFT Manager"))
	}
	
	// Get the MutableMetadataSetManager for a registry address and brand
	access(all)
	fun getSetManagerPublic(
		_ registryAddress: Address,
		_ brand: String
	): &MutableMetadataSetManager.Manager{ 
		let record = self.getRegistryRecord(registryAddress, brand)
		let manager =
			getAccount(record.setManager.account).capabilities.get<
				&MutableMetadataSetManager.Manager
			>(record.setManager.paths.public)
		return manager.borrow()
		?? panic(self._notFoundError(registryAddress, brand, "MutableMetadataSetManager"))
	}
	
	// Get the MetadataViewsManager for a registry address and brand
	access(all)
	fun getMetadataViewsManagerPublic(
		_ registryAddress: Address,
		_ brand: String
	): &MetadataViewsManager.Manager{ 
		let record = self.getRegistryRecord(registryAddress, brand)
		let manager =
			getAccount(record.metadataViewsManager.account).capabilities.get<
				&MetadataViewsManager.Manager
			>(record.metadataViewsManager.paths.public)
		return manager.borrow()
		?? panic(self._notFoundError(registryAddress, brand, "MetadataViewsManager"))
	}
	
	// Get NFTCollectionData for a registry address and brand
	access(all)
	fun buildNFTCollectionData(
		_ registryAddress: Address,
		_ brand: String,
		_ createEmptyCollection: fun (): @{NonFungibleToken.Collection}
	): MetadataViews.NFTCollectionData{ 
		let record = self.getRegistryRecord(registryAddress, brand)
		let paths = record.collectionPaths
		return MetadataViews.NFTCollectionData(
			storagePath: paths.storage,
			publicPath: paths.public,
			publicCollection: Type<
				&{NonFungibleToken.CollectionPublic, NiftoryNonFungibleToken.CollectionPublic}
			>(),
			publicLinkedType: Type<
				&{
					NonFungibleToken.Receiver,
					NonFungibleToken.CollectionPublic,
					ViewResolver.ResolverCollection,
					NiftoryNonFungibleToken.CollectionPublic
				}
			>(),
			createEmptyCollectionFunction: createEmptyCollection
		)
	}
	
	// Initialize contract constants
	init(){ 
		self.PUBLIC_PATH = /public/niftorynftregistry
		self.PRIVATE_PATH = /private/niftorynftregistry
		self.STORAGE_PATH = /storage/niftorynftregistry
		self.NFT_COLLECTION_PATH_SUFFIX = "_nft_collection"
		self.NFT_MANAGER_PATH_SUFFIX = "_nft_manager"
		self.SET_MANAGER_PATH_SUFFIX = "_set_manager"
		self.METADATA_VIEWS_MANAGER_PATH_SUFFIX = "_metadata_views_manager"
	}
}
