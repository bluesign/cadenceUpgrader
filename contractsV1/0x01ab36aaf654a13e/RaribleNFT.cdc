import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import LicensedNFT from "./LicensedNFT.cdc"

// RaribleNFT token contract
//
access(all)
contract RaribleNFT: NonFungibleToken, LicensedNFT{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var collectionPublicPath: PublicPath
	
	access(all)
	var collectionStoragePath: StoragePath
	
	access(all)
	var minterPublicPath: PublicPath
	
	access(all)
	var minterStoragePath: StoragePath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64, creator: Address, metadata:{ String: String}, royalties: [{LicensedNFT.Royalty}])
	
	access(all)
	event Destroy(id: UInt64)
	
	access(all)
	struct Royalty{ 
		access(all)
		let address: Address
		
		access(all)
		let fee: UFix64
		
		init(address: Address, fee: UFix64){ 
			self.address = address
			self.fee = fee
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let creator: Address
		
		access(self)
		let metadata:{ String: String}
		
		access(self)
		let royalties: [{LicensedNFT.Royalty}]
		
		init(id: UInt64, creator: Address, metadata:{ String: String}, royalties: [{LicensedNFT.Royalty}]){ 
			self.id = id
			self.creator = creator
			self.metadata = metadata
			self.royalties = royalties
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
		fun getRoyalties(): [{LicensedNFT.Royalty}]{ 
			return self.royalties
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
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, LicensedNFT.CollectionPublic, CollectionPublic{ 
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
			let token <- token as! @RaribleNFT.NFT
			let id: UInt64 = token.id
			let dummy <- self.ownedNFTs[id] <- token
			destroy dummy
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
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let authRef = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			let ref = authRef as! &NFT
			return ref as! &{ViewResolver.Resolver}
		}
		
		access(all)
		fun borrow(id: UInt64): &NFT?{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &RaribleNFT.NFT
		}
		
		access(all)
		fun getMetadata(id: UInt64):{ String: String}{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return (ref as! &RaribleNFT.NFT).getMetadata()
		}
		
		access(all)
		fun getRoyalties(id: UInt64): [{LicensedNFT.Royalty}]{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return (ref as! &{LicensedNFT.NFT}).getRoyalties()
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
		fun mintTo(creator: Capability<&{NonFungibleToken.Receiver}>, metadata:{ String: String}, royalties: [{LicensedNFT.Royalty}]): &{NonFungibleToken.NFT}{ 
			let token <- create NFT(id: RaribleNFT.totalSupply, creator: creator.address, metadata: metadata, royalties: royalties)
			RaribleNFT.totalSupply = RaribleNFT.totalSupply + 1
			let tokenRef = &token as &{NonFungibleToken.NFT}
			emit Mint(id: token.id, creator: creator.address, metadata: metadata, royalties: royalties)
			(creator.borrow()!).deposit(token: <-token)
			return tokenRef
		}
	}
	
	access(all)
	fun minter(): Capability<&Minter>{ 
		return self.account.capabilities.get<&Minter>(self.minterPublicPath)!
	}
	
	init(){ 
		self.totalSupply = 0
		self.collectionPublicPath = /public/RaribleNFTCollection
		self.collectionStoragePath = /storage/RaribleNFTCollection
		self.minterPublicPath = /public/RaribleNFTMinter
		self.minterStoragePath = /storage/RaribleNFTMinter
		let minter <- create Minter()
		self.account.storage.save(<-minter, to: self.minterStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Minter>(self.minterStoragePath)
		self.account.capabilities.publish(capability_1, at: self.minterPublicPath)
		let collection <- self.createEmptyCollection(nftType: Type<@Collection>())
		self.account.storage.save(<-collection, to: self.collectionStoragePath)
		var capability_2 = self.account.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver}>(self.collectionStoragePath)
		self.account.capabilities.publish(capability_2, at: self.collectionPublicPath)
		emit ContractInitialized()
	}
}
