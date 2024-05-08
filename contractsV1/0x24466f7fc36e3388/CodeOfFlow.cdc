import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

/*
  [Note.]
  This CodeOfFlow contract is the game logic contract for the game, Code Of Flow.
  And Code Of Flow is absolutely paying homage to the SEGA's arcade game, Code Of Joker.
  The idea of game which Code Of Flow is using is belonging to SEGA.
  This smart contract has been created for the Flow Hackathon 1st and Flow Hackathon season 2.
  So let's enjoy the game Code Of Flow and wait the revival of Code Of Joker which runs on the Flow!
 */

access(all)
contract CodeOfFlow{ 
	
	// Events
	access(all)
	event PlayerRegistered(player_id: UInt)
	
	access(all)
	event BattleSequence(sequence: UInt8, player_id: UInt, opponent: UInt)
	
	access(all)
	event GameStart(first: UInt, second: UInt)
	
	access(all)
	event GameResult(first: UInt, second: UInt, winner: UInt)
	
	// Paths
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let PlayerStoragePath: StoragePath
	
	access(all)
	let PlayerPublicPath: PublicPath
	
	// Variants
	access(self)
	var totalPlayers: UInt
	
	access(self)
	var rankingBattleCount: UInt
	
	access(self)
	var ranking1stWinningPlayerId: UInt
	
	access(self)
	var ranking2ndWinningPlayerId: UInt
	
	access(self)
	var ranking3rdWinningPlayerId: UInt
	
	access(all)
	let FlowTokenVault: Capability<&FlowToken.Vault>
	
	access(all)
	let PlayerFlowTokenVault:{ UInt: Capability<&FlowToken.Vault>}
	
	access(all)
	let rankingPeriod: UInt
	
	// Objects
	access(self)
	let cardInfo:{ UInt16: CardStruct}
	
	access(self)
	let battleInfo:{ UInt: BattleStruct}
	
	access(self)
	var matchingLimits: [UFix64]
	
	access(self)
	var matchingPlayers: [UInt]
	
	access(self)
	let playerList:{ UInt: CyberScoreStruct}
	
	access(self)
	let playerDeck:{ UInt: [UInt16]}
	
	access(all)
	let starterDeck: [UInt16]
	
	access(self)
	let playerMatchingInfo:{ UInt: PlayerMatchingStruct}
	
	// [Struct] CardStruct
	access(all)
	struct CardStruct{ 
		access(all)
		let card_id: UInt16
		
		access(all)
		let name: String
		
		access(all)
		let bp: UInt
		
		access(all)
		let cost: UInt8
		
		access(all)
		let type: UInt8
		
		access(all)
		let category: UInt8
		
		access(all)
		let skill: Skill
		
		init(
			card_id: UInt16,
			name: String,
			bp: UInt,
			cost: UInt8,
			type: UInt8,
			category: UInt8,
			skill: Skill
		){ 
			self.card_id = card_id
			self.name = name
			self.bp = bp
			self.cost = cost
			self.type = type
			self.category = category
			self.skill = skill
		}
	}
	
	// [Struct] Skill
	access(all)
	struct Skill{ 
		access(all)
		let description: String
		
		access(all)
		let trigger_1: UInt8
		
		access(all)
		let trigger_2: UInt8
		
		access(all)
		let trigger_3: UInt8
		
		access(all)
		let trigger_4: UInt8
		
		access(all)
		let ask_1: UInt8
		
		access(all)
		let ask_2: UInt8
		
		access(all)
		let ask_3: UInt8
		
		access(all)
		let ask_4: UInt8
		
		access(all)
		let type_1: UInt8
		
		access(all)
		let type_2: UInt8
		
		access(all)
		let type_3: UInt8
		
		access(all)
		let type_4: UInt8
		
		access(all)
		let amount_1: UInt
		
		access(all)
		let amount_2: UInt
		
		access(all)
		let amount_3: UInt
		
		access(all)
		let amount_4: UInt
		
		access(all)
		let nestedSkill_1: Skill?
		
		access(all)
		let nestedSkill_2: Skill?
		
		access(all)
		let nestedSkill_3: Skill?
		
		access(all)
		let nestedSkill_4: Skill?
		
		init(
			description: String,
			triggers: [
				UInt8
			],
			asks: [
				UInt8
			],
			types: [
				UInt8
			],
			amounts: [
				UInt
			],
			skills: [
				Skill
			]
		){ 
			self.description = description
			self.trigger_1 = triggers[0]
			self.ask_1 = asks[0]
			self.type_1 = types[0]
			self.amount_1 = amounts[0]
			if triggers.length >= 2{ 
				self.trigger_2 = triggers[1]
				self.ask_2 = asks[1]
				self.type_2 = types[1]
				self.amount_2 = amounts[1]
			} else{ 
				self.trigger_2 = 0
				self.ask_2 = 0
				self.type_2 = 0
				self.amount_2 = 0
			}
			if triggers.length >= 3{ 
				self.trigger_3 = triggers[2]
				self.ask_3 = asks[2]
				self.type_3 = types[2]
				self.amount_3 = amounts[2]
			} else{ 
				self.trigger_3 = 0
				self.ask_3 = 0
				self.type_3 = 0
				self.amount_3 = 0
			}
			if triggers.length >= 4{ 
				self.trigger_4 = triggers[3]
				self.ask_4 = asks[3]
				self.type_4 = types[3]
				self.amount_4 = amounts[3]
			} else{ 
				self.trigger_4 = 0
				self.ask_4 = 0
				self.type_4 = 0
				self.amount_4 = 0
			}
			if skills.length >= 1{ 
				self.nestedSkill_1 = skills[0]
			} else{ 
				self.nestedSkill_1 = nil
			}
			self.nestedSkill_2 = nil
			self.nestedSkill_3 = nil
			self.nestedSkill_4 = nil
		}
	}
	
	// [Struct] BattleStruct
	access(all)
	struct BattleStruct{ 
		access(all)
		var turn: UInt8
		
		access(all)
		var is_first_turn: Bool
		
		access(all)
		let is_first: Bool
		
		access(all)
		let opponent: UInt
		
		access(all)
		let matched_time: UFix64
		
		access(all)
		var game_started: Bool
		
		access(all)
		var last_time_turnend: UFix64?
		
		access(all)
		var opponent_life: UInt8
		
		access(all)
		var opponent_cp: UInt8
		
		access(all)
		var opponent_field_unit:{ UInt8: UInt16}
		
		access(all)
		var opponent_field_unit_action:{ UInt8: UInt8}
		
		access(all)
		var opponent_field_unit_bp_amount_of_change:{ UInt8: Int}
		
		access(all)
		var opponent_trigger_cards: Int
		
		access(all)
		var opponent_remain_deck: Int
		
		access(all)
		var opponent_hand: Int
		
		access(all)
		var opponent_dead_count: Int
		
		access(all)
		var your_life: UInt8
		
		access(all)
		var your_cp: UInt8
		
		access(all)
		var your_field_unit:{ UInt8: UInt16}
		
		access(all)
		var your_field_unit_action:{ UInt8: UInt8}
		
		access(all)
		var your_field_unit_bp_amount_of_change:{ UInt8: Int}
		
		access(all)
		var your_trigger_cards:{ UInt8: UInt16}
		
		access(all)
		var your_remain_deck: [UInt16]
		
		access(all)
		var your_hand:{ UInt8: UInt16}
		
		access(all)
		var your_dead_count: Int
		
		access(all)
		var your_attacking_card: AttackStruct?
		
		access(all)
		var enemy_attacking_card: AttackStruct?
		
		access(all)
		var newly_drawed_cards: [UInt16]
		
		init(is_first: Bool, opponent: UInt, matched_time: UFix64){ 
			self.turn = 1
			self.is_first_turn = true
			self.is_first = is_first
			self.opponent = opponent
			self.matched_time = matched_time
			self.game_started = false
			self.last_time_turnend = nil
			self.opponent_life = 7
			self.opponent_cp = 2
			self.opponent_field_unit ={} 
			self.opponent_field_unit_action ={} 
			self.opponent_field_unit_bp_amount_of_change ={} 
			self.opponent_trigger_cards = 0
			self.opponent_remain_deck = 30
			self.opponent_hand = 0
			self.opponent_dead_count = 0
			self.your_life = 7
			self.your_cp = 2
			self.your_field_unit ={} 
			self.your_field_unit_action ={} 
			self.your_field_unit_bp_amount_of_change ={} 
			self.your_trigger_cards ={} 
			self.your_remain_deck = []
			self.your_hand ={} 
			self.your_dead_count = 0
			self.your_attacking_card = nil
			self.enemy_attacking_card = nil
			self.newly_drawed_cards = []
		}
	}
	
	// [Struct] AttackStruct
	access(all)
	struct AttackStruct{ 
		access(all)
		let card_id: UInt16
		
		access(all)
		let position: UInt8
		
		access(all)
		let bp: UInt
		
		access(all)
		let pump: UInt
		
		access(all)
		let used_trigger_cards: [UInt16]
		
		access(all)
		let attacked_time: UFix64
		
		init(
			card_id: UInt16,
			position: UInt8,
			bp: UInt,
			pump: UInt,
			used_trigger_cards: [
				UInt16
			],
			attacked_time: UFix64
		){ 
			self.card_id = card_id
			self.position = position
			self.bp = bp
			self.pump = pump
			self.used_trigger_cards = used_trigger_cards
			self.attacked_time = attacked_time
		}
	}
	
	// [Struct] CyberScoreStruct
	access(all)
	struct CyberScoreStruct{ 
		access(all)
		let player_name: String
		
		access(all)
		var score: [{UFix64: UInt8}]
		
		access(all)
		var win_count: UInt
		
		access(all)
		var loss_count: UInt
		
		access(all)
		var ranking_win_count: UInt
		
		access(all)
		var ranking_2nd_win_count: UInt
		
		access(all)
		var period_win_count: UInt
		
		access(all)
		var period_loss_count: UInt
		
		access(all)
		var cyber_energy: UInt8
		
		access(all)
		var balance: UFix64
		
		init(player_name: String){ 
			self.player_name = player_name
			self.score = []
			self.win_count = 0
			self.loss_count = 0
			self.ranking_win_count = 0
			self.ranking_2nd_win_count = 0
			self.period_win_count = 0
			self.period_loss_count = 0
			self.cyber_energy = 0
			self.balance = 0.0
		}
	}
	
	// [Struct] PlayerMatchingStruct
	access(all)
	struct PlayerMatchingStruct{ 
		access(all)
		var lastTimeMatching: UFix64?
		
		access(all)
		var marigan_cards: [[UInt8]]
		
		init(){ 
			self.lastTimeMatching = nil
			self.marigan_cards = []
		}
	}
	
	// [Struct] RankScoreStruct
	access(all)
	struct RankScoreStruct{ 
		access(all)
		let player_name: String
		
		access(all)
		var score: [{UFix64: UInt8}]
		
		access(all)
		var win_count: UInt
		
		access(all)
		var loss_count: UInt
		
		access(all)
		var ranking_win_count: UInt
		
		access(all)
		var ranking_2nd_win_count: UInt
		
		access(all)
		var period_win_count: UInt
		
		access(all)
		var period_loss_count: UInt
		
		access(all)
		var point: UInt
		
		init(
			player_name: String,
			score: [{
				
					UFix64: UInt8
				}
			],
			win_count: UInt,
			loss_count: UInt,
			ranking_win_count: UInt,
			ranking_2nd_win_count: UInt,
			period_win_count: UInt,
			period_loss_count: UInt,
			point: UInt
		){ 
			self.player_name = player_name
			self.score = score
			self.win_count = win_count
			self.loss_count = loss_count
			self.ranking_win_count = ranking_win_count
			self.ranking_2nd_win_count = ranking_2nd_win_count
			self.period_win_count = period_win_count
			self.period_loss_count = period_loss_count
			self.point = point
		}
	}
	
	/*
	  ** [Public methods]
	  */
	
	access(all)
	fun getCardInfo():{ UInt16: CardStruct}{ 
		return self.cardInfo
	}
	
	access(all)
	fun getMatchingLimits(): [UFix64]{ 
		return self.matchingLimits
	}
	
	access(all)
	fun getStarterDeck(): [UInt16]{ 
		return self.starterDeck
	}
	
	access(all)
	fun getRankingScores(): [RankScoreStruct]{ 
		let ret: [RankScoreStruct] = []
		for playerId in self.playerList.keys{ 
			if let score = self.playerList[playerId]{ 
				if score.win_count + score.loss_count > 0{ 
					ret.append(RankScoreStruct(player_name: score.player_name, score: score.score, win_count: score.win_count, loss_count: score.loss_count, ranking_win_count: score.ranking_win_count, ranking_2nd_win_count: score.ranking_2nd_win_count, period_win_count: score.period_win_count, period_loss_count: score.period_loss_count, point: self.calcPoint(win_count: score.period_win_count, loss_count: score.period_loss_count)))
				}
			}
		}
		return ret
	}
	
	access(all)
	fun getTotalScores(): [RankScoreStruct]{ 
		let ret: [RankScoreStruct] = []
		for playerId in self.playerList.keys{ 
			if let score = self.playerList[playerId]{ 
				if score.win_count + score.loss_count > 0{ 
					ret.append(RankScoreStruct(player_name: score.player_name, score: score.score, win_count: score.win_count, loss_count: score.loss_count, ranking_win_count: score.ranking_win_count, ranking_2nd_win_count: score.ranking_2nd_win_count, period_win_count: score.period_win_count, period_loss_count: score.period_loss_count, point: self.calcPoint(win_count: score.win_count, loss_count: score.loss_count)))
				}
			}
		}
		return ret
	}
	
	access(all)
	fun calcPoint(win_count: UInt, loss_count: UInt): UInt{ 
		if win_count + loss_count > 25{ 
			return UInt(UFix64(win_count) / UFix64(win_count + loss_count) * 100.0) + win_count
		} else if win_count + loss_count > 15{ 
			return UInt(UFix64(win_count) / UFix64(win_count + loss_count) * 50.0) + win_count
		} else if win_count + loss_count > 5{ 
			return UInt(UFix64(win_count) / UFix64(win_count + loss_count) * 25.0) + win_count
		} else{ 
			return UInt(UFix64(win_count) / UFix64(win_count + loss_count) * 12.0) + win_count
		}
	}
	
	access(all)
	fun getRewardRaceBattleCount(): UInt{ 
		return self.rankingBattleCount
	}
	
	access(all)
	fun getCurrentRunkingWinners(): [String]{ 
		var rank1stName = ""
		var rank2ndName = ""
		var rank3rdName = ""
		if let rank1stScore = self.playerList[self.ranking1stWinningPlayerId]{ 
			rank1stName = rank1stScore.player_name
		}
		if let rank2ndScore = self.playerList[self.ranking2ndWinningPlayerId]{ 
			rank2ndName = rank2ndScore.player_name
		}
		if let rank3rdScore = self.playerList[self.ranking3rdWinningPlayerId]{ 
			rank3rdName = rank3rdScore.player_name
		}
		return [rank1stName, rank2ndName, rank3rdName]
	}
	
	/*
	  ** [Resource] Admin (Game Server Processing)
	  */
	
	access(all)
	resource Admin{ 
		/*
			** Save the Player's Card Deck
			*/
		
		access(all)
		fun save_deck(player_id: UInt, user_deck: [UInt16]){ 
			if user_deck.length == 30{ 
				CodeOfFlow.playerDeck[player_id] = user_deck
			}
		}
		
		/*
			** Player Matching Transaction
			*/
		
		access(all)
		fun matching_start(player_id: UInt){ 
			pre{ 
				// preの中の条件に合わない場合はエラーメッセージが返ります。 ここでは"Still matching."。
				CodeOfFlow.playerMatchingInfo[player_id] == nil || (CodeOfFlow.playerMatchingInfo[player_id]!).lastTimeMatching == nil || (CodeOfFlow.playerMatchingInfo[player_id]!).lastTimeMatching! + 60.0 <= getCurrentBlock().timestamp:
					"Still matching."
			}
			var counter = 0
			var outdated = -1
			let current_time = getCurrentBlock().timestamp
			if let obj = CodeOfFlow.playerMatchingInfo[player_id]{ 
				obj.lastTimeMatching = current_time
				CodeOfFlow.playerMatchingInfo[player_id] = obj // save
			
			} else{ 
				let newObj = PlayerMatchingStruct()
				newObj.lastTimeMatching = current_time
				CodeOfFlow.playerMatchingInfo[player_id] = newObj
			}
			
			// Search where matching times are already past 60 seconds
			for time in CodeOfFlow.matchingLimits{ 
				if outdated == -1 && current_time > time + 60.0{ 
					outdated = counter
				}
				counter = counter + 1
			}
			
			// If there are some expired matching times
			if outdated > -1{ 
				// Save only valid matchin times
				if outdated == 0{ 
					CodeOfFlow.matchingLimits = []
					CodeOfFlow.matchingPlayers = []
				} else{ 
					CodeOfFlow.matchingLimits = CodeOfFlow.matchingLimits.slice(from: 0, upTo: outdated)
					CodeOfFlow.matchingPlayers = CodeOfFlow.matchingPlayers.slice(from: 0, upTo: outdated)
				}
			}
			if CodeOfFlow.matchingLimits.length >= 1{ 
				// Pick the opponent from still matching players.
				let time = CodeOfFlow.matchingLimits.removeLast()
				let opponent = CodeOfFlow.matchingPlayers.removeLast()
				var is_first = false
				// Decides which is first
				if CodeOfFlow.matchingLimits.length % 2 == 1{ 
					is_first = true
				}
				CodeOfFlow.playerMatchingInfo[player_id] = PlayerMatchingStruct() // マッチング成立したのでnilで初期化
				
				CodeOfFlow.battleInfo[player_id] = BattleStruct(is_first: is_first, opponent: opponent, matched_time: current_time)
				CodeOfFlow.battleInfo[opponent] = BattleStruct(is_first: !is_first, opponent: player_id, matched_time: current_time)
				
				// charge the play fee (料金徴収)
				if let cyberScore = CodeOfFlow.playerList[player_id]{ 
					cyberScore.cyber_energy = cyberScore.cyber_energy - 30
					CodeOfFlow.playerList[player_id] = cyberScore
				}
				
				// charge the play fee (料金徴収)
				if let cyberScore = CodeOfFlow.playerList[opponent]{ 
					cyberScore.cyber_energy = cyberScore.cyber_energy - 30
					CodeOfFlow.playerList[opponent] = cyberScore
				}
				emit BattleSequence(sequence: 1, player_id: player_id, opponent: opponent)
			} else{ 
				// Put player_id in the matching list.
				CodeOfFlow.matchingLimits.append(current_time)
				CodeOfFlow.matchingPlayers.append(player_id)
				emit BattleSequence(sequence: 0, player_id: player_id, opponent: 0)
			}
			
			// Creates Pseudorandom Numbe for the marigan cards
			let blockCreatedAt = getCurrentBlock().timestamp.toString().slice(from: 0, upTo: 10)
			let decodedArray = blockCreatedAt.decodeHex()
			let pseudorandomNumber1 = decodedArray[decodedArray.length - 1]
			let pseudorandomNumber2 = decodedArray[decodedArray.length - 2]
			let pseudorandomNumber3 = decodedArray[decodedArray.length - 3]
			let pseudorandomNumber4 = decodedArray[decodedArray.length - 4]
			let pseudorandomNumber5 = decodedArray[decodedArray.length - 5]
			let pseudorandomNumber6 = decodedArray[decodedArray.length - 1]
			let pseudorandomNumber7 = decodedArray[decodedArray.length - 2]
			let pseudorandomNumber8 = decodedArray[decodedArray.length - 3]
			let pseudorandomNumber9 = decodedArray[decodedArray.length - 4]
			let pseudorandomNumber10 = decodedArray[decodedArray.length - 5]
			let pseudorandomNumber11 = decodedArray[decodedArray.length - 1]
			let pseudorandomNumber12 = decodedArray[decodedArray.length - 2]
			let pseudorandomNumber13 = decodedArray[decodedArray.length - 3]
			let pseudorandomNumber14 = decodedArray[decodedArray.length - 4]
			let pseudorandomNumber15 = decodedArray[decodedArray.length - 5]
			let pseudorandomNumber16 = decodedArray[decodedArray.length - 1]
			let pseudorandomNumber17 = decodedArray[decodedArray.length - 2]
			let pseudorandomNumber18 = decodedArray[decodedArray.length - 3]
			let pseudorandomNumber19 = decodedArray[decodedArray.length - 4]
			let pseudorandomNumber20 = decodedArray[decodedArray.length - 5]
			let withdrawPosition1 = pseudorandomNumber1 % 30
			let withdrawPosition2 = pseudorandomNumber2 % 29
			let withdrawPosition3 = pseudorandomNumber3 % 28
			let withdrawPosition4 = pseudorandomNumber4 % 27
			let withdrawPosition5 = pseudorandomNumber5 % 30
			let withdrawPosition6 = pseudorandomNumber6 % 29
			let withdrawPosition7 = pseudorandomNumber7 % 28
			let withdrawPosition8 = pseudorandomNumber8 % 27
			let withdrawPosition9 = pseudorandomNumber9 % 30
			let withdrawPosition10 = pseudorandomNumber10 % 29
			let withdrawPosition11 = pseudorandomNumber11 % 28
			let withdrawPosition12 = pseudorandomNumber12 % 27
			let withdrawPosition13 = pseudorandomNumber13 % 30
			let withdrawPosition14 = pseudorandomNumber14 % 29
			let withdrawPosition15 = pseudorandomNumber15 % 28
			let withdrawPosition16 = pseudorandomNumber16 % 27
			let withdrawPosition17 = pseudorandomNumber17 % 30
			let withdrawPosition18 = pseudorandomNumber18 % 29
			let withdrawPosition19 = pseudorandomNumber19 % 28
			let withdrawPosition20 = pseudorandomNumber20 % 27
			if let playerMatchingInfo = CodeOfFlow.playerMatchingInfo[player_id]{ 
				playerMatchingInfo.marigan_cards = [[withdrawPosition1, withdrawPosition2, withdrawPosition3, withdrawPosition4], [withdrawPosition5, withdrawPosition6, withdrawPosition7, withdrawPosition8], [withdrawPosition9, withdrawPosition10, withdrawPosition11, withdrawPosition12], [withdrawPosition13, withdrawPosition14, withdrawPosition15, withdrawPosition16], [withdrawPosition17, withdrawPosition18, withdrawPosition19, withdrawPosition20]]
				CodeOfFlow.playerMatchingInfo[player_id] = playerMatchingInfo // save
			
			}
		}
		
		/* 
			** Game Start Transaction
			*/
		
		access(all)
		fun game_start(player_id: UInt, drawed_cards: [UInt16]){ 
			pre{ 
				drawed_cards.length == 4:
					"Invalid argument."
				CodeOfFlow.battleInfo[player_id] != nil && (CodeOfFlow.battleInfo[player_id]!).game_started == false:
					"Game already started."
			}
			var drawed_pos: [UInt8] = []
			if let playerMatchingInfo = CodeOfFlow.playerMatchingInfo[player_id]{ 
				if let deck = CodeOfFlow.playerDeck[player_id]{} 
				for arr in playerMatchingInfo.marigan_cards{ 
					if let deck = CodeOfFlow.playerDeck[player_id]{ 
						var arrCopy = deck.slice(from: 0, upTo: deck.length)
						let card_id1 = arrCopy.remove(at: arr[0])
						let card_id2 = arrCopy.remove(at: arr[1])
						let card_id3 = arrCopy.remove(at: arr[2])
						let card_id4 = arrCopy.remove(at: arr[3])
						if card_id1 == drawed_cards[0] && card_id2 == drawed_cards[1] && card_id3 == drawed_cards[2] && card_id4 == drawed_cards[3]{ 
							drawed_pos = arr
						}
					} else{ 
						var arrCopy = CodeOfFlow.starterDeck.slice(from: 0, upTo: CodeOfFlow.starterDeck.length)
						let card_id1 = arrCopy.remove(at: arr[0])
						let card_id2 = arrCopy.remove(at: arr[1])
						let card_id3 = arrCopy.remove(at: arr[2])
						let card_id4 = arrCopy.remove(at: arr[3])
						if card_id1 == drawed_cards[0] && card_id2 == drawed_cards[1] && card_id3 == drawed_cards[2] && card_id4 == drawed_cards[3]{ 
							drawed_pos = arr
						}
					}
				}
				if drawed_pos.length == 0{ 
					// Maybe the player did marigan more than 5 times. Set first cards to avoid errors.
					drawed_pos = playerMatchingInfo.marigan_cards[0]
				}
			}
			if let info = CodeOfFlow.battleInfo[player_id]{ 
				info.game_started = true
				if let deck = CodeOfFlow.playerDeck[player_id]{ 
					info.your_remain_deck = deck
				} else{ 
					info.your_remain_deck = CodeOfFlow.starterDeck
				}
				info.last_time_turnend = getCurrentBlock().timestamp
				// Set hand
				var key: UInt8 = 1
				for pos in drawed_pos{ 
					let card_id = info.your_remain_deck.remove(at: pos)
					info.your_hand[key] = card_id
					key = key + 1
				}
				if info.is_first == true{ 
					info.your_cp = 2
					emit GameStart(first: player_id, second: info.opponent)
				} else{ 
					info.your_cp = 3
					emit GameStart(first: info.opponent, second: player_id)
				}
				// Save
				CodeOfFlow.battleInfo[player_id] = info
				let opponent = info.opponent
				if let opponentInfo = CodeOfFlow.battleInfo[opponent]{ 
					// if opponentInfo.last_time_turnend != nil { // これだとハンドがセットされないのでコメントアウト.
					opponentInfo.last_time_turnend = info.last_time_turnend // set time same time
					
					// opponentInfo.game_started = true
					opponentInfo.opponent_remain_deck = info.your_remain_deck.length
					opponentInfo.opponent_hand = info.your_hand.keys.length
					opponentInfo.opponent_cp = info.your_cp
					// Save
					CodeOfFlow.battleInfo[opponent] = opponentInfo
					emit BattleSequence(sequence: 2, player_id: player_id, opponent: opponent)
				// }
				}
			}
		}
		
		access(all)
		fun put_card_on_the_field(
			player_id: UInt,
			unit_card:{ 
				UInt8: UInt16
			},
			enemy_skill_target: UInt8?,
			trigger_cards:{ 
				UInt8: UInt16?
			},
			used_intercept_positions: [
				UInt8
			]
		){ 
			for position in unit_card.keys{ 
				if (CodeOfFlow.battleInfo[player_id]!).your_field_unit[position] != nil{ 
					panic("You can't put unit in this position!")
				}
			}
			for position in trigger_cards.keys{ 
				if (CodeOfFlow.battleInfo[player_id]!).your_trigger_cards[position] != nil && (CodeOfFlow.battleInfo[player_id]!).your_trigger_cards[position] != trigger_cards[position]{ 
					panic("Your trigger card is Tampered!")
				}
			}
			var target: UInt8 = 0
			if enemy_skill_target != nil{ 
				target = enemy_skill_target!
			}
			var your_hand_count: Int = 0
			if let info = CodeOfFlow.battleInfo[player_id]{ 
				info.newly_drawed_cards = []
				
				// Match the consistency of the hand (take from the hand the amount moved to the trigger zone) (ハンドの整合性を合わせる(トリガーゾーンに移動した分、ハンドから取る))
				for trigger_position in trigger_cards.keys{ 
					var isRemoved = false
					if info.your_trigger_cards[trigger_position] != trigger_cards[trigger_position] && trigger_cards[trigger_position] != 0{ 
						let card_id = trigger_cards[trigger_position]
						info.your_trigger_cards[trigger_position] = card_id!
						for hand_position in info.your_hand.keys{ 
							if card_id == info.your_hand[hand_position] && isRemoved == false{ 
								info.your_hand[hand_position] = nil
								isRemoved = true
							}
						}
						if isRemoved == false{ 
							panic("You set the card on trigger zone which is not exist in your hand")
						}
					}
				}
				var lost_card_flg = false
				var speed_move_flg = false
				var signal_for_assault_flg = false
				// Process Card Skills
				for field_position in unit_card.keys{ // Usually this is only one card 
					
					let card_id: UInt16 = unit_card[field_position]!
					let unit = CodeOfFlow.cardInfo[card_id]!
					if unit.category != 0{ 
						panic("The card you put on the field is not a Unit Card!")
					}
					// [FIXED]When draw the card, it requires hand is less equal than 6, so hand removing process comes here.
					info.your_field_unit[field_position] = card_id
					info.your_cp = info.your_cp - unit.cost
					
					// Match the consistency of the hand (take from the hand the amount moved to the field)
					var isRemoved2 = false
					for hand_position in info.your_hand.keys{ 
						if card_id == info.your_hand[hand_position] && isRemoved2 == false{ 
							info.your_hand[hand_position] = nil
							isRemoved2 = true
						}
						if info.your_hand[hand_position] != nil{ 
							your_hand_count = your_hand_count + 1
						}
					}
					if isRemoved2 == false{ 
						panic("You set the card on the Field which is not exist in your hand")
					}
					//////////////////////////////////////////////////
					///////////////attribute evaluation///////////////
					//////////////////////////////////////////////////
					// trigger when the card is put on the field
					if unit.skill.trigger_1 == 1{ 
						//---- Damage ----
						if unit.skill.type_1 == 1{ 
							// Belial (Damage to all unit)
							if unit.skill.ask_1 == 3{ 
								for opponent_position in info.opponent_field_unit.keys{ 
									if let opponent_field_unit_bp_amount_of_change = info.opponent_field_unit_bp_amount_of_change[opponent_position]{ 
										info.opponent_field_unit_bp_amount_of_change[opponent_position] = opponent_field_unit_bp_amount_of_change + -1 * Int(unit.skill.amount_1)
									} else{ 
										info.opponent_field_unit_bp_amount_of_change[opponent_position] = -1 * Int(unit.skill.amount_1)
									}
									// assess is this damage enough to beat the unit.
									if let opponent = info.opponent_field_unit[opponent_position]{ 
										let card_id: UInt16 = info.opponent_field_unit[opponent_position]!
										let opponentUnit = CodeOfFlow.cardInfo[card_id]!
										if Int(opponentUnit.bp) <= info.opponent_field_unit_bp_amount_of_change[opponent_position]! * -1{ 
											// beat the opponent
											info.opponent_field_unit[opponent_position] = nil
											info.opponent_field_unit_action[opponent_position] = nil
											info.opponent_dead_count = info.opponent_dead_count + 1
										}
									}
								}
							// Lilim (Damage to one target unit)
							} else if unit.skill.ask_1 == 1{ 
								if target > 0{ 
									if info.opponent_field_unit[target] != nil && info.opponent_field_unit[target]! > 0{ 
										if let opponent_field_unit_bp_amount_of_change = info.opponent_field_unit_bp_amount_of_change[target]{ 
											info.opponent_field_unit_bp_amount_of_change[target] = opponent_field_unit_bp_amount_of_change + -1 * Int(unit.skill.amount_1)
										} else{ 
											info.opponent_field_unit_bp_amount_of_change[target] = -1 * Int(unit.skill.amount_1)
										}
										// assess is this damage enough to beat the unit.
										if let opponent = info.opponent_field_unit[target]{ 
											let card_id: UInt16 = info.opponent_field_unit[target]!
											let opponentUnit = CodeOfFlow.cardInfo[card_id]!
											if Int(opponentUnit.bp) <= info.opponent_field_unit_bp_amount_of_change[target]! * -1{ 
												// beat the opponent
												info.opponent_field_unit[target] = nil
												info.opponent_field_unit_bp_amount_of_change[target] = nil
												info.opponent_dead_count = info.opponent_dead_count + 1
											}
										}
									}
								}
							// Rairyu (Only target which has no action right)
							} else if unit.skill.ask_1 == 2{ 
								if target > 0{ 
									if info.opponent_field_unit[target] != nil && info.opponent_field_unit[target]! > 0{ 
										if info.opponent_field_unit_action[target] == 0{ // // 2: can attack, 1: can defence only, 0: nothing can do. 
											
											if let opponent_field_unit_bp_amount_of_change = info.opponent_field_unit_bp_amount_of_change[target]{ 
												info.opponent_field_unit_bp_amount_of_change[target] = opponent_field_unit_bp_amount_of_change + -1 * Int(unit.skill.amount_1)
											} else{ 
												info.opponent_field_unit_bp_amount_of_change[target] = -1 * Int(unit.skill.amount_1)
											}
										}
									}
								}
							}
							// assess is this damage enough to beat the unit.
							if let opponent = info.opponent_field_unit[target]{ 
								let card_id: UInt16 = info.opponent_field_unit[target]!
								let enemy = CodeOfFlow.cardInfo[card_id]!
								if Int(enemy.bp) <= info.opponent_field_unit_bp_amount_of_change[target]! * -1{ 
									// beat the opponent
									info.opponent_field_unit[target] = nil
									info.opponent_field_unit_bp_amount_of_change[target] = nil
									info.opponent_dead_count = info.opponent_dead_count + 1
								}
							}
						}
						//---- HellDog (Trigger lost) ----
						if unit.skill.type_1 == 3{ 
							lost_card_flg = true
						}
						//---- Allie (Remove action right) ----
						if unit.skill.type_1 == 5{ 
							if target > 0{ 
								if info.opponent_field_unit[target] != nil && info.opponent_field_unit[target]! != 0{ 
									info.opponent_field_unit_action[target] = 0 // // 2: can attack, 1: can defence only, 0: nothing can do.
								
								}
							}
						}
						//---- Caim (Draw card) ----
						if unit.skill.type_1 == 7{ 
							let blockCreatedAt = getCurrentBlock().timestamp.toString().slice(from: 0, upTo: 10)
							let decodedArray = blockCreatedAt.decodeHex()
							let pseudorandomNumber1 = Int(decodedArray[decodedArray.length - 1])
							let withdrawPosition1 = pseudorandomNumber1 % (info.your_remain_deck.length - 1)
							var isSetCard1 = false
							let handPositions: [UInt8] = [1, 2, 3, 4, 5, 6, 7]
							let nextPositions: [UInt8] = [1, 2, 3, 4, 5, 6]
							// カード位置を若い順に整列
							for hand_position in handPositions{ 
								var replaced: Bool = false
								if info.your_hand[hand_position] == nil{ 
									for next in nextPositions{ 
										if replaced == false && hand_position + next <= 7 && info.your_hand[hand_position + next] != nil{ 
											info.your_hand[hand_position] = info.your_hand[hand_position + next]
											info.your_hand[hand_position + next] = nil
											replaced = true
										}
									}
								}
							}
							for hand_position in handPositions{ 
								if info.your_hand[hand_position] == nil && isSetCard1 == false{ 
									var drawed_card = info.your_remain_deck.remove(at: withdrawPosition1)
									info.your_hand[hand_position] = drawed_card
									info.newly_drawed_cards.append(drawed_card)
									isSetCard1 = true
								}
							}
						}
						//---- Arty (Speed Move) ----
						if unit.skill.type_1 == 11{ 
							speed_move_flg = true
						}
					}
					if unit.skill.trigger_2 == 1{ // currently there is no card which has trigger_3 and trigger_4 
						
						if unit.skill.trigger_2 == 1{} 
					}
					// Used Trigger or Intercept Card
					for card_position in used_intercept_positions{ 
						if info.your_trigger_cards[card_position] != nil{ // To avoid transaction error which interrupt the game. 
							
							let trigger_card_id = info.your_trigger_cards[card_position]!
							let trigger = CodeOfFlow.cardInfo[trigger_card_id]!
							info.your_trigger_cards[card_position] = nil
							info.your_dead_count = info.your_dead_count + 1
							
							// trigger when the card is put on the field
							if trigger.skill.trigger_1 == 1{ 
								//---- Damage ----
								if trigger.skill.type_1 == 1{ 
									// RainyFlame (Damage to all unit on the field)
									if trigger.skill.ask_1 == 3{ 
										for opponent_position in info.opponent_field_unit.keys{ 
											if let opponent_field_unit_bp_amount_of_change = info.opponent_field_unit_bp_amount_of_change[opponent_position]{ 
												info.opponent_field_unit_bp_amount_of_change[opponent_position] = opponent_field_unit_bp_amount_of_change + -1 * Int(trigger.skill.amount_1)
											} else{ 
												info.opponent_field_unit_bp_amount_of_change[opponent_position] = -1 * Int(trigger.skill.amount_1)
											}
											// assess is this damage enough to beat the unit.
											if let opponent = info.opponent_field_unit[opponent_position]{ 
												let card_id: UInt16 = info.opponent_field_unit[opponent_position]!
												let opponentUnit = CodeOfFlow.cardInfo[card_id]!
												if Int(opponentUnit.bp) <= info.opponent_field_unit_bp_amount_of_change[opponent_position]! * -1{ 
													// beat the opponent
													info.opponent_field_unit[opponent_position] = nil
													info.opponent_field_unit_action[opponent_position] = nil
													info.opponent_dead_count = info.opponent_dead_count + 1
												}
											}
										}
										for your_position in info.your_field_unit.keys{ 
											if let your_field_unit_bp_amount_of_change = info.your_field_unit_bp_amount_of_change[your_position]{ 
												info.your_field_unit_bp_amount_of_change[your_position] = your_field_unit_bp_amount_of_change + -1 * Int(trigger.skill.amount_1)
											} else{ 
												info.your_field_unit_bp_amount_of_change[your_position] = -1 * Int(trigger.skill.amount_1)
											}
											// assess is this damage enough to beat the unit.
											if let unit = info.your_field_unit[your_position]{ 
												let card_id: UInt16 = info.your_field_unit[your_position]!
												let yourUnit = CodeOfFlow.cardInfo[card_id]!
												if Int(yourUnit.bp) <= info.your_field_unit_bp_amount_of_change[your_position]! * -1{ 
													// the unit is beaten
													info.your_field_unit[your_position] = nil
													info.your_field_unit_action[your_position] = nil
													info.your_dead_count = info.your_dead_count + 1
												}
											}
										}
									}
									// Damage Target
									if target > 0{ 
										if info.opponent_field_unit[target] != nil && info.opponent_field_unit[target]! > 0{ 
											// Damage to one target unit
											// Breaker
											if trigger.skill.ask_1 == 1{ 
												if let opponent_field_unit_bp_amount_of_change = info.opponent_field_unit_bp_amount_of_change[target]{ 
													info.opponent_field_unit_bp_amount_of_change[target] = opponent_field_unit_bp_amount_of_change + -1 * Int(trigger.skill.amount_1)
												} else{ 
													info.opponent_field_unit_bp_amount_of_change[target] = -1 * Int(trigger.skill.amount_1)
												}
												// assess is this damage enough to beat the unit.
												if let opponent = info.opponent_field_unit[target]{ 
													let card_id: UInt16 = info.opponent_field_unit[target]!
													let opponentUnit = CodeOfFlow.cardInfo[card_id]!
													if Int(opponentUnit.bp) <= info.opponent_field_unit_bp_amount_of_change[target]! * -1{ 
														// beat the opponent
														info.opponent_field_unit[target] = nil
														info.opponent_field_unit_bp_amount_of_change[target] = nil
														info.opponent_dead_count = info.opponent_dead_count + 1
													}
												}
											// Only target which has no action right
											// Photon
											} else if trigger.skill.ask_1 == 2{ 
												if info.opponent_field_unit_action[target] == 0{ // // 2: can attack, 1: can defence only, 0: nothing can do. 
													
													if let opponent_field_unit_bp_amount_of_change = info.opponent_field_unit_bp_amount_of_change[target]{ 
														info.opponent_field_unit_bp_amount_of_change[target] = opponent_field_unit_bp_amount_of_change + -1 * Int(trigger.skill.amount_1)
													} else{ 
														info.opponent_field_unit_bp_amount_of_change[target] = -1 * Int(trigger.skill.amount_1)
													}
												} else{ 
													// To avoid a something bug, damage any other target which match the condition.
													let unitPositions: [UInt8] = [1, 2, 3, 4, 5]
													for unit_position in unitPositions{ 
														if info.opponent_field_unit_action[unit_position] == 0{ 
															if let opponent_field_unit_bp_amount_of_change = info.opponent_field_unit_bp_amount_of_change[unit_position]{ 
																info.opponent_field_unit_bp_amount_of_change[unit_position] = opponent_field_unit_bp_amount_of_change + -1 * Int(trigger.skill.amount_1)
															} else{ 
																info.opponent_field_unit_bp_amount_of_change[unit_position] = -1 * Int(trigger.skill.amount_1)
															}
															target = unit_position
															break
														}
													}
												}
												// assess is this damage enough to beat the unit.
												if let opponent = info.opponent_field_unit[target]{ 
													let card_id: UInt16 = info.opponent_field_unit[target]!
													let opponentUnit = CodeOfFlow.cardInfo[card_id]!
													if Int(opponentUnit.bp) <= info.opponent_field_unit_bp_amount_of_change[target]! * -1{ 
														// beat the opponent
														info.opponent_field_unit[target] = nil
														info.opponent_field_unit_bp_amount_of_change[target] = nil
														info.opponent_dead_count = info.opponent_dead_count + 1
													}
												}
											}
										}
									}
								}
								//---- Merchant (Draw card) ----
								if trigger.skill.type_1 == 7{ 
									let blockCreatedAt = getCurrentBlock().timestamp.toString().slice(from: 0, upTo: 10)
									let decodedArray = blockCreatedAt.decodeHex()
									let pseudorandomNumber1 = Int(decodedArray[decodedArray.length - 1])
									let withdrawPosition1 = pseudorandomNumber1 % (info.your_remain_deck.length - 1)
									var isSetCard1 = false
									let handPositions: [UInt8] = [1, 2, 3, 4, 5, 6, 7]
									let nextPositions: [UInt8] = [1, 2, 3, 4, 5, 6]
									// カード位置を若い順に整列
									for hand_position in handPositions{ 
										var replaced: Bool = false
										if info.your_hand[hand_position] == nil{ 
											for next in nextPositions{ 
												if replaced == false && hand_position + next <= 7 && info.your_hand[hand_position + next] != nil{ 
													info.your_hand[hand_position] = info.your_hand[hand_position + next]
													info.your_hand[hand_position + next] = nil
													replaced = true
												}
											}
										}
									}
									for hand_position in handPositions{ 
										if info.your_hand[hand_position] == nil && isSetCard1 == false{ 
											var drawed_card = info.your_remain_deck.remove(at: withdrawPosition1)
											info.your_hand[hand_position] = drawed_card
											info.newly_drawed_cards.append(drawed_card)
											isSetCard1 = true
										}
									}
								}
								//---- Trigger lost ----
								if trigger.skill.type_1 == 3{ 
									lost_card_flg = true
								}
								//---- Speed Move ----
								if trigger.skill.type_1 == 11{ 
									// Signal for assault
									if trigger.skill.ask_1 == 3{ 
										signal_for_assault_flg = true
									// Imperiale
									} else{ 
										speed_move_flg = true
									}
								}
							}
						}
					}
					//////////////////////////////////////////////////
					///////////////↑↑attribute evaluation↑↑///////////
					//////////////////////////////////////////////////
					if speed_move_flg == true{ 
						info.your_field_unit_action[field_position] = 2 // 2: can attack, 1: can defence only, 0: nothing can do.
					
					} else{ 
						info.your_field_unit_action[field_position] = 1
					}
				}
				if signal_for_assault_flg == true{ 
					for your_unit_position in info.your_field_unit.keys{ 
						// Add speed move.
						if info.your_field_unit_action[your_unit_position] == 1{ 
							info.your_field_unit_action[your_unit_position] = 2
						}
					}
				}
				
				// For the loading time.
				info.last_time_turnend = info.last_time_turnend! + 2.0
				let opponent = info.opponent
				if target > 0 && (CodeOfFlow.battleInfo[opponent]!).your_field_unit[target] == nil{ 
					panic("You can not use skill for the target of this position!")
				}
				if let infoOpponent = CodeOfFlow.battleInfo[opponent]{ 
					infoOpponent.last_time_turnend = info.last_time_turnend
					infoOpponent.opponent_remain_deck = info.your_remain_deck.length
					infoOpponent.opponent_hand = your_hand_count
					infoOpponent.opponent_trigger_cards = info.your_trigger_cards.keys.length
					infoOpponent.opponent_field_unit = info.your_field_unit
					infoOpponent.opponent_field_unit_action = info.your_field_unit_action
					infoOpponent.your_field_unit_action = info.opponent_field_unit_action
					infoOpponent.your_field_unit_bp_amount_of_change = info.opponent_field_unit_bp_amount_of_change
					infoOpponent.opponent_field_unit_bp_amount_of_change = info.your_field_unit_bp_amount_of_change
					infoOpponent.your_field_unit = info.opponent_field_unit
					infoOpponent.your_dead_count = info.opponent_dead_count
					infoOpponent.opponent_dead_count = info.your_dead_count
					// Process Trigger Lost
					if lost_card_flg == true{ 
						if infoOpponent.your_trigger_cards.keys.length == 1{ 
							infoOpponent.your_trigger_cards.remove(key: infoOpponent.your_trigger_cards.keys[0])
							infoOpponent.your_dead_count = infoOpponent.your_dead_count + 1
							info.opponent_trigger_cards = infoOpponent.your_trigger_cards.length
							info.opponent_dead_count = info.opponent_dead_count + 1
						} else if infoOpponent.your_trigger_cards.keys.length > 0{ 
							let blockCreatedAt = getCurrentBlock().timestamp.toString().slice(from: 0, upTo: 10)
							let decodedArray = blockCreatedAt.decodeHex()
							let pseudorandomNumber1 = decodedArray[decodedArray.length - 1]
							let withdrawPosition1 = pseudorandomNumber1 % (UInt8(infoOpponent.your_trigger_cards.keys.length) - 1)
							var lostTarget: UInt8 = 0
							for key in infoOpponent.your_trigger_cards.keys{ 
								if key == withdrawPosition1 + 1{ 
									lostTarget = key
								}
							}
							if lostTarget == 0{ 
								lostTarget = infoOpponent.your_trigger_cards.keys[0]
							}
							infoOpponent.your_trigger_cards.remove(key: lostTarget)
							infoOpponent.your_dead_count = infoOpponent.your_dead_count + 1
							info.opponent_trigger_cards = infoOpponent.your_trigger_cards.length
							info.opponent_dead_count = info.opponent_dead_count + 1
						}
					}
					// Save
					CodeOfFlow.battleInfo[opponent] = infoOpponent
				}
				
				// Save
				CodeOfFlow.battleInfo[player_id] = info
			}
			
			// judge the winner
			self.judgeTheWinner(player_id: player_id)
		}
		
		access(all)
		fun attack(
			player_id: UInt,
			attack_unit: UInt8,
			enemy_skill_target: UInt8?,
			trigger_cards:{ 
				UInt8: UInt16
			},
			used_intercept_positions: [
				UInt8
			]
		){ 
			if (CodeOfFlow.battleInfo[player_id]!).your_field_unit[attack_unit] == nil{ 
				panic("You have not set unit card in this position!")
			}
			for trigger_position in trigger_cards.keys{ 
				if !((CodeOfFlow.battleInfo[player_id]!).your_trigger_cards[trigger_position] == trigger_cards[trigger_position] || (CodeOfFlow.battleInfo[player_id]!).your_trigger_cards[trigger_position] == nil){} 
			// panic("Your trigger card is Tampered!") To avoid transaction failure by the coincident accident.
			}
			for card_position in used_intercept_positions{ 
				if (CodeOfFlow.battleInfo[player_id]!).your_trigger_cards[card_position] == nil{} 
			// panic("You have not set trigger card in this position!") TODO FIXME trigger_cards must be counted before check your_trigger_cards
			}
			var attacking_card_to_enemy: AttackStruct? = nil
			var your_trigger_cards_count: Int = 0
			var attack_success_flg = false
			if let info = CodeOfFlow.battleInfo[player_id]{ 
				info.newly_drawed_cards = []
				
				// Match the consistency of the hand (take from the hand the amount moved to the trigger zone) (ハンドの整合性を合わせる(トリガーゾーンに移動した分、ハンドから取る))
				for position in trigger_cards.keys{ 
					var isRemoved = false
					if info.your_trigger_cards[position] != trigger_cards[position] && trigger_cards[position] != 0{ 
						let card_id = trigger_cards[position]
						info.your_trigger_cards[position] = card_id
						for hand_position in info.your_hand.keys{ 
							if card_id == info.your_hand[hand_position] && isRemoved == false{ 
								info.your_hand[hand_position] = nil
								isRemoved = true
							}
						}
						if isRemoved == false{ 
							panic("You set the card on trigger zone which is not exist in your hand")
						}
					}
				}
				
				//////////////////////////////////////////////////
				// Process Battle Action START
				//////////////////////////////////////////////////
				var lost_card_flg_cnt = 0
				var speed_move_flg = false
				let used_trigger_cards: [UInt16] = []
				info.your_field_unit_action[attack_unit] = 0 // 2: can attack, 1: can defence only, 0: nothing can do.
				
				
				///////////////attribute evaluation///////////////
				let card_id: UInt16 = info.your_field_unit[attack_unit]!
				let unit = CodeOfFlow.cardInfo[card_id]!
				// trigger when the unit is attacking
				if unit.skill.trigger_1 == 2{ 
					//---- BP Pump ----
					if unit.skill.type_1 == 2{ 
						if let your_field_unit_bp_amount_of_change = info.your_field_unit_bp_amount_of_change[attack_unit]{ 
							info.your_field_unit_bp_amount_of_change[attack_unit] = your_field_unit_bp_amount_of_change + Int(unit.skill.amount_1)
						} else{ 
							info.your_field_unit_bp_amount_of_change[attack_unit] = Int(unit.skill.amount_1)
						}
					}
					
					//---- Damage ----
					if unit.skill.type_1 == 1{ 
						// Damage to all unit
						if unit.skill.ask_1 == 3{ 
							for opponent_position in info.opponent_field_unit.keys{ 
								if let opponent_field_unit_bp_amount_of_change = info.opponent_field_unit_bp_amount_of_change[opponent_position]{ 
									info.opponent_field_unit_bp_amount_of_change[opponent_position] = opponent_field_unit_bp_amount_of_change + -1 * Int(unit.skill.amount_1)
								} else{ 
									info.opponent_field_unit_bp_amount_of_change[opponent_position] = -1 * Int(unit.skill.amount_1)
								}
								// assess is this damage enough to beat the unit.
								if let opponent = info.opponent_field_unit[opponent_position]{ 
									let card_id: UInt16 = info.opponent_field_unit[opponent_position]!
									let opponentUnit = CodeOfFlow.cardInfo[card_id]!
									if Int(opponentUnit.bp) <= info.opponent_field_unit_bp_amount_of_change[opponent_position]! * -1{ 
										// beat the opponent
										info.opponent_field_unit[opponent_position] = nil
										info.opponent_field_unit_bp_amount_of_change[opponent_position] = nil
										info.opponent_dead_count = info.opponent_dead_count + 1
									}
								}
							}
						// Damage to one target unit
						} else if unit.skill.ask_1 == 1{ 
							var target: UInt8 = 1
							if enemy_skill_target != nil{ 
								target = enemy_skill_target!
							}
							if let opponent_field_unit_bp_amount_of_change = info.opponent_field_unit_bp_amount_of_change[target]{ 
								info.opponent_field_unit_bp_amount_of_change[target] = opponent_field_unit_bp_amount_of_change + -1 * Int(unit.skill.amount_1)
							} else{ 
								info.opponent_field_unit_bp_amount_of_change[target] = -1 * Int(unit.skill.amount_1)
							}
							// assess is this damage enough to beat the unit.
							if let opponent = info.opponent_field_unit[target]{ 
								let card_id: UInt16 = info.opponent_field_unit[target]!
								let opponentUnit = CodeOfFlow.cardInfo[card_id]!
								if Int(opponentUnit.bp) <= info.opponent_field_unit_bp_amount_of_change[target]! * -1{ 
									// beat the opponent
									info.opponent_field_unit[target] = nil
									info.opponent_field_unit_bp_amount_of_change[target] = nil
									info.opponent_dead_count = info.opponent_dead_count + 1
								}
							}
						
						// Only target which has no action right
						} else if unit.skill.ask_1 == 2{ 
							var target: UInt8 = 1
							if enemy_skill_target != nil{ 
								target = enemy_skill_target!
							}
							if info.opponent_field_unit_action[target] == 0{ // // 2: can attack, 1: can defence only, 0: nothing can do. 
								
								if let opponent_field_unit_bp_amount_of_change = info.opponent_field_unit_bp_amount_of_change[target]{ 
									info.opponent_field_unit_bp_amount_of_change[target] = opponent_field_unit_bp_amount_of_change + -1 * Int(unit.skill.amount_1)
								} else{ 
									info.opponent_field_unit_bp_amount_of_change[target] = -1 * Int(unit.skill.amount_1)
								}
							}
							// assess is this damage enough to beat the unit.
							if let opponent = info.opponent_field_unit[target]{ 
								let card_id: UInt16 = info.opponent_field_unit[target]!
								let opponentUnit = CodeOfFlow.cardInfo[card_id]!
								if Int(opponentUnit.bp) <= info.opponent_field_unit_bp_amount_of_change[target]! * -1{ 
									// beat the opponent
									info.opponent_field_unit[target] = nil
									info.opponent_field_unit_bp_amount_of_change[target] = nil
									info.opponent_dead_count = info.opponent_dead_count + 1
								}
							}
						}
					}
					//---- Trigger lost ----
					if unit.skill.type_1 == 3{ 
						lost_card_flg_cnt = lost_card_flg_cnt + 1
					}
					
					//---- Valkyrie(This unit is not blocked.) ----
					if unit.skill.type_1 == 12{ 
						attack_success_flg = true
					}
					
					//---- Remove action right ----
					if unit.skill.type_1 == 5{ 
						var target: UInt8 = 1
						if enemy_skill_target != nil{ 
							target = enemy_skill_target!
						}
						info.opponent_field_unit_action[target] = 0 // // 2: can attack, 1: can defence only, 0: nothing can do.
					
					}
					//---- Draw card ----
					if unit.skill.type_1 == 7{ 
						let blockCreatedAt = getCurrentBlock().timestamp.toString().slice(from: 0, upTo: 10)
						let decodedArray = blockCreatedAt.decodeHex()
						let pseudorandomNumber1 = Int(decodedArray[decodedArray.length - 1])
						let withdrawPosition1 = pseudorandomNumber1 % (info.your_remain_deck.length - 1)
						var isSetCard1 = false
						let handPositions: [UInt8] = [1, 2, 3, 4, 5, 6, 7]
						let nextPositions: [UInt8] = [1, 2, 3, 4, 5, 6]
						// カード位置を若い順に整列
						for hand_position in handPositions{ 
							var replaced: Bool = false
							if info.your_hand[hand_position] == nil{ 
								for next in nextPositions{ 
									if replaced == false && hand_position + next <= 7 && info.your_hand[hand_position + next] != nil{ 
										info.your_hand[hand_position] = info.your_hand[hand_position + next]
										info.your_hand[hand_position + next] = nil
										replaced = true
									}
								}
							}
						}
						for hand_position in handPositions{ 
							if info.your_hand[hand_position] == nil && isSetCard1 == false{ 
								var drawed_card = info.your_remain_deck.remove(at: withdrawPosition1)
								info.your_hand[hand_position] = drawed_card
								info.newly_drawed_cards.append(drawed_card)
								isSetCard1 = true
							}
						}
					}
					//---- Speed Move ----
					if unit.skill.type_1 == 11{ 
						speed_move_flg = true
					}
				}
				// trigger when the unit is attacking
				if unit.skill.trigger_2 == 2{ // currently there is no card which has trigger_3 and trigger_4 
					
					if unit.skill.type_2 == 3{ 
						lost_card_flg_cnt = lost_card_flg_cnt + 1
					}
				}
				
				// Used Intercept Card
				for card_position in used_intercept_positions{ 
					let trigger_card_id = info.your_trigger_cards[card_position]!
					let trigger = CodeOfFlow.cardInfo[trigger_card_id]!
					// info.your_trigger_cards[card_position] = nil  Remove when defence_action transaction is executed.
					// info.your_dead_count = info.your_dead_count + 1
					
					// trigger when the unit is attacking
					if trigger.skill.trigger_1 == 2{ 
						//---- BP Pump ----
						if trigger.skill.type_1 == 2{ 
							if let your_field_unit_bp_amount_of_change = info.your_field_unit_bp_amount_of_change[attack_unit]{ 
								info.your_field_unit_bp_amount_of_change[attack_unit] = your_field_unit_bp_amount_of_change + Int(trigger.skill.amount_1)
							} else{ 
								info.your_field_unit_bp_amount_of_change[attack_unit] = Int(trigger.skill.amount_1)
							}
						}
						// Enemy Unit Target
						var target: UInt8 = 1
						if enemy_skill_target != nil{ 
							target = enemy_skill_target!
						}
						//---- Damage ----
						if trigger.skill.type_1 == 1{ 
							// Damage to one target unit
							if trigger.skill.ask_1 == 1{ 
								if let opponent_field_unit_bp_amount_of_change = info.opponent_field_unit_bp_amount_of_change[target]{ 
									info.opponent_field_unit_bp_amount_of_change[target] = opponent_field_unit_bp_amount_of_change + -1 * Int(trigger.skill.amount_1)
								} else{ 
									info.opponent_field_unit_bp_amount_of_change[target] = -1 * Int(trigger.skill.amount_1)
								}
								// assess is this damage enough to beat the unit.
								if let opponent = info.opponent_field_unit[target]{ 
									let card_id: UInt16 = info.opponent_field_unit[target]!
									let opponentUnit = CodeOfFlow.cardInfo[card_id]!
									if Int(opponentUnit.bp) < info.opponent_field_unit_bp_amount_of_change[target]! * -1{ 
										// beat the opponent
										info.opponent_field_unit[target] = nil
										info.opponent_dead_count = info.opponent_dead_count + 1
									}
								}
							// Only target which has no action right
							} else if trigger.skill.ask_1 == 2{ 
								if info.opponent_field_unit_action[target] == 3{ // // 2: can attack, 1: can defence only, 0: nothing can do. 
									
									if let opponent_field_unit_bp_amount_of_change = info.opponent_field_unit_bp_amount_of_change[target]{ 
										info.opponent_field_unit_bp_amount_of_change[target] = opponent_field_unit_bp_amount_of_change + -1 * Int(trigger.skill.amount_1)
									} else{ 
										info.opponent_field_unit_bp_amount_of_change[target] = -1 * Int(trigger.skill.amount_1)
									}
								}
								// assess is this damage enough to beat the unit.
								if let opponent = info.opponent_field_unit[target]{ 
									let card_id: UInt16 = info.opponent_field_unit[target]!
									let opponentUnit = CodeOfFlow.cardInfo[card_id]!
									if Int(opponentUnit.bp) < info.opponent_field_unit_bp_amount_of_change[target]! * -1{ 
										// beat the opponent
										info.opponent_field_unit[target] = nil
										info.opponent_dead_count = info.opponent_dead_count + 1
									}
								}
							}
						}
						
						//---- Trigger lost ----
						if trigger.skill.type_1 == 3{ 
							lost_card_flg_cnt = lost_card_flg_cnt + 1
						}
						//---- Remove action right ----
						if trigger.skill.type_1 == 5{ 
							if trigger.skill.amount_1 == 1{ 
								info.opponent_field_unit_action[target] = 0 // // 2: can attack, 1: can defence only, 0: nothing can do.
							
							} else if trigger.skill.amount_1 == 5{ 
								for enemy_position in info.opponent_field_unit_action.keys{ 
									info.opponent_field_unit_action[enemy_position] = 0
								}
							}
						}
					}
					used_trigger_cards.append(trigger_card_id)
				}
				///////////////↑↑attribute evaluation↑↑///////////
				var unit_pump: UInt = 0
				if info.your_field_unit_bp_amount_of_change[attack_unit] != nil{ 
					unit_pump = UInt(info.your_field_unit_bp_amount_of_change[attack_unit]!)
				}
				attacking_card_to_enemy = AttackStruct(card_id: unit.card_id, position: attack_unit, bp: unit.bp, pump: unit_pump, used_trigger_cards: used_trigger_cards, attacked_time: getCurrentBlock().timestamp)
				//////////////////////////////////////////////////
				// Process Battle Action END
				//////////////////////////////////////////////////
				info.last_time_turnend = info.last_time_turnend! + 5.0
				info.your_attacking_card = attacking_card_to_enemy
				let opponent = info.opponent
				if enemy_skill_target != nil{ 
					if (CodeOfFlow.battleInfo[opponent]!).your_field_unit[enemy_skill_target!] == nil{ 
						panic("You can not use skill for the target of this position!")
					}
				}
				if let infoOpponent = CodeOfFlow.battleInfo[opponent]{ 
					infoOpponent.last_time_turnend = info.last_time_turnend
					infoOpponent.enemy_attacking_card = attacking_card_to_enemy
					infoOpponent.your_life = info.opponent_life
					infoOpponent.opponent_life = info.your_life
					infoOpponent.opponent_remain_deck = info.your_remain_deck.length
					infoOpponent.opponent_trigger_cards = info.your_trigger_cards.keys.length
					infoOpponent.opponent_field_unit = info.your_field_unit
					infoOpponent.opponent_field_unit_action = info.your_field_unit_action
					infoOpponent.opponent_field_unit_bp_amount_of_change = info.your_field_unit_bp_amount_of_change
					infoOpponent.your_field_unit_bp_amount_of_change = info.opponent_field_unit_bp_amount_of_change
					infoOpponent.your_dead_count = info.opponent_dead_count
					infoOpponent.opponent_dead_count = info.your_dead_count
					// Process Trigger Lost
					if lost_card_flg_cnt > 0{ 
						if infoOpponent.your_trigger_cards.keys.length == 1{ 
							infoOpponent.your_trigger_cards.remove(key: infoOpponent.your_trigger_cards.keys[0])
							infoOpponent.your_dead_count = infoOpponent.your_dead_count + 1
							info.opponent_trigger_cards = infoOpponent.your_trigger_cards.length
							info.opponent_dead_count = info.opponent_dead_count + 1
						} else if infoOpponent.your_trigger_cards.keys.length <= lost_card_flg_cnt{ 
							for key in infoOpponent.your_trigger_cards.keys{ 
								infoOpponent.your_trigger_cards.remove(key: key)
							}
						} else{ 
							while lost_card_flg_cnt > 0{ 
								lost_card_flg_cnt = lost_card_flg_cnt - 1
								let blockCreatedAt = getCurrentBlock().timestamp.toString().slice(from: 0, upTo: 10)
								let decodedArray = blockCreatedAt.decodeHex()
								let pseudorandomNumber1 = decodedArray[decodedArray.length - 1]
								let withdrawPosition1 = pseudorandomNumber1 % (UInt8(infoOpponent.your_trigger_cards.keys.length) - 1)
								var target: UInt8 = 0
								for key in infoOpponent.your_trigger_cards.keys{ 
									if key == withdrawPosition1 + 1{ 
										target = key
									}
								}
								if target == 0{ 
									target = infoOpponent.your_trigger_cards.keys[0]
								}
								infoOpponent.your_trigger_cards.remove(key: target)
							}
							infoOpponent.your_dead_count = infoOpponent.your_dead_count + 1
							info.opponent_trigger_cards = infoOpponent.your_trigger_cards.length
							info.opponent_dead_count = info.opponent_dead_count + 1
						}
					}
					CodeOfFlow.battleInfo[opponent] = infoOpponent
				}
				// save
				CodeOfFlow.battleInfo[player_id] = info
			}
			
			// Valkyrie(This unit is not blocked.)
			if attack_success_flg == true{ 
				self.defence_action(player_id: player_id, opponent_defend_position: nil, attacker_used_intercept_positions: [], defender_used_intercept_positions: [])
			}
		}
		
		access(all)
		fun defence_action(
			player_id: UInt,
			opponent_defend_position: UInt8?,
			attacker_used_intercept_positions: [
				UInt8
			],
			defender_used_intercept_positions: [
				UInt8
			]
		){ 
			for card_position in attacker_used_intercept_positions{ 
				if (CodeOfFlow.battleInfo[player_id]!).your_trigger_cards[card_position] == nil{} 
			// panic("You have not set trigger card in this position!") TODO FIXME trigger_cards must be counted before check your_trigger_cards
			}
			if let info = CodeOfFlow.battleInfo[player_id]{ 
				if info.your_attacking_card == nil && info.enemy_attacking_card == nil{ 
					panic("Battle seems already settled.")
				}
				info.newly_drawed_cards = []
				let opponent = info.opponent
				//////////////////////////////////
				// The Transaction from the player has attacked (アタック側からのトランザクション)
				//////////////////////////////////
				if info.is_first == info.is_first_turn && info.your_attacking_card != nil{ 
					/// attribute evaluation ///
					if opponent_defend_position != nil{ 
						if info.opponent_field_unit[opponent_defend_position!] != nil{ 
							let card_id: UInt16 = info.opponent_field_unit[opponent_defend_position!]!
							let unit = CodeOfFlow.cardInfo[card_id]!
							
							// trigger when the unit is blocking
							if unit.skill.trigger_1 == 3{ 
								//---- BP Pump ----
								if unit.skill.type_1 == 2{ 
									if let opponent_field_unit_bp_amount_of_change = info.opponent_field_unit_bp_amount_of_change[opponent_defend_position!]{ 
										info.opponent_field_unit_bp_amount_of_change[opponent_defend_position!] = opponent_field_unit_bp_amount_of_change + Int(unit.skill.amount_1)
									} else{ 
										info.opponent_field_unit_bp_amount_of_change[opponent_defend_position!] = Int(unit.skill.amount_1)
									}
								}
							}
							
							// Used Intercept Card(Attacker)
							for card_position in attacker_used_intercept_positions{ 
								let trigger_card_id = info.your_trigger_cards[card_position]!
								let trigger = CodeOfFlow.cardInfo[trigger_card_id]!
								let attack_unit = (info.your_attacking_card!).position
								info.your_trigger_cards[card_position] = nil
								info.your_dead_count = info.your_dead_count + 1
								
								// trigger when the unit is battling
								if trigger.skill.trigger_1 == 5{ 
									//---- BP Pump ----
									if trigger.skill.type_1 == 2{ 
										if let your_field_unit_bp_amount_of_change = info.your_field_unit_bp_amount_of_change[attack_unit]{ 
											info.your_field_unit_bp_amount_of_change[attack_unit] = your_field_unit_bp_amount_of_change + Int(trigger.skill.amount_1)
										} else{ 
											info.your_field_unit_bp_amount_of_change[attack_unit] = Int(trigger.skill.amount_1)
										}
									}
								}
							}
							
							// Used Intercept Card(Defender)
							if let infoOpponent = CodeOfFlow.battleInfo[opponent]{ 
								for card_position in defender_used_intercept_positions{ 
									let trigger_card_id = infoOpponent.your_trigger_cards[card_position]!
									let trigger = CodeOfFlow.cardInfo[trigger_card_id]!
									let attack_unit = (infoOpponent.your_attacking_card!).position
									infoOpponent.your_trigger_cards[card_position] = nil
									infoOpponent.your_dead_count = infoOpponent.your_dead_count + 1
									info.opponent_dead_count = info.opponent_dead_count + 1
									
									// trigger when the unit is battling
									if trigger.skill.trigger_1 == 5{ 
										//---- BP Pump ----
										if trigger.skill.type_1 == 2{ 
											if let opponent_field_unit_bp_amount_of_change = info.opponent_field_unit_bp_amount_of_change[opponent_defend_position!]{ 
												info.opponent_field_unit_bp_amount_of_change[opponent_defend_position!] = opponent_field_unit_bp_amount_of_change + Int(trigger.skill.amount_1)
											} else{ 
												info.opponent_field_unit_bp_amount_of_change[opponent_defend_position!] = Int(trigger.skill.amount_1)
											}
										}
									}
								}
								// Save
								CodeOfFlow.battleInfo[opponent] = infoOpponent
							}
						/// ↑↑attribute evaluation↑↑ ///
						}
						
						//////////////// Battle Result ////////////////
						// when each unit's position is matched
						if info.opponent_field_unit[opponent_defend_position!] != nil && CodeOfFlow.cardInfo[info.opponent_field_unit[opponent_defend_position!]!] != nil{ 
							let unit = CodeOfFlow.cardInfo[info.opponent_field_unit[opponent_defend_position!]!]!
							var opponentPump = 0
							var yourPump = 0
							if info.opponent_field_unit_bp_amount_of_change[opponent_defend_position!] != nil{ 
								opponentPump = info.opponent_field_unit_bp_amount_of_change[opponent_defend_position!]!
							}
							if info.your_field_unit_bp_amount_of_change[(info.your_attacking_card!).position] != nil{ 
								yourPump = info.your_field_unit_bp_amount_of_change[(info.your_attacking_card!).position]!
							}
							if Int(unit.bp) + opponentPump < Int((info.your_attacking_card!).bp) + yourPump{ 
								info.opponent_field_unit[opponent_defend_position!] = nil
								info.opponent_field_unit_bp_amount_of_change[opponent_defend_position!] = nil
								info.opponent_field_unit_action[opponent_defend_position!] = nil
								info.opponent_dead_count = info.opponent_dead_count + 1
								info.your_field_unit_bp_amount_of_change[(info.your_attacking_card!).position] = yourPump - (Int(unit.bp) + opponentPump) // Calculate unit's damage.
							
							} else if Int(unit.bp) + opponentPump == Int((info.your_attacking_card!).bp) + yourPump{ 
								info.your_field_unit[(info.your_attacking_card!).position] = nil
								info.your_field_unit_bp_amount_of_change[(info.your_attacking_card!).position!] = nil
								info.your_field_unit_action[(info.your_attacking_card!).position!] = nil
								info.your_dead_count = info.your_dead_count + 1
								info.opponent_field_unit[opponent_defend_position!] = nil
								info.opponent_field_unit_bp_amount_of_change[opponent_defend_position!] = nil
								info.opponent_field_unit_action[opponent_defend_position!] = nil
								info.opponent_dead_count = info.opponent_dead_count + 1
							} else{ 
								info.your_field_unit[(info.your_attacking_card!).position] = nil
								info.your_field_unit_bp_amount_of_change[(info.your_attacking_card!).position!] = nil
								info.your_field_unit_action[(info.your_attacking_card!).position!] = nil
								info.your_dead_count = info.your_dead_count + 1
								info.opponent_field_unit_bp_amount_of_change[opponent_defend_position!] = opponentPump - (Int((info.your_attacking_card!).bp) + yourPump) // Calculate unit's damage.
							
							}
						}
					} else{ 
						info.opponent_life = info.opponent_life - 1
						for card_position in attacker_used_intercept_positions{ 
							let trigger_card_id = info.your_trigger_cards[card_position]!
							let trigger = CodeOfFlow.cardInfo[trigger_card_id]!
							let attack_unit = (info.your_attacking_card!).position
							info.your_trigger_cards[card_position] = nil
							info.your_dead_count = info.your_dead_count + 1
							
							// trigger when the unit is battling
							if trigger.skill.trigger_1 == 5{ 
								//---- BP Pump ----
								if trigger.skill.type_1 == 2{ 
									if let your_field_unit_bp_amount_of_change = info.your_field_unit_bp_amount_of_change[attack_unit]{ 
										info.your_field_unit_bp_amount_of_change[attack_unit] = your_field_unit_bp_amount_of_change + Int(trigger.skill.amount_1)
									} else{ 
										info.your_field_unit_bp_amount_of_change[attack_unit] = Int(trigger.skill.amount_1)
									}
								}
							}
						}
						if info.opponent_life == 1{ 
							if let infoOpponent = CodeOfFlow.battleInfo[opponent]{ 
								for card_position in infoOpponent.your_trigger_cards.keys{ 
									let trigger_card_id = infoOpponent.your_trigger_cards[card_position]!
									let trigger = CodeOfFlow.cardInfo[trigger_card_id]!
									// trigger when the player is hit by a player attack
									if trigger.skill.trigger_1 == 6{ 
										if trigger.skill.type_1 == 9 && trigger.skill.ask_1 == 3{ 
											// Yggdrasill
											infoOpponent.your_trigger_cards[card_position] = nil
											// Save
											CodeOfFlow.battleInfo[opponent] = infoOpponent
											for opponent_position in info.opponent_field_unit.keys{ 
												// destroy the unit
												info.opponent_field_unit[opponent_position] = nil
												info.opponent_field_unit_action[opponent_position] = nil
												info.opponent_dead_count = info.opponent_dead_count + 1
											}
											for your_position in info.your_field_unit.keys{ 
												// destroy the unit
												info.your_field_unit[your_position] = nil
												info.your_field_unit_action[your_position] = nil
												info.your_dead_count = info.your_dead_count + 1
											}
										}
									}
								}
							}
						}
					}
					if (info.your_attacking_card!).attacked_time > info.last_time_turnend!{ 
						info.last_time_turnend = info.last_time_turnend! + ((info.your_attacking_card!).attacked_time - info.last_time_turnend!)
					}
					info.your_attacking_card = nil
					info.enemy_attacking_card = nil
					
					// save
					CodeOfFlow.battleInfo[player_id] = info
					////////////// ↑↑Battle Result↑↑ //////////////
					var handCnt = 0
					let handPositions: [UInt8] = [1, 2, 3, 4, 5, 6, 7]
					for hand_position in handPositions{ 
						if info.your_hand[hand_position] != nil{ 
							handCnt = handCnt + 1
						}
					}
					let opponent = info.opponent
					if let infoOpponent = CodeOfFlow.battleInfo[opponent]{ 
						infoOpponent.last_time_turnend = info.last_time_turnend
						infoOpponent.your_attacking_card = nil
						infoOpponent.enemy_attacking_card = nil
						infoOpponent.your_life = info.opponent_life
						infoOpponent.opponent_life = info.your_life
						infoOpponent.opponent_hand = handCnt
						infoOpponent.opponent_remain_deck = info.your_remain_deck.length
						infoOpponent.opponent_trigger_cards = info.your_trigger_cards.keys.length
						infoOpponent.opponent_field_unit = info.your_field_unit
						infoOpponent.opponent_field_unit_action = info.your_field_unit_action
						infoOpponent.opponent_field_unit_bp_amount_of_change = info.your_field_unit_bp_amount_of_change
						infoOpponent.your_field_unit = info.opponent_field_unit
						infoOpponent.your_field_unit_action = info.opponent_field_unit_action
						infoOpponent.your_field_unit_bp_amount_of_change = info.opponent_field_unit_bp_amount_of_change
						infoOpponent.opponent_cp = info.your_cp
						infoOpponent.your_dead_count = info.opponent_dead_count
						infoOpponent.opponent_dead_count = info.your_dead_count
						CodeOfFlow.battleInfo[opponent] = infoOpponent
					}
				//////////////////////////////////
				// The Transaction from the player has defended (防御側からのトランザクション)
				//////////////////////////////////
				} else if info.is_first != info.is_first_turn && info.enemy_attacking_card != nil{ 
					/// attribute evaluation ///
					if opponent_defend_position != nil{ 
						if info.your_field_unit[opponent_defend_position!] != nil{ 
							let card_id: UInt16 = info.your_field_unit[opponent_defend_position!]!
							let unit = CodeOfFlow.cardInfo[card_id]!
							
							// trigger when the unit is blocking
							if unit.skill.trigger_1 == 3{ 
								//---- BP Pump ----
								if unit.skill.type_1 == 2{ 
									if let your_field_unit_bp_amount_of_change = info.your_field_unit_bp_amount_of_change[opponent_defend_position!]{ 
										info.your_field_unit_bp_amount_of_change[opponent_defend_position!] = your_field_unit_bp_amount_of_change + Int(unit.skill.amount_1)
									} else{ 
										info.your_field_unit_bp_amount_of_change[opponent_defend_position!] = Int(unit.skill.amount_1)
									}
								}
							}
							
							// Used Intercept Card(Attacker)
							if let infoOpponent = CodeOfFlow.battleInfo[opponent]{ 
								for card_position in attacker_used_intercept_positions{ 
									let trigger_card_id = infoOpponent.your_trigger_cards[card_position]!
									let trigger = CodeOfFlow.cardInfo[trigger_card_id]!
									let attack_unit = (info.enemy_attacking_card!).position
									infoOpponent.your_trigger_cards[card_position] = nil
									infoOpponent.your_dead_count = infoOpponent.your_dead_count + 1
									
									// trigger when the unit is battling
									if trigger.skill.trigger_1 == 5{ 
										//---- BP Pump ----
										if trigger.skill.type_1 == 2{ 
											if let opponent_field_unit_bp_amount_of_change = infoOpponent.your_field_unit_bp_amount_of_change[attack_unit]{ 
												info.opponent_field_unit_bp_amount_of_change[attack_unit] = opponent_field_unit_bp_amount_of_change + Int(trigger.skill.amount_1)
											} else{ 
												info.opponent_field_unit_bp_amount_of_change[attack_unit] = Int(trigger.skill.amount_1)
											}
										}
									}
								}
								// Save
								CodeOfFlow.battleInfo[opponent] = infoOpponent
							}
							
							// Used Intercept Card(Defender)
							for card_position in defender_used_intercept_positions{ 
								let trigger_card_id = info.your_trigger_cards[card_position]!
								let trigger = CodeOfFlow.cardInfo[trigger_card_id]!
								info.your_trigger_cards[card_position] = nil
								info.your_dead_count = info.your_dead_count + 1
								
								// trigger when the unit is battling or blocking
								if trigger.skill.trigger_1 == 3 || unit.skill.trigger_1 == 5{ 
									//---- BP Pump ----
									if trigger.skill.type_1 == 2{ 
										if let your_field_unit_bp_amount_of_change = info.your_field_unit_bp_amount_of_change[opponent_defend_position!]{ 
											info.your_field_unit_bp_amount_of_change[opponent_defend_position!] = your_field_unit_bp_amount_of_change + Int(trigger.skill.amount_1)
										} else{ 
											info.your_field_unit_bp_amount_of_change[opponent_defend_position!] = Int(trigger.skill.amount_1)
										}
									}
								}
							}
						/// ↑↑attribute evaluation↑↑ ///
						}
						
						//////////////// Battle Result ////////////////
						// when each unit's position is matched
						if info.your_field_unit[opponent_defend_position!] != nil && CodeOfFlow.cardInfo[info.your_field_unit[opponent_defend_position!]!] != nil{ 
							let unit = CodeOfFlow.cardInfo[info.your_field_unit[opponent_defend_position!]!]!
							var yourPump = 0
							var opponentPump = 0
							if info.your_field_unit_bp_amount_of_change[opponent_defend_position!] != nil{ 
								yourPump = info.your_field_unit_bp_amount_of_change[opponent_defend_position!]!
							}
							if info.opponent_field_unit_bp_amount_of_change[(info.enemy_attacking_card!).position] != nil{ 
								opponentPump = info.opponent_field_unit_bp_amount_of_change[(info.enemy_attacking_card!).position]!
							}
							if Int(unit.bp) + yourPump < Int((info.enemy_attacking_card!).bp) + opponentPump{ 
								info.your_field_unit[opponent_defend_position!] = nil
								info.your_field_unit_bp_amount_of_change[opponent_defend_position!] = nil
								info.your_field_unit_action[opponent_defend_position!] = nil
								info.your_dead_count = info.your_dead_count + 1
								info.opponent_field_unit_bp_amount_of_change[(info.enemy_attacking_card!).position] = opponentPump - (Int(unit.bp) + yourPump) // Calculate unit's damage.
							
							} else if Int(unit.bp) + yourPump == Int((info.enemy_attacking_card!).bp) + opponentPump{ 
								info.opponent_field_unit[(info.enemy_attacking_card!).position] = nil
								info.opponent_field_unit_bp_amount_of_change[(info.enemy_attacking_card!).position] = nil
								info.opponent_field_unit_action[(info.enemy_attacking_card!).position] = nil
								info.opponent_dead_count = info.opponent_dead_count + 1
								info.your_field_unit[opponent_defend_position!] = nil
								info.your_field_unit_bp_amount_of_change[opponent_defend_position!] = nil
								info.your_field_unit_action[opponent_defend_position!] = nil
								info.your_dead_count = info.your_dead_count + 1
							} else{ 
								info.opponent_field_unit[(info.enemy_attacking_card!).position] = nil
								info.opponent_field_unit_bp_amount_of_change[(info.enemy_attacking_card!).position] = nil
								info.opponent_field_unit_action[(info.enemy_attacking_card!).position] = nil
								info.opponent_dead_count = info.opponent_dead_count + 1
								info.your_field_unit_bp_amount_of_change[opponent_defend_position!] = yourPump - (Int((info.enemy_attacking_card!).bp) + opponentPump) // Calculate unit's damage.
							
							}
						}
					} else{ 
						info.your_life = info.your_life - 1
						if let infoOpponent = CodeOfFlow.battleInfo[opponent]{ 
							for card_position in attacker_used_intercept_positions{ 
								let trigger_card_id = infoOpponent.your_trigger_cards[card_position]!
								let trigger = CodeOfFlow.cardInfo[trigger_card_id]!
								let attack_unit = (info.enemy_attacking_card!).position
								infoOpponent.your_trigger_cards[card_position] = nil
								infoOpponent.your_dead_count = infoOpponent.your_dead_count + 1
								
								// trigger when the unit is battling
								if trigger.skill.trigger_1 == 5{ 
									//---- BP Pump ----
									if trigger.skill.type_1 == 2{ 
										if let opponent_field_unit_bp_amount_of_change = infoOpponent.your_field_unit_bp_amount_of_change[attack_unit]{ 
											info.opponent_field_unit_bp_amount_of_change[attack_unit] = opponent_field_unit_bp_amount_of_change + Int(trigger.skill.amount_1)
										} else{ 
											info.opponent_field_unit_bp_amount_of_change[attack_unit] = Int(trigger.skill.amount_1)
										}
									}
								}
							}
							// Save
							CodeOfFlow.battleInfo[opponent] = infoOpponent
						}
						if info.your_life == 1{ 
							for card_position in info.your_trigger_cards.keys{ 
								let trigger_card_id = info.your_trigger_cards[card_position]!
								let trigger = CodeOfFlow.cardInfo[trigger_card_id]!
								// trigger when the player is hit by a player attack
								if trigger.skill.trigger_1 == 6{ 
									if trigger.skill.type_1 == 9 && trigger.skill.ask_1 == 3{ 
										// Yggdrasill
										info.your_trigger_cards[card_position] = nil
										for opponent_position in info.opponent_field_unit.keys{ 
											// destroy the unit
											info.opponent_field_unit[opponent_position] = nil
											info.opponent_field_unit_action[opponent_position] = nil
											info.opponent_dead_count = info.opponent_dead_count + 1
										}
										for your_position in info.your_field_unit.keys{ 
											// destroy the unit
											info.your_field_unit[your_position] = nil
											info.your_field_unit_action[your_position] = nil
											info.your_dead_count = info.your_dead_count + 1
										}
									}
								}
							}
						}
					}
					if (info.enemy_attacking_card!).attacked_time > info.last_time_turnend!{ 
						info.last_time_turnend = info.last_time_turnend! + ((info.enemy_attacking_card!).attacked_time - info.last_time_turnend!)
					}
					info.your_attacking_card = nil
					info.enemy_attacking_card = nil
					
					// save
					CodeOfFlow.battleInfo[player_id] = info
					////////////// ↑↑Battle Result↑↑ //////////////
					var handCnt = 0
					let handPositions: [UInt8] = [1, 2, 3, 4, 5, 6, 7]
					for hand_position in handPositions{ 
						if info.your_hand[hand_position] != nil{ 
							handCnt = handCnt + 1
						}
					}
					if let infoOpponent = CodeOfFlow.battleInfo[opponent]{ 
						infoOpponent.last_time_turnend = info.last_time_turnend
						infoOpponent.your_attacking_card = nil
						infoOpponent.enemy_attacking_card = nil
						infoOpponent.your_life = info.opponent_life
						infoOpponent.opponent_life = info.your_life
						infoOpponent.opponent_hand = handCnt
						infoOpponent.opponent_remain_deck = info.your_remain_deck.length
						infoOpponent.opponent_trigger_cards = info.your_trigger_cards.keys.length
						infoOpponent.opponent_field_unit = info.your_field_unit
						infoOpponent.opponent_field_unit_action = info.your_field_unit_action
						infoOpponent.opponent_field_unit_bp_amount_of_change = info.your_field_unit_bp_amount_of_change
						infoOpponent.your_field_unit = info.opponent_field_unit
						infoOpponent.your_field_unit_action = info.opponent_field_unit_action
						infoOpponent.your_field_unit_bp_amount_of_change = info.opponent_field_unit_bp_amount_of_change
						infoOpponent.opponent_cp = info.your_cp
						infoOpponent.your_dead_count = info.opponent_dead_count
						infoOpponent.opponent_dead_count = info.your_dead_count
						CodeOfFlow.battleInfo[opponent] = infoOpponent
					}
				}
			}
			
			// judge the winner
			self.judgeTheWinner(player_id: player_id)
		}
		
		access(all)
		fun turn_change(player_id: UInt, from_opponent: Bool, trigger_cards:{ UInt8: UInt16}){ 
			if let info = CodeOfFlow.battleInfo[player_id]{ 
				
				// Check is turn already changed.
				if info.is_first != info.is_first_turn{ 
					return
				}
				
				// 決着がついていない攻撃がまだある
				if info.your_attacking_card != nil && (info.your_attacking_card!).attacked_time + 20.0 > info.last_time_turnend!{ 
					return
				} else{ 
					info.your_attacking_card = nil
				}
				if info.enemy_attacking_card != nil && (info.enemy_attacking_card!).attacked_time + 20.0 > info.last_time_turnend!{ 
					return
				} else{ 
					info.enemy_attacking_card = nil
				}
				info.newly_drawed_cards = []
				info.last_time_turnend = getCurrentBlock().timestamp
				
				// トリガーゾーンのカードを合わせる
				for position in trigger_cards.keys{ 
					// セット済みは除外
					if info.your_trigger_cards[position] != trigger_cards[position]{ 
						// ハンドの整合性を合わせる(トリガーゾーンに移動した分、ハンドから取る)
						var isRemoved = false
						if info.your_trigger_cards[position] != trigger_cards[position] && trigger_cards[position] != 0{ 
							let card_id = trigger_cards[position]
							info.your_trigger_cards[position] = card_id
							for hand_position in info.your_hand.keys{ 
								if card_id == info.your_hand[hand_position] && isRemoved == false{ 
									info.your_hand[hand_position] = nil
									isRemoved = true
								}
							}
							if isRemoved == false{ 
								panic("You set the card on trigger zone which is not exist in your hand")
							}
						}
					}
				}
				var handCnt = 0
				let handPositions: [UInt8] = [1, 2, 3, 4, 5, 6, 7]
				for hand_position in handPositions{ 
					if info.your_hand[hand_position] != nil{ 
						handCnt = handCnt + 1
					}
				}
				
				// Set Field Unit Actions To Defence Only
				for position in info.your_field_unit.keys{ 
					if info.your_field_unit_action[position] == 2{ 
						info.your_field_unit_action[position] = 1 // 2: can attack, 1: can defence only, 0: nothing can do.
					
					}
					if info.your_field_unit[position] != nil && info.your_field_unit[position] != 0{ 
						let card_id: UInt16 = info.your_field_unit[position]!
						let unit = CodeOfFlow.cardInfo[card_id]!
						///////////////attribute evaluation///////////////
						// trigger when the turn is changing
						if unit.skill.trigger_1 == 4{ 
							//---- indomitable spirit ----
							if unit.skill.type_1 == 8{ 
								info.your_field_unit_action[position] = 1
							}
						}
					}
				///////////////attribute evaluation///////////////
				}
				
				// Process Turn Change
				info.last_time_turnend = getCurrentBlock().timestamp
				info.is_first_turn = !info.is_first_turn
				if info.is_first_turn{ 
					info.turn = info.turn + 1
				}
				let opponent = info.opponent
				if let infoOpponent = CodeOfFlow.battleInfo[opponent]{ 
					
					// Turn Change
					infoOpponent.last_time_turnend = info.last_time_turnend
					infoOpponent.is_first_turn = !infoOpponent.is_first_turn
					infoOpponent.turn = info.turn
					infoOpponent.opponent_hand = handCnt
					infoOpponent.opponent_remain_deck = info.your_remain_deck.length
					infoOpponent.opponent_trigger_cards = info.your_trigger_cards.keys.length
					infoOpponent.opponent_field_unit = info.your_field_unit
					infoOpponent.opponent_field_unit_action = info.your_field_unit_action
					infoOpponent.opponent_field_unit_bp_amount_of_change = info.your_field_unit_bp_amount_of_change
					infoOpponent.your_field_unit_bp_amount_of_change = info.opponent_field_unit_bp_amount_of_change
					
					// draw card
					let blockCreatedAt = getCurrentBlock().timestamp.toString().slice(from: 0, upTo: 10)
					let decodedArray = blockCreatedAt.decodeHex()
					let pseudorandomNumber1 = decodedArray[decodedArray.length - 1] // as! Int
					
					let pseudorandomNumber2 = decodedArray[decodedArray.length - 2] // as! Int
					
					let cardRemainCounts = infoOpponent.your_remain_deck.length
					let withdrawPosition1 = Int(pseudorandomNumber1) % (cardRemainCounts - 1)
					let withdrawPosition2 = Int(pseudorandomNumber2) % (cardRemainCounts - 2)
					var isSetCard1 = false
					var isSetCard2 = false
					var handCnt2 = 0
					let handPositions: [UInt8] = [1, 2, 3, 4, 5, 6, 7]
					let nextPositions: [UInt8] = [1, 2, 3, 4, 5, 6]
					// カード位置を若い順に整列
					for hand_position in handPositions{ 
						var replaced: Bool = false
						if infoOpponent.your_hand[hand_position] == nil{ 
							for next in nextPositions{ 
								if replaced == false && hand_position + next <= 7 && infoOpponent.your_hand[hand_position + next] != nil{ 
									infoOpponent.your_hand[hand_position] = infoOpponent.your_hand[hand_position + next]
									infoOpponent.your_hand[hand_position + next] = nil
									replaced = true
								}
							}
						}
					}
					for hand_position in handPositions{ 
						if infoOpponent.your_hand[hand_position] == nil && isSetCard1 == false{ 
							infoOpponent.your_hand[hand_position] = infoOpponent.your_remain_deck.remove(at: withdrawPosition1)
							isSetCard1 = true
						}
						if infoOpponent.your_hand[hand_position] == nil && isSetCard2 == false{ 
							infoOpponent.your_hand[hand_position] = infoOpponent.your_remain_deck.remove(at: withdrawPosition2)
							isSetCard2 = true
						}
						if infoOpponent.your_hand[hand_position] != nil{ 
							handCnt2 = handCnt2 + 1
						}
					}
					infoOpponent.your_field_unit_bp_amount_of_change ={} // Damage are reset 
					
					infoOpponent.opponent_field_unit_bp_amount_of_change ={} 
					
					// Recover Field Unit Actions
					for position in infoOpponent.your_field_unit_action.keys{ 
						if infoOpponent.your_field_unit[position] == nil{ 
							infoOpponent.your_field_unit_action[position] = nil
						} else{ 
							infoOpponent.your_field_unit_action[position] = 2 // 2: can attack, 1: can defence only, 0: nothing can do.
						
						}
					}
					// Recover CP
					if infoOpponent.turn <= 6{ 
						infoOpponent.your_cp = infoOpponent.turn + 1
					} else{ 
						infoOpponent.your_cp = 7
					}
					if infoOpponent.turn == 1 && !infoOpponent.is_first{ 
						infoOpponent.your_cp = 3
					}
					info.last_time_turnend = infoOpponent.last_time_turnend // set time same time
					
					info.opponent_hand = handCnt2
					info.opponent_remain_deck = infoOpponent.your_remain_deck.length
					info.opponent_trigger_cards = infoOpponent.your_trigger_cards.keys.length
					info.opponent_field_unit = infoOpponent.your_field_unit
					info.opponent_field_unit_action = infoOpponent.your_field_unit_action
					info.opponent_field_unit_bp_amount_of_change = infoOpponent.your_field_unit_bp_amount_of_change
					info.opponent_cp = infoOpponent.your_cp
					CodeOfFlow.battleInfo[opponent] = infoOpponent
				}
				// save
				CodeOfFlow.battleInfo[player_id] = info
			}
			
			// judge the winner
			self.judgeTheWinner(player_id: player_id)
		}
		
		access(all)
		fun surrender(player_id: UInt){ 
			if CodeOfFlow.battleInfo[player_id] != nil{ 
				let opponent = (CodeOfFlow.battleInfo[player_id]!).opponent
				CodeOfFlow.battleInfo.remove(key: player_id)
				if let cyberScore = CodeOfFlow.playerList[player_id]{ 
					cyberScore.score.append({getCurrentBlock().timestamp: 0})
					cyberScore.loss_count = cyberScore.loss_count + 1
					cyberScore.period_loss_count = cyberScore.period_loss_count + 1
					CodeOfFlow.playerList[player_id] = cyberScore
				}
				if CodeOfFlow.battleInfo[opponent] != nil{ 
					CodeOfFlow.battleInfo.remove(key: opponent)
					if let cyberScore = CodeOfFlow.playerList[opponent]{ 
						cyberScore.score.append({getCurrentBlock().timestamp: 1})
						cyberScore.win_count = cyberScore.win_count + 1
						cyberScore.period_win_count = cyberScore.period_win_count + 1
						CodeOfFlow.playerList[opponent] = cyberScore
					}
				}
				CodeOfFlow.playerMatchingInfo[player_id] = PlayerMatchingStruct() // ゲームが終了したのでnilで初期化
				
				CodeOfFlow.playerMatchingInfo[opponent] = PlayerMatchingStruct() // ゲームが終了したのでnilで初期化
				
				emit BattleSequence(sequence: 3, player_id: opponent, opponent: player_id)
				// Game Reward
				let reward <- (CodeOfFlow.account.storage.borrow<&{FungibleToken.Provider}>(from: /storage/flowTokenVault)!).withdraw(amount: 0.5) as! @FlowToken.Vault
				((CodeOfFlow.PlayerFlowTokenVault[opponent]!).borrow()!).deposit(from: <-reward)
				self.rankingTotalling(playerid: opponent)
			}
		}
		
		access(all)
		fun judgeTheWinner(player_id: UInt): Bool{ 
			pre{ 
				CodeOfFlow.battleInfo[player_id] != nil:
					"This guy doesn't do match."
			}
			if let info = CodeOfFlow.battleInfo[player_id]{ 
				if info.turn > 10{ 
					if info.your_life > info.opponent_life || info.your_life == info.opponent_life && info.is_first == false{ // Second Attack wins if lives are same. 
						
						let opponent = info.opponent
						CodeOfFlow.battleInfo.remove(key: player_id)
						CodeOfFlow.battleInfo.remove(key: opponent)
						if let cyberScore = CodeOfFlow.playerList[player_id]{ 
							cyberScore.score.append({getCurrentBlock().timestamp: 1})
							cyberScore.win_count = cyberScore.win_count + 1
							cyberScore.period_win_count = cyberScore.period_win_count + 1
							CodeOfFlow.playerList[player_id] = cyberScore
						}
						if let cyberScore = CodeOfFlow.playerList[opponent]{ 
							cyberScore.score.append({getCurrentBlock().timestamp: 0})
							cyberScore.loss_count = cyberScore.loss_count + 1
							cyberScore.period_loss_count = cyberScore.period_loss_count + 1
							CodeOfFlow.playerList[opponent] = cyberScore
						}
						CodeOfFlow.playerMatchingInfo[player_id] = PlayerMatchingStruct() // ゲームが終了したのでnilで初期化
						
						CodeOfFlow.playerMatchingInfo[opponent] = PlayerMatchingStruct() // ゲームが終了したのでnilで初期化
						
						emit BattleSequence(sequence: 3, player_id: player_id, opponent: opponent)
						// Game Reward
						let reward <- (CodeOfFlow.account.storage.borrow<&{FungibleToken.Provider}>(from: /storage/flowTokenVault)!).withdraw(amount: 0.5) as! @FlowToken.Vault
						((CodeOfFlow.PlayerFlowTokenVault[player_id]!).borrow()!).deposit(from: <-reward)
						self.rankingTotalling(playerid: player_id)
						return true
					} else{ 
						let opponent = info.opponent
						CodeOfFlow.battleInfo.remove(key: player_id)
						CodeOfFlow.battleInfo.remove(key: opponent)
						if let cyberScore = CodeOfFlow.playerList[player_id]{ 
							cyberScore.score.append({getCurrentBlock().timestamp: 0})
							cyberScore.loss_count = cyberScore.loss_count + 1
							cyberScore.period_loss_count = cyberScore.period_loss_count + 1
							CodeOfFlow.playerList[player_id] = cyberScore
						}
						if let cyberScore = CodeOfFlow.playerList[opponent]{ 
							cyberScore.score.append({getCurrentBlock().timestamp: 1})
							cyberScore.win_count = cyberScore.win_count + 1
							cyberScore.period_win_count = cyberScore.period_win_count + 1
							CodeOfFlow.playerList[opponent] = cyberScore
						}
						CodeOfFlow.playerMatchingInfo[player_id] = PlayerMatchingStruct() // ゲームが終了したのでnilで初期化
						
						CodeOfFlow.playerMatchingInfo[opponent] = PlayerMatchingStruct() // ゲームが終了したのでnilで初期化
						
						emit BattleSequence(sequence: 3, player_id: opponent, opponent: player_id)
						// Game Reward
						let reward <- (CodeOfFlow.account.storage.borrow<&{FungibleToken.Provider}>(from: /storage/flowTokenVault)!).withdraw(amount: 0.5) as! @FlowToken.Vault
						((CodeOfFlow.PlayerFlowTokenVault[opponent]!).borrow()!).deposit(from: <-reward)
						self.rankingTotalling(playerid: opponent)
						return true
					}
				} else if info.turn == 10 && info.is_first_turn == false{ // 10 turn and second attack 
					
					if info.your_life <= info.opponent_life && info.is_first == true{ // Lose if palyer is First Attack & life is less than opponent 
						
						let opponent = info.opponent
						CodeOfFlow.battleInfo.remove(key: player_id)
						CodeOfFlow.battleInfo.remove(key: opponent)
						if let cyberScore = CodeOfFlow.playerList[player_id]{ 
							cyberScore.score.append({getCurrentBlock().timestamp: 0})
							cyberScore.loss_count = cyberScore.loss_count + 1
							cyberScore.period_loss_count = cyberScore.period_loss_count + 1
							CodeOfFlow.playerList[player_id] = cyberScore
						}
						if let cyberScore = CodeOfFlow.playerList[opponent]{ 
							cyberScore.score.append({getCurrentBlock().timestamp: 1})
							cyberScore.win_count = cyberScore.win_count + 1
							cyberScore.period_win_count = cyberScore.period_win_count + 1
							CodeOfFlow.playerList[opponent] = cyberScore
						}
						CodeOfFlow.playerMatchingInfo[player_id] = PlayerMatchingStruct() // ゲームが終了したのでnilで初期化
						
						CodeOfFlow.playerMatchingInfo[opponent] = PlayerMatchingStruct() // ゲームが終了したのでnilで初期化
						
						emit BattleSequence(sequence: 3, player_id: opponent, opponent: player_id)
						// Game Reward
						let reward <- (CodeOfFlow.account.storage.borrow<&{FungibleToken.Provider}>(from: /storage/flowTokenVault)!).withdraw(amount: 0.5) as! @FlowToken.Vault
						((CodeOfFlow.PlayerFlowTokenVault[opponent]!).borrow()!).deposit(from: <-reward)
						self.rankingTotalling(playerid: opponent)
						return true
					} else if info.your_life >= info.opponent_life && info.is_first == false{ // Win if palyer is Second Attack & life is more than opponent 
						
						let opponent = info.opponent
						CodeOfFlow.battleInfo.remove(key: player_id)
						CodeOfFlow.battleInfo.remove(key: opponent)
						if let cyberScore = CodeOfFlow.playerList[player_id]{ 
							cyberScore.score.append({getCurrentBlock().timestamp: 1})
							cyberScore.win_count = cyberScore.win_count + 1
							cyberScore.period_win_count = cyberScore.period_win_count + 1
							CodeOfFlow.playerList[player_id] = cyberScore
						}
						if let cyberScore = CodeOfFlow.playerList[opponent]{ 
							cyberScore.score.append({getCurrentBlock().timestamp: 0})
							cyberScore.loss_count = cyberScore.loss_count + 1
							cyberScore.period_loss_count = cyberScore.period_loss_count + 1
							CodeOfFlow.playerList[opponent] = cyberScore
						}
						CodeOfFlow.playerMatchingInfo[player_id] = PlayerMatchingStruct() // ゲームが終了したのでnilで初期化
						
						CodeOfFlow.playerMatchingInfo[opponent] = PlayerMatchingStruct() // ゲームが終了したのでnilで初期化
						
						emit BattleSequence(sequence: 3, player_id: player_id, opponent: opponent)
						// Game Reward
						let reward <- (CodeOfFlow.account.storage.borrow<&{FungibleToken.Provider}>(from: /storage/flowTokenVault)!).withdraw(amount: 0.5) as! @FlowToken.Vault
						((CodeOfFlow.PlayerFlowTokenVault[player_id]!).borrow()!).deposit(from: <-reward)
						self.rankingTotalling(playerid: player_id)
						return true
					}
				}
				if info.opponent_life == 0{ 
					let opponent = info.opponent
					CodeOfFlow.battleInfo.remove(key: player_id)
					CodeOfFlow.battleInfo.remove(key: opponent)
					if let cyberScore = CodeOfFlow.playerList[player_id]{ 
						cyberScore.score.append({getCurrentBlock().timestamp: 1})
						cyberScore.win_count = cyberScore.win_count + 1
						cyberScore.period_win_count = cyberScore.period_win_count + 1
						CodeOfFlow.playerList[player_id] = cyberScore
					}
					if let cyberScore = CodeOfFlow.playerList[opponent]{ 
						cyberScore.score.append({getCurrentBlock().timestamp: 0})
						cyberScore.loss_count = cyberScore.loss_count + 1
						cyberScore.period_loss_count = cyberScore.period_loss_count + 1
						CodeOfFlow.playerList[opponent] = cyberScore
					}
					CodeOfFlow.playerMatchingInfo[player_id] = PlayerMatchingStruct() // ゲームが終了したのでnilで初期化
					
					CodeOfFlow.playerMatchingInfo[opponent] = PlayerMatchingStruct() // ゲームが終了したのでnilで初期化
					
					emit BattleSequence(sequence: 3, player_id: player_id, opponent: opponent)
					// Game Reward
					let reward <- (CodeOfFlow.account.storage.borrow<&{FungibleToken.Provider}>(from: /storage/flowTokenVault)!).withdraw(amount: 0.5) as! @FlowToken.Vault
					((CodeOfFlow.PlayerFlowTokenVault[player_id]!).borrow()!).deposit(from: <-reward)
					self.rankingTotalling(playerid: player_id)
					return true
				} else if info.your_life == 0{ 
					let opponent = info.opponent
					CodeOfFlow.battleInfo.remove(key: player_id)
					CodeOfFlow.battleInfo.remove(key: opponent)
					if let cyberScore = CodeOfFlow.playerList[player_id]{ 
						cyberScore.score.append({getCurrentBlock().timestamp: 0})
						cyberScore.loss_count = cyberScore.loss_count + 1
						cyberScore.period_loss_count = cyberScore.period_loss_count + 1
						CodeOfFlow.playerList[player_id] = cyberScore
					}
					if let cyberScore = CodeOfFlow.playerList[opponent]{ 
						cyberScore.score.append({getCurrentBlock().timestamp: 1})
						cyberScore.win_count = cyberScore.win_count + 1
						cyberScore.period_win_count = cyberScore.period_win_count + 1
						CodeOfFlow.playerList[opponent] = cyberScore
					}
					CodeOfFlow.playerMatchingInfo[player_id] = PlayerMatchingStruct() // ゲームが終了したのでnilで初期化
					
					CodeOfFlow.playerMatchingInfo[opponent] = PlayerMatchingStruct() // ゲームが終了したのでnilで初期化
					
					emit BattleSequence(sequence: 3, player_id: opponent, opponent: player_id)
					// Game Reward
					let reward <- (CodeOfFlow.account.storage.borrow<&{FungibleToken.Provider}>(from: /storage/flowTokenVault)!).withdraw(amount: 0.5) as! @FlowToken.Vault
					((CodeOfFlow.PlayerFlowTokenVault[opponent]!).borrow()!).deposit(from: <-reward)
					self.rankingTotalling(playerid: opponent)
					return true
				}
			}
			return false
		}
		
		// Totalling Ranking values.
		access(all)
		fun rankingTotalling(playerid: UInt){ 
			CodeOfFlow.rankingBattleCount = CodeOfFlow.rankingBattleCount + 1
			if let score = CodeOfFlow.playerList[playerid]{ 
				// When this game just started
				if CodeOfFlow.ranking3rdWinningPlayerId == 0 || CodeOfFlow.ranking2ndWinningPlayerId == 0 || CodeOfFlow.ranking1stWinningPlayerId == 0{ 
					if CodeOfFlow.ranking1stWinningPlayerId == 0{ 
						CodeOfFlow.ranking1stWinningPlayerId = playerid
					} else if CodeOfFlow.ranking2ndWinningPlayerId == 0{ 
						CodeOfFlow.ranking2ndWinningPlayerId = playerid
					} else{ 
						CodeOfFlow.ranking3rdWinningPlayerId = playerid
					}
				} else{ 
					for player_id in CodeOfFlow.playerList.keys{ 
						if let cyberScore = CodeOfFlow.playerList[player_id]{ 
							if cyberScore.win_count + cyberScore.loss_count > 0{ 
								if player_id != CodeOfFlow.ranking3rdWinningPlayerId && player_id != CodeOfFlow.ranking2ndWinningPlayerId && player_id != CodeOfFlow.ranking1stWinningPlayerId{ 
									if let rank3rdScore = CodeOfFlow.playerList[CodeOfFlow.ranking3rdWinningPlayerId]{ 
										if CodeOfFlow.calcPoint(win_count: rank3rdScore.period_win_count, loss_count: rank3rdScore.period_loss_count) < CodeOfFlow.calcPoint(win_count: cyberScore.period_win_count, loss_count: cyberScore.period_loss_count){ // If it's equal, first come first served. 
											
											if let rank2ndScore = CodeOfFlow.playerList[CodeOfFlow.ranking2ndWinningPlayerId]{ 
												if CodeOfFlow.calcPoint(win_count: rank2ndScore.period_win_count, loss_count: rank2ndScore.period_loss_count) < CodeOfFlow.calcPoint(win_count: cyberScore.period_win_count, loss_count: cyberScore.period_loss_count){ 
													if let rank1stScore = CodeOfFlow.playerList[CodeOfFlow.ranking1stWinningPlayerId]{ 
														if CodeOfFlow.calcPoint(win_count: rank1stScore.period_win_count, loss_count: rank1stScore.period_loss_count) < CodeOfFlow.calcPoint(win_count: cyberScore.period_win_count, loss_count: cyberScore.period_loss_count){ 
															CodeOfFlow.ranking3rdWinningPlayerId = CodeOfFlow.ranking2ndWinningPlayerId
															CodeOfFlow.ranking2ndWinningPlayerId = CodeOfFlow.ranking1stWinningPlayerId
															CodeOfFlow.ranking1stWinningPlayerId = player_id
														} else{ 
															CodeOfFlow.ranking3rdWinningPlayerId = CodeOfFlow.ranking2ndWinningPlayerId
															CodeOfFlow.ranking2ndWinningPlayerId = player_id
														}
													}
												} else{ 
													CodeOfFlow.ranking3rdWinningPlayerId = player_id
												}
											}
										}
									}
								} else if player_id != CodeOfFlow.ranking2ndWinningPlayerId && player_id != CodeOfFlow.ranking1stWinningPlayerId{ 
									if let rank2ndScore = CodeOfFlow.playerList[CodeOfFlow.ranking2ndWinningPlayerId]{ // If it's equal, first come first served. 
										
										if CodeOfFlow.calcPoint(win_count: rank2ndScore.period_win_count, loss_count: rank2ndScore.period_loss_count) < CodeOfFlow.calcPoint(win_count: cyberScore.period_win_count, loss_count: cyberScore.period_loss_count){ 
											if let rank1stScore = CodeOfFlow.playerList[CodeOfFlow.ranking1stWinningPlayerId]{ 
												if CodeOfFlow.calcPoint(win_count: rank1stScore.period_win_count, loss_count: rank1stScore.period_loss_count) < CodeOfFlow.calcPoint(win_count: cyberScore.period_win_count, loss_count: cyberScore.period_loss_count){ 
													CodeOfFlow.ranking3rdWinningPlayerId = CodeOfFlow.ranking2ndWinningPlayerId
													CodeOfFlow.ranking2ndWinningPlayerId = CodeOfFlow.ranking1stWinningPlayerId
													CodeOfFlow.ranking1stWinningPlayerId = player_id
												} else{ 
													CodeOfFlow.ranking3rdWinningPlayerId = CodeOfFlow.ranking2ndWinningPlayerId
													CodeOfFlow.ranking2ndWinningPlayerId = player_id
												}
											}
										}
									}
								} else if player_id != CodeOfFlow.ranking1stWinningPlayerId{ 
									if let rank1stScore = CodeOfFlow.playerList[CodeOfFlow.ranking1stWinningPlayerId]{ 
										if CodeOfFlow.calcPoint(win_count: rank1stScore.period_win_count, loss_count: rank1stScore.period_loss_count) < CodeOfFlow.calcPoint(win_count: cyberScore.period_win_count, loss_count: cyberScore.period_loss_count){ // If it's equal, first come first served. 
											
											CodeOfFlow.ranking2ndWinningPlayerId = CodeOfFlow.ranking1stWinningPlayerId
											CodeOfFlow.ranking1stWinningPlayerId = player_id
										}
									}
								}
							}
						}
					}
				}
			}
			if CodeOfFlow.rankingBattleCount >= CodeOfFlow.rankingPeriod{ 
				// Initialize the ranking win count.
				for playerId in CodeOfFlow.playerList.keys{ 
					if let score = CodeOfFlow.playerList[playerId]{ 
						score.period_win_count = 0
						score.period_loss_count = 0
						CodeOfFlow.playerList[playerId] = score // Save
					
					}
				}
				// Initialize the count.
				CodeOfFlow.rankingBattleCount = 0
				// Pay ranking reward(20 $FLOW)
				if let rank1stScore = CodeOfFlow.playerList[CodeOfFlow.ranking1stWinningPlayerId]{ 
					rank1stScore.ranking_win_count = rank1stScore.ranking_win_count + 1
					CodeOfFlow.playerList[CodeOfFlow.ranking1stWinningPlayerId] = rank1stScore // Save
					
					let reward1st <- (CodeOfFlow.account.storage.borrow<&{FungibleToken.Provider}>(from: /storage/flowTokenVault)!).withdraw(amount: 20.0) as! @FlowToken.Vault
					((CodeOfFlow.PlayerFlowTokenVault[CodeOfFlow.ranking1stWinningPlayerId]!).borrow()!).deposit(from: <-reward1st)
				}
				// Pay ranking reward(10 $FLOW)
				if let rank2ndScore = CodeOfFlow.playerList[CodeOfFlow.ranking2ndWinningPlayerId]{ 
					rank2ndScore.ranking_2nd_win_count = rank2ndScore.ranking_2nd_win_count + 1
					CodeOfFlow.playerList[CodeOfFlow.ranking2ndWinningPlayerId] = rank2ndScore // Save
					
					let reward1st <- (CodeOfFlow.account.storage.borrow<&{FungibleToken.Provider}>(from: /storage/flowTokenVault)!).withdraw(amount: 10.0) as! @FlowToken.Vault
					((CodeOfFlow.PlayerFlowTokenVault[CodeOfFlow.ranking2ndWinningPlayerId]!).borrow()!).deposit(from: <-reward1st)
				}
				// Pay ranking reward(5 $FLOW)
				if let rank1stScore = CodeOfFlow.playerList[CodeOfFlow.ranking3rdWinningPlayerId]{ 
					let reward1st <- (CodeOfFlow.account.storage.borrow<&{FungibleToken.Provider}>(from: /storage/flowTokenVault)!).withdraw(amount: 5.0) as! @FlowToken.Vault
					((CodeOfFlow.PlayerFlowTokenVault[CodeOfFlow.ranking3rdWinningPlayerId]!).borrow()!).deposit(from: <-reward1st)
				}
			}
		}
		
		/*
			** Add new card line-up / revise card info.
			*/
		
		access(all)
		fun edit_card_info(){ 
			CodeOfFlow.cardInfo[28] = CodeOfFlow.CardStruct(
					card_id: 28,
					name: "RainyFlame",
					bp: 0,
					cost: 1,
					type: 0,
					category: 2,
					skill: Skill(
						description: "When your unit enters the field, deal 2000 damage to all units on the field.",
						triggers: [1],
						asks: [3],
						types: [1],
						amounts: [2000],
						skills: []
					)
				)
			CodeOfFlow.cardInfo[29] = CodeOfFlow.CardStruct(
					card_id: 29,
					name: "Yggdrasill",
					bp: 0,
					cost: 0,
					type: 4,
					category: 1,
					skill: Skill(
						description: "When you are hit by a player attack, if you have 1 life or less, destroy all units.",
						triggers: [6],
						asks: [3],
						types: [9],
						amounts: [0],
						skills: []
					)
				)
		}
		
		init(){} 
	}
	
	// [Interface] IPlayerPublic
	access(all)
	resource interface IPlayerPublic{ 
		access(all)
		fun get_current_status(): AnyStruct
		
		access(all)
		fun get_marigan_cards(player_id: UInt): [[UInt16]]
		
		access(all)
		fun get_player_deck(player_id: UInt): [UInt16]
		
		access(all)
		fun get_players_score(): [CyberScoreStruct]
		
		access(all)
		fun buy_en(payment: @FlowToken.Vault)
	}
	
	// [Interface] IPlayerPrivate
	access(all)
	resource interface IPlayerPrivate{} 
	
	// [Resource] Player
	access(all)
	resource Player: IPlayerPublic, IPlayerPrivate{ 
		access(all)
		let player_id: UInt
		
		access(all)
		let nickname: String
		
		access(all)
		fun get_marigan_cards(player_id: UInt): [[UInt16]]{ 
			if let playerMatchingInfo = CodeOfFlow.playerMatchingInfo[player_id]{ 
				var ret_arr: [[UInt16]] = []
				for i in [0, 1, 2, 3, 4]{ 
					if let deck = CodeOfFlow.playerDeck[player_id]{ 
						var tmp = deck.slice(from: 0, upTo: deck.length)
						ret_arr.append([tmp.remove(at: playerMatchingInfo.marigan_cards[i][0]), tmp.remove(at: playerMatchingInfo.marigan_cards[i][1]), tmp.remove(at: playerMatchingInfo.marigan_cards[i][2]), tmp.remove(at: playerMatchingInfo.marigan_cards[i][3])])
					} else{ 
						var tmp = CodeOfFlow.starterDeck.slice(from: 0, upTo: CodeOfFlow.starterDeck.length)
						ret_arr.append([tmp.remove(at: playerMatchingInfo.marigan_cards[i][0]), tmp.remove(at: playerMatchingInfo.marigan_cards[i][1]), tmp.remove(at: playerMatchingInfo.marigan_cards[i][2]), tmp.remove(at: playerMatchingInfo.marigan_cards[i][3])])
					}
				}
				return ret_arr
			}
			return []
		}
		
		access(all)
		fun get_player_deck(player_id: UInt): [UInt16]{ 
			if let deck = CodeOfFlow.playerDeck[player_id]{ 
				return deck
			} else{ 
				return CodeOfFlow.starterDeck
			}
		}
		
		access(all)
		fun get_players_score(): [CyberScoreStruct]{ 
			let retArr: [CyberScoreStruct] = []
			retArr.append(CodeOfFlow.playerList[self.player_id]!)
			if let info = CodeOfFlow.battleInfo[self.player_id]{ 
				let opponent = info.opponent
				retArr.append(CodeOfFlow.playerList[opponent]!)
			}
			return retArr
		}
		
		access(all)
		fun get_current_status(): AnyStruct{ 
			if let info = CodeOfFlow.battleInfo[self.player_id]{ 
				return info
			}
			if let obj = CodeOfFlow.playerMatchingInfo[self.player_id]{ 
				return obj.lastTimeMatching
			}
			return nil
		}
		
		access(all)
		fun buy_en(payment: @FlowToken.Vault){ 
			pre{ 
				payment.balance == 1.0:
					"payment is not 1FLOW coin."
				CodeOfFlow.playerList[self.player_id] != nil:
					"CyberScoreStruct not found."
			}
			(CodeOfFlow.FlowTokenVault.borrow()!).deposit(from: <-payment)
			if let cyberScore = CodeOfFlow.playerList[self.player_id]{ 
				cyberScore.cyber_energy = cyberScore.cyber_energy + 100
				CodeOfFlow.playerList[self.player_id] = cyberScore
			}
		}
		
		init(nickname: String){ 
			CodeOfFlow.totalPlayers = CodeOfFlow.totalPlayers + 1
			self.player_id = CodeOfFlow.totalPlayers
			self.nickname = nickname
			CodeOfFlow.playerList[self.player_id] = CyberScoreStruct(player_name: nickname)
			emit PlayerRegistered(player_id: self.player_id)
		}
	}
	
	access(all)
	fun createPlayer(
		nickname: String,
		flow_vault_receiver: Capability<&FlowToken.Vault>
	): @CodeOfFlow.Player{ 
		let player <- create Player(nickname: nickname)
		if CodeOfFlow.PlayerFlowTokenVault[player.player_id] == nil{ 
			CodeOfFlow.PlayerFlowTokenVault[player.player_id] = flow_vault_receiver
		}
		return <-player
	}
	
	init(){ 
		self.FlowTokenVault = self.account.capabilities.get<&FlowToken.Vault>(
				/public/flowTokenReceiver
			)!
		self.PlayerFlowTokenVault ={} 
		self.AdminStoragePath = /storage/CodeOfFlowAdmin
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath) // grant admin resource
		
		self.PlayerStoragePath = /storage/CodeOfFlowPlayer
		self.PlayerPublicPath = /public/CodeOfFlowPlayer
		self.totalPlayers = 0
		self.rankingBattleCount = 0
		self.ranking1stWinningPlayerId = 0
		self.ranking2ndWinningPlayerId = 0
		self.ranking3rdWinningPlayerId = 0
		self.rankingPeriod = 1000
		self.cardInfo ={ 
				1:
				CardStruct(
					card_id: 1,
					name: "Hound",
					bp: 1000,
					cost: 0,
					type: 0,
					category: 0,
					skill: Skill(
						description: "No Skill",
						triggers: [0],
						asks: [0],
						types: [0],
						amounts: [0],
						skills: []
					)
				),
				2:
				CardStruct(
					card_id: 2,
					name: "Fighter",
					bp: 3000,
					cost: 1,
					type: 0,
					category: 0,
					skill: Skill(
						description: "When this unit attacks, this unit's BP is +2000 until end of turn.",
						triggers: [2],
						asks: [0],
						types: [2],
						amounts: [2000],
						skills: []
					)
				),
				3:
				CardStruct(
					card_id: 3,
					name: "Lancer",
					bp: 5000,
					cost: 2,
					type: 0,
					category: 0,
					skill: Skill(
						description: "When this unit attacks, choose an opponent's unit. Deal 1000 damage to it.",
						triggers: [2],
						asks: [1],
						types: [1],
						amounts: [1000],
						skills: []
					)
				),
				4:
				CardStruct(
					card_id: 4,
					name: "HellDog",
					bp: 6000,
					cost: 3,
					type: 0,
					category: 0,
					skill: Skill(
						description: "When this unit enters the field, a card in the opponent's trigger zone is randomly destroyed.",
						triggers: [1],
						asks: [0],
						types: [3],
						amounts: [1],
						skills: []
					)
				),
				5:
				CardStruct(
					card_id: 5,
					name: "Arty",
					bp: 2000,
					cost: 2,
					type: 0,
					category: 0,
					skill: Skill(
						description: "This unit is not affected by action restrictions for the turn it enters the field.",
						triggers: [1],
						asks: [0],
						types: [11],
						amounts: [0],
						skills: []
					)
				),
				6:
				CardStruct(
					card_id: 6,
					name: "Valkyrie",
					bp: 3000,
					cost: 3,
					type: 0,
					category: 0,
					skill: Skill(
						description: "This unit is not blocked.",
						triggers: [2],
						asks: [0],
						types: [12],
						amounts: [0],
						skills: []
					)
				),
				7:
				CardStruct(
					card_id: 7,
					name: "Lilim",
					bp: 4000,
					cost: 4,
					type: 0,
					category: 0,
					skill: Skill(
						description: "When this unit enters the field, choose one of your opponent's units. Deal 4000 damage to it. \nWhen this unit attacks, destroy a card in your opponent's Trigger Zone at random.",
						triggers: [1, 2],
						asks: [1, 0],
						types: [1, 3],
						amounts: [4000, 1],
						skills: []
					)
				),
				8:
				CardStruct(
					card_id: 8,
					name: "Belial",
					bp: 7000,
					cost: 7,
					type: 0,
					category: 0,
					skill: Skill(
						description: "When this unit enters the field, it deals 3000 damage to all of your opponent's units.",
						triggers: [1],
						asks: [3],
						types: [1],
						amounts: [3000],
						skills: []
					)
				),
				9:
				CardStruct(
					card_id: 9,
					name: "Sohei",
					bp: 2000,
					cost: 1,
					type: 1,
					category: 0,
					skill: Skill(
						description: "When this unit blocks, this unit's BP is +2000 until end of turn.",
						triggers: [3],
						asks: [0],
						types: [2],
						amounts: [2000],
						skills: []
					)
				),
				10:
				CardStruct(
					card_id: 10,
					name: "LionDog",
					bp: 1000,
					cost: 0,
					type: 1,
					category: 0,
					skill: Skill(
						description: "No Skill",
						triggers: [0],
						asks: [0],
						types: [0],
						amounts: [0],
						skills: []
					)
				),
				11:
				CardStruct(
					card_id: 11,
					name: "Allie",
					bp: 2000,
					cost: 1,
					type: 1,
					category: 0,
					skill: Skill(
						description: "When this unit enters the field, choose one of your opponent's units. Consume it's right of action.",
						triggers: [1],
						asks: [1],
						types: [5],
						amounts: [0],
						skills: []
					)
				),
				13:
				CardStruct(
					card_id: 13,
					name: "Caim",
					bp: 5000,
					cost: 3,
					type: 1,
					category: 0,
					skill: Skill(
						description: "When this unit enters the field, you draw a card.",
						triggers: [1],
						asks: [0],
						types: [7],
						amounts: [1],
						skills: []
					)
				),
				14:
				CardStruct(
					card_id: 14,
					name: "Limaru",
					bp: 6000,
					cost: 3,
					type: 1,
					category: 0,
					skill: Skill(
						description: "At the end of your turn, restore this unit's right of action.",
						triggers: [4],
						asks: [0],
						types: [8],
						amounts: [0],
						skills: []
					)
				),
				15:
				CardStruct(
					card_id: 15,
					name: "Roin",
					bp: 4000,
					cost: 2,
					type: 1,
					category: 0,
					skill: Skill(
						description: "When this unit blocks, this unit's BP is +2000 until end of turn.",
						triggers: [3],
						asks: [0],
						types: [2],
						amounts: [2000],
						skills: []
					)
				),
				16:
				CardStruct(
					card_id: 16,
					name: "Rairyu",
					bp: 6000,
					cost: 5,
					type: 1,
					category: 0,
					skill: Skill(
						description: "When this unit enters the field, choose one of your opponent's acted-up units. Deal 7000 damage to it.",
						triggers: [1],
						asks: [2],
						types: [1],
						amounts: [7000],
						skills: []
					)
				),
				17:
				CardStruct(
					card_id: 17,
					name: "Drive",
					bp: 0,
					cost: 0,
					type: 4,
					category: 1,
					skill: Skill(
						description: "When your unit attacks, its BP is +3000 until end of turn.",
						triggers: [2],
						asks: [0],
						types: [2],
						amounts: [3000],
						skills: []
					)
				),
				18:
				CardStruct(
					card_id: 18,
					name: "Canon",
					bp: 0,
					cost: 0,
					type: 4,
					category: 1,
					skill: Skill(
						description: "When your unit enters the field, choose one of your opponent's units. Deal 1000 damage to it.",
						triggers: [1],
						asks: [1],
						types: [1],
						amounts: [1000],
						skills: []
					)
				),
				19:
				CardStruct(
					card_id: 19,
					name: "Merchant",
					bp: 0,
					cost: 0,
					type: 4,
					category: 1,
					skill: Skill(
						description: "When your unit enters the field, you draw a card.",
						triggers: [1],
						asks: [0],
						types: [7],
						amounts: [1],
						skills: []
					)
				),
				20:
				CardStruct(
					card_id: 20,
					name: "Breaker",
					bp: 0,
					cost: 1,
					type: 0,
					category: 2,
					skill: Skill(
						description: "When your unit enters the field, choose one of your opponent's units. Deal 3000 damage to it.",
						triggers: [1],
						asks: [1],
						types: [1],
						amounts: [3000],
						skills: []
					)
				),
				21:
				CardStruct(
					card_id: 21,
					name: "Imperiale",
					bp: 0,
					cost: 0,
					type: 0,
					category: 2,
					skill: Skill(
						description: "When your unit enters the field, grant that unit the ability to be unaffected by action restrictions for the turn it enters the field.",
						triggers: [1],
						asks: [0],
						types: [11],
						amounts: [0],
						skills: []
					)
				),
				22:
				CardStruct(
					card_id: 22,
					name: "Dainsleif",
					bp: 0,
					cost: 1,
					type: 0,
					category: 2,
					skill: Skill(
						description: "When your unit attacks, destroy a card in your opponent's trigger zone at random.",
						triggers: [2],
						asks: [0],
						types: [3],
						amounts: [1],
						skills: []
					)
				),
				23:
				CardStruct(
					card_id: 23,
					name: "Photon",
					bp: 0,
					cost: 0,
					type: 1,
					category: 2,
					skill: Skill(
						description: "When your unit enters the field, choose one of your opponent's acted-up units. Deal 3000 damage to it.",
						triggers: [1],
						asks: [2],
						types: [1],
						amounts: [3000],
						skills: []
					)
				),
				24:
				CardStruct(
					card_id: 24,
					name: "Titan's Lock",
					bp: 0,
					cost: 0,
					type: 1,
					category: 2,
					skill: Skill(
						description: "When your unit attacks, choose one of your opponent's units. Consume it's right of action.",
						triggers: [2],
						asks: [1],
						types: [5],
						amounts: [1],
						skills: []
					)
				),
				25:
				CardStruct(
					card_id: 25,
					name: "Judgement",
					bp: 0,
					cost: 6,
					type: 1,
					category: 2,
					skill: Skill(
						description: "When your unit attacks, consumes the right of action of all opposing units.",
						triggers: [2],
						asks: [0],
						types: [5],
						amounts: [5],
						skills: []
					)
				),
				26:
				CardStruct(
					card_id: 26,
					name: "Hero's Sword",
					bp: 0,
					cost: 0,
					type: 4,
					category: 2,
					skill: Skill(
						description: "When your unit fights, it gets +2000 BP until end of turn.",
						triggers: [5],
						asks: [0],
						types: [2],
						amounts: [2000],
						skills: []
					)
				),
				27:
				CardStruct(
					card_id: 27,
					name: "Signal for assault",
					bp: 0,
					cost: 3,
					type: 4,
					category: 2,
					skill: Skill(
						description: "When your unit enters the field, give all your units [Speed Move] (this unit is not affected by action restrictions for the turn it enters the field) until end of turn.",
						triggers: [1],
						asks: [3],
						types: [11],
						amounts: [0],
						skills: []
					)
				)
			/* MEMO
				   trigger 1: trigger when the card is put on the field (フィールド上にカードを置いた時)  -- trigger: 18,19 intercept: 20,21,23,27 unit: 4,5,7,8,11,13,16
				   trigger 2: trigger when the unit is attacking(攻撃時)
				   trigger 3: trigger when the unit is blocking(防御時)
				   trigger 4: trigger when the turn is changing(ターンが変わる時)
				   trigger 5: trigger when the unit is battling（戦闘時）
				   trigger 6: trigger when the player is hit by a player attack（プレイヤーアタック成功時）
				   ask 0: Not choose target. (選ばない)
				   ask 1: Target one unit (相手を選ぶ)
				   ask 2: Only target which has no action right(行動権がない相手を選ぶ)
				   ask 3: Not choose target. But influence all units (選ばない。全体に影響)
				   type 1: Damage(ダメージ)
				   type 2: BP Pump(BPパンプ)
				   type 3: Trigger lost(トリガーロスト)
				   type 5: Remove action right(行動権剥奪)
				   type 7: Draw cards(カードドロー)
				   type 8: Indomitable spirit(不屈)
				   type 9: Destroy unit cards(ユニットカード破壊)
				   type 11: Speed Move(スピードムーブ)
			
				  */
			
			}
		self.starterDeck = [
				1,
				1,
				2,
				2,
				3,
				3,
				4,
				4,
				5,
				6,
				7,
				8,
				9,
				9,
				10,
				11,
				13,
				14,
				15,
				16,
				17,
				18,
				19,
				20,
				21,
				22,
				23,
				24,
				25,
				26
			]
		self.battleInfo ={} 
		self.matchingLimits = []
		self.matchingPlayers = []
		self.playerList ={} 
		self.playerDeck ={} 
		self.playerMatchingInfo ={} 
	}
}
