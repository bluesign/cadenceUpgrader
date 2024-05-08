access(all) contract EventEmitter {
    pub event StringEvent(_ value: String)
    pub event AddressEvent(_ value: Address)

    pub fun EmitString(_ value: String) {
        emit StringEvent(value)
    }

    pub fun EmitAddress(_ value: Address) {
        emit AddressEvent(value)
    }

    init() {}
}