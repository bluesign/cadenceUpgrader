/*
	Adapted from: AllDay.cdc
	Author: Innocent Abdullahi innocent.abdullahi@dapperlabs.com
*/

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

/*
	Golazos is structured similarly to AllDay.
	Unlike TopShot, we use resources for all entities and manage access to their data
	by copying it to structs (this simplifies access control, in particular write access).
	We also encapsulate resource creation for the admin in member functions on the parent type.

	There are 5 levels of entity:
	1. Series
	2. Sets
	3. Plays
	4. Editions
	4. Moment NFT (an NFT)

	An Edition is created with a combination of a Series, Set, and Play
	Moment NFTs are minted out of Editions.

	Note that we cache some information (Series names/ids, counts of entities) rather
	than calculate it each time.
	This is enabled by encapsulation and saves gas for entity lifecycle operations.
 */

/// The Golazos NFTs and metadata contract
//
access(all)
contract Golazos: NonFungibleToken{ 
	// -----------------------------------------------------------------------
	// Golazos deployment variables
	// -----------------------------------------------------------------------
	access(all)
	fun RoyaltyAddress(): Address{ 
		return 0x87ca73a41bb50ad5
	}
	
	//------------------------------------------------------------
	// Events
	//------------------------------------------------------------
	// Contract Events
	//
	access(all)
	event ContractInitialized()
	
	// NFT Collection Events
	//
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Series Events
	//
	/// Emitted when a new series has been created by an admin
	access(all)
	event SeriesCreated(id: UInt64, name: String)
	
	/// Emitted when a series is closed by an admin
	access(all)
	event SeriesClosed(id: UInt64)
	
	// Set Events
	//
	/// Emitted when a new set has been created by an admin
	access(all)
	event SetCreated(id: UInt64, name: String)
	
	/// Emitted when a Set is locked, meaning Editions cannot be created with the set
	access(all)
	event SetLocked(setID: UInt64)
	
	// Play Events
	//
	/// Emitted when a new play has been created by an admin
	access(all)
	event PlayCreated(id: UInt64, classification: String, metadata:{ String: String})
	
	// Edition Events
	//
	/// Emitted when a new edition has been created by an admin
	access(all)
	event EditionCreated(id: UInt64, seriesID: UInt64, setID: UInt64, playID: UInt64, maxMintSize: UInt64?, tier: String)
	
	/// Emitted when an edition is either closed by an admin, or the max amount of moments have been minted
	access(all)
	event EditionClosed(id: UInt64)
	
	// NFT Events
	//
	/// Emitted when a moment nft is minted
	access(all)
	event MomentNFTMinted(id: UInt64, editionID: UInt64, serialNumber: UInt64)
	
	/// Emitted when a moment nft resource is destroyed
	access(all)
	event MomentNFTBurned(id: UInt64, editionID: UInt64, serialNumber: UInt64)
	
	//------------------------------------------------------------
	// Named values
	//------------------------------------------------------------
	/// Named Paths
	///
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let MinterPrivatePath: PrivatePath
	
	//------------------------------------------------------------
	// Publicly readable contract state
	//------------------------------------------------------------
	/// Entity Counts
	///
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var nextSeriesID: UInt64
	
	access(all)
	var nextSetID: UInt64
	
	access(all)
	var nextPlayID: UInt64
	
	access(all)
	var nextEditionID: UInt64
	
	//------------------------------------------------------------
	// Internal contract state
	//------------------------------------------------------------
	/// Metadata Dictionaries
	///
	/// This is so we can find Series by their names (via seriesByID)
	access(self)
	let seriesIDByName:{ String: UInt64}
	
	access(self)
	let seriesByID: @{UInt64: Series}
	
	access(self)
	let setIDByName:{ String: UInt64}
	
	access(self)
	let setByID: @{UInt64: Set}
	
	access(self)
	let playByID: @{UInt64: Play}
	
	access(self)
	let editionByID: @{UInt64: Edition}
	
	//------------------------------------------------------------
	// Series
	//------------------------------------------------------------
	/// A public struct to access Series data
	///
	access(all)
	struct SeriesData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let active: Bool
		
		/// initializer
		//
		view init(id: UInt64){ 
			let series = (&Golazos.seriesByID[id] as &Golazos.Series?)!
			self.id = series.id
			self.name = series.name
			self.active = series.active
		}
	}
	
	/// A top-level Series with a unique ID and name
	///
	access(all)
	resource Series{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		var active: Bool
		
		/// Close this series
		///
		access(all)
		fun close(){ 
			pre{ 
				self.active == true:
					"series is not active"
			}
			self.active = false
			emit SeriesClosed(id: self.id)
		}
		
		/// initializer
		///
		init(name: String){ 
			pre{ 
				!Golazos.seriesIDByName.containsKey(name):
					"A Series with that name already exists"
			}
			self.id = Golazos.nextSeriesID
			self.name = name
			self.active = true
			
			// Cache the new series's name => ID
			Golazos.seriesIDByName[name] = self.id
			// Increment for the nextSeriesID
			Golazos.nextSeriesID = self.id + 1 as UInt64
			emit SeriesCreated(id: self.id, name: self.name)
		}
	}
	
	/// Get the publicly available data for a Series by id
	///
	access(all)
	view fun getSeriesData(id: UInt64): Golazos.SeriesData{ 
		pre{ 
			Golazos.seriesByID[id] != nil:
				"Cannot borrow series, no such id"
		}
		return Golazos.SeriesData(id: id)
	}
	
	/// Get the publicly available data for a Series by name
	///
	access(all)
	fun getSeriesDataByName(name: String): Golazos.SeriesData?{ 
		let id = Golazos.seriesIDByName[name]
		if id == nil{ 
			return nil
		}
		return Golazos.SeriesData(id: id!)
	}
	
	/// Get all series names (this will be *long*)
	///
	access(all)
	fun getAllSeriesNames(): [String]{ 
		return Golazos.seriesIDByName.keys
	}
	
	/// Get series id by name
	///
	access(all)
	fun getSeriesIDByName(name: String): UInt64?{ 
		return Golazos.seriesIDByName[name]
	}
	
	//------------------------------------------------------------
	// Set
	//------------------------------------------------------------
	/// A public struct to access Set data
	///
	access(all)
	struct SetData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let locked: Bool
		
		access(all)
		var setPlaysInEditions:{ UInt64: Bool}
		
		/// member function to check the setPlaysInEditions to see if this Set/Play combination already exists
		access(all)
		fun setPlayExistsInEdition(playID: UInt64): Bool{ 
			return self.setPlaysInEditions.containsKey(playID)
		}
		
		/// initializer
		///
		view init(id: UInt64){ 
			let set = (&Golazos.setByID[id] as &Golazos.Set?)!
			self.id = id
			self.name = set.name
			self.locked = set.locked
			self.setPlaysInEditions = set.getSetPlaysInEditions()
		}
	}
	
	/// A top level Set with a unique ID and a name
	///
	access(all)
	resource Set{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		/// Store a dictionary of all the Plays which are paired with the Set inside Editions
		/// This enforces only one Set/Play unique pair can be used for an Edition
		access(self)
		var setPlaysInEditions:{ UInt64: Bool}
		
		// Indicates if the Set is currently locked.
		// When a Set is created, it is unlocked
		// and Editions can be created with it.
		// When a Set is locked, new Editions cannot be created with the Set.
		// A Set can never be changed from locked to unlocked,
		// the decision to lock a Set is final.
		// If a Set is locked, Moments can still be minted from the
		// Editions already created from the Set.
		access(all)
		var locked: Bool
		
		/// member function to insert a new Play to the setPlaysInEditions dictionary
		access(all)
		fun insertNewPlay(playID: UInt64){ 
			self.setPlaysInEditions[playID] = true
		}
		
		/// returns the plays added to the set in an edition
		access(all)
		view fun getSetPlaysInEditions():{ UInt64: Bool}{ 
			return self.setPlaysInEditions
		}
		
		/// initializer
		///
		init(name: String){ 
			pre{ 
				!Golazos.setIDByName.containsKey(name):
					"A Set with that name already exists"
			}
			self.id = Golazos.nextSetID
			self.name = name
			self.setPlaysInEditions ={} 
			self.locked = false
			
			// Cache the new set's name => ID
			Golazos.setIDByName[name] = self.id
			// Increment for the nextSeriesID
			Golazos.nextSetID = self.id + 1 as UInt64
			emit SetCreated(id: self.id, name: self.name)
		}
		
		// lock() locks the Set so that no more Plays can be added to it
		//
		// Pre-Conditions:
		// The Set should not be locked
		access(all)
		fun lock(){ 
			if !self.locked{ 
				self.locked = true
				emit SetLocked(setID: self.id)
			}
		}
	}
	
	/// Get the publicly available data for a Set
	///
	access(all)
	view fun getSetData(id: UInt64): Golazos.SetData?{ 
		if Golazos.setByID[id] == nil{ 
			return nil
		}
		return Golazos.SetData(id: id!)
	}
	
	/// Get the publicly available data for a Set by name
	///
	access(all)
	fun getSetDataByName(name: String): Golazos.SetData?{ 
		let id = Golazos.setIDByName[name]
		if id == nil{ 
			return nil
		}
		return Golazos.SetData(id: id!)
	}
	
	/// Get all set names (this will be *long*)
	///
	access(all)
	fun getAllSetNames(): [String]{ 
		return Golazos.setIDByName.keys
	}
	
	//------------------------------------------------------------
	// Play
	//------------------------------------------------------------
	/// A public struct to access Play data
	///
	access(all)
	struct PlayData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let classification: String
		
		access(all)
		let metadata:{ String: String}
		
		/// initializer
		///
		init(id: UInt64){ 
			let play = (&Golazos.playByID[id] as &Golazos.Play?)!
			self.id = id
			self.classification = play.classification
			self.metadata = play.getMetadata()
		}
	}
	
	/// A top level Play with a unique ID and a classification
	//
	access(all)
	resource Play{ 
		access(all)
		let id: UInt64
		
		access(all)
		let classification: String
		
		access(self)
		let metadata:{ String: String}
		
		/// returns the metadata set for this play
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		/// initializer
		///
		init(classification: String, metadata:{ String: String}){ 
			self.id = Golazos.nextPlayID
			self.classification = classification
			self.metadata = metadata
			Golazos.nextPlayID = self.id + 1 as UInt64
			emit PlayCreated(id: self.id, classification: self.classification, metadata: self.metadata)
		}
	}
	
	/// Get the publicly available data for a Play
	///
	access(all)
	fun getPlayData(id: UInt64): Golazos.PlayData?{ 
		if Golazos.playByID[id] == nil{ 
			return nil
		}
		return Golazos.PlayData(id: id!)
	}
	
	//------------------------------------------------------------
	// Edition
	//------------------------------------------------------------
	/// A public struct to access Edition data
	///
	access(all)
	struct EditionData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let seriesID: UInt64
		
		access(all)
		let setID: UInt64
		
		access(all)
		let playID: UInt64
		
		access(all)
		var maxMintSize: UInt64?
		
		access(all)
		let tier: String
		
		access(all)
		var numMinted: UInt64
		
		/// member function to check if max edition size has been reached
		access(all)
		fun maxEditionMintSizeReached(): Bool{ 
			return self.numMinted == self.maxMintSize
		}
		
		/// initializer
		///
		view init(id: UInt64){ 
			let edition = (&Golazos.editionByID[id] as &Golazos.Edition?)!
			self.id = id
			self.seriesID = edition.seriesID
			self.playID = edition.playID
			self.setID = edition.setID
			self.maxMintSize = edition.maxMintSize
			self.tier = edition.tier
			self.numMinted = edition.numMinted
		}
	}
	
	/// A top level Edition that contains a Series, Set, and Play
	///
	access(all)
	resource Edition{ 
		access(all)
		let id: UInt64
		
		access(all)
		let seriesID: UInt64
		
		access(all)
		let setID: UInt64
		
		access(all)
		let playID: UInt64
		
		access(all)
		let tier: String
		
		/// Null value indicates that there is unlimited minting potential for the Edition
		access(all)
		var maxMintSize: UInt64?
		
		/// Updates each time we mint a new moment for the Edition to keep a running total
		access(all)
		var numMinted: UInt64
		
		/// Close this edition so that no more Moment NFTs can be minted in it
		///
		access(contract)
		fun close(){ 
			pre{ 
				self.numMinted != self.maxMintSize:
					"max number of minted moments has already been reached"
			}
			self.maxMintSize = self.numMinted
			emit EditionClosed(id: self.id)
		}
		
		/// Mint a Moment NFT in this edition, with the given minting mintingDate.
		/// Note that this will panic if the max mint size has already been reached.
		///
		access(all)
		fun mint(): @Golazos.NFT{ 
			pre{ 
				self.numMinted != self.maxMintSize:
					"max number of minted moments has been reached"
			}
			
			// Create the Moment NFT, filled out with our information
			let momentNFT <- create NFT(editionID: self.id, serialNumber: self.numMinted + 1)
			Golazos.totalSupply = Golazos.totalSupply + 1
			// Keep a running total (you'll notice we used this as the serial number)
			self.numMinted = self.numMinted + 1 as UInt64
			return <-momentNFT
		}
		
		/// initializer
		///
		init(seriesID: UInt64, setID: UInt64, playID: UInt64, maxMintSize: UInt64?, tier: String){ 
			pre{ 
				maxMintSize != 0:
					"max mint size is zero, must either be null or greater than 0"
				Golazos.seriesByID.containsKey(seriesID):
					"seriesID does not exist"
				Golazos.setByID.containsKey(setID):
					"setID does not exist"
				Golazos.playByID.containsKey(playID):
					"playID does not exist"
				(Golazos.getSeriesData(id: seriesID)!).active == true:
					"cannot create an Edition with a closed Series"
				(Golazos.getSetData(id: setID)!).locked == false:
					"cannot create an Edition with a locked Set"
				(Golazos.getSetData(id: setID)!).setPlayExistsInEdition(playID: playID) == false:
					"set play combination already exists in an edition"
			}
			self.id = Golazos.nextEditionID
			self.seriesID = seriesID
			self.setID = setID
			self.playID = playID
			
			// If an edition size is not set, it has unlimited minting potential
			if maxMintSize == 0{ 
				self.maxMintSize = nil
			} else{ 
				self.maxMintSize = maxMintSize
			}
			self.tier = tier
			self.numMinted = 0 as UInt64
			Golazos.nextEditionID = Golazos.nextEditionID + 1 as UInt64
			Golazos.setByID[setID]?.insertNewPlay(playID: playID)
			emit EditionCreated(id: self.id, seriesID: self.seriesID, setID: self.setID, playID: self.playID, maxMintSize: self.maxMintSize, tier: self.tier)
		}
	}
	
	/// Get the publicly available data for an Edition
	///
	access(all)
	fun getEditionData(id: UInt64): EditionData?{ 
		if Golazos.editionByID[id] == nil{ 
			return nil
		}
		return Golazos.EditionData(id: id)
	}
	
	//------------------------------------------------------------
	// NFT
	//------------------------------------------------------------
	/// A Moment NFT
	///
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let editionID: UInt64
		
		access(all)
		let serialNumber: UInt64
		
		access(all)
		let mintingDate: UFix64
		
		/// Destructor
		///
		/// NFT initializer
		///
		init(editionID: UInt64, serialNumber: UInt64){ 
			pre{ 
				Golazos.editionByID[editionID] != nil:
					"no such editionID"
				EditionData(id: editionID).maxEditionMintSizeReached() != true:
					"max edition size already reached"
			}
			self.id = self.uuid
			self.editionID = editionID
			self.serialNumber = serialNumber
			self.mintingDate = getCurrentBlock().timestamp
			emit MomentNFTMinted(id: self.id, editionID: self.editionID, serialNumber: self.serialNumber)
		}
		
		access(all)
		fun assetPath(): String{ 
			let editionData = Golazos.getEditionData(id: self.editionID)!
			let playDataID: String = Golazos.PlayData(id: editionData.playID).metadata["PlayDataID"] ?? ""
			return "https://assets.laligagolazos.com/editions/".concat(playDataID).concat("/play_").concat(playDataID)
		}
		
		access(all)
		fun getImage(imageType: String, language: String): String{ 
			return self.assetPath().concat("__").concat(imageType).concat("_2880_2880_").concat(language).concat(".png")
		}
		
		access(all)
		fun getVideo(videoType: String, language: String): String{ 
			return self.assetPath().concat("__").concat(videoType).concat("_1080_1080_").concat(language).concat(".mp4")
		}
		
		/// get the name of an nft
		///
		access(all)
		fun name(): String{ 
			let editionData = Golazos.getEditionData(id: self.editionID)!
			let playerKnownName: String = Golazos.PlayData(id: editionData.playID).metadata["PlayerKnownName"] ?? ""
			let playerFirstName: String = Golazos.PlayData(id: editionData.playID).metadata["PlayerFirstName"] ?? ""
			let playerLastName: String = Golazos.PlayData(id: editionData.playID).metadata["PlayerLastName"] ?? ""
			let playType: String = Golazos.PlayData(id: editionData.playID).metadata["PlayType"] ?? ""
			var playerName = playerKnownName
			if playerName == ""{ 
				playerName = playerFirstName.concat(" ").concat(playerLastName)
			}
			return playType.concat(" by ").concat(playerName)
		}
		
		/// get the description of an nft
		///
		access(all)
		fun description(): String{ 
			let editionData = Golazos.getEditionData(id: self.editionID)!
			let metadata = Golazos.PlayData(id: editionData.playID).metadata
			let matchHomeTeam: String = metadata["MatchHomeTeam"] ?? ""
			let matchAwayTeam: String = metadata["MatchAwayTeam"] ?? ""
			let matchHomeScore: String = metadata["MatchHomeScore"] ?? ""
			let matchAwayScore: String = metadata["MatchAwayScore"] ?? ""
			let matchDay: String = metadata["MatchDay"] ?? ""
			let matchSeason: String = metadata["MatchSeason"] ?? ""
			return "LaLiga Golazos Moment from ".concat(matchHomeTeam).concat(" x ").concat(matchAwayTeam).concat(" (").concat(matchHomeScore).concat("-").concat(matchAwayScore).concat(") on Matchday ").concat(matchDay).concat(" (").concat(matchSeason).concat(")")
		}
		
		/// get a thumbnail image that represents this nft
		///
		access(all)
		fun thumbnail(): MetadataViews.HTTPFile{ 
			let editionData = Golazos.getEditionData(id: self.editionID)!
			let playDataID: String = Golazos.PlayData(id: editionData.playID).metadata["PlayDataID"] ?? ""
			if playDataID == ""{ 
				return MetadataViews.HTTPFile(url: "https://ipfs.dapperlabs.com/ipfs/QmPvr5zTwji1UGpun57cbj719MUBsB5syjgikbwCMPmruQ")
			}
			return MetadataViews.HTTPFile(url: self.getImage(imageType: "capture_Hero_Black", language: "default"))
		}
		
		/// get the metadata view types available for this nft
		///
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Serial>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.Traits>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Medias>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Royalties>()]
		}
		
		/// resolve a metadata view type returning the properties of the view type
		///
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name(), description: self.description(), thumbnail: self.thumbnail())
				case Type<MetadataViews.Editions>():
					let editionData = Golazos.getEditionData(id: self.editionID)!
					let editionInfo = MetadataViews.Edition(name: nil, number: self.serialNumber, max: editionData.maxMintSize)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.serialNumber)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Golazos.CollectionStoragePath, publicPath: Golazos.CollectionPublicPath, publicCollection: Type<&Golazos.Collection>(), publicLinkedType: Type<&Golazos.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Golazos.createEmptyCollection(nftType: Type<@Golazos.Collection>())
						})
				case Type<MetadataViews.Traits>():
					return MetadataViews.dictToTraits(dict: self.getTraits(), excludedNames: nil)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://laligagolazos.com/moments/".concat(self.id.toString()))
				case Type<MetadataViews.Medias>():
					return MetadataViews.Medias([MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "capture_Hero_Black", language: "default")), mediaType: "image/png"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "capture_Hero_Black", language: "es")), mediaType: "image/png"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "capture_Front_Black", language: "default")), mediaType: "image/png"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "capture_Front_Black", language: "es")), mediaType: "image/png"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "capture_Legal_Black", language: "default")), mediaType: "image/png"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "capture_Legal_Black", language: "es")), mediaType: "image/png"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "capture_Details_Black", language: "default")), mediaType: "image/png"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "capture_Details_Black", language: "es")), mediaType: "image/png"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getVideo(videoType: "capture_Animated_Video_Popout_Black", language: "default")), mediaType: "video/mp4"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getVideo(videoType: "capture_Animated_Video_Popout_Black", language: "es")), mediaType: "video/mp4"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getVideo(videoType: "capture_Animated_Video_Idle_Black", language: "default")), mediaType: "video/mp4"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getVideo(videoType: "capture_Animated_Video_Idle_Black", language: "es")), mediaType: "video/mp4")])
				case Type<MetadataViews.NFTCollectionDisplay>():
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://assets.laligagolazos.com/static/golazos-logos/Golazos_Logo_Horizontal_B.png"), mediaType: "image/png")
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://assets.laligagolazos.com/static/golazos-logos/Golazos_Logo_Primary_B.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "Laliga Golazos", description: "Collect LaLiga's biggest Moments and get closer to the game than ever before", externalURL: MetadataViews.ExternalURL("https://laligagolazos.com/"), squareImage: squareImage, bannerImage: bannerImage, socials:{ "instagram": MetadataViews.ExternalURL(" https://instagram.com/laligaonflow"), "twitter": MetadataViews.ExternalURL("https://twitter.com/LaLigaGolazos"), "discord": MetadataViews.ExternalURL("https://discord.gg/LaLigaGolazos"), "facebook": MetadataViews.ExternalURL("https://www.facebook.com/LaLigaGolazos/")})
				case Type<MetadataViews.Royalties>():
					let royaltyReceiver: Capability<&{FungibleToken.Receiver}> = getAccount(Golazos.RoyaltyAddress()).capabilities.get<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())!
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: royaltyReceiver, cut: 0.05, description: "Laliga Golazos marketplace royalty")])
			}
			return nil
		}
		
		access(all)
		fun getTraits():{ String: AnyStruct}{ 
			let edition: EditionData = Golazos.getEditionData(id: self.editionID)!
			let play: PlayData = Golazos.getPlayData(id: edition.playID)!
			let series: SeriesData = Golazos.getSeriesData(id: edition.seriesID)!
			let set: SetData = Golazos.getSetData(id: edition.setID)!
			let traitDictionary:{ String: AnyStruct} ={ "editionTier": edition.tier, "seriesName": series.name, "setName": set.name, "serialNumber": self.serialNumber}
			for name in play.metadata.keys{ 
				let value = play.metadata[name] ?? ""
				if value != ""{ 
					traitDictionary.insert(key: name, value)
				}
			}
			return traitDictionary
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	//------------------------------------------------------------
	// Collection
	//------------------------------------------------------------
	/// A public collection interface that allows Moment NFTs to be borrowed
	///
	access(all)
	resource interface MomentNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowMomentNFT(id: UInt64): &Golazos.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Moment NFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	/// An NFT Collection
	///
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, MomentNFTCollectionPublic, ViewResolver.ResolverCollection{ 
		/// dictionary of NFT conforming tokens
		/// NFT is a resource type with an UInt64 ID field
		///
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		/// withdraw removes an NFT from the collection and moves it to the caller
		///
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		/// deposit takes a NFT and adds it to the collections dictionary
		/// and adds the ID to the id array
		///
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Golazos.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		/// batchDeposit takes a Collection object as an argument
		/// and deposits each contained NFT into this Collection
		///
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			// Get an array of the IDs to be deposited
			let keys = tokens.getIDs()
			
			// Iterate through the keys in the collection and deposit each one
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			
			// Destroy the empty Collection
			destroy tokens
		}
		
		/// getIDs returns an array of the IDs that are in the collection
		///
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		/// borrowNFT gets a reference to an NFT in the collection
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		/// borrowMomentNFT gets a reference to an NFT in the collection
		///
		access(all)
		fun borrowMomentNFT(id: UInt64): &Golazos.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Golazos.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let dapperSportNFT = nft as! &Golazos.NFT
			return dapperSportNFT as &{ViewResolver.Resolver}
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
		
		/// Collection destructor
		///
		/// Collection initializer
		///
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	/// public function that anyone can call to create a new empty collection
	///
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	//------------------------------------------------------------
	// Admin
	//------------------------------------------------------------
	/// An interface containing the Admin function that allows minting NFTs
	///
	access(all)
	resource interface NFTMinter{ 
		// Mint a single NFT
		// The Edition for the given ID must already exist
		//
		access(all)
		fun mintNFT(editionID: UInt64): @Golazos.NFT
	}
	
	/// A resource that allows managing metadata and minting NFTs
	///
	access(all)
	resource Admin: NFTMinter{ 
		/// Borrow a Series
		///
		access(all)
		fun borrowSeries(id: UInt64): &Golazos.Series{ 
			pre{ 
				Golazos.seriesByID[id] != nil:
					"Cannot borrow series, no such id"
			}
			return (&Golazos.seriesByID[id] as &Golazos.Series?)!
		}
		
		/// Borrow a Set
		///
		access(all)
		fun borrowSet(id: UInt64): &Golazos.Set{ 
			pre{ 
				Golazos.setByID[id] != nil:
					"Cannot borrow Set, no such id"
			}
			return (&Golazos.setByID[id] as &Golazos.Set?)!
		}
		
		/// Borrow a Play
		///
		access(all)
		fun borrowPlay(id: UInt64): &Golazos.Play{ 
			pre{ 
				Golazos.playByID[id] != nil:
					"Cannot borrow Play, no such id"
			}
			return (&Golazos.playByID[id] as &Golazos.Play?)!
		}
		
		/// Borrow an Edition
		///
		access(all)
		fun borrowEdition(id: UInt64): &Golazos.Edition{ 
			pre{ 
				Golazos.editionByID[id] != nil:
					"Cannot borrow edition, no such id"
			}
			return (&Golazos.editionByID[id] as &Golazos.Edition?)!
		}
		
		/// Create a Series
		///
		access(all)
		fun createSeries(name: String): UInt64{ 
			// Create and store the new series
			let series <- create Golazos.Series(name: name)
			let seriesID = series.id
			Golazos.seriesByID[series.id] <-! series
			
			// Return the new ID for convenience
			return seriesID
		}
		
		/// Close a Series
		///
		access(all)
		fun closeSeries(id: UInt64): UInt64{ 
			let series = (&Golazos.seriesByID[id] as &Golazos.Series?)!
			series.close()
			return series.id
		}
		
		/// Create a Set
		///
		access(all)
		fun createSet(name: String): UInt64{ 
			// Create and store the new set
			let set <- create Golazos.Set(name: name)
			let setID = set.id
			Golazos.setByID[set.id] <-! set
			
			// Return the new ID for convenience
			return setID
		}
		
		/// Locks a Set
		///
		access(all)
		fun lockSet(id: UInt64): UInt64{ 
			let set = (&Golazos.setByID[id] as &Golazos.Set?)!
			set.lock()
			return set.id
		}
		
		/// Create a Play
		///
		access(all)
		fun createPlay(classification: String, metadata:{ String: String}): UInt64{ 
			// Create and store the new play
			let play <- create Golazos.Play(classification: classification, metadata: metadata)
			let playID = play.id
			Golazos.playByID[play.id] <-! play
			
			// Return the new ID for convenience
			return playID
		}
		
		/// Create an Edition
		///
		access(all)
		fun createEdition(seriesID: UInt64, setID: UInt64, playID: UInt64, maxMintSize: UInt64?, tier: String): UInt64{ 
			let edition <- create Edition(seriesID: seriesID, setID: setID, playID: playID, maxMintSize: maxMintSize, tier: tier)
			let editionID = edition.id
			Golazos.editionByID[edition.id] <-! edition
			return editionID
		}
		
		/// Close an Edition
		///
		access(all)
		fun closeEdition(id: UInt64): UInt64{ 
			let edition = (&Golazos.editionByID[id] as &Golazos.Edition?)!
			edition.close()
			return edition.id
		}
		
		/// Mint a single NFT
		/// The Edition for the given ID must already exist
		///
		access(all)
		fun mintNFT(editionID: UInt64): @Golazos.NFT{ 
			pre{ 
				// Make sure the edition we are creating this NFT in exists
				Golazos.editionByID.containsKey(editionID):
					"No such EditionID"
			}
			return <-self.borrowEdition(id: editionID).mint()
		}
	}
	
	//------------------------------------------------------------
	// Contract lifecycle
	//------------------------------------------------------------
	/// Golazos contract initializer
	///
	init(){ 
		// Set the named paths
		self.CollectionStoragePath = /storage/GolazosNFTCollection
		self.CollectionPublicPath = /public/GolazosNFTCollection
		self.AdminStoragePath = /storage/GolazosAdmin
		self.MinterPrivatePath = /private/GolazosMinter
		
		// Initialize the entity counts
		self.totalSupply = 0
		self.nextSeriesID = 1
		self.nextSetID = 1
		self.nextPlayID = 1
		self.nextEditionID = 1
		
		// Initialize the metadata lookup dictionaries
		self.seriesByID <-{} 
		self.seriesIDByName ={} 
		self.setIDByName ={} 
		self.setByID <-{} 
		self.playByID <-{} 
		self.editionByID <-{} 
		
		// Create an Admin resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		// Link capabilites to the admin constrained to the Minter
		// and Metadata interfaces
		var capability_1 = self.account.capabilities.storage.issue<&Golazos.Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.MinterPrivatePath)
		
		// Let the world know we are here
		emit ContractInitialized()
	}
}
