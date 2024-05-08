/**

# 

# Author: Increment Labs

*/

import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
// Lending
import LendingInterfaces from "../0x2df970b6cdee5735/LendingInterfaces.cdc"
import LendingConfig from "../0x2df970b6cdee5735/LendingConfig.cdc"
// Swap
import SwapConfig from "../0xb78ef7afa52ff906/SwapConfig.cdc"
import SwapInterfaces from "../0xb78ef7afa52ff906/SwapInterfaces.cdc"
// Liquid Staking
import LiquidStaking from "../0xd6f80565193ad727/LiquidStaking.cdc"
// Farm
import Staking from "../0x1b77ba4b414de352/Staking.cdc"
// Oracle
import PublicPriceOracle from "../0xec67451f8a58216a/PublicPriceOracle.cdc"


pub contract IncrementPointsV1 {
    
    access(all) var _totalSupply: UFix64
    access(self) let _balances: {Address: UFix64}
    access(self) let _blackList: {Address: UFix64}

    access(self) let _mintPointPerDayFactor: {String: UFix64}
    // 黑名单
    access(self) fun mintPoint(targetAddr: Address, amount: UFix64) {
        // mint points
        if self._balances.containsKey(targetAddr) == false {
            self._balances[targetAddr] = 0.0
        }
        self._balances[targetAddr] = self._balances[targetAddr]! + amount
        
        // referral boost
        let refereeAddr: Address = 0x00
        let refereeAmount: UFix64 = 0.0
        if self._balances.containsKey(targetAddr) == false {
            self._balances[refereeAddr] = 0.0
        }
    
        // update total supply
        self._totalSupply = self._totalSupply + amount + refereeAmount;
    }

    //access(self) let _leaderBoard: [AnyStruct]

    access(self) let _userStates: {Address: {String: UFix64}}

    access(self) let _secondsPerDay: UFix64

    /// Events
    pub event PointsMinted(userAddr: Address, amount: UFix64, source: String, param: String)
    pub event PointsBurned(userAddr: Address, amount: UFix64)
    pub event StateUpdated(userAddr: Address, state: {String: UFix64})

    
    access(all) fun updateUserState(userAddr: Address) {
        if self._userStates.containsKey(userAddr) == false {
            self._userStates[userAddr] = {
                "LastMintTimestamp": 0.0,
                "LendingTotalSupplyInUsd": 0.0,
                "LendingTotalBorrowInUsd": 0.0
            }
        }

        //
        let lastMintTimestamp = self._userStates[userAddr]!["LastMintTimestamp"]!
        let currMintTimestamp = getCurrentBlock().timestamp

        // Mint Points
        if lastMintTimestamp != 0.0 && currMintTimestamp - lastMintTimestamp > 0.0 {
            let duration = currMintTimestamp - lastMintTimestamp
            var amountToMint = 0.0
            // Lending Points
            let currTotalSupplyAmountInUsd = self._userStates[userAddr]!["LendingTotalSupplyInUsd"]!
            let currTotalBorrowAmountInUsd = self._userStates[userAddr]!["LendingTotalBorrowInUsd"]!
            let mintAmountByLendingSupply = currTotalSupplyAmountInUsd * self._mintPointPerDayFactor["LendingSupply"]! / self._secondsPerDay
            let mintAmountbyLendingBorrow = currTotalBorrowAmountInUsd * self._mintPointPerDayFactor["LendingBorrow"]! / self._secondsPerDay
            if mintAmountByLendingSupply > 0.0 {
                emit PointsMinted(userAddr: userAddr, amount: mintAmountByLendingSupply, source: "LendingSupply", param: "SupplyUsdValue:".concat(currTotalSupplyAmountInUsd.toString()).concat(" Seconds:".concat(duration.toString())))
            }
            if mintAmountbyLendingBorrow > 0.0 {
                emit PointsMinted(userAddr: userAddr, amount: mintAmountbyLendingBorrow, source: "LendingBorrow", param: "BorrowUsdValue:".concat(currTotalBorrowAmountInUsd.toString()).concat(" Seconds:".concat(duration.toString())))
            }

            // Mint
            let mintAmount = mintAmountByLendingSupply + mintAmountbyLendingBorrow
            if (mintAmount > 0.0) {
                self.mintPoint(targetAddr: userAddr, amount: mintAmount)
            }

        }
        self._userStates[userAddr]!.insert(key: "LastMintTimestamp", currMintTimestamp)

        // Update Oracle Price
        let oraclePrices: {String: UFix64} = { // OracleAddress -> Token Price
            "Flow": PublicPriceOracle.getLatestPrice(oracleAddr: 0xe385412159992e11),
            "stFlow": PublicPriceOracle.getLatestPrice(oracleAddr: 0x031dabc5ba1d2932),
            "USDC": PublicPriceOracle.getLatestPrice(oracleAddr: 0x031dabc5ba1d2932)
        }
  
        // Update Lending State
        // Lending
        let lendingComptrollerRef = getAccount(0xf80cb737bfe7c792).getCapability<&{LendingInterfaces.ComptrollerPublic}>(LendingConfig.ComptrollerPublicPath).borrow()!
        let marketAddrs: [Address] = lendingComptrollerRef.getAllMarkets()
        let lendingOracleRef = getAccount(0x72d3a05910b6ffa3).getCapability<&{LendingInterfaces.OraclePublic}>(LendingConfig.OraclePublicPath).borrow()!
        var totalSupplyAmountInUsd = 0.0
        var totalBorrowAmountInUsd = 0.0
        for poolAddr in marketAddrs {
            let poolRef = lendingComptrollerRef.getPoolPublicRef(poolAddr: poolAddr)
            let poolOraclePrice = lendingOracleRef.getUnderlyingPrice(pool: poolAddr)
            let res: [UInt256; 5] = poolRef.getAccountRealtimeScaled(account: userAddr)
            let supplyAmount = SwapConfig.ScaledUInt256ToUFix64(res[0] * res[1] / SwapConfig.scaleFactor)
            let borrowAmount = SwapConfig.ScaledUInt256ToUFix64(res[2])
            totalSupplyAmountInUsd = totalSupplyAmountInUsd + supplyAmount * poolOraclePrice
            totalBorrowAmountInUsd = totalBorrowAmountInUsd + borrowAmount * poolOraclePrice
        }
        self._userStates[userAddr]!.insert(key: "LendingTotalSupplyInUsd", totalSupplyAmountInUsd)
        self._userStates[userAddr]!.insert(key: "LendingTotalBorrowInUsd", totalBorrowAmountInUsd)

        //
        emit StateUpdated(userAddr: userAddr, state: self._userStates[userAddr]!)
    }

    access(self) let _reservedFields: {String: AnyStruct}

    /// Admin
    ///
    pub resource Admin {
    }

    init() {
        self._totalSupply = 0.0
        self._secondsPerDay = 86400.0
        self._balances = {}
        self._mintPointPerDayFactor = {
            "LendingSupply": 0.1,
            "LendingBorrow": 0.3
        }

        self._userStates = {}
        self._blackList = {}

        self._reservedFields = {}

        destroy <-self.account.load<@AnyResource>(from: /storage/pointsAdmin)
        self.account.save(<-create Admin(), to: /storage/pointsAdmin)
    }
}
