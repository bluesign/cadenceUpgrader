/**

	TrmAssetMSV1_0.cdc

*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract TrmAssetMSV1_0: NonFungibleToken{ 
	// The total number of tokens of this type in existence
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event AssetCollectionInitialized(userAccountAddress: Address)
	
	access(all)
	event AssetMinted(id: UInt64, serialNumber: UInt32, masterTokenID: UInt64?, totalTokens: UInt32, owners:{ String: UInt32}, renters: [String], invitees: [String], type: String, expiryTimestamp: UFix64, valid: Bool, metadata:{ String: String}, songID: String?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, revenueHash: String?, previewURL: String?, lyricsURL: String?, timestamp: String?, uploadID: String?, webhookID: String?)
	
	access(all)
	event AssetBatchMinted(startID: UInt64, endID: UInt64, totalCount: UInt32, startSerialNumber: UInt32, endSerialNumber: UInt32, masterTokenID: UInt64, totalTokens: UInt32, owners:{ String: UInt32}, renters: [String], invitees: [String], type: String, expiryTimestamp: UFix64, valid: Bool, metadata:{ String: String}, songID: String?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, revenueHash: String?, previewURL: String?, lyricsURL: String?, timestamp: String?, uploadID: String?, webhookID: String?)
	
	access(all)
	event AssetUpdated(id: UInt64, songID: String?, expiryTimestamp: UFix64?, valid: Bool?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, revenueHash: String?, revenueData: String?, previewURL: String?, lyricsURL: String?, iv: String?, timestamp: String?, uploadID: String?, webhookID: String?)
	
	access(all)
	event AssetOwnerTransfer(id: UInt64, ownerFrom: String, ownerTo: String, tokens: UInt32, owners:{ String: UInt32}, songID: String?, ownersHash: String?, price: UFix64?, priceUnit: String?, timestamp: String?, webhookID: String?)
	
	access(all)
	event AssetRenterAdded(id: UInt64, renter: String, songID: String?, timestamp: String?, webhookID: String?)
	
	access(all)
	event AssetRenterRemoved(id: UInt64, renter: String, songID: String?, timestamp: String?, webhookID: String?)
	
	access(all)
	event AssetInviteeAdded(id: UInt64, invitee: String, songID: String?, timestamp: String?, webhookID: String?)
	
	access(all)
	event AssetInviteeRemoved(id: UInt64, invitee: String, songID: String?, timestamp: String?, webhookID: String?)
	
	access(all)
	event AssetTypeUpdated(id: UInt64, type: String, songID: String?, timestamp: String?, webhookID: String?)
	
	access(all)
	event AssetMetadataUpdated(id: UInt64, metadata:{ String: String}, songID: String?, timestamp: String?, webhookID: String?)
	
	access(all)
	event AssetMetadataRemoved(id: UInt64, metadata: [String], songID: String?, timestamp: String?, webhookID: String?)
	
	access(all)
	event AssetDestroyed(id: UInt64, songID: String?, timestamp: String?, webhookID: String?)
	
	access(all)
	event AssetBatchDestroyed(ids: [UInt64], songID: String?, timestamp: String?, webhookID: String?)
	
	// Event that is emitted when a token is withdrawn, indicating the owner of the collection that it was withdrawn from. If the collection is not in an account's storage, `from` will be `nil`.
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Event that emitted when a token is deposited to a collection. It indicates the owner of the collection that it was deposited to.
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Paths where Storage and capabilities are stored
	access(all)
	let collectionStoragePath: StoragePath
	
	access(all)
	let collectionPublicPath: PublicPath
	
	access(all)
	let minterStoragePath: StoragePath
	
	access(all)
	let adminStoragePath: StoragePath
	
	access(all)
	enum AssetType: UInt8{ 
		access(all)
		case private
		
		access(all)
		case public
	}
	
	access(all)
	fun assetTypeToString(_ assetType: AssetType): String{ 
		switch assetType{ 
			case AssetType.private:
				return "private"
			case AssetType.public:
				return "public"
			default:
				return ""
		}
	}
	
	access(all)
	fun stringToAssetType(_ assetTypeStr: String): AssetType{ 
		switch assetTypeStr{ 
			case "private":
				return AssetType.private
			case "public":
				return AssetType.public
			default:
				return panic("Asset Type must be \"private\" or \"public\"")
		}
	}
	
	// AssetData
	//
	// Struct for storing metadata for Asset
	access(all)
	struct AssetData{ 
		access(all)
		let serialNumber: UInt32
		
		access(all)
		let masterTokenID: UInt64
		
		access(all)
		let totalTokens: UInt32
		
		access(all)
		var owners:{ String: UInt32}
		
		access(all)
		var renters: [String]
		
		access(all)
		var invitees: [String]
		
		access(all)
		var type: AssetType
		
		access(all)
		var expiryTimestamp: UFix64
		
		access(all)
		var valid: Bool
		
		access(all)
		var metadata:{ String: String}
		
		access(all)
		let songID: String?
		
		access(all)
		var kID: String?
		
		access(all)
		var title: String?
		
		access(all)
		var description: String?
		
		access(all)
		var url: String?
		
		access(all)
		var thumbnailURL: String?
		
		access(all)
		var orh: [String]?
		
		access(all)
		var isrc: String?
		
		access(all)
		var performers: [String]?
		
		access(all)
		var lyricists: [String]?
		
		access(all)
		var composers: [String]?
		
		access(all)
		var arrangers: [String]?
		
		access(all)
		var releaseDate: String?
		
		access(all)
		var playingTime: String?
		
		access(all)
		var albumTitle: String?
		
		access(all)
		var catalogNumber: String?
		
		access(all)
		var trackNumber: String?
		
		access(all)
		var ownersHash: String?
		
		access(all)
		var revenueHash: String?
		
		access(contract)
		fun transferOwner(ownerFrom: String, ownerTo: String, tokens: UInt32, ownersHash: String){ 
			pre{ 
				self.owners.containsKey(ownerFrom):
					"The account from which ownership is transferred does not own this asset"
				tokens <= self.totalTokens:
					"Total tokens tranferred should be less than total tokens"
				self.owners[ownerFrom]! >= tokens:
					"The account from which ownership is transferred does not own enough tokens for this asset"
			}
			self.owners[ownerFrom] = self.owners[ownerFrom]! - tokens
			if let ownerTokens = self.owners[ownerTo]{ 
				self.owners[ownerTo] = ownerTokens + tokens
			} else{ 
				self.owners[ownerTo] = tokens
			}
			var totalTokens: UInt32 = 0
			for owner in self.owners.keys{ 
				if let ownerTokens: UInt32 = self.owners[owner]{ 
					if ownerTokens == 0{ 
						self.owners.remove(key: owner)
					} else{ 
						totalTokens = totalTokens + ownerTokens
					}
				}
			}
			if totalTokens != self.totalTokens{ 
				panic("Owner tokens do not sum to total tokens")
			}
			if self.owners.length >= 1000{ 
				panic("More than 1000 owners per asset is not supported")
			}
			self.ownersHash = ownersHash
		}
		
		access(contract)
		fun ownerExists(owner: String): Bool{ 
			return self.owners.containsKey(owner)
		}
		
		access(contract)
		fun addRenter(renter: String){ 
			pre{ 
				renter.length > 0:
					"Renter is invalid"
				self.renters.length < 100:
					"Maximum 100 renters allowed"
			}
			if !self.renters.contains(renter){ 
				self.renters.append(renter)
			}
		}
		
		access(contract)
		fun removeRenter(renter: String){ 
			if let renterIndex = self.renters.firstIndex(of: renter){ 
				self.renters.remove(at: renterIndex)
			}
		}
		
		access(contract)
		fun removeRenters(){ 
			self.renters = []
		}
		
		access(contract)
		fun renterExists(renter: String): Bool{ 
			return self.renters.contains(renter)
		}
		
		access(contract)
		fun addInvitee(invitee: String){ 
			pre{ 
				invitee.length > 0:
					"Invitee is invalid"
				self.invitees.length < 100:
					"Maximum 100 renters allowed"
			}
			if !self.invitees.contains(invitee){ 
				self.invitees.append(invitee)
			}
		}
		
		access(contract)
		fun removeInvitee(invitee: String){ 
			if let inviteeIndex = self.invitees.firstIndex(of: invitee){ 
				self.invitees.remove(at: inviteeIndex)
			}
		}
		
		access(contract)
		fun removeInvitees(){ 
			self.invitees = []
		}
		
		access(contract)
		fun inviteeExists(invitee: String): Bool{ 
			return self.invitees.contains(invitee)
		}
		
		access(contract)
		fun setType(type: String){ 
			pre{ 
				type == "private" || type == "public":
					"Asset Type must be private or public"
			}
			self.type = TrmAssetMSV1_0.stringToAssetType(type)
		}
		
		access(contract)
		fun setExpiryTimestamp(expiryTimestamp: UFix64){ 
			pre{ 
				expiryTimestamp > getCurrentBlock().timestamp:
					"Expiry timestamp should be greater than current timestamp"
			}
			self.expiryTimestamp = expiryTimestamp
		}
		
		access(contract)
		fun setValid(valid: Bool){ 
			self.valid = valid
		}
		
		access(contract)
		fun setMetadata(metadata:{ String: String}){ 
			pre{ 
				metadata.length > 0:
					"Total length of metadata cannot be less than 1"
			}
			for metadataEntry in metadata.keys{ 
				self.metadata[metadataEntry] = metadata[metadataEntry]
			}
		}
		
		access(contract)
		fun removeMetadata(metadata: [String]){ 
			pre{ 
				metadata.length > 0:
					"Total length of metadata cannot be less than 1"
			}
			for metadataEntry in metadata{ 
				self.metadata.remove(key: metadataEntry)
			}
		}
		
		access(contract)
		fun metadataExists(metadataEntry: String): Bool{ 
			return self.metadata.containsKey(metadataEntry)
		}
		
		access(contract)
		fun setKID(kID: String?){ 
			self.kID = kID
		}
		
		access(contract)
		fun setTitle(title: String?){ 
			self.title = title
		}
		
		access(contract)
		fun setDescription(description: String?){ 
			self.description = description
		}
		
		access(contract)
		fun setURL(url: String?){ 
			self.url = url
		}
		
		access(contract)
		fun setThumbnailURL(thumbnailURL: String?){ 
			self.thumbnailURL = thumbnailURL
		}
		
		access(contract)
		fun setORH(orh: [String]?){ 
			self.orh = orh
		}
		
		access(contract)
		fun setISRC(isrc: String?){ 
			self.isrc = isrc
		}
		
		access(contract)
		fun setPerformers(performers: [String]?){ 
			self.performers = performers
		}
		
		access(contract)
		fun setLyricists(lyricists: [String]?){ 
			self.lyricists = lyricists
		}
		
		access(contract)
		fun setComposers(composers: [String]?){ 
			self.composers = composers
		}
		
		access(contract)
		fun setArrangers(arrangers: [String]?){ 
			self.arrangers = arrangers
		}
		
		access(contract)
		fun setReleaseDate(releaseDate: String?){ 
			self.releaseDate = releaseDate
		}
		
		access(contract)
		fun setPlayingTime(playingTime: String?){ 
			self.playingTime = playingTime
		}
		
		access(contract)
		fun setAlbumTitle(albumTitle: String?){ 
			self.albumTitle = albumTitle
		}
		
		access(contract)
		fun setCatalogNumber(catalogNumber: String?){ 
			self.catalogNumber = catalogNumber
		}
		
		access(contract)
		fun setTrackNumber(trackNumber: String?){ 
			self.trackNumber = trackNumber
		}
		
		access(contract)
		fun setOwnersHash(ownersHash: String?){ 
			self.ownersHash = ownersHash
		}
		
		access(contract)
		fun setRevenueHash(revenueHash: String?){ 
			self.revenueHash = revenueHash
		}
		
		init(serialNumber: UInt32, masterTokenID: UInt64, totalTokens: UInt32, owners:{ String: UInt32}, renters: [String], invitees: [String], type: String, expiryTimestamp: UFix64, valid: Bool, metadata:{ String: String}, songID: String?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, revenueHash: String?){ 
			pre{ 
				type == "private" || type == "public":
					"Asset Type must be private or public"
				serialNumber >= 0:
					"Serial Number is invalid"
				totalTokens > 0:
					"Total Tokens is invalid"
				owners.length > 0:
					"Owners is invalid"
				owners.length <= 1000:
					"More than 1000 owners per asset is not supported"
			}
			self.serialNumber = serialNumber
			self.masterTokenID = masterTokenID
			self.totalTokens = totalTokens
			self.owners = owners
			self.renters = renters
			self.invitees = invitees
			self.type = TrmAssetMSV1_0.stringToAssetType(type)
			self.expiryTimestamp = expiryTimestamp
			self.valid = valid
			self.metadata = metadata
			self.songID = songID
			self.kID = kID
			self.title = title
			self.description = description
			self.url = url
			self.thumbnailURL = thumbnailURL
			self.orh = orh
			self.isrc = isrc
			self.performers = performers
			self.lyricists = lyricists
			self.composers = composers
			self.arrangers = arrangers
			self.releaseDate = releaseDate
			self.playingTime = playingTime
			self.albumTitle = albumTitle
			self.catalogNumber = catalogNumber
			self.trackNumber = trackNumber
			self.ownersHash = ownersHash
			self.revenueHash = revenueHash
			var totalTokens: UInt32 = 0
			for owner in self.owners.keys{ 
				if let ownerTokens: UInt32 = self.owners[owner]{ 
					if ownerTokens == 0{ 
						self.owners.remove(key: owner)
					} else{ 
						totalTokens = totalTokens + ownerTokens
					}
				}
			}
			if totalTokens != self.totalTokens{ 
				panic("Owner tokens do not sum to total tokens")
			}
		}
	}
	
	//  NFT
	//
	// The main Asset NFT resource that can be bought and sold by users
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let data: AssetData
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.data.title ?? "", description: self.data.description ?? "", thumbnail: MetadataViews.HTTPFile(url: self.data.thumbnailURL ?? ""))
			}
			return nil
		}
		
		access(contract)
		fun transferOwner(ownerFrom: String, ownerTo: String, tokens: UInt32, songID: String, ownersHash: String, price: UFix64?, priceUnit: String?, timestamp: String?, webhookID: String?){ 
			self.data.transferOwner(ownerFrom: ownerFrom, ownerTo: ownerTo, tokens: tokens, ownersHash: ownersHash)
			emit AssetOwnerTransfer(id: self.id, ownerFrom: ownerFrom, ownerTo: ownerTo, tokens: tokens, owners: self.data.owners, songID: songID, ownersHash: ownersHash, price: price, priceUnit: priceUnit, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(contract)
		fun addRenter(renter: String, songID: String?, timestamp: String?, webhookID: String?){ 
			self.data.addRenter(renter: renter)
			emit AssetRenterAdded(id: self.id, renter: renter, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(contract)
		fun removeRenter(renter: String, songID: String?, timestamp: String?, webhookID: String?){ 
			self.data.removeRenter(renter: renter)
			emit AssetRenterRemoved(id: self.id, renter: renter, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(contract)
		fun addInvitee(invitee: String, songID: String?, timestamp: String?, webhookID: String?){ 
			self.data.addInvitee(invitee: invitee)
			emit AssetInviteeAdded(id: self.id, invitee: invitee, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(contract)
		fun removeInvitee(invitee: String, songID: String?, timestamp: String?, webhookID: String?){ 
			self.data.removeInvitee(invitee: invitee)
			emit AssetInviteeRemoved(id: self.id, invitee: invitee, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(contract)
		fun updateType(type: String, songID: String?, timestamp: String?, webhookID: String?){ 
			self.data.setType(type: type)
			emit AssetTypeUpdated(id: self.id, type: type, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(contract)
		fun setMetadata(metadata:{ String: String}, songID: String?, timestamp: String?, webhookID: String?){ 
			self.data.setMetadata(metadata: metadata)
			emit AssetMetadataUpdated(id: self.id, metadata: metadata, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(contract)
		fun removeMetadata(metadata: [String], songID: String?, timestamp: String?, webhookID: String?){ 
			self.data.removeMetadata(metadata: metadata)
			emit AssetMetadataRemoved(id: self.id, metadata: metadata, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(contract)
		fun update(songID: String?, expiryTimestamp: UFix64?, valid: Bool?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, revenueHash: String?, revenueData: String?, previewURL: String?, lyricsURL: String?, iv: String?, timestamp: String?, uploadID: String?, webhookID: String?){ 
			if let tempExpiryTimestamp = expiryTimestamp{ 
				self.data.setExpiryTimestamp(expiryTimestamp: tempExpiryTimestamp)
			}
			if let tempValid = valid{ 
				self.data.setValid(valid: tempValid)
			}
			if let tempKID = kID{ 
				self.data.setKID(kID: tempKID)
			}
			if let tempTitle = title{ 
				self.data.setTitle(title: tempTitle)
			}
			if let tempDescription = description{ 
				self.data.setDescription(description: tempDescription)
			}
			if let tempURL = url{ 
				self.data.setURL(url: tempURL)
			}
			if let tempThumbnailURL = thumbnailURL{ 
				self.data.setThumbnailURL(thumbnailURL: tempThumbnailURL)
			}
			if let tempORH = orh{ 
				self.data.setORH(orh: tempORH)
			}
			if let tempISRC = isrc{ 
				self.data.setISRC(isrc: tempISRC)
			}
			if let tempPerformers = performers{ 
				self.data.setPerformers(performers: tempPerformers)
			}
			if let tempLyricists = lyricists{ 
				self.data.setLyricists(lyricists: tempLyricists)
			}
			if let tempComposers = composers{ 
				self.data.setComposers(composers: tempComposers)
			}
			if let tempArrangers = arrangers{ 
				self.data.setArrangers(arrangers: tempArrangers)
			}
			if let tempReleaseDate = releaseDate{ 
				self.data.setReleaseDate(releaseDate: tempReleaseDate)
			}
			if let tempPlayingTime = playingTime{ 
				self.data.setPlayingTime(playingTime: tempPlayingTime)
			}
			if let tempAlbumTitle = albumTitle{ 
				self.data.setAlbumTitle(albumTitle: tempAlbumTitle)
			}
			if let tempCatalogNumber = catalogNumber{ 
				self.data.setCatalogNumber(catalogNumber: tempCatalogNumber)
			}
			if let tempTrackNumber = trackNumber{ 
				self.data.setTrackNumber(trackNumber: tempTrackNumber)
			}
			if let tempOwnersHash = ownersHash{ 
				self.data.setOwnersHash(ownersHash: tempOwnersHash)
			}
			if let tempRevenueHash = revenueHash{ 
				self.data.setRevenueHash(revenueHash: tempRevenueHash)
			}
			emit AssetUpdated(id: self.id, songID: songID, expiryTimestamp: expiryTimestamp, valid: valid, kID: kID, title: title, description: description, url: url, thumbnailURL: thumbnailURL, orh: orh, isrc: isrc, performers: performers, lyricists: lyricists, composers: composers, arrangers: arrangers, releaseDate: releaseDate, playingTime: playingTime, albumTitle: albumTitle, catalogNumber: catalogNumber, trackNumber: trackNumber, ownersHash: ownersHash, revenueHash: revenueHash, revenueData: revenueData, previewURL: previewURL, lyricsURL: lyricsURL, iv: iv, timestamp: timestamp, uploadID: uploadID, webhookID: webhookID)
		}
		
		access(contract)
		fun reset(songID: String?, revenueData: String?, previewURL: String?, lyricsURL: String?, iv: String?, timestamp: String?, uploadID: String?, webhookID: String?){ 
			self.data.setKID(kID: nil)
			self.data.setTitle(title: nil)
			self.data.setDescription(description: nil)
			self.data.setURL(url: nil)
			self.data.setThumbnailURL(thumbnailURL: nil)
			self.data.setORH(orh: nil)
			self.data.setISRC(isrc: nil)
			self.data.setPerformers(performers: nil)
			self.data.setLyricists(lyricists: nil)
			self.data.setComposers(composers: nil)
			self.data.setArrangers(arrangers: nil)
			self.data.setReleaseDate(releaseDate: nil)
			self.data.setPlayingTime(playingTime: nil)
			self.data.setAlbumTitle(albumTitle: nil)
			self.data.setCatalogNumber(catalogNumber: nil)
			self.data.setTrackNumber(trackNumber: nil)
			emit AssetUpdated(id: self.id, songID: songID, expiryTimestamp: self.data.expiryTimestamp, valid: self.data.valid, kID: self.data.kID, title: self.data.title, description: self.data.description, url: self.data.url, thumbnailURL: self.data.thumbnailURL, orh: self.data.orh, isrc: self.data.isrc, performers: self.data.performers, lyricists: self.data.lyricists, composers: self.data.composers, arrangers: self.data.arrangers, releaseDate: self.data.releaseDate, playingTime: self.data.playingTime, albumTitle: self.data.albumTitle, catalogNumber: self.data.catalogNumber, trackNumber: self.data.trackNumber, ownersHash: self.data.ownersHash, revenueHash: self.data.revenueHash, revenueData: revenueData, previewURL: previewURL, lyricsURL: lyricsURL, iv: iv, timestamp: timestamp, uploadID: uploadID, webhookID: webhookID)
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64, serialNumber: UInt32, masterTokenID: UInt64, totalTokens: UInt32, owners:{ String: UInt32}, renters: [String], invitees: [String], type: String, expiryTimestamp: UFix64, valid: Bool, metadata:{ String: String}, songID: String?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, revenueHash: String?, previewURL: String?, lyricsURL: String?, timestamp: String?, uploadID: String?, webhookID: String?){ 
			self.id = id
			self.data = AssetData(serialNumber: serialNumber, masterTokenID: masterTokenID, totalTokens: totalTokens, owners: owners, renters: renters, invitees: invitees, type: type, expiryTimestamp: expiryTimestamp, valid: valid, metadata: metadata, songID: songID, kID: kID, title: title, description: description, url: url, thumbnailURL: thumbnailURL, orh: orh, isrc: isrc, performers: performers, lyricists: lyricists, composers: composers, arrangers: arrangers, releaseDate: releaseDate, playingTime: playingTime, albumTitle: albumTitle, catalogNumber: catalogNumber, trackNumber: trackNumber, ownersHash: ownersHash, revenueHash: revenueHash)
			emit AssetMinted(id: id, serialNumber: serialNumber, masterTokenID: masterTokenID, totalTokens: totalTokens, owners: owners, renters: renters, invitees: invitees, type: type, expiryTimestamp: expiryTimestamp, valid: valid, metadata: metadata, songID: songID, kID: kID, title: title, description: description, url: url, thumbnailURL: thumbnailURL, orh: orh, isrc: isrc, performers: performers, lyricists: lyricists, composers: composers, arrangers: arrangers, releaseDate: releaseDate, playingTime: playingTime, albumTitle: albumTitle, catalogNumber: catalogNumber, trackNumber: trackNumber, ownersHash: ownersHash, revenueHash: revenueHash, previewURL: previewURL, lyricsURL: lyricsURL, timestamp: timestamp, uploadID: uploadID, webhookID: webhookID)
		}
	}
	
	// CollectionPublic
	//
	// Public interface for Asset Collection
	// This exposes functions for depositing NFTs
	// and also for returning some info for a specific
	// Asset NFT id
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowAsset(id: UInt64): &NFT
		
		access(all)
		fun getAssetInfo(id: UInt64): AssetData
		
		access(all)
		fun idExists(id: UInt64): Bool
		
		access(all)
		fun getSerialNumber(id: UInt64): UInt32
		
		access(all)
		fun getMasterTokenID(id: UInt64): UInt64?
		
		access(all)
		fun getTotalTokens(id: UInt64): UInt32
		
		access(all)
		fun getOwners(id: UInt64):{ String: UInt32}
		
		access(all)
		fun getOwner(id: UInt64, owner: String): UInt32?
		
		access(all)
		fun ownerExists(id: UInt64, owner: String): Bool
		
		access(all)
		fun getRenters(id: UInt64): [String]
		
		access(all)
		fun renterExists(id: UInt64, renter: String): Bool
		
		access(all)
		fun getInvitees(id: UInt64): [String]
		
		access(all)
		fun inviteeExists(id: UInt64, invitee: String): Bool
		
		access(all)
		fun getAssetType(id: UInt64): String
		
		access(all)
		fun getExpiryTimestamp(id: UInt64): UFix64
		
		access(all)
		fun isExpired(id: UInt64): Bool
		
		access(all)
		fun getValid(id: UInt64): Bool
		
		access(all)
		fun isValid(id: UInt64): Bool
		
		access(all)
		fun getMetadata(id: UInt64):{ String: String}
		
		access(all)
		fun getMetadataEntry(id: UInt64, metadataEntry: String): String?
		
		access(all)
		fun getSongID(id: UInt64): String?
		
		access(all)
		fun getKID(id: UInt64): String?
		
		access(all)
		fun getTitle(id: UInt64): String?
		
		access(all)
		fun getDescription(id: UInt64): String?
		
		access(all)
		fun getURL(id: UInt64): String?
		
		access(all)
		fun getThumbnailURL(id: UInt64): String?
		
		access(all)
		fun getORH(id: UInt64): [String]?
		
		access(all)
		fun getISRC(id: UInt64): String?
		
		access(all)
		fun getPerformers(id: UInt64): [String]?
		
		access(all)
		fun getLyricists(id: UInt64): [String]?
		
		access(all)
		fun getComposers(id: UInt64): [String]?
		
		access(all)
		fun getArrangers(id: UInt64): [String]?
		
		access(all)
		fun getReleaseDate(id: UInt64): String?
		
		access(all)
		fun getPlayingTime(id: UInt64): String?
		
		access(all)
		fun getAlbumTitle(id: UInt64): String?
		
		access(all)
		fun getCatalogNumber(id: UInt64): String?
		
		access(all)
		fun getTrackNumber(id: UInt64): String?
		
		access(all)
		fun getOwnersHash(id: UInt64): String?
		
		access(all)
		fun getRevenueHash(id: UInt64): String?
	}
	
	// Collection
	//
	// The resource that stores a user's Asset NFT collection.
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, CollectionPublic{ 
		
		// Dictionary to hold the NFTs in the Collection
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			pre{ 
				false:
					"Withdrawing Asset directly from Asset contract is not allowed"
			}
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Error withdrawing Asset NFT")
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			pre{ 
				false:
					"Depositing Asset directly to Asset contract is not allowed"
			}
			let assetToken <- token as! @NFT
			let oldToken <- self.ownedNFTs[assetToken.id] <- assetToken
			destroy oldToken
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			return refAssetNFT
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowAsset(id: UInt64): &NFT{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return refNFT as! &NFT
		}
		
		access(all)
		fun getAssetInfo(id: UInt64): AssetData{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let serialNumber = refAssetNFT.data.serialNumber
			if serialNumber == 0{ 
				return *refAssetNFT.data
			} else{ 
				let masterTokenID = refAssetNFT.data.masterTokenID
				let refMasterNFT = (&self.ownedNFTs[masterTokenID] as &{NonFungibleToken.NFT}?)!
				let refMasterAssetNFT = refMasterNFT as! &NFT
				return AssetData(serialNumber: refAssetNFT.data.serialNumber, masterTokenID: refAssetNFT.data.masterTokenID, totalTokens: refAssetNFT.data.totalTokens, owners: *refAssetNFT.data.owners, renters: *refAssetNFT.data.renters, invitees: *refAssetNFT.data.invitees, type: TrmAssetMSV1_0.assetTypeToString(*refAssetNFT.data.type), expiryTimestamp: refAssetNFT.data.expiryTimestamp, valid: refAssetNFT.data.valid, metadata: *refAssetNFT.data.metadata, songID: refAssetNFT.data.songID ?? refMasterAssetNFT.data.songID, kID: refAssetNFT.data.kID ?? refMasterAssetNFT.data.kID, title: refAssetNFT.data.title ?? refMasterAssetNFT.data.title, description: refAssetNFT.data.description ?? refMasterAssetNFT.data.description, url: refAssetNFT.data.url ?? refMasterAssetNFT.data.url, thumbnailURL: refAssetNFT.data.thumbnailURL ?? refMasterAssetNFT.data.thumbnailURL, orh: *refAssetNFT.data.orh ?? refMasterAssetNFT.data.orh, isrc: refAssetNFT.data.isrc ?? refMasterAssetNFT.data.isrc, performers: *refAssetNFT.data.performers ?? refMasterAssetNFT.data.performers, lyricists: *refAssetNFT.data.lyricists ?? refMasterAssetNFT.data.lyricists, composers: *refAssetNFT.data.composers ?? refMasterAssetNFT.data.composers, arrangers: *refAssetNFT.data.arrangers ?? refMasterAssetNFT.data.arrangers, releaseDate: refAssetNFT.data.releaseDate ?? refMasterAssetNFT.data.releaseDate, playingTime: refAssetNFT.data.playingTime ?? refMasterAssetNFT.data.playingTime, albumTitle: refAssetNFT.data.albumTitle ?? refMasterAssetNFT.data.albumTitle, catalogNumber: refAssetNFT.data.catalogNumber ?? refMasterAssetNFT.data.catalogNumber, trackNumber: refAssetNFT.data.trackNumber ?? refMasterAssetNFT.data.trackNumber, ownersHash: refAssetNFT.data.ownersHash, revenueHash: refAssetNFT.data.revenueHash)
			}
		}
		
		access(all)
		fun idExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		access(all)
		fun getSerialNumber(id: UInt64): UInt32{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			return refAssetNFT.data.serialNumber
		}
		
		access(all)
		fun getMasterTokenID(id: UInt64): UInt64{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			return refAssetNFT.data.masterTokenID
		}
		
		access(all)
		fun getTotalTokens(id: UInt64): UInt32{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			return refAssetNFT.data.totalTokens
		}
		
		access(all)
		fun getOwners(id: UInt64):{ String: UInt32}{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			return *refAssetNFT.data.owners
		}
		
		access(all)
		fun getOwner(id: UInt64, owner: String): UInt32?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let owners = refAssetNFT.data.owners
			return owners[owner]
		}
		
		access(all)
		fun ownerExists(id: UInt64, owner: String): Bool{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let owners = refAssetNFT.data.owners
			return owners.containsKey(owner)
		}
		
		access(all)
		fun getRenters(id: UInt64): [String]{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			return *refAssetNFT.data.renters
		}
		
		access(all)
		fun renterExists(id: UInt64, renter: String): Bool{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let renters = refAssetNFT.data.renters
			return renters.contains(renter)
		}
		
		access(all)
		fun getInvitees(id: UInt64): [String]{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			return *refAssetNFT.data.invitees
		}
		
		access(all)
		fun inviteeExists(id: UInt64, invitee: String): Bool{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let invitees = refAssetNFT.data.invitees
			return invitees.contains(invitee)
		}
		
		access(all)
		fun getAssetType(id: UInt64): String{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			return TrmAssetMSV1_0.assetTypeToString(*refAssetNFT.data.type)
		}
		
		access(all)
		fun getExpiryTimestamp(id: UInt64): UFix64{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			return refAssetNFT.data.expiryTimestamp
		}
		
		access(all)
		fun isExpired(id: UInt64): Bool{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			return refAssetNFT.data.expiryTimestamp < getCurrentBlock().timestamp
		}
		
		access(all)
		fun getValid(id: UInt64): Bool{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			return refAssetNFT.data.valid
		}
		
		access(all)
		fun isValid(id: UInt64): Bool{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			return refAssetNFT.data.valid && refAssetNFT.data.expiryTimestamp >= getCurrentBlock().timestamp
		}
		
		access(all)
		fun getMetadata(id: UInt64):{ String: String}{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			return *refAssetNFT.data.metadata
		}
		
		access(all)
		fun getMetadataEntry(id: UInt64, metadataEntry: String): String?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let metadata = refAssetNFT.data.metadata
			return metadata[metadataEntry]
		}
		
		access(all)
		fun getSongID(id: UInt64): String?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let serialNumber = refAssetNFT.data.serialNumber
			if serialNumber == 0{ 
				return refAssetNFT.data.songID
			} else if let songID = refAssetNFT.data.songID{ 
				return songID
			} else{ 
				let masterTokenID = refAssetNFT.data.masterTokenID
				let refMasterNFT = (&self.ownedNFTs[masterTokenID] as &{NonFungibleToken.NFT}?)!
				let refMasterAssetNFT = refMasterNFT as! &NFT
				return refMasterAssetNFT.data.songID
			}
		}
		
		access(all)
		fun getKID(id: UInt64): String?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let serialNumber = refAssetNFT.data.serialNumber
			if serialNumber == 0{ 
				return refAssetNFT.data.kID
			} else if let kID = refAssetNFT.data.kID{ 
				return kID
			} else{ 
				let masterTokenID = refAssetNFT.data.masterTokenID
				let refMasterNFT = (&self.ownedNFTs[masterTokenID] as &{NonFungibleToken.NFT}?)!
				let refMasterAssetNFT = refMasterNFT as! &NFT
				return refMasterAssetNFT.data.kID
			}
		}
		
		access(all)
		fun getTitle(id: UInt64): String?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let serialNumber = refAssetNFT.data.serialNumber
			if serialNumber == 0{ 
				return refAssetNFT.data.title
			} else if let title = refAssetNFT.data.title{ 
				return title
			} else{ 
				let masterTokenID = refAssetNFT.data.masterTokenID
				let refMasterNFT = (&self.ownedNFTs[masterTokenID] as &{NonFungibleToken.NFT}?)!
				let refMasterAssetNFT = refMasterNFT as! &NFT
				return refMasterAssetNFT.data.title
			}
		}
		
		access(all)
		fun getDescription(id: UInt64): String?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let serialNumber = refAssetNFT.data.serialNumber
			if serialNumber == 0{ 
				return refAssetNFT.data.description
			} else if let description = refAssetNFT.data.description{ 
				return description
			} else{ 
				let masterTokenID = refAssetNFT.data.masterTokenID
				let refMasterNFT = (&self.ownedNFTs[masterTokenID] as &{NonFungibleToken.NFT}?)!
				let refMasterAssetNFT = refMasterNFT as! &NFT
				return refMasterAssetNFT.data.description
			}
		}
		
		access(all)
		fun getURL(id: UInt64): String?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let serialNumber = refAssetNFT.data.serialNumber
			if serialNumber == 0{ 
				return refAssetNFT.data.url
			} else if let url = refAssetNFT.data.url{ 
				return url
			} else{ 
				let masterTokenID = refAssetNFT.data.masterTokenID
				let refMasterNFT = (&self.ownedNFTs[masterTokenID] as &{NonFungibleToken.NFT}?)!
				let refMasterAssetNFT = refMasterNFT as! &NFT
				return refMasterAssetNFT.data.url
			}
		}
		
		access(all)
		fun getThumbnailURL(id: UInt64): String?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let serialNumber = refAssetNFT.data.serialNumber
			if serialNumber == 0{ 
				return refAssetNFT.data.thumbnailURL
			} else if let thumbnailURL = refAssetNFT.data.thumbnailURL{ 
				return thumbnailURL
			} else{ 
				let masterTokenID = refAssetNFT.data.masterTokenID
				let refMasterNFT = (&self.ownedNFTs[masterTokenID] as &{NonFungibleToken.NFT}?)!
				let refMasterAssetNFT = refMasterNFT as! &NFT
				return refMasterAssetNFT.data.thumbnailURL
			}
		}
		
		access(all)
		fun getORH(id: UInt64): [String]?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let serialNumber = refAssetNFT.data.serialNumber
			if serialNumber == 0{ 
				return *refAssetNFT.data.orh
			} else if let orh = refAssetNFT.data.orh{ 
				return orh
			} else{ 
				let masterTokenID = refAssetNFT.data.masterTokenID
				let refMasterNFT = (&self.ownedNFTs[masterTokenID] as &{NonFungibleToken.NFT}?)!
				let refMasterAssetNFT = refMasterNFT as! &NFT
				return *refMasterAssetNFT.data.orh
			}
		}
		
		access(all)
		fun getISRC(id: UInt64): String?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let serialNumber = refAssetNFT.data.serialNumber
			if serialNumber == 0{ 
				return refAssetNFT.data.isrc
			} else if let isrc = refAssetNFT.data.isrc{ 
				return isrc
			} else{ 
				let masterTokenID = refAssetNFT.data.masterTokenID
				let refMasterNFT = (&self.ownedNFTs[masterTokenID] as &{NonFungibleToken.NFT}?)!
				let refMasterAssetNFT = refMasterNFT as! &NFT
				return refMasterAssetNFT.data.isrc
			}
		}
		
		access(all)
		fun getPerformers(id: UInt64): [String]?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let serialNumber = refAssetNFT.data.serialNumber
			if serialNumber == 0{ 
				return *refAssetNFT.data.performers
			} else if let performers = refAssetNFT.data.performers{ 
				return performers
			} else{ 
				let masterTokenID = refAssetNFT.data.masterTokenID
				let refMasterNFT = (&self.ownedNFTs[masterTokenID] as &{NonFungibleToken.NFT}?)!
				let refMasterAssetNFT = refMasterNFT as! &NFT
				return *refMasterAssetNFT.data.performers
			}
		}
		
		access(all)
		fun getLyricists(id: UInt64): [String]?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let serialNumber = refAssetNFT.data.serialNumber
			if serialNumber == 0{ 
				return *refAssetNFT.data.lyricists
			} else if let lyricists = refAssetNFT.data.lyricists{ 
				return lyricists
			} else{ 
				let masterTokenID = refAssetNFT.data.masterTokenID
				let refMasterNFT = (&self.ownedNFTs[masterTokenID] as &{NonFungibleToken.NFT}?)!
				let refMasterAssetNFT = refMasterNFT as! &NFT
				return *refMasterAssetNFT.data.lyricists
			}
		}
		
		access(all)
		fun getComposers(id: UInt64): [String]?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let serialNumber = refAssetNFT.data.serialNumber
			if serialNumber == 0{ 
				return *refAssetNFT.data.composers
			} else if let composers = refAssetNFT.data.composers{ 
				return composers
			} else{ 
				let masterTokenID = refAssetNFT.data.masterTokenID
				let refMasterNFT = (&self.ownedNFTs[masterTokenID] as &{NonFungibleToken.NFT}?)!
				let refMasterAssetNFT = refMasterNFT as! &NFT
				return *refMasterAssetNFT.data.composers
			}
		}
		
		access(all)
		fun getArrangers(id: UInt64): [String]?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let serialNumber = refAssetNFT.data.serialNumber
			if serialNumber == 0{ 
				return *refAssetNFT.data.arrangers
			} else if let arrangers = refAssetNFT.data.arrangers{ 
				return arrangers
			} else{ 
				let masterTokenID = refAssetNFT.data.masterTokenID
				let refMasterNFT = (&self.ownedNFTs[masterTokenID] as &{NonFungibleToken.NFT}?)!
				let refMasterAssetNFT = refMasterNFT as! &NFT
				return *refMasterAssetNFT.data.arrangers
			}
		}
		
		access(all)
		fun getReleaseDate(id: UInt64): String?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let serialNumber = refAssetNFT.data.serialNumber
			if serialNumber == 0{ 
				return refAssetNFT.data.releaseDate
			} else if let releaseDate = refAssetNFT.data.releaseDate{ 
				return releaseDate
			} else{ 
				let masterTokenID = refAssetNFT.data.masterTokenID
				let refMasterNFT = (&self.ownedNFTs[masterTokenID] as &{NonFungibleToken.NFT}?)!
				let refMasterAssetNFT = refMasterNFT as! &NFT
				return refMasterAssetNFT.data.releaseDate
			}
		}
		
		access(all)
		fun getPlayingTime(id: UInt64): String?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let serialNumber = refAssetNFT.data.serialNumber
			if serialNumber == 0{ 
				return refAssetNFT.data.playingTime
			} else if let playingTime = refAssetNFT.data.playingTime{ 
				return playingTime
			} else{ 
				let masterTokenID = refAssetNFT.data.masterTokenID
				let refMasterNFT = (&self.ownedNFTs[masterTokenID] as &{NonFungibleToken.NFT}?)!
				let refMasterAssetNFT = refMasterNFT as! &NFT
				return refMasterAssetNFT.data.playingTime
			}
		}
		
		access(all)
		fun getAlbumTitle(id: UInt64): String?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let serialNumber = refAssetNFT.data.serialNumber
			if serialNumber == 0{ 
				return refAssetNFT.data.albumTitle
			} else if let albumTitle = refAssetNFT.data.albumTitle{ 
				return albumTitle
			} else{ 
				let masterTokenID = refAssetNFT.data.masterTokenID
				let refMasterNFT = (&self.ownedNFTs[masterTokenID] as &{NonFungibleToken.NFT}?)!
				let refMasterAssetNFT = refMasterNFT as! &NFT
				return refMasterAssetNFT.data.albumTitle
			}
		}
		
		access(all)
		fun getCatalogNumber(id: UInt64): String?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let serialNumber = refAssetNFT.data.serialNumber
			if serialNumber == 0{ 
				return refAssetNFT.data.catalogNumber
			} else if let catalogNumber = refAssetNFT.data.catalogNumber{ 
				return catalogNumber
			} else{ 
				let masterTokenID = refAssetNFT.data.masterTokenID
				let refMasterNFT = (&self.ownedNFTs[masterTokenID] as &{NonFungibleToken.NFT}?)!
				let refMasterAssetNFT = refMasterNFT as! &NFT
				return refMasterAssetNFT.data.catalogNumber
			}
		}
		
		access(all)
		fun getTrackNumber(id: UInt64): String?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let serialNumber = refAssetNFT.data.serialNumber
			if serialNumber == 0{ 
				return refAssetNFT.data.trackNumber
			} else if let trackNumber = refAssetNFT.data.trackNumber{ 
				return trackNumber
			} else{ 
				let masterTokenID = refAssetNFT.data.masterTokenID
				let refMasterNFT = (&self.ownedNFTs[masterTokenID] as &{NonFungibleToken.NFT}?)!
				let refMasterAssetNFT = refMasterNFT as! &NFT
				return refMasterAssetNFT.data.trackNumber
			}
		}
		
		access(all)
		fun getOwnersHash(id: UInt64): String?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			return refAssetNFT.data.ownersHash
		}
		
		access(all)
		fun getRevenueHash(id: UInt64): String?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			return refAssetNFT.data.revenueHash
		}
		
		access(contract)
		fun depositAsset(token: @{NonFungibleToken.NFT}){ 
			let assetToken <- token as! @NFT
			let oldToken <- self.ownedNFTs[assetToken.id] <- assetToken
			destroy oldToken
		}
		
		access(contract)
		fun transferOwner(id: UInt64, ownerFrom: String, ownerTo: String, tokens: UInt32, songID: String, ownersHash: String, previousOwnersHash: String, price: UFix64?, priceUnit: String?, timestamp: String?, webhookID: String?){ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			if refAssetNFT.data.ownersHash != previousOwnersHash{ 
				panic("Previous Owners Hash is incorrect")
			}
			refAssetNFT.transferOwner(ownerFrom: ownerFrom, ownerTo: ownerTo, tokens: tokens, songID: songID, ownersHash: ownersHash, price: price, priceUnit: priceUnit, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(contract)
		fun addRenter(id: UInt64, renter: String, songID: String?, timestamp: String?, webhookID: String?){ 
			pre{ 
				renter.length > 0:
					"Renter is invalid"
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			refAssetNFT.addRenter(renter: renter, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(contract)
		fun removeRenter(id: UInt64, renter: String, songID: String?, timestamp: String?, webhookID: String?){ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			refAssetNFT.removeRenter(renter: renter, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(contract)
		fun addInvitee(id: UInt64, invitee: String, songID: String?, timestamp: String?, webhookID: String?){ 
			pre{ 
				invitee.length > 0:
					"Invitee is invalid"
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			refAssetNFT.addInvitee(invitee: invitee, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(contract)
		fun removeInvitee(id: UInt64, invitee: String, songID: String?, timestamp: String?, webhookID: String?){ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			refAssetNFT.removeInvitee(invitee: invitee, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(contract)
		fun updateType(id: UInt64, type: String, songID: String?, timestamp: String?, webhookID: String?){ 
			pre{ 
				type == "private" || type == "public":
					"Asset Type must be private or public"
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			refAssetNFT.updateType(type: type, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(contract)
		fun setMetadata(id: UInt64, metadata:{ String: String}, songID: String?, timestamp: String?, webhookID: String?){ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			refAssetNFT.setMetadata(metadata: metadata, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(contract)
		fun removeMetadata(id: UInt64, metadata: [String], songID: String?, timestamp: String?, webhookID: String?){ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			refAssetNFT.removeMetadata(metadata: metadata, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(contract)
		fun update(id: UInt64, songID: String?, expiryTimestamp: UFix64?, valid: Bool?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, previousOwnersHash: String?, revenueHash: String?, previousRevenueHash: String?, revenueData: String?, previewURL: String?, lyricsURL: String?, iv: String?, timestamp: String?, uploadID: String?, webhookID: String?){ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
				ownersHash == nil && previousOwnersHash == nil || ownersHash != nil && previousOwnersHash != nil:
					"If owners hash is provided then previous owners hash must also be provided"
				revenueHash == nil && previousRevenueHash == nil || revenueHash != nil && previousRevenueHash != nil:
					"If revenue hash is provided then previous revenue hash must also be provided"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			if previousOwnersHash != nil && refAssetNFT.data.ownersHash != previousOwnersHash{ 
				panic("Previous Owners Hash is incorrect")
			}
			if previousRevenueHash != nil && refAssetNFT.data.revenueHash != previousRevenueHash{ 
				panic("Previous Revenue Hash is incorrect")
			}
			refAssetNFT.update(songID: songID, expiryTimestamp: expiryTimestamp, valid: valid, kID: kID, title: title, description: description, url: url, thumbnailURL: thumbnailURL, orh: orh, isrc: isrc, performers: performers, lyricists: lyricists, composers: composers, arrangers: arrangers, releaseDate: releaseDate, playingTime: playingTime, albumTitle: albumTitle, catalogNumber: catalogNumber, trackNumber: trackNumber, ownersHash: ownersHash, revenueHash: revenueHash, revenueData: revenueData, previewURL: previewURL, lyricsURL: lyricsURL, iv: iv, timestamp: timestamp, uploadID: uploadID, webhookID: webhookID)
		}
		
		access(contract)
		fun reset(id: UInt64, songID: String?, revenueData: String?, previewURL: String?, lyricsURL: String?, iv: String?, timestamp: String?, uploadID: String?, webhookID: String?){ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			if refAssetNFT.data.serialNumber == 0{ 
				panic("Cannot rest master token")
			}
			refAssetNFT.reset(songID: songID, revenueData: revenueData, previewURL: previewURL, lyricsURL: lyricsURL, iv: iv, timestamp: timestamp, uploadID: uploadID, webhookID: webhookID)
		}
		
		access(contract)
		fun destroyNFT(id: UInt64, songID: String?, timestamp: String?, webhookID: String?){ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			if refAssetNFT.data.valid && refAssetNFT.data.expiryTimestamp > getCurrentBlock().timestamp{ 
				panic("Token is not invalid and Token has not expired yet")
			}
			let oldToken <- self.ownedNFTs.remove(key: id)
			emit AssetDestroyed(id: id, songID: songID, timestamp: timestamp, webhookID: webhookID)
			destroy oldToken
		}
		
		access(contract)
		fun dangerouslyDestroyNFT(id: UInt64, songID: String?, timestamp: String?, webhookID: String?){ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refAssetNFT = refNFT as! &NFT
			let oldToken <- self.ownedNFTs.remove(key: id)
			emit AssetDestroyed(id: id, songID: songID, timestamp: timestamp, webhookID: webhookID)
			destroy oldToken
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
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	fun emitCreateEmptyAssetCollectionEvent(userAccountAddress: Address){ 
		emit AssetCollectionInitialized(userAccountAddress: userAccountAddress)
	}
	
	access(all)
	resource Minter{ 
		access(all)
		fun mintNFT(collectionRef: &TrmAssetMSV1_0.Collection, serialNumber: UInt32, masterTokenID: UInt64?, totalTokens: UInt32, owners:{ String: UInt32}, renters: [String], invitees: [String], type: String, expiryTimestamp: UFix64, valid: Bool, metadata:{ String: String}, songID: String?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, revenueHash: String?, previewURL: String?, lyricsURL: String?, timestamp: String?, uploadID: String?, webhookID: String?): UInt64{ 
			pre{ 
				masterTokenID == nil && serialNumber == 0 || masterTokenID != nil && serialNumber > 0:
					"Either master token needs to be minted with serial number 0 or copy token needs to be minted with serial number != 0"
				expiryTimestamp > getCurrentBlock().timestamp:
					"Expiry timestamp should be greater than current timestamp"
			}
			let tokenID = TrmAssetMSV1_0.totalSupply
			var finalMasterTokenID = tokenID
			if let tempMasterTokenID = masterTokenID{ 
				var masterTokenSerialNumber = collectionRef.getSerialNumber(id: tempMasterTokenID)
				if masterTokenSerialNumber != 0{ 
					panic("Invalid Master Token ID")
				}
				finalMasterTokenID = tempMasterTokenID
			}
			collectionRef.depositAsset(token: <-create NFT(id: tokenID, serialNumber: serialNumber, masterTokenID: finalMasterTokenID, totalTokens: totalTokens, owners: owners, renters: renters, invitees: invitees, type: type, expiryTimestamp: expiryTimestamp, valid: valid, metadata: metadata, songID: songID, kID: kID, title: title, description: description, url: url, thumbnailURL: thumbnailURL, orh: orh, isrc: isrc, performers: performers, lyricists: lyricists, composers: composers, arrangers: arrangers, releaseDate: releaseDate, playingTime: playingTime, albumTitle: albumTitle, catalogNumber: catalogNumber, trackNumber: trackNumber, ownersHash: ownersHash, revenueHash: revenueHash, previewURL: previewURL, lyricsURL: lyricsURL, timestamp: timestamp, uploadID: uploadID, webhookID: webhookID))
			TrmAssetMSV1_0.totalSupply = tokenID + 1
			return TrmAssetMSV1_0.totalSupply
		}
		
		access(all)
		fun batchMintNFTs(collectionRef: &TrmAssetMSV1_0.Collection, totalCount: UInt32, startSerialNumber: UInt32, masterTokenID: UInt64, totalTokens: UInt32, owners:{ String: UInt32}, renters: [String], invitees: [String], type: String, expiryTimestamp: UFix64, valid: Bool, metadata:{ String: String}, songID: String?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, revenueHash: String?, previewURL: String?, lyricsURL: String?, timestamp: String?, uploadID: String?, webhookID: String?): UInt64{ 
			pre{ 
				totalCount > 0:
					"Total Count cannot be less than 1"
				startSerialNumber > 0:
					"Batch mint cannot be used to mint the master token"
				expiryTimestamp > getCurrentBlock().timestamp:
					"Expiry timestamp should be greater than current timestamp"
			}
			var masterTokenSerialNumber = collectionRef.getSerialNumber(id: masterTokenID)
			if masterTokenSerialNumber != 0{ 
				panic("Invalid Master Token ID")
			}
			let startTokenID = TrmAssetMSV1_0.totalSupply
			var tokenID = startTokenID
			var counter: UInt32 = 0
			var serialNumber = startSerialNumber
			while counter < totalCount{ 
				collectionRef.depositAsset(token: <-create NFT(id: tokenID, serialNumber: serialNumber, masterTokenID: masterTokenID, totalTokens: totalTokens, owners: owners, renters: renters, invitees: invitees, type: type, expiryTimestamp: expiryTimestamp, valid: valid, metadata: metadata, songID: songID, kID: kID, title: title, description: description, url: url, thumbnailURL: thumbnailURL, orh: orh, isrc: isrc, performers: performers, lyricists: lyricists, composers: composers, arrangers: arrangers, releaseDate: releaseDate, playingTime: playingTime, albumTitle: albumTitle, catalogNumber: catalogNumber, trackNumber: trackNumber, ownersHash: ownersHash, revenueHash: revenueHash, previewURL: previewURL, lyricsURL: lyricsURL, timestamp: timestamp, uploadID: uploadID, webhookID: webhookID))
				counter = counter + 1
				tokenID = tokenID + 1
				serialNumber = serialNumber + 1
			}
			let endTokenID = tokenID - 1
			let endSerialNumber = serialNumber - 1
			emit AssetBatchMinted(startID: startTokenID, endID: endTokenID, totalCount: totalCount, startSerialNumber: startSerialNumber, endSerialNumber: endSerialNumber, masterTokenID: masterTokenID, totalTokens: totalTokens, owners: owners, renters: renters, invitees: invitees, type: type, expiryTimestamp: expiryTimestamp, valid: valid, metadata: metadata, songID: songID, kID: kID, title: title, description: description, url: url, thumbnailURL: thumbnailURL, orh: orh, isrc: isrc, performers: performers, lyricists: lyricists, composers: composers, arrangers: arrangers, releaseDate: releaseDate, playingTime: playingTime, albumTitle: albumTitle, catalogNumber: catalogNumber, trackNumber: trackNumber, ownersHash: ownersHash, revenueHash: revenueHash, previewURL: previewURL, lyricsURL: lyricsURL, timestamp: timestamp, uploadID: uploadID, webhookID: webhookID)
			TrmAssetMSV1_0.totalSupply = tokenID
			return TrmAssetMSV1_0.totalSupply
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun transferOwner(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, ownerFrom: String, ownerTo: String, tokens: UInt32, songID: String, ownersHash: String, previousOwnersHash: String, price: UFix64?, priceUnit: String?, timestamp: String?, webhookID: String?){ 
			collectionRef.transferOwner(id: id, ownerFrom: ownerFrom, ownerTo: ownerTo, tokens: tokens, songID: songID, ownersHash: ownersHash, previousOwnersHash: previousOwnersHash, price: price, priceUnit: priceUnit, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(all)
		fun addRenter(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, renter: String, songID: String?, timestamp: String?, webhookID: String?){ 
			collectionRef.addRenter(id: id, renter: renter, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(all)
		fun removeRenter(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, renter: String, songID: String?, timestamp: String?, webhookID: String?){ 
			collectionRef.removeRenter(id: id, renter: renter, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(all)
		fun addInvitee(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, invitee: String, songID: String?, timestamp: String?, webhookID: String?){ 
			collectionRef.addInvitee(id: id, invitee: invitee, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(all)
		fun removeInvitee(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, invitee: String, songID: String?, timestamp: String?, webhookID: String?){ 
			collectionRef.removeInvitee(id: id, invitee: invitee, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(all)
		fun updateType(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, type: String, songID: String?, timestamp: String?, webhookID: String?){ 
			collectionRef.updateType(id: id, type: type, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(all)
		fun setAssetMetadata(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, metadata:{ String: String}, songID: String?, timestamp: String?, webhookID: String?){ 
			collectionRef.setMetadata(id: id, metadata: metadata, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(all)
		fun removeAssetMetadata(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, metadata: [String], songID: String?, timestamp: String?, webhookID: String?){ 
			collectionRef.removeMetadata(id: id, metadata: metadata, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(all)
		fun updateAsset(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, songID: String?, expiryTimestamp: UFix64?, valid: Bool?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, previousOwnersHash: String?, revenueHash: String?, previousRevenueHash: String?, revenueData: String?, previewURL: String?, lyricsURL: String?, iv: String?, timestamp: String?, uploadID: String?, webhookID: String?){ 
			collectionRef.update(id: id, songID: songID, expiryTimestamp: expiryTimestamp, valid: valid, kID: kID, title: title, description: description, url: url, thumbnailURL: thumbnailURL, orh: orh, isrc: isrc, performers: performers, lyricists: lyricists, composers: composers, arrangers: arrangers, releaseDate: releaseDate, playingTime: playingTime, albumTitle: albumTitle, catalogNumber: catalogNumber, trackNumber: trackNumber, ownersHash: ownersHash, previousOwnersHash: previousOwnersHash, revenueHash: revenueHash, previousRevenueHash: previousRevenueHash, revenueData: revenueData, previewURL: previewURL, lyricsURL: lyricsURL, iv: iv, timestamp: timestamp, uploadID: uploadID, webhookID: webhookID)
		}
		
		access(all)
		fun resetAsset(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, songID: String?, revenueData: String?, previewURL: String?, lyricsURL: String?, iv: String?, timestamp: String?, uploadID: String?, webhookID: String?){ 
			collectionRef.reset(id: id, songID: songID, revenueData: revenueData, previewURL: previewURL, lyricsURL: lyricsURL, iv: iv, timestamp: timestamp, uploadID: uploadID, webhookID: webhookID)
		}
		
		access(all)
		fun destroyNFT(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, songID: String?, timestamp: String?, webhookID: String?){ 
			collectionRef.destroyNFT(id: id, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(all)
		fun batchDestroyNFTs(collectionRef: &TrmAssetMSV1_0.Collection, ids: [UInt64], songID: String?, timestamp: String?, webhookID: String?){ 
			for id in ids{ 
				collectionRef.destroyNFT(id: id, songID: songID, timestamp: timestamp, webhookID: webhookID)
			}
			emit AssetBatchDestroyed(ids: ids, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(all)
		fun dangerouslyDestroyNFT(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, songID: String?, timestamp: String?, webhookID: String?){ 
			collectionRef.dangerouslyDestroyNFT(id: id, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
		
		access(all)
		fun batchDangerouslyDestroyNFTs(collectionRef: &TrmAssetMSV1_0.Collection, ids: [UInt64], songID: String?, timestamp: String?, webhookID: String?){ 
			for id in ids{ 
				collectionRef.dangerouslyDestroyNFT(id: id, songID: songID, timestamp: timestamp, webhookID: webhookID)
			}
			emit AssetBatchDestroyed(ids: ids, songID: songID, timestamp: timestamp, webhookID: webhookID)
		}
	}
	
	init(){ 
		self.totalSupply = 0
		
		// Settings paths
		self.collectionStoragePath = /storage/TrmAssetMSV1_0Collection
		self.collectionPublicPath = /public/TrmAssetMSV1_0Collection
		self.minterStoragePath = /storage/TrmAssetMSV1_0Minter
		self.adminStoragePath = /storage/TrmAssetMSV1_0Admin
		
		// First, check to see if a minter resource already exists
		if self.account.type(at: self.minterStoragePath) == nil{ 
			
			// Put the minter in storage with access only to admin
			self.account.storage.save(<-create Minter(), to: self.minterStoragePath)
		}
		
		// First, check to see if a minter resource already exists
		if self.account.type(at: self.adminStoragePath) == nil{ 
			
			// Put the minter in storage with access only to admin
			self.account.storage.save(<-create Admin(), to: self.adminStoragePath)
		}
		emit ContractInitialized()
	}
}
