pub contract ValueDapp {

    pub var value: UFix64

    init() {
        self.value = UFix64(0)
    }

    pub fun setValue(_ value: UFix64) {
        self.value = value
    }

}