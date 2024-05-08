import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import IrVoucher from "./IrVoucher.cdc"

// The IN|RIFT Contract
//
// There are multiple levels of entity:
// - IrBrand, a Brand associated with or owned by IN|RIFT
// - IrCollection, a IN|RIFT Collection including multiple Items & Drops
// - IrItem, a IN|RIFT Item, part of IrCollection & IrDrop, used to mint NFTs
//   - IrItemAsset, providing rich structute for Item Assets
// - NFT, the actual IN|RIFT item as NFT
// 
// Took a lot inspiration of the TopShot, Genies etc. contracts
//
access(all)
contract IrNFT: NonFungibleToken{ 
	
	//------------------------------------------------------------
	// Events
	//------------------------------------------------------------
	
	// Contract Events
	//
	access(all)
	event ContractInitialized()
	
	// NFT Collection Events (inherited from NonFungibleToken)
	//
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Brand Events
	//
	access(all)
	event BrandCreated(id: UInt32, name: String)
	
	// Collection Events
	//
	access(all)
	event CollectionCreated(id: UInt32, brandIDs: [UInt32], name: String)
	
	access(all)
	event CollectionItemAdded(id: UInt32, itemID: UInt32)
	
	access(all)
	event CollectionDropAdded(id: UInt32, dropID: UInt32)
	
	access(all)
	event CollectionClosed(id: UInt32)
	
	// Item Events
	//
	access(all)
	event ItemCreated(id: UInt32, collectionID: UInt32, name: String)
	
	access(all)
	event ItemRetired(id: UInt32, collectionID: UInt32, name: String)
	
	// Voucher Events
	//
	access(all)
	event VoucherPurchased(id: UInt64, collectionID: UInt32, dropID: UInt32, by: Address)
	
	access(all)
	event VoucherGifted(id: UInt64, collectionID: UInt32, dropID: UInt32, by: Address)
	
	access(all)
	event VoucherRedeemed(id: UInt64, collectionID: UInt32, dropID: UInt32, nftID: UInt64, by: Address)
	
	// NFT Events
	//
	access(all)
	event NFTMinted(id: UInt64, collectionID: UInt32, itemID: UInt32, serial: UInt32)
	
	access(all)
	event NFTBurned(id: UInt64)
	
	//------------------------------------------------------------
	// Named Values
	//------------------------------------------------------------
	// Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	//------------------------------------------------------------
	// Public Contract State
	//------------------------------------------------------------
	// Entity Counts
	//
	access(all)
	var nextBrandID: UInt32
	
	access(all)
	var nextCollectionID: UInt32
	
	access(all)
	var nextItemID: UInt32
	
	access(all)
	var nextDropID: UInt32
	
	access(all)
	var totalSupply: UInt64 // (inherited from NonFungibleToken)
	
	
	// Enumns & Helpers
	//
	access(all)
	enum IrRarity: UInt8{ 
		access(all)
		case UNIQUE
		
		access(all)
		case LEGENDARY
		
		access(all)
		case EPIC
		
		access(all)
		case RARE
		
		access(all)
		case COMMON
	}
	
	access(self)
	var rarityMaxSupply:{ IrRarity: UInt64}
	
	access(self)
	var rarityDefault: IrRarity
	
	//------------------------------------------------------------
	// Private Contract State
	//------------------------------------------------------------
	// Metadata Dictionaries
	//
	access(self)
	var brands: @{UInt32: IrBrand}
	
	access(self)
	var brandIDsByName:{ String: UInt32}
	
	access(self)
	var collections: @{UInt32: IrCollection}
	
	access(self)
	var collectionIDsByName:{ String: UInt32}
	
	access(self)
	var items: @{UInt32: IrItem}
	
	access(self)
	var drops: @{UInt32: IrDrop}
	
	access(self)
	var activeDrops: [UInt32]
	
	//------------------------------------------------------------
	// Brands
	//------------------------------------------------------------
	// A public struct to access Beries data
	//
	access(all)
	struct IrBrandData{ 
		access(all)
		let id: UInt32
		
		access(all)
		let publicID: String
		
		access(all)
		let name: String
		
		init(id: UInt32){ 
			let brand = (&IrNFT.brands[id] as &IrNFT.IrBrand?)!
			self.id = brand.id
			self.publicID = brand.publicID
			self.name = brand.name
		}
	}
	
	// A top-level Brand with a unique ID and name
	//
	access(all)
	resource IrBrand{ 
		// Unique Brand ID (Automatically Incremente)
		access(all)
		let id: UInt32
		
		// Public Brand ID (Most likely an UUID)
		// This would be provided by the Admin to
		// match off chain data to this entry.
		//
		access(all)
		let publicID: String
		
		// Brand Name
		access(all)
		let name: String
		
		init(publicID: String, name: String){ 
			self.id = IrNFT.nextBrandID
			self.publicID = publicID
			self.name = name
			
			// Increment ID to keep it Unique
			IrNFT.nextBrandID = IrNFT.nextBrandID + 1
			emit BrandCreated(id: self.id, name: self.name)
		}
	}
	
	// Get all brand ids
	//
	access(all)
	fun getAllBrandIDs(): [UInt32]{ 
		return IrNFT.brands.keys
	}
	
	// Get the publicly available data for a Brand by id
	//
	access(all)
	fun getBrandData(id: UInt32): IrNFT.IrBrandData{ 
		pre{ 
			IrNFT.brands[id] != nil:
				"Cannot borrow brand, no such id"
		}
		return IrNFT.IrBrandData(id: id)
	}
	
	// Get all brand names
	//
	access(all)
	fun getAllBrandNames(): [String]{ 
		return IrNFT.brandIDsByName.keys
	}
	
	access(all)
	fun getBrandIDByName(name: String): UInt32?{ 
		return IrNFT.brandIDsByName[name]
	}
	
	//------------------------------------------------------------
	// IN|RIFT Collection
	//------------------------------------------------------------
	// A public struct to access IN|RIFT Collection data
	//
	access(all)
	struct IrCollectionData{ 
		access(all)
		let id: UInt32
		
		access(all)
		let publicID: String
		
		access(all)
		let brandIDs: [UInt32]
		
		access(all)
		let brandData:{ UInt32: IrBrandData}
		
		access(all)
		let name: String
		
		access(all)
		let description: String?
		
		access(all)
		let items: [UInt32]
		
		access(all)
		let retiredItems:{ UInt32: Bool}
		
		access(all)
		let drops: [UInt32]
		
		access(all)
		let dropData:{ UInt32: IrDropData}
		
		access(all)
		let open: Bool
		
		access(all)
		let totalSupplyPerItem:{ UInt32: UInt64}
		
		init(id: UInt32){ 
			let collection = (&IrNFT.collections[id] as &IrNFT.IrCollection?)!
			self.id = collection.id
			self.publicID = collection.publicID
			self.brandIDs = *collection.brandIDs
			self.brandData ={} 
			for brandID in collection.brandIDs{ 
				self.brandData[brandID] = IrNFT.getBrandData(id: brandID)
			}
			self.name = collection.name
			self.description = collection.description
			self.items = *collection.items
			self.retiredItems = *collection.retiredItems
			self.drops = *collection.brandIDs
			self.dropData ={} 
			for dropID in collection.drops{ 
				self.dropData[dropID] = IrNFT.getDropData(id: dropID)
			}
			self.open = collection.open
			self.totalSupplyPerItem = *collection.totalSupplyPerItem
		}
	}
	
	// A top-level IN|RIFT Collection with a unique ID and name
	//
	access(all)
	resource IrCollection{ 
		// Unique Collection ID
		access(all)
		let id: UInt32
		
		// Public Collection ID (Most likely an UUID)
		// This would be provided by the Admin to
		// match off chain data to this entry.
		//
		access(all)
		let publicID: String
		
		// Collection Brand IDs
		// Allows multiple Brands for Collabs, e.g. IN|RIFT x Brand XY
		access(all)
		let brandIDs: [UInt32]
		
		// Collection Name, e.g. "Pioneer Collection"
		access(all)
		let name: String
		
		// Optional Collection Description
		access(all)
		let description: String?
		
		// Additional Collection Metadata
		access(all)
		let metadata:{ String: String}
		
		// Collection Items
		access(contract)
		var items: [UInt32]
		
		// Collection Item Retired Flags
		access(contract)
		var retiredItems:{ UInt32: Bool}
		
		// Collection Drops
		access(contract)
		var drops: [UInt32]
		
		// Collection Open Flag
		//
		// The a collection is created it is open and
		// new items can be added.
		// 
		// When the collection is closed no items can be added.
		// This does not prevent minting/selling items via drops.
		access(all)
		var open: Bool
		
		// Already sold/minted Supply per Item
		//
		// Used to determine remaining supply & serials (e.g. 1/10).
		access(contract)
		var totalSupplyPerItem:{ UInt32: UInt64}
		
		init(publicID: String, name: String, brandIDs: [UInt32], description: String?, metadata:{ String: String}?){ 
			pre{ 
				brandIDs.length > 0:
					"At least one brand id is required"
			}
			let providedIDs: [UInt32] = []
			for brandID in brandIDs{ 
				// Make sure the brand exists
				assert(IrNFT.brands[brandID] != nil, message: "Brand not found")
				
				// Make sure each brand is only provided once
				assert(!providedIDs.contains(brandID), message: "Brands are not distinct")
				
				// Keep IDs for distinct check
				providedIDs.append(brandID)
			}
			self.id = IrNFT.nextCollectionID
			self.publicID = publicID
			self.brandIDs = brandIDs
			self.name = name
			self.description = description
			self.metadata = metadata ??{} 
			self.items = []
			self.retiredItems ={} 
			self.drops = []
			self.open = true
			self.totalSupplyPerItem ={} 
			
			// Increment ID to keep it Unique
			IrNFT.nextCollectionID = IrNFT.nextCollectionID + 1
			emit CollectionCreated(id: self.id, brandIDs: self.brandIDs, name: self.name)
		}
		
		// addItem
		// Adds a new item to the collection.
		access(all)
		fun addItem(itemID: UInt32){ 
			pre{ 
				self.open:
					"Collection is closed"
				IrNFT.items.containsKey(itemID):
					"No such itemID"
				self.id == IrNFT.getItemData(id: itemID).collectionID:
					"Item collection mismatch"
				!self.items.contains(itemID):
					"Item already added to this collection"
			}
			
			// Add Item to the Collection
			self.items.append(itemID)
			
			// Open Item for Minting
			self.retiredItems[itemID] = false
			
			// Initialize the Item's Total Supply to Zero
			self.totalSupplyPerItem[itemID] = 0
			emit CollectionItemAdded(id: self.id, itemID: itemID)
		}
		
		// retireItem
		// Retires an item, which prevents it being minted in the future.
		// This doesnt affect already sold vouchers which might still mint
		// the retired item because it was already sold.
		access(all)
		fun retireItem(itemID: UInt32){ 
			pre{ 
				self.open:
					"Collection is closed"
				IrNFT.items.containsKey(itemID):
					"No such itemID"
				!self.retiredItems[itemID]!:
					"Item is already retired"
			}
			self.retiredItems[itemID] = true
			emit ItemRetired(id: itemID, collectionID: self.id, name: IrNFT.getItemData(id: itemID).name)
		}
		
		// addDrop
		// Adds a new drop to the collection.
		access(all)
		fun addDrop(dropID: UInt32){ 
			pre{ 
				self.open:
					"Collection is closed"
				IrNFT.drops.containsKey(dropID):
					"No such dropID"
				self.id == IrNFT.getDropData(id: dropID).collectionID:
					"Drop collection mismatch"
				!self.drops.contains(dropID):
					"Drop already added to this collection"
			}
			
			// Add Drop to the Collection
			self.drops.append(dropID)
			emit CollectionDropAdded(id: self.id, dropID: dropID)
		}
		
		access(contract)
		fun increaseTotalSupplyForItem(itemID: UInt32){ 
			pre{ 
				self.totalSupplyPerItem.containsKey(itemID):
					"No such itemID in this collection"
			}
			self.totalSupplyPerItem[itemID] = self.totalSupplyPerItem[itemID]! + 1
		}
		
		// close
		// Closes this collection
		access(all)
		fun close(){ 
			pre{ 
				self.open:
					"Collection is already closed"
			}
			self.open = false
			emit CollectionClosed(id: self.id)
		}
	}
	
	// Get all collection ids
	//
	access(all)
	fun getAllCollectionIDs(): [UInt32]{ 
		return IrNFT.collections.keys
	}
	
	// Get the publicly available data for a Collection by id
	//
	access(all)
	fun getCollectionData(id: UInt32): IrNFT.IrCollectionData{ 
		pre{ 
			IrNFT.brands[id] != nil:
				"Cannot borrow collection, no such id"
		}
		return IrNFT.IrCollectionData(id: id)
	}
	
	// Get all collection names
	//
	access(all)
	fun getAllCollectionNames(): [String]{ 
		return IrNFT.collectionIDsByName.keys
	}
	
	access(all)
	fun getCollectionIDByName(name: String): UInt32?{ 
		return IrNFT.collectionIDsByName[name]
	}
	
	//------------------------------------------------------------
	// IN|RIFT Item
	//------------------------------------------------------------
	// A public struct to access IN|RIFT Item data
	//
	access(all)
	struct IrItemData{ 
		access(all)
		let collectionID: UInt32
		
		access(all)
		let collectionPublicID: String
		
		access(all)
		let id: UInt32
		
		access(all)
		let publicID: String
		
		access(all)
		let name: String
		
		access(all)
		let supply: UInt64
		
		access(all)
		let rarity: IrRarity
		
		access(all)
		let version: UInt8
		
		access(all)
		let utilities: [String]
		
		access(all)
		let assets: [IrItemAsset]
		
		access(all)
		let metadata:{ String: String}
		
		access(all)
		let provisionedSupply: UInt64
		
		access(all)
		let totalSupply: UInt64
		
		view init(id: UInt32){ 
			let item = (&IrNFT.items[id] as &IrNFT.IrItem?)!
			let collection = (&IrNFT.collections[item.collectionID] as &IrNFT.IrCollection?)!
			self.collectionID = collection.id
			self.collectionPublicID = collection.publicID
			self.id = item.id
			self.publicID = item.publicID
			self.name = item.name
			self.supply = item.supply
			self.rarity = IrNFT.getItemRarity(id: id)
			self.utilities = *item.utilities
			self.version = item.version
			self.assets = *item.assets
			self.metadata = *item.metadata
			self.provisionedSupply = item.provisionedSupply
			self.totalSupply = item.totalSupply
		}
	}
	
	// A nested struct to declare rich assets
	access(all)
	struct IrItemAsset{ 
		access(all)
		let name: String
		
		access(all)
		let provider: String
		
		access(all)
		let extension: String
		
		access(all)
		let megabytes: UFix64
		
		access(all)
		let content: String
		
		init(name: String, provider: String, extension: String, megabytes: UFix64, content: String){ 
			self.name = name
			self.provider = provider
			self.extension = extension
			self.megabytes = megabytes
			self.content = content
		}
	}
	
	// A top-level IN|RIFT Item with a unique ID and name
	//
	access(all)
	resource IrItem{ 
		// Determines to which Collection the Item belongs to
		access(all)
		let collectionID: UInt32
		
		// Public Item ID (Most likely an UUID)
		// This would be provided by the Admin to
		// match off chain data to this entry.
		//
		access(all)
		let publicID: String
		
		access(all)
		let id: UInt32
		
		access(all)
		let name: String
		
		access(all)
		let supply: UInt64
		
		access(all)
		let version: UInt8
		
		access(all)
		let utilities: [String]
		
		// Assets of this Item
		// Structure will match: 
		//   [
		//	  {
		//		  name: '', File Name, e.g. image-large
		//		  provider: '', // Provider Name, e.g skynet, ifps
		//		  content: '' // File Hash
		//	  },
		//	  ... // Additional Assets
		//  ]
		//
		access(all)
		let assets: [IrItemAsset]
		
		access(all)
		let metadata:{ String: String}
		
		// Keeps track of the Total provisioned Supply
		// Drops increase this to ensure we dont oversell
		// the available Item Supply
		access(contract)
		var provisionedSupply: UInt64
		
		access(contract)
		var totalSupply: UInt64
		
		init(collectionID: UInt32, publicID: String, name: String, supply: UInt64, version: UInt8, utilities: [String], assets: [IrItemAsset], metadata:{ String: String}?){ 
			pre{ 
				IrNFT.collections[collectionID] != nil:
					"Could not find collection"
				supply > 0:
					"Missing drop item supply"
				utilities.length > 0:
					"Missing drop item utility"
				assets.length > 0:
					"Missing drop item asset"
			}
			self.collectionID = collectionID
			self.id = IrNFT.nextItemID
			self.publicID = publicID
			self.name = name
			self.supply = supply
			self.version = version
			self.utilities = utilities
			self.assets = assets
			self.metadata = metadata ??{} 
			self.provisionedSupply = 0
			self.totalSupply = 0
			
			// Increment ID to keep it Unique
			IrNFT.nextItemID = IrNFT.nextItemID + 1
			emit ItemCreated(id: self.id, collectionID: self.collectionID, name: self.name)
		}
		
		access(all)
		fun getRemainingProvisionableSupply(): UInt64{ 
			return self.supply - self.provisionedSupply
		}
		
		access(contract)
		fun increaseProvisionedSupply(supply: UInt64){ 
			self.provisionedSupply = self.provisionedSupply + supply
		}
		
		access(contract)
		fun increaseTotalSupply(){ 
			self.totalSupply = self.totalSupply + 1
		}
	}
	
	// Get the publicly available data for an Item by ID
	//
	access(all)
	view fun getItemData(id: UInt32): IrNFT.IrItemData{ 
		pre{ 
			IrNFT.items[id] != nil:
				"Cannot borrow item, no such ID"
		}
		return IrNFT.IrItemData(id: id)
	}
	
	// Get the rarity for an Item by ID
	//
	access(all)
	view fun getItemRarity(id: UInt32): IrNFT.IrRarity{ 
		pre{ 
			IrNFT.items[id] != nil:
				"Cannot borrow item, no such ID"
		}
		let item = (&IrNFT.items[id] as &IrNFT.IrItem?)!
		var itemRarity: IrNFT.IrRarity? = nil
		var matchedMaxSupply: UInt64 = 0
		for rarity in IrNFT.rarityMaxSupply.keys{ 
			let rarityMaxSupply = IrNFT.rarityMaxSupply[rarity]!
			if rarityMaxSupply < item.supply{ 
				continue
			}
			if itemRarity != nil && matchedMaxSupply < rarityMaxSupply{ 
				continue
			}
			itemRarity = rarity
			matchedMaxSupply = rarityMaxSupply
		}
		return itemRarity ?? IrNFT.rarityDefault
	}
	
	//------------------------------------------------------------
	// IN|RIFT Drop
	//------------------------------------------------------------
	// A public struct to access IN|RIFT Drop data
	//
	access(all)
	struct IrDropData{ 
		access(all)
		let collectionID: UInt32
		
		access(all)
		let id: UInt32
		
		access(all)
		let publicID: String
		
		access(all)
		let name: String
		
		access(all)
		let description: String?
		
		access(all)
		let price: UFix64
		
		access(all)
		let start: UFix64
		
		access(all)
		let end: UFix64
		
		access(all)
		var items: [UInt32]
		
		access(all)
		var supplyPerItem:{ UInt32: UInt64}
		
		access(all)
		let itemData:{ UInt32: IrItemData}
		
		access(all)
		var metadata:{ String: String}
		
		access(all)
		var supply: UInt64
		
		access(all)
		var totalSupply: UInt64
		
		view init(id: UInt32){ 
			let drop = (&IrNFT.drops[id] as &IrNFT.IrDrop?)!
			self.collectionID = drop.collectionID
			self.id = drop.id
			self.publicID = drop.publicID
			self.name = drop.name
			self.description = drop.description
			self.price = drop.price
			self.start = drop.start
			self.end = drop.end
			self.items = *drop.items
			self.itemData ={} 
			for itemID in drop.items{ 
				self.itemData[itemID] = IrNFT.getItemData(id: itemID)
			}
			self.supplyPerItem = *drop.supplyPerItem
			self.metadata = *drop.metadata
			self.supply = drop.supply
			self.totalSupply = drop.totalSupply
		}
		
		access(all)
		view fun hasEnded(): Bool{ 
			var current: UFix64 = getCurrentBlock().timestamp
			var end = self.end
			return current > end
		}
		
		access(all)
		view fun isSoldOut(): Bool{ 
			if self.totalSupply >= self.supply{ 
				return true
			}
			return false
		}
		
		access(all)
		fun isOpen(): Bool{ 
			if self.isSoldOut(){ 
				return false
			}
			var current: UFix64 = getCurrentBlock().timestamp
			var start = self.start
			var end = self.end
			
			// Check Drop Running
			return start <= current && current <= end
		}
		
		access(all)
		fun purchaseVoucher(recipient: &{NonFungibleToken.CollectionPublic}, paymentVault: @{FungibleToken.Vault}){ 
			let drop = (&IrNFT.drops[self.id] as &IrNFT.IrDrop?)!
			drop.purchaseVoucher(recipient: recipient, paymentVault: <-paymentVault)
		}
		
		access(all)
		fun redeemVoucher(recipient: &{NonFungibleToken.CollectionPublic}, token: @{NonFungibleToken.NFT}){ 
			let drop = (&IrNFT.drops[self.id] as &IrNFT.IrDrop?)!
			drop.redeemVoucher(recipient: recipient, token: <-token)
		}
	}
	
	// A top-level IN|RIFT Drop with a unique ID and name
	//
	// A drop holds a subset of collectible items.
	// They determine which items are sold when.
	//
	// e.g. all items of the "Pioneer Collection"
	//   will be sold across 3 dates/drops, so we create
	//   3 drop instances for that collection
	//
	access(all)
	resource IrDrop{ 
		// Determines to which Collection the Drop belongs to
		access(all)
		let collectionID: UInt32
		
		access(all)
		let id: UInt32
		
		// Public Item ID (Most likely an UUID)
		// This would be provided by the Admin to
		// match off chain data to this entry.
		//
		access(all)
		let publicID: String
		
		// Drop Name, e.g. "Pioneer Collection Drop #1"
		access(all)
		let name: String
		
		// Optional Drop Description
		access(all)
		let description: String?
		
		// Drop Price (fixed to FUSD)
		access(all)
		let price: UFix64
		
		// Drop Start Datetime (UTC Timestamp)
		access(all)
		let start: UFix64
		
		// Drop End Datetime (UTC Timestamp)
		access(all)
		let end: UFix64
		
		// Drop Items
		//
		// A array to keep the order priority.
		// in case we dont sell out we want to make sure
		// the rarer items are given out!
		//
		access(all)
		var items: [UInt32]
		
		// Drop Item Supply
		// A dictionary of {itemID: itemSupply}
		//
		// We can determine the item supply on a drop basis.
		// That way we might split the available item supply
		// across multiple drops.
		//
		access(all)
		var supplyPerItem:{ UInt32: UInt64}
		
		// Already minted Supply per Item
		//
		// Used to randomly select a item of this drop.
		access(contract)
		var totalSupplyPerItem:{ UInt32: UInt64}
		
		// Additional Drop Metadata
		// Used to store fields like "color" used by the
		// DApp to adjust the visual of each drop.
		access(all)
		var metadata:{ String: String}
		
		// Available Total Item Supply for the Drop
		// We don't sell them directly, we give out "Vouchers"
		// that way we don't have to worry about specific
		// item supplies here yet.
		access(contract)
		var supply: UInt64
		
		// Already sold/given away Item Supply for the Drop
		//
		// Total because this determines the final supply
		// when the drop has ended.
		access(contract)
		var totalSupply: UInt64
		
		// Already redeemed Vouchers of the Total Supply
		//
		access(contract)
		var redeemedSupply: UInt64
		
		init(collectionID: UInt32, publicID: String, name: String, description: String?, price: UFix64, start: UFix64, end: UFix64, items: [UInt32], supplyPerItem:{ UInt32: UInt64}, metadata:{ String: String}){ 
			pre{ 
				IrNFT.collections.containsKey(collectionID):
					"No such collectionID"
				items.length > 0:
					"Missing drop item(s)"
				supplyPerItem.keys.length > 0:
					"Missing drop item(s) supply"
				items.length == supplyPerItem.keys.length:
					"Provided item amount doesnt match supply items"
			}
			var collection = (&IrNFT.collections[collectionID] as &IrCollection?)!
			self.collectionID = collection.id
			self.id = IrNFT.nextDropID
			self.publicID = publicID
			self.name = name
			self.description = description
			self.price = price
			self.start = start
			self.end = end
			for itemID in items{ 
				assert(IrNFT.items.containsKey(itemID), message: "No such itemID")
				assert(supplyPerItem.containsKey(itemID), message: "Missing supply for an item")
			}
			self.items = items
			
			// Available Supply for this Drop & Total per Item
			// These will increment when checking the
			// Supply per Item Dictionary
			self.supply = 0
			self.totalSupplyPerItem ={} 
			for itemID in supplyPerItem.keys{ 
				assert(items.contains(itemID), message: "Did provide supply for an missing item")
				let itemSupply: UInt64 = supplyPerItem[itemID]!
				let item = (&IrNFT.items[itemID] as &IrItem?)!
				assert(item.collectionID == collectionID, message: "Item does not belong to the drop's collection")
				assert(item.getRemainingProvisionableSupply() >= itemSupply, message: "Item supply is not available & would result in overselling")
				
				// Increate provisioned Supply of the Item
				item.increaseProvisionedSupply(supply: itemSupply)
				
				// Increase Supply of this Drop
				self.supply = self.supply + itemSupply
				
				// Set Initial Total Supply per Item (minted amount)
				self.totalSupplyPerItem[itemID] = 0
			}
			self.supplyPerItem = supplyPerItem
			self.metadata = metadata
			
			// Keep total supply (minted vouchers)
			self.totalSupply = 0
			
			// Keep redeemed supply (redeemed vouchers)
			self.redeemedSupply = 0
			
			// Increment ID to keep it Unique
			IrNFT.nextDropID = IrNFT.nextDropID + 1
		}
		
		access(all)
		fun isActive(): Bool{ 
			return IrNFT.activeDrops.contains(self.id)
		}
		
		access(all)
		view fun hasStarted(): Bool{ 
			var current: UFix64 = getCurrentBlock().timestamp
			var start = self.start
			return start < current
		}
		
		access(all)
		view fun hasEnded(): Bool{ 
			var current: UFix64 = getCurrentBlock().timestamp
			var end = self.end
			return current > end
		}
		
		access(all)
		view fun isSoldOut(): Bool{ 
			if self.totalSupply >= self.supply{ 
				return true
			}
			return false
		}
		
		access(all)
		fun isOpen(): Bool{ 
			if self.isSoldOut(){ 
				return false
			}
			
			// Check Drop Running
			return self.hasStarted() && !self.hasEnded()
		}
		
		access(all)
		fun remainingVouchers(): UInt64{ 
			return self.totalSupply - self.redeemedSupply
		}
		
		// Mint a IN|RIFT Voucher for this Drop
		//
		access(contract)
		fun mintVoucher(): @IrVoucher.NFT{ 
			pre{ 
				!self.hasEnded():
					"Drop ended, cannot mint voucher"
			}
			
			// Create the Genies NFT, filled out with our information
			let voucherNFT <- IrVoucher.mintVoucher(dropID: self.id,																	 // Increment, so Serials start at 1
																	 serial: UInt32(self.totalSupply + 1))
			self.totalSupply = self.totalSupply + 1
			return <-voucherNFT
		}
		
		// Purchase a Voucher for this Drop
		//
		access(all)
		fun purchaseVoucher(recipient: &{NonFungibleToken.CollectionPublic}, paymentVault: @{FungibleToken.Vault}){ 
			pre{ 
				!self.isSoldOut():
					"Drop sold out, cannot purchase voucher"
				!self.hasEnded():
					"Drop ended, cannot purchase voucher"
				self.hasStarted():
					"Drop not started, cannot purchase voucher"
				paymentVault.isInstance(Type<@FUSD.Vault>()):
					"Invalid payment type, cannot purchase voucher (only FUSD supported)"
				paymentVault.balance == self.price:
					"Invalid payment balance, cannot purchase voucher"
			}
			let paymentTargetVault = IrNFT.account.capabilities.get<&FUSD.Vault>(/public/fusdReceiver).borrow() ?? panic("Could not borrow reference to target token vault")
			
			// Deposit that to the Service Account
			paymentTargetVault.deposit(from: <-paymentVault)
			let voucherNFT <- self.mintVoucher()
			let tokenID = voucherNFT.id
			assert(voucherNFT != nil, message: "Voucher could not be minted")
			assert(voucherNFT.isInstance(Type<@IrVoucher.NFT>()), message: "Voucher is not of the correct type")
			
			// Deposit the Voucher into the Recipient's Collection
			recipient.deposit(token: <-voucherNFT)
			emit VoucherPurchased(id: tokenID, collectionID: self.collectionID, dropID: self.id, by: (recipient.owner!).address)
		}
		
		access(all)
		fun redeemVoucher(recipient: &{NonFungibleToken.CollectionPublic}, token: @{NonFungibleToken.NFT}){ 
			pre{ 
				self.isSoldOut() || self.hasEnded():
					"Unable to redeem: Drop is not over yet"
				token.isInstance(Type<@IrVoucher.NFT>()):
					"Unable to redeem: Provided token is not a voucher"
			}
			let voucher <- token as! @IrVoucher.NFT
			let remaining = self.remainingVouchers()
			let randomIndex = revertibleRandom<UInt64>() % remaining
			let remainingItems: [UInt32] = []
			for dropItemID in self.items{ 
				let dropItemSupply = self.supplyPerItem[dropItemID]!
				let mintedItemSupply = self.totalSupplyPerItem[dropItemID]!
				var remainingItemSupply = dropItemSupply - mintedItemSupply
				if remainingItemSupply < 1{ 
					// No Supply left of this Item
					// Continue to next Item
					continue
				}
				if remainingItemSupply > remaining{ 
					remainingItemSupply = remaining
				}
				var i = 0 as UInt64
				while i < remainingItemSupply{ 
					remainingItems.append(dropItemID)
					
					// Continue
					i = i + 1
				}
				
				// Reduce Remaining Amount by the Amount
				// we just added to the Item Array
				remaining - remainingItemSupply
			}
			
			// Now we have an Array containing all remaining Items
			// These should be in rarity order to the rarest items are first.
			// That way we definetly sell/mint the rarer items in case
			// a drop did not sell out.
			
			// Failcheck
			assert(UInt64(remainingItems.length) > randomIndex, message: "Has not enough items")
			let randomItemID = remainingItems[randomIndex]
			let item = (&IrNFT.items[randomItemID] as &IrItem?)!
			let collection = (&IrNFT.collections[item.collectionID] as &IrNFT.IrCollection?)!
			let newNFT <- IrNFT.mintDropNFT(collectionID: collection.id, itemID: item.id, dropID: self.id)
			let voucherID = voucher.id
			let nftID = newNFT.id
			
			// Destroy / Redeem the Voucher
			destroy voucher
			
			// Increase Redeemed Supply (Vouchers Used)
			self.increaseRedeemedSupply()
			
			// Deposit the NFT into the Recipient's Collection
			recipient.deposit(token: <-newNFT)
			emit VoucherRedeemed(id: voucherID, collectionID: collection.id, dropID: self.id, nftID: nftID, by: (recipient.owner!).address)
		}
		
		access(all)
		fun setActive(){ 
			pre{ 
				!IrNFT.activeDrops.contains(self.id):
					"Drop is already active"
			}
			IrNFT.activeDrops.append(self.id)
		}
		
		access(all)
		fun setInactive(){ 
			pre{ 
				IrNFT.activeDrops.contains(self.id):
					"Drop is already inactive"
			}
			var dropIndex = 0
			for dropID in IrNFT.activeDrops{ 
				// Check if we found the Drop
				if dropID == self.id{ 
					break
				}
				dropIndex = dropIndex + 1
			}
			IrNFT.activeDrops.remove(at: dropIndex)
		}
		
		access(contract)
		fun increaseRedeemedSupply(){ 
			self.redeemedSupply = self.redeemedSupply + 1
		}
		
		access(contract)
		fun increaseTotalSupplyForItem(itemID: UInt32){ 
			pre{ 
				self.totalSupplyPerItem.containsKey(itemID):
					"No such itemID in this drop"
			}
			self.totalSupplyPerItem[itemID] = self.totalSupplyPerItem[itemID]! + 1
		}
	}
	
	// Get all drop IDs
	//
	access(all)
	fun getAllDropIDs(): [UInt32]{ 
		return IrNFT.drops.keys
	}
	
	// Get active drop IDs
	//
	access(all)
	fun getActiveDropIDs(): [UInt32]{ 
		return IrNFT.activeDrops
	}
	
	// Get the publicly available data for a Drop by ID
	//
	access(all)
	view fun getDropData(id: UInt32): IrNFT.IrDropData{ 
		pre{ 
			IrNFT.drops.containsKey(id):
				"Cannot borrow drop, no such id"
		}
		return IrNFT.IrDropData(id: id)
	}
	
	//------------------------------------------------------------
	// IN|RIFT NFT
	//------------------------------------------------------------
	// A IN|RIFT NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let collectionID: UInt32
		
		access(all)
		let itemID: UInt32
		
		access(all)
		let itemPublicID: String
		
		access(all)
		let serial: UInt64
		
		access(all)
		let supply: UInt64
		
		access(all)
		let rarity: IrRarity
		
		access(all)
		let name: String
		
		access(all)
		let version: UInt8
		
		access(all)
		let utilities: [String]
		
		access(all)
		let assets: [IrItemAsset]
		
		access(all)
		let metadata:{ String: String}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64, collectionID: UInt32, itemID: UInt32, itemPublicID: String, serial: UInt64, supply: UInt64, rarity: IrRarity, name: String, version: UInt8, utilities: [String], assets: [IrItemAsset], metadata:{ String: String}?){ 
			self.id = id
			self.collectionID = collectionID
			self.itemID = itemID
			self.itemPublicID = itemPublicID
			self.serial = serial
			self.supply = supply
			self.rarity = rarity
			self.name = name
			self.version = version
			self.utilities = utilities
			self.assets = assets
			self.metadata = metadata ??{} 
		}
	}
	
	//------------------------------------------------------------
	// NFT Collection
	//------------------------------------------------------------
	// A public collection interface that allows IN|RIFT NFTs to be borrowed
	//
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun idExists(id: UInt64): Bool
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowIrNFT(id: UInt64): &IrNFT.NFT?
	}
	
	// The definition of the Collection resource that
	// holds the Drops (NFTs) that a user owns
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// Initialize the NFTs field to an empty collection
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw
		//
		// Function that removes an NFT from the collection
		// and moves it to the calling context
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// If the NFT isn't found, the transaction panics and reverts
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT to withdraw")
			return <-token
		}
		
		// deposit
		//
		// Function that takes a NFT as an argument and
		// adds it to the collections dictionary
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @IrNFT.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			destroy oldToken
		}
		
		// idExists checks to see if a NFT
		// with the given ID exists in the collection
		access(all)
		fun idExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowIrNFT
		access(all)
		fun borrowIrNFT(id: UInt64): &IrNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &IrNFT.NFT
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
	}
	
	// Allow everyone to create a empty IN|RIFT NFT Collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// mintDropNFT
	//
	access(account)
	fun mintDropNFT(collectionID: UInt32, itemID: UInt32, dropID: UInt32): @NFT{ 
		let admin <- create Admin()
		let newNFT <- admin.mintDropNFT(collectionID: collectionID, itemID: itemID, dropID: dropID)
		destroy admin
		return <-newNFT
	}
	
	//------------------------------------------------------------
	// Admin
	//------------------------------------------------------------
	access(all)
	resource Admin{ 
		
		// createBrand
		// Create and store a new Brand
		//
		access(all)
		fun createBrand(publicID: String, name: String): UInt32{ 
			pre{ 
				!IrNFT.brandIDsByName.containsKey(name):
					"Brand with that name already exists"
			}
			
			// Create a new Brand
			let newBrand <- create IrBrand(publicID: publicID, name: name)
			var newID: UInt32 = newBrand.id
			
			// Store it on the contract
			let oldBrand <- IrNFT.brands[newID] <-! newBrand
			destroy oldBrand
			
			// Cache Name => ID mapping
			IrNFT.brandIDsByName[name] = newID
			return newID
		}
		
		// createCollection
		// Create and store a new Collection
		//
		access(all)
		fun createCollection(publicID: String, name: String, brandIDs: [UInt32], description: String?, metadata:{ String: String}?): UInt32{ 
			// Create a new Collection
			let newCollection <- create IrCollection(publicID: publicID, name: name, brandIDs: brandIDs, description: description, metadata: metadata ??{} )
			var newID: UInt32 = newCollection.id
			
			// Store it on the contract
			let oldCollection <- IrNFT.collections[newID] <-! newCollection
			destroy oldCollection
			
			// Cache Name => ID mapping
			IrNFT.brandIDsByName[name] = newID
			return newID
		}
		
		// borrowCollection
		//
		access(all)
		fun borrowCollection(collectionID: UInt32): &IrCollection{ 
			pre{ 
				IrNFT.collections.containsKey(collectionID):
					"Cannot borrow Collection: No such collectionID"
			}
			
			// Return a reference (&) of the requested Collection
			return (&IrNFT.collections[collectionID] as &IrCollection?)!
		}
		
		// createItem
		// Create and store a new Item
		//
		access(all)
		fun createItem(collectionID: UInt32, publicID: String, name: String, supply: UInt64, utilities: [String], assets: [IrItemAsset], metadata:{ String: String}?): UInt32{ 
			pre{ 
				IrNFT.collections.containsKey(collectionID):
					"No such collectionID"
			}
			let collection = (&IrNFT.collections[collectionID] as &IrNFT.IrCollection?)!
			
			// Create new Item
			let newItem <- create IrItem(collectionID: collectionID, publicID: publicID, name: name, supply: supply, version: 1, utilities: utilities, assets: assets, metadata: metadata)
			let newID: UInt32 = newItem.id
			
			// Store it in the contract storage
			let oldItem <- IrNFT.items[newID] <-! newItem
			destroy oldItem
			
			// Add Item to Collection Instance
			collection.addItem(itemID: newID)
			return newID
		}
		
		// borrowItem
		//
		access(all)
		fun borrowItem(itemID: UInt32): &IrItem{ 
			pre{ 
				IrNFT.items.containsKey(itemID):
					"Cannot borrow Item: Nu such itemID"
			}
			
			// Return a reference (&) of the requested Collection
			return (&IrNFT.items[itemID] as &IrItem?)!
		}
		
		// createDrop
		// Create and store a new Drop
		//
		access(all)
		fun createDrop(collectionID: UInt32, publicID: String, name: String, description: String?, price: UFix64, start: UFix64, end: UFix64, items: [UInt32], supplyPerItem:{ UInt32: UInt64}, metadata:{ String: String}): UInt32{ 
			pre{ 
				IrNFT.collections.containsKey(collectionID):
					"No such collectionID"
			}
			let collection = (&IrNFT.collections[collectionID] as &IrNFT.IrCollection?)!
			
			// Create new Drop
			let newDrop <- create IrDrop(collectionID: collectionID, publicID: publicID, name: name, description: description, price: price, start: start, end: end, items: items, supplyPerItem: supplyPerItem, metadata: metadata)
			let newID: UInt32 = newDrop.id
			
			// Store it in the contract storage
			let oldDrop <- IrNFT.drops[newID] <-! newDrop
			destroy oldDrop
			
			// Add Drop to Collection Instance
			collection.addDrop(dropID: newID)
			return newID
		}
		
		// borrowItem
		//
		access(all)
		fun borrowDrop(dropID: UInt32): &IrDrop{ 
			pre{ 
				IrNFT.drops.containsKey(dropID):
					"Cannot borrow Drop: No such dropID"
			}
			
			// Return a reference (&) of the requested Collection
			return (&IrNFT.drops[dropID] as &IrDrop?)!
		}
		
		// giveawayVoucher
		// Allows Admins to giveaway a Voucher for a specific
		// drop while supply last. Can be done before sale start.
		//
		access(all)
		fun giveawayVoucher(dropID: UInt32, recipient: &{NonFungibleToken.CollectionPublic}){ 
			pre{ 
				IrNFT.drops.containsKey(dropID):
					"No such dropID"
				!IrNFT.getDropData(id: dropID).isSoldOut():
					"Drop is sold out"
				!IrNFT.getDropData(id: dropID).hasEnded():
					"Drop has ended"
			}
			let drop = (&IrNFT.drops[dropID] as &IrNFT.IrDrop?)!
			let voucherNFT <- drop.mintVoucher()
			let tokenID = voucherNFT.id
			assert(voucherNFT != nil, message: "Voucher could not be minted")
			assert(voucherNFT.isInstance(Type<@IrVoucher.NFT>()), message: "Voucher is not of the correct type")
			recipient.deposit(token: <-voucherNFT)
			emit VoucherGifted(id: tokenID, collectionID: drop.collectionID, dropID: drop.id, by: (recipient.owner!).address)
		}
		
		// mintItemNFT
		// Mints a specific item NFT
		//
		access(all)
		fun mintItemNFT(collectionID: UInt32, itemID: UInt32): @IrNFT.NFT{ 
			pre{ 
				IrNFT.collections.containsKey(collectionID):
					"No such collectionID"
				IrNFT.items.containsKey(itemID):
					"No such itemID"
			}
			let collection = (&IrNFT.collections[collectionID] as &IrNFT.IrCollection?)!
			let item = (&IrNFT.items[itemID] as &IrNFT.IrItem?)!
			assert(collection.items.contains(itemID), message: "Collection does not include this item")
			assert(!collection.retiredItems[itemID]!, message: "This item is retired and can no longer be minted")
			let remainingSupply = item.getRemainingProvisionableSupply()
			assert(remainingSupply > 0, message: "Can not mint more of that items, no remaining supply for item")
			
			// Find Item Rarity
			var itemRarity: IrNFT.IrRarity? = nil
			var matchedMaxSupply: UInt64 = 0
			for rarity in IrNFT.rarityMaxSupply.keys{ 
				let rarityMaxSupply = IrNFT.rarityMaxSupply[rarity]!
				if rarityMaxSupply < item.supply{ 
					// Supply is more than the maximum of this rarity
					continue
				}
				if itemRarity != nil && matchedMaxSupply < rarityMaxSupply{ 
					// We already matched a rarity with lower max supply
					// So we do not want to override that! 
					// (dictionaries are not orderes)
					continue
				}
				itemRarity = rarity
				matchedMaxSupply = rarityMaxSupply
			}
			let itemSupply = item.supply
			let itemTotalSupply = item.totalSupply
			
			// Increase Item Total Supply by 1 to get Serial (starting 1)
			let serial = itemTotalSupply + 1
			
			// Create a new NFT
			var newNFT <- create IrNFT.NFT(id: IrNFT.totalSupply, collectionID: collection.id, itemID: item.id, itemPublicID: item.publicID, serial: serial,																																							 // Store Supply to easily show #X/X
																																							 supply: itemSupply,																																												 // Use matched Rarity or fallback to Default
																																												 rarity: itemRarity ?? IrNFT.rarityDefault, name: item.name, version: item.version, utilities: *item.utilities, assets: *item.assets, metadata: item.metadata)
			
			// Increate provisioned Supply of the Item
			// in case this gets mixed with Drops and the provisioning checks
			item.increaseProvisionedSupply(supply: 1)
			
			// Increase Item Total Supply (to keep Serial Unique)
			item.increaseTotalSupply()
			
			// Increase Collection Item Total Supply
			collection.increaseTotalSupplyForItem(itemID: itemID)
			
			// Increate NFT Total Supply (to keep NFT ID Unique)
			IrNFT.totalSupply = IrNFT.totalSupply + 1
			return <-newNFT
		}
		
		// mintDropNFT
		// Mints a random NFT for an item in a drop, this checks
		// the sold voucher amount. 
		//
		access(all)
		fun mintDropNFT(collectionID: UInt32, itemID: UInt32, dropID: UInt32): @IrNFT.NFT{ 
			pre{ 
				IrNFT.collections.containsKey(collectionID):
					"No such collectionID"
				IrNFT.items.containsKey(itemID):
					"No such itemID"
				IrNFT.drops.containsKey(dropID):
					"No such dropID"
			}
			let collection = (&IrNFT.collections[collectionID] as &IrNFT.IrCollection?)!
			let item = (&IrNFT.items[itemID] as &IrNFT.IrItem?)!
			let drop = (&IrNFT.drops[dropID] as &IrNFT.IrDrop?)!
			assert(collection.items.contains(itemID), message: "Collection does not include this item")
			assert(drop.items.contains(itemID), message: "Drop does not include this item")
			let dropItemSupply = drop.supplyPerItem[itemID]!
			let dropItemTotalSupply = drop.totalSupplyPerItem[itemID]!
			assert(dropItemTotalSupply < dropItemSupply, message: "Can not mint more of that items, no remaining supply for this drop")
			let itemSupply = item.supply
			let itemTotalSupply = item.totalSupply
			
			// Find Item Rarity
			var itemRarity: IrNFT.IrRarity? = nil
			var matchedMaxSupply: UInt64 = 0
			for rarity in IrNFT.rarityMaxSupply.keys{ 
				let rarityMaxSupply = IrNFT.rarityMaxSupply[rarity]!
				if rarityMaxSupply < item.supply{ 
					// Supply is more than the maximum of this rarity
					continue
				}
				if itemRarity != nil && matchedMaxSupply < rarityMaxSupply{ 
					// We already matched a rarity with lower max supply
					// So we do not want to override that! 
					// (dictionaries are not orderes)
					continue
				}
				itemRarity = rarity
				matchedMaxSupply = rarityMaxSupply
			}
			
			// Increase Item Total Supply by 1 to get Serial (starting 1)
			let serial = itemTotalSupply + 1
			
			// Create a new NFT
			var newNFT <- create IrNFT.NFT(id: IrNFT.totalSupply, collectionID: collection.id, itemID: item.id, itemPublicID: item.publicID, serial: serial,																																							 // Store Supply to easily show #X/X
																																							 supply: itemSupply,																																												 // Use matched Rarity or fallback to Default
																																												 rarity: itemRarity ?? IrNFT.rarityDefault, name: item.name, version: item.version, utilities: *item.utilities, assets: *item.assets, metadata: item.metadata)
			
			// Increase Item Total Supply (to keep Serial Unique)
			item.increaseTotalSupply()
			
			// Increase Collection Item Total Supply
			collection.increaseTotalSupplyForItem(itemID: itemID)
			
			// Increate Drop Item Total Supply
			drop.increaseTotalSupplyForItem(itemID: itemID)
			
			// Increate NFT Total Supply (to keep NFT ID Unique)
			IrNFT.totalSupply = IrNFT.totalSupply + 1
			return <-newNFT
		}
		
		// createNewAdmin
		// Allows an existing Admin to create other Admins
		//
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	//------------------------------------------------------------
	// Contract lifecycle
	//------------------------------------------------------------
	init(){ 
		// Set the named paths 
		self.CollectionStoragePath = /storage/irCollectionV1
		self.CollectionPublicPath = /public/irCollectionV1
		self.AdminStoragePath = /storage/irAdminV1
		
		// Initialize the entity counts
		self.totalSupply = 0
		self.nextBrandID = 0
		self.nextCollectionID = 0
		self.nextItemID = 0
		self.nextDropID = 0
		
		// Initialize enum helpers
		self.rarityMaxSupply ={ IrRarity.UNIQUE: 1, IrRarity.LEGENDARY: 10, IrRarity.EPIC: 100, IrRarity.RARE: 1000}
		self.rarityDefault = IrRarity.COMMON
		
		// Initialize the metadata lookup dictionaries
		self.brands <-{} 
		self.brandIDsByName ={} 
		self.collections <-{} 
		self.collectionIDsByName ={} 
		self.items <-{} 
		self.drops <-{} 
		self.activeDrops = []
		
		// Store an empty IN|RIFT NFT Collection in account storage
		// & publish a public reference to the  IN|RIFT NFT Collection in storage
		self.account.storage.save(<-self.createEmptyCollection(nftType: Type<@Collection>()), to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&IrNFT.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		let newAdmin <- create Admin()
		
		// Create "IN|RIFT" as initial brand available
		newAdmin.createBrand(publicID: "inrift", name: "IN|RIFT")
		
		// Store Admin/Minter resources in account storage
		self.account.storage.save(<-newAdmin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
