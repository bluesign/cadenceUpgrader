import DigitalNativeArt from "../0xa19cf4dba5941530/DigitalNativeArt.cdc"

pub contract Atelier {

    pub enum Event: UInt8 {
        pub case creation
        pub case destruction
    }

    pub struct Record {
        pub let blockHeight: UInt64
        pub let timestamp: UFix64
        pub let event: Event
        pub let creations: UInt64
        pub let destructions: UInt64

        init(blockHeight: UInt64, timestamp: UFix64, event: Event, creations: UInt64, destructions: UInt64) {
            self.blockHeight = blockHeight
            self.timestamp = timestamp
            self.event = event
            self.creations = creations
            self.destructions = destructions
        }
    }

    pub var arts: @{UInt64: DigitalNativeArt.Art}
    pub var creations: UInt64
    pub var destructions: UInt64
    access(account) var records: [Record]

    pub fun createArt(): UInt64 {
        let art <- DigitalNativeArt.create()
        let uuid = art.uuid
        Atelier.arts[uuid] <-! art
        Atelier.creations = Atelier.creations + 1
        let block = getCurrentBlock()
        let record = Record(
            blockHeight: block.height,
            timestamp: block.timestamp,
            event: Event.creation,
            creations: self.creations,
            destructions: self.destructions
        )
        Atelier.records.insert(at: 0, record)
        return uuid
    }

    pub fun destroyArt(uuid: UInt64) {
        let art <- Atelier.arts.remove(key: uuid)!
        destroy art
        Atelier.destructions = Atelier.destructions + 1
        let block = getCurrentBlock()
        let record = Record(
            blockHeight: block.height,
            timestamp: block.timestamp,
            event: Event.destruction,
            creations: self.creations,
            destructions: self.destructions
        )
        Atelier.records.insert(at: 0, record)
    }

    pub fun withdrawArt(uuid: UInt64): @DigitalNativeArt.Art {
        return <- Atelier.arts.remove(key: uuid)!
    }

    pub fun getUUIDs(): [UInt64] {
        return Atelier.arts.keys
    }

    pub fun getRecords(from: Int, upTo: Int): [Record] {
        if from >= Atelier.records.length {
            return []
        }
        if upTo > Atelier.records.length {
            return Atelier.records.slice(from: from, upTo: Atelier.records.length)
        }
        return Atelier.records.slice(from: from, upTo: upTo)
    }

    init() {
        self.arts <- {}
        self.creations = 1
        self.destructions = 1
        self.records = []
    }
}
