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
	event Minted(id: UInt64, rarity: String, artistName: String)
	
	access(all)
	event Transfer(id: UInt64, from: Address?, to: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let ManagerStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var serialCounter: UInt64
	
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
	var bronzeMaxSupply: UInt64
	
	access(all)
	var silverMaxSupply: UInt64
	
	access(all)
	var goldMaxSupply: UInt64
	
	access(all)
	var platinumMaxSupply: UInt64
	
	access(all)
	var diamondMaxSupply: UInt64
	
	access(all)
	fun getTotalSupply(): [UInt64]{ 
		var supplies: [UInt64] = [RelicContract.bronzeSupply, RelicContract.silverSupply, RelicContract.goldSupply, RelicContract.platinumSupply, RelicContract.diamondSupply, RelicContract.serialCounter, RelicContract.totalSupply]
		return supplies
	}
	
	access(all)
	fun getMaxSupply(): [UInt64]{ 
		var maxSupplies: [UInt64] = [RelicContract.bronzeMaxSupply, RelicContract.silverMaxSupply, RelicContract.goldMaxSupply, RelicContract.platinumMaxSupply, RelicContract.diamondMaxSupply]
		return maxSupplies
	}
	
	access(all)
	resource Relic: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let rarity: String
		
		access(all)
		let category: String
		
		access(all)
		let type: String
		
		access(all)
		let artistName: String
		
		access(all)
		let title: String
		
		access(all)
		let description: String
		
		access(all)
		let serialNumber: UInt64
		
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
		
		init(_initID: UInt64, _rarity: String, _category: String, _type: String, _artistName: String, _title: String, _description: String, _serialNumber: UInt64, _edition: UInt64, _editionSize: UInt64, _mintDate: String, _assetVideoURL: String, _assetImageURL: String, _musicURL: String, _artworkURL: String, _royalties: [MetadataViews.Royalty]){ 
			self.id = _initID
			self.rarity = _rarity
			self.category = _category
			self.type = _type
			self.artistName = _artistName
			self.title = _title
			self.description = _description
			self.serialNumber = _serialNumber
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
		fun updateVideoURL(_newAssetVideoURL: String){ 
			self.assetVideoURL = _newAssetVideoURL
		}
		
		access(all)
		fun updateAssetURL(_newAssetImageURL: String){ 
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
			return self.artistName.concat(" - ").concat(self.title)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Identity>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name(), description: self.description, thumbnail: self.artworkURL, id: self.id, category: self.category, rarity: self.rarity, type: self.type, artistName: self.artistName, title: self.title, mintDate: self.mintDate, assetVideoURL: self.assetVideoURL, assetImageURL: self.assetImageURL, musicURL: self.musicURL, artworkURL: self.artworkURL)
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
					return MetadataViews.Serial(self.serialNumber)
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
			let token <- self.ownedRelics.remove(key: withdrawID) ?? panic("missing Relic")
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
			let token <- self.ownedRelics.remove(key: id) ?? panic("missing Relic")
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
		fun mintRelic(recipient: &{NonFungibleToken.CollectionPublic}, _rarity: String, _category: String, _type: String, _artistName: String, _title: String, _description: String, _mintDate: String, _assetVideoURL: String, _assetImageURL: String, _musicURL: String, _artworkURL: String, _royalties: [MetadataViews.Royalty]){ 
			switch _rarity{ 
				case "Bronze":
					if RelicContract.bronzeSupply < RelicContract.bronzeMaxSupply{ 
						recipient.deposit(token: <-create RelicContract.Relic(_initID: RelicContract.totalSupply, _rarity: _rarity, _category: _category, _type: _type, _artistName: _artistName, _title: _title, _description: _description, _serialNumber: RelicContract.serialCounter + 1, _edition: RelicContract.bronzeSupply + 1, _editionSize: RelicContract.bronzeMaxSupply, _mintDate: _mintDate, _assetVideoURL: _assetVideoURL, _assetImageURL: _assetImageURL, _musicURL: _musicURL, _artworkURL: _artworkURL, _royalties: _royalties))
						RelicContract.bronzeSupply = RelicContract.bronzeSupply + 1
						RelicContract.totalSupply = RelicContract.totalSupply + 1
						RelicContract.serialCounter = RelicContract.serialCounter + 1
						emit Minted(id: RelicContract.totalSupply, rarity: _rarity, artistName: _artistName)
					} else{ 
						log("Bronze Mint attempted but failed, Max Supply exceeded")
					}
				case "Silver":
					if RelicContract.silverSupply < RelicContract.silverMaxSupply{ 
						recipient.deposit(token: <-create RelicContract.Relic(_initID: RelicContract.totalSupply, _rarity: _rarity, _category: _category, _type: _type, _artistName: _artistName, _title: _title, _description: _description, _serialNumber: RelicContract.serialCounter + 1, _edition: RelicContract.silverSupply + 1, _editionSize: RelicContract.silverMaxSupply, _mintDate: _mintDate, _assetVideoURL: _assetVideoURL, _assetImageURL: _assetImageURL, _musicURL: _musicURL, _artworkURL: _artworkURL, _royalties: _royalties))
						RelicContract.silverSupply = RelicContract.silverSupply + 1
						RelicContract.totalSupply = RelicContract.totalSupply + 1
						RelicContract.serialCounter = RelicContract.serialCounter + 1
						emit Minted(id: RelicContract.totalSupply, rarity: _rarity, artistName: _artistName)
					} else{ 
						log("Silver Mint attempted but failed, Max Supply exceeded")
					}
				case "Gold":
					if RelicContract.goldSupply < RelicContract.goldMaxSupply{ 
						recipient.deposit(token: <-create RelicContract.Relic(_initID: RelicContract.totalSupply, _rarity: _rarity, _category: _category, _type: _type, _artistName: _artistName, _title: _title, _description: _description, _serialNumber: RelicContract.serialCounter + 1, _edition: RelicContract.goldSupply + 1, _editionSize: RelicContract.goldMaxSupply, _mintDate: _mintDate, _assetVideoURL: _assetVideoURL, _assetImageURL: _assetImageURL, _musicURL: _musicURL, _artworkURL: _artworkURL, _royalties: _royalties))
						RelicContract.goldSupply = RelicContract.goldSupply + 1
						RelicContract.totalSupply = RelicContract.totalSupply + 1
						RelicContract.serialCounter = RelicContract.serialCounter + 1
						emit Minted(id: RelicContract.totalSupply, rarity: _rarity, artistName: _artistName)
					} else{ 
						log("Gold Mint attempted but failed, Max Supply exceeded")
					}
				case "Platinum":
					if RelicContract.platinumSupply < RelicContract.platinumMaxSupply{ 
						recipient.deposit(token: <-create RelicContract.Relic(_initID: RelicContract.totalSupply, _rarity: _rarity, _category: _category, _type: _type, _artistName: _artistName, _title: _title, _description: _description, _serialNumber: RelicContract.serialCounter + 1, _edition: RelicContract.platinumSupply + 1, _editionSize: RelicContract.platinumMaxSupply, _mintDate: _mintDate, _assetVideoURL: _assetVideoURL, _assetImageURL: _assetImageURL, _musicURL: _musicURL, _artworkURL: _artworkURL, _royalties: _royalties))
						RelicContract.platinumSupply = RelicContract.platinumSupply + 1
						RelicContract.totalSupply = RelicContract.totalSupply + 1
						RelicContract.serialCounter = RelicContract.serialCounter + 1
						emit Minted(id: RelicContract.totalSupply, rarity: _rarity, artistName: _artistName)
					} else{ 
						log("Platinum Mint attempted but failed, Max Supply exceeded")
					}
				case "Diamond":
					if RelicContract.diamondSupply < RelicContract.diamondMaxSupply{ 
						recipient.deposit(token: <-create RelicContract.Relic(_initID: RelicContract.totalSupply, _rarity: _rarity, _category: _category, _type: _type, _artistName: _artistName, _title: _title, _description: _description, _serialNumber: RelicContract.serialCounter + 1, _edition: RelicContract.diamondSupply + 1, _editionSize: RelicContract.diamondMaxSupply, _mintDate: _mintDate, _assetVideoURL: _assetVideoURL, _assetImageURL: _assetImageURL, _musicURL: _musicURL, _artworkURL: _artworkURL, _royalties: _royalties))
						RelicContract.diamondSupply = RelicContract.diamondSupply + 1
						RelicContract.totalSupply = RelicContract.totalSupply + 1
						RelicContract.serialCounter = RelicContract.serialCounter + 1
						emit Minted(id: RelicContract.totalSupply, rarity: _rarity, artistName: _artistName)
					} else{ 
						log("Diamond Mint attempted but failed, Max Supply exceeded")
					}
			}
		}
		
		access(all)
		fun resetRarityCounters(){ 
			RelicContract.bronzeSupply = 0
			RelicContract.silverSupply = 0
			RelicContract.goldSupply = 0
			RelicContract.platinumSupply = 0
			RelicContract.diamondSupply = 0
			RelicContract.serialCounter = 0
		}
		
		access(all)
		fun updateMaxSupplies(_bronze: UInt64, _silver: UInt64, _gold: UInt64, _platinum: UInt64, _diamond: UInt64){ 
			RelicContract.bronzeMaxSupply = _bronze
			RelicContract.silverMaxSupply = _silver
			RelicContract.goldMaxSupply = _gold
			RelicContract.platinumMaxSupply = _platinum
			RelicContract.diamondMaxSupply = _diamond
		}
		
		access(all)
		fun setSerialCounter(_number: UInt64){ 
			RelicContract.serialCounter = _number
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/RelicCollection
		self.CollectionPublicPath = /public/RelicCollection
		self.MinterStoragePath = /storage/RelicMinter
		self.ManagerStoragePath = /storage/RelicManager
		self.totalSupply = 0
		self.bronzeSupply = 0
		self.silverSupply = 0
		self.goldSupply = 0
		self.platinumSupply = 0
		self.diamondSupply = 0
		self.bronzeMaxSupply = 500
		self.silverMaxSupply = 250
		self.goldMaxSupply = 100
		self.platinumMaxSupply = 10
		self.diamondMaxSupply = 1
		self.serialCounter = 0
		let minter <- create RelicMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		let collection <- RelicContract.createEmptyCollection(nftType: Type<@RelicContract.Collection>())
		self.account.storage.save(<-collection, to: RelicContract.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&RelicContract.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
