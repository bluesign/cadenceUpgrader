import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import RandomGenerator from "./RandomGenerator.cdc"

//Wow! You are viewing LimitlessCube Component contract.
access(all)
contract LCubeComponent: NonFungibleToken{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterPublicPath: PublicPath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Created(id: UInt64, metadata:{ String: String})
	
	access(all)
	event Destroy(id: UInt64)
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let gameID: UInt64
		
		access(self)
		let metadata:{ String: String}
		
		access(self)
		let seedBlock: UInt64
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		init(id: UInt64, gameID: UInt64, metadata:{ String: String}, royalties: [MetadataViews.Royalty]){ 
			self.id = id
			self.gameID = gameID
			self.metadata = metadata
			self.royalties = royalties
			self.seedBlock = getCurrentBlock().height + 1
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.metadata["name"] ?? "", description: self.metadata["description"] ?? "", thumbnail: MetadataViews.HTTPFile(url: self.metadata["thumbnail"] ?? ""))
				case Type<MetadataViews.Editions>():
					let editionInfo = MetadataViews.Edition(name: "LimitlessCube NFT Edition", number: self.id, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://limitlesscube.com/flow/".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: LCubeComponent.CollectionStoragePath, publicPath: LCubeComponent.CollectionPublicPath, publicCollection: Type<&LCubeComponent.Collection>(), publicLinkedType: Type<&LCubeComponent.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-LCubeComponent.createEmptyCollection(nftType: Type<@LCubeComponent.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://limitlesscube.com/images/logo.svg"), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "The LimitlessCube Collection", description: "This collection is used as an LimitlessCube to help you develop your next Flow NFT.", externalURL: MetadataViews.ExternalURL("https://limitlesscube.com/flow/MetadataViews"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/limitlesscube")})
				case Type<MetadataViews.Traits>():
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: ["name", "description", "image", "thumbnail", "nftType", "gameName"])
					if getCurrentBlock().height >= self.seedBlock{ 
						let randomizer <- RandomGenerator.createFrom(blockHeight: self.seedBlock, uuid: self.uuid)
						let randomTrait = randomizer.pickWeighted(["legendary", "rare", "common"], [5, 10, 85]) as! String
						traitsView.addTrait(MetadataViews.Trait(name: "rarity", value: randomTrait, displayType: "String", rarity: nil))
						destroy randomizer
					}
					return traitsView
			}
			return nil
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun getRoyalties(): [MetadataViews.Royalty]{ 
			return self.royalties
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface LCubeComponentCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowComponent(id: UInt64): &LCubeComponent.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Component reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: LCubeComponentCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @LCubeComponent.NFT
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
		fun borrowComponent(id: UInt64): &LCubeComponent.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &LCubeComponent.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT does not exist"
			}
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let componentNFT = nft as! &LCubeComponent.NFT
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
		return <-create Collection()
	}
	
	access(all)
	resource ComponentMinter{ 
		access(self)
		fun createComponent(gameID: UInt64, metadata:{ String: String}, royalties: [MetadataViews.Royalty]): @LCubeComponent.NFT{ 
			var packComponent <- create NFT(id: LCubeComponent.totalSupply, gameID: gameID, metadata: metadata, royalties: royalties)
			LCubeComponent.totalSupply = LCubeComponent.totalSupply + 1
			emit Created(id: packComponent.id, metadata: metadata)
			return <-packComponent
		}
		
		access(all)
		fun batchCreateComponents(gameID: UInt64, metadata:{ String: String}, royalties: [MetadataViews.Royalty], quantity: UInt8): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt8 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.createComponent(gameID: gameID, metadata: metadata, royalties: royalties))
				i = i + 1
			}
			return <-newCollection
		}
	}
	
	// pub fun minter(minterAccount:AuthAccount): Capability<&ComponentMinter> {
	//	  return self.account.getCapability<&ComponentMinter>(self.MinterPublicPath)	  
	//  }
	init(){ 
		self.CollectionPublicPath = /public/LCubeComponentCollection
		self.CollectionStoragePath = /storage/LCubeComponentCollection
		self.MinterPublicPath = /public/LCubeComponentMinter
		self.MinterStoragePath = /storage/LCubeComponentMinter
		self.totalSupply = 0
		self.account.storage.save<@{NonFungibleToken.Collection}>(<-LCubeComponent.createEmptyCollection(nftType: Type<@LCubeComponent.Collection>()), to: LCubeComponent.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{LCubeComponent.LCubeComponentCollectionPublic}>(LCubeComponent.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: LCubeComponent.CollectionPublicPath)
		let minter <- create ComponentMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		var capability_2 = self.account.capabilities.storage.issue<&ComponentMinter>(self.MinterStoragePath)
		self.account.capabilities.publish(capability_2, at: self.MinterPublicPath)
		emit ContractInitialized()
	}
}
