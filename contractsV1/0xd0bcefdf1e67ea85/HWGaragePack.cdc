/*
*
*   This is an implemetation of a Flow Non-Fungible Token
*   It is not a part of the official standard but it is assumed to be
*   similar to how NFTs would implement the core functionality
*
*
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract HWGaragePack: NonFungibleToken{ 
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
		*   Pack State Variables
		*/
	
	access(all)
	var name: String
	
	access(self)
	var collectionMetadata:{ String: String}
	
	access(self)
	let idToPackMetadata:{ UInt64: PackMetadata}
	
	access(all)
	struct PackMetadata{ 
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
		let packEditionID: UInt64
		
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
					return MetadataViews.Display(name: self.getMetadata()["name"] ?? "How Wheels Garage Series 4 Pack #".concat(self.packEditionID.toString()), description: self.getMetadata()["description"] ?? "Digital Pack Collectable from Hot Wheels Garage", thumbnail: ipfsImage)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: HWGaragePack.CollectionStoragePath, publicPath: HWGaragePack.CollectionPublicPath, publicCollection: Type<&HWGaragePack.Collection>(), publicLinkedType: Type<&HWGaragePack.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-HWGaragePack.createEmptyCollection(nftType: Type<@HWGaragePack.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let externalURL = MetadataViews.ExternalURL("")
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: ""), mediaType: "image/png")
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: ""), mediaType: "image/png")
					let socialMap:{ String: MetadataViews.ExternalURL} ={ "facebook": MetadataViews.ExternalURL("https://www.facebook.com/hotwheels"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/hotwheelsofficial/"), "twitter": MetadataViews.ExternalURL("https://twitter.com/Hot_Wheels"), "discord": MetadataViews.ExternalURL("https://discord.gg/mattel")}
					return MetadataViews.NFTCollectionDisplay(name: "Hot Wheels Garage Pack", description: "Digital Collectable from Hot Wheels Garage", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socialMap)
				case Type<MetadataViews.Royalties>():
					let flowReciever = getAccount(0xf86e2f015cd692be).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: flowReciever!, cut: 0.05, description: "Mattel 5% Royalty")])
			}
			return nil
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			if HWGaragePack.idToPackMetadata[self.id] != nil{ 
				return (HWGaragePack.idToPackMetadata[self.id]!).metadata
			} else{ 
				return{} 
			}
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64, packID: UInt64, packEditionID: UInt64){ 
			self.id = id
			self.packID = packID
			self.packEditionID = packEditionID
			emit Mint(id: self.id)
		}
	}
	
	access(all)
	resource interface PackCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowPack(id: UInt64): &HWGaragePack.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow HWGaragePack reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: PackCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let HWGaragePack <- token as! @HWGaragePack.NFT
			let HWGaragePackUUID: UInt64 = HWGaragePack.uuid
			let HWGaragePackSeriesID: UInt64 = 4
			let HWGaragePackID: UInt64 = HWGaragePack.id
			let HWGaragePackpackEditionID: UInt64 = HWGaragePack.packEditionID
			self.ownedNFTs[HWGaragePackID] <-! HWGaragePack
			emit Deposit(id: HWGaragePackID, to: self.owner?.address)
			emit DepositEvent(uuid: HWGaragePackUUID, id: HWGaragePackID, seriesId: HWGaragePackSeriesID, editionId: HWGaragePackpackEditionID, to: self.owner?.address)
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
		fun borrowPack(id: UInt64): &HWGaragePack.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &HWGaragePack.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nftPack = nft as! &HWGaragePack.NFT
			return nftPack as &{ViewResolver.Resolver}
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
		self.idToPackMetadata[editionNumber] = PackMetadata(metadata: metadata)
	}
	
	access(account)
	fun setCollectionMetadata(metadata:{ String: String}){ 
		self.collectionMetadata = metadata
	}
	
	access(account)
	fun mint(nftID: UInt64, packID: UInt64, packEditionID: UInt64): @{NonFungibleToken.NFT}{ 
		self.totalSupply = self.totalSupply + 1
		return <-create NFT(id: nftID, packID: packID, packEditionID: packEditionID)
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
	fun transfer(uuid: UInt64, id: UInt64, packSeriesId: UInt64, packEditionId: UInt64, toAddress: Address){ 
		let HWGaragePackV2UUID: UInt64 = uuid
		let HWGaragePackV2SeriesId: UInt64 = packSeriesId
		let HWGaragePackV2ID: UInt64 = id
		let HWGaragePackV2packEditionID: UInt64 = packEditionId
		emit TransferEvent(uuid: HWGaragePackV2UUID, id: HWGaragePackV2ID, seriesId: HWGaragePackV2SeriesId, editionId: HWGaragePackV2packEditionID, to: toAddress)
	}
	
	access(all)
	fun getCollectionMetadata():{ String: String}{ 
		return self.collectionMetadata
	}
	
	access(all)
	fun getEditionMetadata(_ edition: UInt64):{ String: String}{ 
		if self.idToPackMetadata[edition] != nil{ 
			return (self.idToPackMetadata[edition]!).metadata
		} else{ 
			return{} 
		}
	}
	
	access(all)
	fun getMetadataLength(): Int{ 
		return self.idToPackMetadata.length
	}
	
	access(all)
	fun getPackMetadata(): AnyStruct{ 
		return self.idToPackMetadata
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
		self.name = "HWGaragePack"
		self.totalSupply = 0
		self.collectionMetadata ={} 
		self.idToPackMetadata ={} 
		// set the named paths
		self.CollectionStoragePath = /storage/HWGaragePackCollection
		self.CollectionPublicPath = /public/HWGaragePackCollection
		emit ContractInitialized()
	}
}
