/**

    TrmAssetMSV1_0.cdc

*/

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract TrmAssetMSV1_0: NonFungibleToken {
    // The total number of tokens of this type in existence
    pub var totalSupply: UInt64
    
    pub event ContractInitialized()
    pub event AssetCollectionInitialized(userAccountAddress: Address)
    pub event AssetMinted(id: UInt64, serialNumber: UInt32, masterTokenID: UInt64?, totalTokens: UInt32, owners: {String: UInt32}, renters: [String], invitees: [String], type: String, expiryTimestamp: UFix64, valid: Bool, metadata: {String: String}, songID: String?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, revenueHash: String?, previewURL: String?, lyricsURL: String?, timestamp: String?, uploadID: String?, webhookID: String?)
    pub event AssetBatchMinted(startID: UInt64, endID: UInt64, totalCount: UInt32, startSerialNumber: UInt32, endSerialNumber: UInt32, masterTokenID: UInt64, totalTokens: UInt32, owners: {String: UInt32}, renters: [String], invitees: [String], type: String, expiryTimestamp: UFix64, valid: Bool, metadata: {String: String}, songID: String?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, revenueHash: String?, previewURL: String?, lyricsURL: String?, timestamp: String?, uploadID: String?, webhookID: String?)
    pub event AssetUpdated(id: UInt64, songID: String?, expiryTimestamp: UFix64?, valid: Bool?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, revenueHash: String?, revenueData: String?, previewURL: String?, lyricsURL: String?, iv: String?, timestamp: String?, uploadID: String?, webhookID: String?)
    pub event AssetOwnerTransfer(id: UInt64, ownerFrom: String, ownerTo: String, tokens: UInt32, owners: {String: UInt32}, songID: String?, ownersHash: String?, price: UFix64?, priceUnit: String?, timestamp: String?, webhookID: String?)
    pub event AssetRenterAdded(id: UInt64, renter: String, songID: String?, timestamp: String?, webhookID: String?)
    pub event AssetRenterRemoved(id: UInt64, renter: String, songID: String?, timestamp: String?, webhookID: String?)
    pub event AssetInviteeAdded(id: UInt64, invitee: String, songID: String?, timestamp: String?, webhookID: String?)
    pub event AssetInviteeRemoved(id: UInt64, invitee: String, songID: String?, timestamp: String?, webhookID: String?)
    pub event AssetTypeUpdated(id: UInt64, type: String, songID: String?, timestamp: String?, webhookID: String?)
    pub event AssetMetadataUpdated(id: UInt64, metadata: {String: String}, songID: String?, timestamp: String?, webhookID: String?)
    pub event AssetMetadataRemoved(id: UInt64, metadata: [String], songID: String?, timestamp: String?, webhookID: String?)
    pub event AssetDestroyed(id: UInt64, songID: String?, timestamp: String?, webhookID: String?)
    pub event AssetBatchDestroyed(ids: [UInt64], songID: String?, timestamp: String?, webhookID: String?)
    
    // Event that is emitted when a token is withdrawn, indicating the owner of the collection that it was withdrawn from. If the collection is not in an account's storage, `from` will be `nil`.
    pub event Withdraw(id: UInt64, from: Address?)
    // Event that emitted when a token is deposited to a collection. It indicates the owner of the collection that it was deposited to.
    pub event Deposit(id: UInt64, to: Address?)

    // Paths where Storage and capabilities are stored
    pub let collectionStoragePath: StoragePath
    pub let collectionPublicPath: PublicPath
    pub let minterStoragePath: StoragePath
    pub let adminStoragePath: StoragePath

    pub enum AssetType: UInt8 {
        pub case private
        pub case public
    }

    pub fun assetTypeToString(_ assetType: AssetType): String {
        switch assetType {
            case AssetType.private:
                return "private"
            case AssetType.public:
                return "public"
            default:
                return ""
        }
    }

    pub fun stringToAssetType(_ assetTypeStr: String): AssetType {
        switch assetTypeStr {
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
    pub struct AssetData {
        pub let serialNumber: UInt32
        pub let masterTokenID: UInt64
        pub let totalTokens: UInt32
        pub var owners: {String: UInt32}
        pub var renters: [String]
        pub var invitees: [String]
        pub var type: AssetType
        pub var expiryTimestamp: UFix64
        pub var valid: Bool
        pub var metadata: {String: String}

        pub let songID: String?
        pub var kID: String?
        pub var title: String?
        pub var description: String?
        pub var url: String?
        pub var thumbnailURL: String?
        pub var orh: [String]?
        pub var isrc: String?
        pub var performers: [String]?
        pub var lyricists: [String]?
        pub var composers: [String]?
        pub var arrangers: [String]?
        pub var releaseDate: String?
        pub var playingTime: String?
        pub var albumTitle: String?
        pub var catalogNumber: String?
        pub var trackNumber: String?

        pub var ownersHash: String?
        pub var revenueHash: String?

        access(contract) fun transferOwner(ownerFrom: String, ownerTo: String, tokens: UInt32, ownersHash: String) {
            pre {
                self.owners.containsKey(ownerFrom): "The account from which ownership is transferred does not own this asset"

                tokens <= self.totalTokens: "Total tokens tranferred should be less than total tokens"

                self.owners[ownerFrom]! >= tokens: "The account from which ownership is transferred does not own enough tokens for this asset"
            }

            self.owners[ownerFrom] = self.owners[ownerFrom]! - tokens
            if let ownerTokens = self.owners[ownerTo] {
                self.owners[ownerTo] = ownerTokens + tokens
            } else {
                self.owners[ownerTo] = tokens
            }

            var totalTokens: UInt32 = 0
            for owner in self.owners.keys {
                if let ownerTokens: UInt32 = self.owners[owner] {
                    if (ownerTokens == 0) {
                        self.owners.remove(key: owner)
                    } else {
                        totalTokens = totalTokens + ownerTokens
                    }
                    
                }
            }

            if (totalTokens != self.totalTokens) { panic("Owner tokens do not sum to total tokens") }

            if (self.owners.length >= 1000) { panic("More than 1000 owners per asset is not supported") }

            self.ownersHash = ownersHash
        }

        access(contract) fun ownerExists(owner: String): Bool {
            return self.owners.containsKey(owner)
        }

        access(contract) fun addRenter(renter: String) {
            pre {
                renter.length > 0: "Renter is invalid"

                self.renters.length < 100: "Maximum 100 renters allowed"
            }

            if !self.renters.contains(renter) {
                self.renters.append(renter)
            }
        }

        access(contract) fun removeRenter(renter: String) {
            if let renterIndex = self.renters.firstIndex(of: renter) {
                self.renters.remove(at: renterIndex)
            }
        }

        access(contract) fun removeRenters() {
            self.renters = []
        }

        access(contract) fun renterExists(renter: String): Bool {
            return self.renters.contains(renter)
        }

        access(contract) fun addInvitee(invitee: String) {
            pre {
                invitee.length > 0: "Invitee is invalid"

                self.invitees.length < 100: "Maximum 100 renters allowed"
            }

            if !self.invitees.contains(invitee) {
                self.invitees.append(invitee)
            }
        }

        access(contract) fun removeInvitee(invitee: String) {
            if let inviteeIndex = self.invitees.firstIndex(of: invitee) {
                self.invitees.remove(at: inviteeIndex)
            }
        }

        access(contract) fun removeInvitees() {
            self.invitees = []
        }

        access(contract) fun inviteeExists(invitee: String): Bool {
            return self.invitees.contains(invitee)
        }

        access(contract) fun setType(type: String) {
            pre {
                type == "private" || type == "public": 
                    "Asset Type must be private or public"
            }

            self.type = TrmAssetMSV1_0.stringToAssetType(type)
        }

        access(contract) fun setExpiryTimestamp(expiryTimestamp: UFix64) { 
            pre {
                expiryTimestamp > getCurrentBlock().timestamp: "Expiry timestamp should be greater than current timestamp"
            }
            self.expiryTimestamp = expiryTimestamp 
        }

        access(contract) fun setValid(valid: Bool) { self.valid = valid }

        access(contract) fun setMetadata(metadata: {String: String}) {
            pre {
                metadata.length > 0: "Total length of metadata cannot be less than 1"
            }

            for metadataEntry in metadata.keys {
                self.metadata[metadataEntry] = metadata[metadataEntry]
            }
        }

        access(contract) fun removeMetadata(metadata: [String]) {
            pre {
                metadata.length > 0: "Total length of metadata cannot be less than 1"
            }

            for metadataEntry in metadata {
                self.metadata.remove(key: metadataEntry)
            }
        }

        access(contract) fun metadataExists(metadataEntry: String): Bool {
            return self.metadata.containsKey(metadataEntry)
        }



        access(contract) fun setKID(kID: String?) { self.kID = kID }
        access(contract) fun setTitle(title: String?) { self.title = title }
        access(contract) fun setDescription(description: String?) { self.description = description }
        access(contract) fun setURL(url: String?) { self.url = url }
        access(contract) fun setThumbnailURL(thumbnailURL: String?) { self.thumbnailURL = thumbnailURL }
        access(contract) fun setORH(orh: [String]?) { self.orh = orh }
        access(contract) fun setISRC(isrc: String?) { self.isrc = isrc }
        access(contract) fun setPerformers(performers: [String]?) { self.performers = performers }
        access(contract) fun setLyricists(lyricists: [String]?) { self.lyricists = lyricists }
        access(contract) fun setComposers(composers: [String]?) { self.composers = composers }
        access(contract) fun setArrangers(arrangers: [String]?) { self.arrangers = arrangers }
        access(contract) fun setReleaseDate(releaseDate: String?) { self.releaseDate = releaseDate }
        access(contract) fun setPlayingTime(playingTime: String?) { self.playingTime = playingTime }
        access(contract) fun setAlbumTitle(albumTitle: String?) { self.albumTitle = albumTitle }
        access(contract) fun setCatalogNumber(catalogNumber: String?) { self.catalogNumber = catalogNumber }
        access(contract) fun setTrackNumber(trackNumber: String?) { self.trackNumber = trackNumber }
        access(contract) fun setOwnersHash(ownersHash: String?) { self.ownersHash = ownersHash }
        access(contract) fun setRevenueHash(revenueHash: String?) { self.revenueHash = revenueHash }    

        init(serialNumber: UInt32, masterTokenID: UInt64, totalTokens: UInt32, owners: {String: UInt32}, renters: [String], invitees: [String], type: String, expiryTimestamp: UFix64, valid: Bool, metadata: {String: String}, songID: String?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, revenueHash: String?) {
            pre {
                type == "private" || type == "public": "Asset Type must be private or public"
                serialNumber >= 0: "Serial Number is invalid"
                totalTokens > 0: "Total Tokens is invalid"
                owners.length > 0: "Owners is invalid"
                owners.length <= 1000: "More than 1000 owners per asset is not supported"
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
            for owner in self.owners.keys {
                if let ownerTokens: UInt32 = self.owners[owner] {
                    if (ownerTokens == 0) {
                        self.owners.remove(key: owner)
                    } else {
                        totalTokens = totalTokens + ownerTokens
                    }
                    
                }
            }

            if (totalTokens != self.totalTokens) { panic("Owner tokens do not sum to total tokens") }
        }
    }

    //  NFT
    //
    // The main Asset NFT resource that can be bought and sold by users
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let data: AssetData

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.data.title ?? "",
                        description: self.data.description ?? "",
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.data.thumbnailURL ?? ""
                        )
                    )
            }

            return nil
        }

        access(contract) fun transferOwner(ownerFrom: String, ownerTo: String, tokens: UInt32, songID: String, ownersHash: String, price: UFix64?, priceUnit: String?, timestamp: String?, webhookID: String?) {
            self.data.transferOwner(ownerFrom: ownerFrom, ownerTo: ownerTo, tokens: tokens, ownersHash: ownersHash)

            emit AssetOwnerTransfer(id: self.id, ownerFrom: ownerFrom, ownerTo: ownerTo, tokens: tokens, owners: self.data.owners, songID: songID, ownersHash: ownersHash, price: price, priceUnit: priceUnit, timestamp: timestamp, webhookID: webhookID)
        }

        access(contract) fun addRenter(renter: String, songID: String?, timestamp: String?, webhookID: String?) {
            self.data.addRenter(renter: renter)

            emit AssetRenterAdded(id: self.id, renter: renter, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        access(contract) fun removeRenter(renter: String, songID: String?, timestamp: String?, webhookID: String?) {
            self.data.removeRenter(renter: renter)

            emit AssetRenterRemoved(id: self.id, renter: renter, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        access(contract) fun addInvitee(invitee: String, songID: String?, timestamp: String?, webhookID: String?) {
            self.data.addInvitee(invitee: invitee)

            emit AssetInviteeAdded(id: self.id, invitee: invitee, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        access(contract) fun removeInvitee(invitee: String, songID: String?, timestamp: String?, webhookID: String?) {
            self.data.removeInvitee(invitee: invitee)

            emit AssetInviteeRemoved(id: self.id, invitee: invitee, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        access(contract) fun updateType(type: String, songID: String?, timestamp: String?, webhookID: String?) {
            self.data.setType(type: type)

            emit AssetTypeUpdated(id: self.id, type: type, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        access(contract) fun setMetadata(metadata: {String: String}, songID: String?, timestamp: String?, webhookID: String?) {
            self.data.setMetadata(metadata: metadata)

            emit AssetMetadataUpdated(id: self.id, metadata: metadata, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        access(contract) fun removeMetadata(metadata: [String], songID: String?, timestamp: String?, webhookID: String?) {
            self.data.removeMetadata(metadata: metadata)

            emit AssetMetadataRemoved(id: self.id, metadata: metadata, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        access(contract) fun update(songID: String?, expiryTimestamp: UFix64?, valid: Bool?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, revenueHash: String?, revenueData: String?, previewURL: String?, lyricsURL: String?, iv: String?, timestamp: String?, uploadID: String?, webhookID: String?) {
            
            if let tempExpiryTimestamp = expiryTimestamp {self.data.setExpiryTimestamp(expiryTimestamp: tempExpiryTimestamp)}
            if let tempValid = valid {self.data.setValid(valid: tempValid)}
            if let tempKID = kID { self.data.setKID(kID: tempKID) }
            if let tempTitle = title { self.data.setTitle(title: tempTitle) }
            if let tempDescription = description { self.data.setDescription(description: tempDescription) }
            if let tempURL = url { self.data.setURL(url: tempURL) }
            if let tempThumbnailURL = thumbnailURL { self.data.setThumbnailURL(thumbnailURL: tempThumbnailURL) }
            if let tempORH = orh { self.data.setORH(orh: tempORH) }
            if let tempISRC = isrc { self.data.setISRC(isrc: tempISRC) }
            if let tempPerformers = performers { self.data.setPerformers(performers: tempPerformers) }
            if let tempLyricists = lyricists { self.data.setLyricists(lyricists: tempLyricists) }
            if let tempComposers = composers { self.data.setComposers(composers: tempComposers) }
            if let tempArrangers = arrangers { self.data.setArrangers(arrangers: tempArrangers) }
            if let tempReleaseDate = releaseDate { self.data.setReleaseDate(releaseDate: tempReleaseDate) }
            if let tempPlayingTime = playingTime { self.data.setPlayingTime(playingTime: tempPlayingTime) }
            if let tempAlbumTitle = albumTitle { self.data.setAlbumTitle(albumTitle: tempAlbumTitle) }
            if let tempCatalogNumber = catalogNumber { self.data.setCatalogNumber(catalogNumber: tempCatalogNumber) }
            if let tempTrackNumber = trackNumber { self.data.setTrackNumber(trackNumber: tempTrackNumber) }
            if let tempOwnersHash = ownersHash { self.data.setOwnersHash(ownersHash: tempOwnersHash) }
            if let tempRevenueHash = revenueHash { self.data.setRevenueHash(revenueHash: tempRevenueHash) }

            emit AssetUpdated(id: self.id, songID: songID, expiryTimestamp: expiryTimestamp, valid: valid, kID: kID, title: title, description: description, url: url, thumbnailURL: thumbnailURL, orh: orh, isrc: isrc, performers: performers, lyricists: lyricists, composers: composers, arrangers: arrangers, releaseDate: releaseDate, playingTime: playingTime, albumTitle: albumTitle, catalogNumber: catalogNumber, trackNumber: trackNumber, ownersHash: ownersHash, revenueHash: revenueHash, revenueData: revenueData, previewURL: previewURL, lyricsURL: lyricsURL, iv: iv, timestamp: timestamp, uploadID: uploadID, webhookID: webhookID)
        }

        access(contract) fun reset(songID: String?, revenueData: String?, previewURL: String?, lyricsURL: String?, iv: String?, timestamp: String?, uploadID: String?, webhookID: String?) {
            
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

        init(id: UInt64, serialNumber: UInt32, masterTokenID: UInt64, totalTokens: UInt32, owners: {String: UInt32}, renters: [String], invitees: [String], type: String, expiryTimestamp: UFix64, valid: Bool, metadata: {String: String}, songID: String?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, revenueHash: String?, previewURL: String?, lyricsURL: String?, timestamp: String?, uploadID: String?, webhookID: String?) {
            self.id = id

            self.data = AssetData(serialNumber: serialNumber, masterTokenID: masterTokenID, totalTokens: totalTokens, owners: owners, renters: renters, invitees: invitees, type: type, expiryTimestamp: expiryTimestamp, valid: valid, metadata: metadata, songID: songID, kID: kID, title: title, description: description, url: url, thumbnailURL: thumbnailURL, orh: orh, isrc: isrc, performers: performers, lyricists: lyricists, composers: composers, arrangers: arrangers, releaseDate: releaseDate, playingTime: playingTime, albumTitle: albumTitle, catalogNumber: catalogNumber, trackNumber: trackNumber, ownersHash: ownersHash, revenueHash: revenueHash)

            emit AssetMinted(id: id, serialNumber: serialNumber, masterTokenID: masterTokenID, totalTokens: totalTokens, owners: owners, renters: renters, invitees: invitees, type: type, expiryTimestamp: expiryTimestamp, valid: valid, metadata: metadata, songID: songID, kID: kID, title: title, description: description, url: url, thumbnailURL: thumbnailURL, orh: orh, isrc: isrc, performers: performers, lyricists: lyricists, composers: composers, arrangers: arrangers, releaseDate: releaseDate, playingTime: playingTime, albumTitle: albumTitle, catalogNumber: catalogNumber, trackNumber: trackNumber, ownersHash: ownersHash, revenueHash: revenueHash, previewURL: previewURL, lyricsURL: lyricsURL, timestamp: timestamp, uploadID: uploadID, webhookID: webhookID)
        }

        destroy() {
        }
    }

    // CollectionPublic
    //
    // Public interface for Asset Collection
    // This exposes functions for depositing NFTs
    // and also for returning some info for a specific
    // Asset NFT id
    pub resource interface CollectionPublic {
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowAsset(id: UInt64): &NFT
        pub fun getAssetInfo(id: UInt64): AssetData
        pub fun idExists(id: UInt64): Bool
        pub fun getSerialNumber(id: UInt64): UInt32
        pub fun getMasterTokenID(id: UInt64): UInt64?
        pub fun getTotalTokens(id: UInt64): UInt32
        pub fun getOwners(id: UInt64): {String: UInt32}
        pub fun getOwner(id: UInt64, owner: String): UInt32?
        pub fun ownerExists(id: UInt64, owner: String): Bool
        pub fun getRenters(id: UInt64): [String]
        pub fun renterExists(id: UInt64, renter: String): Bool
        pub fun getInvitees(id: UInt64): [String]
        pub fun inviteeExists(id: UInt64, invitee: String): Bool
        pub fun getAssetType(id: UInt64): String
        pub fun getExpiryTimestamp(id: UInt64): UFix64
        pub fun isExpired(id: UInt64): Bool
        pub fun getValid(id: UInt64): Bool 
        pub fun isValid(id: UInt64): Bool
        pub fun getMetadata(id: UInt64): {String: String}
        pub fun getMetadataEntry(id: UInt64, metadataEntry: String): String?
        pub fun getSongID(id: UInt64): String?
        pub fun getKID(id: UInt64): String?
        pub fun getTitle(id: UInt64): String?
        pub fun getDescription(id: UInt64): String?
        pub fun getURL(id: UInt64): String?
        pub fun getThumbnailURL(id: UInt64): String?
        pub fun getORH(id: UInt64): [String]?
        pub fun getISRC(id: UInt64): String?
        pub fun getPerformers(id: UInt64): [String]?
        pub fun getLyricists(id: UInt64): [String]?
        pub fun getComposers(id: UInt64): [String]?
        pub fun getArrangers(id: UInt64): [String]?
        pub fun getReleaseDate(id: UInt64): String?
        pub fun getPlayingTime(id: UInt64): String?
        pub fun getAlbumTitle(id: UInt64): String?
        pub fun getCatalogNumber(id: UInt64): String?
        pub fun getTrackNumber(id: UInt64): String?
        pub fun getOwnersHash(id: UInt64): String?
        pub fun getRevenueHash(id: UInt64): String?
    }

    // Collection
    //
    // The resource that stores a user's Asset NFT collection.
    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, CollectionPublic {
        
        // Dictionary to hold the NFTs in the Collection
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init() {
            self.ownedNFTs <- {}
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            pre {
                false: "Withdrawing Asset directly from Asset contract is not allowed"
            }

            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Error withdrawing Asset NFT")
            
            return <-token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            pre {
                false: "Depositing Asset directly to Asset contract is not allowed"
            }

            let assetToken <- token as! @NFT

            let oldToken <- self.ownedNFTs[assetToken.id] <- assetToken
            destroy oldToken
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            return refAssetNFT
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowAsset(id: UInt64): &NFT {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!

            return refNFT as! &NFT
        }

        pub fun getAssetInfo(id: UInt64): AssetData {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            let serialNumber = refAssetNFT.data.serialNumber

            if serialNumber == 0 {
                return refAssetNFT.data
            } else {
                let masterTokenID = refAssetNFT.data.masterTokenID
                let refMasterNFT = (&self.ownedNFTs[masterTokenID] as auth &NonFungibleToken.NFT?)!
                let refMasterAssetNFT = refMasterNFT as! &NFT

                return AssetData(
                    serialNumber: refAssetNFT.data.serialNumber,
                    masterTokenID: refAssetNFT.data.masterTokenID,
                    totalTokens: refAssetNFT.data.totalTokens,
                    owners: refAssetNFT.data.owners,
                    renters: refAssetNFT.data.renters,
                    invitees: refAssetNFT.data.invitees,
                    type: TrmAssetMSV1_0.assetTypeToString(refAssetNFT.data.type),
                    expiryTimestamp: refAssetNFT.data.expiryTimestamp,
                    valid: refAssetNFT.data.valid,
                    metadata: refAssetNFT.data.metadata,
                    songID: refAssetNFT.data.songID ?? refMasterAssetNFT.data.songID,
                    kID: refAssetNFT.data.kID ?? refMasterAssetNFT.data.kID,
                    title: refAssetNFT.data.title ?? refMasterAssetNFT.data.title,
                    description: refAssetNFT.data.description ?? refMasterAssetNFT.data.description,
                    url: refAssetNFT.data.url ?? refMasterAssetNFT.data.url,
                    thumbnailURL: refAssetNFT.data.thumbnailURL ?? refMasterAssetNFT.data.thumbnailURL,
                    orh: refAssetNFT.data.orh ?? refMasterAssetNFT.data.orh,
                    isrc: refAssetNFT.data.isrc ?? refMasterAssetNFT.data.isrc,
                    performers: refAssetNFT.data.performers ?? refMasterAssetNFT.data.performers,
                    lyricists: refAssetNFT.data.lyricists ?? refMasterAssetNFT.data.lyricists,
                    composers: refAssetNFT.data.composers ?? refMasterAssetNFT.data.composers,
                    arrangers: refAssetNFT.data.arrangers ?? refMasterAssetNFT.data.arrangers,
                    releaseDate: refAssetNFT.data.releaseDate ?? refMasterAssetNFT.data.releaseDate,
                    playingTime: refAssetNFT.data.playingTime ?? refMasterAssetNFT.data.playingTime,
                    albumTitle: refAssetNFT.data.albumTitle ?? refMasterAssetNFT.data.albumTitle,
                    catalogNumber: refAssetNFT.data.catalogNumber ?? refMasterAssetNFT.data.catalogNumber,
                    trackNumber: refAssetNFT.data.trackNumber ?? refMasterAssetNFT.data.trackNumber,
                    ownersHash: refAssetNFT.data.ownersHash,
                    revenueHash: refAssetNFT.data.revenueHash,
                )
            }
        }

        pub fun idExists(id: UInt64): Bool {
            return self.ownedNFTs[id] != nil
        }

        pub fun getSerialNumber(id: UInt64): UInt32 {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            return refAssetNFT.data.serialNumber
        }
        pub fun getMasterTokenID(id: UInt64): UInt64 {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            return refAssetNFT.data.masterTokenID
        }

        pub fun getTotalTokens(id: UInt64): UInt32 {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            return refAssetNFT.data.totalTokens
        }

        pub fun getOwners(id: UInt64): {String: UInt32} {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            return refAssetNFT.data.owners
        }

        pub fun getOwner(id: UInt64, owner: String): UInt32? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT
            let owners = refAssetNFT.data.owners

            return owners[owner]
        }

        pub fun ownerExists(id: UInt64, owner: String): Bool {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT
            let owners = refAssetNFT.data.owners

            return owners.containsKey(owner)
        }

        pub fun getRenters(id: UInt64): [String] {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            return refAssetNFT.data.renters
        }

        pub fun renterExists(id: UInt64, renter: String): Bool {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT
            let renters = refAssetNFT.data.renters

            return renters.contains(renter)
        }

        pub fun getInvitees(id: UInt64): [String] {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            return refAssetNFT.data.invitees
        }

        pub fun inviteeExists(id: UInt64, invitee: String): Bool {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT
            let invitees = refAssetNFT.data.invitees

            return invitees.contains(invitee)
        }

        pub fun getAssetType(id: UInt64): String {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            return TrmAssetMSV1_0.assetTypeToString(refAssetNFT.data.type)
        }

        pub fun getExpiryTimestamp(id: UInt64): UFix64 {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            return refAssetNFT.data.expiryTimestamp
        }

        pub fun isExpired(id: UInt64): Bool {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            return refAssetNFT.data.expiryTimestamp < getCurrentBlock().timestamp
        }

        pub fun getValid(id: UInt64): Bool {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            return refAssetNFT.data.valid
        }

        pub fun isValid(id: UInt64): Bool {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            return refAssetNFT.data.valid && refAssetNFT.data.expiryTimestamp >= getCurrentBlock().timestamp
        }

        pub fun getMetadata(id: UInt64): {String: String} {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            return refAssetNFT.data.metadata
        }

        pub fun getMetadataEntry(id: UInt64, metadataEntry: String): String? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT
            let metadata = refAssetNFT.data.metadata

            return metadata[metadataEntry]
        }

        pub fun getSongID(id: UInt64): String? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT
            
            let serialNumber = refAssetNFT.data.serialNumber

            if serialNumber == 0 {
                return refAssetNFT.data.songID
            } else if let songID = refAssetNFT.data.songID {
                return songID
            } else {
                let masterTokenID = refAssetNFT.data.masterTokenID
                let refMasterNFT = (&self.ownedNFTs[masterTokenID] as auth &NonFungibleToken.NFT?)!
                let refMasterAssetNFT = refMasterNFT as! &NFT

                return refMasterAssetNFT.data.songID
            }
        }

        pub fun getKID(id: UInt64): String? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            let serialNumber = refAssetNFT.data.serialNumber

            if serialNumber == 0 {
                return refAssetNFT.data.kID
            } else if let kID = refAssetNFT.data.kID {
                return kID
            } else {
                let masterTokenID = refAssetNFT.data.masterTokenID
                let refMasterNFT = (&self.ownedNFTs[masterTokenID] as auth &NonFungibleToken.NFT?)!
                let refMasterAssetNFT = refMasterNFT as! &NFT

                return refMasterAssetNFT.data.kID
            }
        }

        pub fun getTitle(id: UInt64): String? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }
            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            let serialNumber = refAssetNFT.data.serialNumber

            if serialNumber == 0 {
                return refAssetNFT.data.title
            } else if let title = refAssetNFT.data.title {
                return title
            } else {
                let masterTokenID = refAssetNFT.data.masterTokenID
                let refMasterNFT = (&self.ownedNFTs[masterTokenID] as auth &NonFungibleToken.NFT?)!
                let refMasterAssetNFT = refMasterNFT as! &NFT

                return refMasterAssetNFT.data.title
            }
        }

        pub fun getDescription(id: UInt64): String? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            let serialNumber = refAssetNFT.data.serialNumber

            if serialNumber == 0 {
                return refAssetNFT.data.description
            } else if let description = refAssetNFT.data.description {
                return description
            } else {
                let masterTokenID = refAssetNFT.data.masterTokenID
                let refMasterNFT = (&self.ownedNFTs[masterTokenID] as auth &NonFungibleToken.NFT?)!
                let refMasterAssetNFT = refMasterNFT as! &NFT

                return refMasterAssetNFT.data.description
            }
        }

        pub fun getURL(id: UInt64): String? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            let serialNumber = refAssetNFT.data.serialNumber

            if serialNumber == 0 {
                return refAssetNFT.data.url
            } else if let url = refAssetNFT.data.url {
                return url
            } else {
                let masterTokenID = refAssetNFT.data.masterTokenID
                let refMasterNFT = (&self.ownedNFTs[masterTokenID] as auth &NonFungibleToken.NFT?)!
                let refMasterAssetNFT = refMasterNFT as! &NFT

                return refMasterAssetNFT.data.url
            }
        }

        pub fun getThumbnailURL(id: UInt64): String? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            let serialNumber = refAssetNFT.data.serialNumber

            if serialNumber == 0 {
                return refAssetNFT.data.thumbnailURL
            } else if let thumbnailURL = refAssetNFT.data.thumbnailURL {
                return thumbnailURL
            } else {
                let masterTokenID = refAssetNFT.data.masterTokenID
                let refMasterNFT = (&self.ownedNFTs[masterTokenID] as auth &NonFungibleToken.NFT?)!
                let refMasterAssetNFT = refMasterNFT as! &NFT

                return refMasterAssetNFT.data.thumbnailURL
            }
        }

        pub fun getORH(id: UInt64): [String]? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }
            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            let serialNumber = refAssetNFT.data.serialNumber

            if serialNumber == 0 {
                return refAssetNFT.data.orh
            } else if let orh = refAssetNFT.data.orh {
                return orh
            } else {
                let masterTokenID = refAssetNFT.data.masterTokenID
                let refMasterNFT = (&self.ownedNFTs[masterTokenID] as auth &NonFungibleToken.NFT?)!
                let refMasterAssetNFT = refMasterNFT as! &NFT

                return refMasterAssetNFT.data.orh
            }
        }

        pub fun getISRC(id: UInt64): String? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            let serialNumber = refAssetNFT.data.serialNumber

            if serialNumber == 0 {
                return refAssetNFT.data.isrc
            } else if let isrc = refAssetNFT.data.isrc {
                return isrc
            } else {
                let masterTokenID = refAssetNFT.data.masterTokenID
                let refMasterNFT = (&self.ownedNFTs[masterTokenID] as auth &NonFungibleToken.NFT?)!
                let refMasterAssetNFT = refMasterNFT as! &NFT

                return refMasterAssetNFT.data.isrc
            }
        }

        pub fun getPerformers(id: UInt64): [String]? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            let serialNumber = refAssetNFT.data.serialNumber

            if serialNumber == 0 {
                return refAssetNFT.data.performers
            } else if let performers = refAssetNFT.data.performers {
                return performers
            } else {
                let masterTokenID = refAssetNFT.data.masterTokenID
                let refMasterNFT = (&self.ownedNFTs[masterTokenID] as auth &NonFungibleToken.NFT?)!
                let refMasterAssetNFT = refMasterNFT as! &NFT

                return refMasterAssetNFT.data.performers
            }
        }

        pub fun getLyricists(id: UInt64): [String]? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            let serialNumber = refAssetNFT.data.serialNumber

            if serialNumber == 0 {
                return refAssetNFT.data.lyricists
            } else if let lyricists = refAssetNFT.data.lyricists {
                return lyricists
            } else {
                let masterTokenID = refAssetNFT.data.masterTokenID
                let refMasterNFT = (&self.ownedNFTs[masterTokenID] as auth &NonFungibleToken.NFT?)!
                let refMasterAssetNFT = refMasterNFT as! &NFT

                return refMasterAssetNFT.data.lyricists
            }
        }

        pub fun getComposers(id: UInt64): [String]? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            let serialNumber = refAssetNFT.data.serialNumber

            if serialNumber == 0 {
                return refAssetNFT.data.composers
            } else if let composers = refAssetNFT.data.composers {
                return composers
            } else {
                let masterTokenID = refAssetNFT.data.masterTokenID
                let refMasterNFT = (&self.ownedNFTs[masterTokenID] as auth &NonFungibleToken.NFT?)!
                let refMasterAssetNFT = refMasterNFT as! &NFT

                return refMasterAssetNFT.data.composers
            }
        }

        pub fun getArrangers(id: UInt64): [String]? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            let serialNumber = refAssetNFT.data.serialNumber

            if serialNumber == 0 {
                return refAssetNFT.data.arrangers
            } else if let arrangers = refAssetNFT.data.arrangers {
                return arrangers
            } else {
                let masterTokenID = refAssetNFT.data.masterTokenID
                let refMasterNFT = (&self.ownedNFTs[masterTokenID] as auth &NonFungibleToken.NFT?)!
                let refMasterAssetNFT = refMasterNFT as! &NFT

                return refMasterAssetNFT.data.arrangers
            }
        }

        pub fun getReleaseDate(id: UInt64): String? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            let serialNumber = refAssetNFT.data.serialNumber

            if serialNumber == 0 {
                return refAssetNFT.data.releaseDate
            } else if let releaseDate = refAssetNFT.data.releaseDate {
                return releaseDate
            } else {
                let masterTokenID = refAssetNFT.data.masterTokenID
                let refMasterNFT = (&self.ownedNFTs[masterTokenID] as auth &NonFungibleToken.NFT?)!
                let refMasterAssetNFT = refMasterNFT as! &NFT

                return refMasterAssetNFT.data.releaseDate
            }
        }

        pub fun getPlayingTime(id: UInt64): String? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            let serialNumber = refAssetNFT.data.serialNumber

            if serialNumber == 0 {
                return refAssetNFT.data.playingTime
            } else if let playingTime = refAssetNFT.data.playingTime {
                return playingTime
            } else {
                let masterTokenID = refAssetNFT.data.masterTokenID
                let refMasterNFT = (&self.ownedNFTs[masterTokenID] as auth &NonFungibleToken.NFT?)!
                let refMasterAssetNFT = refMasterNFT as! &NFT

                return refMasterAssetNFT.data.playingTime
            }
        }

        pub fun getAlbumTitle(id: UInt64): String? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            let serialNumber = refAssetNFT.data.serialNumber

            if serialNumber == 0 {
                return refAssetNFT.data.albumTitle
            } else if let albumTitle = refAssetNFT.data.albumTitle {
                return albumTitle
            } else {
                let masterTokenID = refAssetNFT.data.masterTokenID
                let refMasterNFT = (&self.ownedNFTs[masterTokenID] as auth &NonFungibleToken.NFT?)!
                let refMasterAssetNFT = refMasterNFT as! &NFT

                return refMasterAssetNFT.data.albumTitle
            }
        }

        pub fun getCatalogNumber(id: UInt64): String? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            let serialNumber = refAssetNFT.data.serialNumber

            if serialNumber == 0 {
                return refAssetNFT.data.catalogNumber
            } else if let catalogNumber = refAssetNFT.data.catalogNumber {
                return catalogNumber
            } else {
                let masterTokenID = refAssetNFT.data.masterTokenID
                let refMasterNFT = (&self.ownedNFTs[masterTokenID] as auth &NonFungibleToken.NFT?)!
                let refMasterAssetNFT = refMasterNFT as! &NFT

                return refMasterAssetNFT.data.catalogNumber
            }
        }

        pub fun getTrackNumber(id: UInt64): String? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            let serialNumber = refAssetNFT.data.serialNumber

            if serialNumber == 0 {
                return refAssetNFT.data.trackNumber
            } else if let trackNumber = refAssetNFT.data.trackNumber {
                return trackNumber
            } else {
                let masterTokenID = refAssetNFT.data.masterTokenID
                let refMasterNFT = (&self.ownedNFTs[masterTokenID] as auth &NonFungibleToken.NFT?)!
                let refMasterAssetNFT = refMasterNFT as! &NFT

                return refMasterAssetNFT.data.trackNumber
            }
        }

        pub fun getOwnersHash(id: UInt64): String? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            return refAssetNFT.data.ownersHash
        }

        pub fun getRevenueHash(id: UInt64): String? {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            return refAssetNFT.data.revenueHash
        }

        access(contract) fun depositAsset(token: @NonFungibleToken.NFT) {
            let assetToken <- token as! @NFT

            let oldToken <- self.ownedNFTs[assetToken.id] <- assetToken

            destroy oldToken
        }

        access(contract) fun transferOwner(id: UInt64, ownerFrom: String, ownerTo: String, tokens: UInt32, songID: String, ownersHash: String, previousOwnersHash: String, price: UFix64?, priceUnit: String?, timestamp: String?, webhookID: String?) {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            if (refAssetNFT.data.ownersHash != previousOwnersHash) { panic("Previous Owners Hash is incorrect") }

            refAssetNFT.transferOwner(ownerFrom: ownerFrom, ownerTo: ownerTo, tokens: tokens, songID: songID, ownersHash: ownersHash, price: price, priceUnit: priceUnit, timestamp: timestamp, webhookID: webhookID)
        }

        access(contract) fun addRenter(id: UInt64, renter: String, songID: String?, timestamp: String?, webhookID: String?) {
            pre {
                renter.length > 0: "Renter is invalid"

                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            refAssetNFT.addRenter(renter: renter, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        access(contract) fun removeRenter(id: UInt64, renter: String, songID: String?, timestamp: String?, webhookID: String?) {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            refAssetNFT.removeRenter(renter: renter, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        access(contract) fun addInvitee(id: UInt64, invitee: String, songID: String?, timestamp: String?, webhookID: String?) {
            pre {
                invitee.length > 0: "Invitee is invalid"

                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            refAssetNFT.addInvitee(invitee: invitee, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        access(contract) fun removeInvitee(id: UInt64, invitee: String, songID: String?, timestamp: String?, webhookID: String?) {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            refAssetNFT.removeInvitee(invitee: invitee, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        access(contract) fun updateType(id: UInt64, type: String, songID: String?, timestamp: String?, webhookID: String?) {
            pre {
                type == "private" || type == "public": 
                    "Asset Type must be private or public"

                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            refAssetNFT.updateType(type: type, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        access(contract) fun setMetadata(id: UInt64, metadata: {String: String}, songID: String?, timestamp: String?, webhookID: String?) {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            refAssetNFT.setMetadata(metadata: metadata, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        access(contract) fun removeMetadata(id: UInt64, metadata: [String], songID: String?, timestamp: String?, webhookID: String?) {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            refAssetNFT.removeMetadata(metadata: metadata, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        access(contract) fun update(id: UInt64, songID: String?, expiryTimestamp: UFix64?, valid: Bool?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, previousOwnersHash: String?, revenueHash: String?, previousRevenueHash: String?, revenueData: String?, previewURL: String?, lyricsURL: String?, iv: String?, timestamp: String?, uploadID: String?, webhookID: String?) {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"

                ownersHash == nil && previousOwnersHash == nil || ownersHash != nil && previousOwnersHash != nil: "If owners hash is provided then previous owners hash must also be provided"
                
                revenueHash == nil && previousRevenueHash == nil || revenueHash != nil && previousRevenueHash != nil: "If revenue hash is provided then previous revenue hash must also be provided"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            if (previousOwnersHash != nil && refAssetNFT.data.ownersHash != previousOwnersHash) { panic("Previous Owners Hash is incorrect") }

            if (previousRevenueHash != nil && refAssetNFT.data.revenueHash != previousRevenueHash) { panic("Previous Revenue Hash is incorrect") }

            refAssetNFT.update(songID: songID, expiryTimestamp: expiryTimestamp, valid: valid, kID: kID, title: title, description: description, url: url, thumbnailURL: thumbnailURL, orh: orh, isrc: isrc, performers: performers, lyricists: lyricists, composers: composers, arrangers: arrangers, releaseDate: releaseDate, playingTime: playingTime, albumTitle: albumTitle, catalogNumber: catalogNumber, trackNumber: trackNumber, ownersHash: ownersHash, revenueHash: revenueHash, revenueData: revenueData, previewURL: previewURL, lyricsURL: lyricsURL, iv: iv, timestamp: timestamp, uploadID: uploadID, webhookID: webhookID)
        }

        access(contract) fun reset(id: UInt64, songID: String?, revenueData: String?, previewURL: String?, lyricsURL: String?, iv: String?, timestamp: String?, uploadID: String?, webhookID: String?) {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            if (refAssetNFT.data.serialNumber == 0) { panic("Cannot rest master token") }

            refAssetNFT.reset(songID: songID, revenueData: revenueData, previewURL: previewURL, lyricsURL: lyricsURL, iv: iv, timestamp: timestamp, uploadID: uploadID, webhookID: webhookID)
        }

        access(contract) fun destroyNFT(id: UInt64, songID: String?, timestamp: String?, webhookID: String?) {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            if refAssetNFT.data.valid && refAssetNFT.data.expiryTimestamp > getCurrentBlock().timestamp { panic("Token is not invalid and Token has not expired yet") }

            let oldToken <- self.ownedNFTs.remove(key: id)

            emit AssetDestroyed(id: id, songID: songID, timestamp: timestamp, webhookID: webhookID)

            destroy oldToken
        }

        access(contract) fun dangerouslyDestroyNFT(id: UInt64, songID: String?, timestamp: String?, webhookID: String?) {
            pre {
                self.ownedNFTs[id] != nil: "Asset Token ID does not exist"
            }

            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refAssetNFT = refNFT as! &NFT

            let oldToken <- self.ownedNFTs.remove(key: id)

            emit AssetDestroyed(id: id, songID: songID, timestamp: timestamp, webhookID: webhookID)

            destroy oldToken
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub fun createEmptyCollection(): @Collection {
        return <- create Collection()
    }

    pub fun emitCreateEmptyAssetCollectionEvent(userAccountAddress: Address) {
        emit AssetCollectionInitialized(userAccountAddress: userAccountAddress)
    }

    pub resource Minter {

        pub fun mintNFT(collectionRef: &TrmAssetMSV1_0.Collection, serialNumber: UInt32, masterTokenID: UInt64?, totalTokens: UInt32, owners: {String: UInt32}, renters: [String], invitees: [String], type: String, expiryTimestamp: UFix64, valid: Bool, metadata: {String: String}, songID: String?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, revenueHash: String?, previewURL: String?, lyricsURL: String?, timestamp: String?, uploadID: String?, webhookID: String?): UInt64 {
            pre {
                (masterTokenID == nil && serialNumber == 0) || (masterTokenID != nil && serialNumber > 0): "Either master token needs to be minted with serial number 0 or copy token needs to be minted with serial number != 0"
                expiryTimestamp > getCurrentBlock().timestamp: "Expiry timestamp should be greater than current timestamp"
            }
            
            let tokenID = TrmAssetMSV1_0.totalSupply
            var finalMasterTokenID = tokenID

            if let tempMasterTokenID = masterTokenID {
                var masterTokenSerialNumber = collectionRef.getSerialNumber(id: tempMasterTokenID)
                if masterTokenSerialNumber != 0 { panic("Invalid Master Token ID") }
                finalMasterTokenID = tempMasterTokenID
            }

            collectionRef.depositAsset(token: <- create NFT(id: tokenID, serialNumber: serialNumber, masterTokenID: finalMasterTokenID, totalTokens: totalTokens, owners: owners, renters: renters, invitees: invitees, type: type, expiryTimestamp: expiryTimestamp, valid: valid, metadata: metadata, songID: songID, kID: kID, title: title, description: description, url: url, thumbnailURL: thumbnailURL, orh: orh, isrc: isrc, performers: performers, lyricists: lyricists, composers: composers, arrangers: arrangers, releaseDate: releaseDate, playingTime: playingTime, albumTitle: albumTitle, catalogNumber: catalogNumber, trackNumber: trackNumber, ownersHash: ownersHash, revenueHash: revenueHash, previewURL: previewURL, lyricsURL: lyricsURL, timestamp: timestamp, uploadID: uploadID, webhookID: webhookID))

            TrmAssetMSV1_0.totalSupply = tokenID + 1
            
            return TrmAssetMSV1_0.totalSupply
        }

        pub fun batchMintNFTs(collectionRef: &TrmAssetMSV1_0.Collection, totalCount: UInt32, startSerialNumber: UInt32, masterTokenID: UInt64, totalTokens: UInt32, owners: {String: UInt32}, renters: [String], invitees: [String], type: String, expiryTimestamp: UFix64, valid: Bool, metadata: {String: String}, songID: String?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, revenueHash: String?, previewURL: String?, lyricsURL: String?, timestamp: String?, uploadID: String?, webhookID: String?): UInt64 {
            pre {
                totalCount > 0: "Total Count cannot be less than 1"
                startSerialNumber > 0: "Batch mint cannot be used to mint the master token"
                expiryTimestamp > getCurrentBlock().timestamp: "Expiry timestamp should be greater than current timestamp"
            }

            var masterTokenSerialNumber = collectionRef.getSerialNumber(id: masterTokenID)
            if masterTokenSerialNumber != 0 { panic("Invalid Master Token ID")
            }

            let startTokenID = TrmAssetMSV1_0.totalSupply
            var tokenID = startTokenID
            var counter: UInt32 = 0
            var serialNumber = startSerialNumber

            while counter < totalCount {

                collectionRef.depositAsset(token: <- create NFT(id: tokenID, serialNumber: serialNumber, masterTokenID: masterTokenID, totalTokens: totalTokens, owners: owners, renters: renters, invitees: invitees, type: type, expiryTimestamp: expiryTimestamp, valid: valid, metadata: metadata, songID: songID, kID: kID, title: title, description: description, url: url, thumbnailURL: thumbnailURL, orh: orh, isrc: isrc, performers: performers, lyricists: lyricists, composers: composers, arrangers: arrangers, releaseDate: releaseDate, playingTime: playingTime, albumTitle: albumTitle, catalogNumber: catalogNumber, trackNumber: trackNumber, ownersHash: ownersHash, revenueHash: revenueHash, previewURL: previewURL, lyricsURL: lyricsURL, timestamp: timestamp, uploadID: uploadID, webhookID: webhookID))

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

    pub resource Admin {

        pub fun transferOwner(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, ownerFrom: String, ownerTo: String, tokens: UInt32, songID: String, ownersHash: String, previousOwnersHash: String, price: UFix64?, priceUnit: String?, timestamp: String?, webhookID: String?) {
            
            collectionRef.transferOwner(id: id, ownerFrom: ownerFrom, ownerTo: ownerTo, tokens: tokens, songID: songID, ownersHash: ownersHash, previousOwnersHash: previousOwnersHash, price: price, priceUnit: priceUnit, timestamp: timestamp, webhookID: webhookID)
        }

        pub fun addRenter(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, renter: String, songID: String?, timestamp: String?, webhookID: String?) {

            collectionRef.addRenter(id: id, renter: renter, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        pub fun removeRenter(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, renter: String, songID: String?, timestamp: String?, webhookID: String?) {

            collectionRef.removeRenter(id: id, renter: renter, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        pub fun addInvitee(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, invitee: String, songID: String?, timestamp: String?, webhookID: String?) {

            collectionRef.addInvitee(id: id, invitee: invitee, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        pub fun removeInvitee(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, invitee: String, songID: String?, timestamp: String?, webhookID: String?) {

            collectionRef.removeInvitee(id: id, invitee: invitee, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        pub fun updateType(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, type: String, songID: String?, timestamp: String?, webhookID: String?) {

            collectionRef.updateType(id: id, type: type, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        pub fun setAssetMetadata(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, metadata: {String: String}, songID: String?, timestamp: String?, webhookID: String?) {
            
            collectionRef.setMetadata(id: id, metadata: metadata, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        pub fun removeAssetMetadata(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, metadata: [String], songID: String?, timestamp: String?, webhookID: String?) {
            
            collectionRef.removeMetadata(id: id, metadata: metadata, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        pub fun updateAsset(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, songID: String?, expiryTimestamp: UFix64?, valid: Bool?, kID: String?, title: String?, description: String?, url: String?, thumbnailURL: String?, orh: [String]?, isrc: String?, performers: [String]?, lyricists: [String]?, composers: [String]?, arrangers: [String]?, releaseDate: String?, playingTime: String?, albumTitle: String?, catalogNumber: String?, trackNumber: String?, ownersHash: String?, previousOwnersHash: String?, revenueHash: String?, previousRevenueHash: String?, revenueData: String?, previewURL: String?, lyricsURL: String?, iv: String?, timestamp: String?, uploadID: String?, webhookID: String?) {
            
            collectionRef.update(id: id, songID: songID, expiryTimestamp: expiryTimestamp, valid: valid, kID: kID, title: title, description: description, url: url, thumbnailURL: thumbnailURL, orh: orh, isrc: isrc, performers: performers, lyricists: lyricists, composers: composers, arrangers: arrangers, releaseDate: releaseDate, playingTime: playingTime, albumTitle: albumTitle, catalogNumber: catalogNumber, trackNumber: trackNumber, ownersHash: ownersHash, previousOwnersHash: previousOwnersHash, revenueHash: revenueHash, previousRevenueHash: previousRevenueHash, revenueData: revenueData, previewURL: previewURL, lyricsURL: lyricsURL, iv: iv, timestamp: timestamp, uploadID: uploadID, webhookID: webhookID)
        }

        pub fun resetAsset(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, songID: String?, revenueData: String?, previewURL: String?, lyricsURL: String?, iv: String?, timestamp: String?, uploadID: String?, webhookID: String?) {
            
            collectionRef.reset(id: id, songID: songID, revenueData: revenueData, previewURL: previewURL, lyricsURL: lyricsURL, iv: iv, timestamp: timestamp, uploadID: uploadID, webhookID: webhookID)
        }

        pub fun destroyNFT(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, songID: String?, timestamp: String?, webhookID: String?) {
            
            collectionRef.destroyNFT(id: id, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        pub fun batchDestroyNFTs(collectionRef: &TrmAssetMSV1_0.Collection, ids: [UInt64], songID: String?, timestamp: String?, webhookID: String?) {
            for id in ids {
                collectionRef.destroyNFT(id: id, songID: songID, timestamp: timestamp, webhookID: webhookID)
            }

            emit AssetBatchDestroyed(ids: ids, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        pub fun dangerouslyDestroyNFT(collectionRef: &TrmAssetMSV1_0.Collection, id: UInt64, songID: String?, timestamp: String?, webhookID: String?) {
            
            collectionRef.dangerouslyDestroyNFT(id: id, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }

        pub fun batchDangerouslyDestroyNFTs(collectionRef: &TrmAssetMSV1_0.Collection, ids: [UInt64], songID: String?, timestamp: String?, webhookID: String?) {
            for id in ids {
                collectionRef.dangerouslyDestroyNFT(id: id, songID: songID, timestamp: timestamp, webhookID: webhookID)
            }

            emit AssetBatchDestroyed(ids: ids, songID: songID, timestamp: timestamp, webhookID: webhookID)
        }
    }

    init() {
        self.totalSupply = 0

        // Settings paths
        self.collectionStoragePath = /storage/TrmAssetMSV1_0Collection
        self.collectionPublicPath = /public/TrmAssetMSV1_0Collection
        self.minterStoragePath = /storage/TrmAssetMSV1_0Minter
        self.adminStoragePath = /storage/TrmAssetMSV1_0Admin

        // First, check to see if a minter resource already exists
        if self.account.type(at: self.minterStoragePath) == nil {
            
            // Put the minter in storage with access only to admin
            self.account.save(<-create Minter(), to: self.minterStoragePath)
        }

        // First, check to see if a minter resource already exists
        if self.account.type(at: self.adminStoragePath) == nil {
            
            // Put the minter in storage with access only to admin
            self.account.save(<-create Admin(), to: self.adminStoragePath)
        }

        emit ContractInitialized()
    }
}
 