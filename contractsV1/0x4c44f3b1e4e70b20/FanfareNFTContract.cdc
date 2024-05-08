import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract FanfareNFTContract: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, templateID: UInt64, creatorAddress: Address, recipient: Address, metadata: String)
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	//Contract Owner ContentCreator Resouce 
	access(all)
	let ContentCreatorStoragePath: StoragePath
	
	access(all)
	let ContentCreatorPrivatePath: PrivatePath
	
	access(all)
	let ContentCreatorPublicPath: PublicPath
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let templateID: UInt64
		
		access(all)
		var creatorAddress: Address
		
		access(all)
		var metadata: String
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, templateID: UInt64, creatorAddress: Address, metadata: String){ 
			self.id = initID
			self.templateID = templateID
			self.creatorAddress = creatorAddress
			self.metadata = metadata
		}
	}
	
	access(all)
	resource interface FanfareNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowNFTMetadata(id: UInt64): &FanfareNFTContract.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Card reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, FanfareNFTCollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @FanfareNFTContract.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowNFTMetadata gets a reference to an NFT in the collection
		// so that the caller can read its id and metadata
		access(all)
		fun borrowNFTMetadata(id: UInt64): &FanfareNFTContract.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &FanfareNFTContract.NFT
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
	}
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	resource ContentCreator{ 
		access(all)
		var idCount: UInt64
		
		init(){ 
			self.idCount = 1
		}
		
		access(all)
		fun mintNFT(creatorAddress: Address, recipient: Address, templateID: UInt64, metadata: String): UInt64{ 
			let token: @NFT <- create NFT(initID: self.idCount, templateID: templateID, creatorAddress: creatorAddress, metadata: metadata)
			let id: UInt64 = self.idCount
			self.idCount = self.idCount + 1
			FanfareNFTContract.totalSupply = FanfareNFTContract.totalSupply + 1
			var receiver = getAccount(recipient).capabilities.get<&{FanfareNFTCollectionPublic}>(FanfareNFTContract.CollectionPublicPath)
			let account = receiver.borrow()!
			account.deposit(token: <-token)
			emit Minted(id: id, templateID: templateID, creatorAddress: creatorAddress, recipient: recipient, metadata: metadata)
			return id
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/FanfareNFTCollection
		self.CollectionPublicPath = /public/FanfareNFTCollection
		self.ContentCreatorStoragePath = /storage/FanfareContentStorage
		self.ContentCreatorPrivatePath = /private/FanfareContentStorage
		self.ContentCreatorPublicPath = /public/FanfareContentStorage
		
		// Initialize the total supply
		self.totalSupply = 0
		self.account.storage.save(<-create ContentCreator(), to: self.ContentCreatorStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{FanfareNFTContract.FanfareNFTCollectionPublic}>(/storage/FanfareNFTCollection)
		self.account.capabilities.publish(capability_1, at: /public/FanfareNFTCollection)
		emit ContractInitialized()
	}
}
