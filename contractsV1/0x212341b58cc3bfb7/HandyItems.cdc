import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

// HandyItems
//
access(all)
contract HandyItems: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, name: String, tokenURI: String, color: String, info: String)
	
	access(all)
	event NewSeriesStarted(newCurrentSeries: UInt32)
	
	access(all)
	event SeriesCreated(id: UInt32, name: String)
	
	access(all)
	event EditionCreated(id: UInt32, name: String)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of HandyItems that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// currentSeries
	//
	access(all)
	var currentSeries: UInt32
	
	access(all)
	var nextSeriesID: UInt32
	
	// Indicates next edition's ID. 
	// 
	access(all)
	var nextEditionID: UInt32
	
	access(all)
	var nextSetID: UInt32
	
	// seriesList
	// Holds data about each series
	//
	access(self)
	var seriesList:{ UInt32: SeriesData}
	
	// editionList
	// Holds data about each edition
	//
	access(self)
	var editionList:{ UInt32: EditionData}
	
	access(self)
	var sets: @{UInt32: Set}
	
	access(all)
	struct SeriesData{ 
		// Series's ID
		//
		access(all)
		let id: UInt32
		
		// Holds metadata about series
		//
		access(all)
		let metadata:{ String: String}
		
		init(metadata:{ String: String}){ 
			pre{ 
				metadata.length != 0:
					"New Series metadata cannot be empty"
			}
			self.id = HandyItems.nextSeriesID
			self.metadata = metadata
		}
	}
	
	access(all)
	struct EditionData{ 
		// Edition's ID
		//
		access(all)
		let id: UInt32
		
		access(all)
		let series: UInt32
		
		// Holds metadata about edition
		//
		access(all)
		let metadata:{ String: String}
		
		init(series: UInt32, metadata:{ String: String}){ 
			pre{ 
				metadata.length != 0:
					"New Edition metadata cannot be empty"
			}
			self.id = HandyItems.nextEditionID
			self.series = series
			self.metadata = metadata
		}
	}
	
	access(all)
	struct QuerySeriesData{ 
		access(all)
		let id: UInt32
		
		access(all)
		let name: String
		
		access(all)
		let image: String
		
		init(id: UInt32){ 
			var series = HandyItems.seriesList[id]!
			self.id = id
			self.name = series.metadata["name"] ?? ""
			self.image = series.metadata["image"] ?? ""
		}
	}
	
	access(all)
	struct QueryEditionData{ 
		access(all)
		let id: UInt32
		
		access(all)
		let name: String
		
		access(all)
		let image: String
		
		init(id: UInt32){ 
			var edition = HandyItems.editionList[id]!
			self.id = id
			self.name = edition.metadata["name"] ?? ""
			self.image = edition.metadata["image"] ?? ""
		}
	}
	
	access(all)
	struct QuerySetEditionData{ 
		access(all)
		let id: UInt32
		
		access(all)
		let editionID: UInt32
		
		access(all)
		let name: String
		
		access(all)
		let image: String
		
		init(id: UInt32){ 
			self.editionID = HandyItems.sets[id]?.editionID!
			var edition = HandyItems.editionList[self.editionID]!
			self.id = id
			self.name = edition.metadata["name"] ?? ""
			self.image = edition.metadata["image"] ?? ""
		}
	}
	
	access(all)
	struct QuerySetData{ 
		access(all)
		let id: UInt32
		
		access(all)
		let seriesID: UInt32
		
		access(all)
		let editionID: UInt32
		
		access(all)
		let quantity: UInt32
		
		access(all)
		let price: UFix64
		
		access(all)
		let isSerial: Bool
		
		access(all)
		var metadata:{ String: String}
		
		access(all)
		var numberMinted: UInt32
		
		init(setID: UInt32){ 
			pre{ 
				HandyItems.sets[setID] != nil:
					"The set with the provided ID does not exist"
			}
			let set = &HandyItems.sets[setID] as &HandyItems.Set?
			self.id = setID
			self.seriesID = set.seriesID
			self.editionID = set.editionID
			self.quantity = set.quantity
			self.price = set.price
			self.isSerial = set.isSerial
			self.metadata = set.metadata
			self.numberMinted = set.numberMinted
		}
	}
	
	// NFT
	// A Handy Item as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		//
		access(all)
		let id: UInt64
		
		access(all)
		let setID: UInt32
		
		access(all)
		let serialID: UInt32
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(setID: UInt32, serialID: UInt32){ 
			// Increment the global Moment IDs
			HandyItems.totalSupply = HandyItems.totalSupply + UInt64(1)
			self.id = HandyItems.totalSupply
			self.setID = setID
			self.serialID = serialID
		}
	}
	
	access(all)
	resource Set{ 
		access(all)
		let id: UInt32
		
		access(all)
		let seriesID: UInt32
		
		access(all)
		let editionID: UInt32
		
		access(all)
		let quantity: UInt32
		
		access(all)
		let price: UFix64
		
		access(all)
		let isSerial: Bool
		
		access(all)
		var metadata:{ String: String}
		
		access(all)
		var numberMinted: UInt32
		
		access(all)
		let leftIDs:{ UInt32: UInt32}
		
		init(seriesID: UInt32, editionID: UInt32, quantity: UInt32, price: UFix64, isSerial: Bool, metadata:{ String: String}){ 
			self.id = HandyItems.nextSetID
			self.seriesID = seriesID
			self.editionID = editionID
			self.quantity = quantity
			self.price = price
			self.isSerial = isSerial
			self.metadata = metadata
			self.numberMinted = 0
			self.leftIDs ={} 
		}
		
		/*
					var i: UInt32 = 1
		
					while i <= quantity {
						self.leftIDs[i] = i
						i = i + UInt32(1)
					} */
		
		access(all)
		fun mintNFT(payment: @{FungibleToken.Vault}): @{NonFungibleToken.NFT}{ 
			pre{ 
				self.numberMinted < self.quantity:
					"no nft left"
				// payment.isInstance(self.details.salePaymentVaultType): "payment vault is not requested fungible token"
				payment.balance == self.price:
					"payment vault does not contain requested price"
			}
			
			// deposit it in the recipient's account using their reference
			// recipient.deposit(token: <-create HandyItems.NFT(setID: self.id, serialID: 1))
			let mainFUSDVault = (self.owner!).capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver).borrow<&{FungibleToken.Receiver}>() ?? panic("Could not borrow receiver reference to the recipient's Vault")
			mainFUSDVault.deposit(from: <-payment)
			let numberLeft = self.quantity - self.numberMinted
			let randID = UInt32(revertibleRandom<UInt64>() % UInt64(numberLeft) + 1)
			let token <- create HandyItems.NFT(setID: self.id,															   //				serialID: self.leftIDs[randID]!)
															   serialID: UInt32(revertibleRandom<UInt64>() % UInt64(self.quantity) + 1))
			
			//			self.leftIDs[randID] = self.leftIDs[numberLeft]!
			self.numberMinted = self.numberMinted + 1 as UInt32
			return <-token
		}
	}
	
	// This is the interface that users can cast their HandyItems Collection as
	// to allow others to deposit HandyItems into their Collection. It also allows for reading
	// the details of HandyItems in the Collection.
	access(all)
	resource interface HandyItemsCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowHandyItem(id: UInt64): &HandyItems.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow HandyItem reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of HandyItem NFTs owned by an account
	//
	access(all)
	resource Collection: HandyItemsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
			let token <- token as! @HandyItems.NFT
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
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// borrowHandyItem
		// Gets a reference to an NFT in the collection as a HandyItem,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the HandyItem.
		//
		access(all)
		fun borrowHandyItem(id: UInt64): &HandyItems.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &HandyItems.NFT
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
		access(all)
		fun createSeries(metadata:{ String: String}): UInt32{ 
			// Create the new series
			var newSeries = SeriesData(metadata: metadata)
			let newID = newSeries.id
			HandyItems.nextSeriesID = HandyItems.nextSeriesID + UInt32(1)
			HandyItems.seriesList[newID] = newSeries
			
			// emit SeriesCreated(id: newID, name: name)
			return newID
		}
		
		access(all)
		fun createEdition(series: UInt32, metadata:{ String: String}): UInt32{ 
			// Create the new edition
			var newEdition = EditionData(series: series, metadata: metadata)
			let newID = newEdition.id
			HandyItems.nextEditionID = HandyItems.nextEditionID + UInt32(1)
			HandyItems.editionList[newID] = newEdition
			
			// emit EditionCreated(id: newID, name: name)
			return newID
		}
		
		access(all)
		fun createSet(series: UInt32, edition: UInt32, quantity: UInt32, price: UFix64, isSerial: Bool, metadata:{ String: String}): UInt32{ 
			
			// Create the new Set
			var newSet <- create Set(seriesID: series, editionID: edition, quantity: quantity, price: price, isSerial: isSerial, metadata: metadata)
			
			// Increment the setID so that it isn't used again
			HandyItems.nextSetID = HandyItems.nextSetID + UInt32(1)
			let newID = newSet.id
			
			// Store it in the sets mapping field
			HandyItems.sets[newID] <-! newSet
			return newID
		}
		
		access(all)
		fun borrowSet(setID: UInt32): &Set{ 
			pre{ 
				HandyItems.sets[setID] != nil:
					"Cannot borrow Set: The Set doesn't exist"
			}
			return &HandyItems.sets[setID] as &HandyItems.Set?
		}
		
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun mintNFTOrg(recipient: &{NonFungibleToken.CollectionPublic}, name: String, tokenURI: String, color: String, info: String){ 
			emit Minted(id: HandyItems.totalSupply, name: name, tokenURI: tokenURI, color: color, info: info)
			
			// deposit it in the recipient's account using their reference
			// recipient.deposit(token: <-create HandyItems.NFT(initID: HandyItems.totalSupply, initName: name, initUrl: tokenURI, initColor: color, initInfo: info))
			HandyItems.totalSupply = HandyItems.totalSupply + 1 as UInt64
		}
		
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, edition: UInt32, quantity: UInt64, price: UInt64, isSerial: Bool, metadata:{ String: String}){ 
			// emit Minted(id: HandyItems.totalSupply, name: name, tokenURI: tokenURI, color: color, info: info)
			/*
						// deposit it in the recipient's account using their reference
						recipient.deposit(token: <-create HandyItems.NFT(initID: HandyItems.totalSupply, 
							initEditionID: edition, initQuantity: quantity, initPrice: price,
							isSerial: isSerial, initName: metadata["name"]!, initUrl: metadata["img_url"]!, initColor: "", initInfo: ""))
			*/
			
			HandyItems.totalSupply = HandyItems.totalSupply + 1 as UInt64
		}
	}
	
	// fetch
	// Get a reference to a HandyItem from an account's Collection, if available.
	// If an account does not have a HandyItems.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &HandyItems.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&HandyItems.Collection>(HandyItems.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust HandyItems.Collection.borowHandyItem to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowHandyItem(id: itemID)
	}
	
	// 
	// 
	//
	access(all)
	fun getSeries():{ UInt32: QuerySeriesData}{ 
		var ret:{ UInt32: QuerySeriesData} ={} 
		var i: UInt32 = 0
		while i < self.nextSeriesID{ 
			ret[i] = QuerySeriesData(id: i)
			i = i + UInt32(1)
		}
		return ret
	}
	
	access(all)
	fun getSeriesData(series: UInt32): QuerySeriesData?{ 
		if HandyItems.seriesList[series] == nil{ 
			return nil
		} else{ 
			return QuerySeriesData(id: series)
		}
	}
	
	// getEditions
	// 
	//
	access(all)
	fun getEditions(series: UInt32):{ UInt32: QueryEditionData}{ 
		var ret:{ UInt32: QueryEditionData} ={} 
		var i: UInt32 = 0
		while i < self.nextEditionID{ 
			if (self.editionList[i]!).series == series{ 
				ret[i] = QueryEditionData(id: i)
			}
			i = i + UInt32(1)
		}
		return ret
	}
	
	access(all)
	fun getEditionData(id: UInt32): QueryEditionData?{ 
		if HandyItems.editionList[id] == nil{ 
			return nil
		} else{ 
			return QueryEditionData(id: id)
		}
	}
	
	access(all)
	fun getAllSets():{ UInt32: QuerySetData}{ 
		var ret:{ UInt32: QuerySetData} ={} 
		var i: UInt32 = 0
		while i < self.nextSetID{ 
			ret[i] = QuerySetData(setID: i)
			i = i + UInt32(1)
		}
		return ret
	}
	
	// 
	access(all)
	fun getSets(series: UInt32):{ UInt32: QuerySetEditionData}{ 
		var ret:{ UInt32: QuerySetEditionData} ={} 
		var i: UInt32 = 0
		while i < self.nextSetID{ 
			if self.sets[i]?.seriesID == series{ 
				ret[i] = QuerySetEditionData(id: i)
			}
			i = i + UInt32(1)
		}
		return ret
	}
	
	access(all)
	fun getSetData(setID: UInt32): QuerySetData?{ 
		if HandyItems.sets[setID] == nil{ 
			return nil
		} else{ 
			return QuerySetData(setID: setID)
		}
	}
	
	access(all)
	fun borrowSet(setID: UInt32): &Set{ 
		pre{ 
			HandyItems.sets[setID] != nil:
				"Cannot borrow Set: The Set doesn't exist"
		}
		
		// Get a reference to the Set and return it
		// use `&` to indicate the reference to the object and type
		return &HandyItems.sets[setID] as &HandyItems.Set?
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/HandyItemsCollection
		self.CollectionPublicPath = /public/HandyItemsCollection
		self.MinterStoragePath = /storage/HandyItemsMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		self.currentSeries = 0
		self.nextSeriesID = 0
		self.nextEditionID = 0
		self.nextSetID = 0
		self.seriesList ={} 
		self.editionList ={} 
		self.sets <-{} 
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
