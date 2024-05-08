import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract SherpaItems: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, kind: UInt8, rarity: UInt8)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of SherpaItems that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	access(all)
	enum Rarity: UInt8{ 
		access(all)
		case standard
		
		access(all)
		case special
	}
	
	access(all)
	fun rarityToString(_ rarity: Rarity): String{ 
		switch rarity{ 
			case Rarity.standard:
				return "standard"
			case Rarity.special:
				return "special"
		}
		return ""
	}
	
	access(all)
	enum Kind: UInt8{ 
		access(all)
		case membership
		
		access(all)
		case collectable
	}
	
	access(all)
	fun kindToString(_ kind: Kind): String{ 
		switch kind{ 
			case Kind.membership:
				return "Membership"
			case Kind.collectable:
				return "Collectable"
		}
		return ""
	}
	
	// Mapping from item (kind, rarity) -> IPFS image CID
	//
	access(self)
	var images:{ Kind:{ Rarity: String}}
	
	// Mapping from rarity -> price
	//
	access(self)
	var itemRarityPriceMap:{ Rarity: UFix64}
	
	// Return the initial sale price for an item of this rarity.
	//
	access(all)
	fun getItemPrice(rarity: Rarity): UFix64{ 
		return self.itemRarityPriceMap[rarity]!
	}
	
	// A Sherpa Item as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		// The token kind (e.g. Membership)
		access(all)
		let kind: Kind
		
		// The token rarity (e.g. Standard)
		access(all)
		let rarity: Rarity
		
		init(id: UInt64, kind: Kind, rarity: Rarity){ 
			self.id = id
			self.kind = kind
			self.rarity = rarity
		}
		
		access(all)
		fun name(): String{ 
			return SherpaItems.rarityToString(self.rarity).concat(" ").concat(SherpaItems.kindToString(self.kind))
		}
		
		access(all)
		fun description(): String{ 
			return "A ".concat(SherpaItems.rarityToString(self.rarity).toLower()).concat(" ").concat(SherpaItems.kindToString(self.kind).toLower()).concat(" with serial number ").concat(self.id.toString())
		}
		
		access(all)
		fun imageCID(): String{ 
			return (SherpaItems.images[self.kind]!)[self.rarity]!
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "Sherpa Tea Club Membership", description: self.description(), thumbnail: MetadataViews.IPFSFile(cid: self.imageCID(), path: "sm.png"))
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// This is the interface that users can cast their SherpaItems Collection as
	// to allow others to deposit SherpaItems into their Collection. It also allows for reading
	// the details of SherpaItems in the Collection.
	access(all)
	resource interface SherpaItemsCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowSherpaItem(id: UInt64): &SherpaItems.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow SherpaItem reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of SherpaItem NFTs owned by an account
	//
	access(all)
	resource Collection: SherpaItemsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
			let token <- token as! @SherpaItems.NFT
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
		
		// borrowSherpaItem
		// Gets a reference to an NFT in the collection as a SherpaItem,
		// exposing all of its fields (including the typeID & rarityID).
		// This is safe as there are no functions that can be called on the SherpaItem.
		//
		access(all)
		fun borrowSherpaItem(id: UInt64): &SherpaItems.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &SherpaItems.NFT
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, kind: Kind, rarity: Rarity){ 
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create SherpaItems.NFT(id: SherpaItems.totalSupply, kind: kind, rarity: rarity))
			emit Minted(id: SherpaItems.totalSupply, kind: kind.rawValue, rarity: rarity.rawValue)
			SherpaItems.totalSupply = SherpaItems.totalSupply + 1 as UInt64
		}
	}
	
	// fetch
	// Get a reference to a SherpaItem from an account's Collection, if available.
	// If an account does not have a SherpaItems.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &SherpaItems.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&SherpaItems.Collection>(SherpaItems.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust SherpaItems.Collection.borowSherpaItem to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowSherpaItem(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// set rarity price mapping
		self.itemRarityPriceMap ={ Rarity.standard: 115.0, Rarity.special: 250.0}
		self.images ={ Kind.membership:{ Rarity.standard: "QmTrVcndMLgX8ybTbEd4D1yUPE5WA2wVuMxqthUEHn3xXw", Rarity.special: "QmTrVcndMLgX8ybTbEd4D1yUPE5WA2wVuMxqthUEHn3xXw"}, Kind.collectable:{ Rarity.standard: "QmTrVcndMLgX8ybTbEd4D1yUPE5WA2wVuMxqthUEHn3xXw", Rarity.special: "QmTrVcndMLgX8ybTbEd4D1yUPE5WA2wVuMxqthUEHn3xXw"}}
		
		// Set our named paths
		self.CollectionStoragePath = /storage/sherpaItemsCollectionV10
		self.CollectionPublicPath = /public/sherpaItemsCollectionV10
		self.MinterStoragePath = /storage/sherpaItemsMinterV10
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
