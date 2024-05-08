/**

# SwapPair

# Author: Increment Labs

*/

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import SwapInterfaces from "../0xb78ef7afa52ff906/SwapInterfaces.cdc"

import SwapConfig from "../0xb78ef7afa52ff906/SwapConfig.cdc"

import SwapError from "../0xb78ef7afa52ff906/SwapError.cdc"

import SwapFactory from "../0xb063c16cac85dbd1/SwapFactory.cdc"

access(all)
contract SwapPair: FungibleToken{ 
	/// Total supply of pair lpTokens in existence
	access(all)
	var totalSupply: UFix64
	
	/// Two vaults for the trading pair.
	access(self)
	let token0Vault: @{FungibleToken.Vault}
	
	access(self)
	let token1Vault: @{FungibleToken.Vault}
	
	access(all)
	let token0VaultType: Type
	
	access(all)
	let token1VaultType: Type
	
	access(all)
	let token0Key: String
	
	access(all)
	let token1Key: String
	
	/// TWAP: last cumulative price
	access(all)
	var blockTimestampLast: UFix64
	
	access(all)
	var price0CumulativeLastScaled: UInt256
	
	access(all)
	var price1CumulativeLastScaled: UInt256
	
	/// Transaction lock 
	access(self)
	var lock: Bool
	
	/// √(reserve0 * reserve1) for volatile pool, or √√[(r0^3 * r1 + r0 * r1^3) / 2] for stable pool, as of immediately after the most recent liquidity event
	access(all)
	var rootKLast: UFix64
	
	/// Reserved parameter fields: {ParamName: Value}
	/// Used fields:
	///   |__ 1. "isStableSwap" -> Bool
	access(self)
	let _reservedFields:{ String: AnyStruct}
	
	/// Event that is emitted when the contract is created
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	/// Event that is emitted when tokens are withdrawn from a Vault
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	/// Event that is emitted when tokens are deposited to a Vault
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	/// Event that is emitted when new tokens are minted
	access(all)
	event TokensMinted(amount: UFix64)
	
	/// Event that is emitted when tokens are destroyed
	access(all)
	event TokensBurned(amount: UFix64)
	
	/// Event that is emitted when a swap trade happenes to this trading pair
	/// direction: 0 - in self.token0 swapped to out self.token1
	///			1 - in self.token1 swapped to out self.token0
	access(all)
	event Swap(inTokenAmount: UFix64, outTokenAmount: UFix64, direction: UInt8)
	
	/// Event that is emitted when a flashloan is originated from this SwapPair pool
	access(all)
	event Flashloan(executor: Address, executorType: Type, originator: Address, requestedTokenKey: String, amount: UFix64)
	
	/// Lptoken Vault
	///
	access(all)
	resource Vault: FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance{ 
		/// Holds the balance of a users tokens
		access(all)
		var balance: UFix64
		
		/// Initialize the balance at resource creation time
		init(balance: UFix64){ 
			self.balance = balance
		}
		
		/// withdraw
		///
		/// Function that takes an integer amount as an argument
		/// and withdraws that amount from the Vault.
		/// It creates a new temporary Vault that is used to hold
		/// the money that is being transferred. It returns the newly
		/// created Vault to the context that called so it can be deposited
		/// elsewhere.
		///
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			self.balance = self.balance - amount
			emit TokensWithdrawn(amount: amount, from: self.owner?.address)
			return <-create Vault(balance: amount)
		}
		
		/// deposit
		///
		/// Function that takes a Vault object as an argument and adds
		/// its balance to the balance of the owners Vault.
		/// It is allowed to destroy the sent Vault because the Vault
		/// was a temporary holder of the tokens. The Vault's balance has
		/// been consumed and therefore can be destroyed.
		///
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @SwapPair.Vault
			self.balance = self.balance + vault.balance
			emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
			vault.balance = 0.0
			destroy vault
		}
		
		access(all)
		fun createEmptyVault(): @{FungibleToken.Vault}{ 
			return <-create Vault(balance: 0.0)
		}
		
		access(all)
		view fun isAvailableToWithdraw(amount: UFix64): Bool{ 
			return self.balance >= amount
		}
	}
	
	/// createEmptyVault
	//
	/// Function that creates a new Vault with a balance of zero
	/// and returns it to the calling context. A user must call this function
	/// and store the returned Vault in their storage in order to allow their
	/// account to be able to receive deposits of this token type.
	///
	access(all)
	fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault}{ 
		return <-create Vault(balance: 0.0)
	}
	
	/// Permanently lock the first small amount lpTokens
	access(self)
	fun donateInitialMinimumLpToken(donateLpBalance: UFix64){ 
		self.totalSupply = self.totalSupply + donateLpBalance
		emit TokensMinted(amount: donateLpBalance)
	}
	
	/// Mint lpTokens
	access(self)
	fun mintLpToken(amount: UFix64): @SwapPair.Vault{ 
		self.totalSupply = self.totalSupply + amount
		emit TokensMinted(amount: amount)
		return <-create Vault(balance: amount)
	}
	
	/// Burn lpTokens
	access(self)
	fun burnLpToken(from: @SwapPair.Vault){ 
		let amount = from.balance
		destroy from
		emit TokensBurned(amount: amount)
	}
	
	/// Add liquidity
	///
	access(all)
	fun addLiquidity(tokenAVault: @{FungibleToken.Vault}, tokenBVault: @{FungibleToken.Vault}): @{FungibleToken.Vault}{ 
		pre{ 
			tokenAVault.balance > 0.0 && tokenBVault.balance > 0.0:
				SwapError.ErrorEncode(msg: "SwapPair: added zero liquidity", err: SwapError.ErrorCode.ADD_ZERO_LIQUIDITY)
			tokenAVault.isInstance(self.token0VaultType) && tokenBVault.isInstance(self.token1VaultType) || tokenBVault.isInstance(self.token0VaultType) && tokenAVault.isInstance(self.token1VaultType):
				SwapError.ErrorEncode(msg: "SwapPair: added incompatible liquidity pair vaults", err: SwapError.ErrorCode.INVALID_PARAMETERS)
			self.lock == false:
				SwapError.ErrorEncode(msg: "SwapPair: Reentrant", err: SwapError.ErrorCode.REENTRANT)
		}
		post{ 
			self.lock == false:
				SwapError.ErrorEncode(msg: "SwapPair: Reentrant", err: SwapError.ErrorCode.REENTRANT)
		}
		self.lock = true
		let reserve0LastScaled = SwapConfig.UFix64ToScaledUInt256(self.token0Vault.balance)
		let reserve1LastScaled = SwapConfig.UFix64ToScaledUInt256(self.token1Vault.balance)
		
		/// Update twap at the first transaction in one block with the last block balance
		self._update(reserve0Last: self.token0Vault.balance, reserve1Last: self.token1Vault.balance)
		/// Mint fee
		let feeOn = self._mintFee(reserve0: self.token0Vault.balance, reserve1: self.token1Vault.balance)
		var liquidity = 0.0
		if self.totalSupply == 0.0{ 
			var donateLpBalance = 0.0
			if self.isStableSwap(){ 
				donateLpBalance = 0.0001 // 1e-4
			
			} else{ 
				donateLpBalance = 0.000001 // 1e-6
			
			}
			// When adding initial liquidity, the balance should not be below certain minimum amount
			assert(tokenAVault.balance > donateLpBalance && tokenBVault.balance > donateLpBalance, message: SwapError.ErrorEncode(msg: "SwapPair: less than initial minimum liquidity", err: SwapError.ErrorCode.BELOW_MINIMUM_INITIAL_LIQUIDITY))
			/// Add initial liquidity
			if tokenAVault.isInstance(self.token0VaultType){ 
				self.token0Vault.deposit(from: <-tokenAVault)
				self.token1Vault.deposit(from: <-tokenBVault)
			} else{ 
				self.token0Vault.deposit(from: <-tokenBVault)
				self.token1Vault.deposit(from: <-tokenAVault)
			}
			/// Mint initial liquidity token and donate initial minimum liquidity token
			let initialLpAmount = self._rootK(balance0: self.token0Vault.balance, balance1: self.token1Vault.balance)
			self.donateInitialMinimumLpToken(donateLpBalance: donateLpBalance)
			liquidity = initialLpAmount - donateLpBalance
		} else{ 
			var lptokenMintAmount0Scaled: UInt256 = 0
			var lptokenMintAmount1Scaled: UInt256 = 0
			/// Use UFIx64ToUInt256 in division & multiply to solve precision issues
			let inAmountAScaled = SwapConfig.UFix64ToScaledUInt256(tokenAVault.balance)
			let inAmountBScaled = SwapConfig.UFix64ToScaledUInt256(tokenBVault.balance)
			let totalSupplyScaled = SwapConfig.UFix64ToScaledUInt256(self.totalSupply)
			if tokenAVault.isInstance(self.token0VaultType){ 
				lptokenMintAmount0Scaled = inAmountAScaled * totalSupplyScaled / reserve0LastScaled
				lptokenMintAmount1Scaled = inAmountBScaled * totalSupplyScaled / reserve1LastScaled
				self.token0Vault.deposit(from: <-tokenAVault)
				self.token1Vault.deposit(from: <-tokenBVault)
			} else{ 
				lptokenMintAmount0Scaled = inAmountBScaled * totalSupplyScaled / reserve0LastScaled
				lptokenMintAmount1Scaled = inAmountAScaled * totalSupplyScaled / reserve1LastScaled
				self.token0Vault.deposit(from: <-tokenBVault)
				self.token1Vault.deposit(from: <-tokenAVault)
			}
			
			/// Note: User should add proportional liquidity as any extra is added into pool.
			let mintLptokenAmountScaled = lptokenMintAmount0Scaled < lptokenMintAmount1Scaled ? lptokenMintAmount0Scaled : lptokenMintAmount1Scaled
			
			/// Mint liquidity token pro rata
			liquidity = SwapConfig.ScaledUInt256ToUFix64(mintLptokenAmountScaled)
		}
		/// Mint lpTokens
		let lpTokenVault <- self.mintLpToken(amount: liquidity)
		if feeOn{ 
			self.rootKLast = self._rootK(balance0: self.token0Vault.balance, balance1: self.token1Vault.balance)
		}
		self.lock = false
		return <-lpTokenVault
	}
	
	/// Remove Liquidity
	///
	/// @Return: @[FungibleToken.Vault; 2]
	///
	access(all)
	fun removeLiquidity(lpTokenVault: @{FungibleToken.Vault}): @[{FungibleToken.Vault}]{ 
		pre{ 
			lpTokenVault.balance > 0.0:
				SwapError.ErrorEncode(msg: "SwapPair: removed zero liquidity", err: SwapError.ErrorCode.INVALID_PARAMETERS)
			lpTokenVault.isInstance(Type<@SwapPair.Vault>()):
				SwapError.ErrorEncode(msg: "SwapPair: input vault type mismatch with lpTokenVault type", err: SwapError.ErrorCode.MISMATCH_LPTOKEN_VAULT)
			self.lock == false:
				SwapError.ErrorEncode(msg: "SwapPair: Reentrant", err: SwapError.ErrorCode.REENTRANT)
		}
		post{ 
			self.lock == false:
				SwapError.ErrorEncode(msg: "SwapPair: Reentrant", err: SwapError.ErrorCode.REENTRANT)
		}
		self.lock = true
		let reserve0LastScaled = SwapConfig.UFix64ToScaledUInt256(self.token0Vault.balance)
		let reserve1LastScaled = SwapConfig.UFix64ToScaledUInt256(self.token1Vault.balance)
		
		/// Update twap
		self._update(reserve0Last: self.token0Vault.balance, reserve1Last: self.token1Vault.balance)
		/// Mint fee
		let feeOn = self._mintFee(reserve0: self.token0Vault.balance, reserve1: self.token1Vault.balance)
		
		/// Use UFIx64ToUInt256 in division & multiply to solve precision issues
		let removeAmountScaled = SwapConfig.UFix64ToScaledUInt256(lpTokenVault.balance)
		let totalSupplyScaled = SwapConfig.UFix64ToScaledUInt256(self.totalSupply)
		let token0AmountScaled = removeAmountScaled * reserve0LastScaled / totalSupplyScaled
		let token1AmountScaled = removeAmountScaled * reserve1LastScaled / totalSupplyScaled
		let token0Amount = SwapConfig.ScaledUInt256ToUFix64(token0AmountScaled)
		let token1Amount = SwapConfig.ScaledUInt256ToUFix64(token1AmountScaled)
		let withdrawnToken0 <- self.token0Vault.withdraw(amount: token0Amount)
		let withdrawnToken1 <- self.token1Vault.withdraw(amount: token1Amount)
		
		/// Burn lpTokens
		self.burnLpToken(from: <-(lpTokenVault as! @SwapPair.Vault))
		if feeOn{ 
			self.rootKLast = self._rootK(balance0: self.token0Vault.balance, balance1: self.token1Vault.balance)
		}
		self.lock = false
		return <-[<-withdrawnToken0, <-withdrawnToken1]
	}
	
	/// Swap
	///
	access(all)
	fun swap(vaultIn: @{FungibleToken.Vault}, exactAmountOut: UFix64?): @{FungibleToken.Vault}{ 
		pre{ 
			vaultIn.balance > 0.0:
				SwapError.ErrorEncode(msg: "SwapPair: zero in balance", err: SwapError.ErrorCode.INVALID_PARAMETERS)
			vaultIn.isInstance(self.token0VaultType) || vaultIn.isInstance(self.token1VaultType):
				SwapError.ErrorEncode(msg: "SwapPair: incompatible in token vault", err: SwapError.ErrorCode.INVALID_PARAMETERS)
			self.lock == false:
				SwapError.ErrorEncode(msg: "SwapPair: Reentrant", err: SwapError.ErrorCode.REENTRANT)
		}
		post{ 
			self.lock == false:
				SwapError.ErrorEncode(msg: "SwapPair: Reentrant", err: SwapError.ErrorCode.REENTRANT)
		}
		self.lock = true
		self._update(reserve0Last: self.token0Vault.balance, reserve1Last: self.token1Vault.balance)
		var amountOut = 0.0
		/// Calculate the swap result
		if vaultIn.isInstance(self.token0VaultType){ 
			if self.isStableSwap(){ 
				amountOut = SwapConfig.getAmountOutStable(amountIn: vaultIn.balance, reserveIn: self.token0Vault.balance, reserveOut: self.token1Vault.balance, p: self.getStableCurveP(), swapFeeRateBps: self.getSwapFeeBps())
			} else{ 
				amountOut = SwapConfig.getAmountOutVolatile(amountIn: vaultIn.balance, reserveIn: self.token0Vault.balance, reserveOut: self.token1Vault.balance, swapFeeRateBps: self.getSwapFeeBps())
			}
		} else if self.isStableSwap(){ 
			amountOut = SwapConfig.getAmountOutStable(amountIn: vaultIn.balance, reserveIn: self.token1Vault.balance, reserveOut: self.token0Vault.balance, p: 1.0 / self.getStableCurveP(), swapFeeRateBps: self.getSwapFeeBps())
		} else{ 
			amountOut = SwapConfig.getAmountOutVolatile(amountIn: vaultIn.balance, reserveIn: self.token1Vault.balance, reserveOut: self.token0Vault.balance, swapFeeRateBps: self.getSwapFeeBps())
		}
		/// Check and swap exact output amount if specified in argument
		if exactAmountOut != nil{ 
			assert(amountOut >= exactAmountOut!, message: SwapError.ErrorEncode(msg: "SwapPair: INSUFFICIENT_OUTPUT_AMOUNT", err: SwapError.ErrorCode.INSUFFICIENT_OUTPUT_AMOUNT))
			amountOut = exactAmountOut!
		}
		if vaultIn.isInstance(self.token0VaultType){ 
			emit Swap(inTokenAmount: vaultIn.balance, outTokenAmount: amountOut, direction: 0)
			self.token0Vault.deposit(from: <-vaultIn)
			self.lock = false
			return <-self.token1Vault.withdraw(amount: amountOut)
		} else{ 
			emit Swap(inTokenAmount: vaultIn.balance, outTokenAmount: amountOut, direction: 1)
			self.token1Vault.deposit(from: <-vaultIn)
			self.lock = false
			return <-self.token0Vault.withdraw(amount: amountOut)
		}
	}
	
	/// An executor contract can request to use the whole liquidity of current SwapPair and perform custom operations (like arbitrage, liquidation, et al.), as long as:
	///   1. executor implements FlashLoanExecutor resource interface and sets up corresponding resource to receive & process requested tokens, and
	///   2. executor repays back requested amount + fees (dominated by 'flashloanRateBps x amount'), and
	/// all in one atomic function call.
	/// @params: User-definited extra data passed to executor for further auth/check/decode
	///
	access(all)
	fun flashloan(executorCap: Capability<&{SwapInterfaces.FlashLoanExecutor}>, requestedTokenVaultType: Type, requestedAmount: UFix64, params:{ String: AnyStruct}){ 
		pre{ 
			requestedTokenVaultType == self.token0VaultType || requestedTokenVaultType == self.token1VaultType:
				SwapError.ErrorEncode(msg: "SwapPair: flashloan invalid requested token type", err: SwapError.ErrorCode.INVALID_PARAMETERS)
			requestedTokenVaultType == self.token0VaultType && requestedAmount > 0.0 && requestedAmount < self.token0Vault.balance || requestedTokenVaultType == self.token1VaultType && requestedAmount > 0.0 && requestedAmount < self.token1Vault.balance:
				SwapError.ErrorEncode(msg: "SwapPair: flashloan invalid requested amount", err: SwapError.ErrorCode.INVALID_PARAMETERS)
			executorCap.check():
				SwapError.ErrorEncode(msg: "SwapPair: flashloan executor resource not properly setup", err: SwapError.ErrorCode.FLASHLOAN_EXECUTOR_SETUP)
			self.lock == false:
				SwapError.ErrorEncode(msg: "SwapPair: Reentrant", err: SwapError.ErrorCode.REENTRANT)
		}
		post{ 
			self.lock == false:
				SwapError.ErrorEncode(msg: "SwapPair: Reentrant", err: SwapError.ErrorCode.REENTRANT)
		}
		self.lock = true
		self._update(reserve0Last: self.token0Vault.balance, reserve1Last: self.token1Vault.balance)
		var tokenOut: @{FungibleToken.Vault}? <- nil
		if requestedTokenVaultType == self.token0VaultType{ 
			tokenOut <-! self.token0Vault.withdraw(amount: requestedAmount)
		} else{ 
			tokenOut <-! self.token1Vault.withdraw(amount: requestedAmount)
		}
		// Send loans and invoke custom executor
		let executorRef = executorCap.borrow()!
		let tokenIn <- executorRef.executeAndRepay(loanedToken: <-tokenOut!, params: params)
		assert(tokenIn.isInstance(requestedTokenVaultType), message: SwapError.ErrorEncode(msg: "SwapPair: flashloan repaid incompatible token", err: SwapError.ErrorCode.INVALID_PARAMETERS))
		assert(tokenIn.balance >= requestedAmount * (1.0 + UFix64(SwapFactory.getFlashloanRateBps()) / 10000.0), message: SwapError.ErrorEncode(msg: "SwapPair: flashloan insufficient repayment", err: SwapError.ErrorCode.INVALID_PARAMETERS))
		if requestedTokenVaultType == self.token0VaultType{ 
			self.token0Vault.deposit(from: <-tokenIn)
		} else{ 
			self.token1Vault.deposit(from: <-tokenIn)
		}
		emit Flashloan(executor: (executorRef.owner!).address, executorType: executorRef.getType(), originator: self.account.address, requestedTokenKey: requestedTokenVaultType == self.token0VaultType ? self.token0Key : self.token1Key, amount: requestedAmount)
		self.lock = false
	}
	
	/// Update cumulative price on the first call per block
	access(self)
	fun _update(reserve0Last: UFix64, reserve1Last: UFix64){ 
		let blockTimestamp = getCurrentBlock().timestamp
		let timeElapsed = blockTimestamp - self.blockTimestampLast
		if timeElapsed > 0.0 && reserve0Last != 0.0 && reserve1Last != 0.0{ 
			let timeElapsedScaled = SwapConfig.UFix64ToScaledUInt256(timeElapsed)
			let stableswap_p = self.getStableCurveP()
			let price0 = self.isStableSwap() ? SwapConfig.quoteStable(amountA: 1.0, reserveA: reserve0Last, reserveB: reserve1Last, p: stableswap_p) : SwapConfig.quote(amountA: 1.0, reserveA: reserve0Last, reserveB: reserve1Last)
			var price1 = 0.0
			if price0 == 0.0{ 
				price1 = self.isStableSwap() ? SwapConfig.quoteStable(amountA: 1.0, reserveA: reserve1Last, reserveB: reserve0Last, p: 1.0 / stableswap_p) : SwapConfig.quote(amountA: 1.0, reserveA: reserve1Last, reserveB: reserve0Last)
			} else{ 
				price1 = 1.0 / price0
			}
			self.price0CumulativeLastScaled = SwapConfig.overflowAddUInt256(self.price0CumulativeLastScaled, SwapConfig.UFix64ToScaledUInt256(price0) * timeElapsedScaled / SwapConfig.scaleFactor)
			self.price1CumulativeLastScaled = SwapConfig.overflowAddUInt256(self.price1CumulativeLastScaled, SwapConfig.UFix64ToScaledUInt256(price1) * timeElapsedScaled / SwapConfig.scaleFactor)
		}
		self.blockTimestampLast = blockTimestamp
	}
	
	/// If feeTo is set, mint 1/6th (the default cut) of the growth in sqrt(k) which is only generated by trading behavior.
	/// Instead of collecting protocol fees at the time of each trade, accumulated fees are collected only
	/// when liquidity is deposited or withdrawn.
	///
	access(self)
	fun _mintFee(reserve0: UFix64, reserve1: UFix64): Bool{ 
		let rootKLast = self.rootKLast
		if SwapFactory.feeTo == nil{ 
			if rootKLast > 0.0{ 
				self.rootKLast = 0.0
			}
			return false
		}
		if rootKLast > 0.0{ 
			let rootK = self._rootK(balance0: reserve0, balance1: reserve1)
			if rootK > rootKLast{ 
				let numerator = self.totalSupply * (rootK - rootKLast)
				let denominator = (1.0 / SwapFactory.getProtocolFeeCut() - 1.0) * rootK + rootKLast
				let liquidity = numerator / denominator
				if liquidity > 0.0{ 
					let lpTokenVault <- self.mintLpToken(amount: liquidity)
					let lpTokenCollectionCap = getAccount(SwapFactory.feeTo!).capabilities.get<&{SwapInterfaces.LpTokenCollectionPublic}>(SwapConfig.LpTokenCollectionPublicPath)
					assert(lpTokenCollectionCap.check(), message: SwapError.ErrorEncode(msg: "SwapPair: Cannot borrow reference to LpTokenCollection resource in feeTo account", err: SwapError.ErrorCode.LOST_PUBLIC_CAPABILITY))
					(lpTokenCollectionCap.borrow()!).deposit(pairAddr: self.account.address, lpTokenVault: <-lpTokenVault)
				}
			}
		}
		return true
	}
	
	access(all)
	fun _rootK(balance0: UFix64, balance1: UFix64): UFix64{ 
		let e18: UInt256 = SwapConfig.scaleFactor
		let balance0Scaled = SwapConfig.UFix64ToScaledUInt256(balance0)
		let balance1Scaled = SwapConfig.UFix64ToScaledUInt256(balance1)
		if self.isStableSwap(){ 
			let _p_scaled: UInt256 = SwapConfig.UFix64ToScaledUInt256(self.getStableCurveP())
			let _k_scaled: UInt256 = SwapConfig.k_stable_p(balance0Scaled, balance1Scaled, _p_scaled)
			return SwapConfig.ScaledUInt256ToUFix64(SwapConfig.sqrt(SwapConfig.sqrt(_k_scaled / 2)))
		} else{ 
			return SwapConfig.ScaledUInt256ToUFix64(SwapConfig.sqrt(balance0Scaled * balance1Scaled / e18))
		}
	}
	
	access(all)
	fun isStableSwap(): Bool{ 
		return self._reservedFields["isStableSwap"] as! Bool? ?? false
	}
	
	access(all)
	fun getSwapFeeBps(): UInt64{ 
		return SwapFactory.getSwapFeeRateBps(stableMode: self.isStableSwap())
	}
	
	access(all)
	fun getStableCurveP(): UFix64{ 
		return 1.0
	}
	
	/// Public interfaces
	///
	access(all)
	resource PairPublic: SwapInterfaces.PairPublic{ 
		access(all)
		fun swap(vaultIn: @{FungibleToken.Vault}, exactAmountOut: UFix64?): @{FungibleToken.Vault}{ 
			return <-SwapPair.swap(vaultIn: <-vaultIn, exactAmountOut: exactAmountOut)
		}
		
		access(all)
		fun flashloan(executorCap: Capability<&{SwapInterfaces.FlashLoanExecutor}>, requestedTokenVaultType: Type, requestedAmount: UFix64, params:{ String: AnyStruct}){ 
			SwapPair.flashloan(executorCap: executorCap, requestedTokenVaultType: requestedTokenVaultType, requestedAmount: requestedAmount, params: params)
		}
		
		access(all)
		fun removeLiquidity(lpTokenVault: @{FungibleToken.Vault}): @[{FungibleToken.Vault}]{ 
			return <-SwapPair.removeLiquidity(lpTokenVault: <-lpTokenVault)
		}
		
		access(all)
		fun addLiquidity(tokenAVault: @{FungibleToken.Vault}, tokenBVault: @{FungibleToken.Vault}): @{FungibleToken.Vault}{ 
			return <-SwapPair.addLiquidity(tokenAVault: <-tokenAVault, tokenBVault: <-tokenBVault)
		}
		
		access(all)
		fun getAmountIn(amountOut: UFix64, tokenOutKey: String): UFix64{ 
			if SwapPair.isStableSwap(){ 
				if tokenOutKey == SwapPair.token1Key{ 
					return SwapConfig.getAmountInStable(amountOut: amountOut, reserveIn: SwapPair.token0Vault.balance, reserveOut: SwapPair.token1Vault.balance, p: SwapPair.getStableCurveP(), swapFeeRateBps: SwapPair.getSwapFeeBps())
				} else{ 
					return SwapConfig.getAmountInStable(amountOut: amountOut, reserveIn: SwapPair.token1Vault.balance, reserveOut: SwapPair.token0Vault.balance, p: 1.0 / SwapPair.getStableCurveP(), swapFeeRateBps: SwapPair.getSwapFeeBps())
				}
			} else if tokenOutKey == SwapPair.token1Key{ 
				return SwapConfig.getAmountInVolatile(amountOut: amountOut, reserveIn: SwapPair.token0Vault.balance, reserveOut: SwapPair.token1Vault.balance, swapFeeRateBps: SwapPair.getSwapFeeBps())
			} else{ 
				return SwapConfig.getAmountInVolatile(amountOut: amountOut, reserveIn: SwapPair.token1Vault.balance, reserveOut: SwapPair.token0Vault.balance, swapFeeRateBps: SwapPair.getSwapFeeBps())
			}
		}
		
		access(all)
		fun getAmountOut(amountIn: UFix64, tokenInKey: String): UFix64{ 
			if SwapPair.isStableSwap(){ 
				if tokenInKey == SwapPair.token0Key{ 
					return SwapConfig.getAmountOutStable(amountIn: amountIn, reserveIn: SwapPair.token0Vault.balance, reserveOut: SwapPair.token1Vault.balance, p: SwapPair.getStableCurveP(), swapFeeRateBps: SwapPair.getSwapFeeBps())
				} else{ 
					return SwapConfig.getAmountOutStable(amountIn: amountIn, reserveIn: SwapPair.token1Vault.balance, reserveOut: SwapPair.token0Vault.balance, p: 1.0 / SwapPair.getStableCurveP(), swapFeeRateBps: SwapPair.getSwapFeeBps())
				}
			} else if tokenInKey == SwapPair.token0Key{ 
				return SwapConfig.getAmountOutVolatile(amountIn: amountIn, reserveIn: SwapPair.token0Vault.balance, reserveOut: SwapPair.token1Vault.balance, swapFeeRateBps: SwapPair.getSwapFeeBps())
			} else{ 
				return SwapConfig.getAmountOutVolatile(amountIn: amountIn, reserveIn: SwapPair.token1Vault.balance, reserveOut: SwapPair.token0Vault.balance, swapFeeRateBps: SwapPair.getSwapFeeBps())
			}
		}
		
		access(all)
		fun getPrice0CumulativeLastScaled(): UInt256{ 
			return SwapPair.price0CumulativeLastScaled
		}
		
		access(all)
		fun getPrice1CumulativeLastScaled(): UInt256{ 
			return SwapPair.price1CumulativeLastScaled
		}
		
		access(all)
		fun getBlockTimestampLast(): UFix64{ 
			return SwapPair.blockTimestampLast
		}
		
		access(all)
		fun getPairInfo(): [AnyStruct]{ 
			return [SwapPair.token0Key, // 0										
										SwapPair.token1Key, SwapPair.token0Vault.balance, SwapPair.token1Vault.balance, SwapPair.account.address, SwapPair.totalSupply, // 5																																										
																																										SwapPair.getSwapFeeBps(), SwapPair.isStableSwap(), SwapPair.getStableCurveP()]
		}
		
		access(all)
		fun getLpTokenVaultType(): Type{ 
			return Type<@SwapPair.Vault>()
		}
		
		access(all)
		fun isStableSwap(): Bool{ 
			return SwapPair.isStableSwap()
		}
		
		access(all)
		fun getStableCurveP(): UFix64{ 
			return SwapPair.getStableCurveP()
		}
	}
	
	init(token0Vault: @{FungibleToken.Vault}, token1Vault: @{FungibleToken.Vault}, stableMode: Bool){ 
		self.totalSupply = 0.0
		self.token0VaultType = token0Vault.getType()
		self.token1VaultType = token1Vault.getType()
		self.token0Vault <- token0Vault
		self.token1Vault <- token1Vault
		self.lock = false
		self.blockTimestampLast = getCurrentBlock().timestamp
		self.price0CumulativeLastScaled = 0
		self.price1CumulativeLastScaled = 0
		self.rootKLast = 0.0
		self._reservedFields ={} 
		self._reservedFields["isStableSwap"] = stableMode
		self.token0Key = SwapConfig.SliceTokenTypeIdentifierFromVaultType(vaultTypeIdentifier: self.token0VaultType.identifier)
		self.token1Key = SwapConfig.SliceTokenTypeIdentifierFromVaultType(vaultTypeIdentifier: self.token1VaultType.identifier)
		
		/// Open public interface capability
		destroy <-self.account.storage.load<@AnyResource>(from: /storage/pair_public)
		self.account.storage.save(<-create PairPublic(), to: /storage/pair_public)
		/// Pair interface public path: SwapConfig.PairPublicPath
		var capability_1 = self.account.capabilities.storage.issue<&{SwapInterfaces.PairPublic}>(/storage/pair_public)
		self.account.capabilities.publish(capability_1, at: SwapConfig.PairPublicPath)
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
