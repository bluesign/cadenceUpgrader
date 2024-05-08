
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract SeekEarlySupporters: NonFungibleToken {

  pub var totalSupply: UInt64
  pub let maxSupply: UInt64
  pub let mintedAdresses: [Address?]
  pub var imageUri: String

  pub event ContractInitialized()
  pub event Withdraw(id: UInt64, from: Address?)
  pub event Deposit(id: UInt64, to: Address?)

  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath

  pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
    pub let id: UInt64

    pub let name: String
    pub let description: String
    pub let thumbnail: String

    init(
      id: UInt64,
      name: String,
      description: String,
      thumbnail: String,
    ) {
      self.id = id
      self.name = name
      self.description = description
      self.thumbnail = thumbnail
    }

    pub fun getViews(): [Type] {
      return [
        Type<MetadataViews.Display>()
      ]
    }

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
      }
      return nil
    }
  }

  pub resource interface SeekCollectionPublic {
    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun getIDs(): [UInt64]
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
  }

  pub resource Collection: SeekCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
    pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

    init () {
      self.ownedNFTs <- {}
    }

    pub fun getIDs(): [UInt64] {
      return self.ownedNFTs.keys
    }
    
    pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
      let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

      emit Withdraw(id: token.id, from: self.owner?.address)

      return <-token
    }

    pub fun deposit(token: @NonFungibleToken.NFT) {
      let token <- token as! @SeekEarlySupporters.NFT

      let id: UInt64 = token.id

      let oldToken <- self.ownedNFTs[id] <- token
      
      SeekEarlySupporters.totalSupply = SeekEarlySupporters.totalSupply + UInt64(1)
      SeekEarlySupporters.mintedAdresses.append(self.owner?.address)

      emit Deposit(id: id, to: self.owner?.address)

      destroy oldToken
    }

    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
      return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
    }

    pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
      let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
      let seekEarlySupporters = nft as! &SeekEarlySupporters.NFT
      return seekEarlySupporters as &AnyResource{MetadataViews.Resolver}
    }

    

    destroy() {
      destroy self.ownedNFTs
    }
  }

  pub fun createEmptyCollection(): @NonFungibleToken.Collection {
    return <- create Collection()
  }

  pub fun mintNFT(
    address: Address,
  ): @NFT {
    let recipient = getAccount(address)
      .getCapability(SeekEarlySupporters.CollectionPublicPath)
      .borrow<&{NonFungibleToken.CollectionPublic}>()
      ?? panic("Could not get receiver reference to the NFT Collection")

    // check if user has already minted an NFT
    if self.mintedAdresses.contains(self.account.address) {
        panic("User has already minted an NFT")
    }

   // check if max supply has been reached
    if self.maxSupply == self.totalSupply {
        panic("Max supply reached")
    }

    // mint NFT
    var newNFT <- create NFT(
      id: SeekEarlySupporters.totalSupply + UInt64(1),
      name: "Seek Early Supporter",
      description: "Cherishing our early supporters! First 1.000 supporters can claim a NFT that will offer perks in the future.",
      thumbnail: self.imageUri,
    )
      return <-newNFT
  }

  init() {
    self.totalSupply = 0
    self.maxSupply = 1000
    self.mintedAdresses = []
    self.imageUri = "https://gateway.pinata.cloud/ipfs/Qma44AYC7MrnVYM7qa8yf4Nwy5cTKyuwv2U5XUFH8VwbgX?_gl=1*1q8izqv*_ga*MTIzOTA5MjA1Ny4xNjc2MDM5MDkz*_ga_5RMPXG14TE*MTY3NjkwMjEzNC42LjEuMTY3NjkwMjI2MS42MC4wLjA"

    self.CollectionStoragePath = /storage/SeekEarlySupportersCollection
    self.CollectionPublicPath = /public/SeekEarlySupportersCollection

    let collection <- create Collection()
    self.account.save(<-collection, to: self.CollectionStoragePath)

    self.account.link<&SeekEarlySupporters.Collection{NonFungibleToken.CollectionPublic, SeekEarlySupporters.SeekCollectionPublic, MetadataViews.ResolverCollection}>(
      self.CollectionPublicPath,
      target: self.CollectionStoragePath
    )

    emit ContractInitialized()
  }
}
 