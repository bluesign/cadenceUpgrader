/*
	ListenNFT
	Author: Flowstarter
	Extends the NonFungibleToken standard with an ipfs pin field and metadata for each ListenNFT. 
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract ListenNFT: NonFungibleToken{ 
	// Total number of ListenNFT's in existance
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event ListenNftCreated(id: UInt64, to: Address?)
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// ListenNFTPublic
	//
	// allows access to read the metadata and ipfs pin of the nft
	access(all)
	resource interface ListenNFTPublic{ 
		access(all)
		fun getMetadata():{ String: String}
		
		access(all)
		let ipfsPin: String
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ListenNFTPublic{ 
		access(all)
		let id: UInt64
		
		// Meta data initalized on creation and unalterable
		access(contract)
		let metadata:{ String: String}
		
		// string with ipfs pin of media data
		access(all)
		let ipfsPin: String
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, metadata:{ String: String}, ipfsPin: String){ 
			self.id = initID
			self.ipfsPin = ipfsPin
			self.metadata = metadata
		}
		
		// return metadata of NFT
		access(all)
		fun getMetadata():{ String: String}{ 
			let metadata = self.metadata
			metadata.insert(key: "ipfsPin", self.ipfsPin)
			return metadata
		}
	}
	
	// Public Interface for ListenNFTs Collection to expose metadata as required.
	// Can change this to return a structure custom rather than key value pairs  
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun getListenNFTMetadata(id: UInt64):{ String: String}
		
		access(all)
		fun borrowListenNFT(id: UInt64): &ListenNFT.NFT?
	}
	
	// standard implmentation for managing a collection of NFTs
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @ListenNFT.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// borrowListenNFT gets a reference to an ListenNFT from the collection
		// so the caller can read the NFT's extended information
		access(all)
		fun borrowListenNFT(id: UInt64): &ListenNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &ListenNFT.NFT
			} else{ 
				return nil
			}
		}
		
		// getListenNFTMetadata gets a reference to an ListenNFT with metadata from the collection
		access(all)
		fun getListenNFTMetadata(id: UInt64):{ String: String}{ 
			let listenNFT = self.borrowListenNFT(id: id)
			if listenNFT == nil{ 
				return{} 
			}
			let nftMetadata:{ String: String} = (listenNFT!).getMetadata()
			nftMetadata.insert(key: "id", id.toString())
			return nftMetadata
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
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}, ipfsPin: String){ 
			let initID = ListenNFT.totalSupply
			// create a new NFT
			var newNFT <- create NFT(initID: initID, metadata: metadata, ipfsPin: ipfsPin)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			ListenNFT.totalSupply = ListenNFT.totalSupply + 1 as UInt64
			emit ListenNftCreated(id: initID, to: self.owner?.address)
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Initalize paths for scripts and transactions usage
		self.MinterStoragePath = /storage/ListenNFTMinter
		self.CollectionStoragePath = /storage/ListenNFTCollection
		self.CollectionPublicPath = /public/ListenNFTCollection
		
		// Create a Collection resource and save it to storage
		let collection <- self.account.storage.load<@ListenNFT.Collection>(from: self.CollectionStoragePath)
		destroy collection
		self.account.storage.save(<-create Collection(), to: ListenNFT.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic, ListenNFT.CollectionPublic}>(ListenNFT.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: ListenNFT.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- self.account.storage.load<@ListenNFT.NFTMinter>(from: self.MinterStoragePath)
		destroy minter
		self.account.storage.save(<-create NFTMinter(), to: ListenNFT.MinterStoragePath)
		emit ContractInitialized()
	}
}
