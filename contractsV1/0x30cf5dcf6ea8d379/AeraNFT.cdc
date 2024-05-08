import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import AeraPack from "./AeraPack.cdc"

import BurnRegistry from "./BurnRegistry.cdc"

import FindViews from "../0x097bafa4e0b48eef/FindViews.cdc"

/*
- Can be Player or Team moment
*/

access(all)
contract AeraNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, address: Address)
	
	access(all)
	event Burned(id: UInt64, from: Address?, playId: UInt64, edition: UInt64)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		var nounce: UInt64
		
		access(all)
		let play: Play
		
		access(all)
		let edition: UInt64
		
		access(all)
		let badges:{ UInt64: Badge}
		
		init(play: Play, edition: UInt64){ 
			self.nounce = 0
			self.id = self.uuid
			self.play = play
			self.edition = edition
			self.badges ={} 
		}
		
		access(all)
		fun addBadge(_ badge: Badge){ 
			self.badges[badge.id] = badge
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			let views = [Type<MetadataViews.Display>(), Type<License>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Medias>(), Type<MetadataViews.Rarity>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Traits>(), Type<AeraPack.PackRevealData>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Royalties>(), Type<Play>()]
			
			//1 is soulbound
			if self.isSoulBound(){ 
				views.append(Type<FindViews.SoulBound>())
			}
			return views
		}
		
		access(all)
		view fun isSoulBound(): Bool{ 
			return self.badges[1] != nil && (self.badges[1]!).name == "soulbound"
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let play = self.play
			switch view{ 
				case Type<FindViews.SoulBound>():
					if self.isSoulBound(){ 
						return FindViews.SoulBound("This NFT cannot be traded, it is soulbound")
					}
					return nil
				case Type<Play>():
					return play
				case Type<License>():
					if let licence = play.getLicenseID(){ 
						return AeraNFT.getLicense(licence)!
					} else{ 
						return nil
					}
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: AeraNFT.CollectionStoragePath, publicPath: AeraNFT.CollectionPublicPath, publicCollection: Type<&AeraNFT.Collection>(), publicLinkedType: Type<&AeraNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-AeraNFT.createEmptyCollection(nftType: Type<@AeraNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let externalURL = MetadataViews.ExternalURL("http://aera.onefootbal.com")
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://miro.medium.com/fit/c/176/176/1*hzfP51MATg3et5vghYy1uQ.png"), mediaType: "image/png")
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://bafybeiaaf7bfbppep5ahb2m75xlmxyj76hxo3oh5dcl4prxeskruwpe6c4.ipfs.nftstorage.link/"), mediaType: "image/png")
					let socialMap:{ String: MetadataViews.ExternalURL} ={ "twitter": MetadataViews.ExternalURL("https://twitter.com/aera_football"), "discord": MetadataViews.ExternalURL("https://discord.gg/aera"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/aera_football/")}
					return MetadataViews.NFTCollectionDisplay(name: "Aera", description: "Aera by OneFootball", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socialMap)
				case Type<MetadataViews.Display>():
					return play.asDisplay()
				case Type<MetadataViews.Medias>():
					return play.getMedias()
				case Type<MetadataViews.Editions>():
					return MetadataViews.Editions([MetadataViews.Edition(name: "play", number: self.edition, max: play.maxSerial)])
				case Type<MetadataViews.Rarity>():
					var rarity: UFix64 = 0.0
					switch play.rarity{ 
						case "Common":
							rarity = 1.0
						case "Rare":
							rarity = 2.0
						case "Epic":
							rarity = 3.0
						case "Legendary":
							rarity = 4.0
					}
					return MetadataViews.Rarity(score: rarity, max: nil, description: play.rarity)
				case Type<MetadataViews.Traits>():
					let traits = play.getTraits()
					for badgeID in self.badges.keys{ 
						let badge = self.badges[badgeID]!
						let value = badge.name!
						traits.append(MetadataViews.Trait(name: "badge_".concat(badge.name!), value: value, displayType: "String", rarity: badge.rarity))
					}
					return MetadataViews.Traits(traits)
				case Type<AeraPack.PackRevealData>():
					let display = play.asDisplay()
					let game = AeraNFT.getGame(play.gameID)!
					return AeraPack.PackRevealData({"playId": self.play.id.toString(),																					   // specifically for pack opening sequence, we send the rectangle thumbnail and not the play.thumbnail
																					   "image": self.play.thumbnailsIpfsHash[3], "video": "ipfs://".concat(play.videoIpfsHash), "name": display.name, "rarity": play.rarity, "serial": self.edition.toString(), "maxSerial": play.maxSerial.toString(), "id": self.id.toString(), "gameHighlightedTeam": game.highlightedTeam, "gameCompetition": game.competition, "gameSeason": game.season, "gameMatchday": game.matchday.toString(), "playDate": play.date.toString()})
				case Type<MetadataViews.ExternalURL>():
					if let addr = self.owner?.address{ 
						return MetadataViews.ExternalURL("https://aera.onefootball.com/collectibles/".concat(addr.toString()).concat("/serie-a/").concat(self.id.toString()))
					}
					return MetadataViews.ExternalURL("https://aera.onefootball.com/marketplace/")
				case Type<MetadataViews.Royalties>():
					var address = AeraNFT.account.address
					if address == 0x46625f59708ec2f8{ 
						//testnet merchant address
						address = 0x4ff956c78244911b
					} else if address == 0x30cf5dcf6ea8d379{ 
						//mainnet merchant address
						address = 0xa9277dcbec7769df
					}
					let ducReceiver = getAccount(address).capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: ducReceiver!, cut: 0.06, description: "onefootball largest of 6% or 0.65")])
			/*
						case Type<FindViews.MinimumRoyalty>():
							return FindViews.MinimiumRoyalty({"onefootball largest of 6% or 0.65": 0.65)})
						}
						*/
			
			}
			return nil
		}
		
		access(all)
		fun increaseNounce(){ 
			self.nounce = self.nounce + 1
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	struct Badge{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String?
		
		access(all)
		let description: String?
		
		access(all)
		let rarity: MetadataViews.Rarity?
		
		init(id: UInt64, name: String?, description: String?, rarity: MetadataViews.Rarity?){ 
			self.id = id
			self.name = name
			self.description = description
			self.rarity = rarity
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(account)
		fun addBadge(id: UInt64, badge: Badge)
		
		access(all)
		fun hasNFT(_ id: UInt64): Bool
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(all)
		fun hasNFT(_ id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(all)
		fun burn(_ id: UInt64){ 
			let token <- self.withdraw(withdrawID: id) as! @NFT
			emit Burned(id: token.id, from: self.owner?.address, playId: token.play.id, edition: token.edition)
			destroy <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @NFT
			let id: UInt64 = token.id
			//TODO: add nounce and emit better event the first time it is moved.
			token.increaseNounce()
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let aera = nft as! &NFT
			return aera as &{ViewResolver.Resolver}
		}
		
		access(account)
		fun addBadge(id: UInt64, badge: Badge){ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let aera = nft as! &NFT
			aera.addBadge(badge)
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// mintNFT mints a new NFT with a new ID
	// and deposit it in the recipients collection using their collection reference
	//The distinction between sending in a reference and sending in a capability is that when you send in a reference it cannot be stored. So it can only be used in this method
	//while a capability can be stored and used later. So in this case using a reference is the right choice, but it needs to be owned so that you can have a good event
	access(account)
	fun mintNFT(recipient: &{NonFungibleToken.Receiver}, edition: UInt64, play: Play, badges: [Badge]){ 
		pre{ 
			recipient.owner != nil:
				"Recipients NFT collection is not owned"
		}
		AeraNFT.totalSupply = AeraNFT.totalSupply + 1
		// create a new NFT
		var newNFT <- create NFT(play: play, edition: edition)
		for badge in badges{ 
			newNFT.addBadge(badge)
		}
		recipient.deposit(token: <-newNFT)
	}
	
	access(all)
	struct Game{ 
		access(all)
		let id: UInt64
		
		access(all)
		let homeTeamName: String
		
		access(all)
		let awayTeamName: String
		
		access(all)
		let derbyID: String
		
		access(all)
		let competition: String
		
		access(all)
		let season: String
		
		access(all)
		let date: UFix64
		
		access(all)
		let matchday: UInt64
		
		access(all)
		let highlightedTeam: String
		
		access(all)
		let homeScore: UInt64
		
		access(all)
		let awayScore: UInt64
		
		access(all)
		let metadata:{ String: String}
		
		init(id: UInt64, homeTeamName: String, awayTeamName: String, derbyID: String, competition: String, season: String, date: UFix64, matchday: UInt64, highlightedTeam: String, homeScore: UInt64, awayScore: UInt64, metadata:{ String: String}){ 
			self.id = id
			self.homeTeamName = homeTeamName
			self.awayTeamName = awayTeamName
			self.derbyID = derbyID
			self.competition = competition
			self.season = season
			self.date = date
			self.matchday = matchday
			self.highlightedTeam = highlightedTeam
			self.homeScore = homeScore
			self.awayScore = awayScore
			self.metadata = metadata
		}
		
		access(all)
		fun getTraits(): [MetadataViews.Trait]{ 
			var winner = "tie"
			if self.homeScore > self.awayScore{ 
				winner = "home"
			} else if self.homeScore < self.awayScore{ 
				winner = "away"
			}
			let views = [MetadataViews.Trait(name: "home_team", value: self.homeTeamName, displayType: "String", rarity: nil), MetadataViews.Trait(name: "away_team", value: self.awayTeamName, displayType: "String", rarity: nil), MetadataViews.Trait(name: "competition", value: self.competition, displayType: "String", rarity: nil), MetadataViews.Trait(name: "season", value: self.season, displayType: "String", rarity: nil), MetadataViews.Trait(name: "match_date", value: self.date, displayType: "Date", rarity: nil), MetadataViews.Trait(name: "match_day", value: self.matchday, displayType: "Number", rarity: nil), MetadataViews.Trait(name: "home_score", value: self.homeScore, displayType: "Number", rarity: nil), MetadataViews.Trait(name: "away_score", value: self.awayScore, displayType: "Number", rarity: nil), MetadataViews.Trait(name: "score", value: self.homeScore.toString().concat("-").concat(self.awayScore.toString()), displayType: "String", rarity: nil), MetadataViews.Trait(name: "winner", value: winner, displayType: "String", rarity: nil)]
			if self.derbyID != "-" && self.derbyID != ""{ 
				views.append(MetadataViews.Trait(name: "derby_id", value: self.derbyID, displayType: "String", rarity: nil))
			}
			return views
		}
	}
	
	access(self)
	let games:{ UInt64: Game}
	
	access(account)
	fun addGame(_ game: Game){ 
		self.games[game.id] = game
	}
	
	access(all)
	fun getGames():{ UInt64: Game}{ 
		return self.games
	}
	
	access(all)
	fun getGame(_ id: UInt64): Game?{ 
		return self.games[id]
	}
	
	access(all)
	struct License{ 
		access(all)
		let id: UInt64
		
		access(all)
		let note: String
		
		access(all)
		let copyright: String
		
		init(id: UInt64, note: String, copyright: String){ 
			self.id = id
			self.note = note
			self.copyright = copyright
		}
	}
	
	access(self)
	let licenses:{ UInt64: License}
	
	access(account)
	fun addLicense(_ license: License){ 
		self.licenses[license.id] = license
	}
	
	access(all)
	fun getLicenses():{ UInt64: License}{ 
		return self.licenses
	}
	
	access(all)
	fun getLicense(_ id: UInt64): License?{ 
		return self.licenses[id]
	}
	
	/// A struct to hold information about a play
	access(all)
	struct Play{ 
		access(all)
		let id: UInt64
		
		access(all)
		let gameID: UInt64
		
		access(all)
		let playersInvolved:{ String: UInt64}
		
		access(all)
		let title: String
		
		access(all)
		let description: String
		
		//this is the thumbnail
		access(all)
		let imageIpfsHash: String
		
		access(all)
		let videoIpfsHash: String
		
		//these are images
		access(all)
		let thumbnailsIpfsHash: [String]
		
		access(all)
		let type: String
		
		access(all)
		let rarity: String
		
		access(all)
		let maxSerial: UInt64
		
		access(all)
		let period: String
		
		access(all)
		let date: UFix64
		
		access(all)
		let time: UInt64
		
		access(all)
		let homeScore: UInt64
		
		access(all)
		let awayScore: UInt64
		
		init(id: UInt64, gameID: UInt64, playersInvolved:{ String: UInt64}, title: String, description: String, imageIpfsHash: String, videoIpfsHash: String, thumbnailsIpfsHash: [String], type: String, rarity: String, maxSerial: UInt64, period: String, date: UFix64, time: UInt64, homeScore: UInt64, awayScore: UInt64){ 
			self.id = id
			self.gameID = gameID
			self.playersInvolved = playersInvolved
			self.title = title
			self.description = description
			self.imageIpfsHash = imageIpfsHash
			self.videoIpfsHash = videoIpfsHash
			self.thumbnailsIpfsHash = thumbnailsIpfsHash
			self.type = type
			self.rarity = rarity
			self.maxSerial = maxSerial
			self.period = period
			self.date = date
			self.time = time
			self.homeScore = homeScore
			self.awayScore = awayScore
		}
		
		access(all)
		fun getLicenseID(): UInt64?{ 
			let playId = self.id
			if let licence = self.playersInvolved["license"]{ 
				//There was a typo in mint so we fix it here
				if playId == 338{ 
					return 2
				} else if playId == 342{ 
					return 1
				} else{ 
					return licence
				}
			}
			return nil
		}
		
		access(all)
		fun getTraits(): [MetadataViews.Trait]{ 
			let traits = [MetadataViews.Trait(name: "play_id", value: self.id, displayType: "Number", rarity: nil), MetadataViews.Trait(name: "play_period", value: self.period, displayType: "String", rarity: nil), MetadataViews.Trait(name: "play_time", value: self.time, displayType: "Number", rarity: nil), MetadataViews.Trait(name: "play_home_score", value: self.homeScore, displayType: "Number", rarity: nil), MetadataViews.Trait(name: "play_away_score", value: self.awayScore, displayType: "Number", rarity: nil), MetadataViews.Trait(name: "play_score", value: self.homeScore.toString().concat("-").concat(self.awayScore.toString()), displayType: "String", rarity: nil), MetadataViews.Trait(name: "play_type", value: self.type, displayType: "String", rarity: nil)]
			let game = AeraNFT.getGame(self.gameID)!
			if let ht = self.playersInvolved["highlightedTeam"]{ 
				var highlightedTeam = game.homeTeamName
				if ht == 2{ 
					highlightedTeam = game.awayTeamName
				}
				traits.append(MetadataViews.Trait(name: "highlighted_team", value: highlightedTeam, displayType: "String", rarity: nil))
			}
			if let pt = self.playersInvolved["play_type"]{ 
				var playType = "player"
				if pt == 2{ 
					playType = "team"
				} else if pt == 3{ 
					playType = "reward"
				}
				traits.append(MetadataViews.Trait(name: "play_entity", value: playType, displayType: "String", rarity: nil))
			}
			traits.appendAll(game.getTraits())
			for role in self.playersInvolved.keys{ 
				if role == "highlightedTeam" || role == "license" || role == "play_type"{ 
					continue
				}
				let player = AeraNFT.getPlayer(self.playersInvolved[role]!)!
				var prefix = role
				traits.appendAll(player.getTraits(prefix))
			}
			if let licence = self.getLicenseID(){ 
				let l = AeraNFT.getLicense(licence)!
				traits.append(MetadataViews.Trait(name: "copyright", value: l.copyright, displayType: "String", rarity: nil))
			}
			return traits
		}
		
		access(all)
		fun getMetadata(_ field: String): AnyStruct?{ 
			if let metadata = AeraNFT.getPlayMetadata(self.id){ 
				return metadata.metadata[field]
			}
			return nil
		}
		
		access(all)
		fun getMedias(): MetadataViews.Medias{ 
			let imageFile = MetadataViews.IPFSFile(cid: self.imageIpfsHash, path: nil)
			let medias = [self.getVideo(), MetadataViews.Media(file: imageFile, mediaType: "image/png")]
			for hash in self.thumbnailsIpfsHash{ 
				let file = MetadataViews.IPFSFile(cid: hash, path: nil)
				medias.append(MetadataViews.Media(file: file, mediaType: "image/png"))
			}
			return MetadataViews.Medias(medias)
		}
		
		access(all)
		fun asDisplay(): MetadataViews.Display{ 
			let imageFile = MetadataViews.IPFSFile(cid: self.imageIpfsHash, path: nil)
			return MetadataViews.Display(name: self.title, description: self.description, thumbnail: imageFile)
		}
		
		access(all)
		fun getVideo(): MetadataViews.Media{ 
			let file = MetadataViews.IPFSFile(cid: self.videoIpfsHash, path: nil)
			return MetadataViews.Media(file: file, mediaType: self.getVideoMediaType())
		}
		
		access(all)
		fun getVideoMediaType(): String{ 
			if let videoMediaType = self.getMetadata("videoMediaType"){ 
				return videoMediaType as! String
			}
			return "video/mp4"
		}
	}
	
	access(all)
	struct PlayMetadata{ 
		access(all)
		let id: UInt64
		
		access(all)
		let metadata:{ String: String}
		
		init(id: UInt64, metadata:{ String: String}){ 
			self.id = id
			self.metadata = metadata
		}
	}
	
	access(self)
	let playMetadata:{ UInt64: PlayMetadata}
	
	access(account)
	fun addPlayMetadata(_ play: PlayMetadata){ 
		self.playMetadata[play.id] = play
	}
	
	access(all)
	fun getAllPlayMetadata():{ UInt64: PlayMetadata}{ 
		return self.playMetadata
	}
	
	access(all)
	fun getPlayMetadata(_ id: UInt64): PlayMetadata?{ 
		return self.playMetadata[id]
	}
	
	/// Players store information about a player that can change and is therefore not stored in the NFT itself
	/// can be mutated from Admin
	access(all)
	struct Player{ 
		access(all)
		let id: UInt64
		
		access(all)
		let jerseyname: String
		
		access(all)
		let position: String
		
		access(all)
		let number: UInt64
		
		access(all)
		let nationality: String
		
		access(all)
		let birthday: String
		
		access(all)
		let metadata:{ String: String}
		
		init(id: UInt64, jerseyname: String, position: String, number: UInt64, nationality: String, birthday: String, metadata:{ String: String}){ 
			self.id = id
			self.jerseyname = jerseyname
			self.position = position
			self.number = number
			self.nationality = nationality
			self.birthday = birthday
			self.metadata = metadata
		}
		
		access(all)
		fun getTraits(_ role: String): [MetadataViews.Trait]{ 
			return [MetadataViews.Trait(name: "player_".concat(role).concat("_jersey"), value: self.jerseyname, displayType: "String", rarity: nil), MetadataViews.Trait(name: "player_".concat(role).concat("_position"), value: self.position, displayType: "String", rarity: nil), MetadataViews.Trait(name: "player_".concat(role).concat("_number"), value: self.number, displayType: "Number", rarity: nil), MetadataViews.Trait(name: "player_".concat(role).concat("_nationality"), value: self.nationality, displayType: "String", rarity: nil), MetadataViews.Trait(name: "player_".concat(role).concat("_birthday"), value: self.birthday, displayType: "String", rarity: nil)]
		}
	}
	
	access(self)
	let players:{ UInt64: Player}
	
	access(account)
	fun addPlayer(_ player: Player){ 
		self.players[player.id] = player
	}
	
	access(all)
	fun getPlayers():{ UInt64: Player}{ 
		return self.players
	}
	
	access(all)
	fun getPlayer(_ id: UInt64): Player?{ 
		return self.players[id]
	}
	
	access(all)
	fun resolveLicence(_ viewResolver: &{ViewResolver.Resolver}): License?{ 
		if let view = viewResolver.resolveView(Type<License>()){ 
			if let v = view as? License{ 
				return v
			}
		}
		return nil
	}
	
	access(all)
	struct Challenge{ 
		access(all)
		var completed: Bool
		
		access(all)
		let playIds: [UInt64]
		
		access(all)
		let numberOfPlaysToComplete: Int
		
		access(all)
		let qualification:{ UInt64: UInt64}
		
		init(playIds: [UInt64], numberOfPlaysToComplete: Int){ 
			self.playIds = playIds
			self.numberOfPlaysToComplete = numberOfPlaysToComplete
			self.qualification ={} 
			self.completed = false
		}
		
		access(all)
		fun checkPlay(playId: UInt64, id: UInt64){ 
			if self.playIds.contains(playId) && self.qualification[playId] == nil{ 
				self.qualification[playId] = id
			}
			self.completed = self.qualification.length >= self.numberOfPlaysToComplete
		}
	}
	
	init(){ 
		self.players ={} 
		self.games ={} 
		self.playMetadata ={} 
		self.licenses ={} 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/aeraNFTs
		self.CollectionPublicPath = /public/aeraNFTs
		self.CollectionPrivatePath = /private/aeraNFTs
		emit ContractInitialized()
	}
}
