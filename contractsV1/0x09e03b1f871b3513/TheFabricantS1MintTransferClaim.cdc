/*
	Description: TheFabricantS1MintTransferClaim Contract
   
	This contract prevents users from minting TheFabricantS1ItemNFTs 
	more than a selected amount of times
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import TheFabricantS1GarmentNFT from "../0x9e03b1f871b3513/TheFabricantS1GarmentNFT.cdc"

import TheFabricantS1MaterialNFT from "../0x9e03b1f871b3513/TheFabricantS1MaterialNFT.cdc"

import TheFabricantS1ItemNFT from "../0x9e03b1f871b3513/TheFabricantS1ItemNFT.cdc"

access(all)
contract TheFabricantS1MintTransferClaim{ 
	access(all)
	event ItemMintedAndTransferred(
		garmentDataID: UInt32,
		materialDataID: UInt32,
		primaryColor: String,
		secondaryColor: String,
		itemID: UInt64,
		itemDataID: UInt32,
		name: String
	)
	
	// dictionary of addresses and how many items they have minted
	access(self)
	var addressMintCount:{ Address: UInt32}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var maxMintAmount: UInt32
	
	//is the contract closed
	access(all)
	var closed: Bool
	
	access(all)
	resource Admin{ 
		
		//prevent minting
		access(all)
		fun closeClaim(){ 
			TheFabricantS1MintTransferClaim.closed = true
		}
		
		//call S1ItemNFT's mintItem function
		//each address can only mint 2 times
		access(all)
		fun mintAndTransferItem(
			name: String,
			recipientAddr: Address,
			royalty: TheFabricantS1ItemNFT.Royalty,
			garment: @TheFabricantS1GarmentNFT.NFT,
			material: @TheFabricantS1MaterialNFT.NFT,
			primaryColor: String,
			secondaryColor: String
		): @TheFabricantS1ItemNFT.NFT{ 
			pre{ 
				!TheFabricantS1MintTransferClaim.closed:
					"Minting is closed"
				TheFabricantS1MintTransferClaim.addressMintCount[recipientAddr] != TheFabricantS1MintTransferClaim.maxMintAmount:
					"Address has minted max amount of items already"
			}
			let garmentDataID = garment.garment.garmentDataID
			let materialDataID = material.material.materialDataID
			
			// we check using the itemdataallocation using the garment/material dataid and primary/secondary color
			let itemDataID =
				TheFabricantS1ItemNFT.getItemDataAllocation(
					garmentDataID: garmentDataID,
					materialDataID: materialDataID,
					primaryColor: primaryColor,
					secondaryColor: secondaryColor
				)
			
			//set mint count of transacter as 1 if first time, else 2
			if TheFabricantS1MintTransferClaim.addressMintCount[recipientAddr] == nil{ 
				TheFabricantS1MintTransferClaim.addressMintCount[recipientAddr] = 1
			} else{ 
				TheFabricantS1MintTransferClaim.addressMintCount[recipientAddr] = TheFabricantS1MintTransferClaim.addressMintCount[recipientAddr]! + 1
			}
			let garmentID = garment.id
			let materialID = material.id
			
			//admin mints the item
			let item <-
				TheFabricantS1ItemNFT.mintNFT(
					name: name,
					royaltyVault: royalty,
					garment: <-garment,
					material: <-material,
					primaryColor: primaryColor,
					secondaryColor: secondaryColor
				)
			emit ItemMintedAndTransferred(
				garmentDataID: garmentDataID,
				materialDataID: materialDataID,
				primaryColor: primaryColor,
				secondaryColor: secondaryColor,
				itemID: item.id,
				itemDataID: item.item.itemDataID,
				name: name
			)
			return <-item
		}
		
		access(all)
		fun changeMaxMintAmount(newMax: UInt32){ 
			TheFabricantS1MintTransferClaim.maxMintAmount = newMax
		}
		
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(all)
	fun getAddressMintCount():{ Address: UInt32}{ 
		return TheFabricantS1MintTransferClaim.addressMintCount
	}
	
	init(){ 
		self.closed = false
		self.maxMintAmount = 2
		self.addressMintCount ={} 
		self.AdminStoragePath = /storage/TheFabricantS1MintTransferClaimAdmin0019
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
	}
}
