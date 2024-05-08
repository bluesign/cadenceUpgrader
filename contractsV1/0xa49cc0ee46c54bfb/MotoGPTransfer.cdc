import FlowToken from "./../../standardsV1/FlowToken.cdc"

import MotoGPAdmin from "./MotoGPAdmin.cdc"

import MotoGPPack from "./MotoGPPack.cdc"

import MotoGPCard from "./MotoGPCard.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowStorageFees from "../0xe467b9dd11fa00df/FlowStorageFees.cdc"

import ContractVersion from "./ContractVersion.cdc"

import PackOpener from "./PackOpener.cdc"

// Contract for topping up an account's storage capacity when it receives a MotoGP pack or card
//
access(all)
contract MotoGPTransfer: ContractVersion{ 
	access(all)
	fun getVersion(): String{ 
		return "0.7.8"
	}
	
	// The minium amount to top up
	//
	access(account)
	var minFlowTopUp: UFix64
	
	// The maximum amount to top up
	//
	access(account)
	var maxFlowTopUp: UFix64
	
	// Vault where the admin stores Flow tokens to pay for top-ups
	//
	access(self)
	var flowVault: @FlowToken.Vault
	
	access(self)
	var isPaused: Bool //for future use
	
	
	// Transfers packs from one collection to another, with storage top-up if needed
	//
	access(all)
	fun transferPacks(fromCollection: @MotoGPPack.Collection, toCollection: &MotoGPPack.Collection, toAddress: Address){ 
		pre{ 
			fromCollection.getIDs().length > 0:
				"No packs in fromCollection"
		}
		for id in fromCollection.getIDs(){ 
			toCollection.deposit(token: <-fromCollection.withdraw(withdrawID: id))
		}
		self.topUp(toAddress)
		destroy fromCollection
	}
	
	// Transfer cards from one collection to another, with storage top-up if needed
	//
	access(all)
	fun transferCards(fromCollection: @MotoGPCard.Collection, toCollection: &MotoGPCard.Collection, toAddress: Address){ 
		pre{ 
			fromCollection.getIDs().length > 0:
				"No cards in fromCollection"
		}
		for id in fromCollection.getIDs(){ 
			toCollection.deposit(token: <-fromCollection.withdraw(withdrawID: id))
		}
		self.topUp(toAddress)
		destroy fromCollection
	}
	
	// Transfer a pack to a Pack opener collection, with storage top-up if needed
	access(all)
	fun transferPackToPackOpenerCollection(pack: @MotoGPPack.NFT, toCollection: &PackOpener.Collection, toAddress: Address){ 
		toCollection.deposit(token: <-pack)
		self.topUp(toAddress)
	}
	
	// Admin-controlled method for use in transactions where admin wants to do top-up, e.g. open packs
	//
	access(all)
	fun topUpFlowForAccount(adminRef: &MotoGPAdmin.Admin, toAddress: Address){ 
		pre{ 
			adminRef != nil:
				"AdminRef is nil"
		}
		self.topUp(toAddress)
	}
	
	// Core logic for topping up an account
	//
	access(self)
	fun topUp(_ toAddress: Address){ 
		post{ 
			before(self.flowVault.balance) - self.flowVault.balance <= self.maxFlowTopUp:
				"Top up exceeds max top up"
		}
		let toAccount = getAccount(toAddress)
		if toAccount.storage.capacity < toAccount.storage.used{ 
			let topUpAmount: UFix64 = self.flowForStorage(toAccount.storage.used - toAccount.storage.capacity)
			let toVault = toAccount.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver).borrow<&FlowToken.Vault>()!
			toVault.deposit(from: <-self.flowVault.withdraw(amount: topUpAmount))
		}
	}
	
	// Converts storage bytes to a FLOW token amount
	//
	access(self)
	fun flowForStorage(_ storage: UInt64): UFix64{ 
		return FlowStorageFees.storageCapacityToFlow(FlowStorageFees.convertUInt64StorageBytesToUFix64Megabytes(storage))
	}
	
	access(all)
	fun setMinFlowTopUp(adminRef: &MotoGPAdmin.Admin, amount: UFix64){ 
		pre{ 
			adminRef != nil:
				"adminRef is nil"
		}
		self.minFlowTopUp = amount
	}
	
	access(all)
	fun setMaxFlowTopUp(adminRef: &MotoGPAdmin.Admin, amount: UFix64){ 
		pre{ 
			adminRef != nil:
				"adminRef is nil"
		}
		self.maxFlowTopUp = amount
	}
	
	access(all)
	fun getFlowBalance(): UFix64{ 
		return self.flowVault.balance
	}
	
	access(all)
	fun depositFlow(from: @{FungibleToken.Vault}){ 
		let vault <- from as! @FlowToken.Vault
		self.flowVault.deposit(from: <-vault)
	}
	
	access(all)
	fun withdrawFlow(adminRef: &MotoGPAdmin.Admin, amount: UFix64): @{FungibleToken.Vault}{ 
		pre{ 
			adminRef != nil:
				"adminRef is nil"
		}
		return <-self.flowVault.withdraw(amount: amount)
	}
	
	init(){ 
		self.flowVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()) as! @FlowToken.Vault
		self.minFlowTopUp = 0.0
		self.maxFlowTopUp = 0.1
		self.isPaused = false //for future use
	
	}
}
