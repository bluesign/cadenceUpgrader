access(all)
contract DapperWalletRestrictions{ 
	//
	access(all)
	let StoragePath: StoragePath
	
	access(all)
	event TypeChanged(identifier: Type, newConfig: TypeConfig)
	
	access(all)
	event TypeRemoved(identifier: Type)
	
	access(all)
	fun GetConfigFlags():{ String: String}{ 
		return{ 
			"CAN_INIT": "Can initialize collection in Dapper Custodial Wallet",
			"CAN_WITHDRAW": "Can withdraw NFT out of Dapper Custodial space",
			"CAN_SELL": "Can sell collection in Dapper Custodial space",
			"CAN_TRADE": "Can trade collection with other Dapper Custodial Wallet",
			"CAN_TRADE_EXTERNAL": "Can trade collection with external wallets",
			"CAN_TRADE_DIFF_NFT": "Can trade collection with different NFT types"
		}
	}
	
	access(all)
	struct TypeConfig{ 
		access(all)
		let flags:{ String: Bool}
		
		access(all)
		fun setFlag(_ flag: String, _ value: Bool){ 
			if DapperWalletRestrictions.GetConfigFlags()[flag] == nil{ 
				panic("Invalid flag")
			}
			self.flags[flag] = value
		}
		
		access(all)
		fun getFlag(_ flag: String): Bool{ 
			return self.flags[flag] ?? false
		}
		
		init(){ 
			self.flags ={} 
		}
	}
	
	access(self)
	let types:{ Type: TypeConfig}
	
	access(self)
	let ext:{ String: AnyStruct}
	
	access(all)
	resource Admin{ 
		access(all)
		fun addType(_ t: Type, conf: TypeConfig){ 
			DapperWalletRestrictions.types.insert(key: t, conf)
			emit TypeChanged(identifier: t, newConfig: conf)
		}
		
		access(all)
		fun updateType(_ t: Type, conf: TypeConfig){ 
			DapperWalletRestrictions.types[t] = conf
			emit TypeChanged(identifier: t, newConfig: conf)
		}
		
		access(all)
		fun removeType(_ t: Type){ 
			DapperWalletRestrictions.types.remove(key: t)
			emit TypeRemoved(identifier: t)
		}
	}
	
	access(all)
	fun getTypes():{ Type: TypeConfig}{ 
		return self.types
	}
	
	access(all)
	fun getConfig(_ t: Type): TypeConfig?{ 
		return self.types[t]
	}
	
	init(){ 
		self.types ={} 
		self.ext ={} 
		self.StoragePath = /storage/dapperWalletCollections
		self.account.storage.save(<-create Admin(), to: self.StoragePath)
	}
}
