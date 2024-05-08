pub contract Deities {

    // Deity can be defined, but it cannot be instantiated.

    pub resource Deity {
        pub(set) var name: String
        pub(set) var gender: String?
        pub(set) var ability: String?
        pub(set) var purpose: String?

        init(name: String, gender: String?, ability: String?, purpose: String?) {
            self.name = name
            self.gender = gender
            self.ability = ability
            self.purpose = purpose
        }
    }
}
