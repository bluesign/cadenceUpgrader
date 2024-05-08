import FiatToken from "../0xb19436aae4d94622/FiatToken.cdc"
import FlowSwapPair from "../0xc6c77b9f5c7a378f/FlowSwapPair.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import IPierPair from "../0x609e10301860b683/IPierPair.cdc"
import PierPair from "../0x609e10301860b683/PierPair.cdc"
import SwapConfig from "../0xb78ef7afa52ff906/SwapConfig.cdc"
import SwapFactory from "../0xb063c16cac85dbd1/SwapFactory.cdc"
import SwapInterfaces from "../0xb78ef7afa52ff906/SwapInterfaces.cdc"
import UsdcUsdtSwapPair from "../0x9c6f94adf47904b5/UsdcUsdtSwapPair.cdc"

pub contract SwapPair {
    access(self) fun bloctoScaledReserves(): [UInt256] {
        return [
            SwapConfig.UFix64ToScaledUInt256(FlowSwapPair.getPoolAmounts().token1Amount),
            SwapConfig.UFix64ToScaledUInt256(FlowSwapPair.getPoolAmounts().token2Amount)
        ]
    }
    access(self) fun bloctoUsdScaledReserves(): [UInt256] {
        return [
            SwapConfig.UFix64ToScaledUInt256(UsdcUsdtSwapPair.getPoolAmounts().token1Amount),
            SwapConfig.UFix64ToScaledUInt256(UsdcUsdtSwapPair.getPoolAmounts().token2Amount)
        ]
    }

    access(self) fun incrementScaledReserves(): [UInt256] {
        let pairInfo = getAccount(0xfa82796435e15832).getCapability<&{SwapInterfaces.PairPublic}>(SwapConfig.PairPublicPath).borrow()!.getPairInfo()
        return [
            SwapConfig.UFix64ToScaledUInt256(pairInfo[2] as! UFix64),
            SwapConfig.UFix64ToScaledUInt256(pairInfo[3] as! UFix64)
        ]
    }

    access(self) fun metaScaledReserves(): [UInt256] {
        let mpool = getAccount(0x18187a9d276c0329).getCapability<&PierPair.Pool{IPierPair.IPool}>(/public/metapierSwapPoolPublic).borrow()!
        let mpoolInfo = mpool.getReserves()
        return [
            SwapConfig.UFix64ToScaledUInt256(mpoolInfo[0]),
            SwapConfig.UFix64ToScaledUInt256(mpoolInfo[1])
        ]
    }

    access(self) fun aggregateReserves(): [UFix64] {
        var fr: UInt256 = 0
        var ur: UInt256 = 0
        
        var r = self.incrementScaledReserves()
        fr = fr + r[0]
        ur = ur + r[1]
        r = self.metaScaledReserves()
        fr = fr + r[0]
        ur = ur + r[1]
        r = self.bloctoScaledReserves()
        fr = fr + r[0]
        ur = ur + r[1]

        return [
            SwapConfig.ScaledUInt256ToUFix64(fr),
            SwapConfig.ScaledUInt256ToUFix64(ur)
        ]
    }

    access(self) fun getTokenOutVault(_ vaultInType: Type): @FungibleToken.Vault {
        if vaultInType == self.token0VaultType {
            return <- FiatToken.createEmptyVault()
        }
        return <- FlowToken.createEmptyVault()
    }

    access(self) fun checkBloctoAmounts(_ amountIn: UFix64, _ vaultInType: Type): Bool {
        if UsdcUsdtSwapPair.isFrozen {
            return false
        }

        let ur = self.bloctoUsdScaledReserves()
        if vaultInType == self.token0VaultType {
            let amountOut = FlowSwapPair.quoteSwapExactToken1ForToken2(amount: amountIn)
            return amountOut <= SwapConfig.ScaledUInt256ToUFix64(ur[0])
        } else {
            return amountIn <= SwapConfig.ScaledUInt256ToUFix64(ur[1])
        }
    }

    pub fun swap(vaultIn: @FungibleToken.Vault, exactAmountOut: UFix64?): @FungibleToken.Vault {
        pre { self.check(vaultIn.balance): "SwapPair : swap failed" }

        var mr: [[UInt256]] = []
        mr.append(self.incrementScaledReserves())
        mr.append(self.metaScaledReserves())
        mr.append(self.bloctoScaledReserves())

        var idx = 0
        if vaultIn.isInstance(self.token1VaultType) {
            idx = 1
        }

        var groupAmounts = self.splitAllAmounts(vaultIn.balance, idx, mr)
        if !self.checkBloctoAmounts(groupAmounts[2], vaultIn.getType()) {
            mr = [mr[0], mr[1]]
            groupAmounts = self.splitAllAmounts(vaultIn.balance, idx, mr)
        }

        let swapOutVault <- self.getTokenOutVault(vaultIn.getType())

        var i = 0
        while i < groupAmounts.length {
            var amountIn = groupAmounts[i]
            if i == groupAmounts.length - 1 {
                amountIn = vaultIn.balance
            }
            if amountIn > 0.0 {
                let exactInVault <-vaultIn.withdraw(amount: amountIn)
                var vaultOut <- self.swapOnPlatform(vaultIn: <-exactInVault, p: i)
                swapOutVault.deposit(from: <-vaultOut)
            }
            i = i + 1
        }

        assert(vaultIn.balance == 0.0, message: "SwapPair: swap failed")
        destroy vaultIn

        return <-swapOutVault!
    }
    

    pub fun swapOnPlatform(vaultIn: @FungibleToken.Vault, p: Int): @FungibleToken.Vault {
        switch p {
        case 0:
            let pair = getAccount(0xfa82796435e15832).getCapability<&{SwapInterfaces.PairPublic}>(SwapConfig.PairPublicPath).borrow()!
            if vaultIn.isInstance(self.token0VaultType) {
                return <- pair.swap(vaultIn: <- vaultIn, exactAmountOut: nil)
            } else {
                return <- pair.swap(vaultIn: <- vaultIn, exactAmountOut: nil)
            }
        case 1:
            let mpool = getAccount(0x18187a9d276c0329).getCapability<&PierPair.Pool{IPierPair.IPool}>(/public/metapierSwapPoolPublic).borrow()!
            let minfo = mpool.getReserves()
            if vaultIn.isInstance(self.token0VaultType) {
                let forAmount = SwapConfig.getAmountOutVolatile(amountIn: vaultIn.balance, reserveIn: minfo[0], reserveOut: minfo[1], swapFeeRateBps: 30)
                return <- mpool.swap(fromVault: <- vaultIn, forAmount: forAmount)
            } else {
                let forAmount = SwapConfig.getAmountOutVolatile(amountIn: vaultIn.balance, reserveIn: minfo[1], reserveOut: minfo[0], swapFeeRateBps: 30)
                return <- mpool.swap(fromVault: <- vaultIn, forAmount: forAmount)
            }
        case 2:
            if vaultIn.isInstance(self.token0VaultType) {
                let token0Vault <- FlowSwapPair.swapToken1ForToken2(from: <- (vaultIn as! @FlowToken.Vault))
                return <- UsdcUsdtSwapPair.swapToken2ForToken1(from: <- token0Vault)
            } else {
                let token0Vault <- UsdcUsdtSwapPair.swapToken1ForToken2(from: <- (vaultIn as! @FiatToken.Vault))
                return <- FlowSwapPair.swapToken2ForToken1(from: <- token0Vault)
            }
        }
        return <- vaultIn
    }

    access(self) fun splitAllAmounts(_ amountIn: UFix64, _ idx: Int, _ mr: [[UInt256]]): [UFix64] {
        var i  = 0
        var j = 0
        var g: [UInt256] = []
        var amounts: [UFix64] = []
        while i < mr.length {
            g.append(mr[i][idx])
            if i > 0 && i < mr.length - 1 {
                g.append(g[g.length-1]+g[g.length-2])
            }
            amounts.append(0.0)
            i = i + 1
        }

        i = g.length - 1
        var swapIn = SwapConfig.UFix64ToScaledUInt256(amountIn)
        while i > 0 {
            let a = self.splitPairAmounts(swapIn, g[i], g[i-1])
            swapIn = a[1]
            if i == 1 {
                amounts[0] = SwapConfig.ScaledUInt256ToUFix64(a[1])
            }
            amounts[j] = SwapConfig.ScaledUInt256ToUFix64(a[0])
            i = i - 2
            j = j + 1
        }

        return amounts
    }

    access(self) fun splitPairAmounts(_ amountIn: UInt256, _ r0: UInt256, _ r1: UInt256): [UInt256] {
        let a1 = (amountIn * r1) / (r0 + r1)
        let a0 = amountIn - a1
        return [a0, a1]
    }

    access(self) fun check(_ amount: UFix64): Bool {
        let current = getCurrentBlock().height
        self.prune(current)

        if self.keys.containsKey(amount) {
            return false
        }

        self.keys.insert(key: amount, current)

        return true
    }

    access(self) fun prune(_ height: UInt64) {
        for k in self.keys.keys {
            let value = self.keys[k]!
            if height - value > 100 {
                self.keys.remove(key: k)
            }
        }
    }

    pub fun addLiquidity(tokenAVault: @FungibleToken.Vault, tokenBVault: @FungibleToken.Vault): @FungibleToken.Vault { 
        pre { false: "SwapPair: added incompatible liquidity pair vaults" }
        self.token0Vault.deposit(from: <-tokenAVault)
        self.token1Vault.deposit(from: <-tokenBVault)
        return <- FlowToken.createEmptyVault()
    }

    pub fun removeLiquidity(lpTokenVault: @FungibleToken.Vault) : @[FungibleToken.Vault] { 
        pre { false: "SwapPair: input vault type mismatch with lpTokenVault type" }
        return <- [<-lpTokenVault]
    }

    pub fun getSwapFeeBps(): UInt64 {
        return SwapFactory.getSwapFeeRateBps(stableMode: false)
    }

    pub resource PairPublic: SwapInterfaces.PairPublic {
        pub fun swap(vaultIn: @FungibleToken.Vault, exactAmountOut: UFix64?): @FungibleToken.Vault {
            return <- SwapPair.swap(vaultIn: <-vaultIn, exactAmountOut: exactAmountOut)
        }

        pub fun flashloan(executorCap: Capability<&{SwapInterfaces.FlashLoanExecutor}>, requestedTokenVaultType: Type, requestedAmount: UFix64, params: {String: AnyStruct}) { }

        pub fun removeLiquidity(lpTokenVault: @FungibleToken.Vault) : @[FungibleToken.Vault] {
            return <- SwapPair.removeLiquidity(lpTokenVault: <- lpTokenVault)
        }

        pub fun addLiquidity(tokenAVault: @FungibleToken.Vault, tokenBVault: @FungibleToken.Vault): @FungibleToken.Vault {
            return <- SwapPair.addLiquidity(tokenAVault: <- tokenAVault, tokenBVault: <- tokenBVault)
        }

        pub fun getAmountIn(amountOut: UFix64, tokenOutKey: String): UFix64 {
            let r = SwapPair.aggregateReserves()
            if tokenOutKey == SwapPair.token0Key {
                return SwapConfig.getAmountInVolatile(amountOut: amountOut, reserveIn: r[1], reserveOut: r[0], swapFeeRateBps: SwapPair.getSwapFeeBps())
            } else {
                return SwapConfig.getAmountInVolatile(amountOut: amountOut, reserveIn: r[0], reserveOut: r[1], swapFeeRateBps: SwapPair.getSwapFeeBps())
            }
        }
        pub fun getAmountOut(amountIn: UFix64, tokenInKey: String): UFix64 { 
            let r = SwapPair.aggregateReserves()
            if tokenInKey == SwapPair.token0Key {
                return SwapConfig.getAmountOutVolatile(amountIn: amountIn, reserveIn: r[0], reserveOut: r[1], swapFeeRateBps: SwapPair.getSwapFeeBps())
            } else {
                return SwapConfig.getAmountOutVolatile(amountIn: amountIn, reserveIn: r[1], reserveOut: r[0], swapFeeRateBps: SwapPair.getSwapFeeBps())
            }
        }
        pub fun getPrice0CumulativeLastScaled(): UInt256 {
            return 0
        }
        pub fun getPrice1CumulativeLastScaled(): UInt256 {
            return 0
        }
        pub fun getBlockTimestampLast(): UFix64 {
            return 0.0
        }

        pub fun getPairInfo(): [AnyStruct] {
            return []
        }

        pub fun getLpTokenVaultType(): Type {
            return Type<@FlowToken.Vault>()
        }

        pub fun isStableSwap(): Bool {
            return false
        }

        pub fun getStableCurveP(): UFix64 {
            return 0.0
        }
    }

    access(self) let token0Vault: @FungibleToken.Vault
    access(self) let token1Vault: @FungibleToken.Vault
    access(self) let token0VaultType: Type
    access(self) let token1VaultType: Type
    access(self) let token0Key: String
    access(self) let token1Key: String
    access(self) var keys: {UFix64: UInt64}

    init() {
        self.token0Vault <- FlowToken.createEmptyVault()
        self.token1Vault <- FiatToken.createEmptyVault()
        self.token0VaultType = self.token0Vault.getType()
        self.token1VaultType = self.token1Vault.getType()
        self.token0Key = SwapConfig.SliceTokenTypeIdentifierFromVaultType(vaultTypeIdentifier: self.token0VaultType.identifier)
        self.token1Key = SwapConfig.SliceTokenTypeIdentifierFromVaultType(vaultTypeIdentifier: self.token1VaultType.identifier)
        self.keys = {}

        destroy <-self.account.load<@AnyResource>(from: /storage/pair_public)
        self.account.save(<-create PairPublic(), to: /storage/pair_public)
        self.account.link<&{SwapInterfaces.PairPublic}>(SwapConfig.PairPublicPath, target: /storage/pair_public)                
    }
}
