import Gun from "./Gun.cdc"
pub contract James {
    pub var name: String

    pub init() {
        self.name = "my name is Bond.... James Bond..."
    }

    pub fun sayHi(): String {
        return self.name.concat(Gun.sayHi())
    }
}