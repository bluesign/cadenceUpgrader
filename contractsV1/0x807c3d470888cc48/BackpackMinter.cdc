// SPDX-License-Identifier: UNLICENSED
import Flunks from "./Flunks.cdc"

import Backpack from "./Backpack.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import DapperUtilityCoin from "./../../standardsV1/DapperUtilityCoin.cdc"

access(all)
contract BackpackMinter{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event BackpackClaimed(FlunkTokenID: UInt64, BackpackTokenID: UInt64, signer: Address)
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(self)
	var backpackClaimedPerFlunkTokenID:{ UInt64: UInt64} // Flunk token ID: backpack token ID
	
	
	access(self)
	var backpackClaimedPerFlunkTemplate:{ UInt64: UInt64} // Flunks template ID: backpack token ID
	
	
	access(all)
	fun claimBackPack(tokenID: UInt64, signer: AuthAccount, setID: UInt64){ 
		// verify that the token is not already claimed
		pre{ 
			tokenID >= 0 && tokenID <= 9998:
				"Invalid Flunk token ID"
			!BackpackMinter.backpackClaimedPerFlunkTokenID.containsKey(tokenID):
				"Token ID already claimed"
		}
		
		// verify Flunk ownership
		let collection =
			getAccount(signer.address).capabilities.get<&Flunks.Collection>(
				Flunks.CollectionPublicPath
			).borrow()!
		let collectionIDs = collection.getIDs()
		if !collectionIDs.contains(tokenID){ 
			panic("signer is not owner of Flunk")
		}
		
		// Get recipient receiver capoatility
		let recipient = getAccount(signer.address)
		let backpackReceiver =
			recipient.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				Backpack.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>()
			?? panic("Could not get receiver reference to the Backpack NFT Collection")
		
		// mint backpack to signer
		let admin =
			self.account.storage.borrow<&Backpack.Admin>(from: Backpack.AdminStoragePath)
			?? panic("Could not borrow a reference to the Backpack Admin")
		let backpackSet = admin.borrowSet(setID: setID)
		let backpackNFT <- backpackSet.mintNFT()
		let backpackTokenID = backpackNFT.id
		emit BackpackClaimed(
			FlunkTokenID: tokenID,
			BackpackTokenID: backpackNFT.id,
			signer: signer.address
		)
		backpackReceiver.deposit(token: <-backpackNFT)
		BackpackMinter.backpackClaimedPerFlunkTokenID[tokenID] = backpackTokenID
		let templateID = (collection.borrowFlunks(id: tokenID)!).templateID
		BackpackMinter.backpackClaimedPerFlunkTemplate[templateID] = backpackTokenID
	}
	
	access(all)
	fun getClaimedBackPacksPerFlunkTokenID():{ UInt64: UInt64}{ 
		return BackpackMinter.backpackClaimedPerFlunkTokenID
	}
	
	access(all)
	fun getClaimedBackPacksPerFlunkTemplateID():{ UInt64: UInt64}{ 
		return BackpackMinter.backpackClaimedPerFlunkTemplate
	}
	
	init(){ 
		self.AdminStoragePath = /storage/BackpackMinterAdmin
		self.backpackClaimedPerFlunkTokenID ={} 
		self.backpackClaimedPerFlunkTemplate ={} 
		emit ContractInitialized()
	}
}
