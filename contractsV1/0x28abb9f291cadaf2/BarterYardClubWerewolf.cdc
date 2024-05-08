import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import BarterYardStats from "./BarterYardStats.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract BarterYardClubWerewolf: NonFungibleToken{ 
	
	/// Counter for all the minted Werewolves
	access(all)
	var totalSupply: UInt64
	
	/// Maximum Werewolf NFT supply that will ever exist
	access(all)
	let maxSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Mint(id: UInt64)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Burn(id: UInt64)
	
	/// WerewolfTransformed: Event sent when werewolves in the pack need to transform for better intoperability
	access(all)
	event WerewolfTransformed(ids: [UInt64], imageType: UInt8)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	/// traits contains all single NFT Traits as struct to keep track of supply
	access(self)
	let traits:{ UInt8: Trait}
	
	/// traitTypes all NFT Trait Types
	access(self)
	let traitTypes:{ Int8: String}
	
	/// timezonedWerewolves stores werewolves by timezone with a boolean value to tell if auto thumbnail is active or not
	access(self)
	let timezonedWerewolves:{ Int8:{ UInt64: Bool}}
	
	/// lastSyncedTimestamp stores the last timestamp where computeTimezoneForWerewolves was called
	access(all)
	var lastSyncedTimestamp: Int
	
	access(all)
	struct interface SupplyManager{ 
		access(all)
		var totalSupply: UInt16
		
		access(all)
		fun increment(){ 
			post{ 
				self.totalSupply == before(self.totalSupply) + 1:
					"[SupplyManager](increment): totalSupply should be incremented"
			}
		}
		
		access(all)
		fun decrement(){ 
			pre{ 
				self.totalSupply > 0:
					"[SupplyManager](decrement): totalSupply must be positive in order to decrement"
			}
			post{ 
				self.totalSupply == before(self.totalSupply) - 1:
					"[SupplyManager](decrement): totalSupply should be decremented"
			}
		}
	}
	
	/**********/
	/* TRAITS */
	/**********/
	/// NftTrait is the trait struct meant to be set into NFTs
	access(all)
	struct NftTrait{ 
		access(all)
		let id: UInt8
		
		/// traitType refers to a type of trait (background / clothes / accessory etc...) stored in traitTypes map
		access(all)
		let traitType: Int8
		
		/// value gives the value for the traitType
		access(all)
		let value: String
		
		init(id: UInt8, traitType: Int8, value: String){ 
			self.id = id
			self.traitType = traitType
			self.value = value
		}
	}
	
	/// PublicTrait is the trait struct meant to be exposed in this contract with totalSupply
	access(all)
	struct PublicTrait{ 
		access(all)
		let id: UInt8
		
		access(all)
		let traitType: Int8
		
		access(all)
		let value: String
		
		access(all)
		let totalSupply: UInt16
		
		init(id: UInt8, traitType: Int8, value: String, totalSupply: UInt16){ 
			self.id = id
			self.traitType = traitType
			self.value = value
			self.totalSupply = totalSupply
		}
	}
	
	/// Trait is the trait strcut used inside this contract to manage trait supply and return the different views
	access(all)
	struct Trait: SupplyManager{ 
		access(all)
		let id: UInt8
		
		access(all)
		let traitType: Int8
		
		access(all)
		let value: String
		
		access(all)
		var totalSupply: UInt16
		
		access(all)
		fun increment(){ 
			self.totalSupply = self.totalSupply + 1
		}
		
		access(all)
		fun decrement(){ 
			self.totalSupply = self.totalSupply - 1
		}
		
		access(all)
		fun toPublic(): BarterYardClubWerewolf.PublicTrait{ 
			return BarterYardClubWerewolf.PublicTrait(id: self.id, traitType: self.traitType, value: self.value, totalSupply: self.totalSupply)
		}
		
		access(all)
		fun toNft(): BarterYardClubWerewolf.NftTrait{ 
			return BarterYardClubWerewolf.NftTrait(id: self.id, traitType: self.traitType, value: self.value)
		}
		
		init(id: UInt8, traitType: Int8, value: String){ 
			self.id = id
			self.traitType = traitType
			self.value = value
			self.totalSupply = 0
		}
	}
	
	/*******/
	/* NFT */
	/*******/
	/// ImageType is an enum to manage the different types of image the NFT holds
	access(all)
	enum ImageType: UInt8{ 
		access(all)
		case Day
		
		access(all)
		case Night
		
		access(all)
		case Animated
	}
	
	/// Werewolf interface
	access(all)
	resource interface Werewolf{ 
		/*******************/
		/* NFT information */
		/*******************/
		access(all)
		let id: UInt64 // eg: 1
		
		
		access(all)
		let name: String // eg: Werewolf #1
		
		
		access(all)
		let description: String // eg: Barter Yard Club membership
		
		
		/// Metadata attributes with public traits view
		access(contract)
		let attributes: [NftTrait; 8]
		
		/********************/
		/* Image management */
		/********************/
		/// All images IPFS files
		access(all)
		let dayImage: MetadataViews.IPFSFile
		
		access(all)
		let nightImage: MetadataViews.IPFSFile
		
		access(all)
		let animation: MetadataViews.IPFSFile
		
		/// gmt: can be set by the NFT owner to compute day / night according to his timezone
		access(all)
		var utc: Int8
		
		access(all)
		fun setUTC(utc: Int8)
		
		/// auto: if set to true, let the system compute which NFT to return
		access(all)
		var auto: Bool
		
		access(all)
		fun setAuto(auto: Bool)
		
		/// default: allow the user to set a default image if auto is turned off
		access(all)
		var defaultImage: ImageType
		
		access(all)
		fun setDefaultImage(imageType: ImageType)
		
		/// getThumbnail returns the current image to display depending on user preferences
		access(all)
		fun getThumbnail(): MetadataViews.IPFSFile
	}
	
	access(all)
	struct CompleteDisplay{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(contract)
		let attributes: [NftTrait; 8]
		
		access(all)
		let thumbnail: MetadataViews.IPFSFile
		
		access(all)
		let dayImage: MetadataViews.IPFSFile
		
		access(all)
		let nightImage: MetadataViews.IPFSFile
		
		access(all)
		let animation: MetadataViews.IPFSFile
		
		access(all)
		fun getAttributes(): [NftTrait; 8]{ 
			return self.attributes
		}
		
		init(name: String, description: String, attributes: [NftTrait; 8], thumbnail: MetadataViews.IPFSFile, dayImage: MetadataViews.IPFSFile, nightImage: MetadataViews.IPFSFile, animation: MetadataViews.IPFSFile){ 
			self.name = name
			self.description = description
			self.attributes = attributes
			self.thumbnail = thumbnail
			self.dayImage = dayImage
			self.nightImage = nightImage
			self.animation = animation
		}
	}
	
	access(all)
	struct NFTConfig{ 
		access(all)
		let utc: Int8
		
		access(all)
		let auto: Bool
		
		access(all)
		let defaultImage: ImageType
		
		init(utc: Int8, auto: Bool, defaultImage: ImageType){ 
			self.utc = utc
			self.auto = auto
			self.defaultImage = defaultImage
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, Werewolf, ViewResolver.Resolver{ 
		/// Werewolf
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(contract)
		let attributes: [NftTrait; 8]
		
		access(all)
		let dayImage: MetadataViews.IPFSFile
		
		access(all)
		let nightImage: MetadataViews.IPFSFile
		
		access(all)
		let animation: MetadataViews.IPFSFile
		
		access(all)
		var utc: Int8
		
		access(all)
		var auto: Bool
		
		access(all)
		var defaultImage: ImageType
		
		/// Computed thumbnail
		access(all)
		var thumbnail: MetadataViews.IPFSFile
		
		init(id: UInt64, name: String, description: String, attributes: [NftTrait; 8], dayImage: MetadataViews.IPFSFile, nightImage: MetadataViews.IPFSFile, animation: MetadataViews.IPFSFile){ 
			self.id = id
			self.name = name.concat(" #").concat(id.toString())
			self.description = description
			self.attributes = attributes
			self.dayImage = dayImage
			self.nightImage = nightImage
			self.animation = animation
			self.utc = 0
			self.auto = true
			self.defaultImage = ImageType.Day
			self.thumbnail = dayImage
		}
		
		access(all)
		fun setUTC(utc: Int8){ 
			BarterYardClubWerewolf.timezonedWerewolves.containsKey(utc)
			// Remove werewolf from old UTC
			if BarterYardClubWerewolf.timezonedWerewolves.containsKey(self.utc){ 
				(BarterYardClubWerewolf.timezonedWerewolves[self.utc]!).remove(key: self.id)
			}
			// Add werewolf to new UTC
			if BarterYardClubWerewolf.timezonedWerewolves.containsKey(utc){ 
				(BarterYardClubWerewolf.timezonedWerewolves[utc]!).insert(key: self.id, true)
			} else{ 
				BarterYardClubWerewolf.timezonedWerewolves.insert(key: utc,{ self.id: true})
			}
			self.utc = utc
			self.computeThumbnail()
		}
		
		access(all)
		fun setAuto(auto: Bool){ 
			self.auto = auto
			if !self.auto && BarterYardClubWerewolf.timezonedWerewolves.containsKey(self.utc){ 
				(BarterYardClubWerewolf.timezonedWerewolves[self.utc]!).remove(key: self.id)
			} else if self.auto && BarterYardClubWerewolf.timezonedWerewolves.containsKey(self.utc){ 
				(BarterYardClubWerewolf.timezonedWerewolves[self.utc]!).insert(key: self.id, true)
			}
			self.computeThumbnail()
		}
		
		access(all)
		fun setDefaultImage(imageType: ImageType){ 
			self.defaultImage = imageType
			self.computeThumbnail()
		}
		
		access(all)
		fun computeThumbnail(){ 
			let newThumbnail = self.getThumbnail()
			if newThumbnail.uri() == self.thumbnail.uri(){ 
				return
			}
			self.thumbnail = newThumbnail
			emit WerewolfTransformed(ids: [self.id], imageType: self.getAutoImageType().rawValue)
		}
		
		access(all)
		fun getAutoImageType(): ImageType{ 
			if self.auto{ 
				let hour = BarterYardClubWerewolf.getCurrentHour(self.utc)
				let thumbnail: BarterYardClubWerewolf.ImageType = hour > 8 && hour < 20 ? ImageType.Day : ImageType.Night
				return thumbnail
			}
			return self.defaultImage
		}
		
		/// getThumbnail implementation from Werewolf interface
		access(all)
		fun getThumbnail(): MetadataViews.IPFSFile{ 
			let imageType = self.getAutoImageType()
			switch imageType{ 
				case ImageType.Day:
					return self.dayImage
				case ImageType.Night:
					return self.nightImage
				case ImageType.Animated:
					return self.animation
			}
			return self.dayImage
		}
		
		/// getViews implementation from MetadataViews.Resolver interface
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<CompleteDisplay>(), Type<NFTConfig>(), Type<MetadataViews.Serial>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Traits>()]
		}
		
		/// resolveView implementation from MetadataViews.Resolver interface
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					if ["bafybeiftalxnzljtscdvbgso3qods7zxojas53lcm5pwgbclkdgu3eijlm", "bafybeicx3ti7huwgklrdjqkfrva6kvrm7vpmdwqyipvfwixoqvuc4orqbi", "bafybeidnjh4knx67rlfuwkj7o4a6p4uknclb4nia6ootxlmfa44ohtfrca"].contains(self.dayImage.cid){ 
						return MetadataViews.Display(name: "", description: "", thumbnail: MetadataViews.IPFSFile(cid: "", path: nil))
					}
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: self.getThumbnail())
				case Type<CompleteDisplay>():
					return CompleteDisplay(name: self.name, description: self.description, attributes: self.attributes, thumbnail: self.getThumbnail(), dayImage: self.dayImage, nightImage: self.nightImage, animation: self.animation)
				case Type<NFTConfig>():
					return NFTConfig(utc: self.utc, auto: self.auto, defaultImage: self.defaultImage)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: BarterYardClubWerewolf.CollectionStoragePath, publicPath: BarterYardClubWerewolf.CollectionPublicPath, publicCollection: Type<&BarterYardClubWerewolf.Collection>(), publicLinkedType: Type<&BarterYardClubWerewolf.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-BarterYardClubWerewolf.createEmptyCollection(nftType: Type<@BarterYardClubWerewolf.Collection>())
						})
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://www.barteryard.club")
				case Type<MetadataViews.Royalties>():
					let recipient = getAccount(Address(0xb07b788eb60b6528)).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: recipient, cut: 0.025, description: "Werewolves Royalty")])
				case Type<MetadataViews.NFTCollectionDisplay>():
					let mediaSquare = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://images.barteryard.club/logo.svg"), mediaType: "image/svg+xml")
					let mediaBanner = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://images.barteryard.club/banner.svg"), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "BarterYard Club Werewolves", description: "Barter Yard Club is an NFT toolbox organisation built on Flow Protocol and co-owned by the werewolves", externalURL: MetadataViews.ExternalURL("https://www.barteryard.club"), squareImage: mediaSquare, bannerImage: mediaBanner, socials:{ "discord": MetadataViews.ExternalURL("https://discord.gg/barteryard"), "twitter": MetadataViews.ExternalURL("https://twitter.com/barteryard")})
				case Type<MetadataViews.Traits>():
					let traitsView: [MetadataViews.Trait] = []
					let traits = self.attributes
					let traitTypes = BarterYardClubWerewolf.getTraitsTypes()
					for trait in traits{ 
						let traitView = MetadataViews.Trait(name: traitTypes[trait.traitType]!, value: trait.value, displayType: "String", rarity: nil)
						traitsView.append(traitView)
					}
					return MetadataViews.Traits(traitsView)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	/**************/
	/* COLLECTION */
	/**************/
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @BarterYardClubWerewolf.NFT
			let id: UInt64 = token.id
			
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
		fun borrowBarterYardClubWerewolfNFT(id: UInt64): &BarterYardClubWerewolf.NFT?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT not in collection"
			}
			// Create an authorized reference to allow downcasting
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &BarterYardClubWerewolf.NFT?
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT not in collection"
			}
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let BarterYardClubWerewolf = nft as! &BarterYardClubWerewolf.NFT
			return BarterYardClubWerewolf as! &{ViewResolver.Resolver}
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
	
	// function to burn the NFT
	access(self)
	fun burnNFT(){ 
		// Check NFT ownership from caller?
		self.totalSupply = self.totalSupply - 1
	}
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource Admin{ 
		
		// mintNFT mints a new NFT with a new Id
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(name: String, description: String, attributes: [NftTrait; 8], dayImage: MetadataViews.IPFSFile, nightImage: MetadataViews.IPFSFile, animation: MetadataViews.IPFSFile): @BarterYardClubWerewolf.NFT{ 
			// create a new NFT
			var nftId: UInt64 = BarterYardStats.getNextTokenId()
			var newNFT <- create NFT(									 // Start ID at 1
									 id: nftId, name: name, description: description, attributes: attributes, dayImage: dayImage, nightImage: nightImage, animation: animation)
			for attribute in attributes{ 
				let trait = BarterYardClubWerewolf.traits[attribute.id] ?? panic("[Admin](mintNFT) Invalid trait providen")
				trait.increment()
				BarterYardClubWerewolf.traits[attribute.id] = trait
			}
			emit Mint(id: newNFT.id)
			BarterYardClubWerewolf.totalSupply = BarterYardClubWerewolf.totalSupply + 1
			BarterYardClubWerewolf.timezonedWerewolves.insert(key: 0,{ newNFT.id: true})
			return <-newNFT
		}
		
		access(all)
		fun addTraitType(_ traitType: String){ 
			BarterYardClubWerewolf.traitTypes.insert(key: Int8(BarterYardClubWerewolf.traitTypes.length), traitType)
		}
		
		access(all)
		fun addTrait(traitType: Int8, value: String){ 
			pre{ 
				BarterYardClubWerewolf.traitTypes[traitType] != nil:
					"[Admin](addTrait): couldn't add trait because traitTypes doesn't exists"
			}
			let id = UInt8(BarterYardClubWerewolf.traits.length)
			BarterYardClubWerewolf.traits.insert(key: id, Trait(id: id, traitType: traitType, value: value))
		}
	}
	
	access(all)
	fun getTraitsTypes():{ Int8: String}{ 
		return self.traitTypes
	}
	
	access(all)
	fun getPublicTraits():{ UInt8: PublicTrait}{ 
		let traits:{ UInt8: PublicTrait} ={} 
		for trait in self.traits.values{ 
			traits.insert(key: trait.id, trait.toPublic())
		}
		return traits
	}
	
	access(all)
	fun getNftTraits():{ UInt8: NftTrait}{ 
		let traits:{ UInt8: NftTrait} ={} 
		for trait in self.traits.values{ 
			traits.insert(key: trait.id, trait.toNft())
		}
		return traits
	}
	
	access(all)
	fun getEmptyNftTraits(): [BarterYardClubWerewolf.NftTrait; 8]{ 
		let emptyTrait = NftTrait(id: 0, traitType: -1, value: "Empty")
		return [emptyTrait, emptyTrait, emptyTrait, emptyTrait, emptyTrait, emptyTrait, emptyTrait, emptyTrait]
	}
	
	access(all)
	fun getCurrentHour(_ utc: Int8): Int{ 
		let currentTime = Int(getCurrentBlock().timestamp)
		let hour = (currentTime + Int(utc) * 3600) / 3600 % 24
		return hour
	}
	
	access(all)
	fun getTimezonedWerewolves():{ Int8:{ UInt64: Bool}}{ 
		return self.timezonedWerewolves
	}
	
	/// computeTimezoneForWerewolves gets werewolves in timezones that needs to be updated and call computeThumbnail
	access(all)
	fun computeTimezoneForWerewolves(){ 
		let utcTimestamp = Int(getCurrentBlock().timestamp)
		var elapsedHours = (utcTimestamp - self.lastSyncedTimestamp) / 3600 % 24
		if elapsedHours == 0{ 
			return
		}
		while elapsedHours > 0{ 
			let hour = (utcTimestamp - 3600 * (elapsedHours - 1)) / 3600 % 24
			let dayStartTimezone = Int8(8 - hour)
			let dayEndTimezone = Int8(hour > 8 ? dayStartTimezone + 12 : dayStartTimezone - 12)
			if self.timezonedWerewolves[dayStartTimezone] == nil && self.timezonedWerewolves[dayEndTimezone] == nil{ 
				continue
			}
			if self.timezonedWerewolves[dayStartTimezone] != nil{ 
				emit WerewolfTransformed(ids: (self.timezonedWerewolves[dayStartTimezone]!).keys, imageType: ImageType.Day.rawValue)
			}
			if self.timezonedWerewolves[dayEndTimezone] != nil{ 
				emit WerewolfTransformed(ids: (self.timezonedWerewolves[dayEndTimezone]!).keys, imageType: ImageType.Night.rawValue)
			}
			elapsedHours = elapsedHours - 1
		}
		self.lastSyncedTimestamp = utcTimestamp
	}
	
	init(){ 
		// Initialize the total supply and max supply
		self.totalSupply = 0
		self.maxSupply = 10000
		self.traits ={} 
		self.traitTypes ={} 
		self.timezonedWerewolves ={} 
		self.lastSyncedTimestamp = Int(getCurrentBlock().timestamp)
		
		// Set the named paths
		self.CollectionStoragePath = /storage/BarterYardClubWerewolfCollection
		self.CollectionPublicPath = /public/BarterYardClubWerewolfCollection
		self.CollectionPrivatePath = /private/BarterYardClubWerewolfCollection
		self.AdminStoragePath = /storage/BarterYardClubWerewolfAdmin
		self.AdminPrivatePath = /private/BarterYardClubWerewolfAdmin
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&BarterYardClubWerewolf.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		var capability_2 = self.account.capabilities.storage.issue<&BarterYardClubWerewolf.Collection>(BarterYardClubWerewolf.CollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: BarterYardClubWerewolf.CollectionPrivatePath)
		
		// Create an Admin resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		var capability_3 = self.account.capabilities.storage.issue<&BarterYardClubWerewolf.Admin>(BarterYardClubWerewolf.AdminStoragePath)
		self.account.capabilities.publish(capability_3, at: BarterYardClubWerewolf.AdminPrivatePath)
		emit ContractInitialized()
	}
}
