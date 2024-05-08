pub contract Purification {

    pub struct Desire {}

    pub resource Human {
        access(contract) var desires: [Desire]
        init () { self.desires = [] }
        pub fun live () { self.desires.append(Desire()) }
        access(contract) fun purified () { self.desires.removeFirst() }
    }

    pub fun purify(human: &Human) {
        while human.desires.length > 0 {
            human.purified()
        }
    }

    pub fun birth(): @Human {
        return <- create Human()
    }
}
