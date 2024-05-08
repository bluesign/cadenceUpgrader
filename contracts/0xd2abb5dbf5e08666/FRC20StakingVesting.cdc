/**
> Author: FIXeS World <https://fixes.world/>

# FRC20StakingVesting

TODO: Add description

*/
import FixesHeartbeat from "./FixesHeartbeat.cdc"
import FRC20FTShared from "./FRC20FTShared.cdc"
import FRC20AccountsPool from "./FRC20AccountsPool.cdc"
import FRC20Staking from "./FRC20Staking.cdc"

/// The `FRC20StakingVesting` contract
///
access(all) contract FRC20StakingVesting {
    /* --- Events --- */
    /// Event emitted when the contract is initialized
    access(all) event ContractInitialized()

    /// Event emitted when the `VestingEntry` is created
    access(all) event VestingEntryCreated(
        stakeTick: String,
        vestingTick: String,
        vestingAmount: UFix64,
        totalBatches: UInt32,
        interval: UFix64,
        from: Address,
    )
    /// Event emitted when the `VestingEntry` is vested
    access(all) event VestingEntryVested(
        stakeTick: String,
        vestingTick: String,
        currentBatch: UInt32,
        vestedAmount: UFix64,
        from: Address
    )

    /* --- Variable, Enums and Structs --- */

    access(all)
    let storagePath: StoragePath
    access(all)
    let publicPath: PublicPath

    /* --- Interfaces & Resources --- */

    /// Represents the vesting info
    ///
    access(all) struct VestingInfo {
        access(all) let stakeTick: String
        access(all) let rewardTick: String
        access(all) let by: Address
        access(all) let totalAmount: UFix64
        access(all) let vestedAmount: UFix64
        access(all) let totalBatches: UInt32
        access(all) let vestedBatchAmount: UInt32
        access(all) let vestingInterval: UFix64
        access(all) let lastVestedAt: UFix64
        access(all) let startedAt: UFix64
        init(
            stakeTick: String,
            rewardTick: String,
            by: Address,
            totalAmount: UFix64,
            vestedAmount: UFix64,
            totalBatches: UInt32,
            vestedBatchAmount: UInt32,
            vestingInterval: UFix64,
            lastVestedAt: UFix64,
            startedAt: UFix64,
        ) {
            self.stakeTick = stakeTick
            self.rewardTick = rewardTick
            self.by = by
            self.totalAmount = totalAmount
            self.vestedAmount = vestedAmount
            self.totalBatches = totalBatches
            self.vestedBatchAmount = vestedBatchAmount
            self.vestingInterval = vestingInterval
            self.lastVestedAt = lastVestedAt
            self.startedAt = startedAt
        }
    }

    /// Represents a vesting entry
    ///
    access(all) resource VestingEntry {
        // ---- Fields ----
        access(all)
        let stakeTick: String
        /// The remaining change
        access(all)
        let remaining: @FRC20FTShared.Change
        /// How many batches are there to do the vesting
        access(all)
        let totalBatches: UInt32
        /// The interval between each batch
        access(all)
        let interval: UFix64
        /// The initial amount of the change
        access(all)
        let initialAmount: UFix64
        /// The time when the vesting is started
        access(all)
        let startedAt: UFix64
        // ---- Varibles ----
        /// The batch amount that is vested
        access(all)
        var vestedBatchAmount: UInt32
        /// The last time the change is vested
        access(all)
        var lastVestedAt: UFix64

        init(
            stakeTick: String,
            change: @FRC20FTShared.Change,
            totalBatches: UInt32,
            interval: UFix64,
        ) {
            pre {
                totalBatches > 0: "The total batches must be greater than 0"
                interval > 0.0: "The interval must be greater than 0"
            }
            self.stakeTick = stakeTick
            self.initialAmount = change.getBalance()
            self.remaining <- change
            self.totalBatches = totalBatches
            self.interval = interval
            self.vestedBatchAmount = 0
            self.lastVestedAt = 0.0
            self.startedAt = getCurrentBlock().timestamp
        }

        /// @deprecated after Cadence 1.0
        destroy() {
            destroy self.remaining
        }

        /** ---- Public Methods ---- */

        /// Returns the tick name of remaining change
        ///
        access(all) view
        fun getVestingTick(): String {
            return self.remaining.getOriginalTick()
        }

        /// Returns the vesting info
        ///
        access(all) view
        fun getVestingDetails(): VestingInfo {
            return VestingInfo(
                stakeTick: self.stakeTick,
                rewardTick: self.getVestingTick(),
                by: self.remaining.from,
                totalAmount: self.initialAmount,
                vestedAmount: self.getVestedAmount(),
                totalBatches: self.totalBatches,
                vestedBatchAmount: self.vestedBatchAmount,
                vestingInterval: self.interval,
                lastVestedAt: self.lastVestedAt,
                startedAt: self.startedAt,
            )
        }

        /// Returns the amount of the change that is vested
        ///
        access(all) view
        fun getVestedAmount(): UFix64 {
            return self.initialAmount / UFix64(self.totalBatches) * UFix64(self.vestedBatchAmount)
        }

        access(all) view
        fun getNextVestableAmount(): UFix64 {
            return self.initialAmount / UFix64(self.totalBatches)
        }

        access(all) view
        fun getNextVestableTime(): UFix64 {
            return self.lastVestedAt + self.interval
        }

        access(all) view
        fun isVestable(): Bool {
            let now = getCurrentBlock().timestamp
            return self.getNextVestableTime() <= now
        }

        access(all) view
        fun isCompleted(): Bool {
            return self.vestedBatchAmount >= self.totalBatches || self.remaining.isEmpty()
        }

        /** ---- Contract level methods ---- */
        /// Vest the change
        ///
        access(contract)
        fun tryVesting(): @FRC20FTShared.Change? {
            // Check if the change is vestable
            if !self.isVestable() {
                return nil
            }
            /// Check if the change is already vested
            if self.vestedBatchAmount >= self.totalBatches {
                return nil
            }
            // Check if remaining is empty
            if self.remaining.isEmpty() {
                return nil
            }
            // Vest the change and update the state

            // Calculate the vestable amount
            var nextVestableAmount: UFix64 = self.getNextVestableAmount()
            if self.vestedBatchAmount + 1 == self.totalBatches || nextVestableAmount > self.remaining.getBalance() {
                nextVestableAmount = self.remaining.getBalance()
            }
            // Vest the change
            let vestableChange <- self.remaining.withdrawAsChange(amount: nextVestableAmount)

            // Update the state
            if self.remaining.isEmpty() {
                self.vestedBatchAmount = self.totalBatches
            } else {
                self.vestedBatchAmount = self.vestedBatchAmount + 1
            }
            self.lastVestedAt = getCurrentBlock().timestamp

            // Emit the event
            emit VestingEntryVested(
                stakeTick: self.stakeTick,
                vestingTick: self.getVestingTick(),
                currentBatch: self.vestedBatchAmount,
                vestedAmount: nextVestableAmount,
                from: vestableChange.from
            )
            // return the vestable change
            return <- vestableChange
        }
    }

    /// Public interface for the `VestingVault` resource
    ///
    access(all) resource interface VestingVaultPublic {
        /// Returns the vesting entries
        access(all) view
        fun getVestingEntries(): [VestingInfo]

        /// Add a vesting entry
        access(account)
        fun addVesting(
            stakeTick: String,
            rewardChange: @FRC20FTShared.Change,
            vestingBatchAmount: UInt32,
            vestingInterval: UFix64,
        )
    }

    /// The `VestingVault` resource
    ///
    access(all) resource Vault: VestingVaultPublic, FRC20FTShared.TransactionHook, FixesHeartbeat.IHeartbeatHook {
        access(self)
        let entries: @[VestingEntry]

        init() {
            self.entries <- []
        }

        /// @deprecated after Cadence 1.0
        destroy() {
            destroy self.entries
        }

        /** ---- Public Methods ---- */

        /// Returns the vesting entries
        access(all) view
        fun getVestingEntries(): [VestingInfo] {
            let ret: [VestingInfo] = []
            var i = 0
            let len = self.entries.length
            while i < len {
                let entry = self.borrowEntry(i)
                if entry == nil {
                    break
                }
                ret.append(entry!.getVestingDetails())
                i = i + 1
            }
            return ret
        }

        /** ---- Account Access Methods ---- */

        /// Add a vesting entry
        ///
        access(account)
        fun addVesting(
            stakeTick: String,
            rewardChange: @FRC20FTShared.Change,
            vestingBatchAmount: UInt32,
            vestingInterval: UFix64,
        ) {
            pre {
                rewardChange.getBalance() > 0.0: "The vesting amount must be greater than 0"
                vestingBatchAmount > 0: "The vesting batch amount must be greater than 0"
                vestingInterval > 0.0: "The vesting interval must be greater than 0"
            }
            // singleton resource
            let acctsPool = FRC20AccountsPool.borrowAccountsPool()
            let poolAddr = acctsPool.getFRC20StakingAddress(tick: stakeTick)
                ?? panic("The staking pool is not enabled")
            let stakingPool = FRC20Staking.borrowPool(poolAddr)
                ?? panic("The staking pool is not found")

            let rewardTick = rewardChange.getOriginalTick()
            // ensure reward strategy exists
            assert(
                stakingPool.borrowRewardStrategy(rewardTick) != nil,
                message: "The reward strategy is not found"
            )
            assert(
                rewardChange.getOriginalTick() == rewardTick,
                message: "The reward change is not matched with the reward tick"
            )

            let vestingAmount = rewardChange.getBalance()
            let fromAddr = rewardChange.from

            let newEntry <- create VestingEntry(
                stakeTick: stakeTick,
                change: <- rewardChange,
                totalBatches: vestingBatchAmount,
                interval: vestingInterval,
            )
            self.entries.append(<- newEntry)

            // Emit the event
            emit VestingEntryCreated(
                stakeTick: stakeTick,
                vestingTick: rewardTick,
                vestingAmount: vestingAmount,
                totalBatches: vestingBatchAmount,
                interval: vestingInterval,
                from: fromAddr
            )
        }

        /// The methods that is invoked when the heartbeat is executed
        /// Before try-catch is deployed, please ensure that there will be no panic inside the method.
        ///
        access(account)
        fun onHeartbeat(_ deltaTime: UFix64) {
            let len = self.entries.length
            // if there is no entry, return
            if len == 0 {
                return
            }

            // singleton resource
            let acctsPool = FRC20AccountsPool.borrowAccountsPool()

            var i = 0
            while i < len {
                let current <- self.entries.removeFirst()
                // check if vestable
                if current.isVestable() {
                    // ensure pool address exists
                    if let poolAddr = acctsPool.getFRC20StakingAddress(tick: current.stakeTick) {
                        // ensure pool exists
                        if let stakingPool = FRC20Staking.borrowPool(poolAddr) {
                            // ensure reward strategy exists
                            if let rewardStrategy =  stakingPool.borrowRewardStrategy(current.getVestingTick()) {
                                // vest the change
                                if let vestedChange <- current.tryVesting() {
                                    // add the vested change to the reward strategy
                                    rewardStrategy.addIncome(income: <- vestedChange)
                                }
                            }
                        }
                    }
                } // no panic!!!
                // handle the entry after vesting
                if !current.isCompleted() {
                    // add the entry back to the list
                    self.entries.append(<- current)
                } else {
                    // destroy the entry if completed
                    destroy current
                }
                i = i + 1
            }
        }

        //** ---- Internal Methods ---- */

        /// Borrow the entry
        ///
        access(self)
        fun borrowEntry(_ idx: Int): &VestingEntry? {
            if idx < 0 || idx >= self.entries.length {
                return nil
            }
            return &self.entries[idx] as &VestingEntry
        }
    }

    /* --- Public Functions --- */

    /// Creates a new `Vault` resource
    ///
    access(all)
    fun createVestingVault(): @Vault {
        return <-create Vault()
    }

    /// Returns the `Vault` public capability
    ///
    access(all)
    fun getVaultCap(
        _ addr: Address
    ): Capability<&Vault{VestingVaultPublic, FRC20FTShared.TransactionHook, FixesHeartbeat.IHeartbeatHook}> {
        return getAccount(addr)
            .getCapability<&Vault{VestingVaultPublic, FRC20FTShared.TransactionHook, FixesHeartbeat.IHeartbeatHook}>(self.publicPath)
    }

    /// Borrow the `Vault` resource
    ///
    access(all)
    fun borrowVaultRef(
        _ addr: Address
    ): &Vault{VestingVaultPublic}? {
        return self.getVaultCap(addr).borrow()
    }

    init() {
        let identifier = "FRC20StakingVesting_".concat(self.account.address.toString())
        self.storagePath  = StoragePath(identifier: identifier.concat("_vault"))!
        self.publicPath = PublicPath(identifier: identifier.concat("_vault"))!

        // Register the hooks
        FRC20FTShared.registerHookType(Type<@FRC20StakingVesting.Vault>())

        emit ContractInitialized()
    }
}
