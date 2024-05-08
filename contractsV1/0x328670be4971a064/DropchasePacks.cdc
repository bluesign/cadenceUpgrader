//SPDX-License-Identifier: UNLICENSED
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import DropchaseCoin from "./DropchaseCoin.cdc"

import DropchaseCreatorRegistry from "./DropchaseCreatorRegistry.cdc"

access(all)
contract DropchasePacks: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// DropchasePacks contract Events
	// -----------------------------------------------------------------------
	
	// Emitted when the DropchasePacks contract is created
	access(all)
	event ContractInitialized()
	
	//Emitted some other events 
	access(all)
	event PackAdded(id: UInt64, packID: UInt32, packNumber: UInt32)
	
	access(all)
	event PackBought(packID: UInt32, address: Address?)
	
	access(all)
	event PackOpenRequest(id: UInt64, address: Address?)
	
	access(all)
	event PackBurned(id: UInt64)
	
	// Events for Collection-related actions
	//
	// Emitted when a pack is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when a pack is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// emitted when an creator has received a cut from a pack
	access(all)
	event creatorPackCutReceived(name: String, cut: UFix64)
	
	// Variable size dictionary of Pack resources
	access(self)
	var packs:{ UInt32: Pack}
	
	// The total number of Packs that have been minted
	access(all)
	var totalSupply: UInt64
	
	// The ID that is used to create Packs. Every time a Pack is created
	// packID is assigned to the new pack's ID and then is incremented by 1.
	access(all)
	var nextPackID: UInt32
	
	access(all)
	let PacksHandlerStoragePath: StoragePath
	
	access(all)
	let PacksHandlerPublicPath: PublicPath
	
	access(all)
	struct Pack{ 
		
		// Unique ID for the pack
		access(all)
		let packID: UInt32
		
		access(all)
		var locked: Bool
		
		access(all)
		var numberMinted: UInt32
		
		access(all)
		var name: String
		
		access(all)
		var creator: String
		
		access(all)
		var price: UFix64
		
		access(all)
		var packsAmount: Int
		
		access(all)
		var packImage: String
		
		access(all)
		var packBuyers: [Address]
		
		init(name: String, creator: String, price: UFix64, packsAmount: Int, packImage: String){ 
			pre{ 
				name.length > 0:
					"New Pack name cannot be empty"
			}
			self.packID = DropchasePacks.nextPackID
			DropchasePacks.nextPackID = DropchasePacks.nextPackID + 1 as UInt32
			self.locked = false
			self.numberMinted = 0
			self.name = name
			self.creator = creator
			self.price = price
			self.packsAmount = packsAmount
			self.packImage = packImage
			self.packBuyers = []
		}
		
		access(all)
		fun mintPack(packID: UInt32): @NFT{ 
			// Mint the new moment
			let newPack: @NFT <- create NFT(packID: self.packID, serialNumber: self.numberMinted + 1)
			self.numberMinted = self.numberMinted + 1
			return <-newPack
		}
		
		// batchMintPack mints an arbitrary quantity of Packs 
		// and returns them as a Collection
		//
		//
		// Returns: Collection object that contains all the Packs that were minted
		//
		access(all)
		fun batchMintPack(packID: UInt32, quantity: Int): @Collection{ 
			let newCollection <- create Collection()
			var i: Int = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintPack(packID: packID))
				i = i + 1 as Int
			}
			return <-newCollection
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		
		// Global unique moment ID
		access(all)
		let id: UInt64
		
		access(all)
		let serialNumber: UInt32
		
		access(all)
		let packID: UInt32
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// Struct of Pack metadata
		init(packID: UInt32, serialNumber: UInt32){ 
			// Increment the global Pack IDs
			DropchasePacks.totalSupply = DropchasePacks.totalSupply + 1 as UInt64
			self.serialNumber = serialNumber
			self.id = DropchasePacks.totalSupply
			self.packID = packID
			emit PackAdded(id: self.id, packID: packID, packNumber: serialNumber)
		}
	}
	
	// PackPurchaser
	// An interface to allow purchasing packs
	access(all)
	resource interface PackPurchaser{ 
		access(all)
		fun buyPack(packID: UInt32, buyerPayment: @{FungibleToken.Vault}, buyerAddress: Address)
	}
	
	// PacksHandler
	access(all)
	resource PacksHandler: PackPurchaser{ 
		access(all)
		fun buyPack(packID: UInt32, buyerPayment: @{FungibleToken.Vault}, buyerAddress: Address){ 
			pre{ 
				DropchasePacks.packs[packID] != nil:
					"Pack does not exist in the collection!"
				buyerPayment.balance == (DropchasePacks.packs[packID]!).price:
					"payment does not equal the price of the pack"
				(DropchasePacks.packs[packID]!).packBuyers.length < (DropchasePacks.packs[packID]!).packsAmount as Int:
					"All packs are bought"
				self.owner != nil:
					"Owner cant be nil"
				(self.owner!).capabilities.get<&{FungibleToken.Receiver}>(/public/DropchaseCoinReceiver).borrow<&{FungibleToken.Receiver}>() != nil:
					"DropchaseCoin receiver cant be nil"
			}
			let creatorName = DropchasePacks.getPackCreator(packID: packID)
			let creatorCutPercentage = DropchaseCreatorRegistry.getPackCutPercentage(name: creatorName)
			let creatorCutAmount = (DropchasePacks.packs[packID]!).price * creatorCutPercentage
			let creatorCut <- buyerPayment.withdraw(amount: creatorCutAmount)
			
			// Deposit the creator cut
			let creatorCap = DropchaseCreatorRegistry.getCapability(name: creatorName) ?? panic("Cannot find the creator in the registry")
			let creatorReceiverRef = creatorCap.borrow<&{FungibleToken.Receiver}>() ?? panic("Cannot find a token receiver for the creator")
			creatorReceiverRef.deposit(from: <-creatorCut)
			emit creatorPackCutReceived(name: creatorName, cut: creatorCutAmount)
			let ownerReceiverVault = (self.owner!).capabilities.get<&{FungibleToken.Receiver}>(/public/DropchaseCoinReceiver).borrow<&{FungibleToken.Receiver}>()!
			ownerReceiverVault.deposit(from: <-buyerPayment)
			(DropchasePacks.packs[packID]!).packBuyers.append(buyerAddress)
			emit PackBought(packID: packID, address: buyerAddress)
		}
	}
	
	access(all)
	resource Admin{ 
		
		// createpack creates a new pack resource and stores it
		// in the packs mapping in the DropchasePacks contract
		//
		// Parameters: name: The name of the pack
		//
		access(all)
		fun createPack(name: String, creator: String, price: UFix64, packsAmount: Int, packImage: String){ 
			// Create the new pack
			var newPack = Pack(name: name, creator: creator, price: price, packsAmount: packsAmount, packImage: packImage)
			
			// Store it in the packs mapping field
			DropchasePacks.packs[newPack.packID] = newPack
		}
		
		// borrowpack returns a reference to a pack in the DropchasePacks
		// contract so that the admin can call methods on it
		//
		// Parameters: packID: The ID of the pack that you want to
		// get a reference to
		//
		// Returns: A reference to the pack with all of the fields
		// and methods exposed
		//
		access(all)
		fun borrowPack(packID: UInt32): &Pack{ 
			pre{ 
				DropchasePacks.packs[packID] != nil:
					"Cannot borrow pack: The pack doesn't exist"
			}
			
			// Get a reference to the pack and return it
			// use `&` to indicate the reference to the object and type
			return &DropchasePacks.packs[packID] as &DropchasePacks.Pack?
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	// This is the interface that users can cast their Pack Collection as
	// to allow others to deposit Packs into their Collection. It also allows for reading
	// the IDs of Packs in the Collection.
	access(all)
	resource interface PackCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowPack(id: UInt64): &DropchasePacks.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Pack reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection is a resource that every user who owns NFTs 
	// will store in their account to manage their NFTS
	//
	access(all)
	resource Collection: PackCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// Dictionary of Pack conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes a Pack from the Collection and moves it to the caller
		//
		// Parameters: withdrawID: The ID of the NFT 
		// that is to be removed from the Collection
		//
		// returns: @NonFungibleToken.NFT the token that was withdrawn
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Pack does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			
			// Return the withdrawn token
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: ids: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: A collection that contains
		//										the withdrawn moments
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
		
		// deposit takes a Pack and adds it to the Collections dictionary
		//
		// Paramters: token: the NFT to be deposited in the collection
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			
			// Cast the deposited token as a DropchasePacks NFT to make sure
			// it is the correct type
			let token <- token as! @DropchasePacks.NFT
			
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
		
		// borrowNFT Returns a borrowed reference to a Pack in the Collection
		// so that the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		//
		// Note: This only allows the caller to read the ID of the NFT,
		// not any DropchasePacks specific data. Please use borrowPack to 
		// read Pack data.
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// borrowPack returns a borrowed reference to a Pack
		// so that the caller can read data and call methods from it.
		// They can use this to read its packID, serialNumber,
		// or any of the packData or Stat data associated with it by
		// getting the packID and reading those fields from
		// the smart contract.
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(all)
		fun borrowPack(id: UInt64): &DropchasePacks.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &DropchasePacks.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		fun openPack(withdrawID: UInt64){ 
			
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Pack does not exist in the collection")
			emit PackOpenRequest(id: token.id, address: self.owner?.address)
			
			//destroy old token
			destroy token
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
	}
	
	// -----------------------------------------------------------------------
	// DropchasePacks contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection creates a new, empty Collection object so that
	// a user can store it in their account storage.
	// Once they have a Collection in their storage, they are able to receive
	// Packs in transactions.
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create DropchasePacks.Collection()
	}
	
	access(all)
	fun getPackPrice(packID: UInt32): UFix64{ 
		pre{ 
			self.packs[packID] != nil:
				"Pack must exist"
		}
		return (self.packs[packID]!).price
	}
	
	access(all)
	fun getPackName(packID: UInt32): String?{ 
		// Don't force a revert if the packID is invalid
		return DropchasePacks.packs[packID]?.name
	}
	
	access(all)
	fun getPackCreator(packID: UInt32): String{ 
		// Don't force a revert if the packID is invalid
		return (DropchasePacks.packs[packID]!).creator
	}
	
	// -----------------------------------------------------------------------
	// DropchasePacks initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		// Initialize contract fields
		self.packs ={} 
		self.nextPackID = 1
		self.totalSupply = 0
		self.PacksHandlerStoragePath = /storage/DropchasePacksHandler
		self.PacksHandlerPublicPath = /public/DropchasePacksHandler
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: /storage/DropchasePackCollection)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{PackCollectionPublic}>(/storage/DropchasePackCollection)
		self.account.capabilities.publish(capability_1, at: /public/DropchasePackCollection)
		
		// Put the Minter in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: /storage/DropchasePacksAdmin)
		
		// Create Packhandle
		let packsHandler <- create PacksHandler()
		
		// Put Packhandler to Storage
		self.account.storage.save(<-packsHandler, to: self.PacksHandlerStoragePath)
		
		// Create a public capability for the Packshandler
		var capability_2 = self.account.capabilities.storage.issue<&DropchasePacks.PacksHandler>(self.PacksHandlerStoragePath)
		self.account.capabilities.publish(capability_2, at: self.PacksHandlerPublicPath)
		emit ContractInitialized()
	}
}
