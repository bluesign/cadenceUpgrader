// Gear.cdc
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract Gear_1: NonFungibleToken{ 
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event GearSKUCreated(skuId: UInt64)
	
	access(all)
	event GearSKUUpdated(skuId: UInt64)
	
	access(all)
	event TokenBaseURISet(newBaseURI: String)
	
	access(all)
	event Updated(id: UInt64, charge: UInt16, play: UInt16)
	
	access(all)
	event Minted(skuId: UInt64, id: UInt64)
	
	access(all)
	event Burned(skuId: UInt64, id: UInt64)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	// totalSupply
	// The total number of Gears that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// totalSKUCount
	// The total number of Gear SKUs that have been created
	//
	access(all)
	var totalSKUCount: UInt64
	
	// dictionary of gear SKU
	// SKU is a resource type with an `UInt64` ID field and `Dictionary` metadata field
	//
	access(all)
	var gearSKUs:{ UInt64: GearSKU}
	
	// baseURI
	//
	access(all)
	var baseURI: String
	
	// NFT
	// A Gear as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		//
		access(all)
		let id: UInt64
		
		// The Gear SKU's ID
		//
		access(all)
		let skuId: UInt64
		
		// The Gear's charge level
		//
		access(all)
		var charge: UInt16
		
		// The Gear's number of plays
		//
		access(all)
		var numberOfPlays: UInt16
		
		// initializer
		//
		init(initID: UInt64, skuID: UInt64){ 
			pre{ 
				skuID >= 0 && skuID < Gear_1.totalSKUCount:
					"Cannot mint NFT with invalid SKU"
			}
			self.id = initID
			self.skuId = skuID
			self.charge = 0
			self.numberOfPlays = 0
		}
		
		access(all)
		fun updateInfo(newCharge: UInt16, newPlays: UInt16){ 
			self.charge = newCharge
			self.numberOfPlays = newPlays
		}
		
		access(all)
		fun increasePlays(newPlays: UInt16){ 
			self.numberOfPlays = self.numberOfPlays + newPlays
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// GearSKU
	// A Gear SKU
	//
	access(all)
	struct GearSKU{ 
		// The Gear SKU's ID
		//
		access(all)
		let id: UInt64
		
		// totalSupply
		// The total number of Gears that have been minted in this SKU
		//
		access(all)
		var totalSupply: UInt64
		
		// The Gear SKU's metadata - a Dictionary
		// of key-value pairs describing all intrinsic metadata
		// which make each Gear SKU unique
		//
		access(all)
		let metadata:{ UInt16: String}
		
		// initializer
		//
		init(initID: UInt64, metadata:{ UInt16: String}){ 
			self.id = initID
			self.totalSupply = 0
			self.metadata = metadata
		}
		
		// Upgrade the Gear SKU's metadata by the metadata upgrade resource passed in.
		// The upgrade resource can only be created by authorized accounts,
		// such as an administrator or authorized operators.
		//
		access(all)
		fun upgrade(newMetadata:{ UInt16: String}){ 
			pre{ 
				newMetadata != nil:
					"Cannot upgrade SKU until the new metadata is created"
				self.totalSupply == 0:
					"Cannot upgrade SKU metadata when NFTs are minted in"
			}
			for key in newMetadata.keys{ 
				self.metadata[key] = newMetadata[key]!
			}
		}
		
		access(all)
		fun increaseSupply(){ 
			self.totalSupply = self.totalSupply + 1 as UInt64
		}
		
		access(all)
		fun decreaseSupply(){ 
			self.totalSupply = self.totalSupply - 1 as UInt64
		}
	}
	
	// Admin is a special authorization resource that allows the owner
	// to create or update SKUs and to manage baseURI
	//
	access(all)
	resource Admin{ 
		access(all)
		fun setBaseURI(newBaseURI: String){ 
			Gear_1.baseURI = newBaseURI
			emit TokenBaseURISet(newBaseURI: newBaseURI)
		}
		
		access(all)
		fun createSKU(metadata:{ UInt16: String}){ 
			let skuId = Gear_1.totalSKUCount
			let sku = Gear_1.GearSKU(initID: skuId, metadata: metadata)
			Gear_1.gearSKUs[skuId] = sku
			Gear_1.totalSKUCount = skuId + 1 as UInt64
			emit GearSKUCreated(skuId: skuId)
		}
		
		access(all)
		fun upgradeSKU(skuId: UInt64, metadata:{ UInt16: String}){ 
			var sku = Gear_1.gearSKUs[skuId] ?? panic("missing Gear SKU")
			sku.upgrade(newMetadata: metadata)
			Gear_1.gearSKUs[skuId] = sku
			emit GearSKUUpdated(skuId: skuId)
		}
		
		// updateGearInfo
		// Updates a Gear NFT with a new charge and number of plays
		//
		access(all)
		fun updateGearInfo(recipient: &{Gear_1.GearCollectionPublic}, tokenIds: [UInt64], newCharges: [UInt16], newPlays: [UInt16]){ 
			pre{ 
				tokenIds.length == newCharges.length:
					"Invalid arguments length"
				tokenIds.length == newPlays.length:
					"Invalid arguments length"
			}
			var i = 0
			while i < tokenIds.length{ 
				let token <- recipient.withdraw(withdrawID: tokenIds[i])
				let ref <- token as! @Gear_1.NFT
				ref.updateInfo(newCharge: newCharges[i], newPlays: newPlays[i])
				recipient.deposit(token: <-ref)
				emit Updated(id: tokenIds[i], charge: newCharges[i], play: newPlays[i])
				i = i + 1
			}
		}
		
		// increaseNumberOfPlays
		// Increases number of plays (add with original one)
		//
		access(all)
		fun increaseNumberOfPlays(recipient: &{Gear_1.GearCollectionPublic}, tokenIds: [UInt64], newPlays: [UInt16]){ 
			pre{ 
				tokenIds.length == newPlays.length:
					"Invalid arguments length"
			}
			var i = 0
			while i < tokenIds.length{ 
				let token <- recipient.withdraw(withdrawID: tokenIds[i])
				let ref <- token as! @Gear_1.NFT
				ref.increasePlays(newPlays: newPlays[i])
				var charge = ref.charge
				var numberOfPlays = ref.numberOfPlays
				recipient.deposit(token: <-ref)
				emit Updated(id: tokenIds[i], charge: charge, play: numberOfPlays)
				i = i + 1
			}
		}
	}
	
	// This is the interface that users can cast their Gear Collection as
	// to allow others to deposit Gears into their Collection. It also allows for reading
	// the details of Gears in the Collection.
	//
	access(all)
	resource interface GearCollectionPublic{ 
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}
		
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}
		
		access(all)
		fun burnGear(tokenId: UInt64)
		
		access(all)
		fun batchBurnGears(tokenIdList: [UInt64])
		
		access(all)
		fun borrowGear(id: UInt64): &Gear_1.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Gear reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of Gear NFTs owned by an account
	//
	access(all)
	resource Collection: GearCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// getIDs
		// Returns an array of the IDs that are in the collection
		//
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let ref <- token as! @Gear_1.NFT
			let id: UInt64 = ref.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- ref
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// batchDeposit takes a Collection object as an argument
		// and deposits each contained NFT into this Collection
		//
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
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// batchWithdraw withdraws multiple NFTs and returns them as a Collection
		//
		// Parameters: ids: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: The collection of withdrawn tokens
		//
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			// Create a new empty Collection
			var collection <- create Collection()
			
			// Iterate through the ids and withdraw them from the Collection
			for id in ids{ 
				collection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			
			// Return the withdrawn tokens
			return <-collection
		}
		
		// burnGear
		// Burns a Gear NFT
		// and withdraws it from the recipients collection using their collection reference
		//
		access(all)
		fun burnGear(tokenId: UInt64){ 
			// withdraw it from the recipient's account using their reference
			let token <- self.ownedNFTs.remove(key: tokenId) ?? panic("missing NFT")
			let gearNFT <- token as! @Gear_1.NFT
			var sku = Gear_1.gearSKUs.remove(key: gearNFT.skuId) ?? panic("missing Gear SKU")
			sku.decreaseSupply()
			Gear_1.gearSKUs[gearNFT.skuId] = sku
			Gear_1.totalSupply = Gear_1.totalSupply - 1 as UInt64
			emit Burned(skuId: gearNFT.skuId, id: tokenId)
			destroy gearNFT
		}
		
		// batchBurnGears
		// Burns multiple Gear NFTs given a list of tokenIds
		// and withdraws the NFTs from the recipients collection using their collection reference
		//
		access(all)
		fun batchBurnGears(tokenIdList: [UInt64]){ 
			for tokenId in tokenIdList{ 
				// withdraw it from the recipient's account using their reference
				self.burnGear(tokenId: tokenId)
			}
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowGear
		// Gets a reference to an NFT in the collection as a Gear,
		// exposing all of its fields (including the Gear attributes).
		// This is safe as there are no functions that can be called on the Gear.
		//
		access(all)
		fun borrowGear(id: UInt64): &Gear_1.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Gear_1.NFT
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
		
		// destructor
		//
		// initializer
		//
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// NFTMinter
	// Resource that allows an admin to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		// mintGear
		// Mints a new Gear NFT with a new ID
		// and deposits it in the recipients collection using their collection reference
		//
		access(all)
		fun mintGear(recipient: &{NonFungibleToken.CollectionPublic}, skuID: UInt64): UInt64{ 
			let id = Gear_1.totalSupply
			let sku = Gear_1.gearSKUs[skuID] ?? panic("missing Gear SKU")
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create Gear_1.NFT(initID: id, skuID: skuID))
			sku.increaseSupply()
			Gear_1.gearSKUs[skuID] = sku
			Gear_1.totalSupply = id + 1 as UInt64
			emit Minted(skuId: skuID, id: id)
			return id
		}
		
		// batchMintGears
		// Mints multiple new Gear NFTs given a list of Gear metadata
		// and deposits the NFTs into the recipients collection using their collection reference
		//
		access(all)
		fun batchMintGears(recipient: &{NonFungibleToken.CollectionPublic}, skuIDList: [UInt64]): [UInt64]{ 
			let ids: [UInt64] = []
			for skuID in skuIDList{ 
				// deposit it in the recipient's account using their reference
				ids.append(self.mintGear(recipient: recipient, skuID: skuID))
			}
			return ids
		}
	}
	
	// fetch
	// Get a reference to a Gear from an account's Collection, if available.
	// If an account does not have a Gear_1.Collection, panic.
	// If it has a collection but does not contain the gearId, return nil.
	// If it has a collection and that collection contains the gearId, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, gearId: UInt64): &Gear_1.NFT?{ 
		let collection = getAccount(from).capabilities.get<&Gear_1.Collection>(Gear_1.CollectionPublicPath).borrow<&Gear_1.Collection>() ?? panic("Couldn't get collection")
		// We trust Gear_1.Collection.borowGear to get the correct gearId
		// (it checks it before returning it).
		return collection.borrowGear(id: gearId)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/GearCollection_1
		self.CollectionPublicPath = /public/GearCollection_1
		self.MinterStoragePath = /storage/GearMinter_1
		self.AdminStoragePath = /storage/GearAdmin_1
		self.AdminPrivatePath = /private/GearAdminUpgrade_1
		
		// Initialize the total supply
		self.totalSupply = 0
		self.totalSKUCount = 0
		self.gearSKUs ={} 
		self.baseURI = ""
		
		// Create a Minter resource and save it to admin storage
		self.account.storage.save(<-create NFTMinter(), to: self.MinterStoragePath)
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Gear_1.Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath) ?? panic("Could not get a capmetadata to the admin")
		emit ContractInitialized()
	}
}
