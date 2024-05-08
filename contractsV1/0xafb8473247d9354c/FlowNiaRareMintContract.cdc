import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowNia from "./FlowNia.cdc"

access(all)
contract FlowNiaRareMintContract{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var sale: Sale?
	
	access(all)
	struct Sale{ 
		access(all)
		var startTime: UFix64?
		
		access(all)
		var endTime: UFix64?
		
		access(all)
		var max: UInt64
		
		access(all)
		var current: UInt64
		
		access(all)
		var whitelist:{ Address: Bool}
		
		init(
			startTime: UFix64?,
			endTime: UFix64?,
			max: UInt64,
			current: UInt64,
			whitelist:{ 
				Address: Bool
			}
		){ 
			self.startTime = startTime
			self.endTime = endTime
			self.max = max
			self.current = current
			self.whitelist = whitelist
		}
		
		access(contract)
		fun useWhitelist(_ address: Address){ 
			self.whitelist[address] = true
		}
		
		access(contract)
		fun incCurrent(){ 
			self.current = self.current + UInt64(1)
		}
	}
	
	access(all)
	fun paymentMint(recipient: &{NonFungibleToken.CollectionPublic}){} 
	
	access(all)
	resource Administrator{ 
		access(all)
		fun setSale(sale: Sale?){ 
			FlowNiaRareMintContract.sale = sale
		}
	}
	
	init(){ 
		self.sale = nil
		self.AdminStoragePath = /storage/FlowNiaRareMintContractAdmin
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
}
