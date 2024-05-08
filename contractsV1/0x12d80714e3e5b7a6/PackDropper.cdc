/*
	PackSeller.cdc

	Description: Contract for pack buying and adding new packs  

*/

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

access(all)
contract PackDropper{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event PackAdded(id: UInt32, name: String, size: Int, price: UFix64, availableFrom: UFix64)
	
	access(all)
	event PackBought(id: UInt32, address: Address?, order: Int)
	
	access(all)
	let PacksHandlerStoragePath: StoragePath
	
	access(all)
	let PacksHandlerPublicPath: PublicPath
	
	access(all)
	let PacksInfoPublicPath: PublicPath
	
	// Variable size dictionary of CombinationData structs
	access(all)
	var currentPackId: UInt32
	
	access(all)
	struct PackData{ 
		access(all)
		let id: UInt32
		
		access(all)
		let name: String
		
		access(all)
		let size: Int
		
		access(all)
		let price: UFix64
		
		access(all)
		let availableFromTimeStamp: UFix64
		
		access(all)
		let buyers: [Address]
		
		init(name: String, size: Int, price: UFix64, availableFrom: UFix64){ 
			self.id = PackDropper.currentPackId
			self.name = name
			self.size = size
			self.price = price
			self.availableFromTimeStamp = availableFrom
			self.buyers = []
			// Increment the ID so that it isn't used again
			PackDropper.currentPackId = PackDropper.currentPackId + 1 as UInt32
		}
	}
	
	// PackPurchaser
	// An interface to allow purchasing packs
	access(all)
	resource interface PackPurchaser{ 
		access(all)
		fun buyPack(packId: UInt32, buyerPayment: @{FungibleToken.Vault}, buyerAddress: Address)
		
		access(all)
		fun getPackPrice(packId: UInt32): UFix64
		
		access(all)
		fun getPackBuyers(packId: UInt32): [Address]
	}
	
	// PacksInfo
	// An interface to allow checking information about packs in the account
	access(all)
	resource interface PacksInfo{ 
		access(all)
		fun getIDs(): [UInt32]
	}
	
	// PacksHandler
	// Resource that an admin would own to be able to handle packs
	access(all)
	resource PacksHandler: PackPurchaser, PacksInfo{ 
		access(self)
		var packStats:{ UInt32: PackData}
		
		access(all)
		fun addPack(name: String, size: Int, price: UFix64, availableFrom: UFix64){ 
			pre{ 
				name.length > 0:
					"Pack must have a name"
				size > 0:
					"Size must be positive number"
				price > 0.0:
					"Price must be greater than zero"
			}
			let pack = PackData(name: name, size: size, price: price, availableFrom: availableFrom)
			self.packStats[pack.id] = pack
			emit PackAdded(id: pack.id, name: name, size: size, price: price, availableFrom: availableFrom)
		}
		
		access(all)
		fun getIDs(): [UInt32]{ 
			return self.packStats.keys
		}
		
		access(all)
		fun getPackPrice(packId: UInt32): UFix64{ 
			pre{ 
				self.packStats[packId] != nil:
					"Pack must exist"
			}
			return (self.packStats[packId]!).price
		}
		
		access(all)
		fun getPackBuyers(packId: UInt32): [Address]{ 
			pre{ 
				self.packStats[packId] != nil:
					"Pack must exist"
			}
			return (self.packStats[packId]!).buyers
		}
		
		access(all)
		fun buyPack(packId: UInt32, buyerPayment: @{FungibleToken.Vault}, buyerAddress: Address){ 
			pre{ 
				self.packStats[packId] != nil:
					"Pack does not exist in the collection!"
				buyerPayment.balance == (self.packStats[packId]!).price:
					"payment does not equal the price of the pack"
				getCurrentBlock().timestamp > (self.packStats[packId]!).availableFromTimeStamp:
					"Pack selling not enabled yet!"
				(self.packStats[packId]!).buyers.length < (self.packStats[packId]!).size as Int:
					"All packs are bought"
				(self.owner!).capabilities.get<&FUSD.Vault>(/public/fusdReceiver).borrow() != nil:
					"FUSD receiver cant be nil"
			}
			let ownerReceiverVault = (self.owner!).capabilities.get<&FUSD.Vault>(/public/fusdReceiver).borrow()!
			ownerReceiverVault.deposit(from: <-buyerPayment)
			(self.packStats[packId]!).buyers.append(buyerAddress)
			emit PackBought(id: packId, address: buyerAddress, order: (self.packStats[packId]!).buyers.length)
		}
		
		init(){ 
			self.packStats ={} 
		}
	}
	
	init(){ 
		self.currentPackId = 1
		self.PacksHandlerStoragePath = /storage/packsHandler
		self.PacksHandlerPublicPath = /public/packsHandler
		self.PacksInfoPublicPath = /public/packsInfo
		let packsHandler <- create PacksHandler()
		self.account.storage.save(<-packsHandler, to: self.PacksHandlerStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&PackDropper.PacksHandler>(
				self.PacksHandlerStoragePath
			)
		self.account.capabilities.publish(capability_1, at: self.PacksHandlerPublicPath)
		var capability_2 =
			self.account.capabilities.storage.issue<&PackDropper.PacksHandler>(
				self.PacksHandlerStoragePath
			)
		self.account.capabilities.publish(capability_2, at: self.PacksInfoPublicPath)
		emit ContractInitialized()
	}
}
