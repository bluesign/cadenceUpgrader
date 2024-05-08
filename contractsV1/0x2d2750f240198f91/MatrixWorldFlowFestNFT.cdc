import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract MatrixWorldFlowFestNFT: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, name: String, description: String, animationUrl: String, hash: String, type: String)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	resource interface NFTPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let metadata: Metadata
	}
	
	access(all)
	struct Metadata{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let animationUrl: String
		
		access(all)
		let hash: String
		
		access(all)
		let type: String
		
		init(name: String, description: String, animationUrl: String, hash: String, type: String){ 
			self.name = name
			self.description = description
			self.animationUrl = animationUrl
			self.hash = hash
			self.type = type
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, NFTPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let metadata: Metadata
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, metadata: Metadata){ 
			self.id = initID
			self.metadata = metadata
		}
	}
	
	access(all)
	resource interface MatrixWorldFlowFestNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowVoucher(id: UInt64): &MatrixWorldFlowFestNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow MatrixWorldVoucher reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: MatrixWorldFlowFestNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @MatrixWorldFlowFestNFT.NFT
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
		fun borrowVoucher(id: UInt64): &MatrixWorldFlowFestNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &MatrixWorldFlowFestNFT.NFT
			} else{ 
				return nil
			}
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
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	struct NftData{ 
		access(all)
		let metadata: MatrixWorldFlowFestNFT.Metadata
		
		access(all)
		let id: UInt64
		
		init(metadata: MatrixWorldFlowFestNFT.Metadata, id: UInt64){ 
			self.metadata = metadata
			self.id = id
		}
	}
	
	access(all)
	fun getNft(address: Address): [NftData]{ 
		var nftData: [NftData] = []
		let account = getAccount(address)
		if let nftCollection = account.capabilities.get<&{MatrixWorldFlowFestNFT.MatrixWorldFlowFestNFTCollectionPublic}>(self.CollectionPublicPath).borrow<&{MatrixWorldFlowFestNFT.MatrixWorldFlowFestNFTCollectionPublic}>(){ 
			for id in nftCollection.getIDs(){ 
				var nft = nftCollection.borrowVoucher(id: id)
				nftData.append(NftData(metadata: (nft!).metadata, id: id))
			}
		}
		return nftData
	}
	
	access(all)
	resource NFTMinter{ 
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, animationUrl: String, hash: String, type: String){ 
			emit Minted(id: MatrixWorldFlowFestNFT.totalSupply, name: name, description: description, animationUrl: animationUrl, hash: hash, type: type)
			recipient.deposit(token: <-create MatrixWorldFlowFestNFT.NFT(initID: MatrixWorldFlowFestNFT.totalSupply, metadata: Metadata(name: name, description: description, animationUrl: animationUrl, hash: hash, type: type)))
			MatrixWorldFlowFestNFT.totalSupply = MatrixWorldFlowFestNFT.totalSupply + 1 as UInt64
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/MatrixWorldFlowFestNFTCollection
		self.CollectionPublicPath = /public/MatrixWorldFlowFestNFTCollection
		self.MinterStoragePath = /storage/MatrixWorldFlowFestNFTrMinter
		self.totalSupply = 0
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
