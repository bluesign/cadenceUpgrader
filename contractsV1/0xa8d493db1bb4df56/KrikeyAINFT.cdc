import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

/**
 * This contract defines the structure and behaviour of Solarpups NFT assets.
 * By using the KrikeyAINFT contract, assets can be registered in the AssetRegistry
 * so that NFTs, belonging to that asset can be minted. Assets and NFT tokens can
 * also be locked by this contract.
 */

access(all)
contract KrikeyAINFT: NonFungibleToken{ 
	access(all)
	let KrikeyAINFTPublicPath: PublicPath
	
	access(all)
	let KrikeyAINFTPrivatePath: PrivatePath
	
	access(all)
	let KrikeyAINFTStoragePath: StoragePath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let AssetRegistryStoragePath: StoragePath
	
	access(all)
	let MinterFactoryStoragePath: StoragePath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event MintAsset(id: UInt64, assetId: String)
	
	access(all)
	event BurnAsset(id: UInt64, assetId: String)
	
	access(all)
	event CollectionDeleted(from: Address?)
	
	access(all)
	var totalSupply: UInt64
	
	access(self)
	let assets:{ String: Asset}
	
	// Common interface for the NFT data.
	access(all)
	resource interface TokenDataAware{ 
		access(all)
		let data: TokenData
	}
	
	/**
		 * This resource represents a specific Solarpups NFT which can be
		 * minted and transferred. Each NFT belongs to an asset id and has
		 * an edition information. In addition to that each NFT can have other
		 * NFTs which makes it composable.
		 */
	
	access(all)
	resource NFT: NonFungibleToken.NFT, TokenDataAware, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let data: TokenData
		
		access(self)
		let items: @{String:{ TokenDataAware, NonFungibleToken.INFT}}
		
		init(id: UInt64, data: TokenData, items: @{String:{ TokenDataAware, NonFungibleToken.INFT}}){ 
			self.id = id
			self.data = data
			self.items <- items
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let asset = KrikeyAINFT.getAsset(assetId: self.data.assetId)
			let url = "https://cdn.krikeyapp.com/nft_web/nft_images/".concat(self.data.assetId).concat(".png")
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "Solarpups NFT", description: "The world's most adorable and sensitive pup.", thumbnail: MetadataViews.HTTPFile(url: url))
				case Type<MetadataViews.Editions>():
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					let editionInfo = MetadataViews.Edition(name: "Solarpups NFT Edition", number: self.data.edition as! UInt64, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					let RECEIVER_PATH = /public/flowTokenReceiver
					// Address Hardcoded for testing
					var royaltyReceiver = getAccount(0xff338e9d95c0bb8c).capabilities.get<&{FungibleToken.Receiver}>(RECEIVER_PATH)
					let royalty = MetadataViews.Royalty(receiver: royaltyReceiver!, cut: (asset!).royalty, description: "Solarpups Krikey Creator Royalty")
					return MetadataViews.Royalties([royalty])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(url)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: KrikeyAINFT.KrikeyAINFTStoragePath, publicPath: KrikeyAINFT.KrikeyAINFTPublicPath, publicCollection: Type<&KrikeyAINFT.Collection>(), publicLinkedType: Type<&KrikeyAINFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-KrikeyAINFT.createEmptyCollection(nftType: Type<@KrikeyAINFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://cdn.krikeyapp.com/web/assets/img/solar-pups/logo.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "The Krikey Solarpups Collection", description: "The world's most adorable and sensitive pups.", externalURL: MetadataViews.ExternalURL("https://www.solarpups.com/marketplace"), squareImage: media, bannerImage: media, socials:{ "discord": MetadataViews.ExternalURL("https://discord.com/invite/krikey"), "facebook": MetadataViews.ExternalURL("https://www.facebook.com/krikeyappAR/"), "twitter": MetadataViews.ExternalURL("https://twitter.com/SolarPupsNFTs"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/krikeyapp/?hl=en"), "youtube": MetadataViews.ExternalURL("https://www.youtube.com/channel/UCdTV4cmkQwWgaZ89ITMO-bg")})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	/**
		 * The data of a NFT token. The asset id references to the asset in the
		 * asset registry which holds all the information the NFT is about.
		 */
	
	access(all)
	struct TokenData{ 
		access(all)
		let assetId: String
		
		access(all)
		let edition: UInt16
		
		init(assetId: String, edition: UInt16){ 
			self.assetId = assetId
			self.edition = edition
		}
	}
	
	/**
		 * This resource is used to register an asset in order to mint NFT tokens of it.
		 * The asset registry manages the supply of the asset and is also able to lock it.
		 */
	
	access(all)
	resource AssetRegistry{ 
		access(all)
		fun store(asset: Asset){ 
			pre{ 
				KrikeyAINFT.assets[asset.assetId] == nil:
					"asset id already registered"
			}
			KrikeyAINFT.assets[asset.assetId] = asset
		}
		
		access(contract)
		fun setMaxSupply(assetId: String){ 
			pre{ 
				KrikeyAINFT.assets[assetId] != nil:
					"asset not found"
			}
			(KrikeyAINFT.assets[assetId]!).setMaxSupply()
		}
	}
	
	/**
		 * This structure defines all the information an asset has. The content
		 * attribute is a IPFS link to a data structure which contains all
		 * the data the NFT asset is about.
		 *
		 */
	
	access(all)
	struct Asset{ 
		access(all)
		let assetId: String
		
		access(all)
		let creators:{ Address: UFix64}
		
		access(all)
		var content: String
		
		access(all)
		let royalty: UFix64
		
		access(all)
		let supply: Supply
		
		access(contract)
		fun setMaxSupply(){ 
			self.supply.setMax(supply: 1)
		}
		
		access(contract)
		fun setCurSupply(supply: UInt16){ 
			self.supply.setCur(supply: supply)
		}
		
		init(creators:{ Address: UFix64}, assetId: String, content: String){ 
			pre{ 
				creators.length > 0:
					"no address found"
			}
			var sum: UFix64 = 0.0
			for value in creators.values{ 
				sum = sum + value
			}
			assert(sum == 1.0, message: "invalid creator shares")
			self.creators = creators
			self.assetId = assetId
			self.content = content
			self.royalty = 0.05
			self.supply = Supply(max: 1)
		}
	}
	
	/**
		 * This structure defines all information about the asset supply.
		 */
	
	access(all)
	struct Supply{ 
		access(all)
		var max: UInt16
		
		access(all)
		var cur: UInt16
		
		access(contract)
		fun setMax(supply: UInt16){ 
			pre{ 
				supply <= self.max:
					"supply must be lower or equal than current max supply"
				supply >= self.cur:
					"supply must be greater or equal than current supply"
			}
			self.max = supply
		}
		
		access(contract)
		fun setCur(supply: UInt16){ 
			pre{ 
				supply <= self.max:
					"max supply limit reached"
				supply > self.cur:
					"supply must be greater than current supply"
			}
			self.cur = supply
		}
		
		init(max: UInt16){ 
			self.max = max
			self.cur = 0
		}
	}
	
	/**
		 * This resource is used by an account to collect Solarpups NFTs.
		 */
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		var ownedAssets:{ String:{ UInt16: UInt64}}
		
		init(){ 
			self.ownedNFTs <-{} 
			self.ownedAssets ={} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- (self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")) as! @KrikeyAINFT.NFT
			self.ownedAssets[token.data.assetId]?.remove(key: token.data.edition)
			if self.ownedAssets[token.data.assetId]?.length == 0{ 
				self.ownedAssets.remove(key: token.data.assetId)
			}
			if self.owner?.address != nil{ 
				emit Withdraw(id: token.id, from: self.owner?.address!)
			}
			return <-token
		}
		
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <- create Collection()
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @KrikeyAINFT.NFT
			let id: UInt64 = token.id
			if self.ownedAssets[token.data.assetId] == nil{ 
				self.ownedAssets[token.data.assetId] ={} 
			}
			(self.ownedAssets[token.data.assetId]!).insert(key: token.data.edition, token.id)
			let oldToken <- self.ownedNFTs[id] <- token
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address!)
			}
			destroy oldToken
		}
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			for key in tokens.getIDs(){ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			destroy tokens
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		fun getAssetIDs(): [String]{ 
			return self.ownedAssets.keys
		}
		
		access(all)
		fun getTokenIDs(assetId: String): [UInt64]{ 
			return (self.ownedAssets[assetId] ??{} ).values
		}
		
		access(all)
		fun getEditions(assetId: String):{ UInt16: UInt64}{ 
			return self.ownedAssets[assetId] ??{} 
		}
		
		access(all)
		fun getOwnedAssets():{ String:{ UInt16: UInt64}}{ 
			return self.ownedAssets
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"this NFT is nil"
			}
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref! as! &{NonFungibleToken.NFT}
		}
		
		access(all)
		fun borrowKrikeyAINFT(id: UInt64): &KrikeyAINFT.NFT{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"this NFT is nil"
			}
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let solarpupsNFT = nft as! &KrikeyAINFT.NFT
			return solarpupsNFT as &KrikeyAINFT.NFT
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let solarpupsNFT = nft as! &KrikeyAINFT.NFT
			return solarpupsNFT as &{ViewResolver.Resolver}
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
	
	// This is the interface that users can cast their KrikeyAINFT Collection as
	// to allow others to deposit KrikeyAINFTs into their Collection. It also allows for reading
	// the details of KrikeyAINFTs in the Collection.
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun getAssetIDs(): [String]
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getTokenIDs(assetId: String): [UInt64]
		
		access(all)
		fun getEditions(assetId: String):{ UInt16: UInt64}
		
		access(all)
		fun getOwnedAssets():{ String:{ UInt16: UInt64}}
		
		access(all)
		fun borrowKrikeyAINFT(id: UInt64): &{NonFungibleToken.NFT}?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow KrikeyAINFT reference: the ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
	}
	
	access(all)
	resource MinterFactory{ 
		access(all)
		fun createMinter(): @Minter{ 
			return <-create Minter()
		}
	}
	
	// This resource is used to mint Solarpups NFTs.
	access(all)
	resource Minter{ 
		access(all)
		fun mint(assetId: String): @{NonFungibleToken.Collection}{ 
			pre{ 
				KrikeyAINFT.assets[assetId] != nil:
					"asset not found"
			}
			let collection <- create Collection()
			let supply = (KrikeyAINFT.assets[assetId]!).supply
			supply.setCur(supply: supply.cur + 1 as UInt16)
			let data = TokenData(assetId: assetId, edition: supply.cur)
			let token <- create NFT(id: KrikeyAINFT.totalSupply, data: data, items: <-{})
			collection.deposit(token: <-token)
			KrikeyAINFT.totalSupply = KrikeyAINFT.totalSupply + 1 as UInt64
			emit MintAsset(id: KrikeyAINFT.totalSupply, assetId: assetId)
			(KrikeyAINFT.assets[assetId]!).setCurSupply(supply: supply.cur)
			return <-collection
		}
	}
	
	access(account)
	fun getAsset(assetId: String): &KrikeyAINFT.Asset?{ 
		pre{ 
			self.assets[assetId] != nil:
				"asset not found"
		}
		return &self.assets[assetId] as &KrikeyAINFT.Asset?
	}
	
	access(all)
	fun getAssetIds(): [String]{ 
		return self.assets.keys
	}
	
	init(){ 
		self.totalSupply = 0
		self.assets ={} 
		self.KrikeyAINFTPublicPath = /public/KrikeyAINFTsProd03
		self.KrikeyAINFTPrivatePath = /private/KrikeyAINFTsProd03
		self.KrikeyAINFTStoragePath = /storage/KrikeyAINFTsProd03
		self.CollectionStoragePath = /storage/KrikeyAINFTsProd03
		self.AssetRegistryStoragePath = /storage/SolarpupsAssetRegistryProd03
		self.MinterFactoryStoragePath = /storage/SolarpupsMinterFactoryProd03
		self.account.storage.save(<-create AssetRegistry(), to: self.AssetRegistryStoragePath)
		self.account.storage.save(<-create MinterFactory(), to: self.MinterFactoryStoragePath)
		self.account.storage.save(<-create Collection(), to: self.KrikeyAINFTStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&KrikeyAINFT.Collection>(self.KrikeyAINFTStoragePath)
		self.account.capabilities.publish(capability_1, at: self.KrikeyAINFTPublicPath)
		emit ContractInitialized()
	}
}
