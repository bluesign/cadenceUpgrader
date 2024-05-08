/*
*
*   An NFT contract for redeeming/minting unlimited tokens
*
*
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract BBxBarbieCard: NonFungibleToken{ 
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
		let id: UInt64 // aka cardEditionID
		
		
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
			return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Medias>(), Type<MetadataViews.Rarity>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					var ipfsImage = MetadataViews.IPFSFile(cid: self.metadata["thumbnailCID"] ?? "ThumnailCID not set", path: self.metadata["thumbnailPath"] ?? "ThumbnailPath not set")
					return MetadataViews.Display(name: self.metadata["name"]?.concat(" Card #")?.concat(self.cardEditionID.toString()) ?? "Boss Beauties x Barbie Card", description: self.metadata["description"] ?? "Digital Card Collectable from the Boss Beauties x Barbie collaboration", thumbnail: ipfsImage)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(self.metadata["url"] ?? "")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: BBxBarbieCard.CollectionStoragePath, publicPath: BBxBarbieCard.CollectionPublicPath, publicCollection: Type<&BBxBarbieCard.Collection>(), publicLinkedType: Type<&BBxBarbieCard.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-BBxBarbieCard.createEmptyCollection(nftType: Type<@BBxBarbieCard.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let externalURL = MetadataViews.ExternalURL("https://mattel.com/")
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://www.mattel.com/"), mediaType: "image/png")
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://www.mattel.com/"), mediaType: "image/png")
					let socialMap:{ String: MetadataViews.ExternalURL} ={ "facebook": MetadataViews.ExternalURL("https://www.facebook.com/mattel"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/mattel"), "twitter": MetadataViews.ExternalURL("https://www.twitter.com/mattel")}
					return MetadataViews.NFTCollectionDisplay(name: self.metadata["career"] ?? self.metadata["miniCollection"] ?? "BBxBarbie", description: self.metadata["careerDescription"] ?? "Digital Collectable from the Boss Beauties x Barbie collaboration", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socialMap)
				case Type<MetadataViews.Royalties>():
					let flowReciever = getAccount(0xf86e2f015cd692be).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: flowReciever!, cut: 0.05, description: "Mattel 5% Royalty")])
				case Type<MetadataViews.Traits>():
					let excludedTraits = ["thumbnailPath", "thumbnailCID", "career", "careerDescription", "description", "url"]
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)
					return traitsView
				case Type<MetadataViews.Editions>():
					return MetadataViews.Edition(name: nil, number: self.id, max: nil)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.uuid)
				case Type<MetadataViews.Medias>():
					return []
				// MetadataViews.Media(
				//	 file: MetadataViews.IPFSFile(
				//		 cid: self.metadata["thumbnailCid"] ?? ""
				//		 , path: self.metadata["thumbnailPath"] ?? ""
				//		 )
				//	 , mediaType: "image/png"
				//	 ),
				// MetadataViews.Media(
				//	 file: MetadataViews.IPFSFile(
				//		 cid: self.metadata["mp4Cid"] ?? ""
				//		 , path: self.metadata["mp4Path"] ?? ""
				//		 )
				//	 , mediaType: "video/mp4"
				//	 )
				case Type<MetadataViews.Rarity>():
					return MetadataViews.Rarity(score: nil, max: nil, description: self.metadata["rarity"])
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
		fun borrowCard(id: UInt64): &BBxBarbieCard.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow BBxBarbieCardPack reference: The ID of the returned reference is incorrect"
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
			let BBxBarbieCard <- token as! @BBxBarbieCard.NFT
			let BBxBarbieCardUUID: UInt64 = BBxBarbieCard.uuid
			let BBxBarbieCardSeriesId: UInt64 = BBxBarbieCard.packSeriesID
			let BBxBarbieCardID: UInt64 = BBxBarbieCard.id
			let BBxBarbieCardEditionID: UInt64 = BBxBarbieCard.cardEditionID
			self.ownedNFTs[BBxBarbieCardID] <-! BBxBarbieCard
			emit Deposit(id: BBxBarbieCardID, to: self.owner?.address)
			emit DepositEvent(uuid: BBxBarbieCardUUID, id: BBxBarbieCardID, seriesId: BBxBarbieCardSeriesId, editionId: BBxBarbieCardEditionID, to: self.owner?.address)
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
		fun borrowCard(id: UInt64): &BBxBarbieCard.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &BBxBarbieCard.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let token = nft as! &BBxBarbieCard.NFT
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
	fun mint(nftID: UInt64, packSeriesID: UInt64, cardEditionID: UInt64, packHash: String, metadata:{ String: String}): @{NonFungibleToken.NFT}{ 
		self.totalSupply = self.getTotalSupply() + 1
		self.currentCardEditionIdByPackSeriesId[packSeriesID] = self.currentCardEditionIdByPackSeriesId[packSeriesID]! + 1
		return <-create NFT(id: nftID, packSeriesID: packSeriesID, cardEditionID: self.currentCardEditionIdByPackSeriesId[packSeriesID]!, packHash: packHash, redeemable: metadata["redeemable"]!, metadata: metadata)
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
		let BBxBarbieCardV2UUID: UInt64 = uuid
		let BBxBarbieCardV2SeriesId: UInt64 = packSeriesId
		let BBxBarbieCardV2ID: UInt64 = id
		let BBxBarbieCardV2cardEditionID: UInt64 = cardEditionId
		emit TransferEvent(uuid: BBxBarbieCardV2UUID, id: BBxBarbieCardV2ID, seriesId: BBxBarbieCardV2SeriesId, editionId: BBxBarbieCardV2cardEditionID, to: toAddress)
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
		self.name = "Boss Beauties x Barbie Card"
		self.totalSupply = 0
		self.currentCardEditionIdByPackSeriesId ={ 1: 0}
		
		// set the named paths
		self.CollectionStoragePath = /storage/BBxBarbieCardCollection
		self.CollectionPublicPath = /public/BBxBarbieCardCollection
		emit ContractInitialized()
	}
}
