// import NonFungibleToken from 0x631e88ae7f1d7c20 // testnet
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc" // mainnet


// eternal.gg
access(all)
contract Shard: NonFungibleToken{ 
	// Total amount of Shards that have been minted
	access(all)
	var totalSupply: UInt64
	
	// Total amount of Clips that have been created
	access(all)
	var totalClips: UInt32
	
	// Total amount of Moments that have been created
	access(all)
	var totalMoments: UInt32
	
	// Variable size dictionary of Moment structs
	access(self)
	var moments:{ UInt32: Moment}
	
	// Variable size dictionary of Clip structs
	access(self)
	var clips:{ UInt32: Clip}
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event MomentCreated(id: UInt32, influencerID: String, splits: UInt8, metadata:{ String: String})
	
	access(all)
	event ClipCreated(id: UInt32, momentID: UInt32, sequence: UInt8, metadata:{ String: String})
	
	access(all)
	event ShardMinted(id: UInt64, clipID: UInt32)
	
	access(all)
	struct Moment{ 
		// The unique ID of the Moment
		access(all)
		let id: UInt32
		
		// The influencer that the Moment belongs to
		access(all)
		let influencerID: String
		
		// The amount of Clips the Moments splits into
		access(all)
		let splits: UInt8
		
		// The metadata for a Moment
		access(contract)
		let metadata:{ String: String}
		
		init(influencerID: String, splits: UInt8, metadata:{ String: String}){ 
			pre{ 
				metadata.length > 0:
					"Metadata cannot be empty"
			}
			self.id = Shard.totalMoments
			self.influencerID = influencerID
			self.splits = splits
			self.metadata = metadata
			
			// Increment the ID so that it isn't used again
			Shard.totalMoments = Shard.totalMoments + 1 as UInt32
			
			// Broadcast the new Moment's data
			emit MomentCreated(id: self.id, influencerID: self.influencerID, splits: self.splits, metadata: self.metadata)
		}
	}
	
	access(all)
	struct Clip{ 
		// The unique ID of the Clip
		access(all)
		let id: UInt32
		
		// The moment the Clip belongs to
		access(all)
		let momentID: UInt32
		
		// The sequence of the provided clip
		access(all)
		let sequence: UInt8
		
		// Stores all the metadata about the Clip as a string mapping
		access(contract)
		let metadata:{ String: String}
		
		init(momentID: UInt32, sequence: UInt8, metadata:{ String: String}){ 
			pre{ 
				Shard.moments.containsKey(momentID):
					"Provided Moment ID does not exist"
				(Shard.moments[momentID]!).splits > sequence:
					"The Sequence must be within the Moment's splits limit"
				metadata.length > 0:
					"Metadata cannot be empty"
			}
			self.id = Shard.totalClips
			self.momentID = momentID
			self.sequence = sequence
			self.metadata = metadata
			
			// Increment the ID so that it isn't used again
			Shard.totalClips = Shard.totalClips + 1 as UInt32
			
			// Broadcast the new Clip's data
			emit ClipCreated(id: self.id, momentID: self.momentID, sequence: self.sequence, metadata: self.metadata)
		}
	}
	
	// Add your own Collection interface so you can use it later
	access(all)
	resource interface ShardCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowShardNFT(id: UInt64): &Shard.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Shard reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// Identifier of NFT
		access(all)
		let id: UInt64
		
		// Clip ID corresponding to the Shard
		access(all)
		let clipID: UInt32
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, clipID: UInt32){ 
			pre{ 
				Shard.clips.containsKey(clipID):
					"Clip ID does not exist"
			}
			self.id = initID
			self.clipID = clipID
			
			// Increase the total supply counter
			Shard.totalSupply = Shard.totalSupply + 1 as UInt64
			emit ShardMinted(id: self.id, clipID: self.clipID)
		}
	}
	
	access(all)
	resource Collection: ShardCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// A resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// Removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// Takes a NFT and adds it to the collections dictionary and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Shard.NFT
			let id: UInt64 = token.id
			
			// Add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// Returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// Gets a reference to the Shard NFT for metadata and such
		access(all)
		fun borrowShardNFT(id: UInt64): &Shard.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Shard.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// A special authorization resource with administrative functions
	access(all)
	resource Admin{ 
		// Creates a new Moment and returns the ID
		access(all)
		fun createMoment(influencerID: String, splits: UInt8, metadata:{ String: String}): UInt32{ 
			var newMoment = Moment(influencerID: influencerID, splits: splits, metadata: metadata)
			let newID = newMoment.id
			
			// Store it in the contract storage
			Shard.moments[newID] = newMoment
			return newID
		}
		
		// Creates a new Clip struct and returns the ID
		access(all)
		fun createClip(momentID: UInt32, sequence: UInt8, metadata:{ String: String}): UInt32{ 
			// Create the new Clip
			var newClip = Clip(momentID: momentID, sequence: sequence, metadata: metadata)
			var newID = newClip.id
			
			// Store it in the contract storage
			Shard.clips[newID] = newClip
			return newID
		}
		
		// Mints a new NFT with a new ID
		access(all)
		fun mintNFT(recipient: &{Shard.ShardCollectionPublic}, clipID: UInt32){ 
			// Creates a new NFT with provided arguments
			var newNFT <- create NFT(initID: Shard.totalSupply, clipID: clipID)
			
			// Deposits it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
		}
		
		access(all)
		fun batchMintNFT(recipient: &{Shard.ShardCollectionPublic}, clipID: UInt32, quantity: UInt64){ 
			var i: UInt64 = 0
			while i < quantity{ 
				self.mintNFT(recipient: recipient, clipID: clipID)
				i = i + 1 as UInt64
			}
		}
		
		// Creates a new Admin resource to be given to an account
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	// Public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Publicly get a Moment for a given Moment ID
	access(all)
	fun getMoment(momentID: UInt32): Moment?{ 
		return self.moments[momentID]
	}
	
	// Publicly get a Clip for a given Clip ID
	access(all)
	fun getClip(clipID: UInt32): Clip?{ 
		return self.clips[clipID]
	}
	
	// Publicly get metadata for a given Moment ID
	access(all)
	fun getMomentMetadata(momentID: UInt32):{ String: String}?{ 
		return self.moments[momentID]?.metadata
	}
	
	// Publicly get metadata for a given Clip ID
	access(all)
	fun getClipMetadata(clipID: UInt32):{ String: String}?{ 
		return self.clips[clipID]?.metadata
	}
	
	// Publicly get all Clips
	access(all)
	fun getAllClips(): [Shard.Clip]{ 
		return Shard.clips.values
	}
	
	init(){ 
		// Initialize the total supplies
		self.totalSupply = 0
		self.totalMoments = 0
		self.totalClips = 0
		
		// Initialize with an empty set of Moments
		self.moments ={} 
		
		// Initialize with an empty set of Clips
		self.clips ={} 
		
		// Create a Collection resource and save it to storage
		self.account.storage.save(<-create Collection(), to: /storage/EternalShardCollection)
		
		// Create an Admin resource and save it to storage
		self.account.storage.save(<-create Admin(), to: /storage/EternalShardAdmin)
		
		// Create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&{Shard.ShardCollectionPublic}>(/storage/EternalShardCollection)
		self.account.capabilities.publish(capability_1, at: /public/EternalShardCollection)
		emit ContractInitialized()
	}
}
