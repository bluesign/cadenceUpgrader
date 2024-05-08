import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ExpToken from "./ExpToken.cdc"

import DailyTask from "./DailyTask.cdc"

import FLOAT from "../0x2d4c3caffbeab845/FLOAT.cdc"

access(all)
contract GamingIntegration_FLOAT{ 
	access(all)
	event ExpRewarded(amount: UFix64, to: Address)
	
	access(all)
	event NewExpWeight(weight: UFix64)
	
	access(all)
	var floatExpWeight: UFix64
	
	// The wrapper function to claim FLOAT requires the playerAddress to be passed in.
	access(all)
	fun claim(
		playerAddr: Address,
		FLOATEvent: &FLOAT.FLOATEvent,
		recipient: &FLOAT.Collection,
		params:{ 
			String: AnyStruct
		}
	){ 
		// Gamification Rewards
		let expAmount = self.floatExpWeight
		ExpToken.gainExp(expAmount: expAmount, playerAddr: playerAddr)
		
		// Claim FLOAT
		FLOATEvent.claim(recipient: recipient, params: params)
		
		// Daily task
		DailyTask.completeDailyTask(playerAddr: playerAddr, taskType: "MINT_FLOAT")
		emit ExpRewarded(amount: expAmount, to: playerAddr)
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun setExpWeight(weight: UFix64){ 
			emit NewExpWeight(weight: weight)
			GamingIntegration_FLOAT.floatExpWeight = weight
		}
	}
	
	init(){ 
		self.floatExpWeight = 10.0
		self.account.storage.save(<-create Admin(), to: /storage/adminPath_float)
	}
}
