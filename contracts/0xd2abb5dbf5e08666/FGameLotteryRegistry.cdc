/**
> Author: FIXeS World <https://fixes.world/>

# FGameLotteryRegistry

This contract is the lottery registry contract.
It is responsible for managing the lottery pools and the whitelist of the controllers.

*/
// Fixes Imports
import Fixes from "./Fixes.cdc"
import FixesHeartbeat from "./FixesHeartbeat.cdc"
import FRC20FTShared from "./FRC20FTShared.cdc"
import FRC20Indexer from "./FRC20Indexer.cdc"
import FGameLottery from "./FGameLottery.cdc"
import FRC20Staking from "./FRC20Staking.cdc"
import FRC20AccountsPool from "./FRC20AccountsPool.cdc"

access(all) contract FGameLotteryRegistry {
    /* --- Events --- */
    /// Event emitted when the contract is initialized
    access(all) event ContractInitialized()
    /// Event emitted when the whitelist is updated
    access(all) event RegistryWhitelistUpdated(address: Address, isWhitelisted: Bool)
    /// Event emitted when a lottery pool is enabled
    access(all) event LotteryPoolEnabled(name: String, tick: String, ticketPrice: UFix64, epochInterval: UFix64, address: Address, by: Address)
    /// Event emitted when a lottery pool resources are updated
    access(all) event LotteryPoolResourcesUpdated(name: String, address: Address, by: Address)

    /* --- Variable, Enums and Structs --- */

    access(all) let registryStoragePath: StoragePath
    access(all) let registryPublicPath: PublicPath
    access(all) let registryControllerStoragePath: StoragePath

    /* --- Interfaces & Resources --- */

    /// Resource inferface for the Lottery registry
    ///
    access(all) resource interface RegistryPublic {
        access(all) view
        fun isWhitelisted(address: Address): Bool
        access(all) view
        fun getLotteryPoolNames(): [String]
        access(all) view
        fun getGameWorldKey(_ name: String): String
        access(all) view
        fun getLotteryPoolAddress(_ name: String): Address?
        // --- Write methods ---
        access(contract)
        fun onRegisterLotteryPool(_ name: String)
    }

    /// Resource for the Lottery registry
    ///
    access(all) resource Registry: RegistryPublic {
        access(self)
        let registered: [String]
        access(self)
        let whitelist: {Address: Bool}

        init() {
            self.whitelist = {}
            self.registered = []
        }

        // --- Public methods ---

        access(all) view
        fun isWhitelisted(address: Address): Bool {
            return self.whitelist[address] ?? false
        }

        access(all) view
        fun getLotteryPoolNames(): [String] {
            return self.registered
        }

        access(all) view
        fun getGameWorldKey(_ name: String): String {
            return "Lottery_".concat(name)
        }

        access(all) view
        fun getLotteryPoolAddress(_ name: String): Address? {
            let acctsPool = FRC20AccountsPool.borrowAccountsPool()
            let key = self.getGameWorldKey(name)
            return acctsPool.getGameWorldAddress(key)
        }

        // --- Write methods ---

        access(contract)
        fun onRegisterLotteryPool(_ name: String) {
            pre {
                !self.registered.contains(name): "The lottery pool is already registered"
            }
            self.registered.append(name)
        }

        // --- Private methods ---

        access(all)
        fun updateWhitelist(address: Address, isWhitelisted: Bool) {
            self.whitelist[address] = isWhitelisted

            emit RegistryWhitelistUpdated(address: address, isWhitelisted: isWhitelisted)
        }
    }

    /// Staking Controller Resource, represents a staking controller
    ///
    access(all) resource RegistryController {
        /// Returns the address of the controller
        ///
        access(all)
        fun getControllerAddress(): Address {
            return self.owner?.address ?? panic("The controller is not stored in the account")
        }

        /// Create a new staking pool
        ///
        access(all)
        fun createLotteryPool(
            name: String,
            rewardTick: String,
            ticketPrice: UFix64,
            epochInterval: UFix64,
            newAccount: Capability<&AuthAccount>,
        ){
            pre {
                FGameLotteryRegistry.isWhitelisted(self.getControllerAddress()): "The controller is not whitelisted"
            }

            // singleton resources
            let frc20Indexer = FRC20Indexer.getIndexer()
            let acctsPool = FRC20AccountsPool.borrowAccountsPool()
            let registry = FGameLotteryRegistry.borrowRegistry()

            assert(
                registry.getLotteryPoolAddress(name) == nil,
                message: "The lottery pool is already registered"
            )

            // Check if the token is already registered
            if rewardTick != "" {
                let meta = frc20Indexer.getTokenMeta(tick: rewardTick.toLower())
                assert(
                    meta != nil,
                    message: "The token is not registered"
                )
            }

            // get the game world key
            let key = registry.getGameWorldKey(name)
            let addr = acctsPool.getGameWorldAddress(key)
            assert(addr == nil, message: "The game world account is already created")

            // create the account for the lottery at the accounts pool
            acctsPool.setupNewChildForGameWorld(key: key, newAccount)

            // ensure all lottery resources are available
            self.ensureResourcesAvailable(
                name: name,
                rewardTick: rewardTick,
                ticketPrice: ticketPrice,
                epochInterval: epochInterval
            )

            // register the lottery pool
            registry.onRegisterLotteryPool(name)

            let newAddr = acctsPool.getGameWorldAddress(key)
                ?? panic("The game world account was not created")

            // emit the event
            emit LotteryPoolEnabled(
                name: name,
                tick: rewardTick,
                ticketPrice: ticketPrice,
                epochInterval: epochInterval,
                address: newAddr,
                by: self.getControllerAddress()
            )
        }

        /// Ensure all staking resources are available
        ///
        access(all)
        fun ensureResourcesAvailable(
            name: String,
            rewardTick: String,
            ticketPrice: UFix64,
            epochInterval: UFix64,
        ) {
            pre {
                FGameLotteryRegistry.isWhitelisted(self.getControllerAddress()): "The controller is not whitelisted"
            }

            // singleton resources
            let registry = FGameLotteryRegistry.borrowRegistry()
            let acctsPool = FRC20AccountsPool.borrowAccountsPool()

            // try to borrow the account to check if it was created
            let key = registry.getGameWorldKey(name)
            let childAcctRef = acctsPool.borrowChildAccount(type: FRC20AccountsPool.ChildAccountType.GameWorld, key)
                ?? panic("The staking account was not created")

            var isUpdated = false

            // The lottery pool should have the following resources in the account:
            // - FGameLottery.LotteryPool: Lottery Pool resource
            // - FRC20FTShared.SharedStore: Configuration
            // - FixesHeartbeat.IHeartbeatHook: Register to FixesHeartbeat with the scope of "FGameLottery"

            if let pool = childAcctRef.borrow<&FGameLottery.LotteryPool>(from: FGameLottery.lotteryPoolStoragePath) {
                assert(
                    pool.name == name,
                    message: "The staking pool tick is not the same as the requested"
                )
            } else {
                // create the resource and save it in the account
                let pool <- FGameLottery.createLotteryPool(
                    name: name,
                    rewardTick: rewardTick,
                    ticketPrice: ticketPrice,
                    epochInterval: epochInterval
                )
                // save the resource in the account
                childAcctRef.save(<- pool, to: FGameLottery.lotteryPoolStoragePath)

                isUpdated = true || isUpdated
            }
            // link the resource to the public path
            // @deprecated after Cadence 1.0
            if childAcctRef
                .getCapability<&FGameLottery.LotteryPool{FGameLottery.LotteryPoolPublic, FixesHeartbeat.IHeartbeatHook}>(FGameLottery.lotteryPoolPublicPath)
                .borrow() == nil {
                childAcctRef.unlink(FGameLottery.lotteryPoolPublicPath)
                childAcctRef.link<&FGameLottery.LotteryPool{FGameLottery.LotteryPoolPublic, FixesHeartbeat.IHeartbeatHook}>(
                    FGameLottery.lotteryPoolPublicPath,
                    target: FGameLottery.lotteryPoolStoragePath
                )

                isUpdated = true || isUpdated
            }

            // create the shared store and save it in the account
            if childAcctRef.borrow<&AnyResource>(from: FRC20FTShared.SharedStoreStoragePath) == nil {
                let sharedStore <- FRC20FTShared.createSharedStore()
                childAcctRef.save(<- sharedStore, to: FRC20FTShared.SharedStoreStoragePath)

                isUpdated = true || isUpdated
            }
            // link the resource to the public path
            // @deprecated after Cadence 1.0
            if childAcctRef
                .getCapability<&FRC20FTShared.SharedStore{FRC20FTShared.SharedStorePublic}>(FRC20FTShared.SharedStorePublicPath)
                .borrow() == nil {
                childAcctRef.unlink(FRC20FTShared.SharedStorePublicPath)
                childAcctRef.link<&FRC20FTShared.SharedStore{FRC20FTShared.SharedStorePublic}>(FRC20FTShared.SharedStorePublicPath, target: FRC20FTShared.SharedStoreStoragePath)

                isUpdated = true || isUpdated
            }

            // Register to FixesHeartbeat
            let heartbeatScope = "FGameLottery"
            if !FixesHeartbeat.hasHook(scope: heartbeatScope, hookAddr: childAcctRef.address) {
                FixesHeartbeat.addHook(
                    scope: heartbeatScope,
                    hookAddr: childAcctRef.address,
                    hookPath: FGameLottery.lotteryPoolPublicPath
                )

                isUpdated = true || isUpdated
            }

            if isUpdated {
                emit LotteryPoolResourcesUpdated(
                    name: name,
                    address: acctsPool.getGameWorldAddress(key) ?? panic("The game world account was not created"),
                    by: self.getControllerAddress()
                )
            }
        }
    }

    /** ---- Public Methods - Controller ---- */

    /// Create a new staking controller
    ///
    access(all)
    fun createController(): @RegistryController {
        return <- create RegistryController()
    }

    /// Check if the given address is whitelisted
    ///
    access(all) view
    fun isWhitelisted(_ address: Address): Bool {
        if address == self.account.address {
            return true
        }
        let reg = self.borrowRegistry()
        return reg.isWhitelisted(address: address)
    }

    /// Borrow Lottery Pool Registry
    ///
    access(all)
    fun borrowRegistry(): &Registry{RegistryPublic} {
        return getAccount(self.account.address)
            .getCapability<&Registry{RegistryPublic}>(self.registryPublicPath)
            .borrow()
            ?? panic("Registry not found")
    }

    /* --- Public methods - User --- */

    init() {
        // Identifiers
        let identifier = "FGameLottery_".concat(self.account.address.toString())
        self.registryStoragePath = StoragePath(identifier: identifier.concat("_Registry"))!
        self.registryPublicPath = PublicPath(identifier: identifier.concat("_Registry"))!

        self.registryControllerStoragePath = StoragePath(identifier: identifier.concat("_RegistryController"))!

        // save registry
        let registry <- create Registry()
        self.account.save(<- registry, to: self.registryStoragePath)
        // @deprecated in Cadence 1.0
        self.account.link<&Registry{RegistryPublic}>(self.registryPublicPath, target: self.registryStoragePath)

        // create the controller
        let controller <- create RegistryController()
        self.account.save(<-controller, to: self.registryControllerStoragePath)

        // Emit the ContractInitialized event
        emit ContractInitialized()
    }
}
