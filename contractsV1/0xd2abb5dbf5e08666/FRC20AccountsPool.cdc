/**
> Author: FIXeS World <https://fixes.world/>

# FRC20 Accounts Pool

TODO: Add description

*/


// Third-party imports
import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import HybridCustody from "../0xd8a7e05a7ac670c0/HybridCustody.cdc"

// Fixes imports
// import "Fixes"
// import "FRC20FTShared"
import FRC20Indexer from "./FRC20Indexer.cdc"

access(all)
contract FRC20AccountsPool{ 
	/* --- Events --- */
	/// Event emitted when the contract is initialized
	access(all)
	event ContractInitialized()
	
	/// Event emitted when a new child account is added, if tick is nil, it means the child account is not a shared account
	access(all)
	event NewChildAccountAdded(type: UInt8, address: Address, tick: String?, key: String?)
	
	/* --- Variable, Enums and Structs --- */
	access(all)
	let AccountsPoolStoragePath: StoragePath
	
	access(all)
	let AccountsPoolPublicPath: PublicPath
	
	/* --- Interfaces & Resources --- */
	access(all)
	enum ChildAccountType: UInt8{ 
		access(all)
		case Market
		
		access(all)
		case Staking
		
		access(all)
		case EVMAgency
		
		access(all)
		case EVMEntrustedAccount
		
		access(all)
		case GameWorld
	}
	
	/// The public interface can be accessed by anyone
	///
	access(all)
	resource interface PoolPublic{ 
		/// ---- Getters ----
		/// Returns the addresses of the FRC20 with the given type
		access(all)
		view fun getFRC20Addresses(type: ChildAccountType):{ String: Address}
		
		/// Returns the address of the FRC20 staking for the given tick
		access(all)
		view fun getFRC20StakingAddress(tick: String): Address?
		
		/// Returns the flow token receiver for the given tick
		access(all)
		fun borrowFRC20StakingFlowTokenReceiver(tick: String): &{FungibleToken.Receiver}?
		
		/// Returns the address of the FRC20 market for the given tick
		access(all)
		view fun getFRC20MarketAddress(tick: String): Address?
		
		/// Returns the flow token receiver for the given tick
		access(all)
		fun borrowFRC20MarketFlowTokenReceiver(tick: String): &{FungibleToken.Receiver}?
		
		/// Returns the address of the FRC20 market for the given tick
		access(all)
		view fun getMarketSharedAddress(): Address?
		
		/// Returns the address of the FRC20 market for the given tick
		access(all)
		fun borrowMarketSharedFlowTokenReceiver(): &{FungibleToken.Receiver}?
		
		/// Returns the address of the EVM agent for the given owner address
		access(all)
		view fun getEVMAgencyAddress(_ owner: String): Address?
		
		/// Returns the flow token receiver for the given owner address
		access(all)
		fun borrowEVMAgencyFlowTokenReceiver(_ owner: String): &{FungibleToken.Receiver}?
		
		/// Returns the address of the EVM entrusted account for the given evm address
		access(all)
		view fun getEVMEntrustedAccountAddress(_ evmAddr: String): Address?
		
		/// Returns the flow token receiver for the given evm address
		access(all)
		fun borrowEVMEntrustedAccountFlowTokenReceiver(_ evmAddr: String): &{
			FungibleToken.Receiver
		}?
		
		/// Returns the address of the GameWorld for the given key
		access(all)
		view fun getGameWorldAddress(_ key: String): Address?
		
		/// Returns the flow token receiver for the given key
		access(all)
		fun borrowGameWorldFlowTokenReceiver(_ key: String): &{FungibleToken.Receiver}?
		
		/// ----- Access account methods -----
		/// Borrow child's AuthAccount
		access(account)
		fun borrowChildAccount(type: ChildAccountType, _ key: String?): &AuthAccount?
		
		/// Sets up a new child account for market
		access(account)
		fun setupNewChildForMarket(tick: String, _ acctCap: Capability<&AuthAccount>)
		
		/// Sets up a new child account for staking
		access(account)
		fun setupNewChildForStaking(tick: String, _ acctCap: Capability<&AuthAccount>)
		
		/// Sets up a new child account for EVM agent
		access(account)
		fun setupNewChildForEVMAgency(owner: String, _ acctCap: Capability<&AuthAccount>)
		
		/// Sets up a new child account for EVM entrusted account
		access(account)
		fun setupNewChildForEVMEntrustedAccount(
			evmAddr: String,
			_ acctCap: Capability<&AuthAccount>
		)
		
		/// Sets up a new child account for some Game World
		access(account)
		fun setupNewChildForGameWorld(key: String, _ acctCap: Capability<&AuthAccount>)
	}
	
	/// The admin interface can only be accessed by the the account manager's owner
	///
	access(all)
	resource interface PoolAdmin{ 
		/// Sets up a new child account
		access(all)
		fun setupNewSharedChildByType(type: ChildAccountType, _ acctCap: Capability<&AuthAccount>)
		
		/// Sets up a new child account
		access(all)
		fun setupNewChildByKey(
			type: ChildAccountType,
			key: String,
			_ acctCap: Capability<&AuthAccount>
		)
	}
	
	access(all)
	resource Pool: PoolPublic, PoolAdmin{ 
		access(self)
		let hcManagerCap: Capability<&HybridCustody.Manager>
		
		// AccountType -> Tick -> Address
		access(self)
		let addressMapping:{ ChildAccountType:{ String: Address}}
		
		// AccountType -> Address
		access(self)
		let sharedAddressMappping:{ ChildAccountType: Address}
		
		init(_ hcManagerCap: Capability<&HybridCustody.Manager>){ 
			self.hcManagerCap = hcManagerCap
			self.addressMapping ={} 
			self.sharedAddressMappping ={} 
		}
		
		/** ---- Public Methods ---- */
		/// Returns the addresses of the FRC20 with the given type
		access(all)
		view fun getFRC20Addresses(type: ChildAccountType):{ String: Address}{ 
			if let tickDict = self.addressMapping[type]{ 
				return tickDict
			}
			return{} 
		}
		
		/// Returns the address of the FRC20 market for the given tick
		access(all)
		view fun getFRC20MarketAddress(tick: String): Address?{ 
			if let tickDict = self.borrowDict(type: ChildAccountType.Market){ 
				return tickDict[tick]
			}
			return nil
		}
		
		/// Returns the flow token receiver for the given tick
		access(all)
		fun borrowFRC20MarketFlowTokenReceiver(tick: String): &{FungibleToken.Receiver}?{ 
			if let addr = self.getFRC20MarketAddress(tick: tick){ 
				return FRC20Indexer.borrowFlowTokenReceiver(addr)
			}
			return nil
		}
		
		/// Returns the address of the FRC20 market for the given tick
		access(all)
		view fun getMarketSharedAddress(): Address?{ 
			return self.sharedAddressMappping[ChildAccountType.Market]
		}
		
		/// Returns the address of the FRC20 market for the given tick
		access(all)
		fun borrowMarketSharedFlowTokenReceiver(): &{FungibleToken.Receiver}?{ 
			if let addr = self.getMarketSharedAddress(){ 
				return FRC20Indexer.borrowFlowTokenReceiver(addr)
			}
			return nil
		}
		
		/// Returns the address of the FRC20 staking for the given tick
		access(all)
		view fun getFRC20StakingAddress(tick: String): Address?{ 
			if let tickDict = self.borrowDict(type: ChildAccountType.Staking){ 
				return tickDict[tick]
			}
			return nil
		}
		
		/// Returns the flow token receiver for the given tick
		access(all)
		fun borrowFRC20StakingFlowTokenReceiver(tick: String): &{FungibleToken.Receiver}?{ 
			if let addr = self.getFRC20StakingAddress(tick: tick){ 
				return FRC20Indexer.borrowFlowTokenReceiver(addr)
			}
			return nil
		}
		
		/// Returns the address of the EVM agent for the given eth address
		access(all)
		view fun getEVMAgencyAddress(_ owner: String): Address?{ 
			if let tickDict = self.borrowDict(type: ChildAccountType.EVMAgency){ 
				return tickDict[owner]
			}
			return nil
		}
		
		/// Returns the flow token receiver for the given tick
		access(all)
		fun borrowEVMAgencyFlowTokenReceiver(_ evmAddress: String): &{FungibleToken.Receiver}?{ 
			if let addr = self.getEVMAgencyAddress(evmAddress){ 
				return FRC20Indexer.borrowFlowTokenReceiver(addr)
			}
			return nil
		}
		
		/// Returns the address of the EVM entrusted account for the given evm address
		access(all)
		view fun getEVMEntrustedAccountAddress(_ evmAddr: String): Address?{ 
			if let tickDict = self.borrowDict(type: ChildAccountType.EVMEntrustedAccount){ 
				return tickDict[evmAddr]
			}
			return nil
		}
		
		/// Returns the flow token receiver for the given evm address
		access(all)
		fun borrowEVMEntrustedAccountFlowTokenReceiver(_ evmAddr: String): &{FungibleToken.Receiver}?{ 
			if let addr = self.getEVMEntrustedAccountAddress(evmAddr){ 
				return FRC20Indexer.borrowFlowTokenReceiver(addr)
			}
			return nil
		}
		
		/// Returns the address of the GameWorld for the given key
		access(all)
		view fun getGameWorldAddress(_ key: String): Address?{ 
			if let tickDict = self.borrowDict(type: ChildAccountType.GameWorld){ 
				return tickDict[key]
			}
			return nil
		}
		
		/// Returns the flow token receiver for the given key
		access(all)
		fun borrowGameWorldFlowTokenReceiver(_ key: String): &{FungibleToken.Receiver}?{ 
			if let addr = self.getGameWorldAddress(key){ 
				return FRC20Indexer.borrowFlowTokenReceiver(addr)
			}
			return nil
		}
		
		/// ----- Access account methods -----
		/// Borrow child's AuthAccount
		///
		access(account)
		fun borrowChildAccount(type: ChildAccountType, _ key: String?): &AuthAccount?{ 
			let hcManagerRef = self.hcManagerCap.borrow() ?? panic("Failed to borrow hcManager")
			if let specified = key{ 
				let dict = self.borrowDict(type: type)
				if dict == nil{ 
					return nil
				}
				if let childAddr = (dict!)[specified]{ 
					if let ownedChild = hcManagerRef.borrowOwnedAccount(addr: childAddr){ 
						return ownedChild.borrowAccount()
					}
				}
			} else if let sharedAddr = self.sharedAddressMappping[type]{ 
				if let ownedChild = hcManagerRef.borrowOwnedAccount(addr: sharedAddr){ 
					return ownedChild.borrowAccount()
				}
			}
			return nil
		}
		
		/// Sets up a new child account for market
		///
		access(account)
		fun setupNewChildForMarket(tick: String, _ acctCap: Capability<&AuthAccount>){ 
			self.setupNewChildByKey(type: ChildAccountType.Market, key: tick, acctCap)
		}
		
		/// Sets up a new child account for staking
		///
		access(account)
		fun setupNewChildForStaking(tick: String, _ acctCap: Capability<&AuthAccount>){ 
			self.setupNewChildByKey(type: ChildAccountType.Staking, key: tick, acctCap)
		}
		
		/// Sets up a new child account for EVM agency
		access(account)
		fun setupNewChildForEVMAgency(owner: String, _ acctCap: Capability<&AuthAccount>){ 
			self.setupNewChildByKey(type: ChildAccountType.EVMAgency, key: owner, acctCap)
		}
		
		/// Sets up a new child account for EVM entrusted account
		access(account)
		fun setupNewChildForEVMEntrustedAccount(evmAddr: String, _ acctCap: Capability<&AuthAccount>){ 
			self.setupNewChildByKey(type: ChildAccountType.EVMEntrustedAccount, key: evmAddr, acctCap)
		}
		
		/// Sets up a new child account for some Game World
		access(account)
		fun setupNewChildForGameWorld(key: String, _ acctCap: Capability<&AuthAccount>){ 
			self.setupNewChildByKey(type: ChildAccountType.GameWorld, key: key, acctCap)
		}
		
		/** ---- Admin Methods ---- */
		/// Sets up a new shared child account
		///
		access(all)
		fun setupNewSharedChildByType(type: ChildAccountType, _ childAcctCap: Capability<&AuthAccount>){ 
			pre{ 
				childAcctCap.check():
					"Child account capability is invalid"
				self.sharedAddressMappping[type] == nil:
					"Shared child account already exists"
			}
			self.sharedAddressMappping[type] = childAcctCap.address
			
			// setup new child account
			self._setupChildAccount(childAcctCap)
			
			// emit event
			emit NewChildAccountAdded(type: type.rawValue, address: childAcctCap.address, tick: nil, key: nil)
		}
		
		/// Sets up a new child account
		///
		access(all)
		fun setupNewChildByKey(type: ChildAccountType, key: String, _ childAcctCap: Capability<&AuthAccount>){ 
			pre{ 
				childAcctCap.check():
					"Child account capability is invalid"
			}
			self._ensureDictExists(type)
			let dict = self.borrowDict(type: type) ?? panic("Failed to borrow tick ")
			// no need to setup if already exists
			if dict[key] != nil{ 
				return
			}
			var tick: String? = nil
			// For Market and Staking, we need to ensure the token meta exists
			if type == ChildAccountType.Market || type == ChildAccountType.Staking{ 
				let frc20Indexer = FRC20Indexer.getIndexer()
				// ensure token meta exists
				let tokenMeta = frc20Indexer.getTokenMeta(tick: key)
				assert(tokenMeta != nil, message: "Token meta does not exist")
				tick = key
			}
			
			// record new child account address
			dict[key] = childAcctCap.address
			
			// setup new child account
			self._setupChildAccount(childAcctCap)
			
			// emit event
			emit NewChildAccountAdded(type: type.rawValue, address: childAcctCap.address, tick: tick, key: key)
		}
		
		/** ---- Internal Methods ---- */
		/// Sets up a new child account
		///
		access(self)
		fun _setupChildAccount(_ childAcctCap: Capability<&AuthAccount>){ 
			let hcManager = self.hcManagerCap.borrow() ?? panic("Failed to borrow hcManager")
			let hcManagerAddr = self.hcManagerCap.address
			
			// >>> [0] Get child AuthAccount
			var child = childAcctCap.borrow() ?? panic("Failed to borrow child account")
			
			// >>> [1] Child: createOwnedAccount
			if child.borrow<&AnyResource>(from: HybridCustody.OwnedAccountStoragePath) == nil{ 
				let ownedAccount <- HybridCustody.createOwnedAccount(acct: childAcctCap)
				child.save(<-ownedAccount, to: HybridCustody.OwnedAccountStoragePath)
			}
			
			// ensure owned account exists
			let childRef = child.borrow<&HybridCustody.OwnedAccount>(from: HybridCustody.OwnedAccountStoragePath) ?? panic("owned account not found")
			
			// check that paths are all configured properly
			// public path
			// @deprecated after Cadence 1.0
			child.unlink(HybridCustody.OwnedAccountPublicPath)
			child.link<&HybridCustody.OwnedAccount>(HybridCustody.OwnedAccountPublicPath, target: HybridCustody.OwnedAccountStoragePath)
			
			// private path(will deperated in the future)
			// @deprecated after Cadence 1.0
			child.unlink(HybridCustody.OwnedAccountPrivatePath)
			child.link<&HybridCustody.OwnedAccount>(HybridCustody.OwnedAccountPrivatePath, target: HybridCustody.OwnedAccountStoragePath)
			let publishIdentifier = HybridCustody.getOwnerIdentifier(hcManagerAddr)
			// give ownership to manager
			childRef.giveOwnership(to: hcManagerAddr)
			
			// only childRef will be available after 'giveaway', so we need to re-borrow it
			child = childRef.borrowAccount()
			
			// unpublish the priv capability
			child.inbox.unpublish<&{HybridCustody.OwnedAccountPrivate, HybridCustody.OwnedAccountPublic, MetadataViews.Resolver}>(publishIdentifier)
			
			// >> [2] manager: add owned child account
			
			// Link a Capability for the new owner, retrieve & publish
			let ownedPrivCap = child.getCapability<&{HybridCustody.OwnedAccountPrivate, HybridCustody.OwnedAccountPublic, MetadataViews.Resolver}>(PrivatePath(identifier: publishIdentifier)!)
			assert(ownedPrivCap.check(), message: "Failed to get owned account capability")
			
			// add owned account to manager
			hcManager.addOwnedAccount(cap: ownedPrivCap)
		}
		
		/// Borrow dictioinary
		///
		access(self)
		view fun borrowDict(type: ChildAccountType): &{String: Address}?{ 
			return &self.addressMapping[type] as &{String: Address}?
		}
		
		/// ensure type dict exists
		///
		access(self)
		fun _ensureDictExists(_ type: ChildAccountType){ 
			if self.addressMapping[type] == nil{ 
				self.addressMapping[type] ={} 
			}
		}
	}
	
	/* --- Public Methods --- */
	/// Returns the public account manager interface
	///
	access(all)
	fun borrowAccountsPool(): &Pool{ 
		return self.account.capabilities.get<&Pool>(self.AccountsPoolPublicPath).borrow()
		?? panic("Could not borrow accounts pool reference")
	}
	
	init(){ 
		let identifier = "FRC20AccountsPool_".concat(self.account.address.toString())
		self.AccountsPoolStoragePath = StoragePath(identifier: identifier)!
		self.AccountsPoolPublicPath = PublicPath(identifier: identifier)!
		
		// create account manager with hybrid custody manager capability
		if self.account.storage.borrow<&HybridCustody.Manager>(
			from: HybridCustody.ManagerStoragePath
		)
		== nil{ 
			let m <- HybridCustody.createManager(filter: nil)
			self.account.storage.save(<-m, to: HybridCustody.ManagerStoragePath)
		}
		
		// reset account manager paths
		self.account.unlink(HybridCustody.ManagerPublicPath)
		var capability_1 =
			self.account.capabilities.storage.issue<&HybridCustody.Manager>(
				HybridCustody.ManagerStoragePath
			)
		self.account.capabilities.publish(capability_1, at: HybridCustody.ManagerPublicPath)
		self.account.unlink(HybridCustody.ManagerPrivatePath)
		var capability_2 =
			self.account.capabilities.storage.issue<&HybridCustody.Manager>(
				HybridCustody.ManagerStoragePath
			)
		self.account.capabilities.publish(capability_2, at: HybridCustody.ManagerPrivatePath)
		let cap = capability_2
		
		// init account manager
		let acctPool <- create Pool(cap)
		self.account.storage.save(<-acctPool, to: self.AccountsPoolStoragePath)
		// link public capability
		var capability_3 =
			self.account.capabilities.storage.issue<&Pool>(self.AccountsPoolStoragePath)
		self.account.capabilities.publish(capability_3, at: self.AccountsPoolPublicPath)
		emit ContractInitialized()
	}
}
