access(all)
contract GomokuType{ 
	access(all)
	enum VerifyDirection: UInt8{ 
		access(all)
		case vertical
		
		access(all)
		case horizontal
		
		access(all)
		case diagonal // "/"
		
		
		access(all)
		case reversedDiagonal // "\"
	
	}
	
	access(all)
	enum Role: UInt8{ 
		access(all)
		case host
		
		access(all)
		case challenger
	}
	
	access(all)
	enum StoneColor: UInt8{ 
		// block stone go first
		access(all)
		case black
		
		access(all)
		case white
	}
	
	access(all)
	enum Result: UInt8{ 
		access(all)
		case hostWins
		
		access(all)
		case challengerWins
		
		access(all)
		case draw
	}
	
	access(all)
	resource interface Stoning{ 
		access(all)
		let color: StoneColor
		
		access(all)
		let location: StoneLocation
		
		access(all)
		fun key(): String
		
		access(all)
		fun convertToData():{ GomokuType.StoneDataing}
	}
	
	access(all)
	struct interface StoneDataing{ 
		access(all)
		let color: StoneColor
		
		access(all)
		let location: StoneLocation
		
		access(all)
		init(color: StoneColor, location: StoneLocation)
	}
	
	access(all)
	struct StoneLocation{ 
		access(all)
		let x: Int8
		
		access(all)
		let y: Int8
		
		access(all)
		init(x: Int8, y: Int8){ 
			self.x = x
			self.y = y
		}
		
		access(all)
		fun key(): String{ 
			return self.x.toString().concat(",").concat(self.y.toString())
		}
		
		access(all)
		fun description(): String{ 
			return "x: ".concat(self.x.toString()).concat(", y: ").concat(self.y.toString())
		}
	}
}
