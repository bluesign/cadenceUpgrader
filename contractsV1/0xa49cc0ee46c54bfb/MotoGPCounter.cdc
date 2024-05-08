import MotoGPAdmin from "./MotoGPAdmin.cdc"

import ContractVersion from "./ContractVersion.cdc"

access(all)
contract MotoGPCounter: ContractVersion{ 
	access(all)
	fun getVersion(): String{ 
		return "0.7.8"
	}
	
	access(self)
	let counterMap:{ String: UInt64}
	
	access(account)
	fun increment(_ key: String): UInt64{ 
		if self.counterMap.containsKey(key){ 
			self.counterMap[key] = self.counterMap[key]! + 1
		} else{ 
			self.counterMap[key] = 1
		}
		return self.counterMap[key]!
	}
	
	access(account)
	fun incrementBy(_ key: String, _ value: UInt64){ 
		if self.counterMap.containsKey(key){ 
			self.counterMap[key] = self.counterMap[key]! + value
		} else{ 
			self.counterMap[key] = value
		}
	}
	
	access(all)
	fun hasCounter(_ key: String): Bool{ 
		return self.counterMap.containsKey(key)
	}
	
	access(all)
	fun getCounter(_ key: String): UInt64{ 
		return self.counterMap[key]!
	}
	
	init(){ 
		self.counterMap ={} 
	}
}
