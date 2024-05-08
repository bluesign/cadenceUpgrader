import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MonoGold from "./MonoGold.cdc"

import MonoSilver from "./MonoSilver.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

access(all)
contract MonoPaymentMinter{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var goldPrice: UFix64?
	
	access(all)
	var goldStartTime: UFix64?
	
	access(all)
	var goldEndTime: UFix64?
	
	access(all)
	var goldBaseUri: String?
	
	access(all)
	var silverPrice: UFix64?
	
	access(all)
	var silverStartTime: UFix64?
	
	access(all)
	var silverEndTime: UFix64?
	
	access(all)
	var silverBaseUri: String?
	
	access(all)
	fun paymentMintGold(
		payment: @{FungibleToken.Vault},
		recipient: &{NonFungibleToken.CollectionPublic}
	){ 
		pre{ 
			self.goldStartTime! <= getCurrentBlock().timestamp:
				"sale not started yet"
			self.goldEndTime! > getCurrentBlock().timestamp:
				"sale already ended"
			payment.isInstance(Type<@FUSD.Vault>()):
				"payment vault is not requested fungible token"
			payment.balance == self.goldPrice!:
				"payment vault does not contain requested price"
		}
		let fusdReceiver = self.account.capabilities.get<&FUSD.Vault>(/public/fusdReceiver)!
		let receiver = fusdReceiver.borrow()!
		receiver.deposit(from: <-payment)
		let minter =
			self.account.storage.borrow<&MonoGold.NFTMinter>(from: MonoGold.MinterStoragePath)!
		let metadata:{ String: String} ={} 
		metadata["token_uri"] = (self.goldBaseUri!).concat("/").concat(
				MonoGold.totalSupply.toString()
			)
		minter.mintNFT(recipient: recipient, metadata: metadata)
	}
	
	access(all)
	fun paymentMintSilver(
		payment: @{FungibleToken.Vault},
		recipient: &{NonFungibleToken.CollectionPublic}
	){ 
		pre{ 
			self.silverStartTime! <= getCurrentBlock().timestamp:
				"sale not started yet"
			self.silverEndTime! > getCurrentBlock().timestamp:
				"sale already ended"
			payment.isInstance(Type<@FUSD.Vault>()):
				"payment vault is not requested fungible token"
			payment.balance == self.silverPrice!:
				"payment vault does not contain requested price"
		}
		let fusdReceiver = self.account.capabilities.get<&FUSD.Vault>(/public/fusdReceiver)!
		let receiver = fusdReceiver.borrow()!
		receiver.deposit(from: <-payment)
		let minter =
			self.account.storage.borrow<&MonoSilver.NFTMinter>(from: MonoSilver.MinterStoragePath)!
		let metadata:{ String: String} ={} 
		metadata["token_uri"] = (self.silverBaseUri!).concat("/").concat(
				MonoSilver.totalSupply.toString()
			)
		minter.mintNFT(recipient: recipient, metadata: metadata)
	}
	
	access(all)
	resource Administrator{ 
		access(all)
		fun setGold(
			goldPrice: UFix64,
			goldStartTime: UFix64,
			goldEndTime: UFix64,
			goldBaseUri: String
		){ 
			MonoPaymentMinter.goldPrice = goldPrice
			MonoPaymentMinter.goldStartTime = goldStartTime
			MonoPaymentMinter.goldEndTime = goldEndTime
			MonoPaymentMinter.goldBaseUri = goldBaseUri
		}
		
		access(all)
		fun setSilver(
			silverPrice: UFix64,
			silverStartTime: UFix64,
			silverEndTime: UFix64,
			silverBaseUri: String
		){ 
			MonoPaymentMinter.silverPrice = silverPrice
			MonoPaymentMinter.silverStartTime = silverStartTime
			MonoPaymentMinter.silverEndTime = silverEndTime
			MonoPaymentMinter.silverBaseUri = silverBaseUri
		}
	}
	
	init(){ 
		self.goldPrice = nil
		self.goldStartTime = nil
		self.goldEndTime = nil
		self.goldBaseUri = nil
		self.silverPrice = nil
		self.silverStartTime = nil
		self.silverEndTime = nil
		self.silverBaseUri = nil
		self.AdminStoragePath = /storage/MonoPaymentMinterAdmin
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
}
