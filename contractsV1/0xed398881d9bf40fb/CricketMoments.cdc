// SPDX-License-Identifier: UNLICENSED
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

/**

# CricketMoments

The main contract managing the cricket moments/NFTs created by Faze.

## `NFT` Resource

Each NFT created using this contract consists of - 
- id : globally unique identifier for the NFT
- momentId : The moment of which the NFT is a copy 
- serial : serial number of this NFT
- metadata : Extra metadata for the NFT. It contains a description and an IPFS url, which 
contains the link to the video/image.


## `Collection` resource

Each account that owns cricket moments would need to have an instance
of the Collection resource stored in their account storage.

The Collection resource has methods that the owner and other users can call.

## `CricketMomentsCollectionPublic` resource interfaces

An Interface which is implemented by the collection resource. It contains 
functions for depositing moments, borrowing moments and getting id's of all
 the moments stored in the collection.  

## Locking Moments 
The NFTMinter resource can lock specific moments. After locking a particular moment, no more copies 
of that moment can be minted. Whether a moment is locked or not can also be read easily 
using isMomentLocked function. 

*/

access(all)
contract CricketMoments: NonFungibleToken{ 
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, momentId: UInt64, serial: UInt64, ipfs: String)
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let CollectionProviderPrivatePath: PrivatePath
	
	// totalSupply, the total number of CricketMoments that have been minted
	access(all)
	var totalSupply: UInt64
	
	// The total number of unique moments that have been minted
	access(all)
	var totalMomentIds: UInt64
	
	// A dictionary to track the moments that have been locked. No more copies of a locked moment can be minted
	access(self)
	var locked:{ UInt64: Bool}
	
	// A dictionary to store the next serial number to be minted for a particular moment Id. 
	access(self)
	var nextSerial:{ UInt64: UInt64}
	
	// NFT
	// A Moment as an NFT
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// Token's ID
		access(all)
		let id: UInt64
		
		// Token's momentId to identify the moment
		access(all)
		let momentId: UInt64
		
		// Token's serial number 
		access(all)
		let serial: UInt64
		
		// Token's metadata as a string dictionary
		access(self)
		let metadata:{ String: String}
		
		// initializer
		init(id: UInt64, momentId: UInt64, serial: UInt64, metadata:{ String: String}){ 
			self.id = id
			self.momentId = momentId
			self.serial = serial
			self.metadata = metadata
		}
		
		// get complete metadata
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		// get metadata field by key
		access(all)
		fun getMetadataField(key: String): String?{ 
			if let value = self.metadata[key]{ 
				return value
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// This is the interface that users can cast their CricketMoments Collection as
	// to allow others to deposit CricketMoments into their Collection. It also allows for reading
	// the details of CricketMoments in the Collection.
	access(all)
	resource interface CricketMomentsCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowCricketMoment(id: UInt64): &CricketMoments.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Moment reference: The Id of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of Moment NFTs owned by an account
	//
	access(all)
	resource Collection: CricketMomentsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @CricketMoments.NFT
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
		// so that the caller can read its id
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowCricketMoment
		// Gets a reference to an NFT in the collection as a Moment,
		// exposing all of its fields (including the momentId, serial, and metadata).
		// This is safe as there are no functions that can be called on the Moment.
		// Metadata is also a private field, therefore can't be changed using borrowed object.
		//
		access(all)
		fun borrowCricketMoment(id: UInt64): &CricketMoments.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &CricketMoments.NFT
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
		
		// mintNFTs
		// Mints multiple new NFTs with the same momentId
		// Increments serial number
		// deposits all in the recipients collection using their collection reference
		//
		access(all)
		fun mintNewNFTs(recipient: &{NonFungibleToken.CollectionPublic}, serialQuantity: UInt64, metadata:{ String: String}){ 
			var serialNumber = 1 as UInt64
			var ipfs: String = metadata["ipfs"] ?? panic("IPFS url not available")
			while serialNumber <= serialQuantity{ 
				emit Minted(id: CricketMoments.totalSupply, momentId: CricketMoments.totalMomentIds, serial: serialNumber, ipfs: ipfs)
				
				// create NFT and deposit it in the recipient's account using their reference
				recipient.deposit(token: <-create CricketMoments.NFT(id: CricketMoments.totalSupply, momentId: CricketMoments.totalMomentIds, serial: serialNumber, metadata: metadata))
				serialNumber = serialNumber + 1 as UInt64
				CricketMoments.totalSupply = CricketMoments.totalSupply + 1 as UInt64
			}
			// Save current serial number so that next copies of the same moment can start from here
			CricketMoments.nextSerial[CricketMoments.totalMomentIds] = serialNumber as UInt64
			// Initialize locked as false for a new Moment.
			CricketMoments.locked[CricketMoments.totalMomentIds] = false
			// Increment totalMomentIds
			CricketMoments.totalMomentIds = CricketMoments.totalMomentIds + 1 as UInt64
		}
		
		// Mint more NFTs for a particular momentId that already exists
		access(all)
		fun mintOldNFTs(recipient: &{NonFungibleToken.CollectionPublic}, momentId: UInt64, serialQuantity: UInt64, metadata:{ String: String}){ 
			var ipfs: String = metadata["ipfs"] ?? panic("IPFS url not available")
			var serialNumber = CricketMoments.nextSerial[momentId] ?? panic("momentId not present")
			var isLocked = CricketMoments.locked[momentId] ?? panic("momentId not present")
			if isLocked == true{ 
				panic("Moment already locked. Can't mint any more NFTs for this momentId")
			}
			var i = 1 as UInt64
			while i <= serialQuantity{ 
				emit Minted(id: CricketMoments.totalSupply, momentId: momentId, serial: serialNumber, ipfs: ipfs)
				
				// deposit it in the recipient's account using their reference
				recipient.deposit(token: <-create CricketMoments.NFT(id: CricketMoments.totalSupply, momentId: momentId, serial: serialNumber, metadata: metadata))
				serialNumber = serialNumber + 1 as UInt64
				i = i + 1 as UInt64
				CricketMoments.totalSupply = CricketMoments.totalSupply + 1 as UInt64
			}
			// Save current serial number so that next copies of the same moment can start from here
			// No need to increment totalMomentIds
			CricketMoments.nextSerial[momentId] = serialNumber
		}
		
		// Lock a particular momentId, so that no more moments with this momentId can be minted. 
		access(all)
		fun lockMoment(momentId: UInt64){ 
			if CricketMoments.locked[momentId] == nil{ 
				panic("Moment not minted yet")
			}
			CricketMoments.locked[momentId] = true
		}
	}
	
	// fetch
	// Get a reference to a CricketMoments from an account's Collection, if available.
	// If an account does not have a CricketMoments.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, id: UInt64): &CricketMoments.NFT?{ 
		let collection = getAccount(from).capabilities.get<&CricketMoments.Collection>(CricketMoments.CollectionPublicPath).borrow<&CricketMoments.Collection>() ?? panic("Couldn't get collection")
		// We trust CricketMoments.Collection.borrowMoment to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowCricketMoment(id: id)
	}
	
	// get next serial for a momentId (nextSerial -1 indicates number of copies minted for this momentId)
	access(all)
	fun getNextSerial(momentId: UInt64): UInt64?{ 
		if let nextSerial = self.nextSerial[momentId]{ 
			return nextSerial
		}
		return nil
	}
	
	// check if a moment is locked. No more copies of a locked moment can be minted 
	access(all)
	fun isMomentLocked(momentId: UInt64): Bool?{ 
		if let isLocked = self.locked[momentId]{ 
			return isLocked
		}
		return nil
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/CricketMomentsCollection
		self.CollectionPublicPath = /public/CricketMomentsCollection
		self.MinterStoragePath = /storage/CricketMomentsMinter
		self.CollectionProviderPrivatePath = /private/cricketMomentsCollectionProvider
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Initialize the total Moment IDs
		self.totalMomentIds = 0
		
		// Initialize locked and nextSerial as empty dictionaries
		self.locked ={} 
		self.nextSerial ={} 
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
