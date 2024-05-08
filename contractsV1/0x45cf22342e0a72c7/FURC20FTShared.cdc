import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract FURC20FTShared{ 
	/* --- Events --- */
	/// The event that is emitted when the shared store is updated
	access(all)
	event SharedStoreKeyUpdated(key: String, valueType: Type)
	
	/// The event that is emitted when tokens are created
	access(all)
	event TokenChangeCreated(tick: String, amount: UFix64, from: Address, changeUuid: UInt64)
	
	/// The event that is emitted when tokens are withdrawn from a Vault
	access(all)
	event TokenChangeWithdrawn(tick: String, amount: UFix64, from: Address, changeUuid: UInt64)
	
	/// The event that is emitted when tokens are deposited to a Vault
	access(all)
	event TokenChangeMerged(
		tick: String,
		amount: UFix64,
		from: Address,
		changeUuid: UInt64,
		fromChangeUuid: UInt64
	)
	
	/// The event that is emitted when tokens are extracted
	access(all)
	event TokenChangeExtracted(tick: String, amount: UFix64, from: Address, changeUuid: UInt64)
	
	/// The event that is emitted when a hook is added
	access(all)
	event VaildatedHookTypeAdded(type: Type)
	
	/// The event that is emitted when a hook is added
	access(all)
	event TransactionHookAdded(hooksOwner: Address, hookType: Type)
	
	/// The event that is emitted when a deal is updated
	access(all)
	event TransactionHooksOnDeal(
		hooksOwner: Address,
		executedHookType: Type,
		storefront: Address,
		listingId: UInt64
	)
	
	/* --- Variable, Enums and Structs --- */
	access(all)
	let SharedStoreStoragePath: StoragePath
	
	access(all)
	let SharedStorePublicPath: PublicPath
	
	access(all)
	let TransactionHookStoragePath: StoragePath
	
	access(all)
	let TransactionHookPublicPath: PublicPath
	
	/* --- Interfaces & Resources --- */
	/// Cut type for the sale
	///
	access(all)
	enum SaleCutType: UInt8{ 
		access(all)
		case TokenTreasury
		
		access(all)
		case PlatformTreasury
		
		access(all)
		case PlatformStakers
		
		access(all)
		case SellMaker
		
		access(all)
		case BuyTaker
		
		access(all)
		case Commission
		
		access(all)
		case MarketplacePortion
	}
	
	/// Sale cut struct for the sale
	///
	access(all)
	struct SaleCut{ 
		access(all)
		let type: SaleCutType
		
		access(all)
		let ratio: UFix64
		
		access(all)
		let receiver: Capability<&{FungibleToken.Receiver}>?
		
		init(type: SaleCutType, ratio: UFix64, receiver: Capability<&{FungibleToken.Receiver}>?){ 
			if type == FURC20FTShared.SaleCutType.SellMaker{ 
				assert(receiver != nil, message: "Receiver should not be nil for consumer cut")
			} else{ 
				assert(receiver == nil, message: "Receiver should be nil for non-consumer cut")
			}
			self.type = type
			self.ratio = ratio
			self.receiver = receiver
		}
	}
	
	/// It a general interface for the Change of FURC20 Fungible Token
	///
	access(all)
	resource interface Balance{ 
		/// The ticker symbol of this change
		/// If the tick is "", it means the change is backed by FlowToken.Vault
		///
		access(all)
		let tick: String
		
		/// The type of the FT Vault, Optional
		///
		access(all)
		var ftVault: @{FungibleToken.Vault}?
		
		/// The balance of this change
		///
		access(all)
		var balance: UFix64?
		
		// The conforming type must declare an initializer
		// that allows providing the initial balance of the Vault
		//
		init(tick: String, from: Address, balance: UFix64?, ftVault: @{FungibleToken.Vault}?)
		
		/// Get the balance of this Change
		///
		access(all)
		view fun getBalance(): UFix64{ 
			return self.ftVault?.balance ?? self.balance!
		}
		
		/// Check if this Change is empty
		///
		access(all)
		view fun isEmpty(): Bool{ 
			return self.getBalance() == 0.0
		}
		
		/// Check if this Change is backed by a Vault
		///
		access(all)
		view fun isBackedByVault(): Bool{ 
			return self.ftVault != nil
		}
		
		/// Check if this Change is backed by a FlowToken Vault
		///
		access(all)
		view fun isBackedByFlowTokenVault(): Bool{ 
			return self.tick == "" && self.isBackedByVault()
		}
		
		/// Get the type of the Vault
		///
		access(all)
		view fun getVaultType(): Type?{ 
			return self.ftVault?.getType()
		}
	}
	
	/// It a general interface for the Settler of FURC20 Fungible Token
	///
	access(all)
	resource interface Settler{ 
		/// Withdraw the given amount of tokens, as a FungibleToken Vault
		///
		access(all)
		fun withdrawAsVault(amount: UFix64): @{FungibleToken.Vault}{ 
			post{ 
				// `result` refers to the return value
				result.balance == amount:
					"Withdrawal amount must be the same as the balance of the withdrawn Vault"
			}
		}
		
		/// Extract all balance of this Change
		///
		access(all)
		fun extractAsVault(): @{FungibleToken.Vault}
		
		/// Extract all balance of input Change and deposit to self, this method is only available for the contracts in the same account
		///
		access(account)
		fun merge(from: @Change)
		
		/// Withdraw the given amount of tokens, as a FURC20 Fungible Token Change
		///
		access(account)
		fun withdrawAsChange(amount: UFix64): @Change{ 
			post{ 
				// `result` refers to the return value
				result.getBalance() == amount:
					"Withdrawal amount must be the same as the balance of the withdrawn Change"
			}
		}
		
		/// Extract all balance of this Change
		///
		access(account)
		fun extract(): UFix64
	}
	
	/// It a general resource for the Change of FURC20 Fungible Token
	///
	access(all)
	resource Change: Balance, Settler{ 
		/// The ticker symbol of this change
		access(all)
		let tick: String
		
		/// The address of the owner of this change
		access(all)
		let from: Address
		
		/// The type of the FT Vault, Optional
		access(all)
		var ftVault: @{FungibleToken.Vault}?
		
		// The token balance of this Change
		access(all)
		var balance: UFix64?
		
		init(tick: String, from: Address, balance: UFix64?, ftVault: @{FungibleToken.Vault}?){ 
			pre{ 
				balance != nil || ftVault != nil:
					"The balance of the FT Vault or the initial balance must not be nil"
			}
			post{ 
				self.tick == tick:
					"Tick must be equal to the provided tick"
				self.from == from:
					"The owner of the Change must be the same as the owner of the Change"
				self.balance == balance:
					"Balance must be equal to the initial balance"
				self.ftVault == nil || self.balance == nil:
					"Either FT Vault or balance must be not nil"
			}
			
			// If the tick is "", it means the change is backed by FlowToken.Vault
			if tick == ""{ 
				assert(ftVault != nil && balance == nil, message: "FT Vault must not be nil for tick = \"\"")
				assert(ftVault.isInstance(OptionalType(Type<@FlowToken.Vault>())), message: "FT Vault must be an instance of FlowToken.Vault")
			}
			self.tick = tick
			self.from = from
			self.balance = balance
			self.ftVault <- ftVault
			emit TokenChangeCreated(tick: self.tick, amount: self.getBalance(), from: self.from, changeUuid: self.uuid)
		}
		
		/// Subtracts `amount` from the Vault's balance
		/// and returns a new Vault with the subtracted balance
		///
		access(all)
		fun withdrawAsVault(amount: UFix64): @{FungibleToken.Vault}{ 
			pre{ 
				self.balance == nil:
					"Balance must be nil for withdrawAsVault"
				self.isBackedByVault() == true:
					"The Change must be backed by a Vault"
				self.ftVault?.balance! >= amount:
					"Amount withdrawn must be less than or equal than the balance of the Vault"
			}
			post{ 
				// result's type must be the same as the type of the original Vault
				self.ftVault?.balance == before(self.ftVault?.balance)! - amount:
					"New FT Vault balance must be the difference of the previous balance and the withdrawn Vault"
				// result's type must be the same as the type of the original Vault
				result.getType() == self.ftVault?.getType() ?? panic("The FT Vault must not be nil"):
					"The type of the returned Vault must be the same as the type of the original Vault"
			}
			let vaultRef = self.borrowVault()
			let ret <- vaultRef.withdraw(amount: amount)
			emit TokenChangeWithdrawn(tick: self.tick, amount: amount, from: self.from, changeUuid: self.uuid)
			return <-ret
		}
		
		/// Extract all balance of this Change
		///
		access(all)
		fun extractAsVault(): @{FungibleToken.Vault}{ 
			pre{ 
				self.isBackedByVault() == true:
					"The Change must be backed by a Vault"
				self.getBalance() > UFix64(0):
					"Balance must be greater than zero"
			}
			post{ 
				self.getBalance() == UFix64(0):
					"Balance must be zero after extraction"
				result.balance == before(self.getBalance()):
					"Extracted amount must be the same as the balance of the Change"
			}
			let vaultRef = self.borrowVault()
			let balanceToExtract = self.getBalance()
			let ret <- vaultRef.withdraw(amount: balanceToExtract)
			emit TokenChangeExtracted(tick: self.tick, amount: balanceToExtract, from: self.from, changeUuid: self.uuid)
			return <-ret
		}
		
		/// Extract all balance of input Change and deposit to self, this method is only available for the contracts in the same account
		///
		access(account)
		fun merge(from: @Change){ 
			pre{ 
				self.isBackedByVault() == from.isBackedByVault():
					"The Change must be backed by a Vault if and only if the input Change is backed by a Vault"
				from.tick == self.tick:
					"Tick must be equal to the provided tick"
				from.from == self.from:
					"The owner of the Change must be the same as the owner of the Change"
			}
			post{ 
				self.getBalance() == before(self.getBalance()) + before(from.getBalance()):
					"New Vault balance must be the sum of the previous balance and the deposited Vault"
			}
			var extractAmount: UFix64 = 0.0
			if self.isBackedByVault(){ 
				assert(self.ftVault != nil && from.ftVault != nil, message: "FT Vault must not be nil for merge")
				let extracted <- from.extractAsVault()
				extractAmount = extracted.balance
				// Deposit the extracted Vault to self
				let vaultRef = self.borrowVault()
				vaultRef.deposit(from: <-extracted)
			} else{ 
				assert(self.balance != nil && from.balance != nil, message: "Balance must not be nil for merge")
				extractAmount = from.extract()
				self.balance = self.balance! + extractAmount
			}
			
			// emit TokenChangeMerged event
			emit TokenChangeMerged(tick: self.tick, amount: extractAmount, from: self.from, changeUuid: self.uuid, fromChangeUuid: from.uuid)
			// Destroy the Change that we extracted from
			destroy from
		}
		
		/// Withdraw the given amount of tokens, as a FURC20 Fungible Token Change
		///
		access(account)
		fun withdrawAsChange(amount: UFix64): @Change{ 
			pre{ 
				self.isBackedByVault() == false:
					"The Change must not be backed by a Vault"
				self.balance != nil:
					"Balance must not be nil for withdrawAsChange"
				self.balance! >= amount:
					"Amount withdrawn must be less than or equal than the balance of the Vault"
			}
			post{ 
				// result's type must be the same as the type of the original Change
				result.tick == self.tick:
					"Tick must be equal to the provided tick"
				// use the special function `before` to get the value of the `balance` field
				self.balance == before(self.balance)! - amount:
					"New Change balance must be the difference of the previous balance and the withdrawn Change"
			}
			self.balance = self.balance! - amount
			emit TokenChangeWithdrawn(tick: self.tick, amount: amount, from: self.from, changeUuid: self.uuid)
			return <-create Change(tick: self.tick, from: self.from, balance: amount, ftVault: nil)
		}
		
		/// Extract all balance of this Change, this method is only available for the contracts in the same account
		///
		access(account)
		fun extract(): UFix64{ 
			pre{ 
				!self.isBackedByVault():
					"The Change must not be backed by a Vault"
				self.getBalance() > UFix64(0):
					"Balance must be greater than zero"
			}
			post{ 
				self.getBalance() == UFix64(0):
					"Balance must be zero after extraction"
				result == before(self.getBalance()):
					"Extracted amount must be the same as the balance of the Change"
			}
			var balanceToExtract: UFix64 = self.balance ?? panic("The balance of the Change must be specified")
			self.balance = 0.0
			emit TokenChangeExtracted(tick: self.tick, amount: balanceToExtract, from: self.from, changeUuid: self.uuid)
			return balanceToExtract
		}
		
		/// Borrow the underlying Vault of this Change
		///
		access(self)
		fun borrowVault(): &{FungibleToken.Vault}{ 
			return &self.ftVault as &{FungibleToken.Vault}? ?? panic("The Change is not backed by a Vault")
		}
	}
	
	/// Only the owner of the account can call this method
	///
	access(account)
	fun createChange(
		tick: String,
		from: Address,
		balance: UFix64?,
		ftVault: @{FungibleToken.Vault}?
	): @Change{ 
		return <-create Change(tick: tick, from: from, balance: balance, ftVault: <-ftVault)
	}
	
	/** --- Temporary order resources --- */
	/// It a temporary resource combining change and cuts
	///
	access(all)
	resource ValidFrozenOrder{ 
		access(all)
		let tick: String
		
		access(all)
		let amount: UFix64
		
		access(all)
		let totalPrice: UFix64
		
		access(all)
		let cuts: [SaleCut]
		
		access(all)
		var change: @Change?
		
		init(tick: String, amount: UFix64, totalPrice: UFix64, cuts: [SaleCut], _ change: @Change){ 
			pre{ 
				amount > UFix64(0):
					"Amount must be greater than zero"
				cuts.length > 0:
					"Cuts must not be empty"
				change.getBalance() > UFix64(0):
					"Balance must be greater than zero"
			}
			self.tick = tick
			self.amount = amount
			self.totalPrice = totalPrice
			self.change <- change
			self.cuts = cuts
		}
		
		/// Extract all balance of this Change, this method is only available for the contracts in the same account
		///
		access(account)
		fun extract(): @Change{ 
			pre{ 
				self.change != nil:
					"Change must not be nil for extract"
			}
			post{ 
				self.change == nil:
					"Change must be nil after extraction"
				result.getBalance() == before(self.change?.getBalance()):
					"Extracted amount must be the same as the balance of the Change"
			}
			var out: @Change? <- nil
			self.change <-> out
			return <-out!
		}
	}
	
	/// Only the contracts in this account can call this method
	///
	access(account)
	fun createValidFrozenOrder(
		tick: String,
		amount: UFix64,
		totalPrice: UFix64,
		cuts: [
			SaleCut
		],
		change: @Change
	): @ValidFrozenOrder{ 
		return <-create ValidFrozenOrder(
			tick: tick,
			amount: amount,
			totalPrice: totalPrice,
			cuts: cuts,
			<-change
		)
	}
	
	/** Shared store resource */
	/// The Market config type
	///
	access(all)
	enum ConfigType: UInt8{ 
		access(all)
		case PlatformSalesFee
		
		access(all)
		case PlatformSalesCutTreasuryPoolRatio
		
		access(all)
		case PlatformSalesCutPlatformPoolRatio
		
		access(all)
		case PlatformSalesCutPlatformStakersRatio
		
		access(all)
		case PlatformSalesCutMarketRatio
		
		access(all)
		case PlatofrmMarketplaceStakingToken
		
		access(all)
		case MarketFeeSharedRatio
		
		access(all)
		case MarketFeeTokenSpecificRatio
		
		access(all)
		case MarketFeeDeployerRatio
		
		access(all)
		case MarketAccessibleAfter
		
		access(all)
		case MarketWhitelistClaimingToken
		
		access(all)
		case MarketWhitelistClaimingAmount
	}
	
	/* --- Public Methods --- */
	access(all)
	resource interface SharedStorePublic{ 
		/// Get the key by type
		///
		access(all)
		view fun getKeyByEnum(_ type: ConfigType): String?{ 
			var key: String? = nil
			// get the key by type
			switch type{ 
				case ConfigType.PlatformSalesFee:
					key = "platform:SalesFee"
					break
				case ConfigType.PlatformSalesCutTreasuryPoolRatio:
					key = "platform:SalesCutTreasuryPoolRatio"
					break
				case ConfigType.PlatformSalesCutPlatformPoolRatio:
					key = "platform:SalesCutPlatformPoolRatio"
					break
				case ConfigType.PlatformSalesCutPlatformStakersRatio:
					key = "platform:SalesCutPlatformStakersRatio"
					break
				case ConfigType.PlatformSalesCutMarketRatio:
					key = "platform:SalesCutMarketRatio"
					break
				case ConfigType.PlatofrmMarketplaceStakingToken:
					key = "platform:MarketplaceStakingToken"
					break
				case ConfigType.MarketFeeSharedRatio:
					key = "market:FeeSharedRatio"
					break
				case ConfigType.MarketFeeTokenSpecificRatio:
					key = "market:FeeTokenSpecificRatio"
					break
				case ConfigType.MarketFeeDeployerRatio:
					key = "market:FeeDeployerRatio"
					break
				case ConfigType.MarketAccessibleAfter:
					key = "market:AccessibleAfter"
					break
				case ConfigType.MarketWhitelistClaimingToken:
					key = "market:WhitelistClaimingToken"
					break
				case ConfigType.MarketWhitelistClaimingAmount:
					key = "market:WhitelistClaimingAmount"
					break
			}
			return key
		}
		
		// getter for the shared store
		access(all)
		fun get(_ key: String): AnyStruct?
		
		// getter for the shared store
		access(all)
		fun getByEnum(_ type: ConfigType): AnyStruct?{ 
			if let key = self.getKeyByEnum(type){ 
				return self.get(key)
			}
			return nil
		}
		
		// --- Account Methods ---
		/// Set the value
		access(account)
		fun set(_ key: String, value: AnyStruct)
		
		/// Set the value by type
		access(account)
		fun setByEnum(_ type: ConfigType, value: AnyStruct)
	}
	
	access(all)
	resource SharedStore: SharedStorePublic{ 
		access(self)
		var data:{ String: AnyStruct}
		
		init(){ 
			self.data ={} 
		}
		
		/// getter for the shared store
		///
		access(all)
		fun get(_ key: String): AnyStruct?{ 
			return self.data[key]
		}
		
		/// Set the value
		///
		access(account)
		fun set(_ key: String, value: AnyStruct){ 
			self.data[key] = value
			emit SharedStoreKeyUpdated(key: key, valueType: value.getType())
		}
		
		/// Set the value by type
		///
		access(account)
		fun setByEnum(_ type: ConfigType, value: AnyStruct){ 
			if let key = self.getKeyByEnum(type){ 
				self.set(key, value: value)
			}
		}
	}
	
	/* --- Public Methods --- */
	/// Get the shared store
	///
	access(all)
	fun borrowGlobalStoreRef(): &SharedStore{ 
		let addr = self.account.address
		return self.borrowStoreRef(addr) ?? panic("Could not borrow capability from public store")
	}
	
	/// Borrow the shared store
	///
	access(all)
	fun borrowStoreRef(_ address: Address): &SharedStore?{ 
		return getAccount(address).capabilities.get<&SharedStore>(self.SharedStorePublicPath)
			.borrow()
	}
	
	/* --- Account Methods --- */
	/// Create the instance of the shared store
	///
	access(account)
	fun createSharedStore(): @SharedStore{ 
		return <-create SharedStore()
	}
	
	/** Transaction hooks */
	access(contract)
	let validatedHookTypes:{ Type: Bool}
	
	/// It a general interface for the Transaction Hook
	///
	access(all)
	resource interface TransactionHook{ 
		/// The method that is invoked when the transaction is executed
		/// Before try-catch is deployed, please ensure that there will be no panic inside the method.
		///
		access(account)
		fun onDeal(
			storefront: Address,
			listingId: UInt64,
			seller: Address,
			buyer: Address,
			tick: String,
			dealAmount: UFix64,
			dealPrice: UFix64,
			totalAmountInListing: UFix64
		)
	}
	
	access(account)
	fun registerHookType(_ type: Type){ 
		if type.isSubtype(of: Type<@{TransactionHook}>()){ 
			self.validatedHookTypes[type] = true
			emit VaildatedHookTypeAdded(type: type)
		}
	}
	
	access(all)
	fun getAllValidatedHookTypes(): [Type]{ 
		return self.validatedHookTypes.keys
	}
	
	access(all)
	fun isHookTypeValidated(_ type: Type): Bool{ 
		return self.validatedHookTypes[type] == true
	}
	
	/// It a general resource for the Transaction Hook
	///
	access(all)
	resource Hooks: TransactionHook{ 
		access(self)
		let hooks:{ Type: Capability<&{TransactionHook}>}
		
		init(){ 
			self.hooks ={} 
		}
		
		// --- Public Methods ---
		/// Check if the hook exists
		///
		access(all)
		fun hasHook(_ type: Type): Bool{ 
			return self.hooks[type] != nil
		}
		
		// --- Account Methods ---
		access(all)
		fun addHook(_ hook: Capability<&{TransactionHook}>){ 
			pre{ 
				hook.check():
					"The hook must be valid"
			}
			let hookRef = hook.borrow() ?? panic("Could not borrow reference from hook capability.")
			let type = hookRef.getType()
			assert(self.hooks[type] == nil, message: "Hook of type ".concat(type.identifier).concat("already exists."))
			self.hooks[type] = hook
			emit TransactionHookAdded(hooksOwner: self.owner?.address ?? panic("Hooks owner must not be nil"), hookType: type)
		}
		
		/// The method that is invoked when the transaction is executed
		///
		access(account)
		fun onDeal(storefront: Address, listingId: UInt64, seller: Address, buyer: Address, tick: String, dealAmount: UFix64, dealPrice: UFix64, totalAmountInListing: UFix64){ 
			let hooksOwnerAddr = self.owner?.address
			if hooksOwnerAddr == nil{ 
				return
			}
			
			// call all hooks
			for type in self.hooks.keys{ 
				// check if the hook type is validated
				if !FURC20FTShared.isHookTypeValidated(type){ 
					continue
				}
				// get the hook capability
				if let hookCap = self.hooks[type]{ 
					let valid = hookCap.check()
					if !valid{ 
						continue
					}
					if let ref = hookCap.borrow(){ 
						// call hook
						ref.onDeal(storefront: storefront, listingId: listingId, seller: seller, buyer: buyer, tick: tick, dealAmount: dealAmount, dealPrice: dealPrice, totalAmountInListing: totalAmountInListing)
						
						// emit event
						emit TransactionHooksOnDeal(hooksOwner: hooksOwnerAddr!, executedHookType: type, storefront: storefront, listingId: listingId)
					}
				}
			}
		}
	}
	
	/// Create the instance of the hooks resource
	///
	access(all)
	fun createHooks(): @Hooks{ 
		return <-create Hooks()
	}
	
	/// Only the owner of the account can call this method
	///
	access(account)
	fun borrowTransactionHook(_ address: Address): &{TransactionHook}?{ 
		return getAccount(address).capabilities.get<&{TransactionHook}>(
			self.TransactionHookPublicPath
		).borrow()
	}
	
	init(){ 
		// Transaction Hook
		let hookIdentifier =
			"FURC20FTShared_".concat(self.account.address.toString()).concat("_transactionHook")
		self.TransactionHookStoragePath = StoragePath(identifier: hookIdentifier)!
		self.TransactionHookPublicPath = PublicPath(identifier: hookIdentifier)!
		self.validatedHookTypes ={} 
		
		// Shared Store
		let identifier = "FURC20SharedStore_".concat(self.account.address.toString())
		self.SharedStoreStoragePath = StoragePath(identifier: identifier)!
		self.SharedStorePublicPath = PublicPath(identifier: identifier)!
		
		// create the indexer
		self.account.storage.save(<-self.createSharedStore(), to: self.SharedStoreStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&SharedStore>(self.SharedStoreStoragePath)
		self.account.capabilities.publish(capability_1, at: self.SharedStorePublicPath)
	}
}
