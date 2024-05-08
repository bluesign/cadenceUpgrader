import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

//Wow! You are viewing LimitlessCube TicketComponent contract.
access(all)
contract LCubeTicketComponent: NonFungibleToken{ 
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
		let eventID: UInt64
		
		access(self)
		let metadata:{ String: String}
		
		access(self)
		let seedBlock: UInt64
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		init(id: UInt64, eventID: UInt64, metadata:{ String: String}, royalties: [MetadataViews.Royalty]){ 
			self.id = id
			self.eventID = eventID
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
					let editionInfo = MetadataViews.Edition(name: "LimitlessCube Ticket Edition", number: self.id, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://limitlesscube.io/flow/".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: LCubeTicketComponent.CollectionStoragePath, publicPath: LCubeTicketComponent.CollectionPublicPath, publicCollection: Type<&LCubeTicketComponent.Collection>(), publicLinkedType: Type<&LCubeTicketComponent.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-LCubeTicketComponent.createEmptyCollection(nftType: Type<@LCubeTicketComponent.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://limitlesscube.io/images/logo.svg"), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "The LimitlessCube Collection", description: "This collection is used as an LimitlessCube to help you develop your next Flow NFT.", externalURL: MetadataViews.ExternalURL("https://limitlesscube.io/flow/MetadataViews"), squareImage: media, bannerImage: media, socials:{ "x": MetadataViews.ExternalURL("https://x.com/limitlesscube")})
				case Type<MetadataViews.Traits>():
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: ["name", "description", "image", "thumbnail", "nftType", "eventName"])
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
	resource interface LCubeTicketComponentCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowComponent(id: UInt64): &LCubeTicketComponent.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Component reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: LCubeTicketComponentCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @LCubeTicketComponent.NFT
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
		fun borrowComponent(id: UInt64): &LCubeTicketComponent.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &LCubeTicketComponent.NFT
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
			let componentNFT = nft as! &LCubeTicketComponent.NFT
			return componentNFT
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
		fun createComponent(eventID: UInt64, metadata:{ String: String}, royalties: [MetadataViews.Royalty]): @LCubeTicketComponent.NFT{ 
			var component <- create NFT(id: LCubeTicketComponent.totalSupply, eventID: eventID, metadata: metadata, royalties: royalties)
			LCubeTicketComponent.totalSupply = LCubeTicketComponent.totalSupply + 1
			emit Created(id: component.id, metadata: metadata)
			return <-component
		}
		
		access(all)
		fun batchCreateComponents(eventID: UInt64, metadata:{ String: String}, royalties: [MetadataViews.Royalty], quantity: UInt8): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt8 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.createComponent(eventID: eventID, metadata: metadata, royalties: royalties))
				i = i + 1
			}
			return <-newCollection
		}
	}
	
	// pub fun minter(minterAccount:AuthAccount): Capability<&ComponentMinter> {
	//	  return self.account.getCapability<&ComponentMinter>(self.MinterPublicPath)	  
	//  }
	init(){ 
		self.CollectionPublicPath = /public/LCubeTicketComponentCollection
		self.CollectionStoragePath = /storage/LCubeTicketComponentCollection
		self.MinterPublicPath = /public/LCubeTicketComponentMinter
		self.MinterStoragePath = /storage/LCubeTicketComponentMinter
		self.totalSupply = 0
		self.account.storage.save<@{NonFungibleToken.Collection}>(<-LCubeTicketComponent.createEmptyCollection(nftType: Type<@LCubeTicketComponent.Collection>()), to: LCubeTicketComponent.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{LCubeTicketComponent.LCubeTicketComponentCollectionPublic}>(LCubeTicketComponent.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: LCubeTicketComponent.CollectionPublicPath)
		let minter <- create ComponentMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		var capability_2 = self.account.capabilities.storage.issue<&ComponentMinter>(self.MinterStoragePath)
		self.account.capabilities.publish(capability_2, at: self.MinterPublicPath)
		emit ContractInitialized()
	}
}
