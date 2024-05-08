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
contract HWGarageTokenV2: NonFungibleToken{ 
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
		*   Token State Variables
		*/
	
	access(account)
	var name: String
	
	access(account)
	var currentTokenEditionIdByPackSeriesId:{ UInt64: UInt64}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		// the pack series this Token came from
		access(all)
		let packSeriesID: UInt64
		
		access(all)
		let tokenEditionID: UInt64
		
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
					return MetadataViews.Display(name: self.metadata["tokenName"] ?? "Hot Wheels Garage Token Series ".concat(self.packSeriesID.toString()).concat(" #").concat(self.tokenEditionID.toString()), description: self.metadata["tokenDescription"] ?? "Digital Redeemable Token Collectable from Hot Wheels Garage", thumbnail: ipfsImage)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(self.metadata["url"] ?? "")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: HWGarageTokenV2.CollectionStoragePath, publicPath: HWGarageTokenV2.CollectionPublicPath, publicCollection: Type<&HWGarageTokenV2.Collection>(), publicLinkedType: Type<&HWGarageTokenV2.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-HWGarageTokenV2.createEmptyCollection(nftType: Type<@HWGarageTokenV2.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let externalURL = MetadataViews.ExternalURL("")
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: ""), mediaType: "image/png")
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: ""), mediaType: "image/png")
					let socialMap:{ String: MetadataViews.ExternalURL} ={ "facebook": MetadataViews.ExternalURL("https://www.facebook.com/hotwheels"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/hotwheelsofficial/"), "twitter": MetadataViews.ExternalURL("https://twitter.com/Hot_Wheels"), "discord": MetadataViews.ExternalURL("https://discord.gg/mattel")}
					return MetadataViews.NFTCollectionDisplay(name: self.metadata["collectionName"] ?? "Hot Wheels Garage Redeemable Token", description: self.metadata["collectionDescription"] ?? "Digital Collectable from Hot Wheels Garage", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socialMap)
				case Type<MetadataViews.Traits>():
					let exludedTraits = ["thumbnailPath", "thumbnailCID", "collectionName", "collectionDescription", "tokenDescription", "url"]
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
		
		init(id: UInt64, packSeriesID: UInt64, tokenEditionID: UInt64, metadata:{ String: String}){ 
			self.id = id
			self.packSeriesID = packSeriesID
			self.tokenEditionID = tokenEditionID
			self.metadata = metadata
			emit Mint(id: self.id)
		}
	}
	
	access(all)
	resource interface TokenCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowToken(id: UInt64): &HWGarageTokenV2.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow HWGarageTokenV2Pack reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: TokenCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let HWGarageTokenV2 <- token as! @HWGarageTokenV2.NFT
			let HWGarageTokenV2UUID = HWGarageTokenV2.uuid
			let HWGarageTokenV2SeriesID: UInt64 = HWGarageTokenV2.packSeriesID
			let HWGarageTokenV2ID: UInt64 = HWGarageTokenV2.id
			let HWGarageTokenV2tokenEditionID: UInt64 = HWGarageTokenV2.tokenEditionID
			self.ownedNFTs[HWGarageTokenV2ID] <-! HWGarageTokenV2
			emit Deposit(id: HWGarageTokenV2ID, to: self.owner?.address)
			emit DepositEvent(uuid: HWGarageTokenV2UUID, id: HWGarageTokenV2ID, seriesId: HWGarageTokenV2SeriesID, editionId: HWGarageTokenV2tokenEditionID, to: self.owner?.address)
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
		fun borrowToken(id: UInt64): &HWGarageTokenV2.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &HWGarageTokenV2.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let token = nft as! &HWGarageTokenV2.NFT
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
	fun addNewSeries(newTokenSeriesID: UInt64){ 
		self.currentTokenEditionIdByPackSeriesId.insert(key: newTokenSeriesID, 0)
	}
	
	access(account)
	fun updateCurrentEditionIdByPackSeriesId(packSeriesID: UInt64, tokenSeriesEdition: UInt64){ 
		self.currentTokenEditionIdByPackSeriesId[packSeriesID] = tokenSeriesEdition
	}
	
	access(account)
	fun mint(nftID: UInt64, packSeriesID: UInt64, metadata:{ String: String}): @{NonFungibleToken.NFT}{ 
		self.totalSupply = self.getTotalSupply() + 1
		self.currentTokenEditionIdByPackSeriesId[packSeriesID] = self.currentTokenEditionIdByPackSeriesId[packSeriesID]! + 1
		return <-create NFT(id: nftID, packSeriesID: packSeriesID, tokenEditionID: self.currentTokenEditionIdByPackSeriesId[packSeriesID]!, metadata: metadata)
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
	fun transfer(uuid: UInt64, id: UInt64, packSeriesId: UInt64, tokenEditionId: UInt64, toAddress: Address){ 
		let HWGarageTokenV2UUID: UInt64 = uuid
		let HWGarageTokenV2SeriesId: UInt64 = packSeriesId
		let HWGarageTokenV2ID: UInt64 = id
		let HWGarageTokenV2tokenEditionID: UInt64 = tokenEditionId
		emit TransferEvent(uuid: HWGarageTokenV2UUID, id: HWGarageTokenV2ID, seriesId: HWGarageTokenV2SeriesId, editionId: HWGarageTokenV2tokenEditionID, to: toAddress)
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
		self.name = "Hot Wheels Garage Token v2"
		self.totalSupply = 0
		self.currentTokenEditionIdByPackSeriesId ={ 1: 0}
		// set the named paths
		self.CollectionStoragePath = /storage/HWGarageTokenV2Collection
		self.CollectionPublicPath = /public/HWGarageTokenV2Collection
		emit ContractInitialized()
	}
}
