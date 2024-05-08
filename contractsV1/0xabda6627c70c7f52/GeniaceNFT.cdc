// NFTv2.cdc
//
// This is a complete version of the GeniaceNFT contract
// that includes withdraw and deposit functionality, as well as a
// collection resource that can be used to bundle NFTs together.
//
// It also includes a definition for the Minter resource,
// which can be used by admins to mint new NFTs.
//
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract GeniaceNFT: NonFungibleToken{ 
	
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
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterPrivatePath: PrivatePath
	
	// totalSupply
	// The total number of GeniaceNFT that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// Define three types of rarity {Collectible, Rare, Ultra-Rare}
	access(all)
	enum Rarity: UInt8{ 
		access(all)
		case Collectible
		
		access(all)
		case Rare
		
		access(all)
		case UltraRare
	}
	
	access(all)
	struct Metadata{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let imageUrl: String
		
		access(all)
		let celebrityName: String
		
		access(all)
		let artist: String
		
		access(all)
		let rarity: Rarity
		
		// Extra optional fields can be added in the data dict
		access(all)
		let data:{ String: String}
		
		init(_name: String, _description: String, _celebrityName: String, _artist: String, _rarity: Rarity, _imageUrl: String, _data:{ String: String}){ 
			pre{ 
				!_data.containsKey("name"):
					"data dictionary contains 'name' key"
				!_data.containsKey("description"):
					"data dictionary contains 'description' key"
				!_data.containsKey("imageUrl"):
					"data dictionary contains 'imageUrl' key"
				!_data.containsKey("celebrityName"):
					"data dictionary contains 'celebrityName' key"
				!_data.containsKey("artist"):
					"data dictionary contains 'artist' key"
				!_data.containsKey("rarity"):
					"data dictionary contains 'rarity' key"
			}
			self.name = _name
			self.description = _description
			self.imageUrl = _imageUrl
			self.celebrityName = _celebrityName
			self.rarity = _rarity
			self.artist = _artist
			self.data = _data
		}
	}
	
	// Declare the NFT resource type
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The unique ID that differentiates each NFT
		access(all)
		let id: UInt64
		
		// The metadata associated with the NFT
		access(all)
		let metadata: Metadata
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// Initialize both fields in the init function
		init(initID: UInt64, metadata: Metadata){ 
			self.id = initID
			self.metadata = metadata
		}
	}
	
	// We define this interface purely as a way to allow users
	// to create public, restricted references to their NFT Collection.
	// They would use this to only expose the deposit, getIDs,
	// and idExists fields in their Collection and use to get the details of GeniaceNFT
	access(all)
	resource interface GeniaceNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun idExists(id: UInt64): Bool
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowGeniaceNFT(id: UInt64): &GeniaceNFT.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow GeniaceNFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// The definition of the Collection resource that
	// holds the NFTs that a user owns
	access(all)
	resource Collection: GeniaceNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw 
		//
		// Function that removes an NFT from the collection 
		// and moves it to the calling context
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// If the NFT isn't found, the transaction panics and reverts
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit 
		//
		// Function that takes a NFT as an argument and 
		// adds it to the collections dictionary
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @GeniaceNFT.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// idExists checks to see if a NFT 
		// with the given ID exists in the collection
		access(all)
		fun idExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		// getIDs returns an array of the IDs that are in the collection
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
		
		// borrow GeniaceNFT
		// Gets a reference to an NFT in the collection as a GeniaceNFT,
		// exposing all of its fields, this reference will be used to retrive the meta info.
		// This is safe as there are no functions that can be called on the GeniaceNFT.
		//
		access(all)
		fun borrowGeniaceNFT(id: UInt64): &GeniaceNFT.NFT?{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &GeniaceNFT.NFT?
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
		
		// Initialize the NFTs field to an empty collection
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// creates a new empty Collection resource and returns it 
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// NFTMinter
	//
	// Resource that would be owned by an admin or by a smart contract 
	// that allows them to mint new NFTs when needed
	access(all)
	resource NFTMinter{ 
		
		// mintNFT 
		//
		// Function that mints a new NFT with a new ID
		// and returns it to the caller
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, _metadata: Metadata){ 
			emit Minted(id: GeniaceNFT.totalSupply)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create GeniaceNFT.NFT(initID: GeniaceNFT.totalSupply, metadata: _metadata))
			GeniaceNFT.totalSupply = GeniaceNFT.totalSupply + 1 as UInt64
		}
	}
	
	// NFTAdminHolder will act as an intrface, via this the capability to mint and NFT can be passed to external accounts
	access(all)
	struct NFTMintCapabilityHolder{ 
		access(all)
		var capability: Capability<&GeniaceNFT.NFTMinter>?
		
		// will recive the minter capability and store internally
		access(all)
		fun setCapability(_ link: Capability<&GeniaceNFT.NFTMinter>?){ 
			self.capability = link
		}
		
		// borrow minter capability
		access(all)
		fun getLink(): &GeniaceNFT.NFTMinter{ 
			let ref = (self.capability!).borrow()!
			return ref
		}
		
		init(){ 
			self.capability = nil
		}
	}
	
	init(){ 
		
		// Set named paths
		self.CollectionStoragePath = /storage/GeniaceNFTCollection
		self.CollectionPublicPath = /public/GeniaceNFTCollection
		self.MinterStoragePath = /storage/GeniaceNFTMinter
		self.MinterPrivatePath = /private/GeniaceNFTMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&GeniaceNFT.NFTMinter>(self.MinterStoragePath)
		self.account.capabilities.publish(capability_1, at: self.MinterPrivatePath)
		emit ContractInitialized()
	}
}
