import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract YerchNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Bought(id: UInt64, to: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let edition: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnailCID: String
		
		access(all)
		let gameAssetID: String
		
		access(all)
		let type: String
		
		access(all)
		var season: String
		
		access(all)
		var rarity: String
		
		init(edition: UInt64, name: String, description: String, thumbnailCID: String, gameAssetID: String, type: String, season: String, rarity: String){ 
			YerchNFT.totalSupply = YerchNFT.totalSupply + 1
			self.id = YerchNFT.totalSupply
			self.edition = edition
			self.name = name
			self.description = description
			self.thumbnailCID = thumbnailCID
			self.gameAssetID = gameAssetID
			self.type = type
			self.season = season
			self.rarity = rarity
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.IPFSFile(cid: self.thumbnailCID, path: ""))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: YerchNFT.CollectionStoragePath, publicPath: YerchNFT.CollectionPublicPath, publicCollection: Type<&YerchNFT.Collection>(), publicLinkedType: Type<&YerchNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-YerchNFT.createEmptyCollection(nftType: Type<@YerchNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: ""), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "Yerch NFT", description: "Collection of YDY Yerch NFTs.", externalURL: MetadataViews.ExternalURL("https://www.ydylife.com/"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/ydylife")})
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://www.ydylife.com/")
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: getAccount(YerchNFT.account.address).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, cut: 0.075, description: "This is the royalty receiver for YDY Yerch NFTs")])
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface YerchNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowYerchNFT(id: UInt64): &YerchNFT.NFT
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
	}
	
	access(all)
	resource Collection: NonFungibleToken.Receiver, NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, YerchNFTCollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let myToken <- token as! @YerchNFT.NFT
			emit Deposit(id: myToken.id, to: self.owner?.address)
			self.ownedNFTs[myToken.id] <-! myToken
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("This NFT does not exist")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
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
		fun borrowYerchNFT(id: UInt64): &YerchNFT.NFT{ 
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return ref as! &YerchNFT.NFT
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nft = ref as! &YerchNFT.NFT
			return nft as &{ViewResolver.Resolver}
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
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun mintNFT(metadata:{ String: String}, edition: UInt64, recipient: Capability<&Collection>){ 
			pre{ 
				metadata["name"] != nil:
					"Name is required"
				metadata["description"] != nil:
					"Description is required"
				metadata["thumbnailCID"] != nil:
					"Thumbnail CID is required"
				metadata["gameAssetID"] != nil:
					"Game Asset ID is required"
				metadata["type"] != nil:
					"Type is required"
				metadata["season"] != nil:
					"Season is required"
				metadata["rarity"] != nil:
					"Rarity is required"
			}
			let nft <- create NFT(edition: edition, name: metadata["name"]!, description: metadata["description"]!, thumbnailCID: metadata["thumbnailCID"]!, gameAssetID: metadata["gameAssetID"]!, type: metadata["type"]!, season: metadata["season"]!, rarity: metadata["rarity"]!)
			let recipientCollection = recipient.borrow() ?? panic("Could not borrow recipient's collection")
			recipientCollection.deposit(token: <-nft)
		}
	}
	
	init(){ 
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/YerchNFTCollectionStaging
		self.CollectionPublicPath = /public/YerchNFTCollectionStaging
		self.AdminStoragePath = /storage/YerchNFTAdminStaging
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
