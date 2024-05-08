import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowNia from "./FlowNia.cdc"

access(all)
contract FlowNiaPresale{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var sale: Sale?
	
	access(all)
	struct Sale{ 
		access(all)
		var price: UFix64
		
		access(all)
		var paymentVaultType: Type
		
		access(all)
		var receiver: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		var startTime: UFix64?
		
		access(all)
		var endTime: UFix64?
		
		access(all)
		var max: UInt64
		
		access(all)
		var current: UInt64
		
		init(
			price: UFix64,
			paymentVaultType: Type,
			receiver: Capability<&{FungibleToken.Receiver}>,
			startTime: UFix64?,
			endTime: UFix64?,
			max: UInt64,
			current: UInt64
		){ 
			self.price = price
			self.paymentVaultType = paymentVaultType
			self.receiver = receiver
			self.startTime = startTime
			self.endTime = endTime
			self.max = max
			self.current = current
		}
		
		access(contract)
		fun incCurrent(){ 
			self.current = self.current + UInt64(1)
		}
	}
	
	access(all)
	fun paymentMint(
		payment: @{FungibleToken.Vault},
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
			(self.sale!).receiver.check():
				"invalid receiver"
			payment.isInstance((self.sale!).paymentVaultType):
				"payment vault is not requested fungible token"
			payment.balance == (self.sale!).price!:
				"payment vault does not contain requested price"
		}
		let receiver = (self.sale!).receiver.borrow()!
		receiver.deposit(from: <-payment)
		let minter =
			self.account.storage.borrow<&FlowNia.NFTMinter>(from: FlowNia.MinterStoragePath)!
		let metadata:{ String: String} ={} 
		let tokenId = FlowNia.totalSupply
		// metadata code here
		minter.mintNFT(id: recipient, recipient: metadata)
		(self.sale!).incCurrent()
	}
	
	access(all)
	resource Administrator{ 
		access(all)
		fun setSale(sale: Sale?){ 
			FlowNiaPresale.sale = sale
		}
	}
	
	init(){ 
		self.sale = nil
		self.AdminStoragePath = /storage/FlowNiaPresaleAdmin
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
}
