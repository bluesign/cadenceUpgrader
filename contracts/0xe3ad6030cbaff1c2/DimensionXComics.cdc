import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import DimensionX from "./DimensionX.cdc"

pub contract DimensionXComics: NonFungibleToken {

    pub var totalSupply: UInt64

    pub var totalBurned: UInt64


    pub var metadataUrl: String


    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Mint(id: UInt64)
    pub event Burn(id: UInt64)
    pub event TurnIn(id: UInt64, hero: UInt64)

    pub event MinterCreated()

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let AdminStoragePath: StoragePath
    pub let MinterStoragePath: StoragePath


    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {

        pub let id: UInt64

        init(
            id: UInt64
        ) {
            self.id = id
        }

        destroy () {
            DimensionXComics.totalBurned = DimensionXComics.totalBurned + UInt64(1)
            emit Burn(id: self.id)
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL(
                        url: DimensionXComics.metadataUrl.concat("comics/").concat(self.id.toString())
                    )
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: ("DimensionXComics #").concat(self.id.toString()),
                        description: "A Comics NFT Project with Utility in the Dimension-X Game!",
                        thumbnail: MetadataViews.HTTPFile(
                        url: DimensionXComics.metadataUrl.concat("comics/i/").concat(self.id.toString()).concat(".jpg")
                        )
                    )
                case Type<MetadataViews.Royalties>():
                    let royalties : [MetadataViews.Royalty] = []
                    royalties.append(MetadataViews.Royalty(recepient: DimensionXComics.account.getCapability<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath()), cut: UFix64(0.10), description: "Crypthulhu royalties"))
                    return MetadataViews.Royalties(cutInfos: royalties)
                   
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: DimensionXComics.CollectionStoragePath,
                        publicPath: DimensionXComics.CollectionPublicPath,
                        providerPath: /private/dmxComicsCollection,
                        publicCollection: Type<&DimensionXComics.Collection{DimensionXComics.CollectionPublic}>(),
                        publicLinkedType: Type<&DimensionXComics.Collection{DimensionXComics.CollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&DimensionXComics.Collection{DimensionXComics.CollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-DimensionXComics.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    return MetadataViews.NFTCollectionDisplay(
                        name: "Dimension X",
                        description: "Dimension X is a Free-to-Play, Play-to-Earn strategic role playing game on the Flow blockchain set in the Dimension X comic book universe, where a pan-dimensional explosion created super powered humans, aliens and monsters with radical and terrifying superpowers!",
                        externalURL: MetadataViews.ExternalURL("https://dimensionxnft.com"),
                        squareImage: MetadataViews.Media(
                            file: MetadataViews.HTTPFile(url: DimensionXComics.metadataUrl.concat("comics/collection_image.png")),
                            mediaType: "image/png"
                        ),
                        bannerImage: MetadataViews.Media(
                            file: MetadataViews.HTTPFile(url: DimensionXComics.metadataUrl.concat("comics/collection_banner.png")),
                            mediaType: "image/png"
                        ),
                        socials: {
                            "discord": MetadataViews.ExternalURL("https://discord.gg/dimensionx"),
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/DimensionX_NFT")
                        }
                    )
                    
            }

            return nil
        }
    }

    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowDimensionXComics(id: UInt64): &DimensionXComics.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow DimensionXComics reference: the ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
            let token <- token as! @DimensionXComics.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }
 
        pub fun borrowDimensionXComics(id: UInt64): &DimensionXComics.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &DimensionXComics.NFT
            }

            return nil
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let dmxNft = nft as! &DimensionXComics.NFT
            return dmxNft as &AnyResource{MetadataViews.Resolver}
        }

        pub fun turnInComics(comic_ids: [UInt64], hero: &DimensionX.NFT)  {
            if (comic_ids.length > 4) {
                panic("Too many comics being burned")
            }

            if (self.owner?.address != hero.owner?.address) {
                panic("You must own the hero")
            }

            for id in comic_ids {
                let token <- self.withdraw(withdrawID: id)
                emit TurnIn(id: token.id, hero: hero.id)
                destroy token
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
    pub resource NFTMinter {
        // range if possible
  
        // Determine the next available ID for the rest of NFTs and take into
        // account the custom NFTs that have been minted outside of the reserved
        // range
        pub fun getNextID(): UInt64 {
       
            return DimensionXComics.totalSupply + UInt64(1)
        }

        
/* 
        pub fun mintNFT(
            recipient: &Collection{NonFungibleToken.CollectionPublic},
        ) {
            // Determine the next available ID
            var nextId = self.getNextID()

            // Update supply counters
            DimensionXComics.totalSupply = DimensionXComics.totalSupply + UInt64(1)

            self.mint(
                recipient: recipient,
                id: nextId
            )
        }

       
 
        priv fun mint(
            recipient: &Collection{NonFungibleToken.CollectionPublic},
            id: UInt64
        ) {
            panic("Minting currently disabled")
            // create a new NFT
            var newNFT <- create NFT(id: id)
            emit Mint(id: id)
              
            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newNFT)
        }
        */
    }

    pub resource Admin {


        pub fun setMetadataUrl(url: String) {
            DimensionXComics.metadataUrl = url
        }

        pub fun createNFTMinter(): @NFTMinter {
            emit MinterCreated()
            return <-create NFTMinter()
        }
    
    }

    init() {
        // Initialize supply counters
        self.totalSupply = 0

        // Initialize burned counters
        self.totalBurned = 0
 
        self.metadataUrl = "https://metadata.dimensionx.com/"



        // Set the named paths
        self.CollectionStoragePath = /storage/dmxComicsCollection
        self.CollectionPublicPath = /public/dmxComicsCollection
        self.AdminStoragePath = /storage/dmxComicsAdmin
        self.MinterStoragePath = /storage/dmxComicsMinter

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // create a public capability for the collection
        self.account.link<&DimensionXComics.Collection{NonFungibleToken.CollectionPublic, CollectionPublic}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        let admin <- create Admin()
        let minter <- admin.createNFTMinter()
        self.account.save(<-admin, to: self.AdminStoragePath)
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}
