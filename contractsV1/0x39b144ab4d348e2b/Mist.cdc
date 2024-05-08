// Made by Lanford33
//
// Mist.cdc defines the NFT Raffle and the collections of it.
//
// There are 4 stages in a NFT Raffle. 
// 1. You create a new NFT Raffle by setting the basic information, depositing NFTs and setting the criteria for eligible accounts, then share the Raffle link to your community;
// 2. Community members go to the Raffle page, check their eligibility and register for the Raffle if they are eligible;
// 3. Once the registration end, you can draw the winners. For each draw, a winner will be selected randomly from registrants, and an NFT will be picked out randomly from NFTs in the Raffle as the reward for winner;
// 4. Registrants go to the Raffle page to check whether they are winners or not, and claim the reward if they are.
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import EligibilityVerifiers from "./EligibilityVerifiers.cdc"

import DrizzleRecorder from "./DrizzleRecorder.cdc"

access(all)
contract Mist{ 
	access(all)
	let MistAdminStoragePath: StoragePath
	
	access(all)
	let MistAdminPublicPath: PublicPath
	
	access(all)
	let MistAdminPrivatePath: PrivatePath
	
	access(all)
	let RaffleCollectionStoragePath: StoragePath
	
	access(all)
	let RaffleCollectionPublicPath: PublicPath
	
	access(all)
	let RaffleCollectionPrivatePath: PrivatePath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event RaffleCreated(
		raffleID: UInt64,
		name: String,
		host: Address,
		description: String,
		nftIdentifier: String
	)
	
	access(all)
	event RaffleRegistered(
		raffleID: UInt64,
		name: String,
		host: Address,
		registrator: Address,
		nftIdentifier: String
	)
	
	access(all)
	event RaffleWinnerDrawn(
		raffleID: UInt64,
		name: String,
		host: Address,
		winner: Address,
		nftIdentifier: String,
		tokenIDs: [
			UInt64
		]
	)
	
	access(all)
	event RaffleClaimed(
		raffleID: UInt64,
		name: String,
		host: Address,
		claimer: Address,
		nftIdentifier: String,
		tokenIDs: [
			UInt64
		]
	)
	
	access(all)
	event RafflePaused(raffleID: UInt64, name: String, host: Address)
	
	access(all)
	event RaffleUnpaused(raffleID: UInt64, name: String, host: Address)
	
	access(all)
	event RaffleEnded(raffleID: UInt64, name: String, host: Address)
	
	access(all)
	event RaffleDestroyed(raffleID: UInt64, name: String, host: Address)
	
	access(all)
	enum AvailabilityStatus: UInt8{ 
		access(all)
		case notStartYet
		
		access(all)
		case ended
		
		access(all)
		case registering
		
		access(all)
		case drawing
		
		access(all)
		case drawn
		
		access(all)
		case expired
		
		access(all)
		case paused
	}
	
	access(all)
	struct Availability{ 
		access(all)
		let status: AvailabilityStatus
		
		access(all)
		let extraData:{ String: AnyStruct}
		
		init(status: AvailabilityStatus, extraData:{ String: AnyStruct}){ 
			self.status = status
			self.extraData = extraData
		}
		
		access(all)
		fun getStatus(): String{ 
			switch self.status{ 
				case AvailabilityStatus.notStartYet:
					return "not start yet"
				case AvailabilityStatus.ended:
					return "ended"
				case AvailabilityStatus.registering:
					return "registering"
				case AvailabilityStatus.drawing:
					return "drawing"
				case AvailabilityStatus.drawn:
					return "drawn"
				case AvailabilityStatus.expired:
					return "expired"
				case AvailabilityStatus.paused:
					return "paused"
			}
			panic("invalid status")
		}
	}
	
	access(all)
	enum EligibilityStatus: UInt8{ 
		access(all)
		case eligibleForRegistering
		
		access(all)
		case eligibleForClaiming
		
		access(all)
		case notEligibleForRegistering
		
		access(all)
		case notEligibleForClaiming
		
		access(all)
		case hasRegistered
		
		access(all)
		case hasClaimed
	}
	
	access(all)
	struct Eligibility{ 
		access(all)
		let status: EligibilityStatus
		
		access(all)
		let eligibleNFTs: [UInt64]
		
		access(all)
		let extraData:{ String: AnyStruct}
		
		init(status: EligibilityStatus, eligibleNFTs: [UInt64], extraData:{ String: AnyStruct}){ 
			self.status = status
			self.eligibleNFTs = eligibleNFTs
			self.extraData = extraData
		}
		
		access(all)
		fun getStatus(): String{ 
			switch self.status{ 
				case EligibilityStatus.eligibleForRegistering:
					return "eligible for registering"
				case EligibilityStatus.eligibleForClaiming:
					return "eligible for claiming"
				case EligibilityStatus.notEligibleForRegistering:
					return "not eligible for registering"
				case EligibilityStatus.notEligibleForClaiming:
					return "not eligible for claiming"
				case EligibilityStatus.hasRegistered:
					return "has registered"
				case EligibilityStatus.hasClaimed:
					return "has claimed"
			}
			panic("invalid status")
		}
	}
	
	// We want to get the thumbnail uri directly from Raffle
	// so we define NFTDisplay rather than use MetadataViews.Display
	// due to lack of extraData field, we use description to store rarityDescription
	// temporarily
	access(all)
	struct NFTDisplay{ 
		access(all)
		let tokenID: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		init(tokenID: UInt64, name: String, description: String, thumbnail: String){ 
			self.tokenID = tokenID
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
		}
	}
	
	access(all)
	struct RegistrationRecord{ 
		access(all)
		let address: Address
		
		access(all)
		let extraData:{ String: AnyStruct}
		
		init(address: Address, extraData:{ String: AnyStruct}){ 
			self.address = address
			self.extraData = extraData
		}
	}
	
	access(all)
	struct WinnerRecord{ 
		access(all)
		let address: Address
		
		access(all)
		let rewardTokenIDs: [UInt64]
		
		access(all)
		let extraData:{ String: AnyStruct}
		
		access(all)
		var isClaimed: Bool
		
		access(contract)
		fun markAsClaimed(){ 
			self.isClaimed = true
			self.extraData["claimedAt"] = getCurrentBlock().timestamp
		}
		
		init(address: Address, rewardTokenIDs: [UInt64], extraData:{ String: AnyStruct}){ 
			self.address = address
			self.rewardTokenIDs = rewardTokenIDs
			self.extraData = extraData
			self.isClaimed = false
		}
	}
	
	access(all)
	struct NFTInfo{ 
		access(all)
		let name: String
		
		access(all)
		let nftType: Type
		
		access(all)
		let contractName: String
		
		access(all)
		let contractAddress: Address
		
		access(all)
		let collectionType: Type
		
		access(all)
		let collectionLogoURL: String
		
		access(all)
		let collectionStoragePath: StoragePath
		
		access(all)
		let collectionPublicPath: PublicPath
		
		init(
			name: String,
			nftType: Type,
			contractName: String,
			contractAddress: Address,
			collectionType: Type,
			collectionLogoURL: String,
			collectionStoragePath: StoragePath,
			collectionPublicPath: PublicPath
		){ 
			self.name = name
			self.nftType = nftType
			self.contractName = contractName
			self.contractAddress = contractAddress
			self.collectionType = collectionType
			self.collectionLogoURL = collectionLogoURL
			self.collectionStoragePath = collectionStoragePath
			self.collectionPublicPath = collectionPublicPath
		}
	}
	
	access(all)
	resource interface IRafflePublic{ 
		access(all)
		let raffleID: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let host: Address
		
		access(all)
		let createdAt: UFix64
		
		access(all)
		let image: String?
		
		access(all)
		let url: String?
		
		access(all)
		let startAt: UFix64?
		
		access(all)
		let endAt: UFix64?
		
		access(all)
		let registrationEndAt: UFix64
		
		access(all)
		let numberOfWinners: UInt64
		
		access(all)
		let nftInfo: NFTInfo
		
		access(all)
		let registrationVerifyMode: EligibilityVerifiers.VerifyMode
		
		access(all)
		let claimVerifyMode: EligibilityVerifiers.VerifyMode
		
		access(all)
		var isPaused: Bool
		
		access(all)
		var isEnded: Bool
		
		access(all)
		let extraData:{ String: AnyStruct}
		
		access(all)
		fun register(account: Address, params:{ String: AnyStruct})
		
		access(all)
		fun hasRegistered(account: Address): Bool
		
		access(all)
		fun getRegistrationRecords():{ Address: RegistrationRecord}
		
		access(all)
		fun getRegistrationRecord(account: Address): RegistrationRecord?
		
		access(all)
		fun getWinners():{ Address: WinnerRecord}
		
		access(all)
		fun getWinner(account: Address): WinnerRecord?
		
		access(all)
		fun claim(receiver: &{NonFungibleToken.CollectionPublic}, params:{ String: AnyStruct})
		
		access(all)
		fun checkAvailability(params:{ String: AnyStruct}): Availability
		
		access(all)
		fun checkRegistrationEligibility(account: Address, params:{ String: AnyStruct}): Eligibility
		
		access(all)
		fun checkClaimEligibility(account: Address, params:{ String: AnyStruct}): Eligibility
		
		access(all)
		fun getRegistrationVerifiers():{ String: [{EligibilityVerifiers.IEligibilityVerifier}]}
		
		access(all)
		fun getClaimVerifiers():{ String: [{EligibilityVerifiers.IEligibilityVerifier}]}
		
		access(all)
		fun getRewardDisplays():{ UInt64: NFTDisplay}
	}
	
	access(all)
	resource Raffle: IRafflePublic{ 
		access(all)
		let raffleID: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let host: Address
		
		access(all)
		let createdAt: UFix64
		
		access(all)
		let image: String?
		
		access(all)
		let url: String?
		
		access(all)
		let startAt: UFix64?
		
		access(all)
		let endAt: UFix64?
		
		access(all)
		let registrationEndAt: UFix64
		
		access(all)
		let numberOfWinners: UInt64
		
		access(all)
		let nftInfo: NFTInfo
		
		access(all)
		let registrationVerifyMode: EligibilityVerifiers.VerifyMode
		
		access(all)
		let claimVerifyMode: EligibilityVerifiers.VerifyMode
		
		access(all)
		var isPaused: Bool
		
		// After a Raffle ended, it can't be recovered.
		access(all)
		var isEnded: Bool
		
		access(all)
		let extraData:{ String: AnyStruct}
		
		// Check an account is eligible for registration or not
		access(account)
		let registrationVerifiers:{ String: [{EligibilityVerifiers.IEligibilityVerifier}]}
		
		// Check a winner account is eligible for claiming the reward or not
		// This is mainly used to allow the host add some extra requirements to the winners
		access(account)
		let claimVerifiers:{ String: [{EligibilityVerifiers.IEligibilityVerifier}]}
		
		access(self)
		let collection: @{NonFungibleToken.Collection}
		
		// The information of registrants
		access(self)
		let registrationRecords:{ Address: RegistrationRecord}
		
		// The information of winners
		access(self)
		let winners:{ Address: WinnerRecord}
		
		// Candidates stores the accounts of registrants. It's a helper field to make drawing easy
		access(self)
		let candidates: [Address]
		
		// nftToBeDrawn stores the tokenIDs of undrawn NFTs. It's a helper field to make drawing easy
		access(self)
		let nftToBeDrawn: [UInt64]
		
		// rewardDisplays stores the Display of NFTs added to this Raffle. Once an NFT added as reward, the Display will be recorded here.
		// No item will be deleted from this field.
		access(self)
		let rewardDisplays:{ UInt64: NFTDisplay}
		
		access(all)
		fun register(account: Address, params:{ String: AnyStruct}){ 
			params.insert(key: "recordUsedNFT", true)
			let availability = self.checkAvailability(params: params)
			assert(availability.status == AvailabilityStatus.registering, message: availability.getStatus())
			let eligibility = self.checkRegistrationEligibility(account: account, params: params)
			assert(eligibility.status == EligibilityStatus.eligibleForRegistering, message: eligibility.getStatus())
			emit RaffleRegistered(raffleID: self.raffleID, name: self.name, host: self.host, registrator: account, nftIdentifier: self.nftInfo.nftType.identifier)
			self.registrationRecords[account] = RegistrationRecord(address: account, extraData:{} )
			self.candidates.append(account)
			if let recorderRef = params["recorderRef"]{ 
				let _recorderRef = recorderRef as! &DrizzleRecorder.Recorder
				_recorderRef.insertOrUpdateRecord(DrizzleRecorder.MistRaffle(raffleID: self.raffleID, host: self.host, name: self.name, nftName: self.nftInfo.name, registeredAt: getCurrentBlock().timestamp, extraData:{} ))
			}
		}
		
		access(all)
		fun hasRegistered(account: Address): Bool{ 
			return self.registrationRecords[account] != nil
		}
		
		access(all)
		fun getRegistrationRecords():{ Address: RegistrationRecord}{ 
			return self.registrationRecords
		}
		
		access(all)
		fun getRegistrationRecord(account: Address): RegistrationRecord?{ 
			return self.registrationRecords[account]
		}
		
		access(all)
		fun getWinners():{ Address: WinnerRecord}{ 
			return self.winners
		}
		
		access(all)
		fun getWinner(account: Address): WinnerRecord?{ 
			return self.winners[account]
		}
		
		access(all)
		fun claim(receiver: &{NonFungibleToken.CollectionPublic}, params:{ String: AnyStruct}){ 
			params.insert(key: "recordUsedNFT", true)
			let availability = self.checkAvailability(params: params)
			assert(availability.status == AvailabilityStatus.drawn || availability.status == AvailabilityStatus.drawing, message: availability.getStatus())
			let claimer = (receiver.owner!).address
			let eligibility = self.checkClaimEligibility(account: claimer, params: params)
			assert(eligibility.status == EligibilityStatus.eligibleForClaiming, message: eligibility.getStatus())
			(self.winners[claimer]!).markAsClaimed()
			let winnerRecord = self.winners[claimer]!
			emit RaffleClaimed(raffleID: self.raffleID, name: self.name, host: self.host, claimer: claimer, nftIdentifier: self.nftInfo.nftType.identifier, tokenIDs: winnerRecord.rewardTokenIDs)
			if let recorderRef = params["recorderRef"]{ 
				let _recorderRef = recorderRef as! &DrizzleRecorder.Recorder
				if let record = _recorderRef.getRecord(type: Type<DrizzleRecorder.MistRaffle>(), uuid: self.raffleID){ 
					let _record = record as! DrizzleRecorder.MistRaffle
					_record.markAsClaimed(rewardTokenIDs: winnerRecord.rewardTokenIDs, extraData:{} )
					_recorderRef.insertOrUpdateRecord(_record)
				}
			}
			for tokenID in winnerRecord.rewardTokenIDs{ 
				let nft <- self.collection.withdraw(withdrawID: tokenID)
				receiver.deposit(token: <-nft)
			}
		}
		
		access(all)
		fun checkAvailability(params:{ String: AnyStruct}): Availability{ 
			if self.isEnded{ 
				return Availability(status: AvailabilityStatus.ended, extraData:{} )
			}
			if let startAt = self.startAt{ 
				if getCurrentBlock().timestamp < startAt{ 
					return Availability(status: AvailabilityStatus.notStartYet, extraData:{} )
				}
			}
			if let endAt = self.endAt{ 
				if getCurrentBlock().timestamp > endAt{ 
					return Availability(status: AvailabilityStatus.expired, extraData:{} )
				}
			}
			if self.isPaused{ 
				return Availability(status: AvailabilityStatus.paused, extraData:{} )
			}
			assert(UInt64(self.winners.keys.length) <= self.numberOfWinners, message: "invalid winners")
			if UInt64(self.winners.keys.length) == self.numberOfWinners{ 
				return Availability(status: AvailabilityStatus.drawn, extraData:{} )
			}
			if getCurrentBlock().timestamp > self.registrationEndAt{ 
				if self.candidates.length == 0{ 
					return Availability(status: AvailabilityStatus.drawn, extraData:{} )
				}
				return Availability(status: AvailabilityStatus.drawing, extraData:{} )
			}
			return Availability(status: AvailabilityStatus.registering, extraData:{} )
		}
		
		access(all)
		fun checkRegistrationEligibility(account: Address, params:{ String: AnyStruct}): Eligibility{ 
			if let record = self.registrationRecords[account]{ 
				return Eligibility(status: EligibilityStatus.hasRegistered, eligibleNFTs: [], extraData:{} )
			}
			let isEligible = self.isEligible(account: account, mode: self.registrationVerifyMode, verifiers: &self.registrationVerifiers as &{String: [{EligibilityVerifiers.IEligibilityVerifier}]}, params: params)
			return Eligibility(status: isEligible ? EligibilityStatus.eligibleForRegistering : EligibilityStatus.notEligibleForRegistering, eligibleNFTs: [], extraData:{} )
		}
		
		access(all)
		fun checkClaimEligibility(account: Address, params:{ String: AnyStruct}): Eligibility{ 
			if self.winners[account] == nil{ 
				return Eligibility(status: EligibilityStatus.notEligibleForClaiming, eligibleNFTs: [], extraData:{} )
			}
			let record = self.winners[account]!
			if record.isClaimed{ 
				return Eligibility(status: EligibilityStatus.hasClaimed, eligibleNFTs: record.rewardTokenIDs, extraData:{} )
			}
			
			// Raffle host can add extra requirements to the winners for claiming the NFTs
			// by adding claimVerifiers
			let isEligible = self.isEligible(account: account, mode: self.claimVerifyMode, verifiers: &self.claimVerifiers as &{String: [{EligibilityVerifiers.IEligibilityVerifier}]}, params: params)
			return Eligibility(status: isEligible ? EligibilityStatus.eligibleForClaiming : EligibilityStatus.notEligibleForClaiming, eligibleNFTs: record.rewardTokenIDs, extraData:{} )
		}
		
		access(all)
		fun getRegistrationVerifiers():{ String: [{EligibilityVerifiers.IEligibilityVerifier}]}{ 
			return self.registrationVerifiers
		}
		
		access(all)
		fun getClaimVerifiers():{ String: [{EligibilityVerifiers.IEligibilityVerifier}]}{ 
			return self.claimVerifiers
		}
		
		access(all)
		fun getRewardDisplays():{ UInt64: NFTDisplay}{ 
			return self.rewardDisplays
		}
		
		access(self)
		fun isEligible(account: Address, mode: EligibilityVerifiers.VerifyMode, verifiers: &{String: [{EligibilityVerifiers.IEligibilityVerifier}]}, params:{ String: AnyStruct}): Bool{ 
			params.insert(key: "claimer", account)
			var recordUsedNFT = false
			if let _recordUsedNFT = params["recordUsedNFT"]{ 
				recordUsedNFT = _recordUsedNFT as! Bool
			}
			if mode == EligibilityVerifiers.VerifyMode.oneOf{ 
				for identifier in verifiers.keys{ 
					let _verifiers = &verifiers[identifier]! as &[{EligibilityVerifiers.IEligibilityVerifier}]?
					var counter = 0
					while counter < _verifiers.length{ 
						let result = _verifiers[counter].verify(account: account, params: params)
						if result.isEligible{ 
							if recordUsedNFT{ 
								if let v = _verifiers[counter] as?{ EligibilityVerifiers.INFTRecorder}{ 
									(_verifiers[counter] as!{ EligibilityVerifiers.INFTRecorder}).addUsedNFTs(account: account, nftTokenIDs: result.usedNFTs)
								}
							}
							return true
						}
						counter = counter + 1
					}
				}
				return false
			}
			if mode == EligibilityVerifiers.VerifyMode.all{ 
				let tempUsedNFTs:{ String:{ UInt64: [UInt64]}} ={} 
				for identifier in verifiers.keys{ 
					let _verifiers = &verifiers[identifier]! as &[{EligibilityVerifiers.IEligibilityVerifier}]?
					var counter: UInt64 = 0
					while counter < UInt64(_verifiers.length){ 
						let result = _verifiers[counter].verify(account: account, params: params)
						if !result.isEligible{ 
							return false
						}
						if recordUsedNFT && result.usedNFTs.length > 0{ 
							if tempUsedNFTs[identifier] == nil{ 
								let v:{ UInt64: [UInt64]} ={} 
								tempUsedNFTs[identifier] = v
							}
							(tempUsedNFTs[identifier]! as!{ UInt64: [UInt64]}).insert(key: counter, result.usedNFTs)
						}
						counter = counter + 1
					}
				}
				if recordUsedNFT{ 
					for identifier in tempUsedNFTs.keys{ 
						let usedNFTsInfo = tempUsedNFTs[identifier]!
						let _verifiers = &verifiers[identifier]! as &[{EligibilityVerifiers.IEligibilityVerifier}]?
						for index in usedNFTsInfo.keys{ 
							(_verifiers[index] as!{ EligibilityVerifiers.INFTRecorder}).addUsedNFTs(account: account, nftTokenIDs: usedNFTsInfo[index]!)
						}
					}
				}
				return true
			}
			panic("invalid mode: ".concat(mode.rawValue.toString()))
		}
		
		access(all)
		fun draw(params:{ String: AnyStruct}){ 
			let availability = self.checkAvailability(params: params)
			assert(availability.status == AvailabilityStatus.drawing, message: availability.getStatus())
			let capacity = self.numberOfWinners - UInt64(self.winners.keys.length)
			let upperLimit = capacity > UInt64(self.candidates.length) ? UInt64(self.candidates.length) : capacity
			assert(UInt64(self.nftToBeDrawn.length) >= upperLimit, message: "nft is not enough")
			let winnerIndex = revertibleRandom<UInt64>() % UInt64(self.candidates.length)
			let winner = self.candidates[winnerIndex]
			assert(self.winners[winner] == nil, message: "winner already recorded")
			let rewardIndex = revertibleRandom<UInt64>() % UInt64(self.nftToBeDrawn.length)
			let rewardTokenID = self.nftToBeDrawn[rewardIndex]
			let winnerRecord = WinnerRecord(address: winner, rewardTokenIDs: [rewardTokenID], extraData:{} )
			self.winners[winner] = winnerRecord
			self.candidates.remove(at: winnerIndex)
			self.nftToBeDrawn.remove(at: rewardIndex)
			emit RaffleWinnerDrawn(raffleID: self.raffleID, name: self.name, host: self.host, winner: winner, nftIdentifier: self.nftInfo.nftType.identifier, tokenIDs: [rewardTokenID])
		}
		
		access(all)
		fun batchDraw(params:{ String: AnyStruct}){ 
			let availability = self.checkAvailability(params: params)
			assert(availability.status == AvailabilityStatus.drawing, message: availability.getStatus())
			let capacity = self.numberOfWinners - UInt64(self.winners.keys.length)
			let upperLimit = capacity > UInt64(self.candidates.length) ? UInt64(self.candidates.length) : capacity
			assert(UInt64(self.nftToBeDrawn.length) >= upperLimit, message: "nft is not enough")
			var counter: UInt64 = 0
			while counter < upperLimit{ 
				let winnerIndex = revertibleRandom<UInt64>() % UInt64(self.candidates.length)
				let winner = self.candidates[winnerIndex]
				assert(self.winners[winner] == nil, message: "winner already recorded")
				let rewardIndex = revertibleRandom<UInt64>() % UInt64(self.nftToBeDrawn.length)
				let rewardTokenID = self.nftToBeDrawn[rewardIndex]
				let winnerRecord = WinnerRecord(address: winner, rewardTokenIDs: [rewardTokenID], extraData:{} )
				self.winners[winner] = winnerRecord
				self.candidates.remove(at: winnerIndex)
				self.nftToBeDrawn.remove(at: rewardIndex)
				counter = counter + 1
			}
		}
		
		// private methods
		access(all)
		fun togglePause(): Bool{ 
			pre{ 
				!self.isEnded:
					"Raffle has ended"
			}
			self.isPaused = !self.isPaused
			if self.isPaused{ 
				emit RafflePaused(raffleID: self.raffleID, name: self.name, host: self.host)
			} else{ 
				emit RaffleUnpaused(raffleID: self.raffleID, name: self.name, host: self.host)
			}
			return self.isPaused
		}
		
		// deposit more NFT into the Raffle
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}, display: NFTDisplay){ 
			pre{ 
				!self.isEnded:
					"Raffle has ended"
			}
			let tokenID = token.id
			self.collection.deposit(token: <-token)
			self.nftToBeDrawn.append(tokenID)
			self.rewardDisplays[tokenID] = display
		}
		
		access(all)
		fun end(receiver: &{NonFungibleToken.CollectionPublic}){ 
			self.isEnded = true
			self.isPaused = true
			emit RaffleEnded(raffleID: self.raffleID, name: self.name, host: self.host)
			let tokenIDs = self.collection.getIDs()
			for tokenID in tokenIDs{ 
				let token <- self.collection.withdraw(withdrawID: tokenID)
				receiver.deposit(token: <-token)
			}
		}
		
		init(name: String, description: String, host: Address, image: String?, url: String?, startAt: UFix64?, endAt: UFix64?, registrationEndAt: UFix64, numberOfWinners: UInt64, nftInfo: NFTInfo, collection: @{NonFungibleToken.Collection}, registrationVerifyMode: EligibilityVerifiers.VerifyMode, claimVerifyMode: EligibilityVerifiers.VerifyMode, registrationVerifiers:{ String: [{EligibilityVerifiers.IEligibilityVerifier}]}, claimVerifiers:{ String: [{EligibilityVerifiers.IEligibilityVerifier}]}, extraData:{ String: AnyStruct}){ 
			if !collection.isInstance(nftInfo.collectionType){ 
				panic("invalid nft info: get ".concat(collection.getType().identifier).concat(", want ").concat(nftInfo.collectionType.identifier))
			}
			if let _startAt = startAt{ 
				if let _endAt = endAt{ 
					assert(_startAt < _endAt, message: "endAt should greater than startAt")
					assert(registrationEndAt < _endAt, message: "registrationEndAt should smaller than endAt")
				}
				assert(registrationEndAt > _startAt, message: "registrationEndAt should greater than startAt")
			}
			self.raffleID = self.uuid
			self.name = name
			self.description = description
			self.createdAt = getCurrentBlock().timestamp
			self.host = host
			self.image = image
			self.url = url
			self.startAt = startAt
			self.endAt = endAt
			self.registrationEndAt = registrationEndAt
			self.numberOfWinners = numberOfWinners
			self.nftInfo = nftInfo
			self.collection <- collection
			self.registrationVerifyMode = registrationVerifyMode
			self.claimVerifyMode = claimVerifyMode
			self.registrationVerifiers = registrationVerifiers
			self.claimVerifiers = claimVerifiers
			self.extraData = extraData
			self.isPaused = false
			self.isEnded = false
			self.registrationRecords ={} 
			self.candidates = []
			self.winners ={} 
			self.nftToBeDrawn = []
			self.rewardDisplays ={} 
			Mist.totalRaffles = Mist.totalRaffles + 1
			emit RaffleCreated(raffleID: self.raffleID, name: self.name, host: self.host, description: self.description, nftIdentifier: self.nftInfo.nftType.identifier)
		}
	}
	
	access(all)
	resource interface IMistPauser{ 
		access(all)
		fun toggleContractPause(): Bool
	}
	
	access(all)
	resource Admin: IMistPauser{ 
		// Use to pause the creation of new Raffle
		// If we want to migrate the contracts, we can make sure no more Raffle in old contracts be created.
		access(all)
		fun toggleContractPause(): Bool{ 
			Mist.isPaused = !Mist.isPaused
			return Mist.isPaused
		}
	}
	
	access(all)
	resource interface IRaffleCollectionPublic{ 
		access(all)
		fun getAllRaffles():{ UInt64: &{IRafflePublic}}
		
		access(all)
		fun borrowPublicRaffleRef(raffleID: UInt64): &{IRafflePublic}?
	}
	
	access(all)
	resource RaffleCollection: IRaffleCollectionPublic{ 
		access(all)
		var raffles: @{UInt64: Raffle}
		
		access(all)
		fun createRaffle(name: String, description: String, host: Address, image: String?, url: String?, startAt: UFix64?, endAt: UFix64?, registrationEndAt: UFix64, numberOfWinners: UInt64, nftInfo: NFTInfo, collection: @{NonFungibleToken.Collection}, registrationVerifyMode: EligibilityVerifiers.VerifyMode, claimVerifyMode: EligibilityVerifiers.VerifyMode, registrationVerifiers: [{EligibilityVerifiers.IEligibilityVerifier}], claimVerifiers: [{EligibilityVerifiers.IEligibilityVerifier}], extraData:{ String: AnyStruct}): UInt64{ 
			pre{ 
				registrationVerifiers.length <= 1:
					"Currently only 0 or 1 registration verifier supported"
				claimVerifiers.length <= 1:
					"Currently only 0 or 1 registration verifier supported"
				!Mist.isPaused:
					"Mist contract is paused!"
			}
			let typedRegistrationVerifiers:{ String: [{EligibilityVerifiers.IEligibilityVerifier}]} ={} 
			for verifier in registrationVerifiers{ 
				let identifier = verifier.getType().identifier
				if typedRegistrationVerifiers[identifier] == nil{ 
					typedRegistrationVerifiers[identifier] = [verifier]
				} else{ 
					(typedRegistrationVerifiers[identifier]!).append(verifier)
				}
			}
			let typedClaimVerifiers:{ String: [{EligibilityVerifiers.IEligibilityVerifier}]} ={} 
			for verifier in claimVerifiers{ 
				let identifier = verifier.getType().identifier
				if typedClaimVerifiers[identifier] == nil{ 
					typedClaimVerifiers[identifier] = [verifier]
				} else{ 
					(typedClaimVerifiers[identifier]!).append(verifier)
				}
			}
			let raffle <- create Raffle(name: name, description: description, host: host, image: image, url: url, startAt: startAt, endAt: endAt, registrationEndAt: registrationEndAt, numberOfWinners: numberOfWinners, nftInfo: nftInfo, collection: <-collection, registrationVerifyMode: registrationVerifyMode, claimVerifyMode: claimVerifyMode, registrationVerifiers: typedRegistrationVerifiers, claimVerifiers: typedClaimVerifiers, extraData: extraData)
			let raffleID = raffle.raffleID
			self.raffles[raffleID] <-! raffle
			return raffleID
		}
		
		access(all)
		fun getAllRaffles():{ UInt64: &{IRafflePublic}}{ 
			let raffleRefs:{ UInt64: &{IRafflePublic}} ={} 
			for raffleID in self.raffles.keys{ 
				let raffleRef = (&self.raffles[raffleID] as &{IRafflePublic}?)!
				raffleRefs.insert(key: raffleID, raffleRef)
			}
			return raffleRefs
		}
		
		access(all)
		fun borrowPublicRaffleRef(raffleID: UInt64): &{IRafflePublic}?{ 
			return &self.raffles[raffleID] as &{IRafflePublic}?
		}
		
		access(all)
		fun borrowRaffleRef(raffleID: UInt64): &Raffle?{ 
			return &self.raffles[raffleID] as &Raffle?
		}
		
		access(all)
		fun deleteRaffle(raffleID: UInt64, receiver: &{NonFungibleToken.CollectionPublic}){ 
			// Clean the Raffle before make it ownerless
			let raffleRef = self.borrowRaffleRef(raffleID: raffleID) ?? panic("This raffle does not exist")
			raffleRef.end(receiver: receiver)
			let raffle <- self.raffles.remove(key: raffleID) ?? panic("This raffle does not exist")
			destroy raffle
		}
		
		init(){ 
			self.raffles <-{} 
		}
	}
	
	access(all)
	fun createEmptyRaffleCollection(): @RaffleCollection{ 
		return <-create RaffleCollection()
	}
	
	access(all)
	var isPaused: Bool
	
	access(all)
	var totalRaffles: UInt64
	
	init(){ 
		self.RaffleCollectionStoragePath = /storage/drizzleRaffleCollection
		self.RaffleCollectionPublicPath = /public/drizzleRaffleCollection
		self.RaffleCollectionPrivatePath = /private/drizzleRaffleCollection
		self.MistAdminStoragePath = /storage/drizzleMistAdmin
		self.MistAdminPublicPath = /public/drizzleMistAdmin
		self.MistAdminPrivatePath = /private/drizzleMistAdmin
		self.isPaused = false
		self.totalRaffles = 0
		self.account.storage.save(<-create Admin(), to: self.MistAdminStoragePath)
		emit ContractInitialized()
	}
}
