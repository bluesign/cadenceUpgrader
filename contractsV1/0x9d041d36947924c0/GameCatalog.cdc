access(all)
contract GameCatalog{ 
	access(all)
	struct Game{ 
		access(all)
		let levelType: Type
		
		access(all)
		let gameEngineType: Type
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let image: String
		
		init(
			levelType: Type,
			gameEngineType: Type,
			name: String,
			description: String,
			image: String
		){ 
			self.levelType = levelType
			self.gameEngineType = gameEngineType
			self.name = ""
			self.description = ""
			self.image = ""
		}
	}
	
	access(all)
	let games: [Game]
	
	access(all)
	fun addGame(game: Game){ 
		self.games.append(game)
	}
	
	init(){ 
		self.games = []
	}
}
