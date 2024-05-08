access(all)
contract BarterYardStats{ 
	access(self)
	var minted: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	fun mintedTokens(): UInt64{ 
		return BarterYardStats.minted
	}
	
	access(all)
	fun setLastMintedToken(lastID: UInt64){ 
		self.minted = lastID
	}
	
	access(account)
	fun getNextTokenId(): UInt64{ 
		self.minted = self.minted + 1
		return self.minted
	}
	
	access(all)
	resource Admin{} 
	
	init(){ 
		self.minted = 5500
		emit ContractInitialized()
	}
}
