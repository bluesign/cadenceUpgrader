import Crypto

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract PackNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let itemEditions:{ UInt64: UInt32}
	
	access(all)
	var version: String
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	var CollectionPublicType: Type
	
	access(all)
	var CollectionPrivateType: Type
	
	access(all)
	let OperatorStoragePath: StoragePath
	
	access(all)
	let OperatorPrivPath: PrivatePath
	
	access(all)
	var defaultCollectionMetadata: CollectionMetadata?
	
	access(contract)
	let itemMetadata:{ String: Metadata}
	
	access(contract)
	let itemCollectionMetadata:{ String: CollectionMetadata}
	
	access(all)
	var metadataOpenedWarning: String
	
	// representation of the NFT in this contract to keep track of states
	access(contract)
	let packs: @{UInt64: Pack}
	
	access(all)
	event RevealRequest(id: UInt64, openRequest: Bool)
	
	access(all)
	event OpenRequest(id: UInt64)
	
	access(all)
	event Revealed(id: UInt64, salt: String, nfts: String)
	
	access(all)
	event Opened(id: UInt64)
	
	access(all)
	event MetadataUpdated(distId: UInt64, edition: UInt32?, metadata: Metadata)
	
	access(all)
	event CollectionMetadataUpdated(distId: UInt64, edition: UInt32?, metadata: CollectionMetadata)
	
	access(all)
	event Mint(id: UInt64, edition: UInt32, commitHash: String, distId: UInt64, nftCount: UInt16?, lockTime: UFix64?, additionalInfo:{ String: String}?)
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	enum Status: UInt8{ 
		access(all)
		case Sealed
		
		access(all)
		case Revealed
		
		access(all)
		case Opened
	}
	
	access(all)
	resource interface IOperator{ 
		access(all)
		fun setMetadata(distId: UInt64, edition: UInt32?, metadata: Metadata, overwrite: Bool)
		
		access(all)
		fun setCollectionMetadata(distId: UInt64, edition: UInt32?, metadata: CollectionMetadata, overwrite: Bool)
		
		access(all)
		fun mint(distId: UInt64, additionalInfo:{ String: String}?, commitHash: String, issuer: Address, nftCount: UInt16?, lockTime: UFix64?): @NFT
		
		access(all)
		fun reveal(id: UInt64, nfts: [&{NonFungibleToken.NFT}], salt: String)
		
		access(all)
		fun open(id: UInt64, nfts: [&{NonFungibleToken.NFT}])
	}
	
	access(all)
	resource PackNFTOperator: IOperator{ 
		access(all)
		fun setMetadata(distId: UInt64, edition: UInt32?, metadata: Metadata, overwrite: Bool){ 
			let fullId = edition != nil ? distId.toString().concat(":").concat((edition!).toString()) : distId.toString()
			if !overwrite && PackNFT.itemMetadata[fullId] != nil{ 
				return
			}
			PackNFT.itemMetadata[fullId] = metadata
			emit MetadataUpdated(distId: distId, edition: edition, metadata: metadata)
		}
		
		access(all)
		fun setCollectionMetadata(distId: UInt64, edition: UInt32?, metadata: CollectionMetadata, overwrite: Bool){ 
			let fullId = edition != nil ? distId.toString().concat(":").concat((edition!).toString()) : distId.toString()
			if !overwrite && PackNFT.itemCollectionMetadata[fullId] != nil{ 
				return
			}
			PackNFT.itemCollectionMetadata[fullId] = metadata
			emit CollectionMetadataUpdated(distId: distId, edition: edition, metadata: metadata)
		}
		
		access(all)
		fun mint(distId: UInt64, additionalInfo:{ String: String}?, commitHash: String, issuer: Address, nftCount: UInt16?, lockTime: UFix64?): @NFT{ 
			assert(PackNFT.defaultCollectionMetadata != nil, message: "Please set the default collection metadata before minting")
			let totalEditions = PackNFT.itemEditions[distId] ?? UInt32(0)
			let edition = totalEditions + UInt32(1)
			let id = PackNFT.totalSupply + 1
			let nft <- create NFT(id: id, distId: distId, edition: edition, additionalInfo: additionalInfo, commitHash: commitHash, issuer: issuer, nftCount: nftCount, lockTime: lockTime)
			PackNFT.itemEditions[distId] = edition
			PackNFT.totalSupply = PackNFT.totalSupply + 1
			let p <- create Pack(commitHash: commitHash, issuer: issuer, nftCount: nftCount, lockTime: lockTime)
			PackNFT.packs[id] <-! p
			emit Mint(id: id, edition: edition, commitHash: commitHash, distId: distId, nftCount: nftCount, lockTime: lockTime, additionalInfo: additionalInfo)
			return <-nft
		}
		
		access(all)
		fun reveal(id: UInt64, nfts: [&{NonFungibleToken.NFT}], salt: String){ 
			let p <- PackNFT.packs.remove(key: id) ?? panic("no such pack")
			p.reveal(id: id, nfts: nfts, salt: salt)
			PackNFT.packs[id] <-! p
		}
		
		access(all)
		fun open(id: UInt64, nfts: [&{NonFungibleToken.NFT}]){ 
			let p <- PackNFT.packs.remove(key: id) ?? panic("no such pack")
			p.open(id: id, nfts: nfts)
			PackNFT.packs[id] <-! p
		}
		
		access(all)
		fun createOperator(): @PackNFTOperator{ 
			return <-create PackNFTOperator()
		}
		
		access(all)
		fun setDefaultCollectionMetadata(defaultCollectionMetadata: CollectionMetadata){ 
			PackNFT.defaultCollectionMetadata = defaultCollectionMetadata
		}
		
		access(all)
		fun setVersion(version: String){ 
			PackNFT.version = version
		}
		
		init(){} 
	}
	
	access(all)
	resource Pack{ 
		access(all)
		let commitHash: String
		
		access(all)
		let issuer: Address
		
		access(all)
		let nftCount: UInt16?
		
		access(all)
		let lockTime: UFix64?
		
		access(all)
		var status: Status
		
		access(all)
		var salt: String?
		
		access(all)
		fun verify(nftString: String): Bool{ 
			assert(self.status as! PackNFT.Status != PackNFT.Status.Sealed, message: "Pack not revealed yet")
			var hashString = self.salt!
			hashString = hashString.concat(",").concat(nftString)
			let hash = HashAlgorithm.SHA2_256.hash(hashString.utf8)
			assert(self.commitHash == String.encodeHex(hash), message: "CommitHash was not verified")
			return true
		}
		
		access(self)
		fun _hashNft(nft: &{NonFungibleToken.NFT}): String{ 
			return nft.getType().identifier.concat(".").concat(nft.id.toString())
		}
		
		access(self)
		fun _verify(nfts: [&{NonFungibleToken.NFT}], salt: String, commitHash: String): String{ 
			assert(self.nftCount == nil || self.nftCount! == UInt16(nfts.length), message: "nftCount doesn't match nfts length")
			var hashString = salt.concat(",").concat(nfts.length.toString())
			var nftString = nfts.length > 0 ? self._hashNft(nft: nfts[0]) : ""
			var i = 1
			while i < nfts.length{ 
				let s = self._hashNft(nft: nfts[i])
				nftString = nftString.concat(",").concat(s)
				i = i + 1
			}
			hashString = hashString.concat(",").concat(nftString)
			let hash = HashAlgorithm.SHA2_256.hash(hashString.utf8)
			assert(self.commitHash == String.encodeHex(hash), message: "CommitHash was not verified")
			return nftString
		}
		
		access(contract)
		fun reveal(id: UInt64, nfts: [&{NonFungibleToken.NFT}], salt: String){ 
			assert(self.status as! PackNFT.Status == PackNFT.Status.Sealed, message: "Pack status is not Sealed")
			let v = self._verify(nfts: nfts, salt: salt, commitHash: self.commitHash)
			self.salt = salt
			self.status = PackNFT.Status.Revealed
			emit Revealed(id: id, salt: salt, nfts: v)
		}
		
		access(contract)
		fun open(id: UInt64, nfts: [&{NonFungibleToken.NFT}]){ 
			pre{ 
				self.lockTime == nil || getCurrentBlock().timestamp > self.lockTime!:
					"Pack is locked until ".concat((self.lockTime!).toString())
			}
			assert(self.status as! PackNFT.Status == PackNFT.Status.Revealed, message: "Pack status is not Revealed")
			self._verify(nfts: nfts, salt: self.salt!, commitHash: self.commitHash)
			self.status = PackNFT.Status.Opened
			emit Opened(id: id)
		}
		
		init(commitHash: String, issuer: Address, nftCount: UInt16?, lockTime: UFix64?){ 
			self.commitHash = commitHash
			self.issuer = issuer
			self.status = PackNFT.Status.Sealed
			self.salt = nil
			self.nftCount = nftCount
			self.lockTime = lockTime
		}
	}
	
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
		let artworkOpened: String?
		
		access(all)
		let artworkOpenedMimeType: String?
		
		access(all)
		let artworkOpenedHash: String?
		
		access(all)
		let thumbnail: String
		
		access(all)
		let thumbnailMimeType: String
		
		access(all)
		let thumbnailOpened: String?
		
		access(all)
		let thumbnailOpenedMimeType: String?
		
		access(all)
		let termsUrl: String
		
		access(all)
		let externalUrl: String?
		
		access(all)
		let rarity: String?
		
		access(all)
		let credits: String?
		
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
			rawMetadata.insert(key: "artworkOpened", self.artworkOpened)
			rawMetadata.insert(key: "artworkOpenedMimeType", self.artworkOpenedMimeType)
			rawMetadata.insert(key: "artworkOpenedHash", self.artworkOpenedHash)
			rawMetadata.insert(key: "thumbnail", self.thumbnail)
			rawMetadata.insert(key: "thumbnailMimeType", self.thumbnailMimeType)
			rawMetadata.insert(key: "thumbnailOpened", self.thumbnailOpened)
			rawMetadata.insert(key: "thumbnailOpenedMimeType", self.thumbnailOpenedMimeType)
			rawMetadata.insert(key: "termsUrl", self.termsUrl)
			rawMetadata.insert(key: "externalUrl", self.externalUrl)
			rawMetadata.insert(key: "rarity", self.rarity)
			rawMetadata.insert(key: "credits", self.credits)
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
			rawMetadata.insert(key: "artworkOpened", self.artworkOpened)
			rawMetadata.insert(key: "artworkOpenedMimeType", self.artworkOpenedMimeType)
			rawMetadata.insert(key: "artworkOpenedHash", self.artworkOpenedHash)
			rawMetadata.insert(key: "thumbnail", self.thumbnail)
			rawMetadata.insert(key: "thumbnailMimeType", self.thumbnailMimeType)
			rawMetadata.insert(key: "thumbnailOpened", self.thumbnailOpened)
			rawMetadata.insert(key: "thumbnailOpenedMimeType", self.thumbnailOpenedMimeType)
			rawMetadata.insert(key: "termsUrl", self.termsUrl)
			rawMetadata.insert(key: "externalUrl", self.externalUrl)
			rawMetadata.insert(key: "rarity", self.rarity)
			rawMetadata.insert(key: "credits", self.credits)
			return rawMetadata
		}
		
		access(all)
		fun patchedForOpened(): Metadata{ 
			return Metadata(title: PackNFT.metadataOpenedWarning.concat(self.title), description: PackNFT.metadataOpenedWarning.concat(self.description), creator: self.creator, asset: self.asset, assetMimeType: self.assetMimeType, assetHash: self.assetHash, artwork: self.artworkOpened ?? self.artwork, artworkMimeType: self.artworkOpenedMimeType ?? self.artworkMimeType, artworkHash: self.artworkOpenedHash ?? self.artworkHash, artworkAlternate: self.artworkAlternate, artworkAlternateMimeType: self.artworkAlternateMimeType, artworkAlternateHash: self.artworkAlternateHash, artworkOpened: self.artworkOpened, artworkOpenedMimeType: self.artworkOpenedMimeType, artworkOpenedHash: self.artworkOpenedHash, thumbnail: self.thumbnailOpened ?? self.thumbnail, thumbnailMimeType: self.thumbnailOpenedMimeType ?? self.thumbnailMimeType, thumbnailOpened: self.thumbnailOpened, thumbnailOpenedMimeType: self.thumbnailOpenedMimeType, termsUrl: self.termsUrl, externalUrl: self.externalUrl, rarity: self.rarity, credits: self.credits)
		}
		
		init(title: String, description: String, creator: String, asset: String, assetMimeType: String, assetHash: String, artwork: String, artworkMimeType: String, artworkHash: String, artworkAlternate: String?, artworkAlternateMimeType: String?, artworkAlternateHash: String?, artworkOpened: String?, artworkOpenedMimeType: String?, artworkOpenedHash: String?, thumbnail: String, thumbnailMimeType: String, thumbnailOpened: String?, thumbnailOpenedMimeType: String?, termsUrl: String, externalUrl: String?, rarity: String?, credits: String?){ 
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
			self.artworkOpened = artworkOpened
			self.artworkOpenedMimeType = artworkOpenedMimeType
			self.artworkOpenedHash = artworkOpenedHash
			self.thumbnail = thumbnail
			self.thumbnailMimeType = thumbnailMimeType
			self.thumbnailOpened = thumbnailOpened
			self.thumbnailOpenedMimeType = thumbnailOpenedMimeType
			self.termsUrl = termsUrl
			self.externalUrl = externalUrl
			self.credits = credits
			self.rarity = rarity
		}
	}
	
	access(all)
	struct CollectionMetadata{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let URL: String
		
		access(all)
		let media: String
		
		access(all)
		let mediaMimeType: String
		
		access(all)
		let mediaBanner: String?
		
		access(all)
		let mediaBannerMimeType: String?
		
		access(all)
		let socials:{ String: String}
		
		access(all)
		fun toDict():{ String: AnyStruct?}{ 
			let rawMetadata:{ String: AnyStruct?} ={} 
			rawMetadata.insert(key: "name", self.name)
			rawMetadata.insert(key: "description", self.description)
			rawMetadata.insert(key: "URL", self.URL)
			rawMetadata.insert(key: "media", self.media)
			rawMetadata.insert(key: "mediaMimeType", self.mediaMimeType)
			rawMetadata.insert(key: "mediaBanner", self.mediaBanner)
			rawMetadata.insert(key: "mediaBannerMimeType", self.mediaBanner)
			rawMetadata.insert(key: "socials", self.socials)
			return rawMetadata
		}
		
		init(name: String, description: String, URL: String, media: String, mediaMimeType: String, mediaBanner: String?, mediaBannerMimeType: String?, socials:{ String: String}?){ 
			self.name = name
			self.description = description
			self.URL = URL
			self.media = media
			self.mediaMimeType = mediaMimeType
			self.mediaBanner = mediaBanner
			self.mediaBannerMimeType = mediaBannerMimeType
			self.socials = socials ??{} 
		}
	}
	
	access(all)
	resource interface IPackNFTToken{ 
		access(all)
		let id: UInt64
		
		access(all)
		let edition: UInt32
		
		access(all)
		let commitHash: String
		
		access(all)
		let issuer: Address
		
		access(all)
		let nftCount: UInt16?
		
		access(all)
		let lockTime: UFix64?
	}
	
	access(all)
	resource interface IPackNFTOwnerOperator{ 
		access(all)
		fun reveal(openRequest: Bool)
		
		access(all)
		fun open()
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver, IPackNFTToken, IPackNFTOwnerOperator{ 
		access(all)
		let id: UInt64
		
		access(all)
		let distId: UInt64
		
		access(all)
		let edition: UInt32
		
		access(all)
		let commitHash: String
		
		access(all)
		let issuer: Address
		
		access(all)
		let nftCount: UInt16?
		
		access(all)
		let lockTime: UFix64?
		
		access(self)
		let additionalInfo:{ String: String}
		
		access(all)
		let mintedBlock: UInt64
		
		access(all)
		let mintedTime: UFix64
		
		access(all)
		fun reveal(openRequest: Bool){ 
			PackNFT.revealRequest(id: self.id, openRequest: openRequest)
		}
		
		access(all)
		fun open(){ 
			pre{ 
				self.lockTime == nil || getCurrentBlock().timestamp > self.lockTime!:
					"Pack is locked until ".concat((self.lockTime!).toString())
			}
			PackNFT.openRequest(id: self.id)
		}
		
		access(all)
		fun getAdditionalInfo():{ String: String}{ 
			return self.additionalInfo
		}
		
		access(all)
		fun totalEditions(): UInt32{ 
			return PackNFT.itemEditions[self.distId] ?? UInt32(0)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<Metadata>(), Type<MetadataViews.Display>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<Metadata>():
					return self.metadata()
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.metadata().title, description: self.metadata().description, thumbnail: MetadataViews.HTTPFile(url: self.metadata().thumbnail))
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(UInt64(self.edition))
				case Type<MetadataViews.Editions>():
					let name = self.collectionMetadata()?.name ?? (PackNFT.defaultCollectionMetadata!).name
					let editionInfo = MetadataViews.Edition(name: name, number: UInt64(self.edition), max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(self.metadata().externalUrl ?? "https://www.tunegonft.com/view-pack-collectible/".concat(self.uuid.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: PackNFT.CollectionStoragePath, publicPath: PackNFT.CollectionPublicPath, publicCollection: PackNFT.CollectionPublicType, publicLinkedType: PackNFT.CollectionPublicType, createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-PackNFT.createEmptyCollection(nftType: Type<@PackNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let collectionMetadata = self.collectionMetadata() ?? PackNFT.defaultCollectionMetadata!
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: collectionMetadata.media), mediaType: collectionMetadata.mediaMimeType)
					let mediaBanner = collectionMetadata.mediaBanner != nil ? MetadataViews.Media(file: MetadataViews.HTTPFile(url: collectionMetadata.mediaBanner!), mediaType: collectionMetadata.mediaBannerMimeType!) : media
					let socials:{ String: MetadataViews.ExternalURL} ={} 
					collectionMetadata.socials.forEachKey(fun (key: String): Bool{ 
							socials.insert(key: key, MetadataViews.ExternalURL(collectionMetadata.socials[key]!))
							return false
						})
					return MetadataViews.NFTCollectionDisplay(name: collectionMetadata.name, description: collectionMetadata.description, externalURL: MetadataViews.ExternalURL(collectionMetadata.URL), squareImage: media, bannerImage: mediaBanner, socials: socials)
				case Type<MetadataViews.Traits>():
					let excludedTraits = ["mintedTime"]
					let dict = self.metadataDict()
					dict.forEachKey(fun (key: String): Bool{ 
							if dict[key] == nil{ 
								dict.remove(key: key)
							}
							return false
						})
					let traitsView = MetadataViews.dictToTraits(dict: dict, excludedNames: excludedTraits)
					
					// mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
					let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.mintedTime!, displayType: "Date", rarity: nil)
					traitsView.addTrait(mintedTimeTrait)
					return traitsView
			}
			return nil
		}
		
		access(all)
		fun _metadata(): Metadata{ 
			let fullId = self.distId.toString().concat(":").concat(self.edition.toString())
			let editionMetadata = PackNFT.itemMetadata[fullId]
			if editionMetadata != nil{ 
				return editionMetadata!
			}
			let distMetadata = PackNFT.itemMetadata[self.distId.toString()]
			if distMetadata != nil{ 
				return distMetadata!
			}
			panic("Metadata not found for collectible ".concat(fullId))
		}
		
		access(all)
		fun metadata(): Metadata{ 
			let metadata = self._metadata()
			let p = PackNFT.borrowPackRepresentation(id: self.id) ?? panic("Pack representation not found")
			if p.status as! PackNFT.Status == PackNFT.Status.Opened{ 
				return metadata.patchedForOpened()
			}
			return metadata
		}
		
		access(all)
		fun collectionMetadata(): CollectionMetadata?{ 
			let fullId = self.distId.toString().concat(":").concat(self.edition.toString())
			let editionMetadata = PackNFT.itemCollectionMetadata[fullId]
			if editionMetadata != nil{ 
				return editionMetadata!
			}
			let distMetadata = PackNFT.itemCollectionMetadata[self.distId.toString()]
			return distMetadata
		}
		
		access(all)
		fun metadataDict():{ String: AnyStruct?}{ 
			let dict = self.metadata().toDict()
			let collectionDict = self.collectionMetadata()?.toDict()
			if collectionDict != nil{ 
				(collectionDict!).forEachKey(fun (key: String): Bool{ 
						dict.insert(key: "collection_".concat(key), (collectionDict!)[key])
						return false
					})
			}
			dict.insert(key: "mintedBlock", self.mintedBlock)
			dict.insert(key: "mintedTime", self.mintedTime)
			return dict
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64, distId: UInt64, edition: UInt32, additionalInfo:{ String: String}?, commitHash: String, issuer: Address, nftCount: UInt16?, lockTime: UFix64?){ 
			self.id = id
			self.distId = distId
			self.edition = edition
			self.additionalInfo = additionalInfo ??{} 
			self.commitHash = commitHash
			self.issuer = issuer
			self.nftCount = nftCount
			self.lockTime = lockTime
			let currentBlock = getCurrentBlock()
			self.mintedBlock = currentBlock.height
			self.mintedTime = currentBlock.timestamp
			
			// asserts metadata exists for distribution / edition
			self._metadata()
		}
	}
	
	access(all)
	resource interface IPackNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowPackNFT(id: UInt64): &NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || (result!).id == id:
					"Cannot borrow PackNFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource interface IPackNFTCollectionPrivate{ 
		access(all)
		fun borrowPackNFT(id: UInt64): &NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || (result!).id == id:
					"Cannot borrow PackNFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, IPackNFTCollectionPublic, IPackNFTCollectionPrivate{ 
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
			let token <- token as! @PackNFT.NFT
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
		fun borrowPackNFT(id: UInt64): &NFT?{ 
			let nft <- self.ownedNFTs.remove(key: id)
			if nft == nil{ 
				destroy nft
				return nil
			}
			let token <- nft! as! @PackNFT.NFT
			let ref = &token as &NFT
			self.ownedNFTs[id] <-! token as! @PackNFT.NFT
			return ref
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let ref = nft as! &PackNFT.NFT
			return ref as &{ViewResolver.Resolver}
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
	
	access(contract)
	fun revealRequest(id: UInt64, openRequest: Bool){ 
		let p = PackNFT.borrowPackRepresentation(id: id) ?? panic("No such pack")
		assert(p.status == PackNFT.Status.Sealed, message: "Pack status must be Sealed for reveal request")
		emit RevealRequest(id: id, openRequest: openRequest)
	}
	
	access(contract)
	fun openRequest(id: UInt64){ 
		let p = PackNFT.borrowPackRepresentation(id: id) ?? panic("No such pack")
		assert(p.status == PackNFT.Status.Revealed, message: "Pack status must be Revealed for open request")
		emit OpenRequest(id: id)
	}
	
	access(all)
	fun publicReveal(id: UInt64, nfts: [&{NonFungibleToken.NFT}], salt: String){ 
		let p = PackNFT.borrowPackRepresentation(id: id) ?? panic("No such pack")
		p.reveal(id: id, nfts: nfts, salt: salt)
	}
	
	access(all)
	fun borrowPackRepresentation(id: UInt64): &Pack?{ 
		return &self.packs[id] as &Pack?
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	init(){ 
		self.totalSupply = 0
		self.itemEditions ={} 
		self.packs <-{} 
		self.CollectionStoragePath = /storage/tunegoPack
		self.CollectionPublicPath = /public/tunegoPack
		self.CollectionPrivatePath = /private/tunegoPackPriv
		self.OperatorStoragePath = /storage/tunegoPackOperator
		self.OperatorPrivPath = /private/tunegoPackOperator
		self.defaultCollectionMetadata = nil
		self.version = "1.0"
		self.itemMetadata ={} 
		self.itemCollectionMetadata ={} 
		self.metadataOpenedWarning = "WARNING this pack has already been opened! \n"
		self.CollectionPublicType = Type<&Collection>()
		self.CollectionPrivateType = Type<&Collection>()
		
		// Create a collection to receive Pack NFTs
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		var capability_2 = self.account.capabilities.storage.issue<&Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: self.CollectionPrivatePath)
		
		// Create a operator to share mint capability with proxy
		let operator <- create PackNFTOperator()
		self.account.storage.save(<-operator, to: self.OperatorStoragePath)
		var capability_3 = self.account.capabilities.storage.issue<&PackNFTOperator>(self.OperatorStoragePath)
		self.account.capabilities.publish(capability_3, at: self.OperatorPrivPath)
	}
}
