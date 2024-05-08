pub contract MotoGPAdmin{

    pub fun getVersion(): String {
        return "1.0.1"
    }
    
    pub resource Admin {
        // createAdmin
        // only an admin can ever create
        // a new Admin resource
        //
        pub fun createAdmin(): @Admin {
            return <- create Admin()
        }
    }

    init() {
        self.account.save(<- create Admin(), to: /storage/motogpAdmin)
    }
}