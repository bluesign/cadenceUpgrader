/**
* SPDX-License-Identifier: UNLICENSED
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

// Monsoon
// NFT items for cards!
//
access(all)
contract Monsoon: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Destroy(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, templateID: UInt64, typeOfCard: UInt32, universeID: UInt32, numSeries: UInt32, numSerial: UInt32, CID: String)
	
	access(all)
	event monsoonCutPercentageChange(newPercent: UFix64)
	
	access(all)
	event monsoonCutPercentageReceiverChange(newReceiver: Address)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of Monsoon that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// totalSupplyUniverseType
	// Dictionary with the total number minted desglosed by Universe_Type
	//
	access(contract)
	var totalSupplyUniverseType:{ String: UInt64}
	
	// totalBurned
	// Total Number of cards burned in order to get fusion cards
	//
	access(all)
	var totalBurned: UInt64
	
	// monsoonCutSalesPercentage
	// Commission in the market of the sales 
	//
	access(all)
	var monsoonCutPercentage: UFix64
	
	access(all)
	var addressReceivermonsoonCutPercentage: Address
	
	// function to inform about all totals
	access(all)
	fun getTotals():{ String: UInt64}{ 
		var totals:{ String: UInt64} ={} 
		var old = totals.insert(key: "totalSupply", self.totalSupply)
		old = totals.insert(key: "totalBurned", self.totalBurned)
		for key in self.totalSupplyUniverseType.keys{ 
			old = totals.insert(key: key, self.totalSupplyUniverseType[key] ?? 0 as UInt64)
		}
		return totals
	}
	
	access(all)
	struct CardData{ 
		// This is the key of the templateCard
		access(all)
		let templateID: UInt64
		
		// 0 Comun 1 Rare 2 Combination 3 Legendarie
		access(all)
		let typeOfCard: UInt32
		
		// universe of the card (0 Zombicide 1 .....)
		access(all)
		let universeID: UInt32
		
		// printing number (as an book editon)
		access(all)
		let numSeries: UInt32
		
		// Number of the serie in the card
		access(all)
		let numSerial: UInt32
		
		//File static card in ipfs
		access(all)
		let CID: String
		
		init(templateID: UInt64, typeOfCard: UInt32, universeID: UInt32, numSeries: UInt32, numSerial: UInt32, CID: String){ 
			self.templateID = templateID
			self.typeOfCard = typeOfCard
			self.universeID = universeID
			self.numSeries = numSeries
			self.numSerial = numSerial
			self.CID = CID
		}
	}
	
	// NFT
	// A Monsoon Card as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		access(all)
		let data: CardData
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(initID: UInt64, initTemplateID: UInt64, initTypeOfCard: UInt32, initUniverseID: UInt32, initnumSeries: UInt32, initnumSerial: UInt32, initCID: String){ 
			self.id = initID
			self.data = CardData(templateID: initTemplateID, typeOfCard: initTypeOfCard, universeID: initUniverseID, numSeries: initnumSeries, numSerial: initnumSerial, CID: initCID)
			emit Minted(id: self.id, templateID: self.data.templateID, typeOfCard: self.data.typeOfCard, universeID: self.data.universeID, numSeries: self.data.numSeries, numSerial: self.data.numSerial, CID: self.data.CID)
		}
	}
	
	// This is the interface that users can cast their Monsoon Collection as
	// to allow others to deposit Monsoon into their Collection. It also allows for reading
	// the details of Monsoon in the Collection.
	access(all)
	resource interface MonsoonCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		//list of the propertied of the cards collections
		access(all)
		fun listCards():{ UInt64: CardData}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowMonsoonCard(id: UInt64): &Monsoon.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow MonsoonCard reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of MonsoonCard NFTs owned by an account
	//
	access(all)
	resource Collection: MonsoonCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
			let token <- token as! @Monsoon.NFT
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
		
		// listCards
		// functions for list the properties of the user's cards
		//
		access(all)
		fun listCards():{ UInt64: CardData}{ 
			var cardsList:{ UInt64: CardData} ={} 
			for key in self.ownedNFTs.keys{ 
				//let el = &self.ownedNFTs[key] as &Monsoon.NFT
				let ref = &self.ownedNFTs[key] as &{NonFungibleToken.NFT}? //update secure cadence
				
				let el = ref as! &Monsoon.NFT
				cardsList.insert(key: el.id, *el.data)
			}
			return cardsList
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)! //update secure cadence
		
		}
		
		// borrowMonsoonCard
		// Gets a reference to an NFT in the collection as a MonsoonCard,
		// exposing all of its fields.
		// This is safe as there are no functions that can be called on the MonsoonCard.
		//
		access(all)
		fun borrowMonsoonCard(id: UInt64): &Monsoon.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}? // update secure cadence
				
				return ref as! &Monsoon.NFT
			} else{ 
				return nil
			}
		}
		
		// function for burned the cards in order of allow mint a fusion card
		access(all)
		fun batchDestroy(keys: [UInt64]): Int{ 
			var nBurned: Int = 0
			
			// in a first moment check if all the keys exits in the collection before starting to destroy
			for key in keys{ 
				if self.ownedNFTs[key] == nil{ 
					panic("The reference ".concat(key.toString()).concat(" doesn't exits in the account collection"))
				}
			}
			for key in keys{ 
				let token <- self.ownedNFTs.remove(key: key) ?? panic("missing NFT")
				emit Destroy(id: token.id, from: self.owner?.address)
				destroy token
				Monsoon.totalBurned = Monsoon.totalBurned + 1 as UInt64
				nBurned = nBurned + 1
			}
			return nBurned
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, templateID: UInt64, typeOfCard: UInt32, universeID: UInt32, numSeries: UInt32, numSerial: UInt32, CID: String){ 
			emit Minted(id: Monsoon.totalSupply, templateID: templateID, typeOfCard: typeOfCard, universeID: universeID, numSeries: numSeries, numSerial: numSerial, CID: CID)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create Monsoon.NFT(initID: Monsoon.totalSupply, initTemplateID: templateID, initTypeOfCard: typeOfCard, initUniverseID: universeID, initnumSeries: numSeries, initnumSerial: numSerial, initCID: CID))
			Monsoon.totalSupply = Monsoon.totalSupply + 1 as UInt64
			
			// store the total supply by universe and type of cards
			let keyUnvTyp: String = universeID.toString().concat("_").concat(typeOfCard.toString())
			if !Monsoon.totalSupplyUniverseType.containsKey(keyUnvTyp){ 
				Monsoon.totalSupplyUniverseType.insert(key: keyUnvTyp, 1)
			} else{ 
				var auxCont = Monsoon.totalSupplyUniverseType[keyUnvTyp] ?? 0 as UInt64
				auxCont = auxCont + 1 as UInt64
				Monsoon.totalSupplyUniverseType.insert(key: keyUnvTyp, auxCont)
			}
		//-------------------------------------------------------
		}
		
		access(all)
		fun changeMonsoonCutPercentage(newCutPercentage: UFix64){ 
			Monsoon.monsoonCutPercentage = newCutPercentage
			emit monsoonCutPercentageChange(newPercent: Monsoon.monsoonCutPercentage)
		}
		
		access(all)
		fun changeaddressReceivermonsoonCutPercentage(newReceiver: Address){ 
			Monsoon.addressReceivermonsoonCutPercentage = newReceiver
			emit monsoonCutPercentageReceiverChange(newReceiver: Monsoon.addressReceivermonsoonCutPercentage)
		}
	}
	
	// fetch
	// Get a reference to a MonsoonCard from an account's Collection, if available.
	// If an account does not have a Monsoon.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &Monsoon.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&Monsoon.Collection>(Monsoon.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust Monsoon.Collection.borowMonsoonCard to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowMonsoonCard(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/monsoonDigitalCollection
		self.CollectionPublicPath = /public/monsoonDigitalCollection
		self.MinterStoragePath = /storage/monsoonDigitalMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		self.totalSupplyUniverseType ={} 
		self.totalBurned = 0
		self.monsoonCutPercentage = 0.05
		self.addressReceivermonsoonCutPercentage = self.account.address
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
