import PlayToken from "./PlayToken.cdc"
import ScoreToken from "./ScoreToken.cdc"
import MoxyToken from "./MoxyToken.cdc"
import MoxyVaultToken from "./MoxyVaultToken.cdc"
import LockedMoxyToken from "./LockedMoxyToken.cdc"
import LockedMoxyVaultToken from "./LockedMoxyVaultToken.cdc"
import MoxyReleaseRounds from "./MoxyReleaseRounds.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MoxyProcessQueue from "./MoxyProcessQueue.cdc"
import MoxyData from "./MoxyData.cdc"
 

pub contract MoxyClub {

    // Initial fee amount paid to association
    pub var membershipFee: UFix64

    pub event MoxyAccountAdded(address: Address)
    pub event RoundAdded(name: String)

    // Fee Charged event on MOX transfer
    pub event FeeCharged(address: Address, amount: UFix64)

    // Treasury repurchase event triggered when Treasury wallet has received MOX tokens
    // This will enforce PLAY token with the 10% of MOX received on a 2:1 MOX to PLAY
    // conversion 
    pub event TreasuryRepurchase(amount: UFix64)

    pub event MOXRewaredDueMVHoldingsTo(address: Address, timestamp: UFix64, amount: UFix64)
    pub event MOXRewaredDueDailyActivityTo(address: Address, timestamp: UFix64, amount: UFix64)
    pub event MOXToMVDailyConversionTo(address: Address, timestamp: UFix64, amount: UFix64)
    pub event MOXRewardedToPoPUserNotGoodStanding(address: Address, timestamp: UFix64, amountMOXY: UFix64, amountPLAY: UFix64)

    pub event MembershipFeeDeducted(address: Address, feeDeducted: UFix64, feeDeductedMOXY: UFix64, remaining: UFix64, moxyToUSDValue: UFix64)
    
    pub event MembershipFeeChanged(newAmount: UFix64, newAmountMOXY: UFix64, oldAmount: UFix64, oldAmountMOXY: UFix64, moxyToUSDValue: UFix64)

    //Events to process Start of Round Releases
    pub event StartingRoundReleaseInitializeProcess(timestamp: UFix64, roundsToProcess: Int, accountsToProcess: Int)
    pub event FinishedRoundReleaseInitializeProcess(timestamp: UFix64, roundsProcessed: Int, accountsProcessed: Int)

    //Events to process Round Release allocations
    pub event StartingDailyRoundReleaseAllocationProcess(timestamp: UFix64, accountsToProcess: Int)
    pub event FinishedDailyRoundReleaseAllocationProcess(timestamp: UFix64, accountsProcessed: Int)
    pub event NoAddressesToProcessForRoundReleaseAllocation(timestamp: UFix64)
    pub event BatchDailyRoundReleaseAllocationProcess(timestamp: UFix64, requestedToProcess: Int, accountsProcessed: Int, totalAccounts: Int)

    //Events when paying MV Holdings
    pub event PaidAlreadyMadeWhenPayingMVHoldingsRewards(address: Address, timestamp: UFix64)
    pub event AddressNotFoundWhenPayingMVHoldingsRewards(address: Address, timestamp: UFix64)
    pub event RequestedDateSmallerToLastUpdateWhenPayingMVHoldingsRewards(address: Address, timestamp: UFix64, lastMVHoldingsUpdatedTimestamp: UFix64)
    pub event StartingRewardsPaymentsDueMVHoldings(timestamp: UFix64, accountsToProcess: Int)
    pub event NoAddressesToProcessForMVHoldingsProcess(timestamp: UFix64)
    pub event FinishedRewardsPaymentsDueMVHoldings(timestamp: UFix64, accountsProcessed: Int)
    pub event BatchRewardsPaymentsDueMVHoldings(timestamp: UFix64, requestedToProcess: Int, accountsProcessed: Int, totalAccounts: Int)

    // Event for Proof of Play (PoP) rewards
    pub event AddressNotFoundWhenPayingPoPRewards(address: Address, timestamp: UFix64)
    pub event StartingRewardsPaymentsDuePoP(timestamp: UFix64, accountsToProcess: Int)
    pub event FinishedRewardsPaymentsDuePoP(timestamp: UFix64, accountsProcessed: Int)
    pub event RequestedDateSmallerToLastUpdateWhenPayingPoPRewards(address: Address, timestamp: UFix64, lastDailyActivityUpdatedTimestamp: UFix64)
    pub event NoAddressesToProcessForPoPProcess(timestamp: UFix64)
    pub event BatchRewardsPaymentsDuePoP(timestamp: UFix64, requestedToProcess: Int, accountsProcessed: Int, totalAccounts: Int)

    //Events when Vaults not found on users storage
    pub event AccountDoesNotHaveScoreVault(address: Address, message: String)
    pub event AccountDoesNotHaveMoxyVaultVault(address: Address, message: String)

    // Ecosystem parameters modifications events
    pub event MOXYToFLOWValueChanged(oldAmount: UFix64, newAmount: UFix64, timestamp: UFix64)
    pub event MOXYToUSDValueChanged(oldAmount: UFix64, newAmount: UFix64, timestamp: UFix64)
    pub event TreasuryAddressChanged(newAddress: Address)
    pub event AssociationAddressChanged(newAddress: Address)
    
    // Play and Earn private reference assigned
    pub event PlayAndEarnReferenceAssigned(address: Address)
    pub event PlayAndEarnEventAccountAdded(address: Address)
    
    
    // Moxy Controlled Accounts events
    pub event MoxyControlledAccountAdded(address: Address)

    // Events for process of paying MOXY due MV conversion
    pub event StartingPayingMOXYDueMVConversion(timestamp: UFix64, accountsToProcess: Int)
    pub event FinishedPayingMOXYDueMVConversion(timestamp: UFix64, accountsProcessed: Int)
    pub event MVToMOXYConversionPerformed(address: Address, amount: UFix64, timestamp: UFix64)
    pub event MVToMOXYConversionAlreadyPerformed(address: Address, timestamp: UFix64, lastUpdated: UFix64)
    pub event MVToMOXYConversionAlreadyFinished(address: Address, timestamp: UFix64, lastUpdated: UFix64)
    pub event NoAddressesToProcessMVConversionProcess(timestamp: UFix64)
    pub event BatchPayingMOXYDueMVConversion(timestamp: UFix64, requestedToProcess: Int, accountsProcessed: Int, totalAccounts: Int)

    // Event when Proof of Play weights are modified
    pub event PopWeightsChanged(newScoreWeight: UFix64, newDailyScoreWeight: UFix64, newPlayDonationWeight: UFix64)

    // Launch fee events
    pub event LaunchFeeChanged(newAmount: UFix64)
    pub event LaunchFeePaid(address: Address, amount: UFix64)

    // Masterclass events
    pub event MasterclassPricePaid(address: Address, amount: UFix64)
    pub event MasterclassPriceAdded(classId: String, feeAmount: UFix64)
    pub event MasterclassPriceUpdated(classId: String, oldFeeAmount: UFix64, newFeeAmount: UFix64)
    pub event MasterclassPriceRemoved(classId: String)

    // Games Prices
    pub event GamePricePaid(gameId: String, address: Address, amount: UFix64)
    pub event GamePriceAdded(gameId: String, feeAmount: UFix64)
    pub event GamePriceUpdated(gameId: String, oldFeeAmount: UFix64, newFeeAmount: UFix64)
    pub event GamePriceRemoved(gameId: String)

    // Refund payments from treasury
    pub event RefundedPayment(totalRefunded: UFix64, toAddress: Address, playBurned: UFix64) 


   pub resource MoxyAccount {
        
        // Variables for MV Holdings
        access(contract) var earnedFromMVHoldings: {UFix64:UFix64}
        access(contract) var totalEarnedFromMVHoldings: UFix64
        access(contract) var lastMVHoldingsUpdatedTimestamp: UFix64

        // Variables for Daily Activity
        access(contract) var paidDueActivity: {UFix64:UFix64}
        access(contract) var totalPaidDueDailyActivity: UFix64
        pub var dailyActivityUpdatedTimestamp: UFix64
        
        // Variables for MV Conversion
        access(contract) var totalPaidDueMVConversion: UFix64


        access(contract) var mvToMOXYConverters: Capability<&{UFix64:MVToMOXYConverter}>?
        pub var membershipFee: UFix64
        pub var membershipFeePaid: UFix64

        pub var playAndEarnRef: Capability<&FungibleToken.Vault>?

        pub var goodStandingOnOpenEvents: MoxyData.DictionaryMapped

        pub fun setDailyActivityUpdatedTimestamp(timestamp: UFix64) {
            self.dailyActivityUpdatedTimestamp = timestamp
        }

        pub fun setLastMVHoldingsUpdatedTimestamp(timestamp: UFix64) {
            self.lastMVHoldingsUpdatedTimestamp = timestamp
        }

        pub fun setMOXEarnedFromMVHoldingsFor(timestamp: UFix64, amount: UFix64) {
            if (amount > 0.0) {
                self.earnedFromMVHoldings[timestamp] = amount
                self.totalEarnedFromMVHoldings = self.totalEarnedFromMVHoldings + amount
            }
            self.lastMVHoldingsUpdatedTimestamp = timestamp
        }

        pub fun updateTotalPaidDueDailyActivity(amount: UFix64) {
            let timestamp = MoxyData.getTimestampTo0000(timestamp: getCurrentBlock().timestamp)
            if (self.paidDueActivity[timestamp] == nil) {
                self.paidDueActivity[timestamp] = 0.0
            } 
            self.paidDueActivity[timestamp] = self.paidDueActivity[timestamp]! + amount
            self.totalPaidDueDailyActivity = self.totalPaidDueDailyActivity + amount
        }

        pub fun updateTotalPaidDueMVConversion(amount: UFix64) {
            self.totalPaidDueMVConversion = self.totalPaidDueMVConversion + amount
        }

        pub fun setMVToMOXYConverters(capabilityRef: Capability<&{UFix64:MVToMOXYConverter}>){
            self.mvToMOXYConverters = capabilityRef
        }

        access(contract) fun hasVaildMVToMOXYConverters(address: Address): Bool {
            var hasValid = true
            let converters = self.mvToMOXYConverters!.borrow()!
            for time in converters.keys {
                let addr = converters[time]?.getOwnerAddress()!
                hasValid = hasValid && (address == converters[time]?.getOwnerAddress()!)
            }

            return hasValid
        }

        pub fun getMVToMOXYTotalInConversion(): UFix64 {
            var total = 0.0
            let converters = self.mvToMOXYConverters!.borrow()!
            for time in converters.keys {
                let amount = converters[time]?.getTotalToConvertRemaining()!
                total = total + amount
            }
            return total
        }

        pub fun payMOXDueMVConversionUpto(timestamp: UFix64): UFix64 {
            var conversionsFinished = true
            var total = 0.0
            let converters = self.mvToMOXYConverters!.borrow()!
            for time in converters.keys {
                let amount = converters[time]?.payUpto(timestamp: timestamp)!
                total = total + amount
            }
            return total
        }

        pub fun haveFinishedConversions(): Bool {
            var conversionsFinished = true
            let converters = self.mvToMOXYConverters!.borrow()!
            for time in converters.keys {
                conversionsFinished = conversionsFinished && converters[time]?.hasFinished()!
            }
            return conversionsFinished
        }

        pub fun getMVToMOXtRequests(): {UFix64: MVToMOXRequestInfo} {
            let array: {UFix64:MVToMOXRequestInfo} = {} 
            let converters = self.mvToMOXYConverters!.borrow()!
            for time in converters.keys {
                let request = MVToMOXRequestInfo(amount: converters[time]?.conversionAmount!, 
                    amountReleased: converters[time]?.convertedAmount!, creationTimestamp: converters[time]?.creationTimestamp!, 
                    lastReleaseTime0000: converters[time]?.lastReleaseTime0000!, finishTimestamp: converters[time]?.getFinishTimestamp()!)
                array[converters[time]?.creationTimestamp!] = request 
            }
            return array
        }

        pub fun getMembershipFeeRemaining(): UFix64 {
            return self.membershipFee - self.membershipFeePaid
        }

        pub fun hasMembershipFeePending(): Bool {
            return (self.membershipFee - self.membershipFeePaid) > 0.0
        }

        pub fun updateMembershipFeePaid(amount: UFix64) {
            self.membershipFeePaid = self.membershipFeePaid + amount
        }

        pub fun getEarnedFromMVHoldings(): {UFix64: UFix64} {
            return self.earnedFromMVHoldings
        }

        pub fun getEarnedFromMVHoldingsFor(timestamp: UFix64): UFix64 {
            let time0000 = MoxyData.getTimestampTo0000(timestamp: timestamp)
            if (self.earnedFromMVHoldings[time0000] == nil) {
                return 0.0
            }
            return self.earnedFromMVHoldings[time0000]!
        }

        pub fun getEarnedFromMVHoldingsForRange(from: UFix64, to: UFix64): {UFix64: UFix64} {
            let from0000 = MoxyData.getTimestampTo0000(timestamp: from)
            let to0000 = MoxyData.getTimestampTo0000(timestamp: to)

            let dict: {UFix64:UFix64} = {}

            let day = 86400.0
            var curr0000 = from0000
            var i = 0
            while (curr0000 <= to0000 && i < 30) {
                var val = self.getEarnedFromMVHoldingsFor(timestamp: curr0000)
                dict[curr0000] = val
                curr0000 = curr0000 + day
                i = i + 1
            }

            return dict
        }

        pub fun getPaidDueActivity(): {UFix64: UFix64} {
            return self.paidDueActivity
        }

        pub fun getPaidDueDailyActivityFor(timestamp: UFix64): UFix64 {
            let time0000 = MoxyData.getTimestampTo0000(timestamp: timestamp)
            if (self.paidDueActivity[time0000] == nil) {
                return 0.0
            }
            return self.paidDueActivity[time0000]!
        }

        pub fun getPaidDueDailyActivityForRange(from: UFix64, to: UFix64): {UFix64: UFix64} {
            let from0000 = MoxyData.getTimestampTo0000(timestamp: from)
            let to0000 = MoxyData.getTimestampTo0000(timestamp: to)

            let dict: {UFix64:UFix64} = {}

            let day = 86400.0
            var curr0000 = from0000
            var i = 0
            while (curr0000 <= to0000 && i < 30) {
                var val = self.getPaidDueDailyActivityFor(timestamp: curr0000)
                dict[curr0000] = val
                curr0000 = curr0000 + day
                i = i + 1
            }

            return dict
        }

        pub fun getTotalEarnedFromMVHoldings(): UFix64 {
            return self.totalEarnedFromMVHoldings
                        
        }

        pub fun getTotalPaidDueDailyActivity(): UFix64 {
            return self.totalPaidDueDailyActivity
                        
        }

        pub fun getTotalPaidDueMVConversion(): UFix64 {
            return self.totalPaidDueMVConversion
                        
        }

        pub fun setPlayAndEarnRef(vaultRef: Capability<&FungibleToken.Vault>) {
            self.playAndEarnRef = vaultRef
        }

        pub fun setMVToMOXYConversionsRef(conversionsRef: Capability<&{UFix64:MoxyClub.MVToMOXYConverter}>) {
            self.mvToMOXYConverters = conversionsRef
        }

        pub fun setIsGoodStandingOnOpenEvents(value: Bool) {
            self.goodStandingOnOpenEvents.setValue(value)
        }

        pub fun isGoodStandingOnOpenEvents():Bool {
            let value = self.goodStandingOnOpenEvents.valueNow()
            if (value == nil) {
                //Not value set yet, default behavior is to be true
                return true
            }
            return value! as! Bool
        }

        pub fun isGoodStandingOnOpenEventsFor(timestamp: UFix64):Bool {
            let value = self.goodStandingOnOpenEvents.valueFor(timestamp: timestamp)
            if (value == nil) {
                //Not value set yet, default behavior is to be true
                return true
            }
            return value! as! Bool
        }

        init(){
            self.dailyActivityUpdatedTimestamp = 0.0
            self.earnedFromMVHoldings = {}
            self.totalEarnedFromMVHoldings = 0.0
            self.paidDueActivity = {}
            self.totalPaidDueDailyActivity = 0.0
            self.totalPaidDueMVConversion = 0.0
            self.lastMVHoldingsUpdatedTimestamp = 0.0
            self.mvToMOXYConverters = nil
            self.membershipFee = MoxyClub.membershipFee //Fee is in USD
            self.membershipFeePaid = 0.0
            self.playAndEarnRef = nil
            self.goodStandingOnOpenEvents = MoxyData.DictionaryMapped()
        }
    }

    pub resource PlayAndEarnAccount {
        pub var creationDate: UFix64
        
        access(contract) fun setCreationDate(timestamp: UFix64) {
            self.creationDate = timestamp
        }

        init() {
            self.creationDate = getCurrentBlock().timestamp
        }
    }     

    pub struct MVToMOXRequestInfo {
        pub var amount: UFix64
        pub var amountReleased: UFix64
        pub var creationTimestamp: UFix64
        pub var lastReleaseTime0000: UFix64
        pub var finishTimestamp: UFix64
        pub var remainingDays: Int
        pub var remainingAmount: UFix64
        
        init(amount: UFix64, amountReleased: UFix64, creationTimestamp: UFix64, lastReleaseTime0000: UFix64, finishTimestamp: UFix64) {
            self.amount = amount
            self.amountReleased = amountReleased
            self.creationTimestamp = creationTimestamp
            self.lastReleaseTime0000 = lastReleaseTime0000
            self.finishTimestamp = finishTimestamp
            self.remainingDays = Int((self.finishTimestamp - self.lastReleaseTime0000) / 86400.0)
            self.remainingAmount = self.amount - self.amountReleased
        }
     }

     pub resource MVToMOXYConverter {
        pub var creationTimestamp: UFix64
        pub var conversionAmount: UFix64
        pub var convertedAmount: UFix64
        pub var mvConverter: @MoxyVaultToken.MVConverter
        pub var lockedMOXYVault: @FungibleToken.Vault
        pub var lastReleaseTime0000: UFix64
        pub var withdrawalDays: Int

        pub fun payUpto(timestamp: UFix64): UFix64 {
            let time0000 = MoxyData.getTimestampTo0000(timestamp: timestamp)
            if (time0000 <= self.lastReleaseTime0000) {
                log("WARNING: Cannot pay MOXY in MV to MOXY convertion because it has already paid up to the requested date")
                emit MVToMOXYConversionAlreadyPerformed(address: self.owner!.address, timestamp: time0000, lastUpdated: self.lastReleaseTime0000)
                return 0.0
            }

            if (self.hasFinished()) {
                log("WARNING: Conversion process already finished")
                emit MVToMOXYConversionAlreadyFinished(address: self.owner!.address, timestamp: time0000, lastUpdated: self.lastReleaseTime0000)
                return 0.0
            }

            let days = UFix64(UInt64((time0000 - self.lastReleaseTime0000) / 86400.0))
            var amount: UFix64 = 0.0 

            // If time is grather than the finish time, the amount to withdraw is
            // all allowed
            if (time0000 >= self.getFinishTimestamp()) {
                // Amount to withdraw is all allowed
                amount = self.mvConverter.allowedAmount
            } else {
                // Amount to withdraw is based on daily pay
                amount = (self.conversionAmount / UFix64(self.withdrawalDays)) * days
            }
            
            // Burn MV
            let admin = MoxyClub.account.borrow<&MoxyVaultToken.Administrator>(from: MoxyVaultToken.moxyVaultTokenAdminStorage)
                ?? panic("Could not borrow a reference to the admin resource")
            let burner <- admin.createNewBurner()
            let vault2 <- self.mvConverter.getDailyVault(amount: amount)
            burner.burnTokens(from: <- vault2)
            destroy burner

            // Convert Locked MOXY to MOXY
            // Get the recipient's public account object
            let recipient = self.lockedMOXYVault.owner!

            // Get a reference to the recipient's Receiver
            let receiverRef = recipient.getCapability(MoxyToken.moxyTokenReceiverPath)
                .borrow<&{FungibleToken.Receiver}>()
                ?? panic("Could not borrow receiver reference to the recipient's Vault")

            let vault3 <- self.lockedMOXYVault.withdraw(amount: amount)
            // Deposit the withdrawn tokens in the recipient's receiver
            receiverRef.deposit(from: <- vault3)

            //update converted amount and timestamp
            self.convertedAmount = self.convertedAmount + amount
            self.lastReleaseTime0000 = time0000

            emit MVToMOXYConversionPerformed(address: recipient.address, amount: amount, timestamp: time0000)

            return amount
        }

        pub fun hasFinished(): Bool {
            return self.convertedAmount >= self.conversionAmount
        }

        pub fun getFinishTimestamp(): UFix64 {
            return MoxyData.getTimestampTo0000(timestamp: self.creationTimestamp) + (UFix64(self.withdrawalDays) * 86400.0)
        }

        pub fun getTotalToConvertRemaining(): UFix64 {
            return self.conversionAmount - self.convertedAmount
        }

        pub fun getOwnerAddress(): Address {
            return self.mvConverter.address
        }

        init(mvConverter: @MoxyVaultToken.MVConverter, conversionRequest: @LockedMoxyToken.ConversionRequest , timestamp: UFix64, withdrawalDays: Int) {
            self.creationTimestamp = timestamp
            self.conversionAmount = mvConverter.allowedAmount
            self.convertedAmount = 0.0
            self.mvConverter <- mvConverter
            self.lockedMOXYVault <- conversionRequest.withdraw()
            self.lastReleaseTime0000 = MoxyData.getTimestampTo0000(timestamp: timestamp)
            self.withdrawalDays = withdrawalDays

            destroy conversionRequest
        }

        destroy() {
            destroy self.mvConverter
            destroy self.lockedMOXYVault
        }
    }


    pub resource MoxyEcosystem: MoxyEcosystemInfoInterface, MVToMOXYRequestsInfoInterface, MoxyEcosystemOperations {
        access(contract) let accounts: @{Address:MoxyAccount}
        access(contract) let playAndEarnEventAccounts: @{Address:PlayAndEarnAccount}
        access(contract) let moxyControlledAccounts: {Address:Address}
        pub var isReleaseStarted: Bool

        /// Fee amount to charge on MOX transactions
        pub var feeAmountInFLOW: UFix64
        pub var moxyToFLOWValue: UFix64
        pub var moxyToUSDValue: UFix64
        pub var percentFeeToPLAY: UFix64

        // Moxy Controlled Addresses
        pub var treasuryAddress: Address?
        pub var associationAddress: Address?

        // Total earned from MV holdings
        pub var totalEarnedFromMVHoldings: UFix64
        pub var earnedFromMVHoldings: {UFix64:UFix64}
        
        // Total paid due daily activity or also called Proof of Play
        pub var totalPaidDueDailyActivity: UFix64
        pub var paidDueDailyActivity: {UFix64:UFix64}

        // Total paid due MV conversion back to MOXY
        pub var totalPaidDueMVConversion: UFix64
        pub var paidDueMVConversion: {UFix64:UFix64}


        // Maximum percentage for MV Holdings rewards for Locked MV
        pub var maximumPercentageLockedMV: UFix64

        pub var mvToMOXWithdrawalDays: Int

        // Process Queue handling
        pub var roundReleaseQueue: @MoxyProcessQueue.Queue
        pub var mvHoldingsQueue: @MoxyProcessQueue.Queue
        pub var proofOfPlayQueue: @MoxyProcessQueue.Queue
        pub var mvToMOXConversionQueue: @MoxyProcessQueue.Queue

        // Proof of Play weight for score, daily score and play donations
        pub var popScoreWeight: UFix64
        pub var popDailyScoreWeight: UFix64
        pub var popPlayDonationWeight: UFix64

        pub var proofOfPlayPercentage: UFix64

        // Launch fee to be paid for users
        // It's value is in MOXY
        pub var launchFee: UFix64

        // Masterclass price
        pub var masterclassPrices: {String:UFix64}

        // Games prices
        pub var gamesPrices: {String:UFix64}


        pub fun getMOXYFeeAmount(): UFix64 {
            // Fee amount is the double of flow fee with a minimum of 0.000001 MOX
            var feeInMOXY = self.feeAmountInFLOW * 2.0 * self.moxyToFLOWValue
            if (feeInMOXY < 0.000001) {
                feeInMOXY = 0.000001
            }
            return feeInMOXY
        }

        pub fun getMOXYToFLOWValue(): UFix64 {
            return self.moxyToFLOWValue
        }

        pub fun getMOXYToUSDValue(): UFix64 {
            return self.moxyToUSDValue
        }

        pub fun setMOXYToFLOWValue(amount: UFix64) {
            let oldValue = self.moxyToFLOWValue
            self.moxyToFLOWValue = amount
            emit MOXYToFLOWValueChanged(oldAmount: oldValue, newAmount: amount, timestamp: getCurrentBlock().timestamp)
        }

        pub fun setMOXYToUSDValue(amount: UFix64) {
            let oldValue = self.moxyToUSDValue
            self.moxyToUSDValue = amount
            emit MOXYToUSDValueChanged(oldAmount: oldValue, newAmount: amount, timestamp: getCurrentBlock().timestamp)
        }

        

        pub fun setMembershipFeeUSD(amount: UFix64) {
            let oldAmount = MoxyClub.membershipFee
            let oldMoxy = oldAmount / self.moxyToUSDValue
            MoxyClub.membershipFee = amount
            let newMoxy = amount / self.moxyToUSDValue
            emit MembershipFeeChanged(newAmount: amount, newAmountMOXY: newMoxy, oldAmount: oldAmount, oldAmountMOXY: oldMoxy, moxyToUSDValue: self.moxyToUSDValue)
        }

        pub fun setMembershipFeeMOXY(amount: UFix64) {
            let oldAmount = MoxyClub.membershipFee
            let oldMoxy = oldAmount / self.moxyToUSDValue
            let newMoxy = amount
            MoxyClub.membershipFee = newMoxy * self.moxyToUSDValue
            emit MembershipFeeChanged(newAmount: amount, newAmountMOXY: newMoxy, oldAmount: oldAmount, oldAmountMOXY: oldMoxy, moxyToUSDValue: self.moxyToUSDValue)
        }


        pub fun setTreasuryAddress(address: Address) {
            self.treasuryAddress = address
            emit TreasuryAddressChanged(newAddress: address)
        }

        pub fun setAssociationAddress(address: Address) {
            self.associationAddress = address
            emit AssociationAddressChanged(newAddress: address)
        }

        pub fun setPlayAndEarnRefTo(address: Address, vaultRef: Capability<&FungibleToken.Vault>) {
            self.accounts[address]?.setPlayAndEarnRef(vaultRef: vaultRef)
            emit PlayAndEarnReferenceAssigned(address: address)
        }

        pub fun setMVToMOXYConversionsRefTo(address: Address, conversionsRef: Capability<&{UFix64:MoxyClub.MVToMOXYConverter}>) {
            self.accounts[address]?.setMVToMOXYConversionsRef(conversionsRef: conversionsRef)
            emit PlayAndEarnReferenceAssigned(address: address)
        }


        pub fun setPopWeights(scoreWeight: UFix64, dailyScoreWeight: UFix64, playDonationWeight: UFix64) {
            pre {
                scoreWeight + dailyScoreWeight + playDonationWeight == 100.0 : "The sum of three weights should be 100.0"
            }

            self.popScoreWeight = scoreWeight
            self.popDailyScoreWeight = dailyScoreWeight
            self.popPlayDonationWeight = playDonationWeight
            emit PopWeightsChanged(newScoreWeight: scoreWeight, newDailyScoreWeight: scoreWeight, newPlayDonationWeight: scoreWeight)
        }

        pub fun setProofOfPlayPercentage(value: UFix64) {
            pre {
                value >= 0.0 && value <= 100.0 : "The Proof of Play percentage should be a value between 0.0 and 100.0"
            }
            self.proofOfPlayPercentage = value
        }

        pub fun setLaunchFee(amount: UFix64) {
            self.launchFee = amount
            emit LaunchFeeChanged(newAmount: amount)
        }

        pub fun getLaunchFee(): UFix64 {
            return self.launchFee
        }

        pub fun payLaunchFee(fromVault: @FungibleToken.Vault, address: Address) {
            pre {
                fromVault.balance == self.launchFee : "Amount to paid does not match with launch fee amount."
            }
            let amount = fromVault.balance
            self.transferMOXY(fromVault: <-fromVault, to: self.treasuryAddress!) 
            emit LaunchFeePaid(address: address, amount: amount)

        }

        pub fun payMasterclassPrice(classId: String, fromVault: @FungibleToken.Vault, address: Address) {
            pre {
                fromVault.balance == self.masterclassPrices[classId] : "Amount to paid does not match with masterclass fee amount."
            }
            let amount = fromVault.balance
            self.transferMOXY(fromVault: <-fromVault, to: self.treasuryAddress!) 
            emit MasterclassPricePaid(address: address, amount: amount)
        }

        pub fun addMasterclassPrice(classId: String, feeAmount: UFix64) {
            if (self.masterclassPrices[classId] != nil) {
                panic("Masterclass with classId provided already exists.")
            }
            self.masterclassPrices[classId] = feeAmount
            emit MasterclassPriceAdded(classId: classId, feeAmount: feeAmount)
        }

        pub fun updateMasterclassPrice(classId: String, feeAmount: UFix64) {
            if (self.masterclassPrices[classId] == nil) {
                panic("Masterclass with classId provided does not exists.")
            }
            let oldFeeAmount = self.masterclassPrices[classId]!
            self.masterclassPrices[classId] = feeAmount
            emit MasterclassPriceUpdated(classId: classId, oldFeeAmount: oldFeeAmount, newFeeAmount: feeAmount)
        }

        pub fun removeMasterclassPrice(classId: String) {
            self.masterclassPrices.remove(key: classId)
            emit MasterclassPriceRemoved(classId: classId)
        }

        pub fun getMasterclassPrice(classId: String): UFix64? {
            return self.masterclassPrices[classId]
        }
        
        pub fun getMasterclassPrices(): {String: UFix64} {
            return self.masterclassPrices
        }

        pub fun payGamePrice(gameId: String, fromVault: @FungibleToken.Vault, address: Address) {
            pre {
                fromVault.balance == self.gamesPrices[gameId] : "Amount to paid does not match with game fee amount."
            }
            let amount = fromVault.balance
            self.transferMOXY(fromVault: <-fromVault, to: self.treasuryAddress!) 
            emit GamePricePaid(gameId: gameId, address: address, amount: amount)
        }

        access(contract) fun burnPLAYToken(vault: @FungibleToken.Vault) {
            let admin = MoxyClub.account.borrow<&PlayToken.Administrator>(from: PlayToken.playTokenAdminStorage)
                ?? panic("Could not borrow a reference to the admin resource")

            let burner <- admin.createNewBurner()
            burner.burnTokens(from: <- vault)
            destroy burner
        }

        pub fun refundPaymentDoneToTreasury(address: Address, moxyVault: @FungibleToken.Vault, playVault: @FungibleToken.Vault) {
            // Refunds the amount to the given address
            // from treasury address.
            
            let playAmount = playVault.balance
            let moxyToMint = playAmount * 2.0

            // Burn PLAY
            self.burnPLAYToken(vault: <-playVault)

            // Mint MOXY token 2::1 with PLAY
            let mintedVault <- self.mintMOXYTokens(amount: moxyToMint)
            let receiverVault <- mintedVault.withdraw(amount: mintedVault.balance)

            // Get a reference to the recipient's Receiver
            let recipient = getAccount(address)

            let receiverRef = recipient.getCapability(MoxyToken.moxyTokenReceiverPath)
                .borrow<&{FungibleToken.Receiver}>()
                ?? panic("Could not borrow receiver reference to the recipient's Vault")

            // Deposit the withdrawn tokens in the recipient's receiver
            receiverVault.deposit(from: <-moxyVault)

            let totalRefunded = receiverVault.balance

            receiverRef.deposit(from: <- receiverVault)

            destroy mintedVault

            emit RefundedPayment(totalRefunded: totalRefunded, toAddress: address, playBurned: playAmount) 


        }

        pub fun addGamePrice(gameId: String, feeAmount: UFix64) {
            if (self.gamesPrices[gameId] != nil) {
                panic("Game with gameId provided already exists.")
            }
            self.gamesPrices[gameId] = feeAmount
            emit GamePriceAdded(gameId: gameId, feeAmount: feeAmount)
        }

        pub fun updateGamePrice(gameId: String, feeAmount: UFix64) {
            if (self.gamesPrices[gameId] == nil) {
                panic("Game with gameId provided does not exists.")
            }
            let oldFeeAmount = self.gamesPrices[gameId]!
            self.gamesPrices[gameId] = feeAmount
            emit GamePriceUpdated(gameId: gameId, oldFeeAmount: oldFeeAmount, newFeeAmount: feeAmount)
        }

        pub fun removeGamePrice(gameId: String) {
            self.gamesPrices.remove(key: gameId)
            emit GamePriceRemoved(gameId: gameId)
        }

        pub fun getGamePrice(gameId: String): UFix64? {
            return self.gamesPrices[gameId]
        }
        
        pub fun getGamesPrices(): {String: UFix64} {
            return self.gamesPrices
        }

        pub fun getProofOfPlayPercentage(): UFix64 {
            return self.proofOfPlayPercentage
        }

        pub fun getTreasuryAddress(): Address? {
            return self.treasuryAddress
        }

        pub fun getAssociationAddress(): Address? {
            return self.associationAddress
        }
        
        pub fun hasMembershipFeePendingFor(address: Address): Bool {
            if (self.accounts[address] == nil) {
                panic("Address not found in MoxyClub")
            }
            return self.accounts[address]?.hasMembershipFeePending()!
        }

        //Returns the Membership Fee remaining for an address
        pub fun getMembershipFeeRemainingFor(address: Address): UFix64 {
            if (self.playAndEarnEventAccounts[address] != nil || self.moxyControlledAccounts[address] != nil) {
                return 0.0
            }
            if (self.accounts[address] == nil) {
                panic("Address not found in MoxyClub")
            }
            return self.accounts[address]?.getMembershipFeeRemaining()!
        }

        pub fun getMembershipFeeMOXYRemainingFor(address: Address): UFix64 {
            return self.getMembershipFeeRemainingFor(address: address) / self.moxyToUSDValue
        }

        pub fun getTotalEarnedFromMVHoldings(): UFix64 {
            return self.totalEarnedFromMVHoldings
        }

        pub fun getEarnedFromMVHoldingsForTime(timestamp: UFix64): UFix64 {
            let time0000 = MoxyData.getTimestampTo0000(timestamp: timestamp)
            if (self.earnedFromMVHoldings[timestamp] == nil) {
                return 0.0
            }
            return self.earnedFromMVHoldings[time0000]!
        }

        pub fun getEarnedFromMVHoldingsForTimeRange(from: UFix64, to: UFix64): {UFix64: UFix64} {
            let from0000 = MoxyData.getTimestampTo0000(timestamp: from)
            let to0000 = MoxyData.getTimestampTo0000(timestamp: to)

            let dict: {UFix64:UFix64} = {}

            let day = 86400.0
            var curr0000 = from0000
            var i = 0
            while (curr0000 <= to0000 && i < 30) {
                var val = self.getEarnedFromMVHoldingsForTime(timestamp: curr0000)
                dict[curr0000] = val
                curr0000 = curr0000 + day
                i = i + 1
            }

            return dict
        }

        pub fun getTotalPaidDueDailyActivity(): UFix64 {
            return self.totalPaidDueDailyActivity
        }

        pub fun getPaidDueDailyActivityForTime(timestamp: UFix64): UFix64 {
            let time0000 = MoxyData.getTimestampTo0000(timestamp: timestamp)
            if (self.paidDueDailyActivity[time0000] == nil) {
                return 0.0
            }
            return self.paidDueDailyActivity[time0000]!
        }

        pub fun getPaidDueDailyActivityForTimeRange(from: UFix64, to: UFix64): {UFix64: UFix64} {
            let from0000 = MoxyData.getTimestampTo0000(timestamp: from)
            let to0000 = MoxyData.getTimestampTo0000(timestamp: to)

            let dict: {UFix64:UFix64} = {}

            let day = 86400.0
            var curr0000 = from0000
            var i = 0
            while (curr0000 <= to0000 && i < 30) {
                var val = self.getPaidDueDailyActivityForTime(timestamp: curr0000)
                dict[curr0000] = val
                curr0000 = curr0000 + day
                i = i + 1
            }

            return dict
        }

        pub fun getTotalPaidDueMVConversion(): UFix64 {
            return self.totalPaidDueMVConversion
        }

        pub fun getPaidDueMVConversionForTime(timestamp: UFix64): UFix64 {
            let time0000 = MoxyData.getTimestampTo0000(timestamp:timestamp)
            if (self.paidDueMVConversion[time0000] == nil) {
                return 0.0
            }
            return self.paidDueMVConversion[time0000]!
        }

        pub fun getPaidDueMVConversionForTimeRange(from: UFix64, to: UFix64): {UFix64: UFix64} {
            let from0000 = MoxyData.getTimestampTo0000(timestamp: from)
            let to0000 = MoxyData.getTimestampTo0000(timestamp: to)

            let dict: {UFix64:UFix64} = {}

            let day = 86400.0
            var curr0000 = from0000
            var i = 0
            while (curr0000 <= to0000 && i < 30) {
                var val = self.getPaidDueMVConversionForTime(timestamp: curr0000)
                dict[curr0000] = val
                curr0000 = curr0000 + day
                i = i + 1
            }

            return dict
        }

        pub fun getEarnedFromMVHoldingsFor(address: Address): {UFix64: UFix64} {
            if (self.accounts[address] == nil) {
                panic("Address not found in MoxyClub")
            }
            return self.accounts[address]?.getEarnedFromMVHoldings()!
        }

        pub fun getEarnedFromMVHoldingsForAddressTime(address: Address, timestamp: UFix64): UFix64 {
            if (self.accounts[address] == nil) {
                panic("Address not found in MoxyClub")
            }
            return self.accounts[address]?.getEarnedFromMVHoldingsFor(timestamp: timestamp)!
        }

        pub fun getEarnedFromMVHoldingsForAddressTimeRange(address: Address, from: UFix64, to: UFix64): {UFix64:UFix64} {
            if (self.accounts[address] == nil) {
                panic("Address not found in MoxyClub")
            }
            return self.accounts[address]?.getEarnedFromMVHoldingsForRange(from: from, to: to)!
        }

        pub fun getPaidDueDailyActivityFor(address: Address): {UFix64: UFix64} {
            if (self.accounts[address] == nil) {
                panic("Address not found in MoxyClub")
            }
            return self.accounts[address]?.getPaidDueActivity()!
        }

        pub fun getPaidDueDailyActivityForAddressTime(address: Address, timestamp: UFix64): UFix64 {
            if (self.accounts[address] == nil) {
                panic("Address not found in MoxyClub")
            }
            return self.accounts[address]?.getPaidDueDailyActivityFor(timestamp: timestamp)!
        }

        pub fun getPaidDueDailyActivityForAddressTimeRange(address: Address, from: UFix64, to: UFix64): {UFix64:UFix64} {
            if (self.accounts[address] == nil) {
                panic("Address not found in MoxyClub")
            }
            return self.accounts[address]?.getPaidDueDailyActivityForRange(from: from, to: to)!
        }


        pub fun getTotalEarnedFromMVHoldingsFor(address: Address): UFix64 {
            if (self.accounts[address] == nil) {
                panic("Address not found in MoxyClub")
            }
            return self.accounts[address]?.getTotalEarnedFromMVHoldings()!
        }

        pub fun getTotalPaidDueDailyActivityFor(address: Address): UFix64 {
            if (self.accounts[address] == nil) {
                panic("Address not found in MoxyClub")
            }
            return self.accounts[address]?.getTotalPaidDueDailyActivity()!
        }

        pub fun getTotalPaidDueMVConversionFor(address: Address): UFix64 {
            if (self.accounts[address] == nil) {
                panic("Address not found in MoxyClub")
            }
            return self.accounts[address]?.getTotalPaidDueMVConversion()!
        }

        //Returns the Membership Fee total for an address
        pub fun getMembershipFeeFor(address: Address): UFix64 {
            if (self.accounts[address] == nil) {
                panic("Address not found in MoxyClub")
            }
            return self.accounts[address]?.membershipFee!
        }

        pub fun getMembershipFeeMOXYFor(address: Address): UFix64 {
            return self.getMembershipFeeFor(address: address) / self.moxyToUSDValue
        }

        pub fun getMembershipFeeMOXY(): UFix64 {
            return MoxyClub.membershipFee / self.moxyToUSDValue
        }

        pub fun isMoxyAccount(address: Address): Bool {
            return (self.accounts[address] != nil)
        }

        pub fun isPlayAndEarnEventAccount(address: Address): Bool {
            return self.playAndEarnEventAccounts[address] != nil
        }

        pub fun isMoxyControlledAccount(address: Address): Bool {
            return self.moxyControlledAccounts[address] != nil
        }

        pub fun isGoodStandingOnOpenEvents(address: Address): Bool {
            return self.accounts[address]?.isGoodStandingOnOpenEvents()!
        }

        pub fun addMoxyAccount(address: Address) {
            pre {
                self.accounts[address] == nil : "Account already added to Moxy Club"
                self.checkVaultsTypes(address: address) : "Account is not correctly setup"
            }

            self.accounts[address] <-! create MoxyAccount()
            self.mvHoldingsQueue.addAccount(address: address)
            self.proofOfPlayQueue.addAccount(address: address)
            
            emit MoxyClub.MoxyAccountAdded(address: address)
        }

        pub fun checkVaultsTypes(address: Address): Bool {
            let acct = getAccount(address)

            let moxy = acct.getCapability(MoxyToken.moxyTokenReceiverPath).borrow<&{FungibleToken.Receiver}>()
            let mv = acct.getCapability(MoxyVaultToken.moxyVaultTokenReceiverTimestampPath).borrow<&{MoxyVaultToken.ReceiverInterface}>()
            let play = acct.getCapability(PlayToken.playTokenReceiverPath).borrow<&{FungibleToken.Receiver}>()
            let score = acct.getCapability(ScoreToken.scoreTokenReceiverTimestampPath).borrow<&{ScoreToken.ReceiverInterface}>()

            return (
                moxy != nil && mv != nil &&
                play != nil && score != nil &&
                moxy!.isInstance(Type<@MoxyToken.Vault>()) &&
                mv!.isInstance(Type<@MoxyVaultToken.Vault>()) &&
                play!.isInstance(Type<@PlayToken.Vault>()) &&
                score!.isInstance(Type<@ScoreToken.Vault>()) 
            )
        }

        pub fun removeMoxyAccount(address: Address) {
            if (self.accounts[address] == nil) {
                panic("Can't remove. Account not found in Moxy Club")
            }

            let moxyAccount <- self.accounts.remove(key: address)!
            destroy moxyAccount
            self.mvHoldingsQueue.removeAccount(address: address)
            self.proofOfPlayQueue.removeAccount(address: address)
        }

        pub fun addPlayAndEarnEventAccount(address: Address){
            // Add a Play and Earn Account to the Moxy Ecosystem
            if (self.playAndEarnEventAccounts[address] != nil) {
                panic("Can't add Play and Earn Event account, acount already added.")
            }
            self.playAndEarnEventAccounts[address] <-! create PlayAndEarnAccount()
            emit MoxyClub.PlayAndEarnEventAccountAdded(address: address)
        }

        pub fun addMoxyControlledAccount(address: Address){
            // Add a Moxy Controlled Account to the Moxy Ecosystem
            if (self.moxyControlledAccounts[address] != nil) {
                panic("Can't add Moxy Controlled account, acount already added.")
            }
            self.moxyControlledAccounts[address] = address
            emit MoxyClub.MoxyControlledAccountAdded(address: address)
        }

        pub fun addAccountToRound(roundId: String, address: Address, amount: UFix64) {
            let roundManager = self.getRoundsCapability().borrow()!
            roundManager.setAddress(roundId: roundId, address: address, amount: amount)
            self.roundReleaseQueue.addAccount(address: address)

            if (self.isReleaseStarted) {
                // Mint $MOXY for the round
                let initialReleaseVault <- self.mintMOXYTokens(amount: amount)
                roundManager.allocateAfterTGE(roundId: roundId, vault: <-initialReleaseVault, address: address)
            }
        }

        pub fun getPlayBalanceFor(address: Address, timestamp: UFix64): UFix64? {
            let acct = getAccount(address)
            let vaultRef = acct.getCapability(PlayToken.playTokenDailyBalancePath)
                    .borrow<&PlayToken.Vault{PlayToken.DailyBalancesInterface}>()
                    ?? panic("Could not borrow Balance reference to the Vault")
            return vaultRef.getDailyBalanceFor(timestamp: timestamp)
        }
 
        pub fun getScoreBalanceFor(address: Address, timestamp: UFix64): UFix64? {
            let acct = getAccount(address)
            let vaultRef = acct.getCapability(ScoreToken.scoreTokenDailyBalancePath)
                .borrow<&ScoreToken.Vault{ScoreToken.DailyBalancesInterface}>()
                ?? panic("Could not borrow Balance reference to the Vault")
            return vaultRef.getDailyBalanceFor(timestamp: timestamp)
        }
        
        pub fun getDailyBalanceChangeFor(address: Address, timestamp: UFix64): Fix64 {
            let acct = getAccount(address)
            let vaultRef = acct.getCapability(ScoreToken.scoreTokenDailyBalancePath)
                .borrow<&ScoreToken.Vault{ScoreToken.DailyBalancesInterface}>()
                ?? panic("Could not borrow Balance reference to the Vault")
            
            return vaultRef.getDailyBalanceChange(timestamp: timestamp)
        }

        pub fun getScore24TotalSupplyChange(timestamp: UFix64): Fix64 {
            return ScoreToken.getDailyChangeTo(timestamp: timestamp)
        }


        // Collects the initial fixed Memebership Fee (5 MOXY total)
        access(contract) fun collectMembershipFee(address: Address, vault: @FungibleToken.Vault): @FungibleToken.Vault {
            
            let remainingFee = self.getMembershipFeeMOXYRemainingFor(address: address)

            var feeToDeduct = remainingFee
            if (remainingFee > vault.balance) {
                feeToDeduct = vault.balance
            }

            let association = getAccount(self.associationAddress!)
            let associationVaultRef = association.getCapability(MoxyToken.moxyTokenReceiverPath)
                    .borrow<&{FungibleToken.Receiver}>()
                    ?? panic("Could not borrow Balance reference to the Vault")

            let vaultFee <- vault.withdraw(amount: feeToDeduct)
            associationVaultRef.deposit(from: <-vaultFee)
            
            var feeUSD = feeToDeduct * self.moxyToUSDValue
            if (feeToDeduct > 0.0 && feeUSD == 0.0) {
                feeUSD = 0.00000001
            }
            self.accounts[address]?.updateMembershipFeePaid(amount: feeUSD)

            emit MembershipFeeDeducted(address: address, feeDeducted: feeUSD, feeDeductedMOXY: feeToDeduct, remaining: remainingFee - feeToDeduct, moxyToUSDValue: self.moxyToUSDValue)

            return <-vault

        }

        pub fun calculateRewardsDueMVHoldingsTo(address: Address, timestamp: UFix64): UFix64 {
            let time0000 = MoxyData.getTimestampTo0000(timestamp: timestamp)

            let acct = getAccount(address)
            let vaultRef = acct.getCapability(MoxyVaultToken.moxyVaultTokenDailyBalancePath)
                .borrow<&MoxyVaultToken.Vault{MoxyVaultToken.DailyBalancesInterface}>()
                ?? panic("Could not borrow Balance reference to the Vault")

            let balanceRef = acct.getCapability(MoxyVaultToken.moxyVaultTokenDailyBalancePath)
                    .borrow<&MoxyVaultToken.Vault{MoxyVaultToken.DailyBalancesInterface}>()
                     ?? panic("Could not borrow Balance reference to the Vault")

            let lockedVaultRef = acct.getCapability(MoxyVaultToken.moxyVaultTokenLockedBalancePath)
                .borrow<&LockedMoxyVaultToken.LockedVault{LockedMoxyVaultToken.Balance}>()
                ?? panic("Could not borrow Balance reference to the Vault")

            let totalMV = balanceRef.getDailyBalanceFor(timestamp: timestamp)!
            let totalLockedMV = lockedVaultRef.getDailyBalanceFor(timestamp: timestamp)!
            let total = totalMV + totalLockedMV

            if (total == 0.0) {
                return 0.0
            }

            let balancesChanges = vaultRef.getDailyBalancesChangesUpTo(timestamp: timestamp)
            let lockedBalancesChanges = lockedVaultRef.getDailyBalancesChangesUpTo(timestamp: timestamp)

            var amnt = 0.0
            for value in lockedBalancesChanges.values {
                amnt = amnt + value
            }

            for time in balancesChanges.keys {
                let am = balancesChanges[time]!
                let diff = Fix64(am + amnt) - Fix64(total)
                if (diff > 0.0 ) {
                    if (balancesChanges[time]! >= UFix64(diff)) {
                        balancesChanges[time] = balancesChanges[time]! - UFix64(diff)
                    } else {
                        panic("Difference should not be negative. Negative diff =".concat(diff.toString()).concat(" balancesChanges[time]! ").concat(balancesChanges[time]!.toString()) )
                    }
                }
                amnt = amnt + balancesChanges[time]!
            }

            if (amnt != total) {
                panic("Error calculating MV Holdings amount changes does not match with total MV holdings")
            }

            var rewardsMox = self.getMOXRewardsFromDictionaryFor(time0000: time0000, dictionary: balancesChanges, areLockedMV: false)
            var rewardsMoxFromLockedMV = self.getMOXRewardsFromDictionaryFor(time0000: time0000, dictionary: lockedBalancesChanges, areLockedMV: true)

            var totalRewards = rewardsMox + rewardsMoxFromLockedMV

            return totalRewards
        }

        access(contract) fun getMOXRewardsFromDictionaryFor(time0000: UFix64, dictionary: {UFix64:UFix64}, areLockedMV: Bool): UFix64 {
            // Iterate over all MV allocated over past days
            var rewardsMox = 0.0
            for time in dictionary.keys {
                if (time0000 < time) {
                    // Continue on future MV holdings rewards
                    // This could be caused due to not running daily process on time
                    continue
                }
                // Daily Linear Appreciation over Time
                // days represent the longevity of the tokens
                let days = (time0000 - time) / 86400.0
                let amount = dictionary[time]!

                if (amount == 0.0) {
                    // Continue no amount to compute
                    continue
                }

                var percentage = 0.0
                if (days >= 0.0  && days <= 90.0 ) {
                    percentage = 2.0
                }
                if (days > 90.0  && days <= 180.0 ) {
                    percentage = 4.0
                }
                if (days > 180.0  && days <= 365.0 ) {
                    percentage = 6.0
                }
                if (days > 365.0 ) {
                    percentage = 10.0
                }

                // For locked MV there is a maximum percentage
                if (areLockedMV && percentage > self.maximumPercentageLockedMV) {
                    percentage = self.maximumPercentageLockedMV
                }

                percentage = UFix64(percentage / 100.0 / 365.0)
                rewardsMox = rewardsMox + (amount * percentage)
            }

            return rewardsMox
        }

        pub fun rewardDueMVHoldings(quantity: Int) {
            //It will run for a quantity of addresses depending on the current queue progress
            let run <- self.mvHoldingsQueue.lockRunWith(quantity: quantity)
            if (run == nil) {
                emit NoAddressesToProcessForMVHoldingsProcess(timestamp: getCurrentBlock().timestamp)
                destroy run
                return
            }
            let addresses = run?.getCurrentAddresses()!
            if (self.mvHoldingsQueue.isAtBeginning()) {
                emit StartingRewardsPaymentsDueMVHoldings(timestamp: getCurrentBlock().timestamp, accountsToProcess: self.mvHoldingsQueue.getAccountsQuantity())
            }
            self.rewardDueMVHoldingsToAddresses(addresses: addresses)
            self.mvHoldingsQueue.completeNextAddresses(run: <- run!)
            if (self.mvHoldingsQueue.hasFinished()) {
                emit FinishedRewardsPaymentsDueMVHoldings(timestamp: getCurrentBlock().timestamp, accountsProcessed: self.mvHoldingsQueue.getAccountsQuantity())
            }

            emit BatchRewardsPaymentsDueMVHoldings(timestamp: getCurrentBlock().timestamp, requestedToProcess: quantity, accountsProcessed: addresses!.length, totalAccounts: self.mvHoldingsQueue.getAccountsQuantity())
        }

        pub fun rewardDueMVHoldingsToAddresses(addresses: [Address]) {
            for address in addresses {
                self.rewardDueMVHoldingsTo(address: address)
            }
        }

        pub fun rewardDueMVHoldingsTo(address: Address) {
            let timestamp = getCurrentBlock().timestamp
            let time0000 = MoxyData.getTimestampTo0000(timestamp: timestamp)
            if (self.accounts[address] == nil) {
                log("Address not found in Moxy Club ecosystem")
                emit AddressNotFoundWhenPayingMVHoldingsRewards(address: address, timestamp: time0000)
                return
            }

            // Check for already paid account
            var lastMVHoldingsUpdatedTimestamp = self.accounts[address]?.lastMVHoldingsUpdatedTimestamp!
            if (lastMVHoldingsUpdatedTimestamp == 0.0) {
                //Set fist time when converting MOX to MV when is not already set
                let acct = getAccount(address)
                let mvInfoRef = acct.getCapability(MoxyVaultToken.moxyVaultTokenDailyBalancePath)
                    .borrow<&MoxyVaultToken.Vault{MoxyVaultToken.DailyBalancesInterface}>()
                if (mvInfoRef == nil) {
                    log("Account does not have MoxyVault Vault")
                    emit AccountDoesNotHaveMoxyVaultVault(address: address, message: "Could not borrow reference to MV Vault when processing MV Holdings rewards.")
                    return
                }
                let firstTime = mvInfoRef!.getFirstTimestampAdded()
                if (firstTime == nil) {
                    log("Address does not have MV holdings ".concat(address.toString()))
                    return
                }
                self.accounts[address]?.setLastMVHoldingsUpdatedTimestamp(timestamp: firstTime!)
                lastMVHoldingsUpdatedTimestamp = firstTime!
            }
            
            if (lastMVHoldingsUpdatedTimestamp >= time0000) {
                log("Requested date is smaller than the last MV Holdings updated date")
                emit RequestedDateSmallerToLastUpdateWhenPayingMVHoldingsRewards(address: address, timestamp: time0000, lastMVHoldingsUpdatedTimestamp: lastMVHoldingsUpdatedTimestamp)
                return
            }

            // Get all timestamps from last updated MV Rewards to time0000
            let last0000 = MoxyData.getTimestampTo0000(timestamp: lastMVHoldingsUpdatedTimestamp)
            var days = (time0000 - last0000) / 86400.0

            // Set maximum days to process to five days
            if (days > 5.0) {
                days = 5.0
            }

            var i = 0.0
            var times: [UFix64] = []
            // Iterate maximum five days
            while i < days {
                i = i + 1.0
                times.append(last0000 + (i * 86400.0))
            }

            for time in times {
                if (self.accounts[address]?.earnedFromMVHoldings![time] != nil) {
                    log("Rewards already paid to address in requested day")
                    emit PaidAlreadyMadeWhenPayingMVHoldingsRewards(address: address, timestamp: time0000)
                    continue
                }

                // Moxy Vault rewards are paid in MOX, calculated by each user's MV holding  
                let rewardMOX = self.calculateRewardsDueMVHoldingsTo(address: address, timestamp: time) 
                
                if (rewardMOX > 0.0) {
                    if (self.accounts[address]?.isGoodStandingOnOpenEventsFor(timestamp: time)!) {
                        // Mint corresponding MOX tokens to user's account
                        self.mintMOXToAddress(address: address, amount: rewardMOX)

                        // Update the minted timestamp (MoxyAccount)
                        self.accounts[address]?.setMOXEarnedFromMVHoldingsFor(timestamp: time, amount: rewardMOX)

                        self.totalEarnedFromMVHoldings = self.totalEarnedFromMVHoldings + rewardMOX
                        if (self.earnedFromMVHoldings[time] == nil) {
                            self.earnedFromMVHoldings[time] = 0.0
                        }
                        self.earnedFromMVHoldings[time] = self.earnedFromMVHoldings[time]! + rewardMOX
                        emit MOXRewaredDueMVHoldingsTo(address: address, timestamp: time, amount: rewardMOX)
                    } else {
                        // User has not good standing on open events, so earned rewards will go to improve proof of play
                        self.accounts[address]?.setMOXEarnedFromMVHoldingsFor(timestamp: time, amount: 0.0)

                        let moxToPLAYVault <- self.mintMOXYTokens(amount: rewardMOX)
                        self.convertMOXYtoPLAY(vault: <-moxToPLAYVault, address: self.treasuryAddress!, relation: 1.0)
                        emit MOXRewardedToPoPUserNotGoodStanding(address: address, timestamp: time, amountMOXY: rewardMOX, amountPLAY: rewardMOX / 1.0)
                    }
                }
            }
        }

        pub fun rewardDueDailyActivity(quantity: Int) {
            //It will run for a quantity of addresses depending on the current queue progress
            let run <- self.proofOfPlayQueue.lockRunWith(quantity: quantity)
            if (run == nil) {
                emit NoAddressesToProcessForPoPProcess(timestamp: getCurrentBlock().timestamp)
                destroy run
                return
            }
            let addresses = run?.getCurrentAddresses()!
            
            if (self.proofOfPlayQueue.isAtBeginning()) {
                emit StartingRewardsPaymentsDuePoP(timestamp: getCurrentBlock().timestamp, accountsToProcess: self.proofOfPlayQueue.getAccountsQuantity())
            }
            self.rewardDueDailyActivityToAddresses(addresses: addresses)
            self.proofOfPlayQueue.completeNextAddresses(run: <-run!)
            if (self.proofOfPlayQueue.hasFinished()) {
                emit FinishedRewardsPaymentsDuePoP(timestamp: getCurrentBlock().timestamp, accountsProcessed: self.proofOfPlayQueue.getAccountsQuantity())
            }
            emit BatchRewardsPaymentsDuePoP(timestamp: getCurrentBlock().timestamp, requestedToProcess: quantity, accountsProcessed: addresses.length, totalAccounts: self.proofOfPlayQueue.getAccountsQuantity())
        }

        pub fun rewardDueDailyActivityToAddresses(addresses: [Address]) {
            for address in addresses {
                self.rewardDueDailyActivityFor(address: address)
            }
        }

        pub fun rewardDueDailyActivityFor(address: Address) {
            let timestamp = getCurrentBlock().timestamp

            // SCORE + SCORE24 + PLAY
            let timeTo0000 = MoxyData.getTimestampTo0000(timestamp: timestamp)

            if (self.accounts[address] == nil) {
                log("Address not found in Moxy Club ecosystem")
                emit AddressNotFoundWhenPayingPoPRewards(address: address, timestamp: timeTo0000)
                return
            }

            // Check for already paid account
            var dailyActivityUpdatedTimestamp = self.accounts[address]?.dailyActivityUpdatedTimestamp!
            if (dailyActivityUpdatedTimestamp == 0.0) {
                //Set fist time when received first  SCORE for PoP
                let acct = getAccount(address)
                let scoreInfoRef = acct.getCapability(ScoreToken.scoreTokenDailyBalancePath)
                    .borrow<&ScoreToken.Vault{ScoreToken.DailyBalancesInterface}>()
                if (scoreInfoRef == nil) {
                    log("Account does not have Score Vault")
                    emit AccountDoesNotHaveScoreVault(address: address, message: "Could not borrow reference to SCORE Vault when processing PoP rewards.")
                    return
                }
                let firstTime = scoreInfoRef!.getFirstTimestampAdded()
                if (firstTime == nil) {
                    log("Address ".concat(address.toString()).concat(" does not have SCORE records"))
                    return
                }
                self.accounts[address]?.setDailyActivityUpdatedTimestamp(timestamp: firstTime! - 86400.0)  //Subtract one day
                dailyActivityUpdatedTimestamp = firstTime!
            }
            
            if (dailyActivityUpdatedTimestamp >= timeTo0000) {
                log("Requested date is smaller than the last Daily Activity updated date")
                emit RequestedDateSmallerToLastUpdateWhenPayingPoPRewards(address: address, timestamp: timeTo0000, lastDailyActivityUpdatedTimestamp: dailyActivityUpdatedTimestamp)
                return
            }

            let ecosystemScore24ChangeDict:{UFix64:UFix64} = self.getTotalSupply24DueForProcessTo(address: address, toTimestamp: timeTo0000)

            for time0000 in ecosystemScore24ChangeDict.keys {
                // Pull PLAY from user
                var play = self.getPlayBalanceFor(address: address, timestamp: time0000)
                // Pull SCORE from user
                var score = self.getScoreBalanceFor(address: address, timestamp: time0000)
                // Pull SCORE change from user, change should always be positive
                var change = UFix64(self.getDailyBalanceChangeFor(address: address, timestamp: time0000))
                // Pull totalSupply from PLAY, SCORE and SCORE24 (change in score)
                let ecosystemPlayTotalSupply = PlayToken.getTotalSupplyFor(timestamp: time0000)
                let ecosystemScoreTotalSupply = ScoreToken.getTotalSupplyFor(timestamp: time0000)
                let ecosystemScore24Change = self.getScore24TotalSupplyChange(timestamp: time0000)

                if (play == nil) { play = 0.0}
                if (score == nil) { score = 0.0}
                if (change == nil) { change = 0.0}

                let popDaily = ecosystemPlayTotalSupply * (self.proofOfPlayPercentage/100.0) / 365.0

                var highScore = 0.0
                if (ecosystemScoreTotalSupply > 0.0) {
                    highScore = popDaily * (self.popScoreWeight / 100.0) * (score! / ecosystemScoreTotalSupply)
                }

                var score24Change = 0.0
                if (ecosystemScore24Change != 0.0) {
                    // If SCORE changed
                    score24Change = popDaily * (self.popDailyScoreWeight / 100.0) * (change / UFix64(ecosystemScore24Change))
                }

                var donationLevelProgression = 0.0
                if (ecosystemPlayTotalSupply > 0.0) {
                    donationLevelProgression = popDaily * (self.popPlayDonationWeight / 100.0) * (play! / ecosystemPlayTotalSupply)
                }

                let totalMOX = highScore + score24Change + donationLevelProgression

                if (totalMOX > 0.0) {
                    // Mint corresponding MOX tokens to user's account
                    self.mintMOXToAddress(address: address, amount: totalMOX)
                    emit MOXRewaredDueDailyActivityTo(address: address, timestamp: time0000, amount: totalMOX)
                    self.totalPaidDueDailyActivity = self.totalPaidDueDailyActivity + totalMOX
                    if (self.paidDueDailyActivity[time0000] == nil) {
                        self.paidDueDailyActivity[time0000] = 0.0
                    }
                    self.paidDueDailyActivity[time0000] = self.paidDueDailyActivity[time0000]! + totalMOX
                    self.accounts[address]?.updateTotalPaidDueDailyActivity(amount: totalMOX)
                }
                // Update the minted timestamp (MoxyAccount)
                if (self.accounts[address]?.dailyActivityUpdatedTimestamp! < time0000) {
                    self.accounts[address]?.setDailyActivityUpdatedTimestamp(timestamp: time0000)
                }
            }
        }

        access(contract) fun mintMOXYTokens(amount: UFix64): @FungibleToken.Vault {
            let tokenAdmin = MoxyClub.account.borrow<&MoxyToken.Administrator>(from: MoxyToken.moxyTokenAdminStorage)
                ?? panic("Signer is not the token admin")
            
            let minter <- tokenAdmin.createNewMinter(allowedAmount: amount)
            let vault <- minter.mintTokens(amount: amount)

            destroy minter

            return <-vault
        }

        access(contract) fun mintMOXToAddress(address: Address, amount: UFix64) {
            let tokenReceiver = getAccount(address)
                .getCapability(MoxyToken.moxyTokenReceiverPath)
                .borrow<&{FungibleToken.Receiver}>()
                ?? panic("Unable to borrow receiver reference")
            
            let mintedVault <- self.mintMOXYTokens(amount: amount)

            // Mint tokens to user, first deduct Membership Fee amount
            if (self.accounts[address]?.hasMembershipFeePending()!) {
                let vaultDeducted <- self.collectMembershipFee(address: address, vault: <-mintedVault)
                tokenReceiver.deposit(from: <- vaultDeducted)            
            } else {
                tokenReceiver.deposit(from: <- mintedVault)
            }
        }

        pub fun getTotalSupply24DueForProcessTo(address: Address, toTimestamp: UFix64): {UFix64: UFix64} {
            
            let fromTimestamp = self.accounts[address]?.dailyActivityUpdatedTimestamp!
            let from0000 = MoxyData.getTimestampTo0000(timestamp: fromTimestamp)
            let to0000 = MoxyData.getTimestampTo0000(timestamp: toTimestamp)
            let day = 86400.0
            let acct = getAccount(address)
            let vaultRef = acct.getCapability(ScoreToken.scoreTokenDailyBalancePath)
                            .borrow<&ScoreToken.Vault{ScoreToken.DailyBalancesInterface}>()
                            ?? panic("Could not borrow Balance reference to the Vault (address".concat(acct.address.toString().concat(")")))

            // Get all pending since last update
            let resu: {UFix64: UFix64} = {}
            var curr0000 = from0000

            if (curr0000 <= 0.0) {
                var first = vaultRef.getFirstTimestampAdded()
                if (first == nil) {
                    return resu
                }
                curr0000 = first!
            }
            if (fromTimestamp == curr0000) {
                // Skip to next if start is equal to last registered
                curr0000 = curr0000 + day
            }

            while (curr0000 < to0000) {
                var val = vaultRef.getBalanceFor(timestamp: curr0000)
                if (val == nil) {
                    val = 0.0
                }
                resu[curr0000] = val
                curr0000 = curr0000 + day
            }
            return resu 
        }

        pub fun createMVToMOXYConverter(mvConverter: @MoxyVaultToken.MVConverter, conversionRequest: @LockedMoxyToken.ConversionRequest): @MVToMOXYConverter {
            if (mvConverter.address != conversionRequest.address) {
                panic("Conversion are available only with requests on the same address.")
            }

            let inConversion = self.accounts[mvConverter.address]?.getMVToMOXYTotalInConversion()
            
            let acct = getAccount(mvConverter.address)
            let vaultRef = acct.getCapability(MoxyVaultToken.moxyVaultTokenBalancePath)
                .borrow<&MoxyVaultToken.Vault{FungibleToken.Balance}>()
                ?? panic("Could not borrow Balance reference to the Vault")

            let available = vaultRef.balance - inConversion!

            if (available < mvConverter.allowedAmount) {
                panic("Not enough funds to convert MV to MOXY")
            }

            return <- create MVToMOXYConverter(mvConverter: <-mvConverter, conversionRequest: <- conversionRequest, timestamp: getCurrentBlock().timestamp, withdrawalDays: self.mvToMOXWithdrawalDays)
        }

        pub fun getMVConverterStorageIdentifier(timestamp: UFix64): String {
            return "mvToMOXYConverter".concat(UInt64(timestamp).toString())
        }

        pub fun registerMVToMOXConversion(address:Address, timestamp: UFix64, amount: UFix64) {
            pre {
                self.accounts[address]?.hasVaildMVToMOXYConverters(address: address)! : "Address converting does not match with original converter"
            }

            self.mvToMOXConversionQueue.addAccount(address: address)
            emit MOXToMVDailyConversionTo(address: address, timestamp: timestamp, amount: amount)
        }

        pub fun payMOXDueMVConversion(quantity: Int) {
            //It will run for a quantity of addresses depending on the current queue progress
            let run <- self.mvToMOXConversionQueue.lockRunWith(quantity: quantity)
            if (run == nil) {
                emit NoAddressesToProcessMVConversionProcess(timestamp: getCurrentBlock().timestamp)
                destroy run
                return
            }
            let addresses = run?.getCurrentAddresses()!
            
            if (self.mvToMOXConversionQueue.isAtBeginning()) {
                emit StartingPayingMOXYDueMVConversion(timestamp: getCurrentBlock().timestamp, accountsToProcess: self.mvToMOXConversionQueue.getAccountsQuantity())
            }
            self.payMOXDueMVConversionToAddresses(addresses: addresses)
            self.mvToMOXConversionQueue.completeNextAddresses(run: <-run!)
            if (self.mvToMOXConversionQueue.hasFinished()) {
                emit FinishedPayingMOXYDueMVConversion(timestamp: getCurrentBlock().timestamp, accountsProcessed: self.mvHoldingsQueue.getAccountsQuantity())
            }
            emit BatchRewardsPaymentsDueMVHoldings(timestamp: getCurrentBlock().timestamp, requestedToProcess: quantity, accountsProcessed: addresses.length, totalAccounts: self.mvToMOXConversionQueue.getAccountsQuantity())
        }

        pub fun payMOXDueMVConversionToAddresses(addresses: [Address]) {
            for address in addresses {
                self.payMOXDueMVConversionFor(address: address)
            }
        }

        // Pay due MOXY to MV conversion for an specific account up to
        // the current timestamp date
        pub fun payMOXDueMVConversionFor(address: Address) {
            if (!self.accounts[address]?.hasVaildMVToMOXYConverters(address: address)!) {
                return log("Address has invalid conversion requests.")
            }

            let timestamp = getCurrentBlock().timestamp
            let amount = self.accounts[address]?.payMOXDueMVConversionUpto(timestamp: timestamp)
            self.totalPaidDueMVConversion = self.totalPaidDueMVConversion + amount!
            if (self.paidDueMVConversion[timestamp] == nil) {
                self.paidDueMVConversion[timestamp] = 0.0
            }
            let time0000 = MoxyData.getTimestampTo0000(timestamp: getCurrentBlock().timestamp)
            self.paidDueMVConversion[timestamp] = self.paidDueMVConversion[timestamp]! + amount!
            self.accounts[address]?.updateTotalPaidDueMVConversion(amount: amount!)
        }

        pub fun checkAndRemoveFinishedConversionTo(addresses: [Address]) {
            for address in addresses {
                if (self.accounts[address]?.haveFinishedConversions()!) {
                    self.mvToMOXConversionQueue.removeAccount(address: address)
                }
            }
        }

        pub fun depositToPlayAndEarnVault(address: Address, vault: @FungibleToken.Vault) {
            self.accounts[address]?.playAndEarnRef!.borrow()!.deposit(from: <-vault)
        }

        pub fun withdrawFromPlayAndEarnVault(address: Address, amount: UFix64) {
            let peVault = self.accounts[address]?.playAndEarnRef!.borrow()!
            let vault <- peVault.withdraw(amount: amount)

            let recipient = getAccount(address)
            // Get a reference to the recipient's Receiver
            let receiverRef = recipient.getCapability(MoxyToken.moxyTokenReceiverPath)
                .borrow<&{FungibleToken.Receiver}>()
                ?? panic("Could not borrow receiver reference to the recipient's Vault")

            receiverRef.deposit(from: <-vault)
        }

        pub fun payFromPlayAndEarnVault(payee: Address, amount: UFix64, toAddress: Address) {
            let peVault = self.accounts[payee]?.playAndEarnRef!.borrow()!
            let vault <- peVault.withdraw(amount: amount)

            // Get the recipient's public account object
            let recipient = getAccount(toAddress)

            let receiverRef = recipient.getCapability(MoxyToken.moxyTokenReceiverPath)
                .borrow<&{FungibleToken.Receiver}>()
                ?? panic("Could not borrow receiver reference to the recipient's Vault")

            receiverRef.deposit(from: <- vault)
        }

        pub fun withdrawFundsFromPlayAndEarnVault(address: Address, amount: UFix64): @FungibleToken.Vault {
            let peVault = self.accounts[address]?.playAndEarnRef!.borrow()!
            let vault <- peVault.withdraw(amount: amount)

            return <-vault

        }

        pub fun transferMOXY(fromVault: @FungibleToken.Vault, to: Address) {
            // Function to transfer MOX from one account to a recepient account
            // The process consists on obtainig the vault with the amount received
            // doing a withdraw from the origin account
            // Then is calculated the fee charged, and the amount deposited to
            // the receiver will be the original amount subtracting that fee.
            // Then the fee is stored 95% on Treasury account and 5% is converted
            // to PLAY in order to strength Proof of Play to all ecosystem.
            // Finally if the recipient is the Treasury Account, additionally the 10%
            // of the received funds will be converted to PLAY to strength 
            // Proof of Play.
            // All convertions from MOX to PLAY are done in a rate 2:1 

            
            if (self.accounts[to] == nil && self.playAndEarnEventAccounts[to] == nil && self.moxyControlledAccounts[to] == nil) {
                panic ("Recipient account not found in Moxy Club.")
            }

            // Get the recipient's public account object
            let recipient = getAccount(to)
            let feeRecipient = getAccount(self.treasuryAddress!)

            // Get a reference to the recipient's Receiver
            let receiverRef = recipient.getCapability(MoxyToken.moxyTokenReceiverPath)
                .borrow<&{FungibleToken.Receiver}>()
                ?? panic("Could not borrow receiver reference to the recipient's Vault")

            // Get a reference to the fee recipient's Receiver
            let feeReceiverRef = feeRecipient.getCapability(MoxyToken.moxyTokenReceiverPath)
                .borrow<&{FungibleToken.Receiver}>()
                ?? panic("Could not borrow receiver reference to the recipient's Vault")

            // Calculate cutted amounts
            let feeAmount = self.getMOXYFeeAmount()
            var receiverAmount = fromVault.balance - feeAmount
            var convertToPLAY: UFix64 = 0.0

            emit FeeCharged(address: to, amount: feeAmount)

            // Receiver if treasury 10% goes to PLAY
            if (to == self.treasuryAddress) {
                convertToPLAY = receiverAmount * 0.1
                receiverAmount = receiverAmount - convertToPLAY

                emit TreasuryRepurchase(amount: convertToPLAY)
            } 

            let receiverVault: @FungibleToken.Vault <- fromVault.withdraw(amount: receiverAmount) 
            let feeReceiverVault: @FungibleToken.Vault <- fromVault.withdraw(amount: feeAmount + convertToPLAY)

            // Deposit the withdrawn tokens in the recipient's receiver
            // If the recipient has pending Membership Fee to paid, the fee is collected
            if (self.accountHasMembershipFeePending(address: to)) {
                let vaultDeducted <- self.collectMembershipFee(address: to, vault: <-receiverVault)
                receiverRef.deposit(from: <- vaultDeducted)
            } else {
                receiverRef.deposit(from: <- receiverVault)
            }

            // Fee Amount 95% to treasury and 5% to PLAY (2x1 ratio)
            let moxToPlayAmount = convertToPLAY + feeAmount * self.percentFeeToPLAY
            let moxFeeAmount = feeReceiverVault.balance - moxToPlayAmount

            let feeReceiverMOXVault: @FungibleToken.Vault <- feeReceiverVault.withdraw(amount: moxFeeAmount)
            let moxToPLAYVault: @FungibleToken.Vault <- feeReceiverVault.withdraw(amount: moxToPlayAmount)

            feeReceiverRef.deposit(from: <- feeReceiverMOXVault)

            // Burn MOXY
            // Mint play 2:1 for treasuryAddress
            self.convertMOXYtoPLAY(vault: <-moxToPLAYVault, address: self.treasuryAddress!, relation: 2.0)

            // Residual MOX handling. If there are differences due floating point precision
            feeReceiverRef.deposit(from: <- fromVault)
            feeReceiverRef.deposit(from: <- feeReceiverVault)
            
        }

        pub fun accountHasMembershipFeePending(address: Address): Bool {
            if (self.accounts[address] == nil && self.playAndEarnEventAccounts[address] == nil && self.moxyControlledAccounts[address] == nil ) {
                panic ("Account not found in Moxy Club.")
            }
            if (self.playAndEarnEventAccounts[address] != nil || self.moxyControlledAccounts[address] != nil ) {
                return false
            }
            return self.accounts[address]?.hasMembershipFeePending()!
        }

        access(contract) fun convertMOXYtoPLAY(vault: @FungibleToken.Vault, address: Address, relation: UFix64) {
            let playAmount = vault.balance / relation

            if (playAmount > 0.0) {
                // Mint PLAY token
                let tokenAdmin: &PlayToken.Administrator = MoxyClub.account.borrow<&PlayToken.Administrator>(from: PlayToken.playTokenAdminStorage)
                    ?? panic("Signer is not the token admin")

                let tokenReceiver: &{PlayToken.ReceiverInterface} = getAccount(address)
                    .getCapability(PlayToken.playTokenReceiverInterfacePath)
                    .borrow<&{PlayToken.ReceiverInterface}>()
                    ?? panic("Unable to borrow receiver reference")

                
                let minter <- tokenAdmin.createNewMinter(allowedAmount: playAmount)
                
                let mintedVault <- minter.mintTokens(amount: playAmount)
                tokenReceiver.convertedFromMOXY(from: <-mintedVault)
                destroy minter
            }

            // Burn MOX
            // Create a reference to the admin admin resource in storage
            let admin = MoxyClub.account.borrow<&MoxyToken.Administrator>(from: MoxyToken.moxyTokenAdminStorage)
                ?? panic("Could not borrow a reference to the admin resource")

            let burner <- admin.createNewBurner()
            burner.burnTokens(from: <-vault)
            destroy burner

        }

        // Returns the MV to MOX requests by address
        pub fun getMVToMOXtRequests(address: Address): {UFix64: MVToMOXRequestInfo} {
            if (self.accounts[address] == nil) {
                panic("Address not found in MoxyClub")
            }
            return self.accounts[address]?.getMVToMOXtRequests()!
        }

        pub fun isTGESet(): Bool {
            return self.getTGEDate() > 0.0
        }
        
        pub fun releaseIsNotStarted(): Bool {
            return !self.isReleaseStarted
        }

        pub fun isTGEDateReached(): Bool {
            return self.getTGEDate() <= getCurrentBlock().timestamp
        }

        pub fun areRoundsReadyToStartRelease(): Bool {
            let rounds = self.getRoundsCapability().borrow()!
            return  rounds.isReadyToStartRelease()
        }

        pub fun haveAllRoundsStarted(): Bool {
            let rounds = self.getRoundsCapability().borrow()!
            return  rounds.haveAllRoundsStarted()
        }
        
        // Start release to a quantity of addresses. This is the starting point
        // The methods called from here will be not available to call independtly
        pub fun startReleaseTo(quantity: Int) {
             pre {
                self.releaseIsNotStarted() : "Cannot start allocation process: Release is already started."
                self.isTGESet() : "Cannot start allocation process: TGE Date is not set."
                self.isTGEDateReached() : "Cannot start allocation process: TGE date is not reached."
            }

            let rounds = self.getRoundsCapability().borrow()!
            if (rounds.isQueueAtBegining()) {
                // Start round release is starting process. Emit event.
                let accountsToProcess = rounds.getAccountsToProcess()
                emit StartingRoundReleaseInitializeProcess(timestamp: (getCurrentBlock().timestamp),roundsToProcess: rounds.getRoundsLength(), accountsToProcess: accountsToProcess)
            }

            for roundId in rounds.getRoundsNames() {
                if (!rounds.hasQueueFinished(roundId: roundId)) {
                    // Process unfinished round and exit
                    let run <- rounds.getQueueNextAddresses(roundId: roundId, quantity: quantity)
                    let addresses = run.getCurrentAddresses()
                    self.startReleaseRoundToAddress(roundId: roundId, addresses: addresses)
                    rounds.completeNextAddresses(roundId: roundId, run: <-run)
                    return
                }
            }

            // Check if all rounds were processed
            if (rounds.initialAllocationFinished()) {
                self.isReleaseStarted = true
                let accountsToProcess = rounds.getAccountsToProcess()
                emit FinishedRoundReleaseInitializeProcess(timestamp: getCurrentBlock().timestamp, roundsProcessed: rounds.getRoundsLength(), accountsProcessed: accountsToProcess)
            }
        }

        // Process start release to addresses from round id provided
        access(self) fun startReleaseRoundToAddress(roundId: String, addresses: [Address]) {
            for address in addresses {
                self.startReleaseRoundAddress(roundId: roundId, address: address)
            }
        }

        access(self) fun startReleaseRoundAddress(roundId: String, address: Address) {
            let rounds = self.getRoundsCapability().borrow()!
            let amount = rounds.getAmountFor(roundId: roundId, address: address)

            if (amount > 0.0) {
                // Mint $MOXY for the round
                let initialReleaseVault <- self.mintMOXYTokens(amount: amount)
                rounds.startReleaseRound(roundId: roundId, address: address, initialVault: <-initialReleaseVault)
            }
        }

        pub fun assignMoxyControlledWalletsToRounds( 
                    publicIDOAddress: Address, teamAddress: Address, 
                    foundationAddress: Address, advisorsAddress: Address,
                    treasuryAddress: Address, ecosystemAddress: Address) {
            
            let roundsManager = self.getRoundsCapability().borrow()!
            roundsManager.fullAllocateTo(roundId: "public_ido", address: publicIDOAddress)
            roundsManager.fullAllocateTo(roundId: "team", address: teamAddress)
            roundsManager.fullAllocateTo(roundId: "moxy_foundation", address: foundationAddress)
            roundsManager.fullAllocateTo(roundId: "advisors", address: advisorsAddress)
            roundsManager.fullAllocateTo(roundId: "treasury", address: treasuryAddress)
            roundsManager.fullAllocateTo(roundId: "ecosystem", address: ecosystemAddress)

            self.roundReleaseQueue.addAccount(address: publicIDOAddress)
            self.roundReleaseQueue.addAccount(address: teamAddress)
            self.roundReleaseQueue.addAccount(address: foundationAddress)
            self.roundReleaseQueue.addAccount(address: advisorsAddress)
            self.roundReleaseQueue.addAccount(address: treasuryAddress)
            self.roundReleaseQueue.addAccount(address: ecosystemAddress)
            
        }

        pub fun areMoxyControlledWalletsAllocated(): Bool {
            let roundsManager = self.getRoundsCapability().borrow()!

            return (
                    roundsManager.isReadyToStartReleaseTo(roundId: "public_ido") &&
                    roundsManager.isReadyToStartReleaseTo(roundId: "team") &&
                    roundsManager.isReadyToStartReleaseTo(roundId: "moxy_foundation") &&
                    roundsManager.isReadyToStartReleaseTo(roundId: "advisors") &&
                    roundsManager.isReadyToStartReleaseTo(roundId: "treasury") &&
                    roundsManager.isReadyToStartReleaseTo(roundId: "ecosystem")
                )
        }

        pub fun purchaseFromPublicPresale(roundsRef: Capability<&MoxyReleaseRounds.Rounds>, address: Address, amount: UFix64) {
            let roundManager = roundsRef.borrow()!

            roundManager.setAddress(roundId: "public_presale", address: address, amount: amount)
            self.roundReleaseQueue.addAccount(address: address)

            if (self.isReleaseStarted) {
                // Mint $MOXY for the round
                let initialReleaseVault <- self.mintMOXYTokens(amount: amount)
                roundManager.allocateAfterTGE(roundId: "public_presale", vault: <-initialReleaseVault, address: address)
            }
        }

        pub fun transferWithRoundSchedule(vault: @FungibleToken.Vault, roundsRef: Capability<&MoxyReleaseRounds.Rounds>, roundId: String, address: Address, startTime: UFix64) {
            let roundManager = roundsRef.borrow()!

            roundManager.incorporateAddress(roundId: roundId, address: address, amount: vault.balance, startTime: startTime)
            self.roundReleaseQueue.addAccount(address: address)

            roundManager.allocateOn(timestamp: startTime, roundId: roundId, vault: <-vault, address: address)
        }

        pub fun getProcessRoundsRemainings(): Int {
            return self.roundReleaseQueue.getRemainings()
        }

        pub fun getProcessRoundsAccountsQuantity(): Int {
            return self.roundReleaseQueue.getAccountsQuantity()
        }

        pub fun getProcessRoundsStatus(): MoxyProcessQueue.CurrentRunStatus {
            return self.roundReleaseQueue.getCurrentRunStatus()
        }

        pub fun setProcessRoundsRunSize(quantity: Int) {
            self.roundReleaseQueue.setRunSize(quantity: quantity)
        }

        pub fun getProcessRoundsRunSize(): Int {
            return self.roundReleaseQueue.getRunSize()
        }

        pub fun getProcessRoundsRemainingAddresses(): [Address] {
            return self.roundReleaseQueue.getRemainingAddresses()
        }

        pub fun getProcessMVHoldingsRemainings(): Int {
            return self.mvHoldingsQueue.getRemainings()
        }

        pub fun getProcessMVHoldingsAccountsQuantity(): Int {
            return self.mvHoldingsQueue.getAccountsQuantity()
        }

        pub fun getProcessMVHoldingsStatus(): MoxyProcessQueue.CurrentRunStatus {
            return self.mvHoldingsQueue.getCurrentRunStatus()
        }

        pub fun setProcessMVHoldingsRunSize(quantity: Int) {
            self.mvHoldingsQueue.setRunSize(quantity: quantity)
        }

        pub fun getProcessMVHoldingsRunSize(): Int {
            return self.mvHoldingsQueue.getRunSize()
        }

        pub fun getProcessMVHoldingsRemainingAddresses(): [Address] {
            return self.mvHoldingsQueue.getRemainingAddresses()
        }

        pub fun getProcessProofOfPlayRemainings(): Int {
            return self.proofOfPlayQueue.getRemainings()
        }

        pub fun getProcessProofOfPlayAccountsQuantity(): Int {
            return self.proofOfPlayQueue.getAccountsQuantity()
        }

        pub fun getProcessProofOfPlayStatus(): MoxyProcessQueue.CurrentRunStatus {
            return self.proofOfPlayQueue.getCurrentRunStatus()
        }

        pub fun setProcessProofOfPlayRunSize(quantity: Int) {
            self.proofOfPlayQueue.setRunSize(quantity: quantity)
        }

        pub fun getProcessProofOfPlayRunSize(): Int {
            return self.proofOfPlayQueue.getRunSize()
        }

        pub fun getProcessProofOfPlayRemainingAddresses(): [Address] {
            return self.proofOfPlayQueue.getRemainingAddresses()
        }

        pub fun getMVToMOXConversionRemainings(): Int {
            return self.mvToMOXConversionQueue.getRemainings()
        }

        pub fun getMVToMOXConversionAccountsQuantity(): Int {
            return self.mvToMOXConversionQueue.getAccountsQuantity()
        }

        pub fun getMVToMOXConversionStatus(): MoxyProcessQueue.CurrentRunStatus {
            return self.mvToMOXConversionQueue.getCurrentRunStatus()
        }

        pub fun setMVToMOXConversionRunSize(quantity: Int) {
            self.mvToMOXConversionQueue.setRunSize(quantity: quantity)
        }
        
        pub fun getMVToMOXConversionRunSize(): Int {
            return self.mvToMOXConversionQueue.getRunSize()
        }

        pub fun getMVToMOXConversionRemainingAddresses(): [Address] {
            return self.mvToMOXConversionQueue.getRemainingAddresses()
        }

        pub fun setIsGoodStandingOnOpenEvents(address: Address, value: Bool) {
            self.accounts[address]?.setIsGoodStandingOnOpenEvents(value: value)
        }

        pub fun convertMOXYToMV(address: Address, vault: @FungibleToken.Vault) {
            // Converting MOXY to MV locks the MOXY
            if (!self.accounts[address]?.isGoodStandingOnOpenEvents()!) {
                panic ("Account should participate in next Opnen events to convert MOXY to MV")
            }

            let account = getAccount(address)
            let amount = vault.balance

            // Get a reference to the recipient's Receiver
            let userRef = account.getCapability(MoxyToken.moxyTokenLockedMVReceiverPath)
                .borrow<&{LockedMoxyToken.Receiver}>()
                ?? panic("Could not borrow receiver reference to the recipient's Vault")

            // Deposit the withdrawn tokens in the recipient's receiver
            let vaultConverted <- vault as! @MoxyToken.Vault
            userRef.deposit(from: <- vaultConverted)

            // Create an MV minter with the same amount of MOX locked
            let tokenAdmin = MoxyClub.account.borrow<&MoxyVaultToken.Administrator>(from: MoxyVaultToken.moxyVaultTokenAdminStorage)
                ?? panic("Signer is not the token admin")
            
            let minter <- tokenAdmin.createNewMinter(allowedAmount: amount)
            let mintedVault <- minter.mintTokens(amount: amount)
            // Get a reference to the recipient's Receiver

            let userMVRef = account.getCapability(MoxyVaultToken.moxyVaultTokenReceiverTimestampPath)
                .borrow<&{MoxyVaultToken.ReceiverInterface}>()
                ?? panic("Could not borrow receiver reference to the recipient's Vault")

            // Deposit the withdrawn tokens in the recipient's receiver
            userMVRef.depositDueConversion(from: <- mintedVault) 

            destroy minter
        }

        pub fun convertLockedMOXYToLockedMV(request: @LockedMoxyToken.ConversionRequest, address: Address) {
            pre {
                address == request.address : "Address does not match with the owner of the vault"
            }

            if (!self.accounts[address]?.isGoodStandingOnOpenEvents()!) {
                panic ("Account should participate in next Opnen events to convert MOXY to MV")
            }

            let account = getAccount(address)
            
            let fixedAmount = request.getFixedAmount()

            // Get the reference of the LockedMVMOXY
            let userRef = account.getCapability(MoxyToken.moxyTokenLockedMVReceiverPath)
                    .borrow<&{LockedMoxyToken.Receiver}>()
                    ?? panic("Could not borrow receiver reference to the recipient's Vault")
            let vault <- request.withdraw()
            let amount = vault.balance
            userRef.deposit(from: <- vault)

            // Mint locked MV to the user
            // Create an MV minter with the same amount of MOXY locked
            let tokenAdmin = MoxyClub.account.borrow<&MoxyVaultToken.Administrator>(from: MoxyVaultToken.moxyVaultTokenAdminStorage)
                ?? panic("Signer is not the token admin")
            
            let minter <- tokenAdmin.createNewMinter(allowedAmount: amount)
            let mintedVault <- minter.mintTokens(amount: amount)

            // Get a reference to the recipient's Receiver
            let userMVRef = account.getCapability(MoxyVaultToken.moxyVaultTokenLockedReceiverPath)
                .borrow<&{LockedMoxyVaultToken.Receiver}>()
                ?? panic("Could not borrow receiver reference to the recipient's Vault")

            // Deposit the withdrawn tokens in the recipient's receiver
//            userMVRef.deposit(from: <- mintedVault)
            let vaultConverted <- mintedVault.withdrawAmount(amount: amount - fixedAmount) as! @MoxyVaultToken.Vault
            userMVRef.depositFromSchedule(from: <- vaultConverted, schedule: request.getSchedule())

            var i = 0
            let schedules = request.getFixedSchedules()
            while (i < schedules.length) {
                let fx = schedules[i]
                var am = mintedVault.balance
                if (fx.remaining < am) {
                    am = fx.remaining
                }
                let vaultConverted <- mintedVault.withdrawAmount(amount: am) as! @MoxyVaultToken.Vault
                userMVRef.depositFromFixedSchedule(from: <- vaultConverted, schedule: fx.schedule)
                i = i +1
            }

            if (mintedVault.balance != 0.0) {
                panic("Error minted vault has not been fully allocated")
            } 
        

            // Update MVHoldings timestamp if it is not initialized
            var lastMVHoldingsUpdatedTimestamp = self.accounts[address]?.lastMVHoldingsUpdatedTimestamp!
            if (lastMVHoldingsUpdatedTimestamp == 0.0) {
                self.accounts[address]?.setLastMVHoldingsUpdatedTimestamp(timestamp: getCurrentBlock().timestamp)
            }

            destroy mintedVault
            destroy request
            destroy minter
        }

        pub fun allocateDailyReleaseTo(roundsRef: Capability<&MoxyReleaseRounds.Rounds>, quantity: Int) {
            //It will run for a quantity of addresses depending on the current queue progress
            let run <- self.roundReleaseQueue.lockRunWith(quantity: quantity)
            if (run == nil) {
                emit NoAddressesToProcessForRoundReleaseAllocation(timestamp: getCurrentBlock().timestamp)
                destroy run
                return
            }
            let addresses = run?.getCurrentAddresses()!
            
            if (self.roundReleaseQueue.isAtBeginning()) {
                emit StartingDailyRoundReleaseAllocationProcess(timestamp: getCurrentBlock().timestamp, accountsToProcess: self.roundReleaseQueue.getAccountsQuantity())
            }
            self.allocateDailyReleaseToAddresses(roundsRef: roundsRef, addresses: addresses)
            self.roundReleaseQueue.completeNextAddresses(run: <-run!)
            if (self.roundReleaseQueue.hasFinished()) {
                emit FinishedDailyRoundReleaseAllocationProcess(timestamp: getCurrentBlock().timestamp, accountsProcessed: self.roundReleaseQueue.getAccountsQuantity())
            }
            emit BatchDailyRoundReleaseAllocationProcess(timestamp: getCurrentBlock().timestamp, requestedToProcess: quantity, accountsProcessed: addresses.length, totalAccounts: self.roundReleaseQueue.getAccountsQuantity())
        }

        pub fun allocateDailyReleaseToAddresses(roundsRef: Capability<&MoxyReleaseRounds.Rounds>, addresses: [Address]) {
            for address in addresses {
                self.allocateDailyReleaseNowToAddress(roundsRef: roundsRef, address: address)
            }
        }

        pub fun allocateDailyReleaseNowToAddress(roundsRef: Capability<&MoxyReleaseRounds.Rounds>, address: Address) {
//            let roundManager = roundsRef.borrow()!
            let roundManager= self.getRoundsCapability().borrow()!

            if (!roundManager.hasRoundRelease(address: address)) {
                log("Address is not participating on round release process")
                return
            }

            let membershipFeeReceiver = getAccount(address)
                            .getCapability(MoxyToken.moxyTokenReceiverPath)
                            .borrow<&{FungibleToken.Receiver}>()
                            ?? panic("Unable to borrow receiver reference")

            let feeRemaining = self.getMembershipFeeMOXYRemainingFor(address: address)

            let feeVault <- roundManager.allocateDailyReleaseNowToAddress(address: address, feeRemaining: feeRemaining)
            let vaultDeducted <- self.collectMembershipFee(address: address, vault: <-feeVault)
            membershipFeeReceiver.deposit(from: <- vaultDeducted)            
        }

        pub fun getAccountAddress(start: Int, end: Int): [Address] {
            pre {
                start <= end : "Start parameter should be lower than end"
            }
            let total = self.accounts.length
            var e = end
            if (end >= total) {
                e = total
            }
            return self.accounts.keys.slice(from: start, upTo: e)
        }

        pub fun getTotalAccounts(): Int {
            return self.accounts.length
        }

        access(self) fun getRoundsCapability(): Capability<&MoxyReleaseRounds.Rounds> {
            return MoxyClub.account.getCapability<&MoxyReleaseRounds.Rounds>(MoxyReleaseRounds.moxyRoundsPrivate)
        }

        pub fun getTGEDate(): UFix64 {
            let rounds = self.getRoundsCapability().borrow()!
            return rounds.tgeDate
        }

        pub fun releaseStarted(): Bool {
            return self.isReleaseStarted
        }

        init() {
            self.accounts <- {}

            self.isReleaseStarted = false
  
            // Fee amount in MOX
            self.feeAmountInFLOW = 0.000001
            self.moxyToFLOWValue = 0.02076124 //Estimated FLOW to USD: 2.89, MOXY to USD: 0.06
            self.moxyToUSDValue = 0.06        //Public IDO value at TGE

            // BURN on transaction fees: 95% to Moxy and its affiliates/partners, 
            // and 5% BURN to PLAY token to further strengthen Proof of Play
            self.percentFeeToPLAY = 0.05
            
            self.treasuryAddress = nil
            self.associationAddress = nil

            self.totalEarnedFromMVHoldings = 0.0
            self.earnedFromMVHoldings = {}
            self.totalPaidDueDailyActivity = 0.0
            self.paidDueDailyActivity = {}
            
            self.totalPaidDueMVConversion = 0.0
            self.paidDueMVConversion = {}

            // Maximum percentage for MV Holdings rewards for Locked MV
            // Initial value is 4%
            self.maximumPercentageLockedMV = 4.0

            self.mvToMOXWithdrawalDays = 90

            self.roundReleaseQueue <- MoxyProcessQueue.createNewQueue()
            self.mvHoldingsQueue <- MoxyProcessQueue.createNewQueue()
            self.proofOfPlayQueue <- MoxyProcessQueue.createNewQueue()
            self.mvToMOXConversionQueue <- MoxyProcessQueue.createNewQueue()

            // Proof of Play Weigth
            self.popScoreWeight = 30.0
            self.popDailyScoreWeight = 70.0
            self.popPlayDonationWeight = 0.0

            // Proof of play anual percenage
            self.proofOfPlayPercentage = 1.0

            // Play and Earn event accounts dictionary
            self.playAndEarnEventAccounts <- {}
            
            // Moxy Controlled Accounts dictionary
            self.moxyControlledAccounts = {}

            // Launch fee value is in MOXY
            self.launchFee = 10.0

            //Masterclass prices in MOXY
            self.masterclassPrices = {}

            //Games prices in MOXY
            self.gamesPrices = {}

        }

        destroy() {
            destroy self.accounts
            destroy self.playAndEarnEventAccounts
            destroy self.roundReleaseQueue
            destroy self.mvHoldingsQueue
            destroy self.proofOfPlayQueue
            destroy self.mvToMOXConversionQueue
        }

    }

    access(self) fun getMoxyEcosystemCapability(): &MoxyEcosystem {
        return self.account
            .getCapability(self.moxyEcosystemPrivate)
            .borrow<&MoxyClub.MoxyEcosystem>()!
    }

    pub fun getMoxyEcosystemPublicCapability(): &MoxyEcosystem{MoxyEcosystemInfoInterface} {
        return self.account
                .getCapability(MoxyClub.moxyEcosystemInfoPublic)
                .borrow<&MoxyClub.MoxyEcosystem{MoxyEcosystemInfoInterface}>()!
    }
    
    pub resource interface MoxyEcosystemInfoInterface {
        pub fun isMoxyAccount(address: Address): Bool
        pub fun isPlayAndEarnEventAccount(address: Address): Bool

        pub fun getTGEDate(): UFix64
        pub fun getTreasuryAddress(): Address?
        pub fun getAssociationAddress(): Address?

        pub fun hasMembershipFeePendingFor(address: Address): Bool
        pub fun getMembershipFeeRemainingFor(address: Address): UFix64
        pub fun getMembershipFeeFor(address: Address): UFix64
        pub fun getMembershipFeeMOXYRemainingFor(address: Address): UFix64
        pub fun getMembershipFeeMOXYFor(address: Address): UFix64
        pub fun getMembershipFeeMOXY(): UFix64

        pub fun getTotalEarnedFromMVHoldings(): UFix64
        pub fun getEarnedFromMVHoldingsForTime(timestamp: UFix64): UFix64
        pub fun getEarnedFromMVHoldingsForTimeRange(from: UFix64, to: UFix64): {UFix64:UFix64}
        pub fun getEarnedFromMVHoldingsFor(address: Address): {UFix64: UFix64}
        pub fun getEarnedFromMVHoldingsForAddressTime(address: Address, timestamp: UFix64): UFix64 
        pub fun getEarnedFromMVHoldingsForAddressTimeRange(address: Address, from: UFix64, to: UFix64): {UFix64:UFix64}
        pub fun getTotalEarnedFromMVHoldingsFor(address: Address): UFix64

        pub fun getTotalPaidDueDailyActivity(): UFix64
        pub fun getPaidDueDailyActivityForTime(timestamp: UFix64): UFix64
        pub fun getPaidDueDailyActivityForTimeRange(from: UFix64, to: UFix64): {UFix64:UFix64}
        pub fun getPaidDueDailyActivityFor(address: Address): {UFix64: UFix64}
        pub fun getPaidDueDailyActivityForAddressTime(address: Address, timestamp: UFix64): UFix64
        pub fun getPaidDueDailyActivityForAddressTimeRange(address: Address, from: UFix64, to: UFix64): {UFix64:UFix64}
        pub fun getTotalPaidDueDailyActivityFor(address: Address): UFix64
        
        pub fun getTotalPaidDueMVConversion(): UFix64
        pub fun getTotalPaidDueMVConversionFor(address: Address): UFix64
        pub fun getPaidDueMVConversionForTime(timestamp: UFix64): UFix64
        pub fun getPaidDueMVConversionForTimeRange(from: UFix64, to: UFix64): {UFix64:UFix64}
        
        pub fun getMOXYFeeAmount(): UFix64
        pub fun getMOXYToFLOWValue(): UFix64
        pub fun getMOXYToUSDValue(): UFix64

        pub fun areMoxyControlledWalletsAllocated(): Bool
        
        pub fun getProcessRoundsRemainings(): Int
        pub fun getProcessMVHoldingsRemainings(): Int 
        pub fun getProcessProofOfPlayRemainings(): Int 
        pub fun getMVToMOXConversionRemainings(): Int 
        pub fun getProcessRoundsAccountsQuantity(): Int
        pub fun getProcessMVHoldingsAccountsQuantity(): Int 
        pub fun getProcessProofOfPlayAccountsQuantity(): Int 
        pub fun getMVToMOXConversionAccountsQuantity(): Int 
        pub fun getProcessRoundsStatus(): MoxyProcessQueue.CurrentRunStatus
        pub fun getProcessMVHoldingsStatus(): MoxyProcessQueue.CurrentRunStatus
        pub fun getProcessProofOfPlayStatus(): MoxyProcessQueue.CurrentRunStatus
        pub fun getMVToMOXConversionStatus(): MoxyProcessQueue.CurrentRunStatus
        pub fun getProcessMVHoldingsRunSize(): Int
        pub fun getMVToMOXConversionRunSize(): Int
        pub fun getProcessRoundsRunSize(): Int 
        pub fun getProcessProofOfPlayRunSize(): Int 
        pub fun getProcessRoundsRemainingAddresses(): [Address]
        pub fun getProcessMVHoldingsRemainingAddresses(): [Address]
        pub fun getProcessProofOfPlayRemainingAddresses(): [Address]
        pub fun getMVToMOXConversionRemainingAddresses(): [Address]
        
        pub fun releaseStarted(): Bool

        pub fun getLaunchFee(): UFix64
        pub fun getMasterclassPrice(classId: String): UFix64?
        pub fun getMasterclassPrices(): {String: UFix64}

        pub fun getGamePrice(gameId: String): UFix64?
        pub fun getGamesPrices(): {String: UFix64}
        pub fun getProofOfPlayPercentage(): UFix64

        pub fun isGoodStandingOnOpenEvents(address: Address): Bool
        pub fun getMVConverterStorageIdentifier(timestamp: UFix64): String

        pub fun getAccountAddress(start: Int, end: Int): [Address]
        pub fun getTotalAccounts(): Int
    }

    pub resource interface MVToMOXYRequestsInfoInterface {
        pub fun getMVToMOXtRequests(address: Address): {UFix64: MVToMOXRequestInfo}
    }

    pub resource interface MoxyEcosystemOperations {
        pub fun convertLockedMOXYToLockedMV(request: @LockedMoxyToken.ConversionRequest, address: Address)
        pub fun convertMOXYToMV(address: Address, vault: @FungibleToken.Vault)
        pub fun payGamePrice(gameId: String, fromVault: @FungibleToken.Vault, address: Address)
        pub fun payLaunchFee(fromVault: @FungibleToken.Vault, address: Address)
        pub fun payMasterclassPrice(classId: String, fromVault: @FungibleToken.Vault, address: Address)
        pub fun depositToPlayAndEarnVault(address: Address, vault: @FungibleToken.Vault)
        pub fun setPlayAndEarnRefTo(address: Address, vaultRef: Capability<&FungibleToken.Vault>)
        pub fun setMVToMOXYConversionsRefTo(address: Address, conversionsRef: Capability<&{UFix64:MoxyClub.MVToMOXYConverter}>)
        pub fun transferMOXY(fromVault: @FungibleToken.Vault, to: Address)
        pub fun createMVToMOXYConverter(mvConverter: @MoxyVaultToken.MVConverter, conversionRequest: @LockedMoxyToken.ConversionRequest): @MVToMOXYConverter 
        pub fun registerMVToMOXConversion(address:Address, timestamp: UFix64, amount: UFix64)
        pub fun addMoxyAccount(address: Address)
    }

    pub let moxyEcosystemStorage: StoragePath
    pub let moxyEcosystemPrivate: PrivatePath
    pub let moxyEcosystemInfoPublic: PublicPath

    pub let mvToMOXYRequestsInfoPublic: PublicPath

    pub fun version(): String {
        return "2.1.32"
    }

    // Initialize contract
    init(){
        // Initial membership fee amount in USD, calculated with a value of 1 MOXY 0.06 USD
        self.membershipFee = 0.30

        // Moxy Ecosystem initialization
        let moxyEcosystem <- create MoxyEcosystem()

        self.moxyEcosystemStorage = /storage/moxyEcosystem
        self.moxyEcosystemPrivate = /private/moxyEcosystem
        self.moxyEcosystemInfoPublic = /public/moxyEcosystemInfo

        self.mvToMOXYRequestsInfoPublic = /public/mvToMOXYRequestsInfoPublic

        self.account.save(<-moxyEcosystem, to: self.moxyEcosystemStorage)
        self.account.link<&MoxyEcosystem>(self.moxyEcosystemPrivate, target: self.moxyEcosystemStorage)

        self.account.link<&MoxyEcosystem{MVToMOXYRequestsInfoInterface}>(
            self.mvToMOXYRequestsInfoPublic,
            target: self.moxyEcosystemStorage
        )

        self.account.link<&MoxyEcosystem{MoxyEcosystemInfoInterface}>(
            self.moxyEcosystemInfoPublic ,
            target: self.moxyEcosystemStorage
        )

        self.account.link<&MoxyClub.MoxyEcosystem{MoxyClub.MoxyEcosystemOperations}>(
                /public/moxyEcosystemOperationsPublic, 
                target: MoxyClub.moxyEcosystemStorage)!

        self.account.link<&MoxyReleaseRounds.Rounds{MoxyReleaseRounds.MoxyRoundsCreator}>(
                /public/moxyRoundsCreatorPublic, 
                target: MoxyReleaseRounds.moxyRoundsStorage)!

    }
}
 
