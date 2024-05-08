/*
	Description: TheFabricantS2ItemNFT Contract
   
	TheFabricantS2ItemNFT NFTs are mintable by anyone, but requires a combination of 1 
	TheFabricantS2GarmentNFT NFT and 1 TheFabricantS2MaterialNFT NFT.
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import TheFabricantS2GarmentNFT from "./TheFabricantS2GarmentNFT.cdc"

import TheFabricantS2MaterialNFT from "./TheFabricantS2MaterialNFT.cdc"

access(all)
contract TheFabricantS2ItemNFT: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// TheFabricantS2ItemNFT contract Events
	// -----------------------------------------------------------------------
	
	// Emitted when the Item contract is created
	access(all)
	event ContractInitialized()
	
	// Emitted when a new ItemData struct is created
	access(all)
	event ItemDataCreated(itemDataID: UInt32, coCreator: Address, metadatas:{ String: TheFabricantS2ItemNFT.Metadata})
	
	// Emitted when a mutable metadata in an itemData is changed
	access(all)
	event ItemMetadataChanged(itemDataID: UInt32, metadataKey: String, metadataValue: String)
	
	// Emitted when a mutable metadata in an itemData is set to immutable
	access(all)
	event ItemMetadataImmutable(itemDataID: UInt32, metadataKey: String)
	
	// Emitted when an Item is minted
	access(all)
	event ItemMinted(itemID: UInt64, itemDataID: UInt32, serialNumber: UInt32)
	
	// Emitted when an Item's name is changed
	access(all)
	event ItemNameChanged(id: UInt64, name: String)
	
	// Emitted when an ItemData is allocated 
	access(all)
	event ItemDataAllocated(garmentDataID: UInt32, materialDataID: UInt32, primaryColor: String, secondaryColor: String, key: String, itemDataID: UInt32)
	
	// Emitted when the items are set to be splittable
	access(all)
	event ItemNFTNowSplittable()
	
	// Emitted when the number of items with ItemDataID that can be minted changes
	access(all)
	event numberItemDataMintableChanged(itemDataID: UInt32, number: UInt32)
	
	// Emitted when an ItemData is retired
	access(all)
	event ItemDataIDRetired(itemDataID: UInt32)
	
	// Emitted when a color is added to availablePrimaryColors array
	access(all)
	event PrimaryColorAdded(color: String)
	
	// Emitted when a color is added to availableSecondaryColors array
	access(all)
	event SecondaryColorAdded(color: String)
	
	// Emitted when a color is removed from availablePrimaryColors array
	access(all)
	event PrimaryColorRemoved(color: String)
	
	// Emitted when a color is removed from availableSecondaryColors array
	access(all)
	event SecondaryColorRemoved(color: String)
	
	// Events for Collection-related actions
	//
	// Emitted when a Item is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when a Item is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Emitted when a Item is destroyed
	access(all)
	event ItemDestroyed(id: UInt64)
	
	// -----------------------------------------------------------------------
	// contract-level fields.	  
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// itemDataID: number of NFTs with that ItemDataID are minted
	access(self)
	var numberMintedPerItem:{ UInt32: UInt32}
	
	// itemDataID: how many items with itemData can be minted
	access(self)
	var numberMintablePerItemData:{ UInt32: UInt32}
	
	// itemDataID: itemData struct
	access(self)
	var itemDatas:{ UInt32: ItemData}
	
	// concat of garmentDataID_materialDataID_primaryColor_secondaryColor: itemDataID (eg. 1_1_FFFFFF_000000)
	access(self)
	var itemDataAllocation:{ String: UInt32}
	
	// itemDataID: whether item with ItemDataID cannot be minted anymore
	access(self)
	var isItemDataRetired:{ UInt32: Bool}
	
	// Dictionary of the nft with id and its current owner address
	access(self)
	var nftIDToOwner:{ UInt64: Address}
	
	// array of available primaryColors
	access(self)
	var availablePrimaryColors: [String]
	
	// array of available secondaryColors
	access(self)
	var availableSecondaryColors: [String]
	
	// Keeps track of how many unique ItemDatas are created
	access(all)
	var nextItemDataID: UInt32
	
	// Keeps track of how many unique ItemDataAllocations are created
	access(all)
	var nextItemDataAllocation: UInt32
	
	// Are garment and material removable from item
	access(all)
	var isSplittable: Bool
	
	access(all)
	var totalSupply: UInt64
	
	// metadata of an ItemData struct that contains the metadata value
	// and whether it is mutable
	access(all)
	struct Metadata{ 
		access(all)
		var metadataValue: String
		
		access(all)
		var mutable: Bool
		
		init(metadataValue: String, mutable: Bool){ 
			self.metadataValue = metadataValue
			self.mutable = mutable
		}
		
		access(all)
		fun setMetadataImmutable(){ 
			pre{ 
				self.mutable == true:
					"metadata is already immutable"
			}
			self.mutable = false
		}
		
		access(all)
		fun setMetadataValue(metadataValue: String){ 
			pre{ 
				self.mutable == true:
					"metadata is already immutable"
			}
			self.metadataValue = metadataValue
		}
	}
	
	access(all)
	struct ItemData{ 
		
		// The unique ID for the Item Data
		access(all)
		let itemDataID: UInt32
		
		// stores link to image
		// the address of the user who created the unique combination
		access(all)
		let coCreator: Address
		
		// other metadata
		access(self)
		let metadatas:{ String: TheFabricantS2ItemNFT.Metadata}
		
		init(coCreator: Address, metadatas:{ String: TheFabricantS2ItemNFT.Metadata}){ 
			self.itemDataID = TheFabricantS2ItemNFT.nextItemDataID
			self.coCreator = coCreator
			self.metadatas = metadatas
			TheFabricantS2ItemNFT.isItemDataRetired[self.itemDataID] = false
			
			// set default number mintable of itemData to 1
			TheFabricantS2ItemNFT.numberMintablePerItemData[self.itemDataID] = 1
			
			// Increment the ID so that it isn't used again
			TheFabricantS2ItemNFT.nextItemDataID = TheFabricantS2ItemNFT.nextItemDataID + 1 as UInt32
			emit ItemDataCreated(itemDataID: self.itemDataID, coCreator: self.coCreator, metadatas: self.metadatas)
		}
		
		// change a mutable metadata in the metadata struct
		access(all)
		fun setMetadata(metadataKey: String, metadataValue: String){ 
			(self.metadatas[metadataKey]!).setMetadataValue(metadataValue: metadataValue)
			emit ItemMetadataChanged(itemDataID: self.itemDataID, metadataKey: metadataKey, metadataValue: metadataValue)
		}
		
		// prevent changing of a metadata in the metadata struct
		access(all)
		fun setMetadataKeyImmutable(metadataKey: String){ 
			(self.metadatas[metadataKey]!).setMetadataImmutable()
			emit ItemMetadataImmutable(itemDataID: self.itemDataID, metadataKey: metadataKey)
		}
		
		access(all)
		fun getMetadata():{ String: TheFabricantS2ItemNFT.Metadata}{ 
			return self.metadatas
		}
	}
	
	access(all)
	struct Item{ 
		
		// The ID of the itemData that the item references
		access(all)
		let itemDataID: UInt32
		
		// The N'th NFT with 'ItemDataID' minted
		access(all)
		let serialNumber: UInt32
		
		init(itemDataID: UInt32){ 
			pre{ 
				Int(TheFabricantS2ItemNFT.numberMintedPerItem[itemDataID]!) < Int(TheFabricantS2ItemNFT.numberMintablePerItemData[itemDataID]!):
					"maximum number of TheFabricantS2ItemNFT with itemDataID reached"
			}
			self.itemDataID = itemDataID
			
			// Increment the ID so that it isn't used again
			TheFabricantS2ItemNFT.numberMintedPerItem[itemDataID] = TheFabricantS2ItemNFT.numberMintedPerItem[itemDataID]! + 1 as UInt32
			self.serialNumber = TheFabricantS2ItemNFT.numberMintedPerItem[itemDataID]!
		}
	}
	
	// Royalty struct that each TheFabricantS2ItemNFT will contain
	access(all)
	struct Royalty{ 
		access(all)
		let wallet: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let initialCut: UFix64
		
		access(all)
		let cut: UFix64
		
		/// @param wallet : The wallet to send royalty too
		init(wallet: Capability<&{FungibleToken.Receiver}>, initialCut: UFix64, cut: UFix64){ 
			self.wallet = wallet
			self.initialCut = initialCut
			self.cut = cut
		}
	}
	
	// The resource that represents the Item NFTs
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		
		// Global unique Item ID
		access(all)
		let id: UInt64
		
		// struct of Item
		access(all)
		let item: Item
		
		// name of nft, can be changed
		access(all)
		var name: String
		
		// Royalty struct
		access(all)
		let royaltyVault: TheFabricantS2ItemNFT.Royalty
		
		// after you remove the garment and material from the item, the TheFabricantS2ItemNFT will be considered "dead". 
		// accounts will be unable to deposit, withdraw or call functions of the nft.
		access(all)
		var isDead: Bool
		
		// this is where the garment nft is stored, it cannot be moved out
		access(self)
		var garment: @TheFabricantS2GarmentNFT.NFT?
		
		// this is where the material nft is stored, it cannot be moved out
		access(self)
		var material: @TheFabricantS2MaterialNFT.NFT?
		
		init(serialNumber: UInt32, name: String, itemDataID: UInt32, royaltyVault: TheFabricantS2ItemNFT.Royalty, garment: @TheFabricantS2GarmentNFT.NFT, material: @TheFabricantS2MaterialNFT.NFT){ 
			TheFabricantS2ItemNFT.totalSupply = TheFabricantS2ItemNFT.totalSupply + 1 as UInt64
			self.id = TheFabricantS2ItemNFT.totalSupply
			self.name = name
			self.royaltyVault = royaltyVault
			self.isDead = false
			self.garment <- garment
			self.material <- material
			self.item = Item(itemDataID: itemDataID)
			
			// Emitted when a Item is minted
			emit ItemMinted(itemID: self.id, itemDataID: itemDataID, serialNumber: serialNumber)
		}
		
		//Make Item considered dead. Deposit garment and material to respective vaults
		access(contract)
		fun split(garmentCap: Capability<&{TheFabricantS2GarmentNFT.GarmentCollectionPublic}>, materialCap: Capability<&{TheFabricantS2MaterialNFT.MaterialCollectionPublic}>){ 
			pre{ 
				!self.isDead:
					"Cannot split. Item is dead"
				TheFabricantS2ItemNFT.isSplittable:
					"Item is set to unsplittable"
				garmentCap.check():
					"Garment Capability is invalid"
				materialCap.check():
					"Material Capability is invalid"
			}
			let garmentOptional <- self.garment <- nil
			let materialOptional <- self.material <- nil
			let garmentRecipient = garmentCap.borrow()!
			let materialRecipient = materialCap.borrow()!
			let garment <- garmentOptional!
			let material <- materialOptional!
			let garmentNFT <- garment as!{ NonFungibleToken.NFT}
			let materialNFT <- material as!{ NonFungibleToken.NFT}
			garmentRecipient.deposit(token: <-garmentNFT)
			materialRecipient.deposit(token: <-materialNFT)
			TheFabricantS2ItemNFT.numberMintedPerItem[self.item.itemDataID] = TheFabricantS2ItemNFT.numberMintedPerItem[self.item.itemDataID]! - 1 as UInt32
			self.isDead = true
		}
		
		// get a reference to the garment that item stores
		access(all)
		fun borrowGarment(): &TheFabricantS2GarmentNFT.NFT?{ 
			let garmentOptional <- self.garment <- nil
			let garment <- garmentOptional!
			let garmentRef = &garment as &TheFabricantS2GarmentNFT.NFT
			self.garment <-! garment
			return garmentRef
		}
		
		// get a reference to the material that item stores
		access(all)
		fun borrowMaterial(): &TheFabricantS2MaterialNFT.NFT?{ 
			let materialOptional <- self.material <- nil
			let material <- materialOptional!
			let materialRef = &material as &TheFabricantS2MaterialNFT.NFT
			self.material <-! material
			return materialRef
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	//destroy item if it is considered dead
	access(all)
	fun cleanDeadItems(item: @TheFabricantS2ItemNFT.NFT){ 
		pre{ 
			item.isDead:
				"Cannot destroy, item not dead"
		}
		destroy item
	}
	
	// mint the NFT, based on a combination of garment, material, primaryColor and secondaryColor. 
	// The itemData that is used to mint the Item is based on the garment and material' garmentDataID and materialDataID
	access(all)
	fun mintNFT(name: String, royaltyVault: TheFabricantS2ItemNFT.Royalty, garment: @TheFabricantS2GarmentNFT.NFT, material: @TheFabricantS2MaterialNFT.NFT, primaryColor: String, secondaryColor: String): @NFT{ 
		let garmentDataID = garment.garment.garmentDataID
		let materialDataID = material.material.materialDataID
		let key = TheFabricantS2ItemNFT.getUniqueString(garmentDataID: garmentDataID, materialDataID: materialDataID, primaryColor: primaryColor, secondaryColor: secondaryColor)
		
		//check whether unique combination is allocated
		let itemDataID = TheFabricantS2ItemNFT.itemDataAllocation[key] ?? panic("Cannot mint Item. ItemData not found")
		
		//check whether itemdata is retired
		if TheFabricantS2ItemNFT.isItemDataRetired[itemDataID]!{ 
			panic("Cannot mint Item. ItemDataID retired")
		}
		let numInItem = TheFabricantS2ItemNFT.numberMintedPerItem[itemDataID] ?? panic("Maximum number of Items with itemDataID minted")
		let item <- create NFT(serialNumber: numInItem + 1, name: name, itemDataID: itemDataID, royaltyVault: royaltyVault, garment: <-garment, material: <-material)
		return <-item
	}
	
	// This is the interface that users can cast their Item Collection as
	// to allow others to deposit Items into their Collection. It also allows for reading
	// the IDs of Items in the Collection.
	access(all)
	resource interface ItemCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowItem(id: UInt64): &TheFabricantS2ItemNFT.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Item reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection is a resource that every user who owns NFTs 
	// will store in their account to manage their NFTS
	//
	access(all)
	resource Collection: ItemCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// Dictionary of Item conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(all)
		fun split(id: UInt64, garmentCap: Capability<&{TheFabricantS2GarmentNFT.GarmentCollectionPublic}>, materialCap: Capability<&{TheFabricantS2MaterialNFT.MaterialCollectionPublic}>){ 
			let token <- self.ownedNFTs.remove(key: id) ?? panic("Cannot withdraw: Item does not exist in the collection")
			let item <- token as! @TheFabricantS2ItemNFT.NFT
			item.split(garmentCap: garmentCap, materialCap: materialCap)
			self.ownedNFTs[id] <-! item
		}
		
		// withdraw removes an Item from the Collection and moves it to the caller
		//
		// Parameters: withdrawID: The ID of the NFT 
		// that is to be removed from the Collection
		//
		// returns: @NonFungibleToken.NFT the token that was withdrawn
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Item does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			
			// Return the withdrawn token
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: ids: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: A collection that contains
		//										the withdrawn Items
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
		
		// deposit takes a Item and adds it to the Collections dictionary
		//
		// Paramters: token: the NFT to be deposited in the collection
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			//todo: someFunction that transfers royalty
			// Cast the deposited token as  NFT to make sure
			// it is the correct type
			let token <- token as! @TheFabricantS2ItemNFT.NFT
			
			// Get the token's ID
			let id = token.id
			
			// Add the new token to the dictionary
			let oldToken <- self.ownedNFTs[id] <- token
			
			// Set the global mapping of nft id to new owner
			TheFabricantS2ItemNFT.nftIDToOwner[id] = self.owner?.address
			
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
		
		// borrowNFT Returns a borrowed reference to a Item in the Collection
		// so that the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		//
		// Note: This only allows the caller to read the ID of the NFT,
		// not an specific data. Please use borrowItem to 
		// read Item data.
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(all)
		fun borrowItem(id: UInt64): &TheFabricantS2ItemNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &TheFabricantS2ItemNFT.NFT
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
	
	// Admin is a special authorization resource that 
	// allows the owner to perform important functions to modify the 
	// various aspects of the Items and NFTs
	//
	access(all)
	resource Admin{ 
		
		// create itemdataid allocation based on the 
		// garmentDataID, materialDataID, primaryColor and secondaryColor
		// and create an itemdata struct based on it
		access(all)
		fun createItemDataWithAllocation(garmentDataID: UInt32, materialDataID: UInt32, primaryColor: String, secondaryColor: String, metadatas:{ String: TheFabricantS2ItemNFT.Metadata}, coCreator: Address): UInt32{ 
			
			// check whether colors are valid colors
			pre{ 
				TheFabricantS2ItemNFT.availablePrimaryColors.contains(primaryColor):
					"PrimaryColor not available"
				TheFabricantS2ItemNFT.availableSecondaryColors.contains(secondaryColor):
					"SecondaryColor not available"
				TheFabricantS2GarmentNFT.getGarmentDatas().containsKey(garmentDataID):
					"GarmentData not found"
				TheFabricantS2MaterialNFT.getMaterialDatas().containsKey(materialDataID):
					"MaterialData not found"
			}
			// set the primaryColor and secondaryColor metadata of Metadata struct
			metadatas["primaryColor"] = TheFabricantS2ItemNFT.Metadata(metadataValue: primaryColor, mutable: false)
			metadatas["secondaryColor"] = TheFabricantS2ItemNFT.Metadata(metadataValue: secondaryColor, mutable: false)
			
			// check whether unique combination is allocated already
			let key = TheFabricantS2ItemNFT.getUniqueString(garmentDataID: garmentDataID, materialDataID: materialDataID, primaryColor: primaryColor, secondaryColor: secondaryColor)
			if TheFabricantS2ItemNFT.itemDataAllocation.containsKey(key){ 
				panic("Item already allocated")
			}
			
			// set unique combination's itemdataallocation, then increment nextItemDataAllocation
			TheFabricantS2ItemNFT.itemDataAllocation[key] = TheFabricantS2ItemNFT.nextItemDataAllocation
			emit ItemDataAllocated(garmentDataID: garmentDataID, materialDataID: materialDataID, primaryColor: primaryColor, secondaryColor: secondaryColor, key: key, itemDataID: TheFabricantS2ItemNFT.nextItemDataAllocation)
			TheFabricantS2ItemNFT.nextItemDataAllocation = TheFabricantS2ItemNFT.nextItemDataAllocation + 1 as UInt32
			
			// create new itemData 
			var newItem = ItemData(coCreator: coCreator, metadatas: metadatas)
			
			// Store it in the contract storage
			let newID = newItem.itemDataID
			TheFabricantS2ItemNFT.itemDatas[newID] = newItem
			TheFabricantS2ItemNFT.numberMintedPerItem[newID] = 0 as UInt32
			return newID
		}
		
		// change the metadatavalue of an itemData
		access(all)
		fun setMetadata(itemDataID: UInt32, metadataKey: String, metadataValue: String){ 
			let itemDataTemp = TheFabricantS2ItemNFT.itemDatas[itemDataID]!
			itemDataTemp.setMetadata(metadataKey: metadataKey, metadataValue: metadataValue)
			TheFabricantS2ItemNFT.itemDatas[itemDataID] = itemDataTemp
		}
		
		// make the metadatavalue of an itemData immutable
		access(all)
		fun setMetadataImmutable(itemData: UInt32, metadataKey: String){ 
			let itemDataTemp = TheFabricantS2ItemNFT.itemDatas[itemData]!
			itemDataTemp.setMetadataKeyImmutable(metadataKey: metadataKey)
			TheFabricantS2ItemNFT.itemDatas[itemData] = itemDataTemp
		}
		
		// add the primaryColor to array of availablePrimaryColors
		access(all)
		fun addPrimaryColor(color: String){ 
			pre{ 
				!TheFabricantS2ItemNFT.availablePrimaryColors.contains(color):
					"availablePrimaryColors already has color"
			}
			TheFabricantS2ItemNFT.availablePrimaryColors.append(color)
			emit PrimaryColorAdded(color: color)
		}
		
		// add the primaryColor to array of availablePrimaryColors
		access(all)
		fun addSecondaryColor(color: String){ 
			pre{ 
				!TheFabricantS2ItemNFT.availableSecondaryColors.contains(color):
					"availableSecondaryColors does not contain color"
			}
			TheFabricantS2ItemNFT.availableSecondaryColors.append(color)
			emit SecondaryColorAdded(color: color)
		}
		
		// add the primaryColor to array of availablePrimaryColors
		access(all)
		fun removePrimaryColor(color: String){ 
			pre{ 
				TheFabricantS2ItemNFT.availablePrimaryColors.contains(color):
					"availablePrimaryColors does not contain color"
			}
			var index = 0
			for primaryColor in TheFabricantS2ItemNFT.availablePrimaryColors{ 
				if primaryColor == color{ 
					TheFabricantS2ItemNFT.availablePrimaryColors.remove(at: index)
				} else{ 
					index = index + 1
				}
			}
			emit PrimaryColorRemoved(color: color)
		}
		
		// add the primaryColor to array of availablePrimaryColors
		access(all)
		fun removeSecondaryColor(color: String){ 
			pre{ 
				TheFabricantS2ItemNFT.availableSecondaryColors.contains(color):
					"availableSecondaryColors already has color"
			}
			var index = 0
			for secondaryColor in TheFabricantS2ItemNFT.availableSecondaryColors{ 
				if secondaryColor == color{ 
					TheFabricantS2ItemNFT.availableSecondaryColors.remove(at: index)
				} else{ 
					index = index + 1
				}
			}
			emit SecondaryColorRemoved(color: color)
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
		
		// Change the royalty percentage of the contract
		access(all)
		fun makeSplittable(){ 
			TheFabricantS2ItemNFT.isSplittable = true
			emit ItemNFTNowSplittable()
		}
		
		// Change the number of itemdata mintable
		access(all)
		fun changeItemDataNumberMintable(itemDataID: UInt32, number: UInt32){ 
			TheFabricantS2ItemNFT.numberMintablePerItemData[itemDataID] = number
			emit numberItemDataMintableChanged(itemDataID: itemDataID, number: number)
		}
		
		// Retire itemData so that it cannot be used to mint anymore
		access(all)
		fun retireItemData(itemDataID: UInt32){ 
			pre{ 
				TheFabricantS2ItemNFT.isItemDataRetired[itemDataID] != nil:
					"Cannot retire item: Item doesn't exist!"
			}
			if !TheFabricantS2ItemNFT.isItemDataRetired[itemDataID]!{ 
				TheFabricantS2ItemNFT.isItemDataRetired[itemDataID] = true
				emit ItemDataIDRetired(itemDataID: itemDataID)
			}
		}
	}
	
	// -----------------------------------------------------------------------
	// Item contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection creates a new, empty Collection object so that
	// a user can store it in their account storage.
	// Once they have a Collection in their storage, they are able to receive
	// Items in transactions.
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create TheFabricantS2ItemNFT.Collection()
	}
	
	// get dictionary of numberMintedPerItem
	access(all)
	fun getNumberMintedPerItem():{ UInt32: UInt32}{ 
		return TheFabricantS2ItemNFT.numberMintedPerItem
	}
	
	// get how many Items with itemDataID are minted 
	access(all)
	fun getItemNumberMinted(id: UInt32): UInt32{ 
		let numberMinted = TheFabricantS2ItemNFT.numberMintedPerItem[id] ?? panic("itemDataID not found")
		return numberMinted
	}
	
	// get the ItemData of a specific id
	access(all)
	fun getItemData(id: UInt32): ItemData{ 
		let itemData = TheFabricantS2ItemNFT.itemDatas[id] ?? panic("itemDataID not found")
		return itemData
	}
	
	// get the map of item data allocations
	access(all)
	fun getItemDataAllocations():{ String: UInt32}{ 
		let itemDataAllocation = TheFabricantS2ItemNFT.itemDataAllocation
		return itemDataAllocation
	}
	
	// get the itemData allocation from the garment and material dataID
	access(all)
	fun getItemDataAllocation(garmentDataID: UInt32, materialDataID: UInt32, primaryColor: String, secondaryColor: String): UInt32{ 
		let itemDataAllocation = TheFabricantS2ItemNFT.itemDataAllocation[TheFabricantS2ItemNFT.getUniqueString(garmentDataID: garmentDataID, materialDataID: materialDataID, primaryColor: primaryColor, secondaryColor: secondaryColor)] ?? panic("garment and material dataID pair not allocated")
		return itemDataAllocation
	}
	
	// get all ItemDatas created
	access(all)
	fun getItemDatas():{ UInt32: ItemData}{ 
		return TheFabricantS2ItemNFT.itemDatas
	}
	
	access(all)
	fun getAvailablePrimaryColors(): [String]{ 
		return TheFabricantS2ItemNFT.availablePrimaryColors
	}
	
	access(all)
	fun getAvailableSecondaryColors(): [String]{ 
		return TheFabricantS2ItemNFT.availableSecondaryColors
	}
	
	// get dictionary of itemdataids and whether they are retired
	access(all)
	fun getItemDatasRetired():{ UInt32: Bool}{ 
		return TheFabricantS2ItemNFT.isItemDataRetired
	}
	
	// get bool of if itemdataid is retired
	access(all)
	fun getItemDataRetired(itemDataID: UInt32): Bool?{ 
		return TheFabricantS2ItemNFT.isItemDataRetired[itemDataID]!
	}
	
	access(all)
	fun getUniqueString(garmentDataID: UInt32, materialDataID: UInt32, primaryColor: String, secondaryColor: String): String{ 
		return garmentDataID.toString().concat("_").concat(materialDataID.toString()).concat("_").concat(primaryColor).concat("_").concat(secondaryColor)
	}
	
	access(all)
	fun getNumberMintablePerItemData():{ UInt32: UInt32}{ 
		return TheFabricantS2ItemNFT.numberMintablePerItemData
	}
	
	access(all)
	fun getNftIdToOwner():{ UInt64: Address}{ 
		return TheFabricantS2ItemNFT.nftIDToOwner
	}
	
	// -----------------------------------------------------------------------
	// initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		self.itemDatas ={} 
		self.itemDataAllocation ={} 
		self.numberMintedPerItem ={} 
		self.numberMintablePerItemData ={} 
		self.nextItemDataID = 1
		self.nextItemDataAllocation = 1
		self.isSplittable = false
		self.isItemDataRetired ={} 
		self.nftIDToOwner ={} 
		self.totalSupply = 0
		self.availablePrimaryColors = []
		self.availableSecondaryColors = []
		self.CollectionPublicPath = /public/S2ItemCollection0028
		self.CollectionStoragePath = /storage/S2ItemCollection0028
		self.AdminStoragePath = /storage/S2ItemAdmin0028
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: self.CollectionStoragePath)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{ItemCollectionPublic}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Put the Minter in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
