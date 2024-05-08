import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract TobiraNeko: NonFungibleToken {

    pub var totalSupply: UInt64

    /***********************************************/
    /******************** PATHS ********************/
    /***********************************************/
    pub var collectionPublicPath: PublicPath
    pub var collectionStoragePath: StoragePath
    // pub var minterPublicPath: PublicPath
    pub var minterStoragePath: StoragePath

    /************************************************/
    /******************** EVENTS ********************/
    /************************************************/
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub event Mint(id: UInt64, creator: Address, metadata: {String:String})
    pub event Destroy(id: UInt64)

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let creator: Address
        access(self) let metadata: {String:String}

        init(id: UInt64, creator: Address, metadata: {String:String}) {
            self.id = id
            self.creator = creator
            self.metadata = metadata
        }

        pub fun getViews(): [Type] {
            return [Type<MetadataViews.Display>()]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.metadata["name"] ?? "",
                        description: self.metadata["description"] ?? "",
                        thumbnail: MetadataViews.HTTPFile(url: self.metadata["thumbnail"] ?? ""),
                    )
            }
            return nil
        }

        pub fun getMetadata(): {String:String} {
            return self.metadata
        }

        destroy() {
            emit Destroy(id: self.id)
        }
    }

    pub resource interface CollectionPublic {
        pub fun borrow(id: UInt64): &NFT?
    }

    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, CollectionPublic {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init() {
            self.ownedNFTs <- {}
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <- token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @TobiraNeko.NFT
            let id: UInt64 = token.id
            let dummy <- self.ownedNFTs[id] <- token
            destroy dummy
            // emit Deposit(id: id, to: self.owner?.address)
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver} {
            let authRef = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let ref = authRef as! &NFT
            return ref as! &{MetadataViews.Resolver}
        }

        pub fun borrow(id: UInt64): &NFT? {
            let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            return ref as! &NFT
        }

        pub fun getMetadata(id: UInt64): {String:String} {
            let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            return (ref as! &TobiraNeko.NFT).getMetadata()
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub resource Minter {
        pub fun mintTo(creator: Capability<&{NonFungibleToken.Receiver}>, metadata: {String:String}): &NonFungibleToken.NFT {
            let token <- create NFT(
                id: TobiraNeko.totalSupply,
                creator: creator.address,
                metadata: metadata
            )
            TobiraNeko.totalSupply = TobiraNeko.totalSupply + 1
            let tokenRef = &token as &NonFungibleToken.NFT
            // emit Mint(id: token.id, creator: creator.address, metadata: metadata)
            creator.borrow()!.deposit(token: <- token)
            return tokenRef
        }

        pub fun batchMintTo(creator: Capability<&{NonFungibleToken.Receiver}>, quantity: UInt64): UInt64 {
            var i: UInt64 = 0
            while i < quantity {
                let id = TobiraNeko.totalSupply.toString()
                let idLength = id.length
                let formattedId = "00000".concat(id).slice(from: idLength, upTo: idLength + 5)
                self.mintTo(creator: creator, metadata: {
                    "name": "TOBIRA NEKO #".concat(formattedId),
                    "description": "",
                    "thumbnail": "https://storage.googleapis.com/tobiratory-media/nft/tobiraneko/".concat(id).concat(".png"),
                    "metaURI": "https://nft.tobiratory.com/metadata/".concat(id)
                })
                i = i + UInt64(1)
            }
            return quantity
        }
    }

    // pub fun minter(): Capability<&Minter> {
    //     return self.account.getCapability<&Minter>(self.minterPublicPath)
    // }

    init() {
        self.totalSupply = 0
        self.collectionPublicPath = /public/TobiraNekoCollection001
        self.collectionStoragePath = /storage/TobiraNekoCollection001
        // self.minterPublicPath = /public/TobiraNekoMinter001
        self.minterStoragePath = /storage/TobiraNekoMinter001

        if self.account.borrow<&Minter>(from: self.minterStoragePath) == nil {
            let minter <- create Minter()
            self.account.save(<- minter, to: self.minterStoragePath)
        }

        if self.account.borrow<&TobiraNeko.Collection>(from: TobiraNeko.collectionStoragePath) == nil {
            let collection <- self.createEmptyCollection()
            self.account.save(<- collection, to: self.collectionStoragePath)
            self.account.link<&{NonFungibleToken.CollectionPublic,TobiraNeko.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(self.collectionPublicPath, target: self.collectionStoragePath)
        }

        emit ContractInitialized()
    }
}