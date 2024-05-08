import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract IconoGraphika: NonFungibleToken {

  pub struct IconoGraphikaDisplay {
    pub let itemId: UInt64
    pub let name: String
    pub let collectionName: String
    pub let collectionDescription: String
    pub let shortDescription: String
    pub let fullDescription: String
    pub let creatorName: String
    pub let mintDateTime: UInt64
    pub let mintLocation: String
    pub let copyrightHolder: String
    pub let minterName: String
    pub let fileFormat: String
    pub let propertyObjectType: String
    pub let propertyColour: String
    pub let rightsAndObligationsSummary: String
    pub let rightsAndObligationsFullText: String
    pub let editionSize: UInt64
    pub let editionNumber: UInt64
    pub let fileSizeMb: UFix64
    pub let imageCID: AnyStruct{MetadataViews.File}

    init(
      itemId: UInt64,
      name: String,
      collectionName: String,
      collectionDescription: String,
      shortDescription: String,
      fullDescription: String,
      creatorName: String,
      mintDateTime: UInt64,
      mintLocation: String,
      copyrightHolder: String,
      minterName: String,
      fileFormat: String,
      propertyObjectType: String,
      propertyColour: String,
      rightsAndObligationsSummary: String,
      rightsAndObligationsFullText: String,
      editionSize: UInt64,
      editionNumber: UInt64,
      fileSizeMb: UFix64,
      imageCID: AnyStruct{MetadataViews.File}
    ) {
      self.itemId = itemId
      
      // String
      self.name = name
      self.collectionName = collectionName
      self.collectionDescription = collectionDescription
      self.shortDescription = shortDescription
      self.fullDescription = fullDescription
      self.creatorName = creatorName
      self.mintLocation = mintLocation
      self.copyrightHolder = copyrightHolder
      self.minterName = minterName
      self.fileFormat = fileFormat
      self.propertyObjectType = propertyObjectType
      self.propertyColour = propertyColour
      self.rightsAndObligationsSummary = rightsAndObligationsSummary
      self.rightsAndObligationsFullText = rightsAndObligationsFullText

      // UInt64
      self.mintDateTime = mintDateTime
      self.editionSize = editionSize
      self.editionNumber = editionNumber
      
      // UFix64
      self.fileSizeMb = fileSizeMb

      // IPFS
      self.imageCID = imageCID
    }
  }

  pub var totalSupply: UInt64

  pub event ContractInitialized()
  pub event Withdraw(id: UInt64, from: Address?)
  pub event Deposit(id: UInt64, to: Address?)
  pub event Minted(id: UInt64, name:String)

  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath
  pub let MinterStoragePath: StoragePath

  pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
    pub let id: UInt64

    pub let name: String
    pub let collectionName: String
    pub let collectionDescription: String
    pub let collectionSquareImageCID: String
    pub let collectionBannerImageCID: String
    pub let shortDescription: String
    pub let fullDescription: String
    pub let creatorName: String
    // Save date as unix epoch timestamp
    pub let mintDateTime: UInt64 
    pub let mintLocation: String
    pub let copyrightHolder: String
    pub let minterName: String
    pub let fileFormat: String
    pub let propertyObjectType: String
    pub let propertyColour: String
    pub let rightsAndObligationsSummary: String
    pub let rightsAndObligationsFullText: String
    pub let editionSize: UInt64
    pub let editionNumber: UInt64
    pub let fileSizeMb: UFix64
    access(self) let royalties: [MetadataViews.Royalty]
    pub let imageCID: String

    init(
      id: UInt64,
      name: String,
      collectionName: String,
      collectionDescription: String,
      collectionSquareImageCID: String,
      collectionBannerImageCID: String,
      shortDescription: String,
      fullDescription: String,
      creatorName: String,
      mintDateTime: UInt64,
      mintLocation: String,
      copyrightHolder: String,
      minterName: String,
      fileFormat: String,
      propertyObjectType: String,
      propertyColour: String,
      rightsAndObligationsSummary: String,
      rightsAndObligationsFullText: String,
      editionSize: UInt64,
      editionNumber: UInt64,
      fileSizeMb: UFix64,
      royalties: [MetadataViews.Royalty],
      imageCID: String,
    ) {
      self.id = id
      
      // String
      self.name = name
      self.collectionName = collectionName
      self.collectionDescription = collectionDescription
      self.collectionSquareImageCID = collectionSquareImageCID
      self.collectionBannerImageCID = collectionBannerImageCID
      self.shortDescription = shortDescription
      self.fullDescription = fullDescription
      self.creatorName = creatorName
      self.mintDateTime = mintDateTime
      self.mintLocation = mintLocation
      self.copyrightHolder = copyrightHolder
      self.minterName = minterName
      self.fileFormat = fileFormat
      self.propertyObjectType = propertyObjectType
      self.propertyColour = propertyColour
      self.rightsAndObligationsSummary = rightsAndObligationsSummary
      self.rightsAndObligationsFullText = rightsAndObligationsFullText

      // UInt64
      self.editionSize = editionSize
      self.editionNumber = editionNumber
      
      // UFix64
      self.fileSizeMb = fileSizeMb

      // Royalties
      self.royalties = royalties

      // IPFS
      self.imageCID = imageCID
    }

    pub fun getViews(): [Type] {
      return [
        Type<IconoGraphikaDisplay>(),
        Type<MetadataViews.IPFSFile>(),
        Type<MetadataViews.Display>(),
        Type<MetadataViews.ExternalURL>(),
        Type<MetadataViews.NFTCollectionData>(),
        Type<MetadataViews.NFTCollectionDisplay>(),
        Type<MetadataViews.Medias>(),
        Type<MetadataViews.Royalties>(),
        Type<MetadataViews.Traits>()
      ]
    }

    pub fun resolveView(_ view: Type): AnyStruct? {
      switch view {
        case Type<IconoGraphikaDisplay>():
          return IconoGraphikaDisplay(
            itemId: self.id,
            name: self.name,
            collectionName: self.collectionName,
            collectionDescription: self.collectionDescription,
            shortDescription: self.shortDescription,
            fullDescription: self.fullDescription,
            creatorName: self.creatorName,
            mintDateTime: self.mintDateTime,
            mintLocation: self.mintLocation,
            copyrightHolder: self.copyrightHolder,
            minterName: self.minterName,
            fileFormat: self.fileFormat,
            propertyObjectType: self.propertyObjectType,
            propertyColour: self.propertyColour,
            rightsAndObligationsSummary: self.rightsAndObligationsSummary,
            rightsAndObligationsFullText: self.rightsAndObligationsFullText,
            editionSize: self.editionSize,
            editionNumber: self.editionNumber,
            fileSizeMb: self.fileSizeMb,
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
            description: self.shortDescription,
            image: MetadataViews.IPFSFile(
              cid: self.imageCID,
              path: nil
            )
          )
        case Type<MetadataViews.ExternalURL>():
          return MetadataViews.ExternalURL(url: "https://iconographika.com/")
        case Type<MetadataViews.NFTCollectionData>():
          return MetadataViews.NFTCollectionData(
            storagePath: IconoGraphika.CollectionStoragePath,
            publicPath: IconoGraphika.CollectionPublicPath,
            providerPath: /private/IconoGraphikaCollection,
            publicCollection: Type<&IconoGraphika.Collection{IconoGraphika.IconoGraphikaCollectionPublic, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(),
            publicLinkedType: Type<&IconoGraphika.Collection{IconoGraphika.IconoGraphikaCollectionPublic, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(),
            providerLinkedType: Type<&IconoGraphika.Collection{IconoGraphika.IconoGraphikaCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(),
            createEmptyCollectionFunction: fun (): @NonFungibleToken.Collection {
              return <- IconoGraphika.createEmptyCollection()
            }
          )
        case Type<MetadataViews.NFTCollectionDisplay>():
          return MetadataViews.NFTCollectionDisplay(
            name: self.collectionName,
            description: self.collectionDescription,
            externalURL: MetadataViews.ExternalURL(url: "https://iconographika.com/"),
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
            socials: {}
          )
        case Type<MetadataViews.Medias>():
          return MetadataViews.Medias([
            MetadataViews.Media(
              file: MetadataViews.IPFSFile(
                  cid: self.imageCID,
                  path: nil
              ),
              mediaType: "image/".concat(self.fileFormat)
            )
          ])
        case Type<MetadataViews.Royalties>():
          return MetadataViews.Royalties(
            royalties: self.royalties
          )
        case Type<MetadataViews.Traits>():
          return MetadataViews.Traits([
            MetadataViews.Trait(name: "NFT Creator", value: self.creatorName, displayType: nil, royalty: nil),
            MetadataViews.Trait(name: "NFT Copyright Holder", value: self.copyrightHolder, displayType: nil, royalty: nil),
            MetadataViews.Trait(name: "Minter Name", value: self.minterName, displayType: nil, royalty: nil),
            MetadataViews.Trait(name: "NFT Mint Date", value: self.mintDateTime, displayType: "Date", royalty: nil),
            MetadataViews.Trait(name: "NFT Mint Location", value: self.mintLocation, displayType: nil, royalty: nil),
            MetadataViews.Trait(name: "NFT Rights and Obligations Summary", value: self.rightsAndObligationsSummary, displayType: nil, royalty: nil),
            MetadataViews.Trait(name: "NFT Rights and Obligations Full", value: self.rightsAndObligationsFullText, displayType: nil, royalty: nil),
            MetadataViews.Trait(name: "NFT Object Type", value: self.propertyObjectType, displayType: nil, royalty: nil),
            MetadataViews.Trait(name: "NFT Color", value: self.propertyColour, displayType: nil, royalty: nil)
          ])
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

  pub resource interface IconoGraphikaCollectionPublic {
    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun getIDs(): [UInt64]
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    pub fun borrowIconoGraphika(id: UInt64): &IconoGraphika.NFT? {
      post {
        (result == nil) || (result?.id == id):
            "Cannot borrow IconoGraphika reference: the ID of the returned reference is incorrect"
      }
    }
    pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} 
  }

  pub resource Collection: IconoGraphikaCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
        let token <- token as! @IconoGraphika.NFT

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

      pub fun borrowIconoGraphika(id: UInt64): &IconoGraphika.NFT? {
        if self.ownedNFTs[id] != nil {
          // Create an authorized reference to allow downcasting
          let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
          return ref as! &IconoGraphika.NFT
        }

        return nil
      }

      pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
        let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
        let IconoGraphika = nft as! &IconoGraphika.NFT
        return IconoGraphika as &AnyResource{MetadataViews.Resolver}
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
      collectionName: String,
      collectionDescription: String,
      collectionSquareImageCID: String,
      collectionBannerImageCID: String,
      shortDescription: String,
      fullDescription: String,
      creatorName: String,
      mintDateTime: UInt64,
      mintLocation: String,
      copyrightHolder: String,
      minterName: String,
      fileFormat: String,
      propertyObjectType: String,
      propertyColour: String,
      rightsAndObligationsSummary: String,
      rightsAndObligationsFullText: String,
      editionSize: UInt64,
      editionNumber: UInt64,
      fileSizeMb: UFix64,
      royalties: [MetadataViews.Royalty],
      imageCID: String,
    ) {
      var newNFT <- create NFT(
        id: IconoGraphika.totalSupply,
        name: name,
        collectionName: collectionName,
        collectionDescription: collectionDescription,
        collectionSquareImageCID: collectionSquareImageCID,
        collectionBannerImageCID: collectionBannerImageCID,
        shortDescription: shortDescription,
        fullDescription: fullDescription,
        creatorName: creatorName,
        mintDateTime: mintDateTime,
        mintLocation: mintLocation,
        copyrightHolder: copyrightHolder,
        minterName: minterName,
        fileFormat: fileFormat,
        propertyObjectType: propertyObjectType,
        propertyColour: propertyColour,
        rightsAndObligationsSummary: rightsAndObligationsSummary,
        rightsAndObligationsFullText: rightsAndObligationsFullText,
        editionSize: editionSize,
        editionNumber: editionNumber,
        fileSizeMb: fileSizeMb,
        royalties: royalties,
        imageCID: imageCID
      )
      
      // deposit newNFT in the recipient's account using their reference
      recipient.deposit(token: <-newNFT)

      IconoGraphika.totalSupply = IconoGraphika.totalSupply + 1
    }
  }

  init() {
    // Initialize the total supply
    self.totalSupply = 0

    // Set the named paths
    self.CollectionStoragePath = /storage/IconoGraphikaNFT
    self.CollectionPublicPath = /public/IconoGraphikaNFT
    self.MinterStoragePath = /storage/IconoGraphikaNFTMinter
    
    self.account.save(<-self.createEmptyCollection(), to: self.CollectionStoragePath)

    // create a public capability for the collection
    self.account.link<&IconoGraphika.Collection{NonFungibleToken.CollectionPublic, IconoGraphika.IconoGraphikaCollectionPublic}>(
        self.CollectionPublicPath,
        target: self.CollectionStoragePath
    )

    // Create a Minter resource and save it to storage
    self.account.save(<-self.createMinter(), to: self.MinterStoragePath)

    emit ContractInitialized()
  }
}
 