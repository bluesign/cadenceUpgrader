import Minter from "./Minter.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import DapperUtilityCoin from "./../../standardsV1/DapperUtilityCoin.cdc"

access(all)
contract DapperUtilityCoinMinter{ 
	access(all)
	resource FungibleTokenMinter: Minter.FungibleTokenMinter{ 
		access(all)
		let type: Type
		
		access(all)
		let addr: Address
		
		access(all)
		fun mintTokens(acct: AuthAccount, amount: UFix64): @{FungibleToken.Vault}{ 
			let mainVault = acct.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault) ?? panic("vault not found")
			let tokens <- mainVault.withdraw(amount: amount)
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
