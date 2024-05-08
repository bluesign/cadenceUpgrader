import NonFungibleToken from "../0x1d7e57aa55817448;/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448;/MetadataViews.cdc"

pub contract CatchingUnicorns: NonFungibleToken {

  pub var totalSupply: UInt64

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

  pub resource interface CatchingUnicornsCollectionPublic {
    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun getIDs(): [UInt64]
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
  }

  pub resource Collection: CatchingUnicornsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
      let token <- token as! @CatchingUnicorns.NFT

      let id: UInt64 = token.id

      let oldToken <- self.ownedNFTs[id] <- token

      emit Deposit(id: id, to: self.owner?.address)

      destroy oldToken
    }

    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
      return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
    }

    pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
      let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
      let CatchingUnicorns = nft as! &CatchingUnicorns.NFT
      return CatchingUnicorns as &AnyResource{MetadataViews.Resolver}
    }

    destroy() {
      destroy self.ownedNFTs
    }
  }

  pub fun createEmptyCollection(): @NonFungibleToken.Collection {
    return <- create Collection()
  }

  pub fun mintNFT(
    recipient: &{NonFungibleToken.CollectionPublic},
    name: String,
    description: String,
    thumbnail: String,
  ) {
    var newNFT <- create NFT(
      id: CatchingUnicorns.totalSupply,
      name: name,
      description: description,
      thumbnail: thumbnail
    )

    recipient.deposit(token: <-newNFT)

    CatchingUnicorns.totalSupply = CatchingUnicorns.totalSupply + UInt64(1)
  }

  init() {
    self.totalSupply = 0

    self.CollectionStoragePath = /storage/CatchingUnicornsCollection
    self.CollectionPublicPath = /public/CatchingUnicornsCollection

    let collection <- create Collection()
    self.account.save(<-collection, to: self.CollectionStoragePath)

    self.account.link<&CatchingUnicorns.Collection{NonFungibleToken.CollectionPublic, CatchingUnicorns.CatchingUnicornsCollectionPublic, MetadataViews.ResolverCollection}>(
      self.CollectionPublicPath,
      target: self.CollectionStoragePath
    )

    emit ContractInitialized()
  }
}