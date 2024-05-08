import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ExpToken from "./ExpToken.cdc"

import DailyTask from "./DailyTask.cdc"

import SwapInterfaces from "../0xb78ef7afa52ff906/SwapInterfaces.cdc"

import SwapConfig from "../0xb78ef7afa52ff906/SwapConfig.cdc"

access(all)
contract GamingIntegration_IncrementSwap{ 
	access(all)
	event ExpRewarded(amount: UFix64, to: Address)
	
	access(all)
	event NewExpWeight(weight: UFix64, token: String)
	
	// The proportionate weight of exp amounts obtained from different tokens
	access(all)
	let tokenExpWeights:{ String: UFix64}
	
	// The wrapper function for Swap not only accomplishes the increment of SwapPool's swaps but also integrates gamified numerical growth
	access(all)
	fun swap(
		playerAddr: Address,
		poolAddr: Address,
		vaultIn: @{FungibleToken.Vault},
		exactAmountOut: UFix64?
	): @{FungibleToken.Vault}{ 
		// Gamification Rewards
		let tokenInType =
			vaultIn.getType().identifier.slice(
				from: 0,
				upTo: vaultIn.getType().identifier.length - 6
			)
		var tokenWeight = 0.0
		if self.tokenExpWeights.containsKey(tokenInType){ 
			tokenWeight = self.tokenExpWeights[tokenInType]!
		}
		let expTokenAmount = vaultIn.balance * tokenWeight
		if expTokenAmount > 0.0{ 
			ExpToken.gainExp(expAmount: expTokenAmount, playerAddr: playerAddr)
		}
		emit ExpRewarded(amount: expTokenAmount, to: playerAddr)
		
		// Daily task
		DailyTask.completeDailyTask(playerAddr: playerAddr, taskType: "SWAP_ONCE")
		
		// Inrement Swap
		let poolRef: &{SwapInterfaces.PairPublic} =
			getAccount(poolAddr).capabilities.get<&{SwapInterfaces.PairPublic}>(
				SwapConfig.PairPublicPath
			).borrow()!
		return <-poolRef.swap(vaultIn: <-vaultIn, exactAmountOut: exactAmountOut)
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun setTokenExpWeight(tokenKey: String, weight: UFix64){ 
			emit NewExpWeight(weight: weight, token: tokenKey)
			GamingIntegration_IncrementSwap.tokenExpWeights[tokenKey] = weight
		}
	}
	
	init(){ 
		self.account.storage.save(<-create Admin(), to: /storage/adminPath_incrementSwap)
		self.tokenExpWeights ={} 
		self.tokenExpWeights["A.1654653399040a61.FlowToken"] = 0.5
		self.tokenExpWeights["A.b19436aae4d94622.FiatToken"] = 1.0
	}
}
