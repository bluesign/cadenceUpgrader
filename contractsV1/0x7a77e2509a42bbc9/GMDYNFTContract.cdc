import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract GMDYNFTContract: NonFungibleToken{ 
	
	// Initialize the total supply
	access(all)
	var totalSupply: UInt64
	
	//variable that stores the account address that created the contract
	access(all)
	let privateKey: Address
	
	//total collection created
	access(all)
	var totalCollection: UInt64
	
	access(all)
	event ContractInitialized()
	
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
		
		access(all)
		var metadata:{ String: AnyStruct}
		
		access(all)
		let nftType: String
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		init(id: UInt64, name: String, metadata:{ String: AnyStruct}, nftType: String, thumbnail: String, description: String){ 
			self.id = id
			self.metadata = metadata
			self.nftType = nftType
			self.name = name
			self.thumbnail = thumbnail
			self.description = description
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun getnftType(): String{ 
			return self.nftType
		}
		
		access(all)
		fun getMetadata(): AnyStruct?{ 
			return self.metadata
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
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
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}
		
		access(all)
		fun borrowGMDYNFT(id: UInt64): &GMDYNFTContract.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow NFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	// We define this interface simply as a way to allow users to
	// to create a banner of the collections with their Name and Metadata
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @GMDYNFTContract.NFT
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
		fun borrowGMDYNFT(id: UInt64): &GMDYNFTContract.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &GMDYNFTContract.NFT
			}
			panic("not found NFT")
		}
		
		// fun to check if the NFT exists
		access(all)
		fun idExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			let gmdyNFT = nft as! &GMDYNFTContract.NFT
			return gmdyNFT as &{ViewResolver.Resolver}
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
		fun generateNFT(amount: UInt64, collection: Capability<&GMDYNFTContract.Collection>)
		
		access(all)
		fun getQuantityAvailablesForCreate(): Int
	}
	
	access(all)
	resource NFTTemplate: NFTCollectionReceiver{ 
		access(all)
		var metadata:{ String: AnyStruct}
		
		access(all)
		let nftType: String
		
		// array NFT
		access(all)
		var collectionNFT: [UInt64]
		
		access(all)
		var counteriDs: [UInt64]
		
		access(all)
		let name: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let description: String
		
		access(all)
		let maximum: UInt64
		
		init(name: String, nftType: String, metadata:{ String: AnyStruct}, thumbnail: String, description: String, amountToCreate: UInt64, maximum: UInt64, collection: Capability<&GMDYNFTContract.Collection>){ 
			self.metadata = metadata
			self.name = name
			self.nftType = nftType
			self.maximum = maximum
			self.thumbnail = thumbnail
			self.description = description
			self.collectionNFT = []
			self.counteriDs = []
			self.generateNFT(amount: amountToCreate, collection: collection)
		}
		
		access(all)
		fun generateNFT(amount: UInt64, collection: Capability<&GMDYNFTContract.Collection>){ 
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
				GMDYNFTContract.totalSupply = GMDYNFTContract.totalSupply + 1 as UInt64
				let newNFT <- create NFT(id: GMDYNFTContract.totalSupply, name: self.name, metadata: self.metadata, nftType: self.nftType, thumbnail: self.thumbnail, description: self.description)
				collectionBorrow.deposit(token: <-newNFT)
				self.collectionNFT.append(GMDYNFTContract.totalSupply)
				self.counteriDs.append(GMDYNFTContract.totalSupply)
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
	fun createNFTTemplate(key: AuthAccount, name: String, nftType: String, metadata:{ String: AnyStruct}, thumbnail: String, description: String, amountToCreate: UInt64, maximum: UInt64, collection: Capability<&GMDYNFTContract.Collection>): @NFTTemplate{ 
		if key.address != self.privateKey{ 
			panic("Address Incorrect")
		}
		emit CreateNFTCollection(amount: amountToCreate, maxNFTs: maximum)
		return <-create NFTTemplate(name: name, nftType: nftType, metadata: metadata, thumbnail: thumbnail, description: description, amountToCreate: amountToCreate, maximum: maximum, collection: collection)
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection(name: "", metadata:{} )
	}
	
	access(all)
	fun createEmptyCollectionNFT(name: String, metadata:{ String: AnyStruct}): @{NonFungibleToken.Collection}{ 
		var newID = GMDYNFTContract.totalCollection + 1
		GMDYNFTContract.totalCollection = newID
		emit NewCollection(collectionName: name, collectionID: GMDYNFTContract.totalCollection)
		return <-create Collection(name: name, metadata: metadata)
	}
	
	init(){ 
		//Initialize the keys Address
		self.privateKey = self.account.address
		// Initialize the total supply
		self.totalSupply = 0
		// Initialize the total collection
		self.totalCollection = 0
		emit ContractInitialized()
	}
}
