import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import SwapConfig from "../0xb78ef7afa52ff906/SwapConfig.cdc"
import SwapFactory from "../0xb063c16cac85dbd1/SwapFactory.cdc"
import SwapInterfaces from "../0xb78ef7afa52ff906/SwapInterfaces.cdc"

pub contract SwapTools {
    pub resource Executor: SwapInterfaces.FlashLoanExecutor {
        pub let callback: ((@FungibleToken.Vault, UFix64): @FungibleToken.Vault)

        pub fun executeAndRepay(loanedToken: @FungibleToken.Vault, params: {String: AnyStruct}): @FungibleToken.Vault {
            let amountIn = loanedToken.balance
            let amountOut = amountIn * (1.0 + UFix64(SwapFactory.getFlashloanRateBps()) / 10000.0) + SwapConfig.ufix64NonZeroMin            
            return <- self.callback(<-loanedToken, amountOut)
        }

        init(callback: ((@FungibleToken.Vault, UFix64): @FungibleToken.Vault)) {
            self.callback = callback
        }
    }

    pub fun createExecutor(callback: ((@FungibleToken.Vault, UFix64): @FungibleToken.Vault)): @Executor {
        return <- create Executor(callback: callback)
    }
}
