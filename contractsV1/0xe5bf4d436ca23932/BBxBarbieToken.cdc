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
contract BBxBarbieToken: NonFungibleToken{ 
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
		
		access(all)
		let packSeriesID: UInt64
		
		access(all)
		let tokenEditionID: UInt64
		
		access(all)
		let redeemable: String
		
		access(all)
		let metadata:{ String: String}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					var ipfsImage = MetadataViews.IPFSFile(cid: self.metadata["thumbnailCID"] ?? "ThumnailCID not set", path: self.metadata["thumbnailPath"] ?? "ThumbnailPath not set")
					return MetadataViews.Display(name: self.metadata["name"]?.concat(" Token #")?.concat(self.tokenEditionID.toString()) ?? "Boss Beauties x Barbie Redeemable Token", description: self.metadata["description"] ?? "Digital Redeemable Token Collectable from the Boss Beauties x Barbie collaboration", thumbnail: ipfsImage)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(self.metadata["url"] ?? "")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: BBxBarbieToken.CollectionStoragePath, publicPath: BBxBarbieToken.CollectionPublicPath, publicCollection: Type<&BBxBarbieToken.Collection>(), publicLinkedType: Type<&BBxBarbieToken.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-BBxBarbieToken.createEmptyCollection(nftType: Type<@BBxBarbieToken.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let externalURL = MetadataViews.ExternalURL("https://mattel.com/")
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://www.mattel.com/"), mediaType: "image/png")
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://www.mattel.com/"), mediaType: "image/png")
					let socialMap:{ String: MetadataViews.ExternalURL} ={ "facebook": MetadataViews.ExternalURL("https://www.facebook.com/mattel"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/mattel"), "twitter": MetadataViews.ExternalURL("https://www.twitter.com/mattel")}
					return MetadataViews.NFTCollectionDisplay(name: self.metadata["name"] ?? "Boss Beauties x Barbie Token", description: self.metadata["dropDescription"] ?? "Digital Collectable from the Boss Beauties x Barbie collaboration", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socialMap)
				case Type<MetadataViews.Traits>():
					let excludedTraits = ["thumbnailPath", "thumbnailCID", "drop", "dropDescription", "description", "url"]
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)
					return traitsView
				case Type<MetadataViews.Royalties>():
					let flowReciever = getAccount(0xf86e2f015cd692be).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: flowReciever!, cut: 0.05, description: "Mattel 5% Royalty")])
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64, packSeriesID: UInt64, tokenEditionID: UInt64, redeemable: String, metadata:{ String: String}){ 
			self.id = id
			self.packSeriesID = packSeriesID
			self.tokenEditionID = tokenEditionID
			self.redeemable = redeemable
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
		fun borrowToken(id: UInt64): &BBxBarbieToken.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow BBxBarbieToken reference: The ID of the returned reference is incorrect"
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
			let BBxBarbieToken <- token as! @BBxBarbieToken.NFT
			let BBxBarbieTokenUUID: UInt64 = BBxBarbieToken.uuid
			let BBxBarbieTokenSeriesId: UInt64 = BBxBarbieToken.packSeriesID
			let BBxBarbieTokenID: UInt64 = BBxBarbieToken.id
			let BBxBarbieTokenEditionID: UInt64 = BBxBarbieToken.tokenEditionID
			self.ownedNFTs[BBxBarbieTokenID] <-! BBxBarbieToken
			emit Deposit(id: BBxBarbieTokenID, to: self.owner?.address)
			emit DepositEvent(uuid: BBxBarbieTokenUUID, id: BBxBarbieTokenID, seriesId: BBxBarbieTokenSeriesId, editionId: BBxBarbieTokenEditionID, to: self.owner?.address)
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
		fun borrowToken(id: UInt64): &BBxBarbieToken.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &BBxBarbieToken.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let token = nft as! &BBxBarbieToken.NFT
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
	fun mint(nftID: UInt64, packSeriesID: UInt64, tokenEditionID: UInt64, metadata:{ String: String}): @{NonFungibleToken.NFT}{ 
		self.totalSupply = self.getTotalSupply() + 1
		self.currentTokenEditionIdByPackSeriesId[packSeriesID] = self.currentTokenEditionIdByPackSeriesId[packSeriesID]! + 1
		return <-create NFT(id: nftID, packSeriesID: packSeriesID, tokenEditionID: self.currentTokenEditionIdByPackSeriesId[packSeriesID]!, redeemable: metadata["redeemable"]!, metadata: metadata)
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
		let BBxBarbieTokenV2UUID: UInt64 = uuid
		let BBxBarbieTokenV2SeriesId: UInt64 = packSeriesId
		let BBxBarbieTokenV2ID: UInt64 = id
		let BBxBarbieTokenV2tokenEditionID: UInt64 = tokenEditionId
		emit TransferEvent(uuid: BBxBarbieTokenV2UUID, id: BBxBarbieTokenV2ID, seriesId: BBxBarbieTokenV2SeriesId, editionId: BBxBarbieTokenV2tokenEditionID, to: toAddress)
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
		self.name = "Boss Beauties x Barbie Token"
		self.totalSupply = 0
		self.currentTokenEditionIdByPackSeriesId ={ 1: 0}
		
		// set the named paths
		self.CollectionStoragePath = /storage/BBxBarbieTokenCollection
		self.CollectionPublicPath = /public/BBxBarbieTokenCollection
		emit ContractInitialized()
	}
}
