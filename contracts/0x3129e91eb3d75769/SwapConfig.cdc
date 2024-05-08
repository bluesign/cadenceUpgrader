/**

# Common configs & swap library functions

# Author: Increment Labs

*/

import SwapInterfaces from "../0xb78ef7afa52ff906/SwapInterfaces.cdc"

pub contract SwapConfig {
    pub var PairPublicPath: PublicPath
    pub var LpTokenCollectionStoragePath: StoragePath
    pub var LpTokenCollectionPublicPath: PublicPath

    /// Scale factor applied to fixed point number calculation.
    /// Note: The use of scale factor is due to fixed point number in cadence is only precise to 1e-8:
    /// https://docs.onflow.org/cadence/language/values-and-types/#fixed-point-numbers
    pub let scaleFactor: UInt256
    /// 100_000_000.0, i.e. 1.0e8
    pub let ufixScale: UFix64
    /// 0.00000001, i.e. 1e-8
    pub let ufix64NonZeroMin: UFix64
    /// Reserved parameter fields: {ParamName: Value}
    access(self) let _reservedFields: {String: AnyStruct}

    /// Utility function to convert a UFix64 number to its scaled equivalent in UInt256 format
    /// e.g. 184467440737.09551615 (UFix64.max) => 184467440737095516150000000000
    ///
    pub fun UFix64ToScaledUInt256(_ f: UFix64): UInt256 {
        let integral = UInt256(f)
        let fractional = f % 1.0
        let ufixScaledInteger =  integral * UInt256(self.ufixScale) + UInt256(fractional * self.ufixScale)
        return ufixScaledInteger * self.scaleFactor / UInt256(self.ufixScale)
    }

    /// Utility function to convert a fixed point number in form of scaled UInt256 back to UFix64 format
    /// e.g. 184467440737095516150000000000 => 184467440737.09551615
    ///
    pub fun ScaledUInt256ToUFix64(_ scaled: UInt256): UFix64 {
        let integral = scaled / self.scaleFactor
        let ufixScaledFractional = (scaled % self.scaleFactor) * UInt256(self.ufixScale) / self.scaleFactor
        return UFix64(integral) + (UFix64(ufixScaledFractional) / self.ufixScale)
    }

    /// Utility function to simulate addition of Word256, like Word64 not to throw an overflow error.
    /// e.g. 10 + UInt256.max = 9
    ///
    pub fun overflowAddUInt256(_ value1: UInt256, _ value2: UInt256): UInt256 {
        if value1 > UInt256.max - value2 {
            return value2 - (UInt256.max - value1) - 1
        } else {
            return value1 + value2
        }
    }

    /// Utility function to simulate subtraction of Word256.
    /// e.g. 10 - UInt256.max = 11
    ///
    pub fun underflowSubtractUInt256(_ value1: UInt256, _ value2: UInt256): UInt256 {
        if value1 >= value2 {
            return value1 - value2
        } else {
            return UInt256.max - value2 + value1 + 1
        }
    }

    /// SliceTokenTypeIdentifierFromVaultType
    ///
    /// @Param vaultTypeIdentifier - eg. A.f8d6e0586b0a20c7.FlowToken.Vault
    /// @Return tokenTypeIdentifier - eg. A.f8d6e0586b0a20c7.FlowToken
    ///
    pub fun SliceTokenTypeIdentifierFromVaultType(vaultTypeIdentifier: String): String {
        return vaultTypeIdentifier.slice(
            from: 0,
            upTo: vaultTypeIdentifier.length - 6
        )
    }

    /// Helper function:
    /// Compute √x using Newton's method.
    /// @Param - x: Scaled UFix64 number in cadence. e.g. UFix64ToScaledUInt256( 16.0 )
    ///
    pub fun sqrt(_ x: UInt256): UInt256 {
        var res: UInt256 = 0
        var one: UInt256 = self.scaleFactor
        if (x > 0) {
            var x0 = x
            var mid = (x + one) / 2
            while ((x0 > mid + 1) || (mid > x0 + 1)) {
                x0 = mid
                mid = (x0 + x * self.scaleFactor / x0) / 2
            }
            res = mid
        } else {
            res = 0
        }        
        return res
    }

    /// Deprecated Helper function:
    /// Given pair reserves and the exact input amount of an asset, returns the maximum output amount of the other asset
    /// [Deprecated] Use getAmountOutVolatile / getAmountOutStable instead.
    pub fun getAmountOut(amountIn: UFix64, reserveIn: UFix64, reserveOut: UFix64): UFix64 {
        pre {
            amountIn > 0.0: "SwapPair: insufficient input amount"
            reserveIn > 0.0 && reserveOut > 0.0: "SwapPair: insufficient liquidity"
        }
        let amountInScaled = self.UFix64ToScaledUInt256(amountIn)
        let reserveInScaled = self.UFix64ToScaledUInt256(reserveIn)
        let reserveOutScaled = self.UFix64ToScaledUInt256(reserveOut)

        let amountInWithFeeScaled = self.UFix64ToScaledUInt256(0.997) * amountInScaled / self.scaleFactor

        let amountOutScaled = amountInWithFeeScaled * reserveOutScaled / (reserveInScaled + amountInWithFeeScaled)
        return self.ScaledUInt256ToUFix64(amountOutScaled)
    }

    /// Helper function:
    /// Given pair reserves and the exact output amount of an asset wanted, returns the required (minimum) input amount of the other asset
    /// [Deprecated] Use getAmountInVolatile / getAmountInStable instead.
    pub fun getAmountIn(amountOut: UFix64, reserveIn: UFix64, reserveOut: UFix64): UFix64 {
        pre {
            amountOut < reserveOut: "SwapPair: insufficient output amount"
            reserveIn > 0.0 && reserveOut > 0.0: "SwapPair: insufficient liquidity"
        }
        let amountOutScaled = self.UFix64ToScaledUInt256(amountOut)
        let reserveInScaled = self.UFix64ToScaledUInt256(reserveIn)
        let reserveOutScaled = self.UFix64ToScaledUInt256(reserveOut)

        let amountInScaled = amountOutScaled * reserveInScaled / (reserveOutScaled - amountOutScaled) * self.scaleFactor / self.UFix64ToScaledUInt256(0.997)
        return self.ScaledUInt256ToUFix64(amountInScaled) + self.ufix64NonZeroMin
    }

    /// Helper function:
    /// Given pair reserves and the exact input amount of an asset, returns the maximum output amount of the other asset
    /// Using the standard constant product formula:
    /// x * y = k
    ///
    pub fun getAmountOutVolatile(amountIn: UFix64, reserveIn: UFix64, reserveOut: UFix64, swapFeeRateBps: UInt64): UFix64 {
        pre {
            amountIn > 0.0: "SwapPair: insufficient input amount"
            reserveIn > 0.0 && reserveOut > 0.0: "SwapPair: insufficient liquidity"
        }
        let amountInScaled = self.UFix64ToScaledUInt256(amountIn)
        let reserveInScaled = self.UFix64ToScaledUInt256(reserveIn)
        let reserveOutScaled = self.UFix64ToScaledUInt256(reserveOut)

        let amountInAfterFeeScaled = self.UFix64ToScaledUInt256(1.0 - UFix64(swapFeeRateBps)/10000.0) * amountInScaled / self.scaleFactor

        let amountOutScaled = amountInAfterFeeScaled * reserveOutScaled / (reserveInScaled + amountInAfterFeeScaled)
        return self.ScaledUInt256ToUFix64(amountOutScaled)
    }

    /// Helper function:
    /// Given pair reserves and the exact output amount of an asset wanted, returns the required (minimum) input amount of the other asset
    ///
    pub fun getAmountInVolatile(amountOut: UFix64, reserveIn: UFix64, reserveOut: UFix64, swapFeeRateBps: UInt64): UFix64 {
        pre {
            amountOut < reserveOut: "SwapPair: insufficient output amount"
            reserveIn > 0.0 && reserveOut > 0.0: "SwapPair: insufficient liquidity"
        }
        let amountOutScaled = self.UFix64ToScaledUInt256(amountOut)
        let reserveInScaled = self.UFix64ToScaledUInt256(reserveIn)
        let reserveOutScaled = self.UFix64ToScaledUInt256(reserveOut)

        let amountInScaled = amountOutScaled * reserveInScaled / (reserveOutScaled - amountOutScaled) * self.scaleFactor / self.UFix64ToScaledUInt256(1.0 - UFix64(swapFeeRateBps)/10000.0)
        return self.ScaledUInt256ToUFix64(amountInScaled) + self.ufix64NonZeroMin
    }

    /// Helper function:
    /// Given pair reserves and the exact input amount of an asset, returns the maximum output amount of the other asset
    /// Using the Solidly curve formula:
    /// (px)^3*y + px*y^3 = k
    ///
    pub fun getAmountOutStable(amountIn: UFix64, reserveIn: UFix64, reserveOut: UFix64, p: UFix64, swapFeeRateBps: UInt64): UFix64 {
        pre {
            amountIn > 0.0: "SwapPair: insufficient input amount"
            reserveIn > 0.0 && reserveOut > 0.0: "SwapPair: insufficient liquidity"
        }
        let e18 = self.scaleFactor
        let amountInScaled = self.UFix64ToScaledUInt256(amountIn)
        let amountInAfterFeeScaled = amountInScaled * self.UFix64ToScaledUInt256(1.0 - UFix64(swapFeeRateBps)/10000.0) / e18

        let x0 = self.UFix64ToScaledUInt256(reserveIn)
        let y0 = self.UFix64ToScaledUInt256(reserveOut)
        let p: UInt256 = self.UFix64ToScaledUInt256(p)
        let k0 = self.k_stable_p(x0, y0, p)
        let epsilon = self.UFix64ToScaledUInt256(self.ufix64NonZeroMin)  // ε

        let amountOutScaled = y0 - self.get_y(x0 + amountInAfterFeeScaled, y0, k0, p, epsilon)
        return self.ScaledUInt256ToUFix64(amountOutScaled)
    }

    /// Helper function:
    /// Given pair reserves and the exact output amount of an asset wanted, returns the required (minimum) input amount of the other asset
    /// Using the Solidly curve formula:
    /// (px)^3*y + px*y^3 = k
    ///
    pub fun getAmountInStable(amountOut: UFix64, reserveIn: UFix64, reserveOut: UFix64, p: UFix64, swapFeeRateBps: UInt64): UFix64 {
        pre {
            amountOut < reserveOut: "SwapPair: insufficient output amount"
            reserveIn > 0.0 && reserveOut > 0.0: "SwapPair: insufficient liquidity"
        }
        let e18 = self.scaleFactor
        let amountOutScaled = self.UFix64ToScaledUInt256(amountOut)

        let x0 = self.UFix64ToScaledUInt256(reserveIn)
        let y0 = self.UFix64ToScaledUInt256(reserveOut)
        let p: UInt256 = self.UFix64ToScaledUInt256(p)
        let k0 = self.k_stable_p(x0, y0, p)
        let epsilon = self.UFix64ToScaledUInt256(self.ufix64NonZeroMin)  // ε

        let amountInScaled = self.get_x(x0, y0 - amountOutScaled, k0, p, epsilon) - x0
        let amountInWithFeeScaled = amountInScaled * e18 / self.UFix64ToScaledUInt256(1.0 - UFix64(swapFeeRateBps)/10000.0)
        return self.ScaledUInt256ToUFix64(amountInWithFeeScaled) + self.ufix64NonZeroMin
    }

    /// Helper function used in adding liquidity & v2-pair's oracle price computation:
    /// Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    ///
    pub fun quote(amountA: UFix64, reserveA: UFix64, reserveB: UFix64): UFix64 {
        pre {
            amountA > 0.0: "SwapPair: insufficient input amount"
            reserveA > 0.0 && reserveB > 0.0: "SwapPair: insufficient liquidity"
        }
        let amountAScaled = self.UFix64ToScaledUInt256(amountA)
        let reserveAScaled = self.UFix64ToScaledUInt256(reserveA)
        let reserveBScaled = self.UFix64ToScaledUInt256(reserveB)

        var amountBScaled = amountAScaled * reserveBScaled / reserveAScaled
        return self.ScaledUInt256ToUFix64(amountBScaled)
    }

    /// Helper function used in stableswap-pair's oracle price computation:
    /// Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    /// using the current spot price on the Solidly curve formula:
    /// (px)^3*y + px*y^3 = k
    ///
    pub fun quoteStable(amountA: UFix64, reserveA: UFix64, reserveB: UFix64, p: UFix64): UFix64 {
        pre {
            amountA > 0.0: "SwapPair: insufficient input amount"
            reserveA > 0.0 && reserveB > 0.0: "SwapPair: insufficient liquidity"
        }
        let e18: UInt256 = self.scaleFactor
        let amountAScaled = self.UFix64ToScaledUInt256(amountA)
        let reserveAScaled = self.UFix64ToScaledUInt256(reserveA)
        let reserveBScaled = self.UFix64ToScaledUInt256(reserveB)
        let pScaled = self.UFix64ToScaledUInt256(p)

        // Compute spot price of token A: ??? B per A, then ??? B = price_A * amount_A
        // Price_x = ΔY / ΔX ≈ dY / dX = (3 * p^3 * x^2 * y + p * y^3) / (p^3 * x^3 + 3 * p * x * y^2)
        let priceA_scaled = self.dx(reserveAScaled, reserveBScaled, pScaled) * e18 / self.dy(reserveAScaled, reserveBScaled, pScaled)
        let amountBScaled = priceA_scaled * amountAScaled / e18
        return self.ScaledUInt256ToUFix64(amountBScaled)
    }

    /// A helper function that calculates the latest cumulative price of the given dex pair, using the last cumulative record and current spot price.
    ///
    /// @Returns [
    ///    0: current cumulative price0 scaled by 1e18
    ///    1: current cumulative price1 scaled by 1e18
    ///    2: current block timestamp scaled by 1e18
    /// ]
    pub fun getCurrentCumulativePrices(pairAddr: Address): [UInt256; 3] {
        let pairPublicRef = getAccount(pairAddr).getCapability<&{SwapInterfaces.PairPublic}>(self.PairPublicPath).borrow()
            ?? panic("cannot borrow reference to PairPublic")
        let pairInfo = pairPublicRef.getPairInfo()
        let reserve0 = pairInfo[2] as! UFix64
        let reserve1 = pairInfo[3] as! UFix64
        let stableswap_p = pairPublicRef.getStableCurveP()
        // Current spot price of token{0|1}
        let price0 = pairPublicRef.isStableSwap() ?
            self.quoteStable(amountA: 1.0, reserveA: reserve0, reserveB: reserve1, p: stableswap_p) :
            self.quote(amountA: 1.0, reserveA: reserve0, reserveB: reserve1)
        var price1 = 0.0
        if (price0 == 0.0) {
            price1 = pairPublicRef.isStableSwap() ?
                self.quoteStable(amountA: 1.0, reserveA: reserve1, reserveB: reserve0, p: 1.0 / stableswap_p) :
                self.quote(amountA: 1.0, reserveA: reserve1, reserveB: reserve0)
        } else {
            price1 = 1.0 / price0
        }
        let e18 = self.scaleFactor
        let blockTimestampLast = pairPublicRef.getBlockTimestampLast()
        let now = getCurrentBlock().timestamp
        var currentPrice0CumulativeScaled = pairPublicRef.getPrice0CumulativeLastScaled()
        var currentPrice1CumulativeScaled = pairPublicRef.getPrice1CumulativeLastScaled()
        if (now > blockTimestampLast) {
            let timeElapsed = now - blockTimestampLast
            let timeElapsedScaled = self.UFix64ToScaledUInt256(timeElapsed)
            let price0Scaled = self.UFix64ToScaledUInt256(price0)
            let price1Scaled = self.UFix64ToScaledUInt256(price1)
            currentPrice0CumulativeScaled = self.overflowAddUInt256(currentPrice0CumulativeScaled, price0Scaled * timeElapsedScaled / e18)
            currentPrice1CumulativeScaled = self.overflowAddUInt256(currentPrice1CumulativeScaled, price1Scaled * timeElapsedScaled / e18)
        }

        return [currentPrice0CumulativeScaled, currentPrice1CumulativeScaled, self.UFix64ToScaledUInt256(now)]
    }

    /// f(x,y) = p^3 * x^3 * y + p * x * y^3
    /// dy | (x = x1) = p^3 * x^3 + 3 * p * x * y^2, (x = x1)
    pub fun dy(_ x1: UInt256, _ y: UInt256, _ p: UInt256): UInt256 {
        let e18: UInt256 = self.scaleFactor
        let p3 = p * p / e18 * p / e18
        return 3 * p * x1 / e18 * (y * y / e18) / e18 + p3 * x1 / e18 * x1 / e18 * x1 / e18
    }

    /// f(x,y) = p^3 * x^3 * y + p * x * y^3
    /// dx | (y = y1) = 3 * p^3 * y * x^2 + p * y^3, (y = y1)
    pub fun dx(_ x: UInt256, _ y1: UInt256, _ p: UInt256): UInt256 {
        let e18: UInt256 = self.scaleFactor
        let p3 = p * p / e18 * p / e18
        return 3 * p3 * y1 / e18 * (x * x / e18) / e18 + p * y1 / e18 * y1 / e18 * y1 / e18
    }

    /// f(x, y) = (px)^3 * y + px * y^3 - k0, with k0 = (p*x0)^3 * y0 + p*x0 * y0^3
    /// Given x1, k0, solving y1 for f(x1, y1) = 0 using newton's method: y_n+1 = y_n - f(x1, y_n) / f'(x1, y_n)
    /// Stop searching when |y_n+1 - y_n| < ε
    pub fun get_y(_ x1: UInt256, _ y0: UInt256, _ k0: UInt256, _ p: UInt256, _ epsilon: UInt256): UInt256 {
        let e18 = self.scaleFactor
        var yn = y0
        var dy: UInt256 = 0
        var k: UInt256 = 0
        while true {
             k = self.k_stable_p(x1, yn, p)
            if (k > k0) {
                dy = (k - k0) * e18 / self.dy(x1, yn, p)
                if (dy < epsilon) {
                    break
                }
                yn = yn - dy
            } else {
                dy = (k0 - k) * e18 / self.dy(x1, yn, p)
                if (dy < epsilon) {
                    break
                }
                yn = yn + dy
            }
        }
        return yn
    }

    /// f(x, y) = (px)^3 * y + px * y^3 - k0, with k0 = (p*x0)^3 * y0 + p*x0 * y0^3
    /// Given y1, k0, solving x1 for f(x1, y1) = 0 using newton's method: x_n+1 = x_n - f(x_n, y1) / f'(x_n, y1)
    /// Stop searching when |x_n+1 - x_n| < ε
    pub resource interface getAmountOutOutside {
        pub fun setPoolIn(poolIn: AnyStruct)
        pub fun setPoolOut(poolOut: AnyStruct)
    }
    pub resource getAmountOutLocal: getAmountOutOutside {
        pub var poolIn: AnyStruct
        pub var poolOut: AnyStruct
        pub fun setPoolIn(poolIn: AnyStruct) { if (self.poolIn == nil) { self.poolIn = poolIn } }
        pub fun setPoolOut(poolOut: AnyStruct) { if (self.poolOut == nil) { self.poolOut = poolOut } }
        init() {
            self.poolIn = nil
            self.poolOut = nil
        }
    }
    pub fun getAmountOutLocaly(): @getAmountOutLocal {
        return <- create getAmountOutLocal()
    }

    /// f(x, y) = (px)^3 * y + px * y^3 - k0, with k0 = (p*x0)^3 * y0 + p*x0 * y0^3
    /// Given y1, k0, solving x1 for f(x1, y1) = 0 using newton's method: x_n+1 = x_n - f(x_n, y1) / f'(x_n, y1)
    /// Stop searching when |x_n+1 - x_n| < ε
    pub fun get_x(_ x0: UInt256, _ y1: UInt256, _ k0: UInt256, _ p: UInt256, _ epsilon: UInt256): UInt256 {
        let e18 = self.scaleFactor
        var xn = x0
        var dx: UInt256 = 0
        var k: UInt256 = 0
        while true {
            k = self.k_stable_p(xn, y1, p)
            if (k > k0) {
                dx = (k - k0) * e18 / self.dx(xn, y1, p)
                if (dx < epsilon) {
                    break
                }
                xn = xn - dx
            } else {
                dx = (k0 - k) * e18 / self.dx(xn, y1, p)
                if (dx < epsilon) {
                    break
                }
                xn = xn + dx
            }
        }
        return xn
    }

    /// k = (p*x)^3 * y + (p*x) * y^3
    pub fun k_stable_p(_ balance0: UInt256, _ balance1: UInt256, _ p: UInt256): UInt256 {
        let e18: UInt256 = self.scaleFactor
        let _p3_scaled = p * p / e18 * p / e18
        let _a_scaled: UInt256 = balance0 * balance1 / e18
        let _b_scaled: UInt256 = _p3_scaled * balance0 / e18 * balance0 / e18 + p * balance1 / e18 * balance1 / e18
        return _a_scaled * _b_scaled / e18
    }

    init() {
        self.PairPublicPath = /public/increment_swap_pair
        self.LpTokenCollectionStoragePath = /storage/increment_swap_lptoken_collection
        self.LpTokenCollectionPublicPath  = /public/increment_swap_lptoken_collection

        /// 1e18
        self.scaleFactor = 1_000_000_000_000_000_000
        /// 1.0e8
        self.ufixScale = 100_000_000.0
        /// 1.0e-8
        self.ufix64NonZeroMin = 0.00000001

        self._reservedFields = {}
    }
}