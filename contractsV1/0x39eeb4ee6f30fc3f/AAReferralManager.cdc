access(all)
contract AAReferralManager{ 
	access(self)
	let refs:{ Address: Address}
	
	access(all)
	event Referral(owner: Address, referrer: Address)
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	resource Administrator{ 
		access(all)
		fun setRef(owner: Address, referrer: Address){ 
			AAReferralManager.refs[owner] = referrer
			emit Referral(owner: owner, referrer: referrer)
		}
	}
	
	access(all)
	fun referrerOf(owner: Address): Address?{ 
		return self.refs[owner]
	}
	
	init(){ 
		self.refs ={} 
		self.AdminStoragePath = /storage/AAReferralManagerAdmin
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
}
