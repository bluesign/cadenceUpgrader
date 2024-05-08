import ExpToken from "./ExpToken.cdc"

pub contract GamingIntegration {
    //
    pub resource Player {        
        pub var Level: Int

        pub var Strength: UFix64
        pub var Agility: UFix64
        pub var Intelligence: UFix64

        pub var HP: UFix64
        pub var MP: UFix64
        
        access(self) let reservedAttrs: {String: AnyStruct}

        init() {
            self.Level = 1
            self.Strength = 1.0
            self.Agility = 1.0
            self.Intelligence = 1.0
            self.HP = 100.0
            self.MP = 10.0
            self.reservedAttrs = {}
        }

        pub fun levelUp(expVault: @ExpToken.Vault) {
            let expConsumed = self.getNextLevelExperienceCost(curLevel: self.Level)
            assert(expConsumed == expVault.balance, message: "Insufficient experience points or overflow")
            destroy expVault
            self.Level = self.Level + 1
            // TODO Implement a more meaningful allocation method for upgrading attributes.
            self.Strength = self.Strength + UFix64(unsafeRandom()%5)
            self.Agility = self.Agility + UFix64(unsafeRandom()%5)
            self.Intelligence = self.Intelligence + UFix64(unsafeRandom()%5)
            self.HP = self.HP + UFix64(unsafeRandom()%20)
            self.MP = self.MP + UFix64(unsafeRandom()%5)
        }

        pub fun getNextLevelExperienceCost(curLevel: Int): UFix64 {
            return UFix64(curLevel) * 100.0
        }
    }

    pub fun createNewPlayer(): @Player {
        return <-create Player()
    }
    
    init() {
    }
}