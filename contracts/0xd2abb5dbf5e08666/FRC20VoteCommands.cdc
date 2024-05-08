/**
> Author: FIXeS World <https://fixes.world/>

# FRC20VoteCommands

This contract is used to manage the frc20 vote commands.

*/
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
import Fixes from "./Fixes.cdc"
import FixesInscriptionFactory from "./FixesInscriptionFactory.cdc"
import FRC20Indexer from "./FRC20Indexer.cdc"
import FRC20FTShared from "./FRC20FTShared.cdc"
import FRC20AccountsPool from "./FRC20AccountsPool.cdc"
import FRC20StakingManager from "./FRC20StakingManager.cdc"
import FRC20StakingVesting from "./FRC20StakingVesting.cdc"
import FGameLottery from "./FGameLottery.cdc"
import FGameLotteryRegistry from "./FGameLotteryRegistry.cdc"
import FGameLotteryFactory from "./FGameLotteryFactory.cdc"

access(all) contract FRC20VoteCommands {

    /// The Proposal command type.
    ///
    access(all) enum CommandType: UInt8 {
        access(all) case None;
        access(all) case SetBurnable;
        access(all) case BurnUnsupplied;
        access(all) case MoveTreasuryToLotteryJackpot;
        access(all) case MoveTreasuryToStakingReward;
    }

    /// The interface of FRC20 vote command struct.
    ///
    access(all) struct interface IVoteCommand {
        access(all)
        let inscriptionIds: [UInt64]

        init() {
            post {
                self.verifyVoteCommands(): "Invalid vote commands"
            }
        }

        // ----- Readonly Mehtods -----

        access(all) view
        fun getCommandType(): CommandType
        access(all) view
        fun verifyVoteCommands(): Bool

        /// Check if all inscriptions are extracted.
        ///
        access(all) view
        fun isAllInscriptionsExtracted(): Bool {
            let insRefArr = self.borrowSystemInscriptionWritableRefs()
            for insRef in insRefArr {
                if !insRef.isExtracted() {
                    return false
                }
            }
            return true
        }

        // ----- Account level methods -----

        /// Refund the inscription cost for failed vote commands.
        ///
        access(account)
        fun refundFailedVoteCommands(receiver: Address): Bool {
            let recieverRef = FRC20Indexer.borrowFlowTokenReceiver(receiver)
            if recieverRef == nil {
                return false
            }
            let store = FRC20VoteCommands.borrowSystemInscriptionsStore()
            let insRefArr = self.borrowSystemInscriptionWritableRefs()

            let vault <- FlowToken.createEmptyVault()
            for insRef in insRefArr {
                if !insRef.isExtracted() {
                    vault.deposit(from: <-insRef.extract())
                }
            }
            // deposit to the receiver
            recieverRef!.deposit(from: <- vault)
            return true
        }

        // Methods: Write
        access(account)
        fun safeRunVoteCommands(): Bool

        // ----- General Methods -----

        /// Borrow the system inscriptions references from store.
        ///
        access(contract)
        fun borrowSystemInscriptionWritableRefs(): [&Fixes.Inscription] {
            let store = FRC20VoteCommands.borrowSystemInscriptionsStore()
            let ret: [&Fixes.Inscription] = []
            for id in self.inscriptionIds {
                if let ref = store.borrowInscriptionWritableRef(id) {
                    ret.append(ref)
                }
            }
            return ret
        }
    }

    /**
     * Command: None
     */
    access(all) struct CommandNone: IVoteCommand {
        access(all)
        let inscriptionIds: [UInt64]

        init() {
            self.inscriptionIds = []
        }

        // ----- Methods: Read -----

        access(all) view
        fun getCommandType(): CommandType {
            return CommandType.None
        }

        access(all) view
        fun verifyVoteCommands(): Bool {
            return true
        }

        // ---- Methods: Write ----

        access(account)
        fun safeRunVoteCommands(): Bool {
            return true
        }
    }

    /**
     * Command: SetBurnable
     */
    access(all) struct CommandSetBurnable: IVoteCommand {
        access(all)
        let inscriptionIds: [UInt64]

        init(_ insIds: [UInt64]) {
            self.inscriptionIds = insIds
        }

        // ----- Methods: Read -----

        access(all) view
        fun getCommandType(): CommandType {
            return CommandType.SetBurnable
        }

        access(all) view
        fun verifyVoteCommands(): Bool {
            // Refs
            let frc20Indexer = FRC20Indexer.getIndexer()
            let insRefArr = self.borrowSystemInscriptionWritableRefs()

            var isValid = false
            isValid = insRefArr.length == 1
            if isValid {
                let ins = insRefArr[0]
                let meta = frc20Indexer.parseMetadata(&ins.getData() as &Fixes.InscriptionData)
                isValid = FRC20VoteCommands.isValidSystemInscription(ins)
                    && meta["op"] == "burnable" && meta["tick"] != nil && meta["v"] != nil
            }
            return isValid
        }

        // ---- Methods: Write ----

        access(account)
        fun safeRunVoteCommands(): Bool {
            // Refs
            let frc20Indexer = FRC20Indexer.getIndexer()
            let insRefArr = self.borrowSystemInscriptionWritableRefs()

            if insRefArr.length != 1 {
                return false
            }
            frc20Indexer.setBurnable(ins: insRefArr[0])
            return true
        }
    }

    /**
     * Command: BurnUnsupplied
     */
    access(all) struct CommandBurnUnsupplied: IVoteCommand {
        access(all)
        let inscriptionIds: [UInt64]

        init(_ insIds: [UInt64]) {
            self.inscriptionIds = insIds
        }

        // ----- Methods: Read -----

        access(all) view
        fun getCommandType(): CommandType {
            return CommandType.BurnUnsupplied
        }

        access(all) view
        fun verifyVoteCommands(): Bool {
            // Refs
            let frc20Indexer = FRC20Indexer.getIndexer()
            let insRefArr = self.borrowSystemInscriptionWritableRefs()

            var isValid = insRefArr.length == 1
            if isValid {
                let ins = insRefArr[0]
                let meta = frc20Indexer.parseMetadata(&ins.getData() as &Fixes.InscriptionData)
                isValid = FRC20VoteCommands.isValidSystemInscription(ins)
                    && meta["op"] == "burnUnsup" && meta["tick"] != nil && meta["perc"] != nil
            }
            return isValid
        }

        // ---- Methods: Write ----

        access(account)
        fun safeRunVoteCommands(): Bool {
            // Refs
            let frc20Indexer = FRC20Indexer.getIndexer()
            let insRefArr = self.borrowSystemInscriptionWritableRefs()

            if insRefArr.length != 1 {
                return false
            }
            frc20Indexer.burnUnsupplied(ins: insRefArr[0])
            return true
        }
    }

    /**
     * Command: MoveTreasuryToLotteryJackpot
     */
    access(all) struct CommandMoveTreasuryToLotteryJackpot: IVoteCommand {
        access(all)
        let inscriptionIds: [UInt64]

        init(_ insIds: [UInt64]) {
            self.inscriptionIds = insIds
        }

        // ----- Methods: Read -----

        access(all) view
        fun getCommandType(): CommandType {
            return CommandType.MoveTreasuryToLotteryJackpot
        }

        access(all) view
        fun verifyVoteCommands(): Bool {
            // Refs
            let frc20Indexer = FRC20Indexer.getIndexer()
            let insRefArr = self.borrowSystemInscriptionWritableRefs()

            var isValid = insRefArr.length == 1
            if isValid {
                let ins = insRefArr[0]
                let meta = frc20Indexer.parseMetadata(&ins.getData() as &Fixes.InscriptionData)
                isValid = FRC20VoteCommands.isValidSystemInscription(ins)
                    && meta["op"] == "withdrawFromTreasury" && meta["usage"] == "lottery" && meta["tick"] != nil && meta["amt"] != nil
            }
            return isValid
        }

        // ---- Methods: Write ----

        access(account)
        fun safeRunVoteCommands(): Bool {
            // Refs
            let frc20Indexer = FRC20Indexer.getIndexer()
            let insRefArr = self.borrowSystemInscriptionWritableRefs()

            if insRefArr.length != 1 {
                return false
            }
            let flowLotteryName = FGameLotteryFactory.getFIXESMintingLotteryPoolName()
            let registery = FGameLotteryRegistry.borrowRegistry()
            if let poolAddr = registery.getLotteryPoolAddress(flowLotteryName) {
                if let poolRef = FGameLottery.borrowLotteryPool(poolAddr) {
                    let withdrawnChange <- frc20Indexer.withdrawFromTreasury(ins: insRefArr[0])
                    poolRef.donateToJackpot(payment: <- withdrawnChange)
                    return true
                }
            }
            log("Failed to find the lottery pool")
            return false
        }
    }

    /**
     * Command: MoveTreasuryToStakingReward
     */
    access(all) struct CommandMoveTreasuryToStakingReward: IVoteCommand {
        access(all)
        let inscriptionIds: [UInt64]

        init(_ insIds: [UInt64]) {
            self.inscriptionIds = insIds
        }

        // ----- Methods: Read -----

        access(all) view
        fun getCommandType(): CommandType {
            return CommandType.MoveTreasuryToStakingReward
        }

        access(all) view
        fun verifyVoteCommands(): Bool {
            // Refs
            let frc20Indexer = FRC20Indexer.getIndexer()
            let insRefArr = self.borrowSystemInscriptionWritableRefs()

            var isValid = insRefArr.length == 1
            if isValid {
                let ins = insRefArr[0]
                let meta = frc20Indexer.parseMetadata(&ins.getData() as &Fixes.InscriptionData)
                isValid = FRC20VoteCommands.isValidSystemInscription(ins)
                    && meta["op"] == "withdrawFromTreasury" && meta["usage"] == "staking"
                    && meta["tick"] != nil && meta["amt"] != nil
                    && meta["batch"] != nil && meta["interval"] != nil
            }
            return isValid
        }

        // ---- Methods: Write ----

        access(account)
        fun safeRunVoteCommands(): Bool {
            // Refs
            let frc20Indexer = FRC20Indexer.getIndexer()
            let insRefArr = self.borrowSystemInscriptionWritableRefs()

            if insRefArr.length != 1 {
                return false
            }
            let ins = insRefArr[0]
            let meta = frc20Indexer.parseMetadata(&ins.getData() as &Fixes.InscriptionData)

            // singleton resources
            let acctsPool = FRC20AccountsPool.borrowAccountsPool()
            let platformStakeTick = FRC20StakingManager.getPlatformStakingTickerName()
            let vestingBatch = UInt32.fromString(meta["batch"]!)
            let vestingInterval = UFix64.fromString(meta["interval"]!)
            if vestingBatch == nil || vestingInterval == nil {
                log("Invalid vesting batch or interval")
                return false
            }
            if let stakingAddress = acctsPool.getFRC20StakingAddress(tick: platformStakeTick) {
                if let vestingVault = FRC20StakingVesting.borrowVaultRef(stakingAddress) {
                    let withdrawnChange <- frc20Indexer.withdrawFromTreasury(ins: insRefArr[0])
                    FRC20StakingManager.donateToVestingFromChange(
                        changeToDonate: <- withdrawnChange,
                        tick: platformStakeTick,
                        vestingBatchAmount: vestingBatch!,
                        vestingInterval: vestingInterval!
                    )
                    return true
                }
            }
            log("Failed to find valid staking pool")
            return false
        }
    }

    /// Check if the given inscription is a valid system inscription.
    ///
    access(contract)
    fun isValidSystemInscription(_ ins: &Fixes.Inscription{Fixes.InscriptionPublic}): Bool {
        let frc20Indexer = FRC20Indexer.getIndexer()
        return ins.owner?.address == self.account.address
            && ins.isExtractable()
            && frc20Indexer.isValidFRC20Inscription(ins: ins)
    }

    /// Borrow the system inscriptions store.
    ///
    access(all)
    fun borrowSystemInscriptionsStore(): &Fixes.InscriptionsStore{Fixes.InscriptionsStorePublic, Fixes.InscriptionsPublic} {
        let storePubPath = Fixes.getFixesStorePublicPath()
        return self.account
            .getCapability<&Fixes.InscriptionsStore{Fixes.InscriptionsStorePublic, Fixes.InscriptionsPublic}>(storePubPath)
            .borrow() ?? panic("Fixes.InscriptionsStore is not found")
    }

    /// Build the inscription strings by the given command type and meta.
    ///
    access(all)
    fun buildInscriptionStringsByCommand(_ type: CommandType, _ meta: {String: String}): [String] {
        switch type {
        case CommandType.None:
            return []
        case CommandType.SetBurnable:
            return [
                FixesInscriptionFactory.buildVoteCommandSetBurnable(
                    tick: meta["tick"] ?? panic("Missing tick in params"),
                    burnable: meta["v"] == "1"
                )
            ]
        case CommandType.BurnUnsupplied:
            return [
                FixesInscriptionFactory.buildVoteCommandBurnUnsupplied(
                    tick: meta["tick"] ?? panic("Missing tick in params"),
                    percent: UFix64.fromString(meta["perc"] ?? panic("Missing perc in params")) ?? panic("Invalid perc")
                )
            ]
        case CommandType.MoveTreasuryToLotteryJackpot:
            return [
                FixesInscriptionFactory.buildVoteCommandMoveTreasuryToLotteryJackpot(
                    tick: meta["tick"] ?? panic("Missing tick in params"),
                    amount: UFix64.fromString(meta["amt"] ?? panic("Missing amt in params")) ?? panic("Invalid amt")
                )
            ]
        case CommandType.MoveTreasuryToStakingReward:
            return [
                FixesInscriptionFactory.buildVoteCommandMoveTreasuryToStaking(
                    tick: meta["tick"] ?? panic("Missing tick in params"),
                    amount: UFix64.fromString(meta["amt"] ?? panic("Missing amt in params")) ?? panic("Invalid amt"),
                    vestingBatchAmount: UInt32.fromString(meta["batch"] ?? panic("Missing batch in params")) ?? panic("Invalid batch"),
                    vestingInterval: UFix64.fromString(meta["interval"] ?? panic("Missing interval in params")) ?? panic("Invalid interval")
                )
            ]
        }
        panic("Invalid command type")
    }

    /// Create a vote command by the given type and inscriptions.
    ///
    access(all)
    fun createByCommandType(_ type: CommandType, _ inscriptions: [UInt64]): {IVoteCommand} {
        let store = self.borrowSystemInscriptionsStore()
        // Ensure the inscriptions are valid
        for ins in inscriptions {
            let insRef = store.borrowInscription(ins)
            if insRef == nil {
                panic("Invalid inscription")
            }
        }

        switch type {
        case CommandType.None:
            return CommandNone()
        case CommandType.SetBurnable:
            return CommandSetBurnable(inscriptions)
        case CommandType.BurnUnsupplied:
            return CommandBurnUnsupplied(inscriptions)
        case CommandType.MoveTreasuryToLotteryJackpot:
            return CommandMoveTreasuryToLotteryJackpot(inscriptions)
        case CommandType.MoveTreasuryToStakingReward:
            return CommandMoveTreasuryToStakingReward(inscriptions)
        }
        panic("Invalid command type")
    }
}
