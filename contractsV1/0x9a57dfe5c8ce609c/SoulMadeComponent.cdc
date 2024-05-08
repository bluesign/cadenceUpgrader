import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract SoulMadeComponent: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event SoulMadeComponentCollectionCreated()
	
	access(all)
	event SoulMadeComponentCreated(componentDetail: ComponentDetail)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	struct ComponentDetail{ 
		access(all)
		let id: UInt64
		
		access(all)
		let series: String
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let category: String
		
		access(all)
		let layer: UInt64
		
		access(all)
		let edition: UInt64
		
		access(all)
		let maxEdition: UInt64
		
		access(all)
		let ipfsHash: String
		
		init(id: UInt64, series: String, name: String, description: String, category: String, layer: UInt64, edition: UInt64, maxEdition: UInt64, ipfsHash: String){ 
			self.id = id
			self.series = series
			self.name = name
			self.description = description
			self.category = category
			self.layer = layer
			self.edition = edition
			self.maxEdition = maxEdition
			self.ipfsHash = ipfsHash
		}
	}
	
	access(all)
	resource interface ComponentPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let componentDetail: ComponentDetail
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ComponentPublic, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let componentDetail: ComponentDetail
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.componentDetail.name, description: self.componentDetail.description, thumbnail: MetadataViews.IPFSFile(cid: self.componentDetail.ipfsHash, path: nil))
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: getAccount(0x9a57dfe5c8ce609c).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver), cut: 0.00, description: "SoulMade Component Royalties")])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://soulmade.art")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: SoulMadeComponent.CollectionStoragePath, publicPath: SoulMadeComponent.CollectionPublicPath, publicCollection: Type<&Collection>(), publicLinkedType: Type<&Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-SoulMadeComponent.createEmptyCollection(nftType: Type<@SoulMadeComponent.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://i.imgur.com/XgqDY3s.jpg"), mediaType: "image")
					let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://i.imgur.com/yBw3ktk.png"), mediaType: "image")
					return MetadataViews.NFTCollectionDisplay(name: "SoulMadeComponent", description: "SoulMade Component Collection", externalURL: MetadataViews.ExternalURL("https://soulmade.art"), squareImage: squareMedia, bannerImage: bannerMedia, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/soulmade_nft"), "discord": MetadataViews.ExternalURL("https://discord.com/invite/xtqqXCKW9B")})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64, componentDetail: ComponentDetail){ 
			self.id = id
			self.componentDetail = componentDetail
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
		fun borrowComponent(id: UInt64): &{SoulMadeComponent.ComponentPublic}
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing Component NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @SoulMadeComponent.NFT
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
		fun borrowComponent(id: UInt64): &{SoulMadeComponent.ComponentPublic}{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Component NFT doesn't exist"
			}
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return ref as! &SoulMadeComponent.NFT
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let componentNFT = nft as! &SoulMadeComponent.NFT
			return componentNFT as &{ViewResolver.Resolver}
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
		emit SoulMadeComponentCollectionCreated()
		return <-create Collection()
	}
	
	access(account)
	fun makeEdition(series: String, name: String, description: String, category: String, layer: UInt64, currentEdition: UInt64, maxEdition: UInt64, ipfsHash: String): @NFT{ 
		let componentDetail = ComponentDetail(id: SoulMadeComponent.totalSupply, series: series, name: name, description: description, category: category, layer: layer, edition: currentEdition, maxEdition: maxEdition, ipfsHash: ipfsHash)
		var newNFT <- create NFT(id: SoulMadeComponent.totalSupply, componentDetail: componentDetail)
		emit SoulMadeComponentCreated(componentDetail: componentDetail)
		SoulMadeComponent.totalSupply = SoulMadeComponent.totalSupply + UInt64(1)
		return <-newNFT
	}
	
	init(){ 
		self.totalSupply = 0
		self.CollectionPublicPath = /public/SoulMadeComponentCollection
		self.CollectionStoragePath = /storage/SoulMadeComponentCollection
		self.CollectionPrivatePath = /private/SoulMadeComponentCollection
		emit ContractInitialized()
	}
}
