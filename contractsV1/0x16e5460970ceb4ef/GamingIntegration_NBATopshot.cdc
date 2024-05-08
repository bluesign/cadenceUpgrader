import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ExpToken from "./ExpToken.cdc"

import DailyTask from "./DailyTask.cdc"

import TopShot from "../0x0b2a3299cc857e29/TopShot.cdc"

import Market from "../0xc1e4f4f4c4257510/Market.cdc"

import DapperUtilityCoin from "./../../standardsV1/DapperUtilityCoin.cdc"

access(all)
contract GamingIntegration_NBATopshot{ 
	access(all)
	event ExpRewarded(amount: UFix64, to: Address)
	
	access(all)
	event NewExpWeight(weight: UFix64)
	
	access(all)
	var nbaExpWeight: UFix64
	
	// The wrapper function to purchase nba nfts
	access(all)
	fun purchase(
		playerAddr: Address,
		salePublic: &{Market.SalePublic},
		tokenID: UInt64,
		buyTokens: @DapperUtilityCoin.Vault
	): @TopShot.NFT{ 
		// Gamification Rewards
		let expAmount = buyTokens.balance * self.nbaExpWeight
		ExpToken.gainExp(expAmount: expAmount, playerAddr: playerAddr)
		emit ExpRewarded(amount: expAmount, to: playerAddr)
		
		// Daily task
		DailyTask.completeDailyTask(playerAddr: playerAddr, taskType: "BUY_NBA")
		
		// Purchase NBA
		return <-salePublic.purchase(tokenID: 15172405, buyTokens: <-buyTokens)
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun setExpWeight(weight: UFix64){ 
			emit NewExpWeight(weight: weight)
			GamingIntegration_NBATopshot.nbaExpWeight = weight
		}
	}
	
	init(){ 
		self.nbaExpWeight = 1.0
		self.account.storage.save(<-create Admin(), to: /storage/adminPath_nba)
	}
}
