// import FungibleToken from "../0x9a0766d93b6608b7/FungibleToken.cdc"
// import NonFungibleToken from "../0x631e88ae7f1d7c20/NonFungibleToken.cdc"
// import MetadataViews from "../0x631e88ae7f1d7c20/MetadataViews.cdc"

import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract Syllables: NonFungibleToken {
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event PublishedMinted(id: UInt64, name: String, ipfsLink: String, type: UInt64)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterPublishedPath: StoragePath

    pub var totalSupply: UInt64
    pub var libraryPassTotalSupply: UInt64
    pub var willoTotalSupply: UInt64

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let serialId: UInt64
        pub let id: UInt64
        pub let name: String
        pub let ipfsLink: String
        pub let type: UInt64

        init(serialId: UInt64, initID: UInt64, name: String, ipfsLink: String, type: UInt64) {
            self.serialId = serialId
            self.id = initID
            self.name = name
            self.ipfsLink = ipfsLink
            self.type= type
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            let url = "https://ipfs.io/ipfs/".concat(self.ipfsLink)
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: "Photographer, best-selling author, mentor, consultant. Recipient of the Hamdan International Photography Award Content Creator Award 2019. Sony Digital Imaging Ambassador\n\n Registration group element - New Zealand \n Registrant element - Published NFT \n Publication element - Edition #1 \n ISBN: 978-0241426418 \n",
                        thumbnail: MetadataViews.IPFSFile(
                            cid: self.ipfsLink,
                            path: nil
                        )
                    )
                case Type<MetadataViews.Royalties>():
                    var royalties: [MetadataViews.Royalty] = []
                    return MetadataViews.Royalties(royalties)
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.serialId
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL(url)

                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: Syllables.CollectionStoragePath,
                        publicPath: Syllables.CollectionPublicPath,
                        providerPath: /private/SyllablesCollection,
                        publicCollection: Type<&Syllables.Collection{Syllables.SyllablesCollectionPublic}>(),
                        publicLinkedType: Type<&Syllables.Collection{Syllables.SyllablesCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&Syllables.Collection{Syllables.SyllablesCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-Syllables.createEmptyCollection()
                        })
                    )

                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://publishednft.io/logo-desktop.png"
                        ),
                        mediaType: "image/png"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "The Published NFT Collection",
                        description: "Published NFT is a blockchain eBook publishing platform built on the Flow blockchain, where authors can publish eBooks, Lyrics, Comics, Magazines, Articles, Poems, Recipes, Movie Scripts, Computer Language, etc.",
                        externalURL: MetadataViews.ExternalURL("https://publishednft.io/"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/publishednft/"),
                            "discord": MetadataViews.ExternalURL("https://discord.gg/ct5RPudqpG"),
                            "instagram": MetadataViews.ExternalURL("https://www.instagram.com/publishednft/"),
                            "telegram": MetadataViews.ExternalURL("https://t.me/published_nft"),
                            "reddit": MetadataViews.ExternalURL("https://www.reddit.com/user/PublishedNFT")
                        }
                    )
            }
            return nil
        }
    }

    pub resource interface SyllablesCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowSyllables(id: UInt64): &Syllables.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Syllables reference: The ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: SyllablesCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
            let token <- token as! @Syllables.NFT

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

        pub fun borrowSyllables(id: UInt64): &Syllables.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Syllables.NFT
            } else {
                return nil
            }
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let publishedNFT = nft as! &Syllables.NFT
            return publishedNFT as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }        
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub resource PublishedMinter{
        pub fun mintLibraryPass(_name: String, _ipfsLink: String): @Syllables.NFT?{          
          
          if Syllables.libraryPassTotalSupply == 9999 {return nil}
          
          let libraryPassNft <- create Syllables.NFT(
            serialId: Syllables.libraryPassTotalSupply,
            initID: Syllables.totalSupply,
            name: _name,
            ipfsLink: _ipfsLink,
            type: 1
          )

          emit PublishedMinted(id: Syllables.totalSupply, name: _name, ipfsLink: _ipfsLink, type: 1)

          Syllables.totalSupply = Syllables.totalSupply + (1 as UInt64)
          Syllables.libraryPassTotalSupply = Syllables.libraryPassTotalSupply + (1 as UInt64)

          return <- libraryPassNft
        }

         pub fun mintWillo(_name: String, _ipfsLink: String): @Syllables.NFT?{
          
          if Syllables.willoTotalSupply == 100 {return nil}
          
          let willoNft <- create Syllables.NFT(
            serialId: Syllables.willoTotalSupply,
            initID: Syllables.totalSupply,   
            name: _name,
            ipfsLink: _ipfsLink,
            type: 1
          )
          
          emit PublishedMinted(id: Syllables.totalSupply, name: _name, ipfsLink: _ipfsLink, type: 2)

          Syllables.totalSupply = Syllables.totalSupply + (1 as UInt64)
          Syllables.willoTotalSupply = Syllables.willoTotalSupply + (1 as UInt64)

          return <- willoNft
        }
    } 

    init() {
        self.CollectionStoragePath = /storage/SyllablesCollection
        self.CollectionPublicPath = /public/SyllablesCollection
        self.MinterPublishedPath = /storage/minterSyllablesPath

        self.totalSupply = 0
        self.libraryPassTotalSupply = 0
        self.willoTotalSupply = 0

        self.account.save(<- create PublishedMinter(), to: self.MinterPublishedPath)
        
        self.account.save(<- create Collection(), to: self.CollectionStoragePath)
        self.account.link<&Syllables.Collection{NonFungibleToken.CollectionPublic, Syllables.SyllablesCollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath, 
            target: self.CollectionStoragePath
        )

        emit ContractInitialized()
    }
}
