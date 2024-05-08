import SwapStatsRegistry from "./SwapStatsRegistry.cdc"

access(all)
contract SwapStats{ 
	access(all)
	event AccountStatsAdded(address: Address, data: SwapStatsRegistry.AccountSwapData)
	
	access(all)
	fun getAccountStatsCount(id: String): Int{ 
		return SwapStatsRegistry.getAccountStatsCount(id: id)
	}
	
	access(all)
	fun paginateAccountStats(id: String, skip: Int, take: Int, filter:{ String: AnyStruct}?): [
		SwapStatsRegistry.AccountStats
	]{ 
		return SwapStatsRegistry.paginateAccountStats(
			id: id,
			skip: skip,
			take: take,
			filter: filter
		)
	}
	
	access(all)
	fun getAccountStats(id: String, address: Address): SwapStatsRegistry.AccountStats{ 
		return SwapStatsRegistry.getAccountStats(id: id, address: address)
	}
	
	access(account)
	fun addAccountStats(id: String, address: Address, _ data: SwapStatsRegistry.AccountSwapData){ 
		SwapStatsRegistry.addAccountStats(id: id, address: address, data)
		emit AccountStatsAdded(address: address, data: data)
	}
	
	init(){} 
	
	// everything below is deprecated
	access(all)
	struct InternalAccountSwapStats{ 
		access(all)
		let address: Address
		
		access(all)
		var totalTradeVolumeReceived: UInt
		
		access(all)
		var totalTradeVolumeSent: UInt
		
		access(all)
		var totalUniqueTradeCount: UInt
		
		access(all)
		var totalTradeCount: UInt
		
		access(all)
		let uniqueTradingPartnerAddresses: [Address]
		
		access(contract)
		view fun addStats(_ data: AccountSwapData){ 
			self.totalTradeVolumeReceived = self.totalTradeVolumeReceived
				+ data.totalTradeVolumeReceived
			self.totalTradeVolumeSent = self.totalTradeVolumeSent + data.totalTradeVolumeSent
			self.totalTradeCount = self.totalTradeCount + 1
			if self.uniqueTradingPartnerAddresses.contains(data.partnerAddress){ 
				return
			}
			self.uniqueTradingPartnerAddresses.append(data.partnerAddress)
			self.totalUniqueTradeCount = self.totalUniqueTradeCount + 1
		}
		
		init(_ address: Address){ 
			self.address = address
			self.totalTradeVolumeReceived = 0
			self.totalTradeVolumeSent = 0
			self.totalUniqueTradeCount = 0
			self.totalTradeCount = 0
			self.uniqueTradingPartnerAddresses = []
		}
	}
	
	access(all)
	struct PublicAccountSwapStats{ 
		access(all)
		let address: Address
		
		access(all)
		let totalTradeVolumeReceived: UInt
		
		access(all)
		let totalTradeVolumeSent: UInt
		
		access(all)
		let totalUniqueTradeCount: UInt
		
		access(all)
		let totalTradeCount: UInt
		
		access(all)
		let metadata:{ String: AnyStruct}?
		
		init(_ data: InternalAccountSwapStats, _ metadata:{ String: AnyStruct}?){ 
			self.address = data.address
			self.totalTradeVolumeReceived = data.totalTradeVolumeReceived
			self.totalTradeVolumeSent = data.totalTradeVolumeSent
			self.totalUniqueTradeCount = data.totalUniqueTradeCount
			self.totalTradeCount = data.totalTradeCount
			self.metadata = metadata
		}
	}
	
	access(all)
	struct AccountSwapData{ 
		access(all)
		let partnerAddress: Address
		
		access(all)
		let totalTradeVolumeReceived: UInt
		
		access(all)
		let totalTradeVolumeSent: UInt
		
		init(partnerAddress: Address, totalTradeVolumeSent: UInt, totalTradeVolumeReceived: UInt){ 
			self.partnerAddress = partnerAddress
			self.totalTradeVolumeReceived = totalTradeVolumeReceived
			self.totalTradeVolumeSent = totalTradeVolumeSent
		}
	}
}
