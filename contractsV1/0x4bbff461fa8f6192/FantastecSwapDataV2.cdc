/**
# Contract: FantastecSwapDataV2
# Description:

The purpose of this contract is to provide a central location to hold and maintain metadata about Fantastec Swap's Cards and Collections.

Collections represent a themed set of Cards, as indicated on their attributes.
Collections have 0 or more Cards associated with them.
Cards represent an individual item or moment of interest - a digital card of a player or stadium, a video moment, a VR scene, or access to other resources.
An NFT will be minted against individual Card.
*/

import FantastecSwapDataProperties from "./FantastecSwapDataProperties.cdc"

access(all)
contract FantastecSwapDataV2{ 
	/** EVENTS **/
	// Contract Events
	access(all)
	event ContractInitialized()
	
	// Card Events
	access(all)
	event CardCreated(id: UInt64)
	
	access(all)
	event CardUpdated(id: UInt64)
	
	access(all)
	event CardDeleted(id: UInt64)
	
	// CardCollection Events
	access(all)
	event CardCollectionCreated(id: UInt64)
	
	access(all)
	event CardCollectionUpdated(id: UInt64)
	
	access(all)
	event CardCollectionDeleted(id: UInt64)
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let DataStoragePath: StoragePath
	
	/** CONTRACT LEVEL STRUCTS */
	access(all)
	struct CardCollectionData{ 
		access(all)
		let id: UInt64
		
		access(all)
		var title: String
		
		access(all)
		var description: String
		
		access(all)
		var type: String
		
		access(all)
		var mintVolume: UInt64
		
		access(all)
		var metadata:{ String: [{FantastecSwapDataProperties.MetadataElement}]}
		
		access(contract)
		fun save(){ 
			FantastecSwapDataV2.getDataManager().setCardCollectionData(self)
		}
		
		init(
			_ id: UInt64,
			_ title: String,
			_ description: String,
			_ type: String,
			_ mintVolume: UInt64
		){ 
			self.id = id
			self.title = title
			self.description = description
			self.type = type
			self.mintVolume = mintVolume
			self.metadata ={} 
		}
		
		access(contract)
		fun addMetadata(_ type: String, _ metadata:{ FantastecSwapDataProperties.MetadataElement}){ 
			if self.metadata[type] == nil{ 
				self.metadata[type] = []
			}
			self.metadata[type] = FantastecSwapDataV2.addToMetadata(
					type,
					self.metadata[type]!,
					metadata
				)
		}
		
		access(contract)
		fun removeMetadata(_ type: String, _ id: UInt64?){ 
			if self.metadata[type] == nil{ 
				self.metadata[type] = []
			}
			self.metadata[type] = FantastecSwapDataV2.removeFromMetadata(
					type,
					self.metadata[type]!,
					id
				)
		}
	}
	
	access(all)
	struct CardData{ 
		access(all)
		let id: UInt64
		
		access(all)
		var name: String
		
		access(all)
		var type: String
		
		access(all)
		var aspectRatio: String
		
		access(all)
		var collectionOrder: UInt32
		
		access(all)
		var collectionId: UInt64
		
		access(all)
		var metadata:{ String: [{FantastecSwapDataProperties.MetadataElement}]}
		
		access(contract)
		fun save(){ 
			FantastecSwapDataV2.getDataManager().setCardData(self)
		}
		
		init(
			_ id: UInt64,
			_ name: String,
			_ type: String,
			_ aspectRatio: String,
			_ collectionOrder: UInt32,
			_ collectionId: UInt64
		){ 
			pre{ 
				FantastecSwapDataV2.getDataManager().cardCollectionData[collectionId] != nil:
					"cannot create cardData when collection ID does not exist"
			}
			self.id = id
			self.name = name
			self.type = type
			self.aspectRatio = aspectRatio
			self.collectionOrder = collectionOrder
			self.collectionId = collectionId
			self.metadata ={} 
		}
		
		access(contract)
		fun addMetadata(_ type: String, _ metadata:{ FantastecSwapDataProperties.MetadataElement}){ 
			if self.metadata[type] == nil{ 
				self.metadata[type] = []
			}
			self.metadata[type] = FantastecSwapDataV2.addToMetadata(
					type,
					self.metadata[type]!,
					metadata
				)
		}
		
		access(contract)
		fun removeMetadata(_ type: String, _ id: UInt64?){ 
			if self.metadata[type] == nil{ 
				self.metadata[type] = []
			}
			self.metadata[type] = FantastecSwapDataV2.removeFromMetadata(
					type,
					self.metadata[type]!,
					id
				)
		}
	}
	
	access(all)
	resource Admin{ 
		// ------------------------
		// CardCollection functions
		// ------------------------
		access(self)
		fun getCardCollection(id: UInt64): CardCollectionData{ 
			let cardCollection =
				FantastecSwapDataV2.getCardCollectionById(id: id)
				?? panic("No CardCollection found with id: ".concat(id.toString()))
			return cardCollection
		}
		
		access(all)
		fun addCardCollection(
			id: UInt64,
			title: String,
			description: String,
			type: String,
			mintVolume: UInt64
		){ 
			var newCardCollection = CardCollectionData(id, title, description, type, mintVolume)
			newCardCollection.save()
			emit CardCollectionCreated(id: newCardCollection.id)
		}
		
		access(all)
		fun removeCardCollection(id: UInt64){ 
			FantastecSwapDataV2.getDataManager().removeCardCollectionData(id)
			emit CardCollectionDeleted(id: id)
		}
		
		access(all)
		fun addCardCollectionMetadata(
			collectionId: UInt64,
			metadataType: String,
			metadata:{ FantastecSwapDataProperties.MetadataElement}
		){ 
			let cardCollection = self.getCardCollection(id: collectionId)
			cardCollection.addMetadata(metadataType, metadata)
			cardCollection.save()
		}
		
		access(all)
		fun removeCardCollectionMetadata(
			collectionId: UInt64,
			metadataType: String,
			metadataId: UInt64
		){ 
			let cardCollection = self.getCardCollection(id: collectionId)
			cardCollection.removeMetadata(metadataType, metadataId)
			cardCollection.save()
		}
		
		access(all)
		fun emitCardCollectionUpdated(_ id: UInt64){ 
			emit CardCollectionUpdated(id: id)
		}
		
		// --------------
		// Card functions
		// --------------
		access(self)
		fun getCard(id: UInt64): FantastecSwapDataV2.CardData{ 
			let card =
				FantastecSwapDataV2.getCardById(id: id)
				?? panic("No Card found with id: ".concat(id.toString()))
			return card
		}
		
		access(all)
		fun addCard(
			id: UInt64,
			name: String,
			type: String,
			aspectRatio: String,
			collectionOrder: UInt32,
			collectionId: UInt64
		){ 
			var newCard: CardData =
				CardData(id, name, type, aspectRatio, collectionOrder, collectionId)
			newCard.save()
			emit CardCreated(id: newCard.id)
		}
		
		access(all)
		fun removeCard(id: UInt64){ 
			FantastecSwapDataV2.getDataManager().removeCardData(id)
			emit CardDeleted(id: id)
		}
		
		access(all)
		fun addCardMetadata(
			cardId: UInt64,
			metadataType: String,
			metadata:{ FantastecSwapDataProperties.MetadataElement}
		){ 
			let card = self.getCard(id: cardId)
			card.addMetadata(metadataType, metadata)
			card.save()
		}
		
		access(all)
		fun removeCardMetadata(cardId: UInt64, metadataType: String, metadataId: UInt64){ 
			let card = self.getCard(id: cardId)
			card.removeMetadata(metadataType, metadataId)
			card.save()
		}
		
		access(all)
		fun emitCardUpdated(_ id: UInt64){ 
			emit CardUpdated(id: id)
		}
	}
	
	access(all)
	resource DataManager{ 
		access(contract)
		var cardCollectionData:{ UInt64: CardCollectionData}
		
		access(contract)
		var cardData:{ UInt64: CardData}
		
		access(contract)
		fun setCardCollectionData(_ cardCollection: CardCollectionData){ 
			self.cardCollectionData[cardCollection.id] = cardCollection
		}
		
		access(contract)
		fun removeCardCollectionData(_ cardCollectionId: UInt64){ 
			self.cardCollectionData.remove(key: cardCollectionId)
		}
		
		access(contract)
		fun setCardData(_ card: CardData){ 
			self.cardData[card.id] = card
		}
		
		access(contract)
		fun removeCardData(_ cardId: UInt64){ 
			self.cardData.remove(key: cardId)
		}
		
		init(_ cardCollectionData:{ UInt64: CardCollectionData}, _ cardData:{ UInt64: CardData}){ 
			self.cardCollectionData = cardCollectionData
			self.cardData = cardData
		}
	}
	
	/** PUBLIC GETTING FUNCTIONS */
	// ------------------------
	// CardCollection functions
	// ------------------------
	access(all)
	fun getCardCollectionById(id: UInt64): CardCollectionData?{ 
		return *self.getDataManager().cardCollectionData[id]
	}
	
	access(all)
	fun getCardCollectionIds(): [UInt64]{ 
		var keys: [UInt64] = []
		for collection in self.getDataManager().cardCollectionData.values{ 
			keys.append(collection.id)
		}
		return keys
	}
	
	// --------------
	// Card functions
	// --------------
	access(all)
	fun getAllCards(_ offset: Int?, _ pageSize: Int?):{ UInt64: CardData}{ 
		let cardIds = self.getCardIds(offset, pageSize)
		let dataManager = self.getDataManager()
		let cardsDictionary:{ UInt64: FantastecSwapDataV2.CardData} ={} 
		for cardId in cardIds{ 
			cardsDictionary[cardId] = dataManager.cardData[cardId]!
		}
		return cardsDictionary
	}
	
	access(all)
	fun getCardById(id: UInt64): CardData?{ 
		return *self.getDataManager().cardData[id]
	}
	
	access(all)
	fun getCardIds(_ offset: Int?, _ pageSize: Int?): [UInt64]{ 
		let cardIds = self.getDataManager().cardData.keys
		return FantastecSwapDataV2.paginateIds(*cardIds, offset, pageSize)
	}
	
	// -----------------
	// Utility functions
	// -----------------
	access(all)
	fun join(_ array: [String]): String{ 
		var res = ""
		for string in array{ 
			res = res.concat(" ").concat(string)
		}
		return res
	}
	
	access(all)
	fun paginateIds(_ ids: [UInt64], _ offset: Int?, _ pageSize: Int?): [UInt64]{ 
		let from = offset ?? 0
		if from >= ids.length{ 
			return []
		}
		var upTo = from + (pageSize ?? ids.length)
		if upTo > ids.length{ 
			upTo = ids.length
		}
		let slice = ids.slice(from: from, upTo: upTo)
		return slice
	}
	
	access(contract)
	fun addToMetadata(
		_ type: String,
		_ metadataArray: [{
			FantastecSwapDataProperties.MetadataElement}
		],
		_ metadata:{ FantastecSwapDataProperties.MetadataElement}
	): [{
		FantastecSwapDataProperties.MetadataElement}
	]{ 
		if FantastecSwapDataProperties.IsArrayMetadataType(type){ 
			var updatedMetadataArray = FantastecSwapDataV2.removeMetadataElementById(metadataArray, metadata.id)
			updatedMetadataArray.append(metadata)
			return updatedMetadataArray
		} else{ 
			if metadataArray.length > 0{ 
				metadataArray.removeFirst()
			}
			metadataArray.append(metadata)
			return metadataArray
		}
	}
	
	access(contract)
	fun removeFromMetadata(
		_ type: String,
		_ metadataArray: [{
			FantastecSwapDataProperties.MetadataElement}
		],
		_ id: UInt64?
	): [{
		FantastecSwapDataProperties.MetadataElement}
	]{ 
		if FantastecSwapDataProperties.IsArrayMetadataType(type){ 
			let updatedMetadataArray = FantastecSwapDataV2.removeMetadataElementById(metadataArray, id!)
			return updatedMetadataArray
		} else{ 
			let metadataExists = metadataArray.length > 0
			if metadataExists{ 
				metadataArray.removeFirst()
			}
			return metadataArray
		}
	}
	
	access(all)
	fun removeMetadataElementById(
		_ array: [{
			FantastecSwapDataProperties.MetadataElement}
		],
		_ id: UInt64
	): [{
		FantastecSwapDataProperties.MetadataElement}
	]{ 
		if array == nil{ 
			return []
		}
		var indexToRemove: Int = -1
		for index, element in array{ 
			if element.id == id{ 
				indexToRemove = index
				break
			}
		}
		if indexToRemove > -1{ 
			array.remove(at: indexToRemove)
		}
		return array
	}
	
	access(contract)
	fun setAdmin(){ 
		let oldAdmin <- self.account.storage.load<@Admin>(from: self.AdminStoragePath)
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		destroy oldAdmin
	}
	
	access(contract)
	fun setDataManager(){ 
		let oldDataManager <- self.account.storage.load<@DataManager>(from: self.DataStoragePath)
		var oldCardCollectionData = oldDataManager?.cardCollectionData ??{} 
		var oldCardData = oldDataManager?.cardData ??{} 
		self.account.storage.save<@DataManager>(
			<-create DataManager(oldCardCollectionData, oldCardData),
			to: self.DataStoragePath
		)
		destroy oldDataManager
	}
	
	access(contract)
	view fun getDataManager(): &DataManager{ 
		return self.account.storage.borrow<&DataManager>(from: self.DataStoragePath)!
	}
	
	init(){ 
		// set storage paths and Admin resource
		self.AdminStoragePath = /storage/FantastecSwapV2Admin
		self.DataStoragePath = /storage/FantastecSwapV2Data
		self.setAdmin()
		self.setDataManager()
		emit ContractInitialized()
	}
}
