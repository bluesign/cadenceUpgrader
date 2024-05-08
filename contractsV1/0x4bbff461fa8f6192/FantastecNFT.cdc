import FUSD from "./../../standardsV1/FUSD.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FantastecSwapDataV2 from "./FantastecSwapDataV2.cdc"

import FantastecSwapDataProperties from "./FantastecSwapDataProperties.cdc"

import ViewResolver from "./../../standardsV1/ViewResolver.cdc"

access(all)
contract FantastecNFT: NonFungibleToken, ViewResolver{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64)
	
	access(all)
	event Destroyed(id: UInt64, reason: String)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of FantastecNFT that have ever been minted
	access(all)
	var totalSupply: UInt64
	
	access(all)
	struct Item{ 
		access(all)
		let id: UInt64
		
		access(all)
		let cardId: UInt64
		
		access(all)
		let edition: UInt64
		
		access(all)
		let mintNumber: UInt64
		
		access(all)
		let licence: String
		
		access(all)
		let dateMinted: String
		
		access(all)
		let metadata:{ String: String}
		
		init(id: UInt64, cardId: UInt64, edition: UInt64, mintNumber: UInt64, licence: String, dateMinted: String, metadata:{ String: String}){ 
			self.id = id
			self.cardId = cardId
			self.edition = edition
			self.mintNumber = mintNumber
			self.licence = licence
			self.dateMinted = dateMinted
			self.metadata = metadata
		}
	}
	
	// NFT: FantastecNFT.NFT
	// Raw NFT, doesn't currently restrict the caller instantiating an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		access(all)
		let cardId: UInt64
		
		access(all)
		let edition: UInt64
		
		access(all)
		let mintNumber: UInt64
		
		access(all)
		let licence: String
		
		access(all)
		let dateMinted: String
		
		access(all)
		let metadata:{ String: String}
		
		// initializer
		//
		init(item: Item){ 
			self.id = item.id
			self.cardId = item.cardId
			self.edition = item.edition
			self.mintNumber = item.mintNumber
			self.licence = item.licence
			self.dateMinted = item.dateMinted
			self.metadata = item.metadata
		}
		
		access(self)
		fun concatenateStrings(_ strings: [String?]): String{ 
			var res = ""
			for string in strings{ 
				if string != nil{ 
					if res.length > 0{ 
						res = res.concat(", ")
					}
					res = res.concat(string!)
				}
			}
			return res
		}
		
		access(self)
		fun getCard(): FantastecSwapDataV2.CardData?{ 
			let card = FantastecSwapDataV2.getCardById(id: self.cardId)
			return card
		}
		
		access(self)
		fun getCardCollection(): FantastecSwapDataV2.CardCollectionData?{ 
			let card = self.getCard()
			if card != nil{ 
				let cardCollection = FantastecSwapDataV2.getCardCollectionById(id: (card!).collectionId)
				return cardCollection
			}
			return nil
		}
		
		access(self)
		fun getCardRoyalties(): [MetadataViews.Royalty]{ 
			let card = self.getCard()
			let cardMetadata = card?.metadata ??{} 
			let royaltiesMetadata = cardMetadata["royalties"]
			var royalties: [MetadataViews.Royalty] = []
			if royaltiesMetadata != nil{ 
				for royaltyElement in royaltiesMetadata!{ 
					let royalty = royaltyElement as! FantastecSwapDataProperties.Royalty
					let receiver = getAccount(royalty.address).capabilities.get<&FUSD.Vault>(/public/fusdBalance)
					let cut = royalty.percentage / 100.0
					let description = royalty.id.toString()
					royalties.append(MetadataViews.Royalty(receiver: receiver, cut: cut, description: description))
				}
			}
			return royalties
		}
		
		access(self)
		fun getCardMintVolume(): FantastecSwapDataProperties.MintVolume?{ 
			let card = self.getCard()
			let cardMetadata = card?.metadata ??{} 
			let mintVolumeMetadata = cardMetadata["mintVolume"]
			if mintVolumeMetadata != nil && (mintVolumeMetadata!).length > 0{ 
				let mintVolume = (mintVolumeMetadata!)[0] as? FantastecSwapDataProperties.MintVolume
				return mintVolume
			}
			return nil
		}
		
		access(self)
		fun getCardMediaFile(_ mediaType: String): MetadataViews.HTTPFile{ 
			let card = self.getCard()
			let cardMetadata = card?.metadata ??{} 
			let mediaMetadata = cardMetadata["media"]
			if mediaMetadata != nil{ 
				for mediaElement in mediaMetadata!{ 
					let media = mediaElement as! FantastecSwapDataProperties.Media
					if media.mediaType == mediaType{ 
						return MetadataViews.HTTPFile(url: media.url)
					}
				}
			}
			return MetadataViews.HTTPFile(url: "")
		}
		
		access(self)
		fun getCardCollectionMediaFile(_ mediaType: String): MetadataViews.HTTPFile{ 
			let cardCollection = self.getCardCollection()
			let cardCollectionMetadata = cardCollection?.metadata ??{} 
			let mediaMetadata = cardCollectionMetadata["media"]
			if mediaMetadata != nil{ 
				for mediaElement in mediaMetadata!{ 
					let media = mediaElement as! FantastecSwapDataProperties.Media
					if media.mediaType == mediaType{ 
						return MetadataViews.HTTPFile(url: media.url)
					}
				}
			}
			return MetadataViews.HTTPFile(url: "")
		}
		
		access(self)
		fun getCardCollectionSocials():{ String: MetadataViews.ExternalURL}{ 
			let cardCollection = self.getCardCollection()
			let cardCollectionMetadata = cardCollection?.metadata ??{} 
			let socialsMetadata = cardCollectionMetadata["socials"]
			var socialsDictionary:{ String: MetadataViews.ExternalURL} ={} 
			if socialsMetadata != nil{ 
				for socialElement in socialsMetadata!{ 
					let social = socialElement as! FantastecSwapDataProperties.Social
					socialsDictionary[social.type] = MetadataViews.ExternalURL(social.url)
				}
			}
			return socialsDictionary
		}
		
		access(self)
		fun getCardCollectionPartner(): FantastecSwapDataProperties.Partner?{ 
			let cardCollection = self.getCardCollection()
			let cardCollectionMetadata = cardCollection?.metadata ??{} 
			let partnerMetadata = cardCollectionMetadata["partner"]
			if partnerMetadata != nil && (partnerMetadata!).length > 0{ 
				let partner = (partnerMetadata!)[0] as? FantastecSwapDataProperties.Partner
				return partner
			}
			return nil
		}
		
		access(self)
		fun getCardCollectionTeam(): FantastecSwapDataProperties.Team?{ 
			let cardCollection = self.getCardCollection()
			let cardCollectionMetadata = cardCollection?.metadata ??{} 
			let teamMetadata = cardCollectionMetadata["team"]
			if teamMetadata != nil && (teamMetadata!).length > 0{ 
				let team = (teamMetadata!)[0] as? FantastecSwapDataProperties.Team
				return team
			}
			return nil
		}
		
		access(self)
		fun getCardCollectionSeason(): FantastecSwapDataProperties.Season?{ 
			let cardCollection = self.getCardCollection()
			let cardCollectionMetadata = cardCollection?.metadata ??{} 
			let seasonMetadata = cardCollectionMetadata["season"]
			if seasonMetadata != nil && (seasonMetadata!).length > 0{ 
				let season = (seasonMetadata!)[0] as? FantastecSwapDataProperties.Season
				return season
			}
			return nil
		}
		
		access(self)
		fun getCardCollectionPlayer(): FantastecSwapDataProperties.Player?{ 
			let card = self.getCard()
			let cardMetadata = card?.metadata ??{} 
			let playerMetadata = cardMetadata["player"]
			if playerMetadata != nil && (playerMetadata!).length > 0{ 
				let player = (playerMetadata!)[0] as? FantastecSwapDataProperties.Player
				return player
			}
			return nil
		}
		
		access(self)
		fun getCardCollectionRedeemInfo(): FantastecSwapDataProperties.RedeemInfoV2?{ 
			let card = self.getCard()
			let cardMetadata = card?.metadata ??{} 
			let redeemInfoMetadata = cardMetadata["redeemInfo"]
			if redeemInfoMetadata != nil && (redeemInfoMetadata!).length > 0{ 
				let redeemInfo = (redeemInfoMetadata!)[0] as? FantastecSwapDataProperties.RedeemInfoV2
				return redeemInfo
			}
			return nil
		}
		
		access(self)
		fun getNFTCollectionDisplayDescription(): String{ 
			let cardCollection = self.getCardCollection()
			var description = cardCollection?.description
			if description == nil{ 
				let season = self.getCardCollectionSeason()
				let partner = self.getCardCollectionPartner()
				let team = self.getCardCollectionTeam()
				let level = self.getNFTLevel()
				description = self.concatenateStrings([season?.name, partner?.name, team?.name, level?.name])
			}
			return description!
		}
		
		access(self)
		fun extractLevelFromMetadata(metadata:{ String: [{FantastecSwapDataProperties.MetadataElement}]}): FantastecSwapDataProperties.Level?{ 
			let levelMetadata = metadata["level"]
			if levelMetadata != nil && (levelMetadata!).length > 0{ 
				let level = (levelMetadata!)[0] as? FantastecSwapDataProperties.Level
				return level
			}
			return nil
		}
		
		access(self)
		fun getNFTLevel(): FantastecSwapDataProperties.Level?{ 
			// If the card has a level, use that - otherwise use the collection level
			let card = self.getCard()
			let cardMetadata = card?.metadata ??{} 
			var level = self.extractLevelFromMetadata(metadata: cardMetadata)
			if level == nil{ 
				let cardCollection = self.getCardCollection()
				let cardCollectionMetadata = cardCollection?.metadata ??{} 
				level = self.extractLevelFromMetadata(metadata: cardCollectionMetadata)
			}
			return level
		}
		
		access(self)
		fun getNFTMintVolume(): UInt64?{ 
			// If the card has a mint volume, use that - otherwise use the collection mint volume
			let cardMintVolume = self.getCardMintVolume()
			// Card mint volume is stored in metadata
			if cardMintVolume != nil{ 
				return (cardMintVolume!).value
			}
			let cardCollection = self.getCardCollection()
			if cardCollection != nil{ 
				return (cardCollection!).mintVolume
			}
			return nil
		}
		
		access(self)
		fun getTraits(): MetadataViews.Traits{ 
			let traits = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: [])
			let dateMintedTrait = MetadataViews.Trait(name: "DateMinted", value: self.dateMinted, displayType: nil, rarity: nil)
			traits.addTrait(dateMintedTrait)
			let partner = self.getCardCollectionPartner()
			if partner != nil{ 
				let partnerTrait = MetadataViews.Trait(name: "Partner", value: (partner!).name, displayType: nil, rarity: nil)
				traits.addTrait(partnerTrait)
			}
			let season = self.getCardCollectionSeason()
			if season != nil{ 
				let year = (season!).startDate.concat("-").concat((season!).endDate)
				let yearTrait = MetadataViews.Trait(name: "Year", value: year, displayType: nil, rarity: nil)
				traits.addTrait(yearTrait)
			}
			let team = self.getCardCollectionTeam()
			if team != nil{ 
				let teamTrait = MetadataViews.Trait(name: "TeamName", value: (team!).name, displayType: nil, rarity: nil)
				traits.addTrait(teamTrait)
				let teamGenderTrait = MetadataViews.Trait(name: "TeamGender", value: (team!).gender, displayType: nil, rarity: nil)
				traits.addTrait(teamGenderTrait)
			}
			let player = self.getCardCollectionPlayer()
			if player != nil{ 
				let playerNameTrait = MetadataViews.Trait(name: "PlayerName", value: (player!).name, displayType: nil, rarity: nil)
				traits.addTrait(playerNameTrait)
				let playerGenderTrait = MetadataViews.Trait(name: "PlayerGender", value: (player!).gender, displayType: nil, rarity: nil)
				traits.addTrait(playerGenderTrait)
				if (player!).shirtNumber != nil{ 
					let shirtNumberTrait = MetadataViews.Trait(name: "PlayerShirtNumber", value: (player!).shirtNumber, displayType: nil, rarity: nil)
					traits.addTrait(shirtNumberTrait)
				}
				if (player!).position != nil{ 
					let positionTrait = MetadataViews.Trait(name: "PlayerPosition", value: (player!).position, displayType: nil, rarity: nil)
					traits.addTrait(positionTrait)
				}
			}
			let redeemInfo = self.getCardCollectionRedeemInfo()
			if redeemInfo != nil{ 
				let retailerIdTrait = MetadataViews.Trait(name: "RetailerId", value: (redeemInfo!).id, displayType: nil, rarity: nil)
				traits.addTrait(retailerIdTrait)
				let retailerNameTrait = MetadataViews.Trait(name: "RetailerName", value: (redeemInfo!).retailerName, displayType: nil, rarity: nil)
				traits.addTrait(retailerNameTrait)
				let retailerPinHashTrait = MetadataViews.Trait(name: "RetailerPinHash", value: (redeemInfo!).retailerPinHash, displayType: nil, rarity: nil)
				traits.addTrait(retailerPinHashTrait)
				let retailerAddressTrait = MetadataViews.Trait(name: "RetailerAddress", value: (redeemInfo!).retailerAddress, displayType: nil, rarity: nil)
				traits.addTrait(retailerAddressTrait)
				if (redeemInfo!).validFrom != nil{ 
					let validFromTrait = MetadataViews.Trait(name: "ValidFrom", value: (redeemInfo!).validFrom, displayType: nil, rarity: nil)
					traits.addTrait(validFromTrait)
				}
				if (redeemInfo!).validTo != nil{ 
					let validFromTrait = MetadataViews.Trait(name: "ValidTo", value: (redeemInfo!).validFrom, displayType: nil, rarity: nil)
					traits.addTrait(validFromTrait)
				}
				if (redeemInfo!).type != nil{ 
					let redeemTypeTrait = MetadataViews.Trait(name: "RedeemType", value: (redeemInfo!).type, displayType: nil, rarity: nil)
					traits.addTrait(redeemTypeTrait)
				}
				if (redeemInfo!).t_and_cs != nil{ 
					let tAndCsTrait = MetadataViews.Trait(name: "TAndCs", value: (redeemInfo!).t_and_cs, displayType: nil, rarity: nil)
					traits.addTrait(tAndCsTrait)
				}
				if (redeemInfo!).description != nil{ 
					let descriptionTrait = MetadataViews.Trait(name: "Description", value: (redeemInfo!).description, displayType: nil, rarity: nil)
					traits.addTrait(descriptionTrait)
				}
			}
			let card = self.getCard()
			if card != nil{ 
				let cardIdTrait = MetadataViews.Trait(name: "CardId", value: (card!).id, displayType: nil, rarity: nil)
				traits.addTrait(cardIdTrait)
				let cardTypeTrait = MetadataViews.Trait(name: "CardType", value: (card!).type, displayType: nil, rarity: nil)
				traits.addTrait(cardTypeTrait)
				let cardAspectRatioTrait = MetadataViews.Trait(name: "CardAspectRatio", value: (card!).aspectRatio, displayType: nil, rarity: nil)
				traits.addTrait(cardAspectRatioTrait)
				let collectionIdTrait = MetadataViews.Trait(name: "CollectionId", value: (card!).collectionId, displayType: nil, rarity: nil)
				traits.addTrait(collectionIdTrait)
			}
			let mintVolume = self.getNFTMintVolume()
			if mintVolume != nil{ 
				let mintVolumeTrait = MetadataViews.Trait(name: "MintVolume", value: mintVolume!, displayType: nil, rarity: nil)
				traits.addTrait(mintVolumeTrait)
			}
			return traits
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					let card = self.getCard()
					if card == nil{ 
						return nil
					}
					let name = (card!).name
					let cardCollection = self.getCardCollection()
					var description = cardCollection != nil ? name.concat(", ").concat((cardCollection!).title) : name
					let level = self.getNFTLevel()
					if level != nil{ 
						description = description.concat(", ").concat((level!).name)
					}
					var thumbnail = self.getCardMediaFile("CARD_THUMBNAIL")
					let display = MetadataViews.Display(name: name, description: description, thumbnail: thumbnail)
					return display
				case Type<MetadataViews.Medias>():
					let items: [MetadataViews.Media] = []
					let animation = self.getCardMediaFile("CARD_ANIMATION")
					if animation.uri() != ""{ 
						let animationMedia = MetadataViews.Media(file: animation, mediaType: "video/mp4")
						items.append(animationMedia)
					}
					let frame = self.getCardMediaFile("CARD_FRAME")
					if frame.uri() != ""{ 
						let frameMedia = MetadataViews.Media(file: frame, mediaType: "video/mp4")
						items.append(frameMedia)
					}
					let image = self.getCardMediaFile("CARD_IMAGE")
					if image.uri() != ""{ 
						let imageMedia = MetadataViews.Media(file: image, mediaType: "image/png") // TODO: get file extensiuon
						
						items.append(imageMedia)
					}
					let thumbnail = self.getCardMediaFile("CARD_THUMBNAIL")
					if thumbnail.uri() != ""{ 
						let thumbnailMedia = MetadataViews.Media(file: thumbnail, mediaType: "image/jpeg")
						items.append(thumbnailMedia)
					}
					let medias = MetadataViews.Medias(items)
					return medias
				case Type<MetadataViews.Editions>():
					let card = self.getCard()
					if card == nil{ 
						return nil
					}
					let name = (card!).name
					let number = self.mintNumber
					let cardCollection = self.getCardCollection()
					var max: UInt64? = self.getNFTMintVolume() ?? 0
					if max! < number{ 
						max = nil
					}
					let editionInfo = MetadataViews.Edition(name: name, number: number, max: max)
					return MetadataViews.Editions([editionInfo])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://www.fantastec-swap.io/nft/view?id=".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: FantastecNFT.CollectionStoragePath, publicPath: FantastecNFT.CollectionPublicPath, publicCollection: Type<&FantastecNFT.Collection>(), publicLinkedType: Type<&FantastecNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-FantastecNFT.createEmptyCollection(nftType: Type<@FantastecNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let cardCollection = self.getCardCollection()
					let name = cardCollection?.title ?? ""
					let description = self.getNFTCollectionDisplayDescription()
					let squareImageMedia = MetadataViews.Media(file: self.getCardCollectionMediaFile("COLLECTION_LOGO_IMAGE"), mediaType: "image/png")
					let bannerImageMedia = MetadataViews.Media(file: self.getCardCollectionMediaFile("COLLECTION_HEADER_IMAGE"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: name, description: description, externalURL: MetadataViews.ExternalURL(""), squareImage: squareImageMedia, bannerImage: bannerImageMedia, socials: self.getCardCollectionSocials())
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.uuid)
				case Type<MetadataViews.Traits>():
					return self.getTraits()
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.getCardRoyalties())
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// This is the interface that users can cast their FantastecNFT Collection as
	// to allow others to deposit FantastecNFTs into their Collection. It also allows for reading
	// the details of FantastecNFTs in the Collection.
	access(all)
	resource interface FantastecNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowFantastecNFT(id: UInt64): &FantastecNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow FantastecNFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of Moment NFTs owned by an account
	//
	access(all)
	resource Collection: FantastecNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an UInt64 ID field
		// metadataObjs is a dictionary of metadata mapped to NFT IDs
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @FantastecNFT.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			// TODO: This should never happen
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			if oldToken != nil{ 
				emit Destroyed(id: id, reason: "replaced existing resource with the same id")
			}
			destroy oldToken
		}
		
		// getIDs
		// Returns an array of the IDs that are in the collection
		//
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowFantastecNFT
		// Gets a reference to an NFT in the collection as a FantastecNFT,
		// exposing all of its fields.
		// This is safe as there are no functions that can be called on the FantastecNFT.
		//
		access(all)
		fun borrowFantastecNFT(id: UInt64): &FantastecNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref! as! &FantastecNFT.NFT
			} else{ 
				return nil
			}
		}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let fantastecNFT = nft as! &FantastecNFT.NFT
			return fantastecNFT as &{ViewResolver.Resolver}
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
		
		// destructor
		// initializer
		//
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// NFTMinter
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		// Mints a new NFTs
		// Increments mintNumber
		// returns the newly minted NFT
		//
		access(all)
		fun mintAndReturnNFT(cardId: UInt64, edition: UInt64, mintNumber: UInt64, licence: String, dateMinted: String, metadata:{ String: String}): @FantastecNFT.NFT{ 
			let newId = FantastecNFT.totalSupply + 1 as UInt64
			let nftData: Item = Item(id: FantastecNFT.totalSupply, cardId: cardId, edition: edition, mintNumber: mintNumber, licence: licence, dateMinted: dateMinted, metadata: metadata)
			var newNFT <- create FantastecNFT.NFT(item: nftData)
			
			// emit and update contract
			emit Minted(id: nftData.id)
			
			// update contracts
			FantastecNFT.totalSupply = newId
			return <-newNFT
		}
		
		// Mints a new NFTs
		// Increments mintNumber
		// deposits the NFT into the recipients collection using their collection reference
		//
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, cardId: UInt64, edition: UInt64, mintNumber: UInt64, licence: String, dateMinted: String, metadata:{ String: String}){ 
			var newNFT <- self.mintAndReturnNFT(cardId: cardId, edition: edition, mintNumber: mintNumber, licence: licence, dateMinted: dateMinted, metadata: metadata)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
		}
	}
	
	/// Function that resolves a metadata view for this contract.
	///
	/// @param view: The Type of the desired view.
	/// @return A structure representing the requested view.
	///
	access(all)
	fun resolveView(_ view: Type): AnyStruct?{ 
		switch view{ 
			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(storagePath: FantastecNFT.CollectionStoragePath, publicPath: FantastecNFT.CollectionPublicPath, publicCollection: Type<&FantastecNFT.Collection>(), publicLinkedType: Type<&FantastecNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
						return <-FantastecNFT.createEmptyCollection(nftType: Type<@FantastecNFT.Collection>())
					})
			case Type<MetadataViews.NFTCollectionDisplay>():
				return MetadataViews.NFTCollectionDisplay(name: "Fantastec SWAP", description: "Collect and Swap NFTs created exclusively for European Football clubs Real Madrid Mens and Womens, Arsenal Mens and Womens, Borussia Dortmund, and US College Athletes at Michigan State University, University of Michigan, University of Illinois, and Syracuse University.", externalURL: MetadataViews.ExternalURL("https://fantastec-swap.io"), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://bafkreihvx3vfgnpn4ygfdcq4w7pdlamw4maasok7xuzcfoutm3lbitwprm.ipfs.nftstorage.link/"), mediaType: "image/jpeg"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://bafybeicadjtenkcpdts3rf43a7dgcjjfasihcaed46yxkdgvehj4m33ate.ipfs.nftstorage.link/"), mediaType: "image/jpeg"), socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/fantastecSWAP")})
		}
		return nil
	}
	
	/// Function that returns all the Metadata Views implemented by a Non Fungible Token
	///
	/// @return An array of Types defining the implemented views. This value will be used by
	///		 developers to know which parameter to pass to the resolveView() method.
	///
	access(all)
	fun getViews(): [Type]{ 
		return [Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
	}
	
	access(all)
	fun getTotalSupply(): UInt64{ 
		return FantastecNFT.totalSupply
	}
	
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/FantastecNFTCollection
		self.CollectionPublicPath = /public/FantastecNFTCollection
		self.MinterStoragePath = /storage/FantastecNFTMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		let oldMinter <- self.account.storage.load<@NFTMinter>(from: self.MinterStoragePath)
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		destroy oldMinter
		emit ContractInitialized()
	}
}
