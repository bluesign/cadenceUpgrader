/*
  Description: Central Smart Contract for FrontRow dapp

  This smart contract contains the core functionality for
  FrontRow, created by Choi Holdings

  The contract manages the data associated with blueprints
  that are used as templates for the FrontRow NFTs

  When a new Blueprint needs to be added to the records, an Admin creates
  a new Blueprint struct that is stored in the smart contract.

  Only the admin resource has the power to do all of the important actions
  in the smart contract such as manage blueprints and mint NFTs.

  The contract also defines a Collection resource. This is an object that
  every FrontRow NFT owner will store in their account to manage their
  NFT collection.

  The main FrontRow account will also have its own NFT collection
  it can use to hold its own FrontRow NFTs that have not been sold yet.

  Note: All state changing functions will panic if an invalid argument is
  provided or one of its pre-conditions or post conditions aren't met.
  Functions that don't modify state will simply return 0 or nil
  and those cases need to be handled by the caller.
*/

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract FrontRow: NonFungibleToken{ 
	
	// Fired once this contract is deployed
	access(all)
	event ContractInitialized()
	
	// Events for Collection-related actions
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Events for Blueprint
	access(all)
	event BlueprintPrinted(id: UInt32, maxQuantity: UInt32)
	
	access(all)
	event BlueprintDestroyed(id: UInt32)
	
	access(all)
	event BlueprintCancelled(id: UInt32)
	
	// Events for NFTs
	access(all)
	event Minted(id: UInt64, blueprintId: UInt32, serialNumber: UInt32)
	
	// Variable size dictionary of Blueprint structs
	access(self)
	var blueprints:{ UInt32: Blueprint}
	
	// Global counters for Blueprint and NFT IDs
	access(all)
	var nextBlueprintId: UInt32
	
	access(all)
	var totalSupply: UInt64
	
	// Storage paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// The struct that represents the NFT type or a template. When NFTs are minted
	// they abide by the following restrictions:
	//   - can't mint more NFTs than the defined maxQuantity
	//   - can't mint from a cancelled blueprint
	access(all)
	struct Blueprint{ 
		access(all)
		let id: UInt32
		
		access(all)
		let maxQuantity: UInt32
		
		access(all)
		let metadata:{ String: String}
		
		access(self)
		var cancelled: Bool
		
		access(self)
		var mintCount: UInt32
		
		access(self)
		var nfts:{ UInt32: UInt64} // Map of serial numbers to global NFT IDs
		
		
		// Initialize struct fields
		init(id: UInt32, maxQuantity: UInt32, metadata:{ String: String}){ 
			pre{ 
				id > 0:
					"Couldn't create blueprint: id is required."
				FrontRow.blueprints[FrontRow.nextBlueprintId] == nil:
					"Couldn't create blueprint: already exists."
				maxQuantity > 0:
					"Couldn't create blueprint: maxiumum quantity is required."
			}
			
			// Initialize struct fields
			self.id = id
			self.maxQuantity = maxQuantity
			self.metadata = metadata
			self.cancelled = false
			self.mintCount = 0
			self.nfts ={} 
		}
		
		// Check if blueprint is cancelled
		access(all)
		view fun isCancelled(): Bool{ 
			return self.cancelled
		}
		
		// Cancel a blueprint (no more NFTs can be printed fron it)
		// This operation is irreversible
		access(all)
		fun cancel(){ 
			if !self.cancelled{ 
				self.cancelled = true
			}
		}
		
		// Get mint count
		access(all)
		view fun getMintCount(): UInt32{ 
			return self.mintCount
		}
		
		// Set mint count
		access(all)
		fun setMintCount(_ mintCount: UInt32){ 
			self.mintCount = mintCount
		}
		
		// Set map entry of serial number to the new global NFT ID
		access(all)
		fun setNftId(_ serialNumber: UInt32, nftId: UInt64){ 
			self.nfts[serialNumber] = nftId
		}
		
		// Get the NFT ID corresponding to a serial number
		access(all)
		fun getNftId(_ serialNumber: UInt32): UInt64?{ 
			return self.nfts[serialNumber]
		}
	}
	
	// The resource that represents FrontRow NFT (based on a blueprint)
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64 // Global unique NFT ID
		
		
		access(all)
		let blueprintId: UInt32
		
		access(all)
		let serialNumber: UInt32
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(blueprintId: UInt32, serialNumber: UInt32){ 
			//
			pre{ 
				//
				FrontRow.blueprints[blueprintId] != nil:
					"Couldn't mint NFT: blueprint doesn't exist."
				(				 //
				 FrontRow.blueprints[blueprintId]!).getMintCount() + 1 <= (FrontRow.blueprints[blueprintId]!).maxQuantity:
					"Couldn't mint NFT: maximum quantity limit is reached."
				//
				!(FrontRow.blueprints[blueprintId]!).isCancelled():
					"Couldn't mint NFT: blueprint is cancelled."
			}
			
			// Increment the global supply counter
			FrontRow.totalSupply = FrontRow.totalSupply + 1
			self.id = FrontRow.totalSupply
			self.blueprintId = blueprintId
			self.serialNumber = serialNumber
			emit Minted(id: self.id, blueprintId: self.blueprintId, serialNumber: serialNumber)
		}
	}
	
	// Minter
	//
	// The interface that allows owner to mint new NFTs
	//
	access(all)
	resource interface Minter{ 
		
		// mintNFT mints one NFT from a blueprint
		//
		// Parameters: blueprintId: the ID of the blueprint used for minting
		//
		// Returns: @FrontRow.NFT token that was minted
		//
		access(all)
		fun mintNFT(blueprintId: UInt32): @NFT
	}
	
	// Admin is a special authorization resource that
	// allows the owner to perform important functions such as
	// manage blueprints and mint NFTs
	//
	access(all)
	resource Admin: Minter{ 
		
		// printBlueprint creates a new blueprint and stores it in the blueprints dictionary
		// in the FrontRow smart contract
		//
		// Parameters:  maxQuantity: maximum number of NFTs that can be minted
		//			  metadata: A dictionary mapping metadata titles to their data
		//					   example: {"artist": "BTS", "title": "Permission to Dance"}
		//
		// Returns: the ID of the new Blueprint object
		//
		access(all)
		fun printBlueprint(maxQuantity: UInt32, metadata:{ String: String}): UInt32{ 
			post{ 
				FrontRow.nextBlueprintId == before(FrontRow.nextBlueprintId) + 1:
					"Couldn't create blueprint: the id must be incremented by 1."
			}
			// Get the new blueprint ID from the global counter
			let newId = FrontRow.nextBlueprintId
			
			// Store the newly printed blueprint in the global dictionary
			FrontRow.blueprints[newId] = Blueprint(id: newId, maxQuantity: maxQuantity, metadata: metadata)
			
			// Increment the global counter for the next blueprint
			FrontRow.nextBlueprintId = FrontRow.nextBlueprintId + 1
			
			// Emit the corresponding event
			emit BlueprintPrinted(id: newId, maxQuantity: maxQuantity)
			
			// Return ID of the newly printed blueprint
			return newId
		}
		
		// cancelBlueprint cancels a blueprint so no more NFTs can be minted fron it
		//
		// Parameters:  blueprintId: ID of the blueprint to cancel
		//
		access(all)
		fun cancelBlueprint(_ blueprintId: UInt32){ 
			let blueprint: Blueprint = FrontRow.blueprints[blueprintId]!
			blueprint.cancel()
			FrontRow.blueprints[blueprintId] = blueprint
			emit BlueprintCancelled(id: blueprintId)
		}
		
		// mintNFT mints one NFT from a blueprint
		//
		// Parameters: blueprintId: the ID of the blueprint used for minting
		//
		// Returns: @FrontRow.NFT token that was minted
		//
		access(all)
		fun mintNFT(blueprintId: UInt32): @NFT{ 
			
			// Check if the blueprint with provided ID exists
			pre{ 
				FrontRow.blueprints[blueprintId] != nil:
					"Couldn't create nft: blueprint doesn't exist."
			}
			
			// Check if the serial number has been incremented correctly
			post{ 
				(FrontRow.blueprints[blueprintId]!).getMintCount() == before((FrontRow.blueprints[blueprintId]!).getMintCount()) + 1:
					"Couldn't create nft: the serial number must be incremented by 1."
			}
			
			// Retrieve the corresponding blueprint from the global dictionary
			let blueprint: Blueprint = FrontRow.blueprints[blueprintId]!
			
			// Set the serial number based on the total mintCount value
			let serialNumber: UInt32 = blueprint.getMintCount() + 1
			
			// Mint NFT
			let newNFT: @NFT <- create FrontRow.NFT(blueprintId: blueprintId, serialNumber: serialNumber)
			
			// Update the corresponding blueprint struct
			blueprint.setMintCount(serialNumber)
			blueprint.setNftId(serialNumber, nftId: newNFT.id)
			
			// Store updated blueprint struct in the dictionary
			FrontRow.blueprints[blueprintId] = blueprint
			
			// Return newly minted NFT token
			return <-newNFT
		}
		
		// batchMintNFT mints an arbitrary quantity of FrontRow NFTs and
		// deposits them into receiver's collection
		//
		// Parameters: blueprintId: the ID of the blueprint used for minting
		//			 quantity: number of NFTs to be minted
		//			 receiverRef: reference to the receiver's collection
		//
		access(all)
		fun batchMintNFT(blueprintId: UInt32, quantity: UInt64, receiverRef: &{FrontRow.CollectionPublic}){ 
			// Mint and deposit NFTs to receiver's collection
			var i: UInt64 = 0
			while i < quantity{ 
				receiverRef.deposit(token: <-self.mintNFT(blueprintId: blueprintId))
				i = i + 1
			}
		}
	}
	
	// The interface that users can cast their NFT Collection as
	// to allow others to deposit FrontRow NFTs into their Collection.
	// It also allows for reading the IDs of FrontRow NFTs in the Collection.
	//
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowFrontRowNFT(id: UInt64): &FrontRow.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Can't borrow NFT reference: The ID of the returned reference is incorrect."
			}
		}
		
		// borrowNftByBlueprint let users borrow NFTs based on given blueprint id
		// and a serial number
		//
		// Parameters: blueprintId: the ID of the blueprint
		//			 serialNumber: serial number of the NFT with regard to the blueprint
		//
		// Returns: the ID of the new Blueprint object
		//
		access(all)
		fun borrowNftByBlueprint(blueprintId: UInt32, serialNumber: UInt32): &FrontRow.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.blueprintId == blueprintId || result?.serialNumber == serialNumber:
					"Can't borrow NFT reference: The ID of the returned reference is incorrect."
			}
		}
	}
	
	// Collection is a resource that every user who owns NFTs
	// will store in their account to manage their NFTs
	//
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// Dictionary of NFT conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an NFT from the Collection and moves it to the caller
		//
		// Parameters: withdrawID: the ID of the NFT that is to be removed from the Collection
		//
		// Returns: @NonFungibleToken.NFT the token that was withdrawn
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			
			// Remove the NFT from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Can't withdraw: NFT does not exist in the collection.")
			emit Withdraw(id: token.id, from: self.owner?.address)
			
			// Return the withdrawn token
			return <-(token as! @FrontRow.NFT)
		}
		
		// deposit take an NFT and adds it to the Collections dictionary
		//
		// Parameters: token: the NFT to be deposited in the collection
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			
			// Cast the deposited token as a FrontRow NFT to make sure
			// it is the correct type
			let token <- token as! @FrontRow.NFT
			
			// Get the token's ID
			let id = token.id
			
			// Add the new token to the dictionary
			let oldToken <- self.ownedNFTs[id] <- token
			
			// Only emit a deposit event if the Collection
			// is in an account's storage
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			
			// Destroy the empty old token that was "removed"
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the Collection
		//
		// Returns: an array of NFT IDs in the owner's collection
		//
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT returns a borrowed reference to an NFT in the Collection
		// so that the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		//
		// Note: This only allows the caller to read the ID of the NFT,
		// not any specific data. Please use borrowFrontRowNFT to
		// read NFT data.
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT does not exist in the collection!"
			}
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowFrontRowNFT returns a borrowed reference to a FrontRow NFT
		// so that the caller can read data and call methods from it.
		// They can use this to read its blueprintId, serialNumber,
		// or any of a Blueprint data associated with it by
		// getting a blueprintId and reading those fields from
		// the smart contract.
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: &FrontRow.NFT a reference to the FrontRow NFT
		//
		access(all)
		fun borrowFrontRowNFT(id: UInt64): &FrontRow.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &FrontRow.NFT
			} else{ 
				return nil
			}
		}
		
		// borrowNftByBlueprint returns a borrowed reference to a FrontRow NFT
		// based on provided blueprint id and a serial number.
		//
		// Parameters:  blueprintId: The ID of the blueprint that NFT is associated with
		//			  serialNumber: serial number of the NFT in relation to the blueprint
		//
		// Returns: &FrontRow.NFT a reference to the FrontRow NFT
		//
		access(all)
		fun borrowNftByBlueprint(blueprintId: UInt32, serialNumber: UInt32): &FrontRow.NFT?{ 
			let maybeBlueprint = FrontRow.blueprints[blueprintId]
			if let blueprint = maybeBlueprint{ 
				let maybeNftId = blueprint.getNftId(serialNumber)
				if let nftId = maybeNftId{ 
					if self.ownedNFTs[nftId] != nil{ 
						let ref = (&self.ownedNFTs[nftId] as &{NonFungibleToken.NFT}?)!
						return ref as! &FrontRow.NFT
					}
				}
			}
			return nil
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
	
	// If a transaction destroys the Collection object,
	// all the NFTs contained within are also destroyed!
	//
	}
	
	// createEmptyCollection creates an empty collection of NFTs
	//
	// Returns: @NonFungibleToken.Collection newly created empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// getBlueprints returns map of blueprint IDs to the corresponding blueprint structs
	//
	// Returns: a map of blueprint IDs to the corresponding blueprint objects
	//
	access(all)
	fun getBlueprints():{ UInt32: Blueprint}{ 
		return FrontRow.blueprints
	}
	
	// getBlueprint returns a single blueprint struct
	// based on provided blueprint id and a serial number.
	//
	// Parameters:  id: ID of the blueprint to return
	//
	// Returns: a blueprint struct
	//
	access(all)
	fun getBlueprint(id: UInt32): Blueprint?{ 
		return FrontRow.blueprints[id]
	}
	
	// getBlueprintsCount returns total number of blueprints in existence
	//
	// Returns: total number of blueprints printed so far
	//
	access(all)
	fun getBlueprintsCount(): UInt32{ 
		let count = FrontRow.blueprints != nil ? FrontRow.blueprints.length : 0
		return UInt32(count)
	}
	
	// getBlueprintMintCount returns the total number of NFTs minted for a blueprint
	//
	// Parameters:  id: ID of the blueprint
	//
	// Returns: the mint count for the given blueprint
	//
	access(all)
	fun getBlueprintMintCount(_ blueprintId: UInt32): UInt32{ 
		let blueprint: Blueprint = FrontRow.blueprints[blueprintId]!
		let count = blueprint != nil ? blueprint.getMintCount() : 0 as UInt32
		return count
	}
	
	init(){ 
		// Initialize contract fields
		self.blueprints ={} 
		self.nextBlueprintId = 1
		self.totalSupply = 0
		
		// Set paths aliases
		self.CollectionStoragePath = /storage/FrontRowNFTCollection
		self.CollectionPublicPath = /public/FrontRowNFTCollectionPublic
		self.MinterPrivatePath = /private/FrontRowMinterPrivate
		self.AdminStoragePath = /storage/FrontRowAdmin
		
		// Create the Admin resource and save it to storage
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		
		// Create a private capability for the Minter
		var capability_1 = self.account.capabilities.storage.issue<&{FrontRow.Minter}>(FrontRow.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: FrontRow.MinterPrivatePath)
		emit ContractInitialized()
	}
}
