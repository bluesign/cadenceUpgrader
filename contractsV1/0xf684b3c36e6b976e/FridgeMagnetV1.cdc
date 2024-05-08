/*
	Description: Smart contract for FridgeMagnetV1

	This smart contract is the main and has the core functionality for 
	FridgeMagnetV1's Tester.

	It contains "Admin" resource for performing the essential tasks.
	Admin can mint a new NFT, which will be stored in the contract -> to be sent
	to the users (using transaction) in the next stage.

	The contract has "Collection" resource, an obj that every NFT owner will 
	store in their account to hold the NFT they own.

	This main account will have its own NFT collection to hold the NFTs that will
	be sent to the users on the platform's logics.

 */

// These both imports' accounts are for test, 
// Emulator -> 0xf8d6e0586b0a20c7, Testnet -> 0x631e88ae7f1d7c20, for mainnet -> 0x1d7e57aa55817448
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract FridgeMagnetV1: NonFungibleToken{ 
	// Path constants declaration (so that paths don't have to be hard coded)
	// in transaction && scripts
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// Events -----------------
	// Emitted when FridgeMagnetV1 is created
	access(all)
	event ContractInitialized()
	
	// Emitted when an NFT is withdrawn
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when an NFT is deposited
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Emitted when an NFT is minted
	access(all)
	event NFTMinted(NFTID: UInt64, setID: UInt32, serialNumber: UInt32, mintingDate: UFix64)
	
	// Emitted when a Set is created
	access(all)
	event SetCreated(setID: UInt32)
	
	// Variables -----------------
	// Variable's dictionary of Set struct
	access(self)
	var setDatas:{ UInt32: SetData}
	
	// Variable's dictionary of Set resource
	access(self)
	var sets: @{UInt32: Set}
	
	// The ID used to create the new Sets
	// When a new Set is created, setID is assigned to this, then it increases by 1
	access(all)
	var nextSetID: UInt32
	
	// Total number of FridgeMagnetV1's NFTs that have been "minted" to date (mint counter)
	// and to be used as global NFT IDs
	access(all)
	var totalSupply: UInt64
	
	// Contract-level Composite Type Definitions -----------------
	// SetData is a struct to hold name and metadata associated with a specific collectible
	// NFTs will reference to an individual Set as the owner of its name and metadata
	// It is publicly accessible so anyone can read it with a getter function at the end of this contract
	// TODO: Improve fields var for easier tracking the data (eg. Set of drops on specific time; Edition/Weekly drops)
	access(all)
	struct SetData{ 
		// The unique ID for the Set
		access(all)
		let setID: UInt32
		
		// Name of the Set
		access(all)
		let name: String
		
		// Description of the Set
		access(all)
		let description: String
		
		// Image of the Set
		access(all)
		let image: String
		
		access(self)
		var metadata:{ String: AnyStruct}
		
		init(name: String, description: String, image: String, metadata:{ String: AnyStruct}){ 
			pre{ 
				name.length > 0:
					"A new Set name cannot be empty"
				description.length > 0:
					"A new Set description cannot be empty"
				image.length != 0:
					"A new Set image cannot be empty"
				metadata.length != 0:
					"A new Set metadata cannot be empty"
			}
			self.setID = FridgeMagnetV1.nextSetID
			self.name = name
			self.description = description
			self.image = image
			self.metadata = metadata
		}
		
		access(all)
		fun getMetadata():{ String: AnyStruct}{ 
			return self.metadata
		}
	}
	
	// Set is a resource that hold the functions to mainly mint NFTs
	// Only Admin resource has the ability to perform these; It is stored in a private field in the contract
	// NFTs are minted by a Set and listed in the Set that minted them.
	access(all)
	resource Set{ 
		// The unique ID for the Set
		access(all)
		let setID: UInt32
		
		// Number of NFTs minted per this Set
		// Value is stored in the NFT as for example: ---> 74 /105 (number 74 out of 105 in total)
		access(contract)
		var numberNFTMintedPerSet: UInt32
		
		init(name: String, description: String, image: String, metadata:{ String: AnyStruct}){ 
			self.setID = FridgeMagnetV1.nextSetID
			self.numberNFTMintedPerSet = 0
			// Create and store SetData for this set in the account's storage
			FridgeMagnetV1.setDatas[self.setID] = SetData(name: name, description: description, image: image, metadata: metadata)
		}
		
		// mintNFT is a function to mint a new NFT on the specific Set
		// Param: setID -> ID of the Set 
		// Return: A minted NFT
		access(all)
		fun mintNFT(): @NFT{ 
			// Get the number of NFT that already minted in this Set
			let numNFTInSet = self.numberNFTMintedPerSet
			// Mint new NFT
			let newNFT: @NFT <- create NFT(setID: self.setID, serialNumber: numNFTInSet + UInt32(1))
			// Increase count for NFT in this Set by 1
			self.numberNFTMintedPerSet = numNFTInSet + UInt32(1)
			// Note: Don't need to worry about increasing nextSetID && totalSupply for future use
			// It's implemented in createSet && NFT's init()
			return <-newNFT
		}
		
		// Batch minter
		access(all)
		fun batchMintNFT(quantity: UInt64): @Collection{ 
			let newNFTCollection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				newNFTCollection.deposit(token: <-self.mintNFT())
				i = i + UInt64(1)
			}
			return <-newNFTCollection
		}
		
		access(all)
		fun getNumberNFTMintedPerSet(): UInt32{ 
			return self.numberNFTMintedPerSet
		}
	}
	
	// Struct that has all the Set's data
	// Used by getSetData (see the end of this contract)
	access(all)
	struct QuerySetData{ 
		// Declare all the fields we want to query
		access(all)
		let setID: UInt32
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let numberNFTMintedPerSet: UInt32
		
		init(setID: UInt32){ 
			pre{ 
				FridgeMagnetV1.sets[setID] != nil:
					"The Set with this ID doesn't exist : message from getSetData"
			}
			let set = (&FridgeMagnetV1.sets[setID] as &Set?)!
			let setData = FridgeMagnetV1.setDatas[setID]!
			self.setID = setID
			self.name = setData.name
			self.description = setData.description
			self.numberNFTMintedPerSet = set.numberNFTMintedPerSet
		}
		
		access(all)
		fun getNumberNFTMintedPerSet(): UInt32{ 
			return self.numberNFTMintedPerSet
		}
	}
	
	// Struct for NFT data
	// ***Place this for future use*** eg. Add some extra data to 
	access(all)
	struct NFTData{ 
		// The ID of the Set that the NFT references to
		access(all)
		let setID: UInt32
		
		// Identifier; no. of NFT in a specific Set ( -->74 / 105)
		access(all)
		let serialNumber: UInt32
		
		// Put minting date (unix timestamp) on the NFT
		access(all)
		let mintingDate: UFix64
		
		init(setID: UInt32, serialNumber: UInt32){ 
			self.setID = setID
			self.serialNumber = serialNumber
			self.mintingDate = getCurrentBlock().timestamp
		}
	}
	
	// Custom struct to be used in resolveView
	access(all)
	struct FridgeMagnetV1CustomViews{ 
		// All the var we want to view
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let image: String
		
		access(all)
		let setID: UInt32
		
		access(all)
		let serialNumber: UInt32
		
		access(all)
		let totalNFTInSet: UInt32?
		
		access(all)
		let externalUrl: String?
		
		access(all)
		let location: String?
		
		access(all)
		let mintingDate: UFix64
		
		init(name: String, description: String, image: String, setID: UInt32, serialNumber: UInt32, totalNFTInSet: UInt32?, externalUrl: String?, location: String?, mintingDate: UFix64){ 
			self.name = name
			self.description = description
			self.image = image
			self.setID = setID
			self.serialNumber = serialNumber
			self.totalNFTInSet = totalNFTInSet
			self.externalUrl = externalUrl
			self.location = location
			self.mintingDate = mintingDate
		}
	}
	
	// Resource that represents NFTs
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The global unique ID for each NFT
		access(all)
		let id: UInt64
		
		// Struct of NFT metadata
		access(all)
		let data: NFTData
		
		init(setID: UInt32, serialNumber: UInt32){ 
			// Increase "global NFT IDs" by 1 (Start with 1 in the contract sequel)
			FridgeMagnetV1.totalSupply = FridgeMagnetV1.totalSupply + UInt64(1)
			// Assign to as global unique ID
			self.id = FridgeMagnetV1.totalSupply
			// Set the data struct
			self.data = NFTData(setID: setID, serialNumber: serialNumber)
			emit NFTMinted(NFTID: self.id, setID: self.data.setID, serialNumber: self.data.serialNumber, mintingDate: self.data.mintingDate)
		}
		
		// Functions for resolveView function
		access(all)
		fun name(): String{ 
			let name: String = FridgeMagnetV1.getSetName(setID: self.data.setID) ?? ""
			return name
		}
		
		access(all)
		fun description(): String{ 
			let description: String = FridgeMagnetV1.getSetDescription(setID: self.data.setID) ?? ""
			let number: String = self.data.serialNumber.toString()
			return description.concat(" #").concat(number)
		}
		
		access(all)
		fun image(): String{ 
			let image: String = FridgeMagnetV1.getSetImage(setID: self.data.setID) ?? ""
			return image
		}
		
		access(all)
		fun getSetMetadataByField(field: String): AnyStruct?{ 
			if let set = FridgeMagnetV1.setDatas[self.data.setID]{ 
				return set.getMetadata()[field]
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<FridgeMagnetV1CustomViews>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name(), description: self.description(), thumbnail: MetadataViews.HTTPFile(url: self.image()))
				case Type<FridgeMagnetV1CustomViews>():
					let externalUrl = self.getSetMetadataByField(field: "externalUrl") ?? ""
					let location = self.getSetMetadataByField(field: "location") ?? ""
					return FridgeMagnetV1CustomViews(name: self.name(), description: self.description(), image: self.image(), setID: self.data.setID, serialNumber: self.data.serialNumber, totalNFTInSet: FridgeMagnetV1.getTotalNFTInSet(setID: self.data.setID), externalUrl: externalUrl as? String, location: location as? String, mintingDate: self.data.mintingDate)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Resource that is owned by Admin or smart contract
	// it allows them to call functions inside
	access(all)
	resource Admin{ 
		// This func creates (mints) a new Set with new ID in this contract storage
		// Param: name -> name of the Set
		// Return: ID of the created Set
		access(all)
		fun createSet(name: String, description: String, image: String, metadata:{ String: AnyStruct}): UInt32{ 
			// Create new Set
			var newSet <- create Set(name: name, description: description, image: image, metadata: metadata)
			// Increase nextSetID by 1
			FridgeMagnetV1.nextSetID = FridgeMagnetV1.nextSetID + UInt32(1)
			let newSetID = newSet.setID
			emit SetCreated(setID: newSetID)
			// Store the new Set in the account's storage
			FridgeMagnetV1.sets[newSetID] <-! newSet
			return newSetID
		}
		
		// This func returns a reference to the Set
		// For Admin to call it and mint NFT on the borrowed Set (transaction)
		// Param: setID -> ID of the Set we want to call
		// Return: A reference to the Set (w/all fields & methods)
		access(all)
		fun borrowSet(setID: UInt32): &Set{ 
			pre{ 
				FridgeMagnetV1.sets[setID] != nil:
					"Set doesn't exist, please check"
			}
			return (&FridgeMagnetV1.sets[setID] as &Set?)!
		}
		
		// This func creates new Admin resource
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	// This interface allows users to borrow the functions inside publicly to perform tasks
	access(all)
	resource interface NFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowFridgeMagnetV1NFT(id: UInt64): &FridgeMagnetV1.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow ExampleNFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection is a main resource for "every" user to store their owned NFTs in their accounts
	access(all)
	resource Collection: NFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// Dictionary of NFT conforming tokens
		// NFT is a resource type with an UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// Initialize NFTs field to an empty Collection
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an NFT from the Collection and moves it to the caller
		// Param: withdrawID -> ID of the NFT
		// Return: token (: @NonFungibleToken.NFT)
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: This collection does not contain an NFT with this ID")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit is a function that takes a NFT as an argument and adds it to
		// the Collection dictionary
		// Param: token -> the NFT that will be deposited to the Collection
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			// Make sure that the token has the correct type (as our @FridgeMagnetV1.NFT)
			let token <- token as! @FridgeMagnetV1.NFT
			// Get the token's ID
			let id: UInt64 = token.id
			// Add the new token to the dictionary
			let oldToken <- self.ownedNFTs[id] <- token
			// Trigger event to let listeners know that the NFT was deposited
			emit Deposit(id: id, to: self.owner?.address)
			// Destroy the old token
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the Collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT returns a borrowed reference to NFT in the Collection
		// Param: id -> ID of the NFT we want to get reference
		// Return: A reference to the NFT
		// Caller can only read its ID
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowFridgeMagnetV1NFT returns a borrowed reference to NFT in the Collection
		// Param: id -> ID of the NFT we want to get reference
		// Return: A reference to the NFT
		// Caller can read data and call methods
		// setID, serialNumber, or use it to call getSetData(setID)
		access(all)
		fun borrowFridgeMagnetV1NFT(id: UInt64): &FridgeMagnetV1.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &FridgeMagnetV1.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let FridgeMagnetV1NFT = nft as! &FridgeMagnetV1.NFT
			return FridgeMagnetV1NFT as &{ViewResolver.Resolver}
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
	// Need to destroy the placeholder Collection
	}
	
	// Contract-level Function Definitions -----------------
	// createEmptyCollection creates a new, empty Collection for users
	// Once they create this in their storage they can receive the NFTs
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create FridgeMagnetV1.Collection()
	}
	
	// getAllSets returns all Set and values
	// Return: An array of all created Sets
	access(all)
	fun getAllSets(): [FridgeMagnetV1.SetData]{ 
		return FridgeMagnetV1.setDatas.values
	}
	
	// getTotalNFTinSet returns the number of NFTs that has been minted in a Set
	// Param: setID -> ID of the Set we are searching
	// Return: Total number of NFTs minted in a Set
	access(all)
	fun getTotalNFTInSet(setID: UInt32): UInt32?{ 
		if let setdata = self.getSetData(setID: setID){ 
			let total = setdata.getNumberNFTMintedPerSet()
			return total
		} else{ 
			return nil
		}
	}
	
	// getSetData returns data of the Set
	// Param: setID -> ID of the Set we are searching
	// Return: QuerySetData struct
	access(all)
	fun getSetData(setID: UInt32): QuerySetData?{ 
		if FridgeMagnetV1.sets[setID] == nil{ 
			return nil
		} else{ 
			return QuerySetData(setID: setID)
		}
	}
	
	// getSetName returns name of the Set
	// Param: setID -> ID of the Set we are searching
	// Return: Name of the Set
	access(all)
	fun getSetName(setID: UInt32): String?{ 
		return FridgeMagnetV1.setDatas[setID]?.name
	}
	
	// getSetDescription returns description of the Set
	// Param: setID -> ID of the Set we are searching
	// Return: Description of the Set
	access(all)
	fun getSetDescription(setID: UInt32): String?{ 
		return FridgeMagnetV1.setDatas[setID]?.description
	}
	
	// getSetImage returns image of the Set
	// Param: setID -> ID of the Set we are searching
	// Return: An image of the Set
	access(all)
	fun getSetImage(setID: UInt32): String?{ 
		return FridgeMagnetV1.setDatas[setID]?.image
	}
	
	// Add more func to call for the business logics HERE ^^^
	// 
	// -----------------
	// Initialize fields
	init(){ 
		self.setDatas ={} 
		self.sets <-{} 
		self.nextSetID = 1
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/FridgeMagnetV1Collection
		self.CollectionPublicPath = /public/FridgeMagnetV1Collection
		self.AdminStoragePath = /storage/FridgeMagnetV1Admin
		// Create an NFT Collection on the account storage
		let collection <- create Collection()
		self.account.storage.save<@Collection>(<-collection, to: self.CollectionStoragePath)
		// Publish a reference to the Collection in the storage (public capability)
		var capability_1 = self.account.capabilities.storage.issue<&{NFTCollectionPublic}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		// Store a minter resource in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
