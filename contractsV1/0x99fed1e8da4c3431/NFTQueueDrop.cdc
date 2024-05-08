import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract NFTQueueDrop{ 
	access(all)
	event Claimed(nftType: Type, nftID: UInt64)
	
	access(all)
	let DropStoragePath: StoragePath
	
	access(all)
	let DropPublicPath: PublicPath
	
	access(all)
	enum DropStatus: UInt8{ 
		access(all)
		case open
		
		access(all)
		case paused
		
		access(all)
		case closed
	}
	
	access(all)
	resource interface DropPublic{ 
		access(all)
		let price: UFix64
		
		access(all)
		let size: Int
		
		access(all)
		var status: DropStatus
		
		access(all)
		fun supply(): Int
		
		access(all)
		fun claim(payment: @{FungibleToken.Vault}): @{NonFungibleToken.NFT}
	}
	
	access(all)
	resource Drop: DropPublic{ 
		access(self)
		let nftType: Type
		
		access(self)
		let collection: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
		
		access(self)
		let paymentReceiver: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let price: UFix64
		
		access(all)
		let size: Int
		
		access(all)
		var status: DropStatus
		
		access(all)
		fun pause(){ 
			self.status = DropStatus.paused
		}
		
		access(all)
		fun resume(){ 
			pre{ 
				self.status != DropStatus.closed:
					"Cannot resume drop that is closed"
			}
			self.status = DropStatus.open
		}
		
		access(all)
		fun close(){ 
			self.status = DropStatus.closed
		}
		
		access(all)
		fun supply(): Int{ 
			return (self.collection.borrow()!).getIDs().length
		}
		
		access(all)
		fun complete(): Bool{ 
			return self.supply() == 0
		}
		
		access(self)
		fun pop(): @{NonFungibleToken.NFT}{ 
			let collection = self.collection.borrow()!
			let ids = collection.getIDs()
			let nextID = ids[0]
			return <-collection.withdraw(withdrawID: nextID)
		}
		
		access(all)
		fun claim(payment: @{FungibleToken.Vault}): @{NonFungibleToken.NFT}{ 
			pre{ 
				payment.balance == self.price:
					"payment vault does not contain requested price"
			}
			let collection = self.collection.borrow()!
			let receiver = self.paymentReceiver.borrow()!
			receiver.deposit(from: <-payment)
			let nft <- self.pop()
			if self.supply() == 0{ 
				self.close()
			}
			emit Claimed(nftType: self.nftType, nftID: nft.id)
			return <-nft
		}
		
		init(nftType: Type, collection: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>, paymentReceiver: Capability<&{FungibleToken.Receiver}>, paymentPrice: UFix64){ 
			self.nftType = nftType
			self.collection = collection
			self.paymentReceiver = paymentReceiver
			self.price = paymentPrice
			self.size = (collection.borrow()!).getIDs().length
			self.status = DropStatus.open
		}
	}
	
	access(all)
	fun createDrop(
		nftType: Type,
		collection: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
		paymentReceiver: Capability<&{FungibleToken.Receiver}>,
		paymentPrice: UFix64
	): @Drop{ 
		return <-create Drop(
			nftType: nftType,
			collection: collection,
			paymentReceiver: paymentReceiver,
			paymentPrice: paymentPrice
		)
	}
	
	init(){ 
		self.DropStoragePath = /storage/NFTQueueDrop
		self.DropPublicPath = /public/NFTQueueDrop
	}
}
