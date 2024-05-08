pub contract FirstFinalTouch {

    pub resource Dragon {
        pub(set) var eyes: [Bool; 2]?
        init() { self.eyes = nil }
    }

    pub var dragon: @[Dragon]

    init() { self.dragon <- [<- create Dragon()] }

    pub fun finalize() {
        var dragon <- self.dragon.removeFirst()
        dragon.eyes = [true, true]
        destroy dragon
    }
}
