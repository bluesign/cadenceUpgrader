
  import NonFungibleToken from "../0x1d7e57aa55817448;/NonFungibleToken.cdc"
  import MetadataViews from "../0x1d7e57aa55817448;/MetadataViews.cdc"
  
  pub contract TestCollection: NonFungibleToken {
  
    pub var totalSupply: UInt64
  
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
  
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath
  
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
      pub let id: UInt64
  
      pub let name: String
      pub let description: String
      pub let thumbnail: String
      pub let metadata: {String: AnyStruct}
  
      init(
          id: UInt64,
          name: String,
          description: String,
          thumbnail: String,
          metadata: {String: AnyStruct},
      ) {
          self.id = id
          self.name = name
          self.description = description
          self.thumbnail = thumbnail
          self.metadata = metadata
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
  
    pub resource interface TestCollectionCollectionPublic {
      pub fun deposit(token: @NonFungibleToken.NFT)
      pub fun getIDs(): [UInt64]
      pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    }
  
    pub resource Collection: TestCollectionCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
        let token <- token as! @TestCollection.NFT
  
        let id: UInt64 = token.id
  
        let oldToken: @NonFungibleToken.NFT? <- self.ownedNFTs[id] <- token
  
        emit Deposit(id: id, to: self.owner?.address)
  
        destroy oldToken
      }
  
      pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
        return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
      }
  
      pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
        let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
        let TestCollection = nft as! &TestCollection.NFT
        return TestCollection as &AnyResource{MetadataViews.Resolver}
      }
  
      destroy() {
        destroy self.ownedNFTs
      }
    }
  
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
      return <- create Collection()
    }
    pub resource NFTMinter {
    pub fun mintNFT(
      recipient: &{NonFungibleToken.CollectionPublic},
      name: String,
      description: String,
      thumbnail: String,
      metadata: {String: AnyStruct}
    ) {
      var newNFT <- create NFT(
        id: TestCollection.totalSupply,
        name: name,
        description: description,
        thumbnail: thumbnail,
        metadata: metadata,
      )
  
      recipient.deposit(token: <-newNFT)
  
      TestCollection.totalSupply = TestCollection.totalSupply + 1
    }
    pub fun resolveView(_ view: Type): AnyStruct? {
      switch view {
          case Type<MetadataViews.NFTCollectionData>():
              return MetadataViews.NFTCollectionData(
                  storagePath: TestCollection.CollectionStoragePath,
                  publicPath: TestCollection.CollectionPublicPath,
                  providerPath: /private/TestCollectionCollection,
                  publicCollection: Type<&TestCollection.Collection{TestCollection.TestCollectionCollectionPublic}>(),
                  publicLinkedType: Type<&TestCollection.Collection{TestCollection.TestCollectionCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                  providerLinkedType: Type<&TestCollection.Collection{TestCollection.TestCollectionCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                  createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                      return <-TestCollection.createEmptyCollection()
                  })
              )
      }
      return nil
  }
}
  /// Function that returns all the Metadata Views implemented by a Non Fungible Token
  ///
  /// @return An array of Types defining the implemented views. This value will be used by
  ///         developers to know which parameter to pass to the resolveView() method.
  ///
  pub fun getViews(): [Type] {
      return [
          Type<MetadataViews.NFTCollectionData>()
      ]
  }
  
    init() {
      self.totalSupply = 0
  
      self.CollectionStoragePath = /storage/TestCollectionCollection
      self.CollectionPublicPath = /public/TestCollectionCollection
      self.MinterStoragePath = /storage/TestCollectionMinter
  
      let collection <- create Collection()
      self.account.save(<-collection, to: self.CollectionStoragePath)
  
      self.account.link<&TestCollection.Collection{NonFungibleToken.CollectionPublic, TestCollection.TestCollectionCollectionPublic, MetadataViews.ResolverCollection}>(
        self.CollectionPublicPath,
        target: self.CollectionStoragePath
      )
      let minter <- create NFTMinter()
      self.account.save(<-minter, to: self.MinterStoragePath)
  
      emit ContractInitialized()
    }
  }