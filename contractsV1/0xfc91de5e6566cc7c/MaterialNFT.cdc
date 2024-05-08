import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FBRC from "./FBRC.cdc"

access(all)
contract MaterialNFT: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// MaterialNFT contract Events
	// -----------------------------------------------------------------------
	
	// Emitted when the Material contract is created
	access(all)
	event ContractInitialized()
	
	// Emitted when a new MaterialData struct is created
	access(all)
	event MaterialDataCreated(materialDataID: UInt32, mainImage: String, secondImage: String, name: String, description: String)
	
	// Emitted when a Material is minted
	access(all)
	event MaterialMinted(materialID: UInt64, materialDataID: UInt32, serialNumber: UInt32)
	
	// Emitted when the contract's royalty percentage is changed
	access(all)
	event RoyaltyPercentageChanged(newRoyaltyPercentage: UFix64)
	
	access(all)
	event MaterialDataIDRetired(materialDataID: UInt32)
	
	// Events for Collection-related actions
	//
	// Emitted when a Material is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when a Material is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Emitted when a Material is destroyed
	access(all)
	event MaterialDestroyed(id: UInt64)
	
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
	
	// Variable size dictionary of Material structs
	access(self)
	var materialDatas:{ UInt32: MaterialData}
	
	// Dictionary with MaterialDataID as key and number of NFTs with MaterialDataID are minted
	access(self)
	var numberMintedPerMaterial:{ UInt32: UInt32}
	
	// Dictionary of materialDataID to  whether they are retired
	access(self)
	var isMaterialDataRetired:{ UInt32: Bool}
	
	// Keeps track of how many unique MaterialData's are created
	access(all)
	var nextMaterialDataID: UInt32
	
	access(all)
	var royaltyPercentage: UFix64
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	struct MaterialData{ 
		
		// The unique ID for the Material Data
		access(all)
		let materialDataID: UInt32
		
		//stores link to image
		access(all)
		let mainImage: String
		
		access(all)
		let secondImage: String
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		init(mainImage: String, secondImage: String, name: String, description: String){ 
			self.materialDataID = MaterialNFT.nextMaterialDataID
			self.mainImage = mainImage
			self.secondImage = secondImage
			self.name = name
			self.description = description
			MaterialNFT.isMaterialDataRetired[self.materialDataID] = false
			
			// Increment the ID so that it isn't used again
			MaterialNFT.nextMaterialDataID = MaterialNFT.nextMaterialDataID + 1 as UInt32
			emit MaterialDataCreated(materialDataID: self.materialDataID, mainImage: self.mainImage, secondImage: self.secondImage, name: self.name, description: self.description)
		}
	}
	
	access(all)
	struct Material{ 
		
		// The ID of the MaterialData that the Material references
		access(all)
		let materialDataID: UInt32
		
		// The N'th NFT with 'MaterialDataID' minted
		access(all)
		let serialNumber: UInt32
		
		init(materialDataID: UInt32){ 
			self.materialDataID = materialDataID
			
			// Increment the ID so that it isn't used again
			MaterialNFT.numberMintedPerMaterial[materialDataID] = MaterialNFT.numberMintedPerMaterial[materialDataID]! + 1 as UInt32
			self.serialNumber = MaterialNFT.numberMintedPerMaterial[materialDataID]!
		}
	}
	
	// The resource that represents the Material NFTs
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		
		// Global unique Material ID
		access(all)
		let id: UInt64
		
		// struct of Material
		access(all)
		let material: Material
		
		// Royalty capability which NFT will use
		access(all)
		let royaltyVault: Capability<&FBRC.Vault>
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(serialNumber: UInt32, materialDataID: UInt32, royaltyVault: Capability<&FBRC.Vault>){ 
			MaterialNFT.totalSupply = MaterialNFT.totalSupply + 1 as UInt64
			self.id = MaterialNFT.totalSupply
			self.material = Material(materialDataID: materialDataID)
			self.royaltyVault = royaltyVault
			
			// Emitted when a Material is minted
			emit MaterialMinted(materialID: self.id, materialDataID: materialDataID, serialNumber: serialNumber)
		}
	}
	
	// Admin is a special authorization resource that
	// allows the owner to perform important functions to modify the 
	// various aspects of the Material and NFTs
	//
	access(all)
	resource Admin{ 
		access(all)
		fun createMaterialData(mainImage: String, secondImage: String, name: String, description: String): UInt32{ 
			// Create the new MaterialData
			var newMaterial = MaterialData(mainImage: mainImage, secondImage: secondImage, name: name, description: description)
			let newID = newMaterial.materialDataID
			
			// Store it in the contract storage
			MaterialNFT.materialDatas[newID] = newMaterial
			MaterialNFT.numberMintedPerMaterial[newID] = 0 as UInt32
			return newID
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
		
		// Mint the new Material
		access(all)
		fun mintNFT(materialDataID: UInt32, royaltyVault: Capability<&FBRC.Vault>): @NFT{ 
			pre{ 
				royaltyVault.check():
					"Royalty capability is invalid!"
			}
			if MaterialNFT.isMaterialDataRetired[materialDataID]! == nil{ 
				panic("Cannot mint Material. materialData not found")
			}
			if MaterialNFT.isMaterialDataRetired[materialDataID]!{ 
				panic("Cannot mint material. materialDataID retired")
			}
			let numInMaterial = MaterialNFT.numberMintedPerMaterial[materialDataID] ?? panic("no materialDataID found")
			let newMaterial: @NFT <- create NFT(serialNumber: numInMaterial + 1, materialDataID: materialDataID, royaltyVault: royaltyVault)
			return <-newMaterial
		}
		
		access(all)
		fun batchMintNFT(materialDataID: UInt32, royaltyVault: Capability<&FBRC.Vault>, quantity: UInt64): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintNFT(materialDataID: materialDataID, royaltyVault: royaltyVault))
				i = i + 1 as UInt64
			}
			return <-newCollection
		}
		
		// Change the royalty percentage of the contract
		access(all)
		fun changeRoyaltyPercentage(newRoyaltyPercentage: UFix64){ 
			MaterialNFT.royaltyPercentage = newRoyaltyPercentage
			emit RoyaltyPercentageChanged(newRoyaltyPercentage: newRoyaltyPercentage)
		}
		
		// Retire materialData so that it cannot be used to mint anymore
		access(all)
		fun retireMaterialData(materialDataID: UInt32){ 
			pre{ 
				MaterialNFT.isMaterialDataRetired[materialDataID] != nil:
					"Cannot retire Material: Material doesn't exist!"
			}
			if !MaterialNFT.isMaterialDataRetired[materialDataID]!{ 
				MaterialNFT.isMaterialDataRetired[materialDataID] = true
				emit MaterialDataIDRetired(materialDataID: materialDataID)
			}
		}
	}
	
	// This is the interface users can cast their Material Collection as
	// to allow others to deposit into their Collection. It also allows for reading
	// the IDs of Material in the Collection.
	access(all)
	resource interface MaterialCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowMaterial(id: UInt64): &MaterialNFT.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Material reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection is a resource that every user who owns NFTs 
	// will store in their account to manage their NFTS
	//
	access(all)
	resource Collection: MaterialCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// Dictionary of Material conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an Material from the Collection and moves it to the caller
		//
		// Parameters: withdrawID: The ID of the NFT 
		// that is to be removed from the Collection
		//
		// returns: @NonFungibleToken.NFT the token that was withdrawn
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Material does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			
			// Return the withdrawn token
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: ids: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: A collection that contains
		//										the withdrawn Material
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
		
		// deposit takes a Material and adds it to the Collections dictionary
		//
		// Parameters: token: the NFT to be deposited in the collection
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			// Cast the deposited token as NFT to make sure
			// it is the correct type
			let token <- token as! @MaterialNFT.NFT
			
			// Get the token's ID
			let id = token.id
			
			// Add the new token to the dictionary
			let oldToken <- self.ownedNFTs[id] <- token
			
			// Only emit a deposit event if the Collection 
			// is in an account's storage
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			
			// Destroy the empty old token tMaterial was "removed"
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
		
		// borrowNFT Returns a borrowed reference to a Material in the Collection
		// so tMaterial the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		//
		// Note: This only allows the caller to read the ID of the NFT,
		// not an specific data. Please use borrowMaterial to 
		// read Material data.
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(all)
		fun borrowMaterial(id: UInt64): &MaterialNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &MaterialNFT.NFT
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
	// Material contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection creates a new, empty Collection object so that
	// a user can store it in their account storage.
	// Once they have a Collection in their storage, they are able to receive
	// Material in transactions.
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create MaterialNFT.Collection()
	}
	
	// get dictionary of numberMintedPerMaterial
	access(all)
	fun getNumberMintedPerMaterial():{ UInt32: UInt32}{ 
		return MaterialNFT.numberMintedPerMaterial
	}
	
	// get how many Materials with materialDataID are minted 
	access(all)
	fun getMaterialNumberMinted(id: UInt32): UInt32{ 
		let numberMinted = MaterialNFT.numberMintedPerMaterial[id] ?? panic("materialDataID not found")
		return numberMinted
	}
	
	// get the materialData of a specific id
	access(all)
	fun getMaterialData(id: UInt32): MaterialData{ 
		let materialData = MaterialNFT.materialDatas[id] ?? panic("materialDataID not found")
		return materialData
	}
	
	// get all materialDatas created
	access(all)
	fun getMaterialDatas():{ UInt32: MaterialData}{ 
		return MaterialNFT.materialDatas
	}
	
	access(all)
	fun getMaterialDatasRetired():{ UInt32: Bool}{ 
		return MaterialNFT.isMaterialDataRetired
	}
	
	access(all)
	fun getMaterialDataRetired(materialDataID: UInt32): Bool{ 
		let isMaterialDataRetired = MaterialNFT.isMaterialDataRetired[materialDataID] ?? panic("materialDataID not found")
		return isMaterialDataRetired
	}
	
	// -----------------------------------------------------------------------
	// initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		// Initialize contract fields
		self.materialDatas ={} 
		self.numberMintedPerMaterial ={} 
		self.nextMaterialDataID = 1
		self.royaltyPercentage = 0.10
		self.isMaterialDataRetired ={} 
		self.totalSupply = 0
		self.CollectionPublicPath = /public/MaterialCollection0021
		self.CollectionStoragePath = /storage/MaterialCollection0021
		self.AdminStoragePath = /storage/MaterialAdmin0021
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: self.CollectionStoragePath)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{MaterialCollectionPublic}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Put the Minter in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
