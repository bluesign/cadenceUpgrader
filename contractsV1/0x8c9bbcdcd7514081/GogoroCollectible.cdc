import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract GogoroCollectible: NonFungibleToken{ 
	
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
	let AdminStoragePath: StoragePath
	
	// totalSupply
	// The total number of GogoroCollectible that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// metadata for each item
	// 
	access(contract)
	var itemMetadata:{ UInt64: Metadata}
	
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
		
		// additional metadata
		access(self)
		let additional:{ String: String}
		
		// number of items
		access(all)
		var itemCount: UInt64
		
		init(name: String, description: String, mediaType: String, mediaHash: String, additional:{ String: String}){ 
			self.name = name
			self.description = description
			self.mediaType = mediaType
			self.mediaHash = mediaHash
			self.additional = additional
			self.itemCount = 0
		}
		
		access(all)
		fun getAdditional():{ String: String}{ 
			return self.additional
		}
	}
	
	// NFT
	// A Gogoro Collectible NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// The token's type
		access(all)
		let itemID: UInt64
		
		// The token's edition number
		access(all)
		let editionNumber: UInt64
		
		// initializer
		//
		init(initID: UInt64, itemID: UInt64){ 
			self.id = initID
			self.itemID = itemID
			let metadata = GogoroCollectible.itemMetadata[itemID] ?? panic("itemID not valid")
			self.editionNumber = metadata.itemCount + 1 as UInt64
			
			// Increment the edition count by 1
			metadata.itemCount = self.editionNumber
			GogoroCollectible.itemMetadata[itemID] = metadata
		}
		
		// Expose metadata
		access(all)
		fun getMetadata(): Metadata?{ 
			return GogoroCollectible.itemMetadata[self.itemID]
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.IPFSFile>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					let metadata = self.getMetadata() ?? panic("missing metadata")
					return MetadataViews.Display(name: metadata.name, description: metadata.description, thumbnail: MetadataViews.IPFSFile(cid: metadata.mediaHash, path: nil))
				case Type<MetadataViews.IPFSFile>():
					return MetadataViews.IPFSFile(cid: (self.getMetadata()!).mediaHash, path: nil)
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
		fun borrowGogoroCollectible(id: UInt64): &GogoroCollectible.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow GogoroCollectible reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of GogoroCollectible NFTs owned by an account
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
			let token <- token as! @GogoroCollectible.NFT
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
		
		// borrowGogoroCollectible
		// Gets a reference to an NFT in the collection as a GogoroCollectible,
		// exposing all of its fields.
		// This is safe as there are no functions that can be called on the GogoroCollectible.
		//
		access(all)
		fun borrowGogoroCollectible(id: UInt64): &GogoroCollectible.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &GogoroCollectible.NFT
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
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource Admin{ 
		
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, itemID: UInt64, codeHash: String?){ 
			pre{ 
				codeHash == nil || !GogoroCollectible.checkCodeHashUsed(codeHash: codeHash!):
					"duplicated codeHash"
			}
			emit Minted(id: GogoroCollectible.totalSupply)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create GogoroCollectible.NFT(initID: GogoroCollectible.totalSupply, itemID: itemID))
			GogoroCollectible.totalSupply = GogoroCollectible.totalSupply + 1 as UInt64
			
			// if minter passed in codeHash, register it to dictionary
			if let checkedCodeHash = codeHash{ 
				let redeemedCodes = GogoroCollectible.account.storage.load<{String: Bool}>(from: /storage/redeemedCodes)!
				redeemedCodes[checkedCodeHash] = true
				GogoroCollectible.account.storage.save<{String: Bool}>(redeemedCodes, to: /storage/redeemedCodes)
			}
		}
		
		// batchMintNFT
		// Mints a batch of new NFTs
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun batchMintNFT(recipient: &{NonFungibleToken.CollectionPublic}, itemID: UInt64, count: Int){ 
			var index = 0
			while index < count{ 
				self.mintNFT(recipient: recipient, itemID: itemID, codeHash: nil)
				index = index + 1
			}
		}
		
		// registerMetadata
		// Registers metadata for a itemID
		//
		access(all)
		fun registerMetadata(itemID: UInt64, metadata: Metadata){ 
			pre{ 
				GogoroCollectible.itemMetadata[itemID] == nil:
					"duplicated itemID"
			}
			GogoroCollectible.itemMetadata[itemID] = metadata
		}
		
		// updateMetadata
		// Registers metadata for a itemID
		//
		access(all)
		fun updateMetadata(itemID: UInt64, metadata: Metadata){ 
			pre{ 
				GogoroCollectible.itemMetadata[itemID] != nil:
					"itemID does not exist"
			}
			metadata.itemCount = (GogoroCollectible.itemMetadata[itemID]!).itemCount
			
			// update metadata
			GogoroCollectible.itemMetadata[itemID] = metadata
		}
	}
	
	// fetch
	// Get a reference to a GogoroCollectible from an account's Collection, if available.
	// If an account does not have a GogoroCollectible.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &GogoroCollectible.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&GogoroCollectible.Collection>(GogoroCollectible.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust GogoroCollectible.Collection.borowGogoroCollectible to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowGogoroCollectible(id: itemID)
	}
	
	// getMetadata
	// Get the metadata for a specific type of GogoroCollectible
	//
	access(all)
	fun getMetadata(itemID: UInt64): Metadata?{ 
		return GogoroCollectible.itemMetadata[itemID]
	}
	
	// checkCodeHashUsed
	// Check if a codeHash has been registered
	//
	access(all)
	view fun checkCodeHashUsed(codeHash: String): Bool{ 
		var redeemedCodes = GogoroCollectible.account.storage.copy<{String: Bool}>(from: /storage/redeemedCodes)!
		return redeemedCodes[codeHash] ?? false
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/GogoroCollectibleCollection
		self.CollectionPublicPath = /public/GogoroCollectibleCollection
		self.AdminStoragePath = /storage/GogoroCollectibleAdmin
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Initialize predefined metadata
		self.itemMetadata ={} 
		
		// Create a Admin resource and save it to storage
		let minter <- create Admin()
		self.account.storage.save(<-minter, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
