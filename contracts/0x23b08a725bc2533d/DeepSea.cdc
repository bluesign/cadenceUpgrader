pub contract DeepSea {

    pub resource Deep {
        pub var mystery: @AnyResource?

        init(_ depth: Int) {
            if depth > 1000 {
                self.mystery <- nil
            } else if depth == Int(revertibleRandom() % 400 + 100) {
                self.mystery <- create Coelacanth()
            } else {
                self.mystery <- create Deep(depth + 1)
            }
        }

        destroy() { destroy self.mystery }
    }

    pub resource Coelacanth {}

    pub fun dive(): @Deep {
        return <- create Deep(0)
    }
}
