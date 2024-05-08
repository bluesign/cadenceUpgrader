// SPDX-License-Identifier: UNLICENSED
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract BfeNFT: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event NFTMinted(id: UInt64)
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	var totalSupply: UInt64
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// Declare the NFT resource type
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The unique ID that differentiates each NFT
		access(all)
		let id: UInt64
		
		access(self)
		let metadata:{ String: String}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		// Initialize fields in the init function
		init(initID: UInt64, initMetadata:{ String: String}){ 
			self.id = initID
			self.metadata = initMetadata
		}
	}
	
	// We define this interface purely as a way to allow users
	// to create public, restricted references to their NFT Collection.
	// They would use this to only expose the deposit, getIDs,
	// idExists, and getMetadata fields in their Collection
	access(all)
	resource interface NFTReceiver{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowBfeNFT(id: UInt64): &BfeNFT.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow BfeNFT reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		fun idExists(id: UInt64): Bool
	}
	
	// The definition of the Collection resource that
	// holds the NFTs that a user owns
	access(all)
	resource Collection: NFTReceiver, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		
		// ownedNFTs keeps track of all NFTs a user owns 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// Initialize the ownedNFTs field to an empty collection (for NFTs),
		// and the metadataObjs field to an empty dictionary (for Strings)
		init(){ 
			self.ownedNFTs <-{} 
		}
		
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
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @BfeNFT.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			self.ownedNFTs[id] <-! token
			emit Deposit(id: id, to: self.owner?.address)
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		access(all)
		fun borrowBfeNFT(id: UInt64): &BfeNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &BfeNFT.NFT
			} else{ 
				return nil
			}
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
		
		// the ID that is used to mint NFTs
		// it is only incremented so that NFT ids remain
		// unique. It also keeps track of the total number of NFTs
		// in existence.
		access(all)
		var idCount: UInt64
		
		init(){ 
			self.idCount = 1
		}
		
		// mintNFT 
		//
		// Function that mints a new NFT with a new ID
		// and, instead of depositing the NFT into a specific recipient's collection storage location,
		// just returns the NFT itself!
		access(all)
		fun mintNFT(metadata:{ String: String}): @{NonFungibleToken.NFT}{ 
			
			// create a new NFT! This is where the NFT's core ID gets created.
			// Right now, it's just getting this ID from the idCount field, which
			// merely increments up with each NFT minted. If we want to create more
			// complex IDs with hashing etc., this would be the place to put that new ID
			// generated from that technique.
			var oldNFT <- create NFT(initID: self.idCount, initMetadata: metadata)
			let newNFT <- oldNFT as! @{NonFungibleToken.NFT}
			emit NFTMinted(id: self.idCount)
			
			// Increments the id so that each ID is unique
			self.idCount = self.idCount + 1 as UInt64
			BfeNFT.totalSupply = BfeNFT.totalSupply + 1 as UInt64
			return <-newNFT
		}
	}
	
	init(){ 
		
		// Initialize the total supply
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/BfeNFTcollection
		self.CollectionPublicPath = /public/BfeNFTreceiver
		self.MinterStoragePath = /storage/BfeNFTminter
		
		// store an empty NFT Collection in account storage
		self.account.storage.save(<-self.createEmptyCollection(nftType: Type<@Collection>()), to: self.CollectionStoragePath)
		
		// publish a reference to the Collection in storage
		var capability_1 = self.account.capabilities.storage.issue<&{BfeNFT.NFTReceiver}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// store a minter resource in account storage
		self.account.storage.save(<-create NFTMinter(), to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
