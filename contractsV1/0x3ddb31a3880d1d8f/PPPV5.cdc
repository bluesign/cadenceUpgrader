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

import StakingNFT from "../0x1b77ba4b414de352/StakingNFT.cdc"

import FLOAT from "../0x2d4c3caffbeab845/FLOAT.cdc"

// Oracle
import PublicPriceOracle from "../0xec67451f8a58216a/PublicPriceOracle.cdc"

import RV3 from "./RV3.cdc"

access(all)
contract PPPV5{ 
	
	// 
	access(all)
	var _totalSupply: UFix64
	
	//
	access(self)
	let _pointsBase:{ Address: UFix64}
	
	// 
	access(self)
	let _pointsHistorySnapshot:{ Address: UFix64}
	
	// {Referrer: TotalPointsFromReferees}
	access(self)
	let _totalPointsAsReferrer:{ Address: UFix64}
	
	// {Referrer: {Referee: PointsFrom}}
	access(self)
	let _pointsFromReferees:{ Address:{ Address: UFix64}}
	
	//
	access(self)
	let _pointsAsReferee:{ Address: UFix64}
	
	//
	access(self)
	let _pointsAsCoreMember:{ Address: UFix64}
	
	//
	access(self)
	let _userBlacklist:{ Address: Bool}
	
	// 
	access(self)
	let _swapPoolWhitelist:{ Address: Bool}
	
	/* {
				"LendingSupply": {
					0.0		 : 0.001,  //   0.0	 ~ 1000.0  -> 0.001
					1000.0	  : 0.002,  //   1000.0  ~ 10000.0 -> 0.002
					10000.0	 : 0.003   //   10000.0 ~ Max	 -> 0.003
				}
			}
		*/
	
	access(self)
	let _pointsRate:{ String: AnyStruct}
	
	access(self)
	let _userStates:{ Address:{ String: UFix64}}
	
	access(self)
	let _ifClaimHistorySnapshot:{ Address: Bool}
	
	access(self)
	let _secondsPerPointsRateSession: UFix64
	
	// 
	access(self)
	var _swapPoolAddress: Address
	
	access(self)
	var _swapVolumeTrackingTimestamp: UFix64
	
	access(self)
	var _swapPoolReserve0: UFix64
	
	access(self)
	var _swapPoolReserve1: UFix64
	
	access(self)
	var _topUsers: [Address]
	
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
	
	access(all)
	event ClaimSnapshotPoints(userAddr: Address, amount: UFix64)
	
	access(all)
	event TopUsersChanged(ori: [Address], new: [Address])
	
	access(all)
	event SetSnapshotPoints(userAddr: Address, _pre: UFix64, new: UFix64)
	
	// 
	access(all)
	view fun balanceOf(_ userAddr: Address): UFix64{ 
		return self.getBasePoints(userAddr)
		+ (self.ifClaimHistorySnapshot(userAddr) ? self.getHistorySnapshotPoints(userAddr) : 0.0)
		+ self.getPointsAsReferrer(userAddr)
		+ self.getPointsAsReferee(userAddr)
		+ self.getPointsAsCoreMember(userAddr)
		+ self.calculateNewPointsSinceLastUpdate(userAddr: userAddr) as! UFix64 // accured points
	
	}
	
	// Mint Points
	access(self)
	fun _mint(targetAddr: Address, amount: UFix64){ 
		if self._userBlacklist.containsKey(targetAddr){ 
			return
		}
		
		// mint points
		if self._pointsBase.containsKey(targetAddr) == false{ 
			self._pointsBase[targetAddr] = 0.0
		}
		self._pointsBase[targetAddr] = self._pointsBase[targetAddr]! + amount
		let referrerAddr: Address? = RV3.getReferrerByReferee(referee: targetAddr)
		if referrerAddr != nil{ 
			// referee boost
			let boostAmountAsReferee = amount * self.getPointsRate_RefereeUp()
			if boostAmountAsReferee > 0.0{ 
				if self._pointsAsReferee.containsKey(targetAddr) == false{ 
					self._pointsAsReferee[targetAddr] = boostAmountAsReferee
				} else{ 
					self._pointsAsReferee[targetAddr] = self._pointsAsReferee[targetAddr]! + boostAmountAsReferee
				}
				emit PointsMinted(userAddr: targetAddr, amount: boostAmountAsReferee, source: "AsReferee", param:{} )
				self._totalSupply = self._totalSupply + boostAmountAsReferee
			}
			
			// referrer boost
			let boostAmountForReferrer = amount * self.getPointsRate_ReferrerUp()
			if boostAmountForReferrer > 0.0 && self._userBlacklist.containsKey(referrerAddr!) == false{ 
				if self._totalPointsAsReferrer.containsKey(referrerAddr!) == false{ 
					self._totalPointsAsReferrer[referrerAddr!] = boostAmountForReferrer
				} else{ 
					self._totalPointsAsReferrer[referrerAddr!] = self._totalPointsAsReferrer[referrerAddr!]! + boostAmountForReferrer
				}
				if self._pointsFromReferees.containsKey(referrerAddr!) == false{ 
					self._pointsFromReferees[referrerAddr!] ={} 
				}
				if (self._pointsFromReferees[referrerAddr!]!).containsKey(targetAddr) == false{ 
					(self._pointsFromReferees[referrerAddr!]!).insert(key: targetAddr, boostAmountForReferrer)
				} else{ 
					(self._pointsFromReferees[referrerAddr!]!).insert(key: targetAddr, (self._pointsFromReferees[referrerAddr!]!)[targetAddr]! + boostAmountForReferrer)
				}
				if self._pointsBase.containsKey(referrerAddr!) == false{ 
					self._pointsBase[referrerAddr!] = 0.0
				}
				emit PointsMinted(userAddr: referrerAddr!, amount: boostAmountForReferrer, source: "AsReferrer", param:{} )
				self._totalSupply = self._totalSupply + boostAmountForReferrer
			}
		}
		
		// core member boost
		if self.isCoreMember(targetAddr){ 
			let boostAmountAsCoreMember = amount * self.getPointsRate_CoreMember()
			if boostAmountAsCoreMember > 0.0{ 
				if self._pointsAsCoreMember.containsKey(targetAddr) == false{ 
					self._pointsAsCoreMember[targetAddr] = boostAmountAsCoreMember
				} else{ 
					self._pointsAsCoreMember[targetAddr] = self._pointsAsCoreMember[targetAddr]! + boostAmountAsCoreMember
				}
				emit PointsMinted(userAddr: targetAddr, amount: boostAmountAsCoreMember, source: "AsCoreMember", param:{} )
				self._totalSupply = self._totalSupply + boostAmountAsCoreMember
			}
		}
		
		// update total supply
		self._totalSupply = self._totalSupply + amount
	}
	
	// 
	access(all)
	view fun calculateNewPointsSinceLastUpdate(userAddr: Address): AnyStruct{ 
		let lastUpdateTimestamp = self.getUserState_LastUpdateTimestamp(userAddr: userAddr)
		if lastUpdateTimestamp == 0.0{ 
			return 0.0
		}
		if self._userBlacklist.containsKey(userAddr){ 
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
		return (
			accuredLendingSupplyPoints + accuredLendingBorrowPoints + accuredStFlowHoldingPoints
			+ accuredSwapLPPoints
		)
		* (1.0 + self.getBasePointsBoostRate(userAddr))
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
				emit PointsMinted(userAddr: userAddr, amount: accuredSwapLPPoints, source: "SwapLP", param:{ "SwapLPUsdValue": self.getUserState_SwapLPUsd(userAddr: userAddr).toString(), "Duration": durationStr})
			}
			
			// Mint Points
			let accuredPointsToMint = accuredLendingSupplyPoints + accuredLendingBorrowPoints + accuredStFlowHoldingPoints + accuredSwapLPPoints
			if accuredPointsToMint > 0.0{ 
				self._mint(targetAddr: userAddr, amount: accuredPointsToMint)
			}
		}
		
		//
		let states = self.fetchOnchainUserStates(userAddr: userAddr)
		let totalSupplyAmountInUsd = states[0]
		let totalBorrowAmountInUsd = states[1]
		let stFlowTotalBalance = states[2]
		let totalLpBalanceUsd = states[3]
		let totalLpAmount = states[4]
		
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
			self.setUserState_SwapLPUsd(userAddr: userAddr, lpUsd: totalLpBalanceUsd)
			self.setUserState_SwapLPAmount(userAddr: userAddr, lpAmount: totalLpAmount)
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
		let mintAmountBySwapVolume = volumeUsd * self.getPointsRate_SwapVolume(amount: volumeUsd)
		if mintAmountBySwapVolume > 0.0{ 
			emit PointsMinted(userAddr: userAddr, amount: mintAmountBySwapVolume, source: "SwapVolume", param:{ "TokenInKey": tokenInKey, "TokenOutKey": tokenOutKey, "AmountIn": amountIn.toString(), "AmountOut": amountOut.toString(), "VolumeUsd": volumeUsd.toString()})
			self._mint(targetAddr: userAddr, amount: mintAmountBySwapVolume)
			if self._userStates.containsKey(userAddr) == false{ 
				self._userStates[userAddr] ={} 
			}
			self.setUserState_SwapVolume(userAddr: userAddr, volume: self.getUserState_SwapVolume(userAddr: userAddr) + volumeUsd)
			emit StateUpdated(userAddr: userAddr, state: self._userStates[userAddr]!)
		}
	}
	
	access(all)
	fun claimSnapshotPoints(
		userCertificateCap: Capability<&{LendingInterfaces.IdentityCertificate}>
	){ 
		let userAddr: Address = ((userCertificateCap.borrow()!).owner!).address
		assert(self.getHistorySnapshotPoints(userAddr) > 0.0, message: "Nothing to claim")
		self._ifClaimHistorySnapshot[userAddr] = true
		emit ClaimSnapshotPoints(
			userAddr: userAddr,
			amount: self.getHistorySnapshotPoints(userAddr)
		)
	}
	
	access(all)
	view fun getBasePointsLength(): Int{ 
		return self._pointsBase.length
	}
	
	access(all)
	view fun getSlicedBasePointsAddrs(from: Int, to: Int): [Address]{ 
		let len = self._userStates.length
		let endIndex = to > len ? len : to
		var curIndex = from
		return self._pointsBase.keys.slice(from: from, upTo: to)
	}
	
	access(all)
	view fun getBasePoints(_ userAddr: Address): UFix64{ 
		return self._pointsBase.containsKey(userAddr) ? self._pointsBase[userAddr]! : 0.0
	}
	
	access(all)
	view fun getHistorySnapshotPoints(_ userAddr: Address): UFix64{ 
		return self._pointsHistorySnapshot.containsKey(userAddr)
			? self._pointsHistorySnapshot[userAddr]!
			: 0.0
	}
	
	access(all)
	view fun getPointsAsReferrer(_ userAddr: Address): UFix64{ 
		return self._totalPointsAsReferrer.containsKey(userAddr)
			? self._totalPointsAsReferrer[userAddr]!
			: 0.0
	}
	
	access(all)
	view fun getPointsAsReferee(_ userAddr: Address): UFix64{ 
		return self._pointsAsReferee.containsKey(userAddr) ? self._pointsAsReferee[userAddr]! : 0.0
	}
	
	access(all)
	view fun getPointsAsCoreMember(_ userAddr: Address): UFix64{ 
		return self._pointsAsCoreMember.containsKey(userAddr)
			? self._pointsAsCoreMember[userAddr]!
			: 0.0
	}
	
	access(all)
	view fun getPointsAndTimestamp(_ userAddr: Address): [UFix64; 3]{ 
		return [
			self.balanceOf(userAddr),
			self.getPointsAsReferrer(userAddr),
			self.getUserState_LastUpdateTimestamp(userAddr: userAddr)
		]
	}
	
	access(all)
	view fun getUserInfo(_ userAddr: Address): [UFix64]{ 
		return [
			self.balanceOf(userAddr),
			self.getPointsAsReferrer(userAddr),
			self.getUserState_LastUpdateTimestamp(userAddr: userAddr),
			self.getUserState_LendingSupply(userAddr: userAddr),
			self.getUserState_LendingBorrow(userAddr: userAddr),
			self.getUserState_stFlowHolding(userAddr: userAddr),
			self.getUserState_SwapLPUsd(userAddr: userAddr),
			self.getUserState_SwapVolume(userAddr: userAddr)
		]
	}
	
	access(all)
	view fun getUserInfosLength(): Int{ 
		return self._userStates.length
	}
	
	access(all)
	view fun getSlicedUserInfos(from: Int, to: Int):{ Address: [UFix64]}{ 
		let len = self._userStates.length
		let endIndex = to > len ? len : to
		var curIndex = from
		let res:{ Address: [UFix64]} ={} 
		while curIndex < endIndex{ 
			let userAddr: Address = self._userStates.keys[curIndex]
			res[userAddr] = self.getUserInfo(userAddr)
			curIndex = curIndex + 1
		}
		return res
	}
	
	access(all)
	view fun fetchOnchainUserStates(userAddr: Address): [UFix64]{ 
		// Oracle Price
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
			let supplyAmount = SwapConfig.ScaledUInt256ToUFix64(res[0] * res[1] / SwapConfig.scaleFactor)
			let borrowAmount = SwapConfig.ScaledUInt256ToUFix64(res[2])
			totalSupplyAmountInUsd = totalSupplyAmountInUsd + supplyAmount * poolOraclePrice
			totalBorrowAmountInUsd = totalBorrowAmountInUsd + borrowAmount * poolOraclePrice
		}
		
		// Liquid Staking State
		// stFlow
		var stFlowTotalBalance = 0.0
		let stFlowVaultCap =
			getAccount(userAddr).capabilities.get<&{FungibleToken.Balance}>(
				/public/stFlowTokenBalance
			)
		if stFlowVaultCap.check(){ 
			// Prevent fake stFlow token vault
			if (stFlowVaultCap.borrow()!).getType().identifier == "A.d6f80565193ad727.stFlowToken.Vault"{ 
				stFlowTotalBalance = (stFlowVaultCap.borrow()!).balance
			}
		}
		
		// Swap LP in Balance
		let lpPrices:{ Address: UFix64} ={} 
		var totalLpBalanceUsd = 0.0
		var totalLpAmount = 0.0
		let lpTokenCollectionCap =
			getAccount(userAddr).capabilities.get<&{SwapInterfaces.LpTokenCollectionPublic}>(
				SwapConfig.LpTokenCollectionPublicPath
			)
		if lpTokenCollectionCap.check(){ 
			// Prevent fake lp token vault
			if (lpTokenCollectionCap.borrow()!).getType().identifier == "A.b063c16cac85dbd1.SwapFactory.LpTokenCollection"{ 
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
					totalLpAmount = totalLpAmount + lpTokenAmount
				}
			}
		}
		
		// Swap LP in Farm & stFlow in Farm
		// let farmCollectionRef = getAccount(0x1b77ba4b414de352).getCapability<&{Staking.PoolCollectionPublic}>(Staking.CollectionPublicPath).borrow()!
		// let userFarmIds = Staking.getUserStakingIds(address: userAddr)
		// for farmPoolId in userFarmIds {
		//	 let farmPool = farmCollectionRef.getPool(pid: farmPoolId)
		//	 let farmPoolInfo = farmPool.getPoolInfo()
		//	 let userInfo = farmPool.getUserInfo(address: userAddr)!
		//	 if farmPoolInfo.status == "0" || farmPoolInfo.status == "1" || farmPoolInfo.status == "2" {
		//		 let acceptTokenKey = farmPoolInfo.acceptTokenKey
		//		 let acceptTokenName = acceptTokenKey.slice(from: 19, upTo: acceptTokenKey.length)
		//		 let userFarmAmount = userInfo.stakingAmount
		//		 // add stFlow holding balance
		//		 if acceptTokenKey == "A.d6f80565193ad727.stFlowToken" {
		//			 stFlowTotalBalance = stFlowTotalBalance + userFarmAmount
		//			 continue
		//		 }
		//		 if userFarmAmount == 0.0 {
		//			 continue
		//		 }
		//		 // add lp holding balance
		//		 let swapPoolAddress = self.type2address(acceptTokenKey)
		//		 if acceptTokenName == "SwapPair" {
		//			 let swapPoolInfo = getAccount(swapPoolAddress).getCapability<&{SwapInterfaces.PairPublic}>(SwapConfig.PairPublicPath).borrow()!.getPairInfo()
		//			 var lpPrice = 0.0
		//			 if lpPrices.containsKey(swapPoolAddress) {
		//				 lpPrice = lpPrices[swapPoolAddress]!
		//			 } else {
		//				 lpPrice = self.calValidLpPrice(pairInfo: swapPoolInfo, oraclePrices: oraclePrices)
		//				 lpPrices[swapPoolAddress] = lpPrice
		//			 }
		//			 totalLpBalanceUsd = totalLpBalanceUsd + userFarmAmount * lpPrice
		//			 totalLpAmount = totalLpAmount + userFarmAmount
		//		 }
		//	 }
		// }
		return [
			totalSupplyAmountInUsd,
			totalBorrowAmountInUsd,
			stFlowTotalBalance,
			totalLpBalanceUsd,
			totalLpAmount
		]
	}
	
	access(all)
	view fun isCoreMember(_ userAddr: Address): Bool{ 
		let coreMemberEventID: UInt64 = 326723707
		let floatCollection =
			getAccount(userAddr).capabilities.get<&FLOAT.Collection>(
				FLOAT.FLOATCollectionPublicPath
			).borrow<&FLOAT.Collection>()
		if floatCollection == nil{ 
			return false
		}
		let nftID: [UInt64] = (floatCollection!).ownedIdsFromEvent(eventId: coreMemberEventID)
		if (floatCollection!).getType().identifier == "A.2d4c3caffbeab845.FLOAT.Collection"
		&& nftID.length > 0{ 
			return true
		}
		let poolCollectionCap =
			getAccount(StakingNFT.address).capabilities.get<&{StakingNFT.PoolCollectionPublic}>(
				StakingNFT.CollectionPublicPath
			).borrow()!
		let count = StakingNFT.poolCount
		var idx: UInt64 = 0
		while idx < count{ 
			let pool = poolCollectionCap.getPool(pid: idx)
			let poolExtraParams = pool.getExtraParams()
			if poolExtraParams.containsKey("eventId") && poolExtraParams["eventId"]! as! UInt64 == coreMemberEventID{ 
				let userInfo = pool.getUserInfo(address: userAddr)
				if userInfo != nil && (userInfo!).stakedNftIds.length > 0{ 
					return true
				}
			}
			idx = idx + 1
		}
		return false
	}
	
	access(all)
	view fun ifClaimHistorySnapshot(_ userAddr: Address): Bool{ 
		if self._ifClaimHistorySnapshot.containsKey(userAddr) == true{ 
			return self._ifClaimHistorySnapshot[userAddr]!
		}
		return false
	}
	
	access(all)
	view fun getBasePointsBoostRate(_ userAddr: Address): UFix64{ 
		let referrerAddr = RV3.getReferrerByReferee(referee: userAddr)
		return (self.isCoreMember(userAddr) ? self.getPointsRate_CoreMember() : 0.0)
		+ (referrerAddr != nil ? self.getPointsRate_RefereeUp() : 0.0)
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
			accuredPoints = supplyAmountUsd * self.getPointsRate_LendingSupply(amount: supplyAmountUsd) / self._secondsPerPointsRateSession * duration
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
			accuredPoints = borrowAmountUsd * self.getPointsRate_LendingBorrow(amount: borrowAmountUsd) / self._secondsPerPointsRateSession * duration
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
			accuredPoints = stFlowHolding * self.getPointsRate_stFlowHolding(amount: stFlowHolding) / self._secondsPerPointsRateSession * duration
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
			let swapLP = self.getUserState_SwapLPUsd(userAddr: userAddr)
			accuredPoints = swapLP * self.getPointsRate_SwapLP(amount: swapLP) / self._secondsPerPointsRateSession * duration
		}
		return accuredPoints
	}
	
	access(all)
	view fun getTopUsers(): [Address]{ 
		return self._topUsers
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
	view fun getPointsRate():{ String: AnyStruct}{ 
		return self._pointsRate
	}
	
	access(all)
	view fun getPointsRate_LendingSupply(amount: UFix64): UFix64{ 
		return self.calculateTierRateByAmount(
			amount: amount,
			tier: self._pointsRate["LendingSupply"]! as!{ UFix64: UFix64}
		)
	}
	
	access(all)
	view fun getPointsRate_LendingBorrow(amount: UFix64): UFix64{ 
		return self.calculateTierRateByAmount(
			amount: amount,
			tier: self._pointsRate["LendingBorrow"]! as!{ UFix64: UFix64}
		)
	}
	
	access(all)
	view fun getPointsRate_stFlowHolding(amount: UFix64): UFix64{ 
		return self.calculateTierRateByAmount(
			amount: amount,
			tier: self._pointsRate["stFlowHolding"]! as!{ UFix64: UFix64}
		)
	}
	
	access(all)
	view fun getPointsRate_SwapLP(amount: UFix64): UFix64{ 
		return self.calculateTierRateByAmount(
			amount: amount,
			tier: self._pointsRate["SwapLP"]! as!{ UFix64: UFix64}
		)
	}
	
	access(all)
	view fun getPointsRate_SwapVolume(amount: UFix64): UFix64{ 
		return self.calculateTierRateByAmount(
			amount: amount,
			tier: self._pointsRate["SwapVolume"]! as!{ UFix64: UFix64}
		)
	}
	
	access(all)
	view fun getPointsRate_ReferrerUp(): UFix64{ 
		return self._pointsRate["ReferrerUp"]! as! UFix64
	}
	
	access(all)
	view fun getPointsRate_RefereeUp(): UFix64{ 
		return self._pointsRate["RefereeUp"]! as! UFix64
	}
	
	access(all)
	view fun getPointsRate_CoreMember(): UFix64{ 
		return self._pointsRate["CoreMember"]! as! UFix64
	}
	
	// Get User State
	access(all)
	view fun getUserState(userAddr: Address):{ String: UFix64}{ 
		return self._userStates.containsKey(userAddr) ? self._userStates[userAddr]! :{} 
	}
	
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
		return self._userStates.containsKey(userAddr)
			? (
					(self._userStates[userAddr]!).containsKey("LendingTotalSupplyUsd")
						? (self._userStates[userAddr]!)["LendingTotalSupplyUsd"]!
						: 0.0
				)
			: 0.0
	}
	
	access(all)
	view fun getUserState_LendingBorrow(userAddr: Address): UFix64{ 
		return self._userStates.containsKey(userAddr)
			? (
					(self._userStates[userAddr]!).containsKey("LendingTotalBorrowUsd")
						? (self._userStates[userAddr]!)["LendingTotalBorrowUsd"]!
						: 0.0
				)
			: 0.0
	}
	
	access(all)
	view fun getUserState_stFlowHolding(userAddr: Address): UFix64{ 
		return self._userStates.containsKey(userAddr)
			? (
					(self._userStates[userAddr]!).containsKey("stFlowHolding")
						? (self._userStates[userAddr]!)["stFlowHolding"]!
						: 0.0
				)
			: 0.0
	}
	
	access(all)
	view fun getUserState_SwapLPUsd(userAddr: Address): UFix64{ 
		return self._userStates.containsKey(userAddr)
			? (
					(self._userStates[userAddr]!).containsKey("SwapLpUsd")
						? (self._userStates[userAddr]!)["SwapLpUsd"]!
						: 0.0
				)
			: 0.0
	}
	
	access(all)
	view fun getUserState_SwapLPAmount(userAddr: Address): UFix64{ 
		return self._userStates.containsKey(userAddr)
			? (
					(self._userStates[userAddr]!).containsKey("SwapLpAmount")
						? (self._userStates[userAddr]!)["SwapLpAmount"]!
						: 0.0
				)
			: 0.0
	}
	
	access(all)
	view fun getUserState_SwapVolume(userAddr: Address): UFix64{ 
		return self._userStates.containsKey(userAddr)
			? (
					(self._userStates[userAddr]!).containsKey("SwapVolumeUsd")
						? (self._userStates[userAddr]!)["SwapVolumeUsd"]!
						: 0.0
				)
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
	fun setUserState_SwapLPUsd(userAddr: Address, lpUsd: UFix64){ 
		(self._userStates[userAddr]!).insert(key: "SwapLpUsd", lpUsd)
	}
	
	access(self)
	fun setUserState_SwapLPAmount(userAddr: Address, lpAmount: UFix64){ 
		(self._userStates[userAddr]!).insert(key: "SwapLpAmount", lpAmount)
	}
	
	access(self)
	fun setUserState_SwapVolume(userAddr: Address, volume: UFix64){ 
		(self._userStates[userAddr]!).insert(key: "SwapVolumeUsd", volume)
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
		fun setPointsRate_stFlowHoldingTier(tierRate:{ UFix64: UFix64}){ 
			emit PointsTierRateChanged(
				source: "stFlowHolding",
				ori: PPPV5._pointsRate["stFlowHolding"]! as!{ UFix64: UFix64},
				new: tierRate
			)
			PPPV5._pointsRate["stFlowHolding"] = tierRate
		}
		
		access(all)
		fun setPointsRate_LendingSupplyTier(tierRate:{ UFix64: UFix64}){ 
			emit PointsTierRateChanged(
				source: "LendingSupply",
				ori: PPPV5._pointsRate["LendingSupply"]! as!{ UFix64: UFix64},
				new: tierRate
			)
			PPPV5._pointsRate["LendingSupply"] = tierRate
		}
		
		access(all)
		fun setPointsRate_LendingBorrowTier(tierRate:{ UFix64: UFix64}){ 
			emit PointsTierRateChanged(
				source: "LendingBorrow",
				ori: PPPV5._pointsRate["LendingBorrow"]! as!{ UFix64: UFix64},
				new: tierRate
			)
			PPPV5._pointsRate["LendingBorrow"] = tierRate
		}
		
		access(all)
		fun setPointsRate_SwapLPTier(tierRate:{ UFix64: UFix64}){ 
			emit PointsTierRateChanged(
				source: "SwapLP",
				ori: PPPV5._pointsRate["SwapLP"]! as!{ UFix64: UFix64},
				new: tierRate
			)
			PPPV5._pointsRate["SwapLP"] = tierRate
		}
		
		access(all)
		fun setPointsRate_SwapVolumeTier(tierRate:{ UFix64: UFix64}){ 
			emit PointsTierRateChanged(
				source: "SwapVolume",
				ori: PPPV5._pointsRate["SwapVolume"]! as!{ UFix64: UFix64},
				new: tierRate
			)
			PPPV5._pointsRate["SwapVolume"] = tierRate
		}
		
		access(all)
		fun setPointsRate_ReferrerUp(rate: UFix64){ 
			emit PointsRateChanged(
				source: "ReferrerUp",
				ori: PPPV5._pointsRate["ReferrerUp"]! as! UFix64,
				new: rate
			)
			PPPV5._pointsRate["ReferrerUp"] = rate
		}
		
		access(all)
		fun setPointsRate_RefereeUp(rate: UFix64){ 
			emit PointsRateChanged(
				source: "RefereeUp",
				ori: PPPV5._pointsRate["RefereeUp"]! as! UFix64,
				new: rate
			)
			PPPV5._pointsRate["RefereeUp"] = rate
		}
		
		access(all)
		fun setPointsRate_CoreMember(rate: UFix64){ 
			emit PointsRateChanged(
				source: "CoreMember",
				ori: PPPV5._pointsRate["CoreMember"]! as! UFix64,
				new: rate
			)
			PPPV5._pointsRate["CoreMember"] = rate
		}
		
		// Add Swap Pool in Whiltelist
		access(all)
		fun addSwapPoolInWhiltelist(poolAddr: Address){ 
			PPPV5._swapPoolWhitelist[poolAddr] = true
		}
		
		// Remove Swap Pool in Whitelist
		access(all)
		fun removeSwapPoolInWhiltelist(poolAddr: Address){ 
			PPPV5._swapPoolWhitelist.remove(key: poolAddr)
		}
		
		// Set history snapshot points
		access(all)
		fun setHistorySnapshotPoints(userAddr: Address, newSnapshotBalance: UFix64){ 
			if PPPV5._pointsHistorySnapshot.containsKey(userAddr) == false{ 
				PPPV5._pointsHistorySnapshot[userAddr] = 0.0
			}
			if PPPV5._pointsBase.containsKey(userAddr) == false{ 
				PPPV5._pointsBase[userAddr] = 0.0
			}
			let preSnapshotBalance = PPPV5._pointsHistorySnapshot[userAddr]!
			emit SetSnapshotPoints(
				userAddr: userAddr,
				_pre: preSnapshotBalance,
				new: newSnapshotBalance
			)
			if preSnapshotBalance == newSnapshotBalance{ 
				return
			}
			if preSnapshotBalance < newSnapshotBalance{ 
				emit PointsMinted(userAddr: userAddr, amount: newSnapshotBalance - preSnapshotBalance, source: "HistorySnapshot", param:{ "PreBalance": preSnapshotBalance.toString(), "NewBalance": newSnapshotBalance.toString()})
			} else{ 
				emit PointsBurned(userAddr: userAddr, amount: preSnapshotBalance - newSnapshotBalance, source: "HistorySnapshot", param:{ "PreBalance": preSnapshotBalance.toString(), "NewBalance": newSnapshotBalance.toString()})
			}
			PPPV5._totalSupply = PPPV5._totalSupply - preSnapshotBalance + newSnapshotBalance
			PPPV5._pointsHistorySnapshot[userAddr] = newSnapshotBalance
		}
		
		// Ban user
		access(all)
		fun addUserBlackList(userAddr: Address){ 
			PPPV5._userBlacklist[userAddr] = true
		}
		
		access(all)
		fun removeUserBlackList(userAddr: Address){ 
			PPPV5._userBlacklist.remove(key: userAddr)
		}
		
		access(all)
		fun reconcileBasePoints(userAddr: Address, newBasePoints: UFix64){ 
			// TODO process referral points
			if PPPV5._pointsBase.containsKey(userAddr) == false{ 
				PPPV5._pointsBase[userAddr] = 0.0
			}
			let preBasePoints = PPPV5._pointsBase[userAddr]!
			if preBasePoints == newBasePoints{ 
				return
			}
			if preBasePoints < newBasePoints{ 
				emit PointsMinted(userAddr: userAddr, amount: newBasePoints - preBasePoints, source: "Reconcile", param:{ "PreBaseBalance": preBasePoints.toString(), "NewBaseBalance": newBasePoints.toString()})
			} else{ 
				emit PointsBurned(userAddr: userAddr, amount: preBasePoints - newBasePoints, source: "Reconcile", param:{ "PreBaseBalance": preBasePoints.toString(), "NewBaseBalance": newBasePoints.toString()})
			}
			PPPV5._totalSupply = PPPV5._totalSupply - preBasePoints + newBasePoints
			PPPV5._pointsBase[userAddr] = newBasePoints
		}
		
		access(all)
		fun updateTopUsers(addrs: [Address]){ 
			emit TopUsersChanged(ori: PPPV5._topUsers, new: addrs)
			PPPV5._topUsers = addrs
		}
	}
	
	init(){ 
		self._totalSupply = 0.0
		self._secondsPerPointsRateSession = 3600.0
		self._pointsBase ={} 
		self._pointsHistorySnapshot ={} 
		self._totalPointsAsReferrer ={} 
		self._pointsFromReferees ={} 
		self._pointsAsReferee ={} 
		self._pointsAsCoreMember ={} 
		self._topUsers = []
		self._pointsRate ={ 
				"stFlowHolding":{ "0.0": 0, "1.0": 0.001},
				"LendingSupply":{
				
					"0.0": 0,
					"1.0": 0.00007,
					"10.0": 0.000072,
					"100.0": 0.000074,
					"1000.0": 0.000076,
					"10000.0": 0.000074,
					"100000.0": 0.000072,
					"1000000.0": 0.00007
				},
				"LendingBorrow":{
				
					"0.0": 0,
					"1.0": 0.00035,
					"10.0": 0.00036,
					"100.0": 0.00037,
					"1000.0": 0.00038,
					"10000.0": 0.00037,
					"100000.0": 0.00036,
					"1000000.0": 0.00035
				},
				"SwapLP":{
				
					"0.0": 0,
					"1.0": 0.0001,
					"10.0": 0.0002,
					"100.0": 0.001,
					"1000.0": 0.002,
					"10000.0": 0.001,
					"100000.0": 0.0002,
					"1000000.0": 0.0001
				},
				"SwapVolume":{ "0.0": 0, "1.0": 0.002},
				"ReferrerUp": 0.1,
				"RefereeUp": 0.1,
				"CoreMember": 0.05
			}
		self._swapPoolWhitelist ={ 
				0xfa82796435e15832: true, // FLOW-USDC
				
				0xc353b9d685ec427d: true, // FLOW-stFLOW stable
				
				0xa06c38beec9cf0e8: true, // FLOW-DUST
				
				0xbfb26bb8adf90399: true // FLOW-SLOPPY
			
			}
		self._userStates ={} 
		self._userBlacklist ={} 
		self._ifClaimHistorySnapshot ={} 
		self._swapPoolAddress = 0x00
		self._swapVolumeTrackingTimestamp = 0.0
		self._swapPoolReserve0 = 0.0
		self._swapPoolReserve1 = 0.0
		self._reservedFields ={} 
		destroy <-self.account.storage.load<@AnyResource>(from: /storage/pointsAdmin)
		self.account.storage.save(<-create Admin(), to: /storage/pointsAdmin)
	}
}
