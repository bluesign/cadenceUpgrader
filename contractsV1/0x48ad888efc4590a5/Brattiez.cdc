// SPDX-License-Identifier: UNLICENSED
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

// Brattiez
// NFT item for Brattiez
access(all)
contract Brattiez: NonFungibleToken{ 
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, typeID: UInt64, tokenURI: String, tokenTitle: String, tokenDescription: String, artist: String, secondaryRoyalty: String, platformMintedOn: String)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of Brattiez that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// NFT
	// Brattiez as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// The token's type, e.g. 3 == Hat
		access(all)
		let typeID: UInt64
		
		// Token URI
		access(all)
		let tokenURI: String
		
		// Token Title
		access(all)
		let tokenTitle: String
		
		// Token Description
		access(all)
		let tokenDescription: String
		
		// Artist info
		access(all)
		let artist: String
		
		// Secondary Royalty
		access(all)
		let secondaryRoyalty: String
		
		// Platform Minted On
		access(all)
		let platformMintedOn: String
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(initID: UInt64, initTypeID: UInt64, initTokenURI: String, initTokenTitle: String, initTokenDescription: String, initArtist: String, initSecondaryRoyalty: String, initPlatformMintedOn: String){ 
			self.id = initID
			self.typeID = initTypeID
			self.tokenURI = initTokenURI
			self.tokenTitle = initTokenTitle
			self.tokenDescription = initTokenDescription
			self.artist = initArtist
			self.secondaryRoyalty = initSecondaryRoyalty
			self.platformMintedOn = initPlatformMintedOn
		}
	}
	
	// This is the interface that users can cast their Brattiez Collection as
	// to allow others to deposit Brattiez into their Collection. It also allows for reading
	// the details of Brattiez in the Collection.
	access(all)
	resource interface BrattiezCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowBrattiez(id: UInt64): &Brattiez.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Brattiez reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of Brattiez NFTs owned by an account
	//
	access(all)
	resource Collection: BrattiezCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
			let token <- token as! @Brattiez.NFT
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
		
		// borrowBrattiez
		// Gets a reference to an NFT in the collection as a Brattiez,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the Brattiez.
		//
		access(all)
		fun borrowBrattiez(id: UInt64): &Brattiez.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &Brattiez.NFT
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, typeID: UInt64, tokenURI: String, tokenTitle: String, tokenDescription: String, artist: String, secondaryRoyalty: String, platformMintedOn: String){ 
			Brattiez.totalSupply = Brattiez.totalSupply + 1 as UInt64
			emit Minted(id: Brattiez.totalSupply, typeID: typeID, tokenURI: tokenURI, tokenTitle: tokenTitle, tokenDescription: tokenDescription, artist: artist, secondaryRoyalty: secondaryRoyalty, platformMintedOn: platformMintedOn)
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create Brattiez.NFT(initID: Brattiez.totalSupply, initTypeID: typeID, initTokenURI: tokenURI, initTokenTitle: tokenTitle, initTokenDescription: tokenDescription, initArtist: artist, initSecondaryRoyalty: secondaryRoyalty, initPlatformMintedOn: platformMintedOn))
		}
	}
	
	// fetch
	// Get a reference to a Brattiez from an account's Collection, if available.
	// If an account does not have a Brattiez.Collection, panic.
	// If it has a collection but does not contain the itemId, return nil.
	// If it has a collection and that collection contains the itemId, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &Brattiez.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&Brattiez.Collection>(Brattiez.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust Brattiez.Collection.borrowBrattiez to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowBrattiez(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/BrattiezCollection
		self.CollectionPublicPath = /public/BrattiezCollection
		self.MinterStoragePath = /storage/BrattiezMinter
		// Initialize the total supply
		self.totalSupply = 0
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
