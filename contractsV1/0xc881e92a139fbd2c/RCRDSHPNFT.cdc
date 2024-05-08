import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract RCRDSHPNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let minterStoragePath: StoragePath
	
	access(all)
	let collectionStoragePath: StoragePath
	
	access(all)
	let collectionPublicPath: PublicPath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		var metadata:{ String: String}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, metadata:{ String: String}){ 
			self.id = initID
			self.metadata = metadata
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
			let token <- token as! @RCRDSHPNFT.NFT
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, meta:{ String: String}){ 
			var newNFT <- create NFT(initID: RCRDSHPNFT.totalSupply, metadata: meta)
			recipient.deposit(token: <-newNFT)
			RCRDSHPNFT.totalSupply = RCRDSHPNFT.totalSupply + UInt64(1)
		}
	}
	
	init(){ 
		self.totalSupply = 0
		self.minterStoragePath = /storage/RCRDSHPNFTMinter
		self.collectionStoragePath = /storage/RCRDSHPNFTCollection
		self.collectionPublicPath = /public/RCRDSHPNFTCollection
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.collectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic}>(self.collectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.collectionPublicPath)
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.minterStoragePath)
		emit ContractInitialized()
	}
}
