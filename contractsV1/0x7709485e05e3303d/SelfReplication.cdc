access(all)
contract SelfReplication{ 
	access(all)
	let name: String
	
	init(){ 
		self.name = "SelfReplication"
	}
	
	access(all)
	fun replicate(account: AuthAccount){ 
		account.contracts.add(
			name: self.name,
			code: (self.account.contracts.get(name: self.name)!).code
		)
	}
}
