import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract Boneyard: NonFungibleToken {

  pub struct BoneyardDisplay {
    pub let itemId: UInt64
    pub let name: String
    pub let description: String
    pub let editionSize: UInt64    
    pub let editionNumber: UInt64
    pub let collectionName: String
    pub let collectionDescription: String
    pub let collectionSquareImageCID: String
    pub let collectionBannerImageCID: String
    pub let imageCID: AnyStruct{MetadataViews.File}
    pub let creatorName: String
    pub let mintDateTime: UInt64
    pub let mintLocation: String
    pub let copyrightHolder: String
    pub let minterName: String
    pub let fileFormat: String
    pub let fileSizeMb: UFix64
    pub let rightsAndObligationsSummary: String
    pub let rightsAndObligationsFullText: String
    pub let nftRarityScore: UFix64
    pub let nftRarityDescription: String

    init(
      itemId: UInt64,
      name: String,
      description: String,
      editionSize: UInt64,
      editionNumber: UInt64,
      collectionName: String,
      collectionDescription: String,
      collectionSquareImageCID: String,
      collectionBannerImageCID: String,
      creatorName: String,
      mintDateTime: UInt64,
      mintLocation: String,
      copyrightHolder: String,
      minterName: String,
      fileFormat: String,
      fileSizeMb: UFix64,
      rightsAndObligationsSummary: String,
      rightsAndObligationsFullText: String,
      nftRarityScore: UFix64,
      nftRarityDescription: String,
      imageCID: AnyStruct{MetadataViews.File}
    ) {
      self.itemId = itemId
      self.name = name
      self.description = description
      self.editionSize = editionSize
      self.editionNumber = editionNumber
      self.collectionName = collectionName
      self.collectionDescription = collectionDescription
      self.collectionSquareImageCID = collectionSquareImageCID
      self.collectionBannerImageCID = collectionBannerImageCID
      self.imageCID = imageCID
      self.creatorName = creatorName
      self.mintDateTime = mintDateTime
      self.mintLocation = mintLocation
      self.copyrightHolder = copyrightHolder
      self.minterName = minterName
      self.fileFormat = fileFormat
      self.fileSizeMb = fileSizeMb
      self.rightsAndObligationsSummary = rightsAndObligationsSummary
      self.rightsAndObligationsFullText = rightsAndObligationsFullText
      self.nftRarityScore = nftRarityScore
      self.nftRarityDescription = nftRarityDescription
    }
  }

  // Total NFTs minted
  pub var totalSupply: UInt64

  // Events
  pub event ContractInitialized()
  pub event Withdraw(id: UInt64, from: Address?)
  pub event Deposit(id: UInt64, to: Address?)
  pub event Minted(id: UInt64, name:String)

  // Path Names
  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath
  pub let MinterStoragePath: StoragePath

  pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
    // id
    pub let id: UInt64

    // display
    pub let name: String
    pub let description: String

    pub let editionSize: UInt64
    pub let editionNumber: UInt64

    // collectionDisplay
    pub let collectionName: String
    pub let collectionDescription: String
    pub let collectionSquareImageCID: String
    pub let collectionBannerImageCID: String

    // traits
    // traits data is a dictionary of key value pairs. {
    //  "value": "Pure Jet",
    //  "rarityScore": 0.1,
    //  "rarityDescription": "Common",
    // }

    pub let nftCategoryData: [{String: AnyStruct}]
    pub let airForceData: [{String: AnyStruct}]
    pub let wingData: [{String: AnyStruct}]
    pub let squadronData: [{String: AnyStruct}]
    pub let aircraftNumberData: [{String: AnyStruct}]
    pub let roundelData: [{String: AnyStruct}]
    pub let commandMarkingData: [{String: AnyStruct}]
    pub let aircraftMarkingData: [{String: AnyStruct}]

    // IPFSFile
    pub let imageCID: String
    
    // Royalties
    access(self) let royalties: [MetadataViews.Royalty]

    pub let creatorName: String
    pub let mintDateTime: UInt64
    pub let mintLocation: String
    pub let copyrightHolder: String
    pub let minterName: String

    pub let fileFormat: String
    pub let fileSizeMb: UFix64
    
    pub let rightsAndObligationsSummary: String
    pub let rightsAndObligationsFullText: String

    pub let nftRarityScore: UFix64
    pub let nftRarityDescription: String

    init(
      id: UInt64,
      name: String,
      description: String,
      editionSize: UInt64,
      editionNumber: UInt64,
      collectionName: String,
      collectionDescription: String,
      collectionSquareImageCID: String,
      collectionBannerImageCID: String,
      nftCategoryData: [{String: AnyStruct}],
      airForceData: [{String: AnyStruct}],
      wingData: [{String: AnyStruct}],
      squadronData: [{String: AnyStruct}],
      aircraftNumberData: [{String: AnyStruct}],
      roundelData: [{String: AnyStruct}],
      commandMarkingData: [{String: AnyStruct}],
      aircraftMarkingData: [{String: AnyStruct}], 
      royalties: [MetadataViews.Royalty],
      imageCID: String,
      creatorName: String,
      copyrightHolder: String,
      mintDateTime: UInt64,
      minterName: String,
      mintLocation: String,
      fileFormat: String,
      fileSizeMb: UFix64,
      rightsAndObligationsSummary: String,
      rightsAndObligationsFullText: String,
      nftRarityScore: UFix64,
      nftRarityDescription: String
    ) {
      self.id = id
      self.name = name
      self.description = description
      self.editionSize = editionSize
      self.editionNumber = editionNumber
      self.collectionName = collectionName
      self.collectionDescription = collectionDescription
      self.collectionSquareImageCID = collectionSquareImageCID
      self.collectionBannerImageCID = collectionBannerImageCID
      self.nftCategoryData = nftCategoryData
      self.airForceData = airForceData
      self.wingData = wingData
      self.squadronData = squadronData
      self.aircraftNumberData = aircraftNumberData
      self.roundelData = roundelData
      self.commandMarkingData = commandMarkingData
      self.aircraftMarkingData = aircraftMarkingData
      self.royalties = royalties
      self.imageCID = imageCID
      self.creatorName = creatorName
      self.copyrightHolder = copyrightHolder
      self.mintDateTime = mintDateTime
      self.minterName = minterName
      self.mintLocation = mintLocation
      self.fileFormat = fileFormat
      self.fileSizeMb = fileSizeMb
      self.rightsAndObligationsSummary = rightsAndObligationsSummary
      self.rightsAndObligationsFullText = rightsAndObligationsFullText
      self.nftRarityScore = nftRarityScore
      self.nftRarityDescription = nftRarityDescription
    }

    pub fun getViews(): [Type] {
      return [       
        Type<BoneyardDisplay>(), 
        Type<MetadataViews.IPFSFile>(),
        Type<MetadataViews.Display>(),
        Type<MetadataViews.ExternalURL>(),
        Type<MetadataViews.NFTCollectionData>(),
        Type<MetadataViews.NFTCollectionDisplay>(),
        Type<MetadataViews.Medias>(),
        Type<MetadataViews.Royalties>(),
        Type<MetadataViews.Traits>(),
        Type<MetadataViews.Editions>()
      ]
    }

    pub fun resolveView(_ view: Type): AnyStruct? {
      switch view {
        case Type<BoneyardDisplay>():
          return BoneyardDisplay(
            itemId: self.id,
            name: self.name,
            description: self.description,
            editionSize: self.editionSize,
            editionNumber: self.editionNumber,
            collectionName: self.collectionName,
            collectionDescription: self.collectionDescription,
            collectionSquareImageCID: self.collectionSquareImageCID,
            collectionBannerImageCID: self.collectionBannerImageCID,
            creatorName: self.creatorName,
            mintDateTime: self.mintDateTime,
            mintLocation: self.mintLocation,
            copyrightHolder: self.copyrightHolder,
            minterName: self.minterName,
            fileFormat: self.fileFormat,
            fileSizeMb: self.fileSizeMb,
            rightsAndObligationsSummary: self.rightsAndObligationsSummary,
            rightsAndObligationsFullText: self.rightsAndObligationsFullText,
            nftRarityScore: self.nftRarityScore,
            nftRarityDescription: self.nftRarityDescription,
            imageCID: MetadataViews.IPFSFile(
              cid: self.imageCID,
              path: nil
            )
          )
        case Type<MetadataViews.IPFSFile>():
          return MetadataViews.IPFSFile(
            cid: self.imageCID,
            path: nil
          )
        case Type<MetadataViews.Display>():
          return MetadataViews.Display(
            name: self.name,
            description: self.description,
            image: MetadataViews.IPFSFile(
              cid: self.imageCID,
              path: nil
            )
          )
        case Type<MetadataViews.ExternalURL>():
          return MetadataViews.ExternalURL(url: "https://www.boneyard.cloud")
        case Type<MetadataViews.NFTCollectionData>():
          return MetadataViews.NFTCollectionData(
            storagePath: Boneyard.CollectionStoragePath,
            publicPath: Boneyard.CollectionPublicPath,
            providerPath: /private/BoneyardCollection,
            publicCollection: Type<&Boneyard.Collection{Boneyard.BoneyardCollectionPublic, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(),
            publicLinkedType: Type<&Boneyard.Collection{Boneyard.BoneyardCollectionPublic, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(),
            providerLinkedType: Type<&Boneyard.Collection{Boneyard.BoneyardCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(),
            createEmptyCollectionFunction: fun (): @NonFungibleToken.Collection {
              return <- Boneyard.createEmptyCollection()
            }
          )
        case Type<MetadataViews.NFTCollectionDisplay>():
          return MetadataViews.NFTCollectionDisplay(
            name: self.collectionName,
            description: self.collectionDescription,
            externalURL: MetadataViews.ExternalURL(url: "https://www.boneyard.cloud"),
            squareImage: MetadataViews.Media(
              file: MetadataViews.IPFSFile(
                cid: self.collectionSquareImageCID,
                path: nil,
              ),
              mediaType: "image/png"
            ),
            bannerImage: MetadataViews.Media(
              file: MetadataViews.IPFSFile(
                cid: self.collectionBannerImageCID,
                path: nil,
              ),
              mediaType: "image/png"
            ),
            socials: {
              "mastodon": MetadataViews.ExternalURL(url: "https://me.dm/@The_Boneyard"),
              "twitter": MetadataViews.ExternalURL(url: "https://twitter.com/TheBoneyardNFT")
            }
          )
        case Type<MetadataViews.Medias>():
          return MetadataViews.Medias([
            MetadataViews.Media(
              file: MetadataViews.IPFSFile(
                  cid: self.imageCID,
                  path: nil
              ),
              mediaType: "image/png"
            )
          ])
        case Type<MetadataViews.Royalties>():
          return MetadataViews.Royalties(
            royalties: self.royalties
          )
        case Type<MetadataViews.Traits>():
          // traits data is a dictionary of key value pairs. {
          //  "value": "Pure Jet",
          //  "rarityScore": 0.1,
          //  "rarityDescription": "Common",
          // }
          let nftCategoryTraits: [MetadataViews.Trait] = []
          for category in self.nftCategoryData {
            nftCategoryTraits.append(MetadataViews.Trait(
              name: "NFT Category",
              value: category["value"],
              displayType: nil,
              rarity: MetadataViews.Rarity(
                score: UFix64.fromString(category["rarityScore"]! as? String ?? "0.0"),
                max: 1.0,
                description: category["rarityDescription"] as? String ?? ""
              ),
            ))
          }
          let airForceTraits: [MetadataViews.Trait] = []
          for airForce in self.airForceData {
            airForceTraits.append(MetadataViews.Trait(
              name: "Air Force",
              value: airForce["value"],
              displayType: nil,
              rarity: MetadataViews.Rarity(
                score: UFix64.fromString(airForce["rarityScore"]! as? String ?? "0.0"),
                max: 1.0,
                description: airForce["rarityDescription"] as? String ?? ""
              ),
            ))
          }
          let wingTraits: [MetadataViews.Trait] = []
          for wing in self.wingData {
            wingTraits.append(MetadataViews.Trait(
              name: "Wing",
              value: wing["value"],
              displayType: nil,
              rarity: MetadataViews.Rarity(
                score: UFix64.fromString(wing["rarityScore"]! as? String ?? "0.0"),
                max: 1.0,
                description: wing["rarityDescription"] as? String ?? ""
              ),
            ))
          }
          let squadronTraits: [MetadataViews.Trait] = []
          for squadron in self.squadronData {
            squadronTraits.append(MetadataViews.Trait(
              name: "Squadron",
              value: squadron["value"],
              displayType: nil,
              rarity: MetadataViews.Rarity(
                score: UFix64.fromString(squadron["rarityScore"]! as? String ?? "0.0"),
                max: 1.0,
                description: squadron["rarityDescription"] as? String ?? ""
              ),
            ))
          }
          let aircraftNumberTraits: [MetadataViews.Trait] = []
          for aircraftNumber in self.aircraftNumberData {
            aircraftNumberTraits.append(MetadataViews.Trait(
              name: "Aircraft Number",
              value: aircraftNumber["value"],
              displayType: nil,
              rarity: MetadataViews.Rarity(
                score: UFix64.fromString(aircraftNumber["rarityScore"]! as? String ?? "0.0"),
                max: 1.0,
                description: aircraftNumber["rarityDescription"] as? String ?? ""
              ),
            ))
          }
          let roundelTraits: [MetadataViews.Trait] = []
          for roundel in self.roundelData {
            roundelTraits.append(MetadataViews.Trait(
              name: "Roundel",
              value: roundel["value"],
              displayType: nil,
              rarity: MetadataViews.Rarity(
                score: UFix64.fromString(roundel["rarityScore"]! as? String ?? "0.0"),
                max: 1.0,
                description: roundel["rarityDescription"] as? String ?? ""
              ),
            ))
          }
          let commandMarkingTraits: [MetadataViews.Trait] = []
          for commandMarking in self.commandMarkingData {
            commandMarkingTraits.append(MetadataViews.Trait(
              name: "Command Marking",
              value: commandMarking["value"],
              displayType: nil,
              rarity: MetadataViews.Rarity(
                score: UFix64.fromString(commandMarking["rarityScore"]! as? String ?? "0.0"),
                max: 1.0,
                description: commandMarking["rarityDescription"] as? String ?? ""
              ),
            ))
          }
          let aircraftMarkingTraits: [MetadataViews.Trait] = []
          for aircraftMarking in self.aircraftMarkingData {
            aircraftMarkingTraits.append(MetadataViews.Trait(
              name: "Aircraft Marking",
              value: aircraftMarking["value"],
              displayType: nil,
              rarity: MetadataViews.Rarity(
                score: UFix64.fromString(aircraftMarking["rarityScore"]! as? String ?? "0.0"),
                max: 1.0,
                description: aircraftMarking["rarityDescription"] as? String ?? ""
              ),
            ))
          }

          let otherTraits: [MetadataViews.Trait] = [
            MetadataViews.Trait(name: "NFT Creator", value: self.creatorName, displayType: nil, rarity: nil),
            MetadataViews.Trait(name: "NFT Copyright Holder", value: self.copyrightHolder, displayType: nil, rarity: nil),
            MetadataViews.Trait(name: "Minter Name", value: self.minterName, displayType: nil, rarity: nil),
            MetadataViews.Trait(name: "NFT Mint Date", value: self.mintDateTime, displayType: "Date", rarity: nil),
            MetadataViews.Trait(name: "NFT Mint Location", value: self.mintLocation, displayType: nil, rarity: nil),
            MetadataViews.Trait(name: "NFT License Agreement Summary", value: self.rightsAndObligationsSummary, displayType: nil, rarity: nil),
            MetadataViews.Trait(name: "NFT License Agreement Full", value: self.rightsAndObligationsFullText, displayType: nil, rarity: nil),
            MetadataViews.Trait(name: "NFT File Format", value: self.fileFormat, displayType: nil, rarity: nil),
            MetadataViews.Trait(name: "NFT File Size", value: self.fileSizeMb, displayType: nil, rarity: nil),
            MetadataViews.Trait(name: "NFT Rarity Score", value: self.nftRarityScore, displayType: nil, rarity: nil),
            MetadataViews.Trait(name: "NFT Rarity Description", value: self.nftRarityDescription, displayType: nil, rarity: nil)
          ]

          let allTraits: [MetadataViews.Trait] = nftCategoryTraits.concat(
            airForceTraits.concat(
              wingTraits.concat(
                squadronTraits.concat(
                  aircraftNumberTraits.concat(
                    roundelTraits.concat(
                      commandMarkingTraits.concat(
                        aircraftMarkingTraits.concat(
                          otherTraits
                        )
                      )
                    )
                  )
                )
              ) 
            )
          )
          
          return MetadataViews.Traits(allTraits)
        case Type<MetadataViews.Editions>():
          return MetadataViews.Editions(
            infoList: [
              MetadataViews.Edition(
                name: nil,
                number: self.editionNumber,
                max: self.editionSize,
              )
            ]
          )
      }

      return nil
    }
  }

  pub resource interface BoneyardCollectionPublic {
    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun getIDs(): [UInt64]
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    pub fun borrowBoneyard(id: UInt64): &Boneyard.NFT? {
      post {
        (result == nil) || (result?.id == id):
            "Cannot borrow Boneyard reference: the ID of the returned reference is incorrect"
      }
    }
    pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} 
  }

  pub resource Collection: BoneyardCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
      // dictionary of NFT conforming tokens
      // NFT is a resource type with an `UInt64` ID field
      pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

      init () {
        self.ownedNFTs <- {}
      }

      // withdraw removes an NFT from the collection and moves it to the caller
      pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
        let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

        emit Withdraw(id: token.id, from: self.owner?.address)

        return <-token
      }

      // deposit takes a NFT and adds it to the collections dictionary
      // and adds the ID to the id array
      pub fun deposit(token: @NonFungibleToken.NFT) {
        let token <- token as! @Boneyard.NFT

        let id: UInt64 = token.id

        // add the new token to the dictionary which removes the old one
        let oldToken <- self.ownedNFTs[id] <- token

        emit Deposit(id: id, to: self.owner?.address)

        destroy oldToken
      }

      pub fun getIDs(): [UInt64] {
        return self.ownedNFTs.keys
      }

      // borrowNFT gets a reference to an NFT in the collection
      // so that the caller can read its metadata and call its methods
      pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
        return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
      }

      pub fun borrowBoneyard(id: UInt64): &Boneyard.NFT? {
        if self.ownedNFTs[id] != nil {
          // Create an authorized reference to allow downcasting
          let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
          return ref as! &Boneyard.NFT
        }

        return nil
      }

      pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
        let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
        let Boneyard = nft as! &Boneyard.NFT
        return Boneyard as &AnyResource{MetadataViews.Resolver}
      }

      destroy() {
        destroy self.ownedNFTs
      }
  }

  pub fun createEmptyCollection(): @NonFungibleToken.Collection {
    return <- create Collection()
  }

  pub fun createMinter(): @NFTMinter {
    return <- create NFTMinter()
  }

  pub resource NFTMinter {
    // mintNFT mints a new NFT with a new ID
    // and deposit it in the recipients collection using their collection reference
    pub fun mintNFT(
      recipient: &{NonFungibleToken.CollectionPublic},
      name: String,
      description: String,
      editionSize: UInt64,
      editionNumber: UInt64,
      collectionName: String,
      collectionDescription: String,
      collectionSquareImageCID: String,
      collectionBannerImageCID: String,
      nftCategoryData: [{String: AnyStruct}],
      airForceData: [{String: AnyStruct}],
      wingData: [{String: AnyStruct}],
      squadronData: [{String: AnyStruct}],
      aircraftNumberData: [{String: AnyStruct}],
      roundelData: [{String: AnyStruct}],
      commandMarkingData: [{String: AnyStruct}],
      aircraftMarkingData: [{String: AnyStruct}],
      royalties: [MetadataViews.Royalty],
      imageCID: String,
      creatorName: String,
      copyrightHolder: String,
      mintDateTime: UInt64,
      minterName: String,
      mintLocation: String,
      fileFormat: String,
      fileSizeMb: UFix64,
      rightsAndObligationsSummary: String,
      rightsAndObligationsFullText: String,
      nftRarityScore: UFix64,
    ) {
      // setup rarity description from score
      var nftRarityDescription: String = ""
      if(nftRarityScore <= 5.0) {
        nftRarityDescription = "Common"
      } else if(nftRarityScore <= 10.0) {
        nftRarityDescription = "Uncommon"
      } else if(nftRarityScore <= 40.0) {
        nftRarityDescription = "Unusual"
      } else if(nftRarityScore <= 100.0) {
        nftRarityDescription = "Remarkable"
      } else {
        nftRarityDescription = "Rare"
      }

      var newNFT <- create NFT(
        id: Boneyard.totalSupply,
        name: name,
        description: description,
        editionSize: editionSize,
        editionNumber: editionNumber,
        collectionName: collectionName,
        collectionDescription: collectionDescription,
        collectionSquareImageCID: collectionSquareImageCID,
        collectionBannerImageCID: collectionBannerImageCID,
        nftCategoryData: nftCategoryData,
        airForceData: airForceData,
        wingData: wingData,
        squadronData: squadronData,
        aircraftNumberData: aircraftNumberData,
        roundelData: roundelData,
        commandMarkingData: commandMarkingData,
        aircraftMarkingData: aircraftMarkingData,
        royalties: royalties,
        imageCID: imageCID,
        creatorName: creatorName,
        copyrightHolder: copyrightHolder,
        mintDateTime: mintDateTime,
        minterName: minterName,
        mintLocation: mintLocation,
        fileFormat: fileFormat,
        fileSizeMb: fileSizeMb,
        rightsAndObligationsSummary: rightsAndObligationsSummary,
        rightsAndObligationsFullText: rightsAndObligationsFullText,
        nftRarityScore: nftRarityScore,
        nftRarityDescription: nftRarityDescription
      )
      
      // deposit newNFT in the recipient's account using their reference
      recipient.deposit(token: <-newNFT)

      Boneyard.totalSupply = Boneyard.totalSupply + 1
    }
  }

  init() {
    // Initialize the total supply
    self.totalSupply = 0

    // Set the named paths
    self.CollectionStoragePath = /storage/BoneyardCollection
    self.CollectionPublicPath = /public/BoneyardCollection
    self.MinterStoragePath = /storage/BoneyardMinterCollection
    
    self.account.save(<-self.createEmptyCollection(), to: self.CollectionStoragePath)

    // create a public capability for the collection
    self.account.link<&Boneyard.Collection{NonFungibleToken.CollectionPublic, Boneyard.BoneyardCollectionPublic}>(
        self.CollectionPublicPath,
        target: self.CollectionStoragePath
    )

    // Create a Minter resource and save it to storage
    self.account.save(<-self.createMinter(), to: self.MinterStoragePath)

    emit ContractInitialized()
  }
}
 
 