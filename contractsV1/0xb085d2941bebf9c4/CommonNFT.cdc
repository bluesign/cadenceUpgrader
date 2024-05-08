import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import NFTPlus from "./NFTPlus.cdc"

/**
 * CommonNFT token contract
 */

access(all)
contract CommonNFT: NonFungibleToken, NFTPlus{ 
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
	event Mint(id: UInt64, collection: String, creator: Address, metadata: String, royalties: [{NFTPlus.Royalties}])
	
	access(all)
	event Destroy(id: UInt64)
	
	access(all)
	event Transfer(id: UInt64, from: Address?, to: Address)
	
	access(all)
	struct Royalties{ 
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
	resource NFT: NonFungibleToken.NFT, NFTPlus.WithRoyalties{ 
		access(all)
		let id: UInt64
		
		access(all)
		let creator: Address
		
		access(all)
		let metadata: String
		
		access(self)
		let royalties: [{NFTPlus.Royalties}]
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64, creator: Address, metadata: String, royalties: [{NFTPlus.Royalties}]){ 
			self.id = id
			self.creator = creator
			self.metadata = metadata
			self.royalties = royalties
		}
		
		access(all)
		fun getRoyalties(): [{NFTPlus.Royalties}]{ 
			return self.royalties
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, NFTPlus.Transferable, NFTPlus.CollectionPublic{ 
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
			let token <- token as! @CommonNFT.NFT
			let id: UInt64 = token.id
			let dummy <- self.ownedNFTs[id] <- token
			destroy dummy
			emit Deposit(id: id, to: self.owner?.address)
		}
		
		access(all)
		fun transfer(tokenId: UInt64, to: Capability<&{NonFungibleToken.Receiver}>){ 
			let token <- self.ownedNFTs.remove(key: tokenId) ?? panic("Missed NFT")
			emit Withdraw(id: tokenId, from: self.owner?.address)
			(to.borrow()!).deposit(token: <-token)
			emit Transfer(id: tokenId, from: self.owner?.address, to: to.address)
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
		fun getRoyalties(id: UInt64): [{NFTPlus.Royalties}]{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return (ref as! &{NFTPlus.NFT}).getRoyalties()
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
		fun mint(creator: Address, metadata: String, royalties: [{NFTPlus.Royalties}]): @{NonFungibleToken.NFT}{ 
			let token <- create NFT(id: CommonNFT.totalSupply, creator: creator, metadata: metadata, royalties: royalties)
			CommonNFT.totalSupply = CommonNFT.totalSupply + 1
			emit Mint(id: token.id, collection: token.getType().identifier, creator: creator, metadata: metadata, royalties: royalties)
			return <-token
		}
		
		access(all)
		fun mintTo(creator: Capability<&{NonFungibleToken.Receiver}>, metadata: String, royalties: [{NFTPlus.Royalties}]): &{NonFungibleToken.NFT}{ 
			let token <- create NFT(id: CommonNFT.totalSupply, creator: creator.address, metadata: metadata, royalties: royalties)
			CommonNFT.totalSupply = CommonNFT.totalSupply + 1
			let tokenRef = &token as &{NonFungibleToken.NFT}
			emit Mint(id: token.id, collection: token.getType().identifier, creator: creator.address, metadata: metadata, royalties: royalties)
			(creator.borrow()!).deposit(token: <-token)
			return tokenRef
		}
	}
	
	access(all)
	fun receiver(_ address: Address): Capability<&{NonFungibleToken.Receiver}>{ 
		return getAccount(address).capabilities.get<&{NonFungibleToken.Receiver}>(self.collectionPublicPath)!
	}
	
	access(all)
	fun collectionPublic(_ address: Address): Capability<&{NonFungibleToken.CollectionPublic}>{ 
		return getAccount(address).capabilities.get<&{NonFungibleToken.CollectionPublic}>(self.collectionPublicPath)!
	}
	
	access(all)
	fun minter(): Capability<&Minter>{ 
		return self.account.capabilities.get<&Minter>(self.minterPublicPath)!
	}
	
	init(){ 
		self.totalSupply = 0
		self.collectionPublicPath = /public/CommonNFTCollection
		self.collectionStoragePath = /storage/CommonNFTCollection
		self.minterPublicPath = /public/CommonNFTMinter
		self.minterStoragePath = /storage/CommonNFTMinter
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
