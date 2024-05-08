pub contract EffectiveLifeTime {

    pub let timeBorn: UFix64
    pub var timeLived: UFix64

    pub event Beat(actualLifeTime: UFix64, effectiveLifeTime: UFix64)

    init() {
        self.timeBorn = getCurrentBlock().timestamp
        self.timeLived = 0.0
    }

    pub fun beat() {
        let block = getCurrentBlock()
        let prevBlock = getBlock(at: block.height - 1)!
        self.timeLived = self.timeLived + (block.timestamp - prevBlock.timestamp)

        emit Beat(
            actualLifeTime: block.timestamp - self.timeBorn,
            effectiveLifeTime: self.timeLived
        )
    }
}
