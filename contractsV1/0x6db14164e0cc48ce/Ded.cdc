import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract Ded: NonFungibleToken{ 
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, type: String, uri: String, minter: Address)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		access(all)
		let type: String
		
		access(all)
		let uri: String
		
		access(all)
		let minter: Address
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, initType: String, initUri: String, initMinter: Address){ 
			self.id = initID
			self.type = initType
			self.uri = initUri
			self.minter = initMinter
			emit Minted(id: self.id, type: self.type, uri: self.uri, minter: self.minter)
		}
	}
	
	access(all)
	struct AccountItem{ 
		access(all)
		let itemID: UInt64
		
		access(all)
		let type: String
		
		access(all)
		let uri: String
		
		access(all)
		let minter: Address
		
		access(all)
		let resourceID: UInt64
		
		access(all)
		let owner: Address
		
		init(itemID: UInt64, itemType: String, itemUri: String, itemMinter: Address, resourceID: UInt64, owner: Address){ 
			self.itemID = itemID
			self.type = itemType
			self.uri = itemUri
			self.minter = itemMinter
			self.resourceID = resourceID
			self.owner = owner
		}
	}
	
	access(all)
	resource interface DedCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowDed(id: UInt64): &Ded.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Ded reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: DedCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
			let token <- token as! @Ded.NFT
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
		fun borrowDed(id: UInt64): &Ded.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &Ded.NFT
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
	resource NFTMinter{ 
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, minter: Address, type: String, uri: String){ 
			let newNFT: @Ded.NFT <- create Ded.NFT(initID: Ded.totalSupply, initType: type, initUri: uri, initMinter: minter)
			recipient.deposit(token: <-newNFT)
			Ded.totalSupply = Ded.totalSupply + 1 as UInt64
		}
	}
	
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &Ded.NFT?{ 
		let collection = getAccount(from).capabilities.get<&Ded.Collection>(Ded.CollectionPublicPath).borrow<&Ded.Collection>() ?? panic("Couldn't get collection")
		return collection.borrowDed(id: itemID)
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/DedCollection
		self.CollectionPublicPath = /public/DedCollection
		self.MinterStoragePath = /storage/DedMinter
		self.totalSupply = 0
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
