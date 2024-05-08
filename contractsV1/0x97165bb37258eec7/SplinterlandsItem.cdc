/*
	Description: Central Smart Contract for Splinterlands

	authors: Bilal Shahid bilal@zay.codes
			 Amit Ishairzay amit@zay.codes
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract SplinterlandsItem: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Events
	// -----------------------------------------------------------------------
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// -----------------------------------------------------------------------
	// SplinterlandsItem Events
	// -----------------------------------------------------------------------
	access(all)
	event ItemMinted(id: UInt64, itemID: String)
	
	access(all)
	event AdminDeposit(id: UInt64, itemID: String, bridgeAddress: String)
	
	access(all)
	event ItemDestroyed(id: UInt64, itemID: String)
	
	// -----------------------------------------------------------------------
	// Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPublicPath: PublicPath
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Fields
	// -----------------------------------------------------------------------
	access(all)
	var totalSupply: UInt64
	
	// -----------------------------------------------------------------------
	// Splinterlands Struct Fields
	// -----------------------------------------------------------------------
	access(all)
	struct SplinterlandItemData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let itemID: String
		
		init(id: UInt64, itemID: String){ 
			self.id = id
			self.itemID = itemID
		}
		
		access(all)
		fun getId(): UInt64{ 
			return self.id
		}
		
		access(all)
		fun getItemID(): String{ 
			return self.itemID
		}
	}
	
	access(all)
	struct SplinterlandsItemStateData{ 
		access(self)
		let id: UInt64
		
		access(self)
		let state: SplinterlandsItemState
		
		init(id: UInt64, state: SplinterlandsItemState){ 
			self.id = id
			self.state = state
		}
		
		access(all)
		fun getId(): UInt64{ 
			return self.id
		}
		
		access(all)
		view fun getState(): SplinterlandsItemState{ 
			return self.state
		}
	}
	
	// -----------------------------------------------------------------------
	// Splinterlands Standard Fields
	// -----------------------------------------------------------------------
	access(all)
	var burnedCount: UInt64
	
	access(all)
	enum SplinterlandsItemState: UInt8{ 
		access(all)
		case InFlowCirculation
		
		access(all)
		case OutOfFlowCirculation
		
		access(all)
		case Burned
	}
	
	access(self)
	var itemIDsMinted:{ String: SplinterlandsItemStateData}
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Resources
	// -----------------------------------------------------------------------
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let itemID: String
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64, itemID: String){ 
			self.id = id
			self.itemID = itemID
			SplinterlandsItem.itemIDsMinted[self.itemID] = SplinterlandsItemStateData(id: self.id, state: SplinterlandsItemState.InFlowCirculation)
			emit ItemMinted(id: self.id, itemID: self.itemID)
		}
		
		// We don't really have much metadata to give other than the itemID which is in this already
		// Still creating this function as it may become a standard for other uses in the future
		// and provides an upgradeable location to fill in with more data if needed someday
		access(all)
		fun getMetadata():{ String: String}{ 
			let metadata:{ String: String} ={} 
			metadata["itemID"] = self.itemID
			return metadata
		}
	}
	
	// -----------------------------------------------------------------------
	// SplinterlandsItem Collection Resources
	// -----------------------------------------------------------------------
	access(all)
	resource interface ItemCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowItem(id: UInt64): &SplinterlandsItem.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Item reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ItemCollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Item does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @SplinterlandsItem.NFT
			let id = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			destroy oldToken
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		access(all)
		fun borrowItem(id: UInt64): &SplinterlandsItem.NFT?{ 
			if self.ownedNFTs[id] == nil{ 
				return nil
			} else{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &SplinterlandsItem.NFT
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
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Functions
	// -----------------------------------------------------------------------
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// -----------------------------------------------------------------------
	// SplinterlandsItem Admin Resource
	// -----------------------------------------------------------------------
	access(all)
	resource interface AdminPublic{ // This should be declared immediately before the admin resource 
		
		access(all)
		fun deposit(token: @SplinterlandsItem.NFT, bridgeAddress: String)
	}
	
	access(all)
	resource Admin: AdminPublic{ 
		access(self)
		var adminCollectionPublicCapability: Capability<&SplinterlandsItem.Collection>
		
		init(adminCollectionPublicCapability: Capability<&SplinterlandsItem.Collection>){ 
			self.adminCollectionPublicCapability = adminCollectionPublicCapability
		}
		
		access(all)
		fun mintItem(adminCollection: &SplinterlandsItem.Collection, recipient: &{SplinterlandsItem.ItemCollectionPublic}, itemID: String){ 
			pre{ 
				SplinterlandsItem.itemIDsMinted[itemID] == nil || (SplinterlandsItem.itemIDsMinted[itemID]!).getState() != SplinterlandsItemState.InFlowCirculation:
					"Cannot mint the item. It's already been minted."
			}
			post{ 
				(SplinterlandsItem.itemIDsMinted[itemID]!).getState() == SplinterlandsItemState.InFlowCirculation:
					"Item state not set correctly"
			}
			if SplinterlandsItem.itemIDsMinted[itemID] != nil && (SplinterlandsItem.itemIDsMinted[itemID]!).getState() == SplinterlandsItemState.OutOfFlowCirculation{ 
				// We've minted this item into flow before - and it's still in the admin account.
				// Instead of making a new one, send the existing one.
				let id: UInt64 = (SplinterlandsItem.itemIDsMinted[itemID]!).getId()
				let existingItem <- adminCollection.withdraw(withdrawID: id)
				recipient.deposit(token: <-existingItem)
				SplinterlandsItem.itemIDsMinted[itemID] = SplinterlandsItemStateData(id: id, state: SplinterlandsItemState.InFlowCirculation)
			} else{ 
				let id: UInt64 = SplinterlandsItem.totalSupply
				let newItem: @SplinterlandsItem.NFT <- create SplinterlandsItem.NFT(id: id, itemID: itemID)
				recipient.deposit(token: <-newItem)
				SplinterlandsItem.totalSupply = SplinterlandsItem.totalSupply + 1 as UInt64
				SplinterlandsItem.itemIDsMinted[itemID] = SplinterlandsItemStateData(id: id, state: SplinterlandsItemState.InFlowCirculation)
			}
		}
		
		access(all)
		fun deposit(token: @SplinterlandsItem.NFT, bridgeAddress: String){ 
			let itemID = token.itemID
			let id = token.id
			(self.adminCollectionPublicCapability.borrow()!).deposit(token: <-token)
			SplinterlandsItem.itemIDsMinted[itemID] = SplinterlandsItemStateData(id: id, state: SplinterlandsItemState.OutOfFlowCirculation)
			emit AdminDeposit(id: id, itemID: itemID, bridgeAddress: bridgeAddress)
		}
	}
	
	access(all)
	fun getItemIDs():{ String: SplinterlandsItemStateData}{ 
		return SplinterlandsItem.itemIDsMinted
	}
	
	access(all)
	fun getItemIDState(itemID: String): SplinterlandsItemStateData{ 
		return SplinterlandsItem.itemIDsMinted[itemID]!
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/SplinterlandsItemCollection
		self.CollectionPublicPath = /public/SplinterlandsItemCollection
		self.AdminStoragePath = /storage/SplinterlandsItemAdmin
		self.AdminPublicPath = /public/SplinterlandsItemAdmin
		self.totalSupply = 0
		self.burnedCount = 0
		self.itemIDsMinted ={} 
		
		// Setup Admin Account
		let adminCollection <- SplinterlandsItem.createEmptyCollection(nftType: Type<@SplinterlandsItem.Collection>()) as! @SplinterlandsItem.Collection
		self.account.storage.save(<-adminCollection, to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&SplinterlandsItem.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		let adminCollectionPublicCapability = capability_1
		let admin <- create Admin(adminCollectionPublicCapability: adminCollectionPublicCapability)
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		var capability_2 = self.account.capabilities.storage.issue<&SplinterlandsItem.Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_2, at: self.AdminPublicPath)
		emit ContractInitialized()
	}
}
