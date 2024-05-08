import ShipOfTheseus from "./ShipOfTheseus.cdc"

pub contract ShipOfTheseusWarehouse {
    pub event Withdraw(id: UInt64, uuid: UInt64, from: Address?)
    pub event Deposit(id: UInt64, uuid: UInt64, to: Address?)

    pub resource interface WarehousePublic {
        pub fun deposit(ship: @ShipOfTheseus.Ship)
        pub fun getUUIDs(): [UInt64]
        pub fun borrowShip(uuid: UInt64): &ShipOfTheseus.Ship?
    }

    pub resource Warehouse: WarehousePublic {
        pub var ships: @{UInt64: ShipOfTheseus.Ship}

        init () {
            self.ships <- {}
        }

        pub fun withdraw(uuid: UInt64): @ShipOfTheseus.Ship {
            let ship <- self.ships.remove(key: uuid) ?? panic("Missing Ship")
            emit Withdraw(id: ship.id, uuid: ship.uuid, from: self.owner?.address)
            return <- ship
        }

        pub fun deposit(ship: @ShipOfTheseus.Ship) {
            let id: UInt64 = ship.id
            let uuid: UInt64 = ship.uuid
            self.ships[uuid] <-! ship
            emit Deposit(id: id, uuid: uuid, to: self.owner?.address)
        }

        pub fun getUUIDs(): [UInt64] {
            return self.ships.keys
        }

        pub fun borrowShip(uuid: UInt64): &ShipOfTheseus.Ship? {
            return &self.ships[uuid] as &ShipOfTheseus.Ship?
        }

        destroy() {
            destroy self.ships
        }
    }

    pub fun createWarehouse(): @Warehouse {
        return <- create Warehouse()
    }

    init() {
        self.account.save(<- create Warehouse(), to: /storage/ShipOfTheseusWarehouse)
        self.account.link<&Warehouse{WarehousePublic}>(/public/ShipOfTheseusWarehouse, target: /storage/ShipOfTheseusWarehouse)
    }
}
