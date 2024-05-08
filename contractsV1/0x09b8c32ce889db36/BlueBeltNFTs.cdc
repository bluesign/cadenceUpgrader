//SPDX-License-Identifier: MIT License
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract BlueBeltNFTs: NonFungibleToken{ 
	
	// Events 
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, typeID: UInt64)
	
	access(all)
	event TokensBurned(id: UInt64)
	
	access(all)
	event Price(price: String)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let BurnerStoragePath: StoragePath
	
	// totalSupply
	// The total number of BlueBeltNFTs that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// Requirement that all conforming NFT smart contracts have
	// to define a resource called NFT that conforms to INFT
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// The token's type, e.g. 3 == Hat
		access(all)
		let typeID: UInt64
		
		// String mapping to hold metadata
		access(self)
		var metadata:{ String: String}
		
		// String mapping to hold metadata
		access(all)
		var urlData: String
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(initID: UInt64, initTypeID: UInt64, urlData: String, metadata:{ String: String}?){ 
			self.id = initID
			self.typeID = initTypeID
			self.urlData = urlData
			self.metadata = metadata ??{} 
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
	}
	
	// This is the interface that users can cast their BlueBeltNFTs Collection as
	// to allow others to deposit BlueBeltNFTs into their Collection. It also allows for reading
	// the details of BlueBeltNFTs in the Collection.
	access(all)
	resource interface BlueBeltNFTsCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowBlueBelt(id: UInt64): &BlueBeltNFTs.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow BlueBelt reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		fun notifyPrice(_price: String)
	}
	
	// Requirement for the the concrete resource type
	// to be declared in the implementing contract
	//
	access(all)
	resource Collection: BlueBeltNFTsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		
		// Dictionary to hold the NFTs in the Collection
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// send price to flow scan 
		access(all)
		fun notifyPrice(_price: String){ 
			emit Price(price: _price)
		}
		
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
			let token <- token as! @BlueBeltNFTs.NFT
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
		
		// borrowBlueBelt
		// Gets a reference to an NFT in the collection as a Idol,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the Idol.
		//
		access(all)
		fun borrowBlueBelt(id: UInt64): &BlueBeltNFTs.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &BlueBeltNFTs.NFT
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
	
	// createEmptyCollection creates an empty Collection
	// and returns it to the caller so that they can own NFTs
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
		fun mintNFT(recipient: &{BlueBeltNFTs.BlueBeltNFTsCollectionPublic}, typeID: UInt64, urlData: String, metadata:{ String: String}){ 
			// deposit it in the recipient's account using their reference
			BlueBeltNFTs.totalSupply = BlueBeltNFTs.totalSupply + 1 as UInt64
			recipient.deposit(token: <-create BlueBeltNFTs.NFT(initID: BlueBeltNFTs.totalSupply, initTypeID: typeID, urlData: urlData, metadata: metadata))
			emit Minted(id: BlueBeltNFTs.totalSupply, typeID: typeID)
		}
	}
	
	// fetch
	// Get a reference to a IdolNFT from an account's Collection, if available.
	// If an account does not have a BlueBeltNFTs.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &BlueBeltNFTs.NFT?{ 
		let collection = getAccount(from).capabilities.get<&BlueBeltNFTs.Collection>(BlueBeltNFTs.CollectionPublicPath).borrow<&BlueBeltNFTs.Collection>() ?? panic("Couldn't get collection")
		// We trust BlueBeltNFTs.Collection.borowIdol to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowBlueBelt(id: itemID)
	}
	
	access(all)
	resource NFTBurner{ 
		access(all)
		fun burn(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @BlueBeltNFTs.NFT
			let id: UInt64 = token.id
			destroy token
			emit TokensBurned(id: id)
		}
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/BlueBeltNFTsCollection
		self.CollectionPublicPath = /public/BlueBeltNFTsPublicCollection
		self.MinterStoragePath = /storage/BlueBeltNFTsMinter
		self.BurnerStoragePath = /storage/BlueBeltNFTsBurner
		
		// Initialize the total supply
		self.totalSupply = 0
		// store an empty NFT Collection in account storage
		self.account.storage.save(<-self.createEmptyCollection(nftType: Type<@Collection>()), to: self.CollectionStoragePath)
		
		// publish a reference to the Collection in storage
		var capability_1 = self.account.capabilities.storage.issue<&{BlueBeltNFTs.BlueBeltNFTsCollectionPublic}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		let burner <- create NFTBurner()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		self.account.storage.save(<-burner, to: self.BurnerStoragePath)
		emit ContractInitialized()
	}
}
