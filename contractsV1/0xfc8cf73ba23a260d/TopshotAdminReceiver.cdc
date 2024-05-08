/*

  AdminReceiver.cdc

  This contract defines a function that takes a TopShot admin
  object and stores it in the storage of the contract account
  so it can be used normally

 */

import TopShot from "../0x0b2a3299cc857e29/TopShot.cdc"

import TopShotShardedCollection from "../0xef4d8b44dd7f7ef6/TopShotShardedCollection.cdc"

access(all)
contract TopshotAdminReceiver{ 
	access(all)
	fun storeAdmin(newAdmin: @TopShot.Admin){ 
		self.account.storage.save(<-newAdmin, to: /storage/TopShotAdmin)
	}
	
	init(){ 
		if self.account.storage.borrow<&TopShotShardedCollection.ShardedCollection>(
			from: /storage/ShardedMomentCollection
		)
		== nil{ 
			let collection <- TopShotShardedCollection.createEmptyCollection(numBuckets: 32)
			// Put a new Collection in storage
			self.account.storage.save(<-collection, to: /storage/ShardedMomentCollection)
			var capability_1 =
				self.account.capabilities.storage.issue<&{TopShot.MomentCollectionPublic}>(
					/storage/ShardedMomentCollection
				)
			self.account.capabilities.publish(capability_1, at: /public/MomentCollection)
		}
	}
}
