// This is a complete version of the NFTKred contract
// that includes withdraw and deposit functionality, as well as a
// collection resource that can be used to bundle NFTs together.
//
// It also includes a definition for the Minter resource,
// which can be used by admins to mint new NFTs.

// NOTE: 16 bit numbers are used to represent sequence and limit, 
// unlike 32 bit numbers of the other NFTKred standards. This does not change the functionality
// and ID generation is handled internally, but it does change the maximum number of NFT's that
// can be minted into a single batch to 65536, which should still be enough for our applications.

// This is done for performance reasons, as it allows for a much smaller storage footprint and effective use of capacity
// which is recommended by FLOW team.
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract NFTKred: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// Declare the NFT resource type
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The unique ID that differentiates each NFT
		// The ID is used to reference the NFT in the collection, and is guaranteed to be unique with bit-shifting of unique batch-sequence-limit combination
		// Minting another NFT with the same ID (batch-seq-limit) will fail, as intended
		
		// NOTE: 16 bit numbers are used to represent sequence and limit, 
		// unlike 32 bit numbers of the other NFTKred standards. This does not change the functionality
		// and ID generation is handled internally, but it does change the maximum number of NFT's that
		// can be minted into a single batch to 65536, which should still be enough for our applications.
		
		// This is done for performance reasons, as it allows for a much smaller storage footprint and effective use of capacity
		// which is recommended by FLOW team.
		
		// The ID is stored in the collection as a 64 bit unsigned integer
		access(all)
		let id: UInt64
		
		access(all)
		var link: String
		
		access(all)
		var batch: UInt32
		
		access(all)
		var sequence: UInt16
		
		access(all)
		var limit: UInt16
		
		// Initialize both fields in the init function
		init(initID: UInt64, initlink: String, initbatch: UInt32, initsequence: UInt16, initlimit: UInt16){ 
			self.id = initID // token id
			
			self.link = initlink
			self.batch = initbatch
			self.sequence = initsequence
			self.limit = initlimit
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.NFTCollectionData>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: NFTKred.CollectionStoragePath, publicPath: NFTKred.CollectionPublicPath, publicCollection: Type<&NFTKred.Collection>(), publicLinkedType: Type<&NFTKred.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-NFTKred.createEmptyCollection(nftType: Type<@NFTKred.Collection>())
						})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Declare the collection resource type
	access(all)
	resource interface NFTKredCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowNFTKred(id: UInt64): &NFTKred.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow NFTKred reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// The definition of the Collection resource that
	// holds the NFTs that a user owns
	access(all)
	resource Collection: NFTKredCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// Initialize the NFTs field to an empty collection
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
			let token <- self.ownedNFTs.remove(key: withdrawID)!
			
			// emit the withdraw event
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit 
		//
		// Function that takes a NFT as an argument and 
		// adds it to the collections dictionary
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			// add the new token to the dictionary with a force assignment
			// if there is already a value at that key, it will fail and revert
			
			// Rhea comment- make sure to cast the received NonFungibleToken.NFT to your concrete NFT type
			let token <- token as! @NFTKred.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// idExists checks to see if a NFT 
		// with the given ID exists in the collection
		//pub fun idExists(id: UInt64): Bool {
		//	return self.ownedNFTs[id] != nil
		//}
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nftKredNFT = nft as! &NFTKred.NFT
			return nftKredNFT as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun borrowNFTKred(id: UInt64): &NFTKred.NFT?{ 
			if self.ownedNFTs[id] == nil{ 
				return nil
			} else{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &NFTKred.NFT
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
	
	// creates a new empty Collection resource and returns it 
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// NFTMinter
	// Resource that would be owned by an admin or by a smart contract 
	// that allows them to mint new NFTs when needed
	access(all)
	resource NFTMinter{ 
		// the ID that is used to mint NFTs
		// it is only incremented so that NFT ids remain
		// unique. It also keeps track of the total number of NFTs
		// in existence
		access(all)
		var minterID: UInt64
		
		init(){ 
			self.minterID = 0
		}
		
		// mintNFT mints a new NFT with the given batch, sequence and limit combination, by creating a UNIQUE ID
		// Function that mints a new NFT with a new ID
		// and returns it to the caller
		access(all)
		fun mintNFT(glink: String, gbatch: UInt32, glimit: UInt16, gsequence: UInt16): @NFT{ 
			// create a new NFT
			// Cadence does not allow applying binary operation << to types: `UInt16`, `UInt32`, hence, a small typecasting trick, recommended by FLOW team
			let tokenID = UInt64(gbatch) << 32 | UInt64(glimit) << 16 | UInt64(gsequence)
			var newNFT <- create NFT(initID: tokenID, initlink: glink, initbatch: gbatch, initsequence: gsequence, initlimit: glimit)
			
			// Set the id so that each ID is unique from this minter, ensuring unique ID combination for each asset with NFT.Kred standard
			self.minterID = tokenID
			
			//increase total supply
			NFTKred.totalSupply = NFTKred.totalSupply + UInt64(1)
			return <-newNFT
		}
	}
	
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/NFTKredCollection
		self.CollectionPublicPath = /public/NFTKredCollection
		self.MinterStoragePath = /storage/NFTKredMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// store an empty NFT Collection in account storage
		self.account.storage.save(<-self.createEmptyCollection(nftType: Type<@Collection>()), to: self.CollectionStoragePath)
		
		// publish a reference to the Collection in storage
		var capability_1 = self.account.capabilities.storage.issue<&{NFTKred.NFTKredCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// store a minter resource in account storage
		self.account.storage.save(<-create NFTMinter(), to: self.MinterStoragePath)
	}
}
