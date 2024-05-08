import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import StarVaultFactory from "../0x5c6dad1decebccb4/StarVaultFactory.cdc"

import StarVaultConfig from "../0x5c6dad1decebccb4/StarVaultConfig.cdc"

import StarVaultInterfaces from "../0x5c6dad1decebccb4/StarVaultInterfaces.cdc"

access(all)
contract Migrator{ 
	access(all)
	let vaultAddress: Address
	
	access(all)
	let fromTokenKey: String
	
	access(all)
	fun migrate(from: @{FungibleToken.Vault}): @{FungibleToken.Vault}{ 
		pre{ 
			from.balance > 0.0:
				"from vault no balance"
			self.fromTokenKey == StarVaultConfig.SliceTokenTypeIdentifierFromVaultType(vaultTypeIdentifier: from.getType().identifier):
				"from vault type error"
		}
		let balance = from.balance
		destroy from
		let collectionRef =
			self.account.storage.borrow<&StarVaultFactory.VaultTokenCollection>(
				from: StarVaultConfig.VaultTokenCollectionStoragePath
			)!
		return <-collectionRef.withdraw(vault: self.vaultAddress, amount: balance)
	}
	
	init(fromTokenKey: String, vaultAddress: Address){ 
		self.fromTokenKey = fromTokenKey
		self.vaultAddress = vaultAddress
		let collection <- StarVaultFactory.createEmptyVaultTokenCollection()
		let storagePath = StarVaultConfig.VaultTokenCollectionStoragePath
		self.account.storage.save(<-collection, to: storagePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&StarVaultFactory.VaultTokenCollection>(
				storagePath
			)
		self.account.capabilities.publish(
			capability_1,
			at: StarVaultConfig.VaultTokenCollectionPublicPath
		)
	}
}
