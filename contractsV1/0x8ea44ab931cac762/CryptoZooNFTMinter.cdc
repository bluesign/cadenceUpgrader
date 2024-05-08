// SPDX-License-Identifier: UNLICENSED
import CryptoZooNFT from "./CryptoZooNFT.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract CryptoZooNFTMinter{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	fun mintNFTWithFlow(
		recipient: &{NonFungibleToken.CollectionPublic},
		typeID: UInt64,
		paymentVault: @{FungibleToken.Vault}
	){ 
		pre{ 
			!CryptoZooNFT.isNFTTemplateExpired(typeID: typeID):
				"invalid typeID"
			!CryptoZooNFT.getNFTTemplateByTypeID(typeID: typeID).isLand:
				"land cannot be purchased directly"
			paymentVault.balance >= CryptoZooNFT.getNFTTemplateByTypeID(typeID: typeID).priceFlow:
				"Insufficient balance"
			paymentVault.getType() == Type<@FlowToken.Vault>():
				"invalid payment vault: not FlowToken"
			CryptoZooNFT.getNFTTemplateByTypeID(typeID: typeID).getTimestamps()["availableAt"]! <= getCurrentBlock().timestamp:
				"sale has not yet started"
			CryptoZooNFT.getNFTTemplateByTypeID(typeID: typeID).getTimestamps()["expiresAt"]! >= getCurrentBlock().timestamp:
				"sale has ended"
		}
		let adminFlowReceiverRef =
			self.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
				.borrow<&{FungibleToken.Receiver}>()
			?? panic("Could not borrow receiver reference to the admin's Vault")
		adminFlowReceiverRef.deposit(from: <-paymentVault)
		let admin =
			self.account.storage.borrow<&CryptoZooNFT.Admin>(from: CryptoZooNFT.AdminStoragePath)
			?? panic("Could not borrow a reference to the CryptoZooNFT Admin")
		admin.mintNFT(recipient: recipient, typeID: typeID)
	}
	
	init(){ 
		emit ContractInitialized()
	}
}
