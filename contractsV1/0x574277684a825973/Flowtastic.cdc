access(all)
contract Flowtastic{ 
	
	// Declare a Path constant so we don't need to harcode in tx
	access(all)
	let ReviewCollectionStoragePath: StoragePath
	
	access(all)
	let ReviewCollectionPublicPath: PublicPath
	
	// Declare the Review resource type - nothing changed here!
	access(all)
	resource Review{ 
		// The unique ID that differentiates each Review
		access(all)
		let id: UInt64
		
		// String mapping to hold metadata
		access(all)
		var metadata:{ String: String}
		
		// Initialize both fields in the init function
		init(metadata:{ String: String}){ 
			self.id = self.uuid
			self.metadata = metadata
		}
	}
	
	// Function to create a new Review
	access(all)
	fun createReview(metadata:{ String: String}): @Review{ 
		return <-create Review(metadata: metadata)
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun borrowReview(id: UInt64): &Review?
	}
	
	// Declare a Collection resource that contains Reviews.
	// it does so via `saveReview()`, 
	// and stores them in `self.reviews`
	access(all)
	resource Collection: CollectionPublic{ 
		// an object containing the reviews
		access(all)
		var reviews: @{UInt64: Review}
		
		// a method to save a review in the collection
		access(all)
		fun saveReview(review: @Review){ 
			// add the new review to the dictionary with 
			// a force assignment (check glossary!)
			// If there were to be a value at that key, 
			// it would fail/revert. 
			self.reviews[review.id] <-! review
		}
		
		// get all the id's of the reviews in the collection
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.reviews.keys
		}
		
		access(all)
		fun borrowReview(id: UInt64): &Review?{ 
			if self.reviews[id] != nil{ 
				let ref = (&self.reviews[id] as &Flowtastic.Review?)!
				return ref
			}
			return nil
		}
		
		init(){ 
			self.reviews <-{} 
		}
	}
	
	// create a new collection
	access(all)
	fun createEmptyCollection(): @Collection{ 
		return <-create Collection()
	}
	
	init(){ 
		// assign the storage path to /storage/ReviewCollection
		self.ReviewCollectionStoragePath = /storage/ReviewCollection
		self.ReviewCollectionPublicPath = /public/ReviewCollection
		// save the empty collection to the storage path
		self.account.storage.save(
			<-self.createEmptyCollection(),
			to: self.ReviewCollectionStoragePath
		)
		// publish a reference to the Collection in storage
		var capability_1 =
			self.account.capabilities.storage.issue<&{CollectionPublic}>(
				self.ReviewCollectionStoragePath
			)
		self.account.capabilities.publish(capability_1, at: self.ReviewCollectionPublicPath)
	}
}
