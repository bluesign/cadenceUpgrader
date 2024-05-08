/*
	Description: This is an NFT that will be issued to anyone who visits the Schmoes website before 
	the official launch of the Shmoes NFT
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract SchmoesPreLaunchToken: NonFungibleToken{ 
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Events
	// -----------------------------------------------------------------------
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// -----------------------------------------------------------------------
	// Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Fields
	// -----------------------------------------------------------------------
	access(all)
	var totalSupply: UInt64
	
	// -----------------------------------------------------------------------
	// SchmoesPreLaunchToken Fields
	// -----------------------------------------------------------------------
	// NFT level metadata
	access(all)
	var name: String
	
	access(all)
	var imageUrl: String
	
	access(all)
	var isSaleActive: Bool
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		init(initID: UInt64){ 
			self.id = initID
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "Schmoes Pre Launch Token #".concat(self.id.toString()), description: "", thumbnail: MetadataViews.HTTPFile(url: SchmoesPreLaunchToken.imageUrl))
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://schmoes.io")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: SchmoesPreLaunchToken.CollectionStoragePath, publicPath: SchmoesPreLaunchToken.CollectionPublicPath, publicCollection: Type<&SchmoesPreLaunchToken.Collection>(), publicLinkedType: Type<&SchmoesPreLaunchToken.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-SchmoesPreLaunchToken.createEmptyCollection(nftType: Type<@SchmoesPreLaunchToken.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: SchmoesPreLaunchToken.imageUrl), mediaType: "image")
					return MetadataViews.NFTCollectionDisplay(name: "Schmoes Pre Launch Token", description: "", externalURL: MetadataViews.ExternalURL("https://schmoes.io"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/SchmoesNFT")})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	/*
			This collection only allows the storage of a single NFT
		 */
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @SchmoesPreLaunchToken.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
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
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let launchTokenNFT = nft as! &SchmoesPreLaunchToken.NFT
			return launchTokenNFT as &{ViewResolver.Resolver}
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
	
	// -----------------------------------------------------------------------
	// Admin Functions
	// -----------------------------------------------------------------------
	access(account)
	fun setImageUrl(_ newImageUrl: String){ 
		self.imageUrl = newImageUrl
	}
	
	access(account)
	fun setIsSaleActive(_ newIsSaleActive: Bool){ 
		self.isSaleActive = newIsSaleActive
	}
	
	// -----------------------------------------------------------------------
	// Public Functions
	// -----------------------------------------------------------------------
	access(all)
	fun mint(): @SchmoesPreLaunchToken.NFT{ 
		pre{ 
			self.isSaleActive:
				"Sale is not active"
		}
		let id = SchmoesPreLaunchToken.totalSupply + 1 as UInt64
		let newNFT: @SchmoesPreLaunchToken.NFT <- create SchmoesPreLaunchToken.NFT(initID: id)
		SchmoesPreLaunchToken.totalSupply = id
		return <-newNFT
	}
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Functions
	// -----------------------------------------------------------------------
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	init(){ 
		self.name = "SchmoesPreLaunchToken"
		self.imageUrl = ""
		self.isSaleActive = false
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/SchmoesPreLaunchTokenCollection
		self.CollectionPublicPath = /public/SchmoesPreLaunchTokenCollection
		emit ContractInitialized()
	}
}
