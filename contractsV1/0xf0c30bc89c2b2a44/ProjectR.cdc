import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract ProjectR: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let nftId: UInt64
		
		access(all)
		let nftType: String
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let endpoint: String
		
		access(self)
		let metadata:{ String: AnyStruct}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					let royaltyReceiver: Capability<&{FungibleToken.Receiver}> = getAccount(0xf0c30bc89c2b2a44).capabilities.get<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())!
					let royalty = MetadataViews.Royalty(receiver: royaltyReceiver, cut: 0.0, description: "No Royalties")
					return MetadataViews.Royalties([royalty])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://market.raidersrumble.io")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: ProjectR.CollectionStoragePath, publicPath: ProjectR.CollectionPublicPath, publicCollection: Type<&ProjectR.Collection>(), publicLinkedType: Type<&ProjectR.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-ProjectR.createEmptyCollection(nftType: Type<@ProjectR.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://dtz22sdwncfa9.cloudfront.net/NFT-Flow-Resource/AmSulRXn_400x400.jpg"), mediaType: "image/jpg")
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://dtz22sdwncfa9.cloudfront.net/NFT-Flow-Resource/raider_rumble.jpg"), mediaType: "image/jpg")
					return MetadataViews.NFTCollectionDisplay(name: "Raiders Rumble", description: "Raiders Rumble is the ultimate 1v1 squad-battler for mobile. Players take hold of Raiders from the past and future, pulling them into our present world to engage in battles and prestigious tournaments. Only 1000 digital collectibles will be minted for each Raider and only a selected amount will be released periodically for sale. The digital collectibles will grant the owners unique benefits inside and outside of the game.", externalURL: MetadataViews.ExternalURL("https://market.raidersrumble.io"), squareImage: squareImage, bannerImage: bannerImage, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/raidersrumble"), "discord": MetadataViews.ExternalURL("https://discord.com/invite/raidersrumble")})
				case Type<MetadataViews.Traits>():
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: nil)
					return traitsView
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(nftId: UInt64, nftType: String, name: String, description: String, thumbnail: String, endpoint: String, metadata:{ String: AnyStruct}){ 
			self.id = ProjectR.totalSupply
			self.nftId = nftId
			self.nftType = nftType
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.endpoint = endpoint
			self.metadata = metadata
			ProjectR.totalSupply = ProjectR.totalSupply + 1
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowProjectR(id: UInt64): &ProjectR.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow ProjectR reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("This NFT does not exist")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @ProjectR.NFT
			let id: UInt64 = token.id
			self.ownedNFTs[id] <-! token
			emit Deposit(id: id, to: self.owner?.address)
		}
		
		access(all)
		fun burnNFT(id: UInt64){ 
			let token <- self.ownedNFTs.remove(key: id) ?? panic("This NFT does not exist")
			emit Withdraw(id: token.id, from: Address(0x0))
			destroy token
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
		fun borrowProjectR(id: UInt64): &ProjectR.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &ProjectR.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let ProjectR = nft as! &ProjectR.NFT
			return ProjectR as &{ViewResolver.Resolver}
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
	resource NFTMinter{ 
		access(all)
		fun mintNFT(nftId: UInt64, nftType: String, name: String, description: String, thumbnail: String, endpoint: String): @NFT{ 
			let metadata:{ String: AnyStruct} ={} 
			let currentBlock = getCurrentBlock()
			metadata["mintedBlock"] = currentBlock.height
			metadata["mintedTime"] = currentBlock.timestamp
			return <-create NFT(nftId: nftId, nftType: nftType, name: name, description: description, thumbnail: thumbnail, endpoint: endpoint, metadata: metadata)
		}
	}
	
	init(){ 
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/ProjectRCollection
		self.CollectionPublicPath = /public/ProjectRCollection
		self.MinterStoragePath = /storage/ProjectRMinter
		self.account.storage.save(<-create NFTMinter(), to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
