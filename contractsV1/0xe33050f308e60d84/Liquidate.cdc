import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import LendingConfig from "../0x2df970b6cdee5735/LendingConfig.cdc"

import LendingInterfaces from "../0x2df970b6cdee5735/LendingInterfaces.cdc"

access(all)
contract Liquidate{ 
	access(self)
	let poolNames: [String]
	
	access(self)
	let poolAddrs: [Address]
	
	access(self)
	let poolBalancePaths: [String]
	
	access(self)
	let poolVaultPaths: [String]
	
	access(self)
	let poolPenalties: [UFix64]
	
	access(self)
	let _reservedFields:{ String: AnyStruct}
	
	access(all)
	fun repayAmount(borrowerAddr: Address, liquidatorAddr: Address): UFix64{ 
		let comptrollerRef =
			getAccount(0xf80cb737bfe7c792).capabilities.get<&{LendingInterfaces.ComptrollerPublic}>(
				LendingConfig.ComptrollerPublicPath
			).borrow()!
		let liquidity = comptrollerRef.getUserCrossMarketLiquidity(userAddr: borrowerAddr)
		if liquidity[0] >= liquidity[1]{ 
			return 0.0
		}
		let details =
			self.calculateLiquidation(borrowerAddr: borrowerAddr, liquidatorAddr: liquidatorAddr)
		let maxSupplyIndex = details["maxSupplyIndex"]! as! Int
		let maxBorrowIndex = details["maxBorrowIndex"]! as! Int
		let maxSupplyUsd = details["maxSupplyUsd"]! as! UFix64
		let borrowerBorrows = details["borrowerBorrows"]! as! [UFix64]
		let liquidatorBalances = details["liquidatorBalances"]! as! [UFix64]
		let poolPrices = details["poolPrices"]! as! [UFix64]
		let maxSize = self._reservedFields["maxSize"]! as! UFix64
		var repayAmount =
			self.min(
				borrowerBorrows[maxBorrowIndex] * 0.49,
				self.min(maxSupplyUsd, maxSize) / (1.0 + self.poolPenalties[maxSupplyIndex])
				/ poolPrices[maxBorrowIndex]
				- 0.00000001
			)
		repayAmount = self.min(repayAmount, liquidatorBalances[maxBorrowIndex])
		if repayAmount < 0.0001{ 
			return 0.0
		}
		return repayAmount
	}
	
	access(all)
	fun calculateLiquidation(borrowerAddr: Address, liquidatorAddr: Address):{ String: AnyStruct}{ 
		let poolPrices: [UFix64] = []
		let liquidatorBalances: [UFix64] = []
		let oracleCap =
			getAccount(0x72d3a05910b6ffa3).capabilities.get<&{LendingInterfaces.OraclePublic}>(
				LendingConfig.OraclePublicPath
			).borrow()!
		let borrowerSupplys: [UFix64] = []
		let borrowerBorrows: [UFix64] = []
		var i = 0
		var maxSupplyIndex: Int = 0
		var maxBorrowIndex: Int = 0
		var maxSupply: UFix64 = 0.0
		var maxBorrow: UFix64 = 0.0
		var maxSupplyUsd: UFix64 = 0.0
		var maxBorrowUsd: UFix64 = 0.0
		for poolAddr in self.poolAddrs{ 
			let poolPrice = oracleCap.getUnderlyingPrice(pool: poolAddr)
			poolPrices.append(poolPrice)
			var localBalance = (getAccount(liquidatorAddr).capabilities.get<&{FungibleToken.Balance}>(PublicPath(identifier: self.poolBalancePaths[i])!).borrow()!).balance
			if localBalance > 1.0{ 
				localBalance = localBalance - 1.0
			}
			liquidatorBalances.append(localBalance)
			let lendingPoolCap = getAccount(poolAddr).capabilities.get<&{LendingInterfaces.PoolPublic}>(LendingConfig.PoolPublicPublicPath).borrow()!
			let userInfo = lendingPoolCap.getAccountRealtimeScaled(account: borrowerAddr)
			let userSupply = LendingConfig.ScaledUInt256ToUFix64(userInfo[1] * userInfo[0] / LendingConfig.scaleFactor)
			let userSupplyUsd = userSupply * poolPrice
			let userBorrow = LendingConfig.ScaledUInt256ToUFix64(userInfo[2])
			let userBorrowUsd = userBorrow * poolPrice
			borrowerSupplys.append(userSupply)
			borrowerBorrows.append(userBorrow)
			if userSupplyUsd > maxSupplyUsd{ 
				maxSupplyUsd = userSupplyUsd
				maxSupplyIndex = i
			}
			if userBorrowUsd > maxBorrowUsd{ 
				maxBorrowUsd = userBorrowUsd
				maxBorrowIndex = i
			}
			i = i + 1
		}
		return{ 
			"poolPrices": poolPrices,
			"maxSupplyIndex": maxSupplyIndex,
			"maxBorrowIndex": maxBorrowIndex,
			"maxSupplyUsd": maxSupplyUsd,
			"maxBorrowUsd": maxBorrowUsd,
			"borrowerSupplys": borrowerSupplys,
			"borrowerBorrows": borrowerBorrows,
			"liquidatorBalances": liquidatorBalances
		}
	}
	
	access(all)
	fun liquidate(
		repayVault: &{FungibleToken.Vault},
		borrowerAddr: Address,
		liquidatorAddr: Address,
		userCertificateCap: Capability<&{LendingInterfaces.IdentityCertificate}>
	): @{FungibleToken.Vault}{ 
		let details =
			self.calculateLiquidation(borrowerAddr: borrowerAddr, liquidatorAddr: liquidatorAddr)
		let maxSupplyIndex = details["maxSupplyIndex"]! as! Int
		let maxBorrowIndex = details["maxBorrowIndex"]! as! Int
		let repayAmount =
			self.repayAmount(borrowerAddr: borrowerAddr, liquidatorAddr: liquidatorAddr)
		let repayPoolRef =
			getAccount(self.poolAddrs[maxBorrowIndex]).capabilities.get<
				&{LendingInterfaces.PoolPublic}
			>(LendingConfig.PoolPublicPublicPath).borrow()!
		let seizePoolRef =
			getAccount(self.poolAddrs[maxSupplyIndex]).capabilities.get<
				&{LendingInterfaces.PoolPublic}
			>(LendingConfig.PoolPublicPublicPath).borrow()!
		let preLpToken =
			LendingConfig.ScaledUInt256ToUFix64(
				seizePoolRef.getAccountLpTokenBalanceScaled(account: liquidatorAddr)
			)
		let leftVault <-
			repayPoolRef.liquidate(
				liquidator: liquidatorAddr,
				borrower: borrowerAddr,
				poolCollateralizedToSeize: self.poolAddrs[maxSupplyIndex],
				repayUnderlyingVault: <-repayVault.withdraw(amount: repayAmount)
			)
		if leftVault != nil{ 
			repayVault.deposit(from: <-leftVault!)
		} else{ 
			destroy leftVault
		}
		//
		let aftLpToken =
			LendingConfig.ScaledUInt256ToUFix64(
				seizePoolRef.getAccountLpTokenBalanceScaled(account: liquidatorAddr)
			)
		
		// seize
		let redeemedVault <-
			seizePoolRef.redeem(
				userCertificateCap: userCertificateCap,
				numLpTokenToRedeem: aftLpToken - preLpToken
			)
		return <-redeemedVault
	}
	
	access(all)
	fun min(_ a: UFix64, _ b: UFix64): UFix64{ 
		return a > b ? b : a
	}
	
	access(all)
	fun poolAddresses(): [Address]{ 
		return self.poolAddrs
	}
	
	access(all)
	fun poolVaultStoragePaths(): [String]{ 
		return self.poolVaultPaths
	}
	
	init(){ 
		self.poolNames = ["FlowToken", "FiatToken", "stFlowToken"]
		self.poolAddrs = [0x7492e2f9b4acea9a, 0x8334275bda13b2be, 0x44fe3d9157770b2d]
		self.poolBalancePaths = ["flowTokenBalance", "USDCVaultBalance", "stFlowTokenBalance"]
		self.poolVaultPaths = ["flowTokenVault", "USDCVault", "stFlowTokenVault"]
		self.poolPenalties = [0.1, 0.05, 0.1]
		self._reservedFields ={ "maxSize": 60000.0}
	}
}
