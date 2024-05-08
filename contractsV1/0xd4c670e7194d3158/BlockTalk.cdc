access(all)
contract BlockTalk{ 
	access(all)
	let TalkCollectionStoragePath: StoragePath
	
	access(all)
	let TalkCollectionPublicPath: PublicPath
	
	access(all)
	event TalkCreated(id: UInt64)
	
	access(all)
	event TalkSaved(id: UInt64, owner: Address?)
	
	access(all)
	resource Talk{ 
		access(all)
		let id: UInt64
		
		access(all)
		var metadata:{ String: String}
		
		init(body: String, tweetID: String?){ 
			self.id = self.uuid
			if let _tweetID = tweetID{ 
				self.metadata ={ "tweetId": _tweetID, "body": body}
			} else{ 
				self.metadata ={ "body": body}
			}
		}
	}
	
	access(all)
	fun createTalk(body: String, tweetID: String?): @Talk{ 
		let newTalk: @Talk <- create Talk(body: body, tweetID: tweetID)
		emit TalkCreated(id: newTalk.id)
		return <-newTalk
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun borrowTalk(id: UInt64): &Talk?
	}
	
	access(all)
	resource Collection: CollectionPublic{ 
		access(all)
		var talks: @{UInt64: Talk}
		
		access(all)
		fun saveTalk(talk: @Talk){ 
			emit TalkSaved(id: talk.id, owner: self.owner?.address)
			self.talks[talk.id] <-! talk
		}
		
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.talks.keys
		}
		
		access(all)
		fun borrowTalk(id: UInt64): &Talk?{ 
			if self.talks[id] != nil{ 
				return (&self.talks[id] as &BlockTalk.Talk?)!
			}
			return nil
		}
		
		init(){ 
			self.talks <-{} 
		}
	}
	
	access(all)
	fun createEmptyCollection(): @Collection{ 
		return <-create Collection()
	}
	
	init(){ 
		self.TalkCollectionStoragePath = /storage/BlockTalkCollection
		self.TalkCollectionPublicPath = /public/BlockTalkCollection
		var capability_1 =
			self.account.capabilities.storage.issue<&{CollectionPublic}>(
				self.TalkCollectionStoragePath
			)
		self.account.capabilities.publish(capability_1, at: self.TalkCollectionPublicPath)
	}
}
