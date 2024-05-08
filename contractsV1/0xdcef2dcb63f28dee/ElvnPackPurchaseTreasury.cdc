// SPDX-License-Identifier: Apache License 2.0
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import Elvn from "../0x6292b23b3eb3f999/Elvn.cdc"

access(all)
contract ElvnPackPurchaseTreasury{ 
	access(contract)
	let elvnVault: @Elvn.Vault
	
	access(all)
	event Initialize()
	
	access(all)
	event WithdrawnElvn(amount: UFix64)
	
	access(all)
	event DepositedElvn(amount: UFix64)
	
	access(all)
	resource ElvnAdministrator{ 
		access(all)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			pre{ 
				amount > 0.0:
					"amount is not positive"
			}
			let vaultAmount = ElvnPackPurchaseTreasury.elvnVault.balance
			if vaultAmount < amount{ 
				panic("not enough balance in vault")
			}
			emit WithdrawnElvn(amount: amount)
			return <-ElvnPackPurchaseTreasury.elvnVault.withdraw(amount: amount)
		}
		
		access(all)
		fun withdrawAllAmount(): @{FungibleToken.Vault}{ 
			let vaultAmount = ElvnPackPurchaseTreasury.elvnVault.balance
			if vaultAmount <= 0.0{ 
				panic("not enough balance in vault")
			}
			emit WithdrawnElvn(amount: vaultAmount)
			return <-ElvnPackPurchaseTreasury.elvnVault.withdraw(amount: vaultAmount)
		}
	}
	
	access(all)
	fun depositElvn(vault: @{FungibleToken.Vault}){ 
		pre{ 
			vault.balance > 0.0:
				"amount is not positive"
		}
		let amount = vault.balance
		self.elvnVault.deposit(from: <-vault)
		emit DepositedElvn(amount: amount)
	}
	
	access(all)
	fun getBalance(): UFix64{ 
		return self.elvnVault.balance
	}
	
	init(){ 
		self.elvnVault <- Elvn.createEmptyVault(vaultType: Type<@Elvn.Vault>()) as! @Elvn.Vault
		let elvnAdmin <- create ElvnAdministrator()
		self.account.storage.save(<-elvnAdmin, to: /storage/packPurchaseTreasuryAdmin)
		emit Initialize()
	}
}
