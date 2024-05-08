import TheMasterPieceContract from "./TheMasterPieceContract.cdc"

import TheMasterPixelContract from "./TheMasterPixelContract.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract TheMasterMarketContract{ 
	access(all)
	event ForSale(sectorId: UInt16, ids: [UInt32], price: UFix64)
	
	access(all)
	event TokenPurchased(sectorId: UInt16, ids: [UInt32], price: UFix64)
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MarketStateStoragePath: StoragePath
	
	access(all)
	let MarketStatePublicPath: PublicPath
	
	access(all)
	fun createTheMasterMarket(
		sectorsRef: Capability<&TheMasterPixelContract.TheMasterSectors>
	): @TheMasterMarket{ 
		return <-create TheMasterMarket(sectorsRef: sectorsRef)
	}
	
	init(){ 
		
		// Set our named paths
		self.CollectionStoragePath = /storage/TheMasterMarket
		self.CollectionPublicPath = /public/TheMasterMarket
		self.MarketStateStoragePath = /storage/TheMasterMarketState
		self.MarketStatePublicPath = /public/TheMasterMarketState
		if self.account.storage.borrow<&TheMasterMarketState>(from: self.MarketStateStoragePath)
		== nil{ 
			self.account.storage.save(
				<-create TheMasterMarketState(),
				to: self.MarketStateStoragePath
			)
			var capability_1 =
				self.account.capabilities.storage.issue<&{TheMasterMarketStateInterface}>(
					self.MarketStateStoragePath
				)
			self.account.capabilities.publish(capability_1, at: self.MarketStatePublicPath)
		}
		if self.account.storage.borrow<&TheMasterMarket>(from: self.CollectionStoragePath) == nil{ 
			self.account.storage.save(<-self.createTheMasterMarket(sectorsRef: self.account.capabilities.get<&TheMasterPixelContract.TheMasterSectors>(TheMasterPixelContract.CollectionPrivatePath)!), to: self.CollectionStoragePath)
			var capability_2 = self.account.capabilities.storage.issue<&{TheMasterMarketInterface}>(self.CollectionStoragePath)
			self.account.capabilities.publish(capability_2, at: self.CollectionPublicPath)
		}
	}
	
	access(contract)
	view fun isOpened(ownerAddress: Address): Bool{ 
		let refMarketState =
			getAccount(self.account.address).capabilities.get<&{TheMasterMarketStateInterface}>(
				/public/TheMasterMarketState
			).borrow()!
		return refMarketState.isOpened() || self.account.address == ownerAddress
	}
	
	// ########################################################################################
	access(all)
	resource TheMasterMarketSector{ 
		access(self)
		var forSale: @{UInt32: TheMasterPixelContract.TheMasterPixel}
		
		access(self)
		var prices:{ UInt32: UFix64}
		
		access(all)
		var sectorId: UInt16
		
		access(account)
		let ownerVault: Capability<&{FungibleToken.Receiver}>
		
		access(account)
		let creatorVault: Capability<&{FungibleToken.Receiver}>
		
		access(account)
		let sectorsRef: Capability<&TheMasterPixelContract.TheMasterSectors>
		
		init(
			sectorId: UInt16,
			ownerVault: Capability<&{FungibleToken.Receiver}>,
			creatorVault: Capability<&{FungibleToken.Receiver}>,
			sectorsRef: Capability<&TheMasterPixelContract.TheMasterSectors>
		){ 
			self.sectorId = sectorId
			self.forSale <-{} 
			self.prices ={} 
			self.ownerVault = ownerVault
			self.creatorVault = creatorVault
			self.sectorsRef = sectorsRef
		}
		
		access(all)
		fun listForSale(tokenIDs: [UInt32], price: UFix64){ 
			pre{ 
				TheMasterMarketContract.isOpened(ownerAddress: (self.owner!).address):
					"The trade market is not opened yet."
			}
			let sectorsRef = self.sectorsRef.borrow()!
			let sectorRef = sectorsRef.getSectorRef(sectorId: self.sectorId)
			TheMasterPieceContract.setSaleSize(
				sectorId: self.sectorId,
				address: (self.owner!).address,
				size: UInt16(self.prices.length + tokenIDs.length)
			)
			TheMasterPieceContract.setWalletSize(
				sectorId: self.sectorId,
				address: (self.owner!).address,
				size: UInt16(sectorRef.getIds().length - tokenIDs.length)
			)
			for tokenID in tokenIDs{ 
				self.prices[tokenID] = price
				sectorRef.withdraw(id: tokenID)
			}
			emit ForSale(
				sectorId: self.sectorId,
				ids: tokenIDs,
				price: UFix64(tokenIDs.length) * price
			)
		}
		
		access(all)
		fun purchase(
			tokenIDs: [
				UInt32
			],
			recipient: &{TheMasterPixelContract.TheMasterSectorsInterface},
			vaultRef: &{FungibleToken.Provider}
		){ 
			var totalPrice: UFix64 = 0.0
			let sectorsRef = self.sectorsRef.borrow()!
			let sectorRef: &TheMasterPixelContract.TheMasterSector =
				sectorsRef.getSectorRef(sectorId: self.sectorId)
			let recipientSectorRef: &TheMasterPixelContract.TheMasterSector =
				recipient.getSectorRef(sectorId: self.sectorId)
			TheMasterPieceContract.setSaleSize(
				sectorId: self.sectorId,
				address: (self.owner!).address,
				size: UInt16(self.prices.length - tokenIDs.length)
			)
			TheMasterPieceContract.setWalletSize(
				sectorId: self.sectorId,
				address: (recipient.owner!).address,
				size: UInt16(recipientSectorRef.getIds().length + tokenIDs.length)
			)
			for tokenID in tokenIDs{ 
				recipientSectorRef.deposit(id: tokenID)
				totalPrice = totalPrice + self.prices.remove(key: tokenID)!
			}
			(self.creatorVault.borrow()!).deposit(
				from: <-vaultRef.withdraw(amount: totalPrice * 0.025)
			)
			(self.ownerVault.borrow()!).deposit(
				from: <-vaultRef.withdraw(amount: totalPrice * 0.975)
			)
			emit TokenPurchased(sectorId: self.sectorId, ids: tokenIDs, price: totalPrice)
		}
		
		access(all)
		fun cancelListForSale(tokenIDs: [UInt32]){ 
			let sectorsRef = self.sectorsRef.borrow()!
			let sectorRef: &TheMasterPixelContract.TheMasterSector =
				sectorsRef.getSectorRef(sectorId: self.sectorId)
			TheMasterPieceContract.setSaleSize(
				sectorId: self.sectorId,
				address: (self.owner!).address,
				size: UInt16(self.prices.length - tokenIDs.length)
			)
			TheMasterPieceContract.setWalletSize(
				sectorId: self.sectorId,
				address: (self.owner!).address,
				size: UInt16(sectorRef.getIds().length + tokenIDs.length)
			)
			for tokenID in tokenIDs{ 
				sectorRef.deposit(id: tokenID)
				self.prices.remove(key: tokenID)
			}
		}
		
		access(all)
		fun idPrice(tokenID: UInt32): UFix64?{ 
			return self.prices[tokenID]
		}
		
		access(all)
		fun getPrices():{ UInt32: UFix64}{ 
			return self.prices
		}
	}
	
	// ########################################################################################
	access(all)
	resource interface TheMasterMarketInterface{ 
		access(all)
		fun purchase(
			sectorId: UInt16,
			tokenIDs: [
				UInt32
			],
			recipient: &{TheMasterPixelContract.TheMasterSectorsInterface},
			vaultRef: &{FungibleToken.Provider}
		)
		
		access(all)
		fun getPrices(sectorId: UInt16):{ UInt32: UFix64}
	}
	
	access(all)
	resource TheMasterMarket: TheMasterMarketInterface{ 
		access(self)
		var saleSectors: @{UInt16: TheMasterMarketSector}
		
		access(account)
		let ownerVault: Capability<&{FungibleToken.Receiver}>
		
		access(account)
		let creatorVault: Capability<&{FungibleToken.Receiver}>
		
		access(account)
		let sectorsRef: Capability<&TheMasterPixelContract.TheMasterSectors>
		
		init(sectorsRef: Capability<&TheMasterPixelContract.TheMasterSectors>){ 
			self.saleSectors <-{} 
			self.ownerVault = getAccount(sectorsRef.address).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
			self.creatorVault = getAccount(TheMasterPieceContract.getAddress()).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
			self.sectorsRef = sectorsRef
		}
		
		access(all)
		fun listForSale(sectorId: UInt16, tokenIDs: [UInt32], price: UFix64){ 
			if self.saleSectors[sectorId] == nil{ 
				self.saleSectors[sectorId] <-! create TheMasterMarketSector(sectorId: sectorId, ownerVault: self.ownerVault, creatorVault: self.creatorVault, sectorsRef: self.sectorsRef)
			}
			((&self.saleSectors[sectorId] as &TheMasterMarketSector?)!).listForSale(tokenIDs: tokenIDs, price: price)
		}
		
		access(all)
		fun purchase(sectorId: UInt16, tokenIDs: [UInt32], recipient: &{TheMasterPixelContract.TheMasterSectorsInterface}, vaultRef: &{FungibleToken.Provider}){ 
			((&self.saleSectors[sectorId] as &TheMasterMarketSector?)!).purchase(tokenIDs: tokenIDs, recipient: recipient, vaultRef: vaultRef)
		}
		
		access(all)
		fun cancelListForSale(sectorId: UInt16, tokenIDs: [UInt32]){ 
			if self.saleSectors[sectorId] != nil{ 
				((&self.saleSectors[sectorId] as &TheMasterMarketSector?)!).cancelListForSale(tokenIDs: tokenIDs)
			}
		}
		
		access(all)
		fun getPrices(sectorId: UInt16):{ UInt32: UFix64}{ 
			if self.saleSectors.containsKey(sectorId){ 
				return ((&self.saleSectors[sectorId] as &TheMasterMarketSector?)!).getPrices()
			} else{ 
				return{} 
			}
		}
	}
	
	// ########################################################################################
	access(all)
	resource interface TheMasterMarketStateInterface{ 
		access(all)
		view fun isOpened(): Bool
	}
	
	access(all)
	resource TheMasterMarketState: TheMasterMarketStateInterface{ 
		access(all)
		var opened: Bool
		
		init(){ 
			self.opened = false
		}
		
		access(all)
		fun setOpened(state: Bool){ 
			self.opened = state
		}
		
		access(all)
		view fun isOpened(): Bool{ 
			return self.opened
		}
	}
}
