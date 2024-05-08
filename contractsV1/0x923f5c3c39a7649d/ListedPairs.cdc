access(all)
contract ListedPairs{ 
	/****** Events ******/
	access(all)
	event PairAdded(key: String, name: String, token0: String, token1: String, address: Address)
	
	access(all)
	event PairUpdated(key: String)
	
	access(all)
	event PairRemoved(key: String)
	
	/****** Contract Variables ******/
	access(contract)
	var _pairs:{ String: PairInfo}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	/****** Composite Type Definitions ******/
	access(all)
	struct PairInfo{ 
		access(all)
		let name: String
		
		access(all)
		let token0: String
		
		access(all)
		let token1: String
		
		access(all)
		let address: Address
		
		access(all)
		var liquidityToken: String?
		
		init(
			name: String,
			token0: String,
			token1: String,
			address: Address,
			liquidityToken: String?
		){ 
			self.name = name
			self.token0 = token0
			self.token1 = token1
			self.address = address
			self.liquidityToken = liquidityToken
		}
		
		access(all)
		fun update(liquidityToken: String?){ 
			self.liquidityToken = liquidityToken ?? self.liquidityToken
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun addPair(
			name: String,
			token0: String,
			token1: String,
			address: Address,
			liquidityToken: String?
		){ 
			var key = name.concat(".").concat(address.toString())
			if ListedPairs.pairExists(key: key){ 
				return
			}
			ListedPairs._pairs[key] = PairInfo(
					name: name,
					token0: token0,
					token1: token1,
					address: address,
					liquidityToken: liquidityToken
				)
			emit PairAdded(key: key, name: name, token0: token0, token1: token1, address: address)
		}
		
		access(all)
		fun updatePair(name: String, address: Address, liquidityToken: String?){ 
			var key = name.concat(".").concat(address.toString())
			(ListedPairs._pairs[key]!).update(liquidityToken: liquidityToken)
			emit PairUpdated(key: key)
		}
		
		access(all)
		fun removePair(key: String){ 
			ListedPairs._pairs.remove(key: key)
			emit PairRemoved(key: key)
		}
	}
	
	/****** Methods ******/
	access(all)
	fun pairExists(key: String): Bool{ 
		return self._pairs.containsKey(key)
	}
	
	access(all)
	fun getPairs(): [PairInfo]{ 
		return self._pairs.values
	}
	
	init(){ 
		self._pairs ={} 
		self.AdminStoragePath = /storage/bloctoSwapListedPairsAdmin
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
	}
}
