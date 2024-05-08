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

pub contract FantastecSwapDataV2 {

  /** EVENTS **/
  // Contract Events
  pub event ContractInitialized()

  // Card Events
  pub event CardCreated(id: UInt64)
  pub event CardUpdated(id: UInt64)
  pub event CardDeleted(id: UInt64)

  // CardCollection Events
  pub event CardCollectionCreated(id: UInt64)
  pub event CardCollectionUpdated(id: UInt64)
  pub event CardCollectionDeleted(id: UInt64)

  pub let AdminStoragePath: StoragePath
  pub let DataStoragePath: StoragePath

  /** CONTRACT LEVEL STRUCTS */
  pub struct CardCollectionData {
    pub let id: UInt64;
    pub var title: String;
    pub var description: String;
    pub var type: String;
    pub var mintVolume: UInt64;
    pub var metadata: {String: [AnyStruct{FantastecSwapDataProperties.MetadataElement}]}

    access(contract) fun save(){
      FantastecSwapDataV2.getDataManager().setCardCollectionData(self)
    }

    init(
      _ id: UInt64,
      _ title: String,
      _ description: String,
      _ type: String,
      _ mintVolume: UInt64,
    ){
      self.id = id;
      self.title = title;
      self.description = description;
      self.type = type;
      self.mintVolume = mintVolume;
      self.metadata = {};
    }

    access(contract) fun addMetadata(
      _ type: String,
      _ metadata: AnyStruct{FantastecSwapDataProperties.MetadataElement},
    ) {
      if (self.metadata[type] == nil) {
        self.metadata[type] = []
      }
      self.metadata[type] = FantastecSwapDataV2.addToMetadata(type, self.metadata[type]!, metadata)
    }

    access(contract) fun removeMetadata(
      _ type: String,
      _ id: UInt64?,
    ) {
      if (self.metadata[type] == nil) {
        self.metadata[type] = []
      }
      self.metadata[type] = FantastecSwapDataV2.removeFromMetadata(type, self.metadata[type]!, id)
    }
  }

  pub struct CardData {
    pub let id: UInt64;
    pub var name: String;
    pub var type: String;
    pub var aspectRatio: String;
    pub var collectionOrder: UInt32;
    pub var collectionId: UInt64;
    pub var metadata: {String: [AnyStruct{FantastecSwapDataProperties.MetadataElement}]}

    access(contract) fun save(){
      FantastecSwapDataV2.getDataManager().setCardData(self)
    }

    init(
      _ id: UInt64,
      _ name: String,
      _ type: String,
      _ aspectRatio: String,
      _ collectionOrder: UInt32,
      _ collectionId: UInt64,
    ){
      pre {
        FantastecSwapDataV2.getDataManager().cardCollectionData[collectionId] != nil: "cannot create cardData when collection ID does not exist"
      }

      self.id = id;
      self.name = name;
      self.type = type;
      self.aspectRatio = aspectRatio;
      self.collectionOrder = collectionOrder;
      self.collectionId = collectionId;
      self.metadata = {};
    }

    access(contract) fun addMetadata(
      _ type: String,
      _ metadata: AnyStruct{FantastecSwapDataProperties.MetadataElement},
    ) {
      if (self.metadata[type] == nil) {
        self.metadata[type] = []
      }
      self.metadata[type] = FantastecSwapDataV2.addToMetadata(type, self.metadata[type]!, metadata)
    }

    access(contract) fun removeMetadata(
      _ type: String,
      _ id: UInt64?,
    ) {
      if (self.metadata[type] == nil) {
        self.metadata[type] = []
      }
      self.metadata[type] = FantastecSwapDataV2.removeFromMetadata(type, self.metadata[type]!, id)
    }
  }

  pub resource Admin {
    // ------------------------
    // CardCollection functions
    // ------------------------
    access(self) fun getCardCollection(id: UInt64): CardCollectionData {
      let cardCollection = FantastecSwapDataV2.getCardCollectionById(id: id)
        ?? panic("No CardCollection found with id: ".concat(id.toString()))
      return cardCollection
    }

    pub fun addCardCollection(
      id: UInt64,
      title: String,
      description: String,
      type: String,
      mintVolume: UInt64,
    ) {

      var newCardCollection = CardCollectionData(id, title, description, type, mintVolume)

      newCardCollection.save()

      emit CardCollectionCreated(id: newCardCollection.id)
    }

    pub fun removeCardCollection(id: UInt64) {
      FantastecSwapDataV2.getDataManager().removeCardCollectionData(id)
      emit CardCollectionDeleted(id: id)
    }

    pub fun addCardCollectionMetadata(
      collectionId: UInt64,
      metadataType: String,
      metadata: AnyStruct{FantastecSwapDataProperties.MetadataElement},
    ) {
      let cardCollection = self.getCardCollection(id: collectionId)
      cardCollection.addMetadata(metadataType, metadata)
      cardCollection.save()
    }

    pub fun removeCardCollectionMetadata(
      collectionId: UInt64,
      metadataType: String,
      metadataId: UInt64,
    ) {
      let cardCollection = self.getCardCollection(id: collectionId)
      cardCollection.removeMetadata(metadataType, metadataId)
      cardCollection.save()
    }

    pub fun emitCardCollectionUpdated(_ id: UInt64){
      emit CardCollectionUpdated(id: id)
    }

    // --------------
    // Card functions
    // --------------
    access(self) fun getCard(id: UInt64): FantastecSwapDataV2.CardData {
      let card = FantastecSwapDataV2.getCardById(id: id)
        ?? panic("No Card found with id: ".concat(id.toString()))
      return card
    }

    pub fun addCard(
      id: UInt64,
      name: String,
      type: String,
      aspectRatio: String,
      collectionOrder: UInt32,
      collectionId: UInt64,
    ) {
      var newCard: CardData = CardData(id, name, type, aspectRatio, collectionOrder, collectionId)

      newCard.save()

      emit CardCreated(id: newCard.id)
    }

    pub fun removeCard(id: UInt64) {
      FantastecSwapDataV2.getDataManager().removeCardData(id)
      emit CardDeleted(id: id)
    }

    pub fun addCardMetadata(
      cardId: UInt64,
      metadataType: String,
      metadata: AnyStruct{FantastecSwapDataProperties.MetadataElement},
    ) {
      let card = self.getCard(id: cardId)
      card.addMetadata(metadataType, metadata)
      card.save()
    }

    pub fun removeCardMetadata(
      cardId: UInt64,
      metadataType: String,
      metadataId: UInt64,
    ) {
      let card = self.getCard(id: cardId)
      card.removeMetadata(metadataType, metadataId)
      card.save()
    }
    pub fun emitCardUpdated(_ id: UInt64) {
      emit CardUpdated(id: id)
    }
  }

  pub resource DataManager {
    access(contract) var cardCollectionData: {UInt64: CardCollectionData}
    access(contract) var cardData: {UInt64: CardData}

    access(contract) fun setCardCollectionData(_ cardCollection: CardCollectionData) {
      self.cardCollectionData[cardCollection.id] = cardCollection
    }

    access(contract) fun removeCardCollectionData(_ cardCollectionId: UInt64) {
      self.cardCollectionData.remove(key: cardCollectionId)
    }

    access(contract) fun setCardData(_ card: CardData) {
      self.cardData[card.id] = card
    }

    access(contract) fun removeCardData(_ cardId: UInt64) {
      self.cardData.remove(key: cardId)
    }

    init(_ cardCollectionData: {UInt64: CardCollectionData}, _ cardData: {UInt64: CardData}) {
      self.cardCollectionData = cardCollectionData
      self.cardData = cardData
    }
  }

  /** PUBLIC GETTING FUNCTIONS */
  // ------------------------
  // CardCollection functions
  // ------------------------
  pub fun getCardCollectionById(id: UInt64): CardCollectionData? {
    return self.getDataManager().cardCollectionData[id]
  }

  pub fun getCardCollectionIds(): [UInt64] {
    var keys:[UInt64] = []
    for collection in self.getDataManager().cardCollectionData.values {
      keys.append(collection.id)
    }
    return keys;
  }

  // --------------
  // Card functions
  // --------------
  pub fun getAllCards(_ offset: Int?, _ pageSize: Int?): {UInt64: CardData} {
    let cardIds = self.getCardIds(offset, pageSize)
    let dataManager = self.getDataManager()
    let cardsDictionary: {UInt64: FantastecSwapDataV2.CardData} = {}
    for cardId in cardIds {
      cardsDictionary[cardId] = dataManager.cardData[cardId]!
    }
    return cardsDictionary
  }

  pub fun getCardById(id: UInt64): CardData? {
    return self.getDataManager().cardData[id]
  }

  pub fun getCardIds(_ offset: Int?, _ pageSize: Int?): [UInt64] {
    let cardIds = self.getDataManager().cardData.keys;
    return FantastecSwapDataV2.paginateIds(cardIds, offset, pageSize)
  }

  // -----------------
  // Utility functions
  // -----------------
  pub fun join(_ array: [String]): String {
    var res = ""
    for string in array {
      res = res.concat(" ").concat(string)
    }
    return res
  }

  pub fun paginateIds(_ ids: [UInt64], _ offset: Int?, _ pageSize: Int?): [UInt64] {
    let from = offset ?? 0
    if from >= ids.length {
      return [] 
    }
    var upTo = from + (pageSize ?? ids.length)
    if upTo > ids.length {
      upTo = ids.length
    }
    let slice = ids.slice(from: from, upTo: upTo)
    return slice
  }

  access(contract) fun addToMetadata(
    _ type: String,
    _ metadataArray: [AnyStruct{FantastecSwapDataProperties.MetadataElement}],
    _ metadata: AnyStruct{FantastecSwapDataProperties.MetadataElement},
  ): [AnyStruct{FantastecSwapDataProperties.MetadataElement}] {
    if (FantastecSwapDataProperties.IsArrayMetadataType(type)) {
      var updatedMetadataArray = FantastecSwapDataV2.removeMetadataElementById(metadataArray, metadata.id)
      updatedMetadataArray.append(metadata)
      return updatedMetadataArray
    } else {
      if metadataArray.length > 0 {
        metadataArray.removeFirst()
      }
      metadataArray.append(metadata)
      return metadataArray
    }
  }

  access(contract) fun removeFromMetadata(
    _ type: String,
    _ metadataArray: [AnyStruct{FantastecSwapDataProperties.MetadataElement}],
    _ id: UInt64?,
  ): [AnyStruct{FantastecSwapDataProperties.MetadataElement}] {
    if (FantastecSwapDataProperties.IsArrayMetadataType(type)) {
      let updatedMetadataArray = FantastecSwapDataV2.removeMetadataElementById(metadataArray, id!)
      return updatedMetadataArray
    } else {
      let metadataExists = metadataArray.length > 0
      if (metadataExists) {
        metadataArray.removeFirst()
      }
      return metadataArray
    }
  }

  pub fun removeMetadataElementById(
    _ array: [AnyStruct{FantastecSwapDataProperties.MetadataElement}],
    _ id: UInt64,
  ): [AnyStruct{FantastecSwapDataProperties.MetadataElement}] {
    if (array == nil) {
      return []
    }
    var indexToRemove: Int = -1
    for index, element in array {
      if (element.id == id) {
        indexToRemove = index
        break
      }
    }
    if (indexToRemove > -1) {
      array.remove(at: indexToRemove)
    }
    return array
  }

  access(contract) fun setAdmin(){
    let oldAdmin <- self.account.load<@Admin>(from: self.AdminStoragePath)
    self.account.save<@Admin>(<- create Admin(), to: self.AdminStoragePath)
    destroy oldAdmin
  }

  access(contract) fun setDataManager() {
    let oldDataManager <- self.account.load<@DataManager>(from: self.DataStoragePath)
    var oldCardCollectionData = oldDataManager?.cardCollectionData ?? {}
    var oldCardData = oldDataManager?.cardData ?? {}
    self.account.save<@DataManager>(<- create DataManager(oldCardCollectionData, oldCardData), to: self.DataStoragePath)
    destroy oldDataManager
  }

  access(contract) fun getDataManager(): &DataManager {
    return self.account.borrow<&DataManager>(from: self.DataStoragePath)!
  }

  init() {
    // set storage paths and Admin resource
    self.AdminStoragePath = /storage/FantastecSwapV2Admin
    self.DataStoragePath = /storage/FantastecSwapV2Data

    self.setAdmin()
    self.setDataManager()

    emit ContractInitialized()
  }
}