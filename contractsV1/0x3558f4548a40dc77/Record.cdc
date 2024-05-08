/**  
# Contract defining records and songs. 

## Record:
A record is the unique issuance of a song. 
It holds the information including song title, artist, description, cover image address (an IPFS CID) and audio address (IPFS CID). 

Songs are by default hidden, meaning the audio file is encrypted. The holder can decide to reveal the song (publish the decryption key). 
Publishing the decryption key is done by an admin when the resource is made accessible in "unlocked" mode. 
Once the decryption key has been set, it cannot be changed again.

A record unlocked but without an decryption key should be prevented from being set for auction or for sale. 
It represents the case when the song has been unlock but the admin is still uploading the encryption key. 
We do not want buyers to bid on a song they think is still unreleased, and then discover is was being released. 
If the owner wants to cancel the publication of the key before it has been done, they can call the `lock` function.

A record points to an artist, defined by an ID. An artist registery is held so that the artist share can be sent correctly after sales and auctions.
**/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ArtistRegistery from "./ArtistRegistery.cdc"

access(all)
contract Record: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// Variables 
	// -----------------------------------------------------------------------
	
	// Access paths
	//
	// Public path allowing deposits, listing of IDs and access to records metadata
	access(all)
	let CollectionPublicPath: PublicPath
	
	// Private path allowing withdrawals on top of the public access
	// Useful for SaleCollection requiring withdrawals, but protecting lock/unlock functions
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	// Storage path of the collection of records owned
	access(all)
	let CollectionStoragePath: StoragePath
	
	// Storage path of the Admin, responsible for uploading decryption keys
	access(all)
	let AdminStoragePath: StoragePath
	
	// Storage path of the miner responsible for creating new records
	access(all)
	let MinterStoragePath: StoragePath
	
	// The total number of Record NFTs that have been created
	access(all)
	var totalSupply: UInt64
	
	// -----------------------------------------------------------------------
	// Events
	// -----------------------------------------------------------------------
	// Emitted when the contract is created
	access(all)
	event ContractInitialized()
	
	// Emitted when a new record is minted
	access(all)
	event RecordMinted(id: UInt64, metadata: Metadata)
	
	// Emited when a record is deleted 
	access(all)
	event RecordDestroyed(id: UInt64)
	
	// Emited when a record is locked 
	access(all)
	event RecordLocked(id: UInt64)
	
	// Emited when a record is unlocked 
	access(all)
	event RecordUnlocked(id: UInt64)
	
	// Emitted when a record audio key is published
	access(all)
	event RecordKeyUploaded(id: UInt64, audiokey: String)
	
	// Emitted when a record is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when a record is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// -----------------------------------------------------------------------
	// Resources
	// -----------------------------------------------------------------------
	// Structure representing the metadata of a record
	access(all)
	struct Metadata{ 
		access(all)
		let title: String // title of the record
		
		
		access(all)
		let artistID: UInt64 // this ID can be used in the ArtistRegistery contract functions
		
		
		access(all)
		let description: String // description an artist can write about the record
		
		
		access(all)
		let audioaddr: String // record audio address (IPFS CID)
		
		
		access(all)
		let coveraddr: String // cover image address (IPFS CID)
		
		
		init(title: String, artistID: UInt64, description: String, audioaddr: String, coveraddr: String){ 
			self.title = title
			self.artistID = artistID
			self.description = description
			self.audioaddr = audioaddr
			self.coveraddr = coveraddr
		}
	}
	
	// Interface for records when accessed publicly
	access(all)
	resource interface Public{ 
		access(all)
		let id: UInt64
		
		access(all)
		let metadata: Metadata
		
		access(all)
		var audiokey: String?
		
		// Whether the record decryption key is locked
		access(all)
		fun isLocked(): Bool
		
		// Whether the record decryption key is unlocked but unset yet
		access(all)
		fun tradable(): Bool
		
		// this function can only be called by the admin, and will fail if the record is still locked
		access(contract)
		fun setAudioKey(audiokey: String)
	}
	
	// Resource representing a unique song. Can only be created by a minter
	access(all)
	resource NFT: NonFungibleToken.NFT, Public{ 
		
		// Unique ID for the record
		access(all)
		let id: UInt64
		
		access(all)
		let metadata: Metadata
		
		access(all)
		var audiokey: String? // key used to decrypt the audio content
		
		
		access(all)
		var locked: Bool
		
		init(metadata: Metadata){ 
			pre{ 
				metadata.artistID <= ArtistRegistery.numberOfArtists:
					"This artistID does not exist"
			}
			Record.totalSupply = Record.totalSupply + 1 as UInt64
			self.id = Record.totalSupply
			self.metadata = metadata
			self.audiokey = nil
			self.locked = true
			emit RecordMinted(id: self.id, metadata: self.metadata)
		}
		
		// attach the url to a newly released song, when is unlocked
		access(contract)
		fun setAudioKey(audiokey: String){ 
			pre{ 
				self.audiokey == nil:
					"The key has already been set."
				!self.locked:
					"This record is locked"
			}
			self.audiokey = audiokey
			emit RecordKeyUploaded(id: self.id, audiokey: audiokey)
		}
		
		access(contract)
		fun lock(){ 
			self.locked = true
			emit RecordLocked(id: self.id)
		}
		
		access(contract)
		fun unlock(){ 
			self.locked = false
			emit RecordUnlocked(id: self.id)
		}
		
		access(all)
		fun isLocked(): Bool{ 
			return self.locked
		}
		
		access(all)
		fun tradable(): Bool{ 
			return self.locked || self.audiokey != nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Admin resource
	//
	// Can create new admins and set decryption keys of unlocked songs
	access(all)
	resource Admin{ 
		
		// Publish the decryption key of the record `id` from the given collection
		access(all)
		fun setRecordAudioKey(collection: &Collection, id: UInt64, audiokey: String){ 
			(collection.borrowRecord(recordID: id)!).setAudioKey(audiokey: audiokey)
		}
		
		// New admins can be created by an admin.
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
		
		// New minters can be created by an admin.
		access(all)
		fun createNewMinter(): @Minter{ 
			return <-create Minter()
		}
	}
	
	// Minter resource
	//
	// A minter is responsible for minting new records
	access(all)
	resource Minter{ 
		
		// Mint a new record with the given information
		access(all)
		fun mintRecord(title: String, artistID: UInt64, description: String, audioaddr: String, coveraddr: String): @Record.NFT{ 
			let record <- create NFT(metadata: Metadata(title: title, artistID: artistID, description: description, audioaddr: audioaddr, coveraddr: coveraddr))
			return <-record
		}
	}
	
	// Public interface for a record collection. 
	// It allows someone to check what is inside someone's collection or to deposit a record in it.
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowRecord(recordID: UInt64): &{Record.Public}?{ 
			post{ 
				result == nil || result?.id == recordID:
					"Cannot borrow Record reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// A collection of one's records
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// Withdraw a given record from the collection
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			
			// Remove the nft from the Collection
			let record <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Record does not exist in the collection")
			emit Withdraw(id: record.id, from: self.owner?.address)
			return <-record
		}
		
		// Deposit a record
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			
			// Cast the deposited record as a Record NFT to make sure
			// it is the correct type
			let token <- token as! @Record.NFT
			let id = token.id
			let oldRecord <- self.ownedNFTs[id] <- token
			
			// Only emit a deposit event if the Collection 
			// is in an account's storage
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			destroy oldRecord
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// Get and NFT as a NonFungibleToken.NFT reference
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// Get and NFT as a Record.Public reference
		access(all)
		fun borrowRecord(recordID: UInt64): &{Record.Public}?{ 
			if self.ownedNFTs[recordID] != nil{ 
				let ref = &self.ownedNFTs[recordID] as &{NonFungibleToken.NFT}?
				return ref as! &Record.NFT
			} else{ 
				return nil
			}
		}
		
		// Lock the requested record 
		access(all)
		fun lockRecord(recordID: UInt64){ 
			pre{ 
				self.ownedNFTs[recordID] != nil:
					"The requested record cannot be found in the collection"
			}
			if self.ownedNFTs[recordID] != nil{ 
				let refNFT = &self.ownedNFTs[recordID] as &{NonFungibleToken.NFT}?
				let refRecord = refNFT as! &Record.NFT
				refRecord.lock()
			}
		}
		
		// Unlock the requested record 
		access(all)
		fun unlockRecord(recordID: UInt64){ 
			pre{ 
				self.ownedNFTs[recordID] != nil:
					"The requested record cannot be found in the collection"
			}
			if self.ownedNFTs[recordID] != nil{ 
				let refNFT = &self.ownedNFTs[recordID] as &{NonFungibleToken.NFT}?
				let refRecord = refNFT as! &Record.NFT
				refRecord.unlock()
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
	}
	
	// -----------------------------------------------------------------------
	// Contract public functions
	// -----------------------------------------------------------------------
	// Create a collection to hold records
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Record.Collection()
	}
	
	// -----------------------------------------------------------------------
	// Initialization function
	// -----------------------------------------------------------------------
	init(){ 
		self.CollectionPublicPath = /public/boulangeriev1RecordCollection
		self.CollectionPrivatePath = /private/boulangeriev1RecordCollection
		self.CollectionStoragePath = /storage/boulangeriev1RecordCollection
		self.AdminStoragePath = /storage/boulangeriev1RecordAdminStorage
		self.MinterStoragePath = /storage/boulangeriev1RecordMinterStorage
		self.totalSupply = 0
		self.account.storage.save<@Collection>(<-create Collection(), to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		var capability_2 = self.account.capabilities.storage.issue<&Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: self.CollectionPrivatePath)
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		self.account.storage.save<@Minter>(<-create Minter(), to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
