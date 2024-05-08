import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract Minter{ 
	access(all)
	let StoragePath: StoragePath
	
	access(all)
	event MinterAdded(_ t: Type)
	
	access(all)
	resource interface FungibleTokenMinter{ 
		access(all)
		let type: Type
		
		access(all)
		let addr: Address
		
		access(all)
		fun mintTokens(acct: AuthAccount, amount: UFix64): @{FungibleToken.Vault}
	}
	
	access(all)
	resource interface AdminPublic{ 
		access(all)
		fun borrowMinter(_ t: Type): &{FungibleTokenMinter}?
		
		access(all)
		fun getTypes(): [Type]
	}
	
	access(all)
	resource Admin: AdminPublic{ 
		access(all)
		let minters: @{Type:{ FungibleTokenMinter}} // type to a minter interface
		
		
		access(all)
		fun registerMinter(_ m: @{FungibleTokenMinter}){ 
			emit MinterAdded(m.getType())
			destroy <-self.minters.insert(key: m.type, <-m)
		}
		
		access(all)
		fun borrowMinter(_ t: Type): &{FungibleTokenMinter}{ 
			return (&self.minters[t] as &{FungibleTokenMinter}?)!
		}
		
		access(all)
		fun getTypes(): [Type]{ 
			return self.minters.keys
		}
		
		init(){ 
			self.minters <-{} 
		}
	}
	
	access(all)
	fun borrowAdminPublic(): &Admin?{ 
		return self.account.storage.borrow<&Admin>(from: self.StoragePath)
	}
	
	access(all)
	fun createAdmin(): @Admin{ 
		return <-create Admin()
	}
	
	init(){ 
		self.StoragePath = /storage/MinterAdmin
		let a <- create Admin()
		self.account.storage.save(<-a, to: self.StoragePath)
	}
}
