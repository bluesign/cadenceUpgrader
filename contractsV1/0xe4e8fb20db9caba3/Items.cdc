import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract Items: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// Public named paths
	// -----------------------------------------------------------------------
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let ItemsAdminStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// -----------------------------------------------------------------------
	// Public events
	// -----------------------------------------------------------------------
	// Emitted when the Items contract is created
	access(all)
	event ContractInitialized()
	
	// Emitted when a new Artist struct is created
	access(all)
	event ArtistCreated(id: UInt32, metadata:{ String: String})
	
	// Emitted when a new Piece is created
	access(all)
	event PieceCreated(pieceID: UInt32, artistID: UInt32, metadata:{ String: String})
	
	// Emitted when a Piece is locked, meaning Piece cannot be added
	access(all)
	event PieceLocked(pieceID: UInt32)
	
	// Emitted when a Items is minted from a Piece
	access(all)
	event ItemsMinted(itemID: UInt64, artistID: UInt32, pieceID: UInt32, serialNumber: UInt32)
	
	// Emitted when a item is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when a item is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Emitted when a Items is destroyed
	access(all)
	event ItemsDestroyed(id: UInt64)
	
	// -----------------------------------------------------------------------
	// Items contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// Variable size dictionary of artist structs
	access(self)
	var artistDatas:{ UInt32: Artist}
	
	// Variable size dictionary of piece structs
	access(self)
	var pieceDatas:{ UInt32: PieceData}
	
	// Variable size dictionary of Piece resources
	access(self)
	var pieces: @{UInt32: Piece}
	
	// The ID that is used to create Artists. 
	access(all)
	var nextArtistID: UInt32
	
	// The ID that is used to create Pieces. 
	access(all)
	var nextPieceID: UInt32
	
	// The total number of Items NFTs that have been created
	access(all)
	var totalSupply: UInt64
	
	access(all)
	struct Artist{ 
		
		// The unique ID for the Artist
		access(all)
		let artistID: UInt32
		
		// Stores all the metadata about the artist as a string mapping
		access(all)
		let metadata:{ String: String}
		
		init(metadata:{ String: String}){ 
			pre{ 
				metadata.length != 0:
					"New Play metadata cannot be empty"
			}
			self.artistID = Items.nextArtistID
			self.metadata = metadata
		}
	}
	
	access(all)
	struct PieceData{ 
		
		// The unique ID for the Piece
		access(all)
		let pieceID: UInt32
		
		// Stores all the metadata about the piece as a string mapping
		// name could be a key in metadata
		access(all)
		let metadata:{ String: String}
		
		init(metadata:{ String: String}){ 
			pre{ 
				metadata.length != 0:
					"New Piece metadata cannot be empty"
			}
			self.pieceID = Items.nextPieceID
			self.metadata = metadata
		}
	}
	
	access(all)
	resource Piece{ 
		
		// Unique ID for the piece
		access(all)
		let pieceID: UInt32
		
		// The Artist who created the piece
		access(contract)
		var artistID: UInt32
		
		access(all)
		var locked: Bool
		
		// The number of Itemss minted by using this Piece
		access(contract)
		var numberMinted: UInt32 // serial number
		
		
		init(artistID: UInt32, metadata:{ String: String}){ 
			self.pieceID = Items.nextPieceID
			self.artistID = artistID
			self.locked = false
			self.numberMinted = 0
			// Create a new PieceData for this Set Piece store it in contract storage
			Items.pieceDatas[self.pieceID] = PieceData(metadata: metadata)
		}
		
		access(all)
		fun lock(){ 
			if !self.locked{ 
				self.locked = true
				emit PieceLocked(pieceID: self.pieceID)
			}
		}
		
		access(all)
		fun mintItems(): @NFT{ 
			
			// Mint the new item
			let newItems: @NFT <- create NFT(serialNumber: self.numberMinted + 1 as UInt32, artistID: self.artistID, pieceID: self.pieceID)
			
			// Increment the count of Itemss minted for this Piece
			self.numberMinted = self.numberMinted + 1 as UInt32
			emit ItemsMinted(itemID: newItems.id, artistID: self.artistID, pieceID: self.pieceID, serialNumber: self.numberMinted)
			return <-newItems
		}
		
		access(all)
		fun batchMintItems(quantity: UInt64): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintItems())
				i = i + 1 as UInt64
			}
			return <-newCollection
		}
		
		access(all)
		fun getArtist(): UInt32{ 
			return self.artistID
		}
		
		access(all)
		fun getNumMinted(): UInt32{ 
			return self.numberMinted
		}
	}
	
	access(all)
	struct QueryPieceData{ 
		access(all)
		let pieceID: UInt32
		
		access(self)
		var artistID: UInt32
		
		access(all)
		var locked: Bool
		
		access(self)
		var numberMinted: UInt32
		
		access(all)
		let metadata:{ String: String}
		
		init(pieceID: UInt32){ 
			let piece = &Items.pieces[pieceID] as &Items.Piece?
			let pieceData = Items.pieceDatas[pieceID] as PieceData?
			self.pieceID = pieceID
			self.metadata = (pieceData!).metadata
			self.artistID = piece.artistID
			self.locked = piece.locked
			self.numberMinted = piece.numberMinted
		}
		
		access(all)
		fun getArtist(): UInt32{ 
			return self.artistID
		}
		
		access(all)
		fun getNumberMinted(): UInt32{ 
			return self.numberMinted
		}
	}
	
	access(all)
	struct ItemsData{ 
		
		// The ID of the Piece that the Items comes from
		access(all)
		let pieceID: UInt32
		
		// The ID of the Artist that the Items comes from
		access(all)
		let artistID: UInt32
		
		access(all)
		let serialNumber: UInt32
		
		init(pieceID: UInt32, artistID: UInt32, serialNumber: UInt32){ 
			self.pieceID = pieceID
			self.artistID = artistID
			self.serialNumber = serialNumber
		}
	}
	
	// total supply id is global
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		
		// Global unique Items ID
		access(all)
		let id: UInt64
		
		// Struct of Items metadata
		access(all)
		let data: ItemsData
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(serialNumber: UInt32, artistID: UInt32, pieceID: UInt32){ 
			// Increment the global Items IDs
			Items.totalSupply = Items.totalSupply + 1 as UInt64
			self.id = Items.totalSupply
			
			// piece the metadata struct
			self.data = ItemsData(pieceID: pieceID, artistID: artistID, serialNumber: serialNumber)
		}
	
	// If the Items is destroyed, emit an event to indicate 
	// to outside ovbservers that it has been destroyed
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun createArtist(metadata:{ String: String}): UInt32{ 
			// Create the new Artist
			var newArtist = Artist(metadata: metadata)
			let newID = newArtist.artistID
			
			// Increment the ID so that it isn't used again
			Items.nextArtistID = Items.nextArtistID + 1 as UInt32
			emit ArtistCreated(id: newArtist.artistID, metadata: metadata)
			
			// Store it in the Artists mapping field
			Items.artistDatas[newID] = newArtist
			return newID
		}
		
		access(all)
		fun createPiece(artistID: UInt32, metadata:{ String: String}): UInt32{ 
			
			// Create the new Set
			var newPiece <- create Piece(artistID: artistID, metadata: metadata)
			
			// Increment the PieceID so that it isn't used again
			Items.nextPieceID = Items.nextPieceID + 1 as UInt32
			let newID = newPiece.pieceID
			emit PieceCreated(pieceID: newID, artistID: artistID, metadata: metadata)
			
			// Store it in the Pieces mapping field
			Items.pieces[newID] <-! newPiece
			return newID
		}
		
		access(all)
		fun borrowPiece(pieceID: UInt32): &Piece{ 
			pre{ 
				Items.pieces[pieceID] != nil:
					"Cannot borrow piece: The piece doesn't exist"
			}
			
			// Get a reference to the pice and return it
			// use `&` to indicate the reference to the object and type
			return &Items.pieces[pieceID] as &Items.Piece?
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(all)
	resource interface ItemsCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowItems(id: UInt64): &Items.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Items reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: ItemsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// Dictionary of Items conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an Items from the Collection and moves it to the caller
		//
		// Parameters: withdrawID: The ID of the NFT 
		// that is to be removed from the Collection
		//
		// returns: @NonFungibleToken.NFT the token that was withdrawn
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Items does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			
			// Return the withdrawn token
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: ids: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: A collection that contains
		//										the withdrawn Itemss
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
		
		// deposit takes a Moment and adds it to the Collections dictionary
		//
		// Paramters: token: the NFT to be deposited in the collection
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			
			// Cast the deposited token as a Items NFT to make sure
			// it is the correct type
			let token <- token as! @Items.NFT
			
			// Get the token's ID
			let id = token.id
			
			// Add the new token to the dictionary
			let oldToken <- self.ownedNFTs[id] <- token
			
			// Only emit a deposit event if the Collection 
			// is in an account's storage
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			
			// Destroy the empty old token that was "removed"
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
		
		// getIDs returns an array of the IDs that are in the Collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT Returns a borrowed reference to an Items in the Collection
		// so that the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// borrowItems returns a borrowed reference to an Items
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(all)
		fun borrowItems(id: UInt64): &Items.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &Items.NFT
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
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Items.Collection()
	}
	
	access(all)
	fun getAllArtists(): [Items.Artist]{ 
		return Items.artistDatas.values
	}
	
	access(all)
	fun getArtistMetaData(artistID: UInt32):{ String: String}?{ 
		return Items.artistDatas[artistID]?.metadata
	}
	
	access(all)
	fun getPieceData(pieceID: UInt32): QueryPieceData?{ 
		if Items.pieces[pieceID] == nil{ 
			return nil
		} else{ 
			return QueryPieceData(pieceID: pieceID)
		}
	}
	
	access(all)
	fun isPieceLocked(pieceID: UInt32): Bool?{ 
		// Don't force a revert if the pieceID is invalid
		return Items.pieces[pieceID]?.locked
	}
	
	// -----------------------------------------------------------------------
	// Items initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		self.CollectionStoragePath = /storage/ItemsEcosystemCollection
		self.ItemsAdminStoragePath = /storage/ItemsEcosystemAdmin
		self.CollectionPublicPath = /public/ItemsEcosystemCollection
		self.artistDatas ={} 
		self.pieceDatas ={} 
		self.pieces <-{} 
		self.nextArtistID = 1
		self.nextPieceID = 1
		self.totalSupply = 0 // will be itemID
		
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: self.CollectionStoragePath)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{ItemsCollectionPublic}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Put the Admin in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: self.ItemsAdminStoragePath)
		emit ContractInitialized()
	}
}
