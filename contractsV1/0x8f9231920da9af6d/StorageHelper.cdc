import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract StorageHelper{ 
	access(all)
	var topUpAmount: UFix64
	
	access(all)
	var topUpThreshold: UInt64
	
	access(all)
	event AccountToppedUp(address: Address, amount: UFix64)
	
	access(all)
	fun availableAccountStorage(address: Address): UInt64{ 
		return getAccount(address).storage.capacity - getAccount(address).storage.used
	}
	
	access(account)
	fun topUpAccount(address: Address){ 
		let topUpAmount = self.getTopUpAmount()
		let topUpThreshold = self.getTopUpThreshold()
		if StorageHelper.availableAccountStorage(address: address) > topUpThreshold{ 
			return
		}
		let vaultRef =
			self.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Could not borrow reference to the owner's Vault!")
		let topUpFunds <- vaultRef.withdraw(amount: topUpAmount)
		let receiverRef =
			getAccount(address).capabilities.get<&{FungibleToken.Receiver}>(
				/public/flowTokenReceiver
			).borrow<&{FungibleToken.Receiver}>()
			?? panic("Could not borrow receiver reference to the recipient's Vault")
		receiverRef.deposit(from: <-topUpFunds)
		emit AccountToppedUp(address: address, amount: topUpAmount)
	}
	
	access(account)
	fun updateTopUpAmount(amount: UFix64){ 
		self.topUpAmount = amount
	}
	
	access(account)
	fun updateTopUpThreshold(threshold: UInt64){ 
		self.topUpThreshold = threshold
	}
	
	access(account)
	fun getTopUpAmount(): UFix64{ 
		return 0.000012 // self.topUpAmount //
	
	}
	
	access(account)
	fun getTopUpThreshold(): UInt64{ 
		return 1200 // self.topUpThreshold
	
	}
	
	init(){ 
		self.topUpAmount = 0.000012
		self.topUpThreshold = 1200
	}
}
