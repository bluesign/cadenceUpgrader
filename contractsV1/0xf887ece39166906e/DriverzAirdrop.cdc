import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract DriverzAirdrop: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event DriverzAirdropMinted(id: UInt64, name: String, ipfsLink: String)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	struct DriverzAirdropMetadata{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let ipfsLink: String
		
		init(id: UInt64, name: String, description: String, ipfsLink: String){ 
			self.id = id
			self.name = name
			self.description = description
			self.ipfsLink = ipfsLink
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
		var ipfsLink: String
		
		init(initID: UInt64, name: String, description: String, ipfsLink: String){ 
			self.id = initID
			self.name = name
			self.description = description
			self.ipfsLink = ipfsLink
		}
		
		access(all)
		fun revealThumbnail(){ 
			let urlBase = "QmP45SUvQjwfdbsnXMyGf5BiHF51KSmVkvB9QAkRgviLnV/"
			let newImage = urlBase.concat(self.id.toString()).concat(".png")
			self.ipfsLink = newImage
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<DriverzAirdrop.DriverzAirdropMetadata>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.IPFSFile(cid: self.ipfsLink, path: nil))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://driverznftairdrops.io/")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: DriverzAirdrop.CollectionStoragePath, publicPath: DriverzAirdrop.CollectionPublicPath, publicCollection: Type<&Collection>(), publicLinkedType: Type<&Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-DriverzAirdrop.createEmptyCollection(nftType: Type<@DriverzAirdrop.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://driverznftairdrops.io/DriverzNFT-logo.png"), mediaType: "image")
					let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://driverznftairdrops.io/DriverzNFT-logo.png"), mediaType: "image")
					return MetadataViews.NFTCollectionDisplay(name: "DriverzAirdrop", description: "DriverzAirdrop Collection", externalURL: MetadataViews.ExternalURL("https://driverznftairdrops.io/"), squareImage: squareMedia, bannerImage: bannerMedia, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/driverznft"), "discord": MetadataViews.ExternalURL("https://discord.gg/TdxXJEPhhv")})
				case Type<DriverzAirdrop.DriverzAirdropMetadata>():
					return DriverzAirdrop.DriverzAirdropMetadata(id: self.id, name: self.name, description: self.description, ipfsLink: self.ipfsLink)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
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
		fun borrowArt(id: UInt64): &DriverzAirdrop.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow DriverzAirdrop reference: The ID of the returned reference is incorrect"
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
			let token <- token as! @DriverzAirdrop.NFT
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
			let mainNFT = nft as! &DriverzAirdrop.NFT
			return mainNFT as &{ViewResolver.Resolver}
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowArt(id: UInt64): &DriverzAirdrop.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &DriverzAirdrop.NFT
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, ipfsLink: String){ 
			emit DriverzAirdropMinted(id: DriverzAirdrop.totalSupply, name: name, ipfsLink: ipfsLink)
			recipient.deposit(token: <-create DriverzAirdrop.NFT(initID: DriverzAirdrop.totalSupply, name: name, description: description, ipfsLink: ipfsLink))
			DriverzAirdrop.totalSupply = DriverzAirdrop.totalSupply + 1 as UInt64
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/DriverzAirdropCollection
		self.CollectionPublicPath = /public/DriverzAirdropCollection
		self.AdminStoragePath = /storage/DriverzAirdropMinter
		self.totalSupply = 0
		let minter <- create Admin()
		self.account.storage.save(<-minter, to: self.AdminStoragePath)
		let collection <- DriverzAirdrop.createEmptyCollection(nftType: Type<@DriverzAirdrop.Collection>())
		self.account.storage.save(<-collection, to: DriverzAirdrop.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&DriverzAirdrop.Collection>(DriverzAirdrop.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: DriverzAirdrop.CollectionPublicPath)
		emit ContractInitialized()
	}
}
