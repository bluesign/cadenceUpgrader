import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract TobiraNeko: NonFungibleToken{ 
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
	event Mint(id: UInt64, creator: Address, metadata:{ String: String})
	
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
					return MetadataViews.Display(name: self.metadata["name"] ?? "", description: self.metadata["description"] ?? "", thumbnail: MetadataViews.HTTPFile(url: self.metadata["thumbnail"] ?? ""))
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
			let token <- token as! @TobiraNeko.NFT
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
			return (ref as! &TobiraNeko.NFT).getMetadata()
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
			let token <- create NFT(id: TobiraNeko.totalSupply, creator: creator.address, metadata: metadata)
			TobiraNeko.totalSupply = TobiraNeko.totalSupply + 1
			let tokenRef = &token as &{NonFungibleToken.NFT}
			(			 // emit Mint(id: token.id, creator: creator.address, metadata: metadata)
			 creator.borrow()!).deposit(token: <-token)
			return tokenRef
		}
		
		access(all)
		fun batchMintTo(creator: Capability<&{NonFungibleToken.Receiver}>, quantity: UInt64): UInt64{ 
			var i: UInt64 = 0
			while i < quantity{ 
				let id = TobiraNeko.totalSupply.toString()
				let idLength = id.length
				let formattedId = "00000".concat(id).slice(from: idLength, upTo: idLength + 5)
				self.mintTo(creator: creator, metadata:{ "name": "TOBIRA NEKO #".concat(formattedId), "description": "", "thumbnail": "https://storage.googleapis.com/tobiratory-media/nft/tobiraneko/".concat(id).concat(".png"), "metaURI": "https://nft.tobiratory.com/metadata/".concat(id)})
				i = i + UInt64(1)
			}
			return quantity
		}
	}
	
	// pub fun minter(): Capability<&Minter> {
	//	 return self.account.getCapability<&Minter>(self.minterPublicPath)
	// }
	init(){ 
		self.totalSupply = 0
		self.collectionPublicPath = /public/TobiraNekoCollection001
		self.collectionStoragePath = /storage/TobiraNekoCollection001
		// self.minterPublicPath = /public/TobiraNekoMinter001
		self.minterStoragePath = /storage/TobiraNekoMinter001
		if self.account.storage.borrow<&Minter>(from: self.minterStoragePath) == nil{ 
			let minter <- create Minter()
			self.account.storage.save(<-minter, to: self.minterStoragePath)
		}
		if self.account.storage.borrow<&TobiraNeko.Collection>(from: TobiraNeko.collectionStoragePath) == nil{ 
			let collection <- self.createEmptyCollection(nftType: Type<@Collection>())
			self.account.storage.save(<-collection, to: self.collectionStoragePath)
			var capability_1 = self.account.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic, TobiraNeko.CollectionPublic, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(self.collectionStoragePath)
			self.account.capabilities.publish(capability_1, at: self.collectionPublicPath)
		}
		emit ContractInitialized()
	}
}
