import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

// TODO: change to your account which deploy ChainIDEShildNFT
import ChainIDEShieldNFT from "./ChainIDEShieldNFT.cdc"

access(all)
contract ChainIDEShieldNFTMintContract{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var sale: Sale
	
	access(all)
	struct Sale{ 
		access(all)
		var price: UFix64
		
		access(all)
		var receiver: Address
		
		init(price: UFix64, receiver: Address){ 
			self.price = price
			self.receiver = receiver
		}
	}
	
	access(all)
	fun paymentMint(
		payment: @{FungibleToken.Vault},
		amount: Int,
		recipient: &{NonFungibleToken.CollectionPublic}
	){ 
		pre{ 
			amount <= 10:
				"amount should less equal than 10 in per mint"
			payment.balance == self.sale.price! * UFix64(amount):
				"payment vault does not contain requested price"
		}
		let receiver =
			getAccount(self.sale.receiver).capabilities.get<&{FungibleToken.Receiver}>(
				/public/flowTokenReceiver
			).borrow()
			?? panic("Could not get receiver reference to Flow Token")
		receiver.deposit(from: <-payment)
		let minter =
			self.account.storage.borrow<&ChainIDEShieldNFT.NFTMinter>(
				from: ChainIDEShieldNFT.MinterStoragePath
			)!
		var index = 0
		let types = ["bronze", "silver", "gold", "platinum"]
		while index < amount{ 
			minter.mintNFT(recipient: recipient, type: types[revertibleRandom<UInt64>() % 4])
			index = index + 1
		}
	}
	
	access(all)
	resource Administrator{ 
		access(all)
		fun setSale(price: UFix64, receiver: Address){ 
			ChainIDEShieldNFTMintContract.sale = Sale(price: price, receiver: receiver)
		}
	}
	
	init(price: UFix64, receiver: Address){ 
		self.sale = Sale(price: price, receiver: receiver)
		self.AdminStoragePath = /storage/ChainIDEShieldNFTMintAdmin
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
}
