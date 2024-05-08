// SPDX-License-Identifier: MIT
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import DapperUtilityCoin from "./../../standardsV1/DapperUtilityCoin.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import KlktnVoucher from "./KlktnVoucher.cdc"

access(all)
contract KlktnVoucherMinter{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(contract)
	var mintedAccounts:{ Address: UInt64}
	
	access(all)
	fun mintKlktnVoucher(buyer: Address, templateID: UInt64){ 
		pre{ 
			!KlktnVoucherMinter.mintedAccounts.containsKey(buyer):
				"Already minted!"
		}
		let admin =
			self.account.storage.borrow<&KlktnVoucher.Admin>(from: KlktnVoucher.AdminStoragePath)
			?? panic("Could not borrow a reference to the KlktnVoucher Admin")
		let recipient = getAccount(buyer)
		let NFTReceiver =
			recipient.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				KlktnVoucher.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>()
			?? panic("Could not get receiver reference to the NFT Collection")
		
		// Validate buyer's DUC receiver
		let buyerDUCReceiverRef =
			getAccount(buyer).capabilities.get<&{FungibleToken.Receiver}>(
				/public/dapperUtilityCoinReceiver
			)
		assert(
			buyerDUCReceiverRef.borrow() != nil,
			message: "Missing or mis-typed buyer DUC receiver"
		)
		admin.mintNFT(recipient: NFTReceiver, templateID: templateID)
		KlktnVoucherMinter.mintedAccounts[buyer] = 1
	}
	
	access(all)
	fun hasMinted(address: Address): Bool{ 
		return KlktnVoucherMinter.mintedAccounts.containsKey(address)
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun removeUserFromMintedAccounts(address: Address){ 
			pre{ 
				KlktnVoucherMinter.mintedAccounts[address] != nil:
					"Provided Address is not found"
			}
			KlktnVoucherMinter.mintedAccounts.remove(key: address)
		}
	}
	
	init(){ 
		self.AdminStoragePath = /storage/KlktnVoucherMinterWhitelistMinterAdmin
		self.mintedAccounts ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
