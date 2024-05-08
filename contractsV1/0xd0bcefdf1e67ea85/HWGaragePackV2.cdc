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
contract HWGaragePackV2: NonFungibleToken{ 
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
	
	access(account)
	var name: String
	
	access(account)
	var currentPackEditionIdByPackSeriesId:{ UInt64: UInt64}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let packSeriesID: UInt64
		
		access(all)
		let packEditionID: UInt64
		
		access(all)
		let packHash: String
		
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
					var ipfsImage = MetadataViews.IPFSFile(cid: self.metadata["thumbnailCID"] ?? "No ThumnailCID set", path: self.metadata["thumbnailPath"] ?? "")
					return MetadataViews.Display(name: (self.metadata["packName"]!).concat(" Series ").concat(self.packSeriesID.toString()).concat(" #").concat(self.packEditionID.toString()), description: self.metadata["packDescription"] ?? "Digital Pack Collectable from Hot Wheels Garage", thumbnail: ipfsImage)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(self.metadata["url"] ?? "")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: HWGaragePackV2.CollectionStoragePath, publicPath: HWGaragePackV2.CollectionPublicPath, publicCollection: Type<&HWGaragePackV2.Collection>(), publicLinkedType: Type<&HWGaragePackV2.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-HWGaragePackV2.createEmptyCollection(nftType: Type<@HWGaragePackV2.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let externalURL = MetadataViews.ExternalURL("")
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: ""), mediaType: "image/png")
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: ""), mediaType: "image/png")
					let socialMap:{ String: MetadataViews.ExternalURL} ={ "facebook": MetadataViews.ExternalURL("https://www.facebook.com/hotwheels"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/hotwheelsofficial/"), "twitter": MetadataViews.ExternalURL("https://twitter.com/Hot_Wheels"), "discord": MetadataViews.ExternalURL("https://discord.gg/mattel")}
					return MetadataViews.NFTCollectionDisplay(name: self.metadata["collectionName"] ?? "Hot Wheels Garage Pack", description: self.metadata["collectionDescription"] ?? "Digital Collectable from Hot Wheels Garage", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socialMap)
				case Type<MetadataViews.Traits>():
					let excludedTraits = ["thumbnailPath", "thumbnailCID", "collectionName", "collectionDescription", "packDescription", "url"]
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)
					let packHashTrait = MetadataViews.Trait(name: "packHash", value: self.packHash, displayType: "String", rarity: nil)
					traitsView.addTrait(packHashTrait)
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
		
		init(id: UInt64, packSeriesID: UInt64, packEditionID: UInt64, packHash: String, metadata:{ String: String}){ 
			self.id = id
			self.packSeriesID = packSeriesID
			self.packEditionID = packEditionID
			self.packHash = packHash
			self.metadata = metadata
			emit Mint(id: self.packEditionID)
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
		fun borrowPack(id: UInt64): &HWGaragePackV2.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow HWGaragePackV2 reference: The ID of the returned reference is incorrect"
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
			let HWGaragePackV2 <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: HWGaragePackV2.id, from: self.owner?.address)
			return <-HWGaragePackV2
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let HWGaragePackV2 <- token as! @HWGaragePackV2.NFT
			let HWGaragePackV2UUID: UInt64 = HWGaragePackV2.uuid
			let HWGaragePackV2SeriesID: UInt64 = HWGaragePackV2.packSeriesID
			let HWGaragePackV2ID: UInt64 = HWGaragePackV2.id
			let HWGaragePackV2packEditionID: UInt64 = HWGaragePackV2.packEditionID
			self.ownedNFTs[HWGaragePackV2ID] <-! HWGaragePackV2
			emit Deposit(id: HWGaragePackV2ID, to: self.owner?.address)
			emit DepositEvent(uuid: HWGaragePackV2UUID, id: HWGaragePackV2ID, seriesId: HWGaragePackV2SeriesID, editionId: HWGaragePackV2packEditionID, to: self.owner?.address)
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
		fun borrowPack(id: UInt64): &HWGaragePackV2.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &HWGaragePackV2.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nftPack = nft as! &HWGaragePackV2.NFT
			return nftPack
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
	fun addNewSeries(newPackSeriesID: UInt64){ 
		if newPackSeriesID == 4{ 
			panic("series 4 cannot live here")
		} else{ 
			self.currentPackEditionIdByPackSeriesId.insert(key: newPackSeriesID, 0)
		}
	}
	
	access(account)
	fun updateCurrentEditionIdByPackSeriesId(packSeriesID: UInt64, packSeriesEdition: UInt64){ 
		self.currentPackEditionIdByPackSeriesId[packSeriesID] = packSeriesEdition
	}
	
	access(account)
	fun mint(nftID: UInt64, packEditionID: UInt64, packSeriesID: UInt64, packHash: String, metadata:{ String: String}): @{NonFungibleToken.NFT}{ 
		self.totalSupply = self.totalSupply + 1
		self.currentPackEditionIdByPackSeriesId[packSeriesID] = self.currentPackEditionIdByPackSeriesId[packSeriesID]! + 1
		return <-create NFT(id: nftID, packSeriesID: packSeriesID, packEditionID: self.currentPackEditionIdByPackSeriesId[packSeriesID]!, packHash: packHash, metadata: metadata)
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
	
	/* 
		*   NonFungibleToken Standard Functions
		*/
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// initialize contract state variables
	init(){ 
		self.name = "Hot Wheels Garage Pack v2"
		self.totalSupply = 0
		self.currentPackEditionIdByPackSeriesId ={ 1: 0}
		// set the named paths
		self.CollectionStoragePath = /storage/HWGaragePackV2Collection
		self.CollectionPublicPath = /public/HWGaragePackV2Collection
		emit ContractInitialized()
	}
}
