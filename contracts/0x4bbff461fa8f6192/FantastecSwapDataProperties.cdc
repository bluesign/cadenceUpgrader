/**
# Contract: FantastecSwapDataProperties
# Description:

The purpose of this contract is to define the metadata objects that are properties of cards and collections
(as defined in the fantastecSwapDataV2 contract)
*/

pub contract FantastecSwapDataProperties {
  access(contract) var arrayTypes: [String]

  pub struct interface MetadataElement {
    pub let id: UInt64
  }

  pub struct ProductCollectionChance {
    pub let collectionId : UInt64
    pub let chance: UFix64
    init (
      _ collectionId: UInt64,
      _ chance: UFix64
    ) {
      self.collectionId = collectionId
      self.chance = chance
    }
  }

  pub struct ProductContent: MetadataElement {
    pub let id: UInt64;
    pub let content: [ProductCollectionChance];
    init (
      _ id: UInt64
    ){
      self.id = id;
      self.content = [];
    }
    pub fun add(_ collectionId: UInt64, _ chance: UFix64){
      let productCollectionChance = ProductCollectionChance(collectionId, chance)
      self.content.append(productCollectionChance)
    }
  }

  pub struct Media: MetadataElement {
    pub let id: UInt64;
    pub let url: String;
    pub let type: String;
    pub let mediaType: String;
    pub let ipfsCid: String;
    pub let hash: String;

    init(
      _ id: UInt64,
      _ url: String,
      _ type: String,
      _ mediaType: String,
      _ ipfsCid: String,
      _ hash: String,
    ){
      self.id = id;
      self.url = url;
      self.type = type;
      self.mediaType = mediaType;
      self.ipfsCid = ipfsCid;
      self.hash = hash;
    }
  }

  pub struct Social: MetadataElement {
    pub let id: UInt64;
    pub let url: String;
    pub let type: String;

    init(
      _ id: UInt64,
      _ url: String,
      _ type: String,
    ){
      self.id = id;
      self.url = url;
      self.type = type;
    }
  }

  pub struct Partner: MetadataElement {
    pub let id: UInt64;
    pub let name: String;

    init(
      _ id: UInt64,
      _ name: String,
    ){
      self.id = id;
      self.name = name;
    }
  }

  pub struct Team: MetadataElement {
    pub let id: UInt64;
    pub let name: String;
    pub let gender: String;

    init(
      _ id: UInt64,
      _ name: String,
      _ gender: String,
    ){
      self.id = id;
      self.name = name;
      self.gender = gender;
    }
  }

  pub struct Sport: MetadataElement {
    pub let id: UInt64;
    pub let name: String;

    init(
      _ id: UInt64,
      _ name: String,
    ){
      self.id = id;
      self.name = name;
    }
  }

  pub struct Sku: MetadataElement {
    pub let id: UInt64;
    pub let name: String;

    init(
      _ id: UInt64,
      _ name: String,
    ){
      self.id = id;
      self.name = name;
    }
  }

  pub struct Season: MetadataElement {
    pub let id: UInt64;
    pub let name: String;
    pub let startDate: String;
    pub let endDate: String;

    init(
      _ id: UInt64,
      _ name: String,
      _ startDate: String,
      _ endDate: String,
    ){
      self.id = id;
      self.name = name;
      self.startDate = startDate;
      self.endDate = endDate;
    }
  }

  pub struct Level: MetadataElement {
    pub let id: UInt64;
    pub let name: String;
    pub let scarcity: String;

    init(
      _ id: UInt64,
      _ name: String,
      _ scarcity: String,
    ){
      self.id = id;
      self.name = name;
      self.scarcity = scarcity;
    }
  }

  pub struct Player: MetadataElement {
    pub let id: UInt64;
    pub let name: String;
    pub let gender: String;
    pub let position: String?;
    pub let shirtNumber: String?;
    init(
      _ id: UInt64,
      _ name: String,
      _ gender: String,
      _ position: String?,
      _ shirtNumber: String?,
    ){
      self.id = id;
      self.name = name;
      self.gender = gender;
      self.position = position;
      self.shirtNumber = shirtNumber;
    }
  }

  pub struct Royalty: MetadataElement {
    pub let id: UInt64;
    pub let address: Address;
    pub let percentage: UFix64;
    init(
      _ id: UInt64,
      _ address: Address,
      _ percentage: UFix64,
    ){
      pre {
        percentage <= 100.0: "percentage cannot be higher than 100"
      }
      self.id = id;
      self.address = address;
      self.percentage = percentage;
    }
  }

  pub struct License: MetadataElement {
    pub let id: UInt64;
    pub let name: String;
    pub let url: String;
    pub let dateAwarded: String;
    init(
      _ id: UInt64,
      _ name: String,
      _ url: String,
      _ dateAwarded: String,
    ){
      self.id = id;
      self.name = name;
      self.url = url;
      self.dateAwarded = dateAwarded;
    }
  }

  pub struct CardId: MetadataElement {
    pub let id: UInt64;
    init(
      _ id: UInt64,
    ){
      self.id = id;
    }
  }

  pub struct MintVolume: MetadataElement {
    pub let id: UInt64;
    pub let value: UInt64;
    init(
      _ id: UInt64,
      _ value: UInt64,
    ){
      self.id = id;
      self.value = value;
    }
  }

  pub struct RedeemInfo: MetadataElement {
    pub let id: UInt64;
    pub let retailerName: String;
    pub let retailerPinHash: String;
    pub let retailerAddress: Address;
    pub let validFrom: UFix64?;
    pub let validTo: UFix64?;
    init(
      _ id: UInt64,
      _ retailerName: String,
      _ retailerPinHash: String,
      _ retailerAddress: Address,
      _ validFrom: UFix64?,
      _ validTo: UFix64?,
    ){
      self.id = id;
      self.retailerName = retailerName;
      self.retailerPinHash = retailerPinHash;
      self.retailerAddress = retailerAddress;
      self.validFrom = validFrom;
      self.validTo = validTo;
    }
  }

  pub struct RedeemInfoV2: MetadataElement {
    pub let id: UInt64;
    pub let retailerName: String;
    pub let retailerPinHash: String;
    pub let retailerAddress: Address;
    pub let validFrom: UFix64?;
    pub let validTo: UFix64?;
    pub let type: String;
    pub let t_and_cs: String;
    pub let description: String;

    init(
      _ id: UInt64,
      _ retailerName: String,
      _ retailerPinHash: String,
      _ retailerAddress: Address,
      _ validFrom: UFix64?,
      _ validTo: UFix64?,
      _ type: String,
      _ t_and_cs: String,
      _ description: String,
    ){
      self.id = id;
      self.retailerName = retailerName;
      self.retailerPinHash = retailerPinHash;
      self.retailerAddress = retailerAddress;
      self.validFrom = validFrom;
      self.validTo = validTo;
      self.type = type;
      self.t_and_cs = t_and_cs;
      self.description = description;
    }
  }

  pub struct NewsFeed: MetadataElement {
    pub let id: UInt64
    pub let title: String
    pub let publishedDate: UFix64
    pub let buttonUrl: String
    pub let buttonText: String
    init(
      _ id: UInt64,
      _ title: String,
      _ publishedDate: UFix64,
      _ buttonUrl: String,
      _ buttonText: String,      
    ){
      self.id = id
      self.title = title
      self.publishedDate = publishedDate
      self.buttonUrl = buttonUrl
      self.buttonText = buttonText
    }
  }

    pub struct BlockedUsers: MetadataElement {
    pub let id: UInt64;
    pub let blockedAddresses: [Address];
    init(
      _ id: UInt64,
      _ blockedAddresses: [Address]
    ){
      self.id = id;
      self.blockedAddresses = blockedAddresses;
    }
  }

  pub fun IsArrayMetadataType(_ type: String): Bool {
    return self.arrayTypes.contains(type);
  }

  pub fun parseUInt64(_ string: String?): UInt64? {
    if (string == nil) {
      return nil
    }
    return UInt64.fromString(string!)
  }

  pub fun parseUFix64(_ string: String?): UFix64? {
    if (string == nil) {
      return nil
    }
    return UFix64.fromString(string!)
  }

  pub fun parseAddress(_ string: String?): Address? {
    if (string == nil) {
      return nil
    }
    var addressString = string!
    if (addressString.slice(from: 0, upTo: 2) == "0x") {
      addressString = addressString.slice(from: 2, upTo: addressString.length)
    }
    let bytes = addressString.decodeHex()
    let numberOfBytes: UInt64 = UInt64(bytes.length)
    var i: UInt64 = 0
    var addressAsInt: UInt64 = 0
    var multiplier: UInt64 = 1
    while i < numberOfBytes {
      let index: UInt64 = numberOfBytes - 1 - i
      let intPart = UInt64(bytes[index]) * multiplier
      addressAsInt = addressAsInt + intPart
      i = i + 1
      multiplier = multiplier.saturatingMultiply(256)
    }
    let address = Address(addressAsInt)
    return address
  }

  pub fun addToMetadata(
    _ type: String,
    _ metadataArray: [AnyStruct{MetadataElement}],
    _ metadata: AnyStruct{MetadataElement},
  ): [AnyStruct{MetadataElement}] {
    if (self.IsArrayMetadataType(type)) {
      var updatedMetadataArray = self.removeMetadataElementById(metadataArray, metadata.id)
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

  pub fun removeFromMetadata(
    _ type: String,
    _ metadataArray: [AnyStruct{MetadataElement}],
    _ id: UInt64?,
  ): [AnyStruct{MetadataElement}] {
    if (self.IsArrayMetadataType(type)) {
      let updatedMetadataArray = self.removeMetadataElementById(metadataArray, id!)
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
    _ array: [AnyStruct{MetadataElement}],
    _ id: UInt64,
  ): [AnyStruct{MetadataElement}] {
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

  init() {
    self.arrayTypes = ["media", "socials", "royalties", "licenses", "cardIds"]
  }
}