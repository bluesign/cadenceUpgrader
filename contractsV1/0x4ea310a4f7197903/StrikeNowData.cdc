access(all)
contract StrikeNowData{ 
	
	//Should look like:
	// {
	//   "seriesId": "1",
	//   "seriesName": "UFC 292 Oezdemir vs. Smith",
	//   "seriesDescription": "UFC 292 Inaugral Launch",
	//   "eventId": "890",
	//   "season": "1",
	//   "eventTime": "1691694054.0",
	// }
	access(all)
	struct SeriesData{ 
		access(all)
		let seriesId: UInt32
		
		access(all)
		let seriesName: String
		
		access(all)
		let seriesDescription: String
		
		access(all)
		let eventId: UInt32
		
		access(all)
		let eventTime: UFix64
		
		access(all)
		let season: String
		
		access(all)
		let fights:{ UInt32: FightData}
		
		access(all)
		let metadataRaw:{ String: String}
		
		access(all)
		let fightsRaw: [{String: String}]?
		
		init(seriesId: UInt32, metadata:{ String: String}, fights: [{String: String}]?){ 
			pre{ 
				metadata["seriesName"] != nil:
					"Key seriesName is required on SeriesData"
				metadata["seriesDescription"] != nil:
					"Key seriesDescription is required on SeriesData"
				metadata["eventId"] != nil:
					"Key eventId is required on SeriesData"
				metadata["season"] != nil:
					"Key season is required on SeriesData"
				metadata["eventTime"] != nil:
					"Key eventTime is required on SeriesData"
			}
			self.seriesId = seriesId
			self.seriesName = metadata["seriesName"]!
			self.seriesDescription = metadata["seriesDescription"]!
			self.eventId = UInt32.fromString(metadata["eventId"]!)!
			self.season = metadata["season"]!
			self.eventTime = UFix64.fromString(metadata["eventTime"]!)!
			self.metadataRaw = metadata
			self.fightsRaw = fights
			self.fights ={} 
			if fights != nil && fights?.length! > 0{ 
				for fight in fights!{ 
					let id = UInt32.fromString(fight["fightId"]!)!
					self.fights[id] = StrikeNowData.FightData(fightId: id, input: fight)
				}
			}
		}
	}
	
	// Should look like:
	// { 
	//   "fightId": "7441",
	//   "fightName": "Oezdemir vs Smith",
	//   "cardSegment": "Main",
	//   "weightClass": "Featherweight",
	//   "weightClassDescription": "136-145",
	//   "city": "Moncton",
	//   "state": "New Brunswick",
	//   "country": "Canada",
	// }
	access(all)
	struct FightData{ 
		access(all)
		let fightId: UInt32
		
		access(all)
		let fightName: String
		
		access(all)
		let cardSegment: String
		
		access(all)
		let weightClass: String
		
		access(all)
		let weightClassDescription: String
		
		access(all)
		let city: String
		
		access(all)
		let state: String
		
		access(all)
		let country: String
		
		init(fightId: UInt32, input:{ String: String}){ 
			pre{ 
				input["fightName"] != nil:
					"Key fightName required on FightData"
				input["cardSegment"] != nil:
					"Key cardSegment required on FightData"
				input["weightClass"] != nil:
					"Key weightClass required on FightData"
				input["weightClassDescription"] != nil:
					"Key weightClassDescription required on FightData"
				input["city"] != nil:
					"Key city required on FightData"
				input["state"] != nil:
					"Key state required on FightData"
				input["country"] != nil:
					"Key country required on FightData"
			}
			self.fightId = fightId
			self.fightName = input["fightName"]!
			self.cardSegment = input["cardSegment"]!
			self.weightClass = input["weightClass"]!
			self.weightClassDescription = input["weightClassDescription"]!
			self.city = input["city"]!
			self.state = input["state"]!
			self.country = input["country"]!
		}
	}
	
	//Should look like this
	// {  
	//   "setId": "1",
	//   "fightId": "7441",
	//   "fighterId": "5",
	//   "fighterName": "Test Oezdemir",
	//   "fightDescription": "Oezdemir faces Smith for the title",
	//   "thumbnail": "0",
	//   "mainAsset": "1",
	//   "opponentName": "Test Smith",
	//   "editionName": "Snapshot",
	//   "price": "5.75",
	//   "externalURL": "http://ufc292.oezdemir.strikenow.com"
	// }
	access(all)
	struct SetData{ 
		access(all)
		let setId: UInt32
		
		access(all)
		let seriesId: UInt32
		
		access(all)
		let editionName: String
		
		access(all)
		let price: UFix64
		
		access(all)
		let fightId: UInt32
		
		access(all)
		let thumbnail: UInt32
		
		access(all)
		let fighterName: String
		
		access(all)
		let fightDescription: String
		
		access(all)
		let opponentName: String
		
		access(all)
		let externalURL: String?
		
		access(all)
		let fightResult: FightResult?
		
		access(all)
		let assets:{ UInt32: AssetData}?
		
		access(all)
		let fightResultRaw:{ String: String}?
		
		access(all)
		let assetsRaw: [{String: String}]?
		
		access(all)
		let metadataRaw:{ String: String}
		
		init(
			setId: UInt32,
			seriesId: UInt32,
			metadata:{ 
				String: String
			},
			assets: [{
				
					String: String
				}
			]?,
			result:{ 
				String: String
			}?
		){ 
			pre{ 
				metadata["fightId"] != nil:
					"Key fightId required on SetData"
				metadata["editionName"] != nil:
					"Key editionName required on SetData"
				metadata["price"] != nil:
					"Key price required on SetData"
				metadata["thumbnail"] != nil:
					"Key thumbnail required on SetData"
				metadata["fighterName"] != nil:
					"Key fighterName required on SetData"
				metadata["fightDescription"] != nil:
					"Key fightDescription required on SetData"
				metadata["opponentName"] != nil:
					"Key opponentName required on SetData"
			}
			self.setId = setId
			self.seriesId = seriesId
			self.fightResultRaw = result
			self.assetsRaw = assets
			self.metadataRaw = metadata
			self.fightId = UInt32.fromString(metadata["fightId"]!)!
			self.editionName = metadata["editionName"]!
			self.price = UFix64.fromString(metadata["price"]!)!
			self.thumbnail = UInt32.fromString(metadata["thumbnail"]!)!
			self.fighterName = metadata["fighterName"]!
			self.fightDescription = metadata["fightDescription"]!
			self.opponentName = metadata["opponentName"]!
			self.externalURL = metadata["externalURL"]
			if assets != nil && assets?.length! > 0{ 
				let output:{ UInt32: AssetData} ={} 
				for asset in assets!{ 
					let id = UInt32.fromString(asset["assetId"]!)!
					output[id] = StrikeNowData.AssetData(assetId: id, rawData: asset)
				}
				self.assets = output
			} else{ 
				self.assets = nil
			}
			if result != nil && result?.length! > 0{ 
				self.fightResult = StrikeNowData.FightResult(input: result!)
			} else{ 
				self.fightResult = nil
			}
		}
	}
	
	// Should look like
	// {
	//   "assetURI": "https://testasset.com/assetOne",
	//   "assetFileType": "mp4",
	//   "assetId": "0"
	// }
	access(all)
	struct AssetData{ 
		access(all)
		let assetId: UInt32
		
		access(all)
		let assetURI: String
		
		access(all)
		let assetFileType: String
		
		access(all)
		let rawData:{ String: String}
		
		init(assetId: UInt32, rawData:{ String: String}){ 
			pre{ 
				rawData["assetURI"] != nil:
					"Key assetURI required on AssetData"
				rawData["assetFileType"] != nil:
					"Key assetFileType required on AssetData"
			}
			self.assetId = assetId
			self.rawData = rawData
			self.assetURI = rawData["assetURI"]!
			self.assetFileType = rawData["assetFileType"]!
		}
	}
	
	// Should look like this
	// {
	//   "outcome": "Win", //THIS MUST BE EITHER "Win" or "Lose"
	//   "grade": "Gold",
	//   "method": "Submission",
	//   "endingRound": "3",
	//   "endingTime": "1:24",
	//   "endingPosition":"From Back Control",
	//   "edingSubmission":"Rear Naked Choke",
	//   "wins": "32",
	//   "losses": "15",
	//   "draws": "0",
	//   "knockdowns": "0",
	//   "strikeAttempts": "45",
	//   "strikesLanded": "32",
	//   "significantStrikes": "3",
	//   "takedownAttempts": "5",
	//   "takedownsLanded": "2",
	//   "submissionAttempts": "3",
	// }
	access(all)
	struct FightResult{ 
		access(all)
		let outcome: String
		
		access(all)
		let won: Bool
		
		access(all)
		let grade: String
		
		access(all)
		let method: String
		
		access(all)
		let endingRound: UInt16
		
		access(all)
		let endingTime: String
		
		access(all)
		let endingStrike: String?
		
		access(all)
		let endingTarget: String?
		
		access(all)
		let endingPosition: String?
		
		access(all)
		let endingSubmission: String?
		
		access(all)
		let wins: UInt16
		
		access(all)
		let losses: UInt16
		
		access(all)
		let draws: UInt16
		
		access(all)
		let strikeAttempts: UInt16
		
		access(all)
		let strikesLanded: UInt16
		
		access(all)
		let significantStrikes: UInt16
		
		access(all)
		let takedownAttempts: UInt16
		
		access(all)
		let takedownsLanded: UInt16
		
		access(all)
		let submissionAttempts: UInt16
		
		access(all)
		let knockdowns: UInt16
		
		init(input:{ String: String}){ 
			pre{ 
				input["outcome"] != nil:
					"Got nil for outcome"
				input["grade"] != nil:
					"Key grade required on FightResult"
				input["method"] != nil:
					"Key method required on FightResult"
				input["endingRound"] != nil:
					"Key endingRound required on FightResult"
				input["endingTime"] != nil:
					"Key endingTime required on FightResult"
				input["wins"] != nil:
					"Key wins required on FightResult"
				input["losses"] != nil:
					"Key losses required on FightResult"
				input["draws"] != nil:
					"Key draws required on FightResult"
				input["strikeAttempts"] != nil:
					"Key strikeAttempts required on FightResult"
				input["strikesLanded"] != nil:
					"Key strikesLanded required on FightResult"
				input["significantStrikes"] != nil:
					"Key significantStrikes required on FightResult"
				input["takedownAttempts"] != nil:
					"Key takedownAttempts required on FightResult"
				input["takedownsLanded"] != nil:
					"Key takedownsLanded required on FightResult"
				input["submissionAttempts"] != nil:
					"Key submissionAttempts required on FightResult"
				input["knockdowns"] != nil:
					"Key knockdowns required on FightResult"
			}
			self.outcome = input["outcome"]!
			self.won = self.outcome.toLower() == "win" || self.outcome.toLower() == "won"
				|| self.outcome.toLower() == "victory"
			self.grade = input["grade"]!
			self.method = input["method"]!
			self.endingRound = UInt16.fromString(input["endingRound"]!)!
			self.endingTime = input["endingTime"]!
			self.endingStrike = input["endingStrike"]
			self.endingTarget = input["endingTarget"]
			self.endingPosition = input["endingPosition"]
			self.endingSubmission = input["endingSubmission"]
			self.wins = UInt16.fromString(input["wins"]!)!
			self.losses = UInt16.fromString(input["losses"]!)!
			self.draws = UInt16.fromString(input["draws"]!)!
			self.strikeAttempts = UInt16.fromString(input["strikeAttempts"]!)!
			self.strikesLanded = UInt16.fromString(input["strikesLanded"]!)!
			self.significantStrikes = UInt16.fromString(input["significantStrikes"]!)!
			self.takedownAttempts = UInt16.fromString(input["takedownAttempts"]!)!
			self.takedownsLanded = UInt16.fromString(input["takedownsLanded"]!)!
			self.submissionAttempts = UInt16.fromString(input["submissionAttempts"]!)!
			self.knockdowns = UInt16.fromString(input["knockdowns"]!)!
		}
	}
	
	//Should look like this
	// let input = {
	//   "collectionName": "UFC Strike Now",
	//   "collectionDescription": "UFC Strike Now: Commemorate The Fight. Win The Night.",
	//   "externalURL": "https://ufcstrike.com/now",
	//   "squareImageURL": "https://media.gigantik.io/ufc/square.png",
	//   "squareImageMediaType": "image/png",
	//   "bannerImageURL": "https://media.gigantik.io/ufc/banner.png",
	//   "bannerImageMediaType": "image/png"
	// }
	// let socials = {
	//   "instagram": "https://instagram.com/ufcstrike",
	//   "twitter": "https://twitter.com/UFCStrikeNFT",
	//   "discord": "https://discord.gg/UFCStrike"
	// }
	access(all)
	struct ConfigData{ 
		access(all)
		let collectionName: String
		
		access(all)
		let collectionDescription: String
		
		access(all)
		let externalURL: String
		
		access(all)
		let squareImageURL: String
		
		access(all)
		let squareImageMediaType: String
		
		access(all)
		let bannerImageURL: String
		
		access(all)
		let bannerImageMediaType: String
		
		access(all)
		let socials:{ String: String}
		
		init(input:{ String: String}, socials:{ String: String}){ 
			pre{ 
				input["collectionName"] != nil:
					"Key collectionName required on ConfigData"
				input["collectionDescription"] != nil:
					"Key collectionDescription required on ConfigData"
				input["externalURL"] != nil:
					"Key externalURL required on ConfigData"
				input["squareImageURL"] != nil:
					"Key squareImageURL required on ConfigData"
				input["squareImageMediaType"] != nil:
					"Key squareImageMediaType required on ConfigData"
				input["bannerImageURL"] != nil:
					"Key bannerImageURL required on ConfigData"
				input["bannerImageMediaType"] != nil:
					"Key bannerImageMediaType required on ConfigData"
			}
			self.collectionName = input["collectionName"]!
			self.collectionDescription = input["collectionDescription"]!
			self.externalURL = input["externalURL"]!
			self.squareImageURL = input["squareImageURL"]!
			self.squareImageMediaType = input["squareImageMediaType"]!
			self.bannerImageURL = input["bannerImageURL"]!
			self.bannerImageMediaType = input["bannerImageMediaType"]!
			self.socials = socials
		}
	}
	
	//Struct designed to capture a pending mint request along with the requester
	//address. Mints stores in format:
	//{
	//  SET_ID: AMOUNT_FROM_SET_TO_MINT  
	//}
	access(all)
	struct MintSet{ 
		access(all)
		var address: Address
		
		access(all)
		var setIdToAmountMap:{ UInt32: UInt32}
		
		init(address: Address, setIdToAmountMap:{ UInt32: UInt32}){ 
			self.address = address
			self.setIdToAmountMap = setIdToAmountMap
		}
		
		//Returns the number of mints expressed in the set
		access(all)
		view fun getAmountInSet(): UInt32{ 
			var amount: UInt32 = 0
			for set in self.setIdToAmountMap.keys{ 
				amount = amount + self.setIdToAmountMap[set]!
			}
			return amount
		}
		
		//Take a sequence of entries from the current mint set, removing them from the set
		//afterward. The format returned matches the format by which mint claims are 
		//submitted:
		//{
		//  SET_ID: AMOUNT_FROM_SET_TO_MINT  
		//}
		access(all)
		fun takeMintListAndDeplete(amountToTake: UInt32):{ UInt32: UInt32}{ 
			pre{ 
				amountToTake <= self.getAmountInSet():
					"Mint set does not have sufficient entries"
			}
			var amountRemaining = amountToTake
			let list:{ UInt32: UInt32} ={} 
			for set in self.setIdToAmountMap.keys{ 
				let amountCurrent = self.setIdToAmountMap[set]!
				if amountRemaining >= amountCurrent{ 
					list[set] = amountCurrent
					self.setIdToAmountMap[set] = 0
					amountRemaining = amountRemaining - amountCurrent
				} else{ 
					list[set] = amountRemaining
					self.setIdToAmountMap[set] = self.setIdToAmountMap[set]! - amountRemaining
					amountRemaining = 0
				}
				if amountRemaining == 0{ 
					break
				}
			}
			return list
		}
	}
}
