//this address was 0xf8d6e0586b0a20c7 on localhost
//testnet: 0x631e88ae7f1d7c20
//mainnet: 0x1d7e57aa55817448

import NonFungibleToken from "../0x1d7e57aa55817448;/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448;/MetadataViews.cdc"
import ViewResolver from "../0x1d7e57aa55817448;/ViewResolver.cdc"

pub contract aiSportsMinter: NonFungibleToken, ViewResolver {
  // Total supply of aiSportsMinters in existence
  pub var totalSupply: UInt64
  // total burned moments
  pub var totalBurned: UInt64

  // The event that is emitted when the contract is created
  pub event ContractInitialized()

  // The event that is emitted when an NFT is withdrawn from a Collection
  pub event Withdraw(id: UInt64, from: Address?)
  // The event that is emitted when an NFT is deposited to a Collection
  pub event Deposit(id: UInt64, to: Address?)
  // The event that is emitted when an NFT is burned
  pub event Burn(id: UInt64)

  /// Storage and Public Paths
  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath
  pub let MinterStoragePath: StoragePath
  pub let AdminStoragePath: StoragePath


  pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
    
    // The unique ID that each NFT has
    pub let id: UInt64

    //Metadata fields
    pub let name: String
    pub let description: String
    pub let thumbnail: String
    pub let edition: String //this could be moved to Metadata
    pub var items: @{UInt64: AnyResource}
    access(self) let royalties: [MetadataViews.Royalty]
    access(self) let metadata: {String: AnyStruct}

    init(
      id: UInt64,
      name: String,
      description: String,
      edition: String,
      thumbnail: String,
      royalties: [MetadataViews.Royalty],
      metadata: {String: AnyStruct},
    ) {
      self.id = id
      self.name = name
      self.description = description
      self.edition = edition
      self.thumbnail = thumbnail
      self.items <- {}
      self.royalties = royalties
      self.metadata = metadata
    }

    /// Function that returns all the Metadata Views implemented by a Non Fungible Token
    ///
    /// @return An array of Types defining the implemented views. This value will be used by
    /// developers to know which parameter to pass to the resolveView() method.
    pub fun getViews(): [Type] {
      return [
        Type<MetadataViews.Display>(),
        Type<MetadataViews.Royalties>(),
        Type<MetadataViews.Editions>(),
        Type<MetadataViews.ExternalURL>(),
        Type<MetadataViews.NFTCollectionData>(),
        Type<MetadataViews.NFTCollectionDisplay>(),
        Type<MetadataViews.Serial>(),
        Type<MetadataViews.Traits>()
      ]
    }


    /// Function that resolves a metadata view for this token.
    ///
    /// @param view: The Type of the desired view.
    /// @return A structure representing the requested view.
    ///
    pub fun resolveView(_ view: Type): AnyStruct? {
      switch view {
        case Type<MetadataViews.Display>():
          return MetadataViews.Display(
            name: self.name,
            description: self.description,
            thumbnail: MetadataViews.HTTPFile(
              url: self.thumbnail
            )
          )
        case Type<MetadataViews.Editions>():
          // There is no max number of NFTs that can be minted from this contract
          // so the max edition field value is set to nil
          let editionInfo = MetadataViews.Edition(name: self.edition, number: self.id, max: nil)
          let editionList: [MetadataViews.Edition] = [editionInfo]
          return MetadataViews.Editions(
              editionList
          )
        case Type<MetadataViews.Serial>():
          return MetadataViews.Serial(
              self.id
          )
        case Type<MetadataViews.Royalties>():
          return MetadataViews.Royalties(
              self.royalties
          )
        case Type<MetadataViews.ExternalURL>():
          return MetadataViews.ExternalURL(
            //"https://example-nft.onflow.org/".concat(self.id.toString())//this was the example
            "https://www.aisportspro.com/"
          )
        case Type<MetadataViews.NFTCollectionData>():
          return MetadataViews.NFTCollectionData(
              storagePath: aiSportsMinter.CollectionStoragePath,
              publicPath: aiSportsMinter.CollectionPublicPath,
              providerPath: /private/aiSportsMinterCollection,
              publicCollection: Type<&aiSportsMinter.Collection{aiSportsMinter.aiSportsMinterCollectionPublic}>(),
              publicLinkedType: Type<&aiSportsMinter.Collection{aiSportsMinter.aiSportsMinterCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
              providerLinkedType: Type<&aiSportsMinter.Collection{aiSportsMinter.aiSportsMinterCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
              createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                  return <-aiSportsMinter.createEmptyCollection()
              })
          )
        case Type<MetadataViews.NFTCollectionDisplay>():
          let media = MetadataViews.Media(
              file: MetadataViews.HTTPFile(
                  url: "https://firebasestorage.googleapis.com/v0/b/fantasyball-6e433.appspot.com/o/upload_image.png?alt=media&token=947bf82d-b697-4cb2-b58f-17b237705ae5"
              ),
              mediaType: "image/png"
          )
          return MetadataViews.NFTCollectionDisplay(
              name: "The aiSports Collection",
              description: "This collection is the home of the official aSports' NFTs.",
              externalURL: MetadataViews.ExternalURL("https://www.aisportspro.com/"),
              squareImage: media,
              bannerImage: media,
              socials: {
                  "twitter": MetadataViews.ExternalURL("https://twitter.com/aisportspro")
              }
          )
        case Type<MetadataViews.Traits>():
          // exclude mintedTime and foo to show other uses of Traits
          let excludedTraits = ["mintedTime"]
          let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)

          // mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
          let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
          traitsView.addTrait(mintedTimeTrait)

          /*
          // foo is a trait with its own rarity
          let fooTraitRarity = MetadataViews.Rarity(score: 10.0, max: 100.0, description: "Common")
          let fooTrait = MetadataViews.Trait(name: "foo", value: self.metadata["foo"], displayType: nil, rarity: fooTraitRarity)
          traitsView.addTrait(fooTrait)

          */
          
          return traitsView
          
      }
      return nil
    }

    access(contract) fun updateStatus(status: String) {
      self.metadata["status"] = status
    }

    destroy() {
      destroy self.items
      aiSportsMinter.totalBurned = aiSportsMinter.totalBurned + UInt64(1)
      emit Burn(id: self.id)
    }
  }

  pub resource interface aiSportsMinterCollectionPublic {
    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun getIDs(): [UInt64]
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    pub fun borrowAiSportsMinter(id: UInt64): &aiSportsMinter.NFT? {
      post {
          (result == nil) || (result?.id == id):
              "Cannot borrow aiSportsMinter reference: the ID of the returned reference is incorrect"
      }
    }
  }

  pub resource Collection: aiSportsMinterCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
    
    // dictionary of NFT conforming tokens
    // NFT is a resource type with an `UInt64` ID field
    pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

    init () {
      self.ownedNFTs <- {}
    }

    /// Helper method for getting the collection IDs
    ///
    /// @return An array containing the IDs of the NFTs in the collection
    ///
    pub fun getIDs(): [UInt64] {
      return self.ownedNFTs.keys
    }


    /// Removes an NFT from the collection and moves it to the caller
    ///
    /// @param withdrawID: The ID of the NFT that wants to be withdrawn
    /// @return The NFT resource that has been taken out of the collection
    ///
    pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
      let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

      emit Withdraw(id: token.id, from: self.owner?.address)

      return <-token
    }

      /// Adds an NFT to the collections dictionary and adds the ID to the id array
      ///
      /// @param token: The NFT resource to be included in the collection
      /// 
    pub fun deposit(token: @NonFungibleToken.NFT) {
      let token <- token as! @aiSportsMinter.NFT

      let id: UInt64 = token.id

      let oldToken <- self.ownedNFTs[id] <- token

      emit Deposit(id: id, to: self.owner?.address)

      destroy oldToken
    }


    /// Gets a reference to an NFT in the collection so that 
    /// the caller can read its metadata and call its methods
    ///
    /// @param id: The ID of the wanted NFT
    /// @return A reference to the wanted NFT resource
    ///

    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
      return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
    }

    /// Gets a reference to an NFT in the collection so that 
    /// the caller can read its metadata and call its methods
    ///
    /// @param id: The ID of the wanted NFT
    /// @return A reference to the wanted NFT resource
    ///       
    pub fun borrowAiSportsMinter(id: UInt64): &aiSportsMinter.NFT? {
      if self.ownedNFTs[id] != nil {
          // Create an authorized reference to allow downcasting
          let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
          return ref as! &aiSportsMinter.NFT
      }

      return nil
    }


    pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
      let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
      let aiSportsMinter = nft as! &aiSportsMinter.NFT
      return aiSportsMinter as &AnyResource{MetadataViews.Resolver}
    }

    destroy() {
      destroy self.ownedNFTs
    }
  }

  pub fun createEmptyCollection(): @NonFungibleToken.Collection {
    return <- create Collection()
  }

  pub resource Admin {
    pub fun updateStatus(userNft: &aiSportsMinter.NFT, status: String) {
      //let value = ref as! &aiSportsMinter.NFT
      userNft.updateStatus(status: status)
    }
  }

  /// Resource that an admin or something similar would own to be
  /// able to mint new NFTs
  ///
  pub resource NFTMinter {

    /// Mints a new NFT with a new ID and deposit it in the
    /// recipients collection using their collection reference
    ///
    /// @param recipient: A capability to the collection where the new NFT will be deposited
    /// @param name: The name for the NFT metadata
    /// @param description: The description for the NFT metadata
    /// @param thumbnail: The thumbnail for the NFT metadata
    /// @param royalties: An array of Royalty structs, see MetadataViews docs 
    ///   

    pub fun mintNFT(
      
      recipient: &{NonFungibleToken.CollectionPublic},
      name: String,
      description: String,
      edition: String,
      thumbnail: String,
      royalties: [MetadataViews.Royalty],
      status: String,
      player: String,
      landscape: String,
      scene: String,
      style: String,
      medium: String      
    ) {
      let metadata: {String: AnyStruct} = {}
      let currentBlock = getCurrentBlock()
      metadata["mintedBlock"] = currentBlock.height
      metadata["mintedTime"] = currentBlock.timestamp
      metadata["minter"] = recipient.owner!.address

      metadata["Status"] = status
      metadata["Player"] = player
      metadata["Landscape"] = landscape
      metadata["Scene"] = scene
      metadata["Style"] = style
      metadata["Medium"] = medium


      // create a new NFT
      var newNFT <- create NFT(
        id: aiSportsMinter.totalSupply,
        name: name,
        description: description,
        edition: edition,
        thumbnail: thumbnail,
        royalties: royalties,
        metadata: metadata,
      )

      // deposit it in the recipient's account using their reference
      recipient.deposit(token: <-newNFT)

      aiSportsMinter.totalSupply = aiSportsMinter.totalSupply + UInt64(1)
    }
  }

  /// Function that resolves a metadata view for this contract.
  ///
  /// @param view: The Type of the desired view.
  /// @return A structure representing the requested view.
  ///
  pub fun resolveView(_ view: Type): AnyStruct? {
      switch view {
          case Type<MetadataViews.NFTCollectionData>():
              return MetadataViews.NFTCollectionData(
                  storagePath: aiSportsMinter.CollectionStoragePath,
                  publicPath: aiSportsMinter.CollectionPublicPath,
                  providerPath: /private/aiSportsMinterCollection,
                  publicCollection: Type<&aiSportsMinter.Collection{aiSportsMinter.aiSportsMinterCollectionPublic}>(),
                  publicLinkedType: Type<&aiSportsMinter.Collection{aiSportsMinter.aiSportsMinterCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                  providerLinkedType: Type<&aiSportsMinter.Collection{aiSportsMinter.aiSportsMinterCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                  createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                      return <-aiSportsMinter.createEmptyCollection()
                  })
              )
          case Type<MetadataViews.NFTCollectionDisplay>():
              let media = MetadataViews.Media(
                  file: MetadataViews.HTTPFile(
                      url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"
                  ),
                  mediaType: "image/svg+xml"
              )
      }
      return nil
    }

    /// Function that returns all the Metadata Views implemented by a Non Fungible Token
    ///
    /// @return An array of Types defining the implemented views. This value will be used by
    ///         developers to know which parameter to pass to the resolveView() method.
    ///
    pub fun getViews(): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>()
        ]
    }

  init() {
    self.totalSupply = 0
    self.totalBurned = 0

    self.CollectionStoragePath = /storage/aiSportsMinterCollection
    self.CollectionPublicPath = /public/aiSportsMinterCollection
    self.MinterStoragePath = /storage/aiSportsMinterStorage //if we change this contract name to aiSports from aiSportsMinter, this storage should be /storage/aiSportsMinter
    self.AdminStoragePath = /storage/aiSportsAdmin


    let collection <- create Collection()
    self.account.save(<-collection, to: self.CollectionStoragePath)

    // create a public capability for the collection
    self.account.link<&aiSportsMinter.Collection{NonFungibleToken.CollectionPublic, aiSportsMinter.aiSportsMinterCollectionPublic, MetadataViews.ResolverCollection}>(
      self.CollectionPublicPath,
      target: self.CollectionStoragePath
    )
    // Create a Minter resource and save it to storage
    let minter <- create NFTMinter()
    let admin <- create Admin()
    self.account.save(<-minter, to: self.MinterStoragePath)
    self.account.save(<-admin, to: self.AdminStoragePath)


    emit ContractInitialized()
  }
}
 