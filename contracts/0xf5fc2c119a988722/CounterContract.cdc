pub contract CounterContract {

    pub let CounterStoragePath: StoragePath
    pub let CounterPublicPath: PublicPath
    pub event AddedCount(currentCount: UInt64)


    pub resource interface  HasCount {
        pub fun currentCount(): UInt64
    }

    pub resource Counter: HasCount {

        access(contract) var count: UInt64

        init() {
            self.count  = 0
        }

        pub fun plusOne(hash: String) {
            self.count = self.count + 1
        }

        pub fun currentCount(): UInt64 {
            return self.count
        }

    }


    pub fun currentCount(): UInt64 {
        let counter = self.account.getCapability<&{HasCount}>(self.CounterPublicPath)
        let counterRef = counter.borrow()!
        return counterRef.currentCount()
    }

    // initializer
    //
    init() {


        self.CounterStoragePath = /storage/testCounterPrivatePath
        self.CounterPublicPath = /public/testCounterPublicPath

        let counter <- create Counter()
        self.account.save(<-counter, to: self.CounterStoragePath)
        self.account.link<&{HasCount}>(self.CounterPublicPath, target: self.CounterStoragePath)
    }
}
 