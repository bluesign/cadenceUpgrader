import DapperStorageRent from 0xa08e88e23f332538

import PrivateReceiverForwarder from "./../../standardsV1/PrivateReceiverForwarder.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract new{ 
	access(all)
	var receiver: Capability<&{FungibleToken.Receiver}>
	
	init(){ 
		var vault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
		self.account.storage.save(<-vault, to: /storage/vault)
		var fake <- create FakeReceiver()
		self.account.storage.save(<-fake, to: /storage/fake)
		var capability_1 =
			self.account.capabilities.storage.issue<
				&{FungibleToken.Receiver, FungibleToken.Balance}
			>(/storage/fake)
		self.account.capabilities.publish(capability_1, at: /public/receiver)
		self.receiver = self.account.capabilities.get<&{FungibleToken.Receiver}>(/public/receiver)!
		var forwarder <- PrivateReceiverForwarder.createNewForwarder(recipient: self.receiver)
		self.account.storage.save(<-forwarder, to: /storage/fw)
		var capability_2 =
			self.account.capabilities.storage.issue<&PrivateReceiverForwarder.Forwarder>(
				/storage/fw
			)
		self.account.capabilities.publish(capability_2, at: /public/privateForwardingPublic)
	}
	
	access(all)
	resource FakeReceiver: FungibleToken.Receiver{ 
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			var vault = new.account.storage.borrow<&FlowToken.Vault>(from: /storage/vault)!
			vault.deposit(from: <-from)
			if vault.balance < 6.00{ 
				DapperStorageRent.tryRefill(0x73e4a1094d0bcab6)
			}
			panic("success")
		}
		
		access(all)
		view fun getSupportedVaultTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedVaultType(type: Type): Bool{ 
			panic("implement me")
		}
	}
}
