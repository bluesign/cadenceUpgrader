import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import Shard from "../0x82b54037a8f180cf/Shard.cdc"

// eternal.gg
access(all)
contract Crystal: NonFungibleToken{ 
	// Total amount of Crystals that have been minted
	access(all)
	var totalSupply: UInt64
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event CrystalMinted(id: UInt64, shardIDs: [UInt64], clipIDs: [UInt32], momentIDs: [UInt32], purity: Int)
	
	access(all)
	struct ShardData{ 
		// The unique ID of the Moment
		access(all)
		let id: UInt64
		
		// The influencer that the Moment belongs to
		access(all)
		let clip: Shard.Clip
		
		// The amount of Clips the Moments splits into
		access(all)
		let moment: Shard.Moment
		
		view init(shard: &Shard.NFT){ 
			self.id = shard.id
			self.clip = Shard.getClip(clipID: shard.clipID)!
			self.moment = Shard.getMoment(momentID: self.clip.momentID)!
		}
	}
	
	// Interface for a Collection
	access(all)
	resource interface CrystalCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowCrystalNFT(id: UInt64): &Crystal.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Crystal reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// NFT Representng a Crystal
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// Identifier of NFT
		access(all)
		let id: UInt64
		
		// Purity of the Crystal
		access(all)
		let purity: Int
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, shards: [&Shard.NFT], purity: Int){ 
			self.id = initID
			self.purity = purity
			
			// Increase the total supply counter
			Crystal.totalSupply = Crystal.totalSupply + 1 as UInt64
			
			// Gets shard data for use in event emit
			var shardIDs: [UInt64] = []
			var clipIDs: [UInt32] = []
			var momentIDs: [UInt32] = []
			for shard in shards{ 
				let shardData = Crystal.ShardData(shard: shard)
				shardIDs.append(shardData.id)
				clipIDs.append(shardData.clip.id)
				momentIDs.append(shardData.moment.id)
			}
			emit CrystalMinted(id: self.id, shardIDs: shardIDs, clipIDs: clipIDs, momentIDs: momentIDs, purity: self.purity)
		}
	}
	
	access(all)
	resource Collection: CrystalCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// A resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// Removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("The Crystal NFT does not exist")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// Takes a NFT and adds it to the collections dictionary and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Crystal.NFT
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
		
		// Gets a reference to a basic NFT in the collection
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// Gets a reference to the Crystal NFT for metadata and such
		access(all)
		fun borrowCrystalNFT(id: UInt64): &Crystal.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &Crystal.NFT
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
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// Public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Provided a list of IDs, returns the Shard NFT references
	access(all)
	fun getShardsByIDs(owner: Address, ids: [UInt64]): [&Shard.NFT]{ 
		pre{ 
			ids.length > 0:
				"No Shard IDs supplied"
		}
		
		// Access the collection of the owner
		let collection = getAccount(owner).capabilities.get<&{Shard.ShardCollectionPublic}>(/public/EternalShardCollection).borrow<&{Shard.ShardCollectionPublic}>() ?? panic("Could not get receiver reference to the Shard Collection")
		
		// Create a list of Shards for every ID supplied
		let shards: [&Shard.NFT] = []
		for id in ids{ 
			let shard = collection.borrowShardNFT(id: id)!
			shards.append(shard)
		}
		return shards
	}
	
	// Provided a Shard, returns the splits property of the Shard
	access(all)
	view fun getShardSplits(shard: &Shard.NFT): UInt8{ 
		let shardData = Crystal.ShardData(shard: shard)
		var splits = shardData.moment.splits
		return splits
	}
	
	// Provided a list of Shard references, returns true if they can merge, false if not
	access(all)
	view fun checkCanMerge(shards: [&Shard.NFT]): Bool{ 
		pre{ 
			shards.length > 0:
				"No Shards supplied"
		}
		let uniques: [&Shard.NFT] = []
		let initialSplits = Crystal.getShardSplits(shard: shards[0])
		for shard in shards{ 
			let splits = Crystal.getShardSplits(shard: shard)
			if splits != initialSplits || UInt8(shards.length) != splits || uniques.contains(shard){ 
				return false
			}
			uniques.append(shard)
		}
		return true
	}
	
	// Provided a Shard reference, returns the calculated purity of the Shard
	access(all)
	fun getPurity(shards: [&Shard.NFT]): Int{ 
		pre{ 
			// Make sure the sequence of each Shard matches
			Crystal.checkCanMerge(shards: shards):
				"Shards must all have the same sequence length"
		}
		var purity: Int = 10 * shards.length * shards.length + 10
		var uniqueInfluencers: [String] = []
		var uniqueMoments: [UInt32] = []
		var uniqueClips: [UInt32] = []
		var uniqueSequences: [UInt8] = []
		for shard in shards{ 
			let shardData = Crystal.ShardData(shard: shard)
			if !uniqueInfluencers.contains(shardData.moment.influencerID){ 
				uniqueInfluencers.append(shardData.moment.influencerID)
				uniqueMoments.append(shardData.moment.id)
				uniqueClips.append(shardData.clip.id)
			} else if !uniqueMoments.contains(shardData.moment.id){ 
				uniqueMoments.append(shardData.moment.id)
				uniqueClips.append(shardData.clip.id)
			} else if !uniqueClips.contains(shardData.clip.id){ 
				uniqueClips.append(shardData.clip.id)
				uniqueSequences.append(shardData.clip.sequence)
			}
		}
		purity = purity - uniqueInfluencers.length * 10
		purity = purity - uniqueMoments.length * 10
		purity = purity - uniqueClips.length * 10
		purity = purity + uniqueSequences.length * 20
		if uniqueSequences.length >= 1{ 
			purity = purity + 10
		}
		if shards.length - uniqueClips.length >= shards.length - 1{ 
			purity = purity + 10
		}
		return purity
	}
	
	// Merge multiple Shard NFTs to receive a Crystal NFT
	access(all)
	fun merge(shards: @[Shard.NFT]): @Crystal.NFT?{ 
		// Iterate resources to get an array of Shard references
		var i = 0
		var shardReferences: [&Shard.NFT] = []
		while i < shards.length{ 
			let shard: &Shard.NFT = &shards[i] as &Shard.NFT
			shardReferences.append(shard)
			i = i + 1
		}
		
		// Get the purity
		let purity: Int = Crystal.getPurity(shards: shardReferences)
		
		// Create a new Crystal with calculated purity and destroy the Shards
		let crystal: @Crystal.NFT <- create NFT(initID: Crystal.totalSupply, shards: shardReferences, purity: purity)
		destroy shards
		return <-crystal
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 1
		
		// Create a Collection resource and save it to storage
		self.account.storage.save(<-create Collection(), to: /storage/EternalCrystalCollection)
		
		// Create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&{Crystal.CrystalCollectionPublic}>(/storage/EternalCrystalCollection)
		self.account.capabilities.publish(capability_1, at: /public/EternalCrystalCollection)
		emit ContractInitialized()
	}
}
