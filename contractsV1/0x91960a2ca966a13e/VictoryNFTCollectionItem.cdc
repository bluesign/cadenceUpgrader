// NonFungibleToken - MAINNET
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

// VictoryNFTCollectionItem
// NFT items for Victory Collection
//
access(all)
contract VictoryNFTCollectionItem: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, typeID: UInt64, brandID: UInt64, dropID: UInt64)
	
	access(all)
	event HashUpdated(id: UInt64)
	
	access(all)
	event MetaUpdated(id: UInt64)
	
	access(all)
	event Geolocated(id: UInt64)
	
	access(all)
	event BundleCreated(owner: Address, id: UInt64)
	
	access(all)
	event BundleRemoved(owner: Address, id: UInt64)
	
	access(all)
	event AllBundlesRemoved(owner: Address)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of VictoryNFTCollectionItem that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// NFT
	// A Victory Collectible as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// Original owner (for revenue sharing)
		access(all)
		let originalOwner: Address
		
		// The token's ID
		access(all)
		let id: UInt64
		
		// The token's type, e.g. 0 == Art
		access(all)
		let typeID: UInt64
		
		// The token's brand ID, e.g. 0 == Victory
		access(all)
		let brandID: UInt64
		
		// The token's drop ID, e.g. 0 == None
		access(all)
		let dropID: UInt64
		
		// The token's issue number
		access(all)
		let issueNum: UInt32
		
		// How many tokens were issued
		access(all)
		let maxIssueNum: UInt32
		
		// The token's content hash
		access(all)
		let contentHash: UInt256
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(initOwner: Address, initID: UInt64, initTypeID: UInt64, initBrandID: UInt64, initDropID: UInt64, initHash: UInt256, initIssueNum: UInt32, initMaxIssueNum: UInt32){ 
			self.originalOwner = initOwner
			self.id = initID
			self.typeID = initTypeID
			self.brandID = initBrandID
			self.dropID = initDropID
			self.contentHash = initHash
			self.issueNum = initIssueNum
			self.maxIssueNum = initMaxIssueNum
		}
	}
	
	// This is the interface that users can cast their VictoryNFTCollectionItem Collection as
	// to allow others to deposit VictoryNFTCollectionItem into their Collection. It also allows for reading
	// the details of VictoryNFTCollectionItem in the Collection.
	access(all)
	resource interface VictoryNFTCollectionItemCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun getBundleIDs(bundleID: UInt64): [UInt64]
		
		access(all)
		fun getNextBundleID(): UInt64
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun isNFTForSale(id: UInt64): Bool
		
		access(all)
		fun borrowVictoryItem(id: UInt64): &VictoryNFTCollectionItem.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow VictoryItem reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// The interface that users can use to manage their own bundles for sale
	access(all)
	resource interface VictoryNFTCollectionItemBundle{ 
		access(all)
		fun createBundle(itemIDs: [UInt64]): UInt64
		
		access(all)
		fun removeBundle(bundleID: UInt64)
		
		access(all)
		fun removeAllBundles()
	}
	
	// Collection
	// A collection of Victory Collection NFTs owned by an account
	//
	access(all)
	resource Collection: VictoryNFTCollectionItemCollectionPublic, VictoryNFTCollectionItemBundle, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// dictionary of bundles for sale
		access(contract)
		var bundles:{ UInt64: [UInt64]}
		
		// ID for next bundle
		access(all)
		var nextBundleID: UInt64
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			
			// also delete any bundle that this item was part of
			for key in self.bundles.keys{ 
				if (self.bundles[key]!).contains(withdrawID){ 
					self.bundles.remove(key: key)
					emit BundleRemoved(owner: self.owner?.address!, id: key)
					break
				}
			}
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit
		// Takes an NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @VictoryNFTCollectionItem.NFT
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
		
		// getBundleIDs
		// Returns an array of the IDs that are in the specified bundle
		//
		access(all)
		fun getBundleIDs(bundleID: UInt64): [UInt64]{ 
			return self.bundles[bundleID] ?? panic("Bundle does not exist")
		}
		
		// getNextBundleID
		// Returns the next bundle ID
		//
		access(all)
		fun getNextBundleID(): UInt64{ 
			return self.nextBundleID
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// isNFTForSale
		// Gets a reference to an NFT in the collection as a VictoryItem,
		access(all)
		fun isNFTForSale(id: UInt64): Bool{ 
			for key in self.bundles.keys{ 
				if (self.bundles[key]!).contains(id){ 
					return true
				}
			}
			return false
		}
		
		// borrowVictoryItem
		// Gets a reference to an NFT in the collection as a VictoryItem,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the VictoryItem.
		//
		access(all)
		fun borrowVictoryItem(id: UInt64): &VictoryNFTCollectionItem.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &VictoryNFTCollectionItem.NFT
			} else{ 
				return nil
			}
		}
		
		// createBundle
		// Creates a new array of itemIDs which can be used to list multiple items
		// for sale as one bundle
		// Returns the id of the bundle
		access(all)
		fun createBundle(itemIDs: [UInt64]): UInt64{ 
			var bundle: [UInt64] = []
			for id in itemIDs{ 
				if self.isNFTForSale(id: id){ 
					panic("Item is already part of a bundle!")
				}
				bundle.append(id)
			}
			let id = self.nextBundleID
			self.bundles[id] = bundle
			self.nextBundleID = self.nextBundleID + 1 as UInt64
			emit BundleCreated(owner: self.owner?.address!, id: id)
			return id
		}
		
		// removeBundle
		// Removes the specified bundle from the dictionary
		access(all)
		fun removeBundle(bundleID: UInt64){ 
			for key in self.bundles.keys{ 
				if key == bundleID{ 
					self.bundles.remove(key: bundleID)
					emit BundleRemoved(owner: self.owner?.address!, id: bundleID)
					return
				}
			}
			panic("Bundle does not exist")
		}
		
		// removeAllBundles
		// Removes all bundles from the dictionary - use with caution!
		// Note: nextBundleID is *not* set to 0 to avoid unexpected collision
		access(all)
		fun removeAllBundles(){ 
			self.bundles ={} 
			emit AllBundlesRemoved(owner: self.owner?.address!)
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
			self.bundles ={} 
			self.nextBundleID = 0
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, owner: Address, typeID: UInt64, brandID: UInt64, dropID: UInt64, contentHash: UInt256, startIssueNum: UInt32, maxIssueNum: UInt32, totalIssueNum: UInt32){ 
			var i: UInt32 = 0
			while i < maxIssueNum{ 
				emit Minted(id: VictoryNFTCollectionItem.totalSupply, typeID: typeID, brandID: brandID, dropID: dropID)
				
				// deposit it in the recipient's account using their reference
				recipient.deposit(token: <-create VictoryNFTCollectionItem.NFT(initOwner: owner, initID: VictoryNFTCollectionItem.totalSupply, initTypeID: typeID, initBrandID: brandID, initDropID: dropID, initHash: contentHash, initIssueNum: i + startIssueNum, initMaxIssueNum: totalIssueNum))
				VictoryNFTCollectionItem.totalSupply = VictoryNFTCollectionItem.totalSupply + 1 as UInt64
				i = i + 1 as UInt32
			}
		}
	}
	
	// fetch
	// Get a reference to a VictoryItem from an account's Collection, if available.
	// If an account does not have a VictoryNFTCollectionItem.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &VictoryNFTCollectionItem.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&VictoryNFTCollectionItem.Collection>(VictoryNFTCollectionItem.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust VictoryNFTCollectionItem.Collection.borowVictoryItem to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowVictoryItem(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/VictoryNFTCollectionItemCollection
		self.CollectionPublicPath = /public/VictoryNFTCollectionItemCollection
		self.MinterStoragePath = /storage/VictoryNFTCollectionItemMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
