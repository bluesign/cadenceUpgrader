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
    // TODO snapshot POINTS
    access(self) let _balancesHistorySnapshot: {Address: UFix64}

    access(all) var _totalSupply: UFix64
    access(self) let _balances: {Address: UFix64}
    access(self) let _blackList: {Address: UFix64}

    access(self) let _swapPoolWhitelist: {Address: Bool} // {PoolAddress}

    // 为方便扩展和修改，采用 dict 方式存储
    // 当前的 rate 如下:
    /* {
            "LendingSupply": {
                0.0         : 0.001,  //   0.0     ~ 1000.0  -> 0.001
                1000.0      : 0.002,  //   1000.0  ~ 10000.0 -> 0.002
                10000.0     : 0.003   //   10000.0 ~ Max     -> 0.003
            }
        }
    */
    access(self) let _pointsRatePerDay: {String: AnyStruct}

    // TODO 黑名单 只是 0 不能让tx失败
    access(self) fun mintPoints(targetAddr: Address, amount: UFix64) {
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

    // 用于统计 Swap Volume 的锁
    access(self) var _swapPoolAddress: Address
    access(self) var _swapVolumeTrackingTimestamp: UFix64
    access(self) var _swapPoolReserve0: UFix64
    access(self) var _swapPoolReserve1: UFix64
    

    access(self) let _reservedFields: {String: AnyStruct}

    /// Events
    access(all) event PointsMinted(userAddr: Address, amount: UFix64, source: String, param: {String: String})
    access(all) event PointsBurned(userAddr: Address, amount: UFix64)
    access(all) event StateUpdated(userAddr: Address, state: {String: UFix64})
    access(all) event PointsRateChanged(source: String, ori: UFix64, new: UFix64)
    access(all) event PointsTierRateChanged(source: String, ori: {UFix64: UFix64}, new: {UFix64: UFix64})

    
    access(all) fun updateUserState(userAddr: Address) {
        //
        let lastMintTimestamp = self._userStates.containsKey(userAddr)? self._userStates[userAddr]!["LastMintTimestamp"]! : 0.0
        let currMintTimestamp = getCurrentBlock().timestamp

        // Mint Points
        if lastMintTimestamp != 0.0 && currMintTimestamp - lastMintTimestamp > 0.0 {
            let duration = currMintTimestamp - lastMintTimestamp
            let timeRate = duration
            var amountToMint = 0.0
            // Lending Points
            let currTotalSupplyAmountInUsd = self._userStates[userAddr]!["LendingTotalSupplyInUsd"]!
            let currTotalBorrowAmountInUsd = self._userStates[userAddr]!["LendingTotalBorrowInUsd"]!
            let mintAmountByLendingSupply = currTotalSupplyAmountInUsd * self.getPointsRatePerDay_LendingSupply(amount: currTotalSupplyAmountInUsd) / self._secondsPerDay * timeRate
            let mintAmountbyLendingBorrow = currTotalBorrowAmountInUsd * self.getPointsRatePerDay_LendingBorrow(amount: currTotalBorrowAmountInUsd) / self._secondsPerDay * timeRate
            if mintAmountByLendingSupply > 0.0 {
                emit PointsMinted(userAddr: userAddr, amount: mintAmountByLendingSupply, source: "LendingSupply", param: {"SupplyUsdValue": currTotalSupplyAmountInUsd.toString(), "Duration": duration.toString()})
            }
            if mintAmountbyLendingBorrow > 0.0 {
                emit PointsMinted(userAddr: userAddr, amount: mintAmountbyLendingBorrow, source: "LendingBorrow", param: {"SupplyUsdValue": currTotalBorrowAmountInUsd.toString(), "Duration": duration.toString()})
            }

            // Mint
            let mintAmount = mintAmountByLendingSupply + mintAmountbyLendingBorrow
            if (mintAmount > 0.0) {
                self.mintPoints(targetAddr: userAddr, amount: mintAmount)
            }

        }
        

        // Update Oracle Price
        let oraclePrices: {String: UFix64} = { // OracleAddress -> Token Price
            "Flow": PublicPriceOracle.getLatestPrice(oracleAddr: 0xe385412159992e11),
            "stFlow": PublicPriceOracle.getLatestPrice(oracleAddr: 0x031dabc5ba1d2932),
            "USDC": PublicPriceOracle.getLatestPrice(oracleAddr: 0xf5d12412c09d2470)
        }
  
        // Lending State
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

        // Liquid Staking State


        // 

        // Update State
        if self._userStates.containsKey(userAddr) 
            || totalSupplyAmountInUsd > 0.0 || totalBorrowAmountInUsd > 0.0 {
            if self._userStates.containsKey(userAddr) == false {
                self._userStates[userAddr] = {
                    "LastMintTimestamp": 0.0,
                    "LendingTotalSupplyInUsd": 0.0,
                    "LendingTotalBorrowInUsd": 0.0
                }
            }

            self._userStates[userAddr]!.insert(key: "LendingTotalSupplyInUsd", totalSupplyAmountInUsd)
            self._userStates[userAddr]!.insert(key: "LendingTotalBorrowInUsd", totalBorrowAmountInUsd)

            self._userStates[userAddr]!.insert(key: "LastMintTimestamp", currMintTimestamp)

            //
            emit StateUpdated(userAddr: userAddr, state: self._userStates[userAddr]!)
        }

    }

    access(all) fun beginVolumeTracking(swapPoolAddr: Address) {
        // 判断是否是Increment的池子
        if self._swapPoolWhitelist.containsKey(swapPoolAddr) == false { return }

        let poolInfo: [AnyStruct] = getAccount(swapPoolAddr).getCapability<&{SwapInterfaces.PairPublic}>(SwapConfig.PairPublicPath).borrow()!.getPairInfo()
        self._swapPoolReserve0 = poolInfo[2] as! UFix64
        self._swapPoolReserve1 = poolInfo[3] as! UFix64

        self._swapVolumeTrackingTimestamp = getCurrentBlock().timestamp
        self._swapPoolAddress = swapPoolAddr
    }

    access(all) fun endVolumeTrackingAndMintPoints(userAddr: Address) {
        if self._swapVolumeTrackingTimestamp != getCurrentBlock().timestamp {
            return
        }
        self._swapVolumeTrackingTimestamp = 0.0

        let poolInfo: [AnyStruct] = getAccount(self._swapPoolAddress).getCapability<&{SwapInterfaces.PairPublic}>(SwapConfig.PairPublicPath).borrow()!.getPairInfo()
        let reserve0Token = poolInfo[0] as! String
        let reserve1Token = poolInfo[1] as! String
        let curReserve0 = poolInfo[2] as! UFix64
        let curReserve1 = poolInfo[3] as! UFix64

        // Add/Remove Lp won't mint any points
        if curReserve0 >= self._swapPoolReserve0 && curReserve1 >= self._swapPoolReserve1 { return }
        if curReserve0 <= self._swapPoolReserve0 && curReserve1 <= self._swapPoolReserve1 { return }
        var amountIn = 0.0
        var amountOut = 0.0
        var tokenInKey = ""
        var tokenOutKey = ""
        // Swap A to B
        if curReserve0 > self._swapPoolReserve0 && curReserve1 < self._swapPoolReserve1 {
            amountIn = curReserve0 - self._swapPoolReserve0
            tokenInKey = reserve0Token
            amountOut = self._swapPoolReserve1 - curReserve1
            tokenOutKey = reserve1Token
        }
        // Swap B to A
        if curReserve0 < self._swapPoolReserve0 && curReserve1 > self._swapPoolReserve1 {
            amountIn = curReserve1 - self._swapPoolReserve1
            tokenInKey = reserve1Token
            amountOut = self._swapPoolReserve0 - curReserve0
            tokenOutKey = reserve0Token
        }

        // Cal volume
        let usdcPrice = PublicPriceOracle.getLatestPrice(oracleAddr: 0xf5d12412c09d2470)
        let flowPrice = PublicPriceOracle.getLatestPrice(oracleAddr: 0xe385412159992e11)
        let stflowPrice = PublicPriceOracle.getLatestPrice(oracleAddr: 0x031dabc5ba1d2932)
        var volumeUsd = 0.0
        if tokenInKey == "A.b19436aae4d94622.FiatToken" { volumeUsd = amountIn * usdcPrice }
        else if tokenInKey == "A.1654653399040a61.FlowToken" { volumeUsd = amountIn * flowPrice }
        else if tokenInKey == "A.d6f80565193ad727.stFlowToken" { volumeUsd = amountIn * stflowPrice }
        else if tokenOutKey == "A.b19436aae4d94622.FiatToken" { volumeUsd = amountOut * usdcPrice }
        else if tokenOutKey == "A.1654653399040a61.FlowToken" { volumeUsd = amountOut * flowPrice }
        else if tokenOutKey == "A.d6f80565193ad727.stFlowToken" { volumeUsd = amountOut * stflowPrice }

        // Mint points
        let mintAmountBySwapVolume = volumeUsd * self.getPointsRatePerDay_SwapVolume()
        if mintAmountBySwapVolume > 0.0 {
            emit PointsMinted(userAddr: userAddr, amount: mintAmountBySwapVolume, source: "SwapVolume", param: {"TokenInKey": tokenInKey, "TokenOutKey": tokenOutKey, "AmountIn": amountIn.toString(), "AmountOut": amountOut.toString(), "VolumeUsd": volumeUsd.toString()})
            self.mintPoints(targetAddr: userAddr, amount: mintAmountBySwapVolume)
        }
    }

    // 计算符合条件的Lp的Price
    // 符合条件：包含Flow, stFlow, USDC，并且tvl > 2k
    access(all) fun calValidLpPrice(pairInfo: [AnyStruct], oraclePrices: {String: UFix64}): UFix64 {
        // TODO 或者命中白名单

        var reserveAmount = 0.0
        var reservePrice = 0.0
        var lpPrice = 0.0
        if pairInfo[0] as! String == "A.b19436aae4d94622.FiatToken" {reserveAmount = pairInfo[2] as! UFix64; reservePrice = oraclePrices["USDC"]!}
        else if pairInfo[1] as! String == "A.b19436aae4d94622.FiatToken" {reserveAmount = pairInfo[3] as! UFix64; reservePrice = oraclePrices["USDC"]!}
        else if pairInfo[0] as! String == "A.1654653399040a61.FlowToken" {reserveAmount = pairInfo[2] as! UFix64; reservePrice = oraclePrices["Flow"]!}
        else if pairInfo[1] as! String == "A.1654653399040a61.FlowToken" {reserveAmount = pairInfo[3] as! UFix64; reservePrice = oraclePrices["Flow"]!}
        else if pairInfo[0] as! String == "A.d6f80565193ad727.stFlowToken" {reserveAmount = pairInfo[2] as! UFix64; reservePrice = oraclePrices["stFlow"]!}
        else if pairInfo[1] as! String == "A.d6f80565193ad727.stFlowToken" {reserveAmount = pairInfo[3] as! UFix64; reservePrice = oraclePrices["stFlow"]!}
        if reservePrice > 0.0 && reserveAmount > 1000.0 {
            lpPrice = reserveAmount * reservePrice * 2.0 / (pairInfo[5] as! UFix64)
        }
        return lpPrice
    }
    pub fun type2address(_ type: String) : Address {
        let address = type.slice(from: 2, upTo: 18)
        var r: UInt64 = 0
        var bytes = address.decodeHex()
        while bytes.length>0{
            r = r  + (UInt64(bytes.removeFirst()) << UInt64(bytes.length*8))
        }
        return Address(r)
    }

    access(all) fun getSwapPoolWhiltlist(): {Address: Bool} { return self._swapPoolWhitelist }

    access(all) fun getPointsRatePerDay_LiquidStaking(amount: UFix64): UFix64 {
        return self.calculateTierRateByAmount(amount: amount, tier: self._pointsRatePerDay["LiquidStaking"]! as! {UFix64: UFix64})
    }
    access(all) fun getPointsRatePerDay_LendingSupply(amount: UFix64): UFix64 {
        return self.calculateTierRateByAmount(amount: amount, tier: self._pointsRatePerDay["LendingSupply"]! as! {UFix64: UFix64})
    }
    access(all) fun getPointsRatePerDay_LendingBorrow(amount: UFix64): UFix64 {
        return self.calculateTierRateByAmount(amount: amount, tier: self._pointsRatePerDay["LendingBorrow"]! as! {UFix64: UFix64})
    }
    access(all) fun getPointsRatePerDay_SwapLP(): UFix64 { return self._pointsRatePerDay["SwapLP"]! as! UFix64 }
    access(all) fun getPointsRatePerDay_SwapVolume(): UFix64 { return self._pointsRatePerDay["SwapVolume"]! as! UFix64 }

    access(all) fun calculateTierRateByAmount(amount: UFix64, tier: {UFix64: UFix64}): UFix64 {
        var rate = 0.0
        var maxThreshold = 0.0
        for threshold in tier.keys {
            if amount >= threshold && threshold >= maxThreshold {
                rate = tier[threshold]!
                maxThreshold = threshold
            }
        }
        return rate
    }

    /// Admin
    ///
    access(all) resource Admin {
        access(all) fun setPointsRatePerDay_LiquidStakingTier(tierRate: {UFix64: UFix64}) {
            emit PointsTierRateChanged(source: "LiquidStaking", ori: IncrementPointsV1._pointsRatePerDay["LiquidStaking"]! as! {UFix64: UFix64}, new: tierRate)
            IncrementPointsV1._pointsRatePerDay["LiquidStaking"] = tierRate
        }
        access(all) fun setPointsRatePerDay_LendingSupplyTier(tierRate: {UFix64: UFix64}) {
            emit PointsTierRateChanged(source: "LendingSupply", ori: IncrementPointsV1._pointsRatePerDay["LendingSupply"]! as! {UFix64: UFix64}, new: tierRate)
            IncrementPointsV1._pointsRatePerDay["LendingSupply"] = tierRate
        }
        access(all) fun setPointsRatePerDay_LendingBorrowTier(tierRate: {UFix64: UFix64}) {
            emit PointsTierRateChanged(source: "LendingBorrow", ori: IncrementPointsV1._pointsRatePerDay["LendingBorrow"]! as! {UFix64: UFix64}, new: tierRate)
            IncrementPointsV1._pointsRatePerDay["LendingBorrow"] = tierRate
        }
        access(all) fun setPointsRatePerDay_SwapLP(rate: UFix64) {
            emit PointsRateChanged(source: "SwapLP", ori: IncrementPointsV1._pointsRatePerDay["SwapLP"]! as! UFix64, new: rate)
            IncrementPointsV1._pointsRatePerDay["SwapLP"] = rate
        }
        access(all) fun setPointsRatePerDay_SwapVolume(rate: UFix64) {
            emit PointsRateChanged(source: "SwapVolume", ori: IncrementPointsV1._pointsRatePerDay["SwapVolume"]! as! UFix64, new: rate)
            IncrementPointsV1._pointsRatePerDay["SwapVolume"] = rate
        }

        // Add Swap Pool in Whiltelist
        access(all) fun addSwapPoolInWhiltelist(poolAddr: Address) {
            IncrementPointsV1._swapPoolWhitelist[poolAddr] = true
        }
        // Remove Swap Pool in Whitelist
        access(all) fun removeSwapPoolInWhiltelist(poolAddr: Address) {
            IncrementPointsV1._swapPoolWhitelist.remove(key: poolAddr)
        }
    }

    init() {
        self._totalSupply = 0.0
        self._secondsPerDay = 86400.0
        self._balances = {}
        self._balancesHistorySnapshot = {}
        self._pointsRatePerDay = {
            "LiquidStaking": {
                0.0:        0.001,
                1000.0:     0.002,
                10000.0:    0.003
            },
            "LendingSupply": {
                0.0:        0.001,
                1000.0:     0.002,
                10000.0:    0.003
            },
            "LendingBorrow": {
                0.0:        0.002,
                1000.0:     0.004,
                10000.0:    0.006
            },
            "SwapLP": 0.01,
            "SwapVolume": 1.0
        }
        self._swapPoolWhitelist = {
            0xfa82796435e15832: true, // FLOW-USDC
            0xcc96d987317f0342: true, // FLOW-ceWETH
            0x09c49abce2a7385c: true, // FLOW-ceWBTC
            0x396c0cda3302d8c5: true, // FLOW-stFLOW v1
            0xc353b9d685ec427d: true, // FLOW-stFLOW stable
            0xa06c38beec9cf0e8: true, // FLOW-DUST
            0xbfb26bb8adf90399: true  // FLOW-SLOPPY
        }

        self._userStates = {}
        self._blackList = {}

        self._swapPoolAddress = 0x00
        self._swapVolumeTrackingTimestamp = 0.0
        self._swapPoolReserve0 = 0.0
        self._swapPoolReserve1 = 0.0
        

        self._reservedFields = {}

        destroy <-self.account.load<@AnyResource>(from: /storage/pointsAdmin1)
        self.account.save(<-create Admin(), to: /storage/pointsAdmin1)
    }
}
