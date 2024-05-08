
pub contract FlowMeiumContract {
    // Events
    pub event FlowMeiumUserCreated(address: Address)
    pub event FlowMeiumPostCreated(post: PartialPost)
    pub event FlowMeiumPostDeleted(post: PartialPost)
    pub event FlowMeiumPostUpdated(post: PartialPost)

    // Declare a Path constant so we don't need to harcode in tx
    pub let PostCollectionStoragePath: StoragePath
    pub let PostCollectionPublicPath: PublicPath

    pub struct Author {
        pub let author: Address
        pub let royalty: UFix64

        init(_author: Address, _royalty: UFix64) {
            self.author = _author
            self.royalty = _royalty
        }
    }

    // Declare the Post resource type
    pub resource Post {
        // The unique ID that differentiates each Post
        pub let id: UInt64
        pub(set) var title: String
        pub(set) var description: String
        pub(set) var author:  Address
        pub(set) var image: String
        pub(set) var price: UFix64
        pub(set) var data: String 
        pub(set) var metadata: {String: String}
        pub var createDate: UFix64

        // Initialize both fields in the init function
        init(_title: String, _description: String, _author: Address, _image: String, _price:UFix64, _data: String, _metadata: {String: String}) {
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
    pub struct PartialPost {
        pub let id: UInt64?
        pub let title: String?
        pub let description: String?
        pub let author: Address?
        pub let image: String?
        pub let price: UFix64?
        pub let metadata: {String: String}?
        pub let createDate: UFix64?
        pub let data: String?

        init(_id: UInt64?, _title: String?, _description: String?, _author:Address?, _image: String?, _price: UFix64?, _createDate: UFix64?, _metadata: {String: String}?, _data: String?) {
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
    pub fun createPost(_title: String, _description: String, _author: Address, _image: String, _price:UFix64, _data: String, _metadata: {String: String}): @Post {
        return <-create Post(_title: _title, _description: _description, _author: _author, _image: _image, _price: _price, _data: _data, _metadata: _metadata)
    }

    pub resource interface CollectionPublic {
        pub fun borrowPartialPost(postID: UInt64): PartialPost?
        pub fun getAllPostIDs(): [UInt64]
        pub fun borrowPost(postID: UInt64, address: Address?): &Post? 
    }

    pub resource Collection: CollectionPublic {
        access(self) var posts: @{UInt64: Post}

        pub fun updatePost(post: PartialPost) {
            if(post.id != nil && self.posts.containsKey(post.id!)){
                let ref: &FlowMeiumContract.Post = (&self.posts[post.id!] as &FlowMeiumContract.Post?)!
                ref.title = post.title ?? ref.title
                ref.description = post.description ?? ref.description
                ref.image = post.image ?? ref.image
                ref.data = post.data ?? ref.data
                ref.price = post.price ?? ref.price
                ref.metadata = post.metadata ?? ref.metadata              

                emit FlowMeiumPostUpdated(post: post)
            }
        }

        pub fun savePost(post: @Post) {
            // If there were to be a value at that key, 
            // it would fail/revert. 
            let evetData : PartialPost = PartialPost(_id: post.id, 
                                                    _title: post.title, 
                                                    _description: post.description, 
                                                    _author: post.author, 
                                                    _image: post.image, 
                                                    _price: post.price, 
                                                    _createDate: post.createDate, 
                                                    _metadata: post.metadata, 
                                                    _data: nil) 
            emit FlowMeiumPostCreated(post: evetData)
            self.posts[post.id] <-! post
        }
        
        init() {
            self.posts <- {}
        }

        destroy() {
            // when the Colletion resource is destroyed, 
            // we need to explicitly destroy the tweets too.
            destroy self.posts
        }
    
        pub fun borrowPartialPost(postID: UInt64): FlowMeiumContract.PartialPost? {
            if self.posts[postID] != nil {
                let ref: &FlowMeiumContract.Post = (&self.posts[postID!] as &FlowMeiumContract.Post?)!
                let postData : PartialPost = PartialPost(_id: ref.id, 
                                                        _title: ref.title, 
                                                        _description: ref.description, 
                                                        _author: ref.author, 
                                                        _image: ref.image, 
                                                        _price: ref.price, 
                                                        _createDate: ref.createDate, 
                                                        _metadata: ref.metadata, 
                                                        _data: nil) 
                return postData
            }
            return nil
        }

        pub fun getAllPostIDs(): [UInt64] {
            return self.posts.keys
        }
    
        pub fun borrowPost(postID: UInt64, address: Address?): &FlowMeiumContract.Post? {
            if self.posts[postID] != nil {
                let ref: &FlowMeiumContract.Post = (&self.posts[postID!] as &FlowMeiumContract.Post?)!
                if(ref.author == address || ref.price == 0.0) { return ref }
            }
            return  nil
        }
}   

    // create a new collection
    pub fun createEmptyCollection(address: Address): @Collection {
        emit FlowMeiumUserCreated(address: address)
        return <- create Collection()
    }

    init() {
        // assign the storage path to /storage/PostCollection
        self.PostCollectionStoragePath = /storage/PostCollection
        self.PostCollectionPublicPath = /public/PostCollection
        // save the empty collection to the storage path
        //self.account.save(<-self.createEmptyCollection(address: self.account.address), to: self.PostCollectionStoragePath)
        // publish a reference to the Collection in storage
        self.account.link<&{CollectionPublic}>(self.PostCollectionPublicPath, target: self.PostCollectionStoragePath)   
    }
}
 