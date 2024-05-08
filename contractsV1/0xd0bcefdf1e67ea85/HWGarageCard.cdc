/*
*
*   An NFT contract demo for redeeming/minting unlimited tokens
*
*
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract HWGarageCard: NonFungibleToken{ 
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
	
	access(all)
	var name: String
	
	access(self)
	var collectionMetadata:{ String: String}
	
	access(self)
	let idToTokenMetadata:{ UInt64: TokenMetadata}
	
	access(all)
	struct TokenMetadata{ 
		access(all)
		let metadata:{ String: String}
		
		init(metadata:{ String: String}){ 
			self.metadata = metadata
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let packID: UInt64
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					var ipfsImage = MetadataViews.IPFSFile(cid: "No thumbnail cid set", path: "No thumbnail path set")
					if self.getMetadata().containsKey("thumbnailCID"){ 
						ipfsImage = MetadataViews.IPFSFile(cid: self.getMetadata()["thumbnailCID"]!, path: self.getMetadata()["thumbnailPath"])
					}
					return MetadataViews.Display(name: self.getMetadata()["name"] ?? "Hot Wheels Garage Card Series 4 #".concat(self.id.toString()), description: self.getMetadata()["description"] ?? "Digital Card Collectable from Hot Wheels Garage", thumbnail: ipfsImage)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: HWGarageCard.CollectionStoragePath, publicPath: HWGarageCard.CollectionPublicPath, publicCollection: Type<&HWGarageCard.Collection>(), publicLinkedType: Type<&HWGarageCard.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-HWGarageCard.createEmptyCollection(nftType: Type<@HWGarageCard.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let externalURL = MetadataViews.ExternalURL("")
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: ""), mediaType: "image/png")
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: ""), mediaType: "image/png")
					let socialMap:{ String: MetadataViews.ExternalURL} ={ "facebook": MetadataViews.ExternalURL("https://www.facebook.com/hotwheels"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/hotwheelsofficial/"), "twitter": MetadataViews.ExternalURL("https://twitter.com/Hot_Wheels"), "discord": MetadataViews.ExternalURL("https://discord.gg/mattel")}
					return MetadataViews.NFTCollectionDisplay(name: "Hot Wheels Garage Card", description: "Digital Collectable from Hot Wheels Garage", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socialMap)
				case Type<MetadataViews.Royalties>():
					let flowReciever = getAccount(0xf86e2f015cd692be).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: flowReciever!, cut: 0.05, description: "Mattel 5% Royalty")])
			}
			return nil
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			if HWGarageCard.idToTokenMetadata[self.id] != nil{ 
				return (HWGarageCard.idToTokenMetadata[self.id]!).metadata
			} else{ 
				return{} 
			}
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64, packID: UInt64){ 
			self.id = id
			self.packID = packID
			emit Mint(id: self.id)
		}
	}
	
	access(all)
	resource interface HWGarageCardCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowHWGarageCard(id: UInt64): &HWGarageCard.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow HWGarageCardPack reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: HWGarageCardCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			// let token <- token as! @HWGarageCard.NFT
			// let id: UInt64 = token.id
			let HWGarageCard <- token as! @HWGarageCard.NFT
			let HWGarageCardUUID: UInt64 = HWGarageCard.uuid
			let HWGarageCardSeriesId: UInt64 = 4
			let HWGarageCardID: UInt64 = HWGarageCard.id
			let HWGarageCardcardEditionID: UInt64 = HWGarageCard.id
			self.ownedNFTs[HWGarageCardID] <-! HWGarageCard
			emit Deposit(id: HWGarageCardID, to: self.owner?.address)
			emit DepositEvent(uuid: HWGarageCardUUID, id: HWGarageCardID, seriesId: HWGarageCardSeriesId, editionId: HWGarageCardcardEditionID, to: self.owner?.address)
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
		fun borrowHWGarageCard(id: UInt64): &HWGarageCard.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &HWGarageCard.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let token = nft as! &HWGarageCard.NFT
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
	fun setEditionMetadata(editionNumber: UInt64, metadata:{ String: String}){ 
		self.idToTokenMetadata[editionNumber] = TokenMetadata(metadata: metadata)
	}
	
	access(account)
	fun setCollectionMetadata(metadata:{ String: String}){ 
		self.collectionMetadata = metadata
	}
	
	access(account)
	fun mint(nftID: UInt64, packID: UInt64): @{NonFungibleToken.NFT}{ 
		self.totalSupply = self.totalSupply + 1
		return <-create NFT(id: nftID, packID: packID)
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
	
	access(all)
	fun getCollectionMetadata():{ String: String}{ 
		return self.collectionMetadata
	}
	
	access(all)
	fun getEditionMetadata(_ edition: UInt64):{ String: String}{ 
		if self.idToTokenMetadata[edition] != nil{ 
			return (self.idToTokenMetadata[edition]!).metadata
		} else{ 
			return{} 
		}
	}
	
	access(all)
	fun getMetadataLength(): Int{ 
		return self.idToTokenMetadata.length
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
		self.name = "HWGarageCard"
		self.totalSupply = 0
		self.collectionMetadata ={} 
		self.idToTokenMetadata ={} 
		// set the named paths
		self.CollectionStoragePath = /storage/HWGarageCardCollection
		self.CollectionPublicPath = /public/HWGarageCardCollection
		emit ContractInitialized()
	}
}
