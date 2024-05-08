/**
> Author: FIXeS World <https://fixes.world/>

# FRC20 Staking Contract

TODO: Add description

*/
// Third Party Imports
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
// Fixes Imports
import Fixes from "./Fixes.cdc"
import FRC20Indexer from "./FRC20Indexer.cdc"
import FRC20FTShared from "./FRC20FTShared.cdc"
import FRC20SemiNFT from "./FRC20SemiNFT.cdc"

access(all) contract FRC20Staking {
    /* --- Events --- */
    /// Event emitted when the contract is initialized
    access(all) event ContractInitialized()
    /// Event emitted when the staking pool is created
    access(all) event StakingInitialized(pool: Address, tick: String)
    /// Event emitted when the reward strategy is created
    access(all) event RewardStrategyInitialized(pool: Address, stakeTick: String, rewardTick: String, ftVaultType: String?)
    /// Event emitted when the reward strategy is added
    access(all) event RewardStrategyAdded(pool: Address, stakeTick: String, rewardTick: String)
    /// Event emitted when the reward income is added
    access(all) event RewardIncomeAdded(pool: Address, tick: String, amount: UFix64, from: Address)
    /// Event emitted when the delegator record is added
    access(all) event DelegatorRecordAdded(pool: Address, tick: String, delegatorID: UInt32, delegatorAddress: Address)
    /// Event emitted when the delegator staked FRC20 token
    access(all) event DelegatorStaked(pool: Address, tick: String, delegatorID: UInt32, delegatorAddress: Address, amount: UFix64)
    /// Event emitted when the delegator try to staking FRC20 token and lock tokens
    access(all) event DelegatorUnStakingLocked(pool: Address, tick: String, delegatorID: UInt32, delegatorAddress: Address, amount: UFix64, unlockTime: UInt64)
    /// Event emitted when the delegator unstaked FRC20 token
    access(all) event DelegatorUnStakingUnlocked(pool: Address, tick: String, delegatorID: UInt32, delegatorAddress: Address, amount: UFix64)
    /// Event emitted when the delegator unstaked FRC20 token
    access(all) event DelegatorUnStaked(pool: Address, tick: String, delegatorID: UInt32, delegatorAddress: Address, amount: UFix64)
    /// Event emitted when the delegator claim status is updated
    access(all) event DelegatorClaimedReward(pool: Address, stakeTick: String, rewardTick: String, amount: UFix64, yieldAdded: UFix64)
    /// Event emitted when the delegator received staked FRC20 token
    access(all) event DelegatorStakedTokenDeposited(tick: String, pool: Address, receiver: Address, amount: UFix64, semiNftId: UInt64)

    /* --- Variable, Enums and Structs --- */
    access(all)
    let StakingPoolStoragePath: StoragePath
    access(all)
    let StakingPoolPublicPath: PublicPath
    access(all)
    let DelegatorStoragePath: StoragePath
    access(all)
    let DelegatorPublicPath: PublicPath

    /* --- Interfaces & Resources --- */

    /// Staking Info Struct, represents the staking info of a FRC20 token
    ///
    access(all) struct StakingInfo {
        access(all)
        let tick: String
        access(all)
        let totalStaked: UFix64
        access(all)
        let totalUnstakingLocked: UFix64
        access(all)
        let delegatorsAmount: UInt32
        access(all)
        let rewardStrategies: [String]

        init(
            tick: String,
            totalStaked: UFix64,
            totalUnstakingLocked: UFix64,
            delegatorsAmount: UInt32,
            rewardStrategies: [String]
        ) {
            self.tick = tick
            self.totalStaked = totalStaked
            self.totalUnstakingLocked = totalUnstakingLocked
            self.delegatorsAmount = delegatorsAmount
            self.rewardStrategies = rewardStrategies
        }
    }

    /// Pool Public Interface
    ///
    access(all) resource interface PoolPublic {
        /// The ticker name of the FRC20 Staking Pool
        access(all)
        let tick: String

        /// Returns the details of the staking pool
        access(all) view
        fun getDetails(): StakingInfo

        /** ---- Rewards ---- */
        /// Returns the reward strategy names
        access(all) view
        fun getRewardNames(): [String]

        /// Returns the reward details of the given name
        access(all) view
        fun getRewardDetails(_ rewardTick: String): RewardDetails?

        /** -- Rewards: Account Level Methods -- */

        /// register reward strategy
        access(account)
        fun registerRewardStrategy(rewardTick: String)

        /// Borrow the Reward Strategy
        access(account)
        fun borrowRewardStrategy(_ rewardTick: String): &RewardStrategy?

        /** ---- Delegators ---- */

        /// Returns the delegators of this staking pool
        access(all) view
        fun getDelegators(): [Address]

        /// Returns the delegator unstaking info
        access(all) view
        fun getDelegatorUnstakingInfo(_ delegator: Address): DelegatorUnstakingInfo?

        /** -- Delegators: Account Level Methods -- */

        /// Stake FRC20 token
        access(account)
        fun stake(_ change: @FRC20FTShared.Change)

        /// Unstake FRC20 token
        access(account)
        fun unstake(
            _ semiNFTCol: &FRC20SemiNFT.Collection{FRC20SemiNFT.FRC20SemiNFTCollectionPublic, FRC20SemiNFT.FRC20SemiNFTBorrowable, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection},
            nftId: UInt64
        )

        /// Claim all unlocked staked changes
        access(account)
        fun claimUnlockedUnstakingChange(
            delegator: Address
        ): @FRC20FTShared.Change?

        /** ---- Contract Level Methods ---- */

        /// Borrow the Pool reference
        access(contract)
        fun borrowSelf(): &Pool

        /// Borrow Delegator Record
        access(contract)
        fun borrowDelegatorRecord(_ addr: Address): &DelegatorRecord?
    }

    access(all) resource Pool: PoolPublic {
        /// The ticker name of the FRC20 Staking Pool
        access(all)
        let tick:String
        /// The total FRC20 tokens staked in the pool
        access(contract)
        var totalStaked: @FRC20FTShared.Change?
        /// The counter for FRC20 tokens unstaking locked in the pool
        access(all)
        var totalUnstakingLocked: UFix64
        /** ----- Delegators ---- */
        /// The delegator ID counter
        access(all)
        var delegatorIDCounter: UInt32
        /// The delegators of this staking pool
        access(self)
        let delegators: @{Address: DelegatorRecord}
        /** ----- Rewards ----- */
        /// The rewards of this staking pool
        access(self)
        let rewards: @{String: RewardStrategy}

        init(
            _ tick: String
        ) {
            // Singleton
            let frc20Indexer = FRC20Indexer.getIndexer()
            assert(
                frc20Indexer.getTokenMeta(tick: tick) != nil,
                message: "Reward tick must be valid"
            )

            self.tick = tick
            self.totalStaked <- nil
            self.totalUnstakingLocked = 0.0
            self.delegators <- {}
            self.delegatorIDCounter = 0
            self.rewards <- {}
        }

        /// @deprecated after Cadence 1.0
        destroy() {
            destroy self.totalStaked
            destroy self.delegators
            destroy self.rewards
        }

        /// Initialize the staking record
        ///
        access(all)
        fun initialize() {
            pre {
                self.totalStaked == nil: "Total staked must be nil"
            }
            let owner = self.owner?.address ?? panic("Pool owner must exist")
            self.totalStaked <-! FRC20FTShared.createEmptyChange(tick: self.tick, from: owner)

            // emit event
            emit StakingInitialized(pool: owner, tick: self.tick)
        }

        /** ---- Public Methods ---- */

        /// Returns the details of the staking pool
        ///
        access(all) view
        fun getDetails(): StakingInfo {
            let totalStakedRef = self.borrowTotalStaked()
            return StakingInfo(
                tick: self.tick,
                totalStaked: totalStakedRef.getBalance(),
                totalUnstakingLocked: self.totalUnstakingLocked,
                delegatorsAmount: UInt32(self.delegators.keys.length),
                rewardStrategies: self.getRewardNames()
            )
        }

        /// Returns the reward strategy names
        ///
        access(all) view
        fun getRewardNames(): [String] {
            return self.rewards.keys
        }

        /// Returns the reward details of the given tick name
        ///
        access(all) view
        fun getRewardDetails(_ rewardTick: String): RewardDetails? {
            if let reward = self.borrowRewardStrategy(rewardTick) {
                return RewardDetails(
                    stakeTick: reward.stakeTick,
                    totalReward: reward.totalReward.getBalance(),
                    globalYieldRate: reward.globalYieldRate,
                    rewardTick: reward.rewardTick,
                    registeredAt: reward.registeredAt
                )
            }
            return nil
        }

        /// Returns the delegators of this staking pool
        ///
        access(all) view
        fun getDelegators(): [Address] {
            return self.delegators.keys
        }

        /// Returns the delegator unstaking info
        ///
        access(all) view
        fun getDelegatorUnstakingInfo(_ delegator: Address): DelegatorUnstakingInfo? {
            if let delegatorRecordRef = self.borrowDelegatorRecord(delegator) {
                return delegatorRecordRef.getDetails()
            }
            return nil
        }

        /** ---- Account Level Methods ----- */

        /// register reward strategy
        ///
        access(account)
        fun registerRewardStrategy(rewardTick: String) {
            pre {
                self.rewards[rewardTick] == nil: "Reward strategy name already exists"
            }
            let poolAddr = self.owner?.address ?? panic("Pool owner must exist")
            let strategy <- create RewardStrategy(
                pool: FRC20Staking.getPoolCap(poolAddr),
                rewardTick: rewardTick
            )
            self.rewards[rewardTick] <-! strategy

            // emit event
            emit RewardStrategyAdded(
                pool: self.owner?.address ?? panic("Reward owner must exist"),
                stakeTick: self.tick,
                rewardTick: rewardTick
            )
        }

        /// Stake FRC20 token
        ///
        access(account)
        fun stake(_ change: @FRC20FTShared.Change) {
            pre {
                change.tick == self.tick: "Staked change tick must match"
            }

            let stakedAmount = change.getBalance()
            let delegator = change.from

            // ensure delegator record exists
            let delegatorRecordRef = self.borrowOrCreateDelegatorRecord(delegator)

            let poolAddr = self.owner?.address ?? panic("Pool owner must exist")

            // create staked tick change
            let stakedChange <- FRC20FTShared.createStakedChange(
                ref: &change as &FRC20FTShared.Change,
                issuer: poolAddr
            )

            // update staked change
            FRC20FTShared.depositToChange(
                receiver: self.borrowTotalStaked(),
                change: <- change
            )

            // update staked change for delegator
            let delegatorRef = delegatorRecordRef.borrowDelegatorRef()
            // call onFRC20Staked to save the staked change
            delegatorRef.onFRC20Staked(stakedChange: <- stakedChange)

            // emit stake event
            emit DelegatorStaked(
                pool: poolAddr,
                tick: self.tick,
                delegatorID: delegatorRecordRef.id,
                delegatorAddress: delegator,
                amount: stakedAmount
            )
        }

        /// Unstake FRC20 token
        ///
        access(account)
        fun unstake(
            _ semiNFTCol: &FRC20SemiNFT.Collection{FRC20SemiNFT.FRC20SemiNFTCollectionPublic, FRC20SemiNFT.FRC20SemiNFTBorrowable, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection},
            nftId: UInt64
        ) {
            let poolAddr = self.owner?.address ?? panic("Pool owner must exist")
            let delegator = semiNFTCol.owner?.address ?? panic("Delegator must exist")
            // ensure the nft is valid
            let nftRef = semiNFTCol.borrowFRC20SemiNFT(id: nftId)
                ?? panic("Staked NFT must exist")
            assert(
                nftRef.getOriginalTick() == self.tick,
                message: "NFT tick must match"
            )
            assert(
                nftRef.getFromAddress() == poolAddr,
                message: "NFT must be created from pool"
            )

            // add to totalUnstakingLocked
            self.totalUnstakingLocked = self.totalUnstakingLocked + nftRef.getBalance()

            // withdraw the nft from semiNFT collection
            let nft <- semiNFTCol.withdraw(withdrawID: nftId) as! @FRC20SemiNFT.NFT

            // ensure delegator record exists
            let delegatorRecordRef = self.borrowOrCreateDelegatorRecord(delegator)

            // save the nft to unstaking queue in delegator record
            delegatorRecordRef.addUnstakingEntry(<- nft)
        }

        /// Claim all unlocked staked changes
        ///
        access(account)
        fun claimUnlockedUnstakingChange(
            delegator: Address
        ): @FRC20FTShared.Change? {
            let poolAddr = self.owner?.address ?? panic("Pool owner must exist")
            let delegatorRecordRef = self.borrowDelegatorRecord(delegator)
                ?? panic("Delegator record must exist")
            if let unlockedStakedChange <- delegatorRecordRef.refundAllUnlockedEnties() {
                // extract all unlocked staked change
                let amount = unlockedStakedChange.extract()
                // destroy the unlocked staked change
                destroy unlockedStakedChange

                let totalStakedRef = self.borrowTotalStaked()
                // withdraw from totalStaked
                let unstakedChange <- totalStakedRef.withdrawAsChange(amount: amount)

                // decrease totalUnstakingLocked
                self.totalUnstakingLocked = self.totalUnstakingLocked - unstakedChange.getBalance()

                // emit event
                emit DelegatorUnStaked(
                    pool: poolAddr,
                    tick: self.tick,
                    delegatorID: delegatorRecordRef.id,
                    delegatorAddress: delegator,
                    amount: amount
                )
                return <- unstakedChange
            }
            return nil
        }

        /// Borrow Reward Strategy
        ///
        access(account)
        fun borrowRewardStrategy(_ rewardTick: String): &RewardStrategy? {
            return &self.rewards[rewardTick] as &RewardStrategy?
        }

        /** ---- Contract Level Methods ----- */

        /// Borrow or craete the delegator record
        ///
        access(contract)
        fun borrowOrCreateDelegatorRecord(_ addr: Address): &DelegatorRecord {
            // check if delegator's record exists
            if self.delegators[addr] == nil {
                self._addDelegator(<- create DelegatorRecord(
                    id: self.delegatorIDCounter,
                    tick: self.tick,
                    address: addr
                ))
            }
            return self.borrowDelegatorRecord(addr)!
        }

        /// Borrow Delegator Record
        ///
        access(contract)
        fun borrowDelegatorRecord(_ addr: Address): &DelegatorRecord? {
            return &self.delegators[addr] as &DelegatorRecord?
        }

        /// Borrow Staking Reference
        ///
        access(contract)
        fun borrowSelf(): &Pool {
            return &self as &Pool
        }

        /// Borrow Staked Change
        ///
        access(contract)
        fun borrowTotalStaked(): &FRC20FTShared.Change {
            return &self.totalStaked as &FRC20FTShared.Change? ?? panic("Total staked must exist")
        }

        /** ---- Internal Methods */

        /// Add the Delegator Record
        ///
        access(self)
        fun _addDelegator(_ newRecord: @DelegatorRecord) {
            pre {
                self.delegators[newRecord.delegator] == nil: "Delegator id already exists"
            }
            let delegatorID = newRecord.id
            let address = newRecord.delegator
            self.delegators[newRecord.delegator] <-! newRecord

            // increase delegator ID counter
            self.delegatorIDCounter = self.delegatorIDCounter + 1

            let ref = self.borrowDelegatorRecord(address)
                ?? panic("Delegator record must exist")

            // emit event
            emit DelegatorRecordAdded(
                pool: self.owner?.address ?? panic("Pool owner must exist"),
                tick: self.tick,
                delegatorID: delegatorID,
                delegatorAddress: ref.delegator
            )
        }
    }

    /// Delegator Unstaking Info Struct, represents a delegator unstaking info for a FRC20 token
    ///
    access(all) struct DelegatorUnstakingInfo {
        access(all) let delegator: Address
        access(all) let delegatorId: UInt32
        access(all) let stakeTick: String
        access(all) let unstakingEntriesNFTIds: [UInt64]
        access(all) let totalUnstakingBalance: UFix64
        access(all) let totalUnlockedClaimableBalance: UFix64
        init(
            delegator: Address,
            delegatorId: UInt32,
            stakeTick: String,
            unstakingEntriesNFTIds: [UInt64],
            totalUnstakingBalance: UFix64,
            totalUnlockedClaimableBalance: UFix64
        ) {
            self.delegator = delegator
            self.delegatorId = delegatorId
            self.stakeTick = stakeTick
            self.unstakingEntriesNFTIds = unstakingEntriesNFTIds
            self.totalUnstakingBalance = totalUnstakingBalance
            self.totalUnlockedClaimableBalance = totalUnlockedClaimableBalance
        }
    }

    /// Interface of Delegator Unstaking Entry
    ///
    access(all) resource interface UnstakingEntryPublic {
        access(all)
        let unlockTime: UInt64

        access(all)
        fun getNFTId(): UInt64?

        access(all)
        fun isUnlocked(): Bool

        access(all)
        fun unlockingBalance(): UFix64

        access(all)
        fun isExtracted(): Bool
    }

    /// Unstaking Entry Resource, represents a unstaking entry for a FRC20 token
    ///
    access(all) resource UnstakingEntry: UnstakingEntryPublic {
        access(all)
        let unlockTime: UInt64
        access(all)
        var unstakingNFT: @FRC20SemiNFT.NFT?

        init(
            unlockTime: UInt64,
            unstakingNFT: @FRC20SemiNFT.NFT
        ) {
            self.unlockTime = unlockTime
            self.unstakingNFT <- unstakingNFT
        }

        destroy () {
            destroy self.unstakingNFT
        }

        access(all)
        fun getNFTId(): UInt64? {
            return self.unstakingNFT?.id
        }

        access(all)
        fun isUnlocked(): Bool {
            return UInt64(getCurrentBlock().timestamp) >= self.unlockTime
        }

        access(all)
        fun unlockingBalance(): UFix64 {
            return self.unstakingNFT?.getBalance() ?? 0.0
        }

        access(all)
        fun isExtracted(): Bool {
            return self.unstakingNFT == nil
        }

        /// Extract the unstaking FRC20 token
        access(contract)
        fun extract(): @FRC20FTShared.Change {
            pre {
                self.unstakingNFT != nil : "Unstaking NFT must exist"
            }
            post {
                self.unstakingNFT == nil : "Unstaking NFT must be destroyed"
            }
            var toUnwrapNft: @FRC20SemiNFT.NFT? <- nil
            self.unstakingNFT <-> toUnwrapNft

            return <- FRC20SemiNFT.unwrapStakedFRC20(nftToUnwrap: <- toUnwrapNft!)
        }
    }

    /// Delegator Record Resource, represents a delegator record for a FRC20 token and store in pool's account
    ///
    access(all) resource DelegatorRecord {
        // The delegator ID
        access(all)
        let id: UInt32
        // The delegator address
        access(all)
        let delegator: Address
        // The staking tick
        access(all)
        let stakeTick: String
        // The delegator's unstaking entries
        access(all)
        let unstakingEntries: @[UnstakingEntry]

        init(
            id: UInt32,
            tick: String,
            address: Address
        ) {
            pre {
                FRC20Staking.borrowDelegator(address) != nil: "Delegator must exist"
            }
            self.id = id
            self.stakeTick = tick
            self.delegator = address
            self.unstakingEntries <- []
        }

        /// @deprecated after Cadence 1.0
        destroy() {
            destroy self.unstakingEntries
        }

        access(all)
        fun entriesLength(): UInt64 {
            return UInt64(self.unstakingEntries.length)
        }

        /// Is the frist unstaking entry unlocked
        ///
        access(all)
        fun isFirstUnlocked(): Bool {
            if self.unstakingEntries.length > 0 {
                return self.unstakingEntries[0].isUnlocked()
            }
            return false
        }

        /// Get all unlocked balance
        ///
        access(all)
        fun getDetails(): DelegatorUnstakingInfo {
            var totalUnlockedBalance = 0.0
            var totalBalance = 0.0
            var nftIds: [UInt64] = []
            let len = self.unstakingEntries.length
            var i = 0
            while i < len {
                let entryRef = self.borrowEntry(i)
                let unlockingBalance = entryRef.unlockingBalance()
                // add to NFTIds
                if let nftId = entryRef.getNFTId() {
                    nftIds.append(nftId)
                }
                // add to unlocked balance
                if entryRef.isUnlocked() {
                    totalUnlockedBalance = totalUnlockedBalance + unlockingBalance
                }
                // add to total balance
                totalBalance = totalBalance + unlockingBalance
                // loop next
                i = i + 1
            }
            return DelegatorUnstakingInfo(
                delegator: self.delegator,
                delegatorId: self.id,
                stakeTick: self.stakeTick,
                unstakingEntriesNFTIds: nftIds,
                totalUnstakingBalance: totalBalance,
                totalUnlockedClaimableBalance: totalUnlockedBalance
            )
        }

        /// Locking unstaking FRC20 token
        ///
        access(contract)
        fun addUnstakingEntry(
            _ unstakingNFT: @FRC20SemiNFT.NFT
        ) {
            pre {
                unstakingNFT.getOriginalTick() == self.stakeTick: "Unstaking NFT tick must match"
            }
            let unlockTime = UInt64(getCurrentBlock().timestamp) + FRC20Staking.getUnstakingLockTime()
            let tick = unstakingNFT.getOriginalTick()
            let amount = unstakingNFT.getBalance()
            self.unstakingEntries.append(
                <- create UnstakingEntry(
                    unlockTime: unlockTime,
                    unstakingNFT: <- unstakingNFT
                )
            )

            // emit event
            emit DelegatorUnStakingLocked(
                pool: self.owner?.address ?? panic("Pool owner must exist"),
                tick: tick,
                delegatorID: self.id,
                delegatorAddress: self.delegator,
                amount: amount,
                unlockTime: unlockTime
            )
        }

        access(contract)
        fun refundAllUnlockedEnties(): @FRC20FTShared.Change? {
            if self.unstakingEntries.length > 0 {
                // create new staked frc20 change
                let ret: @FRC20FTShared.Change <- FRC20FTShared.createEmptyChange(
                    tick: "!".concat(self.stakeTick),
                    from: self.owner?.address ?? panic("Pool owner must exist"),
                )
                let retRef = &ret as &FRC20FTShared.Change

                let len = self.unstakingEntries.length
                var isFirstUnlocked = self.isFirstUnlocked()
                while isFirstUnlocked {
                    let entryRef = self.borrowEntry(0)
                    if entryRef.isUnlocked() {
                        // remove the first entry
                        let entry <- self.unstakingEntries.remove(at: 0)
                        // extract the unstaked change
                        let unwrappedChange <- entry.extract()
                        // extracted
                        assert(
                            entry.isExtracted(),
                            message: "Unstaking entry must be extracted"
                        )
                        destroy entry
                        // merge to ret change
                        let amount = unwrappedChange.getBalance()
                        // deposit to change
                        FRC20FTShared.depositToChange(
                            receiver: retRef,
                            change: <- unwrappedChange
                        )

                        // emit event
                        emit DelegatorUnStakingUnlocked(
                            pool: self.owner?.address ?? panic("Pool owner must exist"),
                            tick: self.stakeTick,
                            delegatorID: self.id,
                            delegatorAddress: self.delegator,
                            amount: amount
                        )
                    }
                    // check again, if the first entry is unlocked
                    isFirstUnlocked = self.isFirstUnlocked()
                }
                // return the unstaked change
                return <- ret
            }
            return nil
        }

        /// Borrow Delegator reference
        ///
        access(contract)
        fun borrowDelegatorRef(): &Delegator{DelegatorPublic} {
            return FRC20Staking.borrowDelegator(self.delegator) ?? panic("Delegator must exist")
        }

        access(self)
        fun borrowEntry(_ index: Int): &UnstakingEntry {
            pre {
                index < self.unstakingEntries.length: "Index must be less than entries length"
            }
            return &self.unstakingEntries[index] as &UnstakingEntry
        }
    }

    /// Reward Details Struct, represents a reward details for a FRC20 token
    ///
    access(all) struct RewardDetails {
        access(all)
        let stakeTick: String
        access(all)
        let totalReward: UFix64
        access(all)
        let globalYieldRate: UFix64
        access(all)
        let rewardTick: String
        access(all)
        let rewardVaultType: Type?
        access(all)
        let registeredAt: UFix64

        init(
            stakeTick: String,
            totalReward: UFix64,
            globalYieldRate: UFix64,
            rewardTick: String,
            registeredAt: UFix64
        ) {
            self.stakeTick = stakeTick
            self.totalReward = totalReward
            self.globalYieldRate = globalYieldRate
            self.rewardTick = rewardTick
            self.registeredAt = registeredAt

            if rewardTick == "" {
                self.rewardVaultType = Type<@FlowToken.Vault>()
            } else if rewardTick.slice(from: 0, upTo: 2) == "A." {
                self.rewardVaultType = CompositeType(rewardTick)
            } else {
                self.rewardVaultType = nil
            }
        }
    }

    /// Reward Strategy Resource, represents a reward strategy for a FRC20 token and store in pool's account
    ///
    access(all) resource RewardStrategy {
        /// The pool capability
        access(self)
        let poolCap: Capability<&Pool{PoolPublic}>
        /// The ticker name of staking pool
        access(all)
        let stakeTick: String
        /// The ticker name of reward
        access(all)
        let rewardTick: String
        /// The registered time of the reward strategy
        access(contract)
        let registeredAt: UFix64
        /// The global yield rate of the reward strategy
        access(contract)
        var globalYieldRate: UFix64
        /// The reward change, can be any FRC20 token or Flow FT
        access(contract)
        let totalReward: @FRC20FTShared.Change

        init(
            pool: Capability<&Pool{PoolPublic}>,
            rewardTick: String,
        ) {
            pre {
                pool.check(): "Pool must be valid"
            }

            self.registeredAt = getCurrentBlock().timestamp
            self.poolCap = pool
            let poolRef = pool.borrow() ?? panic("Pool must exist")

            self.stakeTick = poolRef.tick
            self.rewardTick = rewardTick
            self.globalYieldRate = 0.0

            // current only support FlowToken
            let isFtVault = rewardTick == "" || rewardTick.slice(from: 0, upTo: 2) == "A."
            /// create empty change
            if isFtVault {
                assert(
                    rewardTick == "" || rewardTick == Type<@FlowToken.Vault>().identifier,
                    message: "Currently only FlowToken.Vault is supported"
                )
                self.totalReward <- FRC20FTShared.createEmptyFlowChange(from: pool.address)
            } else {
                // Singleton
                let frc20Indexer = FRC20Indexer.getIndexer()
                assert(
                    frc20Indexer.getTokenMeta(tick: rewardTick) != nil,
                    message: "Reward tick must be valid"
                )
                self.totalReward <- FRC20FTShared.createEmptyChange(tick: rewardTick, from: pool.address)
            }

            // emit event
            emit RewardStrategyInitialized(
                pool: pool.address,
                stakeTick: poolRef.tick,
                rewardTick: rewardTick,
                ftVaultType: isFtVault ? self.totalReward.getVaultType()?.identifier! : nil
            )
        }

        /// @deprecated after Cadence 1.0
        destroy() {
            destroy self.totalReward
        }

        access(account)
        fun addIncome(income: @FRC20FTShared.Change) {
            pre {
                self.poolCap.check(): "Pool must be valid"
                self.owner?.address == self.poolCap.address: "Pool owner must match with reward strategy owner"
                income.tick == self.rewardTick: "Income tick must match with reward strategy tick"
            }

            let pool = (self.poolCap.borrow() ?? panic("Pool must exist")).borrowSelf()

            let incomeFrom = income.from
            let incomeValue = income.getBalance()
            if incomeValue > 0.0 {
                let totalStakedRef = pool.borrowTotalStaked()
                // add to total reward and update global yield rate
                let totalStakedToken = totalStakedRef.getBalance()
                let newAddedYieldRate = totalStakedToken > 0.0
                    ? incomeValue / totalStakedToken
                    : 0.0
                // update global yield rate
                self.globalYieldRate = self.globalYieldRate + newAddedYieldRate

                if newAddedYieldRate > 0.0 {
                    // add to total reward
                    FRC20FTShared.depositToChange(
                        receiver: self.borrowRewardRef(),
                        change: <- income
                    )

                    // emit event
                    emit RewardIncomeAdded(
                        pool: pool.owner?.address!,
                        tick: self.rewardTick,
                        amount: incomeValue,
                        from: incomeFrom
                    )
                } else {
                    // if the income is not enough to update the global yield rate
                    // deposit the income to pool's address
                    let poolAddr = pool.owner?.address ?? panic("Pool owner must exist")
                    // create an empty change for the reward
                    let newChange <- FRC20FTShared.createEmptyChange(
                        tick: self.rewardTick,
                        from: poolAddr
                    )
                    // Deposit pool address for accumulating enough values
                    FRC20FTShared.depositToChange(
                        receiver: &newChange as &FRC20FTShared.Change,
                        change: <- income
                    )
                    let indexer = FRC20Indexer.getIndexer()
                    // deposit change to indexer
                    indexer.returnChange(change: <- newChange)
                }
            } else {
                destroy income
            }
        }

        /// Claim reward, the return valus's from is the delegator's address
        ///
        access(account)
        fun claim(
            byNft: &FRC20SemiNFT.NFT{FRC20SemiNFT.IFRC20SemiNFT},
        ): @FRC20FTShared.Change {
            pre {
                self.poolCap.check(): "Pool must be valid"
                self.owner?.address == self.poolCap.address: "Pool owner must match with reward strategy owner"
                byNft.getOriginalTick() == self.stakeTick: "NFT tick must match with reward strategy tick"
            }
            post {
                byNft.owner?.address == result.from: "Result from must match with NFT owner"
            }
            let pool = (self.poolCap.borrow() ?? panic("Pool must exist")).borrowSelf()

            // global info
            let totalStakedRef = pool.borrowTotalStaked()
            let totalStakedToken = totalStakedRef.getBalance()
            let totalRewardBalance = self.totalReward.getBalance()

            // related addreses info
            let poolAddr = pool.owner?.address ?? panic("Pool owner must exist")
            let delegator = byNft.owner?.address ?? panic("Delegator must exist")

            // create an empty change for the reward
            let delegatorRewardChange <- FRC20FTShared.createEmptyChange(
                tick: self.rewardTick,
                from: delegator
            )

            // delegator info
            let delegatorRef = FRC20Staking.borrowDelegator(delegator)
                ?? panic("Delegator must exist")
            let strategyUniqueName = byNft.buildUniqueName(poolAddr, self.rewardTick)
            let claimingRecord = byNft.getClaimingRecord(strategyUniqueName)

            // calculate reward
            let delegatorLastGlobalYieldRate = claimingRecord?.lastGlobalYieldRate ?? 0.0
            let delegatorStakedToken = byNft.getBalance() // staked token's balance is the same as NFT's balance

            // ensure delegator's global yield rate is less than current global yield rate
            if self.globalYieldRate <= delegatorLastGlobalYieldRate {
                // no reward to claim
                return <- delegatorRewardChange
            }

            // This is reward to distribute
            let yieldReward = (self.globalYieldRate - delegatorLastGlobalYieldRate) * delegatorStakedToken
            assert(
                yieldReward <= totalRewardBalance,
                message: "Reward must be less than total reward"
            )

            // withdraw from totalReward
            let withdrawnChange: @FRC20FTShared.Change <- self.totalReward.withdrawAsChange(amount: yieldReward)

            // update delegator claiming record
            delegatorRef.onClaimingReward(
                reward: self.borrowSelf(),
                byNftId: byNft.id,
                amount: yieldReward,
                currentGlobalYieldRate: self.globalYieldRate
            )

            // emit event
            emit DelegatorClaimedReward(
                pool: self.owner?.address ?? panic("Reward owner must exist"),
                stakeTick: self.stakeTick,
                rewardTick: self.rewardTick,
                amount: yieldReward,
                yieldAdded: self.globalYieldRate
            )

            // Deposit the reward to delegatorRewardChange's change
            FRC20FTShared.depositToChange(
                receiver: &delegatorRewardChange as &FRC20FTShared.Change,
                change: <- withdrawnChange
            )
            // return the change
            return <- delegatorRewardChange
        }

        /** ---- Internal Methods ---- */

        access(self)
        fun borrowRewardRef(): &FRC20FTShared.Change {
            return &self.totalReward as &FRC20FTShared.Change
        }

        access(self)
        fun borrowSelf(): &RewardStrategy {
            return &self as &RewardStrategy
        }
    }

    /// Delegator Public Interface
    ///
    access(all) resource interface DelegatorPublic {
        /** ---- Public methods ---- */

        /// Get the staked frc20 token balance of the delegator
        access(all) view
        fun getStakedBalance(tick: String): UFix64

        /// Get the staked frc20 Semi-NFTs of the delegator
        access(all) view
        fun getStakedNFTIds(tick: String): [UInt64]

        /** ---- Contract level methods ---- */

        /// Invoked when the staking is successful
        access(contract)
        fun onFRC20Staked(
            stakedChange: @FRC20FTShared.Change
        )

        /// Update the claiming record
        access(contract)
        fun onClaimingReward(
            reward: &RewardStrategy,
            byNftId: UInt64,
            amount: UFix64,
            currentGlobalYieldRate: UFix64
        )
    }

    /// Delegator Resource, represents a delegator and store in user's account
    ///
    access(all) resource Delegator: DelegatorPublic {
        access(self)
        let semiNFTcolCap: Capability<&FRC20SemiNFT.Collection{FRC20SemiNFT.FRC20SemiNFTCollectionPublic, FRC20SemiNFT.FRC20SemiNFTBorrowable, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>

        init(
            _ semiNFTCol: Capability<&FRC20SemiNFT.Collection{FRC20SemiNFT.FRC20SemiNFTCollectionPublic, FRC20SemiNFT.FRC20SemiNFTBorrowable, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>
        ) {
            pre {
                semiNFTCol.check(): "SemiNFT Collection must be valid"
            }
            self.semiNFTcolCap = semiNFTCol
        }

        /** ----- Public Methods ----- */

        /// Get the staked frc20 token balance of the delegator
        ///
        access(all) view
        fun getStakedBalance(tick: String): UFix64 {
            let colRef = self.borrowSemiNFTCollection()
            return colRef.getStakedBalance(tick: tick)
        }

        /// Get the staked frc20 Semi-NFTs of the delegator
        ///
        access(all) view
        fun getStakedNFTIds(tick: String): [UInt64] {
            let colRef = self.borrowSemiNFTCollection()
            return colRef.getIDsByTick(tick: tick)
        }

        /** ----- Contract Methods ----- */

        /// Invoked when the staking is successful
        ///
        access(contract)
        fun onFRC20Staked(
            stakedChange: @FRC20FTShared.Change
        ) {
            pre {
                stakedChange.isStakedTick(): "Staked change tick must be staked tick"
            }
            let from = stakedChange.from
            let pool = FRC20Staking.borrowPool(from)
                ?? panic("Pool must exist")
            assert(
                pool.tick == stakedChange.getOriginalTick(),
                message: "Staked change tick must match"
            )
            // deposit
            self._depositStakedToken(change: <- stakedChange)
        }

        /// Update the claiming record
        ///
        access(contract)
        fun onClaimingReward(
            reward: &RewardStrategy,
            byNftId: UInt64,
            amount: UFix64,
            currentGlobalYieldRate: UFix64
        ) {
            let pool = reward.owner?.address ?? panic("Reward owner must exist")

            // borrow the nft from semiNFT collection
            let semiNFTCol = self.borrowSemiNFTCollection()
            let stakedNFT = semiNFTCol.borrowFRC20SemiNFT(id: byNftId)
                ?? panic("Staked NFT must exist")

            // update the claiming record
            stakedNFT.onClaimingReward(
                poolAddress: pool,
                rewardTick: reward.rewardTick,
                amount: amount,
                currentGlobalYieldRate: currentGlobalYieldRate
            )
        }

        /** ----- Internal Methods ----- */

        access(self)
        fun _depositStakedToken(change: @FRC20FTShared.Change) {
            let tick = change.getOriginalTick()
            let semiNFTCol = self.borrowSemiNFTCollection()

            let initialYieldRates: {String: UFix64} = {}
            // update all reward strategies record
            let pool = FRC20Staking.borrowPool(change.from)
                ?? panic("Pool must exist")
            let fromPool = change.from
            let amount = change.getBalance()
            let strategies = pool.getRewardNames()
            log("Init SemiNFT with balance: ".concat(amount.toString()))
            for rewardTick in strategies {
                if let reward: &FRC20Staking.RewardStrategy = pool.borrowRewardStrategy(rewardTick) {
                    // update the claiming record
                    initialYieldRates[rewardTick] = reward.globalYieldRate
                }
                log("Reward tick: ".concat(rewardTick).concat(" initial yield rate:").concat(initialYieldRates[rewardTick]!.toString()))
            }
            // wrap the change to semiNFT
            let nftId = FRC20SemiNFT.wrap(
                recipient: semiNFTCol,
                change: <- change,
                initialYieldRates: initialYieldRates
            )

            // emit event
            emit DelegatorStakedTokenDeposited(
                tick: tick,
                pool: fromPool,
                receiver: self.owner?.address ?? panic("Delegator owner must exist"),
                amount: amount,
                semiNftId: nftId
            )
        }

        /// Borrow Staked Change
        ///
        access(self)
        fun borrowSemiNFTCollection(): &FRC20SemiNFT.Collection{FRC20SemiNFT.FRC20SemiNFTCollectionPublic, FRC20SemiNFT.FRC20SemiNFTBorrowable, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection} {
            return self.semiNFTcolCap.borrow() ?? panic("The SemiNFT Collection must exist")
        }
    }

    /** ---- Account access methods ---- */

    /// Create the Staking Pool resource
    ///
    access(account)
    fun createPool(_ tick: String): @Pool {
        return <- create Pool(tick)
    }

    /** ---- public methods ---- */

    /// Get the lock time of unstaking
    ///
    access(all)
    fun getUnstakingLockTime(): UInt64 {
        // 1 day = 86400 seconds
        return 86400
    }

    /// Borrow Pool by address
    ///
    access(all)
    fun borrowPool(_ addr: Address): &Pool{PoolPublic}? {
        return self.getPoolCap(addr).borrow()
    }

    /// Borrow Pool Capability by address
    ///
    access(all)
    fun getPoolCap(_ addr: Address): Capability<&Pool{PoolPublic}> {
        return getAccount(addr)
            .getCapability<&Pool{PoolPublic}>(self.StakingPoolPublicPath)
    }

    /// Borrow Delegate by address
    ///
    access(all)
    fun borrowDelegator(_ addr: Address): &Delegator{DelegatorPublic}? {
        return getAccount(addr)
            .getCapability<&Delegator{DelegatorPublic}>(self.DelegatorPublicPath)
            .borrow()
    }

    /// Create the Delegator resource
    ///
    access(all)
    fun createDelegator(
        _ semiNFTCol: Capability<&FRC20SemiNFT.Collection{FRC20SemiNFT.FRC20SemiNFTCollectionPublic, FRC20SemiNFT.FRC20SemiNFTBorrowable, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>
    ): @Delegator {
        pre {
            semiNFTCol.check(): "SemiNFT Collection must be valid"
        }
        return <- create Delegator(semiNFTCol)
    }

    init() {
        let identifier = "FRC20Staking_".concat(self.account.address.toString())
        self.StakingPoolStoragePath = StoragePath(identifier: identifier.concat("_pool"))!
        self.StakingPoolPublicPath = PublicPath(identifier: identifier.concat("_pool"))!
        self.DelegatorStoragePath = StoragePath(identifier: identifier.concat("_delegator"))!
        self.DelegatorPublicPath = PublicPath(identifier: identifier.concat("_delegator"))!

        emit ContractInitialized()
    }
}
