// Description: Smart Contract for Stanz
// SPDX-License-Identifier: UNLICENSED
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Stanz: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var name: String
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	struct Rarity{ 
		access(all)
		let rarity: UFix64?
		
		access(all)
		let rarityName: String
		
		access(all)
		let parts:{ String: RarityPart}
		
		init(rarity: UFix64?, rarityName: String, parts:{ String: RarityPart}){ 
			self.rarity = rarity
			self.rarityName = rarityName
			self.parts = parts
		}
	}
	
	access(all)
	struct RarityPart{ 
		access(all)
		let rarity: UFix64?
		
		access(all)
		let rarityName: String
		
		access(all)
		let name: String
		
		init(rarity: UFix64?, rarityName: String, name: String){ 
			self.rarity = rarity
			self.rarityName = rarityName
			self.name = name
		}
	}
	
	access(all)
	resource interface NFTModifier{ 
		access(account)
		fun setURLMetadataHelper(newURL: String, newThumbnail: String)
		
		access(account)
		fun setRarityHelper(rarity: UFix64, rarityName: String, rarityValue: String)
		
		access(account)
		fun setEditionHelper(editionNumber: UInt64)
		
		access(account)
		fun setMetadataHelper(metadata_name: String, metadata_value: String)
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver, NFTModifier{ 
		access(all)
		let id: UInt64
		
		access(all)
		var link: String
		
		access(all)
		var batch: UInt32
		
		access(all)
		var sequence: UInt16
		
		access(all)
		var limit: UInt16
		
		access(all)
		var name: String
		
		access(all)
		var description: String
		
		access(all)
		var thumbnail: String
		
		access(all)
		var royalties: [MetadataViews.Royalty]
		
		access(all)
		var rarity: UFix64?
		
		access(all)
		var rarityName: String
		
		access(all)
		var rarityValue: String
		
		access(all)
		var parts:{ String: RarityPart}
		
		access(all)
		var editionNumber: UInt64
		
		access(all)
		var metadata:{ String: String}
		
		access(account)
		fun setURLMetadataHelper(newURL: String, newThumbnail: String){ 
			self.link = newURL
			self.thumbnail = newThumbnail
			log("URL metadata is set to: ")
			log(self.link)
			log(self.thumbnail)
		}
		
		access(account)
		fun setRarityHelper(rarity: UFix64, rarityName: String, rarityValue: String){ 
			self.rarity = rarity
			self.rarityName = rarityName
			self.rarityValue = rarityValue
			self.parts ={ rarityName: RarityPart(rarity: rarity, rarityName: rarityName, name: rarityValue)}
			log("Rarity metadata is updated")
		}
		
		access(account)
		fun setEditionHelper(editionNumber: UInt64){ 
			self.editionNumber = editionNumber
			log("Edition metadata is updated")
		}
		
		access(account)
		fun setMetadataHelper(metadata_name: String, metadata_value: String){ 
			self.metadata.insert(key: metadata_name, metadata_value)
			log("Custom Metadata store is updated")
		}
		
		init(initID: UInt64, initlink: String, initbatch: UInt32, initsequence: UInt16, initlimit: UInt16, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty], editionNumber: UInt64, metadata:{ String: String}){ 
			self.id = initID
			self.link = initlink
			self.batch = initbatch
			self.sequence = initsequence
			self.limit = initlimit
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.royalties = royalties
			self.rarity = nil
			self.rarityName = "Tier"
			self.rarityValue = "null"
			self.parts ={ self.rarityName: RarityPart(rarity: self.rarity, rarityName: self.rarityName, name: self.rarityValue)}
			self.editionNumber = editionNumber
			self.metadata = metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<Rarity>(), Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<Rarity>():
					return Rarity(rarity: self.rarity, rarityName: self.rarityName, parts: self.parts)
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<MetadataViews.Editions>():
					let editionInfo: MetadataViews.Edition = MetadataViews.Edition(name: "Stanz", number: self.id, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(self.link)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Stanz.CollectionStoragePath, publicPath: Stanz.CollectionPublicPath, publicCollection: Type<&Stanz.Collection>(), publicLinkedType: Type<&Stanz.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Stanz.createEmptyCollection(nftType: Type<@Stanz.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					var squareImageFile: String = "null"
					var squareImageType: String = "null"
					if var _file = self.metadata["SquareImageFile"]{ 
						squareImageFile = _file
					}
					if var _type = self.metadata["SquareImageType"]{ 
						squareImageType = _type
					}
					let squareImage: MetadataViews.Media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: squareImageFile), mediaType: squareImageType)
					var bannerImageFile: String = "null"
					var bannerImageType: String = "null"
					if var _file = self.metadata["BannerImageFile"]{ 
						bannerImageFile = _file
					}
					if var _type = self.metadata["BannerImageType"]{ 
						bannerImageType = _type
					}
					let bannerImage: MetadataViews.Media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: bannerImageFile), mediaType: bannerImageType)
					return MetadataViews.NFTCollectionDisplay(name: "Stanz", description: "Stanz", externalURL: MetadataViews.ExternalURL(self.link), squareImage: squareImage, bannerImage: bannerImage, socials:{} )
				case Type<MetadataViews.Traits>():
					let excludedNames: [String] = ["SquareImageFile", "BannerImageFile", "SquareImageType", "BannerImageType"]
					let traitsView: MetadataViews.Traits = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedNames)
					return traitsView
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface StanzCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowStanz(id: UInt64): &Stanz.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Stanz reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: StanzCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID)!
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Stanz.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let exampleNFT = nft as! &Stanz.NFT
			return exampleNFT as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun borrowStanz(id: UInt64): &Stanz.NFT?{ 
			if self.ownedNFTs[id] == nil{ 
				return nil
			} else{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Stanz.NFT
			}
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
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	resource NFTMinter{ 
		access(all)
		var minterID: UInt64
		
		init(){ 
			self.minterID = 0
		}
		
		access(all)
		fun mintNFT(glink: String, gbatch: UInt32, glimit: UInt16, gsequence: UInt16, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty], editionNumber: UInt64, metadata:{ String: String}): @NFT{ 
			let tokenID = UInt64(gbatch) << 32 | UInt64(glimit) << 16 | UInt64(gsequence)
			var newNFT <- create NFT(initID: tokenID, initlink: glink, initbatch: gbatch, initsequence: gsequence, initlimit: glimit, name: name, description: description, thumbnail: thumbnail, royalties: royalties, editionNumber: editionNumber, metadata: metadata)
			self.minterID = tokenID
			Stanz.totalSupply = Stanz.totalSupply + 1
			return <-newNFT
		}
	}
	
	access(all)
	resource Modifier{ 
		access(all)
		var ModifierID: UInt64
		
		access(all)
		fun setURLMetadata(currentNFT: &Stanz.NFT?, newURL: String, newThumbnail: String): String{ 
			let ref2 = currentNFT!
			ref2.setURLMetadataHelper(newURL: newURL, newThumbnail: newThumbnail)
			log("URL metadata is set to: ")
			log(newURL)
			return newURL
		}
		
		access(all)
		fun setRarity(currentNFT: &Stanz.NFT?, rarity: UFix64, rarityName: String, rarityValue: String){ 
			let ref2 = currentNFT!
			ref2.setRarityHelper(rarity: rarity, rarityName: rarityName, rarityValue: rarityValue)
			log("Rarity metadata is updated")
		}
		
		access(all)
		fun setEdition(currentNFT: &Stanz.NFT?, editionNumber: UInt64){ 
			let ref2 = currentNFT!
			ref2.setEditionHelper(editionNumber: editionNumber)
			log("Edition metadata is updated")
		}
		
		access(all)
		fun setMetadata(currentNFT: &Stanz.NFT?, metadata_name: String, metadata_value: String){ 
			let ref2 = currentNFT!
			ref2.setMetadataHelper(metadata_name: metadata_name, metadata_value: metadata_value)
			log("Custom Metadata store is updated")
		}
		
		init(){ 
			self.ModifierID = 0
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/StanzCollection
		self.CollectionPublicPath = /public/StanzCollection
		self.MinterStoragePath = /storage/StanzMinter
		self.totalSupply = 0
		self.name = "Stanz Club"
		self.account.storage.save(<-self.createEmptyCollection(nftType: Type<@Collection>()), to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic, Stanz.StanzCollectionPublic, ViewResolver.ResolverCollection}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		self.account.storage.save(<-create NFTMinter(), to: self.MinterStoragePath)
		self.account.storage.save(<-create Modifier(), to: /storage/StanzModifier)
		emit ContractInitialized()
	}
}
