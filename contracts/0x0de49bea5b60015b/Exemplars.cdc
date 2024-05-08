import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

pub contract Exemplars: NonFungibleToken {

    pub var totalSupply: UInt64
    pub let idRegistry: { UInt64: Address }
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let CollectionPrivatePath: PrivatePath

    pub event Minted(id: UInt64, address: Address)
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event ContractInitialized()

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.NFTCollectionData>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: Exemplars.CollectionStoragePath,
                        publicPath: Exemplars.CollectionPublicPath,
                        providerPath: Exemplars.CollectionPrivatePath,
                        publicCollection: Type<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                        publicLinkedType: Type<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection {return <- Exemplars.createEmptyCollection()})
            }
            return nil
        }

        init(id: UInt64) {
            self.id = id
        }
    }

    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {

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
            let token <- token as! @NFT

            let id: UInt64 = token.id

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

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let doodles = nft as! &NFT
            return doodles
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub fun mintExemplar(id: UInt64, recipient: &Collection{NonFungibleToken.Receiver}) {
        pre {
            !self.idRegistry.containsKey(id): "id is already registered"
            recipient.owner != nil: "recipient is not stored in an account"
        }

        self.idRegistry.insert(key: id, recipient.owner!.address)
        self.totalSupply = self.totalSupply + 1

        let nft <- create NFT(id: id)
        recipient.deposit(token: <-nft)

        emit Minted(id: id, address: recipient.owner!.address)
    }

    init() {
        self.totalSupply = 0
        self.idRegistry = {}
        self.CollectionStoragePath = /storage/exemplars
        self.CollectionPrivatePath = /private/exemplars
        self.CollectionPublicPath = /public/exemplars

        emit ContractInitialized()
    }
}
