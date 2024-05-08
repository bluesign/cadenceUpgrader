import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract DieselNFT: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// DieselNFT contract Events
	// -----------------------------------------------------------------------
	
	// Emitted when the Diesel contract is created
	access(all)
	event ContractInitialized()
	
	// Emitted when a new DieselData struct is created
	access(all)
	event DieselDataCreated(dieselDataID: UInt32, name: String, description: String, mainVideo: String)
	
	// Emitted when a Diesel is minted
	access(all)
	event DieselMinted(dieselID: UInt64, dieselDataID: UInt32, serialNumber: UInt32)
	
	// Emitted when the contract's royalty percentage is changed
	access(all)
	event RoyaltyPercentageChanged(newRoyaltyPercentage: UFix64)
	
	access(all)
	event DieselDataIDRetired(dieselDataID: UInt32)
	
	// Events for Collection-related actions
	//
	// Emitted when a Diesel is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when a Diesel is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Emitted when a Diesel is destroyed
	access(all)
	event DieselDestroyed(id: UInt64)
	
	// -----------------------------------------------------------------------
	// contract-level fields.	  
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// Contains standard storage and public paths of resources
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// Variable size dictionary of Diesel structs
	access(self)
	var dieselDatas:{ UInt32: DieselData}
	
	// Dictionary with DieselDataID as key and number of NFTs with DieselDataID are minted
	access(self)
	var numberMintedPerDiesel:{ UInt32: UInt32}
	
	// Dictionary of dieselDataID to  whether they are retired
	access(self)
	var isDieselDataRetired:{ UInt32: Bool}
	
	// Keeps track of how many unique DieselData's are created
	access(all)
	var nextDieselDataID: UInt32
	
	access(all)
	var royaltyPercentage: UFix64
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	struct DieselData{ 
		
		// The unique ID for the Diesel Data
		access(all)
		let dieselDataID: UInt32
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		//stores link to video
		access(all)
		let mainVideo: String
		
		init(name: String, description: String, mainVideo: String){ 
			self.dieselDataID = DieselNFT.nextDieselDataID
			self.name = name
			self.description = description
			self.mainVideo = mainVideo
			DieselNFT.isDieselDataRetired[self.dieselDataID] = false
			
			// Increment the ID so that it isn't used again
			DieselNFT.nextDieselDataID = DieselNFT.nextDieselDataID + 1 as UInt32
			emit DieselDataCreated(dieselDataID: self.dieselDataID, name: self.name, description: self.description, mainVideo: self.mainVideo)
		}
	}
	
	access(all)
	struct Diesel{ 
		
		// The ID of the DieselData that the Diesel references
		access(all)
		let dieselDataID: UInt32
		
		// The N'th NFT with 'DieselDataID' minted
		access(all)
		let serialNumber: UInt32
		
		init(dieselDataID: UInt32){ 
			self.dieselDataID = dieselDataID
			
			// Increment the ID so that it isn't used again
			DieselNFT.numberMintedPerDiesel[dieselDataID] = DieselNFT.numberMintedPerDiesel[dieselDataID]! + 1 as UInt32
			self.serialNumber = DieselNFT.numberMintedPerDiesel[dieselDataID]!
		}
	}
	
	// The resource that represents the Diesel NFTs
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		
		// Global unique Diesel ID
		access(all)
		let id: UInt64
		
		// struct of Diesel
		access(all)
		let diesel: Diesel
		
		// Royalty capability which NFT will use
		access(all)
		let royaltyVault: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(serialNumber: UInt32, dieselDataID: UInt32, royaltyVault: Capability<&{FungibleToken.Receiver}>){ 
			DieselNFT.totalSupply = DieselNFT.totalSupply + 1 as UInt64
			self.id = DieselNFT.totalSupply
			self.diesel = Diesel(dieselDataID: dieselDataID)
			self.royaltyVault = royaltyVault
			
			// Emitted when a Diesel is minted
			emit DieselMinted(dieselID: self.id, dieselDataID: dieselDataID, serialNumber: serialNumber)
		}
	}
	
	// Admin is a special authorization resource that
	// allows the owner to perform important functions to modify the 
	// various aspects of the Diesel and NFTs
	//
	access(all)
	resource Admin{ 
		access(all)
		fun createDieselData(name: String, description: String, mainVideo: String): UInt32{ 
			// Create the new DieselData
			var newDiesel = DieselData(name: name, description: description, mainVideo: mainVideo)
			let newID = newDiesel.dieselDataID
			
			// Store it in the contract storage
			DieselNFT.dieselDatas[newID] = newDiesel
			DieselNFT.numberMintedPerDiesel[newID] = 0 as UInt32
			return newID
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
		
		// Mint the new Diesel
		access(all)
		fun mintNFT(dieselDataID: UInt32, royaltyVault: Capability<&{FungibleToken.Receiver}>): @NFT{ 
			pre{ 
				royaltyVault.check():
					"Royalty capability is invalid!"
			}
			if DieselNFT.isDieselDataRetired[dieselDataID]! == nil{ 
				panic("Cannot mint Diesel. dieselData not found")
			}
			if DieselNFT.isDieselDataRetired[dieselDataID]!{ 
				panic("Cannot mint diesel. dieselDataID retired")
			}
			let numInDiesel = DieselNFT.numberMintedPerDiesel[dieselDataID] ?? panic("Cannot mint Diesel. dieselData not found")
			let newDiesel: @NFT <- create NFT(serialNumber: numInDiesel + 1, dieselDataID: dieselDataID, royaltyVault: royaltyVault)
			return <-newDiesel
		}
		
		access(all)
		fun batchMintNFT(dieselDataID: UInt32, royaltyVault: Capability<&{FungibleToken.Receiver}>, quantity: UInt64): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintNFT(dieselDataID: dieselDataID, royaltyVault: royaltyVault))
				i = i + 1 as UInt64
			}
			return <-newCollection
		}
		
		// Change the royalty percentage of the contract
		access(all)
		fun changeRoyaltyPercentage(newRoyaltyPercentage: UFix64){ 
			DieselNFT.royaltyPercentage = newRoyaltyPercentage
			emit RoyaltyPercentageChanged(newRoyaltyPercentage: newRoyaltyPercentage)
		}
		
		// Retire dieselData so that it cannot be used to mint anymore
		access(all)
		fun retireDieselData(dieselDataID: UInt32){ 
			pre{ 
				DieselNFT.isDieselDataRetired[dieselDataID] != nil:
					"Cannot retire Diesel: Diesel doesn't exist!"
			}
			if !DieselNFT.isDieselDataRetired[dieselDataID]!{ 
				DieselNFT.isDieselDataRetired[dieselDataID] = true
				emit DieselDataIDRetired(dieselDataID: dieselDataID)
			}
		}
	}
	
	// This is the interface users can cast their Diesel Collection as
	// to allow others to deposit into their Collection. It also allows for reading
	// the IDs of Diesel in the Collection.
	access(all)
	resource interface DieselCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowDiesel(id: UInt64): &DieselNFT.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Diesel reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection is a resource that every user who owns NFTs 
	// will store in their account to manage their NFTS
	//
	access(all)
	resource Collection: DieselCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// Dictionary of Diesel conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an Diesel from the Collection and moves it to the caller
		//
		// Parameters: withdrawID: The ID of the NFT 
		// that is to be removed from the Collection
		//
		// returns: @NonFungibleToken.NFT the token that was withdrawn
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Diesel does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			
			// Return the withdrawn token
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: ids: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: A collection that contains
		//										the withdrawn Diesel
		//
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			// Create a new empty Collection
			var batchCollection <- create Collection()
			
			// Iterate through the ids and withdraw them from the Collection
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			
			// Return the withdrawn tokens
			return <-batchCollection
		}
		
		// deposit takes a Diesel and adds it to the Collections dictionary
		//
		// Parameters: token: the NFT to be deposited in the collection
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			// Cast the deposited token as NFT to make sure
			// it is the correct type
			let token <- token as! @DieselNFT.NFT
			
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
		
		// batchDeposit takes a Collection object as an argument
		// and deposits each contained NFT into this Collection
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			// Get an array of the IDs to be deposited
			let keys = tokens.getIDs()
			
			// Iterate through the keys in the collection and deposit each one
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			
			// Destroy the empty Collection
			destroy tokens
		}
		
		// getIDs returns an array of the IDs that are in the Collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT Returns a borrowed reference to a Diesel in the Collection
		// so that the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		//
		// Note: This only allows the caller to read the ID of the NFT,
		// not an specific data. Please use borrowDiesel to 
		// read Diesel data.
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(all)
		fun borrowDiesel(id: UInt64): &DieselNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &DieselNFT.NFT
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
	
	// If a transaction destroys the Collection object,
	// All the NFTs contained within are also destroyed!
	//
	}
	
	// -----------------------------------------------------------------------
	// Diesel contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection creates a new, empty Collection object so that
	// a user can store it in their account storage.
	// Once they have a Collection in their storage, they are able to receive
	// Diesel in transactions.
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create DieselNFT.Collection()
	}
	
	// get dictionary of numberMintedPerDiesel
	access(all)
	fun getNumberMintedPerDiesel():{ UInt32: UInt32}{ 
		return DieselNFT.numberMintedPerDiesel
	}
	
	// get how many Diesels with dieselDataID are minted 
	access(all)
	fun getDieselNumberMinted(id: UInt32): UInt32{ 
		let numberMinted = DieselNFT.numberMintedPerDiesel[id] ?? panic("dieselDataID not found")
		return numberMinted
	}
	
	// get the dieselData of a specific id
	access(all)
	fun getDieselData(id: UInt32): DieselData{ 
		let dieselData = DieselNFT.dieselDatas[id] ?? panic("dieselDataID not found")
		return dieselData
	}
	
	// get all dieselDatas created
	access(all)
	fun getDieselDatas():{ UInt32: DieselData}{ 
		return DieselNFT.dieselDatas
	}
	
	access(all)
	fun getDieselDatasRetired():{ UInt32: Bool}{ 
		return DieselNFT.isDieselDataRetired
	}
	
	access(all)
	fun getDieselDataRetired(dieselDataID: UInt32): Bool{ 
		let isDieselDataRetired = DieselNFT.isDieselDataRetired[dieselDataID] ?? panic("dieselDataID not found")
		return isDieselDataRetired
	}
	
	// -----------------------------------------------------------------------
	// initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		// Initialize contract fields
		self.dieselDatas ={} 
		self.numberMintedPerDiesel ={} 
		self.nextDieselDataID = 1
		self.royaltyPercentage = 0.10
		self.isDieselDataRetired ={} 
		self.totalSupply = 0
		self.CollectionPublicPath = /public/DieselCollection004
		self.CollectionStoragePath = /storage/DieselCollection004
		self.AdminStoragePath = /storage/DieselAdmin004
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: self.CollectionStoragePath)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{DieselCollectionPublic}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Put the Minter in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
