import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract DelayedTransfer{ 
	// path for admin resource
	access(all)
	let AdminPath: StoragePath
	
	// ========== events ==========
	access(all)
	event DelayedTransferAdded(id: String)
	
	access(all)
	event DelayedTransferExecuted(id: String, receiver: Address, token: String, amount: UFix64)
	
	access(all)
	event DelayPeriodUpdated(period: UInt64)
	
	// ========== structs ==========
	/// one delayed transfer info, will release if current block.timestamp >= info.blockTs + delayPeriod
	access(all)
	struct Info{ 
		// block.timestamp when this xfer is added
		access(all)
		let blockTs: UFix64
		
		// .borrow then .deposit
		access(all)
		let receiverCap: Capability<&{FungibleToken.Receiver}>
		
		init(blockTs: UFix64, receiverCap: Capability<&{FungibleToken.Receiver}>){ 
			self.blockTs = blockTs
			self.receiverCap = receiverCap
		}
	}
	
	// ========== contract states and maps ==========
	// how many seconds for delayed transfer to wait,
	// default is 3600*24 = 86400, can be changed by Admin
	access(all)
	var delayPeriod: UInt64
	
	// map from unique ID string to Info struct and from vault, have to keep fromVault separate as struct can't include Resource
	// and Capability can only be acquired by path which doesn't exist in mint case
	access(account)
	var infoMap:{ String: Info}
	
	access(account)
	var vaultMap: @{String:{ FungibleToken.Vault}}
	
	// when SafeBox/PegBridge is paused, this will also be paused
	access(all)
	var isPaused: Bool
	
	// ========== resource ==========
	access(all)
	resource Admin{ 
		access(all)
		fun setDelayPeriod(newP: UInt64){ 
			DelayedTransfer.delayPeriod = newP
			emit DelayPeriodUpdated(period: newP)
		}
		
		// createNewAdmin creates a new Admin resource
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	// ========== functions ==========
	init(){ 
		self.delayPeriod = 86400
		self.infoMap ={} 
		self.vaultMap <-{} 
		self.isPaused = false
		self.AdminPath = /storage/DelayedTransferAdmin
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminPath)
	}
	
	access(account)
	fun pause(){ 
		self.isPaused = true
	}
	
	access(account)
	fun unPause(){ 
		self.isPaused = false
	}
	
	// only accessible by contracts in the same account to avoid spam (storage cost and valid ids)
	access(account)
	fun addDelayXfer(
		id: String,
		receiverCap: Capability<&{FungibleToken.Receiver}>,
		from: @{FungibleToken.Vault}
	){ 
		pre{ 
			!self.infoMap.containsKey(id):
				"id already exists!"
			!self.vaultMap.containsKey(id):
				"id already exists!"
		}
		self.infoMap[id] = Info(blockTs: getCurrentBlock().timestamp, receiverCap: receiverCap)
		let old <- self.vaultMap[id] <- from
		destroy old
		emit DelayedTransferAdded(id: id)
	}
	
	// execute xfer, if id is found in infoMap and block is big enough, deposit fund to receiver
	// we must restrict to account because if safebox/pegbridge contracts are paused, this can't be called either
	// note if only one contract is paused, we pause all executeDelayXfer for safety
	access(account)
	fun executeDelayXfer(_ wdId: String){ 
		pre{ 
			!self.isPaused:
				"delay transfer is paused"
			self.infoMap.containsKey(wdId):
				"wdId not found!"
			self.vaultMap.containsKey(wdId):
				"wdId not found!"
		}
		let xfer = self.infoMap[wdId]!
		assert(
			getCurrentBlock().timestamp > xfer.blockTs + UFix64(self.delayPeriod),
			message: "delayed transfer still locked"
		)
		// delete from map so no re-trigger
		self.infoMap.remove(key: wdId)
		let recRef = xfer.receiverCap.borrow() ?? panic("Could not borrow reference to receiver")
		let fromVault <- self.vaultMap.remove(key: wdId)!
		let tokStr = fromVault.getType().identifier
		let amt = fromVault.balance
		recRef.deposit(from: <-fromVault)
		emit DelayedTransferExecuted(
			id: wdId,
			receiver: (recRef.owner!).address,
			token: tokStr,
			amount: amt
		)
	}
}
