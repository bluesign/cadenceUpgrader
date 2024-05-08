import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

// Marsart
// NFT items for Marsart!
access(all)
contract Marsart: NonFungibleToken{ 
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, name: String, artist: String, artistIntroduction: String, artworkIntroduction: String, typeId: UInt64, type: String, description: String, ipfsLink: String, MD5Hash: String, serialNumber: UInt32, totalNumber: UInt32)
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// The total number of tokens of this type in existence
	access(all)
	var totalSupply: UInt64
	
	access(all)
	resource interface NFTPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let data: NFTData
	}
	
	access(all)
	struct NFTData{ 
		access(all)
		let name: String
		
		access(all)
		let artist: String
		
		access(all)
		let artistIntroduction: String
		
		access(all)
		let artworkIntroduction: String
		
		access(all)
		let typeId: UInt64
		
		access(all)
		let type: String
		
		access(all)
		let description: String
		
		access(all)
		let ipfsLink: String
		
		access(all)
		let MD5Hash: String
		
		access(all)
		let serialNumber: UInt32
		
		access(all)
		let totalNumber: UInt32
		
		init(name: String, artist: String, artistIntroduction: String, artworkIntroduction: String, typeId: UInt64, type: String, description: String, ipfsLink: String, MD5Hash: String, serialNumber: UInt32, totalNumber: UInt32){ 
			self.name = name
			self.artist = artist
			self.artistIntroduction = artistIntroduction
			self.artworkIntroduction = artworkIntroduction
			self.typeId = typeId
			self.type = type
			self.description = description
			self.ipfsLink = ipfsLink
			self.MD5Hash = MD5Hash
			self.serialNumber = serialNumber
			self.totalNumber = totalNumber
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, NFTPublic{ 
		// global unique NFT ID
		access(all)
		let id: UInt64
		
		access(all)
		let data: NFTData
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, nftData: NFTData){ 
			self.id = initID
			self.data = nftData
		}
	}
	
	// This is the interface that users can cast their Marsart Collection as
	// to allow others to deposit Marsart into their Collection. It also allows for reading
	// the details of Marsart in the Collection.
	access(all)
	resource interface MarsartCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun depositBatch(cardCollection: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowMarsart(id: UInt64): &Marsart.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Marsart reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of Marsart NFTs owned by an account
	access(all)
	resource Collection: MarsartCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Marsart.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// depositBatch
		// This is primarily called by an Admin to
		// deposit newly minted Cards into this Collection.
		access(all)
		fun depositBatch(cardCollection: @{NonFungibleToken.Collection}){ 
			pre{ 
				cardCollection.getIDs().length <= 100:
					"Too many cards being deposited. Must be less than or equal to 100"
			}
			// Get an array of the IDs to be deposited
			let keys = cardCollection.getIDs()
			// Iterate through the keys in the collection and deposit each one
			for key in keys{ 
				self.deposit(token: <-cardCollection.withdraw(withdrawID: key))
			}
			// Destroy the empty Collection
			destroy cardCollection
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
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowMarsart
		// Gets a reference to an NFT in the collection as a Marsart,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the Marsart.
		access(all)
		fun borrowMarsart(id: UInt64): &Marsart.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Marsart.NFT
			}
			return nil
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
	
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// NFTMinter
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	access(all)
	resource NFTMinter{ 
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, artist: String, artistIntroduction: String, artworkIntroduction: String, typeId: UInt64, type: String, description: String, ipfsLink: String, MD5Hash: String, serialNumber: UInt32, totalNumber: UInt32){ 
			Marsart.totalSupply = Marsart.totalSupply + 1 as UInt64
			emit Minted(id: Marsart.totalSupply, name: name, artist: artist, artistIntroduction: artistIntroduction, artworkIntroduction: artworkIntroduction, typeId: typeId, type: type, description: description, ipfsLink: ipfsLink, MD5Hash: MD5Hash, serialNumber: serialNumber, totalNumber: totalNumber)
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create Marsart.NFT(initID: Marsart.totalSupply, nftData: NFTData(name: name, artist: artist, artistIntroduction: artistIntroduction, artworkIntroduction: artworkIntroduction, typeId: typeId, type: type, description: description, ipfsLink: ipfsLink, MD5Hash: MD5Hash, serialNumber: serialNumber, totalNumber: totalNumber)))
		}
	}
	
	// initializer
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		// Set our named paths
		self.CollectionStoragePath = /storage/MarsartCollection
		self.CollectionPublicPath = /public/MarsartCollection
		self.MinterStoragePath = /storage/MarsartMinter
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
