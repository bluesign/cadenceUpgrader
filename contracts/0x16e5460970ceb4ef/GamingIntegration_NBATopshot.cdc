import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import ExpToken from "./ExpToken.cdc"
import DailyTask from "./DailyTask.cdc"

import TopShot from "../0x0b2a3299cc857e29/TopShot.cdc"
import Market from "../0xc1e4f4f4c4257510/Market.cdc"
import DapperUtilityCoin from "../0xead892083b3e2c6c/DapperUtilityCoin.cdc"

pub contract GamingIntegration_NBATopshot {

    pub event ExpRewarded(amount: UFix64, to: Address)
    pub event NewExpWeight(weight: UFix64)

    pub var nbaExpWeight: UFix64

    // The wrapper function to purchase nba nfts
    pub fun purchase(
        playerAddr: Address,
        salePublic: &{Market.SalePublic},
        tokenID: UInt64,
        buyTokens: @DapperUtilityCoin.Vault
    ): @TopShot.NFT
    {
        // Gamification Rewards
        let expAmount = buyTokens.balance * self.nbaExpWeight
        ExpToken.gainExp(expAmount: expAmount, playerAddr: playerAddr)

        emit ExpRewarded(amount: expAmount, to: playerAddr)

        // Daily task
        DailyTask.completeDailyTask(playerAddr: playerAddr, taskType: "BUY_NBA")

        // Purchase NBA
        return <-salePublic.purchase(tokenID: 15172405, buyTokens: <-buyTokens)
    }
    
    pub resource Admin {
        pub fun setExpWeight(weight: UFix64) {
            emit NewExpWeight(weight: weight)
            GamingIntegration_NBATopshot.nbaExpWeight = weight
        }
    }

    init() {
        self.nbaExpWeight = 1.0

        self.account.save(<-create Admin(), to: /storage/adminPath_nba)
    }
}
 