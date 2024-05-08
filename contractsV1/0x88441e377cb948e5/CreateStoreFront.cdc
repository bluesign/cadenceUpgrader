// SPDX-License-Identifier: Unlicense
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract CreateStoreFront{ 
	access(all)
	event CreateStoreFrontSubmit(storefrontAddress: Address)
	
	access(account)
	var beneficiaryCapability: Capability<&{FungibleToken.Receiver}>?
	
	access(account)
	var amount: UFix64
	
	access(all)
	fun createStorefront(storefrontAddress: Address, vault: @{FungibleToken.Vault}){ 
		pre{ 
			vault.balance == self.amount:
				"Amount does not match the amount"
			self.amount >= UFix64(0):
				"Configure the amount field"
		}
		((self.beneficiaryCapability!).borrow()!).deposit(from: <-vault)
		emit CreateStoreFrontSubmit(storefrontAddress: storefrontAddress)
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun updateBeneficiary(
			beneficiaryCapabilityReceiver: Capability<&{FungibleToken.Receiver}>
		){ 
			CreateStoreFront.beneficiaryCapability = beneficiaryCapabilityReceiver
		}
		
		access(all)
		fun updateAmount(amountReceiver: UFix64){ 
			CreateStoreFront.amount = amountReceiver
		}
	}
	
	init(){ 
		self.amount = UFix64(0)
		self.beneficiaryCapability = nil
		self.account.storage.save<@CreateStoreFront.Admin>(
			<-create Admin(),
			to: /storage/createStoreFrontAdmin
		)
	}
}
