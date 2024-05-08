import ShipOfTheseus from "./ShipOfTheseus.cdc"

access(all)
contract ShipOfTheseusWarehouse{ 
	access(all)
	event Withdraw(id: UInt64, uuid: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, uuid: UInt64, to: Address?)
	
	access(all)
	resource interface WarehousePublic{ 
		access(all)
		fun deposit(ship: @ShipOfTheseus.Ship)
		
		access(all)
		fun getUUIDs(): [UInt64]
		
		access(all)
		fun borrowShip(uuid: UInt64): &ShipOfTheseus.Ship?
	}
	
	access(all)
	resource Warehouse: WarehousePublic{ 
		access(all)
		var ships: @{UInt64: ShipOfTheseus.Ship}
		
		init(){ 
			self.ships <-{} 
		}
		
		access(all)
		fun withdraw(uuid: UInt64): @ShipOfTheseus.Ship{ 
			let ship <- self.ships.remove(key: uuid) ?? panic("Missing Ship")
			emit Withdraw(id: ship.id, uuid: ship.uuid, from: self.owner?.address)
			return <-ship
		}
		
		access(all)
		fun deposit(ship: @ShipOfTheseus.Ship){ 
			let id: UInt64 = ship.id
			let uuid: UInt64 = ship.uuid
			self.ships[uuid] <-! ship
			emit Deposit(id: id, uuid: uuid, to: self.owner?.address)
		}
		
		access(all)
		fun getUUIDs(): [UInt64]{ 
			return self.ships.keys
		}
		
		access(all)
		fun borrowShip(uuid: UInt64): &ShipOfTheseus.Ship?{ 
			return &self.ships[uuid] as &ShipOfTheseus.Ship?
		}
	}
	
	access(all)
	fun createWarehouse(): @Warehouse{ 
		return <-create Warehouse()
	}
	
	init(){ 
		self.account.storage.save(<-create Warehouse(), to: /storage/ShipOfTheseusWarehouse)
		var capability_1 =
			self.account.capabilities.storage.issue<&Warehouse>(/storage/ShipOfTheseusWarehouse)
		self.account.capabilities.publish(capability_1, at: /public/ShipOfTheseusWarehouse)
	}
}
