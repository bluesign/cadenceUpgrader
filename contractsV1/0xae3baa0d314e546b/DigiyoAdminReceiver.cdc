//SPDX-License-Identifier: MIT
import Digiyo from "./Digiyo.cdc"

import DigiyoSplitCollection from "./DigiyoSplitCollection.cdc"

access(all)
contract DigiyoAdminReceiver{ 
	access(all)
	let splitCollectionPath: StoragePath
	
	access(all)
	fun storeAdmin(newAdmin: @Digiyo.Admin){ 
		self.account.storage.save(<-newAdmin, to: Digiyo.digiyoAdminPath)
	}
	
	init(){ 
		self.splitCollectionPath = /storage/SplitDigiyoNFTCollection
		if self.account.storage.borrow<&DigiyoSplitCollection.SplitCollection>(
			from: self.splitCollectionPath
		)
		== nil{ 
			let collection <- DigiyoSplitCollection.createEmptyCollection(numBuckets: 32)
			self.account.storage.save(<-collection, to: self.splitCollectionPath)
			var capability_1 =
				self.account.capabilities.storage.issue<&{Digiyo.DigiyoNFTCollectionPublic}>(
					self.splitCollectionPath
				)
			self.account.capabilities.publish(capability_1, at: Digiyo.collectionPublicPath)
		}
	}
}
