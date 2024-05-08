/**

  LogEntry for Increment products for purpose of onchain data analysis.

  Declaring misc events not belonging to a specific product, e.g.: sign agreement tx, aggregation tx, et al. 

  Author: Increment Labs
*/

access(all)
contract LogEntry{ 
	// Naming convension: event - Log<X>E ; corresponding function - Log<X>
	access(all)
	event LogAgreementE(a: Address, t: UFix64)
	
	// Log aggregated-swap info of txs originated from frontend.
	// amountInSplitByPoolSource: { liquiditySource => splittedInAmount}
	access(all)
	event AggregateSwap(
		userAddr: Address,
		tokenInKey: String,
		tokenOutKey: String,
		tokenInAmount: UFix64,
		tokenOutAmount: UFix64,
		amountInSplitByPoolSource:{ 
			String: UFix64
		},
		isExactAForB: Bool
	)
	
	// Log swap info of each pool traversed in a single aggregated-swap tx originated from frontend.
	access(all)
	event PoolSwapInAggregator(
		tokenInKey: String,
		tokenOutKey: String,
		tokenInAmount: UFix64,
		tokenOutAmount: UFix64,
		poolAddress: Address?,
		poolSource: String
	)
	
	// Log sweep multiple small-value tokens and exchanges them for Flow Tokens.
	access(all)
	event SweepTokensToFlow(
		tokensToSweep: [
			String
		],
		amountsToSweep: [
			UFix64
		],
		flowTokensOut: [
			UFix64
		]
	)
	
	// Log swap lp migration from v1 to v2
	access(all)
	event MigrateSwapLpFromV1ToV2(
		token0Key: String,
		token1Key: String,
		lpToRemove: UFix64,
		token0WithdrawFromV1: UFix64,
		token1WithdrawFromV1: UFix64,
		token0LeftAfterFirstAddV2Lp: UFix64,
		token1LeftAfterFirstAddV2Lp: UFix64,
		zappedAmount: UFix64
	)
	
	// Log burn swap lp tokens
	access(all)
	event BurnSwapLp(token0Key: String, token1Key: String, pairAddr: Address, amountToBurn: UFix64)
	
	// ... More to be added here ...
	access(all)
	fun LogAgreement(addr: Address){ 
		emit LogAgreementE(a: addr, t: getCurrentBlock().timestamp)
	}
	
	access(all)
	fun LogAggregateSwap(
		userAddr: Address,
		tokenInKey: String,
		tokenOutKey: String,
		tokenInAmount: UFix64,
		tokenOutAmount: UFix64,
		amountInSplitByPoolSource:{ 
			String: UFix64
		},
		isExactAForB: Bool
	){ 
		emit AggregateSwap(
			userAddr: userAddr,
			tokenInKey: tokenInKey,
			tokenOutKey: tokenOutKey,
			tokenInAmount: tokenInAmount,
			tokenOutAmount: tokenOutAmount,
			amountInSplitByPoolSource: amountInSplitByPoolSource,
			isExactAForB: isExactAForB
		)
	}
	
	access(all)
	fun LogPoolSwapInAggregator(
		tokenInKey: String,
		tokenOutKey: String,
		tokenInAmount: UFix64,
		tokenOutAmount: UFix64,
		poolAddress: Address?,
		poolSource: String
	){ 
		emit PoolSwapInAggregator(
			tokenInKey: tokenInKey,
			tokenOutKey: tokenOutKey,
			tokenInAmount: tokenInAmount,
			tokenOutAmount: tokenOutAmount,
			poolAddress: poolAddress,
			poolSource: poolSource
		)
	}
	
	access(all)
	fun LogSweepTokensToFlow(
		tokensToSweep: [
			String
		],
		amountsToSweep: [
			UFix64
		],
		flowTokensOut: [
			UFix64
		]
	){ 
		emit SweepTokensToFlow(
			tokensToSweep: tokensToSweep,
			amountsToSweep: amountsToSweep,
			flowTokensOut: flowTokensOut
		)
	}
	
	access(all)
	fun LogMigrateSwapLpFromV1ToV2(
		token0Key: String,
		token1Key: String,
		lpToRemove: UFix64,
		token0WithdrawFromV1: UFix64,
		token1WithdrawFromV1: UFix64,
		token0LeftAfterFirstAddV2Lp: UFix64,
		token1LeftAfterFirstAddV2Lp: UFix64,
		zappedAmount: UFix64
	){ 
		emit MigrateSwapLpFromV1ToV2(
			token0Key: token0Key,
			token1Key: token1Key,
			lpToRemove: lpToRemove,
			token0WithdrawFromV1: token0WithdrawFromV1,
			token1WithdrawFromV1: token1WithdrawFromV1,
			token0LeftAfterFirstAddV2Lp: token0LeftAfterFirstAddV2Lp,
			token1LeftAfterFirstAddV2Lp: token1LeftAfterFirstAddV2Lp,
			zappedAmount: zappedAmount
		)
	}
	
	access(all)
	fun LogBurnSwapLp(
		token0Key: String,
		token1Key: String,
		pairAddr: Address,
		amountToBurn: UFix64
	){ 
		emit BurnSwapLp(
			token0Key: token0Key,
			token1Key: token1Key,
			pairAddr: pairAddr,
			amountToBurn: amountToBurn
		)
	}
// ... More to be added here ...
}
