import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract test{ 
	access(all)
	var array: [{String: UInt32}]
	
	access(all)
	fun getArray(): [{String: UInt32}]{ 
		return self.array
	}
	
	access(all)
	fun testGas2(){ 
		let tmp = self.array
		tmp.append({"tmp": 0})
	}
	
	access(all)
	fun add(_ item:{ String: UInt32}){ 
		self.array.append(item)
	}
	
	access(all)
	fun remove(_ index: Int){ 
		self.array.remove(at: index)
	}
	
	access(all)
	fun insert(_ index: Int, item:{ String: UInt32}){ 
		self.array.insert(at: index, item)
	}
	
	access(all)
	fun testGas1(batch: Int){ 
		var i = 0
		while i < batch{ 
			self.array.append({"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa": 1})
			i = i + 1
		}
	}
	
	access(all)
	fun assign(){ 
		let tmp = self.array
	
	//self.array = tmp
	}
	
	init(){ 
		self.array = []
	}
}
