// A gift is not a gift.
//
// This NFT will not emit Withdraw/Deposit events until it is recognized.
// Unless the owner recognizes it himself, external viewers will probably not be able to see it.
// Once recognized by the owner, it is no longer a gift.
//
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract Gift: NonFungibleToken {
    pub let CollectionPublicPath: PublicPath
    pub let CollectionStoragePath: StoragePath
    pub var totalSupply: UInt64
    pub var giftThumbnail: AnyStruct{MetadataViews.File}
    pub var notGiftThumbnail: AnyStruct{MetadataViews.File}

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Mint(id: UInt64)
    pub event Destroy(id: UInt64)

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        access(self) var recognized: Bool

        init(id: UInt64) {
            self.id = id
            self.recognized = false
        }

        pub fun recognize() {
            self.recognized = true
        }

        pub fun isGift(): Bool {
            return !self.recognized
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
                        name: (self.isGift() ? "Gift #" : "NOT Gift #").concat(self.id.toString()),
                        description: self.isGift() ? "This is a gift." : "This is NOT a gift.",
                        thumbnail: self.isGift() ? Gift.giftThumbnail : Gift.notGiftThumbnail,
                    )
            }
            return nil
        }

        destroy() {
            emit Destroy(id: self.id)
        }
    }

    pub resource interface GiftCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowGift(id: UInt64): &Gift.NFT? {
            post {
                (result == nil) || (result?.id == id): "Cannot borrow Gift reference"
            }
        }
    }

    pub resource Collection: GiftCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT")
            let tokenRef = (&token as auth &NonFungibleToken.NFT?)! as! &Gift.NFT
            if !tokenRef.isGift() {
                emit Withdraw(id: token.id, from: self.owner?.address)
            }
            return <- token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Gift.NFT
            let id: UInt64 = token.id
            if !token.isGift() {
                emit Deposit(id: id, to: self.owner?.address)
            }
            self.ownedNFTs[id] <-! token
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowGift(id: UInt64): &Gift.NFT? {
            if self.ownedNFTs[id] != nil {
                return (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)! as! &Gift.NFT
            }
            return nil
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)! as! &Gift.NFT
            return nft as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub resource Maintainer {
        pub fun setThumbnail(giftThumbnail: AnyStruct{MetadataViews.File}, notGiftThumbnail: AnyStruct{MetadataViews.File}) {
            Gift.giftThumbnail = giftThumbnail
            Gift.notGiftThumbnail = notGiftThumbnail
        }
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub fun mintNFT(): @NFT {
        Gift.totalSupply = Gift.totalSupply + 1
        emit Mint(id: Gift.totalSupply)
        return <- create NFT(id: Gift.totalSupply)
    }

    init() {
        self.CollectionPublicPath = /public/GiftCollection
        self.CollectionStoragePath = /storage/GiftCollection
        self.totalSupply = 0
        self.giftThumbnail = MetadataViews.HTTPFile(url: "https://nftstorage.link/ipfs/bafkreicmoh2ummsp4qgyp6fvk7lj7uy44jmnymhl6v75h5bbexf5i6njdm")
        self.notGiftThumbnail = MetadataViews.HTTPFile(url: "https://nftstorage.link/ipfs/bafkreiftdj3uj25a4tdnofc3ht6ir2pftwbn2dvtxsajj3rzkrsbdvkkqi")
        self.account.save(<- create Maintainer(), to: /storage/GiftMaintainer)
        self.account.save(<- create Collection(), to: self.CollectionStoragePath)
        self.account.link<&Gift.Collection{NonFungibleToken.CollectionPublic, Gift.GiftCollectionPublic}>(self.CollectionPublicPath, target: self.CollectionStoragePath)

        emit ContractInitialized()
    }
}
