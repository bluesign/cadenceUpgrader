import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Ezy3dItems: NonFungibleToken{ 
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, TaskId: String, TaskName: String, ImgId: String, TaskFrame: String, TaskHolder: String, TaskDetail: String)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of Ezy3dItems that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// A Exy3d Item as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		// 作品ID
		access(all)
		let TaskId: String
		
		// 作品名称
		access(all)
		let TaskName: String
		
		// 缩略图片ID
		access(all)
		let ImgId: String
		
		// 作品帧数
		access(all)
		let TaskFrame: String
		
		// 作品持有者
		access(all)
		let TaskHolder: String
		
		// 作品详情
		access(all)
		let TaskDetail: String
		
		init(id: UInt64, TaskId: String, TaskName: String, ImgId: String, TaskFrame: String, TaskHolder: String, TaskDetail: String){ 
			self.id = id
			self.TaskId = TaskId
			self.TaskName = TaskName
			self.ImgId = ImgId
			self.TaskFrame = TaskFrame
			self.TaskHolder = TaskHolder
			self.TaskDetail = TaskDetail
		}
		
		access(all)
		fun description(): String{ 
			return "TaskId: ".concat(self.TaskId).concat(" TaskName:").concat(self.TaskName)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.TaskName, description: self.description(), thumbnail: self.TaskId, thumbnail: self.ImgId)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// This is the interface that users can cast their Ezy3dItems Collection as
	// to allow others to deposit Ezy3dItems into their Collection. It also allows for reading
	// the details of Ezy3dItems in the Collection.
	access(all)
	resource interface Ezy3dItemsCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowEzy3dItem(id: UInt64): &Ezy3dItems.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Ezy3dItem reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of Ezy3dItem NFTs owned by an account
	//
	access(all)
	resource Collection: Ezy3dItemsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Ezy3dItems.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs
		// Returns an array of the IDs that are in the collection
		//
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
		
		// borrowEzy3dItem
		// Gets a reference to an NFT in the collection as a Ezy3dItem,
		// exposing all of its fields (including the typeID & rarityID).
		// This is safe as there are no functions that can be called on the Ezy3dItem.
		//
		access(all)
		fun borrowEzy3dItem(id: UInt64): &Ezy3dItems.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Ezy3dItems.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let Ezy3dItem = nft as! &Ezy3dItems.NFT
			return Ezy3dItem as &{ViewResolver.Resolver}
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
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, TaskId: String, TaskName: String, ImgId: String, taskFrame: String, taskHolder: String, taskDetail: String){ 
			// deposit it in the recipient's account using their reference
			//  TaskId: String, TaskName: String, ImgId: String
			recipient.deposit(token: <-create Ezy3dItems.NFT(id: Ezy3dItems.totalSupply, TaskId: TaskId, TaskName: TaskName, ImgId: ImgId, TaskFrame: taskFrame, TaskHolder: taskHolder, TaskDetail: taskDetail))
			emit Minted(id: Ezy3dItems.totalSupply, TaskId: TaskId, TaskName: TaskName, ImgId: ImgId, TaskFrame: taskFrame, TaskHolder: taskHolder, TaskDetail: taskDetail)
			Ezy3dItems.totalSupply = Ezy3dItems.totalSupply + 1 as UInt64
		}
	}
	
	// fetch
	// Get a reference to a Ezy3dItem from an account's Collection, if available.
	// If an account does not have a Ezy3dItems.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &Ezy3dItems.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&Ezy3dItems.Collection>(Ezy3dItems.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust Ezy3dItems.Collection.borowEzy3dItem to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowEzy3dItem(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/Ezy3dItemsCollectionV1
		self.CollectionPublicPath = /public/Ezy3dItemsCollectionV1
		self.MinterStoragePath = /storage/Ezy3dItemsMinterV1
		// Initialize the total supply
		self.totalSupply = 0
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
