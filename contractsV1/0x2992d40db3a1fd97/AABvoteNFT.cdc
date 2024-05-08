import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract AABvoteNFT: NonFungibleToken{ 
	access(all)
	let mintedNFTs:{ UInt64: MintedNFT}
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, candidateId: String, name: String, description: String, thumbnail: String, rarity: UInt8, metadata:{ String: String}, to: Address)
	
	access(all)
	event Destroy(id: UInt64)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	enum Rarity: UInt8{ 
		access(all)
		case common
		
		access(all)
		case iconic
	}
	
	access(all)
	struct MintedNFT{ 
		access(all)
		let used: Bool
		
		access(all)
		let ownerMinted: Address
		
		init(used: Bool, ownerMinted: Address){ 
			self.used = used
			self.ownerMinted = ownerMinted
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let candidateId: String
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let rarity: UInt8
		
		access(all)
		let metadata:{ String: String}
		
		init(id: UInt64, candidateId: String, name: String, description: String, thumbnail: String, rarity: UInt8, metadata:{ String: String}){ 
			self.id = id
			self.candidateId = candidateId
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.rarity = rarity
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
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface AABvoteNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowAABvoteNFT(id: UInt64): &AABvoteNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow AABvoteNFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: AABvoteNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @AABvoteNFT.NFT
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
		fun borrowAABvoteNFT(id: UInt64): &AABvoteNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &AABvoteNFT.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let AABvoteNFT = nft as! &AABvoteNFT.NFT
			return AABvoteNFT as &{ViewResolver.Resolver}
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, candidateId: String, name: String, description: String, thumbnail: String, rarity: UInt8, metadata:{ String: String}){ 
			var newNFT <- create NFT(id: AABvoteNFT.totalSupply, candidateId: candidateId, name: name, description: description, thumbnail: thumbnail, rarity: rarity, metadata: metadata)
			recipient.deposit(token: <-newNFT)
			AABvoteNFT.mintedNFTs[AABvoteNFT.totalSupply] = MintedNFT(used: false, ownerMinted: (recipient.owner!).address)
			emit Minted(id: AABvoteNFT.totalSupply, candidateId: candidateId, name: name, description: description, thumbnail: thumbnail, rarity: rarity, metadata: metadata, to: (recipient.owner!).address)
			AABvoteNFT.totalSupply = AABvoteNFT.totalSupply + UInt64(1)
		}
	}
	
	access(all)
	fun getCollection(_ from: Address): &Collection{ 
		let collection = (getAccount(from).capabilities.get<&AABvoteNFT.Collection>(AABvoteNFT.CollectionPublicPath)!).borrow() ?? panic("Could not borrow capability from public collection")
		return collection
	}
	
	access(all)
	fun getNFT(_ from: Address, id: UInt64): &AABvoteNFT.NFT?{ 
		let collection = self.getCollection(from)
		return collection.borrowAABvoteNFT(id: id)
	}
	
	access(account)
	fun setUsedNFT(id: UInt64, used: Bool){ 
		pre{ 
			AABvoteNFT.mintedNFTs.containsKey(id):
				"NFT does not exist"
		}
		AABvoteNFT.mintedNFTs[id] = MintedNFT(used: used, ownerMinted: (AABvoteNFT.mintedNFTs[id]!).ownerMinted)
	}
	
	access(all)
	resource Administrator{ 
		access(all)
		fun createNFTMinter(): @NFTMinter{ 
			return <-create NFTMinter()
		}
	}
	
	init(){ 
		self.mintedNFTs ={} 
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/AABvoteNFTCollectionV1
		self.CollectionPublicPath = /public/AABvoteNFTCollectionV1
		self.MinterStoragePath = /storage/AABvoteNFTMinterV1
		self.AdminStoragePath = /storage/AABvoteNFTAdminV1
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&AABvoteNFT.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		let admin <- create Administrator()
		self.account.storage.save<@Administrator>(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
