// import NonFungibleToken from "../"./NonFungibleToken.cdc"/NonFungibleToken.cdc"
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

// TheGreatGeneral
// NFT items for MugenART!
//
access(all)
contract TheGreatGeneral: NonFungibleToken{ 
	
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
	event MintFail(id: UInt64)
	
	access(all)
	event MintFailDuplicateId(id: UInt64)
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let maxSupply: UInt64
	
	// totalSupply
	// The total number of NTFs that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var mintedIds:{ UInt64: Bool}
	
	// NFT
	// A Kitty Item as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(initID: UInt64){ 
			self.id = initID
		}
	}
	
	// Collection
	// A collection of NFTs owned by an account
	//
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
			emit Withdraw(id: withdrawID, from: self.owner?.address)
			return <-token
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @TheGreatGeneral.NFT
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, mugenNFTID: UInt64){ 
			if TheGreatGeneral.mintedIds[mugenNFTID] == true{ 
				emit MintFailDuplicateId(id: mugenNFTID)
				panic("Duplicate token id")
			}
			if TheGreatGeneral.totalSupply == TheGreatGeneral.maxSupply{ 
				emit MintFail(id: mugenNFTID)
				panic("Exceed the max supply")
			}
			emit Minted(id: mugenNFTID)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create TheGreatGeneral.NFT(initID: mugenNFTID))
			TheGreatGeneral.mintedIds[mugenNFTID] = true
			TheGreatGeneral.totalSupply = TheGreatGeneral.totalSupply + 1 as UInt64
		}
	}
	
	// initializer
	//
	init(){ 
		// Mugen contract name
		// Set our named paths
		self.CollectionStoragePath = /storage/TheGreatGeneralCollection
		self.CollectionPublicPath = /public/TheGreatGeneralCollection
		self.MinterStoragePath = /storage/TheGreatGeneral
		
		// Initialize the total supply
		self.totalSupply = 1
		self.maxSupply = 10000
		self.mintedIds ={} 
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
