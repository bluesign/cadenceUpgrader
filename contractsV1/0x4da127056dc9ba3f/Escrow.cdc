/*
	Escrow Contract for managing NFTs in a Leaderboard Context.
	Holds NFTs in Escrow account awaiting transfer or burn.

	Authors:
		Corey Humeston: corey.humeston@dapperlabs.com
		Deewai Abdullahi: innocent.abdullahi@dapperlabs.com
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract Escrow{ 
	// Event emitted when a new leaderboard is created.
	access(all)
	event LeaderboardCreated(name: String, nftType: Type)
	
	// Event emitted when an NFT is deposited to a leaderboard.
	access(all)
	event EntryDeposited(leaderboardName: String, nftID: UInt64, owner: Address)
	
	// Event emitted when an NFT is returned to the original collection from a leaderboard.
	access(all)
	event EntryReturnedToCollection(leaderboardName: String, nftID: UInt64, owner: Address)
	
	// Event emitted when an NFT is burned from a leaderboard.
	access(all)
	event EntryBurned(leaderboardName: String, nftID: UInt64)
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	struct LeaderboardInfo{ 
		access(all)
		let name: String
		
		access(all)
		let nftType: Type
		
		access(all)
		let entriesLength: Int
		
		init(name: String, nftType: Type, entriesLength: Int){ 
			self.name = name
			self.nftType = nftType
			self.entriesLength = entriesLength
		}
	}
	
	// The resource representing a leaderboard.
	access(all)
	resource Leaderboard{ 
		access(all)
		var collection: @{NonFungibleToken.Collection}
		
		access(all)
		var entriesData:{ UInt64: LeaderboardEntry}
		
		access(all)
		let name: String
		
		access(all)
		let nftType: Type
		
		access(all)
		var entriesLength: Int
		
		access(all)
		var metadata:{ String: AnyStruct}
		
		// Adds an NFT entry to the leaderboard.
		access(all)
		fun addEntryToLeaderboard(
			nft: @{NonFungibleToken.NFT},
			ownerAddress: Address,
			metadata:{ 
				String: AnyStruct
			}
		){ 
			pre{ 
				nft.isInstance(self.nftType):
					"This NFT cannot be used for leaderboard. NFT is not of the correct type."
			}
			let nftID = nft.id
			
			// Create the entry and add it to the entries map
			let entry =
				LeaderboardEntry(nftID: nftID, ownerAddress: ownerAddress, metadata: metadata)
			self.entriesData[nftID] = entry
			self.collection.deposit(token: <-nft)
			
			// Increment entries length.
			self.entriesLength = self.entriesLength + 1
			emit EntryDeposited(leaderboardName: self.name, nftID: nftID, owner: ownerAddress)
		}
		
		// Withdraws an NFT entry from the leaderboard.
		access(contract)
		fun transferNftToCollection(
			nftID: UInt64,
			depositCap: Capability<&{NonFungibleToken.CollectionPublic}>
		){ 
			// Check to see if the entry exists.
			pre{ 
				self.entriesData[nftID] != nil:
					"Entry does not exist with this NFT ID"
				depositCap.address == (self.entriesData[nftID]!).ownerAddress:
					"Only the owner of the entry can withdraw it"
				depositCap.check():
					"Deposit capability is not valid"
			}
			self.entriesData.remove(key: nftID)!
			let token <- self.collection.withdraw(withdrawID: nftID)
			let receiverCollection =
				depositCap.borrow() as &{NonFungibleToken.CollectionPublic}?
				?? panic("Could not borrow the NFT receiver from the capability")
			(receiverCollection!).deposit(token: <-token)
			emit EntryReturnedToCollection(
				leaderboardName: self.name,
				nftID: nftID,
				owner: depositCap.address
			)
			
			// Decrement entries length.
			self.entriesLength = self.entriesLength - 1
		}
		
		// Burns an NFT entry from the leaderboard.
		access(contract)
		fun burn(nftID: UInt64){ 
			// Check to see if the entry exists.
			pre{ 
				self.entriesData[nftID] != nil:
					"Entry does not exist with this NFT ID"
			}
			self.entriesData.remove(key: nftID)!
			let token <- self.collection.withdraw(withdrawID: nftID)
			emit EntryBurned(leaderboardName: self.name, nftID: nftID)
			
			// Decrement entries length.
			self.entriesLength = self.entriesLength - 1
			destroy token
		}
		
		// Destructor for Leaderboard resource.
		init(name: String, nftType: Type, collection: @{NonFungibleToken.Collection}){ 
			self.name = name
			self.nftType = nftType
			self.collection <- collection
			self.entriesLength = 0
			self.metadata ={} 
			self.entriesData ={} 
		}
	}
	
	// The resource representing an NFT entry in a leaderboard.
	access(all)
	struct LeaderboardEntry{ 
		access(all)
		let nftID: UInt64
		
		access(all)
		let ownerAddress: Address
		
		access(all)
		var metadata:{ String: AnyStruct}
		
		init(nftID: UInt64, ownerAddress: Address, metadata:{ String: AnyStruct}){ 
			self.nftID = nftID
			self.ownerAddress = ownerAddress
			self.metadata = metadata
		}
	}
	
	// An interface containing the Collection function that gets leaderboards by name.
	access(all)
	resource interface ICollectionPublic{ 
		access(all)
		fun getLeaderboardInfo(name: String): LeaderboardInfo?
		
		access(all)
		fun addEntryToLeaderboard(
			nft: @{NonFungibleToken.NFT},
			leaderboardName: String,
			ownerAddress: Address,
			metadata:{ 
				String: AnyStruct
			}
		)
	}
	
	access(all)
	resource interface ICollectionPrivate{ 
		access(all)
		fun createLeaderboard(
			name: String,
			nftType: Type,
			collection: @{NonFungibleToken.Collection}
		)
		
		access(all)
		fun transferNftToCollection(
			leaderboardName: String,
			nftID: UInt64,
			depositCap: Capability<&{NonFungibleToken.CollectionPublic}>
		)
		
		access(all)
		fun burn(leaderboardName: String, nftID: UInt64)
	}
	
	// The resource representing a collection.
	access(all)
	resource Collection: ICollectionPublic, ICollectionPrivate{ 
		// A dictionary holding leaderboards.
		access(self)
		var leaderboards: @{String: Leaderboard}
		
		// Creates a new leaderboard and stores it.
		access(all)
		fun createLeaderboard(name: String, nftType: Type, collection: @{NonFungibleToken.Collection}){ 
			if self.leaderboards[name] != nil{ 
				panic("Leaderboard already exists with this name")
			}
			
			// Create a new leaderboard resource.
			let newLeaderboard <- create Leaderboard(name: name, nftType: nftType, collection: <-collection)
			
			// Store the leaderboard for future access.
			self.leaderboards[name] <-! newLeaderboard
			
			// Emit the event.
			emit LeaderboardCreated(name: name, nftType: nftType)
		}
		
		// Returns leaderboard info with the given name.
		access(all)
		fun getLeaderboardInfo(name: String): LeaderboardInfo?{ 
			let leaderboard = &self.leaderboards[name] as &Leaderboard?
			if leaderboard == nil{ 
				return nil
			}
			return LeaderboardInfo(name: (leaderboard!).name, nftType: (leaderboard!).nftType, entriesLength: (leaderboard!).entriesLength)
		}
		
		// Call addEntry.
		access(all)
		fun addEntryToLeaderboard(nft: @{NonFungibleToken.NFT}, leaderboardName: String, ownerAddress: Address, metadata:{ String: AnyStruct}){ 
			let leaderboard = &self.leaderboards[leaderboardName] as &Leaderboard?
			if leaderboard == nil{ 
				panic("Leaderboard does not exist with this name")
			}
			(leaderboard!).addEntryToLeaderboard(nft: <-nft, ownerAddress: ownerAddress, metadata: metadata)
		}
		
		// Calls transferNftToCollection.
		access(all)
		fun transferNftToCollection(leaderboardName: String, nftID: UInt64, depositCap: Capability<&{NonFungibleToken.CollectionPublic}>){ 
			let leaderboard = &self.leaderboards[leaderboardName] as &Leaderboard?
			if leaderboard == nil{ 
				panic("Leaderboard does not exist with this name")
			}
			(leaderboard!).transferNftToCollection(nftID: nftID, depositCap: depositCap)
		}
		
		// Calls burn.
		access(all)
		fun burn(leaderboardName: String, nftID: UInt64){ 
			let leaderboard = &self.leaderboards[leaderboardName] as &Leaderboard?
			if leaderboard == nil{ 
				panic("Leaderboard does not exist with this name")
			}
			(leaderboard!).burn(nftID: nftID)
		}
		
		// Destructor for Collection resource.
		init(){ 
			self.leaderboards <-{} 
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/EscrowLeaderboardCollection
		self.CollectionPrivatePath = /private/EscrowLeaderboardCollectionAccess
		self.CollectionPublicPath = /public/EscrowLeaderboardCollectionInfo
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPrivatePath)
		var capability_2 =
			self.account.capabilities.storage.issue<&Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: self.CollectionPublicPath)
	}
}
