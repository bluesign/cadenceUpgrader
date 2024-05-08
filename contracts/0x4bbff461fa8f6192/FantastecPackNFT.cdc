import Crypto
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FantastecNFT, IFantastecPackNFT from 0x4bbff461fa8f6192
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract FantastecPackNFT: NonFungibleToken, IFantastecPackNFT {

    pub var totalSupply: UInt64
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let CollectionIFantastecPackNFTPublicPath: PublicPath
    pub let OperatorStoragePath: StoragePath
    pub let OperatorPrivPath: PrivatePath

    access(contract) let packs: @{UInt64: Pack}

    // from IFantastecPackNFT
    pub event Burned(id: UInt64)
    // from NonFungibleToken
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    // contract specific
    pub event Minted(id: UInt64)

    pub resource FantastecPackNFTOperator: IFantastecPackNFT.IOperator {
        pub fun mint(packId: UInt64, productId: UInt64): @NFT{
            let packNFT <- create NFT(packId: packId, productId: productId)
            FantastecPackNFT.totalSupply = FantastecPackNFT.totalSupply + 1
            emit Minted(id: packNFT.id)
            let pack <- create Pack()
            FantastecPackNFT.packs[packNFT.id] <-! pack
            return <- packNFT
        }

        pub fun open(id: UInt64, recipient: Address) {
            let pack <- FantastecPackNFT.packs.remove(key: id) ?? panic("cannot find pack with ID ".concat(id.toString()))
            pack.open(recipient: recipient)
            FantastecPackNFT.packs[id] <-! pack
        }

        pub fun addFantastecNFT(id: UInt64, nft: @FantastecNFT.NFT) {
            let pack <- FantastecPackNFT.packs.remove(key: id) ?? panic("cannot find pack with ID ".concat(id.toString()))
            pack.addFantastecNFT(nft: <- nft)
            FantastecPackNFT.packs[id] <-! pack
        }

        init(){}
    }

    pub resource Pack: IFantastecPackNFT.IFantastecPack {
        pub var ownedNFTs: @{UInt64: FantastecNFT.NFT}

        pub fun open(recipient: Address) {
            let receiver = getAccount(recipient)
                .getCapability(FantastecNFT.CollectionPublicPath)
                .borrow<&{NonFungibleToken.CollectionPublic}>()
                ?? panic("Could not get receiver reference to the NFT Collection - ".concat(recipient.toString()))
            for key in self.ownedNFTs.keys {
                let nft <-! self.ownedNFTs.remove(key: key)
                receiver.deposit(token: <- nft!)
            }
        }

        pub fun addFantastecNFT(nft: @FantastecNFT.NFT){
            let id = nft.id
            self.ownedNFTs[id] <-! nft
        }

        init() {
            self.ownedNFTs <- {}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let productId: UInt64

        destroy() {
            FantastecPackNFT.totalSupply = FantastecPackNFT.totalSupply - (1 as UInt64)
            let pack <- FantastecPackNFT.packs.remove(key: self.id)
                ?? panic("cannot find pack with ID ".concat(self.id.toString()))
            destroy pack
            emit Burned(id: self.id)
        }

        init(packId: UInt64, productId: UInt64) {
            self.id = packId
            self.productId = productId
        }

        // from MetadataViews.Resolver
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>()
                // Type<MetadataViews.ExternalURL>(),
                // Type<MetadataViews.Medias>(),
                // Type<MetadataViews.NFTCollectionData>(),
                // Type<MetadataViews.NFTCollectionDisplay>(),
                // Type<MetadataViews.Royalties>(),
                // Type<MetadataViews.Serial>(),
                // Type<MetadataViews.Traits>()
            ]
        }

        // from MetadataViews.Resolver
        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: "Fantastec Pack",
                        description: "Reveals Fantstec NFTs when opened",
                        thumbnail: MetadataViews.HTTPFile(self.getThumbnailPath())
                    )
            }
            return nil
        }

        pub fun getThumbnailPath(): String {
            return "path/to/thumbnail/".concat(self.id.toString())
        }
    }

    pub resource Collection:
        NonFungibleToken.Provider,
        NonFungibleToken.Receiver,
        NonFungibleToken.CollectionPublic,
        IFantastecPackNFT.IFantastecPackNFTCollectionPublic
    {
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
            return <- token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @FantastecPackNFT.NFT

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

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    init(){
        self.totalSupply = 0
        self.packs <- {}
        // Set our named paths
        self.CollectionStoragePath = /storage/FantastecPackNFTCollection
        self.CollectionPublicPath = /public/FantastecPackNFTCollection
        self.CollectionIFantastecPackNFTPublicPath = /public/FantastecPackNFTCollection
        self.OperatorStoragePath = /storage/FantastecPackNFTOperatorCollection
        self.OperatorPrivPath = /private/FantastecPackNFTOperatorCollection

        // Create a collection to receive Pack NFTs
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)
        self.account.link<&Collection{NonFungibleToken.CollectionPublic}>(self.CollectionPublicPath, target: self.CollectionStoragePath)
        self.account.link<&Collection{IFantastecPackNFT.IFantastecPackNFTCollectionPublic}>(self.CollectionIFantastecPackNFTPublicPath, target: self.CollectionStoragePath)

        // Create a operator to share mint capability with proxy
        let operator <- create FantastecPackNFTOperator()
        self.account.save(<-operator, to: self.OperatorStoragePath)
        self.account.link<&FantastecPackNFTOperator{IFantastecPackNFT.IOperator}>(self.OperatorPrivPath, target: self.OperatorStoragePath)
    }

}
