pub contract StrikeNowData {

  //Should look like:
  // {
  //   "seriesId": "1",
  //   "seriesName": "UFC 292 Oezdemir vs. Smith",
  //   "seriesDescription": "UFC 292 Inaugral Launch",
  //   "eventId": "890",
  //   "season": "1",
  //   "eventTime": "1691694054.0",
  // }
  pub struct SeriesData {
    pub let seriesId: UInt32
    pub let seriesName: String
    pub let seriesDescription: String
    pub let eventId: UInt32
    pub let eventTime: UFix64
    pub let season: String
    pub let fights: {UInt32: FightData}
    pub let metadataRaw: {String: String}
    pub let fightsRaw: [{String: String}]?

    init(seriesId: UInt32, metadata: {String: String}, fights: [{String: String}]?) {
      pre {
        metadata["seriesName"] != nil: "Key seriesName is required on SeriesData"
        metadata["seriesDescription"] != nil: "Key seriesDescription is required on SeriesData"
        metadata["eventId"] != nil: "Key eventId is required on SeriesData"
        metadata["season"] != nil: "Key season is required on SeriesData"
        metadata["eventTime"] != nil: "Key eventTime is required on SeriesData"
      }

      self.seriesId = seriesId
      self.seriesName = metadata["seriesName"]!      
      self.seriesDescription = metadata["seriesDescription"]!
      self.eventId = UInt32.fromString(metadata["eventId"]!)!
      self.season = metadata["season"]!
      self.eventTime = UFix64.fromString(metadata["eventTime"]!)!
      self.metadataRaw = metadata
      self.fightsRaw = fights
      self.fights = {}
      
      if fights != nil && fights?.length! > 0 {
        for fight in fights! {
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
  pub struct FightData {
    pub let fightId: UInt32
    pub let fightName: String
    pub let cardSegment: String
    pub let weightClass: String
    pub let weightClassDescription: String
    pub let city: String
    pub let state: String
    pub let country: String

    init(fightId: UInt32, input: {String: String})
    {
      pre {
        input["fightName"] != nil: "Key fightName required on FightData"
        input["cardSegment"] != nil: "Key cardSegment required on FightData"
        input["weightClass"] != nil: "Key weightClass required on FightData"
        input["weightClassDescription"] != nil: "Key weightClassDescription required on FightData"
        input["city"] != nil: "Key city required on FightData"
        input["state"] != nil: "Key state required on FightData"
        input["country"] != nil: "Key country required on FightData"
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
  pub struct SetData {
    pub let setId: UInt32
    pub let seriesId: UInt32
    pub let editionName: String
    pub let price: UFix64
    pub let fightId: UInt32
    pub let thumbnail: UInt32
    pub let fighterName: String
    pub let fightDescription: String
    pub let opponentName: String
    pub let externalURL: String?
    pub let fightResult: FightResult?
    pub let assets: {UInt32: AssetData}?
    pub let fightResultRaw: {String: String}?
    pub let assetsRaw: [{String: String}]?
    pub let metadataRaw: {String: String}

    init(
      setId: UInt32, 
      seriesId: UInt32, 
      metadata: {String: String}, 
      assets: [{String: String}]?, 
      result: {String: String}?) {

      pre {
        metadata["fightId"] != nil: "Key fightId required on SetData"
        metadata["editionName"] != nil: "Key editionName required on SetData"
        metadata["price"] != nil: "Key price required on SetData"
        metadata["thumbnail"] != nil: "Key thumbnail required on SetData"
        metadata["fighterName"] != nil: "Key fighterName required on SetData"
        metadata["fightDescription"] != nil: "Key fightDescription required on SetData"
        metadata["opponentName"] != nil: "Key opponentName required on SetData"
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
      
      if assets != nil && assets?.length! > 0 {
        let output: {UInt32: AssetData} = {}
        for asset in assets! {          
          let id = UInt32.fromString(asset["assetId"]!)!
          output[id] = StrikeNowData.AssetData(id, asset)
        }
        self.assets = output
      } else {
        self.assets = nil
      }

      if result != nil && result?.length! > 0 {   
        self.fightResult = StrikeNowData.FightResult(result!)
      } else {
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
  pub struct AssetData {
    pub let assetId: UInt32
    pub let assetURI: String
    pub let assetFileType: String
    pub let rawData: {String: String}

    init(assetId: UInt32, rawData: {String: String}) {
      pre {
        rawData["assetURI"] != nil: "Key assetURI required on AssetData"
        rawData["assetFileType"] != nil: "Key assetFileType required on AssetData"
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
  pub struct FightResult {
    pub let outcome: String
    pub let won: Bool
    pub let grade: String
    pub let method: String
    pub let endingRound: UInt16
    pub let endingTime: String
    pub let endingStrike: String?
    pub let endingTarget: String?
    pub let endingPosition: String?
    pub let endingSubmission: String?
    pub let wins: UInt16
    pub let losses: UInt16
    pub let draws: UInt16
    pub let strikeAttempts: UInt16
    pub let strikesLanded: UInt16
    pub let significantStrikes: UInt16
    pub let takedownAttempts: UInt16
    pub let takedownsLanded: UInt16
    pub let submissionAttempts: UInt16
    pub let knockdowns: UInt16

    init(input: {String: String}) {
      pre {
        input["outcome"] != nil: "Got nil for outcome"
        input["grade"] != nil: "Key grade required on FightResult"
        input["method"] != nil: "Key method required on FightResult"
        input["endingRound"] != nil: "Key endingRound required on FightResult"
        input["endingTime"] != nil: "Key endingTime required on FightResult"
        input["wins"] != nil: "Key wins required on FightResult"
        input["losses"] != nil: "Key losses required on FightResult"
        input["draws"] != nil: "Key draws required on FightResult"
        input["strikeAttempts"] != nil: "Key strikeAttempts required on FightResult"      
        input["strikesLanded"] != nil: "Key strikesLanded required on FightResult"
        input["significantStrikes"] != nil: "Key significantStrikes required on FightResult"     
        input["takedownAttempts"] != nil: "Key takedownAttempts required on FightResult"       
        input["takedownsLanded"] != nil: "Key takedownsLanded required on FightResult"      
        input["submissionAttempts"] != nil: "Key submissionAttempts required on FightResult"
        input["knockdowns"] != nil: "Key knockdowns required on FightResult"
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
  pub struct ConfigData {
    pub let collectionName: String
    pub let collectionDescription: String
    pub let externalURL: String
    pub let squareImageURL: String
    pub let squareImageMediaType: String
    pub let bannerImageURL: String
    pub let bannerImageMediaType: String
    pub let socials: { String: String }

    init(input: { String: String }, socials: { String: String }) {
      pre {
        input["collectionName"] != nil: "Key collectionName required on ConfigData"
        input["collectionDescription"] != nil: "Key collectionDescription required on ConfigData"
        input["externalURL"] != nil: "Key externalURL required on ConfigData"
        input["squareImageURL"] != nil: "Key squareImageURL required on ConfigData"
        input["squareImageMediaType"] != nil: "Key squareImageMediaType required on ConfigData"
        input["bannerImageURL"] != nil: "Key bannerImageURL required on ConfigData"
        input["bannerImageMediaType"] != nil: "Key bannerImageMediaType required on ConfigData"
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
  pub struct MintSet {
    pub var address: Address
    pub var setIdToAmountMap: { UInt32: UInt32 }

    init(address: Address, setIdToAmountMap: { UInt32: UInt32 }) {
      self.address = address
      self.setIdToAmountMap = setIdToAmountMap
    }

    //Returns the number of mints expressed in the set
    pub fun getAmountInSet(): UInt32 {
      var amount: UInt32 = 0
      for set in self.setIdToAmountMap.keys {
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
    pub fun takeMintListAndDeplete(amountToTake: UInt32): { UInt32: UInt32 } {
      pre {
        amountToTake <= self.getAmountInSet(): "Mint set does not have sufficient entries"
      }

      var amountRemaining = amountToTake
      let list: { UInt32: UInt32 } = {}
      for set in self.setIdToAmountMap.keys {
        let amountCurrent = self.setIdToAmountMap[set]!
        if amountRemaining >= amountCurrent {
          list[set] = amountCurrent
          self.setIdToAmountMap[set] = 0
          amountRemaining = amountRemaining - amountCurrent
        }
        else {
          list[set] = amountRemaining
          self.setIdToAmountMap[set] = self.setIdToAmountMap[set]! - amountRemaining
          amountRemaining = 0
        }
        
        if amountRemaining == 0 {
          break
        }
      }
      return list
    }
  }
}