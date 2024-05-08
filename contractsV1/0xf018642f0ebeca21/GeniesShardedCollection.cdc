/*
	Description: Central Collection for a large number of Genies NFTs

	Adapted from: TopShotShardedCollection.cdc
	Authors: Joshua Hannan joshua.hannan@dapperlabs.com
			 Bastian Muller bastian@dapperlabs.com

	[...]

	When Cadence is updated to allow larger dictionaries, 
	then this contract can be retired.
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import Genies from "../0x9c2234b992667d22/Genies.cdc"

access(all)
contract GeniesShardedCollection{ 
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	// ShardedCollection stores a dictionary of Genies Collections
	// A Genies NFT is stored in the field that corresponds to its id % numBuckets
	access(all)
	resource ShardedCollection:
		Genies.GeniesNFTCollectionPublic,
		NonFungibleToken.Provider,
		NonFungibleToken.Receiver,
		NonFungibleToken.Collection,
		NonFungibleToken.CollectionPublic{
	
		// Dictionary of Genies collections
		access(all)
		var collections: @{UInt64: Genies.Collection}
		
		// The number of buckets to split Genies NFTs into
		// This makes storage more efficient and performant
		access(all)
		let numBuckets: UInt64
		
		init(numBuckets: UInt64){ 
			self.collections <-{} 
			self.numBuckets = numBuckets
			
			// Create a new empty collection for each bucket
			var i: UInt64 = 0
			while i < numBuckets{ 
				self.collections[i] <-! Genies.createEmptyCollection(nftType: Type<@Genies.Collection>()) as! @Genies.Collection
				i = i + 1 as UInt64
			}
		}
		
		// withdraw removes a Genies NFT from one of the Collections
		// and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			post{ 
				result.id == withdrawID:
					"The ID of the withdrawn NFT is incorrect"
			}
			// Find the bucket it should be withdrawn from
			let bucket = withdrawID % self.numBuckets
			
			// Withdraw the Genies NFT
			let token <- self.collections[bucket]?.withdraw(withdrawID: withdrawID)!
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: ids: an array of the IDs to be withdrawn from the Collection
		//
		// Returns: @NonFungibleToken.Collection a Collection containing the Genies NFTs
		//		  that were withdrawn
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <- Genies.createEmptyCollection(nftType: Type<@Genies.Collection>())
			
			// Iterate through the ids and withdraw them from the Collection
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		// deposit takes a Genies NFT and adds it to the Collections dictionary
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			
			// Find the bucket this corresponds to
			let bucket = token.id % self.numBuckets
			
			// Remove the collection
			let collection <- self.collections.remove(key: bucket)!
			
			// Deposit the nft into the bucket
			collection.deposit(token: <-token)
			
			// Put the Collection back in storage
			self.collections[bucket] <-! collection
		}
		
		// batchDeposit takes a Collection object as an argument
		// and deposits each contained NFT into this Collection
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			let keys = tokens.getIDs()
			
			// Iterate through the keys in the Collection and deposit each one
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			destroy tokens
		}
		
		// getIDs returns an array of the IDs that are in the Collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			var ids: [UInt64] = []
			// Concatenate IDs in all the Collections
			for key in self.collections.keys{ 
				for id in self.collections[key]?.getIDs() ?? []{ 
					ids.append(id)
				}
			}
			return ids
		}
		
		// borrowNFT Returns a borrowed reference to a Genies NFT in the Collection
		// so that the caller can read data and call methods from it
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			post{ 
				result.id == id:
					"The ID of the reference is incorrect"
			}
			
			// Get the bucket of the nft to be borrowed
			let bucket = id % self.numBuckets
			
			// Find NFT in the collections and borrow a reference
			return self.collections[bucket]?.borrowNFT(id)!!
		}
		
		// borrowGeniesNFT Returns a borrowed reference to a Genies NFT in the Collection
		// so that the caller can read data and call methods from it
		// They can use this to read its setID, playID, serialNumber,
		// or any of the setData or Play Data associated with it by
		// getting the setID or playID and reading those fields from
		// the smart contract
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(all)
		fun borrowGeniesNFT(id: UInt64): &Genies.NFT?{ 
			
			// Get the bucket of the nft to be borrowed
			let bucket = id % self.numBuckets
			return self.collections[bucket]?.borrowGeniesNFT(id: id) ?? nil
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
	
	// If a transaction destroys the Collection object,
	// All the NFTs contained within are also destroyed
	}
	
	// Creates an empty ShardedCollection and returns it to the caller
	access(all)
	fun createEmptyCollection(numBuckets: UInt64): @ShardedCollection{ 
		return <-create ShardedCollection(numBuckets: numBuckets)
	}
	
	init(){ 
		// Set the named paths
		self.CollectionStoragePath = /storage/GeniesShardedNFTCollection
	}
}
