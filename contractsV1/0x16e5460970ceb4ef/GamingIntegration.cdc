import ExpToken from "./ExpToken.cdc"

access(all)
contract GamingIntegration{ 
	//
	access(all)
	resource Player{ 
		access(all)
		var Level: Int
		
		access(all)
		var Strength: UFix64
		
		access(all)
		var Agility: UFix64
		
		access(all)
		var Intelligence: UFix64
		
		access(all)
		var HP: UFix64
		
		access(all)
		var MP: UFix64
		
		access(self)
		let reservedAttrs:{ String: AnyStruct}
		
		init(){ 
			self.Level = 1
			self.Strength = 1.0
			self.Agility = 1.0
			self.Intelligence = 1.0
			self.HP = 100.0
			self.MP = 10.0
			self.reservedAttrs ={} 
		}
		
		access(all)
		fun levelUp(expVault: @ExpToken.Vault){ 
			let expConsumed = self.getNextLevelExperienceCost(curLevel: self.Level)
			assert(
				expConsumed == expVault.balance,
				message: "Insufficient experience points or overflow"
			)
			destroy expVault
			self.Level = self.Level + 1
			// TODO Implement a more meaningful allocation method for upgrading attributes.
			self.Strength = self.Strength + UFix64(revertibleRandom<UInt64>() % 5)
			self.Agility = self.Agility + UFix64(revertibleRandom<UInt64>() % 5)
			self.Intelligence = self.Intelligence + UFix64(revertibleRandom<UInt64>() % 5)
			self.HP = self.HP + UFix64(revertibleRandom<UInt64>() % 20)
			self.MP = self.MP + UFix64(revertibleRandom<UInt64>() % 5)
		}
		
		access(all)
		fun getNextLevelExperienceCost(curLevel: Int): UFix64{ 
			return UFix64(curLevel) * 100.0
		}
	}
	
	access(all)
	fun createNewPlayer(): @Player{ 
		return <-create Player()
	}
	
	init(){} 
}
