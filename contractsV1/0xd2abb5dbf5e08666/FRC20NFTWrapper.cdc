/**
> Author: FIXeS World <https://fixes.world/>

# FRC20NFTWrapper

TODO: Add description

*/

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import Fixes from "./Fixes.cdc"

import FixesWrappedNFT from "./FixesWrappedNFT.cdc"

import FRC20Indexer from "./FRC20Indexer.cdc"

import StringUtils from "./../../standardsV1/StringUtils.cdc"

import NFTCatalog from "./../../standardsV1/NFTCatalog.cdc"

access(all)
contract FRC20NFTWrapper{ 
	
	/// The event that is emitted when the contract is created
	access(all)
	event ContractInitialized()
	
	/// The event that is emitted when the internal flow vault is donated to
	access(all)
	event InternalFlowVaultDonated(amount: UFix64)
	
	/// The event that is emitted when a new Wrapper is created
	access(all)
	event WrapperCreated()
	
	/// The event that is emitted when the wrapper options is updated
	access(all)
	event WrapperOptionsUpdated(wrapper: Address, key: String)
	
	/// The event that is emitted when the whitelist is updated
	access(all)
	event AuthorizedWhitelistUpdated(addr: Address, isAuthorized: Bool)
	
	/// The event that is emitted when an NFT is unwrapped
	access(all)
	event FRC20StrategyRegistered(
		wrapper: Address,
		deployer: Address,
		nftType: Type,
		tick: String,
		alloc: UFix64,
		copies: UInt64,
		cond: String?
	)
	
	/// The event that is emitted when an NFT is wrapped
	access(all)
	event NFTWrappedWithFRC20Allocated(
		wrapper: Address,
		nftType: Type,
		srcNftId: UInt64,
		wrappedNftId: UInt64,
		tick: String,
		alloc: UFix64,
		address: Address
	)
	
	// Indexer
	/// The event that is emitted when a new wrapper is added to the indexer
	access(all)
	event WrapperAddedToIndexer(wrapper: Address)
	
	/// The event that is emitted when the extra NFT collection display is updated
	access(all)
	event WrapperIndexerUpdatedNFTCollectionDisplay(
		nftType: Type,
		name: String,
		description: String
	)
	
	/* --- Variable, Enums and Structs --- */
	access(all)
	let FRC20NFTWrapperStoragePath: StoragePath
	
	access(all)
	let FRC20NFTWrapperPublicPath: PublicPath
	
	access(all)
	let FRC20NFTWrapperIndexerStoragePath: StoragePath
	
	access(all)
	let FRC20NFTWrapperIndexerPublicPath: PublicPath
	
	/* --- Interfaces & Resources --- */
	access(all)
	struct FRC20Strategy{ 
		access(all)
		let tick: String
		
		access(all)
		let nftType: Type
		
		access(all)
		let alloc: UFix64
		
		access(all)
		let copies: UInt64
		
		access(all)
		let cond: String?
		
		access(all)
		let createdAt: UFix64
		
		access(all)
		var usedAmt: UInt64
		
		init(tick: String, nftType: Type, alloc: UFix64, copies: UInt64, cond: String?){ 
			self.tick = tick
			self.nftType = nftType
			self.alloc = alloc
			self.copies = copies
			self.cond = cond
			self.usedAmt = 0
			self.createdAt = getCurrentBlock().timestamp
		}
		
		access(all)
		fun isUsedUp(): Bool{ 
			return self.usedAmt >= self.copies
		}
		
		access(contract)
		fun use(){ 
			pre{ 
				self.usedAmt < self.copies:
					"The strategy is used up"
			}
			self.usedAmt = self.usedAmt + 1
		}
	}
	
	access(all)
	resource interface WrapperPublic{ 
		// public methods ----
		
		/// Get the internal flow vault balance
		///
		access(all)
		view fun getInternalFlowBalance(): UFix64
		
		access(all)
		view fun isFRC20NFTWrappered(nft: &{NonFungibleToken.NFT}): Bool
		
		access(all)
		view fun hasFRC20Strategy(_ collectionType: Type): Bool
		
		access(all)
		view fun getStrategiesAmount(all: Bool): UInt64
		
		access(all)
		view fun getStrategies(all: Bool): [FRC20Strategy]
		
		access(all)
		view fun isAuthorizedToRegister(addr: Address): Bool
		
		access(all)
		view fun getWhitelistedAddresses(): [Address]
		
		access(all)
		view fun getOption(key: String): AnyStruct?
		
		access(all)
		view fun getOptions():{ String: AnyStruct}
		
		// write methods ----
		/// Donate to the internal flow vault
		access(all)
		fun donate(value: @FlowToken.Vault): Void
		
		/// Register a new FRC20 strategy
		access(all)
		fun registerFRC20Strategy(
			type: Type,
			alloc: UFix64,
			copies: UInt64,
			cond: String?,
			ins: &Fixes.Inscription
		)
		
		/// Xerox an NFT and wrap it to the FixesWrappedNFT collection
		///
		access(all)
		fun wrap(recipient: &FixesWrappedNFT.Collection, nftToWrap: @{NonFungibleToken.NFT}): UInt64
	}
	
	/// The resource for the Wrapper contract
	///
	access(all)
	resource Wrapper: WrapperPublic{ 
		access(self)
		let strategies:{ Type: FRC20Strategy}
		
		access(self)
		let histories:{ Type:{ UInt64: Bool}}
		
		access(self)
		let internalFlowVault: @FlowToken.Vault
		
		access(self)
		let whitelist:{ Address: Bool}
		
		access(self)
		let options:{ String: AnyStruct}
		
		init(){ 
			self.histories ={} 
			self.strategies ={} 
			self.whitelist ={} 
			self.options ={} 
			self.internalFlowVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()) as! @FlowToken.Vault
			emit WrapperCreated()
		}
		
		/// @deprecated after Cadence 1.0
		// public methods
		access(all)
		view fun getInternalFlowBalance(): UFix64{ 
			return self.internalFlowVault.balance
		}
		
		access(all)
		view fun isFRC20NFTWrappered(nft: &{NonFungibleToken.NFT}): Bool{ 
			let collectionType = FRC20NFTWrapper.asCollectionType(nft.getType().identifier)
			if let nftHistories = &self.histories[collectionType] as &{UInt64: Bool}?{ 
				return nftHistories[nft.id] ?? false
			}
			return false
		}
		
		access(all)
		view fun hasFRC20Strategy(_ collectionType: Type): Bool{ 
			return self.strategies[collectionType] != nil
		}
		
		access(all)
		view fun getStrategiesAmount(all: Bool): UInt64{ 
			if all{ 
				return UInt64(self.strategies.keys.length)
			}
			return UInt64(self.strategies.values.filter(fun (s: FRC20Strategy): Bool{ 
						return s.isUsedUp() == false
					}).length)
		}
		
		access(all)
		view fun getStrategies(all: Bool): [FRC20Strategy]{ 
			if all{ 
				return self.strategies.values
			}
			return self.strategies.values.filter(fun (s: FRC20Strategy): Bool{ 
					return s.isUsedUp() == false
				})
		}
		
		access(all)
		view fun isAuthorizedToRegister(addr: Address): Bool{ 
			return addr == self.owner?.address || self.whitelist[addr] ?? false
		}
		
		access(all)
		view fun getWhitelistedAddresses(): [Address]{ 
			let ret: [Address] = []
			for addr in self.whitelist.keys{ 
				if self.whitelist[addr]!{ 
					ret.append(addr)
				}
			}
			return ret
		}
		
		access(all)
		view fun getOption(key: String): AnyStruct?{ 
			return self.options[key]
		}
		
		access(all)
		view fun getOptions():{ String: AnyStruct}{ 
			return self.options
		}
		
		// write methods
		access(all)
		fun donate(value: @FlowToken.Vault): Void{ 
			pre{ 
				value.balance > UFix64(0.0):
					"Donation must be greater than 0"
			}
			let amt = value.balance
			self.internalFlowVault.deposit(from: <-value)
			emit InternalFlowVaultDonated(amount: amt)
		}
		
		/// Register a new FRC20 strategy
		access(all)
		fun registerFRC20Strategy(type: Type, alloc: UFix64, copies: UInt64, cond: String?, ins: &Fixes.Inscription){ 
			pre{ 
				ins.isExtractable():
					"The inscription is not extractable"
			}
			let indexer = FRC20Indexer.getIndexer()
			assert(indexer.isValidFRC20Inscription(ins: ins), message: "The inscription is not a valid FRC20 inscription")
			let fromAddr = ins.owner?.address ?? panic("Inscription owner is nil")
			let data = indexer.parseMetadata(&ins.getData() as &Fixes.InscriptionData)
			assert(data["op"] == "transfer" && data["tick"] != nil && data["amt"] != nil && data["to"] != nil, message: "The inscription is not a valid FRC20 inscription for transfer")
			let tick: String = (data["tick"]!).toLower()
			let meta = indexer.getTokenMeta(tick: tick) ?? panic("Could not get token meta for ".concat(tick))
			
			/// check if the deployer is the owner of the inscription
			assert(meta.deployer == fromAddr, message: "The frc20 deployer is not the owner of the inscription")
			
			// check if the deployer is authorized to register a new strategy
			assert(self.isAuthorizedToRegister(addr: fromAddr), message: "The deployer is not authorized to register a new strategy")
			
			// ensure store as collection type
			let collectionType = FRC20NFTWrapper.asCollectionType(type.identifier)
			assert(collectionType.identifier != Type<@FixesWrappedNFT.Collection>().identifier, message: "You cannot wrap a FixesWrappedNFT")
			
			// check if the strategy already exists
			assert(self.strategies[collectionType] == nil, message: "The strategy already exists")
			
			// ensure condition is valid
			if let condStr = cond{ 
				let conds = StringUtils.split(condStr, ",")
				for one in conds{ 
					let subConds = StringUtils.split(one, "~")
					if subConds.length == 1 && UInt64.fromString(subConds[0]) != nil{ 
						continue
					} else if subConds.length == 2 && UInt64.fromString(subConds[0]) != nil && UInt64.fromString(subConds[1]) != nil{ 
						continue
					} else{ 
						panic("Invalid condition")
					}
				}
			}
			
			// indexer address
			let indexerAddr = FRC20Indexer.getAddress()
			
			// check if the allocation is enough
			let amt = UFix64.fromString(data["amt"]!) ?? panic("The amount is not a valid UFix64")
			let to = Address.fromString(data["to"]!) ?? panic("The receiver is not a valid address")
			let toAllocateAmt = alloc * UFix64(copies)
			assert(amt >= toAllocateAmt, message: "The amount is not enough to allocate")
			assert(to == indexerAddr, message: "The receiver is not the indexer")
			
			// apply inscription for transfer
			indexer.transfer(ins: ins)
			
			// ensure frc20 is enough
			let frc20BalanceForContract = indexer.getBalance(tick: tick, addr: indexerAddr)
			assert(frc20BalanceForContract >= toAllocateAmt, message: "The FRC20 balance for the contract is not enough")
			
			// setup strategy
			self.strategies[collectionType] = FRC20Strategy(tick: tick, nftType: collectionType, alloc: alloc, copies: copies, cond: cond)
			// setup history
			self.histories[collectionType] ={} 
			
			// emit event
			emit FRC20StrategyRegistered(wrapper: self.owner?.address ?? panic("Wrapper owner is nil"), deployer: fromAddr, nftType: collectionType, tick: tick, alloc: alloc, copies: copies, cond: cond)
		}
		
		/// Wrap an NFT and wrap it to the FixesWrappedNFT collection
		///
		access(all)
		fun wrap(recipient: &FixesWrappedNFT.Collection, nftToWrap: @{NonFungibleToken.NFT}): UInt64{ 
			// check if the NFT is owned by the signer
			let recipientAddr = recipient.owner?.address ?? panic("Recipient owner is nil")
			// get the NFT type
			let nftTypeIdentifier = nftToWrap.getType().identifier
			// generate the collection type
			let nftType = FRC20NFTWrapper.asCollectionType(nftTypeIdentifier)
			// get the NFT id
			let srcNftId = nftToWrap.id
			// check if the strategy exists, and borrow it
			let strategy = self.borrowStrategy(nftType: nftType)
			// check if the strategy is used up
			assert(strategy.usedAmt < strategy.copies, message: "The strategy is used up")
			
			// check strategy condition
			if let condStr = strategy.cond{ 
				var valid: Bool = false
				let conds = StringUtils.split(condStr, ",")
				for one in conds{ 
					let subConds = StringUtils.split(one, "~")
					if subConds.length == 1{ 
						// check if the NFT id is the same
						valid = valid || UInt64.fromString(subConds[0]) == srcNftId
					} else if subConds.length == 2{ 
						// check if the NFT id is in the range
						let start = UInt64.fromString(subConds[0]) ?? panic("Invalid condition")
						let end = UInt64.fromString(subConds[1]) ?? panic("Invalid condition")
						// check if the range is valid, and the NFT id is in the range
						// NOTE: the range is [start, end)
						valid = valid || start <= srcNftId && srcNftId < end
					} else{ 
						panic("Invalid condition")
					}
					// break if valid
					if valid{ 
						break
					}
				}
				assert(valid, message: "The NFT ID does not meet the condition:".concat(condStr))
			}
			
			// borrow the history
			let history = self.borrowHistory(nftType: nftType)
			// check if the NFT is already wrapped
			assert(history[nftToWrap.id] == nil, message: "The NFT is already wrapped")
			
			// basic attributes
			let mimeType = "text/plain"
			let metaProtocol = "frc20"
			let dataStr = "op=alloc,tick=".concat(strategy.tick).concat(",amt=").concat(strategy.alloc.toString()).concat(",to=").concat(recipientAddr.toString())
			let metadata = dataStr.utf8
			
			// estimate the required storage
			let estimatedReqValue = Fixes.estimateValue(index: Fixes.totalInscriptions, mimeType: mimeType, data: metadata, protocol: metaProtocol, encoding: nil)
			
			// Get a reference to the signer's stored vault
			let flowToReserve <- self.internalFlowVault.withdraw(amount: estimatedReqValue)
			
			// Create the Inscription first
			let newIns <- Fixes.createInscription(												  // Withdraw tokens from the signer's stored vault
												  value: <-(flowToReserve as! @FlowToken.Vault), mimeType: mimeType, metadata: metadata, metaProtocol: metaProtocol, encoding: nil, parentId: nil)
			// mint the wrapped NFT
			let newId = FixesWrappedNFT.wrap(recipient: recipient, nftToWrap: <-nftToWrap, inscription: <-newIns)
			
			// borrow the inscription
			let nft = recipient.borrowFixesWrappedNFT(id: newId) ?? panic("Could not borrow FixesWrappedNFT")
			let insRef = nft.borrowInscription() ?? panic("Could not borrow inscription")
			
			// get FRC20 indexer
			let indexer: &FRC20Indexer.InscriptionIndexer = FRC20Indexer.getIndexer()
			let used <- indexer.allocate(ins: insRef)
			
			// deposit the unused flow back to the internal flow vault
			self.internalFlowVault.deposit(from: <-used)
			
			// update strategy used one time
			strategy.use()
			
			// update histories
			history[srcNftId] = true
			
			// emit event
			emit NFTWrappedWithFRC20Allocated(wrapper: self.owner?.address ?? panic("Wrapper owner is nil"), nftType: nftType, srcNftId: srcNftId, wrappedNftId: newId, tick: strategy.tick, alloc: strategy.alloc, address: recipientAddr)
			return newId
		}
		
		// private methods
		/// Update the wrapper options
		access(all)
		fun updateOptions(key: String, value: AnyStruct){ 
			self.options[key] = value
			emit WrapperOptionsUpdated(wrapper: self.owner?.address ?? panic("Wrapper owner is nil"), key: key)
		}
		
		/// Update the whitelist
		///
		access(all)
		fun updateWhitelist(addr: Address, isAuthorized: Bool): Void{ 
			self.whitelist[addr] = isAuthorized
			emit AuthorizedWhitelistUpdated(addr: addr, isAuthorized: isAuthorized)
		}
		
		// internal methods
		/// Borrow the strategy for an NFT type
		///
		access(self)
		fun borrowStrategy(nftType: Type): &FRC20Strategy{ 
			return &self.strategies[nftType] as &FRC20Strategy? ?? panic("Could not borrow strategy")
		}
		
		/// Borrow the history for an NFT type
		///
		access(self)
		fun borrowHistory(nftType: Type): &{UInt64: Bool}{ 
			return &self.histories[nftType] as &{UInt64: Bool}? ?? panic("Could not borrow history")
		}
	}
	
	/// The public resource interface for the Wrapper Indexer
	///
	access(all)
	resource interface WrapperIndexerPublic{ 
		// public methods ----
		
		/// Check if the wrapper is registered
		///
		access(all)
		view fun hasRegisteredWrapper(addr: Address): Bool
		
		/// Get all the wrappers
		access(all)
		view fun getAllWrappers(_ includeNoStrategy: Bool, _ includeFinished: Bool): [Address]
		
		/// Get the public reference to the Wrapper resource
		///
		access(all)
		fun borrowWrapperPublic(addr: Address): &Wrapper?{ 
			return FRC20NFTWrapper.borrowWrapperPublic(addr: addr)
		}
		
		/// Get the NFT collection display
		///
		access(all)
		view fun getNFTCollectionDisplay(nftType: Type): MetadataViews.NFTCollectionDisplay
		
		// write methods ----
		/// Register a new Wrapper
		access(all)
		fun registerWrapper(wrapper: &Wrapper)
	}
	
	/// The resource for the Wrapper indexer contract
	///
	access(all)
	resource WrapperIndexer: WrapperIndexerPublic{ 
		/// The event that is emitted when the contract is created
		access(self)
		let wrappers:{ Address: Bool}
		
		access(self)
		let displayHelper:{ Type: MetadataViews.NFTCollectionDisplay}
		
		init(){ 
			self.wrappers ={} 
			self.displayHelper ={} 
		}
		
		// public methods ----
		/// Check if the wrapper is registered
		///
		access(all)
		view fun hasRegisteredWrapper(addr: Address): Bool{ 
			return self.wrappers[addr] != nil
		}
		
		/// Get all the wrappers
		///
		access(all)
		view fun getAllWrappers(_ includeNoStrategy: Bool, _ includeFinished: Bool): [Address]{ 
			return self.wrappers.keys.filter(fun (addr: Address): Bool{ 
					if let wrapper = FRC20NFTWrapper.borrowWrapperPublic(addr: addr){ 
						return includeNoStrategy ? true : wrapper.getStrategiesAmount(all: includeFinished) > 0
					} else{ 
						return false
					}
				})
		}
		
		/// Get the extra NFT collection display
		///
		access(all)
		view fun getNFTCollectionDisplay(nftType: Type): MetadataViews.NFTCollectionDisplay{ 
			let collectionType = FRC20NFTWrapper.asCollectionType(nftType.identifier)
			let nftType = FRC20NFTWrapper.asNFTType(nftType.identifier)
			// get from NFTCatalog first
			if let entries:{ String: Bool} = NFTCatalog.getCollectionsForType(nftTypeIdentifier: nftType.identifier){ 
				for colId in entries.keys{ 
					if let catalogEntry = NFTCatalog.getCatalogEntry(collectionIdentifier: colId){ 
						return catalogEntry.collectionDisplay
					}
				}
			}
			// if no exists, then get from display helper
			if let display = self.displayHelper[collectionType]{ 
				return display
			}
			let defaultDisplay = (FixesWrappedNFT.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) as! MetadataViews.NFTCollectionDisplay?)!
			let ids = StringUtils.split(nftType.identifier, ".")
			return MetadataViews.NFTCollectionDisplay(name: ids[2], description: "NFT Collection built by address ".concat(ids[1]), externalURL: defaultDisplay.externalURL, squareImage: defaultDisplay.squareImage, bannerImage: defaultDisplay.bannerImage, socials: defaultDisplay.socials)
		}
		
		// write methods ----
		/// Register a new Wrapper
		access(all)
		fun registerWrapper(wrapper: &Wrapper){ 
			pre{ 
				wrapper.owner != nil:
					"Wrapper owner is nil"
			}
			let ownerAddr = (wrapper.owner!).address
			self.wrappers[ownerAddr] = true
			emit WrapperAddedToIndexer(wrapper: ownerAddr)
		}
		
		// private write methods ----
		access(all)
		fun updateExtraNFTCollectionDisplay(nftType: Type, display: MetadataViews.NFTCollectionDisplay): Void{ 
			let collectionType = FRC20NFTWrapper.asCollectionType(nftType.identifier)
			self.displayHelper[collectionType] = display
			emit WrapperIndexerUpdatedNFTCollectionDisplay(nftType: collectionType, name: display.name, description: display.description)
		}
	}
	
	/// Donate to the internal flow vault
	///
	access(all)
	fun donate(addr: Address, _ value: @FlowToken.Vault): Void{ 
		let ref =
			self.borrowWrapperPublic(addr: addr) ?? panic("Could not borrow Xerox public reference")
		ref.donate(value: <-value)
	}
	
	/// Create a new Wrapper resourceTON
	///
	access(all)
	fun createNewWrapper(): @Wrapper{ 
		return <-create Wrapper()
	}
	
	/// Make a new NFT type
	///
	access(all)
	view fun asNFTType(_ identifier: String): Type{ 
		let ids = StringUtils.split(identifier, ".")
		assert(ids.length == 4, message: "Invalid NFT type identifier!")
		ids[3] = "NFT"
		return CompositeType(StringUtils.join(ids, "."))!
	}
	
	/// Make a new NFT Collection type
	///
	access(all)
	view fun asCollectionType(_ identifier: String): Type{ 
		let ids = StringUtils.split(identifier, ".")
		assert(ids.length == 4, message: "Invalid NFT Collection type identifier!")
		ids[3] = "Collection"
		return CompositeType(StringUtils.join(ids, "."))!
	}
	
	/// Borrow the public reference to the Wrapper resource
	///
	access(all)
	fun borrowWrapperPublic(addr: Address): &FRC20NFTWrapper.Wrapper?{ 
		return getAccount(addr).capabilities.get<&FRC20NFTWrapper.Wrapper>(
			self.FRC20NFTWrapperPublicPath
		).borrow()
	}
	
	/// Borrow the public interface to the Wrapper Indexer resource
	///
	access(all)
	view fun borrowWrapperIndexerPublic(): &FRC20NFTWrapper.WrapperIndexer{ 
		return getAccount(self.account.address).capabilities.get<&FRC20NFTWrapper.WrapperIndexer>(
			self.FRC20NFTWrapperIndexerPublicPath
		).borrow()
		?? panic("Could not borrow WrapperIndexer public reference")
	}
	
	/// Get the NFT collection display
	///
	access(all)
	view fun getNFTCollectionDisplay(nftType: Type): MetadataViews.NFTCollectionDisplay{ 
		return self.borrowWrapperIndexerPublic().getNFTCollectionDisplay(nftType: nftType)
	}
	
	/// init
	init(){ 
		let identifier = "FixesFRC20NFTWrapper_".concat(self.account.address.toString())
		self.FRC20NFTWrapperStoragePath = StoragePath(identifier: identifier)!
		self.FRC20NFTWrapperPublicPath = PublicPath(identifier: identifier)!
		self.FRC20NFTWrapperIndexerStoragePath = StoragePath(
				identifier: identifier.concat("_indexer")
			)!
		self.FRC20NFTWrapperIndexerPublicPath = PublicPath(
				identifier: identifier.concat("_indexer")
			)!
		self.account.storage.save(
			<-self.createNewWrapper(),
			to: FRC20NFTWrapper.FRC20NFTWrapperStoragePath
		)
		var capability_1 =
			self.account.capabilities.storage.issue<&FRC20NFTWrapper.Wrapper>(
				FRC20NFTWrapper.FRC20NFTWrapperStoragePath
			)
		self.account.capabilities.publish(
			capability_1,
			at: FRC20NFTWrapper.FRC20NFTWrapperPublicPath
		)
		
		// create indexer
		let indexer <- create WrapperIndexer()
		// save the indexer
		self.account.storage.save(<-indexer, to: self.FRC20NFTWrapperIndexerStoragePath)
		var capability_2 =
			self.account.capabilities.storage.issue<&FRC20NFTWrapper.WrapperIndexer>(
				self.FRC20NFTWrapperIndexerStoragePath
			)
		self.account.capabilities.publish(capability_2, at: self.FRC20NFTWrapperIndexerPublicPath)
		let indexerRef =
			self.account.storage.borrow<&FRC20NFTWrapper.WrapperIndexer>(
				from: self.FRC20NFTWrapperIndexerStoragePath
			)
			?? panic("Could not borrow indexer public reference")
		
		// register the wrapper to the indexer
		let wrapper =
			self.account.storage.borrow<&Wrapper>(from: FRC20NFTWrapper.FRC20NFTWrapperStoragePath)
			?? panic("Could not borrow wrapper public reference")
		indexerRef.registerWrapper(wrapper: wrapper)
		emit ContractInitialized()
	}
}
