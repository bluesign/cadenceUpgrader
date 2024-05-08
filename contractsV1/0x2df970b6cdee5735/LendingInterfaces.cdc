/**

# Lending related interface definitions all-in-one

# Author: Increment Labs

*/

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract interface LendingInterfaces{ 
	access(all)
	resource interface PoolPublic{ 
		access(all)
		fun getPoolAddress(): Address
		
		access(all)
		fun getUnderlyingTypeString(): String
		
		access(all)
		fun getUnderlyingAssetType(): String
		
		access(all)
		fun getUnderlyingToLpTokenRateScaled(): UInt256
		
		access(all)
		fun getAccountLpTokenBalanceScaled(account: Address): UInt256
		
		/// Return snapshot of account borrowed balance in scaled UInt256 format
		access(all)
		fun getAccountBorrowBalanceScaled(account: Address): UInt256
		
		/// Return: [scaledExchangeRate, scaledLpTokenBalance, scaledBorrowBalance, scaledAccountBorrowPrincipal, scaledAccountBorrowIndex]
		access(all)
		fun getAccountSnapshotScaled(account: Address): [UInt256; 5]
		
		access(all)
		fun getAccountRealtimeScaled(account: Address): [UInt256; 5]
		
		access(all)
		fun getInterestRateModelAddress(): Address
		
		access(all)
		fun getPoolReserveFactorScaled(): UInt256
		
		access(all)
		fun getPoolAccrualBlockNumber(): UInt256
		
		access(all)
		fun getPoolTotalBorrowsScaled(): UInt256
		
		access(all)
		fun getPoolBorrowIndexScaled(): UInt256
		
		access(all)
		fun getPoolTotalSupplyScaled(): UInt256
		
		access(all)
		fun getPoolCash(): UInt256
		
		access(all)
		fun getPoolTotalLpTokenSupplyScaled(): UInt256
		
		access(all)
		fun getPoolTotalReservesScaled(): UInt256
		
		access(all)
		fun getPoolBorrowRateScaled(): UInt256
		
		access(all)
		fun getPoolSupplyAprScaled(): UInt256
		
		access(all)
		fun getPoolBorrowAprScaled(): UInt256
		
		access(all)
		fun getPoolSupplierCount(): UInt256
		
		access(all)
		fun getPoolBorrowerCount(): UInt256
		
		access(all)
		fun getPoolSupplierList(): [Address]
		
		access(all)
		fun getPoolBorrowerList(): [Address]
		
		access(all)
		fun getPoolSupplierSlicedList(from: UInt64, to: UInt64): [Address]
		
		access(all)
		fun getPoolBorrowerSlicedList(from: UInt64, to: UInt64): [Address]
		
		access(all)
		fun getFlashloanRateBps(): UInt64
		
		/// Accrue pool interest and checkpoint latest data to pool states
		access(all)
		fun accrueInterest()
		
		access(all)
		fun accrueInterestReadonly(): [UInt256; 4]
		
		access(all)
		fun getPoolCertificateType(): Type
		
		/// Note: Check to ensure @callerPoolCertificate's run-time type is another LendingPool's.IdentityCertificate,
		/// so that this public seize function can only be invoked by another LendingPool contract
		access(all)
		fun seize(
			seizerPoolCertificate: @{LendingInterfaces.IdentityCertificate},
			seizerPool: Address,
			liquidator: Address,
			borrower: Address,
			scaledBorrowerCollateralLpTokenToSeize: UInt256
		)
		
		access(all)
		fun supply(supplierAddr: Address, inUnderlyingVault: @{FungibleToken.Vault})
		
		access(all)
		fun redeem(
			userCertificateCap: Capability<&{LendingInterfaces.IdentityCertificate}>,
			numLpTokenToRedeem: UFix64
		): @{FungibleToken.Vault}
		
		access(all)
		fun redeemUnderlying(
			userCertificateCap: Capability<&{LendingInterfaces.IdentityCertificate}>,
			numUnderlyingToRedeem: UFix64
		): @{FungibleToken.Vault}
		
		access(all)
		fun borrow(
			userCertificateCap: Capability<&{LendingInterfaces.IdentityCertificate}>,
			borrowAmount: UFix64
		): @{FungibleToken.Vault}
		
		access(all)
		fun repayBorrow(borrower: Address, repayUnderlyingVault: @{FungibleToken.Vault}): @{
			FungibleToken.Vault
		}?
		
		access(all)
		fun liquidate(
			liquidator: Address,
			borrower: Address,
			poolCollateralizedToSeize: Address,
			repayUnderlyingVault: @{FungibleToken.Vault}
		): @{FungibleToken.Vault}?
		
		access(all)
		fun flashloan(
			executorCap: Capability<&{LendingInterfaces.FlashLoanExecutor}>,
			requestedAmount: UFix64,
			params:{ 
				String: AnyStruct
			}
		){ 
			return
		}
	}
	
	access(all)
	resource interface PoolAdminPublic{ 
		access(all)
		fun setInterestRateModel(newInterestRateModelAddress: Address)
		
		access(all)
		fun setReserveFactor(newReserveFactor: UFix64)
		
		access(all)
		fun setPoolSeizeShare(newPoolSeizeShare: UFix64)
		
		access(all)
		fun setComptroller(newComptrollerAddress: Address)
		
		/// A pool can only be initialized once
		access(all)
		fun initializePool(
			reserveFactor: UFix64,
			poolSeizeShare: UFix64,
			interestRateModelAddress: Address
		)
		
		access(all)
		fun withdrawReserves(reduceAmount: UFix64): @{FungibleToken.Vault}
		
		access(all)
		fun setFlashloanRateBps(rateBps: UInt64)
		
		access(all)
		fun setFlashloanOpen(isOpen: Bool)
	}
	
	access(all)
	resource interface FlashLoanExecutor{ 
		access(all)
		fun executeAndRepay(loanedToken: @{FungibleToken.Vault}, params:{ String: AnyStruct}): @{
			FungibleToken.Vault
		}
	}
	
	access(all)
	resource interface InterestRateModelPublic{ 
		/// exposing model specific fields, e.g.: modelName, model params.
		access(all)
		fun getInterestRateModelParams():{ String: AnyStruct}
		
		/// pool's capital utilization rate (scaled up by scaleFactor, e.g. 1e18)
		access(all)
		fun getUtilizationRate(cash: UInt256, borrows: UInt256, reserves: UInt256): UInt256
		
		/// Get the borrow interest rate per block (scaled up by scaleFactor, e.g. 1e18)
		access(all)
		fun getBorrowRate(cash: UInt256, borrows: UInt256, reserves: UInt256): UInt256
		
		/// Get the supply interest rate per block (scaled up by scaleFactor, e.g. 1e18)
		access(all)
		fun getSupplyRate(
			cash: UInt256,
			borrows: UInt256,
			reserves: UInt256,
			reserveFactor: UInt256
		): UInt256
		
		/// Get the number of blocks per year.
		access(all)
		fun getBlocksPerYear(): UInt256
	}
	
	/// IdentityCertificate resource which is used to identify account address or perform caller authentication
	access(all)
	resource interface IdentityCertificate{} 
	
	access(all)
	resource interface OraclePublic{ 
		/// Get the given pool's underlying asset price denominated in USD.
		/// Note: Return value of 0.0 means the given pool's price feed is not available.
		access(all)
		fun getUnderlyingPrice(pool: Address): UFix64
		
		/// Return latest reported data in [timestamp, priceData]
		access(all)
		fun latestResult(pool: Address): [UFix64; 2]
		
		/// Return supported markets' addresses
		access(all)
		fun getSupportedFeeds(): [Address]
	}
	
	access(all)
	resource interface ComptrollerPublic{ 
		/// Return error string on condition (or nil)
		access(all)
		fun supplyAllowed(
			poolCertificate: @{LendingInterfaces.IdentityCertificate},
			poolAddress: Address,
			supplierAddress: Address,
			supplyUnderlyingAmountScaled: UInt256
		): String?
		
		access(all)
		fun redeemAllowed(
			poolCertificate: @{LendingInterfaces.IdentityCertificate},
			poolAddress: Address,
			redeemerAddress: Address,
			redeemLpTokenAmountScaled: UInt256
		): String?
		
		access(all)
		fun borrowAllowed(
			poolCertificate: @{LendingInterfaces.IdentityCertificate},
			poolAddress: Address,
			borrowerAddress: Address,
			borrowUnderlyingAmountScaled: UInt256
		): String?
		
		access(all)
		fun repayAllowed(
			poolCertificate: @{LendingInterfaces.IdentityCertificate},
			poolAddress: Address,
			borrowerAddress: Address,
			repayUnderlyingAmountScaled: UInt256
		): String?
		
		access(all)
		fun liquidateAllowed(
			poolCertificate: @{LendingInterfaces.IdentityCertificate},
			poolBorrowed: Address,
			poolCollateralized: Address,
			borrower: Address,
			repayUnderlyingAmountScaled: UInt256
		): String?
		
		access(all)
		fun seizeAllowed(
			poolCertificate: @{LendingInterfaces.IdentityCertificate},
			borrowPool: Address,
			collateralPool: Address,
			liquidator: Address,
			borrower: Address,
			seizeCollateralPoolLpTokenAmountScaled: UInt256
		): String?
		
		access(all)
		fun callerAllowed(
			callerCertificate: @{LendingInterfaces.IdentityCertificate},
			callerAddress: Address
		): String?
		
		access(all)
		fun calculateCollateralPoolLpTokenToSeize(
			borrower: Address,
			borrowPool: Address,
			collateralPool: Address,
			actualRepaidBorrowAmountScaled: UInt256
		): UInt256
		
		access(all)
		fun getUserCertificateType(): Type
		
		access(all)
		fun getPoolPublicRef(poolAddr: Address): &{PoolPublic}
		
		access(all)
		fun getAllMarkets(): [Address]
		
		access(all)
		fun getMarketInfo(poolAddr: Address):{ String: AnyStruct}
		
		access(all)
		fun getUserMarkets(userAddr: Address): [Address]
		
		access(all)
		fun getUserCrossMarketLiquidity(userAddr: Address): [String; 3]
		
		access(all)
		fun getUserMarketInfo(userAddr: Address, poolAddr: Address):{ String: AnyStruct}
	}
}
