

    import NonFungibleToken from "../0x1d7e57aa55817448;/NonFungibleToken.cdc"
    import MetadataViews from "../0x1d7e57aa55817448;/MetadataViews.cdc"
    
    access(all) contract ThaSup: NonFungibleToken {
    
      pub var totalSupply: UInt64
    
      pub event ContractInitialized()
      pub event Withdraw(id: UInt64, from: Address?)
      pub event Deposit(id: UInt64, to: Address?)
    
      pub let CollectionStoragePath: StoragePath
      pub let CollectionPublicPath: PublicPath
      pub let MinterStoragePath: StoragePath
    
      // Our NFT resource conforms to the INFT interface
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
    
      pub resource interface ThaSupCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
      }
    
      // Same goes for our Collection, it conforms to multiple interfaces 
      pub resource Collection: ThaSupCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic,  MetadataViews.ResolverCollection {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
    
        init () {
          self.ownedNFTs <- {}
        }
        
        pub fun deposit(token: @NonFungibleToken.NFT) {
          let token <- token as! @ThaSup.NFT
    
          let id: UInt64 = token.id
    
          let oldToken: @NonFungibleToken.NFT? <- self.ownedNFTs[id] <- token
          
          emit Deposit(id: id, to: self.owner?.address)
          
          destroy oldToken
        }
    
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
          let token <- self.ownedNFTs.remove(key: withdrawID) ??
            panic("This collection doesn't contain an NFT with that ID")
    
          emit Withdraw(id: token.id, from: self.owner?.address)
    
          return <- token
        }
    
        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
          return self.ownedNFTs.keys
        }
    
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
          let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
          let ThaSup = nft as! &ThaSup.NFT
          return ThaSup as &AnyResource{MetadataViews.Resolver}
        }
    
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
          return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }
    
    
    
        destroy() {
          destroy self.ownedNFTs
        }
      }
    
      pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
      }
        pub resource NFTMinter {
    
      // Mints a new NFT with a new ID and deposits it 
      // in the recipients collection using their collection reference
          pub fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            name: String,
            description: String,
            thumbnail: String,
            metadata: {String: AnyStruct},
          ) {

            // create a new NFT
            var newNFT <- create NFT(
                id: ThaSup.totalSupply,
                name: name,
                description: description,
                thumbnail: thumbnail,
                metadata: metadata,
            )
    
    
            // Deposit it in the recipient's account using their collection ref
            recipient.deposit(token: <-newNFT)
        
            ThaSup.totalSupply = ThaSup.totalSupply + 1
          }
        }
    
        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: ThaSup.CollectionStoragePath,
                        publicPath: ThaSup.CollectionPublicPath,
                        providerPath: /private/exampleNFTCollection,
                        publicCollection: Type<&ThaSup.Collection{ThaSup.ThaSupCollectionPublic}>(),
                        publicLinkedType: Type<&ThaSup.Collection{ThaSup.ThaSupCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&ThaSup.Collection{ThaSup.ThaSupCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-ThaSup.createEmptyCollection()
                        })
                    )
                    case Type<MetadataViews.NFTCollectionDisplay>():
                        let media = MetadataViews.Media(
                            file: MetadataViews.HTTPFile(
                                url: "ipfs://bafybeie4bchvcflip2wf57wn63y3wqphsdgm24nichzi3nfpaertaqbgwq/ThaSup.jpg"
                            ),
                            mediaType: "image/svg+xml" 
                        )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "ThaSup",
                        description: "The collection of Tha Supreme", 
                        externalURL: MetadataViews.ExternalURL("https://www.thasup.com"), 
                        squareImage: media, 
                        bannerImage: media, 
                        socials: {
 "Instagram":  MetadataViews.ExternalURL("www.instagram.com"),
 "Twitter":  MetadataViews.ExternalURL("www.twitter.com")
                    }
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
    
        self.CollectionStoragePath = /storage/ThaSupCollection
        self.CollectionPublicPath = /public/ThaSupCollection
        self.MinterStoragePath = /storage/ThaSupMinter
    
        // Create a Collection for the deployer
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)
    
        // Create a public capability for the collection
        self.account.link<&ThaSup.Collection{NonFungibleToken.CollectionPublic, ThaSup.ThaSupCollectionPublic}>(
          self.CollectionPublicPath,
          target: self.CollectionStoragePath
        )
    
            // Create a Minter resource and save it to storage
            let minter <- create NFTMinter()
            self.account.save(<-minter, to: self.MinterStoragePath)
    
        emit ContractInitialized()
      }
    }
    