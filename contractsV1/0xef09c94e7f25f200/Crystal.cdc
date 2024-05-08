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
	event CrystalMinted(id: UInt64)
	
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
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64){ 
			self.id = initID
			
			// Increase the total supply counter
			Crystal.totalSupply = Crystal.totalSupply + 1 as UInt64
			emit CrystalMinted(id: self.id)
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
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
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
	
	// A special authorization resource with administrative functions
	access(all)
	resource Admin{ 
		// Mints a new NFT with a new ID
		access(all)
		fun mintNFT(recipient: &{Crystal.CrystalCollectionPublic}, clipID: UInt32){ 
			// Creates a new NFT with provided arguments
			var newNFT <- create NFT(initID: Crystal.totalSupply)
			
			// Deposits it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
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
	
	access(all)
	fun checkCanMerge(shards: [&Shard.NFT]): Bool{ 
		pre{ 
			shards.length > 0:
				"No Shards supplied"
		}
		
		// Make sure the sequence of each Shard matches
		let initialClip = Shard.getClip(clipID: shards[0].clipID)!
		let initialMoment = Shard.getMoment(momentID: initialClip.momentID)!
		var sequenceLength = initialMoment.splits
		for shard in shards{ 
			let clip = Shard.getClip(clipID: shards[0].clipID)!
			let moment = Shard.getMoment(momentID: clip.momentID)!
		}
		return false
	}
	
	// Merge multiple Shard NFTs to receive a Crystal NFT
	access(all)
	fun merge(shards: [&Shard.NFT]): @NFT?{ 
		// Make sure the sequence of each Shard matches
		Crystal.checkCanMerge(shards: shards)
		var purity = 0
		for shard in shards{} 
		//
		return <-create NFT(initID: Crystal.totalSupply)
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Collection resource and save it to storage
		self.account.storage.save(<-create Collection(), to: /storage/EternalCrystalCollection)
		
		// Create an Admin resource and save it to storage
		self.account.storage.save(<-create Admin(), to: /storage/EternalCrystalAdmin)
		
		// Create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&{Crystal.CrystalCollectionPublic}>(/storage/EternalCrystalCollection)
		self.account.capabilities.publish(capability_1, at: /public/EternalCrystalCollection)
		emit ContractInitialized()
	}
}
