import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract FantastecNFT: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(item: Item)
	
	access(all)
	event Destroyed(id: UInt64, reason: String)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of FantastecNFT that have ever been minted
	//
	access(all)
	var totalSupply: UInt64
	
	access(all)
	struct Item{ 
		access(all)
		let id: UInt64
		
		access(all)
		let cardId: UInt64
		
		access(all)
		let edition: UInt64
		
		access(all)
		let mintNumber: UInt64
		
		access(all)
		let metadata:{ String: String}
		
		init(id: UInt64, cardId: UInt64, edition: UInt64, mintNumber: UInt64, metadata:{ String: String}){ 
			self.id = id
			self.cardId = cardId
			self.edition = edition
			self.mintNumber = mintNumber
			self.metadata = metadata
		}
	}
	
	// NFT: FantastecNFT.NFT
	// Raw NFT, doesn't currently restrict the caller instantiating an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		access(all)
		let cardId: UInt64
		
		access(all)
		let edition: UInt64
		
		access(all)
		let mintNumber: UInt64
		
		access(all)
		let metadata:{ String: String}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(item: Item){ 
			self.id = item.id
			self.cardId = item.cardId
			self.edition = item.edition
			self.mintNumber = item.mintNumber
			self.metadata = item.metadata
		}
	}
	
	// This is the interface that users can cast their FantastecNFT Collection as
	// to allow others to deposit FantastecNFTs into their Collection. It also allows for reading
	// the details of FantastecNFTs in the Collection.
	access(all)
	resource interface FantastecNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowFantastecNFT(id: UInt64): &FantastecNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow FantastecNFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of Moment NFTs owned by an account
	//
	access(all)
	resource Collection: FantastecNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		// metadataObjs is a dictionary of metadata mapped to NFT IDs
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @FantastecNFT.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			// TODO: This should never happen
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			if oldToken != nil{ 
				emit Destroyed(id: id, reason: "replaced existing resource with the same id")
			}
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
		
		// borrowFantastecNFT
		// Gets a reference to an NFT in the collection as a FantastecNFT,
		// exposing all of its fields.
		// This is safe as there are no functions that can be called on the FantastecNFT.
		//
		access(all)
		fun borrowFantastecNFT(id: UInt64): &FantastecNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &FantastecNFT.NFT
			} else{ 
				return nil
			}
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
		// Mints a new NFTs
		// Increments mintNumber
		// deposits the NFT into the recipients collection using their collection reference
		//
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, cardId: UInt64, edition: UInt64, mintNumber: UInt64, metadata:{ String: String}){ 
			let newId = FantastecNFT.totalSupply + 1 as UInt64
			let nftData: Item = Item(id: FantastecNFT.totalSupply, cardId: cardId, edition: edition, mintNumber: mintNumber, metadata: metadata)
			var newNFT <- create FantastecNFT.NFT(item: nftData)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			
			// emit and update contract
			emit Minted(item: nftData)
			
			// update contracts
			FantastecNFT.totalSupply = newId
		}
	}
	
	access(all)
	fun getTotalSupply(): UInt64{ 
		return FantastecNFT.totalSupply
	}
	
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/FantastecNFTCollection
		self.CollectionPublicPath = /public/FantastecNFTCollection
		self.MinterStoragePath = /storage/FantastecNFTMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
