import Minter from "./Minter.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FiatToken from "./../../standardsV1/FiatToken.cdc"

access(all)
contract FiatTokenMinter{ 
	access(all)
	resource FungibleTokenMinter: Minter.FungibleTokenMinter{ 
		access(all)
		let type: Type
		
		access(all)
		let addr: Address
		
		access(all)
		fun mintTokens(acct: AuthAccount, amount: UFix64): @{FungibleToken.Vault}{ 
			let minter <- FiatToken.createNewMinter()
			let controller <- FiatToken.createNewMinterController(publicKeys: [], pubKeyAttrs: [])
			let executor = acct.borrow<&FiatToken.MasterMinterExecutor>(from: FiatToken.MasterMinterExecutorStoragePath) ?? panic("executor not found")
			executor.configureMinterController(minter: minter.uuid, minterController: controller.uuid)
			controller.increaseMinterAllowance(increment: amount)
			let tokens <- minter.mint(amount: amount)
			destroy minter
			destroy controller
			return <-tokens
		}
		
		init(_ t: Type, _ a: Address){ 
			self.type = t
			self.addr = a
		}
	}
	
	access(all)
	fun createMinter(_ t: Type, _ a: Address): @FungibleTokenMinter{ 
		return <-create FungibleTokenMinter(t, a)
	}
}
