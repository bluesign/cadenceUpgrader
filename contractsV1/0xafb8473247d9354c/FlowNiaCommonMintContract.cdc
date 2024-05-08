import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowNia from "./FlowNia.cdc"

access(all)
contract FlowNiaCommonMintContract{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var whitelist:{ Address: Bool}
	
	access(all)
	var extraFields:{ String: AnyStruct}
	
	init(){ 
		self.whitelist ={} 
		self.extraFields ={} 
		self.AdminStoragePath = /storage/FlowNiaCommonMintContractAdmin
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
	
	access(all)
	resource Administrator{ 
		access(all)
		fun setFields(fields:{ String: AnyStruct}){ 
			for key in fields.keys{ 
				if key == "whitelist"{ 
					FlowNiaCommonMintContract.whitelist = fields[key] as!{ Address: Bool}? ??{} 
				} else if key == "whitelistToAdd"{ 
					let whitelistToAdd = fields[key] as!{ Address: Bool}? ??{} 
					for k in whitelistToAdd.keys{ 
						FlowNiaCommonMintContract.whitelist[k] = whitelistToAdd[k]!
					}
				} else{ 
					FlowNiaCommonMintContract.extraFields[key] = fields[key]
				}
			}
		}
	}
	
	access(all)
	fun paymentMint(recipient: &{NonFungibleToken.CollectionPublic}){ 
		var opened = self.extraFields["opened"] as! Bool? ?? false
		var startTime = self.extraFields["startTime"] as! UFix64?
		var endTime = self.extraFields["endTime"] as! UFix64?
		var currentTokenId = UInt64(self.extraFields["currentTokenId"] as! Number? ?? 0)
		var maxTokenId = UInt64(self.extraFields["maxTokenId"] as! Number? ?? 0)
		if !opened{ 
			panic("sale closed")
		}
		if !(startTime == nil || startTime! <= getCurrentBlock().timestamp){ 
			panic("sale not started yet")
		}
		if !(endTime == nil || endTime! > getCurrentBlock().timestamp){ 
			panic("sale already ended")
		}
		if !(currentTokenId <= maxTokenId){ 
			panic("all minted")
		}
		if self.whitelist[(recipient.owner!).address] == nil{ 
			panic("address not in whitelist")
		}
		if self.whitelist[(recipient.owner!).address]!{ 
			panic("address in whitelist already used")
		}
		self.whitelist[(recipient.owner!).address] = true
		let minter =
			self.account.storage.borrow<&FlowNia.NFTMinter>(from: FlowNia.MinterStoragePath)!
		let metadata:{ String: String} ={} 
		if currentTokenId == 0{ 
			currentTokenId = FlowNia.totalSupply
		}
		
		// metadata code here
		minter.mintNFT(id: currentTokenId, recipient: recipient, metadata: metadata)
		self.extraFields["currentTokenId"] = currentTokenId + 1
	}
}
