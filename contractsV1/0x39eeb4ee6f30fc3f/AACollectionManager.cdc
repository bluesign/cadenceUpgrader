import AACommon from "./AACommon.cdc"

access(all)
contract AACollectionManager{ 
	access(self)
	let collections: @{UInt64: Collection}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// A map from nftType-nftID -> Collection ID
	access(self)
	let items:{ String: UInt64}
	
	access(all)
	event CollectionCreated(collectionID: UInt64, name: String)
	
	access(all)
	event CollectionItemAdd(collectionID: UInt64, type: Type, nftID: UInt64)
	
	access(all)
	event CollectionItemRemove(collectionID: UInt64, type: Type, nftID: UInt64)
	
	access(all)
	struct Item{ 
		access(all)
		let type: Type
		
		access(all)
		let nftID: UInt64
		
		init(type: Type, nftID: UInt64){ 
			self.type = type
			self.nftID = nftID
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun getCuts(): [AACommon.PaymentCut]
	}
	
	access(all)
	resource Collection: CollectionPublic{ 
		access(all)
		var name: String
		
		access(all)
		let items:{ String: Item}
		
		access(all)
		let cuts: [AACommon.PaymentCut]
		
		init(name: String, cuts: [AACommon.PaymentCut]){ 
			self.name = name
			self.items ={} 
			self.cuts = cuts
		}
		
		access(all)
		fun addItemToCollection(type: Type, nftID: UInt64){ 
			self.items[AACommon.itemIdentifier(type: type, id: nftID)] = Item(type: type, nftID: nftID)
			emit CollectionItemAdd(collectionID: self.uuid, type: type, nftID: nftID)
		}
		
		access(all)
		fun removeItemFromCollection(type: Type, nftID: UInt64){ 
			self.items.remove(key: AACommon.itemIdentifier(type: type, id: nftID))
			emit CollectionItemRemove(collectionID: self.uuid, type: type, nftID: nftID)
		}
		
		access(all)
		fun getCuts(): [AACommon.PaymentCut]{ 
			return self.cuts
		}
	}
	
	access(all)
	fun borrowCollection(id: UInt64): &Collection?{ 
		if self.collections[id] != nil{ 
			return (&self.collections[id] as &Collection?)!
		}
		return nil
	}
	
	access(all)
	fun getCollectionCuts(type: Type, nftID: UInt64): [AACommon.PaymentCut]?{ 
		if let collectionID = self.items[AACommon.itemIdentifier(type: type, id: nftID)]{ 
			let collection = self.borrowCollection(id: collectionID)
			return collection?.getCuts()
		}
		return nil
	}
	
	access(all)
	resource Administrator{ 
		access(all)
		fun createCollection(name: String, cuts: [AACommon.PaymentCut]){ 
			let collection <- create Collection(name: name, cuts: cuts)
			let collectionID = collection.uuid
			let old <- AACollectionManager.collections[collectionID] <- collection
			destroy old
			emit CollectionCreated(collectionID: collectionID, name: name)
		}
		
		access(all)
		fun addItemToCollection(collectionID: UInt64, type: Type, nftID: UInt64){ 
			pre{ 
				AACollectionManager.collections.containsKey(collectionID):
					"Collection not exist"
			}
			let id = AACommon.itemIdentifier(type: type, id: nftID)
			assert(
				AACollectionManager.items[id] == nil,
				message: "1 NFT should only in a collection"
			)
			let collection = (&AACollectionManager.collections[collectionID] as &Collection?)!
			collection.addItemToCollection(type: type, nftID: nftID)
			AACollectionManager.items[id] = collectionID
		}
		
		access(all)
		fun removeItemFromCollection(collectionID: UInt64, type: Type, nftID: UInt64){ 
			pre{ 
				AACollectionManager.collections.containsKey(collectionID):
					"Collection not exist"
			}
			let collection = (&AACollectionManager.collections[collectionID] as &Collection?)!
			collection.removeItemFromCollection(type: type, nftID: nftID)
			let id = AACommon.itemIdentifier(type: type, id: nftID)
			AACollectionManager.items.remove(key: id)
		}
	}
	
	init(){ 
		self.collections <-{} 
		self.items ={} 
		self.AdminStoragePath = /storage/AACollectionManagerAdmin
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
}
