pub contract HelloFlow {
    pub let greeting: String

    init() {
        self.greeting = "Hello, Flow! Love, G"
    }

    pub fun hello(): String {
        return self.greeting
    }
}
