pub contract ConstantUpdate {

    pub event HardMaximum(value: UFix64)

    pub let hardMaximum: UFix64

    pub fun doSomethingUnrelated(): Bool {
        return true
    }

    pub fun broadcastHardMaximum() {
        emit HardMaximum(value: self.hardMaximum)
    }

    init() {
        self.hardMaximum = 100.0
    }
}
