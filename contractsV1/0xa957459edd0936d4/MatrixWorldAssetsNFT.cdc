import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import LicensedNFT from "./LicensedNFT.cdc"

// MatirxWorldAssetsNFT token contract
//
access(all)
contract MatrixWorldAssetsNFT: NonFungibleToken, LicensedNFT{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var collectionPublicPath: PublicPath
	
	access(all)
	var collectionStoragePath: StoragePath
	
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
	resource NFT: NonFungibleToken.NFT{ 
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
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, LicensedNFT.CollectionPublic{ 
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
			let token <- token as! @MatrixWorldAssetsNFT.NFT
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
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		access(all)
		fun getMetadata(id: UInt64):{ String: String}{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return (ref as! &MatrixWorldAssetsNFT.NFT).getMetadata()
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
			let token <- create NFT(id: MatrixWorldAssetsNFT.totalSupply, creator: creator.address, metadata: metadata, royalties: royalties)
			MatrixWorldAssetsNFT.totalSupply = MatrixWorldAssetsNFT.totalSupply + 1
			let tokenRef = &token as &{NonFungibleToken.NFT}
			emit Mint(id: token.id, creator: creator.address, metadata: metadata, royalties: royalties)
			(creator.borrow()!).deposit(token: <-token)
			return tokenRef
		}
	}
	
	access(all)
	fun minter(): &Minter{ 
		return self.account.storage.borrow<&Minter>(from: self.minterStoragePath) ?? panic("Could not borrow minter reference")
	}
	
	init(){ 
		self.totalSupply = 0
		self.collectionPublicPath = /public/MatrixWorldAssetNFTCollection
		self.collectionStoragePath = /storage/MatrixWorldAssetNFTCollection
		self.minterStoragePath = /storage/AssetNFTMinter
		let minter <- create Minter()
		self.account.storage.save(<-minter, to: self.minterStoragePath)
		let collection <- self.createEmptyCollection(nftType: Type<@Collection>())
		self.account.storage.save(<-collection, to: self.collectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver}>(self.collectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.collectionPublicPath)
		emit ContractInitialized()
	}
}
