import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import REVV from "../0xd01e482eb680ec9f/REVV.cdc"

access(all)
contract BattlesV2{ 
	access(all)
	fun getPlayerPayment(): String{ 
		return "Hello, Main!"
	}
	
	access(all)
	resource Admin{} 
	
	init(){ 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: /storage/AdminTest)
	}
}
