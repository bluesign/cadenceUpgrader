import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

// CommonNFT
// Supporting common NFT feature.
//
access(all)
contract CommonNFT: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event WithdrawMultiple(ids: [UInt64], from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event DepositMultiple(ids: [UInt64], to: Address?)
	
	access(all)
	event Minted(id: UInt64, developerID: UInt64, developerMetadata: String, contentURL: String)
	
	access(all)
	event MintedMultiple(startID: UInt64, developerID: UInt64, startEdition: UInt64, number: UInt64, developerMetadata: String, contentURL: String)
	
	access(all)
	event Delete(id: UInt64, from: Address?)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of Common NFTs that have been minted.
	//
	access(all)
	var totalSupply: UInt64
	
	// NFT
	// A Common NFT usable by different developers.
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID.
		access(all)
		let id: UInt64
		
		// The token developer's ID.
		access(all)
		let developerID: UInt64
		
		// The token's edition number.
		access(all)
		let edition: UInt64
		
		// The token's metadata specified by the developer.
		access(all)
		let developerMetadata: String
		
		// The token's content URL.
		access(all)
		let contentURL: String
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(initID: UInt64, initDeveloperID: UInt64, initEdition: UInt64, initDeveloperMetadata: String, initContentURL: String){ 
			self.id = initID
			self.developerID = initDeveloperID
			self.edition = initEdition
			self.developerMetadata = initDeveloperMetadata
			self.contentURL = initContentURL
		}
	}
	
	// This is the interface that users can cast their Common NFT Collection as
	// to allow others to deposit Common NFTs into their Collection. It also allows for reading
	// the details of Common NFTs in the Collection.
	access(all)
	resource interface CommonNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun depositMultiple(tokens: @[{NonFungibleToken.NFT}])
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowCommonNFT(id: UInt64): &CommonNFT.NFT?{ 
			// If the result isn't nil, the ID of the returned reference
			// should be the same as the argument to the function.
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow CommonNFT reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		fun borrowAllCommonNFTs(): [&{NonFungibleToken.NFT}]
	}
	
	// Collection
	// A collection of Common NFTs owned by an account.
	//
	access(all)
	resource Collection: CommonNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// Dictionary of NFT conforming tokens.
		// NFT is a resource type with an `UInt64` ID field.
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller.
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// withdrawMultiple
		// Removes multiple NFTs from the collection and moves them to the caller.
		//
		access(all)
		fun withdrawMultiple(withdrawIDs: [UInt64]): @[{NonFungibleToken.NFT}]{ 
			var tokens: @[{NonFungibleToken.NFT}] <- []
			var count: Int = 0
			while count < withdrawIDs.length{ 
				let token <- self.ownedNFTs.remove(key: withdrawIDs[count]) ?? panic("missing NFT")
				tokens.append(<-token)
				count = count + 1
			}
			emit WithdrawMultiple(ids: withdrawIDs, from: self.owner?.address)
			return <-tokens
		}
		
		// deleteMultiple
		// Burns multiple NFTs from the collection.
		//
		access(all)
		fun deleteMultiple(deleteIDs: [UInt64]){ 
			var count: Int = 0
			while count < deleteIDs.length{ 
				let token <- self.ownedNFTs.remove(key: deleteIDs[count]) ?? panic("missing NFT")
				destroy token
				count = count + 1
			}
		}
		
		// deposit
		// Takes a NFT, adds it to the collections dictionary,
		// and adds the ID to the id array.
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @CommonNFT.NFT
			let id: UInt64 = token.id
			
			// Add the new token to the dictionary which removes the old one.
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// depositMultiple
		// Takes multiple NFTs, adds them to the collections dictionary,
		// and adds the IDs to the id array.
		//
		access(all)
		fun depositMultiple(tokens: @[{NonFungibleToken.NFT}]){ 
			var count = 0
			var ids: [UInt64] = []
			while tokens.length > 0{ 
				let token <- tokens.removeFirst()
				let id: UInt64 = token.id
				ids.append(id)
				
				// Add the new token to the dictionary which removes the old one.
				let oldToken <- self.ownedNFTs[id] <- token
				destroy oldToken
				count = count + 1
			}
			emit DepositMultiple(ids: ids, to: self.owner?.address)
			destroy tokens
		}
		
		// getIDs
		// Returns an array of the IDs that are in the collection.
		//
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods.
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// borrowCommonNFT
		// Gets a reference to an NFT in the collection as a CommonNFT,
		// exposing all of its fields (including the edition, developer metadata, and content URL).
		// This is safe as there are no functions that can be called on the CommonNFT.
		//
		access(all)
		fun borrowCommonNFT(id: UInt64): &CommonNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &CommonNFT.NFT
			} else{ 
				return nil
			}
		}
		
		// borrowAllCommonNFTs
		// Returns an array of references to the NFTs that are in the collection.
		//
		access(all)
		fun borrowAllCommonNFTs(): [&{NonFungibleToken.NFT}]{ 
			var nftRefs: [&{NonFungibleToken.NFT}] = []
			for id in self.ownedNFTs.keys{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				nftRefs.append(ref!)
			}
			return nftRefs
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
		//
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// createEmptyCollection
	// Public function that anyone can call to create a new empty collection.
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// NFTMinter
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs.
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposits it in the recipient's collection using their collection reference.
		//
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, developerID: UInt64, developerMetadata: String, contentURL: String){ 
			CommonNFT.totalSupply = CommonNFT.totalSupply + 1 as UInt64
			emit Minted(id: CommonNFT.totalSupply, developerID: developerID, developerMetadata: developerMetadata, contentURL: contentURL)
			
			// Deposit it in the recipient's account using their reference.
			recipient.deposit(token: <-create CommonNFT.NFT(initID: CommonNFT.totalSupply, initDeveloperID: developerID, initEdition: 0 as UInt64, initDeveloperMetadata: developerMetadata, initContentURL: contentURL))
		}
		
		// mintMulitpleNFTs
		// Mints multiple new NFTs with same developer metadata and content URL but different IDs and editions,
		// then deposits them in the recipient's collection using their collection reference.
		//
		access(all)
		fun mintMultipleNFTs(recipient: &{CommonNFT.CommonNFTCollectionPublic}, developerID: UInt64, startEdition: UInt64, number: UInt64, developerMetadata: String, contentURL: String){ 
			var edition: UInt64 = startEdition
			var tokens: @[CommonNFT.NFT] <- []
			CommonNFT.totalSupply = CommonNFT.totalSupply + 1 as UInt64
			emit MintedMultiple(startID: CommonNFT.totalSupply, developerID: developerID, startEdition: startEdition, number: number, developerMetadata: developerMetadata, contentURL: contentURL)
			while edition < startEdition + number{ 
				tokens.append(<-create CommonNFT.NFT(initID: CommonNFT.totalSupply, initDeveloperID: developerID, initEdition: edition, initDeveloperMetadata: developerMetadata, initContentURL: contentURL))
				if edition != number{ 
					CommonNFT.totalSupply = CommonNFT.totalSupply + 1 as UInt64
				}
				edition = edition + 1 as UInt64
			}
			
			// Deposit the tokens in the recipient's account using their reference.
			recipient.depositMultiple(tokens: <-tokens)
		}
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths.
		self.CollectionStoragePath = /storage/commonNFTCollection
		self.CollectionPublicPath = /public/commonNFTCollection
		self.MinterStoragePath = /storage/commonNFTMinter
		
		// Initialize totalSupply.
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage.
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
