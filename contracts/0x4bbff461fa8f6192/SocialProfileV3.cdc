// TODOs
// * check events have enough information to be useful
// * add FLOW balance checking
// * Refactor Post to a simpler set of attributes, and put Newsfeed fields in a metadata field
//      add pub let metadata: {String: [AnyStruct{FantastecSwapDataProperties.MetadataElement}]}
/*
TODO
    Use MetadataElement for all metadata properties [done]
    Reduce Post so that NewPost items are in metadata [done]
    Make Comment a resource, or have a nextCommentId on the post
    Add liker's address to commentLikes
    Should there be a limit to the number of comments? as Address will get more and more
    Should there be a limit to the number of likes? as Address will get more and more

    Check Events parameters are sufficient

    PostDetails to PostStruct, and use the same structure as with Post

*/

import FantastecSwapDataProperties from "./FantastecSwapDataProperties.cdc"

pub contract SocialProfileV3 {

    pub event PostCreated           (owner: Address, postId: UInt64)
    pub event PostDestroyed         (owner: Address, postId: UInt64)
    pub event NewsFeedPostCreated   (owner: Address, postId: UInt64)
    pub event PostLiked             (owner: Address, postId: UInt64, liker: Address)
    pub event PostUnliked           (owner: Address, postId: UInt64, liker: Address)
    pub event CommentCreated        (owner: Address, postId: UInt64, commenter: Address, commentId: UInt64)
    pub event CommentDestroyed      (owner: Address, postId: UInt64, commenter: Address, commentId: UInt64)
    pub event CommentLiked          (owner: Address, postId: UInt64, commentId: UInt64, liker: Address)
    pub event CommentUnliked        (owner: Address, postId: UInt64, commentId: UInt64, liker: Address)

    pub event ProfileFollowed       (owner: Address, follower: Address)
    pub event ProfileUnfollowed     (owner: Address, follower: Address)
    pub event ProfileUpdated        (owner: Address, field: String)

    pub event Installed             (owner: Address)
    pub event Destroyed             (owner: Address)

    pub let SocialProfileStoragePath: StoragePath
    pub let SocialProfilePublicPath: PublicPath

//    access(contract) let maxCommentsPerPost: UInt64
//    access(contract) let maxPostsPerProfile: UInt64
//    access(contract) let maxFollowingPerProfile: UInt64
    access(contract) var nextCommentId: UInt64

    pub struct PostDetails {
        pub let id: UInt64
        pub let author: Address // If we don't add author here, can it be inferred in some way on chain? perhaps by event history?
        pub let content: String
        pub let image: FantastecSwapDataProperties.Media?
        pub let dateCreated: UFix64
        pub let likeCount: UInt
        pub let comments: {UInt64: Comment}
        pub var metadata: {String: [AnyStruct{FantastecSwapDataProperties.MetadataElement}]}
        // consider mirroring the minimal post and have the rest of the properties in metadata
        init(
            id: UInt64, 
            author: Address,
            content: String, 
            image: FantastecSwapDataProperties.Media?, 
            dateCreated: UFix64,
            likeCount: UInt,
            comments: {UInt64: Comment},
            metadata: {String: [AnyStruct{FantastecSwapDataProperties.MetadataElement}]}
            ) {
            self.id = id
            self.author = author
            self.image = image
            self.content = content
            self.dateCreated = dateCreated
            self.likeCount = likeCount
            self.comments = comments
            self.metadata = metadata
        }
    }

    pub struct Comment {
        pub let id: UInt64
        pub let author: Address
        pub let content: String
        pub let dateCreated: UFix64
        pub var likeCount: Int
        pub var metadata: {String: [AnyStruct{FantastecSwapDataProperties.MetadataElement}]}

        init(id: UInt64, author: Address, content: String) {
            let dateCreated = getCurrentBlock().timestamp
            self.id = id
            self.author = author
            self.content = content
            self.dateCreated = dateCreated
            self.likeCount = 0
            self.metadata = {}
        }
    
        access(contract) fun incrementLike() {
            self.likeCount = self.likeCount + 1
        }

        access(contract) fun decrementLike() {
            if self.likeCount == 0 {
                panic("Cannot unlike as likeCount already 0")
            }
            self.likeCount = self.likeCount - 1
        }
    }

    pub struct Profile {
        pub let avatar: String
        pub let username: String
        pub let name: String
        pub let bio: String
        pub let coverMedia: FantastecSwapDataProperties.Media?
        pub let following: {Address: Bool}
        pub let followers : Int
        pub var metadata: {String: [AnyStruct{FantastecSwapDataProperties.MetadataElement}]}
        init(
            avatar: String, 
            bio: String, 
            name: String, 
            username: String, 
            coverMedia: FantastecSwapDataProperties.Media?, 
            following: {Address: Bool}, 
            followers: Int,
            metadata: {String: [AnyStruct{FantastecSwapDataProperties.MetadataElement}]}
        ) {
            self.avatar = avatar
            self.bio = bio
            self.name = name
            self.username = username
            self.coverMedia = coverMedia
            self.following = following
            self.followers = followers
            self.metadata = metadata
        }
    }

    pub resource Post {
        pub let id: UInt64
        pub let author: Address
        pub let content: String
        pub let image: FantastecSwapDataProperties.Media?
        pub let dateCreated: UFix64
        pub var likeCount: Int // should this be access(contract)? Can someone else change this value?
        pub let comments: {UInt64: Comment}
        pub var metadata: {String: [AnyStruct{FantastecSwapDataProperties.MetadataElement}]} // should this be access(contract)? Can someone else change this value?

        init(content: String, author: Address, image: FantastecSwapDataProperties.Media?) {
            self.id = self.uuid
            self.image = image
            self.author = author
            self.content = content
            self.dateCreated = getCurrentBlock().timestamp
            self.likeCount = 0
            self.comments = {}
            self.metadata = {}
        }

        /* Post Likes */
        access(contract) fun incrementLike() {
            self.likeCount = self.likeCount + 1
        }

        access(contract) fun decrementLike() {
            if self.likeCount == 0 {
                panic("Cannot unlike as likeCount already 0")
            }
            self.likeCount = self.likeCount - 1
        }

        /* Comments */
        access(contract) fun getComment(_ commentId: UInt64): Comment? {
            let comment = self.comments[commentId]
            return comment
        }

       access(contract) fun addComment(comment: Comment) {
            let id = comment.id
            self.comments[id] = comment
        }

        access(contract) fun removeComment(comment: Comment) {
            let id = comment.id
            self.comments.remove(key: id)
        }
        
        /* Comment Likes */
        access(contract) fun likeComment(_ commentId: UInt64) {
            let comment = self.comments[commentId] ?? panic("Comment does not exist with that id")
            comment.incrementLike()
            self.comments[commentId] = comment
        }

        access(contract) fun unlikeComment(_ commentId: UInt64) {
            let comment = self.comments[commentId] ?? panic("Comment does not exist with that id")
            comment.decrementLike()
            self.comments[commentId] = comment
        }

        /* Metadata */
        access(contract) fun addMetadata(
        _ type: String,
        _ metadata: AnyStruct{FantastecSwapDataProperties.MetadataElement},
        ) {
            if (self.metadata[type] == nil) {
                self.metadata[type] = []
            }
            self.metadata[type] = FantastecSwapDataProperties.addToMetadata(type, self.metadata[type]!, metadata)
        }

        access(contract) fun removeMetadata(
        _ type: String,
        _ id: UInt64?,
        ) {
            if (self.metadata[type] == nil) {
                self.metadata[type] = []
            }
            self.metadata[type] = FantastecSwapDataProperties.removeFromMetadata(type, self.metadata[type]!, id)
        }        
    }

    pub resource interface SocialProfilePublic {
        pub fun borrowPost(_ id: UInt64): &Post?
        pub fun getPostIds(): [UInt64]
        pub fun getLikedPosts(): [UInt64]
        pub fun getAvatar(): String
        pub fun getBio(): String
        pub fun getCoverMedia(): FantastecSwapDataProperties.Media?
        pub fun getUsername(): String
        pub fun getName(): String
        pub fun getFollowing(): {Address:Bool}
        pub fun getFollowersCount(): Int
        pub fun getMetadata(): {String: [AnyStruct{FantastecSwapDataProperties.MetadataElement}]} // pub let metadata: {String: [AnyStruct{FantastecSwapDataProperties.MetadataElement}]}
        access(contract) fun incrementFollower() // care to explain why it's like this? by access(contract) in public interface?
        access(contract) fun decrementFollower() // this permits another SP to call someone else's SP, but (contract) permits only the contract to call it
    }

    pub resource interface SocialProfilePrivate {
        pub fun addMetadata(_ type: String, _ metadata: AnyStruct{FantastecSwapDataProperties.MetadataElement})
        pub fun createComment(theirAddress: Address, postId: UInt64, content: String)
        pub fun createPost(content: String, image: FantastecSwapDataProperties.Media?)
        pub fun createNewsFeedPost(content: String, title: String, publishedDate: UFix64, image: FantastecSwapDataProperties.Media?, buttonUrl: String, buttonText: String)
        pub fun deleteComment(theirAddress: Address, postId: UInt64, commentId: UInt64)
        pub fun follow(theirAddress: Address)
        pub fun likeComment(theirAddress: Address, postId: UInt64, commentId: UInt64)
        pub fun likePost(theirAddress: Address, id: UInt64)
        pub fun removeMetadata(_ type: String, _ id: UInt64?)
        pub fun removePost(_ id: UInt64)
        pub fun setAvatar(avatar: String)
        pub fun setBio(bio: String)
        pub fun setName(name: String)
        pub fun setUsername(username: String)
        pub fun setCoverMedia(media: FantastecSwapDataProperties.Media?)
        pub fun unfollow(theirAddress: Address)
        pub fun unlikeComment(theirAddress: Address, postId: UInt64, commentId: UInt64)
        pub fun unlikePost(theirAddress: Address, id: UInt64)
    }

    pub resource SocialProfile: SocialProfilePrivate, SocialProfilePublic {
        access(self) var posts: @{UInt64: Post}
        access(self) var likedPosts: {UInt64:Bool}
        access(self) var likedComments: {UInt64: Bool}
        access(self) var avatar: String
        access(self) var bio: String
        access(self) var name: String
        access(self) var username: String
        access(self) var coverMedia: FantastecSwapDataProperties.Media?
        access(self) var followers: Int
        access(self) var following: {Address: Bool}
        access(self) var metadata: {String: [AnyStruct{FantastecSwapDataProperties.MetadataElement}]}

        /* Profile Getters */
        pub fun getAvatar(): String {
            return self.avatar
        }
        pub fun getBio(): String {
            return self.bio
        }
        pub fun getMetadata(): {String: [AnyStruct{FantastecSwapDataProperties.MetadataElement}]} {
            return self.metadata
        }
        pub fun getCoverMedia(): FantastecSwapDataProperties.Media? {
            return self.coverMedia
        }
        pub fun getUsername(): String {
            return self.username
        }
        pub fun getName(): String {
            return self.name
        }

        /* Profile Setters */
        access(contract) fun emitUpdateEvent(_ field: String) {
            emit ProfileUpdated(owner: self.owner!.address, field: field)
        }
        pub fun setAvatar(avatar: String) {
            self.avatar = avatar
            self.emitUpdateEvent("avatar")
        }
        pub fun setBio(bio: String) {
            self.bio = bio
            self.emitUpdateEvent("bio")
        }
        pub fun setUsername(username: String) {
            self.username = username
            self.emitUpdateEvent("username")
        }
        pub fun setCoverMedia(media: FantastecSwapDataProperties.Media?) {
            self.coverMedia = media
            self.emitUpdateEvent("coverMedia")
        }
        pub fun setName(name: String) {
            self.name = name
            self.emitUpdateEvent("name")
        }

        /* Follow */
        pub fun getFollowing(): {Address:Bool} {
            return self.following
        }
        pub fun getFollowersCount(): Int {
            return self.followers
        }
        pub fun follow(theirAddress: Address) {
            if self.following[theirAddress] == true  {
                panic("You already follow this profile")
            }

            if self.owner!.address == theirAddress {
                panic("You cannot follow your own profile")
            }
            
            let socialProfileRef = getAccount(theirAddress).getCapability<&SocialProfileV3.SocialProfile{SocialProfileV3.SocialProfilePublic}>(SocialProfileV3.SocialProfilePublicPath).borrow()!
            let theirAccount = socialProfileRef.incrementFollower()
            
            self.following[theirAddress] = true
            emit ProfileFollowed(owner: self.owner!.address, follower: theirAddress)
        }
        pub fun unfollow(theirAddress: Address) {
            if self.following[theirAddress] == nil {
                panic("You can not unfollow as you do not follow profile")
            } 
            let socialProfileRef = getAccount(theirAddress).getCapability<&SocialProfileV3.SocialProfile{SocialProfileV3.SocialProfilePublic}>(SocialProfileV3.SocialProfilePublicPath).borrow()!
            let theirAccount = socialProfileRef.decrementFollower()

            self.following.remove(key: theirAddress)
            emit ProfileUnfollowed(owner: self.owner!.address, follower: theirAddress)
        }

        /* Posts */
        pub fun createPost(content: String, image: FantastecSwapDataProperties.Media?) {
            let post <- create Post(
                content: content,
                author: self.owner!.address,
                image: image
            )
            emit PostCreated(owner: self.owner!.address, postId: post.id)
            self.posts[post.id] <-! post
        }
        pub fun createNewsFeedPost(content: String, title: String, publishedDate: UFix64, image: FantastecSwapDataProperties.Media?, buttonUrl: String, buttonText: String) {
            let post <- create Post(
                content: content,
                author: self.owner!.address,
                image: image
            )
            let metadataItemId: UInt64 = 1
            let metadata = FantastecSwapDataProperties.NewsFeed(metadataItemId, title, publishedDate, buttonUrl, buttonText)
            post.addMetadata("NewsFeed", metadata)
            emit NewsFeedPostCreated(owner: self.owner!.address, postId: post.id)
            let oldPost <- self.posts[post.id] <-! post
            destroy oldPost
        }
        pub fun borrowPost(_ id: UInt64): &Post? {
            return (&self.posts[id] as &Post?)
        }
        pub fun removePost(_ id: UInt64) {
            let post <- self.posts.remove(key: id) ?? panic("Post with that id does not exist")
            emit PostDestroyed(owner: self.owner!.address, postId: post.id)
            destroy post
        }
        pub fun likePost(theirAddress: Address, id: UInt64) {
            if self.likedPosts[id] == true {
                panic("You already liked this post")
            }
            let socialProfileRef = getAccount(theirAddress).getCapability<&SocialProfileV3.SocialProfile{SocialProfileV3.SocialProfilePublic}>(SocialProfileV3.SocialProfilePublicPath).borrow()!
            let theirPost = socialProfileRef.borrowPost(id) ?? panic("Post does not exist with that id")
            theirPost.incrementLike()
            self.likedPosts[id] = true
            emit PostLiked(owner: theirAddress, postId: id, liker: self.owner!.address)
        }
        pub fun unlikePost(theirAddress: Address, id: UInt64) {
            if self.likedPosts[id] == false ||  self.likedPosts[id] == nil {
                panic("Post cannot be unliked as it was not previously liked")
            }
            let socialProfileRef = getAccount(theirAddress).getCapability<&SocialProfileV3.SocialProfile{SocialProfileV3.SocialProfilePublic}>(SocialProfileV3.SocialProfilePublicPath).borrow()!
            let theirPost = socialProfileRef.borrowPost(id) ?? panic("Post does not exist with that id")
            theirPost.decrementLike()
            self.likedPosts.remove(key:id)
            emit PostUnliked(owner: theirAddress, postId: id, liker: self.owner!.address)
        }
        pub fun getLikedPosts(): [UInt64] {
            return self.likedPosts.keys
        }
        pub fun getPostIds(): [UInt64] {
            return self.posts.keys
        } 

        /* Comments */
        pub fun createComment(theirAddress: Address, postId: UInt64, content: String) {
            let socialProfileRef = getAccount(theirAddress).getCapability<&SocialProfileV3.SocialProfile{SocialProfileV3.SocialProfilePublic}>(SocialProfileV3.SocialProfilePublicPath).borrow()!
            let theirPost = socialProfileRef.borrowPost(postId) ?? panic("Post does not exist with that id")

            let commentId = SocialProfileV3.nextCommentId
            SocialProfileV3.nextCommentId = SocialProfileV3.nextCommentId + 1

            let comment = Comment(id: commentId, author: self.owner!.address, content: content)
            theirPost.addComment(comment: comment)

            emit CommentCreated(owner: theirAddress, postId: theirPost.id, commenter: self.owner!.address, commentId: commentId)
        }

        pub fun deleteComment(theirAddress: Address, postId: UInt64, commentId: UInt64){
            let socialProfileRef = getAccount(theirAddress).getCapability<&SocialProfileV3.SocialProfile{SocialProfileV3.SocialProfilePublic}>(SocialProfileV3.SocialProfilePublicPath).borrow()!
            let theirPost = socialProfileRef.borrowPost(postId) ?? panic("Post does not exist with that id")
            let _comment: Comment? = theirPost.getComment(commentId)
            // check comment exists
            if _comment == nil {
                log("comment not found")
                return 
            }
            let comment: Comment = _comment!
            if comment.author != self.owner!.address {
                panic("Comment was not created by you")
            }
            theirPost.removeComment(comment: comment)
            emit CommentDestroyed(owner: theirAddress, postId: theirPost.id, commenter: self.owner!.address, commentId: commentId)
        }

        pub fun likeComment(theirAddress: Address, postId: UInt64, commentId: UInt64) {
            if self.likedComments[commentId] == true {
                panic("You already liked this comment")
            }
            let socialProfileRef = getAccount(theirAddress).getCapability<&SocialProfileV3.SocialProfile{SocialProfileV3.SocialProfilePublic}>(SocialProfileV3.SocialProfilePublicPath).borrow()!
            let theirPost: &Post = socialProfileRef.borrowPost(postId) ?? panic("Post does not exist with that id")
            // Call the method to like the comment within the post
            theirPost.likeComment(commentId)
            self.likedComments.insert(key: commentId, true)
            emit CommentLiked(owner: theirAddress, postId: postId, commentId: commentId, liker: self.owner!.address)
        }

        pub fun unlikeComment(theirAddress: Address, postId: UInt64, commentId: UInt64) {
             if self.likedComments[commentId] == nil {
                panic("You havent liked this comment so you can not unlike")
            }
            let socialProfileRef = getAccount(theirAddress).getCapability<&SocialProfileV3.SocialProfile{SocialProfileV3.SocialProfilePublic}>(SocialProfileV3.SocialProfilePublicPath).borrow()!
            let theirPost = socialProfileRef.borrowPost(postId) ?? panic("Post does not exist with that id")
            theirPost.unlikeComment(commentId)
            self.likedComments.remove(key: commentId)
            emit CommentUnliked(owner: theirAddress, postId: postId, commentId: commentId, liker: self.owner!.address)
        }
  
        /* Internal Contract Mutators */
        access(contract) fun incrementFollower() {
           self.followers = self.followers + 1 
        }

        access(contract) fun decrementFollower() {
            if self.followers > 0 {
                self.followers = self.followers - 1
            } else {
                panic("Follower count cannot be less than zero")
            }
        }

        /* Metadata */
        pub fun addMetadata(
        _ type: String,
        _ metadata: AnyStruct{FantastecSwapDataProperties.MetadataElement},
        ) {
            if (self.metadata[type] == nil) {
                self.metadata[type] = []
            }
            self.metadata[type] = FantastecSwapDataProperties.addToMetadata(type, self.metadata[type]!, metadata)
            self.emitUpdateEvent("metadata add - ".concat(type))
        }

        pub fun removeMetadata(
        _ type: String,
        _ id: UInt64?,
        ) {
            if (self.metadata[type] == nil) {
                self.metadata[type] = []
            }
            self.metadata[type] = FantastecSwapDataProperties.removeFromMetadata(type, self.metadata[type]!, id)
            self.emitUpdateEvent("metadata remove - ".concat(type))
        }

        destroy() {
            let posts <- self.posts
            destroy posts
        }
        
        pub fun emitInstalledEvent() {
            emit Installed(owner: self.owner!.address)
        }

        pub fun emitDestroyedEvent(_ address: Address) {
            emit Destroyed(owner: address)
        }

        init() {
            self.posts <- {}
            self.likedPosts = {}
            self.likedComments = {}
            self.avatar = ""
            self.bio = ""
            self.followers = 0
            self.following = {}
            self.metadata = {}
            self.username = ""
            self.name = ""
            self.coverMedia = nil
        }
    }

    pub fun createSocialProfile(): @SocialProfile {
        return <-create SocialProfile()
    }

    init() {
        self.SocialProfileStoragePath = /storage/SocialProfile 
        self.SocialProfilePublicPath = /public/SocialProfile
        self.nextCommentId = 1
    }
}
