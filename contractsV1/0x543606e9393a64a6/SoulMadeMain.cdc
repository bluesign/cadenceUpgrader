import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import SoulMadeComponent from "./SoulMadeComponent.cdc"

access(all)
contract SoulMadeMain: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event SoulMadeMainCollectionCreated()
	
	access(all)
	event SoulMadeMainCreated(id: UInt64, series: String)
	
	access(all)
	event NameSet(id: UInt64, name: String)
	
	access(all)
	event DescriptionSet(id: UInt64, description: String)
	
	access(all)
	event IpfsHashSet(id: UInt64, ipfsHash: String)
	
	access(all)
	event MainComponentUpdated(mainNftId: UInt64)
	
	access(all)
	struct MainDetail{ 
		access(all)
		let id: UInt64
		
		access(all)
		var name: String
		
		access(all)
		let series: String
		
		access(all)
		var description: String
		
		access(all)
		var ipfsHash: String
		
		access(all)
		var componentDetails: [SoulMadeComponent.ComponentDetail]
		
		init(id: UInt64, name: String, series: String, description: String, ipfsHash: String, componentDetails: [SoulMadeComponent.ComponentDetail]){ 
			self.id = id
			self.name = name
			self.series = series
			self.description = description
			self.ipfsHash = ipfsHash
			self.componentDetails = componentDetails
		}
	}
	
	access(all)
	resource interface MainPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let mainDetail: MainDetail
		
		access(all)
		fun getAllComponentDetail():{ String: SoulMadeComponent.ComponentDetail}
	}
	
	access(all)
	resource interface MainPrivate{ 
		access(all)
		fun setName(_ name: String)
		
		access(all)
		fun setDescription(_ description: String)
		
		access(all)
		fun setIpfsHash(_ ipfsHash: String)
		
		access(all)
		fun withdrawComponent(category: String): @SoulMadeComponent.NFT?
		
		access(all)
		fun depositComponent(componentNft: @SoulMadeComponent.NFT): @SoulMadeComponent.NFT?
	}
	
	access(all)
	resource NFT: MainPublic, MainPrivate, NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let mainDetail: MainDetail
		
		access(self)
		var components: @{String: SoulMadeComponent.NFT}
		
		init(id: UInt64, series: String){ 
			self.id = id
			self.mainDetail = MainDetail(id: id, name: "", series: series, description: "", ipfsHash: "", componentDetails: [])
			self.components <-{} 
		}
		
		access(all)
		fun getAllComponentDetail():{ String: SoulMadeComponent.ComponentDetail}{ 
			var info:{ String: SoulMadeComponent.ComponentDetail} ={} 
			for categoryKey in self.components.keys{ 
				let componentRef = &self.components[categoryKey] as &SoulMadeComponent.NFT?
				let detail = componentRef.componentDetail
				info[categoryKey] = detail
			}
			return info
		}
		
		access(all)
		fun withdrawComponent(category: String): @SoulMadeComponent.NFT{ 
			let componentNft <- self.components.remove(key: category)!
			self.mainDetail.componentDetails = self.getAllComponentDetail().values
			emit MainComponentUpdated(mainNftId: self.id)
			return <-componentNft
		}
		
		access(all)
		fun depositComponent(componentNft: @SoulMadeComponent.NFT): @SoulMadeComponent.NFT?{ 
			let category: String = componentNft.componentDetail.category
			var old <- self.components[category] <- componentNft
			self.mainDetail.componentDetails = self.getAllComponentDetail().values
			emit MainComponentUpdated(mainNftId: self.id)
			return <-old
		}
		
		access(all)
		fun setName(_ name: String){ 
			pre{ 
				name.length > 2:
					"The name is too short"
				name.length < 100:
					"The name is too long"
			}
			self.mainDetail.name = name
			emit NameSet(id: self.id, name: name)
		}
		
		access(all)
		fun setDescription(_ description: String){ 
			pre{ 
				description.length > 2:
					"The descripton is too short"
				description.length < 500:
					"The description is too long"
			}
			self.mainDetail.description = description
			emit DescriptionSet(id: self.id, description: description)
		}
		
		access(all)
		fun setIpfsHash(_ ipfsHash: String){ 
			self.mainDetail.ipfsHash = ipfsHash
			emit IpfsHashSet(id: self.id, ipfsHash: ipfsHash)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.mainDetail.name, description: self.mainDetail.description, thumbnail: MetadataViews.IPFSFile(cid: self.mainDetail.ipfsHash, path: nil))
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
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowMain(id: UInt64): &{SoulMadeMain.MainPublic}
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
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing Main NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @SoulMadeMain.NFT
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
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		access(all)
		fun borrowMain(id: UInt64): &{SoulMadeMain.MainPublic}{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Main NFT doesn't exist"
			}
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &SoulMadeMain.NFT
		}
		
		access(all)
		fun borrowMainPrivate(id: UInt64): &{SoulMadeMain.MainPrivate}{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Main NFT doesn't exist"
			}
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &SoulMadeMain.NFT
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			let mainNFT = nft as! &SoulMadeMain.NFT
			return mainNFT as &{ViewResolver.Resolver}
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
		emit SoulMadeMainCollectionCreated()
		return <-create Collection()
	}
	
	access(all)
	fun mintMain(series: String): @NFT{ 
		var new <- create NFT(id: SoulMadeMain.totalSupply, series: series)
		emit SoulMadeMainCreated(id: SoulMadeMain.totalSupply, series: series)
		SoulMadeMain.totalSupply = SoulMadeMain.totalSupply + 1
		return <-new
	}
	
	init(){ 
		self.totalSupply = 0
		self.CollectionPublicPath = /public/SoulMadeMainCollection
		self.CollectionStoragePath = /storage/SoulMadeMainCollection
		self.CollectionPrivatePath = /private/SoulMadeMainCollection
		emit ContractInitialized()
	}
}
