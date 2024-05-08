pub contract Waterfalls {

    pub resource Carp {}

    pub resource Dragon { init (_ carp: @Carp) { destroy carp } }

    pub resource Waterfall {
        pub let wall: UInt64
        init (_ wall: UInt64) { self.wall = wall }
        pub fun hatch (): @Carp { return <- create Carp() }
        pub fun climb (carp: @Carp): @Dragon? {
            if unsafeRandom() < self.wall { destroy carp; return nil }
            return <- create Dragon(<- carp)
        }
    }

    pub fun create (wall: UInt64): @Waterfall {
        return <- create Waterfall(wall)
    }
}
