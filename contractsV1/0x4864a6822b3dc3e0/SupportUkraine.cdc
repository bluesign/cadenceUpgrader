import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract SupportUkraine: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, name: String)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of SupportUkraine that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// A SupportUkraine as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let description: String
		
		access(all)
		let image: String
		
		access(all)
		let name: String
		
		access(all)
		let series: String
		
		init(id: UInt64, description: String, image: String, name: String, series: String){ 
			self.id = id
			self.description = description
			self.image = image
			self.name = name
			self.series = series
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.IPFSFile(cid: self.image, path: "sm.png"))
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// This is the interface that users can cast their SupportUkraine Collection as
	// to allow others to deposit SupportUkraine into their Collection. It also allows for reading
	// the details of SupportUkraine in the Collection.
	access(all)
	resource interface SupportUkraineCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowSupportUkraine(id: UInt64): &SupportUkraine.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow SupportUkraine reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of SupportUkraine NFTs owned by an account
	//
	access(all)
	resource Collection: SupportUkraineCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
			let token <- token as! @SupportUkraine.NFT
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
		
		// borrowSupportUkraine
		// Gets a reference to an NFT in the collection as a SupportUkraine,
		// exposing all of its fields (including the typeID & rarityID).
		// This is safe as there are no functions that can be called on the SupportUkraine.
		//
		access(all)
		fun borrowSupportUkraine(id: UInt64): &SupportUkraine.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &SupportUkraine.NFT
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, description: String, image: String, name: String, series: String){ 
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create SupportUkraine.NFT(id: SupportUkraine.totalSupply, description: description, image: image, name: name, series: series))
			emit Minted(id: SupportUkraine.totalSupply, name: name)
			SupportUkraine.totalSupply = SupportUkraine.totalSupply + 1 as UInt64
		}
	}
	
	// fetch
	// Get a reference to a SupportUkraine from an account's Collection, if available.
	// If an account does not have a SupportUkraine.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &SupportUkraine.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&SupportUkraine.Collection>(SupportUkraine.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust SupportUkraine.Collection.borowSupportUkraine to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowSupportUkraine(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// set rarity price mapping
		
		// Set our named paths
		self.CollectionStoragePath = /storage/SupportUkraineCollectionV10
		self.CollectionPublicPath = /public/SupportUkraineCollectionV10
		self.MinterStoragePath = /storage/SupportUkraineMinterV10
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
