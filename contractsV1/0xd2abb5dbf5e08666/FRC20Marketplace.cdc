/**
> Author: FIXeS World <https://fixes.world/>

# FRC20Marketplace

TODO: Add description

*/

// Third-party imports
import StringUtils from "./../../standardsV1/StringUtils.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

// Fixes imports
import FRC20FTShared from "./FRC20FTShared.cdc"

import FRC20Indexer from "./FRC20Indexer.cdc"

import FRC20Storefront from "./FRC20Storefront.cdc"

import FRC20AccountsPool from "./FRC20AccountsPool.cdc"

access(all)
contract FRC20Marketplace{ 
	/* --- Events --- */
	/// Event emitted when the contract is initialized
	access(all)
	event ContractInitialized()
	
	/// Event emitted when a new market is created
	access(all)
	event MarketCreated(tick: String, uuid: UInt64)
	
	/// Event emitted when a new listing is added
	access(all)
	event ListingAdded(tick: String, storefront: Address, listingId: UInt64, type: UInt8)
	
	/// Event emitted when a listing is removed
	access(all)
	event ListingRemoved(tick: String, storefront: Address, listingId: UInt64, type: UInt8)
	
	/// Event emitted when the market is Accessible
	access(all)
	event MarketWhitelistClaimed(tick: String, addr: Address)
	
	/// Event emitted when the market Accessible after timestamp is updated
	access(all)
	event MarketAdminWhitelistUpdated(tick: String, addr: Address, isWhitelisted: Bool)
	
	/// Event emitted when the market properties are updated
	access(all)
	event MarketAdminPropertiesUpdated(tick: String, key: UInt8, value: String)
	
	/* --- Variable, Enums and Structs --- */
	access(all)
	let FRC20MarketStoragePath: StoragePath
	
	access(all)
	let FRC20MarketPublicPath: PublicPath
	
	/* --- Interfaces & Resources --- */
	/// The Listing item information
	access(all)
	struct ListedItem{ 
		// The combined uid for querying in the market
		access(all)
		let rankedId: String
		
		// The address of the storefront
		access(all)
		let storefront: Address
		
		// The listing resource uuid
		access(all)
		let id: UInt64
		
		// The timestamp when the listing was added
		access(all)
		let timestamp: UFix64
		
		init(address: Address, listingID: UInt64){ 
			let storefront =
				FRC20Storefront.borrowStorefront(address: address)
				?? panic("no storefront found in address:".concat(address.toString()))
			self.storefront = address
			self.id = listingID
			let listingRef =
				storefront.borrowListing(listingID)
				?? panic("no listing id found in storefront:".concat(address.toString()))
			self.timestamp = getCurrentBlock().timestamp
			let details = listingRef.getDetails()
			// combine the price rank and listing id
			self.rankedId = details.type.rawValue.toString().concat("-").concat(
					details.priceRank().toString()
				).concat("-").concat(listingID.toString())
		}
		
		/// Get the listing details
		access(all)
		view fun getDetails(): FRC20Storefront.ListingDetails?{ 
			let listingRef = self.borrowListing()
			return listingRef?.getDetails()
		}
		
		/// Borrow the listing resource
		access(all)
		view fun borrowListing(): &FRC20Storefront.Listing?{ 
			if let storefront = self.borrowStorefront(){ 
				return storefront.borrowListing(self.id)
			}
			return nil
		}
		
		/// Borrow the storefront resource
		access(all)
		view fun borrowStorefront(): &FRC20Storefront.Storefront?{ 
			return FRC20Storefront.borrowStorefront(address: self.storefront)
		}
	}
	
	/// The Item identifier in the market
	///
	access(all)
	struct ItemIdentifier{ 
		access(all)
		let type: FRC20Storefront.ListingType
		
		access(all)
		let rank: UInt64
		
		access(all)
		let listingId: UInt64
		
		view init(type: FRC20Storefront.ListingType, rank: UInt64, listingId: UInt64){ 
			self.type = type
			self.rank = rank
			self.listingId = listingId
		}
	}
	
	/// The Listing collection public interface
	///
	access(all)
	resource interface ListingCollectionPublic{ 
		access(all)
		view fun getListedIds(): [UInt64]
		
		access(all)
		view fun getListedItem(_ id: UInt64): ListedItem?
	}
	
	/// The Listing collection
	///
	access(all)
	resource ListingCollection: ListingCollectionPublic{ 
		// Listing ID => ListedItem
		access(contract)
		let listingIDItems:{ UInt64: ListedItem}
		
		init(){ 
			self.listingIDItems ={} 
		}
		
		// Public methods
		access(all)
		view fun getListedIds(): [UInt64]{ 
			return self.listingIDItems.keys
		}
		
		access(all)
		view fun getListedItem(_ id: UInt64): ListedItem?{ 
			return self.listingIDItems[id]
		}
		
		// Internal methods
		access(contract)
		fun borrowListedItem(_ id: UInt64): &ListedItem?{ 
			return &self.listingIDItems[id] as &ListedItem?
		}
		
		access(contract)
		fun addListedItem(_ listedItem: ListedItem){ 
			self.listingIDItems[listedItem.id] = listedItem
		}
		
		access(contract)
		fun removeListedItem(_ id: UInt64){ 
			self.listingIDItems.remove(key: id)
		}
	}
	
	/// The interface for the market manager
	///
	access(all)
	resource interface MarketManager{ 
		/// Get the owner address
		access(all)
		view fun getOwnerAddress(): Address{ 
			return self.owner?.address ?? panic("The owner is not set")
		}
	}
	
	/// Market public interface
	///
	access(all)
	resource interface MarketPublic{ 
		// ---- Public read methods ----
		access(all)
		view fun getTickerName(): String
		
		access(all)
		view fun getSuperAdmin(): Address
		
		access(all)
		view fun getPriceRanks(type: FRC20Storefront.ListingType): [UInt64]
		
		access(all)
		view fun getListedIds(type: FRC20Storefront.ListingType, rank: UInt64): [UInt64]
		
		access(all)
		view fun getListedItem(
			type: FRC20Storefront.ListingType,
			rank: UInt64,
			id: UInt64
		): ListedItem?
		
		/// Get the listing item
		access(all)
		view fun getListedItemByRankdedId(rankedId: String): ListedItem?
		
		/// Get the listed item amount
		access(all)
		view fun getListedAmount(): UInt64
		
		// ---- Market operations ----
		/// Add a listing to the market
		access(all)
		fun addToList(storefront: Address, listingId: UInt64)
		
		// Anyone can remove it if the listing item has been removed or purchased.
		access(all)
		fun tryRemoveCompletedListing(rankedId: String)
		
		// ---- Accessible settings ----
		/// Check if the address is in the whitelist or admin whitelist or the market is Accessible
		access(all)
		view fun canAccess(addr: Address): Bool
		
		/// Check if the market is Accessible
		access(all)
		view fun isAccessible(): Bool
		
		/// The Accessible after timestamp
		access(all)
		view fun accessibleAfter(): UInt64?
		
		/// The Accessible conditions: tick => amount, the conditions are OR relationship
		access(all)
		view fun whitelistClaimingConditions():{ String: UFix64}
		
		/// Check if the address is valid to claim Accessible
		access(all)
		view fun isValidToClaimAccess(addr: Address): Bool
		
		/// Claim the address to the whitelist before the Accessible timestamp
		access(all)
		fun claimWhitelist(addr: Address)
		
		// --- Admin operations ---
		/// Check if the address is in the admin whitelist
		access(all)
		view fun isInAdminWhitelist(_ addr: Address): Bool
		
		/// Update the admin whitelist
		access(account)
		fun updateAdminWhitelist(mananger: &{MarketManager}, address: Address, isWhitelisted: Bool)
		
		/// Update the marketplace properties
		access(account)
		fun updateMarketplaceProperties(
			mananger: &{MarketManager},
			_ props:{ 
				FRC20FTShared.ConfigType: String
			}
		)
	}
	
	/// The Market resource
	///
	access(all)
	resource Market: MarketPublic{ 
		access(all)
		let tick: String
		
		access(self)
		let collections: @{FRC20Storefront.ListingType:{ UInt64: ListingCollection}}
		
		access(self)
		let sortedPriceRanks:{ FRC20Storefront.ListingType: [UInt64]}
		
		access(self)
		let adminWhitelist:{ Address: Bool}
		
		access(self)
		let accessWhitelist:{ Address: Bool}
		
		access(self)
		var listedItemAmount: UInt64
		
		init(tick: String){ 
			self.tick = tick
			self.collections <-{} 
			self.sortedPriceRanks ={} 
			self.listedItemAmount = 0
			self.accessWhitelist ={} 
			self.adminWhitelist ={} 
			let frc20Indexer = FRC20Indexer.getIndexer()
			let meta = frc20Indexer.getTokenMeta(tick: tick) ?? panic("Invalid tick")
			// add the deployer of the tick to the admin whitelist
			self.adminWhitelist[meta.deployer] = true
		}
		
		/// @deprecated after Cadence 1.0
		/** ---- Public Methods ---- */
		/// The ticker name of the FRC20 market
		///
		access(all)
		view fun getTickerName(): String{ 
			return self.tick
		}
		
		/// Get the super admin address
		///
		access(all)
		view fun getSuperAdmin(): Address{ 
			let meta = FRC20Indexer.getIndexer().getTokenMeta(tick: self.tick) ?? panic("Invalid tick")
			return meta.deployer
		}
		
		/// Get the price ranks
		///
		access(all)
		view fun getPriceRanks(type: FRC20Storefront.ListingType): [UInt64]{ 
			return self.sortedPriceRanks[type] ?? []
		}
		
		/// Get the listed ids
		///
		access(all)
		view fun getListedIds(type: FRC20Storefront.ListingType, rank: UInt64): [UInt64]{ 
			let colRef = self.borrowCollection(type, rank)
			return colRef?.getListedIds() ?? []
		}
		
		/// Get the listing item
		///
		access(all)
		view fun getListedItem(type: FRC20Storefront.ListingType, rank: UInt64, id: UInt64): ListedItem?{ 
			if let colRef = self.borrowCollection(type, rank){ 
				return colRef.getListedItem(id)
			}
			return nil
		}
		
		/// Get the listing item
		///
		access(all)
		view fun getListedItemByRankdedId(rankedId: String): ListedItem?{ 
			let ret = self.parseRankedId(rankedId: rankedId)
			return self.getListedItem(type: ret.type, rank: ret.rank, id: ret.listingId)
		}
		
		access(all)
		view fun getListedAmount(): UInt64{ 
			return self.listedItemAmount
		}
		
		/// Add a listing to the market
		access(all)
		fun addToList(storefront: Address, listingId: UInt64){ 
			pre{ 
				self.canAccess(addr: storefront):
					"The storefront address is not Accessible"
			}
			let item = ListedItem(address: storefront, listingID: listingId)
			let listingRef = item.borrowListing() ?? panic("no listing id found in storefront:".concat(storefront.toString()))
			let details = listingRef.getDetails()
			/// The listing item must be available
			assert(details.status == FRC20Storefront.ListingStatus.Available, message: "The listing is not active")
			/// The tick should be the same as the market's ticker name
			assert(details.tick == self.tick, message: "The listing tick is not the same as the market's ticker name")
			let rank = details.priceRank()
			let collRef = self.borrowOrCreateCollection(details.type, rank)
			collRef.addListedItem(item)
			
			// update the sorted price ranks
			let ranks = self.getPriceRanks(type: details.type)
			// add the rank if it's not in the list
			if !ranks.contains(rank){ 
				var idx: Int = -1
				// Find the right index to insert, rank should be in ascending order
				for i, curr in ranks{ 
					if curr > rank{ 
						idx = i
						break
					}
				}
				if idx == -1{ 
					// append to the end
					ranks.append(rank)
				} else{ 
					// insert at the right index
					ranks.insert(at: idx, rank)
				}
				// update the sorted price ranks
				self.sortedPriceRanks[details.type] = ranks
			}
			self.listedItemAmount = self.listedItemAmount + 1
			// emit event
			emit ListingAdded(tick: self.tick, storefront: storefront, listingId: listingId, type: details.type.rawValue)
		}
		
		// Anyone can remove it if the listing item has been removed or purchased.
		// Do not panic
		access(all)
		fun tryRemoveCompletedListing(rankedId: String){ 
			let parsed = self.parseRankedId(rankedId: rankedId)
			if let collRef = self.borrowCollection(parsed.type, parsed.rank){ 
				if let listedItemRef = collRef.borrowListedItem(parsed.listingId){ 
					let listingRef = listedItemRef.borrowListing()
					let storefrontAddr = listedItemRef.storefront
					var removed = false
					if listingRef == nil{ 
						// remove the listed item if the listing resource is not found
						collRef.removeListedItem(parsed.listingId)
						removed = true
					} else{ 
						let details = listingRef?.getDetails()
						// remove the listed item if the listing is cancelled or completed
						if (details!).isCancelled() || (details!).isCompleted(){ 
							// clean up the listing if it's cancelled or completed
							if let storefront = listedItemRef.borrowStorefront(){ 
								storefront.tryCleanupFinishedListing(parsed.listingId)
							}
							// remove the listed item
							collRef.removeListedItem(parsed.listingId)
							removed = true
						}
					}
					// emit event if removed
					if removed{ 
						let listedIds = collRef.getListedIds()
						// remove the rank if the collection is empty
						if collRef.getListedIds().length == 0{ 
							// update the sorted price ranks
							let ranks = self.getPriceRanks(type: parsed.type)
							let priceRank = parsed.rank
							if let rankIdx: Int = ranks.firstIndex(of: priceRank){ 
								(self.sortedPriceRanks[parsed.type]!).remove(at: rankIdx)
							}
						}
						self.listedItemAmount = self.listedItemAmount - 1
						emit ListingRemoved(tick: self.tick, storefront: storefrontAddr, listingId: parsed.listingId, type: parsed.type.rawValue)
					}
				}
			}
		}
		
		// ---- Admin operations ----
		/// Check if the address is in the admin whitelist
		access(all)
		view fun isInAdminWhitelist(_ addr: Address): Bool{ 
			return self.adminWhitelist[addr] ?? false
		}
		
		/// Update the admin whitelist
		/// The method is called by the manager resource
		///
		access(account)
		fun updateAdminWhitelist(mananger: &{MarketManager}, address: Address, isWhitelisted: Bool){ 
			pre{ 
				self.isInAdminWhitelist(mananger.getOwnerAddress()):
					"The manager is not in the admin whitelist"
			}
			let superAdmin = self.getSuperAdmin()
			if superAdmin == address && !isWhitelisted{ 
				panic("The super admin can not be removed from the admin whitelist")
			}
			self.adminWhitelist[address] = isWhitelisted
			emit MarketAdminWhitelistUpdated(tick: self.tick, addr: address, isWhitelisted: isWhitelisted)
		}
		
		/// Update the marketplace properties
		/// The method is called by the manager resource
		///
		access(account)
		fun updateMarketplaceProperties(mananger: &{MarketManager}, _ props:{ FRC20FTShared.ConfigType: String}){ 
			pre{ 
				self.isInAdminWhitelist(mananger.getOwnerAddress()):
					"The manager is not in the admin whitelist"
			}
			// save the properties to the shared store
			if let storeRef = self.borrowSharedStore(){ 
				for key in props.keys{ 
					var value: AnyStruct? = nil
					switch key{ 
						case FRC20FTShared.ConfigType.MarketFeeSharedRatio:
							value = UFix64.fromString(props[key]!) ?? panic("Invalid ratio")
							break
						case FRC20FTShared.ConfigType.MarketFeeTokenSpecificRatio:
							value = UFix64.fromString(props[key]!) ?? panic("Invalid ratio")
							break
						case FRC20FTShared.ConfigType.MarketFeeDeployerRatio:
							value = UFix64.fromString(props[key]!) ?? panic("Invalid ratio")
							break
						case FRC20FTShared.ConfigType.MarketAccessibleAfter:
							value = UInt64.fromString(props[key]!) ?? panic("Invalid timestamp")
							break
						case FRC20FTShared.ConfigType.MarketWhitelistClaimingToken:
							value = props[key]!
							break
						case FRC20FTShared.ConfigType.MarketWhitelistClaimingAmount:
							value = UFix64.fromString(props[key]!) ?? panic("Invalid amount")
							break
					}
					if value != nil{ 
						storeRef.setByEnum(key, value: value)
						
						// emit event
						emit MarketAdminPropertiesUpdated(tick: self.tick, key: key.rawValue, value: props[key]!)
					}
				}
			} else{ 
				panic("Failed to borrow the shared store for the market: ".concat(self.tick))
			}
		}
		
		// TODO more admin operations
		// ---- Accessible settings ----
		/// Check if the address is in the whitelist or admin whitelist or the market is Accessible
		///
		access(all)
		view fun canAccess(addr: Address): Bool{ 
			let isAccessibleNow = self.isAccessible()
			if isAccessibleNow{ 
				return true
			}
			let isWhitelisted = self.accessWhitelist[addr] ?? false
			if isWhitelisted{ 
				return true
			}
			let isAdmin = self.isInAdminWhitelist(addr)
			if isAdmin{ 
				return true
			}
			return false
		}
		
		/// Check if the market is Accessible
		///
		access(all)
		view fun isAccessible(): Bool{ 
			if let after = self.accessibleAfter(){ 
				return UInt64(getCurrentBlock().timestamp) >= after / 1000
			}
			return true
		}
		
		/// The Accessible after timestamp
		///
		access(all)
		view fun accessibleAfter(): UInt64?{ 
			if let storeRef = self.borrowSharedStore(){ 
				return storeRef.getByEnum(FRC20FTShared.ConfigType.MarketAccessibleAfter) as! UInt64?
			}
			return nil
		}
		
		/// The Accessible conditions: tick => amount, the conditions are OR relationship
		///
		access(all)
		view fun whitelistClaimingConditions():{ String: UFix64}{ 
			let ret:{ String: UFix64} ={} 
			if let storeRef = self.borrowSharedStore(){ 
				let name = storeRef.getByEnum(FRC20FTShared.ConfigType.MarketWhitelistClaimingToken) as! String?
				let amt = storeRef.getByEnum(FRC20FTShared.ConfigType.MarketWhitelistClaimingAmount) as! UFix64?
				if name != nil && amt != nil{ 
					ret[name!] = amt
				}
			}
			return ret
		}
		
		/// Check if the address is valid to claim Accessible
		///
		access(all)
		view fun isValidToClaimAccess(addr: Address): Bool{ 
			let isAccessibleNow = self.isAccessible()
			if isAccessibleNow{ 
				return false
			}
			let conds = self.whitelistClaimingConditions()
			// no conditions set, so you can not claim
			if conds.keys.length == 0{ 
				return false
			}
			let frc20Indexer = FRC20Indexer.getIndexer()
			for tick in conds.keys{ 
				let balance = frc20Indexer.getBalance(tick: tick, addr: addr)
				if balance >= conds[tick]!{ 
					return true
				}
			}
			return false
		}
		
		/// Claim the address to the whitelist before the Accessible timestamp
		///
		access(all)
		fun claimWhitelist(addr: Address){ 
			let valid = self.isValidToClaimAccess(addr: addr)
			// add to the whitelist if valid
			if valid{ 
				self.accessWhitelist[addr] = true
				emit MarketWhitelistClaimed(tick: self.tick, addr: addr)
			}
		}
		
		/** ---- Internal Methods ---- */
		/// Borrow the shared store
		///
		access(self)
		view fun borrowSharedStore(): &FRC20FTShared.SharedStore?{ 
			return FRC20FTShared.borrowStoreRef((self.owner!).address)
		}
		
		/// Parse the ranked id
		///
		access(self)
		view fun parseRankedId(rankedId: String): ItemIdentifier{ 
			let parts = StringUtils.split(rankedId, "-")
			assert(parts.length == 3, message: "Invalid rankedId format, should be <type>-<rank>-<id>")
			let type = FRC20Storefront.ListingType(rawValue: UInt8.fromString(parts[0]) ?? panic("Invalid type")) ?? panic("Invalid listing type")
			let rank = UInt64.fromString(parts[1]) ?? panic("Invalid rank")
			let id = UInt64.fromString(parts[2]) ?? panic("Invalid id")
			return ItemIdentifier(type: type, rank: rank, listingId: id)
		}
		
		/// Borrow or create the collection
		///
		access(self)
		fun borrowOrCreateCollection(_ type: FRC20Storefront.ListingType, _ rank: UInt64): &ListingCollection{ 
			var tryDictRef = self._borrowCollectionDict(type)
			if tryDictRef == nil{ 
				self.collections[type] <-!{} 
				tryDictRef = self._borrowCollectionDict(type)
			}
			let dictRef = tryDictRef!
			var collRef = dictRef[rank] as &FRC20Marketplace.ListingCollection?
			if collRef == nil{ 
				dictRef[rank] <-! create ListingCollection()
				collRef = dictRef[rank] as &FRC20Marketplace.ListingCollection?
			}
			return collRef ?? panic("Failed to create collection")
		}
		
		/// Get the collection by rank
		access(self)
		view fun borrowCollection(_ type: FRC20Storefront.ListingType, _ rank: UInt64): &ListingCollection?{ 
			if let colDictRef = self._borrowCollectionDict(type){ 
				return colDictRef[rank] as &FRC20Marketplace.ListingCollection?
			}
			return nil
		}
		
		access(self)
		view fun _borrowCollectionDict(_ type: FRC20Storefront.ListingType): &{UInt64: ListingCollection}?{ 
			return &self.collections[type] as &{UInt64: ListingCollection}?
		}
	}
	
	/** ---– Account Access methods ---- */
	/// Create a new market
	///
	access(account)
	fun createMarket(_ tick: String): @Market{ 
		let market <- create Market(tick: tick)
		emit MarketCreated(tick: tick, uuid: market.uuid)
		return <-market
	}
	
	/** ---– Public methods ---- */
	/// The helper method to get the market resource reference
	///
	access(all)
	fun borrowMarket(_ addr: Address): &Market?{ 
		return getAccount(addr).capabilities.get<&Market>(self.FRC20MarketPublicPath).borrow()
	}
	
	init(){ 
		let identifier = "FRC20Market_".concat(self.account.address.toString())
		self.FRC20MarketStoragePath = StoragePath(identifier: identifier)!
		self.FRC20MarketPublicPath = PublicPath(identifier: identifier)!
		emit ContractInitialized()
	}
}
