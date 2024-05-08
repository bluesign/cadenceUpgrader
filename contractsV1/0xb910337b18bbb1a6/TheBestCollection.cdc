import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract TheBestCollection: NonFungibleToken{ 
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
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let metadata:{ String: AnyStruct}
		
		init(id: UInt64, name: String, description: String, thumbnail: String, metadata:{ String: AnyStruct}){ 
			self.id = id
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
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
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface TheBestCollectionCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
	}
	
	access(all)
	resource Collection: TheBestCollectionCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @TheBestCollection.NFT
			let id: UInt64 = token.id
			let oldToken: @{NonFungibleToken.NFT}? <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let TheBestCollection = nft as! &TheBestCollection.NFT
			return TheBestCollection as &{ViewResolver.Resolver}
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
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, thumbnail: String, metadata:{ String: AnyStruct}){ 
			var newNFT <- create NFT(id: TheBestCollection.totalSupply, name: name, description: description, thumbnail: thumbnail, metadata: metadata)
			recipient.deposit(token: <-newNFT)
			TheBestCollection.totalSupply = TheBestCollection.totalSupply + 1
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: TheBestCollection.CollectionStoragePath, publicPath: TheBestCollection.CollectionPublicPath, publicCollection: Type<&TheBestCollection.Collection>(), publicLinkedType: Type<&TheBestCollection.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-TheBestCollection.createEmptyCollection(nftType: Type<@TheBestCollection.Collection>())
						})
			}
			return nil
		}
	}
	
	/// Function that returns all the Metadata Views implemented by a Non Fungible Token
	///
	/// @return An array of Types defining the implemented views. This value will be used by
	///		 developers to know which parameter to pass to the resolveView() method.
	///
	access(all)
	fun getViews(): [Type]{ 
		return [Type<MetadataViews.NFTCollectionData>()]
	}
	
	init(){ 
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/TheBestCollectionCollection
		self.CollectionPublicPath = /public/TheBestCollectionCollection
		self.MinterStoragePath = /storage/TheBestCollectionMinter
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&TheBestCollection.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
