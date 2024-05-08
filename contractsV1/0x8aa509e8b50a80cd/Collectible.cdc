import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import Edition from "./Edition.cdc"

access(all)
contract Collectible: NonFungibleToken{ 
	// Named Paths   
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterPrivatePath: PrivatePath
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Created(id: UInt64)
	
	// totalSupply
	// The total number of NFTs that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	access(all)
	resource interface Public{ 
		access(all)
		let id: UInt64
		
		access(all)
		let metadata: Metadata
		
		// Common number for all copies of the item
		access(all)
		let editionNumber: UInt64
	}
	
	access(all)
	struct Metadata{ 
		// Link to IPFS file
		access(all)
		let link: String
		
		// Name  
		access(all)
		let name: String
		
		// Author name
		access(all)
		let author: String
		
		// Description
		access(all)
		let description: String
		
		// Number of copy
		access(all)
		let edition: UInt64
		
		// Additional properties to use in future
		access(all)
		let properties: AnyStruct
		
		init(link: String, name: String, author: String, description: String, edition: UInt64, properties: AnyStruct){ 
			self.link = link
			self.name = name
			self.author = author
			self.description = description
			self.edition = edition
			self.properties = properties
		}
	}
	
	// NFT
	// Collectible as an NFT
	access(all)
	resource NFT: NonFungibleToken.NFT, Public{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		access(all)
		let metadata: Metadata
		
		// Common number for all copies of the item
		access(all)
		let editionNumber: UInt64
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(initID: UInt64, metadata: Metadata, editionNumber: UInt64){ 
			self.id = initID
			self.metadata = metadata
			self.editionNumber = editionNumber
		}
	}
	
	//Standard NFT collectionPublic interface that can also borrowArt as the correct type
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowCollectible(id: UInt64): &Collectible.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow collectible reference: The id of the returned reference is incorrect."
			}
		}
		
		// Common number for all copies of the item
		access(all)
		fun getEditionNumber(id: UInt64): UInt64?
	}
	
	// Collection
	// A collection of NFTs owned by an account
	//
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
			let token <- token as! @Collectible.NFT
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
		
		access(all)
		fun getNFT(id: UInt64): &Collectible.NFT{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &Collectible.NFT
		}
		
		// Common number for all copies of the item
		access(all)
		fun getEditionNumber(id: UInt64): UInt64?{ 
			if self.ownedNFTs[id] == nil{ 
				return nil
			}
			let ref = self.getNFT(id: id)
			return ref.editionNumber
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		access(all)
		fun borrowCollectible(id: UInt64): &Collectible.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &Collectible.NFT
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
	
	access(all)
	resource NFTMinter{ 
		access(all)
		fun mintNFT(metadata: Metadata, editionNumber: UInt64): @NFT{ 
			let editionRef = Collectible.account.capabilities.get<&{Edition.EditionCollectionPublic}>(Edition.CollectionPublicPath).borrow()!
			
			// Check edition info in contract Edition in order to manage commission and all amount of copies of the same item
			assert(editionRef.getEdition(editionNumber) != nil, message: "Edition does not exist")
			var newNFT <- create NFT(initID: Collectible.totalSupply, metadata: Metadata(link: metadata.link, name: metadata.name, author: metadata.author, description: metadata.description, edition: metadata.edition, properties: metadata.properties), editionNumber: editionNumber)
			emit Created(id: Collectible.totalSupply)
			Collectible.totalSupply = Collectible.totalSupply + UInt64(1)
			return <-newNFT
		}
	}
	
	// structure for display NFTs data
	access(all)
	struct CollectibleData{ 
		access(all)
		let metadata: Collectible.Metadata
		
		access(all)
		let id: UInt64
		
		access(all)
		let editionNumber: UInt64
		
		init(metadata: Collectible.Metadata, id: UInt64, editionNumber: UInt64){ 
			self.metadata = metadata
			self.id = id
			self.editionNumber = editionNumber
		}
	}
	
	// get info for NFT including metadata
	access(all)
	fun getCollectibleDatas(address: Address): [CollectibleData]{ 
		var collectibleData: [CollectibleData] = []
		let account = getAccount(address)
		if let CollectibleCollection = account.capabilities.get<&Collectible.Collection>(self.CollectionPublicPath).borrow<&Collectible.Collection>(){ 
			for id in CollectibleCollection.getIDs(){ 
				var collectible = CollectibleCollection.borrowCollectible(id: id)
				collectibleData.append(CollectibleData(metadata: (collectible!).metadata, id: id, editionNumber: (collectible!).editionNumber))
			}
		}
		return collectibleData
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 1
		self.CollectionPublicPath = /public/NFTxtinglesCollectibleCollection
		self.CollectionStoragePath = /storage/NFTxtinglesCollectibleCollection
		self.MinterStoragePath = /storage/NFTxtinglesCollectibleMinter
		self.MinterPrivatePath = /private/NFTxtinglesCollectibleMinter
		self.account.storage.save<@{NonFungibleToken.Collection}>(<-Collectible.createEmptyCollection(nftType: Type<@Collectible.Collection>()), to: Collectible.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Collectible.Collection>(Collectible.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: Collectible.CollectionPublicPath)
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		var capability_2 = self.account.capabilities.storage.issue<&Collectible.NFTMinter>(self.MinterStoragePath)
		self.account.capabilities.publish(capability_2, at: self.MinterPrivatePath)
		emit ContractInitialized()
	}
}
