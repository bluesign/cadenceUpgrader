access(all)
contract FlowMeiumContract{ 
	// Events
	access(all)
	event FlowMeiumUserCreated(address: Address)
	
	access(all)
	event FlowMeiumPostCreated(_post: PartialPost)
	
	access(all)
	event FlowMeiumPostDeleted(_post: PartialPost)
	
	access(all)
	event FlowMeiumPostUpdated(_post: PartialPost)
	
	// Declare a Path constant so we don't need to harcode in tx
	access(all)
	let PostCollectionStoragePath: StoragePath
	
	access(all)
	let PostCollectionPublicPath: PublicPath
	
	access(all)
	struct Author{ 
		access(all)
		let author: Address
		
		access(all)
		let royalty: UFix64
		
		init(_author: Address, _royalty: UFix64){ 
			self.author = _author
			self.royalty = _royalty
		}
	}
	
	// Declare the Post resource type
	access(all)
	resource Post{ 
		// The unique ID that differentiates each Post
		access(all)
		let id: UInt64
		
		access(all)
		var title: String
		
		access(all)
		var description: String
		
		access(all)
		var author: Address
		
		access(all)
		var image: String
		
		access(all)
		var price: UFix64
		
		access(all)
		var data: String
		
		access(all)
		var metadata:{ String: String}
		
		access(all)
		var createDate: UFix64
		
		// Initialize both fields in the init function
		init(
			_title: String,
			_description: String,
			_author: Address,
			_image: String,
			_price: UFix64,
			_data: String,
			_metadata:{ 
				String: String
			}
		){ 
			self.id = self.uuid
			self.title = _title
			self.description = _description
			self.author = _author
			self.image = _image
			self.price = _price
			self.data = _data
			self.metadata = _metadata
			self.createDate = getCurrentBlock().timestamp
		}
	}
	
	// Partial Post -> Open to be viewed by public, does not contain complete data
	access(all)
	struct PartialPost{ 
		access(all)
		let id: UInt64?
		
		access(all)
		let title: String?
		
		access(all)
		let description: String?
		
		access(all)
		let author: Address?
		
		access(all)
		let image: String?
		
		access(all)
		let price: UFix64?
		
		access(all)
		let metadata:{ String: String}?
		
		access(all)
		let createDate: UFix64?
		
		access(all)
		let data: String?
		
		init(
			_id: UInt64?,
			_title: String?,
			_description: String?,
			_author: Address?,
			_image: String?,
			_price: UFix64?,
			_createDate: UFix64?,
			_metadata:{ 
				String: String
			}?,
			_data: String?
		){ 
			self.id = _id
			self.title = _title
			self.description = _description
			self.author = _author
			self.image = _image
			self.price = _price
			self.metadata = _metadata
			self.createDate = _createDate
			self.data = _data
		}
	}
	
	// Function to create a new Post
	access(all)
	fun createPost(
		_title: String,
		_description: String,
		_author: Address,
		_image: String,
		_price: UFix64,
		_data: String,
		_metadata:{ 
			String: String
		}
	): @Post{ 
		return <-create Post(
			_title: _title,
			_description: _description,
			_author: _author,
			_image: _image,
			_price: _price,
			_data: _data,
			_metadata: _metadata
		)
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun borrowPartialPost(postID: UInt64): PartialPost?
		
		access(all)
		fun getAllPostIDs(): [UInt64]
		
		access(all)
		fun borrowPost(postID: UInt64, address: Address?): &Post?
	}
	
	access(all)
	resource Collection: CollectionPublic{ 
		access(self)
		var posts: @{UInt64: Post}
		
		access(all)
		fun updatePost(_post: PartialPost){ 
			if _post.id != nil && self.posts.containsKey(_post.id!){ 
				let ref: &FlowMeiumContract.Post = (&self.posts[_post.id!] as &FlowMeiumContract.Post?)!
				ref.title = _post.title ?? ref.title
				ref.description = _post.description ?? ref.description
				ref.image = _post.image ?? ref.image
				ref.data = _post.data ?? ref.data
				ref.price = _post.price ?? ref.price
				ref.metadata = _post.metadata ?? ref.metadata
				emit FlowMeiumPostUpdated(_post: _post)
			}
		}
		
		access(all)
		fun savePost(_post: @Post){ 
			// If there were to be a value at that key, 
			// it would fail/revert. 
			let evetData: PartialPost = PartialPost(_id: _post.id, _title: _post.title, _description: _post.description, _author: _post.author, _image: _post.image, _price: _post.price, _createDate: _post.createDate, _metadata: _post.metadata, _data: nil)
			emit FlowMeiumPostCreated(_post: evetData)
			self.posts[_post.id] <-! _post
		}
		
		init(){ 
			self.posts <-{} 
		}
		
		access(all)
		fun borrowPartialPost(postID: UInt64): FlowMeiumContract.PartialPost?{ 
			if self.posts[postID] != nil{ 
				let ref: &FlowMeiumContract.Post = (&self.posts[postID!] as &FlowMeiumContract.Post?)!
				let postData: PartialPost = PartialPost(_id: ref.id, _title: ref.title, _description: ref.description, _author: ref.author, _image: ref.image, _price: ref.price, _createDate: ref.createDate, _metadata: ref.metadata, _data: nil)
				return postData
			}
			return nil
		}
		
		access(all)
		fun getAllPostIDs(): [UInt64]{ 
			return self.posts.keys
		}
		
		access(all)
		fun borrowPost(postID: UInt64, address: Address?): &FlowMeiumContract.Post?{ 
			if self.posts[postID] != nil{ 
				let ref: &FlowMeiumContract.Post = (&self.posts[postID!] as &FlowMeiumContract.Post?)!
				if ref.author == address || ref.price == 0.0{ 
					return ref
				}
			}
			return nil
		}
	}
	
	// create a new collection
	access(all)
	fun createEmptyCollection(address: Address): @Collection{ 
		emit FlowMeiumUserCreated(address: address)
		return <-create Collection()
	}
	
	init(){ 
		// assign the storage path to /storage/PostCollection
		self.PostCollectionStoragePath = /storage/PostCollection
		self.PostCollectionPublicPath = /public/PostCollection
		// save the empty collection to the storage path
		//self.account.save(<-self.createEmptyCollection(address: self.account.address), to: self.PostCollectionStoragePath)
		// publish a reference to the Collection in storage
		var capability_1 =
			self.account.capabilities.storage.issue<&{CollectionPublic}>(
				self.PostCollectionStoragePath
			)
		self.account.capabilities.publish(capability_1, at: self.PostCollectionPublicPath)
	}
}
