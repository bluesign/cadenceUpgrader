import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract RedSquirrelNFT: NonFungibleToken {

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
                      thumbnail: MetadataViews.IPFSFile(
                          cid: self.thumbnail,
                          path: nil
                      )
                  )
            }

            return nil
        }
    }

    pub resource interface RedSquirrelNFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowRedSquirrelNFT(id: UInt64): &RedSquirrelNFT.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow RedSquirrelNFT reference: the ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: RedSquirrelNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
            let token <- token as! @RedSquirrelNFT.NFT

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
        // pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
        //     return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        // }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?) ?? panic("nothing in this index")
        }
 
        pub fun borrowRedSquirrelNFT(id: UInt64): &RedSquirrelNFT.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?) ?? panic("something1")
                return ref as! &RedSquirrelNFT.NFT
            }

            return nil
        }

        // pub fun borrowRedSquirrelNFT(id: UInt64): &NFT {
        //     let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?) ?? panic("something1")
        //     return refNFT as! &NFT
        // }


        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?) ?? panic("something2")
            let redSquirrelNFT = nft as! &RedSquirrelNFT.NFT
            return redSquirrelNFT as &AnyResource{MetadataViews.Resolver}
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

        // mintNFT mints a new NFT with a new ID
        // and deposit it in the recipients collection using their collection reference
        pub fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            name: String,
            description: String,
            thumbnail: String,
        ) {

            // create a new NFT
            var newNFT <- create NFT(
                id: RedSquirrelNFT.totalSupply,
                name: name,
                description: description,
                thumbnail: thumbnail,
            )

            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newNFT)

            RedSquirrelNFT.totalSupply = RedSquirrelNFT.totalSupply + UInt64(1)
        }
    }

    init() {
        // Initialize the total supply
        self.totalSupply = 0

        // Set the named paths
        self.CollectionStoragePath = /storage/redSquirrelNFTCollection
        self.CollectionPublicPath = /public/redSquirrelNFTCollection
        self.MinterStoragePath = /storage/redSquirrelNFTMinter

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // create a public capability for the collection
        self.account.link<&RedSquirrelNFT.Collection{NonFungibleToken.CollectionPublic, RedSquirrelNFT.RedSquirrelNFTCollectionPublic}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}