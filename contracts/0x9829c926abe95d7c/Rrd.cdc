pub contract Rrd {
    pub resource interface RR {
        pub fun h(_ n: UInt256): Bool        
    }
    pub resource R: RR {
        access(self) var r: {UInt256: Bool}
        pub fun s(_ n: UInt256) {
            assert(!self.r.containsKey(n), message: "e")
            self.r[n] = true
        }
        pub fun c() {
            self.r = {}
        }
        pub fun h(_ n: UInt256): Bool {
            return self.r.containsKey(n)
        }
        pub fun size(): Int {
            return self.r.keys.length
        }
        init() {
            self.r = {}
        }
    }
    pub fun mint(): @R {
        return <-create R()
    }
    init() {
    }
}