import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowverseSocks from "./FlowverseSocks.cdc"

import RaribleNFT from "../0x01ab36aaf654a13e/RaribleNFT.cdc"

access(all)
contract FlowverseSocksMintContract{ 
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
		var idMapping:{ UInt64: UInt64}
		
		init(
			startTime: UFix64?,
			endTime: UFix64?,
			max: UInt64,
			current: UInt64,
			idMapping:{ 
				UInt64: UInt64
			}
		){ 
			self.startTime = startTime
			self.endTime = endTime
			self.max = max
			self.current = current
			self.idMapping = idMapping
		}
		
		access(contract)
		fun incCurrent(){ 
			self.current = self.current + UInt64(1)
		}
	}
	
	access(all)
	fun paymentMint(
		toBurn: @{NonFungibleToken.NFT},
		recipient: &{NonFungibleToken.CollectionPublic}
	){ 
		pre{ 
			self.sale != nil:
				"sale closed"
			(self.sale!).startTime == nil || (self.sale!).startTime! <= getCurrentBlock().timestamp:
				"sale not started yet"
			(self.sale!).endTime == nil || (self.sale!).endTime! > getCurrentBlock().timestamp:
				"sale already ended"
			(self.sale!).max > (self.sale!).current:
				"sale items sold out"
			toBurn.isInstance(Type<@RaribleNFT.NFT>()):
				"toBurn is not requested NFT type"
		}
		let id = (self.sale!).idMapping[toBurn.id]
		if id == nil{ 
			panic("NFT id not in list")
		}
		destroy toBurn
		let minter =
			self.account.storage.borrow<&FlowverseSocks.NFTMinter>(
				from: FlowverseSocks.MinterStoragePath
			)!
		let metadata:{ String: String} ={} 
		let tokenId = id
		// metadata code here
		minter.mintNFTWithID(id: id!, recipient: recipient, metadata: metadata)
		(self.sale!).incCurrent()
	}
	
	access(all)
	resource Administrator{ 
		access(all)
		fun setSale(sale: Sale?){ 
			FlowverseSocksMintContract.sale = sale
		}
	}
	
	init(){ 
		self.sale = nil
		self.AdminStoragePath = /storage/FlowverseSocksMintContractAdmin
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
}
