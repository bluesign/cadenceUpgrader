/*
	DSSCollection contains collection group & completion functionality for DSS.
	Author: Jeremy Ahrens jer.ahrens@dapperlabs.com
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

// The DSSCollection contract
//
access(all)
contract DSSCollection: NonFungibleToken{ 
	
	// Contract Events
	//
	access(all)
	event ContractInitialized()
	
	// NFT Collection Events
	//
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Events
	//
	access(all)
	event CollectionGroupCreated(id: UInt64, name: String, description: String, productName: String, endTime: UFix64?, metadata:{ String: String})
	
	access(all)
	event CollectionGroupClosed(id: UInt64)
	
	access(all)
	event ItemCreatedInSlot(itemID: String, points: UInt64, itemType: String, comparator: String, slotID: UInt64, collectionGroupID: UInt64)
	
	access(all)
	event SlotCreated(id: UInt64, collectionGroupID: UInt64, logicalOperator: String, required: Bool, typeName: Type, metadata:{ String: String})
	
	access(all)
	event CollectionNFTMinted(id: UInt64, collectionGroupID: UInt64, serialNumber: UInt64, completionAddress: String, completionDate: UFix64, level: UInt8)
	
	access(all)
	event CollectionNFTCompletedWith(collectionGroupID: UInt64, completionAddress: String, completionNftIds: [UInt64])
	
	access(all)
	event CollectionNFTBurned(id: UInt64)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let MinterPrivatePath: PrivatePath
	
	// Entity Counts
	//
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var collectionGroupNFTCount:{ UInt64: UInt64}
	
	// Placeholder for future updates
	access(all)
	let extCollectionGroup:{ String: AnyStruct}
	
	// Lists in contract
	//
	access(self)
	let collectionGroupByID: @{UInt64: CollectionGroup}
	
	access(self)
	let slotByID: @{UInt64: Slot}
	
	// A public struct to stores the nftIDs used to complete a collection group
	//
	access(all)
	struct CollectionCompletedWith{ 
		access(all)
		var collectionGroupID: UInt64
		
		access(all)
		var nftIDs: [UInt64]
		
		init(collectionGroupID: UInt64, nftIDs: [UInt64]){ 
			self.collectionGroupID = collectionGroupID
			self.nftIDs = nftIDs
		}
	}
	
	access(all)
	var completedCollections:{ Address: [CollectionCompletedWith]}
	
	// A public struct to access Item data
	//
	access(all)
	struct Item{ 
		access(all)
		let itemID: String // the id of the edition, tier, play
		
		
		access(all)
		let points: UInt64 // points for item
		
		
		access(all)
		let itemType: String // (edition.id, edition.tier, play.id)
		
		
		access(all)
		let comparator: String // (< | > | =)
		
		
		init(itemID: String, points: UInt64, itemType: String, comparator: String){ 
			self.itemID = itemID
			self.points = points
			self.itemType = itemType
			self.comparator = comparator
		}
	}
	
	// A public struct to access Slot data
	//
	access(all)
	struct SlotData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let collectionGroupID: UInt64
		
		access(all)
		let logicalOperator: String // (AND / OR)
		
		
		access(all)
		let required: Bool
		
		access(all)
		let typeName: Type // (Type<A.f8d6e0586b0a20c7.ExampleNFT.NFT>()...)
		
		
		access(all)
		var items: [Item]
		
		access(all)
		let metadata:{ String: String}
		
		init(id: UInt64){ 
			if let slot = &DSSCollection.slotByID[id] as &DSSCollection.Slot?{ 
				self.id = slot.id
				self.collectionGroupID = slot.collectionGroupID
				self.logicalOperator = slot.logicalOperator
				self.required = slot.required
				self.typeName = slot.typeName
				self.items = *slot.items
				self.metadata = *slot.metadata
			} else{ 
				panic("Slot does not exist")
			}
		}
	}
	
	// A top-level Slot with a unique ID
	//
	access(all)
	resource Slot{ 
		access(all)
		let id: UInt64
		
		access(all)
		let collectionGroupID: UInt64
		
		access(all)
		let logicalOperator: String // (AND / OR)
		
		
		access(all)
		let required: Bool
		
		access(all)
		let typeName: Type // (Type<A.f8d6e0586b0a20c7.ExampleNFT.NFT>())
		
		
		access(all)
		var items: [Item]
		
		access(all)
		let metadata:{ String: String}
		
		// Create item in slot
		//
		access(contract)
		fun createItemInSlot(itemID: String, points: UInt64, itemType: String, comparator: String){ 
			pre{ 
				DSSCollection.CollectionGroupData(id: self.collectionGroupID).active:
					"Collection group inactive"
				DSSCollection.validateComparator(comparator: comparator) == true:
					"Slot submitted with unsupported comparator"
			}
			let item = DSSCollection.Item(itemID: itemID, points: points, itemType: itemType, comparator: comparator)
			self.items.append(item)
			emit ItemCreatedInSlot(itemID: itemID, points: points, itemType: itemType, comparator: comparator, slotID: self.id, collectionGroupID: self.collectionGroupID)
		}
		
		init(collectionGroupID: UInt64, logicalOperator: String, required: Bool, typeName: Type, metadata:{ String: String}){ 
			pre{ 
				DSSCollection.CollectionGroupData(id: collectionGroupID).active:
					"Collection group inactive"
				DSSCollection.validateLogicalOperator(logicalOperator: logicalOperator) == true:
					"Slot submitted with unsupported logical operator"
			}
			self.id = self.uuid
			self.collectionGroupID = collectionGroupID
			self.logicalOperator = logicalOperator
			self.required = required
			self.typeName = typeName
			self.metadata = metadata
			self.items = []
			emit SlotCreated(id: self.id, collectionGroupID: self.collectionGroupID, logicalOperator: self.logicalOperator, required: self.required, typeName: self.typeName, metadata: self.metadata)
		}
	}
	
	// A public struct to access CollectionGroup data
	//
	access(all)
	struct CollectionGroupData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let productName: String
		
		access(all)
		let active: Bool
		
		access(all)
		let endTime: UFix64?
		
		access(all)
		let metadata:{ String: String}
		
		view init(id: UInt64){ 
			if let collectionGroup = &DSSCollection.collectionGroupByID[id] as &DSSCollection.CollectionGroup?{ 
				self.id = collectionGroup.id
				self.name = collectionGroup.name
				self.description = collectionGroup.description
				self.productName = collectionGroup.productName
				self.active = collectionGroup.active
				self.endTime = collectionGroup.endTime
				self.metadata = *collectionGroup.metadata
			} else{ 
				panic("CollectionGroup does not exist")
			}
		}
	}
	
	// A top-level CollectionGroup with a unique ID and name
	//
	access(all)
	resource CollectionGroup{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let productName: String
		
		access(all)
		var active: Bool
		
		access(all)
		let endTime: UFix64?
		
		access(all)
		var numMinted: UInt64
		
		access(all)
		let metadata:{ String: String}
		
		// Close this collection group
		//
		access(contract)
		fun close(){ 
			pre{ 
				self.active:
					"Already deactivated"
			}
			self.active = false
			emit CollectionGroupClosed(id: self.id)
		}
		
		// Mint a DSSCollection NFT in this group
		//
		access(all)
		fun mint(completionAddress: String, level: UInt8): @DSSCollection.NFT{ 
			pre{ 
				!self.active:
					"Cannot mint an active collection group"
				DSSCollection.validateTimeBound(endTime: self.endTime) == true:
					"Cannot mint a collection group outside of time bounds"
				level <= 10:
					"Token level must be less than 10"
			}
			
			// Create the DSSCollection NFT, filled out with our information
			//
			let dssCollectionNFT <- create NFT(collectionGroupID: self.id, serialNumber: self.numMinted + 1, completionAddress: completionAddress, level: level, extensionData:{} )
			DSSCollection.totalSupply = DSSCollection.totalSupply + 1
			self.numMinted = self.numMinted + 1 as UInt64
			return <-dssCollectionNFT
		}
		
		init(name: String, description: String, productName: String, endTime: UFix64?, metadata:{ String: String}){ 
			pre{ 
				DSSCollection.validateTimeBound(endTime: endTime) == true:
					"Cannot create expired timebound collection group"
			}
			self.id = self.uuid
			self.name = name
			self.description = description
			self.productName = productName
			self.active = true
			self.endTime = endTime
			self.numMinted = 0 as UInt64
			self.metadata = metadata
			emit CollectionGroupCreated(id: self.id, name: self.name, description: self.description, productName: self.productName, endTime: self.endTime, metadata: self.metadata)
		}
	}
	
	// Get the publicly available data for a CollectionGroup by id
	//
	access(all)
	fun getCollectionGroupData(id: UInt64): DSSCollection.CollectionGroupData{ 
		pre{ 
			DSSCollection.collectionGroupByID[id] != nil:
				"Cannot borrow collection group, no such id"
		}
		return DSSCollection.CollectionGroupData(id: id)
	}
	
	// Get the publicly available data for a Slot by id
	//
	access(all)
	fun getSlotData(id: UInt64): DSSCollection.SlotData{ 
		pre{ 
			DSSCollection.slotByID[id] != nil:
				"Cannot borrow slot, no such id"
		}
		return DSSCollection.SlotData(id: id)
	}
	
	// Validate time range of collection group
	//
	access(all)
	view fun validateTimeBound(endTime: UFix64?): Bool{ 
		if endTime == nil{ 
			return true
		}
		if endTime! >= getCurrentBlock().timestamp{ 
			return true
		}
		return false
	}
	
	// Validate logical operator of slot
	//
	access(all)
	view fun validateLogicalOperator(logicalOperator: String): Bool{ 
		if logicalOperator == "OR" || logicalOperator == "AND"{ 
			return true
		}
		return false
	}
	
	// Validate comparator of item
	//
	access(all)
	view fun validateComparator(comparator: String): Bool{ 
		if comparator == ">" || comparator == "<" || comparator == "="{ 
			return true
		}
		return false
	}
	
	// Get the nftIds for each completed collection for a given address
	//
	access(all)
	fun getCompletedCollectionIDs(address: Address): [CollectionCompletedWith]?{ 
		return DSSCollection.completedCollections[address]
	}
	
	// A DSSCollection NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let collectionGroupID: UInt64
		
		access(all)
		let serialNumber: UInt64
		
		access(all)
		let completionDate: UFix64
		
		access(all)
		let completionAddress: String
		
		access(all)
		let level: UInt8
		
		// Placeholder for future updates
		access(all)
		let extensionData:{ String: AnyStruct}
		
		access(all)
		fun name(): String{ 
			let collectionGroupData: DSSCollection.CollectionGroupData = DSSCollection.getCollectionGroupData(id: self.collectionGroupID)
			let level: String = self.level.toString()
			return collectionGroupData.name.concat(" Level ").concat(level).concat(" Completion Token")
		}
		
		access(all)
		fun description(): String{ 
			let serialNumber: String = self.serialNumber.toString()
			let completionDate: String = self.completionDate.toString()
			return "Completed by ".concat(self.completionAddress).concat(" on ").concat(completionDate).concat(" with serial number ").concat(serialNumber)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			return MetadataViews.Display(name: self.name(), description: self.description(), thumbnail: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/dl-nfl-assets-prod/static/images/collection-group/token-placeholder.png"))
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(collectionGroupID: UInt64, serialNumber: UInt64, completionAddress: String, level: UInt8, extensionData:{ String: AnyStruct}){ 
			pre{ 
				DSSCollection.collectionGroupByID[collectionGroupID] != nil:
					"no such collectionGroupID"
			}
			self.id = self.uuid
			self.collectionGroupID = collectionGroupID
			self.serialNumber = serialNumber
			self.completionDate = getCurrentBlock().timestamp
			self.completionAddress = completionAddress
			self.level = level
			self.extensionData = extensionData
			emit CollectionNFTMinted(id: self.id, collectionGroupID: self.collectionGroupID, serialNumber: self.serialNumber, completionAddress: self.completionAddress, completionDate: self.completionDate, level: self.level)
		}
	}
	
	// A public collection interface that allows DSSCollection NFTs to be borrowed
	//
	access(all)
	resource interface DSSCollectionNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowDSSCollectionNFT(id: UInt64): &DSSCollection.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Moment NFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// An NFT Collection
	//
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, DSSCollectionNFTCollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an UInt64 ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @DSSCollection.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// batchDeposit takes a Collection object as an argument
		// and deposits each contained NFT into this Collection
		//
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			let keys = tokens.getIDs()
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			destroy tokens
		}
		
		// getIDs returns an array of the IDs that are in the collection
		//
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Cannot borrow NFT, no such id"
			}
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowDSSCollectionNFT gets a reference to an NFT in the collection
		//
		access(all)
		fun borrowDSSCollectionNFT(id: UInt64): &DSSCollection.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				if let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?{ 
					return ref! as! &DSSCollection.NFT
				}
				return nil
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let dssNFT = nft as! &DSSCollection.NFT
			return dssNFT as &{ViewResolver.Resolver}
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
	
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// An interface containing the Admin function that allows minting NFTs
	//
	access(all)
	resource interface NFTMinter{ 
		access(all)
		fun mintNFT(collectionGroupID: UInt64, completionAddress: String, level: UInt8): @DSSCollection.NFT
	}
	
	// A resource that allows managing metadata and minting NFTs
	//
	access(all)
	resource Admin: NFTMinter{ 
		// Record the nftIds that were used to complete a CollectionGroup
		//
		access(all)
		fun completedCollectionGroup(collectionGroupID: UInt64, userAddress: Address, nftIDs: [UInt64]){ 
			let collection = CollectionCompletedWith(collectionGroupID: collectionGroupID, nftIDs: nftIDs)
			if DSSCollection.completedCollections[userAddress] == nil{ 
				DSSCollection.completedCollections[userAddress] = [collection]
			} else{ 
				(DSSCollection.completedCollections[userAddress]!).append(collection)
			}
			emit CollectionNFTCompletedWith(collectionGroupID: collectionGroupID, completionAddress: userAddress.toString(), completionNftIds: nftIDs)
		}
		
		// Borrow a Collection Group
		//
		access(all)
		fun borrowCollectionGroup(id: UInt64): &DSSCollection.CollectionGroup{ 
			pre{ 
				DSSCollection.collectionGroupByID[id] != nil:
					"Cannot borrow collection group, no such id"
			}
			return (&DSSCollection.collectionGroupByID[id] as &DSSCollection.CollectionGroup?)!
		}
		
		// Borrow a Slot
		//
		access(all)
		fun borrowSlot(id: UInt64): &DSSCollection.Slot{ 
			pre{ 
				DSSCollection.slotByID[id] != nil:
					"Cannot borrow slot, no such id"
			}
			return (&DSSCollection.slotByID[id] as &DSSCollection.Slot?)!
		}
		
		// Create a Collection Group
		//
		access(all)
		fun createCollectionGroup(name: String, description: String, productName: String, endTime: UFix64?, metadata:{ String: String}): UInt64{ 
			let collectionGroup <- create DSSCollection.CollectionGroup(name: name, description: description, productName: productName, endTime: endTime, metadata: metadata)
			let collectionGroupID = collectionGroup.id
			DSSCollection.collectionGroupByID[collectionGroup.id] <-! collectionGroup
			return collectionGroupID
		}
		
		// Close a Collection Group
		//
		access(all)
		fun closeCollectionGroup(id: UInt64): UInt64{ 
			if let collectionGroup = &DSSCollection.collectionGroupByID[id] as &DSSCollection.CollectionGroup?{ 
				collectionGroup.close()
				return collectionGroup.id
			}
			panic("collection group does not exist")
		}
		
		// Create a Slot
		//
		access(all)
		fun createSlot(collectionGroupID: UInt64, logicalOperator: String, required: Bool, typeName: Type, metadata:{ String: String}): UInt64{ 
			let slot <- create DSSCollection.Slot(collectionGroupID: collectionGroupID, logicalOperator: logicalOperator, required: required, typeName: typeName, metadata: metadata)
			let slotID = slot.id
			DSSCollection.slotByID[slot.id] <-! slot
			return slotID
		}
		
		// Create an Item in slot
		//
		access(all)
		fun createItemInSlot(itemID: String, points: UInt64, itemType: String, comparator: String, slotID: UInt64){ 
			if let slot = &DSSCollection.slotByID[slotID] as &DSSCollection.Slot?{ 
				slot.createItemInSlot(itemID: itemID, points: points, itemType: itemType, comparator: comparator)
				return
			}
			panic("Slot does not exist")
		}
		
		// Mint a single NFT
		// The CollectionGroup for the given ID must already exist
		//
		access(all)
		fun mintNFT(collectionGroupID: UInt64, completionAddress: String, level: UInt8): @DSSCollection.NFT{ 
			pre{ 
				// Make sure the collection group exists
				DSSCollection.collectionGroupByID.containsKey(collectionGroupID):
					"No such CollectionGroupID"
			}
			let nft <- self.borrowCollectionGroup(id: collectionGroupID).mint(completionAddress: completionAddress, level: level)
			
			// Increment the count of minted NFTs for the Collection Group ID
			let currentCount = DSSCollection.collectionGroupNFTCount[collectionGroupID] ?? 0
			DSSCollection.collectionGroupNFTCount[collectionGroupID] = currentCount + 1
			return <-nft
		}
	}
	
	// DSSCollection contract initializer
	//
	init(){ 
		// Set the named paths
		self.CollectionStoragePath = /storage/DSSCollectionNFTCollection
		self.CollectionPublicPath = /public/DSSCollectionNFTCollection
		self.AdminStoragePath = /storage/CollectionGroupAdmin
		self.MinterPrivatePath = /private/CollectionGroupMinter
		
		// Initialize the entity counts
		self.totalSupply = 0
		
		// Initialize the metadata lookup dictionaries
		self.collectionGroupNFTCount ={} 
		self.collectionGroupByID <-{} 
		self.slotByID <-{} 
		self.completedCollections ={} 
		self.extCollectionGroup ={} 
		
		// Create an Admin resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		// Link capabilites to the admin constrained to the Minter
		// and Metadata interfaces
		var capability_1 = self.account.capabilities.storage.issue<&DSSCollection.Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.MinterPrivatePath)
		emit ContractInitialized()
	}
}
