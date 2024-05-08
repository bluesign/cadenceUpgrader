import GameLevels from "./GameLevels.cdc"

access(all)
contract GameEngine{ 
	access(all)
	struct interface GameObject{ 
		access(all)
		var id: UInt64
		
		access(all)
		var type: String
		
		access(all)
		var doesTick: Bool
		
		access(all)
		var referencePoint: [Int]
		
		access(all)
		var relativePositions: [[Int]]
		
		access(all)
		fun toMap():{ String: String}
		
		access(all)
		fun fromMap(_ map:{ String: String})
		
		access(all)
		fun setReferencePoint(_ newReferencePoint: [Int]){ 
			self.referencePoint = newReferencePoint
		}
		
		access(all)
		fun tick(
			tickCount: UInt64,
			events: [
				PlayerEvent
			],
			level:{ Level},
			callbacks:{ 
				String: fun (AnyStruct?): AnyStruct?
			}
		)
	}
	
	access(all)
	struct GameObjectType{ 
		access(all)
		let type: Type
		
		access(all)
		let createType: fun ():{ GameObject}
		
		init(type: Type, createType: fun ():{ GameObject}){ 
			self.type = type
			self.createType = createType
		}
	}
	
	access(all)
	struct PlayerEvent{ 
		access(all)
		let type: String
		
		init(type: String){ 
			self.type = type
		}
	}
	
	access(all)
	struct GameTickInput{ 
		access(all)
		let tickCount: UInt64
		
		access(all)
		var objects: [{GameObject}?]
		
		access(all)
		let events: [PlayerEvent]
		
		access(all)
		let state:{ String: String}
		
		init(
			tickCount: UInt64,
			objects: [{
				GameObject}?
			],
			events: [
				PlayerEvent
			],
			state:{ 
				String: String
			}
		){ 
			self.tickCount = tickCount
			self.objects = objects
			self.events = events
			self.state = state
		}
	}
	
	access(all)
	struct GameTickOutput{ 
		access(all)
		let tickCount: UInt64
		
		access(all)
		var objects: [{String: String}]
		
		access(all)
		var gameboard:{ Int:{ Int:{ GameObject}?}}
		
		access(all)
		let state:{ String: String}
		
		init(
			tickCount: UInt64,
			objects: [{
				
					String: String
				}
			],
			gameboard:{ 
				Int:{ 
					Int:{ GameEngine.GameObject}?
				}
			},
			state:{ 
				String: String
			}
		){ 
			self.tickCount = tickCount
			self.objects = objects
			self.gameboard = gameboard
			self.state = state
		}
	}
	
	// ------------------------------------------
	// Begin GameBoard struct
	// ------------------------------------------
	access(all)
	struct GameBoard{ 
		access(all)
		var board:{ Int:{ Int:{ GameObject}?}}
		
		access(all)
		var width: Int
		
		access(all)
		var height: Int
		
		access(self)
		fun updateBoard(_ gameObject:{ GameObject}, _ isRemoval: Bool){ 
			let referencePoint: [Int] = gameObject.referencePoint
			var x = 0
			var xLen = gameObject.relativePositions.length
			while x < xLen{ 
				var y = 0
				var yLen = (gameObject.relativePositions[x]!).length
				while y < yLen{ 
					if (gameObject.relativePositions[x]!)[y]! == 0{ 
						y = y + 1
					} else{ 
						let curX = referencePoint[0]! + x
						let curY = referencePoint[1]! + y
						if self.board[curX] == nil{ 
							self.board[curX] ={} 
						}
						var column = self.board[curX]!
						if isRemoval{ 
							column[curY] = nil
						} else{ 
							column[curY] = gameObject
						}
						self.board[curX] = column
						y = y + 1
					}
				}
				x = x + 1
			}
		}
		
		// Add the given gameobject to the gameboard
		access(all)
		fun add(_ gameObject:{ GameObject}){ 
			self.updateBoard(gameObject, false)
		}
		
		// Remove this object from the gameboard
		access(all)
		fun remove(_ gameObject:{ GameObject}?){ 
			if gameObject != nil{ 
				self.updateBoard(gameObject!, true)
			}
		}
		
		access(all)
		fun getCollisionMap(_ gameObject:{ GameObject}): [[Int]]{ 
			var collisionMap: [[Int]] = []
			var x = 0
			let xLen = gameObject.relativePositions.length
			while x < xLen{ 
				var y = 0
				let yLen = (gameObject.relativePositions[x]!).length
				while y < yLen{ 
					if (gameObject.relativePositions[x]!)[y]! == 0{ 
						y = y + 1
					} else{ 
						let curX = gameObject.referencePoint[0]! + x
						let curY = gameObject.referencePoint[1]! + y
						if self.board[curX] != nil && (self.board[curX]!)[curY] != nil && ((self.board[curX]!)[curY]!)?.id != gameObject.id{ 
							collisionMap.append([curX, curY])
						}
						y = y + 1
					}
				}
				x = x + 1
			}
			return collisionMap
		}
		
		init(width: Int, height: Int){ 
			self.board ={} 
			self.width = 0
			self.height = 0
		}
	}
	
	// ------------------------------------------
	// Begin Level interface
	// ------------------------------------------
	access(all)
	struct interface Level{ 
		access(all)
		var gameboard: GameBoard
		
		access(all)
		var objects:{ UInt64:{ GameObject}}
		
		// State is data meant to be carried between ticks
		// as both input and output
		access(all)
		var state:{ String: String}
		
		// The tick rate is the number of ticks per second
		access(all)
		let tickRate: UInt64
		
		// Size of the 2d board for this level
		// and what is visible of the board on the screen
		access(all)
		let boardWidth: Int
		
		access(all)
		let boardHeight: Int
		
		// Extras is data that is not meant to be carried between ticks
		// and is only used as output from a tick to the client
		access(all)
		let extras:{ String: AnyStruct}
		
		access(all)
		fun createInitialGameObjects(): [{GameObject}?]
		
		access(all)
		fun parseGameObjectsFromMaps(_ map: [{String: String}]): [{GameObject}?]
		
		access(all)
		fun storeGameObjects(_ objects: [{GameObject}?]){ 
			for object in objects{ 
				if object != nil{ 
					self.objects[(object!).id] = object!
					self.gameboard.add(object!)
				}
			}
		}
		
		access(all)
		fun setState(_ state:{ String: String}){ 
			self.state = state
		}
		
		// Default implementation of tick is to tick on all contained
		// game objects that have doesTick set to true
		access(all)
		fun tick(tickCount: UInt64, events: [PlayerEvent])
		
		// Default implementation of postTick is to do nothing
		access(all)
		fun postTick(tickCount: UInt64, events: [PlayerEvent])
	}
	
	// ------------------------------------------
	// End Level interface
	// ------------------------------------------
	// ------------------------------------------
	//  Public game engine functions
	// ------------------------------------------
	access(all)
	fun convertGameObjectsToStrMaps(_ gameObjects:{ UInt64:{ GameEngine.GameObject}}): [{
		
			String: String
		}
	]{ 
		var maps: [{String: String}] = []
		var keys = gameObjects.keys
		for key in gameObjects.keys{ 
			var obj = gameObjects[key]!
			maps.append(obj.toMap())
		}
		return maps
	}
	
	access(all)
	fun startLevel(contractAddress: Address, contractName: String, levelName: String):{ Level}{ 
		let gameLevels: &{GameLevels} =
			getAccount(contractAddress).contracts.borrow<&{GameLevels}>(name: contractName)
			?? panic("Could not borrow a reference to the GameLevels contract")
		let level:{ Level} = gameLevels.createLevel(levelName)! as!{ Level}
		
		// Create the initial objects for the game. This will create a new list of game objects
		let objects: [{GameObject}?] = level.createInitialGameObjects()
		level.storeGameObjects(objects)
		return level
	}
	
	access(all)
	fun getLevel(contractAddress: Address, contractName: String, levelName: String):{ Level}{ 
		let gameLevels: &{GameLevels} =
			getAccount(contractAddress).contracts.borrow<&{GameLevels}>(name: contractName)
			?? panic("Could not borrow a reference to the GameLevels contract")
		let level:{ Level} = gameLevels.createLevel(levelName)! as!{ Level}
		return level
	}
	
	access(all)
	fun tickLevel(
		contractAddress: Address,
		contractName: String,
		levelName: String,
		input: GameTickInput
	):{ Level}{ 
		let gameLevels: &{GameLevels} =
			getAccount(contractAddress).contracts.borrow<&{GameLevels}>(name: contractName)
			?? panic("Could not borrow a reference to the GameLevels contract")
		let level:{ Level} = gameLevels.createLevel(levelName)! as!{ Level}
		
		// Setup the level with initial state from the input
		level.storeGameObjects(input.objects)
		level.setState(input.state)
		
		// Tick the level
		level.tick(tickCount: input.tickCount, events: input.events)
		level.postTick(tickCount: input.tickCount, events: input.events)
		return level
	}
}
