import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import StarlyToken from "../0x142fa6570b62fd97/StarlyToken.cdc"

import TeleportedTetherToken from "../0xcfdd90d4a00f7b5b/TeleportedTetherToken.cdc"

// Exchange pair between StarlyToken and TeleportedTetherToken
// Token1: StarlyToken
// Token2: TeleportedTetherToken
access(all)
contract StarlyUsdtSwapPair: FungibleToken{ 
	// Frozen flag controlled by Admin
	access(all)
	var isFrozen: Bool
	
	// Total supply of StarlyUsdtSwapPair liquidity token in existence
	access(all)
	var totalSupply: UFix64
	
	// Fee charged when performing token swap
	access(all)
	var feePercentage: UFix64
	
	// Controls StarlyToken vault
	access(contract)
	let token1Vault: @StarlyToken.Vault
	
	// Controls TeleportedTetherToken vault
	access(contract)
	let token2Vault: @TeleportedTetherToken.Vault
	
	// Defines token vault storage path
	access(all)
	let TokenStoragePath: StoragePath
	
	// Defines token vault public balance path
	access(all)
	let TokenPublicBalancePath: PublicPath
	
	// Defines token vault public receiver path
	access(all)
	let TokenPublicReceiverPath: PublicPath
	
	// Event that is emitted when the contract is created
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	// Event that is emitted when tokens are withdrawn from a Vault
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	// Event that is emitted when tokens are deposited to a Vault
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	// Event that is emitted when new tokens are minted
	access(all)
	event TokensMinted(amount: UFix64)
	
	// Event that is emitted when tokens are destroyed
	access(all)
	event TokensBurned(amount: UFix64)
	
	// Event that is emitted when trading fee is updated
	access(all)
	event FeeUpdated(feePercentage: UFix64)
	
	// Event that is emitted when a swap happens
	// Side 1: from token1 to token2
	// Side 2: from token2 to token1
	access(all)
	event Trade(token1Amount: UFix64, token2Amount: UFix64, side: UInt8)
	
	// Vault
	//
	// Each user stores an instance of only the Vault in their storage
	// The functions in the Vault and governed by the pre and post conditions
	// in StarlyUsdtSwapPair when they are called.
	// The checks happen at runtime whenever a function is called.
	//
	// Resources can only be created in the context of the contract that they
	// are defined in, so there is no way for a malicious user to create Vaults
	// out of thin air. A special Minter resource needs to be defined to mint
	// new tokens.
	//
	access(all)
	resource Vault: FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance{ 
		
		// holds the balance of a users tokens
		access(all)
		var balance: UFix64
		
		// initialize the balance at resource creation time
		init(balance: UFix64){ 
			self.balance = balance
		}
		
		// withdraw
		//
		// Function that takes an integer amount as an argument
		// and withdraws that amount from the Vault.
		// It creates a new temporary Vault that is used to hold
		// the money that is being transferred. It returns the newly
		// created Vault to the context that called so it can be deposited
		// elsewhere.
		//
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			self.balance = self.balance - amount
			emit TokensWithdrawn(amount: amount, from: self.owner?.address)
			return <-create Vault(balance: amount)
		}
		
		// deposit
		//
		// Function that takes a Vault object as an argument and adds
		// its balance to the balance of the owners Vault.
		// It is allowed to destroy the sent Vault because the Vault
		// was a temporary holder of the tokens. The Vault's balance has
		// been consumed and therefore can be destroyed.
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @StarlyUsdtSwapPair.Vault
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
	
	// createEmptyVault
	//
	// Function that creates a new Vault with a balance of zero
	// and returns it to the calling context. A user must call this function
	// and store the returned Vault in their storage in order to allow their
	// account to be able to receive deposits of this token type.
	//
	access(all)
	fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault}{ 
		return <-create Vault(balance: 0.0)
	}
	
	access(all)
	resource TokenBundle{ 
		access(all)
		var token1: @StarlyToken.Vault
		
		access(all)
		var token2: @TeleportedTetherToken.Vault
		
		// initialize the vault bundle
		init(fromToken1: @StarlyToken.Vault, fromToken2: @TeleportedTetherToken.Vault){ 
			self.token1 <- fromToken1
			self.token2 <- fromToken2
		}
		
		access(all)
		fun depositToken1(from: @StarlyToken.Vault){ 
			self.token1.deposit(from: <-(from as!{ FungibleToken.Vault}))
		}
		
		access(all)
		fun depositToken2(from: @TeleportedTetherToken.Vault){ 
			self.token2.deposit(from: <-(from as!{ FungibleToken.Vault}))
		}
		
		access(all)
		fun withdrawToken1(): @StarlyToken.Vault{ 
			var vault <- StarlyToken.createEmptyVault(vaultType: Type<@StarlyToken.Vault>()) as! @StarlyToken.Vault
			vault <-> self.token1
			return <-vault
		}
		
		access(all)
		fun withdrawToken2(): @TeleportedTetherToken.Vault{ 
			var vault <- TeleportedTetherToken.createEmptyVault(vaultType: Type<@TeleportedTetherToken.Vault>()) as! @TeleportedTetherToken.Vault
			vault <-> self.token2
			return <-vault
		}
	}
	
	// createEmptyBundle
	//
	access(all)
	fun createEmptyTokenBundle(): @StarlyUsdtSwapPair.TokenBundle{ 
		return <-create TokenBundle(fromToken1: <-(StarlyToken.createEmptyVault(vaultType: Type<@StarlyToken.Vault>()) as! @StarlyToken.Vault), fromToken2: <-(TeleportedTetherToken.createEmptyVault(vaultType: Type<@TeleportedTetherToken.Vault>()) as! @TeleportedTetherToken.Vault))
	}
	
	// createTokenBundle
	//
	access(all)
	fun createTokenBundle(fromToken1: @StarlyToken.Vault, fromToken2: @TeleportedTetherToken.Vault): @StarlyUsdtSwapPair.TokenBundle{ 
		return <-create TokenBundle(fromToken1: <-fromToken1, fromToken2: <-fromToken2)
	}
	
	// mintTokens
	//
	// Function that mints new tokens, adds them to the total supply,
	// and returns them to the calling context.
	//
	access(contract)
	fun mintTokens(amount: UFix64): @StarlyUsdtSwapPair.Vault{ 
		pre{ 
			amount > 0.0:
				"Amount minted must be greater than zero"
		}
		StarlyUsdtSwapPair.totalSupply = StarlyUsdtSwapPair.totalSupply + amount
		emit TokensMinted(amount: amount)
		return <-create Vault(balance: amount)
	}
	
	// burnTokens
	//
	// Function that destroys a Vault instance, effectively burning the tokens.
	//
	// Note: the burned tokens are automatically subtracted from the 
	// total supply in the Vault destructor.
	//
	access(contract)
	fun burnTokens(from: @StarlyUsdtSwapPair.Vault){ 
		let vault <- from as! @StarlyUsdtSwapPair.Vault
		let amount = vault.balance
		destroy vault
		emit TokensBurned(amount: amount)
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun freeze(){ 
			StarlyUsdtSwapPair.isFrozen = true
		}
		
		access(all)
		fun unfreeze(){ 
			StarlyUsdtSwapPair.isFrozen = false
		}
		
		access(all)
		fun addInitialLiquidity(from: @StarlyUsdtSwapPair.TokenBundle): @StarlyUsdtSwapPair.Vault{ 
			pre{ 
				StarlyUsdtSwapPair.totalSupply == 0.0:
					"Pair already initialized"
			}
			let token1Vault <- from.withdrawToken1()
			let token2Vault <- from.withdrawToken2()
			assert(token1Vault.balance > 0.0, message: "Empty token1 vault")
			assert(token2Vault.balance > 0.0, message: "Empty token2 vault")
			StarlyUsdtSwapPair.token1Vault.deposit(from: <-token1Vault)
			StarlyUsdtSwapPair.token2Vault.deposit(from: <-token2Vault)
			destroy from
			
			// Create initial tokens
			return <-StarlyUsdtSwapPair.mintTokens(amount: 1.0)
		}
		
		access(all)
		fun updateFeePercentage(feePercentage: UFix64){ 
			StarlyUsdtSwapPair.feePercentage = feePercentage
			emit FeeUpdated(feePercentage: feePercentage)
		}
	}
	
	access(all)
	struct PoolAmounts{ 
		access(all)
		let token1Amount: UFix64
		
		access(all)
		let token2Amount: UFix64
		
		init(token1Amount: UFix64, token2Amount: UFix64){ 
			self.token1Amount = token1Amount
			self.token2Amount = token2Amount
		}
	}
	
	access(all)
	fun getFeePercentage(): UFix64{ 
		return self.feePercentage
	}
	
	// Check current pool amounts
	access(all)
	fun getPoolAmounts(): PoolAmounts{ 
		return PoolAmounts(token1Amount: StarlyUsdtSwapPair.token1Vault.balance, token2Amount: StarlyUsdtSwapPair.token2Vault.balance)
	}
	
	// Get quote for Token1 (given) -> Token2
	access(all)
	fun quoteSwapExactToken1ForToken2(amount: UFix64): UFix64{ 
		let poolAmounts = self.getPoolAmounts()
		
		// token1Amount * token2Amount = token1Amount' * token2Amount' = (token1Amount + amount) * (token2Amount - quote)
		let quote = poolAmounts.token2Amount * amount / (poolAmounts.token1Amount + amount)
		return quote
	}
	
	// Get quote for Token1 -> Token2 (given)
	access(all)
	fun quoteSwapToken1ForExactToken2(amount: UFix64): UFix64{ 
		let poolAmounts = self.getPoolAmounts()
		assert(poolAmounts.token2Amount > amount, message: "Not enough Token2 in the pool")
		
		// token1Amount * token2Amount = token1Amount' * token2Amount' = (token1Amount + quote) * (token2Amount - amount)
		let quote = poolAmounts.token1Amount * amount / (poolAmounts.token2Amount - amount)
		return quote
	}
	
	// Get quote for Token2 (given) -> Token1
	access(all)
	fun quoteSwapExactToken2ForToken1(amount: UFix64): UFix64{ 
		let poolAmounts = self.getPoolAmounts()
		
		// token1Amount * token2Amount = token1Amount' * token2Amount' = (token2Amount + amount) * (token1Amount - quote)
		let quote = poolAmounts.token1Amount * amount / (poolAmounts.token2Amount + amount)
		return quote
	}
	
	// Get quote for Token2 -> Token1 (given)
	access(all)
	fun quoteSwapToken2ForExactToken1(amount: UFix64): UFix64{ 
		let poolAmounts = self.getPoolAmounts()
		assert(poolAmounts.token1Amount > amount, message: "Not enough Token1 in the pool")
		
		// token1Amount * token2Amount = token1Amount' * token2Amount' = (token2Amount + quote) * (token1Amount - amount)
		let quote = poolAmounts.token2Amount * amount / (poolAmounts.token1Amount - amount)
		return quote
	}
	
	// Swaps Token1 (STARLY) -> Token2 (tUSDT)
	access(contract)
	fun _swapToken1ForToken2(from: @StarlyToken.Vault): @TeleportedTetherToken.Vault{ 
		pre{ 
			!StarlyUsdtSwapPair.isFrozen:
				"StarlyUsdtSwapPair is frozen"
			from.balance > 0.0:
				"Empty token vault"
		}
		
		// Calculate amount from pricing curve
		// A fee portion is taken from the final amount
		let token1Amount = from.balance * (1.0 - self.feePercentage)
		let token2Amount = self.quoteSwapExactToken1ForToken2(amount: token1Amount)
		assert(token2Amount > 0.0, message: "Exchanged amount too small")
		self.token1Vault.deposit(from: <-(from as!{ FungibleToken.Vault}))
		emit Trade(token1Amount: token1Amount, token2Amount: token2Amount, side: 1)
		return <-(self.token2Vault.withdraw(amount: token2Amount) as! @TeleportedTetherToken.Vault)
	}
	
	access(all)
	fun swapToken1ForToken2(from: @StarlyToken.Vault): @TeleportedTetherToken.Vault{ 
		return <-StarlyUsdtSwapPair._swapToken1ForToken2(from: <-from)
	}
	
	// Swap Token2 (tUSDT) -> Token1 (STARLY)
	access(contract)
	fun _swapToken2ForToken1(from: @TeleportedTetherToken.Vault): @StarlyToken.Vault{ 
		pre{ 
			!StarlyUsdtSwapPair.isFrozen:
				"StarlyUsdtSwapPair is frozen"
			from.balance > 0.0:
				"Empty token vault"
		}
		
		// Calculate amount from pricing curve
		// A fee portion is taken from the final amount
		let token2Amount = from.balance * (1.0 - self.feePercentage)
		let token1Amount = self.quoteSwapExactToken2ForToken1(amount: token2Amount)
		assert(token1Amount > 0.0, message: "Exchanged amount too small")
		self.token2Vault.deposit(from: <-(from as!{ FungibleToken.Vault}))
		emit Trade(token1Amount: token1Amount, token2Amount: token2Amount, side: 2)
		return <-(self.token1Vault.withdraw(amount: token1Amount) as! @StarlyToken.Vault)
	}
	
	access(all)
	fun swapToken2ForToken1(from: @TeleportedTetherToken.Vault): @StarlyToken.Vault{ 
		return <-StarlyUsdtSwapPair._swapToken2ForToken1(from: <-from)
	}
	
	// Used to add liquidity without minting new liquidity token
	access(all)
	fun donateLiquidity(from: @StarlyUsdtSwapPair.TokenBundle){ 
		let token1Vault <- from.withdrawToken1()
		let token2Vault <- from.withdrawToken2()
		StarlyUsdtSwapPair.token1Vault.deposit(from: <-token1Vault)
		StarlyUsdtSwapPair.token2Vault.deposit(from: <-token2Vault)
		destroy from
	}
	
	access(contract)
	fun _addLiquidity(from: @StarlyUsdtSwapPair.TokenBundle): @StarlyUsdtSwapPair.Vault{ 
		pre{ 
			self.totalSupply > 0.0:
				"Pair must be initialized by admin first"
		}
		let token1Vault <- from.withdrawToken1()
		let token2Vault <- from.withdrawToken2()
		assert(token1Vault.balance > 0.0, message: "Empty token1 vault")
		assert(token2Vault.balance > 0.0, message: "Empty token2 vault")
		
		// shift decimal 4 places to avoid truncation error
		let token1Percentage: UFix64 = token1Vault.balance * 10000.0 / StarlyUsdtSwapPair.token1Vault.balance
		let token2Percentage: UFix64 = token2Vault.balance * 10000.0 / StarlyUsdtSwapPair.token2Vault.balance
		
		// final liquidity token minted is the smaller between token1Liquidity and token2Liquidity
		// to maximize profit, user should add liquidity propotional to current liquidity
		let liquidityPercentage = token1Percentage < token2Percentage ? token1Percentage : token2Percentage
		assert(liquidityPercentage > 0.0, message: "Liquidity too small")
		StarlyUsdtSwapPair.token1Vault.deposit(from: <-token1Vault)
		StarlyUsdtSwapPair.token2Vault.deposit(from: <-token2Vault)
		let liquidityTokenVault <- StarlyUsdtSwapPair.mintTokens(amount: StarlyUsdtSwapPair.totalSupply * liquidityPercentage / 10000.0)
		destroy from
		return <-liquidityTokenVault
	}
	
	access(all)
	fun addLiquidity(from: @StarlyUsdtSwapPair.TokenBundle): @StarlyUsdtSwapPair.Vault{ 
		return <-StarlyUsdtSwapPair._addLiquidity(from: <-from)
	}
	
	access(contract)
	fun _removeLiquidity(from: @StarlyUsdtSwapPair.Vault): @StarlyUsdtSwapPair.TokenBundle{ 
		pre{ 
			from.balance > 0.0:
				"Empty liquidity token vault"
			from.balance < StarlyUsdtSwapPair.totalSupply:
				"Cannot remove all liquidity"
		}
		
		// shift decimal 4 places to avoid truncation error
		let liquidityPercentage = from.balance * 10000.0 / StarlyUsdtSwapPair.totalSupply
		assert(liquidityPercentage > 0.0, message: "Liquidity too small")
		
		// Burn liquidity tokens and withdraw
		StarlyUsdtSwapPair.burnTokens(from: <-from)
		let token1Vault <- StarlyUsdtSwapPair.token1Vault.withdraw(amount: StarlyUsdtSwapPair.token1Vault.balance * liquidityPercentage / 10000.0) as! @StarlyToken.Vault
		let token2Vault <- StarlyUsdtSwapPair.token2Vault.withdraw(amount: StarlyUsdtSwapPair.token2Vault.balance * liquidityPercentage / 10000.0) as! @TeleportedTetherToken.Vault
		let tokenBundle <- StarlyUsdtSwapPair.createTokenBundle(fromToken1: <-token1Vault, fromToken2: <-token2Vault)
		return <-tokenBundle
	}
	
	access(all)
	fun removeLiquidity(from: @StarlyUsdtSwapPair.Vault): @StarlyUsdtSwapPair.TokenBundle{ 
		return <-StarlyUsdtSwapPair._removeLiquidity(from: <-from)
	}
	
	init(){ 
		self.isFrozen = true // frozen until admin unfreezes
		
		self.totalSupply = 0.0
		self.feePercentage = 0.003 // 0.3%
		
		self.TokenStoragePath = /storage/StarlyUsdtSwapLpVault
		self.TokenPublicBalancePath = /public/StarlyUsdtSwapLpBalance
		self.TokenPublicReceiverPath = /public/StarlyUsdtSwapLpReceiver
		
		// Setup internal StarlyToken vault
		self.token1Vault <- StarlyToken.createEmptyVault(vaultType: Type<@StarlyToken.Vault>()) as! @StarlyToken.Vault
		
		// Setup internal TeleportedTetherToken vault
		self.token2Vault <- TeleportedTetherToken.createEmptyVault(vaultType: Type<@TeleportedTetherToken.Vault>()) as! @TeleportedTetherToken.Vault
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: /storage/StarlyUsdtSwapAdmin)
		
		// Emit an event that shows that the contract was initialized
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
