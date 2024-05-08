import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

pub contract BalloonSampleNFT: NonFungibleToken {

    /// Total supply of BalloonSampleNFT in existence
    pub var totalSupply: UInt64

    /// The event that is emitted when the contract is created
    pub event ContractInitialized()

    /// The event that is emitted when an NFT is withdrawn from a Collection
    pub event Withdraw(id: UInt64, from: Address?)

    /// The event that is emitted when an NFT is deposited to a Collection
    pub event Deposit(id: UInt64, to: Address?)

    /// Storage and Public Paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    /// The core resource that represents a Non Fungible Token.
    /// and stored in the Collection resource
    ///
    pub resource NFT: NonFungibleToken.INFT {

        /// The unique ID that each NFT has
        pub let id: UInt64

        /// Metadata fields
        pub let name: String
        pub let rgbColor: String
        pub let inflation: UInt64
        access(self) let metadata: {String: AnyStruct}

        init(
            id: UInt64,
            name: String,
            rgbColor: String,
            inflation: UInt64,
            metadata: {String: AnyStruct},
        ) {
            self.id = id
            self.name = name
            self.rgbColor = rgbColor
            self.inflation = inflation
            self.metadata = metadata
        }
    }

    pub resource interface BalloonSampleNFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowBalloonSampleNFT(id: UInt64): &BalloonSampleNFT.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow BalloonSampleNFT reference: the ID of the returned reference is incorrect"
            }
        }
    }

    /// The resource that will be holding the NFTs inside any account.
    /// In order to be able to manage NFTs any account will need to create
    /// an empty collection first
    ///
    pub resource Collection: BalloonSampleNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }


        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }


        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @BalloonSampleNFT.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }


        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }


        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }


        pub fun borrowBalloonSampleNFT(id: UInt64): &BalloonSampleNFT.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &BalloonSampleNFT.NFT
            }

            return nil
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
            rgbColor: String,
            inflation: UInt64
        ) {
            let metadata: {String: AnyStruct} = {}
            let currentBlock = getCurrentBlock()
            metadata["mintedBlock"] = currentBlock.height
            metadata["mintedTime"] = currentBlock.timestamp
            metadata["minter"] = recipient.owner!.address


            var newNFT <- create NFT(
                id: BalloonSampleNFT.totalSupply,
                name: name,
                rgbColor: rgbColor,
                inflation: inflation,
                metadata: metadata,
            )
            recipient.deposit(token: <-newNFT)

            BalloonSampleNFT.totalSupply = BalloonSampleNFT.totalSupply + UInt64(1)
    }

    init() {
        // Initialize the total supply
        self.totalSupply = 0

        // Set the named paths
        self.CollectionStoragePath = /storage/balloonSampleNFTCollection
        self.CollectionPublicPath = /public/balloonSampleNFTCollection

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // create a public capability for the collection
        self.account.link<&BalloonSampleNFT.Collection{NonFungibleToken.CollectionPublic, BalloonSampleNFT.BalloonSampleNFTCollectionPublic}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        emit ContractInitialized()
    }
}