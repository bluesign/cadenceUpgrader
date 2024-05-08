// ゆく河の流れは絶えずして、しかも、もとの水にあらず。淀みに浮かぶうたかたはかつ消えかつ結びて、久しくとどまりたるためしなし。
// 世の中にある人と栖とまたかくのごとし。
//
// Of the flowing river the flood ever changeth, on the still pool the foam gathering, vanishing, stayeth not.
// Such too is the lot of men and of the dwellings of men in this world of ours.

pub contract ShipOfTheseus {
    pub var theShip: @[Ship]

    pub struct Memory {
        pub let timestamp: UFix64
        pub let event: String
        pub let executor: Address

        init(timestamp: UFix64, event: String, executor: Address) {
            self.timestamp = timestamp
            self.event = event
            self.executor = executor
        }
    }

    pub resource Ship {
        pub let id: UInt64
        access(account) var memories: [Memory]

        init(id: UInt64, memories: [Memory], executor: Address) {
            self.id = id
            self.memories = memories
            self.memories.insert(at: 0, Memory(timestamp: getCurrentBlock().timestamp, event: "init", executor: executor))
        }

        pub fun touch(executor: &AuthAccount) {
            self.memories.insert(at: 0, Memory(timestamp: getCurrentBlock().timestamp, event: "touch", executor: executor.address))
        }

        pub fun getMemories(): [Memory] {
            return self.memories
        }
    }

    pub fun touch(executor: &AuthAccount) {
        let ship = &self.theShip[0] as &Ship
        ship.touch(executor: executor)
    }

    pub fun renew(executor: &AuthAccount): @Ship {
        // Here, the ship is replaced by a new resource object, with the same ID and memories, but a different UUID.
        let ship <- self.theShip.removeFirst()!
        self.theShip.append(<- create Ship(id: ship.id, memories: ship.getMemories(), executor: executor.address))
        return <- ship
    }

    init() {
        self.theShip <- [<- create Ship(id: 0, memories: [], executor: self.account.address)]
    }
}
