import TheMasterPieceContract from "./TheMasterPieceContract.cdc"

access(all)
contract TheMasterPixelContract{ 
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/TheMasterSectors
		self.CollectionPublicPath = /public/TheMasterSectors
		self.CollectionPrivatePath = /private/TheMasterSectors
		self.MinterStoragePath = /storage/TheMasterPixelMinter
		if self.account.storage.borrow<&TheMasterPixelMinter>(from: self.MinterStoragePath) == nil
		&& self.account.storage.borrow<&TheMasterSectors>(from: self.CollectionStoragePath) == nil{ 
			self.account.storage.save(<-create TheMasterPixelMinter(), to: self.MinterStoragePath)
			self.account.storage.save(<-self.createEmptySectors(), to: self.CollectionStoragePath)
			var capability_1 =
				self.account.capabilities.storage.issue<&{TheMasterSectorsInterface}>(
					self.CollectionStoragePath
				)
			self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
			var capability_2 =
				self.account.capabilities.storage.issue<&TheMasterSectors>(
					self.CollectionStoragePath
				)
			self.account.capabilities.publish(capability_2, at: self.CollectionPrivatePath)
		}
	}
	
	// ########################################################################################
	access(all)
	resource TheMasterPixel{ 
		access(all)
		let id: UInt32
		
		init(id: UInt32){ 
			self.id = id
		}
	}
	
	access(all)
	resource TheMasterPixelMinter{ 
		init(){} 
		
		access(all)
		fun mintTheMasterPixel(
			theMasterSectorsRef: &TheMasterPixelContract.TheMasterSectors,
			pixels:{ 
				UInt32: UInt32
			},
			sector: UInt16
		){ 
			let sectorRef = theMasterSectorsRef.getSectorRef(sectorId: sector)
			for id in pixels.keys{ 
				sectorRef.deposit(id: id)
				sectorRef.setColor(id: id, color: pixels[id]!)
			}
			TheMasterPieceContract.setWalletSize(
				sectorId: sector,
				address: (self.owner!).address,
				size: UInt16(sectorRef.getIds().length + pixels.length)
			)
		}
	}
	
	// ########################################################################################
	access(all)
	resource TheMasterSector{ 
		access(self)
		var ownedNFTs: @{UInt32: TheMasterPixel}
		
		access(self)
		var colors:{ UInt32: UInt32}
		
		access(all)
		var id: UInt16
		
		init(sectorId: UInt16){ 
			self.id = sectorId
			self.ownedNFTs <-{} 
			self.colors ={} 
		}
		
		access(account)
		fun withdraw(id: UInt32): UInt32{ 
			return self.colors.remove(key: id)!
		}
		
		access(account)
		fun deposit(id: UInt32){ 
			self.colors[id] = 4294967295
		}
		
		access(all)
		fun getColor(id: UInt32): UInt32{ 
			return self.colors[id]!
		}
		
		access(all)
		fun getPixels():{ UInt32: UInt32}{ 
			return self.colors
		}
		
		access(all)
		fun setColor(id: UInt32, color: UInt32){ 
			if self.colors.containsKey(id){ 
				self.colors[id] = color
			}
		}
		
		access(account)
		fun setColors(colors:{ UInt32: UInt32}){ 
			self.colors = colors
			TheMasterPieceContract.setWalletSize(
				sectorId: self.id,
				address: (self.owner!).address,
				size: UInt16(colors.length)
			)
		}
		
		access(all)
		fun getIds(): [UInt32]{ 
			return self.colors.keys
		}
	}
	
	// ########################################################################################
	access(all)
	resource interface TheMasterSectorsInterface{ 
		access(all)
		fun getPixels(sectorId: UInt16):{ UInt32: UInt32}
		
		access(all)
		fun getIds(sectorId: UInt16): [UInt32]
		
		access(account)
		fun getSectorRef(sectorId: UInt16): &TheMasterSector
	}
	
	access(all)
	fun createEmptySectors(): @TheMasterSectors{ 
		return <-create TheMasterSectors()
	}
	
	access(all)
	resource TheMasterSectors: TheMasterSectorsInterface{ 
		access(self)
		var ownedSectors: @{UInt16: TheMasterSector}
		
		init(){ 
			self.ownedSectors <-{} 
		}
		
		access(account)
		fun getSectorRef(sectorId: UInt16): &TheMasterSector{ 
			if self.ownedSectors[sectorId] == nil{ 
				self.ownedSectors[sectorId] <-! create TheMasterSector(sectorId: sectorId)
			}
			return (&self.ownedSectors[sectorId] as &TheMasterSector?)!
		}
		
		access(all)
		fun getPixels(sectorId: UInt16):{ UInt32: UInt32}{ 
			if self.ownedSectors.containsKey(sectorId){ 
				return self.ownedSectors[sectorId]?.getPixels()!
			} else{ 
				return{} 
			}
		}
		
		access(all)
		fun setColors(sectorId: UInt16, colors:{ UInt32: UInt32}){ 
			self.getSectorRef(sectorId: sectorId).setColors(colors: colors)
		}
		
		access(all)
		fun setColor(sectorId: UInt16, id: UInt32, color: UInt32){ 
			if self.ownedSectors.containsKey(sectorId){ 
				self.ownedSectors[sectorId]?.setColor(id: id, color: color)!
			}
		}
		
		access(all)
		fun getIds(sectorId: UInt16): [UInt32]{ 
			if self.ownedSectors.containsKey(sectorId){ 
				return self.ownedSectors[sectorId]?.getIds()!
			} else{ 
				return []
			}
		}
	}
}
