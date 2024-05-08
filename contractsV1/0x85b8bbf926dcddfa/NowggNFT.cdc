import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract NowggNFT: NonFungibleToken{ 
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, typeId: String)
	
	access(all)
	event TypeRegistered(typeId: String)
	
	access(all)
	event TypeSoldOut(typeId: String)
	
	access(all)
	event NftDestroyed(id: UInt64)
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let NftTypeHelperStoragePath: StoragePath
	
	access(all)
	let NFTtypeHelperPublicPath: PublicPath
	
	// totalSupply
	// The total number of NowggNFTs that have been minted
	access(all)
	var totalSupply: UInt64
	
	// NFT type
	// It is used to keep a check on the current NFTs minted and the total number of NFTs that can be minted
	// for a given type
	access(all)
	struct NftType{ 
		access(all)
		let typeId: String
		
		access(all)
		var currentCount: UInt64
		
		access(all)
		let maxCount: UInt64
		
		access(all)
		fun updateCount(count: UInt64){ 
			self.currentCount = count
		}
		
		init(typeId: String, maxCount: UInt64){ 
			if NowggNFT.activeNftTypes.keys.contains(typeId){ 
				panic("Type is already registered")
			}
			self.typeId = typeId
			self.maxCount = maxCount
			self.currentCount = 0
		}
	}
	
	// NFT types registered which can be minted
	access(contract)
	var activeNftTypes:{ String: NftType}
	
	// NFT types registered which have reached the max limit for minting
	access(contract)
	var historicNftTypes:{ String: NftType}
	
	// NFT
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		access(self)
		let metadata:{ String: AnyStruct}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(initID: UInt64, metadata:{ String: AnyStruct}){ 
			self.id = initID
			self.metadata = metadata
		}
		
		// getter for metadata
		access(all)
		fun getMetadata():{ String: AnyStruct}{ 
			return self.metadata
		}
	}
	
	// This is the interface that users can cast their NowggNFTs Collection as
	// to allow others to deposit NowggNFTs into their Collection. It also allows for reading
	// the details of NowggNFTs in the Collection.
	access(all)
	resource interface NowggNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowNowggNFT(id: UInt64): &NowggNFT.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow NowggNFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Interface that allows other users to access details of the NFTtypes
	// by providing the IDs for them
	access(all)
	resource interface NftTypeHelperPublic{ 
		access(all)
		fun borrowActiveNFTtype(id: String): NftType?{ 
			post{ 
				result == nil || result?.typeId == id:
					"Cannot borrow NftType reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		fun borrowHistoricNFTtype(id: String): NftType?{ 
			post{ 
				result == nil || result?.typeId == id:
					"Cannot borrow NftType reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of NowggItem NFTs owned by an account
	access(all)
	resource Collection: NowggNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @NowggNFT.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs
		// Returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowNowggNFT
		// Gets a reference to an NFT in the collection as a NowggItem,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the NowggItem.
		access(all)
		fun borrowNowggNFT(id: UInt64): &NowggNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &NowggNFT.NFT
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
		
		// destructor
		// initializer
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Resource that allows other users to access details of the NFTtypes
	// by providing the IDs for them
	access(all)
	resource NftTypeHelper: NftTypeHelperPublic{ 
		// public function to borrow details of NFTtype
		access(all)
		fun borrowActiveNFTtype(id: String): NftType?{ 
			if NowggNFT.activeNftTypes[id] != nil{ 
				let ref = NowggNFT.activeNftTypes[id]
				return ref
			} else{ 
				return nil
			}
		}
		
		access(all)
		fun borrowHistoricNFTtype(id: String): NftType?{ 
			if NowggNFT.historicNftTypes[id] != nil{ 
				let ref = NowggNFT.historicNftTypes[id]
				return ref
			} else{ 
				return nil
			}
		}
	}
	
	// NFTMinter
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	access(all)
	resource NFTMinter{ 
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, typeId: String, metaData:{ String: AnyStruct}){ 
			if !NowggNFT.activeNftTypes.keys.contains(typeId){ 
				panic("Invalid typeId")
			}
			let nftType = NowggNFT.activeNftTypes[typeId]!
			let currentCount = nftType.currentCount
			if currentCount >= nftType.maxCount{ 
				panic("NFT mint limit exceeded")
			}
			let updateCount = currentCount + 1 as UInt64
			
			// Adding copy number to metadata
			metaData["copyNumber"] = updateCount
			metaData["maxCount"] = nftType.maxCount
			
			// Create and deposit NFT in recipent's account
			recipient.deposit(token: <-create NowggNFT.NFT(initID: NowggNFT.totalSupply, metadata: metaData))
			
			// Increment count for NFT of particular type
			nftType.updateCount(count: updateCount)
			if updateCount < nftType.maxCount{ 
				NowggNFT.activeNftTypes[typeId] = nftType
			} else{ 
				NowggNFT.historicNftTypes[typeId] = nftType
				NowggNFT.activeNftTypes.remove(key: typeId)
				emit TypeSoldOut(typeId: typeId)
			}
			
			// emit event
			emit Minted(id: NowggNFT.totalSupply, typeId: typeId)
			
			// Increment total supply of NFTs
			NowggNFT.totalSupply = NowggNFT.totalSupply + 1 as UInt64
		}
		
		access(all)
		fun registerType(typeId: String, maxCount: UInt64){ 
			let nftType = NftType(typeId: typeId, maxCount: maxCount)
			NowggNFT.activeNftTypes[typeId] = nftType
			emit TypeRegistered(typeId: typeId)
		}
	}
	
	// fetch
	// Get a reference to a NowggNFT from an account's Collection, if available.
	// If an account does not have a NowggNFT.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	access(all)
	fun borrowNFT(from: Address, itemID: UInt64): &NowggNFT.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&NowggNFT.Collection>(NowggNFT.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust NowggNFT.Collection.borrowNowggNFT to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowNowggNFT(id: itemID)
	}
	
	// initializer
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/NowggNFTsCollection
		self.CollectionPublicPath = /public/NowggNFTsCollection
		self.MinterStoragePath = /storage/NowggNFTMinter
		self.NftTypeHelperStoragePath = /storage/NowggNftTypeHelperStoragePath
		self.NFTtypeHelperPublicPath = /public/NowggNftNFTtypeHelperPublicPath
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Initialize active NFT types
		self.activeNftTypes ={} 
		
		// Initialize historic NFT types
		self.historicNftTypes ={} 
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		
		// Create an empty collection
		let emptyCollection <- self.createEmptyCollection(nftType: Type<@Collection>())
		self.account.storage.save(<-emptyCollection, to: self.CollectionStoragePath)
		self.account.unlink(self.CollectionPublicPath)
		var capability_1 = self.account.capabilities.storage.issue<&NowggNFT.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create helper for getting details of NftTypes
		let nftTypehelper <- create NftTypeHelper()
		self.account.storage.save(<-nftTypehelper, to: self.NftTypeHelperStoragePath)
		self.account.unlink(self.NFTtypeHelperPublicPath)
		var capability_2 = self.account.capabilities.storage.issue<&NowggNFT.NftTypeHelper>(self.NftTypeHelperStoragePath)
		self.account.capabilities.publish(capability_2, at: self.NFTtypeHelperPublicPath)
		
		// Emit event for contract initialized
		emit ContractInitialized()
	}
}
