pub contract YaoyorozunoKami {

    pub resource Kami {
        pub let name: String
        init (name: String) { self.name = name }
    }

    pub resource Creator {
        pub fun create(name: String): @Kami {
            return <- create Kami(name: name)
        }
    }

    init() {
        self.account.save(<- create Creator(), to: /storage/Creator)
        self.account.link<&Creator>(/public/Creator, target: /storage/Creator)
    }
}
