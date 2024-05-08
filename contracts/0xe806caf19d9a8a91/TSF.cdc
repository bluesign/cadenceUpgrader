import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import TopShot from "../0x0b2a3299cc857e29/TopShot.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import HybridCustody from "../0xd8a7e05a7ac670c0/HybridCustody.cdc"

pub contract TSF {
    pub event ContractInitialized()

    pub event Minted(id: UInt64)

    pub event NFTDestroyed(id: UInt64)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let AdminStoragePath: StoragePath
    pub let AdminPrivatePath: PrivatePath

    pub var currentSeason: String
    pub var currentWeek: UInt8
    pub var isGameActive: Bool

    pub var totalSupply: UInt64
    pub var indexCounter: UInt64

    pub struct PowerUps {
        pub let score: Fix64
        pub let rebound: Fix64
        pub let assist: Fix64
        pub let block: Fix64
        pub let steal: Fix64
        pub let turnover: Fix64
        init() {
            self.score = 10.0
            self.rebound = 12.0
            self.assist = 15.0
            self.block = 30.0
            self.steal = 30.0
            self.turnover = -10.0
        }
    }

    pub struct SelectedPlayerInfo {
        pub let name: String
        pub let momentId: UInt64
        pub let momentImage: String
        pub let videoUrl: String
        pub let teamAtMoment: String
        pub let nbaTeamID : String
        init(name: String, momentId: UInt64, momentImage: String, videoUrl: String, teamAtMoment: String, nbaTeamID: String) {
            self.name = name
            self.momentId = momentId
            self.momentImage = momentImage
            self.videoUrl = videoUrl
            self.teamAtMoment = teamAtMoment
            self.nbaTeamID = nbaTeamID
        }
    }

    pub struct OwnedPlayerInfo {
        pub let fullname: String
        pub let momentUrl: String
        pub let nbaSeason: String
        pub let videoUrl: String
        pub let teamAtMoment: String
        pub let nbaTeamID : String
        init(fullname: String, nbaSeason: String, momentUrl: String, videoUrl: String, teamAtMoment: String, nbaTeamID: String) {
            self.fullname = fullname
            self.momentUrl = momentUrl
            self.nbaSeason = nbaSeason
            self.videoUrl = videoUrl
            self.teamAtMoment = teamAtMoment
            self.nbaTeamID = nbaTeamID
        }
    }

    // {season: {address: totalpoints}}
    pub var userTotalPoints: {String: {Address:Fix64}}
    // {season: {week: {address: totalpoints}}}
    pub var userWeeklyTotalPoints: {String:{UInt8:{Address:Fix64}}}
    // {season: {week: {address: true}}}
    pub var accountsParticipated: {String:{UInt8:{Address: Bool}}}
    // {season: {week: {momentId: PowerUps}}}
    pub var momentPowerUps:  {String:{UInt8:{UInt64: PowerUps}}}
    // {season: {week: {momentId: isUsed}}}
    pub var usedMomentIds:  {String:{UInt8:{UInt64: Bool}}}

    // --------------------------------------------------------------------- //

    pub fun mintNFT(
            recipientAcc: AuthAccount,
            momentIds: [UInt64],
        ) {

        if (!self.isGameActive) {
            panic("The Game is not yet active, wait for the admin to start the game")
        }
         

        if (!self.isAddressMintAuthorizedThisWeek(address: recipientAcc.address)) {
            panic("The user is not able to mint this week, an entry for this week has already been submitted")
        }

        // Check User Owns the TopShot moments at the time of submitting
        let userMoments: {UInt64: TSF.OwnedPlayerInfo} = self.getUserTopShotMoments(recipientAcc: recipientAcc, momentIdsToMint: momentIds)

        let depositRef: &AnyResource{TSF.TopShotCareerCollectionPublic} = recipientAcc.getCapability(TSF.CollectionPublicPath).borrow<&{TSF.TopShotCareerCollectionPublic}>()
            ?? panic("Could Not borrow Reference")

        var tempArr: [SelectedPlayerInfo] = []

        var countItems: UInt = 0
        var usedMomentIds: {UInt64:Bool} = {}

        for momentId in momentIds {
            countItems = countItems + 1
            if self.usedMomentIds[self.currentSeason]![self.currentWeek]![momentId] != nil {
                panic("Moment aready played this week! Moment: ".concat(momentId.toString()))
            }

            if userMoments[momentId] == nil {
                 panic("User does not own the moment. MomentId: ".concat(momentId.toString()))
            }

            let name: String = userMoments[momentId]!.fullname
            let image: String = userMoments[momentId]!.momentUrl
            let videoUrl: String = userMoments[momentId]!.videoUrl
            let teamAtMoment: String = userMoments[momentId]!.teamAtMoment
            let nbaTeamID: String = userMoments[momentId]!.nbaTeamID

            self.usedMomentIds[self.currentSeason]![self.currentWeek]!.insert(key: momentId, true)
            let temp: SelectedPlayerInfo = SelectedPlayerInfo(name: name, momentId: momentId, momentImage: image, videoUrl: videoUrl, teamAtMoment: teamAtMoment, nbaTeamID: nbaTeamID)
            tempArr.append(temp)
        }

        if countItems != 5  {
            panic("Player needs 5 moments to play, got: ".concat(countItems.toString()))
        }

        // deposit
        depositRef.deposit(token: <- create TSF.NFT(
            id: self.indexCounter,
            playerInfo: tempArr
        ))

        // Mark user as minted to only allow the user to mint once
        self.accountsParticipated[self.currentSeason]![self.currentWeek]!.insert(key: recipientAcc.address, true)
    }

    pub fun isAddressMintAuthorizedThisWeek(address: Address): Bool {
      let accountExistsForWeek: Bool = self.accountsParticipated[self.currentSeason]![self.currentWeek]![address] != nil

      if !accountExistsForWeek{
        return true
      }

      return self.accountsParticipated[self.currentSeason]![self.currentWeek]![address] == false
    }

    pub fun getUserTopShotMoments(recipientAcc: AuthAccount, momentIdsToMint: [UInt64]): {UInt64: OwnedPlayerInfo} {
        // Check current account for TopShot Moments
        let account: PublicAccount = getAccount(recipientAcc.address)
        let collectionRef = account.getCapability(/public/MomentCollection)!
            .borrow<&{TopShot.MomentCollectionPublic}>()

        let info: {UInt64: OwnedPlayerInfo} = {}

        if collectionRef != nil {
            let collRef = collectionRef!

             for mId in momentIdsToMint {
                let nft = collRef.borrowMoment(id: mId)
                if nft == nil {
                    continue
                }
                let metaData = nft!.resolveView(Type<TopShot.TopShotMomentMetadataView>())!
                let topShotMomentMetadata = (metaData! as? TopShot.TopShotMomentMetadataView)!

                let display = (nft!.resolveView(Type<MetadataViews.Display>())! as? MetadataViews.Display)!
                let thumbnail = (display.thumbnail as? MetadataViews.HTTPFile)!
                let url = thumbnail.url

                let videoUrl = nft!.video()
                let nbaTeamID: String = topShotMomentMetadata!.teamAtMomentNBAID!
                let teamAtMoment: String = topShotMomentMetadata!.teamAtMoment!

                if (topShotMomentMetadata!.fullName != nil && topShotMomentMetadata!.nbaSeason != nil) {
                    info[mId] = OwnedPlayerInfo(fullname: topShotMomentMetadata!.fullName!, nbaSeason: topShotMomentMetadata!.nbaSeason!, momentUrl: url, videoUrl: videoUrl, teamAtMoment: teamAtMoment, nbaTeamID: nbaTeamID)
                }        
            }
        }
                
        // // Check any child account for TopShot Moments
        let manager = recipientAcc.borrow<&HybridCustody.Manager>(from: HybridCustody.ManagerStoragePath)

        if manager == nil {
            return info
        }

        for address in manager!.getChildAddresses() {

            let account: PublicAccount = getAccount(address)

            let collectionRef = account.getCapability(/public/MomentCollection)!
                .borrow<&{TopShot.MomentCollectionPublic}>()

            if collectionRef != nil {
                let collRef = collectionRef!

                for mId in momentIdsToMint {
                    let nft = collRef.borrowMoment(id: mId)
                    if nft == nil {
                        continue
                    }
                    let metaData = nft!.resolveView(Type<TopShot.TopShotMomentMetadataView>())!
                    let topShotMomentMetadata = (metaData! as? TopShot.TopShotMomentMetadataView)!

                    let display = (nft!.resolveView(Type<MetadataViews.Display>())! as? MetadataViews.Display)!
                    let thumbnail = (display.thumbnail as? MetadataViews.HTTPFile)!
                    let url = thumbnail.url

                    let videoUrl = nft!.video()
                    let nbaTeamID: String = topShotMomentMetadata!.teamAtMomentNBAID!
                    let teamAtMoment: String = topShotMomentMetadata!.teamAtMoment!

                    if (topShotMomentMetadata!.fullName != nil && topShotMomentMetadata!.nbaSeason != nil) {
                        info[mId] = OwnedPlayerInfo(fullname: topShotMomentMetadata!.fullName!, nbaSeason: topShotMomentMetadata!.nbaSeason!, momentUrl: url, videoUrl: videoUrl, teamAtMoment: teamAtMoment, nbaTeamID: nbaTeamID)
                    }       
                }
            }
        }

        return info
    }


    pub resource NFT : NonFungibleToken.INFT {
        pub let id: UInt64
        pub let playerInfo: [SelectedPlayerInfo]
        pub let seasonYear: String
        pub let seasonWeek: UInt8

        init(id: UInt64, playerInfo: [SelectedPlayerInfo]) {
            TSF.totalSupply = TSF.totalSupply + 1
            TSF.indexCounter = TSF.indexCounter + 1
            self.id = id
            self.playerInfo = playerInfo
            self.seasonYear = TSF.currentSeason
            self.seasonWeek = TSF.currentWeek
        }

        pub fun getViews(): [Type] {
            return []
        }

        pub fun getPlayerInfo(): [SelectedPlayerInfo] {
            return self.playerInfo
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            return nil
        }

        destroy() {
            TSF.totalSupply = TSF.totalSupply - 1
            emit NFTDestroyed(id: self.id)
        }
    }

    pub resource Admin {
        pub fun setGameActive() {
            TSF.isGameActive = true
        }

        pub fun setGameInactive() {
            TSF.isGameActive = false
        }

        pub fun setGameSeason(newSeason: String) {
            TSF.currentSeason = newSeason
            TSF.currentWeek = 1
            TSF.accountsParticipated.insert(key: TSF.currentSeason, {TSF.currentWeek: {}})
            TSF.usedMomentIds.insert(key:  TSF.currentSeason, {TSF.currentWeek: {}})
            TSF.userWeeklyTotalPoints.insert(key: TSF.currentSeason, {TSF.currentWeek: {}})
            TSF.userTotalPoints.insert(key: TSF.currentSeason, {})
        }

        pub fun setGameWeek(newWeek: UInt8) {
            TSF.currentWeek = newWeek
            TSF.accountsParticipated[TSF.currentSeason]!.insert(key:TSF.currentWeek, {})
            TSF.usedMomentIds.insert(key: TSF.currentSeason, {TSF.currentWeek: {}})
            TSF.userWeeklyTotalPoints[TSF.currentSeason]!.insert(key:TSF.currentWeek, {})
        }

        pub fun setPlayerWeeklyScore(season: String, week: UInt8, userAddr: Address, scores: [{String: Fix64}]) {
            var totalAssists: Fix64 = 0.0 
            var totalTurnOvers: Fix64 = 0.0 
            var totalSteals: Fix64 = 0.0 
            var totalBlocks: Fix64 = 0.0 
            var totalPoints: Fix64 = 0.0 
            var totalRebounds: Fix64 = 0.0 

            for score in scores {
                if let assists: Fix64 = score["assists"] {
                    totalAssists = totalAssists + assists
                }

                if let turnovers: Fix64 = score["turnovers"] {
                    totalTurnOvers = totalTurnOvers + turnovers
                }

                if let steals: Fix64 = score["steals"] {
                    totalSteals = totalSteals + steals
                }

                if let blocks: Fix64 = score["blocks"] {
                    totalBlocks = totalBlocks + blocks
                }

                if let points: Fix64 = score["points"] {
                    totalPoints = totalPoints + points
                }

                if let rebounds: Fix64 = score["rebounds"] {
                    totalRebounds = totalRebounds + rebounds
                }
            }

            // This was a mistake, these are point multiplers, but was named for powerups
            let multiplers: TSF.PowerUps = PowerUps()
            let totalAssistsScore: Fix64 = totalAssists * multiplers.assist
            let totalTurnOverScore: Fix64 = totalTurnOvers * multiplers.turnover
            let totalStealScore: Fix64 = totalSteals * multiplers.steal
            let totalBlockScore: Fix64 = totalBlocks * multiplers.block
            let totalPointsScore: Fix64 = totalPoints * multiplers.score
            let totalReboundScore: Fix64 = totalRebounds * multiplers.rebound

            let totalWeeklyScore: Fix64 = totalAssistsScore + totalTurnOverScore + totalStealScore + totalBlockScore + totalPointsScore + totalReboundScore

            // Upsert the weekly score for the user, returns the currently set socre if we need to update it
            if TSF.userWeeklyTotalPoints[season]!.containsKey(week) == false {
                TSF.userWeeklyTotalPoints[season]!.insert(key: week, {})
            }

            let previousWeeklyVal: Fix64? = TSF.userWeeklyTotalPoints[season]![week]!.insert(key: userAddr, totalWeeklyScore)


            // Start calculating the total Season Score
            var newTotal: Fix64 = 0.0

            let prevSeasonTotal: Fix64? = TSF.userTotalPoints[season]![userAddr]

            if prevSeasonTotal != nil {
                newTotal = prevSeasonTotal!
            }

            // If a score was already set for the week, we need to subtract it from the Season total
            if previousWeeklyVal != nil {
                newTotal = newTotal - previousWeeklyVal!
            }

            newTotal = newTotal + totalWeeklyScore

            // Upsert the new total for the season
            TSF.userTotalPoints[season]!.insert(key: userAddr, newTotal)
        }

        pub fun createNewAdmin(): @Admin {
            return <- create Admin()
        }
    }

    pub resource interface TopShotCareerCollectionPublic {
        pub fun deposit(token: @TSF.NFT)
        pub fun getIDs(): [UInt64]
        pub fun withdraw(withdrawID: UInt64): @TSF.NFT
        pub fun borrowTopShotCareerNFT(id: UInt64): &TSF.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow NFT reference: The ID of the returned reference is incorrect"
            }
        }
    }


        // The definition of the Collection resource that
    // holds the NFTs that a user owns
    pub resource Collection: TopShotCareerCollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NFT}

        // Initialize the NFTs field to an empty collection
        init () {
            self.ownedNFTs <- {}
        }

        pub fun borrowTopShotCareerNFT(id: UInt64): &TSF.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref: &TSF.NFT = (&self.ownedNFTs[id] as &TSF.NFT?)!
                return ref
            }
            return nil
        }

        // withdraw
        //
        // Function that removes an NFT from the collection
        // and moves it to the calling context
        pub fun withdraw(withdrawID: UInt64): @NFT {
            // If the NFT isn't found, the transaction panics and reverts
            let token: @TSF.NFT <- self.ownedNFTs.remove(key: withdrawID)!

            return <-token
        }

        // deposit
        //
        // Function that takes a NFT as an argument and
        // adds it to the collections dictionary
        pub fun deposit(token: @TSF.NFT) {
            // add the new token to the dictionary with a force assignment
            // if there is already a value at that key, it will fail and revert
            self.ownedNFTs[token.id] <-! token
        }

        // idExists checks to see if a NFT
        // with the given ID exists in the collection
        pub fun idExists(id: UInt64): Bool {
            return self.ownedNFTs[id] != nil
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // create a new collection
    pub fun createEmptyCollection(): @Collection {
        return <- create Collection()
    }

    init() {
        self.currentSeason = "2022-23"
        self.currentWeek = 1
        self.isGameActive = true

        self.accountsParticipated = {self.currentSeason: {self.currentWeek: {}}}
        self.userWeeklyTotalPoints = {self.currentSeason: {self.currentWeek: {}}}
        self.userTotalPoints = {self.currentSeason: {}}
        self.momentPowerUps = {self.currentSeason: {self.currentWeek: {}}}
        self.usedMomentIds = {self.currentSeason: {self.currentWeek: {}}}


        self.CollectionStoragePath = /storage/TSFCollection
        self.CollectionPublicPath = /public/TSFCollection
        self.AdminPrivatePath = /private/TSFAdmin
        self.AdminStoragePath = /storage/TSFAdmin

        self.totalSupply = 0
        self.indexCounter = 1

        // store an empty NFT Collection in account storage
        self.account.save(<-self.createEmptyCollection(), to: self.CollectionStoragePath)

        // publish a reference to the Collection in storage
        self.account.link<&{TopShotCareerCollectionPublic}>(self.CollectionPublicPath, target: self.CollectionStoragePath)

        self.account.save(<-create Admin(), to: self.AdminStoragePath)

        self.account.link<&TSF.Admin>(
            self.AdminPrivatePath,
            target: self.AdminStoragePath
        ) ?? panic("Could not get a capability to the admin")
	}
}