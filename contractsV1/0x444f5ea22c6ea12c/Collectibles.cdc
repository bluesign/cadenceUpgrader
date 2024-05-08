import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract Collectibles: NonFungibleToken{ 
	
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
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of Collectibles that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// Type Definitions
	// 
	access(all)
	struct Metadata{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		// MIME type: image/png, image/jpeg, video/mp4, audio/mpeg
		access(all)
		let mediaType: String
		
		// IPFS storage hash
		access(all)
		let mediaHash: String
		
		// URI to NFT media - incase IPFS not in use/avail
		access(all)
		let mediaURI: String
		
		init(name: String, description: String, mediaType: String, mediaHash: String, mediaURI: String){ 
			self.name = name
			self.description = description
			self.mediaType = mediaType
			self.mediaHash = mediaHash
			self.mediaURI = mediaURI
		}
	}
	
	// NFT
	// A Collectible
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// The token's metadata
		access(self)
		let metadata: Metadata
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// Implement the NFTMetadata.INFTPublic interface
		access(all)
		fun getMetadata(): Metadata{ 
			return self.metadata
		}
		
		// initializer
		//
		init(initID: UInt64, metadata: Metadata){ 
			self.id = initID
			self.metadata = metadata
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowCollectible(id: UInt64): &Collectibles.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Collectibles reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of Collectible NFTs owned by an account
	//
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic{ 
		// dictionary of NFT conforming tokens
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
			let token <- token as! @Collectibles.NFT
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
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// borrowCollectible
		// Gets a reference to an NFT in the collection as a Collectible,
		// exposing all of its fields.
		// This is safe as there are no functions that can be called on the Collectibles.
		//
		access(all)
		fun borrowCollectible(id: UInt64): &Collectibles.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &Collectibles.NFT
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
	
	// NFTMinter
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata: Metadata){ 
			emit Minted(id: Collectibles.totalSupply)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create Collectibles.NFT(initID: Collectibles.totalSupply, metadata: metadata))
			Collectibles.totalSupply = Collectibles.totalSupply + 1 as UInt64
		}
		
		// batchMintNFT
		// Mints a batch of new NFTs
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun batchMintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata: Metadata, count: Int){ 
			var index = 0
			while index < count{ 
				self.mintNFT(recipient: recipient, metadata: metadata)
				index = index + 1
			}
		}
	}
	
	// fetch
	// Get a reference to a Collectible from an account's Collection, if available.
	// If an account does not have a Collectibles.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &Collectibles.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&Collectibles.Collection>(Collectibles.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust Collectibles.Collection.borowCollectible to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowCollectible(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/jambbLaunchCollectiblesCollection
		self.CollectionPublicPath = /public/jambbLaunchCollectiblesCollection
		self.MinterStoragePath = /storage/jambbLaunchCollectiblesMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
