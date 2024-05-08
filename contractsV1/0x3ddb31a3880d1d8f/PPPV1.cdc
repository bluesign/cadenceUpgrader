/**

# 

*/

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

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

access(all)
contract PPPV1{ 
	
	//
	access(all)
	var _totalSupply: UFix64
	
	//
	access(self)
	let _balances:{ Address: UFix64}
	
	// 
	access(self)
	let _balancesHistorySnapshot:{ Address: UFix64}
	
	// 在黑名单里的地址，不会再有积分累计，积分暂时不会清零
	access(self)
	let _userBlacklist:{ Address: Bool}
	
	// 
	access(self)
	let _swapPoolWhitelist:{ Address: Bool} // {PoolAddress}
	
	
	// 为方便扩展和修改，采用 dict 方式存储
	// 当前的 rate 如下:
	/* {
				"LendingSupply": {
					0.0		 : 0.001,  //   0.0	 ~ 1000.0  -> 0.001
					1000.0	  : 0.002,  //   1000.0  ~ 10000.0 -> 0.002
					10000.0	 : 0.003   //   10000.0 ~ Max	 -> 0.003
				}
			}
		*/
	
	access(self)
	let _pointsRatePerDay:{ String: AnyStruct}
	
	//access(self) let _leaderBoard: [AnyStruct]
	access(self)
	let _userStates:{ Address:{ String: UFix64}}
	
	access(self)
	let _secondsPerDay: UFix64
	
	// 用于统计 Swap Volume 的锁
	access(self)
	var _swapPoolAddress: Address
	
	access(self)
	var _swapVolumeTrackingTimestamp: UFix64
	
	access(self)
	var _swapPoolReserve0: UFix64
	
	access(self)
	var _swapPoolReserve1: UFix64
	
	access(self)
	let _reservedFields:{ String: AnyStruct}
	
	/// Events
	access(all)
	event PointsMinted(userAddr: Address, amount: UFix64, source: String, param:{ String: String})
	
	access(all)
	event PointsBurned(userAddr: Address, amount: UFix64, source: String, param:{ String: String})
	
	access(all)
	event StateUpdated(userAddr: Address, state:{ String: UFix64})
	
	access(all)
	event PointsRateChanged(source: String, ori: UFix64, new: UFix64)
	
	access(all)
	event PointsTierRateChanged(source: String, ori:{ UFix64: UFix64}, new:{ UFix64: UFix64})
	
	//
	access(all)
	view fun balanceOf(_ userAddr: Address): UFix64{ 
		return (self._balances.containsKey(userAddr) ? self._balances[userAddr]! : 0.0)
		+ (self._balancesHistorySnapshot.containsKey(userAddr) ? self._balances[userAddr]! : 0.0)
	}
	
	// 估算当前实时的points数量
	access(all)
	view fun balanceOfRealTime(_ userAddr: Address): UFix64{ 
		return self.balanceOf(userAddr) // base points
		
		+ self.calculateNewPointsSinceLastUpdate(userAddr: userAddr) as! UFix64 // accured points
	
	}
	
	// Mint Points
	access(self)
	fun _mint(targetAddr: Address, amount: UFix64){ 
		if self._userBlacklist.containsKey(targetAddr){ 
			return
		}
		
		// mint points
		if self._balances.containsKey(targetAddr) == false{ 
			self._balances[targetAddr] = 0.0
		}
		self._balances[targetAddr] = self._balances[targetAddr]! + amount
		
		// referral boost
		let refereeAddr: Address = 0x00
		let refereeAmount: UFix64 = 0.0
		if self._balances.containsKey(targetAddr) == false{ 
			self._balances[refereeAddr] = 0.0
		}
		
		// update total supply
		self._totalSupply = self._totalSupply + amount + refereeAmount
	}
	
	// 
	access(all)
	view fun calculateNewPointsSinceLastUpdate(userAddr: Address): AnyStruct{ 
		let lastUpdateTimestamp = self.getUserState_LastUpdateTimestamp(userAddr: userAddr)
		if lastUpdateTimestamp == 0.0{ 
			return 0.0
		}
		
		// Lending Supply
		let accuredLendingSupplyPoints =
			self.calculateNewPointsSinceLastUpdate_LendingSupply(userAddr: userAddr)
		// Lending Borrow
		let accuredLendingBorrowPoints =
			self.calculateNewPointsSinceLastUpdate_LendingBorrow(userAddr: userAddr)
		// stFlow Holdings
		let accuredStFlowHoldingPoints =
			self.calculateNewPointsSinceLastUpdate_stFlowHolding(userAddr: userAddr)
		// Swap LP
		let accuredSwapLPPoints = self.calculateNewPointsSinceLastUpdate_SwapLP(userAddr: userAddr)
		return accuredLendingSupplyPoints + accuredLendingBorrowPoints + accuredStFlowHoldingPoints
	}
	
	access(all)
	fun updateUserState(userAddr: Address){ 
		if self._userBlacklist.containsKey(userAddr){ 
			return
		}
		let lastUpdateTimestamp = self.getUserState_LastUpdateTimestamp(userAddr: userAddr)
		let duration = getCurrentBlock().timestamp - lastUpdateTimestamp
		let durationStr = duration.toString()
		if duration > 0.0{ 
			// Lending Supply
			let accuredLendingSupplyPoints = self.calculateNewPointsSinceLastUpdate_LendingSupply(userAddr: userAddr)
			if accuredLendingSupplyPoints > 0.0{ 
				emit PointsMinted(userAddr: userAddr, amount: accuredLendingSupplyPoints, source: "LendingSupply", param:{ "SupplyUsdValue": self.getUserState_LendingSupply(userAddr: userAddr).toString(), "Duration": durationStr})
			}
			
			// Lending Borrow
			let accuredLendingBorrowPoints = self.calculateNewPointsSinceLastUpdate_LendingBorrow(userAddr: userAddr)
			if accuredLendingBorrowPoints > 0.0{ 
				emit PointsMinted(userAddr: userAddr, amount: accuredLendingBorrowPoints, source: "LendingBorrow", param:{ "BorrowUsdValue": self.getUserState_LendingBorrow(userAddr: userAddr).toString(), "Duration": durationStr})
			}
			
			// stFlow Holding
			let accuredStFlowHoldingPoints = self.calculateNewPointsSinceLastUpdate_stFlowHolding(userAddr: userAddr)
			if accuredStFlowHoldingPoints > 0.0{ 
				emit PointsMinted(userAddr: userAddr, amount: accuredStFlowHoldingPoints, source: "stFlowHolding", param:{ "stFlowHoldingBalance": self.getUserState_stFlowHolding(userAddr: userAddr).toString(), "Duration": durationStr})
			}
			
			// Swap LP
			let accuredSwapLPPoints = self.calculateNewPointsSinceLastUpdate_SwapLP(userAddr: userAddr)
			if accuredSwapLPPoints > 0.0{ 
				emit PointsMinted(userAddr: userAddr, amount: accuredSwapLPPoints, source: "SwapLP", param:{ "SwapLPUsdValue": self.getUserState_SwapLP(userAddr: userAddr).toString(), "Duration": durationStr})
			}
			
			// Mint Points
			let accuredPointsToMint = accuredLendingSupplyPoints + accuredLendingBorrowPoints + accuredStFlowHoldingPoints + accuredSwapLPPoints
			if accuredPointsToMint > 0.0{ 
				self._mint(targetAddr: userAddr, amount: accuredPointsToMint)
			}
		}
		
		// Update Oracle Price
		let oraclePrices:{ String: UFix64} ={ // OracleAddress -> Token Price
			
				
				"Flow": PublicPriceOracle.getLatestPrice(oracleAddr: 0xe385412159992e11),
				"stFlow": PublicPriceOracle.getLatestPrice(oracleAddr: 0x031dabc5ba1d2932),
				"USDC": PublicPriceOracle.getLatestPrice(oracleAddr: 0xf5d12412c09d2470)
			}
		
		// Lending State
		let lendingComptrollerRef =
			getAccount(0xf80cb737bfe7c792).capabilities.get<&{LendingInterfaces.ComptrollerPublic}>(
				LendingConfig.ComptrollerPublicPath
			).borrow()!
		let marketAddrs: [Address] = lendingComptrollerRef.getAllMarkets()
		let lendingOracleRef =
			getAccount(0x72d3a05910b6ffa3).capabilities.get<&{LendingInterfaces.OraclePublic}>(
				LendingConfig.OraclePublicPath
			).borrow()!
		var totalSupplyAmountInUsd = 0.0
		var totalBorrowAmountInUsd = 0.0
		for poolAddr in marketAddrs{ 
			let poolRef = lendingComptrollerRef.getPoolPublicRef(poolAddr: poolAddr)
			let poolOraclePrice = lendingOracleRef.getUnderlyingPrice(pool: poolAddr)
			let res: [UInt256; 5] = poolRef.getAccountRealtimeScaled(account: userAddr)
		}
		
		// Liquid Staking State
		// stFlow
		var stFlowTotalBalance = 0.0
		let stFlowVaultCap =
			getAccount(userAddr).capabilities.get<&{FungibleToken.Balance}>(
				/public/stFlowTokenBalance
			)
		if stFlowVaultCap.check(){ 
			stFlowTotalBalance = (stFlowVaultCap.borrow()!).balance
		}
		
		// Swap LP in Balance
		let lpPrices:{ Address: UFix64} ={} 
		var totalLpBalanceUsd = 0.0
		let lpTokenCollectionCap =
			getAccount(userAddr).capabilities.get<&{SwapInterfaces.LpTokenCollectionPublic}>(
				SwapConfig.LpTokenCollectionPublicPath
			)
		if lpTokenCollectionCap.check(){ 
			let lpTokenCollectionRef = lpTokenCollectionCap.borrow()!
			let liquidityPairAddrs = lpTokenCollectionRef.getAllLPTokens()
			for pairAddr in liquidityPairAddrs{ 
				// 
				if self._swapPoolWhitelist.containsKey(pairAddr) == false{ 
					continue
				}
				var lpTokenAmount = lpTokenCollectionRef.getLpTokenBalance(pairAddr: pairAddr)
				let pairInfo = (getAccount(pairAddr).capabilities.get<&{SwapInterfaces.PairPublic}>(/public/increment_swap_pair).borrow()!).getPairInfo()
				// Cal lp price
				var lpPrice = 0.0
				if lpPrices.containsKey(pairAddr){ 
					lpPrice = lpPrices[pairAddr]!
				} else{ 
					lpPrice = self.calValidLpPrice(pairInfo: pairInfo, oraclePrices: oraclePrices)
					lpPrices[pairAddr] = lpPrice
				}
				if lpPrice == 0.0 || lpTokenAmount == 0.0{ 
					continue
				}
				totalLpBalanceUsd = totalLpBalanceUsd + lpPrice * lpTokenAmount
			}
		}
		
		// Swap LP in Farm & stFlow in Farm
		let farmCollectionRef =
			getAccount(0x1b77ba4b414de352).capabilities.get<&{Staking.PoolCollectionPublic}>(
				Staking.CollectionPublicPath
			).borrow()!
		let userFarmIds = Staking.getUserStakingIds(address: userAddr)
		for farmPoolId in userFarmIds{ 
			let farmPool = farmCollectionRef.getPool(pid: farmPoolId)
			let farmPoolInfo = farmPool.getPoolInfo()
			let userInfo = farmPool.getUserInfo(address: userAddr)!
			if farmPoolInfo.status == "0" || farmPoolInfo.status == "1" || farmPoolInfo.status == "2"{ 
				let acceptTokenKey = farmPoolInfo.acceptTokenKey
				let acceptTokenName = acceptTokenKey.slice(from: 19, upTo: acceptTokenKey.length)
				let userFarmAmount = userInfo.stakingAmount
				// add stFlow holding balance
				if acceptTokenKey == "A.d6f80565193ad727.stFlowToken"{ 
					stFlowTotalBalance = stFlowTotalBalance + userFarmAmount
					continue
				}
				if userFarmAmount == 0.0{ 
					continue
				}
				// add lp holding balance
				let swapPoolAddress = self.type2address(acceptTokenKey)
				if acceptTokenName == "SwapPair"{ 
					let swapPoolInfo = (getAccount(swapPoolAddress).capabilities.get<&{SwapInterfaces.PairPublic}>(SwapConfig.PairPublicPath).borrow()!).getPairInfo()
					var lpPrice = 0.0
					if lpPrices.containsKey(swapPoolAddress){ 
						lpPrice = lpPrices[swapPoolAddress]!
					} else{ 
						lpPrice = self.calValidLpPrice(pairInfo: swapPoolInfo, oraclePrices: oraclePrices)
						lpPrices[swapPoolAddress] = lpPrice
					}
					totalLpBalanceUsd = totalLpBalanceUsd + userFarmAmount * lpPrice
				}
			}
		}
		
		// Update State
		if self._userStates.containsKey(userAddr) || totalSupplyAmountInUsd > 0.0
		|| totalBorrowAmountInUsd > 0.0
		|| stFlowTotalBalance > 0.0
		|| totalLpBalanceUsd > 0.0{ 
			if self._userStates.containsKey(userAddr) == false{ 
				self._userStates[userAddr] ={} 
			}
			self.setUserState_LendingSupply(
				userAddr: userAddr,
				supplyAmount: totalSupplyAmountInUsd
			)
			self.setUserState_LendingBorrow(
				userAddr: userAddr,
				borrowAmount: totalBorrowAmountInUsd
			)
			self.setUserState_stFlowHolding(userAddr: userAddr, stFlowBalance: stFlowTotalBalance)
			self.setUserState_SwapLP(userAddr: userAddr, lpAmount: totalLpBalanceUsd)
			self.setUserState_LastUpdateTimestamp(
				userAddr: userAddr,
				timestamp: getCurrentBlock().timestamp
			)
			
			//
			emit StateUpdated(userAddr: userAddr, state: self._userStates[userAddr]!)
		}
	}
	
	access(all)
	fun beginVolumeTracking(swapPoolAddr: Address){ 
		// 判断是否是Increment的池子
		if self._swapPoolWhitelist.containsKey(swapPoolAddr) == false{ 
			return
		}
		let poolInfo: [AnyStruct] =
			(
				getAccount(swapPoolAddr).capabilities.get<&{SwapInterfaces.PairPublic}>(
					SwapConfig.PairPublicPath
				).borrow()!
			).getPairInfo()
		self._swapPoolReserve0 = poolInfo[2] as! UFix64
		self._swapPoolReserve1 = poolInfo[3] as! UFix64
		self._swapVolumeTrackingTimestamp = getCurrentBlock().timestamp
		self._swapPoolAddress = swapPoolAddr
	}
	
	access(all)
	fun endVolumeTrackingAndMintPoints(userAddr: Address){ 
		if self._swapVolumeTrackingTimestamp != getCurrentBlock().timestamp{ 
			return
		}
		self._swapVolumeTrackingTimestamp = 0.0
		if self._userBlacklist.containsKey(userAddr){ 
			return
		}
		let poolInfo: [AnyStruct] =
			(
				getAccount(self._swapPoolAddress).capabilities.get<&{SwapInterfaces.PairPublic}>(
					SwapConfig.PairPublicPath
				).borrow()!
			).getPairInfo()
		let reserve0Token = poolInfo[0] as! String
		let reserve1Token = poolInfo[1] as! String
		let curReserve0 = poolInfo[2] as! UFix64
		let curReserve1 = poolInfo[3] as! UFix64
		
		// Add/Remove Lp won't mint any points
		if curReserve0 >= self._swapPoolReserve0 && curReserve1 >= self._swapPoolReserve1{ 
			return
		}
		if curReserve0 <= self._swapPoolReserve0 && curReserve1 <= self._swapPoolReserve1{ 
			return
		}
		var amountIn = 0.0
		var amountOut = 0.0
		var tokenInKey = ""
		var tokenOutKey = ""
		// Swap A to B
		if curReserve0 > self._swapPoolReserve0 && curReserve1 < self._swapPoolReserve1{ 
			amountIn = curReserve0 - self._swapPoolReserve0
			tokenInKey = reserve0Token
			amountOut = self._swapPoolReserve1 - curReserve1
			tokenOutKey = reserve1Token
		}
		// Swap B to A
		if curReserve0 < self._swapPoolReserve0 && curReserve1 > self._swapPoolReserve1{ 
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
		if tokenInKey == "A.b19436aae4d94622.FiatToken"{ 
			volumeUsd = amountIn * usdcPrice
		} else if tokenInKey == "A.1654653399040a61.FlowToken"{ 
			volumeUsd = amountIn * flowPrice
		} else if tokenInKey == "A.d6f80565193ad727.stFlowToken"{ 
			volumeUsd = amountIn * stflowPrice
		} else if tokenOutKey == "A.b19436aae4d94622.FiatToken"{ 
			volumeUsd = amountOut * usdcPrice
		} else if tokenOutKey == "A.1654653399040a61.FlowToken"{ 
			volumeUsd = amountOut * flowPrice
		} else if tokenOutKey == "A.d6f80565193ad727.stFlowToken"{ 
			volumeUsd = amountOut * stflowPrice
		}
		
		// Mint points
		let mintAmountBySwapVolume = volumeUsd * self.getPointsRatePerDay_SwapVolume()
		if mintAmountBySwapVolume > 0.0{ 
			emit PointsMinted(userAddr: userAddr, amount: mintAmountBySwapVolume, source: "SwapVolume", param:{ "TokenInKey": tokenInKey, "TokenOutKey": tokenOutKey, "AmountIn": amountIn.toString(), "AmountOut": amountOut.toString(), "VolumeUsd": volumeUsd.toString()})
			self._mint(targetAddr: userAddr, amount: mintAmountBySwapVolume)
		}
	}
	
	access(all)
	view fun getBalanceLength(): Int{ 
		return self._balances.length
	}
	
	access(all)
	view fun getSlicedBalances(from: UInt64, to: UInt64):{ Address: UFix64}{ 
		let len = UInt64(self._balances.length)
		let endIndex = to >= len ? len - 1 : to
		var curIndex = from
		let res:{ Address: UFix64} ={} 
		while curIndex <= endIndex{ 
			let key: Address = self._balances.keys[curIndex]
			res[key] = self.balanceOfRealTime(key)
			curIndex = curIndex + 1
		}
		return res
	}
	
	// Accure Lending Supply
	access(all)
	view fun calculateNewPointsSinceLastUpdate_LendingSupply(userAddr: Address): UFix64{ 
		let lastUpdateTimestamp = self.getUserState_LastUpdateTimestamp(userAddr: userAddr)
		var accuredPoints = 0.0
		if lastUpdateTimestamp == 0.0{ 
			return 0.0
		}
		let currUpdateTimestamp = getCurrentBlock().timestamp
		let duration = currUpdateTimestamp - lastUpdateTimestamp
		if duration > 0.0{ 
			let supplyAmountUsd = self.getUserState_LendingSupply(userAddr: userAddr)
			accuredPoints = supplyAmountUsd * self.getPointsRatePerDay_LendingSupply(amount: supplyAmountUsd) / self._secondsPerDay * duration
		}
		return accuredPoints
	}
	
	// Accure Lending Borrow
	access(all)
	view fun calculateNewPointsSinceLastUpdate_LendingBorrow(userAddr: Address): UFix64{ 
		let lastUpdateTimestamp = self.getUserState_LastUpdateTimestamp(userAddr: userAddr)
		var accuredPoints = 0.0
		if lastUpdateTimestamp == 0.0{ 
			return 0.0
		}
		let currUpdateTimestamp = getCurrentBlock().timestamp
		let duration = currUpdateTimestamp - lastUpdateTimestamp
		if duration > 0.0{ 
			let borrowAmountUsd = self.getUserState_LendingBorrow(userAddr: userAddr)
			accuredPoints = borrowAmountUsd * self.getPointsRatePerDay_LendingBorrow(amount: borrowAmountUsd) / self._secondsPerDay * duration
		}
		return accuredPoints
	}
	
	// Accure Liquid Staking - stFlowHolding
	access(self)
	view fun calculateNewPointsSinceLastUpdate_stFlowHolding(userAddr: Address): UFix64{ 
		let lastUpdateTimestamp = self.getUserState_LastUpdateTimestamp(userAddr: userAddr)
		var accuredPoints = 0.0
		if lastUpdateTimestamp == 0.0{ 
			return 0.0
		}
		let currUpdateTimestamp = getCurrentBlock().timestamp
		let duration = currUpdateTimestamp - lastUpdateTimestamp
		if duration > 0.0{ 
			let stFlowHolding = self.getUserState_stFlowHolding(userAddr: userAddr)
			accuredPoints = stFlowHolding * self.getPointsRatePerDay_stFlowHolding(amount: stFlowHolding) / self._secondsPerDay * duration
		}
		return accuredPoints
	}
	
	// Accure Swap LP
	access(self)
	view fun calculateNewPointsSinceLastUpdate_SwapLP(userAddr: Address): UFix64{ 
		let lastUpdateTimestamp = self.getUserState_LastUpdateTimestamp(userAddr: userAddr)
		var accuredPoints = 0.0
		if lastUpdateTimestamp == 0.0{ 
			return 0.0
		}
		let currUpdateTimestamp = getCurrentBlock().timestamp
		let duration = currUpdateTimestamp - lastUpdateTimestamp
		if duration > 0.0{ 
			let swapLP = self.getUserState_SwapLP(userAddr: userAddr)
			accuredPoints = swapLP * self.getPointsRatePerDay_SwapLP(amount: swapLP) / self._secondsPerDay * duration
		}
		return accuredPoints
	}
	
	access(all)
	view fun getSwapPoolWhiltlist():{ Address: Bool}{ 
		return self._swapPoolWhitelist
	}
	
	access(all)
	view fun getUserBlacklist():{ Address: Bool}{ 
		return self._userBlacklist
	}
	
	// Get Points Rate
	access(all)
	view fun getPointsRatePerDay_LendingSupply(amount: UFix64): UFix64{ 
		return self.calculateTierRateByAmount(
			amount: amount,
			tier: self._pointsRatePerDay["LendingSupply"]! as!{ UFix64: UFix64}
		)
	}
	
	access(all)
	view fun getPointsRatePerDay_LendingBorrow(amount: UFix64): UFix64{ 
		return self.calculateTierRateByAmount(
			amount: amount,
			tier: self._pointsRatePerDay["LendingBorrow"]! as!{ UFix64: UFix64}
		)
	}
	
	access(all)
	view fun getPointsRatePerDay_stFlowHolding(amount: UFix64): UFix64{ 
		return self.calculateTierRateByAmount(
			amount: amount,
			tier: self._pointsRatePerDay["stFlowHolding"]! as!{ UFix64: UFix64}
		)
	}
	
	access(all)
	view fun getPointsRatePerDay_SwapLP(amount: UFix64): UFix64{ 
		return self.calculateTierRateByAmount(
			amount: amount,
			tier: self._pointsRatePerDay["SwapLP"]! as!{ UFix64: UFix64}
		)
	}
	
	access(all)
	view fun getPointsRatePerDay_SwapVolume(): UFix64{ 
		return self._pointsRatePerDay["SwapVolume"]! as! UFix64
	}
	
	// Get User State
	access(all)
	view fun getUserState_LastUpdateTimestamp(userAddr: Address): UFix64{ 
		return self._userStates.containsKey(userAddr)
			? (
					(self._userStates[userAddr]!).containsKey("LastUpdateTimestamp")
						? (self._userStates[userAddr]!)["LastUpdateTimestamp"]!
						: 0.0
				)
			: 0.0
	}
	
	access(all)
	view fun getUserState_LendingSupply(userAddr: Address): UFix64{ 
		return (self._userStates[userAddr]!).containsKey("LendingTotalSupplyUsd")
			? (self._userStates[userAddr]!)["LendingTotalSupplyUsd"]!
			: 0.0
	}
	
	access(all)
	view fun getUserState_LendingBorrow(userAddr: Address): UFix64{ 
		return (self._userStates[userAddr]!).containsKey("LendingTotalBorrowUsd")
			? (self._userStates[userAddr]!)["LendingTotalBorrowUsd"]!
			: 0.0
	}
	
	access(all)
	view fun getUserState_stFlowHolding(userAddr: Address): UFix64{ 
		return (self._userStates[userAddr]!).containsKey("stFlowHolding")
			? (self._userStates[userAddr]!)["stFlowHolding"]!
			: 0.0
	}
	
	access(all)
	view fun getUserState_SwapLP(userAddr: Address): UFix64{ 
		return (self._userStates[userAddr]!).containsKey("SwapLpUsd")
			? (self._userStates[userAddr]!)["SwapLpUsd"]!
			: 0.0
	}
	
	access(self)
	fun setUserState_LastUpdateTimestamp(userAddr: Address, timestamp: UFix64){ 
		(self._userStates[userAddr]!).insert(key: "LastUpdateTimestamp", timestamp)
	}
	
	access(self)
	fun setUserState_LendingSupply(userAddr: Address, supplyAmount: UFix64){ 
		(self._userStates[userAddr]!).insert(key: "LendingTotalSupplyUsd", supplyAmount)
	}
	
	access(self)
	fun setUserState_LendingBorrow(userAddr: Address, borrowAmount: UFix64){ 
		(self._userStates[userAddr]!).insert(key: "LendingTotalBorrowUsd", borrowAmount)
	}
	
	access(self)
	fun setUserState_stFlowHolding(userAddr: Address, stFlowBalance: UFix64){ 
		(self._userStates[userAddr]!).insert(key: "stFlowHolding", stFlowBalance)
	}
	
	access(self)
	fun setUserState_SwapLP(userAddr: Address, lpAmount: UFix64){ 
		(self._userStates[userAddr]!).insert(key: "SwapLpUsd", lpAmount)
	}
	
	access(all)
	view fun calculateTierRateByAmount(amount: UFix64, tier:{ UFix64: UFix64}): UFix64{ 
		var rate = 0.0
		var maxThreshold = 0.0
		for threshold in tier.keys{ 
			if amount >= threshold && threshold >= maxThreshold{ 
				rate = tier[threshold]!
				maxThreshold = threshold
			}
		}
		return rate
	}
	
	// 计算符合条件的Lp的Price
	// 符合条件：包含Flow, stFlow, USDC，并且tvl > 2k
	access(all)
	view fun calValidLpPrice(pairInfo: [AnyStruct], oraclePrices:{ String: UFix64}): UFix64{ 
		var reserveAmount = 0.0
		var reservePrice = 0.0
		var lpPrice = 0.0
		if pairInfo[0] as! String == "A.b19436aae4d94622.FiatToken"{ 
			reserveAmount = pairInfo[2] as! UFix64
			reservePrice = oraclePrices["USDC"]!
		} else if pairInfo[1] as! String == "A.b19436aae4d94622.FiatToken"{ 
			reserveAmount = pairInfo[3] as! UFix64
			reservePrice = oraclePrices["USDC"]!
		} else if pairInfo[0] as! String == "A.1654653399040a61.FlowToken"{ 
			reserveAmount = pairInfo[2] as! UFix64
			reservePrice = oraclePrices["Flow"]!
		} else if pairInfo[1] as! String == "A.1654653399040a61.FlowToken"{ 
			reserveAmount = pairInfo[3] as! UFix64
			reservePrice = oraclePrices["Flow"]!
		} else if pairInfo[0] as! String == "A.d6f80565193ad727.stFlowToken"{ 
			reserveAmount = pairInfo[2] as! UFix64
			reservePrice = oraclePrices["stFlow"]!
		} else if pairInfo[1] as! String == "A.d6f80565193ad727.stFlowToken"{ 
			reserveAmount = pairInfo[3] as! UFix64
			reservePrice = oraclePrices["stFlow"]!
		}
		if reservePrice > 0.0 && reserveAmount > 1000.0{ 
			lpPrice = reserveAmount * reservePrice * 2.0 / pairInfo[5] as! UFix64
		}
		return lpPrice
	}
	
	access(all)
	view fun type2address(_ type: String): Address{ 
		let address = type.slice(from: 2, upTo: 18)
		var r: UInt64 = 0
		var bytes = address.decodeHex()
		while bytes.length > 0{ 
			r = r + (UInt64(bytes.removeFirst()) << UInt64(bytes.length * 8))
		}
		return Address(r)
	}
	
	/// Admin
	///
	access(all)
	resource Admin{ 
		// Set Points Rate
		access(all)
		fun setPointsRatePerDay_stFlowHoldingTier(tierRate:{ UFix64: UFix64}){ 
			emit PointsTierRateChanged(
				source: "stFlowHolding",
				ori: PPPV1._pointsRatePerDay["stFlowHolding"]! as!{ UFix64: UFix64},
				new: tierRate
			)
			PPPV1._pointsRatePerDay["stFlowHolding"] = tierRate
		}
		
		access(all)
		fun setPointsRatePerDay_LendingSupplyTier(tierRate:{ UFix64: UFix64}){ 
			emit PointsTierRateChanged(
				source: "LendingSupply",
				ori: PPPV1._pointsRatePerDay["LendingSupply"]! as!{ UFix64: UFix64},
				new: tierRate
			)
			PPPV1._pointsRatePerDay["LendingSupply"] = tierRate
		}
		
		access(all)
		fun setPointsRatePerDay_LendingBorrowTier(tierRate:{ UFix64: UFix64}){ 
			emit PointsTierRateChanged(
				source: "LendingBorrow",
				ori: PPPV1._pointsRatePerDay["LendingBorrow"]! as!{ UFix64: UFix64},
				new: tierRate
			)
			PPPV1._pointsRatePerDay["LendingBorrow"] = tierRate
		}
		
		access(all)
		fun setPointsRatePerDay_SwapLPTier(tierRate:{ UFix64: UFix64}){ 
			emit PointsTierRateChanged(
				source: "SwapLP",
				ori: PPPV1._pointsRatePerDay["SwapLP"]! as!{ UFix64: UFix64},
				new: tierRate
			)
			PPPV1._pointsRatePerDay["SwapLP"] = tierRate
		}
		
		access(all)
		fun setPointsRatePerDay_SwapVolume(rate: UFix64){ 
			emit PointsRateChanged(
				source: "SwapVolume",
				ori: PPPV1._pointsRatePerDay["SwapVolume"]! as! UFix64,
				new: rate
			)
			PPPV1._pointsRatePerDay["SwapVolume"] = rate
		}
		
		// Add Swap Pool in Whiltelist
		access(all)
		fun addSwapPoolInWhiltelist(poolAddr: Address){ 
			PPPV1._swapPoolWhitelist[poolAddr] = true
		}
		
		// Remove Swap Pool in Whitelist
		access(all)
		fun removeSwapPoolInWhiltelist(poolAddr: Address){ 
			PPPV1._swapPoolWhitelist.remove(key: poolAddr)
		}
		
		// Set history snapshot points
		access(all)
		fun setHistorySnapshotPointsBalance(userAddr: Address, newSnapshotBalance: UFix64){ 
			if PPPV1._balancesHistorySnapshot.containsKey(userAddr) == false{ 
				PPPV1._balancesHistorySnapshot[userAddr] = 0.0
			}
			if PPPV1._balances.containsKey(userAddr) == false{ 
				PPPV1._balances[userAddr] = 0.0
			}
			let preSnapshotBalance = PPPV1._balancesHistorySnapshot[userAddr]!
			if preSnapshotBalance == newSnapshotBalance{ 
				return
			}
			if preSnapshotBalance < newSnapshotBalance{ 
				emit PointsMinted(userAddr: userAddr, amount: newSnapshotBalance - preSnapshotBalance, source: "HistorySnapshot", param:{ "PreBalance": preSnapshotBalance.toString(), "NewBalance": newSnapshotBalance.toString()})
			} else{ 
				emit PointsBurned(userAddr: userAddr, amount: preSnapshotBalance - newSnapshotBalance, source: "HistorySnapshot", param:{ "PreBalance": preSnapshotBalance.toString(), "NewBalance": newSnapshotBalance.toString()})
			}
			PPPV1._totalSupply = PPPV1._totalSupply - preSnapshotBalance + newSnapshotBalance
			PPPV1._balancesHistorySnapshot[userAddr] = newSnapshotBalance
		}
		
		// Ban user
		access(all)
		fun addUserBlackList(userAddr: Address){ 
			PPPV1._userBlacklist[userAddr] = true
		}
		
		access(all)
		fun removeUserBlackList(userAddr: Address){ 
			PPPV1._userBlacklist.remove(key: userAddr)
		}
		
		access(all)
		fun reconcilePoints(userAddr: Address, newBalance: UFix64){ 
			// TODO process referrel points
			if PPPV1._balances.containsKey(userAddr) == false{ 
				PPPV1._balances[userAddr] = 0.0
			}
			let preBalance = PPPV1._balances[userAddr]!
			if preBalance == newBalance{ 
				return
			}
			if preBalance < newBalance{ 
				emit PointsMinted(userAddr: userAddr, amount: newBalance - preBalance, source: "Reconcile", param:{ "PreBalance": preBalance.toString(), "NewBalance": newBalance.toString()})
			} else{ 
				emit PointsBurned(userAddr: userAddr, amount: preBalance - newBalance, source: "Reconcile", param:{ "PreBalance": preBalance.toString(), "NewBalance": newBalance.toString()})
			}
			PPPV1._totalSupply = PPPV1._totalSupply - preBalance + newBalance
			PPPV1._balancesHistorySnapshot[userAddr] = newBalance
		}
	}
	
	init(){ 
		self._totalSupply = 0.0
		self._secondsPerDay = 86400.0
		self._balances ={} 
		self._balancesHistorySnapshot ={} 
		self._pointsRatePerDay ={ 
				"stFlowHolding":{ 0.0: 1.0, 1000.0: 2.0, 10000.0: 3.0},
				"LendingSupply":{ 0.0: 0.001, 1000.0: 0.002, 10000.0: 0.003},
				"LendingBorrow":{ 0.0: 0.002, 1000.0: 0.004, 10000.0: 0.006},
				"SwapLP":{ 0.0: 1.0, 1000.0: 2.0, 10000.0: 3.0},
				"SwapVolume": 5.0
			}
		self._swapPoolWhitelist ={ 
				0xfa82796435e15832: true, // FLOW-USDC
				
				0xcc96d987317f0342: true, // FLOW-ceWETH
				
				0x09c49abce2a7385c: true, // FLOW-ceWBTC
				
				0x396c0cda3302d8c5: true, // FLOW-stFLOW v1
				
				0xc353b9d685ec427d: true, // FLOW-stFLOW stable
				
				0xa06c38beec9cf0e8: true, // FLOW-DUST
				
				0xbfb26bb8adf90399: true // FLOW-SLOPPY
			
			}
		self._userStates ={} 
		self._userBlacklist ={} 
		self._swapPoolAddress = 0x00
		self._swapVolumeTrackingTimestamp = 0.0
		self._swapPoolReserve0 = 0.0
		self._swapPoolReserve1 = 0.0
		self._reservedFields ={} 
		destroy <-self.account.storage.load<@AnyResource>(from: /storage/pointsAdmin1)
		self.account.storage.save(<-create Admin(), to: /storage/pointsAdmin1)
	}
}
