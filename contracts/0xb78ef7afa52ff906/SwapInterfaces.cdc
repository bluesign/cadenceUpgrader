/**

# Swap related interface definitions all-in-one

# Author: Increment Labs

*/
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

pub contract interface SwapInterfaces {
    pub resource interface PairPublic {
        pub fun addLiquidity(tokenAVault: @FungibleToken.Vault, tokenBVault: @FungibleToken.Vault): @FungibleToken.Vault
        pub fun removeLiquidity(lpTokenVault: @FungibleToken.Vault) : @[FungibleToken.Vault]
        pub fun swap(vaultIn: @FungibleToken.Vault, exactAmountOut: UFix64?): @FungibleToken.Vault
        pub fun flashloan(executorCap: Capability<&{SwapInterfaces.FlashLoanExecutor}>, requestedTokenVaultType: Type, requestedAmount: UFix64, params: {String: AnyStruct}) { return }
        pub fun getAmountIn(amountOut: UFix64, tokenOutKey: String): UFix64
        pub fun getAmountOut(amountIn: UFix64, tokenInKey: String): UFix64
        pub fun getPrice0CumulativeLastScaled(): UInt256
        pub fun getPrice1CumulativeLastScaled(): UInt256
        pub fun getBlockTimestampLast(): UFix64
        pub fun getPairInfo(): [AnyStruct]
        pub fun getLpTokenVaultType(): Type
        pub fun isStableSwap(): Bool { return false }
        pub fun getStableCurveP(): UFix64 { return 1.0 }
    }

    pub resource interface LpTokenCollectionPublic {
        pub fun deposit(pairAddr: Address, lpTokenVault: @FungibleToken.Vault)
        pub fun getCollectionLength(): Int
        pub fun getLpTokenBalance(pairAddr: Address): UFix64
        pub fun getAllLPTokens(): [Address]
        pub fun getSlicedLPTokens(from: UInt64, to: UInt64): [Address]
    }

    pub resource interface FlashLoanExecutor {
        pub fun executeAndRepay(loanedToken: @FungibleToken.Vault, params: {String: AnyStruct}): @FungibleToken.Vault
    }
}
