/*******************************************/
// Modern Musician Relic Contract v.0.1.1
// developed by info@spaceleaf.io
/*******************************************/
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract RelicContract: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, rarity: String, creatorName: String)
	
	access(all)
	event Transfer(id: UInt64, from: Address?, to: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var bronzeSupply: UInt64
	
	access(all)
	var silverSupply: UInt64
	
	access(all)
	var goldSupply: UInt64
	
	access(all)
	var platinumSupply: UInt64
	
	access(all)
	var diamondSupply: UInt64
	
	access(all)
	let idMap:{ String: UInt64}
	
	access(all)
	fun getTotalSupply(): [UInt64]{ 
		var supplies: [UInt64] = [RelicContract.bronzeSupply, RelicContract.silverSupply, RelicContract.goldSupply, RelicContract.platinumSupply, RelicContract.diamondSupply, RelicContract.totalSupply]
		return supplies
	}
	
	access(all)
	fun getRelicId(_relicId: String): UInt64?{ 
		return RelicContract.idMap[_relicId]
	}
	
	access(all)
	resource Relic: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let creatorId: String
		
		access(all)
		let relicId: String
		
		access(all)
		let rarity: String
		
		access(all)
		let category: String
		
		access(all)
		let type: String
		
		access(all)
		let creatorName: String
		
		access(all)
		let title: String
		
		access(all)
		let description: String
		
		access(all)
		let edition: UInt64
		
		access(all)
		let editionSize: UInt64
		
		access(all)
		let mintDate: String
		
		access(all)
		var assetVideoURL: String
		
		access(all)
		var assetImageURL: String
		
		access(all)
		var musicURL: String
		
		access(all)
		var artworkURL: String
		
		access(all)
		var marketDisplay: String
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		init(_initID: UInt64, _creatorId: String, _relicId: String, _rarity: String, _category: String, _type: String, _creatorName: String, _title: String, _description: String, _edition: UInt64, _editionSize: UInt64, _mintDate: String, _assetVideoURL: String, _assetImageURL: String, _musicURL: String, _artworkURL: String, _royalties: [MetadataViews.Royalty]){ 
			self.id = _initID
			self.creatorId = _creatorId
			self.relicId = _relicId
			self.rarity = _rarity
			self.category = _category
			self.type = _type
			self.creatorName = _creatorName
			self.title = _title
			self.description = _description
			self.edition = _edition
			self.editionSize = _editionSize
			self.mintDate = _mintDate
			self.assetVideoURL = _assetVideoURL
			self.assetImageURL = _assetImageURL
			self.musicURL = _musicURL
			self.artworkURL = _artworkURL
			self.marketDisplay = _assetImageURL
			self.royalties = _royalties
		}
		
		access(all)
		fun updateAssetVideoURL(_newAssetVideoURL: String){ 
			self.assetVideoURL = _newAssetVideoURL
		}
		
		access(all)
		fun updateAssetImageURL(_newAssetImageURL: String){ 
			self.assetImageURL = _newAssetImageURL
		}
		
		access(all)
		fun updateMusicURL(_newMusicURL: String){ 
			self.musicURL = _newMusicURL
		}
		
		access(all)
		fun updateArtworkURL(_newArtworkURL: String){ 
			self.artworkURL = _newArtworkURL
		}
		
		access(all)
		fun updateMarketDisplay(_newURL: String){ 
			self.marketDisplay = _newURL
		}
		
		access(all)
		fun updateMediaURLs(_newAssetVideoURL: String, _newAssetImageURL: String, _newMusicURL: String, _newArtworkURL: String){ 
			self.assetVideoURL = _newAssetVideoURL
			self.assetImageURL = _newAssetImageURL
			self.musicURL = _newMusicURL
			self.artworkURL = _newArtworkURL
		}
		
		access(all)
		fun name(): String{ 
			return self.creatorName.concat(" - ").concat(self.title)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Identity>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name(), description: self.description, thumbnail: self.assetImageURL, id: self.id, category: self.category, rarity: self.rarity, type: self.type, creatorName: self.creatorName, title: self.title, mintDate: self.mintDate, assetVideoURL: self.assetVideoURL, assetImageURL: self.assetImageURL, musicURL: self.musicURL, artworkURL: self.artworkURL)
				case Type<MetadataViews.Identity>():
					return MetadataViews.Identity(uuid: self.uuid)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(": https://www.musicrelics.com/".concat(self.id.toString()))
				case Type<MetadataViews.Editions>():
					let editionInfo = MetadataViews.Edition(name: self.rarity, number: self.edition, max: self.editionSize)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: RelicContract.CollectionStoragePath, publicPath: RelicContract.CollectionPublicPath, publicCollection: Type<&RelicContract.Collection>(), publicLinkedType: Type<&RelicContract.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-RelicContract.createEmptyCollection(nftType: Type<@RelicContract.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let video = MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.marketDisplay), mediaType: "video/image")
					let image = MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.artworkURL), mediaType: "image")
					return MetadataViews.NFTCollectionDisplay(name: self.name(), description: self.description, externalURL: MetadataViews.ExternalURL("https://www.musicrelics.com/"), squareImage: video, bannerImage: image, socials:{} )
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface RelicCollectionPublic{ 
		access(all)
		fun deposit(token: @NonFungibleToken.Relic)
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun borrowRelic(id: UInt64): &NonFungibleToken.Relic
		
		access(all)
		fun borrowRelicSpecific(id: UInt64): &Relic
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, RelicCollectionPublic{ 
		access(all)
		var ownedRelics: @{UInt64: NonFungibleToken.Relic}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedRelics.remove(key: withdrawID) ?? panic("Relic not found.")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @NonFungibleToken.Relic){ 
			let relic <- token as! @RelicContract.Relic
			emit Deposit(id: relic.id, to: self.owner?.address)
			self.ownedRelics[relic.id] <-! relic
		}
		
		access(all)
		fun transfer(id: UInt64, recipient: &{NonFungibleToken.CollectionPublic}){ 
			let token <- self.ownedRelics.remove(key: id) ?? panic("Relic not found.")
			recipient.deposit(token: <-token)
			emit Transfer(id: id, from: self.owner?.address, to: recipient.owner?.address)
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedRelics.keys
		}
		
		access(all)
		fun borrowRelic(id: UInt64): &NonFungibleToken.Relic{ 
			return (&self.ownedRelics[id] as &NonFungibleToken.Relic?)!
		}
		
		access(all)
		fun borrowRelicSpecific(id: UInt64): &Relic{ 
			let ref = (&self.ownedRelics[id] as &NonFungibleToken.Relic?)!
			return ref as! &Relic
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let relic = (&self.ownedRelics[id] as &NonFungibleToken.Relic?)!
			let getRelic = relic as! &Relic
			return getRelic
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
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			panic("implement me")
		}
		
		init(){ 
			self.ownedRelics <-{} 
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	resource RelicMinter{ 
		access(all)
		fun mintRelic(recipient: &{NonFungibleToken.CollectionPublic}, _id: UInt64, _creatorId: String, _relicId: String, _rarity: String, _category: String, _type: String, _creatorName: String, _title: String, _description: String, _edition: UInt64, _editionSize: UInt64, _mintDate: String, _assetVideoURL: String, _assetImageURL: String, _musicURL: String, _artworkURL: String, _royalties: [MetadataViews.Royalty]){ 
			switch _rarity{ 
				case "Bronze":
					recipient.deposit(token: <-create RelicContract.Relic(_initID: _id, _creatorId: _creatorId, _relicId: _relicId, _rarity: _rarity, _category: _category, _type: _type, _creatorName: _creatorName, _title: _title, _description: _description, _edition: _edition, _editionSize: _editionSize, _mintDate: _mintDate, _assetVideoURL: _assetVideoURL, _assetImageURL: _assetImageURL, _musicURL: _musicURL, _artworkURL: _artworkURL, _royalties: _royalties))
					emit Minted(id: RelicContract.totalSupply, rarity: _rarity, creatorName: _creatorName)
					RelicContract.idMap.insert(key: _relicId, RelicContract.totalSupply)
					RelicContract.bronzeSupply = RelicContract.bronzeSupply + 1
					RelicContract.totalSupply = RelicContract.totalSupply + 1
				case "Silver":
					recipient.deposit(token: <-create RelicContract.Relic(_initID: _id, _creatorId: _creatorId, _relicId: _relicId, _rarity: _rarity, _category: _category, _type: _type, _creatorName: _creatorName, _title: _title, _description: _description, _edition: _edition, _editionSize: _editionSize, _mintDate: _mintDate, _assetVideoURL: _assetVideoURL, _assetImageURL: _assetImageURL, _musicURL: _musicURL, _artworkURL: _artworkURL, _royalties: _royalties))
					emit Minted(id: RelicContract.totalSupply, rarity: _rarity, creatorName: _creatorName)
					RelicContract.idMap.insert(key: _relicId, RelicContract.totalSupply)
					RelicContract.silverSupply = RelicContract.silverSupply + 1
					RelicContract.totalSupply = RelicContract.totalSupply + 1
				case "Gold":
					recipient.deposit(token: <-create RelicContract.Relic(_initID: _id, _creatorId: _creatorId, _relicId: _relicId, _rarity: _rarity, _category: _category, _type: _type, _creatorName: _creatorName, _title: _title, _description: _description, _edition: _edition, _editionSize: _editionSize, _mintDate: _mintDate, _assetVideoURL: _assetVideoURL, _assetImageURL: _assetImageURL, _musicURL: _musicURL, _artworkURL: _artworkURL, _royalties: _royalties))
					emit Minted(id: RelicContract.totalSupply, rarity: _rarity, creatorName: _creatorName)
					RelicContract.idMap.insert(key: _relicId, RelicContract.totalSupply)
					RelicContract.goldSupply = RelicContract.goldSupply + 1
					RelicContract.totalSupply = RelicContract.totalSupply + 1
				case "Platinum":
					recipient.deposit(token: <-create RelicContract.Relic(_initID: _id, _creatorId: _creatorId, _relicId: _relicId, _rarity: _rarity, _category: _category, _type: _type, _creatorName: _creatorName, _title: _title, _description: _description, _edition: _edition, _editionSize: _editionSize, _mintDate: _mintDate, _assetVideoURL: _assetVideoURL, _assetImageURL: _assetImageURL, _musicURL: _musicURL, _artworkURL: _artworkURL, _royalties: _royalties))
					emit Minted(id: RelicContract.totalSupply, rarity: _rarity, creatorName: _creatorName)
					RelicContract.idMap.insert(key: _relicId, RelicContract.totalSupply)
					RelicContract.platinumSupply = RelicContract.platinumSupply + 1
					RelicContract.totalSupply = RelicContract.totalSupply + 1
				case "Diamond":
					recipient.deposit(token: <-create RelicContract.Relic(_initID: _id, _creatorId: _creatorId, _relicId: _relicId, _rarity: _rarity, _category: _category, _type: _type, _creatorName: _creatorName, _title: _title, _description: _description, _edition: _edition, _editionSize: _editionSize, _mintDate: _mintDate, _assetVideoURL: _assetVideoURL, _assetImageURL: _assetImageURL, _musicURL: _musicURL, _artworkURL: _artworkURL, _royalties: _royalties))
					emit Minted(id: RelicContract.totalSupply, rarity: _rarity, creatorName: _creatorName)
					RelicContract.idMap.insert(key: _relicId, RelicContract.totalSupply)
					RelicContract.diamondSupply = RelicContract.diamondSupply + 1
					RelicContract.totalSupply = RelicContract.totalSupply + 1
			}
		}
		
		access(all)
		fun resetRarityCounters(){ 
			RelicContract.bronzeSupply = 0
			RelicContract.silverSupply = 0
			RelicContract.goldSupply = 0
			RelicContract.platinumSupply = 0
			RelicContract.diamondSupply = 0
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/RelicCollection
		self.CollectionPublicPath = /public/RelicCollection
		self.MinterStoragePath = /storage/RelicMinter
		self.totalSupply = 0
		self.bronzeSupply = 0
		self.silverSupply = 0
		self.goldSupply = 0
		self.platinumSupply = 0
		self.diamondSupply = 0
		self.idMap ={} 
		let minter <- create RelicMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		let collection <- RelicContract.createEmptyCollection(nftType: Type<@RelicContract.Collection>())
		self.account.storage.save(<-collection, to: RelicContract.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&RelicContract.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
