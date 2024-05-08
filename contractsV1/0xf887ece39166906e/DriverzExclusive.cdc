
// Mainnet
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

//Testnet
// import NonFungibleToken from "../0x631e88ae7f1d7c20/NonFungibleToken.cdc"
// import MetadataViews from "../0x631e88ae7f1d7c20/MetadataViews.cdc"
access(all)
contract DriverzExclusive: NonFungibleToken{ 
	
	//Define Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event ExclusiveMinted(id: UInt64, name: String, description: String, image: String, traits:{ String: String})
	
	//Define Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	//Difine Total Supply
	access(all)
	var totalSupply: UInt64
	
	access(all)
	struct driverzExclusiveMetadata{ 
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
		
		init(_id: UInt64, _name: String, _description: String, _image: String, _traits:{ String: String}){ 
			self.id = _id
			self.name = _name
			self.description = _description
			self.image = _image
			self.traits = _traits
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
		
		init(_id: UInt64, _name: String, _description: String, _image: String, _traits:{ String: String}){ 
			self.id = _id
			self.name = _name
			self.description = _description
			self.image = _image
			self.traits = _traits
		}
		
		access(all)
		fun revealThumbnail(){ 
			let urlBase = self.image.slice(from: 0, upTo: 47)
			let newImage = urlBase.concat(self.id.toString()).concat(".png")
			self.image = newImage
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.NFTView>(), Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<DriverzExclusive.driverzExclusiveMetadata>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.IPFSFile(cid: self.image, path: nil))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://driverz.world")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: DriverzExclusive.CollectionStoragePath, publicPath: DriverzExclusive.CollectionPublicPath, publicCollection: Type<&Collection>(), publicLinkedType: Type<&Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-DriverzExclusive.createEmptyCollection(nftType: Type<@DriverzExclusive.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://driverzinc.io/DriverzNFT-logo.png"), mediaType: "image")
					let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://driverzinc.io/DriverzNFT-logo.png"), mediaType: "image")
					return MetadataViews.NFTCollectionDisplay(name: "Driverz Exclusive", description: "Driverz Exclusive Collection", externalURL: MetadataViews.ExternalURL("https://driverz.world"), squareImage: squareMedia, bannerImage: bannerMedia, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/DriverzWorld/"), "discord": MetadataViews.ExternalURL("https://discord.gg/driverz"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/driverzworld/")})
				case Type<DriverzExclusive.driverzExclusiveMetadata>():
					return DriverzExclusive.driverzExclusiveMetadata(_id: self.id, _name: self.name, _description: self.description, _image: self.image, _traits: self.traits)
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
		fun borrowDriverzExclusive(id: UInt64): &DriverzExclusive.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow DriverzExclusive reference: The ID of the returned reference is incorrect."
			}
		}
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an 'UInt64' ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @DriverzExclusive.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let mainNFT = nft as! &DriverzExclusive.NFT
			return mainNFT
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowDriverzExclusive(id: UInt64): &DriverzExclusive.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &DriverzExclusive.NFT
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
			emit ExclusiveMinted(id: DriverzExclusive.totalSupply, name: name, description: description, image: image, traits: traits)
			DriverzExclusive.totalSupply = DriverzExclusive.totalSupply + 1 as UInt64
			recipient.deposit(token: <-create DriverzExclusive.NFT(_id: DriverzExclusive.totalSupply, _name: name, _description: description, _image: image, _traits: traits))
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/DriverzExclusiveCollection
		self.CollectionPublicPath = /public/DriverzExclusiveCollection
		self.CollectionPrivatePath = /private/DriverzExclusiveCollection
		self.AdminStoragePath = /storage/DriverzExclusiveMinter
		self.totalSupply = 0
		let minter <- create Admin()
		self.account.storage.save(<-minter, to: self.AdminStoragePath)
		let collection <- DriverzExclusive.createEmptyCollection(nftType: Type<@DriverzExclusive.Collection>())
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&DriverzExclusive.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
