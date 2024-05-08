import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract ProvineerV1: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let ProvineerV1AdminStoragePath: StoragePath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event ProvineerV1Created(id: UInt64, name: String, version: String, description: String, signature: String)
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let certificate_id: String
		
		access(all)
		let name: String
		
		access(all)
		let version: String
		
		access(all)
		let description: String
		
		access(all)
		let url: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let main_sha256: String
		
		access(all)
		let proofs_sha256: String
		
		access(all)
		let email_sha256: String
		
		access(all)
		let email_salt: String
		
		access(all)
		let signature: String
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://www.provineer.com/")
				case Type<MetadataViews.NFTCollectionDisplay>():
					let mediaSquare = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://global-uploads.webflow.com/60f008ba9757da0940af288e/62e77af588325131a9aa8e61_4BFJowii_400x400.jpeg"), mediaType: "image/svg+xml")
					let mediaBanner = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://www.provineer.com/static/logo-full-dark@2x-0e8797bb751b2fcb15c6c1227ca7b3b6.png"), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "Provineer", description: "Authenticate anything, anytime, anywhere.", externalURL: MetadataViews.ExternalURL("https://www.provineer.com/"), squareImage: mediaSquare, bannerImage: mediaBanner, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/provineer")})
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: ProvineerV1.CollectionStoragePath, publicPath: ProvineerV1.CollectionPublicPath, publicCollection: Type<&ProvineerV1.Collection>(), publicLinkedType: Type<&ProvineerV1.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-ProvineerV1.createEmptyCollection(nftType: Type<@ProvineerV1.Collection>())
						})
				case Type<MetadataViews.Traits>():
					let traits: [MetadataViews.Trait] = []
					traits.append(MetadataViews.Trait(name: "File Version", value: self.version, displayType: nil, rarity: nil))
					return MetadataViews.Traits(traits)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(certificate_id: String, name: String, version: String, description: String, url: String, thumbnail: String, main_sha256: String, proofs_sha256: String, email_sha256: String, email_salt: String, signature: String){ 
			self.id = self.uuid
			self.certificate_id = certificate_id
			self.name = name
			self.version = version
			self.description = description
			self.url = url
			self.thumbnail = thumbnail
			self.main_sha256 = main_sha256
			self.proofs_sha256 = proofs_sha256
			self.email_sha256 = email_sha256
			self.email_salt = email_salt
			self.signature = signature
		}
	}
	
	access(all)
	resource interface ProvineerV1CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowProvineerV1(id: UInt64): &ProvineerV1.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Provineer reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: ProvineerV1CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @ProvineerV1.NFT
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
		fun borrowProvineerV1(id: UInt64): &ProvineerV1.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &ProvineerV1.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let provineer = nft as! &ProvineerV1.NFT
			return provineer as &{ViewResolver.Resolver}
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
	resource ProvineerV1Admin{ 
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, certificate_id: String, name: String, version: String, description: String, url: String, thumbnail: String, main_sha256: String, proofs_sha256: String, email_sha256: String, email_salt: String, signature: String){ 
			recipient.deposit(token: <-create ProvineerV1.NFT(certificate_id: certificate_id, name: name, version: version, description: description, url: url, thumbnail: thumbnail, main_sha256: main_sha256, proofs_sha256: proofs_sha256, email_sha256: email_sha256, email_salt: email_salt, signature: signature))
			emit ProvineerV1Created(id: self.uuid, name: name, version: version, description: description, signature: signature)
			ProvineerV1.totalSupply = ProvineerV1.totalSupply + 1 as UInt64
		}
	}
	
	init(){ 
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/provineerV1Collection
		self.CollectionPublicPath = /public/provineerV1Collection
		self.ProvineerV1AdminStoragePath = /storage/provineerV1Admin
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&ProvineerV1.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		let minter <- create ProvineerV1Admin()
		self.account.storage.save(<-minter, to: self.ProvineerV1AdminStoragePath)
		emit ContractInitialized()
	}
}
