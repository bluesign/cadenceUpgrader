import IStats from "./IStats.cdc"

access(all)
contract Stats2: IStats{ 
	access(all)
	let stats:{ UInt64: String}
	
	// The init() function is required if the contract contains any fields.
	init(){ 
		self.stats ={ 1: "Uno", 2: "Dos"}
	}
}
