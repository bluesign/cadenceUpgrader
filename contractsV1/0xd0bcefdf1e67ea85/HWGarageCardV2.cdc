/*
*
*   An NFT contract for redeeming/minting tokens by series
*
*
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract HWGarageCardV2: NonFungibleToken{ 
	/* 
		*   NonFungibleToken Standard Events
		*/
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	/* 
		*   Project Events
		*/
	
	access(all)
	event Mint(id: UInt64)
	
	access(all)
	event Burn(id: UInt64)
	
	access(all)
	event DepositEvent(uuid: UInt64, id: UInt64, seriesId: UInt64, editionId: UInt64, to: Address?)
	
	access(all)
	event TransferEvent(uuid: UInt64, id: UInt64, seriesId: UInt64, editionId: UInt64, to: Address?)
	
	/* 
		*   Named Paths
		*/
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	/* 
		*   NonFungibleToken Standard Fields
		*/
	
	access(all)
	var totalSupply: UInt64
	
	/*
		*   Card State Variables
		*/
	
	access(account)
	var name: String
	
	access(account)
	var currentCardEditionIdByPackSeriesId:{ UInt64: UInt64}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		// the pack series this card came from
		access(all)
		let packSeriesID: UInt64
		
		access(all)
		let cardEditionID: UInt64
		
		access(all)
		let packHash: String
		
		access(all)
		let redeemable: String
		
		access(all)
		let metadata:{ String: String}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Rarity>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					var ipfsImage = MetadataViews.IPFSFile(cid: self.metadata["thumbnailCID"] ?? "ThumbnailCID not set", path: self.metadata["thumbnailPath"] ?? "")
					return MetadataViews.Display(name: self.metadata["cardName"] ?? "Hot Wheels Garage Card Series ".concat(self.packSeriesID.toString()).concat(" #").concat(self.cardEditionID.toString()), description: self.metadata["cardDescription"] ?? "Digital Card Collectable from Hot Wheels Garage", thumbnail: ipfsImage)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(self.metadata["url"] ?? "")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: HWGarageCardV2.CollectionStoragePath, publicPath: HWGarageCardV2.CollectionPublicPath, publicCollection: Type<&HWGarageCardV2.Collection>(), publicLinkedType: Type<&HWGarageCardV2.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-HWGarageCardV2.createEmptyCollection(nftType: Type<@HWGarageCardV2.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let externalURL = MetadataViews.ExternalURL("")
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: ""), mediaType: "image/png")
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: ""), mediaType: "image/png")
					let socialMap:{ String: MetadataViews.ExternalURL} ={ "facebook": MetadataViews.ExternalURL("https://www.facebook.com/hotwheels"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/hotwheelsofficial/"), "twitter": MetadataViews.ExternalURL("https://twitter.com/Hot_Wheels"), "discord": MetadataViews.ExternalURL("https://discord.gg/mattel")}
					return MetadataViews.NFTCollectionDisplay(name: self.metadata["collectionName"] ?? "Hot Wheels Garage Card", description: self.metadata["collectionDescription"] ?? "Digital Collectable from Hot Wheels Garage", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socialMap)
				case Type<MetadataViews.Traits>():
					let exludedTraits = ["thumbnailPath", "thumbnailCID", "collectionName", "collectionDescription", "cardDescription", "url"]
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: exludedTraits)
					return traitsView
				case Type<MetadataViews.Royalties>():
					let flowReciever = getAccount(0xf86e2f015cd692be).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: flowReciever!, cut: 0.05, description: "Mattel 5% Royalty")])
				case Type<MetadataViews.Rarity>():
					let rarityDescription = self.metadata["rarity"]
					return MetadataViews.Rarity(score: nil, max: nil, description: rarityDescription)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64, packSeriesID: UInt64, cardEditionID: UInt64, packHash: String, redeemable: String, metadata:{ String: String}){ 
			self.id = id
			self.packSeriesID = packSeriesID
			self.cardEditionID = cardEditionID
			self.packHash = packHash
			self.redeemable = redeemable
			self.metadata = metadata
			emit Mint(id: self.id)
		}
	}
	
	access(all)
	resource interface CardCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowCard(id: UInt64): &HWGarageCardV2.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow HWGarageCardV2Pack reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: CardCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let HWGarageCardV2 <- token as! @HWGarageCardV2.NFT
			let HWGarageCardV2UUID: UInt64 = HWGarageCardV2.uuid
			let HWGarageCardV2SeriesId: UInt64 = HWGarageCardV2.packSeriesID
			let HWGarageCardV2ID: UInt64 = HWGarageCardV2.id
			let HWGarageCardV2cardEditionID: UInt64 = HWGarageCardV2.cardEditionID
			self.ownedNFTs[HWGarageCardV2ID] <-! HWGarageCardV2
			emit Deposit(id: HWGarageCardV2ID, to: self.owner?.address)
			emit DepositEvent(uuid: HWGarageCardV2UUID, id: HWGarageCardV2ID, seriesId: HWGarageCardV2SeriesId, editionId: HWGarageCardV2cardEditionID, to: self.owner?.address)
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
		fun borrowCard(id: UInt64): &HWGarageCardV2.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &HWGarageCardV2.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let token = nft as! &HWGarageCardV2.NFT
			return token as &{ViewResolver.Resolver}
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
	
	/* 
		*   Admin Functions
		*/
	
	access(account)
	fun addNewSeries(newCardSeriesID: UInt64){ 
		self.currentCardEditionIdByPackSeriesId.insert(key: newCardSeriesID, 0)
	}
	
	access(account)
	fun updateCurrentEditionIdByPackSeriesId(packSeriesID: UInt64, cardSeriesEdition: UInt64){ 
		self.currentCardEditionIdByPackSeriesId[packSeriesID] = cardSeriesEdition
	}
	
	access(account)
	fun mint(nftID: UInt64, packSeriesID: UInt64, cardEditionID: UInt64, packHash: String, redeemable: String, metadata:{ String: String}): @{NonFungibleToken.NFT}{ 
		self.totalSupply = self.getTotalSupply() + 1
		self.currentCardEditionIdByPackSeriesId[packSeriesID] = self.currentCardEditionIdByPackSeriesId[packSeriesID]! + 1
		return <-create NFT(id: nftID, packSeriesID: packSeriesID, cardEditionID: self.currentCardEditionIdByPackSeriesId[packSeriesID]!, packHash: packHash, redeemable: redeemable, metadata: metadata)
	}
	
	/* 
		*   Public Functions
		*/
	
	access(all)
	fun getTotalSupply(): UInt64{ 
		return self.totalSupply
	}
	
	access(all)
	fun getName(): String{ 
		return self.name
	}
	
	access(all)
	fun transfer(uuid: UInt64, id: UInt64, packSeriesId: UInt64, cardEditionId: UInt64, toAddress: Address){ 
		let HWGarageCardV2UUID: UInt64 = uuid
		let HWGarageCardV2SeriesId: UInt64 = packSeriesId
		let HWGarageCardV2ID: UInt64 = id
		let HWGarageCardV2cardEditionID: UInt64 = cardEditionId
		emit TransferEvent(uuid: HWGarageCardV2UUID, id: HWGarageCardV2ID, seriesId: HWGarageCardV2SeriesId, editionId: HWGarageCardV2cardEditionID, to: toAddress)
	}
	
	/* 
		*   NonFungibleToken Standard Functions
		*/
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// initialize contract state variables
	init(){ 
		self.name = "Hot Wheels Garage Card v2"
		self.totalSupply = 0
		self.currentCardEditionIdByPackSeriesId ={ 1: 0}
		// set the named paths
		self.CollectionStoragePath = /storage/HWGarageCardV2Collection
		self.CollectionPublicPath = /public/HWGarageCardV2Collection
		emit ContractInitialized()
	}
}
