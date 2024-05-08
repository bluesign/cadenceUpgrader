/*
	Author: Jude Zhu jude.zhu@dapperlabs.com
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

/*
	There are 2 levels of entity:
	1. Edition
	2. NFT
	
	An Edition is created with metadata. NFTs are minted out of Editions.
 */

// The AllDaySeasonal contract
//
access(all)
contract AllDaySeasonal: NonFungibleToken{ 
	//------------------------------------------------------------
	// Events
	//------------------------------------------------------------
	
	// Contract Events
	//
	access(all)
	event ContractInitialized()
	
	// NFT Collection Events
	//
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Burned(id: UInt64)
	
	access(all)
	event Minted(id: UInt64, editionID: UInt64)
	
	// Edition Events
	//
	// Emitted when a new edition has been created by an admin.
	access(all)
	event EditionCreated(id: UInt64, metadata:{ String: String})
	
	// Emitted when an edition is closed.
	access(all)
	event EditionClosed(id: UInt64)
	
	//------------------------------------------------------------
	// Named values
	//------------------------------------------------------------
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let MinterPrivatePath: PrivatePath
	
	//------------------------------------------------------------
	// Publicly readable contract state
	//------------------------------------------------------------
	// totalSupply
	// The total number of NFTs that in circulation.
	//
	access(all)
	var totalSupply: UInt64
	
	// totalEditions
	// The total number of editions that have been created.
	//
	access(all)
	var totalEditions: UInt64
	
	// nextEditionID
	// The editionID will be assigned to the next edition.
	//
	access(all)
	var nextEditionID: UInt64
	
	//------------------------------------------------------------
	// Internal contract state
	//------------------------------------------------------------
	// Metadata Dictionaries
	//
	// This is so we can find Edition via ID.
	access(self)
	let editionByID: @{UInt64: Edition}
	
	//------------------------------------------------------------
	// Edition
	//------------------------------------------------------------
	// A public struct to access Edition data
	//
	access(all)
	struct EditionData{ 
		access(all)
		let id: UInt64
		
		access(all)
		var numMinted: UInt64
		
		access(all)
		var active: Bool
		
		access(all)
		let metadata:{ String: String}
		
		// initializer
		//
		view init(id: UInt64){ 
			if let edition = &AllDaySeasonal.editionByID[id] as &AllDaySeasonal.Edition?{ 
				self.id = id
				self.metadata = *edition.metadata
				self.numMinted = edition.numMinted
				self.active = edition.active
			} else{ 
				panic("edition does not exist")
			}
		}
	}
	
	// A top level Edition with a unique ID
	//
	access(all)
	resource Edition{ 
		access(all)
		let id: UInt64
		
		// Contents writable if borrowed!
		// This is deliberate, as it allows admins to update the data.
		access(all)
		var numMinted: UInt64
		
		access(all)
		let metadata:{ String: String}
		
		access(all)
		var active: Bool
		
		// Close this edition
		//
		access(all)
		fun close(){ 
			pre{ 
				self.active:
					"edtion is already closed"
			}
			self.active = false
			emit EditionClosed(id: self.id)
		}
		
		// Mint a Seasonal NFT in this edition, with the given minting mintingDate.
		// Note that this will panic if the max mint size has already been reached.
		//
		access(all)
		fun mint(): @AllDaySeasonal.NFT{ 
			pre{ 
				self.active:
					"edition is already closed. minting is not allowed"
			}
			
			// Create thek NFT, filled out with our information
			let nft <- create NFT(editionID: self.id)
			AllDaySeasonal.totalSupply = AllDaySeasonal.totalSupply + 1
			// Keep a running total (you'll notice we used this as the serial number)
			self.numMinted = self.numMinted + 1 as UInt64
			return <-nft
		}
		
		// initializer
		//
		init(metadata:{ String: String}){ 
			self.id = AllDaySeasonal.nextEditionID
			self.metadata = metadata
			self.numMinted = 0 as UInt64
			self.active = true
			AllDaySeasonal.nextEditionID = self.id + 1 as UInt64
			emit EditionCreated(id: self.id, metadata: self.metadata)
		}
	}
	
	// Get the publicly available data for a Edition
	//
	access(all)
	fun getEditionData(id: UInt64): AllDaySeasonal.EditionData{ 
		pre{ 
			AllDaySeasonal.editionByID[id] != nil:
				"Cannot borrow edition, no such id"
		}
		return AllDaySeasonal.EditionData(id: id)
	}
	
	//------------------------------------------------------------
	// NFT
	//------------------------------------------------------------
	// A Seasonal NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let editionID: UInt64
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// Destructor
		//
		// NFT initializer
		//
		init(editionID: UInt64){ 
			pre{ 
				AllDaySeasonal.editionByID[editionID] != nil:
					"no such editionID"
				EditionData(id: editionID).active == true:
					"edition already closed"
			}
			self.id = self.uuid
			self.editionID = editionID
			emit Minted(id: self.id, editionID: self.editionID)
		}
	}
	
	//------------------------------------------------------------
	// Collection
	//------------------------------------------------------------
	// A public collection interface that allows Moment NFTs to be borrowed
	//
	access(all)
	resource interface AllDaySeasonalCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowAllDaySeasonal(id: UInt64): &AllDaySeasonal.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Moment NFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// An NFT Collection
	//
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, AllDaySeasonalCollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an UInt64 ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @AllDaySeasonal.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// batchDeposit takes a Collection object as an argument
		// and deposits each contained NFT into this Collection
		//
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			// Get an array of the IDs to be deposited
			let keys = tokens.getIDs()
			
			// Iterate through the keys in the collection and deposit each one
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			
			// Destroy the empty Collection
			destroy tokens
		}
		
		// getIDs returns an array of the IDs that are in the collection
		//
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Cannot borrow NFT, no such id"
			}
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowAllDaySeasonal gets a reference to an AllDaySeasonal in the collection
		//
		access(all)
		fun borrowAllDaySeasonal(id: UInt64): &AllDaySeasonal.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				if let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?{ 
					return ref! as! &AllDaySeasonal.NFT
				}
				return nil
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
		
		// Collection destructor
		//
		// Collection initializer
		//
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	//------------------------------------------------------------
	// Admin
	//------------------------------------------------------------
	// An interface containing the Admin function that allows minting NFTs
	//
	access(all)
	resource interface NFTMinter{ 
		// Mint a single NFT
		// The Edition for the given ID must already exist
		//
		access(all)
		fun mintNFT(editionID: UInt64): @AllDaySeasonal.NFT
	}
	
	// A resource that allows managing metadata and minting NFTs
	//
	access(all)
	resource Admin: NFTMinter{ 
		
		// Borrow an Edition
		//
		access(all)
		fun borrowEdition(id: UInt64): &AllDaySeasonal.Edition{ 
			pre{ 
				AllDaySeasonal.editionByID[id] != nil:
					"Cannot borrow edition, no such id"
			}
			return (&AllDaySeasonal.editionByID[id] as &AllDaySeasonal.Edition?)!
		}
		
		// Create a Edition 
		//
		access(all)
		fun createEdition(metadata:{ String: String}): UInt64{ 
			// Create and store the new edition
			let edition <- create AllDaySeasonal.Edition(metadata: metadata)
			let editionID = edition.id
			AllDaySeasonal.editionByID[edition.id] <-! edition
			
			// Return the new ID for convenience
			return editionID
		}
		
		// Close an Edition
		//
		access(all)
		fun closeEdition(id: UInt64): UInt64{ 
			if let edition = &AllDaySeasonal.editionByID[id] as &AllDaySeasonal.Edition?{ 
				edition.close()
				return edition.id
			}
			panic("edition does not exist")
		}
		
		// Mint a single NFT
		// The Edition for the given ID must already exist
		//
		access(all)
		fun mintNFT(editionID: UInt64): @AllDaySeasonal.NFT{ 
			pre{ 
				// Make sure the edition we are creating this NFT in exists
				AllDaySeasonal.editionByID.containsKey(editionID):
					"No such EditionID"
			}
			return <-self.borrowEdition(id: editionID).mint()
		}
	}
	
	//------------------------------------------------------------
	// Contract lifecycle
	//------------------------------------------------------------
	// AllDaySeasonal contract initializer
	//
	init(){ 
		// Set the named paths
		self.CollectionStoragePath = /storage/AllDaySeasonalCollection
		self.CollectionPublicPath = /public/AllDaySeasonalCollection
		self.AdminStoragePath = /storage/AllDaySeasonalAdmin
		self.MinterPrivatePath = /private/AllDaySeasonalMinter
		
		// Initialize the entity counts		
		self.totalSupply = 0
		self.totalEditions = 0
		self.nextEditionID = 1
		
		// Initialize the metadata lookup dictionaries
		self.editionByID <-{} 
		
		// Create an Admin resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		// Link capabilites to the admin constrained to the Minter
		// and Metadata interfaces
		var capability_1 = self.account.capabilities.storage.issue<&AllDaySeasonal.Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.MinterPrivatePath)
		
		// Let the world know we are here
		emit ContractInitialized()
	}
}
