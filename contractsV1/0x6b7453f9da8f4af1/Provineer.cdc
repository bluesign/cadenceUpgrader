import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Provineer: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let ProvineerAdminStoragePath: StoragePath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event ProvineerCreated(id: UInt64, fileName: String, fileVersion: String, description: String, signature: String)
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let fileName: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let fileVersion: String
		
		access(all)
		let category: String
		
		access(all)
		let description: String
		
		access(all)
		let proof1: String
		
		access(all)
		let proof2: String
		
		access(all)
		let proof3: String
		
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
					return MetadataViews.Display(name: self.fileName, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://www.provineer.com/")
				case Type<MetadataViews.NFTCollectionDisplay>():
					let mediaSquare = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://global-uploads.webflow.com/60f008ba9757da0940af288e/62e77af588325131a9aa8e61_4BFJowii_400x400.jpeg"), mediaType: "image/svg+xml")
					let mediaBanner = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://www.provineer.com/static/logo-full-dark@2x-0e8797bb751b2fcb15c6c1227ca7b3b6.png"), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "Provineer", description: "Authenticate anything, anytime, anywhere.", externalURL: MetadataViews.ExternalURL("https://www.provineer.com/"), squareImage: mediaSquare, bannerImage: mediaBanner, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/provineer")})
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Provineer.CollectionStoragePath, publicPath: Provineer.CollectionPublicPath, publicCollection: Type<&Provineer.Collection>(), publicLinkedType: Type<&Provineer.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Provineer.createEmptyCollection(nftType: Type<@Provineer.Collection>())
						})
				case Type<MetadataViews.Traits>():
					let traits: [MetadataViews.Trait] = []
					traits.append(MetadataViews.Trait(name: "File Version", value: self.fileVersion, displayType: nil, rarity: nil))
					return MetadataViews.Traits(traits)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(fileName: String, thumbnail: String, fileVersion: String, category: String, description: String, proof1: String, proof2: String, proof3: String, signature: String){ 
			self.id = self.uuid
			self.fileName = fileName
			self.thumbnail = thumbnail
			self.fileVersion = fileVersion
			self.category = category
			self.description = description
			self.proof1 = proof1
			self.proof2 = proof2
			self.proof3 = proof3
			self.signature = signature
		}
	}
	
	access(all)
	resource interface ProvineerCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowProvineer(id: UInt64): &Provineer.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Provineer reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: ProvineerCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @Provineer.NFT
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
		fun borrowProvineer(id: UInt64): &Provineer.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Provineer.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let provineer = nft as! &Provineer.NFT
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
	resource ProvineerAdmin{ 
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, fileName: String, thumbnail: String, fileVersion: String, category: String, description: String, proof1: String, proof2: String, proof3: String, signature: String){ 
			recipient.deposit(token: <-create Provineer.NFT(fileName: fileName, thumbnail: thumbnail, fileVersion: fileVersion, category: category, description: description, proof1: proof1, proof2: proof2, proof3: proof3, signature: signature))
			emit ProvineerCreated(id: self.uuid, fileName: fileName, fileVersion: fileVersion, description: description, signature: signature)
			Provineer.totalSupply = Provineer.totalSupply + 1 as UInt64
		}
	}
	
	init(){ 
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/provineerCollection
		self.CollectionPublicPath = /public/provineerCollection
		self.ProvineerAdminStoragePath = /storage/provineerAdmin
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Provineer.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		let minter <- create ProvineerAdmin()
		self.account.storage.save(<-minter, to: self.ProvineerAdminStoragePath)
		emit ContractInitialized()
	}
}
