import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Flex: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, projectName: String, projectID: String)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of Flex that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	access(self)
	var nameData:{ String: String}
	
	// A Flex as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let description: String
		
		access(all)
		let name: String
		
		access(all)
		let image: String
		
		access(all)
		fun getImage(): String{ 
			return self.image
		}
		
		access(all)
		let projectID: String
		
		access(all)
		fun getProjectID(): String{ 
			return self.projectID
		}
		
		access(all)
		let projectName: String
		
		access(all)
		fun getProjectName(): String{ 
			return self.projectName
		}
		
		access(self)
		let attributes:{ String: String}
		
		access(all)
		fun getAttributes():{ String: String}{ 
			return self.attributes
		}
		
		access(self)
		let metadata:{ String: String}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		init(id: UInt64, description: String, name: String, image: String, projectID: String, projectName: String, attributes:{ String: String}, metadata:{ String: String}, royalties: [MetadataViews.Royalty]){ 
			self.id = id
			self.description = description
			self.name = name
			self.image = image
			self.projectID = projectID
			self.projectName = projectName
			self.attributes = attributes
			self.metadata = metadata
			self.royalties = royalties
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.IPFSFile(cid: self.image, path: "sm.png"))
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// This is the interface that users can cast their Flex Collection as
	// to allow others to deposit Flex into their Collection. It also allows for reading
	// the details of Flex in the Collection.
	access(all)
	resource interface FlexCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowFlex(id: UInt64): &Flex.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Flex reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of Flex NFTs owned by an account
	//
	access(all)
	resource Collection: FlexCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
			let token <- token as! @Flex.NFT
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
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowFlex
		// Gets a reference to an NFT in the collection as a Flex,
		// exposing all of its fields (including the typeID & rarityID).
		// This is safe as there are no functions that can be called on the Flex.
		//
		access(all)
		fun borrowFlex(id: UInt64): &Flex.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Flex.NFT
			}
			return nil
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, description: String, name: String, image: String, projectID: String, projectName: String, attributes:{ String: String}, metadata:{ String: String}, royalties: [MetadataViews.Royalty]){ 
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create Flex.NFT(id: Flex.totalSupply, description: description, name: name, image: image, projectID: projectID, projectName: projectName, attributes: attributes, metadata: metadata, royalties: royalties))
			emit Minted(id: Flex.totalSupply, projectName: projectName, projectID: projectID)
			Flex.totalSupply = Flex.totalSupply + 1 as UInt64
		}
	}
	
	// fetch
	// Get a reference to a Flex from an account's Collection, if available.
	// If an account does not have a Flex.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &Flex.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&Flex.Collection>(Flex.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust Flex.Collection.borowFlex to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowFlex(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// set rarity price mapping
		
		// Set our named paths
		self.CollectionStoragePath = /storage/FlexCollections
		self.CollectionPublicPath = /public/FlexCollections
		self.MinterStoragePath = /storage/FlexMinters
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Initialize the name data
		self.nameData ={} 
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&Flex.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
