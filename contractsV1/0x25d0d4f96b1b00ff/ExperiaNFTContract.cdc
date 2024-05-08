import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract ExperiaNFTContract: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	var ExperiaCollectionPublic: PublicPath
	
	// Initialize the total supply
	access(all)
	var totalSupply: UInt64
	
	//total collection created
	access(all)
	var totalCollection: UInt64
	
	/* withdraw event */
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	/* Event that is issued when an NFT is deposited */
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	/* event that is emitted when a new collection is created */
	access(all)
	event NewCollection(collectionName: String, collectionID: UInt64)
	
	/* Event that is emitted when new NFTs are cradled*/
	access(all)
	event NewNFTsminted(amount: UInt64)
	
	/* Event that is emitted when an NFT collection is created */
	access(all)
	event CreateNFTCollection(amount: UInt64, maxNFTs: UInt64)
	
	/* Event that returns how many IDs a collection has */
	access(all)
	event TotalsIDs(ids: [UInt64])
	
	access(all)
	let MinterStoragePath: StoragePath
	
	/* ## ~~This is the contract where we manage the flow of our collections and NFTs~~  ## */
	/* 
		Through the contract you can find variables such as Metadata,
		which are no longer a name to refer to the attributes of our NFTs. 
		which could be the url where our images live
		*/
	
	//In this section you will find our variables and fields for our NFTs and Collections
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The unique ID that each NFT has
		access(all)
		let id: UInt64
		
		access(self)
		var metadata:{ String: AnyStruct}
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		init(id: UInt64, name: String, metadata:{ String: AnyStruct}, thumbnail: String, description: String){ 
			self.id = id
			self.metadata = metadata
			self.name = name
			self.thumbnail = thumbnail
			self.description = description
		}
		
		access(all)
		fun getMetadata():{ String: AnyStruct}{ 
			return self.metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.IPFSFile(cid: self.thumbnail, path: "sm.png"))
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// We define this interface purely as a way to allow users
	// They would use this to only expose getIDs
	// borrowGMDYNFT
	// and idExists fields in their Collection
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun idExists(id: UInt64): Bool
		
		access(all)
		fun getRefNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowExperiaNFT(id: UInt64): &ExperiaNFTContract.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow NFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	// We define this interface simply as a way to allow users to
	// to create a banner of the collections with their Name and Metadata
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		var metadata:{ String: AnyStruct}
		
		access(all)
		var name: String
		
		init(name: String, metadata:{ String: AnyStruct}){ 
			self.ownedNFTs <-{} 
			self.name = name
			self.metadata = metadata
		}
		
		/* Function to remove the NFt from the Collection */
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// If the NFT isn't found, the transaction panics and reverts
			let exist = self.idExists(id: withdrawID)
			if exist == false{ 
				panic("id NFT Not exist")
			}
			let token <- self.ownedNFTs.remove(key: withdrawID)!
			/* Emit event when a common user withdraws an NFT*/
			emit Withdraw(id: withdrawID, from: self.owner?.address)
			return <-token
		}
		
		/*Function to deposit a  NFT in the collection*/
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @ExperiaNFTContract.NFT
			let id: UInt64 = token.id
			self.ownedNFTs[token.id] <-! token
			emit Deposit(id: id, to: self.owner?.address)
		}
		
		//fun get IDs nft
		access(all)
		view fun getIDs(): [UInt64]{ 
			emit TotalsIDs(ids: self.ownedNFTs.keys)
			return self.ownedNFTs.keys
		}
		
		/*Function get Ref NFT*/
		access(all)
		fun getRefNFT(id: UInt64): &{NonFungibleToken.NFT}{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		/*Function borrow NFT*/
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			if self.ownedNFTs[id] != nil{ 
				return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			}
			panic("not found NFT")
		}
		
		access(all)
		fun borrowExperiaNFT(id: UInt64): &ExperiaNFTContract.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &ExperiaNFTContract.NFT
			}
			panic("not found NFT")
		}
		
		// fun to check if the NFT exists
		access(all)
		fun idExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
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
	
	// We define this interface simply as a way to allow users to
	// to add the first NFTs to an empty collection.
	access(all)
	resource interface NFTCollectionReceiver{ 
		access(all)
		fun generateNFT(amount: UInt64, collection: Capability<&ExperiaNFTContract.Collection>)
		
		access(all)
		fun getQuantityAvailablesForCreate(): Int
	}
	
	access(all)
	resource NFTTemplate: NFTCollectionReceiver{ 
		access(self)
		var metadata:{ String: AnyStruct}
		
		// array NFT
		access(self)
		var collectionNFT: [UInt64]
		
		access(self)
		var counteriDs: [UInt64]
		
		access(all)
		let name: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let description: String
		
		access(all)
		let maximum: UInt64
		
		init(name: String, metadata:{ String: AnyStruct}, thumbnail: String, description: String, amountToCreate: UInt64, maximum: UInt64, collection: Capability<&ExperiaNFTContract.Collection>){ 
			self.metadata = metadata
			self.name = name
			self.maximum = maximum
			self.thumbnail = thumbnail
			self.description = description
			self.collectionNFT = []
			self.counteriDs = []
			self.generateNFT(amount: amountToCreate, collection: collection)
		}
		
		access(all)
		fun generateNFT(amount: UInt64, collection: Capability<&ExperiaNFTContract.Collection>){ 
			if Int(amount) < 0{ 
				panic("Error amount should be greather than 0")
			}
			if amount > self.maximum{ 
				panic("Error amount is greater than maximun")
			}
			let newTotal = Int(amount) + self.collectionNFT.length
			if newTotal > Int(self.maximum){ 
				panic("The collection is already complete or The amount of nft sent exceeds the maximum amount")
			}
			var i = 0
			let collectionBorrow = collection.borrow() ?? panic("cannot borrow collection")
			emit NewNFTsminted(amount: amount)
			while i < Int(amount){ 
				ExperiaNFTContract.totalSupply = ExperiaNFTContract.totalSupply + 1
				let newNFT <- create NFT(id: ExperiaNFTContract.totalSupply, name: self.name, metadata: self.metadata, thumbnail: self.thumbnail, description: self.description)
				collectionBorrow.deposit(token: <-newNFT)
				self.collectionNFT.append(ExperiaNFTContract.totalSupply)
				self.counteriDs.append(ExperiaNFTContract.totalSupply)
				i = i + 1
			}
			emit TotalsIDs(ids: self.counteriDs)
			self.counteriDs = []
		}
		
		access(all)
		fun getQuantityAvailablesForCreate(): Int{ 
			return Int(self.maximum) - self.collectionNFT.length
		}
	}
	
	access(all)
	resource NFTMinter{ 
		access(all)
		fun createNFTTemplate(name: String, metadata:{ String: AnyStruct}, thumbnail: String, description: String, amountToCreate: UInt64, maximum: UInt64, collection: Capability<&ExperiaNFTContract.Collection>): @NFTTemplate{ 
			emit CreateNFTCollection(amount: amountToCreate, maxNFTs: maximum)
			return <-create NFTTemplate(name: name, metadata: metadata, thumbnail: thumbnail, description: description, amountToCreate: amountToCreate, maximum: maximum, collection: collection)
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection(name: "", metadata:{} )
	}
	
	access(all)
	fun createEmptyCollectionNFT(name: String, metadata:{ String: AnyStruct}): @{NonFungibleToken.Collection}{ 
		var newID = ExperiaNFTContract.totalCollection + 1
		ExperiaNFTContract.totalCollection = newID
		emit NewCollection(collectionName: name, collectionID: ExperiaNFTContract.totalCollection)
		return <-create Collection(name: name, metadata: metadata)
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		// Initialize the total collection
		self.totalCollection = 0
		self.MinterStoragePath = /storage/experiaMinterV1
		self.ExperiaCollectionPublic = /public/ExperiaCollectionPublic
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
