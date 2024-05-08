pub contract Metabolism {

    pub resource Cell {

        pub var is_dead: Bool

        init() {
            self.is_dead = false
        }

        destroy() {
            assert(self.is_dead, message: "Not dead yet.")
        }

        pub fun kill(): @Cell {
            self.is_dead = true
            return <- create Cell()
        }
    }

    init() {
        self.account.save(<- create Cell(), to: /storage/MetabolismCell)
    }
}
