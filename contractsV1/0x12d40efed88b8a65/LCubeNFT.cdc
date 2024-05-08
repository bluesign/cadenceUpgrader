import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import LCubeExtension from "./LCubeExtension.cdc"

//Wow! You are viewing LimitlessCube NFT token contract.
access(all)
contract LCubeNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterPublicPath: PublicPath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64, setID: UInt64, creator: Address, metadata:{ String: String})
	
	access(all)
	event Destroy(id: UInt64)
	
	access(all)
	event SetCreated(setID: UInt64, creator: Address, metadata:{ String: String})
	
	access(all)
	event NFTAddedToSet(setID: UInt64, nftID: UInt64)
	
	access(all)
	event NFTRetiredFromSet(setID: UInt64, nftID: UInt64)
	
	access(all)
	event SetLocked(setID: UInt64)
	
	access(all)
	fun createMinter(creator: Address, metadata:{ String: String}): @NFTMinter{ 
		assert(metadata.containsKey("setName"), message: "setName property is required for LCubeNFTSet!")
		assert(metadata.containsKey("thumbnail"), message: "thumbnail property is required for LCubeNFTSet!")
		var setName = LCubeExtension.clearSpaceLetter(text: metadata["setName"]!)
		assert(setName.length > 2, message: "setName property is not empty or minimum 3 characters!")
		let storagePath = "LCubeNFTSet_".concat(setName)
		let candidate <- self.account.storage.load<@LCubeNFTSet>(from: StoragePath(identifier: storagePath)!)
		if candidate != nil{ 
			panic(setName.concat(" LCubeNFTSet already created before!"))
		}
		destroy candidate
		var newSet <- create LCubeNFTSet(creatorAddress: creator, metadata: metadata)
		var setID: UInt64 = newSet.uuid
		emit SetCreated(setID: setID, creator: creator, metadata: metadata)
		self.account.storage.save(<-newSet, to: StoragePath(identifier: storagePath)!)
		return <-create NFTMinter(setID: setID)
	}
	
	access(all)
	fun borrowSet(storagePath: StoragePath): &LCubeNFTSet{ 
		return self.account.storage.borrow<&LCubeNFTSet>(from: storagePath)!
	}
	
	access(all)
	resource LCubeNFTSet{ 
		access(all)
		let creatorAddress: Address
		
		access(all)
		let metadata:{ String: String}
		
		init(creatorAddress: Address, metadata:{ String: String}){ 
			self.creatorAddress = creatorAddress
			self.metadata = metadata
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let setID: UInt64
		
		access(all)
		let creator: Address
		
		access(self)
		let metadata:{ String: String}
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		init(id: UInt64, setID: UInt64, creator: Address, metadata:{ String: String}, royalties: [MetadataViews.Royalty]){ 
			self.id = id
			self.setID = setID
			self.creator = creator
			self.royalties = royalties
			self.metadata = metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.metadata["name"] ?? "", description: self.metadata["description"] ?? "", thumbnail: MetadataViews.HTTPFile(url: self.metadata["thumbnail"] ?? ""))
				case Type<MetadataViews.Editions>():
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					let editionInfo = MetadataViews.Edition(name: "LCube NFT Edition", number: self.id, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://limitlesscube.com/".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: LCubeNFT.CollectionStoragePath, publicPath: LCubeNFT.CollectionPublicPath, publicCollection: Type<&LCubeNFT.Collection>(), publicLinkedType: Type<&LCubeNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-LCubeNFT.createEmptyCollection(nftType: Type<@LCubeNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://limitlesscube.com/images/logo.svg"), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "The LCube Collection", description: "This collection is used as an limitlesscube to help you develop your next Flow NFT.", externalURL: MetadataViews.ExternalURL("https://limitlesscube.com"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/limitlesscube")})
				case Type<MetadataViews.Traits>():
					let excludedTraits = ["name", "description", "thumbnail", "uri"]
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)
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
	resource interface LCubeNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowLCubeNFT(id: UInt64): &LCubeNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow LCube reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: LCubeNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @LCubeNFT.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			destroy oldToken
			emit Deposit(id: id, to: self.owner?.address)
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
		fun borrowLCubeNFT(id: UInt64): &LCubeNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &LCubeNFT.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refItem = nft as! &LCubeNFT.NFT
			return refItem
		}
		
		access(all)
		fun borrow(id: UInt64): &NFT?{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &LCubeNFT.NFT
		}
		
		access(all)
		fun getMetadata(id: UInt64):{ String: String}{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return (ref as! &LCubeNFT.NFT).getMetadata()
		}
		
		access(all)
		fun getRoyalties(id: UInt64): [MetadataViews.Royalty]{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return (ref as! &LCubeNFT.NFT).getRoyalties()
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
	resource NFTMinter{ 
		access(self)
		let setID: UInt64
		
		init(setID: UInt64){ 
			self.setID = setID
		}
		
		access(all)
		fun mintNFT(creator: Capability<&{NonFungibleToken.Receiver}>, metadata:{ String: String}, royalties: [MetadataViews.Royalty]): &{NonFungibleToken.NFT}{ 
			assert(metadata.containsKey("nftType"), message: "nftType property is required for LCubeNFT!")
			assert(metadata.containsKey("name"), message: "name property is required for LCubeNFT!")
			assert(metadata.containsKey("description"), message: "description property is required for LCubeNFT!")
			assert(metadata.containsKey("thumbnail"), message: "thumbnail property is required for LCubeNFT!")
			let token <- create NFT(id: LCubeNFT.totalSupply, setID: self.setID, creator: creator.address, metadata: metadata, royalties: royalties)
			LCubeNFT.totalSupply = LCubeNFT.totalSupply + 1
			let tokenRef = &token as &{NonFungibleToken.NFT}
			emit Mint(id: token.id, setID: self.setID, creator: creator.address, metadata: metadata)
			(creator.borrow()!).deposit(token: <-token)
			return tokenRef
		}
	}
	
	init(){ 
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/LCubeNFTCollection
		self.CollectionPublicPath = /public/LCubeNFTCollection
		self.MinterPublicPath = /public/LCubeNFTMinter
		self.MinterStoragePath = /storage/LCubeNFTMinter
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&LCubeNFT.Collection>(LCubeNFT.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: LCubeNFT.CollectionPublicPath)
		emit ContractInitialized()
	}
}
