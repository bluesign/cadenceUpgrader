import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract CaaArts: NonFungibleToken{ 
	
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
	// The total number of CaaArts that have been minted
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
		
		// mediaType: MIME type of the media
		// - image/png
		// - image/jpeg
		// - video/mp4
		// - audio/mpeg
		access(all)
		let mediaType: String
		
		// mediaHash: IPFS storage hash
		access(all)
		let mediaHash: String
		
		init(name: String, description: String, mediaType: String, mediaHash: String){ 
			self.name = name
			self.description = description
			self.mediaType = mediaType
			self.mediaHash = mediaHash
		}
	}
	
	// NFT
	// An CAA art piece NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// The token's metadata
		access(self)
		let metadata: Metadata
		
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
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<Metadata>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Display>(), Type<MetadataViews.NFTCollectionData>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let metadata = self.getMetadata()
			switch view{ 
				case Type<Metadata>():
					return metadata
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: metadata.name, description: metadata.description, thumbnail: MetadataViews.IPFSFile(cid: metadata.mediaHash, path: nil))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: CaaArts.CollectionStoragePath, publicPath: CaaArts.CollectionPublicPath, publicCollection: Type<&CaaArts.Collection>(), publicLinkedType: Type<&CaaArts.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-CaaArts.createEmptyCollection(nftType: Type<@CaaArts.Collection>())
						})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
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
		fun borrowCaaArt(id: UInt64): &CaaArts.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow CaaArts reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of CaaArt NFTs owned by an account
	//
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @CaaArts.NFT
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
		
		// borrowViewResolver
		// 
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let theNFT = nft as! &CaaArts.NFT
			return theNFT as &{ViewResolver.Resolver}
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowCaaArt
		// Gets a reference to an NFT in the collection as a CaaArt,
		// exposing all of its fields.
		// This is safe as there are no functions that can be called on the CaaArts.
		//
		access(all)
		fun borrowCaaArt(id: UInt64): &CaaArts.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &CaaArts.NFT
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
			emit Minted(id: CaaArts.totalSupply)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create CaaArts.NFT(initID: CaaArts.totalSupply, metadata: metadata))
			CaaArts.totalSupply = CaaArts.totalSupply + 1 as UInt64
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
	// Get a reference to a CaaArt from an account's Collection, if available.
	// If an account does not have a CaaArts.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &CaaArts.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&CaaArts.Collection>(CaaArts.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust CaaArts.Collection.borowCaaArt to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowCaaArt(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/caaArtsCollection
		self.CollectionPublicPath = /public/caaArtsCollection
		self.MinterStoragePath = /storage/caaArtsMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
