import IStats from "./IStats.cdc"

access(all)
contract NFT001{ 
	access(all)
	var statsContract: Address
	
	access(all)
	var statsContractName: String
	
	init(){ 
		self.statsContract = 0x9bcd6bb87052c775
		self.statsContractName = "Stats"
	}
	
	access(all)
	fun setStatsContract(address: Address, name: String){ 
		self.statsContract = address
		self.statsContractName = name
	}
	
	access(all)
	fun getMetadata():{ UInt64: String}?{ 
		// https://github.com/onflow/cadence/pull/1934
		let account = getAccount(self.statsContract)
		let borrowedContract: &{IStats} =
			account.contracts.borrow<&{IStats}>(name: self.statsContractName) ?? panic("Error")
		log(borrowedContract.stats[1])
		log(borrowedContract.stats[2])
		return borrowedContract.stats
	}
}
