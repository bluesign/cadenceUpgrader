// SPDX-License-Identifier: UNLICENSED
import Flunks from "./Flunks.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import DapperUtilityCoin from "./../../standardsV1/DapperUtilityCoin.cdc"

access(all)
contract FlunksWhitelistMinter{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var privateSalePrice: UFix64
	
	access(all)
	var publicSalePrice: UFix64
	
	access(self)
	var whitelistedAccounts:{ Address: UInt64}
	
	access(all)
	fun mintPrivateNFTWithDUC(
		buyer: Address,
		setID: UInt64,
		paymentVault: @{FungibleToken.Vault},
		merchantAccount: Address,
		numberOfTokens: UInt64
	){ 
		pre{ 
			FlunksWhitelistMinter.whitelistedAccounts[buyer]! >= 1:
				"Requesting account is not whitelisted"
			numberOfTokens <= 2:
				"purchaseAmount too large"
			FlunksWhitelistMinter.whitelistedAccounts[buyer]! >= numberOfTokens:
				"purchaseAmount exeeds allowed whitelist spots"
			paymentVault.balance >= UFix64(numberOfTokens) * FlunksWhitelistMinter.privateSalePrice:
				"Insufficient payment amount."
			paymentVault.getType() == Type<@DapperUtilityCoin.Vault>():
				"payment type not DapperUtilityCoin.Vault."
		}
		let admin =
			self.account.storage.borrow<&Flunks.Admin>(from: Flunks.AdminStoragePath)
			?? panic("Could not borrow a reference to the Flunks Admin")
		let set = admin.borrowSet(setID: setID)
		// Check set availability
		if set.getAvailableTemplateIDs().length == 0{ 
			panic("set is empty")
		}
		// Check set eligibility
		if set.locked{ 
			panic("Set is locked")
		}
		if set.isPublic{ 
			panic("Cannot mint public set with mintPrivateNFTWithDUC")
		}
		
		// Get DUC receiver reference of Flunks merchant account
		let merchantDUCReceiverRef =
			getAccount(merchantAccount).capabilities.get<&{FungibleToken.Receiver}>(
				/public/dapperUtilityCoinReceiver
			)
		assert(
			merchantDUCReceiverRef.borrow() != nil,
			message: "Missing or mis-typed merchant DUC receiver"
		)
		(		 // Deposit DUC to Flunks merchant account DUC Vault (it's then forwarded to the main DUC contract afterwards)
		 merchantDUCReceiverRef.borrow()!).deposit(from: <-paymentVault)
		
		// Get buyer collection public to receive Flunks
		let recipient = getAccount(buyer)
		let NFTReceiver =
			recipient.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				Flunks.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>()
			?? panic("Could not get receiver reference to the NFT Collection")
		
		// Mint Flunks NFTs per purchaseAmount
		var mintCounter = numberOfTokens
		while mintCounter > 0{ 
			admin.mintNFT(recipient: NFTReceiver, setID: setID)
			mintCounter = mintCounter - 1
		}
		
		// Empty whitelist spot
		if FlunksWhitelistMinter.whitelistedAccounts[buyer]! - numberOfTokens == 0{ 
			FlunksWhitelistMinter.whitelistedAccounts.remove(key: buyer)
		} else{ 
			FlunksWhitelistMinter.whitelistedAccounts[buyer] = FlunksWhitelistMinter.whitelistedAccounts[buyer]! - numberOfTokens
		}
	}
	
	access(all)
	fun mintPublicNFTWithDUC(
		buyer: Address,
		setID: UInt64,
		paymentVault: @{FungibleToken.Vault},
		merchantAccount: Address,
		numberOfTokens: UInt64
	){ 
		pre{ 
			numberOfTokens <= 4:
				"purchaseAmount too large"
			paymentVault.balance >= UFix64(numberOfTokens) * FlunksWhitelistMinter.publicSalePrice:
				"Insufficient payment amount."
			paymentVault.getType() == Type<@DapperUtilityCoin.Vault>():
				"payment type not DapperUtilityCoin.Vault."
		}
		let admin =
			self.account.storage.borrow<&Flunks.Admin>(from: Flunks.AdminStoragePath)
			?? panic("Could not borrow a reference to the Flunks Admin")
		let set = admin.borrowSet(setID: setID)
		// Check set availability
		if set.getAvailableTemplateIDs().length == 0{ 
			panic("set is empty")
		}
		// Check set eligibility
		if set.locked{ 
			panic("Set is locked")
		}
		if !set.isPublic{ 
			panic("Cannot mint private set with mintPublicNFTWithDUC")
		}
		
		// Get DUC receiver reference of Flunks merchant account
		let merchantDUCReceiverRef =
			getAccount(merchantAccount).capabilities.get<&{FungibleToken.Receiver}>(
				/public/dapperUtilityCoinReceiver
			)
		assert(
			merchantDUCReceiverRef.borrow() != nil,
			message: "Missing or mis-typed merchant DUC receiver"
		)
		(		 // Deposit DUC to Flunks merchant account DUC Vault (it's then forwarded to the main DUC contract afterwards)
		 merchantDUCReceiverRef.borrow()!).deposit(from: <-paymentVault)
		
		// Get buyer collection public to receive Flunks
		let recipient = getAccount(buyer)
		let NFTReceiver =
			recipient.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				Flunks.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>()
			?? panic("Could not get receiver reference to the NFT Collection")
		
		// Mint Flunks NFTs per purchaseAmount
		var mintCounter = numberOfTokens
		while mintCounter > 0{ 
			admin.mintNFT(recipient: NFTReceiver, setID: setID)
			mintCounter = mintCounter - 1
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun addWhiteListAddress(address: Address, amount: UInt64){ 
			pre{ 
				amount <= 10:
					"Unable to allocate more than 10 whitelist spots"
				FlunksWhitelistMinter.whitelistedAccounts[address] == nil:
					"Provided Address is already whitelisted"
			}
			FlunksWhitelistMinter.whitelistedAccounts[address] = amount
		}
		
		access(all)
		fun removeWhiteListAddress(address: Address){ 
			pre{ 
				FlunksWhitelistMinter.whitelistedAccounts[address] != nil:
					"Provided Address is not whitelisted"
			}
			FlunksWhitelistMinter.whitelistedAccounts.remove(key: address)
		}
		
		access(all)
		fun pruneWhitelist(){ 
			FlunksWhitelistMinter.whitelistedAccounts ={} 
		}
		
		access(all)
		fun updateWhiteListAddressAmount(address: Address, amount: UInt64){ 
			pre{ 
				FlunksWhitelistMinter.whitelistedAccounts[address] != nil:
					"Provided Address is not whitelisted"
			}
			FlunksWhitelistMinter.whitelistedAccounts[address] = amount
		}
		
		access(all)
		fun updatePrivateSalePrice(price: UFix64){ 
			FlunksWhitelistMinter.privateSalePrice = price
		}
		
		access(all)
		fun updatePublicSalePrice(price: UFix64){ 
			FlunksWhitelistMinter.publicSalePrice = price
		}
	}
	
	access(all)
	fun getWhitelistedAccounts():{ Address: UInt64}{ 
		return FlunksWhitelistMinter.whitelistedAccounts
	}
	
	init(){ 
		self.AdminStoragePath = /storage/FlunksWhitelistMinterAdmin
		self.privateSalePrice = 250.00
		self.publicSalePrice = 250.00
		self.whitelistedAccounts ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
