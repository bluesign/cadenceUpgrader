import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc" //"./NonFungibleToken.cdc"


// import FungibleToken from "../"./FungibleToken.cdc"/FungibleToken.cdc"
access(all)
contract FlowChinaBadge: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// totalSupply
	// The total number of FlowChinaBadge that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		// The IPFS CID of the metadata file.
		access(all)
		let metadata: String
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64, metadata: String){ 
			self.id = id
			self.metadata = metadata
		}
	}
	
	access(all)
	resource interface FlowChinaBadgeCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowFlowChinaBadge(id: UInt64): &FlowChinaBadge.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow FlowChinaBadge reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: FlowChinaBadgeCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		
		// dictionary of NFTs
		// NFT is a resource type with an `UInt64` ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @FlowChinaBadge.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs
		// Returns an array of the IDs that are in the collection
		//
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowFlowChinaBadge
		// Gets a reference to an NFT in the collection as a FlowChinaBadge.
		//
		access(all)
		fun borrowFlowChinaBadge(id: UInt64): &FlowChinaBadge.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &FlowChinaBadge.NFT
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
		//
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Admin
	// Resource that an admin can use to mint NFTs.
	//
	access(all)
	resource Admin{ 
		
		// mintNFT
		// Mints a new NFT with a new ID
		//
		access(all)
		fun mintNFT(metadata: String): @FlowChinaBadge.NFT{ 
			let nft <- create FlowChinaBadge.NFT(id: FlowChinaBadge.totalSupply, metadata: metadata)
			emit Minted(id: nft.id)
			FlowChinaBadge.totalSupply = FlowChinaBadge.totalSupply + 1 as UInt64
			return <-nft
		}
	}
	
	// fetch
	// Get a reference to a FlowChinaBadge from an account's Collection, if available.
	// If an account does not have a FlowChinaBadge.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &FlowChinaBadge.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&{FlowChinaBadge.FlowChinaBadgeCollectionPublic}>(FlowChinaBadge.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		
		// We trust FlowChinaBadge.Collection.borowFlowChinaBadge to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowFlowChinaBadge(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/FlowChinaBadgeCollection
		self.CollectionPublicPath = /public/FlowChinaBadgeCollection
		self.CollectionPrivatePath = /private/FlowChinaBadgeCollection
		self.AdminStoragePath = /storage/FlowChinaBadgeAdmin
		
		// Initialize the total supply
		self.totalSupply = 0
		let collection <- FlowChinaBadge.createEmptyCollection(nftType: Type<@FlowChinaBadge.Collection>())
		self.account.storage.save(<-collection, to: FlowChinaBadge.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&FlowChinaBadge.Collection>(FlowChinaBadge.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: FlowChinaBadge.CollectionPrivatePath)
		var capability_2 = self.account.capabilities.storage.issue<&FlowChinaBadge.Collection>(FlowChinaBadge.CollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: FlowChinaBadge.CollectionPublicPath)
		
		// Create an admin resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
