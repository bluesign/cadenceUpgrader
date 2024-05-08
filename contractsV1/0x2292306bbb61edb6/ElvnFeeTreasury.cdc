// SPDX-License-Identifier: Apache License 2.0
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import Elvn from "../0x3084a96e617d3b0a/Elvn.cdc"

// ElvnFeeTreasury
// 
// Contract Manager for taking commissions from SprtNFTStorefront
access(all)
contract ElvnFeeTreasury{ 
	access(all)
	event Initialize()
	
	access(all)
	event Withdrawn(amount: UFix64)
	
	access(all)
	event Deposited(amount: UFix64)
	
	access(all)
	resource Administrator{ 
		access(all)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			pre{ 
				amount > 0.0:
					"amount is not positive"
			}
			let vault = ElvnFeeTreasury.getVault()
			let vaultAmount = vault.balance
			if vaultAmount < amount{ 
				panic("not enough balance in vault")
			}
			emit Withdrawn(amount: amount)
			return <-vault.withdraw(amount: amount)
		}
		
		access(all)
		fun withdrawAllAmount(): @{FungibleToken.Vault}{ 
			let vault = ElvnFeeTreasury.getVault()
			let vaultAmount = vault.balance
			if vaultAmount <= 0.0{ 
				panic("not enough balance in vault")
			}
			emit Withdrawn(amount: vaultAmount)
			return <-vault.withdraw(amount: vaultAmount)
		}
	}
	
	access(all)
	fun deposit(vault: @{FungibleToken.Vault}){ 
		pre{ 
			vault.balance > 0.0:
				"amount is not positive"
		}
		let treasuryVault = ElvnFeeTreasury.getVault()
		let amount = vault.balance
		treasuryVault.deposit(from: <-vault)
		emit Deposited(amount: amount)
	}
	
	access(self)
	fun getVault(): &Elvn.Vault{ 
		return self.account.storage.borrow<&Elvn.Vault>(from: /storage/elvnVault)
		?? panic("failed borrow elvn vault")
	}
	
	access(all)
	fun getBalance(): UFix64{ 
		let vault = ElvnFeeTreasury.getVault()
		return vault.balance
	}
	
	access(all)
	fun getReceiver(): Capability<&Elvn.Vault>{ 
		return self.account.capabilities.get<&Elvn.Vault>(/public/elvnReceiver)!
	}
	
	init(){ 
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: /storage/elvnFeeTreasuryAdmin)
		if self.account.storage.borrow<&Elvn.Vault>(from: /storage/elvnVault) == nil{ 
			self.account.storage.save(<-Elvn.createEmptyVault(vaultType: Type<@Elvn.Vault>()), to: /storage/elvnVault)
			var capability_1 = self.account.capabilities.storage.issue<&Elvn.Vault>(/storage/elvnVault)
			self.account.capabilities.publish(capability_1, at: /public/elvnReceiver)
			var capability_2 = self.account.capabilities.storage.issue<&Elvn.Vault>(/storage/elvnVault)
			self.account.capabilities.publish(capability_2, at: /public/elvnBalance)
		}
		emit Initialize()
	}
}
