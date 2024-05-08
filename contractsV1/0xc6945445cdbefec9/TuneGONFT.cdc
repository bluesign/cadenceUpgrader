import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

// Contract
//
access(all)
contract TuneGONFT: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, itemId: String, edition: UInt64, royalties: [RoyaltyData], additionalInfo:{ String: String})
	
	access(all)
	event Destroyed(id: UInt64)
	
	access(all)
	event Burned(id: UInt64)
	
	access(all)
	event Claimed(id: UInt64, type: String, recipient: Address, tag: String?)
	
	access(all)
	event ClaimedReward(id: String, recipient: Address)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of TuneGONFT that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// itemEditions
	//
	access(contract)
	var itemEditions:{ String: UInt64}
	
	// Default Collection Metadata
	access(all)
	struct CollectionMetadata{ 
		access(all)
		let collectionName: String
		
		access(all)
		let collectionDescription: String
		
		access(all)
		let collectionURL: String
		
		access(all)
		let collectionMedia: String
		
		access(all)
		let collectionMediaMimeType: String
		
		access(all)
		let collectionMediaBanner: String?
		
		access(all)
		let collectionMediaBannerMimeType: String?
		
		access(all)
		let collectionSocials:{ String: String}
		
		init(collectionName: String, collectionDescription: String, collectionURL: String, collectionMedia: String, collectionMediaMimeType: String, collectionMediaBanner: String?, collectionMediaBannerMimeType: String?, collectionSocials:{ String: String}){ 
			self.collectionName = collectionName
			self.collectionDescription = collectionDescription
			self.collectionURL = collectionURL
			self.collectionMedia = collectionMedia
			self.collectionMediaMimeType = collectionMediaMimeType
			self.collectionMediaBanner = collectionMediaBanner
			self.collectionMediaBannerMimeType = collectionMediaBannerMimeType
			self.collectionSocials = collectionSocials
		}
	}
	
	access(all)
	fun getDefaultCollectionMetadata(): CollectionMetadata{ 
		let media = "https://www.tunegonft.com/assets/images/tunego-beta-logo.png"
		return TuneGONFT.CollectionMetadata(collectionName: "TuneGO NFT", collectionDescription: "Unique music collectibles from the TuneGO Community", collectionURL: "https://www.tunegonft.com/", collectionMedia: media, collectionMediaMimeType: "image/png", collectionMediaBanner: media, collectionMediaBannerMimeType: "image/png", collectionSocials:{ "discord": "https://discord.gg/nsGnsRbMke", "facebook": "https://www.facebook.com/tunego", "instagram": "https://www.instagram.com/tunego", "twitter": "https://twitter.com/TuneGONFT", "tiktok": "https://www.tiktok.com/@tunegoadmin?lang=en"})
	}
	
	// Metadata
	//
	access(all)
	struct Metadata{ 
		access(all)
		let title: String
		
		access(all)
		let description: String
		
		access(all)
		let creator: String
		
		access(all)
		let asset: String
		
		access(all)
		let assetMimeType: String
		
		access(all)
		let assetHash: String
		
		access(all)
		let artwork: String
		
		access(all)
		let artworkMimeType: String
		
		access(all)
		let artworkHash: String
		
		access(all)
		let artworkAlternate: String?
		
		access(all)
		let artworkAlternateMimeType: String?
		
		access(all)
		let artworkAlternateHash: String?
		
		access(all)
		let thumbnail: String
		
		access(all)
		let thumbnailMimeType: String
		
		access(all)
		let termsUrl: String
		
		access(all)
		let rarity: String?
		
		access(all)
		let credits: String?
		
		// Collection information
		access(all)
		let collectionName: String?
		
		access(all)
		let collectionDescription: String?
		
		access(all)
		let collectionURL: String?
		
		access(all)
		let collectionMedia: String?
		
		access(all)
		let collectionMediaMimeType: String?
		
		access(all)
		let collectionMediaBanner: String?
		
		access(all)
		let collectionMediaBannerMimeType: String?
		
		access(all)
		let collectionSocials:{ String: String}?
		
		// Miscellaneous
		access(all)
		let mintedBlock: UInt64
		
		access(all)
		let mintedTime: UFix64
		
		init(title: String, description: String, creator: String, asset: String, assetMimeType: String, assetHash: String, artwork: String, artworkMimeType: String, artworkHash: String, artworkAlternate: String?, artworkAlternateMimeType: String?, artworkAlternateHash: String?, thumbnail: String, thumbnailMimeType: String, termsUrl: String, rarity: String?, credits: String?, collectionName: String?, collectionDescription: String?, collectionURL: String?, collectionMedia: String?, collectionMediaMimeType: String?, collectionMediaBanner: String?, collectionMediaBannerMimeType: String?, collectionSocials:{ String: String}?, mintedBlock: UInt64, mintedTime: UFix64){ 
			if collectionName != nil{ 
				assert(collectionDescription != nil, message: "Missing collectionDescription")
				assert(collectionURL != nil, message: "Missing collectionURL")
				assert(collectionMedia != nil, message: "Missing collectionMedia")
				assert(collectionMediaMimeType != nil, message: "Missing collectionMediaMimeType")
				assert(collectionSocials != nil, message: "Missing collectionSocials")
			}
			self.title = title
			self.description = description
			self.creator = creator
			self.asset = asset
			self.assetMimeType = assetMimeType
			self.assetHash = assetHash
			self.artwork = artwork
			self.artworkMimeType = artworkMimeType
			self.artworkHash = artworkHash
			self.artworkAlternate = artworkAlternate
			self.artworkAlternateMimeType = artworkAlternateMimeType
			self.artworkAlternateHash = artworkAlternateHash
			self.thumbnail = thumbnail
			self.thumbnailMimeType = thumbnailMimeType
			self.termsUrl = termsUrl
			self.credits = credits
			self.rarity = rarity
			self.collectionName = collectionName
			self.collectionDescription = collectionDescription
			self.collectionURL = collectionURL
			self.collectionMedia = collectionMedia
			self.collectionMediaMimeType = collectionMediaMimeType
			self.collectionMediaBanner = collectionMediaBanner
			self.collectionMediaBannerMimeType = collectionMediaBannerMimeType
			self.collectionSocials = collectionSocials
			self.mintedBlock = mintedBlock
			self.mintedTime = mintedTime
		}
		
		access(all)
		fun getCollectionMetadata(): CollectionMetadata{ 
			if self.collectionName != nil{ 
				return TuneGONFT.CollectionMetadata(collectionName: self.collectionName!, collectionDescription: self.collectionDescription!, collectionURL: self.collectionURL!, collectionMedia: self.collectionMedia!, collectionMediaMimeType: self.collectionMediaMimeType!, collectionMediaBanner: self.collectionMediaBanner, collectionMediaBannerMimeType: self.collectionMediaBannerMimeType, collectionSocials: self.collectionSocials!)
			}
			return TuneGONFT.getDefaultCollectionMetadata()
		}
		
		access(all)
		fun toDict():{ String: AnyStruct?}{ 
			let rawMetadata:{ String: AnyStruct?} ={} 
			rawMetadata.insert(key: "title", self.title)
			rawMetadata.insert(key: "description", self.description)
			rawMetadata.insert(key: "creator", self.creator)
			if self.asset.length == 0{ 
				rawMetadata.insert(key: "asset", nil)
				rawMetadata.insert(key: "assetMimeType", nil)
				rawMetadata.insert(key: "assetHash", nil)
			} else{ 
				rawMetadata.insert(key: "asset", self.asset)
				rawMetadata.insert(key: "assetMimeType", self.assetMimeType)
				rawMetadata.insert(key: "assetHash", self.assetHash)
			}
			rawMetadata.insert(key: "artwork", self.artwork)
			rawMetadata.insert(key: "artworkMimeType", self.artworkMimeType)
			rawMetadata.insert(key: "artworkHash", self.artworkHash)
			rawMetadata.insert(key: "artworkAlternate", self.artworkAlternate)
			rawMetadata.insert(key: "artworkAlternateMimeType", self.artworkAlternateMimeType)
			rawMetadata.insert(key: "artworkAlternateHash", self.artworkAlternateHash)
			rawMetadata.insert(key: "thumbnail", self.thumbnail)
			rawMetadata.insert(key: "thumbnailMimeType", self.thumbnailMimeType)
			rawMetadata.insert(key: "termsUrl", self.termsUrl)
			rawMetadata.insert(key: "rarity", self.rarity)
			rawMetadata.insert(key: "credits", self.credits)
			let collectionSource = self.getCollectionMetadata()
			rawMetadata.insert(key: "collectionName", collectionSource.collectionName)
			rawMetadata.insert(key: "collectionDescription", collectionSource.collectionDescription)
			rawMetadata.insert(key: "collectionURL", collectionSource.collectionURL)
			rawMetadata.insert(key: "collectionMedia", collectionSource.collectionMedia)
			rawMetadata.insert(key: "collectionMediaMimeType", collectionSource.collectionMediaMimeType)
			rawMetadata.insert(key: "collectionMediaBanner", collectionSource.collectionMediaBanner ?? collectionSource.collectionMedia)
			rawMetadata.insert(key: "collectionMediaBannerMimeType", collectionSource.collectionMediaBannerMimeType ?? collectionSource.collectionMediaBannerMimeType)
			rawMetadata.insert(key: "collectionSocials", collectionSource.collectionSocials)
			rawMetadata.insert(key: "mintedBlock", self.mintedBlock)
			rawMetadata.insert(key: "mintedTime", self.mintedTime)
			return rawMetadata
		}
		
		access(all)
		fun toStringDict():{ String: String?}{ 
			let rawMetadata:{ String: String?} ={} 
			rawMetadata.insert(key: "title", self.title)
			rawMetadata.insert(key: "description", self.description)
			rawMetadata.insert(key: "creator", self.creator)
			if self.asset.length == 0{ 
				rawMetadata.insert(key: "asset", nil)
				rawMetadata.insert(key: "assetMimeType", nil)
				rawMetadata.insert(key: "assetHash", nil)
			} else{ 
				rawMetadata.insert(key: "asset", self.asset)
				rawMetadata.insert(key: "assetMimeType", self.assetMimeType)
				rawMetadata.insert(key: "assetHash", self.assetHash)
			}
			rawMetadata.insert(key: "artwork", self.artwork)
			rawMetadata.insert(key: "artworkMimeType", self.artworkMimeType)
			rawMetadata.insert(key: "artworkHash", self.artworkHash)
			rawMetadata.insert(key: "artworkAlternate", self.artworkAlternate)
			rawMetadata.insert(key: "artworkAlternateMimeType", self.artworkAlternateMimeType)
			rawMetadata.insert(key: "artworkAlternateHash", self.artworkAlternateHash)
			rawMetadata.insert(key: "thumbnail", self.thumbnail)
			rawMetadata.insert(key: "thumbnailMimeType", self.thumbnailMimeType)
			rawMetadata.insert(key: "termsUrl", self.termsUrl)
			rawMetadata.insert(key: "rarity", self.rarity)
			rawMetadata.insert(key: "credits", self.credits)
			let collectionSource = self.getCollectionMetadata()
			rawMetadata.insert(key: "collectionName", collectionSource.collectionName)
			rawMetadata.insert(key: "collectionDescription", collectionSource.collectionDescription)
			rawMetadata.insert(key: "collectionURL", collectionSource.collectionURL)
			rawMetadata.insert(key: "collectionMedia", collectionSource.collectionMedia)
			rawMetadata.insert(key: "collectionMediaMimeType", collectionSource.collectionMediaMimeType)
			rawMetadata.insert(key: "collectionMediaBanner", collectionSource.collectionMediaBanner ?? collectionSource.collectionMedia)
			rawMetadata.insert(key: "collectionMediaBannerMimeType", collectionSource.collectionMediaBannerMimeType ?? collectionSource.collectionMediaBannerMimeType)
			rawMetadata.insert(key: "mintedBlock", self.mintedBlock.toString())
			rawMetadata.insert(key: "mintedTime", self.mintedTime.toString())
			
			// Socials
			for key in (collectionSource.collectionSocials!).keys{ 
				rawMetadata.insert(key: "collectionSocials_".concat(key), (collectionSource.collectionSocials!)[key])
			}
			return rawMetadata
		}
	}
	
	// Edition
	//
	access(all)
	struct Edition{ 
		access(all)
		let edition: UInt64
		
		access(all)
		let totalEditions: UInt64
		
		init(edition: UInt64, totalEditions: UInt64){ 
			self.edition = edition
			self.totalEditions = totalEditions
		}
	}
	
	access(all)
	fun editionCirculatingKey(itemId: String): String{ 
		return "circulating:".concat(itemId)
	}
	
	// RoyaltyData
	//
	access(all)
	struct RoyaltyData{ 
		access(all)
		let receiver: Address
		
		access(all)
		let percentage: UFix64
		
		init(receiver: Address, percentage: UFix64){ 
			self.receiver = receiver
			self.percentage = percentage
		}
	}
	
	// NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let itemId: String
		
		access(all)
		let edition: UInt64
		
		access(self)
		let metadata: Metadata
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		access(self)
		let additionalInfo:{ String: String}
		
		init(id: UInt64, itemId: String, edition: UInt64, metadata: Metadata, royalties: [MetadataViews.Royalty], additionalInfo:{ String: String}){ 
			self.id = id
			self.itemId = itemId
			self.edition = edition
			self.metadata = metadata
			self.royalties = royalties
			self.additionalInfo = additionalInfo
		}
		
		access(all)
		fun getAdditionalInfo():{ String: String}{ 
			return self.additionalInfo
		}
		
		access(all)
		fun totalEditions(): UInt64{ 
			return TuneGONFT.itemEditions[self.itemId] ?? UInt64(0)
		}
		
		access(all)
		fun circulatingEditions(): UInt64{ 
			return TuneGONFT.itemEditions[TuneGONFT.editionCirculatingKey(itemId: self.itemId)] ?? self.totalEditions()
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<Metadata>(), Type<Edition>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Display>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<Metadata>():
					return self.metadata
				case Type<Edition>():
					return Edition(edition: self.edition, totalEditions: self.totalEditions())
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.metadata.title, description: self.metadata.description, thumbnail: MetadataViews.HTTPFile(url: self.metadata.thumbnail))
				case Type<MetadataViews.Editions>():
					let editionInfo = MetadataViews.Edition(name: "TuneGO NFT", number: self.edition, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.edition)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://www.tunegonft.com/view-collectible/".concat(self.uuid.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: TuneGONFT.CollectionStoragePath, publicPath: TuneGONFT.CollectionPublicPath, publicCollection: Type<&TuneGONFT.Collection>(), publicLinkedType: Type<&TuneGONFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-TuneGONFT.createEmptyCollection(nftType: Type<@TuneGONFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let collectionMetadata = self.metadata.getCollectionMetadata()
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: collectionMetadata.collectionMedia), mediaType: collectionMetadata.collectionMediaMimeType)
					let mediaBanner = collectionMetadata.collectionMediaBanner != nil ? MetadataViews.Media(file: MetadataViews.HTTPFile(url: collectionMetadata.collectionMediaBanner!), mediaType: collectionMetadata.collectionMediaBannerMimeType!) : media
					let socials:{ String: MetadataViews.ExternalURL} ={} 
					for key in collectionMetadata.collectionSocials.keys{ 
						socials.insert(key: key, MetadataViews.ExternalURL((collectionMetadata.collectionSocials!)[key]!))
					}
					return MetadataViews.NFTCollectionDisplay(name: collectionMetadata.collectionName, description: collectionMetadata.collectionDescription, externalURL: MetadataViews.ExternalURL(collectionMetadata.collectionURL), squareImage: media, bannerImage: mediaBanner, socials: socials)
				case Type<MetadataViews.Traits>():
					let excludedTraits = ["mintedTime"]
					let dict = self.metadata.toDict()
					dict.forEachKey(fun (key: String): Bool{ 
							if dict[key] == nil{ 
								dict.remove(key: key)
							}
							return false
						})
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata.toDict(), excludedNames: excludedTraits)
					
					// mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
					let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata.mintedTime!, displayType: "Date", rarity: nil)
					traitsView.addTrait(mintedTimeTrait)
					return traitsView
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	
	// If the Collectible is destroyed, emit an event
	}
	
	// TuneGONFTCollectionPublic
	//
	access(all)
	resource interface TuneGONFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowTuneGONFT(id: UInt64): &TuneGONFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow TuneGONFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	//
	access(all)
	resource Collection: TuneGONFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @TuneGONFT.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowTuneGONFT(id: UInt64): &TuneGONFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &TuneGONFT.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let tunegoNFT = nft as! &TuneGONFT.NFT
			return tunegoNFT as &{ViewResolver.Resolver}
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
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// createEmptyCollection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// burnNFTs
	//
	access(all)
	fun burnNFTs(nfts: @{UInt64: TuneGONFT.NFT}){ 
		let toBurn: Int = nfts.keys.length
		var nftItemID: String? = nil
		for nftID in nfts.keys{ 
			let nft <- nfts.remove(key: nftID)!
			assert(nft.id == nftID, message: "Invalid nftID")
			nftItemID = nftItemID ?? nft.itemId
			assert(nftItemID == nft.itemId, message: "All burned NFTs must have the same itemID")
			assert(Int64(nft.edition) > Int64(nft.circulatingEditions()) - Int64(toBurn), message: "Invalid NFT edition to burn")
			TuneGONFT.itemEditions[TuneGONFT.editionCirculatingKey(itemId: nftItemID!)] = nft.circulatingEditions() - UInt64(1)
			destroy nft
			emit Burned(id: nftID)
		}
		destroy nfts
	}
	
	// Claiming
	access(all)
	fun claimNFT(nft: @{NonFungibleToken.NFT}, receiver: &{NonFungibleToken.Receiver}, tag: String?){ 
		let id = nft.id
		let type = nft.getType().identifier
		let recipient = receiver.owner?.address ?? panic("Receiver must be owned")
		receiver.deposit(token: <-nft)
		emit Claimed(id: id, type: type, recipient: recipient, tag: tag)
	}
	
	// NFTMinter
	//
	access(all)
	resource NFTMinter{ 
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, itemId: String, metadata: Metadata, royalties: [MetadataViews.Royalty], additionalInfo:{ String: String}){ 
			assert(TuneGONFT.itemEditions[TuneGONFT.editionCirculatingKey(itemId: itemId)] == nil, message: "New NFTs cannot be minted")
			var totalRoyaltiesPercentage: UFix64 = 0.0
			let royaltiesData: [RoyaltyData] = []
			for royalty in royalties{ 
				assert(royalty.receiver.borrow() != nil, message: "Missing royalty receiver")
				let receiverAccount = getAccount(royalty.receiver.address)
				let receiverDUCVaultCapability = receiverAccount.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
				assert(receiverDUCVaultCapability.borrow() != nil, message: "Missing royalty receiver DapperUtilityCoin vault")
				let royaltyPercentage = royalty.cut * 100.0
				royaltiesData.append(RoyaltyData(receiver: receiverAccount.address, percentage: royaltyPercentage))
				totalRoyaltiesPercentage = totalRoyaltiesPercentage + royaltyPercentage
			}
			assert(totalRoyaltiesPercentage <= 95.0, message: "Total royalties percentage is too high")
			let totalEditions = TuneGONFT.itemEditions[itemId] != nil ? TuneGONFT.itemEditions[itemId] : UInt64(0)
			let edition = totalEditions! + UInt64(1)
			emit Minted(id: TuneGONFT.totalSupply, itemId: itemId, edition: edition, royalties: royaltiesData, additionalInfo: additionalInfo)
			recipient.deposit(token: <-create TuneGONFT.NFT(id: TuneGONFT.totalSupply, itemId: itemId, edition: edition, metadata: metadata, royalties: royalties, additionalInfo: additionalInfo))
			TuneGONFT.itemEditions[itemId] = totalEditions! + UInt64(1)
			TuneGONFT.totalSupply = TuneGONFT.totalSupply + UInt64(1)
		}
		
		access(all)
		fun batchMintNFTOld(recipient: &{NonFungibleToken.CollectionPublic}, itemId: String, metadata: Metadata, royalties: [MetadataViews.Royalty], additionalInfo:{ String: String}, quantity: UInt64){ 
			var i: UInt64 = 0
			while i < quantity{ 
				i = i + UInt64(1)
				self.mintNFT(recipient: recipient, itemId: itemId, metadata: metadata, royalties: royalties, additionalInfo: additionalInfo)
			}
		}
		
		access(all)
		fun batchMintNFT(recipient: &{NonFungibleToken.CollectionPublic}, itemId: String, metadata: Metadata, royalties: [MetadataViews.Royalty], additionalInfo:{ String: String}, quantity: UInt64){ 
			assert(TuneGONFT.itemEditions[TuneGONFT.editionCirculatingKey(itemId: itemId)] == nil, message: "New NFTs cannot be minted")
			var totalRoyaltiesPercentage: UFix64 = 0.0
			let royaltiesData: [RoyaltyData] = []
			for royalty in royalties{ 
				assert(royalty.receiver.borrow() != nil, message: "Missing royalty receiver")
				let receiverAccount = getAccount(royalty.receiver.address)
				let receiverDUCVaultCapability = receiverAccount.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
				assert(receiverDUCVaultCapability.borrow() != nil, message: "Missing royalty receiver DapperUtilityCoin vault")
				let royaltyPercentage = royalty.cut * 100.0
				royaltiesData.append(RoyaltyData(receiver: receiverAccount.address, percentage: royaltyPercentage))
				totalRoyaltiesPercentage = totalRoyaltiesPercentage + royaltyPercentage
			}
			assert(totalRoyaltiesPercentage <= 95.0, message: "Total royalties percentage is too high")
			let totalEditions = TuneGONFT.itemEditions[itemId] != nil ? TuneGONFT.itemEditions[itemId]! : UInt64(0)
			var i: UInt64 = 0
			while i < quantity{ 
				let id = TuneGONFT.totalSupply + i
				i = i + UInt64(1)
				let edition = totalEditions + i
				emit Minted(id: id, itemId: itemId, edition: edition, royalties: royaltiesData, additionalInfo: additionalInfo)
				recipient.deposit(token: <-create TuneGONFT.NFT(id: id, itemId: itemId, edition: edition, metadata: metadata, royalties: royalties, additionalInfo: additionalInfo))
			}
			TuneGONFT.itemEditions[itemId] = totalEditions + quantity
			TuneGONFT.totalSupply = TuneGONFT.totalSupply + quantity
		}
		
		access(all)
		fun checkIncClaim(id: String, address: Address, max: UInt16): Bool{ 
			return TuneGONFT.loadMetadataStorage().checkIncClaim(id: id, address: address, max: max)
		}
		
		access(all)
		fun readClaims(id: String, addresses: [Address]):{ Address: UInt16}{ 
			let storage = TuneGONFT.loadMetadataStorage()
			let res:{ Address: UInt16} ={} 
			for address in addresses{ 
				let claims:{ String: UInt16} = storage.claims[address] ??{} 
				res[address] = claims[id] ?? UInt16(0)
			}
			return res
		}
		
		access(all)
		fun emitClaimedReward(id: String, address: Address){ 
			emit ClaimedReward(id: id, recipient: address)
		}
		
		access(all)
		fun createNFTMinter(): @NFTMinter{ 
			return <-create NFTMinter()
		}
	}
	
	access(all)
	resource MetadataStorage{ 
		access(account)
		let metadatas:{ String: Metadata}
		
		access(account)
		let royalties:{ String:{ Address: UFix64}}
		
		access(account)
		let claims:{ Address:{ String: UInt16}}
		
		access(account)
		fun setMetadata(id: String, edition: UInt64?, data: Metadata){ 
			let fullId = edition == nil ? id : id.concat((edition!).toString())
			if self.metadatas[fullId] != nil{ 
				return
			}
			self.metadatas[fullId] = data
		}
		
		access(all)
		fun getMetadata(id: String, edition: UInt64?): Metadata?{ 
			if edition != nil{ 
				let perItem = self.metadatas[id.concat((edition!).toString())]
				if perItem != nil{ 
					return perItem
				}
			}
			return self.metadatas[id]
		}
		
		access(account)
		fun setRoyalties(id: String, edition: UInt64?, royalties:{ Address: UFix64}){ 
			let fullId = edition == nil ? id : id.concat((edition!).toString())
			if self.royalties[fullId] != nil{ 
				return
			}
			self.royalties[fullId] = royalties
		}
		
		access(all)
		fun getRoyalties(id: String, edition: UInt64?):{ Address: UFix64}?{ 
			if edition != nil{ 
				let perItem = self.royalties[id.concat((edition!).toString())]
				if perItem != nil{ 
					return perItem
				}
			}
			return self.royalties[id]
		}
		
		access(account)
		fun checkIncClaim(id: String, address: Address, max: UInt16): Bool{ 
			if self.claims[address] == nil{ 
				self.claims[address] ={} 
			}
			let claims = self.claims[address]!
			let prev: UInt16 = claims[id] ?? 0
			if prev >= max{ 
				return false
			}
			claims[id] = prev + UInt16(1)
			self.claims[address] = claims
			return true
		}
		
		init(){ 
			self.metadatas ={} 
			self.royalties ={} 
			self.claims ={} 
		}
	}
	
	access(contract)
	fun loadMetadataStorage(): &MetadataStorage{ 
		if let existing = self.account.storage.borrow<&MetadataStorage>(from: /storage/metadataStorage){ 
			return existing
		}
		let res <- create MetadataStorage()
		let ref = &res as &MetadataStorage
		self.account.storage.save(<-res, to: /storage/metadataStorage)
		return ref
	}
	
	access(all)
	fun getMetadata(id: String, edition: UInt64?): Metadata?{ 
		return TuneGONFT.loadMetadataStorage().getMetadata(id: id, edition: edition)
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/tunegoNFTCollection
		self.CollectionPrivatePath = /private/tunegoNFTCollection
		self.CollectionPublicPath = /public/tunegoNFTCollection
		self.MinterStoragePath = /storage/tunegoNFTMinter
		self.totalSupply = 0
		self.itemEditions ={} 
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
