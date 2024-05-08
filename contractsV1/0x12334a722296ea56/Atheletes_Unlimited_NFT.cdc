/////////////////////////////////////////////////////////////////////
//
//  Atheletes_Unlimited_NFT.cdc
//
//  This smart contract has the core NFT functionality for 
//  Atheletes_Unlimited_NFTs. It is part of the NFT Bridge platform
//  created by GigLabs.
//  
//  Author: Brian Burns brian@giglabs.io
//
/////////////////////////////////////////////////////////////////////
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract Atheletes_Unlimited_NFT: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64)
	
	access(all)
	event NFTDestroyed(id: UInt64)
	
	access(all)
	event SeriesCreated(seriesId: UInt32)
	
	access(all)
	event SeriesSealed(seriesId: UInt32)
	
	access(all)
	event SetCreated(seriesId: UInt32, setId: UInt32)
	
	access(all)
	event SeriesMetadataUpdated(seriesId: UInt32)
	
	access(all)
	event SetMetadataUpdated(seriesId: UInt32, setId: UInt32)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	// totalSupply
	// The total number of Atheletes_Unlimited_NFT that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// Variable size dictionary of SetData structs
	access(self)
	var setData:{ UInt32: NFTSetData}
	
	// Variable size dictionary of SeriesData structs
	access(self)
	var seriesData:{ UInt32: SeriesData}
	
	// Variable size dictionary of Series resources
	access(self)
	var series: @{UInt32: Series}
	
	access(all)
	struct NFTSetData{ 
		
		// Unique ID for the Set
		access(all)
		let setId: UInt32
		
		// Series ID the Set belongs to
		access(all)
		let seriesId: UInt32
		
		// Maximum number of editions that can be minted in this Set
		access(all)
		let maxEditions: UInt32
		
		// The JSON metadata for each NFT edition can be stored off-chain on IPFS.
		// This is an optional dictionary of IPFS hashes, which will allow marketplaces
		// to pull the metadata for each NFT edition
		access(self)
		var ipfsMetadataHashes:{ UInt32: String}
		
		// Set level metadata
		// Dictionary of metadata key value pairs
		access(self)
		var metadata:{ String: String}
		
		init(setId: UInt32, seriesId: UInt32, maxEditions: UInt32, ipfsMetadataHashes:{ UInt32: String}, metadata:{ String: String}){ 
			self.setId = setId
			self.seriesId = seriesId
			self.maxEditions = maxEditions
			self.metadata = metadata
			self.ipfsMetadataHashes = ipfsMetadataHashes
			emit SetCreated(seriesId: self.seriesId, setId: self.setId)
		}
		
		access(all)
		fun getIpfsMetadataHash(editionNum: UInt32): String?{ 
			return self.ipfsMetadataHashes[editionNum]
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun getMetadataField(field: String): String?{ 
			return self.metadata[field]
		}
	}
	
	access(all)
	struct SeriesData{ 
		
		// Unique ID for the Series
		access(all)
		let seriesId: UInt32
		
		// Dictionary of metadata key value pairs
		access(self)
		var metadata:{ String: String}
		
		init(seriesId: UInt32, metadata:{ String: String}){ 
			self.seriesId = seriesId
			self.metadata = metadata
			emit SeriesCreated(seriesId: self.seriesId)
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
	}
	
	// NFTSet
	// Resource that allows an admin to mint new NFTs
	//
	access(all)
	resource Series{ 
		
		// Unique ID for the Series
		access(all)
		let seriesId: UInt32
		
		// Array of NFTSets that belong to this Series
		access(self)
		var setIds: [UInt32]
		
		// Series sealed state
		access(all)
		var seriesSealedState: Bool
		
		// Set sealed state
		access(self)
		var setSealedState:{ UInt32: Bool}
		
		// Current number of editions minted per Set
		access(self)
		var numberEditionsMintedPerSet:{ UInt32: UInt32}
		
		init(seriesId: UInt32, metadata:{ String: String}){ 
			self.seriesId = seriesId
			self.seriesSealedState = false
			self.numberEditionsMintedPerSet ={} 
			self.setIds = []
			self.setSealedState ={} 
			Atheletes_Unlimited_NFT.seriesData[seriesId] = SeriesData(seriesId: seriesId, metadata: metadata)
		}
		
		access(all)
		fun addNftSet(setId: UInt32, maxEditions: UInt32, ipfsMetadataHashes:{ UInt32: String}, metadata:{ String: String}){ 
			pre{ 
				self.setIds.contains(setId) == false:
					"The Set has already been added to the Series."
			}
			
			// Create the new Set struct
			var newNFTSet = NFTSetData(setId: setId, seriesId: self.seriesId, maxEditions: maxEditions, ipfsMetadataHashes: ipfsMetadataHashes, metadata: metadata)
			
			// Add the NFTSet to the array of Sets
			self.setIds.append(setId)
			
			// Initialize the NFT edition count to zero
			self.numberEditionsMintedPerSet[setId] = 0
			
			// Store it in the sets mapping field
			Atheletes_Unlimited_NFT.setData[setId] = newNFTSet
			emit SetCreated(seriesId: self.seriesId, setId: setId)
		}
		
		// updateSeriesMetadata
		// For practical reasons, a short period of time is given to update metadata
		// following Series creation or minting of the NFT editions. Once the Series is
		// sealed, no updates to the Series metadata will be possible - the information
		// is permanent and immutable.
		access(all)
		fun updateSeriesMetadata(metadata:{ String: String}){ 
			pre{ 
				self.seriesSealedState == false:
					"The Series is permanently sealed. No metadata updates can be made."
			}
			let newSeriesMetadata = SeriesData(seriesId: self.seriesId, metadata: metadata)
			// Store updated Series in the Series mapping field
			Atheletes_Unlimited_NFT.seriesData[self.seriesId] = newSeriesMetadata
			emit SeriesMetadataUpdated(seriesId: self.seriesId)
		}
		
		// updateSetMetadata
		// For practical reasons, a short period of time is given to update metadata
		// following Set creation or minting of the NFT editions. Once the Series is
		// sealed, no updates to the Set metadata will be possible - the information
		// is permanent and immutable.
		access(all)
		fun updateSetMetadata(setId: UInt32, maxEditions: UInt32, ipfsMetadataHashes:{ UInt32: String}, metadata:{ String: String}){ 
			pre{ 
				self.seriesSealedState == false:
					"The Series is permanently sealed. No metadata updates can be made."
				self.setIds.contains(setId) == true:
					"The Set is not part of this Series."
			}
			let newSetMetadata = NFTSetData(setId: setId, seriesId: self.seriesId, maxEditions: maxEditions, ipfsMetadataHashes: ipfsMetadataHashes, metadata: metadata)
			// Store updated Set in the Sets mapping field
			Atheletes_Unlimited_NFT.setData[setId] = newSetMetadata
			emit SetMetadataUpdated(seriesId: self.seriesId, setId: setId)
		}
		
		// mintAtheletes_Unlimited_NFT
		// Mints a new NFT with a new ID
		// and deposits it in the recipients collection using their collection reference
		//
		access(all)
		fun mintAtheletes_Unlimited_NFT(recipient: &{NonFungibleToken.CollectionPublic}, tokenId: UInt64, setId: UInt32){ 
			pre{ 
				self.numberEditionsMintedPerSet[setId] != nil:
					"The Set does not exist."
				self.numberEditionsMintedPerSet[setId]! <= Atheletes_Unlimited_NFT.getSetMaxEditions(setId: setId)!:
					"Set has reached maximum NFT edition capacity."
			}
			
			// Gets the number of editions that have been minted so far in 
			// this set
			let editionNum: UInt32 = self.numberEditionsMintedPerSet[setId]! + 1 as UInt32
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create Atheletes_Unlimited_NFT.NFT(tokenId: tokenId, setId: setId, editionNum: editionNum))
			
			// Increment the count of global NFTs 
			Atheletes_Unlimited_NFT.totalSupply = Atheletes_Unlimited_NFT.totalSupply + 1 as UInt64
			
			// Update the count of Editions minted in the set
			self.numberEditionsMintedPerSet[setId] = editionNum
		}
		
		// batchMintAtheletes_Unlimited_NFT
		// Mints multiple new NFTs given and deposits the NFTs
		// into the recipients collection using their collection reference
		access(all)
		fun batchMintAtheletes_Unlimited_NFT(recipient: &{NonFungibleToken.CollectionPublic}, setId: UInt32, tokenIds: [UInt64]){ 
			pre{ 
				tokenIds.length > 0:
					"Number of token Ids must be > 0"
			}
			for tokenId in tokenIds{ 
				self.mintAtheletes_Unlimited_NFT(recipient: recipient, tokenId: tokenId, setId: setId)
			}
		}
		
		// sealSeries
		// Once a series is sealed, the metadata for the NFTs in the Series can no
		// longer be updated
		//
		access(all)
		fun sealSeries(){ 
			pre{ 
				self.seriesSealedState == false:
					"The Series is already sealed"
			}
			self.seriesSealedState = true
			emit SeriesSealed(seriesId: self.seriesId)
		}
	}
	
	// NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// The Set id references this NFT belongs to
		access(all)
		let setId: UInt32
		
		// The specific edition number for this NFT
		access(all)
		let editionNum: UInt32
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(tokenId: UInt64, setId: UInt32, editionNum: UInt32){ 
			self.id = tokenId
			self.setId = setId
			self.editionNum = editionNum
			emit Minted(id: self.id)
		}
	
	// If the NFT is destroyed, emit an event
	}
	
	// Admin is a special authorization resource that 
	// allows the owner to perform important NFT 
	// functions
	//
	access(all)
	resource Admin{ 
		access(all)
		fun addSeries(seriesId: UInt32, metadata:{ String: String}){ 
			pre{ 
				Atheletes_Unlimited_NFT.series[seriesId] == nil:
					"Cannot add Series: The Series already exists"
			}
			
			// Create the new Series
			var newSeries <- create Series(seriesId: seriesId, metadata: metadata)
			
			// Add the new Series resource to the Series dictionary in the contract
			Atheletes_Unlimited_NFT.series[seriesId] <-! newSeries
		}
		
		access(all)
		fun borrowSeries(seriesId: UInt32): &Series{ 
			pre{ 
				Atheletes_Unlimited_NFT.series[seriesId] != nil:
					"Cannot borrow Series: The Series does not exist"
			}
			
			// Get a reference to the Series and return it
			return &Atheletes_Unlimited_NFT.series[seriesId] as &Atheletes_Unlimited_NFT.Series?
		}
		
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	// This is the interface that users can cast their NFT Collection as
	// to allow others to deposit Atheletes_Unlimited_NFT into their Collection. It also allows for reading
	// the details of Atheletes_Unlimited_NFT in the Collection.
	access(all)
	resource interface Atheletes_Unlimited_NFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowAtheletes_Unlimited_NFT(id: UInt64): &Atheletes_Unlimited_NFT.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Atheletes_Unlimited_NFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of Atheletes_Unlimited_NFT NFTs owned by an account
	//
	access(all)
	resource Collection: Atheletes_Unlimited_NFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
		
		// batchWithdraw withdraws multiple NFTs and returns them as a Collection
		//
		// Parameters: ids: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: The collection of withdrawn tokens
		//
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			// Create a new empty Collection
			var batchCollection <- create Collection()
			
			// Iterate through the ids and withdraw them from the Collection
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			
			// Return the withdrawn tokens
			return <-batchCollection
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Atheletes_Unlimited_NFT.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// batchDeposit takes a Collection object as an argument
		// and deposits each contained NFT into this Collection
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
		
		// borrowAtheletes_Unlimited_NFT
		// Gets a reference to an NFT in the collection as a Atheletes_Unlimited_NFT,
		// exposing all of its fields.
		// This is safe as there are no functions that can be called on the Atheletes_Unlimited_NFT.
		//
		access(all)
		fun borrowAtheletes_Unlimited_NFT(id: UInt64): &Atheletes_Unlimited_NFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &Atheletes_Unlimited_NFT.NFT
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
	
	// fetch
	// Get a reference to a Atheletes_Unlimited_NFT from an account's Collection, if available.
	// If an account does not have a Atheletes_Unlimited_NFT.Collection, panic.
	// If it has a collection but does not contain the Id, return nil.
	// If it has a collection and that collection contains the Id, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, id: UInt64): &Atheletes_Unlimited_NFT.NFT?{ 
		let collection = getAccount(from).capabilities.get<&Atheletes_Unlimited_NFT.Collection>(Atheletes_Unlimited_NFT.CollectionPublicPath).borrow<&Atheletes_Unlimited_NFT.Collection>() ?? panic("Couldn't get collection")
		// We trust Atheletes_Unlimited_NFT.Collection.borrowAtheletes_Unlimited_NFT to get the correct id
		// (it checks it before returning it).
		return collection.borrowAtheletes_Unlimited_NFT(id: id)
	}
	
	// getAllSeries returns all the sets
	//
	// Returns: An array of all the series that have been created
	access(all)
	fun getAllSeries(): [Atheletes_Unlimited_NFT.SeriesData]{ 
		return Atheletes_Unlimited_NFT.seriesData.values
	}
	
	// getAllSets returns all the sets
	//
	// Returns: An array of all the sets that have been created
	access(all)
	fun getAllSets(): [Atheletes_Unlimited_NFT.NFTSetData]{ 
		return Atheletes_Unlimited_NFT.setData.values
	}
	
	// getSeriesMetadata returns the metadata that the specified Series
	//			is associated with.
	// 
	// Parameters: seriesId: The id of the Series that is being searched
	//
	// Returns: The metadata as a String to String mapping optional
	access(all)
	fun getSeriesMetadata(seriesId: UInt32):{ String: String}?{ 
		return Atheletes_Unlimited_NFT.seriesData[seriesId]?.getMetadata()
	}
	
	// getSetMaxEditions returns the the maximum number of NFT editions that can
	//		be minted in this Set.
	// 
	// Parameters: setId: The id of the Set that is being searched
	//
	// Returns: The max number of NFT editions in this Set
	access(all)
	view fun getSetMaxEditions(setId: UInt32): UInt32?{ 
		return Atheletes_Unlimited_NFT.setData[setId]?.maxEditions
	}
	
	// getSetMetadata returns all the metadata associated with a specific Set
	// 
	// Parameters: setId: The id of the Set that is being searched
	//
	// Returns: The metadata as a String to String mapping optional
	access(all)
	fun getSetMetadata(setId: UInt32):{ String: String}?{ 
		return Atheletes_Unlimited_NFT.setData[setId]?.getMetadata()
	}
	
	// getSetSeriesId returns the Series Id the Set belongs to
	// 
	// Parameters: setId: The id of the Set that is being searched
	//
	// Returns: The Series Id
	access(all)
	fun getSetSeriesId(setId: UInt32): UInt32?{ 
		return Atheletes_Unlimited_NFT.setData[setId]?.seriesId
	}
	
	// getSetMetadata returns all the ipfs hashes for each nft 
	//	 edition in the Set.
	// 
	// Parameters: setId: The id of the Set that is being searched
	//
	// Returns: The ipfs hashes of nft editions as a Array of Strings
	access(all)
	fun getIpfsMetadataHashByNftEdition(setId: UInt32, editionNum: UInt32): String?{ 
		// Don't force a revert if the setId or field is invalid
		if let set = Atheletes_Unlimited_NFT.setData[setId]{ 
			return set.getIpfsMetadataHash(editionNum: editionNum)
		} else{ 
			return nil
		}
	}
	
	// getSetMetadataByField returns the metadata associated with a 
	//						specific field of the metadata
	// 
	// Parameters: setId: The id of the Set that is being searched
	//			 field: The field to search for
	//
	// Returns: The metadata field as a String Optional
	access(all)
	fun getSetMetadataByField(setId: UInt32, field: String): String?{ 
		// Don't force a revert if the setId or field is invalid
		if let set = Atheletes_Unlimited_NFT.setData[setId]{ 
			return set.getMetadataField(field: field)
		} else{ 
			return nil
		}
	}
	
	// initializer
	//
	init(){ 
		// Set named paths
		self.CollectionStoragePath = /storage/Atheletes_Unlimited_NFTCollection
		self.CollectionPublicPath = /public/Atheletes_Unlimited_NFTCollection
		self.AdminStoragePath = /storage/Atheletes_Unlimited_NFTAdmin
		self.AdminPrivatePath = /private/Atheletes_Unlimited_NFTAdminUpgrade
		
		// Initialize the total supply
		self.totalSupply = 0
		self.setData ={} 
		self.seriesData ={} 
		self.series <-{} 
		
		// Put Admin in storage
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Atheletes_Unlimited_NFT.Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath) ?? panic("Could not get a capability to the admin")
		emit ContractInitialized()
	}
}
