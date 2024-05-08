// SPDX-License-Identifier: UNLICENSED
/*
	Description: Central Collection for a large number of CricketMoments
				 NFTs

	This contract bundles together a bunch of Collection objects 
	in a dictionary, and then distributes the individual Moments between them 
	while implementing the same public interface 
	as the default CricketMomentCollection implementation. 

	If we assume that Moment IDs are uniformly distributed, 
	a ShardedCollection with 10 inner Collections should be able 
	to store 10x as many Moments (or ~1M).

	When Cadence is updated to allow larger dictionaries, 
	then this contract can be retired.

*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import CricketMoments from "./CricketMoments.cdc"

access(all)
contract CricketMomentsShardedCollection{ 
	access(all)
	let ShardedCollectionStoragePath: StoragePath
	
	// ShardedCollection stores a dictionary of CricketMoments Collections
	// A Moment is stored in the field that corresponds to its id % numBuckets
	access(all)
	resource ShardedCollection:
		CricketMoments.CricketMomentsCollectionPublic,
		NonFungibleToken.Provider,
		NonFungibleToken.Receiver,
		NonFungibleToken.Collection,
		NonFungibleToken.CollectionPublic{
	
		// Dictionary of CricketMoments collections
		access(all)
		var collections: @{UInt64: CricketMoments.Collection}
		
		// The number of buckets to split Moments into
		// This makes storage more efficient and performant
		access(all)
		let numBuckets: UInt64
		
		init(numBuckets: UInt64){ 
			self.collections <-{} 
			self.numBuckets = numBuckets
			
			// Create a new empty collection for each bucket
			var i: UInt64 = 0
			while i < numBuckets{ 
				self.collections[i] <-! CricketMoments.createEmptyCollection(nftType: Type<@CricketMoments.Collection>()) as! @CricketMoments.Collection
				i = i + 1 as UInt64
			}
		}
		
		// withdraw removes a Moment from one of the Collections 
		// and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			post{ 
				result.id == withdrawID:
					"The ID of the withdrawn NFT is incorrect"
			}
			// Find the bucket it should be withdrawn from
			let bucket = withdrawID % self.numBuckets
			
			// Withdraw the moment
			let token <- self.collections[bucket]?.withdraw(withdrawID: withdrawID)!
			return <-token
		}
		
		// deposit takes a Moment and adds it to the Collections dictionary
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			
			// Find the bucket this corresponds to
			let bucket = token.id % self.numBuckets
			
			// Get collection Reference
			let collectionRef = (&self.collections[bucket] as &CricketMoments.Collection?)!
			
			// Deposit the nft into the bucket
			collectionRef.deposit(token: <-token)
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
		
		// borrowNFT Returns a borrowed reference to a Moment in the Collection
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
		
		// borrowCricketMoment Returns a borrowed reference to a Moment in the Collection
		// so that the caller can read data and call methods from it
		// They can use this to read its serial, momentId, metadata
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(all)
		fun borrowCricketMoment(id: UInt64): &CricketMoments.NFT?{ 
			
			// Get the bucket of the nft to be borrowed
			let bucket = id % self.numBuckets
			return self.collections[bucket]?.borrowCricketMoment(id: id) ?? nil
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
		self.ShardedCollectionStoragePath = /storage/CricketMomentsShardedCollection
	}
}
