/** * SPDX-License-Identifier: MIT */
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

// Nftly
// NFT items for Nftly!
//
access(all)
contract Nftly: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, metadata:{ String: String})
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of Nftly that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// NFT
	// A Nftly Nftly as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// The token's type, e.g. 3 == Hat
		// pub let typeID: UInt64
		access(self)
		var metadata:{ String: String}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(initID: UInt64, initMetadata:{ String: String}){ 
			self.id = initID
			self.metadata = initMetadata
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
	}
	
	// This is the interface that users can cast their Nftly Collection as
	// to allow others to deposit Nftly into their Collection. It also allows for reading
	// the details of Nftly in the Collection.
	access(all)
	resource interface NftlyCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowNftly(id: UInt64): &Nftly.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Nftly reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of Nftly NFTs owned by an account
	//
	access(all)
	resource Collection: NftlyCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
			let token <- token as! @Nftly.NFT
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
		
		// Nftly
		// Gets a reference to an NFT in the collection as a Nftly,
		// exposing all of its fields (including the metadata).
		// This is safe as there are no functions that can be called on the Nftly.
		//
		access(all)
		fun borrowNftly(id: UInt64): &Nftly.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &Nftly.NFT
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}){ 
			emit Minted(id: Nftly.totalSupply, metadata: metadata)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create Nftly.NFT(initID: Nftly.totalSupply, initMetadata: metadata))
			Nftly.totalSupply = Nftly.totalSupply + 1 as UInt64
		}
	}
	
	// fetch
	// Get a reference to a Nftly from an account's Collection, if available.
	// If an account does not have a Nftly.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &Nftly.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&Nftly.Collection>(Nftly.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust Nftly.Collection.borowNftlyto get the correct itemID
		// (it checks it before returning it).
		return collection.borrowNftly(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/NftlyCollection
		self.CollectionPublicPath = /public/NftlyCollection
		self.MinterStoragePath = /storage/NftlyMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
