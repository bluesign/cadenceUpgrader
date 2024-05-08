import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

/*
	Description: Central Smart Contract for arbitrary ZeedzItems

	The main heros of Zeedz are Zeedles - cute little nature-inspired monsters that grow 
	with the real world weather. But there are manifold items that users can pick up
	along their journey, from Early Access keys to Zeedle wearables. These items are
	so called ZeedzItems. 
	
	This smart contract encompasses the main functionality for ZeedzItems. Since the main 
	functionality lies in their plain ownership, their design is held intentionally simple. 
	A single typeID denominates their specific type, and additional metadata can be passed
	along into a flexible {String: String} dictionary. 
*/

access(all)
contract ZeedzItems: NonFungibleToken{ 
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, metadata:{ String: String})
	
	access(all)
	event Burned(id: UInt64, from: Address?)
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	// totalSupply
	// The total number of ZeedzItems that have been minted
	access(all)
	var totalSupply: UInt64
	
	// 
	// A ZeedzItem as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// The items's type, e.g. 1 == early Acess Alpha Key
		access(all)
		let typeID: UInt64
		
		// String mapping to hold metadata
		access(self)
		let metadata:{ String: String}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		init(initID: UInt64, initTypeID: UInt64, initMetadata:{ String: String}){ 
			self.id = initID
			self.typeID = initTypeID
			self.metadata = initMetadata
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
	}
	
	//
	// This is the interface that users can cast their ZeedzItems Collection as
	// to allow others to deposit ZeedzItems into their Collection. It also allows for reading
	// the details of ZeedzItems in the Collection.
	//
	access(all)
	resource interface ZeedzItemsCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowZeedzItem(id: UInt64): &ZeedzItems.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow ZeedzItem reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// 
	// This is the interface that users can cast their ZeedzItems Collection as
	// to allow themselves to call the burn function on their own collection.
	// 
	access(all)
	resource interface ZeedzItemsCollectionPrivate{ 
		access(all)
		fun burn(burnID: UInt64)
	}
	
	// 
	// A collection of ZeedzItem NFTs owned by an account
	//
	access(all)
	resource Collection: ZeedzItemsCollectionPublic, ZeedzItemsCollectionPrivate, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Not able to find specified NFT within the owner's collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun burn(burnID: UInt64){ 
			let token <- self.ownedNFTs.remove(key: burnID) ?? panic("Not able to find specified NFT within the owner's collection")
			destroy token
			emit Burned(id: burnID, from: self.owner?.address)
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @ZeedzItems.NFT
			let id: UInt64 = token.id
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs
		// Returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// borrowZeedzItem
		// Gets a reference to an NFT in the collection as a ZeedzItem,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the ZeedzItem.
		access(all)
		fun borrowZeedzItem(id: UInt64): &ZeedzItems.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &ZeedzItems.NFT
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
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	//
	// A public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	//
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource Administrator{ 
		
		// 
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, typeID: UInt64, metadata:{ String: String}){ 
			emit Minted(id: ZeedzItems.totalSupply, metadata: metadata)
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create ZeedzItems.NFT(initID: ZeedzItems.totalSupply, initTypeID: typeID, initMetadata: metadata))
			ZeedzItems.totalSupply = ZeedzItems.totalSupply + 1 as UInt64
		}
	}
	
	// 
	// Get a reference to a ZeedzItem from an account's Collection, if available.
	// If an account does not have a ZeedzItems.Collection, panic.
	// If it has a collection but does not contain the itemId, return nil.
	// If it has a collection and that collection contains the itemId, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &ZeedzItems.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&ZeedzItems.Collection>(ZeedzItems.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust ZeedzItems.Collection.borowZeedzItem to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowZeedzItem(id: itemID)
	}
	
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/ZeedzItemsCollection
		self.CollectionPublicPath = /public/ZeedzItemsCollection
		self.AdminStoragePath = /storage/ZeedzItemsMinter
		self.AdminPrivatePath = /private/ZeedzItemsAdminPrivate
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Admin resource and save it to storage
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Administrator>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath)
		emit ContractInitialized()
	}
}
