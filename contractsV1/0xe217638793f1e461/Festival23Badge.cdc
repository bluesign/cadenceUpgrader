import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Festival23Badge: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	/***********************************************/
	/******************** PATHS ********************/
	/***********************************************/
	access(all)
	var collectionPublicPath: PublicPath
	
	access(all)
	var collectionStoragePath: StoragePath
	
	// pub var minterPublicPath: PublicPath
	access(all)
	var minterStoragePath: StoragePath
	
	/************************************************/
	/******************** EVENTS ********************/
	/************************************************/
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64, creator: Address, metadata:{ String: String}, totalSupply: UInt64)
	
	access(all)
	event Destroy(id: UInt64)
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let creator: Address
		
		access(self)
		let metadata:{ String: String}
		
		init(id: UInt64, creator: Address, metadata:{ String: String}){ 
			self.id = id
			self.creator = creator
			self.metadata = metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.metadata["name"] ?? "", description: self.metadata["description"] ?? "", thumbnail: MetadataViews.HTTPFile(url: self.metadata["metaURI"] ?? ""))
			}
			return nil
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun borrow(id: UInt64): &NFT?
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, CollectionPublic{ 
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
			let token <- token as! @Festival23Badge.NFT
			let id: UInt64 = token.id
			let dummy <- self.ownedNFTs[id] <- token
			destroy dummy
		// emit Deposit(id: id, to: self.owner?.address)
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
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let authRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let ref = authRef as! &NFT
			return ref as! &{ViewResolver.Resolver}
		}
		
		access(all)
		fun borrow(id: UInt64): &NFT?{ 
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return ref as! &NFT
		}
		
		access(all)
		fun getMetadata(id: UInt64):{ String: String}{ 
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return (ref as! &Festival23Badge.NFT).getMetadata()
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
	resource Minter{ 
		access(all)
		fun mintTo(creator: Capability<&{NonFungibleToken.Receiver}>, metadata:{ String: String}): &{NonFungibleToken.NFT}{ 
			let id = Festival23Badge.totalSupply.toString()
			let meta ={ "name": metadata["name"] ?? "", "description": metadata["description"] ?? "", "metaURI": "https://nft.tobiratory.com/festival23badge/metadata/".concat(id)}
			let token <- create NFT(id: Festival23Badge.totalSupply, creator: creator.address, metadata: meta)
			Festival23Badge.totalSupply = Festival23Badge.totalSupply + 1
			let tokenRef = &token as &{NonFungibleToken.NFT}
			emit Mint(id: token.id, creator: creator.address, metadata: meta, totalSupply: Festival23Badge.totalSupply)
			(creator.borrow()!).deposit(token: <-token)
			return tokenRef
		}
	}
	
	// pub fun minter(): Capability<&Minter> {
	//	 return self.account.getCapability<&Minter>(self.minterPublicPath)
	// }
	init(){ 
		self.totalSupply = 0
		self.collectionPublicPath = /public/Festival23Badge
		self.collectionStoragePath = /storage/Festival23Badge
		// self.minterPublicPath = /public/Festival23BadgeMinter
		self.minterStoragePath = /storage/Festival23BadgeMinter
		if self.account.storage.borrow<&Minter>(from: self.minterStoragePath) == nil{ 
			let minter <- create Minter()
			self.account.storage.save(<-minter, to: self.minterStoragePath)
		}
		if self.account.storage.borrow<&Festival23Badge.Collection>(from: Festival23Badge.collectionStoragePath) == nil{ 
			let collection <- self.createEmptyCollection(nftType: Type<@Collection>())
			self.account.storage.save(<-collection, to: self.collectionStoragePath)
			var capability_1 = self.account.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic, Festival23Badge.CollectionPublic, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(self.collectionStoragePath)
			self.account.capabilities.publish(capability_1, at: self.collectionPublicPath)
		}
		emit ContractInitialized()
	}
}
