access(all)
contract TraditionalTetrisPieces{ 
	
	// This map is a map of piece names to a map of rotations to a 4x4 matrix of 1s and 0s
	access(contract)
	let pieceMap:{ String:{ Int: [[Int]]}}
	
	access(all)
	fun getRandomPiece(): String{ 
		let rand = revertibleRandom<UInt64>()
		let length = self.pieceMap.keys.length
		let randPiece: Int = Int(rand % UInt64(length))
		let pieceName = self.pieceMap.keys[randPiece]!
		return pieceName
	}
	
	access(all)
	fun getNextShape(_ curShape: String): String{ 
		var i = 0
		while i < self.pieceMap.keys.length{ 
			if self.pieceMap.keys[i] == curShape{ 
				break
			}
			i = i + 1
		}
		let nextShapeIndex = (i + 1) % self.pieceMap.keys.length
		return self.pieceMap.keys[nextShapeIndex]!
	}
	
	access(all)
	fun getColorForShape(_ shape: String): String{ 
		if shape == "S"{ 
			return "#00ff00"
		}
		if shape == "L"{ 
			return "#ffa500"
		}
		if shape == "I"{ 
			return "#00ffff"
		}
		if shape == "O"{ 
			return "#ffff00"
		}
		if shape == "J"{ 
			return "#0000ff"
		}
		if shape == "T"{ 
			return "#800080"
		}
		if shape == "Z"{ 
			return "#ff0000"
		}
		return "#ff0000"
	}
	
	access(all)
	fun getPiece(_ name: String, _ rotation: Int): [[Int]]{ 
		return (self.pieceMap[name]!)[rotation]!
	}
	
	access(all)
	fun getPieces():{ String:{ Int: [[Int]]}}{ 
		return self.pieceMap
	}
	
	init(){ 
		self.pieceMap ={ 
				"Z":{
				
					0: [[0, 1, 1], [1, 1, 0]],
					1: [[1, 0], [1, 1], [0, 1]],
					2: [[0, 1, 1], [1, 1, 0]],
					3: [[1, 0], [1, 1], [0, 1]]
				},
				"I":{
				
					0: [[1, 1, 1, 1]],
					1: [[1], [1], [1], [1]],
					2: [[1, 1, 1, 1]],
					3: [[1], [1], [1], [1]]
				},
				"J":{
				
					0: [[1, 1, 1], [0, 0, 1]],
					1: [[0, 1], [0, 1], [1, 1]],
					2: [[1, 0, 0], [1, 1, 1]],
					3: [[1, 1], [1, 0], [1, 0]]
				},
				"O":{
				
					0: [[1, 1], [1, 1]],
					1: [[1, 1], [1, 1]],
					2: [[1, 1], [1, 1]],
					3: [[1, 1], [1, 1]]
				},
				"T":{
				
					0: [[1, 1, 1], [0, 1, 0]],
					1: [[0, 1], [1, 1], [0, 1]],
					2: [[0, 1, 0], [1, 1, 1]],
					3: [[1, 0], [1, 1], [1, 0]]
				},
				"S":{
				
					0: [[1, 1, 0], [0, 1, 1]],
					1: [[0, 1], [1, 1], [1, 0]],
					2: [[0, 1, 1], [1, 1, 0]],
					3: [[1, 0], [1, 1], [0, 1]]
				},
				"L":{
				
					0: [[0, 0, 1], [1, 1, 1]],
					1: [[1, 1], [0, 1], [0, 1]],
					2: [[1, 1, 1], [1, 0, 0]],
					3: [[1, 0], [1, 0], [1, 1]]
				}
			}
	}
}
