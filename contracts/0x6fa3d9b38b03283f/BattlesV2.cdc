import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import REVV from "../0xd01e482eb680ec9f/REVV.cdc"

pub contract BattlesV2 {
   
    pub fun getPlayerPayment(): String {
        return "Hello, Main!"
    }

    pub resource Admin {}

    init () {
        let admin <- create Admin()
        self.account.save(<-admin, to: /storage/AdminTest)
    }
}
