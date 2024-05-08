import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract CarClub: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event CarClubMinted(id: UInt64, name: String, description: String, image: String, traits:{ String: String})
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	struct CarClubMetadata{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let image: String
		
		access(all)
		let traits:{ String: String}
		
		init(id: UInt64, name: String, description: String, image: String, traits:{ String: String}){ 
			self.id = id
			self.name = name
			self.description = description
			self.image = image
			self.traits = traits
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		var image: String
		
		access(all)
		let traits:{ String: String}
		
		init(id: UInt64, name: String, description: String, image: String, traits:{ String: String}){ 
			self.id = id
			self.name = name
			self.description = description
			self.image = image
			self.traits = traits
		}
		
		access(all)
		fun revealThumbnail(){ 
			let urlBase = self.image.slice(from: 0, upTo: 47)
			let newImage = urlBase.concat(self.id.toString()).concat(".png")
			self.image = newImage
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.NFTView>(), Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<CarClub.CarClubMetadata>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.IPFSFile(cid: self.image, path: nil))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://driverz.world")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: CarClub.CollectionStoragePath, publicPath: CarClub.CollectionPublicPath, publicCollection: Type<&Collection>(), publicLinkedType: Type<&Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-CarClub.createEmptyCollection(nftType: Type<@CarClub.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://driverzinc.io/DriverzNFT-logo.png"), mediaType: "image")
					let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://driverzinc.io/DriverzNFT-logo.png"), mediaType: "image")
					return MetadataViews.NFTCollectionDisplay(name: "CarClub", description: "CarClub Collection", externalURL: MetadataViews.ExternalURL("https://driverz.world"), squareImage: squareMedia, bannerImage: bannerMedia, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/DriverzWorld/"), "discord": MetadataViews.ExternalURL("https://discord.gg/driverz"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/driverzworld/")})
				case Type<CarClub.CarClubMetadata>():
					return CarClub.CarClubMetadata(id: self.id, name: self.name, description: self.description, image: self.image, traits: self.traits)
				case Type<MetadataViews.NFTView>():
					let viewResolver = &self as &{ViewResolver.Resolver}
					return MetadataViews.NFTView(id: self.id, uuid: self.uuid, display: MetadataViews.getDisplay(viewResolver), externalURL: MetadataViews.getExternalURL(viewResolver), collectionData: MetadataViews.getNFTCollectionData(viewResolver), collectionDisplay: MetadataViews.getNFTCollectionDisplay(viewResolver), royalties: MetadataViews.getRoyalties(viewResolver), traits: MetadataViews.getTraits(viewResolver))
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
				case Type<MetadataViews.Traits>():
					let traits: [MetadataViews.Trait] = []
					for trait in self.traits.keys{ 
						traits.append(MetadataViews.Trait(name: trait, value: self.traits[trait]!, displayType: nil, rarity: nil))
					}
					return MetadataViews.Traits(traits)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowCarClub(id: UInt64): &CarClub.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow CarClub reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @CarClub.NFT
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
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let mainNFT = nft as! &CarClub.NFT
			return mainNFT
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowCarClub(id: UInt64): &CarClub.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &CarClub.NFT
			} else{ 
				return nil
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, image: String, traits:{ String: String}){ 
			emit CarClubMinted(id: CarClub.totalSupply, name: name, description: description, image: image, traits: traits)
			CarClub.totalSupply = CarClub.totalSupply + 1 as UInt64
			recipient.deposit(token: <-create CarClub.NFT(id: CarClub.totalSupply, name: name, description: description, image: image, traits: traits))
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/CarClubCollection
		self.CollectionPublicPath = /public/CarClubCollection
		self.CollectionPrivatePath = /private/CarClubCollection
		self.AdminStoragePath = /storage/CarClubMinter
		self.totalSupply = 0
		let minter <- create Admin()
		self.account.storage.save(<-minter, to: self.AdminStoragePath)
		let collection <- CarClub.createEmptyCollection(nftType: Type<@CarClub.Collection>())
		self.account.storage.save(<-collection, to: CarClub.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&CarClub.Collection>(CarClub.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: CarClub.CollectionPublicPath)
		emit ContractInitialized()
	}
}
