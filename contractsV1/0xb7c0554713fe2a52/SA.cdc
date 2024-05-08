import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import SwapInterfaces from "../0xb78ef7afa52ff906/SwapInterfaces.cdc"

import SwapConfig from "../0xb78ef7afa52ff906/SwapConfig.cdc"

import PierRouter from "../0xa0ebe96eb1366be6/PierRouter.cdc"

import IPierPair from "../0x609e10301860b683/IPierPair.cdc"

import PierPair from "../0x609e10301860b683/PierPair.cdc"

access(all)
contract SA{ 
	access(all)
	fun getAmountOut(amountIn: UFix64, reserveIn: UFix64, reserveOut: UFix64): UFix64{ 
		return amountIn * 0.997 * reserveOut / (reserveIn + amountIn * 0.997)
	}
	
	access(all)
	fun getAmountIn(amountOut: UFix64, reserveIn: UFix64, reserveOut: UFix64): UFix64{ 
		return amountOut * reserveIn / ((reserveOut - amountOut) * 0.997)
	}
	
	access(all)
	fun swapFlowToUsdc_IM(inVault: @{FungibleToken.Vault}, minAmountOut: UFix64): @{
		FungibleToken.Vault
	}{ 
		let amountIn: UFix64 = inVault.balance
		var outVault <-
			(getAccount(0xb19436aae4d94622).contracts.borrow<&{FungibleToken}>(name: "FiatToken")!)
				.createEmptyVault()
		let pool1 =
			getAccount(0xfa82796435e15832).capabilities.get<&{SwapInterfaces.PairPublic}>(
				/public/increment_swap_pair
			).borrow()!
		let poolInfo = pool1.getPairInfo()
		let f1 = poolInfo[2] as! UFix64
		let u1 = poolInfo[3] as! UFix64
		let pool2 =
			getAccount(0x18187a9d276c0329).capabilities.get<&PierPair.Pool>(
				/public/metapierSwapPoolPublic
			).borrow()!
		let poolInfo2 = pool2.getReserves()
		let f2 = poolInfo2[0]
		let u2 = poolInfo2[1]
		let scale: UInt256 = 1_000_000_000_000_000_000
		var a1 = f1
		var b1 = u1
		var a2 = f2
		var b2 = u2
		var flip = false
		if b1 / b2 * a2 < a1{ 
			a1 = f2
			b1 = u2
			a2 = f1
			b2 = u1
			flip = true
		}
		let F = 0.997
		let F_ = SwapConfig.UFix64ToScaledUInt256(0.997)
		let A = 0.997
		let A_ = F_
		let B = a1 * (1.0 + F)
		let B_ = SwapConfig.UFix64ToScaledUInt256(B)
		var C = 0.0
		if b1 / b2 * a2 >= a1{ 
			C = (b1 / b2 * a2 - a1) * a1
		}
		let C_ = SwapConfig.UFix64ToScaledUInt256(C)
		let AA_ = B_ * B_ / scale + A_ * C_ / scale * 4 as UInt256
		let x = (SwapConfig.ScaledUInt256ToUFix64(SwapConfig.sqrt(AA_)) - B) / (2.0 * A)
		var amountIn1 = amountIn
		var amountIn2 = 0.0
		if x >= amountIn{ 
			if flip{ 
				amountIn1 = 0.0
				amountIn2 = amountIn
			} else{ 
				amountIn1 = amountIn
				amountIn2 = 0.0
			}
		} else{ 
			let f1_aft = a1 + x
			var f2_aft = b1
			if x > 0.0{ 
				f2_aft = b1 - self.getAmountOut(amountIn: x, reserveIn: a1, reserveOut: b1)
			}
			let x_left = amountIn - x
			let x_left_to_a = x_left / (f1_aft + a2) * f1_aft
			let in1 = x + x_left_to_a
			let in2 = amountIn - in1
			if flip{ 
				amountIn1 = in2
				amountIn2 = in1
			} else{ 
				amountIn1 = in1
				amountIn2 = in2
			}
		}
		var out1 = 0.0
		var out2 = 0.0
		if amountIn1 > 0.0{ 
			let inVault1 <- inVault.withdraw(amount: amountIn1)
			let outVault1 <- pool1.swap(vaultIn: <-inVault1, exactAmountOut: nil)
			out1 = outVault1.balance
			outVault.deposit(from: <-outVault1)
		}
		if amountIn2 > 0.0{ 
			let inVault2 <- inVault.withdraw(amount: amountIn2)
			let forAmount = self.getAmountOut(amountIn: amountIn2, reserveIn: f2, reserveOut: u2)
			let outVault2 <- pool2.swap(fromVault: <-inVault2, forAmount: forAmount)
			out2 = outVault2.balance
			outVault.deposit(from: <-outVault2)
		}
		destroy inVault
		assert(out1 + out2 >= minAmountOut, message: "s")
		return <-outVault
	}
	
	access(all)
	fun swapUsdcToFlow_IM(inVault: @{FungibleToken.Vault}, minAmountOut: UFix64): @{
		FungibleToken.Vault
	}{ 
		let amountIn: UFix64 = inVault.balance
		var outVault <-
			(getAccount(0x1654653399040a61).contracts.borrow<&{FungibleToken}>(name: "FlowToken")!)
				.createEmptyVault()
		let pool1 =
			getAccount(0xfa82796435e15832).capabilities.get<&{SwapInterfaces.PairPublic}>(
				/public/increment_swap_pair
			).borrow()!
		let poolInfo = pool1.getPairInfo()
		let u1 = poolInfo[2] as! UFix64
		let f1 = poolInfo[3] as! UFix64
		let pool2 =
			getAccount(0x18187a9d276c0329).capabilities.get<&PierPair.Pool>(
				/public/metapierSwapPoolPublic
			).borrow()!
		let poolInfo2 = pool2.getReserves()
		let u2 = poolInfo2[0]
		let f2 = poolInfo2[1]
		let scale: UInt256 = 1_000_000_000_000_000_000
		var a1 = f1
		var b1 = u1
		var a2 = f2
		var b2 = u2
		var flip = false
		if b1 / b2 * a2 < a1{ 
			a1 = f2
			b1 = u2
			a2 = f1
			b2 = u1
			flip = true
		}
		let F = 0.997
		let F_ = SwapConfig.UFix64ToScaledUInt256(0.997)
		let A = 0.997
		let A_ = F_
		let B = a1 * (1.0 + F)
		let B_ = SwapConfig.UFix64ToScaledUInt256(B)
		var C = 0.0
		if b1 / b2 * a2 >= a1{ 
			C = (b1 / b2 * a2 - a1) * a1
		}
		let C_ = SwapConfig.UFix64ToScaledUInt256(C)
		let AA_ = B_ * B_ / scale + A_ * C_ / scale * 4 as UInt256
		let x = (SwapConfig.ScaledUInt256ToUFix64(SwapConfig.sqrt(AA_)) - B) / (2.0 * A)
		var amountIn1 = amountIn
		var amountIn2 = 0.0
		if x >= amountIn{ 
			if flip{ 
				amountIn1 = 0.0
				amountIn2 = amountIn
			} else{ 
				amountIn1 = amountIn
				amountIn2 = 0.0
			}
		} else{ 
			let f1_aft = a1 + x
			var f2_aft = b1
			if x > 0.0{ 
				f2_aft = b1 - self.getAmountOut(amountIn: x, reserveIn: a1, reserveOut: b1)
			}
			let x_left = amountIn - x
			let x_left_to_a = x_left / (f1_aft + a2) * f1_aft
			let in1 = x + x_left_to_a
			let in2 = amountIn - in1
			if flip{ 
				amountIn1 = in2
				amountIn2 = in1
			} else{ 
				amountIn1 = in1
				amountIn2 = in2
			}
		}
		var out1 = 0.0
		var out2 = 0.0
		if amountIn1 > 0.0{ 
			let inVault1 <- inVault.withdraw(amount: amountIn1)
			let outVault1 <- pool1.swap(vaultIn: <-inVault1, exactAmountOut: nil)
			out1 = outVault1.balance
			outVault.deposit(from: <-outVault1)
		}
		if amountIn2 > 0.0{ 
			let inVault2 <- inVault.withdraw(amount: amountIn2)
			let forAmount = self.getAmountOut(amountIn: amountIn2, reserveIn: f2, reserveOut: u2)
			let outVault2 <- pool2.swap(fromVault: <-inVault2, forAmount: forAmount)
			out2 = outVault2.balance
			outVault.deposit(from: <-outVault2)
		}
		destroy inVault
		assert(out1 + out2 >= minAmountOut, message: "s")
		return <-outVault
	}
	
	init(){} 
}
