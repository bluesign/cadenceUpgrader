 import HeroSurname from "./HeroSurname.cdc"
 pub contract Hero {
    pub var name: String

    pub init() {
        self.name = "My name is Bond...".concat(HeroSurname.surname)
    }

    pub fun sayName(): String {
        return self.name
    }
 }