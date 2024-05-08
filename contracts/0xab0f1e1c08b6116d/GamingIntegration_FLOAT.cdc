import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import ExpToken from "./ExpToken.cdc"
import DailyTask from "./DailyTask.cdc"

import FLOAT from "../0x2d4c3caffbeab845/FLOAT.cdc"

pub contract GamingIntegration_FLOAT {

    pub event ExpRewarded(amount: UFix64, to: Address)
    pub event NewExpWeight(weight: UFix64)

    pub var floatExpWeight: UFix64

    // The wrapper function to claim FLOAT requires the playerAddress to be passed in.
    pub fun claim(
        playerAddr: Address,
        FLOATEvent: &FLOAT.FLOATEvent{FLOAT.FLOATEventPublic},
        recipient: &FLOAT.Collection,
        params: {String: AnyStruct})
    {
        // Gamification Rewards
        let expAmount = self.floatExpWeight
        ExpToken.gainExp(expAmount: expAmount, playerAddr: playerAddr)

        // Claim FLOAT
        FLOATEvent.claim(recipient: recipient, params: params)

        // Daily task
        DailyTask.completeDailyTask(playerAddr: playerAddr, taskType: "MINT_FLOAT")

        emit ExpRewarded(amount: expAmount, to: playerAddr)
    }
    
    pub resource Admin {
        pub fun setExpWeight(weight: UFix64) {
            emit NewExpWeight(weight: weight)
            GamingIntegration_FLOAT.floatExpWeight = weight
        }
    }

    init() {
        self.floatExpWeight = 10.0

        self.account.save(<-create Admin(), to: /storage/adminPath_float)
    }
}
 