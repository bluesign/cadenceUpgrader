/*

  AdminReceiver.cdc

  This contract defines a function that takes a Olympic Admin
  object and stores it in the storage of the contract account
  so it can be used.

  Do not deploy this contract to initial Admin.
 */

import OlympicPin from 0x1d007eed492fdbbe

import OlympicPinShardedCollection from "../0xf087790fe77461e4/OlympicPinShardedCollection.cdc"

access(all)
contract OlympicPinAdminReceiver{ 
	
	// storeAdmin takes a OlympicPin Admin resource and 
	// saves it to the account storage of the account
	// where the contract is deployed
	access(all)
	fun storeAdmin(newAdmin: @OlympicPin.Admin){ 
		self.account.storage.save(<-newAdmin, to: OlympicPin.AdminStoragePath)
	}
	
	init(){ 
		// Save a copy of the sharded Piece Collection to the account storage
		if self.account.storage.borrow<&OlympicPinShardedCollection.ShardedCollection>(
			from: OlympicPinShardedCollection.ShardedPieceCollectionPath
		)
		== nil{ 
			let collection <- OlympicPinShardedCollection.createEmptyCollection(numBuckets: 32)
			// Put a new Collection in storage
			self.account.storage.save(
				<-collection,
				to: OlympicPinShardedCollection.ShardedPieceCollectionPath
			)
			var capability_1 =
				self.account.capabilities.storage.issue<&{OlympicPin.PieceCollectionPublic}>(
					OlympicPinShardedCollection.ShardedPieceCollectionPath
				)
			self.account.capabilities.publish(capability_1, at: OlympicPin.CollectionPublicPath)
		}
	}
}
