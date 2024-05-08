import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import StrikeNowData from "./StrikeNowData.cdc"
import DapperUtilityCoin from "../0xead892083b3e2c6c/DapperUtilityCoin.cdc"
import Utils from "./Utils.cdc"

pub contract StrikeNow: NonFungibleToken {
  pub event ContractInitialized()
  pub event Minted(id: UInt64, setId: UInt32, seriesId: UInt32)
  pub event SeriesCreated(seriesId: UInt32)
  pub event SeriesSealed(seriesId: UInt32)
  pub event SeriesEditionsSetToProceedSerially(seriesId: UInt32)
  pub event SeriesMetadataUpdated(seriesId: UInt32)
  pub event SetCreated(seriesId: UInt32, setId: UInt32)
  pub event SetMetadataUpdated(seriesId: UInt32, setId: UInt32)
  pub event Withdraw(id: UInt64, from: Address?)
  pub event Deposit(id: UInt64, to: Address?)
  pub event NFTDestroyed(id: UInt64)
  pub event SetSaleStateChanged(id: UInt32, onSale: Bool)
  pub event SetEditionShuffleActivated(id: UInt32)

  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath
  pub let AdminStoragePath: StoragePath
  pub let AdminPrivatePath: PrivatePath
  pub let MinterPublicPath: PublicPath
  pub let VaultPublicPath: PublicPath

  pub var totalSupply: UInt64
  pub var numberEditionsMintedPerSet: {UInt32: UInt64}

  access(self) var setData: {UInt32: StrikeNowData.SetData}
  access(self) var seriesData: {UInt32: StrikeNowData.SeriesData}
  access(self) var series: @{UInt32: Series}
  access(self) var config: StrikeNowData.ConfigData

  pub resource Series {
    pub let seriesId: UInt32
    pub var setIds: [UInt32]
    pub var sealed: Bool;
    //TODO $BS - Please come up with a better name for this
    pub var editionsProceedingSerially: Bool;
    pub let setEditionMap: {UInt32: {UInt32: UInt32}}
    pub let onSaleStateMap: {UInt32: Bool}

    init(
      seriesId: UInt32,
      metadata: {String: String},
      fights: [{String: String}]?) {

      self.seriesId = seriesId
      self.sealed = false
      self.setIds = []
      self.editionsProceedingSerially = false
      self.setEditionMap = {}
      self.onSaleStateMap = {}

      StrikeNow.seriesData[seriesId] = StrikeNowData.SeriesData(seriesId: seriesId, metadata: metadata, fights: fights)
      emit SeriesCreated(seriesId: seriesId)
    }

    pub fun updateSeriesMetadata(metadata: {String: String}, fights: [{String: String}]?) {
      pre {
        self.sealed == false: "The Series is permanently sealed. No metadata updates can be made."
      }
      let data = StrikeNowData.SeriesData(seriesId: self.seriesId, metadata: metadata, fights: fights)
      StrikeNow.seriesData[self.seriesId] = data
      emit SeriesMetadataUpdated(seriesId: self.seriesId)
    }

    pub fun addNftSet(
      setId: UInt32, 
      metadata: {String: String}, 
      assets: [{String: String}]?, 
      result: {String: String}?) {
      pre {
        self.setIds.contains(setId) == false: "The Set has already been added to the Series."
        self.sealed == false: "The Series is already sealed."
      }

      var newNFTSet = StrikeNowData.SetData(
        setId: setId,
        seriesId: self.seriesId,
        metadata: metadata,
        assets: assets,
        result: result
      )

      self.setIds.append(setId)
      self.setEditionMap[setId] = {}
      self.onSaleStateMap[setId] = false
      StrikeNow.numberEditionsMintedPerSet[setId] = 0
      StrikeNow.setData[setId] = newNFTSet

      emit SetCreated(seriesId: self.seriesId, setId: setId)
    }

    pub fun updateSetMetadata(
      setId: UInt32, 
      metadata: {String: String}, 
      assets: [{String: String}]?, 
      result: {String: String}?) {
      pre {
        self.sealed == false: "The Series is permanently sealed. No metadata updates can be made."
        self.setIds.contains(setId) == true: "The Set is not part of this Series."
      }

      let newSetMetadata = StrikeNowData.SetData(
        setId: setId,
        seriesId: self.seriesId,
        metadata: metadata,
        assets: assets,
        result: result
      )
      StrikeNow.setData[setId] = newSetMetadata

      emit SetMetadataUpdated(seriesId: self.seriesId, setId: setId)
    }

    pub fun mintStrikeNow(recipient: &{NonFungibleToken.CollectionPublic}, setId: UInt32) {
      pre {
        StrikeNow.numberEditionsMintedPerSet[setId] != nil: "The Set does not exist."
      }

      let index = StrikeNow.numberEditionsMintedPerSet[setId]! + 1
      let index32 = UInt32(index)
      recipient.deposit(token: <-create StrikeNow.NFT(setId: setId, tokenIndex: index32))

      let setMap = self.setEditionMap[setId]!
      setMap[index32] = self.editionsProceedingSerially ? index32 : 0
      self.setEditionMap[setId] = setMap
      StrikeNow.totalSupply = StrikeNow.totalSupply + 1
      StrikeNow.numberEditionsMintedPerSet[setId] = index
    }

    pub fun sealSeries() {
      pre {
        self.sealed == false: "The Series is already sealed"
      }
      self.sealed = true
      emit SeriesSealed(seriesId: self.seriesId)
    }

    pub fun setEditionsProceedingSerially() {
      pre {
        self.sealed == false: "The Series is sealed"
        self.editionsProceedingSerially == false: "Sets in this Series are already numbering editions serially"
      }
      self.editionsProceedingSerially = true
      emit SeriesEditionsSetToProceedSerially(seriesId: self.seriesId)
    }

    pub fun applyEditionsToRange(setId: UInt32, editionMap: {UInt32: UInt32}) {
      pre {
        self.sealed == false: "The Series is sealed"
      }
      
      let setMap = self.setEditionMap[setId]!
      for index in editionMap.keys {
        assert(setMap.containsKey(index), message: "Invalid token index ".concat(index.toString()))
        setMap[index] = editionMap[index]
      }
      self.setEditionMap[setId] = setMap

      emit SetEditionShuffleActivated(id: setId)
    }

    pub fun getEdition(setId: UInt32, tokenIndex: UInt32): UInt32 {
      pre {
        self.setEditionMap.containsKey(setId): "Invalid set id ".concat(setId.toString())
        self.setEditionMap[setId]!.containsKey(tokenIndex): "Invalid token index ".concat(tokenIndex.toString())
      }
      return self.setEditionMap[setId]![tokenIndex]!
    }

    pub fun setSaleState(setId: UInt32, onSale: Bool) {
      pre {
        self.setEditionMap.containsKey(setId): "Series ".concat(self.seriesId.toString()).concat(" does not contain set id ").concat(setId.toString())
      }
      self.onSaleStateMap[setId] = onSale

      emit SetSaleStateChanged(id: setId, onSale: onSale)
    }
  }

  pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
    pub let id: UInt64
    pub let tokenIndex: UInt32
    pub let setId: UInt32

    init(setId: UInt32, tokenIndex: UInt32) {
      self.id = self.uuid
      self.tokenIndex = tokenIndex
      self.setId = setId

      let seriesId = StrikeNow.getSetSeriesId(setId) !

      emit Minted(id: self.id, setId: setId, seriesId: seriesId)
    }

    pub fun getViews(): [Type] {
      return [
        Type<MetadataViews.Display>(),
        Type<MetadataViews.Edition>(),
        Type<MetadataViews.Editions>(),
        Type<MetadataViews.ExternalURL>(),
        Type<MetadataViews.NFTCollectionData>(),
        Type<MetadataViews.NFTCollectionDisplay>(),
        Type<MetadataViews.Serial>(),
        Type<MetadataViews.Traits>(),
        Type<MetadataViews.Medias>()
      ]
    }

    pub fun resolveView(_ view: Type): AnyStruct? {
      switch view {
        case Type<MetadataViews.Display>():
          let setData = StrikeNow.setData[self.setId]!
          let asset = StrikeNow.getAssetForId(setId: self.setId, assetId: setData.thumbnail)
          return MetadataViews.Display(
            name: setData.fighterName,
            description: setData.fightDescription,
            thumbnail: MetadataViews.HTTPFile(url: asset.assetURI)
          )
        case Type<MetadataViews.Serial>():
          return MetadataViews.Serial(self.id)
        case Type<MetadataViews.Edition>():
          return self.getEditionView()
        case Type<MetadataViews.Editions>():
          return [self.getEditionView()]
        case Type<MetadataViews.NFTCollectionData>():
          return MetadataViews.NFTCollectionData(
            storagePath: StrikeNow.CollectionStoragePath,
            publicPath: StrikeNow.CollectionPublicPath,
            providerPath: /private/StrikeNow,
            publicCollection: Type<&StrikeNow.Collection{StrikeNow.StrikeNowCollectionPublic, NonFungibleToken.CollectionPublic}>(),
            publicLinkedType: Type<&StrikeNow.Collection{StrikeNow.StrikeNowCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
            providerLinkedType: Type<&StrikeNow.Collection{StrikeNow.StrikeNowCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
            createEmptyCollectionFunction: (fun(): @NonFungibleToken.Collection {
              return <-StrikeNow.createEmptyCollection()
            })
          )
        case Type<MetadataViews.NFTCollectionDisplay> ():
          let squareImage = MetadataViews.Media(
            file: MetadataViews.HTTPFile(url: StrikeNow.config.squareImageURL),
            mediaType: StrikeNow.config.squareImageMediaType
          )
          let bannerImage = MetadataViews.Media(
            file: MetadataViews.HTTPFile(url: StrikeNow.config.bannerImageURL),
            mediaType: StrikeNow.config.bannerImageMediaType
          )
          var socials: { String: MetadataViews.ExternalURL } = {}
          for social in StrikeNow.config.socials.keys {
            socials[social] = MetadataViews.ExternalURL(StrikeNow.config.socials[social]!)
          }
          return MetadataViews.NFTCollectionDisplay(
            name: StrikeNow.config.collectionName,
            description : StrikeNow.config.collectionDescription,
            externalURL : MetadataViews.ExternalURL(StrikeNow.config.externalURL),
            squareImage : squareImage,
            bannerImage : bannerImage,
            socials: socials
          )        
        case Type<MetadataViews.ExternalURL>():
          if let externalURL = StrikeNow.setData[self.setId]?.externalURL {
            return MetadataViews.ExternalURL(externalURL)
          }
          return MetadataViews.ExternalURL("")
        case Type<MetadataViews.Traits>():
          let set = StrikeNow.setData[self.setId]!
          let series = StrikeNow.seriesData[set.seriesId]!
          let fight = StrikeNow.getFightForSet(self.setId)
          let traitDictionary: {String: AnyStruct} = {
            "Season": series.season,
            "Weight Class": fight.weightClass,
            "Athlete Name": set.fighterName,
            "Opponent Name": set.opponentName,
            "Matchup": fight.fightName,
            "Date": series.eventTime,
            "Event Name": series.seriesName,
            "Location": fight.city.concat(", ").concat(fight.state)
          }

          if set.fightResult != nil {
            let result = set.fightResult!
            traitDictionary["Winner"] = result.won ? set.fighterName : set.opponentName
            traitDictionary["Grade"] = result.grade
            traitDictionary["Defeated"] = result.won ? set.opponentName : set.fighterName
            traitDictionary["Round"] = result.endingRound
            traitDictionary["Fight Result"] = result.method
            traitDictionary["Time"] = result.endingTime
            traitDictionary["Strike Attempts"] = result.strikeAttempts
            traitDictionary["Strikes Landed"] = result.strikesLanded
            traitDictionary["Significant Strikes"] = result.significantStrikes
            traitDictionary["Takedown Attempts"] = result.takedownAttempts
            traitDictionary["Takedowns Landed"] = result.takedownsLanded
            traitDictionary["Submission Attempts"] = result.submissionAttempts
            traitDictionary["Knockdowns"] = result.knockdowns            
          }
          return MetadataViews.dictToTraits(dict: traitDictionary, excludedNames: [])
        case Type<MetadataViews.Medias>():
          let assets = StrikeNow.setData[self.setId]!.assets
          if assets == nil { 
            return MetadataViews.Medias(items: [])
          }
          
          let medias: [MetadataViews.Media] = []
          for asset in assets!.keys {
            let file = MetadataViews.HTTPFile(url: assets![asset]!.assetURI)
            let fileType = Utils.getMimeType(assets![asset]!.assetFileType.toLower())
            medias.append(MetadataViews.Media(file: file, mediaType: fileType))
          }
          return MetadataViews.Medias(items: medias)
      }
      return nil
    }
    
    access(self) fun getEditionView(): MetadataViews.Edition {
      let maxEditions = StrikeNow.getMaxEditions(setId: self.setId)
      let seriesId = StrikeNow.getSetSeriesId(self.setId)!
      let edition: UInt32 = StrikeNow.getEditionNumber(seriesId: seriesId, setId: self.setId, tokenIndex: self.tokenIndex)!
      let editionName = StrikeNow.setData[self.setId]!.editionName
      return MetadataViews.Edition(name: editionName, number: UInt64(edition), max: maxEditions)
    }

    destroy() {
      StrikeNow.totalSupply = StrikeNow.totalSupply - 1
      emit NFTDestroyed(id: self.id)
    }
  }

  pub resource Admin: StrikeNowMinterPublic {
    access(self) var vaultPath: PublicPath

    init(vaultPath: PublicPath) {
      self.vaultPath = vaultPath
    }

    pub fun addSeries(seriesId: UInt32, metadata: {String: String}, fights: [{String: String}]?) {
      pre {
        StrikeNow.series[seriesId] == nil: "Cannot add Series: The Series already exists"
      }

      var newSeries <-create Series(
        seriesId: seriesId,
        metadata: metadata,
        fights: fights
      )

      StrikeNow.series[seriesId] <-! newSeries
    }

    pub fun borrowSeries(seriesId: UInt32): &Series {
      pre {
        StrikeNow.series[seriesId] != nil: "Cannot borrow Series: The Series does not exist"
      }
      return (&StrikeNow.series[seriesId] as &Series?)!
    }

    pub fun borrowSet(setId: UInt32): &StrikeNowData.SetData {
      pre {
        StrikeNow.setData[setId] != nil: "The Set does not exist"
      }
      return &StrikeNow.setData[setId]! as &StrikeNowData.SetData
    }

    pub fun borrowSets(seriesId: UInt32): [&StrikeNowData.SetData] {
      pre {
        StrikeNow.series[seriesId] != nil: "The Series does not exist"
      }
      let sets:[&StrikeNowData.SetData] = []
      for setId in StrikeNow.series[seriesId]?.setIds! {
        sets.append(&StrikeNow.setData[setId]! as &StrikeNowData.SetData)
      }
      return sets
    }

    pub fun updateConfigData(input: { String: String }, socials: { String: String }) {
      StrikeNow.config = StrikeNowData.ConfigData(input, socials)
    }

    //Allow the admin to update the DUC vault with which to receive currency
    pub fun updateVaultPath(vaultPath: PublicPath) {
      self.vaultPath = vaultPath
    }

    //Only this function on Admin will be exposed via a public capability
    //Takes a preloaded payment vault from a user, a map of sets to mint from,
    //and a collection reference in which to deposit minted NFTs.
    //If payment is in correct amount and denomination and NFTs are all set to 
    //on sale, mints them in the amounts specified and deposits them in the user collection.
    pub fun mintStrikeNow(paymentVault: @FungibleToken.Vault, setIdToAmountMap: {UInt32: UInt32}, 
      recipient: &{NonFungibleToken.CollectionPublic}) {
        pre {
          StrikeNow.getSetsPurchasable(setIds: setIdToAmountMap.keys): 
            "Not all of the specified sets are purchasable"
          paymentVault.balance == StrikeNow.getPriceForSetBatch(setIdToAmountMap: setIdToAmountMap): 
            "Incorrect amount of currency supplied"          
        }

        //Borrow a reference to our receiver vault using the stored path
        let vault = self.owner?.getCapability(self.vaultPath)?.borrow<&{FungibleToken.Receiver}>()!!
        //Confirm that we have stored a vault of the same type as the one the minter is paying with
        assert(paymentVault.isInstance(vault.getType()), message: "Purchase currency must be same type as receiver")

        //Walk through each of the set ids to purchase and mint the specified amount
        for setId in setIdToAmountMap.keys {
          var amount = setIdToAmountMap[setId]!
          assert(amount > 0, message: "Can't mint 0 or fewer NFTs of set ".concat(setId.toString()))
          let seriesId = StrikeNow.getSetSeriesId(setId)!
          let series = self.borrowSeries(seriesId: seriesId)
          while amount > 0 {
            series.mintStrikeNow(recipient: recipient, setId: setId)
            amount = amount - 1
          }
        }

        //After minting, deposit in our vault from the paying vault
        vault.deposit(from: <- paymentVault)
    }
  }

  //A public interface to allow minting on demand in exchange for DUC
  pub resource interface StrikeNowMinterPublic {
    pub fun mintStrikeNow(paymentVault: @FungibleToken.Vault, setIdToAmountMap: {UInt32: UInt32}, 
      recipient: &{NonFungibleToken.CollectionPublic})
  }

  pub resource interface StrikeNowCollectionPublic {
    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun batchDeposit(tokens: @NonFungibleToken.Collection)
    pub fun getIDs(): [UInt64]
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    pub fun borrowStrikeNow(id: UInt64): &StrikeNow.NFT? {
      post {
        (result == nil) || (result?.id == id):
          "Cannot borrow StrikeNow reference: The ID of the returned reference is incorrect"
      }
    }
  }

  pub resource Collection: StrikeNowCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
    pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

    pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
      let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

      emit Withdraw(id: token.id, from: self.owner?.address)

      return <-token
    }

    pub fun batchWithdraw(ids: [UInt64]): @NonFungibleToken.Collection {
      var batchCollection <-create Collection()

      for id in ids {
        batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
      }

      return <-batchCollection
    }

    pub fun deposit(token: @NonFungibleToken.NFT) {
      let token <-token as!@StrikeNow.NFT

      let id: UInt64 = token.id
      let oldToken <-self.ownedNFTs[id] <-token

      emit Deposit(id: id, to: self.owner?.address)

      destroy oldToken
    }

    pub fun batchDeposit(tokens: @NonFungibleToken.Collection) {
      let keys = tokens.getIDs()

      for key in keys {
        self.deposit(token: <-tokens.withdraw(withdrawID: key))
      }

      destroy tokens
    }

    pub fun getIDs(): [UInt64] {
      return self.ownedNFTs.keys
    }

    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
      return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
    }

    pub fun borrowStrikeNow(id: UInt64): &StrikeNow.NFT? {
      let ref = & self.ownedNFTs[id] as auth &NonFungibleToken.NFT?
        return ref as! &StrikeNow.NFT?
    }

    pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
      let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
      let StrikeNowNft = nft as! &StrikeNow.NFT
      return StrikeNowNft as &AnyResource{MetadataViews.Resolver}
    }

    destroy() {
      destroy self.ownedNFTs
    }

    init() {
      self.ownedNFTs <- {}
    }
  }

  pub fun createEmptyCollection(): @NonFungibleToken.Collection {
    return <-create Collection()
  }

  pub fun fetch(_ from: Address, id: UInt64): &StrikeNow.NFT? {
    let collection = getAccount(from)
      .getCapability(StrikeNow.CollectionPublicPath)
      .borrow<&StrikeNow.Collection{StrikeNow.StrikeNowCollectionPublic}>()
        ?? panic("Couldn't get collection")

    return collection.borrowStrikeNow(id: id)
  }

  pub fun getAllSeries(): [StrikeNowData.SeriesData] {
    return StrikeNow.seriesData.values
  }

  pub fun getAllSets(): [StrikeNowData.SetData] {
    return StrikeNow.setData.values
  }

  pub fun getSeriesMetadata(seriesId: UInt32): {String: String}? {
    pre {
      StrikeNow.seriesData.containsKey(seriesId): "Invalid series id ".concat(seriesId.toString())
    }
    return StrikeNow.seriesData[seriesId]?.metadataRaw
  }

  pub fun getSetMetadata(setId: UInt32): {String: String}? {
    pre {
      StrikeNow.setData.containsKey(setId): "Invalid set id ".concat(setId.toString())
    }
    return StrikeNow.setData[setId]?.metadataRaw
  }

  pub fun getSetSeriesId(_ setId: UInt32): UInt32? {
    pre {
      StrikeNow.setData.containsKey(setId): "Invalid set id ".concat(setId.toString())
    }
    return StrikeNow.setData[setId]?.seriesId
  }

  pub fun getConfigData(): StrikeNowData.ConfigData {
    return StrikeNow.config
  }

  //Returns the shuffled edition number that is mapped to the token index in that set
  pub fun getEditionNumber(seriesId: UInt32, setId: UInt32, tokenIndex: UInt32): UInt32? {
    pre {
      StrikeNow.seriesData.containsKey(seriesId): "Invalid series id ".concat(seriesId.toString())
      StrikeNow.setData.containsKey(setId): "Invalid set id ".concat(setId.toString())
    }
    return StrikeNow.series[seriesId]?.getEdition(setId: setId, tokenIndex: tokenIndex)
  }

  //Just returns the total minted for a given set, as we will be running
  //open editions
  pub fun getMaxEditions(setId: UInt32): UInt64? {
    pre {
      StrikeNow.setData.containsKey(setId): "Invalid set id ".concat(setId.toString())
    }
    return StrikeNow.numberEditionsMintedPerSet[setId]
  }

  //Return the FightData that is referenced by a particular set
  pub fun getFightForSet(_ setId: UInt32): StrikeNowData.FightData {
    pre {
      StrikeNow.setData.containsKey(setId): "Invalid set id ".concat(setId.toString())
      StrikeNow.seriesData.containsKey(StrikeNow.setData[setId]!.seriesId)
    }
    let set = StrikeNow.setData[setId]!
    let series = StrikeNow.seriesData[set.seriesId]!
    assert(series.fights.containsKey(set.fightId), message: "Could not find fight in set with id ".concat(set.fightId.toString()))
    return series.fights[set.fightId]!
  }

  pub fun getSetPurchasable(setId: UInt32): Bool {
    pre {
      StrikeNow.setData.containsKey(setId): "Invalid set id ".concat(setId.toString())
    }
    let seriesId = StrikeNow.getSetSeriesId(setId)!
    let map = StrikeNow.series[seriesId]?.onSaleStateMap!   
    return map[setId]!
  }

  //Return the total purchasability of an array of sets, as represented by
  //ids
  pub fun getSetsPurchasable(setIds: [UInt32]): Bool {
    for setId in setIds {
      if !StrikeNow.getSetPurchasable(setId: setId) { 
        return false
      }
    }
    return true
  }

  //Return the price for an individual set
  pub fun getPriceForSet(setId: UInt32): UFix64 {
    pre {
      StrikeNow.setData.containsKey(setId): "Invalid set id ".concat(setId.toString())
    }
    return StrikeNow.setData[setId]!.price
  }

  //Return the total price for a set of NFTs, represented as a map between
  //setId and count to purchase:
  //{
  //  setId: numberToPurchase,
  //  setId: numberToPurchase  
  //}
  pub fun getPriceForSetBatch(setIdToAmountMap: {UInt32: UInt32}): UFix64 {
    var price: UFix64 = 0.0
    for setId in setIdToAmountMap.keys {
      price = price + StrikeNow.getPriceForSet(setId: setId) * UFix64(setIdToAmountMap[setId]!)
    }
    return price
  }

  pub fun getOwnerAddress(): Address {
    return self.account.address
  }

  pub fun getAssetForId(setId: UInt32, assetId: UInt32): StrikeNowData.AssetData {
    pre {
      StrikeNow.setData.containsKey(setId): "Missing set id ".concat(setId.toString())
      StrikeNow.setData[setId]!.assets != nil: "No asset data on set id ".concat(setId.toString())
      StrikeNow.setData[setId]!.assets![assetId] != nil: "No asset with id ".concat(assetId.toString())
    }
    return StrikeNow.setData[setId]!.assets![assetId]!
  }

  init() {
    self.CollectionStoragePath = /storage/StrikeNowCollection
    self.CollectionPublicPath = /public/StrikeNowCollection
    self.AdminStoragePath = /storage/StrikeNowAdmin
    self.AdminPrivatePath = /private/StrikeNowAdmin
    self.MinterPublicPath = /public/StrikeNowMinter
    self.VaultPublicPath = /public/StrikeNowVault

    self.totalSupply = 0
    self.setData = {}
    self.seriesData = {}
    self.series <-{}
    self.numberEditionsMintedPerSet = {}

    //Initialize our admin resource with a path to our funds receiver vault
    let admin <- create Admin(vaultPath: self.VaultPublicPath)
    self.account.save(<- admin, to: self.AdminStoragePath)

    //Create a private capability that the deployer account can use to
    //manage the contract
    self.account.link<&StrikeNow.Admin> (
      self.AdminPrivatePath,
      target: self.AdminStoragePath
    ) ?? panic("Could not get a capability to the admin")

    //Create a public capability to access just the minter function on
    //the admin resource to enable external transactions
    self.account.link<&{StrikeNow.StrikeNowMinterPublic}> (
      self.MinterPublicPath,
      target: self.AdminStoragePath
    ) ?? panic("Could not get a capability to the admin")

    //Create a public capability to access just the receiver side of
    //our stored vault
    self.account.link<&{FungibleToken.Receiver}>(
      self.VaultPublicPath,
      target: /storage/dapperUtilityCoinVault
    ) ?? panic("Could not set up capability link for DUC vault")

    //Set up our initial configuration data
    let input = {
      "collectionName": "UFC Strike Now",
      "collectionDescription": "UFC Strike Now: Commemorate The Fight. Win The Night.",
      "externalURL": "https://ufcstrike.com/now",
      "squareImageURL": "https://media.gigantik.io/ufc/square.png",
      "squareImageMediaType": "image/png",
      "bannerImageURL": "https://media.gigantik.io/ufc/banner.png",
      "bannerImageMediaType": "image/png"
    }
    let socials = {
      "instagram": "https://instagram.com/ufcstrike",
      "twitter": "https://twitter.com/UFCStrikeNFT",
      "discord": "https://discord.gg/UFCStrike"
    }
    self.config = StrikeNowData.ConfigData(input: input, socials: socials)

    emit ContractInitialized()
  }
}